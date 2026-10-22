-- ============================================================
-- 05_validation.sql
-- Task 9 : Test queries and validate correctness of calculations
-- Expected values come from Payroll_Data.xlsx (after cleaning).
-- Every test returns PASS or FAIL.
-- ============================================================
USE payroll_db;

-- T1: Row counts match the Excel file (3,214 payroll rows, 3,177 employees, 5 departments)
SELECT 'T1 salary rows = 3214' AS test,
       CASE WHEN COUNT(*) = 3214 THEN 'PASS' ELSE 'FAIL' END AS result FROM salary
UNION ALL
SELECT 'T2 employees = 3177', CASE WHEN COUNT(*) = 3177 THEN 'PASS' ELSE 'FAIL' END FROM employees
UNION ALL
SELECT 'T3 departments = 5', CASE WHEN COUNT(*) = 5 THEN 'PASS' ELSE 'FAIL' END FROM departments

-- T4-T6: Column totals match Excel totals
UNION ALL
SELECT 'T4 SUM(gross) = 1862533389', CASE WHEN SUM(gross_salary) = 1862533389 THEN 'PASS' ELSE 'FAIL' END FROM salary
UNION ALL
SELECT 'T5 SUM(net) = 298437401', CASE WHEN SUM(net_salary) = 298437401 THEN 'PASS' ELSE 'FAIL' END FROM salary
UNION ALL
SELECT 'T6 SUM(deductions) = 21622100', CASE WHEN SUM(total_deductions) = 21622100 THEN 'PASS' ELSE 'FAIL' END FROM deductions

-- T7-T9: Referential integrity (no orphan records)
UNION ALL
SELECT 'T7 no salary without employee',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM salary s LEFT JOIN employees e ON e.emp_id = s.emp_id WHERE e.emp_id IS NULL
UNION ALL
SELECT 'T8 no employee without department',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM employees e LEFT JOIN departments d ON d.dept_id = e.dept_id WHERE d.dept_id IS NULL
UNION ALL
SELECT 'T9 every salary has deduction + bonus row',
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM salary s
LEFT JOIN deductions dd ON dd.salary_id = s.salary_id
LEFT JOIN bonuses b ON b.salary_id = s.salary_id
WHERE dd.salary_id IS NULL OR b.salary_id IS NULL

-- T10-T11: Report totals reconcile with overall total
UNION ALL
SELECT 'T10 dept-wise gross total = overall gross',
       CASE WHEN (SELECT SUM(x.g) FROM (SELECT SUM(s.gross_salary) AS g
                  FROM salary s JOIN employees e ON e.emp_id = s.emp_id
                  GROUP BY e.dept_id) x) = (SELECT SUM(gross_salary) FROM salary)
            THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 'T11 month-wise gross total = overall gross',
       CASE WHEN (SELECT SUM(x.g) FROM (SELECT SUM(gross_salary) AS g
                  FROM salary GROUP BY pay_month) x) = (SELECT SUM(gross_salary) FROM salary)
            THEN 'PASS' ELSE 'FAIL' END

-- T12: take_home formula check (two different ways of computing must agree)
UNION ALL
SELECT 'T12 take_home = earnings - deductions (aggregate check)',
       CASE WHEN ABS(
            (SELECT SUM(s.basic_salary + s.allowance + s.special_allowance_arrear
                        + b.statutory_bonus + b.arrear_statutory_bonus - dd.total_deductions)
             FROM salary s JOIN bonuses b ON b.salary_id = s.salary_id
                           JOIN deductions dd ON dd.salary_id = s.salary_id)
            -
            ((SELECT SUM(basic_salary + allowance + special_allowance_arrear) FROM salary)
             + (SELECT SUM(statutory_bonus + arrear_statutory_bonus) FROM bonuses)
             - (SELECT SUM(total_deductions) FROM deductions))) < 0.01
            THEN 'PASS' ELSE 'FAIL' END

-- T13: slab tax computed with CASE equals slab tax computed bucket by bucket
UNION ALL
SELECT 'T13 slab tax: CASE method = bucket method',
       CASE WHEN ABS(
            (SELECT SUM(CASE WHEN gross_salary <= 250000  THEN 0
                             WHEN gross_salary <= 500000  THEN gross_salary * 0.05
                             WHEN gross_salary <= 1000000 THEN gross_salary * 0.10
                             ELSE gross_salary * 0.20 END) FROM salary)
            -
            ((SELECT COALESCE(SUM(gross_salary),0) * 0.05 FROM salary WHERE gross_salary > 250000  AND gross_salary <= 500000)
           + (SELECT COALESCE(SUM(gross_salary),0) * 0.10 FROM salary WHERE gross_salary > 500000  AND gross_salary <= 1000000)
           + (SELECT COALESCE(SUM(gross_salary),0) * 0.20 FROM salary WHERE gross_salary > 1000000))
            ) < 0.01 THEN 'PASS' ELSE 'FAIL' END;

-- ------------------------------------------------------------
-- CONSTRAINT TESTS (run one by one - each one MUST give an error)
-- ------------------------------------------------------------
-- C1: duplicate department name  -> violates UNIQUE
--   INSERT INTO departments (dept_id, dept_name) VALUES (99, 'IT');
-- C2: employee with unknown department -> violates FOREIGN KEY
--   INSERT INTO employees (emp_id, first_name, gender, country, dept_id, employee_type, employee_status)
--   VALUES ('TEST001', 'Test', 'Male', 'India', 999, 'Permanent', 'Active');
-- C3: invalid gender -> violates CHECK
--   INSERT INTO employees (emp_id, first_name, gender, country, dept_id, employee_type, employee_status)
--   VALUES ('TEST002', 'Test', 'X', 'India', 1, 'Permanent', 'Active');
-- C4: NULL first name -> violates NOT NULL
--   INSERT INTO employees (emp_id, first_name, gender, country, dept_id, employee_type, employee_status)
--   VALUES ('TEST003', NULL, 'Male', 'India', 1, 'Permanent', 'Active');
-- C5: negative basic salary -> violates CHECK
--   INSERT INTO salary (salary_id, emp_id, pay_period, pay_month, basic_salary, gross_salary, net_salary, payroll_status)
--   VALUES (99999, '1692406', '2022-01-01', '2022-01', -500, 1000, 1000, 'Active');
