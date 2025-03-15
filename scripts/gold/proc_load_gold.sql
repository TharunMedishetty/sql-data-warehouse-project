USE DataWarehouse

/*
===============================================================================
Stored Procedure: Load Gold Layer (Silver -> Gold)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'Gold' schema tables from the 'Silver' schema.
	Actions Performed:
		- Truncates Gold tables.
		- Inserts transformed and cleansed data from Silver into Gold tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC gold.load_gold;
===============================================================================
*/


CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME

	BEGIN TRY

	    SET @batch_start_time = GETDATE();
	    PRINT '================================================';
        PRINT 'Loading Gold Layer';
        PRINT '================================================';


		-- Loading gold.dim_customers_tb
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_customers_tb';
		TRUNCATE TABLE gold.dim_customers_tb;
		PRINT '>> Inserting Data Into: gold.dim_customers_tb';

		INSERT INTO gold.dim_customers_tb
		(
			customer_key,
			customer_id,
			customer_number,
			first_name,
			last_name,
			country,
			marital_status,
			gender,
			birthdate,
			create_date  
		)
		SELECT 
			ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, ---we can use any column for creating the Surrogate Key
			ci.cst_id AS customer_id,
			ci.cst_key AS customer_number,
			ci.cst_firstname AS first_name,
			ci.cst_lastname AS last_name,
			la.cntry AS country,
			ci.cst_marital_status AS marital_status,
			CASE
				WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr  -- CRM is the master for gender info
				ELSE COALESCE(ca.gen,'n/a')
			END AS gender,
			ca.bdate AS birthdate,
			ci.cst_create_date AS create_date
		FROM silver.crm_cust_info ci
		LEFT JOIN silver.erp_cust_az12 ca
		ON        ci.cst_key = ca.cid
		LEFT JOIN silver.erp_loc_a101 la
		ON        ci.cst_key = la.cid;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR ) + ' seconds';
        PRINT '>> -------------';

		-- Loading gold.dim_products_tb
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: gold.dim_products_tb';
		TRUNCATE TABLE gold.dim_products_tb;
		PRINT '>> Inserting Data Into: gold.dim_products_tb';

		INSERT INTO gold.dim_products_tb
		(
			product_key,
			product_id,
			product_number,
			product_name,
			category_id,
			category,
			subcategory,
			cost,
			product_line,
			start_date,
			maintenance
		)
		SELECT
			ROw_NUMBER() OVER(ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key,
			pn.prd_id AS product_id ,
			pn.prd_key AS product_number,
			pn.prd_nm AS product_name,
			pn.cat_id AS category_id,
			pc.cat AS category,
			pc.subcat AS subcategory,
			pn.prd_cost AS cost,
			pn.prd_line AS product_line,
			pn.prd_start_dt AS start_date,
			pc.maintenance AS maintenance
		FROM
		silver.crm_prd_info pn
		LEFT JOIN silver.erp_px_cat_g1v2 pc
		ON pn.cat_id = pc.id
		WHERE pn.prd_end_dt IS NULL;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		-- Loading gold.dim_products_tb
		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: gold.fact_sales_tb';
		TRUNCATE TABLE gold.fact_sales_tb;
		PRINT '>> Inserting Data Into: gold.fact_sales_tb';

		INSERT INTO gold.fact_sales_tb
		(
			order_number,
			product_key,
			customer_key,
			order_date,
			shipping_date,
			due_date,
			sales_amount,
			quantity,
			price
		)
		SELECT
			sd.sls_ord_num AS order_number,
			pr.product_key,      
			cu.customer_key,
			sd.sls_order_dt AS order_date,
			sd.sls_ship_dt AS shipping_date,
			sd.sls_due_dt AS due_date,
			sd.sls_sales AS sales_amount,
			sd.sls_quantity AS quantity,
			sd.sls_price AS price
		FROM silver.crm_sales_details sd
		LEFT JOIN gold.dim_products pr
		ON		  sd.sls_prd_key = pr.product_number
		LEFT JOIN gold.dim_customers cu
		ON		  sd.sls_cust_id = cu.customer_id;

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '==========================================';
		PRINT 'Loading Gold Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================';

	END TRY
	BEGIN CATCH
		PRINT '==========================================';
		PRINT 'ERROR OCCURED DURING LOADING GOLD LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '==========================================';
	END CATCH
END

EXEC gold.load_gold
