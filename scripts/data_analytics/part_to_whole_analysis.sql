/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/
-- Which categories contribute the most to overall sales?
WITH category_sales AS (
	SELECT 
		p.category AS category,
		SUM(f.sales_amount) AS sales_amount
	FROM      gold.fact_sales_tb f
	LEFT JOIN gold.dim_products_tb p
	ON        f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY p.category ) 
SELECT
	category,
	sales_amount,
	SUM(sales_amount) OVER() AS overall_sales,
	ROUND((CAST(sales_amount AS FLOAT)/ SUM(sales_amount) OVER())*100, 2 ) AS percentage_of_total
FROM category_sales
ORDER BY percentage_of_total DESC;
