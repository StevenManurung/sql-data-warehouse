
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS firstname,
	ci.cst_lastname AS lastname,
	ci.cst_marital_status AS marital_status,
	CASE 
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	CASE 
		WHEN birth_dt IS NULL THEN 'n/a'
		ELSE CONVERT(VARCHAR(10), birth_dt, 120)
	END AS birth_date,
	la.country AS country,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 as la
ON		  ci.cst_key = la.cid;

CREATE VIEW gold.dim_products AS 
SELECT 
	ROW_NUMBER() OVER (ORDER BY prd_id) AS product_key,
	cpi.prd_id AS product_id,
	-- CASE
		-- WHEN cpi.cat_id != CAST(cpi.cat_id AS VARCHAR) THEN CAST(cpi.cat_id AS VARCHAR)
		-- ELSE cpi.cat_id
	-- END AS product_id,
	cpi.cat_id AS category_id,
	cpi.prd_key AS product_number,
	cpi.prd_nm AS product_name,
	cpi.prd_cost AS cost, 
	cpi.prd_line AS line,
	CASE 
		WHEN pcg.cat IS NULL THEN 'n/a'
		ELSE pcg.cat
	END AS category,
	CASE 
		WHEN pcg.subcat IS NULL THEN 'n/a'
		ELSE pcg.subcat
	END AS sub_category,
	CASE 
		WHEN pcg.maintenance IS NULL THEN 'n/a'
		ELSE pcg.maintenance
	END AS maintenance,
	cpi.prd_start_dt AS start_dt, 
	cpi.prd_end_dt AS end_dt
FROM silver.crm_prd_info AS cpi
LEFT JOIN silver.erp_px_cat_g1v2 AS pcg
ON		  cpi.cat_id = pcg.id;

CREATE VIEW gold.fact_sales AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY sls_ord_num) AS order_id,
	sl.sls_ord_num AS order_number,
	pr.prd_key AS product_key,
	cu.cst_id AS customer_id,
	sl.sls_order_dt AS order_date,
	sl.sls_ship_dt AS ship_date,
	sl.sls_due_dt AS due_date,
	sl.sls_sales AS sales, 
	sl.sls_quantity AS quantity,
	sl.sls_price AS price
FROM silver.crm_sales_details AS sl
LEFT JOIN silver.crm_cust_info AS cu
ON sl.sls_cust_id = cu.cst_id
LEFT JOIN silver.crm_prd_info AS pr
ON sl.sls_prd_key = pr.prd_key;
