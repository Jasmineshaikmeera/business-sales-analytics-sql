SELECT * FROM [dbo].[Customers]
SELECT * FROM [dbo].[Exchange_Rates]
SELECT * FROM [dbo].[Products]
SELECT * FROM [dbo].[Sales]
SELECT * FROM [dbo].[Stores]

--Write a query to display every sales order along with the corresponding customer name, product name, and quantity purchased.

SELECT
    s.[Order_Number]   AS [Order Number],
    c.[Name]            AS [Name],
    p.[Product_Name]    AS [Product Name],
    s.[Quantity]         AS [Quantity]
FROM Sales AS s
LEFT JOIN Customers AS c
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN Products AS p
    ON s.ProductKey = p.ProductKey


-- Write a query to display, for every sale, the customer name, customer country, product name, product category, and quantity sold

SELECT
    C.[Name]            AS [Name],
    C.[Country]          AS [Country],
    P.[Product_Name]    AS [Product Name],
    P.[Category]         AS [Category],
    S.[Quantity]          AS [Quantity]
FROM [dbo].[Sales] AS S
LEFT JOIN [dbo].[Customers] AS C
    ON S.[CustomerKey] = C.[CustomerKey]
LEFT JOIN [dbo].[Products] AS P
    ON S.[ProductKey] = P.[ProductKey];

 ---Write a query to calculate the total quantity sold for each combination of store country and product category.
 SELECT S.[Country],P.[Category],SUM(X.[Quantity]) AS TotalQty
 FROM [dbo].[Stores] AS S
 LEFT JOIN 
[dbo].[Sales] AS X
ON S.StoreKey=X.StoreKey
LEFT JOIN [dbo].[Products] AS P 
ON X.ProductKey=P.ProductKey
GROUP BY S.[Country],P.[Category]
ORDER BY TotalQty DESC

--Write a query to calculate the total sales revenue (in USD) generated across all orders.

Sales Amount USD= Quantity * Unit Price USD

SELECT SUM(S.[Quantity]*P.[Unit_Price_USD]) AS TotalSalesUSD 
FROM [dbo].[Sales] AS S
LEFT JOIN 
[dbo].[Products] AS P 
ON S.ProductKey=P.ProductKey

---Write a query to calculate total sales converted into each order's local currency,
--using the exchange rate matched by currency code and order date

SELECT S.[Order_Number]AS [Order Number],S.[Currency_Code] AS [Currency Code],(SUM(S.Quantity*P.[Unit_Price_USD]))* E.Exchange AS LocalSales
FROM [dbo].[Sales] AS S
LEFT JOIN 
[dbo].[Exchange_Rates] AS E
ON S.Currency_Code=E.Currency AND S.Order_Date=E.Date
LEFT JOIN 
[dbo].[Products] AS P 
ON S.ProductKey= P.[ProductKey]
GROUP BY S.[Order_Number],S.[Currency_Code],E.Exchange


---Write a query to display, for each order, the total sales in both USD and the local currency side by side.
Order Number
SalesUSD= SUM(Q*UNIT PRICE OF USD )
LocalSales=(SUM(S.Quantity*P.[Unit_Price_USD]))

SELECT S.[Order_Number]AS [Order Number],
SUM(S.[Quantity]*P.[Unit_Price_USD])AS SalesUSD ,
(SUM(S.Quantity*P.[Unit_Price_USD]))* E.Exchange AS LocalSales
FROM [dbo].[Sales] AS S
LEFT JOIN 
[dbo].[Exchange_Rates] AS E
ON S.Currency_Code=E.Currency AND S.Order_Date=E.Date
LEFT JOIN 
[dbo].[Products] AS P 
ON S.ProductKey= P.[ProductKey]
GROUP BY S.[Order_Number],E.Exchange


--Assume the Sales table stores the order amount in local currency.
--Write a query to convert this local currency amount into USD for each order using the applicable exchange rate

USD Amount = Local Amount / Exchange


SELECT S.[Order_Number],(S.AMOUNT/E.Exchange) AS USDAmount FROM [dbo].[Sales] AS S
LEFT JOIN 
[dbo].[Exchange_Rates] AS E
ON S.Order_Date=E.Date AND S.Currency_Code=E.Currency

--Write a query to identify the top 10 customers ranked by total sales revenue.


WITH TOP_CUSTOMERS AS (
    SELECT 
        C.[CustomerKey], 
        C.[Name],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Sales
    FROM [dbo].[Customers] AS C
    LEFT JOIN [dbo].[Sales] AS S
        ON C.[CustomerKey] = S.[CustomerKey]
    LEFT JOIN [dbo].[Products] AS P 
        ON S.[ProductKey] = P.[ProductKey]
    GROUP BY C.[CustomerKey], C.[Name]
)
SELECT TOP 10 [Name], Sales
FROM TOP_CUSTOMERS
ORDER BY Sales DESC;


---Write a query to find the best-selling product (by revenue) within each product category.

SELECT P.[Category],P.[Product_Name],SUM(S.[Quantity]*P.[Unit_Price_USD]) AS SALES ,
DENSE_RANK() OVER ( ORDER BY SUM(S.[Quantity]*P.[Unit_Price_USD]) DESC ) AS RN
FROM [dbo].[Products] AS P 
LEFT JOIN 
[dbo].[Sales] AS  S
ON P.ProductKey=S.ProductKey
GROUP BY  P.[Category],P.[Product_Name]


---Write a query to calculate the number of days taken to deliver each order, along with the customer name.


SELECT DISTINCT S.[Order_Number],
DATEDIFF(DAY,S.[Order_Date],S.[Delivery_Date]) AS DeliveryDays,
C.[Name]
FROM [dbo].[Sales] AS S
LEFT JOIN  
[dbo].[Customers] AS C
ON S.CustomerKey=C.CustomerKey


--Write a query to calculate the average order delivery time (in days) for each customer country.

SELECT 
    C.[Country],
    AVG(DATEDIFF(DAY, S.[Order_Date], S.[Delivery_Date])) AS AvgDays
FROM [dbo].[Customers] AS C
LEFT JOIN [dbo].[Sales] AS S
    ON C.[CustomerKey] = S.[CustomerKey]
GROUP BY C.[Country];

--Write a query to identify the top 5 product brands ranked by total revenue
WITH CTE AS (
    SELECT 
        P.[Brand],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue
    FROM [dbo].[Products] AS P 
    LEFT JOIN [dbo].[Sales] AS S
        ON P.[ProductKey] = S.[ProductKey]
    GROUP BY P.[Brand]
)
SELECT TOP 5 [Brand], [Revenue] 
FROM CTE
ORDER BY [Revenue] DESC;

--Write a query to identify the single store that has generated the highest total revenue.

WITH CTE AS (
    SELECT 
        S.[StoreKey],
        SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue
    FROM [dbo].[Sales] AS S
    LEFT JOIN [dbo].[Products] AS P 
        ON S.[ProductKey] = P.[ProductKey]
    GROUP BY S.StoreKey
)
SELECT TOP 1 [StoreKey], [Revenue] 
FROM CTE
ORDER BY [Revenue] DESC;

--Write a query to calculate the total profit generated by each product category.

Profit=SUM(QTY*[Unit_Price_USD]-[Unit_Cost_USD])

SELECT [Category],SUM(S.[Quantity]*([Unit_Price_USD]-[Unit_Cost_USD])) AS Profit FROM [dbo].[Products] AS P 
LEFT JOIN [dbo].[Sales] AS S 
ON P.[ProductKey]=S.[ProductKey]
GROUP BY [Category]
ORDER BY Profit DESC 

--Write a query to calculate the total profit generated by customers in each country.
Expected Output (Columns):
Output Column
Country
Profit

SELECT C.[Country],SUM(S.[Quantity]*(P.[Unit_Price_USD]-P.[Unit_Cost_USD])) AS Profit 
FROM [dbo].[Customers] AS C
LEFT JOIN [dbo].[Sales] AS S 
ON C.CustomerKey=S.CustomerKey
LEFT JOIN 
[dbo].[Products]AS P 
ON S.ProductKey=P.ProductKey
GROUP BY C.[Country]
ORDER BY Profit DESC ;

---Write a query to identify the top 3 best-selling products (by revenue) within each product category,using a ranking window function such as ROW_NUMBER(), RANK(), or DENSE_RANK().


WITH CTE AS (
SELECT 
P.[Category],
P.[Product_Name],
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue,
DENSE_RANK() OVER (PARTITION BY P.[Category] ORDER BY SUM(S.[Quantity] * P.[Unit_Price_USD]) DESC) AS  RANK 
FROM [dbo].[Products] AS P
LEFT JOIN 
[dbo].[Sales] AS S
ON P.[ProductKey]=S.[ProductKey]
GROUP BY P.[Category],
P.[Product_Name]
)
SELECT Category,[Product_Name],Revenue,RANK FROM CTE WHERE RANK<=3

--Write a query to calculate each customer's age at the time they placed each order.
Expected Output (Columns):
Output Column
Name
Age

SELECT C.[Name],C.[Birthday],S.[Order_Date],DATEDIFF(YEAR,C.[Birthday],S.[Order_Date])AS AGE  FROM [dbo].[Customers] AS C
LEFT JOIN 
[dbo].[Sales]AS S 
ON C.CustomerKey=S.CustomerKey
GROUP BY C.[Name],C.[Birthday],S.[Order_Date]
ORDER BY AGE 

SELECT 
    C.[Name],
    DATEDIFF(YEAR, C.[Birthday], S.[Order_Date]) 
        - CASE 
            WHEN (MONTH(S.[Order_Date]) < MONTH(C.[Birthday])) 
              OR (MONTH(S.[Order_Date]) = MONTH(C.[Birthday]) AND DAY(S.[Order_Date]) < DAY(C.[Birthday]))
            THEN 1 ELSE 0 
          END AS Age
FROM [dbo].[Customers] AS C
LEFT JOIN [dbo].[Sales] AS S 
    ON C.[CustomerKey] = S.[CustomerKey]
 ORDER BY AGE;


---Write a query to identify customers who have made purchases from more than one store.

SELECT 
    C.[Name],
    COUNT(DISTINCT S.[StoreKey]) AS StoresVisited
FROM [dbo].[Customers] AS C
JOIN [dbo].[Sales] AS S
    ON C.[CustomerKey] = S.[CustomerKey]
GROUP BY C.[Name]
HAVING COUNT(DISTINCT S.[StoreKey]) > 1
ORDER BY StoresVisited DESC;


---Write a query to calculate total revenue generated by each store, grouped by store country and state.
Expected Output (Columns):
Output Column
Country
State
Revenue

SELECT S.[Country],S.[State],SUM(X.[Quantity] * P.[Unit_Price_USD]) AS Revenue
FROM [dbo].[Stores] AS S
LEFT JOIN 
[dbo].[Sales] AS X
ON S.StoreKey=X.StoreKey
LEFT JOIN 
[dbo].[Products] AS P 
ON X.ProductKey=P.ProductKey
GROUP BY S.[Country],S.[State]


--Write a query to calculate total revenue generated on each continent.
Expected Output (Columns):
Output Column
Continent
Revenue

SELECT C.[Continent],SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue FROM [dbo].[Customers] AS C
LEFT JOIN 
[dbo].[Sales] AS S
ON C.CustomerKey=S.CustomerKey
LEFT JOIN 
[dbo].[Products] AS P 
ON S.ProductKey=P.ProductKey
GROUP BY C.[Continent]

---Write a query to identify repeat customers, i.e., customers who have placed more than one order.

SELECT 
    C.[Name],
    COUNT(DISTINCT S.[Order_Number]) AS TotalOrders
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales] AS S
    ON C.[CustomerKey] = S.[CustomerKey]
GROUP BY C.[Name]
HAVING COUNT(DISTINCT S.[Order_Number]) > 1;

--Write a query to identify customers who have purchased products from more than one product category.

SELECT C.[Name],COUNT(DISTINCT P.[Category]) AS CategoriesPurchased FROM [dbo].[Customers] AS C
INNER JOIN
[dbo].[Sales] AS S
ON C.CustomerKey=S.[CustomerKey]
INNER JOIN 
[dbo].[Products] AS P 
ON S.ProductKey=P.ProductKey
GROUP BY C.[Name]
HAVING COUNT(DISTINCT P.[Category])>1

--Write a query to calculate total monthly sales revenue for each country.

SELECT 
YEAR(S.[Order_Date]) AS SalesYear,
MONTH(S.[Order_Date]) AS SalesMonth,
C.[Country],
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS SalesUSD
FROM [dbo].[Customers] AS C
LEFT JOIN 
[dbo].[Sales] AS S
ON C.CustomerKey=S.CustomerKey
LEFT JOIN 
[dbo].[Products] AS P 
ON S.ProductKey=P.ProductKey
GROUP BY C.[Country],YEAR(S.[Order_Date]),MONTH(S.[Order_Date]) 

--Write a query to identify the top-selling product (by quantity) in each country.
WITH CTE AS (
SELECT  [Country],[Product_Name],SUM([Quantity]) AS TotalQty,
DENSE_RANK() OVER (PARTITION BY [Country] ORDER BY SUM([Quantity]) DESC )AS RANK  
FROM [dbo].[Customers] AS C
LEFT JOIN 
[dbo].[Sales] AS S
ON C.CustomerKey=S.CustomerKey
LEFT JOIN 
[dbo].[Products] AS P 
ON S.ProductKey=P.ProductKey
GROUP BY [Country],[Product_Name]
) 
SELECT [Country],[Product_Name], TotalQty  FROM CTE 
WHERE RANK=1

---Write a query to calculate revenue, cost, profit, profit percentage, and revenue in local currency for each country.

SELECT [Country],
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS RevenueUSD,
SUM(S.[Quantity] * P.[Unit_Cost_USD]) AS CostUSD,
SUM(S.[Quantity]*([Unit_Price_USD]-[Unit_Cost_USD])) AS ProfitUSD,
( SUM(S.[Quantity]*([Unit_Price_USD]-[Unit_Cost_USD]))/(SUM(S.[Quantity] * P.[Unit_Price_USD])) )* 100 AS ProfitPercentage,
SUM(S.[Quantity] * P.[Unit_Price_USD] * [Exchange])AS RevenueLocalCurrency
FROM [dbo].[Customers] AS C
LEFT JOIN 
[dbo].[Sales] AS S
ON C.CustomerKey=S.CustomerKey
LEFT JOIN
[dbo].[Exchange_Rates] AS E
ON S.[Order_Date]=E.Date AND S.[Currency_Code]=E.Currency
LEFT JOIN 
[dbo].[Products] AS P 
ON S.ProductKey=P.ProductKey
GROUP BY [Country];

--The marketing team wants to identify high-value customers for a loyalty program. Write a query to display each customer's name, country, total number of orders, total quantity purchased, and total sales in USD, sorted by highest sales.

SELECT [Name],
[Country],
COUNT(DISTINCT [Order_Number]) AS TotalOrders,
SUM([Quantity]) AS TotalQuantity,
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS TotalSalesUSD
FROM 
[dbo].[Customers] AS C
LEFT JOIN 
[dbo].[Sales] AS S
ON C.[CustomerKey]=S.[CustomerKey]
LEFT JOIN 
[dbo].[Products] AS P 
ON S.[ProductKey]=P.[ProductKey]
GROUP BY [Name],[Country]
ORDER BY TotalSalesUSD DESC 
 
---The procurement department wants to identify products with the highest profit contribution. 
--Write a query to display product name, brand, revenue, cost, and profit, sorted by profit in descending order.

SELECT [Product_Name],[Brand],
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue,
SUM(S.[Quantity] * P.[Unit_Cost_USD]) AS Cost,
SUM(S.[Quantity]*([Unit_Price_USD]-[Unit_Cost_USD])) AS Profit
FROM [dbo].[Products] AS P 
INNER JOIN 
[dbo].[Sales] AS S 
ON P.ProductKey=S.ProductKey
GROUP BY [Product_Name],[Brand]
ORDER BY Profit DESC 

--Management wants to know which stores are generating the highest sales.
--Write a query to display total revenue for every store along with store country, state, and store size (square meters).

SELECT S.[Country],S.[State],S.[Square_Meters] ,
SUM(X.[Quantity] * P.[Unit_Price_USD]) AS Revenue
FROM [dbo].[Stores] AS S
LEFT JOIN 
[dbo].[Sales] AS X
ON S.StoreKey=X.StoreKey
LEFT JOIN 
[dbo].[Products] AS P 
ON X.ProductKey=P.ProductKey
GROUP BY S.[Country],S.[State],S.[Square_Meters]  

 --The CEO wants to identify the best-selling product category in each country.
 --Write a query to display the top-selling category (by revenue) for every customer country.
WITH CTE AS 
(
SELECT [Country],[Category],SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue,
DENSE_RANK() OVER (PARTITION BY [Country] ORDER BY SUM(S.[Quantity] * P.[Unit_Price_USD])DESC ) AS RNK 
FROM [dbo].[Customers] AS C
LEFT JOIN 
[dbo].[Sales] AS S
ON C.[CustomerKey]=S.[CustomerKey]
LEFT JOIN
[dbo].[Products] AS P 
ON S.[ProductKey]=P.[ProductKey]
GROUP BY [Country],[Category]
)
SELECT [Country],[Category],Revenue FROM CTE 
WHERE RNK=1

--Finance wants to calculate revenue in each customer's local currency. 
--Write a query to display order number, customer name, currency code, revenue in USD, and revenue in local currency.

SELECT [Order_Number],
[Name],
[Currency_Code],
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS RevenueUSD,
SUM(S.[Quantity] * P.[Unit_Price_USD] * [Exchange])AS RevenueLocal
FROM [dbo].[Sales] AS S
INNER JOIN 
[dbo].[Customers]AS C
ON S.CustomerKey=C.CustomerKey
INNER JOIN 
[dbo].[Products] AS P 
ON S.ProductKey=P.ProductKey
INNER JOIN
[dbo].[Exchange_Rates] AS E
ON S.Order_Date=E.Date AND S.[Currency_Code]=E.Currency
GROUP BY [Order_Number],
[Name],[Currency_Code]

---Write a query to find customers who have purchased products from at least three different brands.

SELECT 
    C.[Name],
    COUNT(DISTINCT P.[Brand]) AS BrandsPurchased
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales] AS S
    ON C.[CustomerKey] = S.[CustomerKey]
INNER JOIN [dbo].[Products] AS P 
    ON S.[ProductKey] = P.[ProductKey]
GROUP BY C.[Name]
HAVING COUNT(DISTINCT P.[Brand]) >= 3
ORDER BY BrandsPurchased DESC;

---Write a query to calculate the average order value for each country.
 ORDER VALUE=SUM([Quantity]*[Unit_Price_USD])
 AVG(SUM([Quantity]*[Unit_Price_USD]))


WITH CTE AS (
SELECT [Country], SUM([Quantity]*[Unit_Price_USD]) AS OrderValue
FROM [dbo].[Customers] AS C
LEFT JOIN [dbo].[Sales] AS S
ON C.[CustomerKey] = S.[CustomerKey]
LEFT JOIN [dbo].[Products] AS P 
ON S.[ProductKey] = P.[ProductKey]
GROUP BY [Country]
)
SELECT [Country] ,AVG(OrderValue) AS AvgOrderValue FROM CTE  GROUP BY [Country]

--Write a query to find the oldest customer (by birthday) who has placed at least one order.

SELECT  TOP 1 [Name],[Country],[Birthday],COUNT([Order_Number]) AS CNT 
FROM [dbo].[Customers] AS C
INNER JOIN [dbo].[Sales] AS S
ON C.[CustomerKey] = S.[CustomerKey]
GROUP BY [Name],[Country],[Birthday]
HAVING COUNT([Order_Number])>=1
ORDER BY [Birthday] 

--Write a query to display yearly revenue for each product category.

SELECT 
[Category],
YEAR([Order_Date]) AS SalesYear,
SUM([Quantity]*[Unit_Price_USD]) AS Revenue
FROM [dbo].[Products] AS P 
LEFT JOIN 
[dbo].[Sales] AS S
ON P.ProductKey=S.ProductKey
GROUP BY [Category],YEAR([Order_Date])

---Write a query to identify products that have never been sold.

SELECT 
P.[ProductKey],P.[Product_Name]
FROM [dbo].[Products] AS P 
LEFT JOIN 
[dbo].[Sales] AS S
ON P.ProductKey=S.ProductKey
WHERE S.[Order_Number] IS NULL 

---Write a query to identify stores that have never processed an order.

SELECT S.[StoreKey],S.[Country],S.[State]
FROM [dbo].[Stores]AS S
LEFT JOIN [dbo].[Sales]AS X
ON S.StoreKey=X.StoreKey
WHERE [Order_Number] IS NULL 

---Write a query to display monthly revenue for each product brand.

SELECT 
YEAR(S.[Order_Date]) AS SalesYear,
MONTH(S.[Order_Date]) AS SalesMonth,
[Brand],
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue
FROM [dbo].[Products]AS P
LEFT JOIN 
[dbo].[Sales] AS S
ON P.[ProductKey]=S.[ProductKey]
GROUP BY [Brand],YEAR(S.[Order_Date]),MONTH(S.[Order_Date])

--Write a query to identify customers whose total spending exceeds the overall average customer spending.
WITH CTE AS(

SELECT [Name],
SUM([Quantity]*[Unit_Price_USD]) AS SALES 
FROM [dbo].[Customers] AS C
INNER JOIN 
[dbo].[Sales] AS S
ON C.CustomerKey=S.CustomerKey
INNER JOIN 
[dbo].[Products] AS P 
ON S.ProductKey=P.ProductKey
GROUP BY [Name]
)
SELECT [Name],SALES 
FROM CTE 
WHERE  SALES>(AVG(SALES) )

--- Write a query to rank all stores based on their total revenue.

SELECT S.[StoreKey],S.[Country],SUM(X.[Quantity] * P.[Unit_Price_USD]) AS Revenue,
DENSE_RANK() OVER(ORDER BY SUM(X.[Quantity] * P.[Unit_Price_USD] )DESC ) AS StoreRank
FROM [dbo].[Stores] AS S
LEFT JOIN 
[dbo].[Sales] AS X
ON S.[StoreKey]=X.[StoreKey]
LEFT JOIN 
[dbo].[Products] AS P 
ON X.[ProductKey]=P.[ProductKey]
GROUP BY S.[StoreKey],S.[Country]

---Write a query to calculate each customer's percentage contribution to total company revenue.
 
 --NOTE :  TO SUM ANY VALUE IN A LIST THEN USE SUM() OVER() 

CREATE  VIEW CUST_PERCENTAGE  AS 
(
SELECT C.[Name],SUM(S.[Quantity] * P.[Unit_Price_USD])AS CUST_REVENUE,
SUM( SUM(S.[Quantity] * P.[Unit_Price_USD]) )  OVER () AS Revenue,
(
SUM(S.[Quantity] * P.[Unit_Price_USD]) /SUM( SUM(S.[Quantity] * P.[Unit_Price_USD]) )  OVER ()
) * 100 AS ContributionPercent
FROM [dbo].[Customers] AS C
LEFT JOIN 
[dbo].[Sales]AS S
ON C.CustomerKey=S.CustomerKey
LEFT JOIN 
[dbo].[Products]AS P
ON S.[ProductKey]=P.[ProductKey]
GROUP BY C.[Name]
)


SELECT * FROM [dbo].[CUST_PERCENTAGE]

---The Operations Manager wants to identify which stores consistently deliver orders the fastest.
--Write a query to display store key, country, state, total orders, and average delivery days, sorted by the fastest delivery time.

SELECT S.[StoreKey],S.[Country],S.[State],COUNT(DISTINCT X.[Order_Number]) AS TotalOrders,
AVG(DATEDIFF(DAY,X.[Order_Date],X.[Delivery_Date])) AS AvgDeliveryDays
FROM [dbo].[Stores] AS S
INNER JOIN 
[dbo].[Sales] AS X
ON S.StoreKey=X.StoreKey
GROUP BY  S.[StoreKey],S.[Country],S.[State]
ORDER BY AvgDeliveryDays

---Management wants to investigate stores with poor delivery performance. 
---Write a query to display the top 5 stores with the highest average delivery days.
Expected Output (Columns):
Output Column
StoreKey
Country
State
AvgDeliveryDays

SELECT  TOP 5 S.[StoreKey],S.[Country],S.[State],COUNT(DISTINCT X.[Order_Number]) AS TotalOrders,
AVG(DATEDIFF(DAY,X.[Order_Date],X.[Delivery_Date])) AS AvgDeliveryDays
FROM [dbo].[Stores] AS S
INNER JOIN 
[dbo].[Sales] AS X
ON S.StoreKey=X.StoreKey
GROUP BY  S.[StoreKey],S.[Country],S.[State]
ORDER BY AvgDeliveryDays DESC 

---Finance wants to know which product categories generate the highest profit margin. 
--Write a query to display category, revenue, cost, profit, and profit percentage, sorted by profit percentage in descending order.
SELECT [Category],
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue,
SUM(S.[Quantity] * P.[Unit_Cost_USD]) AS Cost,
SUM(S.[Quantity]*([Unit_Price_USD]-[Unit_Cost_USD])) AS Profit,
( SUM(S.[Quantity]*([Unit_Price_USD]-[Unit_Cost_USD]))/(SUM(S.[Quantity] * P.[Unit_Price_USD])) )* 100 AS ProfitPercentage
FROM [dbo].[Products] AS P 
INNER JOIN 
[dbo].[Sales] AS S
ON P.[ProductKey]=S.ProductKey
GROUP BY [Category] 
ORDER BY ProfitPercentage DESC 

--Marketing wants to know which brands dominate each country. 
--Write a query to display the top 5 brands (by revenue) within each country, along with their rank.

 WITH CTE AS 
 (
SELECT P.[Brand],X.[Country],SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue,
DENSE_RANK() OVER ( PARTITION BY [Country] ORDER BY SUM(S.[Quantity] * P.[Unit_Price_USD]) DESC ) AS RN 
FROM [dbo].[Products] AS P 
INNER JOIN 
[dbo].[Sales] AS S
ON P.ProductKey=S.ProductKey
INNER JOIN 
[dbo].[Stores] AS X
ON S.StoreKey=X.StoreKey
GROUP BY  P.[Brand],X.[Country]
) 
SELECT [Brand],[Country],Revenue,RN  FROM CTE WHERE RN<=5


--The CFO wants to track cumulative revenue throughout the year. 
--Write a query to display year, month, monthly revenue, and running (cumulative) revenue

SELECT 
YEAR(S.[Order_Date]) AS SalesYear,
MONTH(S.[Order_Date]) AS SalesMonth,
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue,
SUM(SUM(S.[Quantity] * P.[Unit_Price_USD]) )  OVER( ORDER BY YEAR(S.[Order_Date]),MONTH(S.[Order_Date])  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS RunningRevenue
FROM [dbo].[Sales] AS S
LEFT JOIN 
[dbo].[Products]AS P
ON P.[ProductKey]=S.[ProductKey]
GROUP BY YEAR(S.[Order_Date]),MONTH(S.[Order_Date])
ORDER BY SalesYear, SalesMonth;

 --Management wants to compare each month's revenue with the previous month.
 --Write a query to display year, month, current month revenue, previous month revenue, and month-over-month growth.

WITH CTE AS 
(
SELECT 
YEAR(S.[Order_Date]) AS SalesYear,
MONTH(S.[Order_Date]) AS SalesMonth,
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS Revenue,
LAG(SUM(S.[Quantity] * P.[Unit_Price_USD])) OVER ( ORDER BY YEAR(S.[Order_Date]),MONTH(S.[Order_Date]) ) AS PreviousMonthRevenue
FROM [dbo].[Sales] AS S
LEFT JOIN 
[dbo].[Products]AS P
ON P.[ProductKey]=S.[ProductKey]
GROUP BY YEAR(S.[Order_Date]),MONTH(S.[Order_Date])
)
SELECT SalesYear,SalesMonth,Revenue,PreviousMonthRevenue,(Revenue-PreviousMonthRevenue)/PreviousMonthRevenue *100 AS  MoMGrowth
FROM CTE 

--Write a query to find the highest-selling product color (by quantity) within each product category.

WITH CTE AS 
(
SELECT P.[Category],P.[Color],SUM(S.[Quantity]) AS Qty,
DENSE_RANK() OVER (PARTITION BY P.[Category] ORDER BY SUM(S.[Quantity]) DESC ) AS RN
FROM [dbo].[Products] AS P 
INNER JOIN 
[dbo].[Sales] AS S
ON P.ProductKey=S.ProductKey
GROUP BY  P.[Category],P.[Color]
)
SELECT Category,Color,Qty,RN FROM CTE WHERE RN=1;

--Write a query to identify customers who have made purchases in more than one store country
(e.g., customers who travel and shop internationally).
Expected Output (Columns):
Output Column
Name
CountriesPurchased

SELECT C.[Name],COUNT(DISTINCT X.[Country]) AS CountriesPurchased FROM [dbo].[Customers] AS C
INNER JOIN 
[dbo].[Sales] AS S
ON C.CustomerKey=S.CustomerKey
INNER JOIN 
[dbo].[Stores] AS X
ON S.StoreKey=X.StoreKey
GROUP BY C.[Name],X.[Country]
HAVING COUNT(DISTINCT X.[Country])>1;


---Marketing wants age-wise revenue insights. 
--Write a query to calculate total revenue by customer age group (18-25, 26-35, 36-45, 46-60, 60+) at the time of purchase.
Expected Output (Columns):
Output Column
AgeGroup
Revenue

WITH AgeCalc AS (
    SELECT 
        S.[Quantity],
        P.[Unit_Price_USD],
        DATEDIFF(YEAR, C.[Birthday], S.[Order_Date]) 
            - CASE 
                WHEN DATEADD(YEAR, DATEDIFF(YEAR, C.[Birthday], S.[Order_Date]), C.[Birthday]) > S.[Order_Date] 
                THEN 1 
                ELSE 0 
              END AS AgeAtPurchase
    FROM [dbo].[Sales] AS S
    INNER JOIN [dbo].[Customers] AS C
        ON S.[CustomerKey] = C.[CustomerKey]
    INNER JOIN [dbo].[Products] AS P
        ON S.[ProductKey] = P.[ProductKey]
)
SELECT 
    CASE 
        WHEN AgeAtPurchase BETWEEN 18 AND 25 THEN '18-25'
        WHEN AgeAtPurchase BETWEEN 26 AND 35 THEN '26-35'
        WHEN AgeAtPurchase BETWEEN 36 AND 45 THEN '36-45'
        WHEN AgeAtPurchase BETWEEN 46 AND 60 THEN '46-60'
        WHEN AgeAtPurchase > 60 THEN '60+'
        ELSE 'Under 18 / Unknown'
    END AS AgeGroup,
    SUM([Quantity] * [Unit_Price_USD]) AS Revenue
FROM AgeCalc
GROUP BY 
    CASE 
        WHEN AgeAtPurchase BETWEEN 18 AND 25 THEN '18-25'
        WHEN AgeAtPurchase BETWEEN 26 AND 35 THEN '26-35'
        WHEN AgeAtPurchase BETWEEN 36 AND 45 THEN '36-45'
        WHEN AgeAtPurchase BETWEEN 46 AND 60 THEN '46-60'
        WHEN AgeAtPurchase > 60 THEN '60+'
        ELSE 'Under 18 / Unknown'
    END
ORDER BY Revenue DESC;

--The CEO requires a single query to power an executive dashboard. 
Write a query to return total revenue (USD), total cost (USD), 
total profit (USD), profit percentage, total orders, total customers, 
total products sold, average order value, and total revenue in local currency.
Expected Output (Columns):
Output Column
TotalRevenueUSD
TotalCostUSD
TotalProfitUSD
ProfitPercentage
TotalOrders
TotalCustomers
TotalProductsSold
AverageOrderValueUSD
TotalRevenueLocalCurrency

WITH CTE AS 
(
SELECT 
SUM(S.[Quantity] * P.[Unit_Price_USD]) AS TotalRevenueUSD,
SUM(S.[Quantity] * P.[Unit_Cost_USD]) AS TotalCostUSD,
SUM(S.[Quantity]*([Unit_Price_USD]-[Unit_Cost_USD])) AS TotalProfitUSD,
( SUM(S.[Quantity]*([Unit_Price_USD]-[Unit_Cost_USD]))/(SUM(S.[Quantity] * P.[Unit_Price_USD])) )* 100 AS ProfitPercentage,
COUNT(DISTINCT S.[Order_Number]) AS TotalOrders,
COUNT(DISTINCT C.[CustomerKey]) AS TotalCustomers,
SUM(S.[Quantity]) AS TotalProductsSold
FROM [dbo].[Products] AS P 
INNER JOIN 
[dbo].[Sales] AS S
ON P.[ProductKey]=S.ProductKey
INNER JOIN 
[dbo].[Customers] AS C
ON C.[CustomerKey]=S.[CustomerKey]
),
 
LOCAL_CURRENCY AS (

SELECT (SUM(S.Quantity*P.[Unit_Price_USD]* E.Exchange)) AS TotalRevenueLocalCurrency
FROM [dbo].[Sales] AS S
LEFT JOIN 
[dbo].[Exchange_Rates] AS E
ON S.Currency_Code=E.Currency AND S.Order_Date=E.Date
LEFT JOIN 
[dbo].[Products] AS P 
ON S.ProductKey= P.[ProductKey]


)

SELECT TotalRevenueUSD,TotalCostUSD,TotalProfitUSD,ProfitPercentage,TotalOrders,TotalCustomers,TotalProductsSold,
TotalRevenueUSD/TotalOrders AS  AverageOrderValueUSD,LOCAL_CURRENCY.TotalRevenueLocalCurrency  FROM CTE CROSS JOIN  LOCAL_CURRENCY 





