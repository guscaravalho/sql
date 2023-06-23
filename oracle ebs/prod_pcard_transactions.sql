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
                                        AS department
        FROM GL_CODE_COMBINATIONS glcc)
        
    ,expense_reports AS
        (SELECT
            erl.report_line_id
            ,erh.report_header_id
            ,erd.report_distribution_id
            ,erl.credit_card_trx_id
            ,erh.employee_id                    AS expense_report_employee_id
            ,erh.created_by                     AS expense_report_creator_user_id
            ,erh.invoice_num 			        AS invoice_number
            ,erh.expense_report_id 			    AS er_header_id
            ,erh.description 				    AS er_header_description
            ,erl.report_line_id 			    AS er_line_id    
            ,erl.justification 				    AS er_line_justification
            ,erd.amount 				        AS distribution_amount
            ,erd.code_combination_id
            ,erl.allocation_split_code 		    AS allocation_split_code
            ,(CASE  
                WHEN erl.allocation_split_code = 'ACCOUNT' 
                THEN 'Split'
                ELSE 'Single' END) 					
                                                AS transaction_allocation_type
            ,erl.itemization_parent_id 		    AS transaction_allocation_id
            ,INITCAP(erh.expense_status_code)   AS expense_status_code
            ,erh.source
            ,erh.report_submitted_date 		    AS er_submitted_date
            ,erh.creation_date 			        AS er_created_date
            ,erh.workflow_approved_flag 		AS er_workflow_approved_flag
            ,(CASE
                WHEN erh.workflow_approved_flag = 'A' OR erh.workflow_approved_flag = 'Y'
                                                      THEN 'Complete'
                WHEN erh.workflow_approved_flag = 'I' THEN 'Incomplete'
                WHEN erh.workflow_approved_flag = 'M' THEN 'Manager Approved'
                WHEN erh.workflow_approved_flag = 'R' THEN 'Rejected'
                WHEN erh.workflow_approved_flag = 'S' THEN 'Saved'
                WHEN erh.workflow_approved_flag = 'W' THEN 'Withdrawn' END)
                                                AS er_workflow_status
            ,INITCAP(REPLACE(erh.expense_status_code,'PENDMGR','Pending With Manager')) 
                                                AS er_status
            ,erl.flex_concatenated
            ,INITCAP(erl.category_code)         AS er_line_category_code
            ,erl.amount_includes_tax_flag
            ,erl.merchant_name 			        AS er_merchant_name
            ,erl.creation_date 			        AS er_line_created_datetime
            ,erl.last_update_date 			    AS er_line_last_update_datetime
            
        FROM AP_EXP_REPORT_DISTS_ALL erd

        LEFT OUTER JOIN AP_EXPENSE_REPORT_LINES_ALL erl
            ON erd.report_line_id = erl.report_line_id

        LEFT OUTER JOIN AP_EXPENSE_REPORT_HEADERS_ALL erh
            ON erl.report_header_id = erh.report_header_id)
          
    ,invoices AS
        (SELECT
            DISTINCT ai.invoice_num     AS invoice_number
            ,aid.accounting_date        AS er_invoice_gl_date
            
        FROM AP_INVOICE_DISTRIBUTIONS_ALL aid

        LEFT OUTER JOIN AP_INVOICES_ALL ai
            ON aid.invoice_id = ai.invoice_id
            
        WHERE
            SUBSTR(ai.invoice_num,1,8) = 'iExpense')

    ,pcards AS
        (SELECT
            c.card_id
            ,c.card_reference_id
            ,c.employee_id              AS cc_holder_employee_id
            ,c.attribute1               AS cc_manager_employee_id
            ,c.card_number
            ,c.limit_override_amount    AS cc_limit
            ,cc.instrid
            ,cc.ccnumber                AS cc_number
            ,cc.masked_cc_number        AS cc_number_masked    
            ,cc.expirydate              AS cc_expiration_date
            ,INITCAP(cc.chname)         AS cc_holder_name
            ,cc.creation_date           AS cc_created_datetime
            ,cc.last_update_date        AS cc_last_update_datetime
            ,(CASE
                WHEN cc.active_flag = 'Y' THEN 'Active'
                WHEN cc.active_flag = 'N' THEN 'Not Active' END)
                                        AS card_status
            ,(CASE
                WHEN cc.expired_flag = 'Y' THEN 'Expired'
                WHEN cc.expired_flag = 'N' THEN 'Not Expired' END)
                                        AS expiration_status                
        FROM AP_CARDS_ALL c

        LEFT OUTER JOIN IBY_CREDITCARD cc
            ON c.card_reference_id = cc.instrid)

    ,employees AS 
        (SELECT 
            e.employee_id
            ,e.assignment_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
            ,u.user_id
            ,u.user_name                    AS prism_user_name
            ,e.inactive_date                AS employee_inactive_date
            ,(CASE   
                WHEN e.inactive_date IS NULL THEN 'Active'
                ELSE 'Not Active' END)
                                            AS employee_status
            ,e.organization_id
            ,org.name                       AS org_name
            ,(CASE
                WHEN SUBSTR(org.name,1,3) = 'AED' THEN '25 Economic Development'
                WHEN SUBSTR(org.name,1,3) = 'CAO' THEN '07 County Attorney'
                WHEN SUBSTR(org.name,1,3) = 'CBO' THEN '01 County Board'
                WHEN SUBSTR(org.name,1,3) = 'CCJ' THEN '11 Circuit Court Judiciary'
                WHEN SUBSTR(org.name,1,3) = 'CCT' THEN '12 Circuit Court Clerk'
                WHEN SUBSTR(org.name,1,3) = 'CMO' THEN '02 County Manager'
                WHEN SUBSTR(org.name,1,3) = 'COR' THEN '08 Commissioner of Revenue'
                WHEN SUBSTR(org.name,1,3) = 'CPH' THEN '26 Planning and Housing'
                WHEN SUBSTR(org.name,1,3) = 'CWA' THEN '15 Commonwealth''s Attorney'
                WHEN SUBSTR(org.name,1,3) = 'DES' THEN '22 Environmental Services'
                WHEN SUBSTR(org.name,1,3) = 'DHS' THEN '23 Human Services'
                WHEN SUBSTR(org.name,1,3) = 'DMF' THEN '03 Management and Finance'
                WHEN SUBSTR(org.name,1,3) = 'DPR' THEN '27 Parks and Recreation'
                WHEN SUBSTR(org.name,1,3) = 'DTS' THEN '06 Technology Services'
                WHEN SUBSTR(org.name,1,3) = 'FIR' THEN '21 Fire'
                WHEN SUBSTR(org.name,1,3) = 'GDC' THEN '13 District Court'
                WHEN SUBSTR(org.name,1,3) = 'HRD' THEN '05 Human Resources'
                WHEN SUBSTR(org.name,1,3) = 'JDR' THEN '14 Juvenile / Domestic Court'
                WHEN SUBSTR(org.name,1,3) = 'LIB' THEN '24 Libraries'
                WHEN SUBSTR(org.name,1,3) = 'MAG' THEN '16 Magistrate'
                WHEN SUBSTR(org.name,1,3) = 'OEM' THEN '20 Emergency Management'
                WHEN SUBSTR(org.name,1,3) = 'PDO' THEN '17 Public Defender'
                WHEN SUBSTR(org.name,1,3) = 'POL' THEN '19 Police'
                WHEN SUBSTR(org.name,1,3) = 'PPO' THEN '19 Police'
                WHEN SUBSTR(org.name,1,3) = 'PSC' THEN '20 Emergency Management'
                WHEN SUBSTR(org.name,1,3) = 'REG' THEN '10 Registrar'
                WHEN SUBSTR(org.name,1,3) = 'SRF' THEN '18 Sheriff'
                WHEN SUBSTR(org.name,1,3) = 'TRS' THEN '09 Treasurer'
                WHEN SUBSTR(org.name,1,3) = 'OFF' THEN '17 Public Defender'
                WHEN SUBSTR(org.name,1,3) = 'RET' THEN '30 Retirement' END)
                                            AS department      
        FROM PER_EMPLOYEES_X e
        
        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id

        LEFT OUTER JOIN PER_ALL_ORGANIZATION_UNITS org
            ON e.organization_id = org.organization_id)

SELECT 
    COALESCE(pc.cc_number_masked,pc.card_number)    AS pcard_number
    ,holder.department                              AS pcard_holder_dept

--transaction identification
    ,er.invoice_number
    ,er.report_header_id                            AS er_header_id    
    ,cct.trx_id 				                    AS transaction_id
    ,er.report_distribution_id 		                AS distribution_id
    ,er.report_header_id||'-'||cct.trx_id||'-'||er.report_distribution_id 
                                                    AS unique_id
    ,er.report_line_id                              AS er_line_id

--card holder/manager
    ,pc.cc_holder_employee_id		                AS pcard_holder_employee_id
    ,holder.employee_name   		                AS pcard_holder_name
    ,holder.employee_number                         AS pcard_holder_emp_number
    ,pc.cc_manager_employee_id 				        AS pcard_manager_employee_id
    ,manager.employee_name		                    AS pcard_manager_name
    ,manager.employee_number                        AS pcard_manager_emp_number 

--transaction dates/amounts, note: distribution_amount shows split transactions accurately
    ,INITCAP(cct.expense_status) 			        AS cc_transaction_status
    ,cct.mis_industry_code 			                AS mcc_code
    ,cct.transaction_date 			                AS cc_transaction_date
    ,(CASE  
        WHEN cct.debit_flag = 'D' THEN 'Debit'
        WHEN cct.debit_flag = 'C' THEN 'Credit' END)				
                                                    AS transaction_type
    ,cct.transaction_amount 			            AS cc_transaction_amount
    ,cct.billed_date 				                AS billed_date
    ,cct.billed_amount 				                AS billed_amount
    ,cct.posted_date 				                AS posted_date
    ,cct.posted_amount 			                    AS posted_amount
    ,cct.posted_currency_code 			            AS posted_currency_code
    ,cct.expensed_amount 			                AS expensed_amount
    ,er.distribution_amount

--transaction tax information
    ,cct.local_tax 				                    AS tax_amount_local
    ,cct.national_tax 				                AS tax_amount_national
    ,cct.other_tax 				                    AS tax_amount_other
    ,cct.total_tax 				                    AS tax_amount_total

--merchant info
    ,cct.merchant_name1 			                AS merchant_name
    ,cct.merchant_reference 			            AS merchant_reference
    ,cct.merchant_tax_id
    
--expense report employee/creator (expense reports can be created on others' behalf) and other info
    ,er.source                                      AS er_source
    ,report1.employee_name                          AS er_employee_name
    ,report2.employee_name                          AS er_preparer_name
    ,cct.trx_available_date                         AS cc_transaction_available_date 
    ,er.er_created_date
    ,er.er_line_created_datetime
    ,er.er_line_last_update_datetime
    ,er.er_submitted_date
    ,i.er_invoice_gl_date
    ,er.er_workflow_status
    ,er.er_status
    ,INITCAP(cct.folio_type) 				        AS folio_type
    ,er.er_line_category_code
    ,er.er_line_justification                       AS cc_transaction_justification
    ,er.er_header_description                       AS expense_report_description
    ,er.allocation_split_code
    ,er.transaction_allocation_type
    ,er.transaction_allocation_id
    
--GL info
    ,gla.department                                 AS department
    ,gla.fund_code 				                    AS fund_code
    ,gla.natural_account_code	                    AS natural_account_code
    ,gla.cost_center_code		                    AS cost_center_code
    ,gla.project_code   		                    AS project_code
    ,gla.source_of_funds_code	                    AS source_of_funds_code
    ,gla.task_code          	                    AS task_code
    ,gla.fund_code||'_x' 				            AS fund_code_x
    ,gla.natural_account_code||'_x' 	            AS natural_account_code_x
    ,gla.cost_center_code||'_x' 		            AS cost_center_code_x
    ,gla.project_code||'_x'    		                AS project_code_x
    ,gla.source_of_funds_code||'_x' 	            AS source_of_funds_code_x
    ,gla.task_code||'_x'           	                AS task_code_x

--other fields
    ,cct.debit_flag                                 AS debit_flag
    ,cct.company_prepaid_invoice_id
    ,INITCAP(cct.category)                          AS cc_transaction_category
    ,er.amount_includes_tax_flag
    ,er.er_merchant_name
    ,pc.cc_expiration_date 			                AS pcard_expiration_datetime
    ,holder.employee_name||' '||holder.employee_number 				
                                                    AS pcard_holder_name_number
    ,manager.employee_name||' '||manager.employee_number			
                                                    AS pcard_manager_name_number
    ,TRUNC(sysdate)                                 AS report_run_date

FROM AP_CREDIT_CARD_TRXNS_ALL cct
    
LEFT OUTER JOIN PCARDS pc
    ON pc.card_id = cct.card_id
    
LEFT OUTER JOIN EXPENSE_REPORTS er
    ON er.credit_card_trx_id = cct.trx_id
    
LEFT OUTER JOIN INVOICES i
    ON er.invoice_number = i.invoice_number
    
LEFT OUTER JOIN GL_ACCOUNTS gla
    ON er.code_combination_id = gla.code_combination_id

LEFT OUTER JOIN EMPLOYEES holder
    ON pc.cc_holder_employee_id = holder.employee_id

LEFT OUTER JOIN EMPLOYEES manager
    ON pc.cc_manager_employee_id = manager.employee_id

LEFT OUTER JOIN EMPLOYEES report1
    ON er.expense_report_employee_id = report1.employee_id

LEFT OUTER JOIN EMPLOYEES report2
    ON er.expense_report_creator_user_id = report2.user_id   

WHERE
--    er.distribution_amount IS NOT NULL
--    AND manager.employee_name LIKE '%%'
    holder.employee_name LIKE '%M%Ebony%'
    AND cct.transaction_date BETWEEN '01-JUL-2022' AND '31-DEC-2022'