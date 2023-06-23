WITH
    invoices AS
        (SELECT
            DISTINCT aid.invoice_distribution_id
            ,ai.invoice_num                                  		AS invoice_number
            ,aid.invoice_line_number                         		AS invoice_line_number
            ,aid.distribution_line_number                    		AS invoice_dist_line_number
            ,(CASE
                WHEN SUBSTR(ai.invoice_num,1,8) = 'iExpense' THEN 'Expense Report'
                ELSE 'Payables' END)                                AS invoice_source 
            ,TRUNC(ai.creation_date)                                AS invoice_created_date
            ,ai.creation_date                                       AS invoice_created_datetime
            ,ai.invoice_date                                 		AS invoice_date
            ,aid.accounting_date                             		AS invoice_dist_gl_date
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(aid.accounting_date,4,3)) IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR( aid.accounting_date ,8,4))+1)
                WHEN TO_CHAR(SUBSTR(aid.accounting_date,4,3)) IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR( aid.accounting_date ,8,4)) END)    
                                                                    AS invoice_dist_fiscal_year
            ,(CASE
                WHEN SUBSTR(aid.accounting_date,4,3) = 'JUL'    THEN '01 JUL.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'AUG'    THEN '02 AUG.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'SEP'    THEN '03 SEP.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'OCT'    THEN '04 OCT.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'NOV'    THEN '05 NOV.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'DEC'    THEN '06 DEC.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'JAN'    THEN '07 JAN.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'FEB'    THEN '08 FEB.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'MAR'    THEN '09 MAR.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'APR'    THEN '10 APR.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'MAY'    THEN '11 MAY.'
                WHEN SUBSTR(aid.accounting_date,4,3) = 'JUN'    THEN '12 JUN.' END)   
                                                                    AS invoice_dist_month
            ,ai.description                                  	    AS invoice_description
            ,aid.description                                 		AS distribution_description
            ,ai.invoice_amount                               		AS invoice_amount
            ,aid.amount                                      		AS distribution_amount
            ,(CASE  
                WHEN aid.reversal_flag = 'Y' THEN 'Reversed'
                ELSE NULL END)                          		
                                                                    AS dist_reversal_status
            ,(CASE  
                WHEN aid.posted_flag = 'Y' THEN 'Posted'
                WHEN aid.posted_flag = 'N' THEN 'Not Posted'
                ELSE 'Error' END)                       		
                                                                    AS distribution_status
            ,ai.vendor_id
            ,ai.invoice_id
            ,aid.dist_code_combination_id
            ,aid.po_distribution_id

        FROM AP_INVOICE_DISTRIBUTIONS_ALL aid

        LEFT OUTER JOIN AP_INVOICES_ALL ai
            ON aid.invoice_id = ai.invoice_id)
    
    ,gl_accounts AS
        (SELECT
            glcc.code_combination_id
            ,glcc.segment1                                  AS fund_code
            ,glcc.segment2                                  AS natural_account_code
            ,glcc.segment3                                  AS cost_center_code
            ,glcc.segment4                                  AS project_code
            ,glcc.segment5                                  AS source_of_funds_code
            ,glcc.segment6                                  AS task_code
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
        
    ,employees AS
        (SELECT 
            e.employee_id
            ,e.employee_num                                 AS employee_number
            ,e.global_name                                  AS employee_name
            ,u.user_id                                      
            ,u.user_name
        FROM PER_EMPLOYEES_X e

        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id)
     
    ,purchase_orders AS
        (SELECT
            pod.po_distribution_id
            ,pod.req_distribution_id
            ,poh.created_by                                 AS po_converter
            ,pod.created_by                                 AS po_dist_creator
            ,poh.segment1                                   AS po_number
            ,pol.line_num                                   AS po_line_number
            ,INITCAP(poh.closed_code)            			AS po_status
            ,INITCAP(pol.closed_code)            			AS po_line_status
            ,TRUNC(poh.creation_date)                       AS po_create_date
            ,TRUNC(pod.gl_encumbered_date)                  AS po_line_gl_date
            ,poh.attribute1                                 AS purchasing_authority_number
            ,poh.attribute4                                 AS quick_quote_number
            ,(CASE
                WHEN SUBSTR(poh.attribute1,1,1) = 'Q' THEN poh.attribute1||' '||poh.attribute4
                ELSE poh.attribute1 END) 
                                                            AS purchasing_authority
            
        FROM PO_DISTRIBUTIONS_ALL pod

        LEFT OUTER JOIN PO_HEADERS_ALL poh
            ON pod.po_header_id = poh.po_header_id
            
        LEFT OUTER JOIN PO_LINES_ALL pol
            ON pod.po_line_id = pol.po_line_id)
    
    ,requisitions AS
        (SELECT 
            prd.distribution_id
            ,prh.segment1                                   AS req_number
            ,prh.preparer_id                                AS keyer
            ,prl.item_description                           AS item_description

        FROM PO_REQ_DISTRIBUTIONS_ALL prd
            
        LEFT OUTER JOIN PO_REQUISITION_LINES_ALL prl
            ON prd.requisition_line_id = prl.requisition_line_id
            
        LEFT OUTER JOIN PO_REQUISITION_HEADERS_ALL prh
            ON prl.requisition_header_id = prh.requisition_header_id)
    
    ,checks AS 
        (SELECT
            p.invoice_id
            ,c.check_id
            ,c.check_number                               AS check_number
            ,c.amount                                     AS check_amount
            ,REPLACE(c.payment_method_code,'CHECK','Check') AS payment_method
            ,p.accounting_date                             AS payment_gl_date
            ,c.check_date                                 AS check_issued_date
            ,c.cleared_date                               AS check_cleared_date
            ,INITCAP(c.status_lookup_code)                AS check_status
            ,c.vendor_site_code

        FROM AP_INVOICE_PAYMENTS_ALL p

        LEFT OUTER JOIN AP_CHECKS_ALL c
            ON p.check_id = c.check_id)
            
    ,suppliers AS
        (SELECT
            s.vendor_id
            ,s.segment1                             AS supplier_number
            ,INITCAP(s.vendor_name)                 AS supplier_name            
            ,(CASE   
                WHEN s.enabled_flag = 'Y' THEN 'Enabled'
                WHEN s.enabled_flag = 'N' THEN 'Not Enabled' END)                                   		
                                                    AS supplier_status
            ,(CASE
                WHEN TRUNC(sysdate) >= TRUNC(s.start_date_active) AND s.end_date_active IS NULL THEN 'Valid'
                ELSE 'Not Valid' END)              
                                                    AS supplier_validity
            ,TRUNC(s.start_date_active)             AS supplier_active_date_start
            ,TRUNC(s.end_date_active)               AS supplier_active_date_end
            ,s.hold_all_payments_flag
            
            ,INITCAP(s.vendor_type_lookup_code)     AS supplier_type
            ,s.employee_id
            ,(CASE
                WHEN s.payment_method_lookup_code = 'EFT' THEN 'EFT'
                ELSE INITCAP(s.payment_method_lookup_code) END)
                                                    AS payment_method
            ,INITCAP(s.pay_group_lookup_code)       AS payment_group

        FROM AP_SUPPLIERS s)

SELECT
    DISTINCT i.invoice_distribution_id
    ,po.purchasing_authority_number
    ,po.quick_quote_number
    ,po.purchasing_authority                                AS purchasing_authority
    ,s.supplier_name                                		AS supplier_name
    ,req.req_number                                         AS req_number
    ,po.po_number                                   	    AS po_number
    ,po.po_status                                           AS po_status
    ,po.po_line_number                                 		AS po_line_number
    ,po.po_line_status                                      AS po_line_status
    ,reqkey.employee_name                                   AS req_keyer_name
    ,buyer.employee_name                                    AS po_buyer_name
    ,podist.employee_name                                   AS po_distribution_keyer_name
    ,i.invoice_number
    ,i.invoice_line_number
    ,i.invoice_dist_line_number
    ,i.invoice_source 
    ,po.po_create_date                                      AS po_create_date
    ,po.po_line_gl_date                                     AS po_line_gl_date
    ,i.invoice_created_date
    ,i.invoice_created_datetime
    ,i.invoice_date
    ,i.invoice_date - po.po_create_date                     AS pocreatedate_to_invoicedate
    ,i.invoice_date - po.po_line_gl_date                    AS polinegldate_to_invoicedate
    ,i.invoice_dist_gl_date
    ,i.invoice_dist_fiscal_year
    ,i.invoice_dist_month
    ,req.item_description                                   AS req_item_description
    ,i.invoice_description
    ,i.distribution_description
    ,i.invoice_amount
    ,i.distribution_amount
    ,gla.department  
    ,gla.fund_code
    ,gla.natural_account_code
    ,gla.cost_center_code
    ,gla.project_code
    ,gla.source_of_funds_code
    ,gla.task_code
    ,gla.fund_code||'_x'                                    AS fund_code_x
    ,gla.natural_account_code||'_x'                         AS natural_account_code_x
    ,gla.cost_center_code||'_x'                             AS cost_center_code_x
    ,gla.project_code||'_x'                                 AS project_code_x
    ,gla.source_of_funds_code||'_x'                         AS source_of_funds_code_x
    ,gla.task_code||'_x'                                    AS task_code_x
    ,i.invoice_dist_gl_date||'_x'                           AS invoice_dist_gl_date_x
    ,i.dist_reversal_status
    ,i.distribution_status
    ,chk.payment_method                                     AS payment_method
    ,chk.payment_gl_date                                    AS payment_gl_date
    ,chk.check_number                               		AS check_number
    ,chk.check_amount                                       AS check_amount
    ,chk.check_issued_date                                 	AS check_issued_date
    ,chk.check_cleared_date                               	AS check_cleared_date
    ,chk.check_status                                       AS check_status
    ,sysdate                                                AS report_run_datetime    

FROM INVOICES i

LEFT OUTER JOIN SUPPLIERS s
    ON i.vendor_id = s.vendor_id
    
LEFT OUTER JOIN CHECKS chk
    ON i.invoice_id = chk.invoice_id 

LEFT OUTER JOIN GL_ACCOUNTS gla
    ON i.dist_code_combination_id = gla.code_combination_id

LEFT OUTER JOIN PURCHASE_ORDERS po
    ON i.po_distribution_id = po.po_distribution_id
    
LEFT OUTER JOIN REQUISITIONS req
    ON po.req_distribution_id = req.distribution_id

LEFT OUTER JOIN EMPLOYEES buyer
    ON po.po_converter = buyer.user_id
    
LEFT OUTER JOIN EMPLOYEES reqkey
    ON req.keyer = reqkey.employee_id
    
LEFT OUTER JOIN EMPLOYEES podist
    ON po.po_dist_creator = podist.user_id

WHERE 
--    po.po_number = '273457'
--    i.invoice_date > '15-APR-2022'
--    AND gla.cost_center_code = '41183'
--    i.invoice_id = '2449121'
    i.invoice_dist_gl_date BETWEEN '01-JUL-2019' AND '30-JUN-2020'
    AND gla.department = '03 Management and Finance'

ORDER BY 
    i.invoice_date DESC
    ,s.supplier_name
    ,i.invoice_number
    ,i.invoice_dist_line_number