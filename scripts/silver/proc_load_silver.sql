EXEC silver.load_silver;

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		SET @start_time = GETDATE();
		PRINT('================================================================================');
		PRINT('LOADING SILVER LAYER');
		PRINT('================================================================================');

		PRINT('--------------------------------------------------------------------------------');
		PRINT('LOADING CRM TABLES');
		PRINT('--------------------------------------------------------------------------------');
		-- INSERT TO ALL TABLE IN SILVER LAYER
		PRINT('Truncating Table: silver.crm_cust_info');
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT('Inserting Data Into : silver.crm_cust_info');
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			-- select unwanted spaces (cst_firstname, cst_lastname)
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				ELSE 'n/a'
			END cst_marital_status,
			CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				 ELSE 'n/a'
			END cst_gndr,
			cst_create_date
		FROM(
			-- selected unique and not null PK (cst_id)
			SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM BRONZE.crm_cust_info
			) t
		WHERE flag_last = 1 AND cst_id IS NOT NULL;
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('--------------------');

		SET @start_time = GETDATE();
		PRINT('Truncating Table : silver.crm_prd_info');
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT('Inserting Data Into : silver.crm_prd_info');
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key, 
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		) SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
			TRIM(prd_nm) AS prd_nm, 
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'M' THEN 'Mountain'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line,
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' second');
		PRINT('--------------------');

		SET @start_time = GETDATE();
		PRINT('Truncating Table : silver.crm_sales_details');
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT('Inserting Data Into : silver.crm_sales_details');
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key, 
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt, 
			sls_due_dt, 
			sls_sales,
			sls_quantity,
			sls_price
		)
		-- check invalid data type from sls_order_dt, sls_ship_dt, sls_due_dt
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
			END AS sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
			END AS sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
			END AS sls_due_dt,
			CASE
				WHEN sls_sales < 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) 
					THEN sls_quantity * ABS(sls_price) 
			 ELSE sls_sales
			END AS sls_sales,
			CASE 
				WHEN sls_quantity < 0 OR sls_quantity IS NULL OR sls_quantity != ABS(sls_sales) / ABS(sls_price)
					THEN ABS(sls_sales) / ABS(sls_price)
				ELSE sls_quantity
			END AS sls_quantity,
			CASE
				WHEN sls_price < 0 OR sls_price IS NULL OR sls_price != ABS(sls_sales) / sls_quantity
					THEN ABS(sls_sales) / sls_quantity
				ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' second');
		PRINT('--------------------');

		SET @start_time = GETDATE();
		PRINT('--------------------------------------------------------------------------------');
		PRINT('LOADING CRM TABLES');
		PRINT('--------------------------------------------------------------------------------');
		PRINT('Truncating Table : silver.erp_cust_az12');
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT('Inserting Data Into : silver.erp_cust_az12');
		INSERT INTO silver.erp_cust_az12(
			cid, 
			birth_dt, 
			gen
		)
		SELECT
			CASE
				WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
				ELSE CID
			END AS CID,
			CASE 
				WHEN BDATE > GETDATE() THEN NULL
				ELSE BDATE
			END AS BDATE,
			CASE
				WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
			END AS GEN
		FROM bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' second');
		PRINT('--------------------');

		SET @start_time = GETDATE();
		PRINT('Truncating Table : silver.erp_loc_a101');
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT('Inserting Data Into : silver.erp_loc_a101');
		INSERT INTO silver.erp_loc_a101(
			cid,
			country
		)
		SELECT
			REPLACE (CID, '-', '') AS CID,
			CASE 
				WHEN CNTRY IS NULL OR TRIM(CNTRY) = '' THEN 'n/a'
				WHEN TRIM(CNTRY) = 'US' THEN 'United States'
				WHEN TRIM(CNTRY) = 'USA' THEN 'United States'
				WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
				ELSE TRIM(CNTRY)
			END AS CNTRY
		FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' second');
		PRINT('--------------------');

		SET @start_time = GETDATE();
		PRINT('Truncating Table : silver.erp_px_cat_g1v2');
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT('Inserting Data Into : silver.erp_px_cat_g1v2');
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			TRIM(ID) AS ID,
			TRIM(CAT) AS CAT,
			REPLACE(TRIM(SUBCAT), '-', ' ') AS SUBCAT, 
			TRIM(MAINTENANCE) AS MAINTENANCE
		FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' second');
		PRINT('--------------------');
		SET @batch_end_time = GETDATE();
		PRINT('LOAD BATCH DURATION : ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS VARCHAR) + ' second');
	END TRY
	BEGIN CATCH
		PRINT('=====================');
		PRINT(' Error Message ' + ERROR_MESSAGE());
		PRINT(' Error Message ' + CAST(ERROR_NUMBER() AS VARCHAR));
		PRINT(' Error Message ' + CAST(ERROR_STATE() AS VARCHAR));
		PRINT('=====================');
	END CATCH
END
