# Employee Payroll Data Analysis Using PostgreSQL

## 1. Project Overview

The Employee Payroll Data Analysis project uses PostgreSQL to organize, examine, validate, and analyze employee payroll data.

The project begins with a raw staging table containing imported payroll records. SQL queries and views are used to examine data quality, summarize payroll information, and generate reports based on departments, countries, and employee employment status.

The primary objective is to demonstrate practical skills in SQL, relational databases, data quality auditing, and payroll analytics.

## 2. Project Objectives

* Import payroll data into PostgreSQL.
* Preserve the original imported records in a staging table.
* Identify missing employee identifiers and other incomplete fields.
* Investigate repeated employee IDs without automatically deleting potentially valid records.
* Examine payroll salary and allowance information.
* Generate department-wise payroll summaries.
* Analyze payroll figures by country.
* Compare payroll records by employee status.
* Create reusable SQL views for reporting and analysis.
* Document data quality findings and project results.

## 3. Technologies Used

* Database: PostgreSQL
* Database management tool: pgAdmin
* Query language: SQL
* Input format: CSV
* Data analysis methods: Aggregation, grouping, filtering, and data quality auditing

## 4. Database Structure

### Raw Staging Table

Table name: `public.payroll_raw_staging`

Verified record count: 3,216

Verified column count: 48

The table contains employee identifiers, names, business unit details, employment dates, country information, employee status, department and designation details, and payroll amounts.

The staging table has the following data type structure:

* `staging_row_id`: bigint
* Remaining 47 columns: text

The staging layer preserves the imported data for examination before any additional transformations are performed.

## 5. Main Database Objects

The following eight database objects were successfully verified.

| Database object                    |     Verified result |
| ---------------------------------- | ------------------: |
| `payroll_raw_staging`              |       3,216 records |
| `vw_payroll_clean`                 |       3,216 records |
| `vw_payroll_clean_v2`              |       3,216 records |
| `vw_payroll_kpis`                  |               1 row |
| `vw_payroll_data_quality_audit_v2` |     9 audit results |
| `vw_department_payroll_summary`    |       5 departments |
| `vw_payroll_by_country`            |         6 countries |
| `vw_payroll_by_status`             | 2 status categories |

The clean views contain the same number of rows as the staging table. This confirms that their row counts match; it does not, by itself, establish that every record is error-free.

## 6. Data Quality Findings

The project's existing KPI and audit results identify the following issues for investigation.

| Data quality measure                             | Observed result |
| ------------------------------------------------ | --------------: |
| Total payroll records                            |           3,216 |
| Distinct employee IDs                            |           3,177 |
| Records with missing employee IDs                |               2 |
| Missing first names                              |              28 |
| Missing last names                               |             111 |
| Records with missing gross salary                |               0 |
| Records with missing net salary                  |               0 |
| Records with missing basic salary                |               0 |
| Records with missing total deductions            |             283 |
| Records with negative allowance                  |               4 |
| Repeated employee ID groups                      |              13 |
| Records belonging to repeated employee ID groups |              50 |

Repeated employee IDs require investigation because an employee may legitimately appear in multiple payroll periods or records. They should not automatically be treated as duplicate payroll transactions.

Missing deduction values should also be investigated rather than automatically replaced with zero.

Negative allowance values should be reviewed against the original dataset and applicable payroll rules.

## 7. Department-Wise Payroll Analysis

The department summary covers five departments: Finance, HR, IT, Management, and Marketing.

Key findings:

* Marketing has the highest number of payroll records, at 1,363.
* Marketing has the highest total gross salary, at 763,795,000.
* Marketing has the highest total net salary, at 129,543,101.
* Finance has the highest average gross salary, at 629,850.87.
* Marketing has the highest average net salary, at 95,042.63.

These results illustrate the difference between total payroll expenditure and average payroll amounts.

## 8. Country-Wise Payroll Analysis

The country summary covers six countries: China, India, Italy, Portugal, Singapore, and Turkey.

Key findings:

* India has the highest number of payroll records, at 1,211.
* India has the highest total net salary, at 112,896,200.
* Singapore has the highest average gross salary, at 613,549.72.
* Portugal has the lowest average gross salary among the six listed countries, at 459,367.09.

Country-level comparisons can help identify differences in payroll distribution. The results should be interpreted in the context of the available dataset and its currency and payroll-period definitions.

## 9. Employee Status Analysis

The status summary contains two categories.

| Employee status | Payroll records | Distinct employees |
| --------------- | --------------: | -----------------: |
| Active          |           2,276 |              2,243 |
| Inactive        |             940 |                934 |
| Total           |           3,216 |              3,177 |

The difference between payroll records and distinct employees indicates that some employee identifiers occur in multiple records within the status summary.

Further investigation is necessary before concluding whether those records represent legitimate payroll history or data quality issues.

## 10. Key Performance Indicators

The existing KPI view reports the following results:

* Total payroll records: 3,216
* Distinct employee IDs: 3,177
* Missing employee ID records: 2
* Missing deduction records: 283
* Negative allowance records: 4
* Average gross salary: 579,425.80
* Average net salary: 92,854.91

These indicators provide a compact overview of the dataset and highlight issues that may require additional validation.

## 11. Data Quality and Data Integrity

The project uses separate analysis views to identify incomplete records, repeated employee IDs, and unusual allowance values.

The original staging data should be retained so that reported results can be traced back to the imported dataset.

Before modifying payroll values or deleting records, the relevant business rules should be established and the proposed changes validated.

## 12. Limitations

* The accuracy of the analysis depends on the quality and completeness of the source dataset.
* Repeated employee IDs cannot be classified as errors without understanding the intended payroll record structure.
* Missing deduction values cannot safely be inferred without an approved business rule.
* Negative allowance values may require investigation against payroll policy.
* The presence of a clean view does not guarantee that every data quality issue has been resolved.
* Currency, payroll frequency, and payroll-period definitions should be confirmed before using the figures for financial decisions.

## 13. Conclusion

The Employee Payroll Data Analysis project demonstrates how PostgreSQL can be used to stage imported data, examine data quality, create reusable analytical views, and summarize payroll information.

The verified database contains 3,216 payroll records, five department categories, six country categories, and two employee status categories. The analysis identifies missing values, repeated employee identifiers, and negative allowance values that require further review.

The project provides a foundation for more detailed payroll reporting and data quality management while emphasizing the importance of preserving source data and validating business rules before making changes.
