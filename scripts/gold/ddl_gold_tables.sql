/*
===============================================================================
DDL Script: Create Gold Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'gold' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'Gold' Tables
===============================================================================
*/

USE DataWarehouse


--=======================================
-->>gold.dim_customers_tb<<--
--=======================================
IF OBJECT_ID('gold.dim_customers_tb','U') IS NOT NULL
	DROP TABLE gold.dim_customers_tb
GO

CREATE TABLE gold.dim_customers_tb
(
customer_key      INT,
customer_id       INT,
customer_number   NVARCHAR(50),
first_name        NVARCHAR(50),
last_name         NVARCHAR(50),
country           NVARCHAR(50),
marital_status    NVARCHAR(50),
gender            NVARCHAR(50),
birthdate         DATE,
create_date       DATE
);
GO

--=======================================
-->>gold.dim_products_tb<<--
--=======================================

IF OBJECT_ID('gold.dim_products_tb','U') IS NOT NULL
	DROP TABLE gold.dim_products_tb
GO

CREATE TABLE gold.dim_products_tb
(
product_key       INT,
product_id        INT,
product_number    NVARCHAR(50),
product_name      NVARCHAR(50),
category_id       NVARCHAR(50),
category          NVARCHAR(50),
subcategory       NVARCHAR(50),
cost              INT,
product_line      NVARCHAR(50),
start_date        DATE,
maintenance       NVARCHAR(50)
);
GO

--=======================================
-->>gold.fact_sales_tb<<--
--=======================================

IF OBJECT_ID('gold.fact_sales_tb','U') IS NOT NULL
	DROP TABLE gold.fact_sales_tb
GO

CREATE TABLE gold.fact_sales_tb
(
order_number      NVARCHAR(50),
product_key       INT,
customer_key      NVARCHAR(50),
order_date        DATE,
shipping_date     DATE,
due_date          DATE,
sales_amount      INT,
quantity          INT,
price             INT
);
GO
