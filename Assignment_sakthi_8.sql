CREATE OR REPLACE DATABASE SQL_ADVANCED_DB;
USE DATABASE SQL_ADVANCED_DB;
CREATE OR REPLACE SCHEMA SALES;
USE SCHEMA SALES;

-- Create Employees table
CREATE OR REPLACE TABLE EMPLOYEES (
    EMPLOYEE_ID INT PRIMARY KEY,
    EMPLOYEE_NAME VARCHAR(100),
    DEPARTMENT VARCHAR(50),
    SALARY DECIMAL(10,2),
    MANAGER_ID INT,
    HIRE_DATE DATE,
    CITY VARCHAR(50)
);

-- Create Sales table
CREATE OR REPLACE TABLE SALES_TRANSACTIONS (
    TRANSACTION_ID INT PRIMARY KEY,
    EMPLOYEE_ID INT,
    SALE_DATE DATE,
    PRODUCT_CATEGORY VARCHAR(50),
    SALE_AMOUNT DECIMAL(10,2),
    QUANTITY INT,
    REGION VARCHAR(50)
);

-- Create Targets table
CREATE OR REPLACE TABLE MONTHLY_TARGETS (
    TARGET_ID INT PRIMARY KEY,
    EMPLOYEE_ID INT,
    MONTH DATE,
    TARGET_AMOUNT DECIMAL(10,2)
);

-- Insert Employees
INSERT INTO EMPLOYEES VALUES
(1, 'Rajesh Kumar', 'Sales', 75000, NULL, '2020-01-15', 'Mumbai'),
(2, 'Priya Sharma', 'Sales', 65000, 1, '2020-03-20', 'Mumbai'),
(3, 'Amit Patel', 'Sales', 60000, 1, '2021-05-10', 'Mumbai'),
(4, 'Sneha Reddy', 'Sales', 68000, 1, '2020-07-12', 'Bangalore'),
(5, 'Vikram Singh', 'Sales', 62000, 1, '2021-02-18', 'Delhi'),
(6, 'Anjali Verma', 'Marketing', 70000, NULL, '2019-11-05', 'Mumbai'),
(7, 'Rahul Nair', 'Marketing', 58000, 6, '2021-08-22', 'Bangalore'),
(8, 'Neha Gupta', 'Marketing', 55000, 6, '2022-01-10', 'Delhi'),
(9, 'Karthik Iyer', 'IT', 85000, NULL, '2018-06-15', 'Bangalore'),
(10, 'Deepa Shah', 'IT', 72000, 9, '2020-09-30', 'Bangalore');

-- Insert Sales Transactions (2024 data)
INSERT INTO SALES_TRANSACTIONS VALUES
-- January
(1, 2, '2024-01-05', 'Electronics', 45000, 3, 'West'),
(2, 3, '2024-01-08', 'Clothing', 12000, 8, 'West'),
(3, 4, '2024-01-12', 'Electronics', 67000, 4, 'South'),
(4, 5, '2024-01-15', 'Home', 23000, 5, 'North'),
(5, 2, '2024-01-20', 'Electronics', 89000, 5, 'West'),
-- February
(6, 2, '2024-02-03', 'Clothing', 15000, 10, 'West'),
(7, 3, '2024-02-07', 'Electronics', 56000, 3, 'West'),
(8, 4, '2024-02-10', 'Home', 34000, 7, 'South'),
(9, 5, '2024-02-14', 'Electronics', 78000, 4, 'North'),
(10, 2, '2024-02-18', 'Clothing', 18000, 12, 'West'),
-- March
(11, 2, '2024-03-02', 'Electronics', 92000, 5, 'West'),
(12, 3, '2024-03-05', 'Home', 28000, 6, 'West'),
(13, 4, '2024-03-09', 'Electronics', 71000, 4, 'South'),
(14, 5, '2024-03-12', 'Clothing', 16000, 11, 'North'),
(15, 2, '2024-03-18', 'Electronics', 85000, 5, 'West'),
-- April
(16, 3, '2024-04-01', 'Electronics', 63000, 3, 'West'),
(17, 4, '2024-04-05', 'Home', 31000, 6, 'South'),
(18, 5, '2024-04-10', 'Electronics', 74000, 4, 'North'),
(19, 2, '2024-04-15', 'Clothing', 21000, 14, 'West'),
(20, 3, '2024-04-20', 'Electronics', 58000, 3, 'West');

-- Insert Monthly Targets
INSERT INTO MONTHLY_TARGETS VALUES
(1, 2, '2024-01-01', 120000),
(2, 3, '2024-01-01', 80000),
(3, 4, '2024-01-01', 90000),
(4, 5, '2024-01-01', 85000),
(5, 2, '2024-02-01', 125000),
(6, 3, '2024-02-01', 85000),
(7, 4, '2024-02-01', 95000),
(8, 5, '2024-02-01', 90000),
(9, 2, '2024-03-01', 130000),
(10, 3, '2024-03-01', 90000),
(11, 4, '2024-03-01', 100000),
(12, 5, '2024-03-01', 95000),
(13, 2, '2024-04-01', 135000),
(14, 3, '2024-04-01', 95000),
(15, 4, '2024-04-01', 105000),
(16, 5, '2024-04-01', 100000);




WITH RegionalSales AS (
    SELECT 
        st.employee_id,
        st.region,
        SUM(st.sale_amount) AS total_sales
    FROM SALES_TRANSACTIONS st
    GROUP BY st.employee_id, st.region
),
RankedEmployees AS (
    SELECT 
        rs.employee_id,
        rs.region,
        rs.total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY rs.region 
            ORDER BY rs.total_sales DESC
        ) AS rank_in_region
    FROM RegionalSales rs
)
SELECT 
    e.employee_name,
    e.department,
    re.region,
    re.total_sales,
    re.rank_in_region
FROM RankedEmployees re
JOIN EMPLOYEES e 
    ON re.employee_id = e.employee_id
WHERE re.rank_in_region <= 2
ORDER BY re.region, re.rank_in_region;

---2.

WITH MonthlySales AS (
    SELECT 
        employee_id,
        DATE_TRUNC('MONTH', sale_date) AS month,
        SUM(sale_amount) AS actual_sales
    FROM SALES_TRANSACTIONS
    GROUP BY employee_id, DATE_TRUNC('MONTH', sale_date)
)
SELECT 
    e.employee_name,
    TO_CHAR(mt.month, 'YYYY-MM') AS month,
    mt.target_amount,
    COALESCE(ms.actual_sales, 0) AS actual_sales,
    COALESCE(ms.actual_sales, 0) - mt.target_amount AS variance,
    ROUND(
        (COALESCE(ms.actual_sales, 0) / mt.target_amount) * 100,
        2
    ) AS achievement_pct,
    CASE 
        WHEN (COALESCE(ms.actual_sales, 0) / mt.target_amount) >= 1 THEN 'Exceeded'
        WHEN (COALESCE(ms.actual_sales, 0) / mt.target_amount) >= 0.9 THEN 'Met'
        ELSE 'Below'
    END AS status
FROM MONTHLY_TARGETS mt
LEFT JOIN EMPLOYEES e
    ON mt.employee_id = e.employee_id
LEFT JOIN MonthlySales ms
    ON mt.employee_id = ms.employee_id
    AND mt.month = ms.month
ORDER BY mt.month, achievement_pct DESC;

----3.

WITH CategorySales AS (
    SELECT 
        region,
        product_category,
        SUM(sale_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM SALES_TRANSACTIONS
    GROUP BY region, product_category
)
SELECT 
    region,
    product_category,
    total_sales,
    total_quantity,
    transaction_count,
    RANK() OVER (
        PARTITION BY region 
        ORDER BY total_sales DESC
    ) AS sales_rank,
    DENSE_RANK() OVER (
        PARTITION BY region 
        ORDER BY total_sales DESC
    ) AS dense_rank,
    ROUND(
        (total_sales / SUM(total_sales) OVER (PARTITION BY region)) * 100,
        2
    ) AS pct_of_regional_sales
FROM CategorySales
WHERE total_sales > 50000
ORDER BY region, sales_rank;

---4.

WITH EmployeeSales AS (
    SELECT 
        employee_id,
        SUM(sale_amount) AS total_sales
    FROM SALES_TRANSACTIONS
    GROUP BY employee_id
)
SELECT 
    e.employee_name,
    m.employee_name AS manager_name,
    e.department,
    e.salary,
    es.total_sales,
    RANK() OVER (
        PARTITION BY e.department
        ORDER BY es.total_sales DESC NULLS LAST
    ) AS dept_sales_rank,
    CASE 
        WHEN RANK() OVER (
            PARTITION BY e.department
            ORDER BY es.total_sales DESC NULLS LAST
        ) = 1 THEN 'Y'
        ELSE 'N'
    END AS is_top_in_dept
FROM EMPLOYEES e
LEFT JOIN EMPLOYEES m
    ON e.manager_id = m.employee_id
LEFT JOIN EmployeeSales es
    ON e.employee_id = es.employee_id
ORDER BY e.department, dept_sales_rank;


--5.

WITH MonthlySales AS (
    SELECT 
        employee_id,
        DATE_TRUNC('MONTH', sale_date) AS month,
        SUM(sale_amount) AS monthly_sales
    FROM SALES_TRANSACTIONS
    GROUP BY employee_id, DATE_TRUNC('MONTH', sale_date)
),
EmployeeAvg AS (
    SELECT 
        employee_id,
        AVG(monthly_sales) AS employee_avg_monthly_sales
    FROM MonthlySales
    GROUP BY employee_id
),
MonthlyRanking AS (
    SELECT 
        employee_id,
        month,
        monthly_sales,
        RANK() OVER (
            PARTITION BY month
            ORDER BY monthly_sales DESC
        ) AS rank_in_month
    FROM MonthlySales
)
SELECT 
    e.employee_name,
    TO_CHAR(mr.month, 'YYYY-MM') AS month,
    mr.monthly_sales,
    ea.employee_avg_monthly_sales,
    mr.rank_in_month,
    CASE 
        WHEN mr.monthly_sales > ea.employee_avg_monthly_sales THEN 'Above Average'
        WHEN mr.monthly_sales = ea.employee_avg_monthly_sales THEN 'At Average'
        ELSE 'Below Average'
    END AS performance_vs_own_avg,
    mr.monthly_sales - ea.employee_avg_monthly_sales AS variance_from_avg,
    CASE 
        WHEN mr.rank_in_month = 1 THEN 'Y'
        ELSE 'N'
    END AS best_month
FROM MonthlyRanking mr
JOIN EmployeeAvg ea
    ON mr.employee_id = ea.employee_id
JOIN EMPLOYEES e
    ON mr.employee_id = e.employee_id
ORDER BY mr.month, mr.rank_in_month;