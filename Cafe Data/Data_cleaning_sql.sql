use Cafe_cleaning;

SELECT 
	*
FROM backup_data;

-- CHECKING THE DATA TYPES
SELECT COLUMN_NAME,DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'backup_data';


-- CHECK FOR DUPLICATES
WITH DUPLICATES_CHECK AS (
SELECT
	*,
	ROW_NUMBER() OVER(PARTITION BY Transaction_ID ORDER BY Transaction_ID) AS row_num
FROM backup_data

)
SELECT * FROM DUPLICATES_CHECK where row_num > 1;


-- CHECK FOR NULLS
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, ' +
    'COUNT(*) AS NullCount ' +
    'FROM ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ' ' +
    'WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
    ' UNION ALL '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'backup_data';  -- Replace 'your_table' with your actual table name

-- Optional: To see the generated SQL
-- PRINT @SQL;

-- Execute the dynamically generated SQL
EXEC sp_executesql @SQL;


-- HANDLING NULL AND OTHERS IN  ITEMS
SELECT 
    distinct Item 
FROM backup_data
;
UPDATE backup_data  
set Item = 'Unknown'
WHERE Item in (
SELECT Item
FROM backup_data
where Item in ('UNKNOWN','ERROR'));

UPDATE backup_data
set Item = 'Unknown'
where Item IS NULL;

-- HANDLING NULL AND OTHERS IN QUANTITY
SELECT 
    distinct Quantity 
FROM backup_data

UPDATE backup_data
SET Quantity = 0
WHERE Quantity IS NULL;
-- HANDLING NULL AND OTHERS IN PRICE_PER_UNIT
SELECT 
    distinct Price_Per_Unit
FROM backup_data

UPDATE backup_data
SET Price_Per_Unit = 0
WHERE Price_Per_Unit IS NULL;
-- HANDLING NULL AND OTHERS IN TOTAL_SPENT
SELECT 
    distinct Total_Spent
FROM backup_data

UPDATE backup_data
SET Total_Spent = 0
WHERE Total_Spent IS NULL;

-- ADDING A NEW COLUMN TOTAL_AMOUNT
ALTER TABLE backup_data
ADD Total_Amount float

UPDATE backup_data
SET Total_Amount = Quantity * Price_Per_Unit

-- HANDLING NULL AND ISSUES WITH PAYMENT_METHODS
SELECT 
    distinct Payment_Method
FROM backup_data;

UPDATE backup_data
SET Payment_Method = 'Unknown'
WHERE Payment_Method is null ;

UPDATE backup_data
SET Payment_Method = 'Unknown'
WHERE Payment_Method IN (

SELECT Payment_Method FROM backup_data WHERE Payment_Method in ('UNKNOWN','ERROR')
);


-- HANDLING NULL AND OTHERS IN LOCATIONS
SELECT 
    distinct Location
FROM backup_data;

UPDATE backup_data
SET Location = 'Not Available'
WHERE Location is null ;

UPDATE backup_data
SET Location = 'Not Available'
WHERE Location IN (

SELECT Location FROM backup_data WHERE Location in ('UNKNOWN','ERROR')
);

-- HANDLING TRANSACTION_DATE
SELECT 
    DISTINCT Transaction_Date
FROM backup_data;
