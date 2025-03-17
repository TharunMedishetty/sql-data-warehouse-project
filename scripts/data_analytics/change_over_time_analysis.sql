/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/

USE DataWarehouse
GO


-- Analyse sales performance over time
-- -- Quick Date Functions
SELECT
YEAR(order_date) as order_year,
MONTH(order_date) as order_month,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT customer_key) AS total_customers,
COUNT(DISTINCT order_number) AS total_orders
FROM
gold.fact_sales_tb
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),
		 MONTH(order_date)
ORDER BY YEAR(order_date),
		 MONTH(order_date)

-- DATETRUNC()
SELECT
DATETRUNC(month, order_date) as order_date,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT customer_key) AS total_customers,
COUNT(DISTINCT order_number) AS total_orders
FROM
gold.fact_sales_tb
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
ORDER BY DATETRUNC(month,order_date)

-- FORMAT()
SELECT
FORMAT(order_date,'yyyy-MMM') as order_date,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT customer_key) AS total_customers,
COUNT(DISTINCT order_number) AS total_orders
FROM
gold.fact_sales_tb
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'yyyy-MMM')
ORDER BY FORMAT(order_date,'yyyy-MMM')
