/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/

-- Calculate the total sales per year 
-- and the running total of sales over time 
SELECT
order_year,
total_sales,
SUM(total_sales)    OVER (ORDER BY order_year) AS running_total_sales,
AVG(average_sales)  OVER (ORDER BY order_year) AS moving_average_sales
FROM
	( SELECT
		DATETRUNC(YEAR,order_date) AS order_year,
		SUM(sales_amount) AS total_sales,
		AVG(sales_amount) AS average_sales
	FROM gold.fact_sales_tb
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(YEAR,order_date) ) t
