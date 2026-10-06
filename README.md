# Business Sales Analytics using SQL Server

A scenario-based SQL Server analytics project for retail sales analysis across customers, products, stores, and currencies.

## Project Overview

This project uses a star-style analytical model with:

- **1 fact table:** Sales
- **5 related/dimensional tables:** Customers, Products, Stores, Exchange Rates, plus the product/customer/store attributes used for analysis
- **50 scenario-based SQL questions** covering business reporting, customer analytics, product analysis, profitability, delivery performance, ranking, and time-series analysis.

The uploaded scenario document defines the relationships between Sales and the Customer, Product, Store, and Exchange Rates tables, including the currency conversion logic. 

## Objectives

- Analyze sales revenue, cost, and profit
- Convert USD revenue to local currencies using date- and currency-matched exchange rates
- Identify high-value and repeat customers
- Rank products, brands, categories, and stores
- Analyze delivery performance
- Calculate monthly/yearly trends
- Use SQL Server window functions for ranking, running totals, and month-over-month analysis
- Build an executive-level KPI query

## Dataset Inventory

| Dataset | Approx. rows | Purpose |
|---|---:|---|
| Sales.csv | 62,884 | Sales fact data |
| Customers.csv | 15,266 | Customer attributes |
| Products.csv | 2,517 | Product, brand, category, price and cost |
| Stores.csv | 67 | Store geography and size |
| Exchange_Rates.csv | 11,215 | Date/currency exchange rates |
| Data_Dictionary.csv | 37 | Field definitions |

## Data Model

```text
Customers
   │
   │ CustomerKey
   ▼
 Sales ───────────── ProductKey ─────────────► Products
   │
   │ StoreKey
   ▼
 Stores

Sales.Currency Code + Sales.Order Date
              │
              ▼
       Exchange Rates
       Currency + Date
```

## Currency Conversion Logic

The exchange-rate table is defined relative to USD:

- **Local Amount = USD Amount × Exchange Rate**
- **USD Amount = Local Amount ÷ Exchange Rate**
- **Sales Amount USD = Quantity × Unit Price USD**

The SQL scenarios use the applicable currency and order date to look up the exchange rate.

## SQL Techniques Demonstrated

- INNER JOIN
- LEFT JOIN
- CTEs
- GROUP BY / HAVING
- CASE expressions
- Subqueries
- Aggregations
- ROW_NUMBER()
- RANK()
- DENSE_RANK()
- SUM() OVER()
- LAG()
- DATEDIFF()
- Date-based analysis
- Running totals
- Month-over-month growth
- Contribution percentages
- Customer segmentation
- Multi-dimensional analysis
- Multi-currency calculations

## Scenario Coverage

The 50 scenarios include:

1. Sales/customer/product joins
2. Customer and country analysis
3. Store/category quantity analysis
4. Total USD revenue
5–7. Multi-currency conversion
8. Top customers
9. Best-selling product by category
10–11. Delivery-time analysis
12. Top brands
13. Highest-revenue store
14–15. Profit analysis
16. Top 3 products by category
17. Customer age at purchase
18. Multi-store customers
19–20. Geographic/continent revenue
21. Repeat customers
22. Multi-category customers
23. Monthly country sales
24. Top product by country
25. Country-level revenue/cost/profit/margin
26. Loyalty-program candidates
27. Product profit contribution
28. Store sales with size
29. Best category by country
30. Local-currency revenue
31. Multi-brand customers
32. Average order value
33. Oldest purchasing customer
34. Yearly category revenue
35–36. Unsold products / inactive stores
37. Monthly brand revenue
38. Customers above average spending
39. Store revenue ranking
40. Customer revenue contribution
41–42. Store delivery performance
43. Category profit margin
44. Top brands by country
45. Running revenue
46. Month-over-month growth
47. Top product color by category
48. International/multi-country shoppers
49. Revenue by customer age group
50. Executive dashboard KPI query

## Repository Structure

```text
business-sales-analytics-sql/
│
├── README.md
│
├── sql/
│   └── business_sales_analytics_queries.sql
│
├── data/
│   ├── Customers.csv
│   ├── Products.csv
│   ├── Sales.csv
│   ├── Stores.csv
│   └── Exchange_Rates.csv
│
└── docs/
    ├── Data_Dictionary.csv
    └── SQL_Scenario_Based_Questions.docx
```

## How to Use

1. Import the CSV files into SQL Server.
2. Create/import the five tables using your preferred SQL Server import workflow.
3. Keep the table and column names consistent with the SQL script. The supplied SQL script uses SQL Server-style names such as `Order_Number`, `Order_Date`, `Unit_Price_USD`, and `Currency_Code`.
4. Run the queries in `sql/business_sales_analytics_queries.sql`.
5. Use `docs/Data_Dictionary.csv` to understand the source fields.
6. Use `docs/SQL_Scenario_Based_Questions.docx` to review the business questions and expected output columns.

## Important Note

This repository contains the project dataset and SQL scripts used for portfolio/demo purposes. Do not add passwords, API keys, connection strings, or other secrets to the repository.

## Skills

**SQL Server · T-SQL · Data Analysis · Business Analytics · Joins · CTEs · Window Functions · Aggregations · Customer Analytics · Product Analytics · Profitability Analysis · Time-Series Analysis · Multi-Currency Analysis**
