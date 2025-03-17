/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/*Segment products into cost ranges and 
count how many products fall into each segment*/
SELECT
cost_range,
COUNT(DISTINCT product_key) AS total_products
FROM
	(SELECT 
		product_key,
		product_name,
		CASE
			WHEN cost < 100 THEN 'Below 100'
			WHEN cost BETWEEN 100 AND 500  THEN '100-500'
			WHEN cost BETWEEN 500 AND 1000 THEN '500-1000' 
			WHEN cost > 1000 THEN 'Above 1000'
		END AS cost_range
	FROM
	gold.dim_products_tb) t
GROUP BY cost_range
ORDER BY total_products DESC;

----------

WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/

WITH customer_spending AS (
	SELECT
		customer_key,
		SUM(sales_amount)                                AS total_spending,
		MIN(order_date)                                  AS min_order_date,
		MAX(order_date)                                  AS max_order_date,
		DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS lifespan
	FROM 
	gold.fact_sales_tb
	GROUP BY customer_key )
SELECT 
customer_segment,
COUNT(DISTINCT customer_key) AS total_customers
FROM
	(SELECT 
		customer_key,
		total_spending,
		min_order_date,
		max_order_date,
		lifespan,
		CASE
			WHEN lifespan >= 12 and total_spending > 5000  THEN 'VIP'
			WHEN lifespan >= 12 and total_spending <= 5000 THEN 'Regular'
			ELSE 'NEW'
		END AS customer_segment
	FROM 
	customer_spending ) t
GROUP BY customer_segment
ORDER BY total_customers DESC ;
