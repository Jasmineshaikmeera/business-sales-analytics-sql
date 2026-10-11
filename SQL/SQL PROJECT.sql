-- ============================================================
-- BUSINESS SALES ANALYTICS - 50 CORRECTED T-SQL QUERIES
-- Dataset: Sales, Customers, Products, Stores, Exchange_Rates
-- Revenue = Quantity * Unit_Price_USD
-- Profit  = Quantity * (Unit_Price_USD - Unit_Cost_USD)
-- ============================================================


-- ============================================================
-- Q1: Display every sales order with customer name,
--     product name, and quantity purchased.
-- ============================================================
SELECT
    S.[Order_Number]    AS [Order Number],
    C.[Name]            AS [Customer Name],
    P.[Product_Name]    AS [Product Name],
    S.[Quantity]        AS [Quantity]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Customers] AS C ON S.[CustomerKey] = C.[CustomerKey]
INNER JOIN [dbo].[Products]  AS P ON S.[ProductKey]  = P.[ProductKey];



-- ============================================================
-- Q2: Display customer name, customer country, product name,
--     product category, and quantity sold for every sale.
-- ============================================================
SELECT
    C.[Name]         AS [Customer Name],
    C.[Country]      AS [Country],
    P.[Product_Name] AS [Product Name],
    P.[Category]     AS [Category],
    S.[Quantity]     AS [Quantity]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Customers] AS C ON S.[CustomerKey] = C.[CustomerKey]
INNER JOIN [dbo].[Products]  AS P ON S.[ProductKey]  = P.[ProductKey];


-- ============================================================
-- Q3: Total quantity sold for each combination of
--     store country and product category.
-- ============================================================
SELECT
    ST.[Country]      AS [Store Country],
    P.[Category]      AS [Category],
    SUM(S.[Quantity]) AS [TotalQty]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Stores]   AS ST ON S.[StoreKey]  = ST.[StoreKey]
INNER JOIN [dbo].[Products] AS P  ON S.[ProductKey] = P.[ProductKey]
GROUP BY ST.[Country], P.[Category]
ORDER BY [TotalQty] DESC;


-- ============================================================
-- Q4: Total sales revenue in USD across all orders.
--     Formula: SUM(Quantity * Unit_Price_USD)
-- ============================================================
SELECT
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [TotalSalesUSD]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey] = P.[ProductKey];


-- ============================================================
-- Q5: Total sales converted into each order's local currency.
--     Formula: SUM(Quantity * Unit_Price_USD) * Exchange_Rate
--     NOTE: Exchange_Rates deduped using AVG to handle
--           duplicate rows on the same date+currency.
-- ============================================================
WITH DedupeRates AS (
    SELECT
        [Date],
        [Currency],
        AVG([Exchange]) AS [Exchange]
    FROM [dbo].[Exchange_Rates]
    GROUP BY [Date], [Currency]
)
SELECT
    S.[Order_Number]   AS [Order Number],
    S.[Currency_Code]  AS [Currency Code],
    SUM(S.[Quantity] * P.[Unit_Price_USD])                  AS [SalesUSD],
    SUM(S.[Quantity] * P.[Unit_Price_USD] * DR.[Exchange])  AS [LocalSales]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Products] AS P
    ON S.[ProductKey] = P.[ProductKey]
LEFT JOIN DedupeRates AS DR
    ON S.[Currency_Code] = DR.[Currency]
   AND S.[Order_Date]    = DR.[Date]
GROUP BY S.[Order_Number], S.[Currency_Code];


-- ============================================================
-- Q6: For each order, total sales in USD and local currency
--     side by side.
-- ============================================================
WITH DedupeRates AS (
    SELECT
        [Date],
        [Currency],
        AVG([Exchange]) AS [Exchange]
    FROM [dbo].[Exchange_Rates]
    GROUP BY [Date], [Currency]
)
SELECT
    S.[Order_Number]                                        AS [Order Number],
    S.[Currency_Code]                                       AS [Currency Code],
    SUM(S.[Quantity] * P.[Unit_Price_USD])                  AS [SalesUSD],
    SUM(S.[Quantity] * P.[Unit_Price_USD] * DR.[Exchange])  AS [LocalSales]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Products] AS P
    ON S.[ProductKey] = P.[ProductKey]
LEFT JOIN DedupeRates AS DR
    ON S.[Currency_Code] = DR.[Currency]
   AND S.[Order_Date]    = DR.[Date]
GROUP BY S.[Order_Number], S.[Currency_Code];


-- ============================================================
-- Q7: Assume Sales table stores order amount in local currency.
--     Convert to USD: USD Amount = Local Amount / Exchange
--     NOTE: The actual Sales table has no AMOUNT column.
--     This query shows the correct logic if that column existed.
-- ============================================================
-- Add an AMOUNT column to Sales before running this:
-- ALTER TABLE [dbo].[Sales] ADD [Amount] DECIMAL(18,2);

WITH DedupeRates AS (
    SELECT
        [Date],
        [Currency],
        AVG([Exchange]) AS [Exchange]
    FROM [dbo].[Exchange_Rates]
    GROUP BY [Date], [Currency]
)
SELECT
    S.[Order_Number]                        AS [Order Number],
    S.[Currency_Code]                       AS [Currency Code],
    SUM(S.[Amount] / NULLIF(DR.[Exchange], 0)) AS [USDAmount]
FROM [dbo].[Sales] AS S
LEFT JOIN DedupeRates AS DR
    ON S.[Order_Date]    = DR.[Date]
   AND S.[Currency_Code] = DR.[Currency]
GROUP BY S.[Order_Number], S.[Currency_Code];


-- ============================================================
-- Q8: Top 10 customers ranked by total sales revenue.
-- ============================================================
WITH TopCustomers AS (
    SELECT
        C.[CustomerKey],
        C.[Name],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Sales]
    FROM [dbo].[Customers] AS C
    INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
    GROUP BY C.[CustomerKey], C.[Name]
)
SELECT TOP 10
    [Name],
    [Sales]
FROM TopCustomers
ORDER BY [Sales] DESC;


-- ============================================================
-- Q9: Best-selling product (by revenue) within each category.
--     FIX: Added PARTITION BY Category to DENSE_RANK.
-- ============================================================
WITH Ranked AS (
    SELECT
        P.[Category],
        P.[Product_Name],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue],
        DENSE_RANK() OVER (
            PARTITION BY P.[Category]
            ORDER BY SUM(S.[Quantity] * P.[Unit_Price_USD]) DESC
        ) AS RN
    FROM [dbo].[Products] AS P
    INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
    GROUP BY P.[Category], P.[Product_Name]
)
SELECT
    [Category],
    [Product_Name],
    [Revenue]
FROM Ranked
WHERE RN = 1;


-- ============================================================
-- Q10: Number of days to deliver each order with customer name.
--      NOTE: Delivery dates exist only for Online (StoreKey=0).
--            1,100 of 5,580 orders show negative days (data issue).
-- ============================================================
SELECT DISTINCT
    S.[Order_Number],
    C.[Name],
    DATEDIFF(DAY, S.[Order_Date], S.[Delivery_Date]) AS [DeliveryDays]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Customers] AS C ON S.[CustomerKey] = C.[CustomerKey]
WHERE S.[Delivery_Date] IS NOT NULL;


-- ============================================================
-- Q11: Average delivery time (days) per customer country.
--      FIX: Filter negative days and cast to FLOAT to avoid
--           integer truncation. Online-only metric.
-- ============================================================
WITH DeliveryCalc AS (
    SELECT DISTINCT
        S.[Order_Number],
        C.[Country],
        DATEDIFF(DAY, S.[Order_Date], S.[Delivery_Date]) AS [DeliveryDays]
    FROM [dbo].[Sales] AS S
    INNER JOIN [dbo].[Customers] AS C ON S.[CustomerKey] = C.[CustomerKey]
    WHERE S.[Delivery_Date] IS NOT NULL
      AND DATEDIFF(DAY, S.[Order_Date], S.[Delivery_Date]) >= 0
)
SELECT
    [Country],
    CAST(AVG(CAST([DeliveryDays] AS FLOAT)) AS DECIMAL(10,1)) AS [AvgDeliveryDays]
FROM DeliveryCalc
GROUP BY [Country]
ORDER BY [AvgDeliveryDays];


-- ============================================================
-- Q12: Top 5 product brands by total revenue.
-- ============================================================
WITH BrandRevenue AS (
    SELECT
        P.[Brand],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
    FROM [dbo].[Products] AS P
    INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
    GROUP BY P.[Brand]
)
SELECT TOP 5
    [Brand],
    [Revenue]
FROM BrandRevenue
ORDER BY [Revenue] DESC;


-- ============================================================
-- Q13: Single store with highest total revenue.
--      NOTE: StoreKey 0 = Online channel (not a physical store).
--            Top physical store is StoreKey 55 (Nevada).
-- ============================================================
-- Top store overall (includes Online):
WITH StoreRevenue AS (
    SELECT
        S.[StoreKey],
        ST.[Country],
        ST.[State],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
    FROM [dbo].[Sales] AS S
    INNER JOIN [dbo].[Stores]   AS ST ON S.[StoreKey]  = ST.[StoreKey]
    INNER JOIN [dbo].[Products] AS P  ON S.[ProductKey] = P.[ProductKey]
    GROUP BY S.[StoreKey], ST.[Country], ST.[State]
)
SELECT TOP 1
    [StoreKey],
    [Country],
    [State],
    [Revenue]
FROM StoreRevenue
ORDER BY [Revenue] DESC;


-- ============================================================
-- Q14: Total profit by product category.
--      Formula: SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD))
-- ============================================================
SELECT
    P.[Category],
    SUM(S.[Quantity] * (P.[Unit_Price_USD] - P.[Unit_Cost_USD])) AS [Profit]
FROM [dbo].[Products] AS P
INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
GROUP BY P.[Category]
ORDER BY [Profit] DESC;


-- ============================================================
-- Q15: Total profit by customer country.
-- ============================================================
SELECT
    C.[Country],
    SUM(S.[Quantity] * (P.[Unit_Price_USD] - P.[Unit_Cost_USD])) AS [Profit]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
GROUP BY C.[Country]
ORDER BY [Profit] DESC;


-- ============================================================
-- Q16: Top 3 best-selling products (by revenue) per category.
-- ============================================================
WITH Ranked AS (
    SELECT
        P.[Category],
        P.[Product_Name],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue],
        DENSE_RANK() OVER (
            PARTITION BY P.[Category]
            ORDER BY SUM(S.[Quantity] * P.[Unit_Price_USD]) DESC
        ) AS [Rank]
    FROM [dbo].[Products] AS P
    INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
    GROUP BY P.[Category], P.[Product_Name]
)
SELECT
    [Category],
    [Product_Name],
    [Revenue],
    [Rank]
FROM Ranked
WHERE [Rank] <= 3
ORDER BY [Category], [Rank];


-- ============================================================
-- Q17: Each customer's age at the time of each order.
--      Uses DATEADD method to correctly handle leap years.
-- ============================================================
SELECT
    C.[Name],
    S.[Order_Date],
    DATEDIFF(YEAR, C.[Birthday], S.[Order_Date])
    - CASE
        WHEN DATEADD(
                 YEAR,
                 DATEDIFF(YEAR, C.[Birthday], S.[Order_Date]),
                 C.[Birthday]
             ) > S.[Order_Date]
        THEN 1
        ELSE 0
      END AS [AgeAtPurchase]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales] AS S ON C.[CustomerKey] = S.[CustomerKey]
ORDER BY [AgeAtPurchase];


-- ============================================================
-- Q18: Customers who purchased from more than one store.
--      FIX: Group by CustomerKey (not Name) to avoid merging
--           different people who share a name.
-- ============================================================
SELECT
    C.[Name],
    COUNT(DISTINCT S.[StoreKey]) AS [StoresVisited]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales] AS S ON C.[CustomerKey] = S.[CustomerKey]
GROUP BY C.[CustomerKey], C.[Name]
HAVING COUNT(DISTINCT S.[StoreKey]) > 1
ORDER BY [StoresVisited] DESC;


-- ============================================================
-- Q19: Total revenue by store country and state.
-- ============================================================
SELECT
    ST.[Country],
    ST.[State],
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
FROM [dbo].[Stores] AS ST
INNER JOIN [dbo].[Sales]    AS S ON ST.[StoreKey]  = S.[StoreKey]
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey] = P.[ProductKey]
GROUP BY ST.[Country], ST.[State]
ORDER BY [Revenue] DESC;


-- ============================================================
-- Q20: Total revenue by continent.
-- ============================================================
SELECT
    C.[Continent],
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
GROUP BY C.[Continent]
ORDER BY [Revenue] DESC;


-- ============================================================
-- Q21: Repeat customers (placed more than one order).
--      FIX: Group by CustomerKey to avoid name collisions.
-- ============================================================
SELECT
    C.[Name],
    COUNT(DISTINCT S.[Order_Number]) AS [TotalOrders]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales] AS S ON C.[CustomerKey] = S.[CustomerKey]
GROUP BY C.[CustomerKey], C.[Name]
HAVING COUNT(DISTINCT S.[Order_Number]) > 1
ORDER BY [TotalOrders] DESC;


-- ============================================================
-- Q22: Customers who purchased from more than one category.
--      FIX: Group by CustomerKey.
-- ============================================================
SELECT
    C.[Name],
    COUNT(DISTINCT P.[Category]) AS [CategoriesPurchased]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
GROUP BY C.[CustomerKey], C.[Name]
HAVING COUNT(DISTINCT P.[Category]) > 1
ORDER BY [CategoriesPurchased] DESC;


-- ============================================================
-- Q23: Total monthly sales revenue for each country.
-- ============================================================
SELECT
    YEAR(S.[Order_Date])                   AS [SalesYear],
    MONTH(S.[Order_Date])                  AS [SalesMonth],
    C.[Country],
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [SalesUSD]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Customers] AS C ON S.[CustomerKey] = C.[CustomerKey]
INNER JOIN [dbo].[Products]  AS P ON S.[ProductKey]  = P.[ProductKey]
GROUP BY C.[Country], YEAR(S.[Order_Date]), MONTH(S.[Order_Date])
ORDER BY [SalesYear], [SalesMonth], C.[Country];


-- ============================================================
-- Q24: Top-selling product (by quantity) in each country.
-- ============================================================
WITH Ranked AS (
    SELECT
        C.[Country],
        P.[Product_Name],
        SUM(S.[Quantity]) AS [TotalQty],
        DENSE_RANK() OVER (
            PARTITION BY C.[Country]
            ORDER BY SUM(S.[Quantity]) DESC
        ) AS RN
    FROM [dbo].[Customers] AS C
    INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
    GROUP BY C.[Country], P.[Product_Name]
)
SELECT
    [Country],
    [Product_Name],
    [TotalQty]
FROM Ranked
WHERE RN = 1
ORDER BY [TotalQty] DESC;


-- ============================================================
-- Q25: Revenue, cost, profit, profit %, and local currency
--      revenue for each country.
--      NOTE: Exchange_Rates deduped to avoid row multiplication.
-- ============================================================
WITH DedupeRates AS (
    SELECT
        [Date],
        [Currency],
        AVG([Exchange]) AS [Exchange]
    FROM [dbo].[Exchange_Rates]
    GROUP BY [Date], [Currency]
)
SELECT
    C.[Country],
    SUM(S.[Quantity] * P.[Unit_Price_USD])                         AS [RevenueUSD],
    SUM(S.[Quantity] * P.[Unit_Cost_USD])                          AS [CostUSD],
    SUM(S.[Quantity] * (P.[Unit_Price_USD] - P.[Unit_Cost_USD]))   AS [ProfitUSD],
    CAST(
        SUM(S.[Quantity] * (P.[Unit_Price_USD] - P.[Unit_Cost_USD]))
        / NULLIF(SUM(S.[Quantity] * P.[Unit_Price_USD]), 0)
        * 100
    AS DECIMAL(10,2))                                              AS [ProfitPercentage],
    SUM(S.[Quantity] * P.[Unit_Price_USD] * DR.[Exchange])         AS [RevenueLocalCurrency]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales]    AS S  ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Products] AS P  ON S.[ProductKey]  = P.[ProductKey]
LEFT  JOIN DedupeRates      AS DR ON S.[Order_Date]  = DR.[Date]
                                  AND S.[Currency_Code] = DR.[Currency]
GROUP BY C.[Country]
ORDER BY [RevenueUSD] DESC;


-- ============================================================
-- Q26: High-value customers for loyalty program.
--      Name, country, total orders, total quantity, total sales.
-- ============================================================
SELECT
    C.[Name],
    C.[Country],
    COUNT(DISTINCT S.[Order_Number])       AS [TotalOrders],
    SUM(S.[Quantity])                      AS [TotalQuantity],
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [TotalSalesUSD]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
GROUP BY C.[CustomerKey], C.[Name], C.[Country]
ORDER BY [TotalSalesUSD] DESC;


-- ============================================================
-- Q27: Products with highest profit contribution.
--      Product name, brand, revenue, cost, profit.
-- ============================================================
SELECT
    P.[Product_Name],
    P.[Brand],
    SUM(S.[Quantity] * P.[Unit_Price_USD])                       AS [Revenue],
    SUM(S.[Quantity] * P.[Unit_Cost_USD])                        AS [Cost],
    SUM(S.[Quantity] * (P.[Unit_Price_USD] - P.[Unit_Cost_USD])) AS [Profit]
FROM [dbo].[Products] AS P
INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
GROUP BY P.[Product_Name], P.[Brand]
ORDER BY [Profit] DESC;


-- ============================================================
-- Q28: Total revenue per store with country, state, size (sqm).
-- ============================================================
SELECT
    ST.[Country],
    ST.[State],
    ST.[Square_Meters],
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
FROM [dbo].[Stores] AS ST
INNER JOIN [dbo].[Sales]    AS S ON ST.[StoreKey]  = S.[StoreKey]
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey] = P.[ProductKey]
GROUP BY ST.[Country], ST.[State], ST.[Square_Meters]
ORDER BY [Revenue] DESC;


-- ============================================================
-- Q29: Top-selling category (by revenue) for each country.
-- ============================================================
WITH Ranked AS (
    SELECT
        C.[Country],
        P.[Category],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue],
        DENSE_RANK() OVER (
            PARTITION BY C.[Country]
            ORDER BY SUM(S.[Quantity] * P.[Unit_Price_USD]) DESC
        ) AS RNK
    FROM [dbo].[Customers] AS C
    INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
    GROUP BY C.[Country], P.[Category]
)
SELECT
    [Country],
    [Category],
    [Revenue]
FROM Ranked
WHERE RNK = 1
ORDER BY [Revenue] DESC;


-- ============================================================
-- Q30: Order number, customer name, currency, revenue USD,
--      revenue in local currency.
--      NOTE: LEFT JOIN keeps all orders; 134 Jan-2021 orders
--            have no exchange rate (LocalRevenue will be NULL).
-- ============================================================
WITH DedupeRates AS (
    SELECT
        [Date],
        [Currency],
        AVG([Exchange]) AS [Exchange]
    FROM [dbo].[Exchange_Rates]
    GROUP BY [Date], [Currency]
)
SELECT
    S.[Order_Number]                                        AS [Order Number],
    C.[Name],
    S.[Currency_Code]                                       AS [Currency Code],
    SUM(S.[Quantity] * P.[Unit_Price_USD])                  AS [RevenueUSD],
    SUM(S.[Quantity] * P.[Unit_Price_USD] * DR.[Exchange])  AS [RevenueLocal]
FROM [dbo].[Sales] AS S
INNER JOIN [dbo].[Customers] AS C  ON S.[CustomerKey] = C.[CustomerKey]
INNER JOIN [dbo].[Products]  AS P  ON S.[ProductKey]  = P.[ProductKey]
LEFT  JOIN DedupeRates       AS DR ON S.[Order_Date]  = DR.[Date]
                                   AND S.[Currency_Code] = DR.[Currency]
GROUP BY S.[Order_Number], C.[Name], S.[Currency_Code]
ORDER BY S.[Order_Number];


-- ============================================================
-- Q31: Customers who purchased from at least 3 different brands.
--      FIX: Group by CustomerKey.
-- ============================================================
SELECT
    C.[Name],
    COUNT(DISTINCT P.[Brand]) AS [BrandsPurchased]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
GROUP BY C.[CustomerKey], C.[Name]
HAVING COUNT(DISTINCT P.[Brand]) >= 3
ORDER BY [BrandsPurchased] DESC;


-- ============================================================
-- Q32: Average order value for each country.
--      FIX: First sum per order, then average those order totals.
--      Your original query averaged one row per country = wrong.
-- ============================================================
WITH OrderTotals AS (
    SELECT
        C.[Country],
        S.[Order_Number],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [OrderValue]
    FROM [dbo].[Customers] AS C
    INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
    GROUP BY C.[Country], S.[Order_Number]
)
SELECT
    [Country],
    CAST(AVG([OrderValue]) AS DECIMAL(18,2)) AS [AvgOrderValue]
FROM OrderTotals
GROUP BY [Country]
ORDER BY [AvgOrderValue] DESC;


-- ============================================================
-- Q33: Oldest customer (by birthday) who placed at least one order.
-- ============================================================
SELECT TOP 1
    C.[Name],
    C.[Country],
    C.[Birthday]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales] AS S ON C.[CustomerKey] = S.[CustomerKey]
GROUP BY C.[CustomerKey], C.[Name], C.[Country], C.[Birthday]
ORDER BY C.[Birthday];


-- ============================================================
-- Q34: Yearly revenue for each product category.
-- ============================================================
SELECT
    P.[Category],
    YEAR(S.[Order_Date])                   AS [SalesYear],
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
FROM [dbo].[Products] AS P
INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
GROUP BY P.[Category], YEAR(S.[Order_Date])
ORDER BY P.[Category], [SalesYear];


-- ============================================================
-- Q35: Products that have never been sold.
-- ============================================================
SELECT
    P.[ProductKey],
    P.[Product_Name],
    P.[Category]
FROM [dbo].[Products] AS P
LEFT JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
WHERE S.[Order_Number] IS NULL;


-- ============================================================
-- Q36: Stores that have never processed an order.
-- ============================================================
SELECT
    ST.[StoreKey],
    ST.[Country],
    ST.[State]
FROM [dbo].[Stores] AS ST
LEFT JOIN [dbo].[Sales] AS S ON ST.[StoreKey] = S.[StoreKey]
WHERE S.[Order_Number] IS NULL;


-- ============================================================
-- Q37: Monthly revenue for each product brand.
-- ============================================================
SELECT
    YEAR(S.[Order_Date])                   AS [SalesYear],
    MONTH(S.[Order_Date])                  AS [SalesMonth],
    P.[Brand],
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
FROM [dbo].[Products] AS P
INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
GROUP BY P.[Brand], YEAR(S.[Order_Date]), MONTH(S.[Order_Date])
ORDER BY [SalesYear], [SalesMonth], P.[Brand];


-- ============================================================
-- Q38: Customers whose total spending exceeds the overall
--      customer average.
--      FIX: Use a subquery for the average.
--           WHERE clause cannot contain aggregate functions.
-- ============================================================
WITH CustomerSales AS (
    SELECT
        C.[CustomerKey],
        C.[Name],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Sales]
    FROM [dbo].[Customers] AS C
    INNER JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
    GROUP BY C.[CustomerKey], C.[Name]
)
SELECT
    [Name],
    [Sales]
FROM CustomerSales
WHERE [Sales] > (SELECT AVG([Sales]) FROM CustomerSales)
ORDER BY [Sales] DESC;


-- ============================================================
-- Q39: Rank all stores by total revenue.
-- ============================================================
SELECT
    ST.[StoreKey],
    ST.[Country],
    ST.[State],
    SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue],
    DENSE_RANK() OVER (
        ORDER BY SUM(S.[Quantity] * P.[Unit_Price_USD]) DESC
    ) AS [StoreRank]
FROM [dbo].[Stores] AS ST
INNER JOIN [dbo].[Sales]    AS S ON ST.[StoreKey]  = S.[StoreKey]
INNER JOIN [dbo].[Products] AS P ON S.[ProductKey] = P.[ProductKey]
GROUP BY ST.[StoreKey], ST.[Country], ST.[State]
ORDER BY [StoreRank];


-- ============================================================
-- Q40: Each customer's percentage contribution to total revenue.
--      FIX: Added GO before CREATE VIEW (required by SQL Server).
--           Group by CustomerKey to avoid name collisions.
-- ============================================================
GO
CREATE VIEW [dbo].[CUST_PERCENTAGE] AS
    SELECT
        C.[CustomerKey],
        C.[Name],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [CustRevenue],
        SUM(SUM(S.[Quantity] * P.[Unit_Price_USD])) OVER () AS [TotalRevenue],
        CAST(
            SUM(S.[Quantity] * P.[Unit_Price_USD])
            / NULLIF(SUM(SUM(S.[Quantity] * P.[Unit_Price_USD])) OVER (), 0)
            * 100
        AS DECIMAL(10,4)) AS [ContributionPercent]
    FROM [dbo].[Customers] AS C
    LEFT JOIN [dbo].[Sales]    AS S ON C.[CustomerKey] = S.[CustomerKey]
    LEFT JOIN [dbo].[Products] AS P ON S.[ProductKey]  = P.[ProductKey]
    GROUP BY C.[CustomerKey], C.[Name];
GO

SELECT * FROM [dbo].[CUST_PERCENTAGE]
ORDER BY [ContributionPercent] DESC;


-- ============================================================
-- Q41: Stores that deliver orders fastest (avg delivery days).
--      FIX: Filter WHERE Delivery_Date IS NOT NULL and
--           exclude negative days.
--           NOTE: Only Online (StoreKey 0) has delivery data.
-- ============================================================
WITH DeliveryCalc AS (
    SELECT DISTINCT
        S.[StoreKey],
        S.[Order_Number],
        DATEDIFF(DAY, S.[Order_Date], S.[Delivery_Date]) AS [DeliveryDays]
    FROM [dbo].[Sales] AS S
    WHERE S.[Delivery_Date] IS NOT NULL
      AND DATEDIFF(DAY, S.[Order_Date], S.[Delivery_Date]) >= 0
)
SELECT
    ST.[StoreKey],
    ST.[Country],
    ST.[State],
    COUNT(DISTINCT DC.[Order_Number])                           AS [TotalOrders],
    CAST(AVG(CAST(DC.[DeliveryDays] AS FLOAT)) AS DECIMAL(10,1)) AS [AvgDeliveryDays]
FROM [dbo].[Stores] AS ST
INNER JOIN DeliveryCalc AS DC ON ST.[StoreKey] = DC.[StoreKey]
GROUP BY ST.[StoreKey], ST.[Country], ST.[State]
ORDER BY [AvgDeliveryDays];


-- ============================================================
-- Q42: Top 5 stores with the highest average delivery days.
--      FIX: Same as Q41 — filter NULLs and negatives.
-- ============================================================
WITH DeliveryCalc AS (
    SELECT DISTINCT
        S.[StoreKey],
        S.[Order_Number],
        DATEDIFF(DAY, S.[Order_Date], S.[Delivery_Date]) AS [DeliveryDays]
    FROM [dbo].[Sales] AS S
    WHERE S.[Delivery_Date] IS NOT NULL
      AND DATEDIFF(DAY, S.[Order_Date], S.[Delivery_Date]) >= 0
)
SELECT TOP 5
    ST.[StoreKey],
    ST.[Country],
    ST.[State],
    COUNT(DISTINCT DC.[Order_Number])                           AS [TotalOrders],
    CAST(AVG(CAST(DC.[DeliveryDays] AS FLOAT)) AS DECIMAL(10,1)) AS [AvgDeliveryDays]
FROM [dbo].[Stores] AS ST
INNER JOIN DeliveryCalc AS DC ON ST.[StoreKey] = DC.[StoreKey]
GROUP BY ST.[StoreKey], ST.[Country], ST.[State]
ORDER BY [AvgDeliveryDays] DESC;


-- ============================================================
-- Q43: Category profit margin analysis.
--      Revenue, cost, profit, and profit percentage.
-- ============================================================
SELECT
    P.[Category],
    SUM(S.[Quantity] * P.[Unit_Price_USD])                       AS [Revenue],
    SUM(S.[Quantity] * P.[Unit_Cost_USD])                        AS [Cost],
    SUM(S.[Quantity] * (P.[Unit_Price_USD] - P.[Unit_Cost_USD])) AS [Profit],
    CAST(
        SUM(S.[Quantity] * (P.[Unit_Price_USD] - P.[Unit_Cost_USD]))
        / NULLIF(SUM(S.[Quantity] * P.[Unit_Price_USD]), 0)
        * 100
    AS DECIMAL(10,2))                                            AS [ProfitPercentage]
FROM [dbo].[Products] AS P
INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
GROUP BY P.[Category]
ORDER BY [ProfitPercentage] DESC;


-- ============================================================
-- Q44: Top 5 brands by revenue within each store country.
-- ============================================================
WITH Ranked AS (
    SELECT
        ST.[Country],
        P.[Brand],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue],
        DENSE_RANK() OVER (
            PARTITION BY ST.[Country]
            ORDER BY SUM(S.[Quantity] * P.[Unit_Price_USD]) DESC
        ) AS RN
    FROM [dbo].[Products] AS P
    INNER JOIN [dbo].[Sales]   AS S  ON P.[ProductKey] = S.[ProductKey]
    INNER JOIN [dbo].[Stores]  AS ST ON S.[StoreKey]   = ST.[StoreKey]
    GROUP BY ST.[Country], P.[Brand]
)
SELECT
    [Country],
    [Brand],
    [Revenue],
    RN AS [Rank]
FROM Ranked
WHERE RN <= 5
ORDER BY [Country], [Rank];


-- ============================================================
-- Q45: Cumulative (running) revenue by year and month.
--      FIX: Added PARTITION BY SalesYear so the running total
--           resets at the start of each year.
-- ============================================================
WITH MonthlyRevenue AS (
    SELECT
        YEAR(S.[Order_Date])                   AS [SalesYear],
        MONTH(S.[Order_Date])                  AS [SalesMonth],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
    FROM [dbo].[Sales] AS S
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey] = P.[ProductKey]
    GROUP BY YEAR(S.[Order_Date]), MONTH(S.[Order_Date])
)
SELECT
    [SalesYear],
    [SalesMonth],
    [Revenue],
    SUM([Revenue]) OVER (
        PARTITION BY [SalesYear]
        ORDER BY [SalesYear], [SalesMonth]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS [RunningRevenue]
FROM MonthlyRevenue
ORDER BY [SalesYear], [SalesMonth];


-- ============================================================
-- Q46: Month-over-month revenue growth.
-- ============================================================
WITH MonthlyRevenue AS (
    SELECT
        YEAR(S.[Order_Date])                   AS [SalesYear],
        MONTH(S.[Order_Date])                  AS [SalesMonth],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS [Revenue]
    FROM [dbo].[Sales] AS S
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey] = P.[ProductKey]
    GROUP BY YEAR(S.[Order_Date]), MONTH(S.[Order_Date])
),
WithLag AS (
    SELECT
        [SalesYear],
        [SalesMonth],
        [Revenue],
        LAG([Revenue]) OVER (
            ORDER BY [SalesYear], [SalesMonth]
        ) AS [PreviousMonthRevenue]
    FROM MonthlyRevenue
)
SELECT
    [SalesYear],
    [SalesMonth],
    [Revenue],
    [PreviousMonthRevenue],
    CAST(
        ([Revenue] - [PreviousMonthRevenue])
        / NULLIF([PreviousMonthRevenue], 0)
        * 100
    AS DECIMAL(10,2)) AS [MoMGrowthPercent]
FROM WithLag
ORDER BY [SalesYear], [SalesMonth];


-- ============================================================
-- Q47: Highest-selling product color (by quantity) per category.
-- ============================================================
WITH Ranked AS (
    SELECT
        P.[Category],
        P.[Color],
        SUM(S.[Quantity]) AS [TotalQty],
        DENSE_RANK() OVER (
            PARTITION BY P.[Category]
            ORDER BY SUM(S.[Quantity]) DESC
        ) AS RN
    FROM [dbo].[Products] AS P
    INNER JOIN [dbo].[Sales] AS S ON P.[ProductKey] = S.[ProductKey]
    GROUP BY P.[Category], P.[Color]
)
SELECT
    [Category],
    [Color],
    [TotalQty]
FROM Ranked
WHERE RN = 1
ORDER BY [TotalQty] DESC;


-- ============================================================
-- Q48: Customers who shopped in more than one store country.
--      FIX: Group by CustomerKey only (not Name + Country).
--           Original GROUP BY Name, Country made HAVING always
--           return 0 rows (each group already had 1 country).
--      NOTE: No customer shops physically in 2+ countries.
--            The 3,317 results include Online as a "country".
--            Version A below excludes Online for physical only.
-- ============================================================

-- Version A: Physical stores only (returns 0 rows — no one
--            physically shops in multiple countries)
SELECT
    C.[Name],
    COUNT(DISTINCT ST.[Country]) AS [CountriesPurchased]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales]  AS S  ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Stores] AS ST ON S.[StoreKey]    = ST.[StoreKey]
WHERE S.[StoreKey] <> 0
GROUP BY C.[CustomerKey], C.[Name]
HAVING COUNT(DISTINCT ST.[Country]) > 1
ORDER BY [CountriesPurchased] DESC;

-- Version B: Including Online channel as a country (3,317 customers)
SELECT
    C.[Name],
    COUNT(DISTINCT ST.[Country]) AS [CountriesPurchased]
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales]  AS S  ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Stores] AS ST ON S.[StoreKey]    = ST.[StoreKey]
GROUP BY C.[CustomerKey], C.[Name]
HAVING COUNT(DISTINCT ST.[Country]) > 1
ORDER BY [CountriesPurchased] DESC;


-- ============================================================
-- Q49: Total revenue by customer age group at time of purchase.
--      Age groups: Under 18, 18-25, 26-35, 36-45, 46-60, 60+
-- ============================================================
WITH AgeCalc AS (
    SELECT
        S.[Quantity],
        P.[Unit_Price_USD],
        DATEDIFF(YEAR, C.[Birthday], S.[Order_Date])
        - CASE
            WHEN DATEADD(
                     YEAR,
                     DATEDIFF(YEAR, C.[Birthday], S.[Order_Date]),
                     C.[Birthday]
                 ) > S.[Order_Date]
            THEN 1
            ELSE 0
          END AS [AgeAtPurchase]
    FROM [dbo].[Sales] AS S
    INNER JOIN [dbo].[Customers] AS C ON S.[CustomerKey] = S.[CustomerKey]
    INNER JOIN [dbo].[Products]  AS P ON S.[ProductKey]  = P.[ProductKey]
)
SELECT
    CASE
        WHEN [AgeAtPurchase] < 18                    THEN 'Under 18'
        WHEN [AgeAtPurchase] BETWEEN 18 AND 25       THEN '18-25'
        WHEN [AgeAtPurchase] BETWEEN 26 AND 35       THEN '26-35'
        WHEN [AgeAtPurchase] BETWEEN 36 AND 45       THEN '36-45'
        WHEN [AgeAtPurchase] BETWEEN 46 AND 60       THEN '46-60'
        WHEN [AgeAtPurchase] > 60                    THEN '60+'
    END AS [AgeGroup],
    SUM([Quantity] * [Unit_Price_USD]) AS [Revenue]
FROM AgeCalc
GROUP BY
    CASE
        WHEN [AgeAtPurchase] < 18                    THEN 'Under 18'
        WHEN [AgeAtPurchase] BETWEEN 18 AND 25       THEN '18-25'
        WHEN [AgeAtPurchase] BETWEEN 26 AND 35       THEN '26-35'
        WHEN [AgeAtPurchase] BETWEEN 36 AND 45       THEN '36-45'
        WHEN [AgeAtPurchase] BETWEEN 46 AND 60       THEN '46-60'
        WHEN [AgeAtPurchase] > 60                    THEN '60+'
    END
ORDER BY [Revenue] DESC;


-- ============================================================
-- Q50: Executive dashboard — all key business KPIs in one query.
--      NOTE: TotalRevenueLocalCurrency sums across 5 currencies
--            and is not a meaningful single number.
--            Use Q25 for per-country local currency figures.
-- ============================================================
WITH CoreKPIs AS (
    SELECT
        SUM(S.[Quantity] * P.[Unit_Price_USD])                       AS [TotalRevenueUSD],
        SUM(S.[Quantity] * P.[Unit_Cost_USD])                        AS [TotalCostUSD],
        SUM(S.[Quantity] * (P.[Unit_Price_USD] - P.[Unit_Cost_USD])) AS [TotalProfitUSD],
        COUNT(DISTINCT S.[Order_Number])                             AS [TotalOrders],
        COUNT(DISTINCT S.[CustomerKey])                              AS [TotalCustomers],
        SUM(S.[Quantity])                                            AS [TotalUnitsSold]
    FROM [dbo].[Sales] AS S
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey] = P.[ProductKey]
),
LocalCurrency AS (
    SELECT
        SUM(S.[Quantity] * P.[Unit_Price_USD] * DR.[Exchange]) AS [TotalRevenueLocalCurrency]
    FROM [dbo].[Sales] AS S
    INNER JOIN [dbo].[Products] AS P ON S.[ProductKey] = P.[ProductKey]
    LEFT JOIN (
        SELECT [Date], [Currency], AVG([Exchange]) AS [Exchange]
        FROM [dbo].[Exchange_Rates]
        GROUP BY [Date], [Currency]
    ) AS DR
        ON S.[Order_Date]    = DR.[Date]
       AND S.[Currency_Code] = DR.[Currency]
)
SELECT
    K.[TotalRevenueUSD],
    K.[TotalCostUSD],
    K.[TotalProfitUSD],
    CAST(K.[TotalProfitUSD] / NULLIF(K.[TotalRevenueUSD], 0) * 100 AS DECIMAL(10,2)) AS [ProfitPercentage],
    K.[TotalOrders],
    K.[TotalCustomers],
    K.[TotalUnitsSold],
    CAST(K.[TotalRevenueUSD] / NULLIF(K.[TotalOrders], 0) AS DECIMAL(18,2))          AS [AvgOrderValueUSD],
    L.[TotalRevenueLocalCurrency]
FROM CoreKPIs AS K
CROSS JOIN LocalCurrency AS L;

