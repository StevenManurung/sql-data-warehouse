/*
  =========================================================================================
  STORED PROCEDURE: Load Bronze Layer (Source -> Bronze)
  =========================================================================================
  Script Purpose:
    This Stored procedure loads data into 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the 'BULK INSERT' command to load data from csv files into bronze layers

  Usage Examples
    EXEC bronze.load_bronze;
*/

USE DataWarehouse;

-- MEMBUAT KEDALAM SEBUAH PROSEDUR AGAR LEBIH MUDAH DIJALANKAN DAN DILIHAT
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT('================================================================================');
		PRINT('LOADING BRONZE LAYER');
		PRINT('================================================================================');

		PRINT('--------------------------------------------------------------------------------');
		PRINT('LOADING CRM TABLES');
		PRINT('--------------------------------------------------------------------------------');
		-- DELETE DATA SEBELUM INSERT DATA (PASTIKAN DATA KOSONG KARENA AKAN KETIMPA)
		SET @start_time = GETDATE();
		PRINT('>> TRUNCATE TABLE : bronze.crm_cust_info');
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT('>> INSERTING DATA INTO : bronze.crm_cust_info');
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\steve\data-engineer\sql-data-warehouse\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK -- SELAMA INSERT BERJALAN, USER ATAU APK LAIN TIDAK BISA MELAKUKAN DML
		);
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('--------------------');

		SET @start_time = GETDATE();
		PRINT('>> TRUNCATE TABLE : bronze.crm_prd_info');
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT('>> INSERTING DATA INTO : bronze.crm_prd_info');
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\steve\data-engineer\sql-data-warehouse\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('--------------------');

		SET @start_time = GETDATE();
		PRINT('>> TRUNCATE TABLE : bronze.crm_sales_details');
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT('>> INSERTING DATA INTO : bronze.crm_sales_details');
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\steve\data-engineer\sql-data-warehouse\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT('>> LOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('--------------------');

		PRINT('--------------------------------------------------------------------------------');
		PRINT('LOADING ERP TABLES');
		PRINT('--------------------------------------------------------------------------------');
		SET @start_time = GETDATE();
		PRINT('>> TRUNCATE TABLE : bronze.erp_cust_az12');
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT('>> INSERTING DATA INTO : bronze.erp_cust_az12');
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\steve\data-engineer\sql-data-warehouse\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('--------------------');

		PRINT('>> TRUNCATE TABLE : bronze.erp_loc_a101');
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT('>> INSERTING DATA INTO : bronze.erp_loc_a101');
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\steve\data-engineer\sql-data-warehouse\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('--------------------');

		SET @start_time = GETDATE();
		PRINT('>> TRUNCATE TABLE : bronze.erp_px_cat_g1v2');
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT('>> INSERTING DATA INTO : bronze.erp_px_cat_g1v2');
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\steve\data-engineer\sql-data-warehouse\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT('LOAD DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('--------------------');
		SET @batch_end_time = GETDATE();
		PRINT('TOTAL LOAD DURATION : ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS VARCHAR) + ' seconds');
		PRINT('--------------------');
	END TRY
	BEGIN CATCH
		PRINT('============================================');
		PRINT('ERROR OCCURED DURING LOADING BRONZE LAYER');
		PRINT('Error Message ' + ERROR_MESSAGE());
		PRINT('Error Message ' + CAST(ERROR_NUMBER() AS VARCHAR));
		PRINT('Error Message ' + CAST(ERROR_STATE() AS VARCHAR));
		PRINT('============================================');
	END CATCH
END
