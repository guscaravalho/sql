WITH
    invoices AS
        (SELECT
            DISTINCT ail.po_line_id
            ,MAX(ai.invoice_date) OVER (PARTITION BY ail.po_line_id) AS latest_invoice_date
        
        FROM AP_INVOICE_LINES_ALL ail

        LEFT OUTER JOIN AP_INVOICES_ALL ai
            ON ail.invoice_id = ai.invoice_id)
    
    ,purchase_orders AS
        (SELECT
            poh.attribute1                                  AS purchasing_authority_number
            ,poh.attribute4                                 AS quick_quote_number
            ,(CASE
                WHEN SUBSTR(poh.attribute1,1,1) = 'Q' THEN poh.attribute1||' '||poh.attribute4
                ELSE poh.attribute1 END) 
                                                            AS purchasing_authority
            ,poh.segment1                                   AS po_number
            ,pol.line_num                                   AS po_line_number
            ,poh.segment1||'-'||pol.line_num                AS po_number_line_number
            ,INITCAP(poh.authorization_status)   		    AS po_workflow_phase
            ,INITCAP(poh.closed_code)            			AS po_status
            ,INITCAP(pol.closed_code)            			AS po_line_status  
            ,TRUNC(poh.creation_date)            			AS po_created_date
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(poh.creation_date,4,3)) IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(poh.creation_date,8,4))+1)
                WHEN TO_CHAR(SUBSTR(poh.creation_date,4,3)) IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(poh.creation_date,8,4)) END)
                                                            AS po_created_fiscal_year
            ,TRUNC(poh.submit_date)                         AS po_submitted_date
            ,TRUNC(poh.revised_date)                        AS po_revised_date
            ,TRUNC(poh.approved_date)                       AS po_approved_date
            ,TRUNC(poh.printed_date)                        AS po_printed_date
            ,TRUNC(poh.closed_date)                         AS po_closed_date
            ,TRUNC(pol.closed_date)                         AS po_line_closed_date
            ,TRUNC(pod.gl_encumbered_date)       		    AS po_line_gl_date
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(pod.gl_encumbered_date,4,3)) IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(pod.gl_encumbered_date,8,4))+1)
                WHEN TO_CHAR(SUBSTR(pod.gl_encumbered_date,4,3)) IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(pod.gl_encumbered_date,8,4)) END)
                                                            AS po_line_gl_fiscal_year
            ,(CASE
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'JUL'    THEN '01 JUL.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'AUG'    THEN '02 AUG.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'SEP'    THEN '03 SEP.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'OCT'    THEN '04 OCT.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'NOV'    THEN '05 NOV.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'DEC'    THEN '06 DEC.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'JAN'    THEN '07 JAN.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'FEB'    THEN '08 FEB.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'MAR'    THEN '09 MAR.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'APR'    THEN '10 APR.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'MAY'    THEN '11 MAY.'
                WHEN SUBSTR(TRUNC(pod.gl_encumbered_date),4,3) = 'JUN'    THEN '12 JUN.' END)   
                                                            AS po_line_gl_month
            ,poh.comments                        			AS po_description
            ,pol.item_description                			AS po_line_description
            ,pol.unit_price
            ,pol.quantity
            ,pod.quantity_ordered
            ,(CASE
                WHEN pod.quantity_ordered < pol.quantity THEN pol.unit_price * pod.quantity_ordered
                ELSE pol.unit_price * pol.quantity END)     
                                                            AS obligation_original
            ,COALESCE(pod.amount_billed,0)                  AS liquidated
            ,(CASE
                WHEN pod.quantity_ordered < pol.quantity THEN pol.unit_price * pod.quantity_ordered
                ELSE pol.unit_price * pol.quantity END) 
            - COALESCE(pod.amount_billed,0)
                                                            AS obligation_remaining
            ,MAX(i.latest_invoice_date) OVER (PARTITION BY poh.segment1, pol.line_num)
                                                            AS po_line_latest_invoice_date
            ,pod.code_combination_id
            ,poh.vendor_id
            ,poh.created_by                                 AS po_converter_user_id
            ,poh.po_header_id
            ,pol.po_line_id
            ,pod.po_distribution_id
            ,pod.req_distribution_id
            
        FROM PO_DISTRIBUTIONS_ALL pod

        LEFT OUTER JOIN PO_HEADERS_ALL poh
            ON pod.po_header_id = poh.po_header_id
            
        LEFT OUTER JOIN PO_LINES_ALL pol
            ON pod.po_line_id = pol.po_line_id
        
        LEFT OUTER JOIN INVOICES i
            ON pol.po_line_id = i.po_line_id)

    ,gl_accounts AS
        (SELECT
            glcc.code_combination_id                AS code_combination_id
            ,glcc.segment1                          AS fund_code
            ,glcc.segment2                          AS natural_account_code
            ,glcc.segment3                          AS cost_center_code
            ,glcc.segment4                          AS project_code
            ,glcc.segment5                          AS source_of_funds_code
            ,glcc.segment6                          AS task_code
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

    ,natural_account_levels AS
        (SELECT 
            fv.flex_value                                       AS natural_account_code
            ,fv.description                               	    AS natural_account_name
            ,fv.flex_value||' '||fv.description    	    	    AS natural_account
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,1) = '1' THEN '1 Asset'
                WHEN SUBSTR(fv.flex_value,1,1) = '2' THEN '2 Liability'
                WHEN SUBSTR(fv.flex_value,1,3) BETWEEN '300' AND '348' 
                    OR SUBSTR(fv.flex_value,1,3) BETWEEN '350' AND '399' THEN '3 Revenue'
                WHEN SUBSTR(fv.flex_value,1,1) = '4' 
                    OR SUBSTR(fv.flex_value,1,3) = '349' THEN '4 Expenditure'
                WHEN SUBSTR(fv.flex_value,1,1) = '5' THEN '5 Owner''s Equity'
                WHEN fv.flex_value = '0' THEN '4 Expenditure'
                WHEN fv.flex_value = '1' THEN '1 Asset'
                WHEN fv.flex_value = '34511' THEN '3 Revenue'
                WHEN fv.flex_value = '48001' THEN '4 Expenditure'
                WHEN fv.flex_value = '53612' THEN '4 Expenditure'
                WHEN fv.flex_value = '900001' THEN '1 Asset'
                WHEN fv.flex_value = '990000' THEN '4 Expenditure'
                WHEN fv.flex_value = 'NE32' THEN '4 Expenditure'
                WHEN fv.flex_value = 'T' THEN '1 Asset'
                WHEN fv.flex_value = 'TASK' THEN '4 Expenditure' END)
                                                                AS natural_account_level_1
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACGA_GL_NATURAL_ACCOUNT')

    ,requisitions AS
        (SELECT 
            prd.distribution_id
            ,prh.segment1                           AS req_number
            ,prl.line_num                           AS req_line_number
            ,prh.preparer_id                        AS req_preparer_id
            ,prl.item_description                   AS item_description
            ,prl.suggested_buyer_id                 AS suggested_buyer_id

        FROM PO_REQ_DISTRIBUTIONS_ALL prd
            
        LEFT OUTER JOIN PO_REQUISITION_LINES_ALL prl
            ON prd.requisition_line_id = prl.requisition_line_id
            
        LEFT OUTER JOIN PO_REQUISITION_HEADERS_ALL prh
            ON prl.requisition_header_id = prh.requisition_header_id)

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
            
    ,employees AS
        (SELECT 
            e.employee_id
            ,e.employee_num                         AS employee_number
            ,e.global_name                          AS employee_name
            ,u.user_id                                      
            ,u.user_name
        FROM PER_EMPLOYEES_X e

        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id)
            
SELECT
    po.po_status
    ,po.po_workflow_phase
    ,poconvert.employee_name                AS po_converter_name
    ,s.supplier_name
    ,po.purchasing_authority_number
    ,po.quick_quote_number
    ,po.purchasing_authority
    ,po.po_number
    ,po.po_line_number
    ,po.po_number_line_number
    ,po.po_line_status
    ,po.po_description
    ,po.po_line_description
    ,po.obligation_original
    ,po.liquidated
    ,po.obligation_remaining
    ,gla.department
    ,nal.natural_account_level_1        AS account_class                  
    ,gla.fund_code                      			
    ,gla.natural_account_code              			
    ,gla.cost_center_code               			
    ,gla.project_code                    			
    ,gla.source_of_funds_code             			
    ,gla.task_code
    ,gla.fund_code||'_x'                AS fund_code_x                   			
    ,gla.natural_account_code||'_x'     AS natural_account_code_x                      			
    ,gla.cost_center_code||'_x'         AS cost_center_code_x                   			
    ,gla.project_code||'_x'             AS project_code_x                        			
    ,gla.source_of_funds_code||'_x'     AS source_of_funds_code_x                 			
    ,gla.task_code||'_x'                AS task_code_x
    ,po.po_line_gl_date                 AS gl_effective_date_x                          			
    ,po.po_created_date
    ,po.po_created_fiscal_year
    ,po.po_line_gl_date
    ,po.po_line_gl_fiscal_year
    ,po.po_line_gl_month
    ,po.po_approved_date
    ,po.po_printed_date
    ,po.po_line_latest_invoice_date
    ,po.po_closed_date
    ,po_line_closed_date   
    ,req.req_number 
    ,req.req_line_number
    ,req.item_description                   AS req_item_description                   		
    ,reqprep.employee_name                  AS req_preparer_name
    ,reqbuyer.employee_name                 AS req_buyer_name
    ,po.vendor_id
    ,po.po_converter_user_id
    ,po.po_header_id
    ,po.po_line_id
    ,po.po_distribution_id
    ,po.req_distribution_id

FROM PURCHASE_ORDERS po

--LEFT OUTER JOIN INVOICES i 
--    ON pol.po_line_id = i.po_line_id

LEFT OUTER JOIN SUPPLIERS s
    ON po.vendor_id = s.vendor_id

LEFT OUTER JOIN REQUISITIONS req
    ON po.req_distribution_id = req.distribution_id

LEFT OUTER JOIN GL_ACCOUNTS gla
    ON po.code_combination_id = gla.code_combination_id
    
LEFT OUTER JOIN NATURAL_ACCOUNT_LEVELS nal
    ON gla.natural_account_code = nal.natural_account_code
    
LEFT OUTER JOIN EMPLOYEES poconvert
    ON po.po_converter_user_id = poconvert.user_id

LEFT OUTER JOIN EMPLOYEES reqprep
    ON req.req_preparer_id = reqprep.employee_id
    
LEFT OUTER JOIN EMPLOYEES reqbuyer
    ON req.suggested_buyer_id = reqbuyer.employee_id

WHERE
    po.po_number = '267071'

ORDER BY 
    po.po_number_line_number