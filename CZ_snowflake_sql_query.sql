-----Czechoslovakia Bank Data Analysis----
--CREATE DATATBASE BANK--
CREATE WAREHOUSE BANK_WH;
CREATE DATABASE BANK;
USE DATABASE BANK;

CREATE SCHEMA BANK_SCHEMA;
USE SCHEMA BANK_SCHEMA;

-- CREATE TABLES
CREATE OR REPLACE TABLE DISTRICT(
District_Code INT PRIMARY KEY,
District_Name VARCHAR(100),
Region VARCHAR(60),
No_of_inhabitants INT,
No_of_municipalities_with_inhabitants_less_499 INT,
No_of_municipalities_with_inhabitants_500_btw_1999	INT,
No_of_municipalities_with_inhabitants_2000_btw_9999	INT,
No_of_municipalities_with_inhabitants_less_10000 INT,	
No_of_cities	INT,
Ratio_of_urban_inhabitants	FLOAT,
Average_salary	INT,
No_of_entrepreneurs_per_1000_inhabitants INT,
No_committed_crime_2017	INT,
No_committed_crime_2018 INT);

CREATE OR REPLACE TABLE ACCOUNT(
Account_id INT PRIMARY KEY,
District_id	INT,
Frequency	VARCHAR(50),
Date DATE ,
Account_Type VARCHAR(50),
Card_Assigned VARCHAR(40),
FOREIGN KEY (District_id) REFERENCES DISTRICT(District_Code));

CREATE OR REPLACE TABLE LOAN(
Loan_id	INT ,
Account_id INT,
Date DATE,
Amount INT,
Duration INT,
Payments INT,
Status VARCHAR(30),
FOREIGN KEY (Account_id) REFERENCES ACCOUNT(Account_id));

CREATE OR REPLACE TABLE TRANSACTIONS(
Trans_id INT,	
Account_id INT,
Date DATE,
Type VARCHAR(40),
Operation VARCHAR(40),
Amount INT,
Balance	FLOAT,
Purpose	VARCHAR(40),
Bank VARCHAR(40),
Account_partern_id INT,
FOREIGN KEY (Account_id) REFERENCES ACCOUNT(Account_id));

CREATE OR REPLACE TABLE CLIENT(
Client_id INT PRIMARY KEY,
Gender	VARCHAR(10),
Birth_date	DATE,
District_id INT,
FOREIGN KEY (District_id) REFERENCES DISTRICT(District_Code));

CREATE OR REPLACE TABLE DISPOSITION(
Disp_id	INT PRIMARY KEY,
Client_id INT,
Account_id	INT,
Type VARCHAR(15),
FOREIGN KEY (Account_id) REFERENCES ACCOUNT(Account_id),
FOREIGN KEY (Client_id) references CLIENT(Client_id));

CREATE OR REPLACE TABLE CARD(
Card_id	INT PRIMARY KEY,
Disp_id	INT,
Type VARCHAR(20),
Issued DATE,
FOREIGN KEY (Disp_id) REFERENCES DISPOSITION(Disp_id));

CREATE OR REPLACE TABLE ORDER1(
Order_id INT,
Account_id INT,
Bank_to VARCHAR(50),
Account_to INT,
Amount FLOAT,
FOREIGN KEY (Account_id) REFERENCES ACCOUNT(Account_id));

SELECT * FROM DISTRICT;
SELECT * FROM ACCOUNT;
SELECT * FROM LOAN;
SELECT * FROM CARD;
SELECT * FROM CLIENT;
SELECT * FROM DISPOSITION;
SELECT * FROM ORDER1;
SELECT * FROM TRANSACTIONS;
---------------------------------------------
--CREATE CLOUD STORAGE INTEGRATION FOR S3--------

CREATE or REPLACE STORAGE INTEGRATION  s3_int
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::084375574474:role/BANK-ROLE'
STORAGE_ALLOWED_LOCATIONS = ('s3://cz-bank-bucket/');


---- DESCRIBE STORAGE INTEGRASTION----

DESC INTEGRATION  s3_int;
  
----- CREATE EXTERNAL STAGE THAT REFERANCES YOUR (AWS) S3 BUCKET------
CREATE OR REPLACE FILE FORMAT BANKCSV
TYPE = CSV
FIELD_DELIMITER = ','
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1;

CREATE OR REPLACE STAGE BANKSTAGE
URL =  's3://cz-bank-bucket/'     --  (Name of your bucket)
FILE_FORMAT = BANKCSV
STORAGE_INTEGRATION = s3_int;

--Creating a new S3 event notification to automate Snowpipe
-- create separate Snowpipes for each dataset.--

CREATE OR REPLACE PIPE SNOWPIPE_ACCOUNT 
AUTO_INGEST = TRUE 
AS COPY INTO BANK.BANK_SCHEMA.ACCOUNT --table name that you created in snowflake)
FROM @BANKSTAGE/ACCOUNT          ---------s3 bucket subfolder name
FILE_FORMAT = BANKCSV;

CREATE OR REPLACE PIPE SNOWPIPE_CARD 
AUTO_INGEST = TRUE 
AS COPY INTO BANK.BANK_SCHEMA.CARD 
FROM @BANKSTAGE/CARD
FILE_FORMAT = BANKCSV;

CREATE OR REPLACE PIPE SNOWPIPE_CLIENT 
AUTO_INGEST = TRUE 
AS COPY INTO BANK.BANK_SCHEMA.CLIENT 
FROM @BANKSTAGE/CLIENT
FILE_FORMAT = BANKCSV;

CREATE OR REPLACE PIPE SNOWPIPE_DISPOSITION 
AUTO_INGEST = TRUE 
AS COPY INTO BANK.BANK_SCHEMA.DISPOSITION 
FROM @BANKSTAGE/DISPOSITION
FILE_FORMAT = BANKCSV;

CREATE OR REPLACE PIPE SNOWPIPE_DISTRICT 
AUTO_INGEST = TRUE 
AS COPY INTO BANK.BANK_SCHEMA.DISTRICT 
FROM @BANKSTAGE/DISTRICT
FILE_FORMAT = BANKCSV;

CREATE OR REPLACE PIPE SNOWPIPE_LOAN 
AUTO_INGEST = TRUE 
AS COPY INTO BANK.BANK_SCHEMA.LOAN
FROM @BANKSTAGE/LOAN
FILE_FORMAT = BANKCSV;

CREATE OR REPLACE PIPE SNOWPIPE_ORDER 
AUTO_INGEST = TRUE 
AS COPY INTO BANK.BANK_SCHEMA.ORDER1 
FROM @BANKSTAGE/ORDER1
FILE_FORMAT = BANKCSV;

CREATE OR REPLACE PIPE SNOWPIPE_TRANSACTIONS 
AUTO_INGEST = TRUE 
AS COPY INTO BANK.BANK_SCHEMA.TRANSACTIONS  
FROM @BANKSTAGE/TRANSACTIONS 
FILE_FORMAT = BANKCSV;
--------now create event notification in s3 bucket-------------
SHOW PIPES;
------------------------------
SELECT SYSTEM$PIPE_STATUS('SNOWPIPE_ACCOUNT');
desc pipe SNOWPIPE_ACCOUNT;
SHOW STORAGE INTEGRATIONS;

-------------------------------------------------------------------------------------------
--ALTER PIPE SNOWPIPE_ACCOUNT RESUME;------(Run if pipe is suspended)

ALTER PIPE SNOWPIPE_ACCOUNT REFRESH;
ALTER PIPE SNOWPIPE_CARD REFRESH;
ALTER PIPE SNOWPIPE_CLIENT REFRESH;
ALTER PIPE SNOWPIPE_DISPOSITION REFRESH;
ALTER PIPE SNOWPIPE_DISTRICT REFRESH;
ALTER PIPE SNOWPIPE_LOAN REFRESH;
ALTER PIPE SNOWPIPE_ORDER REFRESH;
ALTER PIPE SNOWPIPE_TRANSACTIONS REFRESH;
----------------------------------------------
SHOW PIPES;
show stages;
LIST @BANKSTAGE;
SHOW FILE FORMATS LIKE 'BANKCSV';

-------------- COUNT ALL RECORDS IN EACH TABLES----
SELECT COUNT(*) FROM ACCOUNT;
SELECT  COUNT(*) FROM CARD;
SELECT COUNT(*) FROM CLIENT;
SELECT COUNT(*) FROM DISTRICT;
SELECT COUNT(*) FROM DISPOSITION;
SELECT COUNT(*) FROM LOAN;
SELECT COUNT(*) FROM ORDER1;
SELECT COUNT(*) FROM TRANSACTIONS;
---------- Fetch data-------------

SELECT * FROM ACCOUNT LIMIT 10;
SELECT * FROM CARD LIMIT 10;
SELECT * FROM CLIENT LIMIT 10;
SELECT * FROM DISTRICT LIMIT 10;
SELECT * FROM DISPOSITION LIMIT 10;
SELECT * FROM LOAN LIMIT 10;
SELECT * FROM ORDER1 LIMIT 10;
SELECT * FROM TRANSACTIONS LIMIT 10;

SELECT Loan_id, LENGTH(Status), Status FROM LOAN;

-----ADDING AGE COLUMN TO THE CLIENT TABLE
SELECT * FROM CLIENT LIMIT 10;
ALTER TABLE CLIENT ADD AGE INT;
SELECT * FROM CLIENT LIMIT 10;

UPDATE CLIENT
SET AGE = DATEDIFF('YEAR',BIRTH_DATE,'2024-12-31');  -- age at present
SELECT * FROM CLIENT limit 10;

-----------------NEXT DATA TRANSFORMATION----------
/*
 CONVERT 2021 TXN_YEAR TO 2022
 CONVERT 2020 TXN_YEAR TO 2021
 CONVERT 2019 TXN_YEAR TO 2020
 CONVERT 2018 TXN_YEAR TO 2019
 CONVERT 2017 TXN_YEAR TO 2018
 CONVERT 2016 TXN_YEAR TO 2017 */

 SELECT YEAR(DATE),COUNT(*) AS TOTAL FROM TRANSACTIONS
 GROUP BY 1 ORDER BY 1;

 UPDATE TRANSACTIONS SET DATE= DATEADD(YEAR,1,DATE) 
 WHERE YEAR(DATE)=2021;

 UPDATE TRANSACTIONS SET DATE= DATEADD(YEAR,1,DATE) 
 WHERE YEAR(DATE)=2020;

 UPDATE TRANSACTIONS SET DATE= DATEADD(YEAR,1,DATE) 
 WHERE YEAR(DATE)=2019;

 UPDATE TRANSACTIONS SET DATE= DATEADD(YEAR,1,DATE) 
 WHERE YEAR(DATE)=2018;
 
 UPDATE TRANSACTIONS SET DATE= DATEADD(YEAR,1,DATE) 
 WHERE YEAR(DATE)=2017;

 SELECT YEAR(DATE),COUNT(*) AS TOTAL FROM TRANSACTIONS
 GROUP BY 1 ORDER BY 2 DESC;
 
 ------------- CHECK MINIMUM AND MAXIMUM DATE OF TRANSACTION ----------

 SELECT MIN(DATE),MAX(DATE) FROM TRANSACTIONS;

 ----------- FILL NULL VALUES IN TTRANSACTIONS IN BANK FOR EVERY YEARS ------
SELECT * FROM TRANSACTIONS WHERE BANK IS NULL AND YEAR(DATE)=2019;
SELECT COUNT(*) FROM TRANSACTIONS WHERE BANK IS NULL AND YEAR(DATE)=2018;--NO BLANKS
SELECT COUNT(*) FROM TRANSACTIONS WHERE BANK IS NULL AND YEAR(DATE)=2019;
SELECT COUNT(*) FROM TRANSACTIONS WHERE BANK IS NULL AND YEAR(DATE)=2020;
SELECT COUNT(*) FROM TRANSACTIONS WHERE BANK IS NULL AND YEAR(DATE)=2021;
SELECT COUNT(*) FROM TRANSACTIONS WHERE BANK IS NULL AND YEAR(DATE)=2022;

UPDATE TRANSACTIONS SET BANK='Southern BANK'  WHERE BANK IS NULL AND YEAR(DATE)=2019;--fill null in Bank
UPDATE TRANSACTIONS SET BANK='Northern BANK'  WHERE BANK IS NULL AND YEAR(DATE)=2020;--fill null in Bank
UPDATE TRANSACTIONS SET BANK='DBS BANK'  WHERE BANK IS NULL AND YEAR(DATE)=2021;
UPDATE TRANSACTIONS SET BANK='SKY BANK'  WHERE BANK IS NULL AND YEAR(DATE)=2022;

--checking null values in column PURPOSE, BANK AND ACCOUNT_PARTERN_ID
SELECT * FROM TRANSACTIONS LIMIT 10;
SELECT COUNT(*) FROM TRANSACTIONS WHERE PURPOSE IS NULL;
SELECT COUNT(*) FROM TRANSACTIONS WHERE BANK IS NULL;
SELECT COUNT(*) FROM TRANSACTIONS WHERE ACCOUNT_PARTERN_ID IS NULL;

SELECT PURPOSE , COUNT(*) TOTAL FROM txn_restore
GROUP BY 1 ORDER BY 2 DESC;

UPDATE txn_restore SET PURPOSE = 'Household' where purpose is null;

UPDATE txn_restore
SET purpose = 'Loan Payment'
WHERE TRIM(purpose) = '';

UPDATE txn_restore
SET ACCOUNT_PARTERN_ID = 123
WHERE ACCOUNT_PARTERN_ID is null;

UPDATE txn_restore
SET BANK = 'DBS BANK'
WHERE TRIM(BANK) = '';

--CALL SYSTEM$CANCEL_QUERY('01bbbbc5-3201-8dbd-000c-6a8a000b70aa');
--ROLLBACK;
CREATE OR REPLACE TABLE txn_restore AS
SELECT * FROM transactions AT (OFFSET => -60*25);  -- 5 mins ago
--------------------------------
CREATE OR REPLACE TABLE transactions AS
SELECT * FROM txn_restore;

SELECT PURPOSE , COUNT(*) TOTAL FROM transactions
GROUP BY 1 ORDER BY 2 DESC;

----- FOR CARD---
SELECT * FROM CARD;
select distinct year(issued) from card;

select distinct year(issued), count(*) as total_count from card
group by 1 order by 1;

------FOR DISTRCIT TABLE--
SELECT * FROM DISTRICT;
SELECT * FROM ACCOUNT;
SELECT DISTINCT YEAR(DATE) FROM ACCOUNT;
SELECT DISTINCT YEAR(DATE),COUNT(*) FROM ACCOUNT
GROUP BY 1 ORDER BY 1;

SELECT * FROM DISPOSITION limit 10;
SELECT * FROM ORDER1 limit 10;

---for currency
-- 1 CZK = 0.046735 USD 
-- 1 CZK = 3.836706 INR 

SELECT * FROM LOAN limit 10;
SELECT DISTINCT YEAR(DATE) FROM LOAN;
SELECT YEAR(DATE),count(*) FROM LOAN
group by 1 order by 2 DESC;


---- FOR CLIENT TABLE
SELECT * FROM client limit 10;

---FINDING MALE FEMALE CLIENT

SELECT 
SUM(CASE WHEN GENDER ='Male' THEN 1 END) AS MALE_CLIENT,
SUM(CASE WHEN GENDER ='Female' THEN 1 END) AS FEMALE_CLIENT 
FROM CLIENT;

 ---FINDING MALE FEMALE CLIENT %

SELECT 
ROUND(SUM(CASE WHEN GENDER='Male' THEN 1 END)/count(*)*100,2) AS MALE_PERC,
ROUND(SUM(CASE WHEN GENDER='Female' THEN 1 END)/COUNT(*)*100,2) AS FEMALE_PERC
FROM CLIENT;

--- AD-HOC DATA ANALYSIS IN SQL-- 

/* 1. What is the demographic profile of the bank's clients and how does it vary 
across districts? YEAR WISE COUNTS. */

SELECT * FROM CLIENT LIMIT 10;
SELECT * FROM DISTRICT LIMIT 10;

CREATE OR REPLACE TABLE CZ_DEMOGRAPHIC_DATA_KPI AS
SELECT  C.DISTRICT_ID,D.DISTRICT_NAME,D.AVERAGE_SALARY,
ROUND(AVG(C.AGE),0) AS AVG_AGE,
SUM(CASE WHEN GENDER = 'Male' THEN 1 ELSE 0 END) AS MALE_CLIENT ,
SUM(CASE WHEN GENDER = 'Female' THEN 1 ELSE 0 END) AS FEMALE_CLIENT ,
ROUND((FEMALE_CLIENT/MALE_CLIENT)*100,2) AS MALE_FEMALE_RATIO_PERC,
COUNT(*)AS TOTAL_CLIENT
FROM CLIENT C INNER JOIN DISTRICT D ON C.DISTRICT_ID = D.DISTRICT_CODE
GROUP BY 1,2,3
ORDER BY 1;

SELECT * FROM CZ_DEMOGRAPHIC_DATA_KPI;

--2. How the banks have performed over the years.Give their detailed analysis month wise?

-- Transaction per years--
SELECT YEAR(DATE) AS YEAR_DATE, COUNT(*) AS TOTAL_RECORDS FROM TRANSACTIONS 
GROUP BY 1 ORDER BY 1;

-- BANK WISE CUSTOMERS-ID
SELECT BANK, COUNT(DISTINCT ACCOUNT_ID) AS TOTAL_CUSTOMERS FROM TRANSACTIONS 
GROUP BY 1 ORDER BY 1 DESC;

UPDATE TRANSACTIONS
SET BANK = UPPER(BANK);
 
/* 3. What are the most common types of accounts and how do they differ in terms of usage 
and profitability? */

SELECT * FROM ACCOUNT LIMIT 10;
-- MOST COMMON TYPES OF ACCOUNT --

SELECT ACCOUNT_TYPE, COUNT(*) TOTAL_ACCOUNT FROM ACCOUNT
GROUP BY 1 ORDER BY 2 DESC;

SELECT FREQUENCY, COUNT(*) TOTAL_ACCOUNT FROM ACCOUNT
GROUP BY 1 ORDER BY 2 DESC;

SELECT ACCOUNT_TYPE,FREQUENCY, COUNT(*) TOTAL_ACCOUNT FROM ACCOUNT
GROUP BY 1,2 ORDER BY 3 DESC;

/*4. Which types of cards are most frequently used by the bank's clients and what is the 
overall profitability of the credit card business? */

SELECT * FROM CARD LIMIT 10;

SELECT TYPE ,COUNT(*) FROM CARD
GROUP BY 1 ORDER BY 2 DESC;

/*5. What are the major expenses of the bank and how can they be reduced to improve profitability? */


/* 6. What is the bank’s loan portfolio and how does it vary across different purposes and client segments? 


/* 7. How can the bank improve its customer service and satisfaction levels? */


/* 8. Can the bank introduce new financial products or services to attract more customers and 
increase profitability?*/ 




--------------------
