/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
Execution:
	SELECT * FROM gold.report_products
===============================================================================
*/

USE DataWarehouse

IF OBJECT_ID('gold.report_products','V') IS NOT NULL
	DROP VIEW gold.report_products;
GO


CREATE VIEW gold.report_products AS
	WITH base_query AS (
	/*---------------------------------------------------------------------------
	1) Base Query: Retrieves core columns from fact_sales and dim_products
	---------------------------------------------------------------------------*/
		SELECT
			p.product_key,
			p.product_number,
			p.category,
			p.product_name,
			p.subcategory,
			p.cost,
			f.order_number,
			f.customer_key,
			f.sales_amount,
			f.quantity,
			f.order_date
		FROM 
				  gold.fact_sales_tb f
		LEFT JOIN gold.dim_products_tb p
		ON        f.product_key = p.product_key
		WHERE f.order_date IS NOT NULL),
	/*---------------------------------------------------------------------------
	2) Product Aggregations: Summarizes key metrics at the product level
	---------------------------------------------------------------------------*/
			product_aggregations AS(
			SELECT
				product_key,
				product_number,
				category,
				product_name,
				subcategory,
				cost,
				COUNT(DISTINCT order_number)                                    AS total_orders,
				SUM(sales_amount)                                               AS total_sales,
				SUM(quantity)	                                                AS total_quantity		,
				COUNT(customer_key)                                             AS total_customers,    
				MAX(order_date)                                                 AS last_order_date,
				DATEDIFF(MONTH, MIN(order_date), MAX(order_date))               AS lifespan,
				ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
			FROM base_query
			GROUP BY 
				product_key,
				product_number,
				category,
				product_name,
				subcategory,
				cost)
	SELECT 
		product_key,
		product_number,
		category,
		product_name,
		subcategory,
		cost
		total_orders,
		total_sales,
		avg_selling_price,
		total_quantity		,
		total_customers,    
		last_order_date,
		lifespan,
		-- recency
		DATEDIFF(MONTH, last_order_date, GETDATE() )  AS recency_in_months,
		-- product segment
		CASE
			WHEN total_sales > 50000  THEN 'High-Performer'
			WHEN total_sales >= 10000 THEN 'Mid-Range'
			ELSE 'Low-Performer'
		END AS product_segment,
		-- Average Order Revenue (AOR)
		CASE 
			WHEN total_orders = 0 THEN 0
			ELSE total_sales / total_orders
		END AS avg_order_revenue,
		-- Average Monthly Revenue
		CASE
			WHEN lifespan = 0 THEN total_sales
			ELSE total_sales / lifespan
		END AS avg_monthly_revenue
	FROM 
	product_aggregations;

--Execution
SELECT * FROM gold.report_products
