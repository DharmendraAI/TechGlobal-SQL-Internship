-- ============================================================
-- 03_queries.sql
-- Task 8 : Queries to calculate salaries, deductions and bonuses
-- Formulae used:
--   total_earnings = basic_salary + allowance + special_allowance_arrear
--                    + statutory_bonus + arrear_statutory_bonus
--   take_home      = total_earnings - total_deductions
-- ============================================================
USE payroll_db;

-- Q1. Salary calculation for every payroll record (first 15 rows)
SELECT s.salary_id, s.emp_id, e.first_name, d.dept_name, s.pay_month,
       s.basic_salary, s.allowance, s.special_allowance_arrear,
       b.statutory_bonus + b.arrear_statutory_bonus                      AS total_bonus,
       ROUND(s.basic_salary + s.allowance + s.special_allowance_arrear
         + b.statutory_bonus + b.arrear_statutory_bonus, 2)              AS total_earnings,
       dd.total_deductions,
       ROUND(s.basic_salary + s.allowance + s.special_allowance_arrear
         + b.statutory_bonus + b.arrear_statutory_bonus
         - dd.total_deductions, 2)                                       AS take_home
FROM salary s
JOIN employees  e  ON e.emp_id    = s.emp_id
JOIN departments d ON d.dept_id   = e.dept_id
JOIN bonuses    b  ON b.salary_id = s.salary_id
JOIN deductions dd ON dd.salary_id = s.salary_id
ORDER BY s.salary_id
LIMIT 15;

-- Q2. Top 10 employees by total take-home (all pay records combined)
SELECT e.emp_id, e.first_name, e.designation, d.dept_name,
       COUNT(*)                              AS pay_records,
       ROUND(SUM(s.basic_salary + s.allowance + s.special_allowance_arrear
           + b.statutory_bonus + b.arrear_statutory_bonus
           - dd.total_deductions), 2)        AS total_take_home
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id
JOIN salary s      ON s.emp_id = e.emp_id
JOIN bonuses b     ON b.salary_id = s.salary_id
JOIN deductions dd ON dd.salary_id = s.salary_id
GROUP BY e.emp_id, e.first_name, e.designation, d.dept_name
ORDER BY total_take_home DESC
LIMIT 10;

-- Q3. Deduction calculation: department-wise total / average deductions
SELECT d.dept_name,
       COUNT(*)                                  AS pay_records,
       SUM(dd.total_deductions)                  AS total_deductions,
       ROUND(AVG(dd.total_deductions), 2)        AS avg_deduction,
       MAX(dd.total_deductions)                  AS max_deduction
FROM deductions dd
JOIN salary s      ON s.salary_id = dd.salary_id
JOIN employees e   ON e.emp_id = s.emp_id
JOIN departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY total_deductions DESC;

-- Q4. Deduction as % of gross, employees whose deduction is above 5,000 (top 10)
SELECT s.salary_id, s.emp_id, dd.total_deductions, s.gross_salary,
       ROUND(dd.total_deductions * 100.0 / s.gross_salary, 2) AS deduction_pct_of_gross
FROM deductions dd
JOIN salary s ON s.salary_id = dd.salary_id
WHERE dd.total_deductions > 5000
ORDER BY dd.total_deductions DESC
LIMIT 10;

-- Q5. Bonus calculation: department-wise statutory bonus
SELECT d.dept_name,
       ROUND(SUM(b.statutory_bonus), 2)            AS total_statutory_bonus,
       SUM(b.arrear_statutory_bonus)              AS total_arrear_bonus,
       ROUND(AVG(b.statutory_bonus), 2)           AS avg_bonus_per_record,
       ROUND(SUM(b.statutory_bonus) * 100.0 / SUM(s.basic_salary), 2) AS bonus_pct_of_basic
FROM bonuses b
JOIN salary s      ON s.salary_id = b.salary_id
JOIN employees e   ON e.emp_id = s.emp_id
JOIN departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY total_statutory_bonus DESC;

-- Q6. Top 10 bonus earners
SELECT e.emp_id, e.first_name, e.designation, d.dept_name,
       ROUND(SUM(b.statutory_bonus + b.arrear_statutory_bonus), 2) AS total_bonus
FROM bonuses b
JOIN employees e   ON e.emp_id = b.emp_id
JOIN departments d ON d.dept_id = e.dept_id
GROUP BY e.emp_id, e.first_name, e.designation, d.dept_name
ORDER BY total_bonus DESC
LIMIT 10;

-- Q7. Overall payroll summary (company level)
SELECT COUNT(DISTINCT s.emp_id)              AS employees_paid,
       COUNT(*)                              AS pay_records,
       SUM(s.basic_salary)                   AS total_basic,
       SUM(s.allowance)                      AS total_allowance,
       SUM(b.statutory_bonus)                AS total_statutory_bonus,
       SUM(dd.total_deductions)              AS total_deductions,
       SUM(s.gross_salary)                   AS total_gross,
       SUM(s.net_salary)                     AS total_net
FROM salary s
JOIN bonuses b     ON b.salary_id = s.salary_id
JOIN deductions dd ON dd.salary_id = s.salary_id;
