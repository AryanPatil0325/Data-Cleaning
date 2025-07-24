CREATE DATABASE DS_Jobs;
USE DS_Jobs;

-- CREATING A BACKUP TABLE
CREATE TABLE [dbo].[Uncleaned_DS_jobs_backup](
	[index] [int] NOT NULL,
	[Job_Title] [nvarchar](100) NULL,
	[Salary_Estimate] [nvarchar](50) NULL,
	[Job_Description] [nvarchar](max) NULL,
	[Rating] [float] NULL,
	[Company_Name] [nvarchar](100) NULL,
	[Location] [nvarchar](50) NULL,
	[Headquarters] [nvarchar](50) NULL,
	[Size] [nvarchar](50) NULL,
	[Founded] [int] NULL,
	[Type_of_ownership] [nvarchar](100) NULL,
	[Industry] [nvarchar](100) NULL,
	[Sector] [nvarchar](100) NULL,
	[Revenue] [nvarchar](100) NULL,
	[Competitors] [nvarchar](100) NULL,
 CONSTRAINT [PK_Uncleaned_DS_jobs_backup] PRIMARY KEY CLUSTERED 
(
	[index] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

-- INSERTING DATA INTO BACKUP TABLE
INSERT INTO [dbo].[Uncleaned_DS_jobs_backup]
SELECT * FROM [dbo].[Uncleaned_DS_jobs];

-- CHECK FOR NULLS 

DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += 'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, 
    COUNT(*) - COUNT([' + COLUMN_NAME + ']) AS NullCount 
    FROM Uncleaned_DS_jobs_backup UNION ALL '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Uncleaned_DS_jobs_backup';

-- Remove final UNION ALL
SET @sql = LEFT(@sql, LEN(@sql) - 10);

EXEC sp_executesql @sql;


-- VIEWING THE DATASET
SELECT
	* 
FROM Uncleaned_DS_jobs_backup;


-- CHECK FOR DUPLICATES
WITH CTE AS (
SELECT * ,
		ROW_NUMBER() OVER(PARTITION BY [index],Job_Title,Salary_Estimate,Job_Description,Rating,Company_Name,
		Location,Headquarters,Size,Founded,Type_of_ownership,Industry,Sector,Revenue,Competitors ORDER BY [index]) AS row_num
FROM Uncleaned_DS_jobs_backup
)
select * from CTE WHERE row_num > 1


-- JOB_TITLE COLUMN
SELECT
	DISTINCT Job_Title
FROM Uncleaned_DS_jobs_backup;

SELECT
	DISTINCT Job_Title
FROM Uncleaned_DS_jobs_backup
WHERE Job_Title LIKE '%Data Scientist%';

-- REPLACED Sr TO Senior
UPDATE Uncleaned_DS_jobs_backup
SET Job_Title = REPLACE(REPLACE(REPLACE(Job_Title,'Sr ','Senior '),'Sr. ','Senior '),'(Sr.) ','Senior ')
WHERE Job_Title LIKE 'Sr%' OR Job_Title LIKE 'Sr.%' Or Job_Title LIKE '(Sr.)%'

UPDATE Uncleaned_DS_jobs_backup
SET Job_Title = CASE WHEN RIGHT(Job_Title,1) = '-' THEN LEFT(Job_Title,LEN(Job_Title)-1) ElSE Job_Title END
WHERE Job_Title LIKE '%-';



-- Company_Name Column 
SELECT * FROM Uncleaned_DS_jobs_backup;


SELECT 
	Company_Name,
	LEFT(Company_Name,LEN(Company_Name)-3)
FROM Uncleaned_DS_jobs_backup
WHERE Rating NOT IN (
						SELECT 
							DISTINCT Rating
						FROM Uncleaned_DS_jobs_backup
						WHERE Rating = -1 
)

UPDATE Uncleaned_DS_jobs_backup
SET Company_Name = LEFT(Company_Name,LEN(Company_Name)-3)
WHERE Rating NOT IN (
						SELECT 
							DISTINCT Rating
						FROM Uncleaned_DS_jobs_backup
						WHERE Rating = -1 
)


-- RATING COLUMN
SELECT DISTINCT Rating FROM Uncleaned_DS_jobs_backup

UPDATE Uncleaned_DS_jobs_backup
SET Rating = 0 
WHERE Rating = -1


-- CREATING COLUMNS FOR MIN AND MAX SALARY 
ALTER TABLE Uncleaned_Ds_jobs_backup
ADD Minimum_Salary INT

ALTER TABLE Uncleaned_Ds_jobs_backup
ADD Maximum_Salary INT

SELECT Salary_Estimate FROM Uncleaned_DS_jobs_backup

SELECT '$137K-$171K (Glassdoor est.)',
REPLACE(REPLACE('$137K-$171K (Glassdoor est.)','$',''),'(Glassdoor est.)',''),
SUBSTRING('137K-171K',CHARINDEX('-','137K-171K')+1,LEN('137K-171K')),
LEFT('137K-171K',CHARINDEX('-','137K-171K')-1)
SELECT '$13K-$17K (Glassdoor est.)',
REPLACE(REPLACE('$13K-$17K (Glassdoor est.)','$',''),'(Glassdoor est.)',''),
SUBSTRING('13K-17K',CHARINDEX('-','13K-17K')+1,LEN('13K-17K')),
LEFT('13K-17K',CHARINDEX('-','13K-17K')-1)

SELECT 
	Salary_Estimate,
	REPLACE(REPLACE(Salary_Estimate,'$',''),'(Glassdoor est.)',''),
	SUBSTRING(Salary_Estimate,CHARINDEX('-',Salary_Estimate)+1,LEN(Salary_Estimate)),
	LEFT(Salary_Estimate,CHARINDEX('-',Salary_Estimate)-1)
FROM Uncleaned_DS_jobs_backup;



WITH CTE AS (
    SELECT 
        *,
        REPLACE(REPLACE(REPLACE(REPLACE(Salary_Estimate, '$', ''), '(Glassdoor est.)', ''), '(Employer est.)', ''), 'K', '') AS clean
    FROM Uncleaned_DS_jobs_backup
),
CTE2 AS (
    SELECT 
        [index],  -- Assuming this is your primary key
        TRY_CAST(LEFT(clean, CHARINDEX('-', clean) - 1) AS INT) * 1000 AS MinimumSalary,
        TRY_CAST(SUBSTRING(clean, CHARINDEX('-', clean) + 1, LEN(clean)) AS INT) * 1000 AS MaximumSalary
    FROM CTE
    WHERE CHARINDEX('-', clean) > 0  -- Ensures only rows with a dash are processed
)

UPDATE u
SET 
    Minimum_Salary = c.MinimumSalary,
    Maximum_Salary = c.MaximumSalary
FROM Uncleaned_DS_jobs_backup u
JOIN CTE2 c ON u.[index] = c.[index];

SELECT 
	*
FROM Uncleaned_DS_jobs_backup


-- AGE OF COMPANY 
SELECT 
	YEAR(GETDATE()) - Founded as Age
FROM Uncleaned_DS_jobs_backup

ALTER TABLE Uncleaned_Ds_jobs_backup
ADD Age_Company INT

UPDATE Uncleaned_DS_jobs_backup
SET Age_Company = YEAR(GETDATE()) - Founded 
WHERE Founded IS NOT NULL AND Founded > 0

UPDATE Uncleaned_DS_jobs_backup
SET Age_Company = 0 
where Age_company IS NULL 

-- DROPPING COLUMNS -- Founded , Competitors
ALTER TABLE Uncleaned_Ds_jobs_backup
DROP COLUMN Founded,Competitors
