-- ============================================================
-- 04_reports.sql
-- Task 7 : Reports - monthly payroll, department-wise salary, tax calculation
-- ============================================================
USE payroll_db;

-- REPORT 1: Monthly payroll report
SELECT s.pay_month,
       COUNT(DISTINCT s.emp_id)          AS employees_paid,
       ROUND(SUM(s.basic_salary), 2)             AS total_basic,
       ROUND(SUM(s.allowance), 2)                AS total_allowance,
       ROUND(SUM(b.statutory_bonus), 2)   AS total_bonus,
       SUM(s.gross_salary)               AS total_gross,
       SUM(dd.total_deductions)          AS total_deductions,
       SUM(s.net_salary)                 AS total_net
FROM salary s
JOIN bonuses b     ON b.salary_id = s.salary_id
JOIN deductions dd ON dd.salary_id = s.salary_id
GROUP BY s.pay_month
ORDER BY s.pay_month;

-- REPORT 2: Department-wise salary report
SELECT d.dept_name,
       COUNT(DISTINCT e.emp_id)          AS employees,
       COUNT(*)                          AS pay_records,
       ROUND(SUM(s.basic_salary), 2)             AS total_basic,
       ROUND(AVG(s.basic_salary), 2)     AS avg_basic,
       SUM(s.gross_salary)               AS total_gross,
       SUM(s.net_salary)                 AS total_net,
       ROUND(AVG(s.net_salary), 2)       AS avg_net
FROM salary s
JOIN employees e   ON e.emp_id = s.emp_id
JOIN departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY total_gross DESC;

-- REPORT 3: Tax calculation (department-wise)
-- Tax is calculated on gross salary using slabs (illustrative slabs for this project):
--   gross <= 250,000          -> 0%
--   250,001 to 500,000        -> 5%
--   500,001 to 1,000,000      -> 10%
--   above 1,000,000           -> 20%
SELECT d.dept_name,
       COUNT(*)                                             AS pay_records,
       SUM(s.gross_salary)                                  AS total_gross,
       ROUND(SUM(CASE WHEN s.gross_salary <= 250000  THEN 0
                WHEN s.gross_salary <= 500000  THEN s.gross_salary * 0.05
                WHEN s.gross_salary <= 1000000 THEN s.gross_salary * 0.10
                ELSE s.gross_salary * 0.20 END), 2)         AS calculated_tax,
       ROUND(SUM(CASE WHEN s.gross_salary <= 250000  THEN 0
                WHEN s.gross_salary <= 500000  THEN s.gross_salary * 0.05
                WHEN s.gross_salary <= 1000000 THEN s.gross_salary * 0.10
                ELSE s.gross_salary * 0.20 END) * 100.0
             / SUM(s.gross_salary), 2)                      AS effective_tax_pct,
       SUM(dd.tax_spend)                                    AS recorded_tax_spend
FROM salary s
JOIN employees e   ON e.emp_id = s.emp_id
JOIN departments d ON d.dept_id = e.dept_id
JOIN deductions dd ON dd.salary_id = s.salary_id
GROUP BY d.dept_name
ORDER BY calculated_tax DESC;

-- REPORT 4: Attendance / leave summary
SELECT leave_status, COUNT(*) AS records
FROM attendance
GROUP BY leave_status
ORDER BY records DESC;
