-- ============================================================
-- 01_create_tables.sql
-- Project : Employee Payroll SQL Database
-- Covers  : Task 1-5 (objective, tables, schema, constraints, CREATE scripts)
-- Works on: MySQL 8.0.16+ (CHECK constraints are enforced from this version)
-- ============================================================
-- OBJECTIVE: Create a database to manage employee payroll details
-- (employees, departments, salary, deductions, bonuses, attendance).

CREATE DATABASE IF NOT EXISTS payroll_db;
USE payroll_db;

DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS bonuses;
DROP TABLE IF EXISTS deductions;
DROP TABLE IF EXISTS salary;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- 1) DEPARTMENTS -------------------------------------------------
CREATE TABLE departments (
    dept_id     INT            NOT NULL,
    dept_name   VARCHAR(50)    NOT NULL,
    CONSTRAINT pk_departments      PRIMARY KEY (dept_id),
    CONSTRAINT uq_departments_name UNIQUE (dept_name)
);

-- 2) EMPLOYEES ---------------------------------------------------
CREATE TABLE employees (
    emp_id            VARCHAR(15)  NOT NULL,
    first_name        VARCHAR(60)  NOT NULL,
    last_name         VARCHAR(60),
    date_of_birth     DATE,
    gender            VARCHAR(10)  NOT NULL,
    marital_status    VARCHAR(40),
    country           VARCHAR(30)  NOT NULL,
    business_unit     VARCHAR(50),
    dept_id           INT          NOT NULL,
    designation       VARCHAR(50),
    grade             VARCHAR(5),
    employee_type     VARCHAR(20)  NOT NULL,
    employee_category VARCHAR(30),
    employee_status   VARCHAR(10)  NOT NULL,
    date_of_joining   DATE,
    date_of_termination DATE,
    CONSTRAINT pk_employees PRIMARY KEY (emp_id),
    CONSTRAINT fk_emp_dept  FOREIGN KEY (dept_id) REFERENCES departments (dept_id),
    CONSTRAINT ck_emp_gender CHECK (gender IN ('Male','Female','Opt-In')),
    CONSTRAINT ck_emp_status CHECK (employee_status IN ('Active','Inactive')),
    CONSTRAINT ck_emp_type   CHECK (employee_type IN ('Permanent','Temporary','External User'))
);

-- 3) SALARY ------------------------------------------------------
CREATE TABLE salary (
    salary_id                 INT           NOT NULL,
    emp_id                    VARCHAR(15)   NOT NULL,
    pay_period                DATE          NOT NULL,
    pay_month                 CHAR(7)       NOT NULL,   -- format YYYY-MM
    basic_salary              DECIMAL(14,2) NOT NULL,
    allowance                 DECIMAL(14,2) NOT NULL DEFAULT 0,
    special_allowance_arrear  DECIMAL(14,2) NOT NULL DEFAULT 0,
    gross_salary              DECIMAL(14,2) NOT NULL,
    net_salary                DECIMAL(14,2) NOT NULL,
    payroll_status            VARCHAR(30)   NOT NULL,
    CONSTRAINT pk_salary     PRIMARY KEY (salary_id),
    CONSTRAINT fk_salary_emp FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    CONSTRAINT ck_sal_basic  CHECK (basic_salary > 0),
    CONSTRAINT ck_sal_allow  CHECK (allowance >= 0),
    CONSTRAINT ck_sal_gross  CHECK (gross_salary >= 0),
    CONSTRAINT ck_sal_net    CHECK (net_salary >= 0)
);

-- 4) DEDUCTIONS --------------------------------------------------
CREATE TABLE deductions (
    deduction_id     INT           NOT NULL,
    salary_id        INT           NOT NULL,
    emp_id           VARCHAR(15)   NOT NULL,
    total_deductions DECIMAL(14,2) NOT NULL DEFAULT 0,
    tax_spend        DECIMAL(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_deductions  PRIMARY KEY (deduction_id),
    CONSTRAINT uq_ded_salary  UNIQUE (salary_id),
    CONSTRAINT fk_ded_salary  FOREIGN KEY (salary_id) REFERENCES salary (salary_id),
    CONSTRAINT fk_ded_emp     FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    CONSTRAINT ck_ded_total   CHECK (total_deductions >= 0),
    CONSTRAINT ck_ded_tax     CHECK (tax_spend >= 0)
);

-- 5) BONUSES -----------------------------------------------------
CREATE TABLE bonuses (
    bonus_id               INT           NOT NULL,
    salary_id              INT           NOT NULL,
    emp_id                 VARCHAR(15)   NOT NULL,
    statutory_bonus        DECIMAL(14,2) NOT NULL DEFAULT 0,
    arrear_statutory_bonus DECIMAL(14,2) NOT NULL DEFAULT 0,
    reimbursement_paid     DECIMAL(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_bonuses    PRIMARY KEY (bonus_id),
    CONSTRAINT uq_bonus_sal  UNIQUE (salary_id),
    CONSTRAINT fk_bonus_sal  FOREIGN KEY (salary_id) REFERENCES salary (salary_id),
    CONSTRAINT fk_bonus_emp  FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    CONSTRAINT ck_bonus_stat CHECK (statutory_bonus >= 0)
);

-- 6) ATTENDANCE (leave / assignment status per pay month) --------
CREATE TABLE attendance (
    attendance_id INT         NOT NULL,
    emp_id        VARCHAR(15) NOT NULL,
    pay_month     CHAR(7)     NOT NULL,
    leave_status  VARCHAR(30) NOT NULL,
    CONSTRAINT pk_attendance PRIMARY KEY (attendance_id),
    CONSTRAINT fk_att_emp    FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    CONSTRAINT ck_att_status CHECK (leave_status IN
        ('Active Assignment','Leave with Pay','Leave without Pay','Global Mobility','Not Recorded'))
);

-- Helpful indexes for reports
CREATE INDEX idx_emp_dept      ON employees (dept_id);
CREATE INDEX idx_salary_emp    ON salary (emp_id);
CREATE INDEX idx_salary_month  ON salary (pay_month);
