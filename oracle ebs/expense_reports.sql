SELECT
    DISTINCT unique_id
    ,report_type
    ,header_employee_name  
    ,dist_create_date
    ,dist_amount
    ,item_description
    ,department
    ,fund_code
    ,natural_account_code
    ,cost_center_code
    ,project_code
    ,source_of_funds_code
    ,task_code
    ,distribution_line_number
    ,justification
    ,amount_includes_tax_flag
    ,tax_code_override_flag
    ,category_code
    ,line_amount
    ,line_type_lookup_code
    ,line_create_date
    ,line_created_by
    ,header_create_date
    ,header_description    
    ,report_total_amount
    ,start_expense_date
    ,end_expense_date
    ,line_submitted_amount
    ,header_employee_id
    ,report_invoice_number
    ,expense_report_id            
    ,source
    ,workflow_approved_flag
    ,workflow_status
    ,expense_report_status
    ,amt_due_employee
    ,amt_due_ccard_company
    ,expense_last_status_date
    ,dist_created_by
    ,report_submitted_date
    ,last_audited_by
    ,report_header_id
    ,report_line_id
    ,report_distribution_id
    ,cc_dist_amount  
    ,dept_dist_amount
FROM (
WITH
    gl_accounts AS
        (SELECT
            glcc.code_combination_id
            ,glcc.segment1              AS fund_code
            ,glcc.segment2              AS natural_account_code
            ,glcc.segment3              AS cost_center_code
            ,glcc.segment4              AS project_code
            ,glcc.segment5              AS source_of_funds_code
            ,glcc.segment6              AS task_code
            ,(CASE
                WHEN SUBSTR(glcc.segment3,1,3) = '101'  THEN '01 County Board'
                WHEN SUBSTR(glcc.segment3,1,3) = '102'  THEN '02 County Manager'
                WHEN SUBSTR(glcc.segment3,1,3) = '103'  THEN '03 Management and Finance'
                WHEN SUBSTR(glcc.segment3,1,3) = '104'  THEN '04 Civil Service Commission'
                WHEN SUBSTR(glcc.segment3,1,2) = '12'   THEN '05 Human Resources'
                WHEN SUBSTR(glcc.segment3,1,2) = '13'   THEN '06 Technology Services'
                WHEN SUBSTR(glcc.segment3,1,3) = '141'  THEN '07 County Attorney'
                WHEN SUBSTR(glcc.segment3,1,3) = '142'  THEN '08 Commissioner of Revenue'
                WHEN SUBSTR(glcc.segment3,1,3) = '143'  THEN '09 Treasurer'
                WHEN SUBSTR(glcc.segment3,1,3) = '144'  THEN '10 Registrar'
                WHEN SUBSTR(glcc.segment3,1,3) = '201'  THEN '11 Circuit Court Judiciary'
                WHEN SUBSTR(glcc.segment3,1,3) = '202'  THEN '12 Circuit Court Clerk'
                WHEN SUBSTR(glcc.segment3,1,3) = '203'  THEN '13 District Court'
                WHEN SUBSTR(glcc.segment3,1,3) IN ('204','206') THEN '14 Juvenile / Domestic Court'
                WHEN SUBSTR(glcc.segment3,1,3) = '207'  THEN '15 Commonwealth''s Attorney'
                WHEN SUBSTR(glcc.segment3,1,3) = '208'  THEN '16 Magistrate'
                WHEN SUBSTR(glcc.segment3,1,3) = '209'  THEN '17 Public Defender'
                WHEN SUBSTR(glcc.segment3,1,2) = '22'   THEN '18 Sheriff'
                WHEN SUBSTR(glcc.segment3,1,2) = '31'   THEN '19 Police'
                WHEN SUBSTR(glcc.segment3,1,2) = '32'   THEN '20 Emergency Management'
                WHEN SUBSTR(glcc.segment3,1,2) = '34'   THEN '21 Fire'
                WHEN SUBSTR(glcc.segment3,1,1) = '4'    THEN '22 Environmental Services'
                WHEN SUBSTR(glcc.segment3,1,1) = '5'    THEN '23 Human Services'
                WHEN SUBSTR(glcc.segment3,1,1) = '6'    THEN '24 Libraries'
                WHEN SUBSTR(glcc.segment3,1,2) = '71'   THEN '25 Economic Development'
                WHEN SUBSTR(glcc.segment3,1,2) = '72'   THEN '26 Planning and Housing'
                WHEN SUBSTR(glcc.segment3,1,1) = '8'    THEN '27 Parks and Recreation'
                WHEN SUBSTR(glcc.segment3,1,3) IN ('910','911','912') 
                    OR SUBSTR(glcc.segment3,1,2) IN ('00','99') 
                    OR glcc.segment3 = '10001' THEN '28 Non-Departmental'
                WHEN SUBSTR(glcc.segment3,1,3) = '913'  THEN '29 Schools'
                WHEN SUBSTR(glcc.segment3,1,3) = '914'  THEN '30 Retirement' END)
                                        AS department_name
        FROM GL_CODE_COMBINATIONS glcc)

    ,employees AS
        (SELECT 
            e.employee_id
            ,e.employee_num                                 AS employee_number
            ,e.global_name                                  AS employee_name
            ,u.user_id                                      AS user_id
            ,u.user_name                                    AS user_name
            ,u.description                                  AS description
            
        FROM PER_EMPLOYEES_X e

        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id)   
    
    ,general_reimbursements AS
        (SELECT
            d.report_header_id ||'-'|| d.report_line_id ||'-'|| d.report_distribution_id
                                                    AS unique_id
            ,d.segment3                             AS cost_center_code
            ,d.amount                               AS dist_amount
            ,d.segment3 ||'-'|| d.amount            AS cc_dist_amount
            ,h.creation_date                        AS header_create_date

        FROM AP_EXP_REPORT_DISTS_ALL d

        LEFT OUTER JOIN AP_EXPENSE_REPORT_HEADERS_ALL h
            ON d.report_header_id = h.report_header_id
            
        LEFT OUTER JOIN AP_EXPENSE_REPORTS_ALL r
            ON r.expense_report_id = h.expense_report_id

        WHERE
            r.report_type = 'General Reimbursements'
            AND h.expense_status_code = 'PAID'
            AND h.creation_date BETWEEN '01-JUL-2020' AND '30-JUN-2022')

    ,pcard_reconciliation AS
        (SELECT
            d.report_header_id ||'-'|| d.report_line_id ||'-'|| d.report_distribution_id
                                                    AS unique_id
            ,d.segment3                             AS cost_center_code
            ,d.amount                               AS dist_amount
            ,d.segment3 ||'-'|| d.amount            AS cc_dist_amount
            ,h.creation_date                        AS header_create_date

        FROM AP_EXP_REPORT_DISTS_ALL d

        LEFT OUTER JOIN AP_EXPENSE_REPORT_HEADERS_ALL h
            ON d.report_header_id = h.report_header_id
            
        LEFT OUTER JOIN AP_EXPENSE_REPORTS_ALL r
            ON r.expense_report_id = h.expense_report_id
            
        WHERE
            r.report_type = 'P-Card Reconciliation'
            AND h.expense_status_code = 'PAID'
            AND h.creation_date BETWEEN '01-JUL-2020' AND '30-JUN-2022')

SELECT
    d.report_header_id ||'-'|| d.report_line_id ||'-'|| d.report_distribution_id
                                    AS unique_id
    ,d.report_header_id
    ,d.report_line_id
    ,d.report_distribution_id
    ,d.creation_date                AS dist_create_date
    ,d.created_by                   AS dist_created_by
    ,d.amount                       AS dist_amount
    ,l.item_description
    ,gla.department_name            AS department
    ,gla.fund_code
    ,gla.natural_account_code
    ,gla.cost_center_code
    ,gla.project_code
    ,gla.source_of_funds_code
    ,gla.task_code
    ,gla.cost_center_code||'-'|| d.amount   AS cc_dist_amount
    ,gla.department_name ||'-'|| d.amount   AS dept_dist_amount
    ,l.amount                       AS line_amount
    ,INITCAP(l.line_type_lookup_code)   AS line_type_lookup_code
    ,l.creation_date                AS line_create_date
    ,l.created_by                   AS line_created_by
    ,l.distribution_line_number
    ,l.justification
    ,l.start_expense_date
    ,l.end_expense_date
    ,l.amount_includes_tax_flag
    ,l.tax_code_override_flag
    ,INITCAP(l.category_code)       AS category_code
    ,l.submitted_amount             AS line_submitted_amount
    ,h.employee_id                  AS header_employee_id
    ,e.employee_name                AS header_employee_name
    ,h.creation_date                AS header_create_date
    ,h.total                        AS report_total_amount
    ,h.invoice_num                  AS report_invoice_number
    ,h.expense_report_id
    ,r.report_type                  
    ,h.source
    ,h.description                  AS header_description
    ,h.workflow_approved_flag
    ,(CASE
        WHEN h.workflow_approved_flag = 'A' 
             OR h.workflow_approved_flag = 'Y'
                                            THEN 'Complete'
        WHEN h.workflow_approved_flag = 'I' THEN 'Incomplete'
        WHEN h.workflow_approved_flag = 'M' THEN 'Manager Approved'
        WHEN h.workflow_approved_flag = 'R' THEN 'Rejected'
        WHEN h.workflow_approved_flag = 'S' THEN 'Saved'
        WHEN h.workflow_approved_flag = 'W' THEN 'Withdrawn' END)
                                    AS workflow_status
    ,INITCAP(REPLACE(h.expense_status_code,'PENDMGR','Pending With Manager')) 
                                    AS expense_report_status
    ,h.amt_due_employee
    ,h.amt_due_ccard_company
    ,h.expense_last_status_date
    ,h.report_submitted_date
    ,h.last_audited_by  

FROM AP_EXP_REPORT_DISTS_ALL d

LEFT OUTER JOIN AP_EXPENSE_REPORT_LINES_ALL l
    ON d.report_line_id = l.report_line_id

LEFT OUTER JOIN AP_EXPENSE_REPORT_HEADERS_ALL h
    ON d.report_header_id = h.report_header_id
    
LEFT OUTER JOIN AP_EXPENSE_REPORTS_ALL r
    ON r.expense_report_id = h.expense_report_id
    
LEFT OUTER JOIN GL_ACCOUNTS gla
    ON d.code_combination_id = gla.code_combination_id
    
LEFT OUTER JOIN EMPLOYEES e
    ON h.employee_id = e.employee_id
    
INNER JOIN (
        SELECT
            gr.cc_dist_amount
            ,gr.unique_id       AS unique_id_gr          
            ,pc.unique_id       AS unique_id_pc
            
        FROM GENERAL_REIMBURSEMENTS gr
        
        INNER JOIN PCARD_RECONCILIATION pc
            ON gr.cc_dist_amount = pc.cc_dist_amount
            ) ex
            
    ON d.report_header_id ||'-'|| d.report_line_id ||'-'|| d.report_distribution_id = ex.unique_id_gr
        OR d.report_header_id ||'-'|| d.report_line_id ||'-'|| d.report_distribution_id = ex.unique_id_pc
)
WHERE
    header_create_date BETWEEN '01-JUL-2020' AND '30-JUN-2022'