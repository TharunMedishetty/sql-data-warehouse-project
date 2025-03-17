/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/
USE DataWarehouse

IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
	DROP VIEW gold.report_customers;
GO

CREATE VIEW  gold.report_customers AS
	WITH base_query AS 
	/*---------------------------------------------------------------------------
	1) Base Query: Retrieves core columns from tables
	---------------------------------------------------------------------------*/
	(
	SELECT 
		f.order_number,
		f.product_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		c.customer_key,  
		c.customer_number,
		CONCAT(c.first_name, ' ', c.last_name)           AS customer_name,
		c.birthdate,
		DATEDIFF(YEAR, c.birthdate, GETDATE())           AS age
	FROM 
			  gold.fact_sales_tb f
	LEFT JOIN gold.dim_customers_tb c
	ON		  f.customer_key = c.customer_key
	),
	/*---------------------------------------------------------------------------
	2) Customer Aggregations: Summarizes key metrics at the customer level
	---------------------------------------------------------------------------*/
		customer_aggregation AS
		(
			SELECT
				customer_key,
				customer_number,
				customer_name,
				age,
				COUNT(DISTINCT order_number)                     AS total_orders,
				SUM(sales_amount)                                AS total_sales,
				SUM(quantity)                                    AS total_quantity,
				COUNT(DISTINCT product_key)                      AS total_products,
				DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS lifespan,
				MAX(order_date)                                  AS last_order_date
			FROM
			base_query
			GROUP BY
				customer_key,
				customer_number,
				customer_name,
				age
		)
	/*---------------------------------------------------------------------------
	3) Calculations: Calculating valuable KPI's
	---------------------------------------------------------------------------*/
	SELECT
		customer_key,
		customer_number,
		customer_name,
		age,
		CASE 
			 WHEN age < 20 THEN 'Under 20'
			 WHEN age between 20 and 29 THEN '20-29'
			 WHEN age between 30 and 39 THEN '30-39'
			 WHEN age between 40 and 49 THEN '40-49'
			 ELSE '50 and above'
		END AS age_group,
		CASE
			WHEN lifespan >= 12 and total_sales > 5000  THEN 'VIP'
			WHEN lifespan >= 12 and total_sales <= 5000 THEN 'Regular'
			ELSE 'NEW'
		END AS customer_segment,
		last_order_date,
		total_orders,
		total_sales,
		total_quantity,
		total_products
		lifespan,
		-- recency
		DATEDIFF(month, last_order_date, GETDATE()) AS recency,
		-- Compuate average order value (AVO)
		CASE WHEN total_sales = 0 THEN 0
			 ELSE total_sales / total_orders
		END AS avg_order_value,
		-- Compuate average monthly spend
		CASE WHEN lifespan = 0 THEN total_sales
			 ELSE total_sales / lifespan
		END AS avg_monthly_spend
	FROM
	customer_aggregation;
