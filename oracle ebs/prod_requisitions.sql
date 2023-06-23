WITH
    requisitions AS
        (SELECT 
            prh.segment1||'-'||prl.line_num||'-'||prd.distribution_num
                                                    AS req_unique_id
            ,prh.segment1                           AS req_number                                      
            ,prl.line_num                           AS req_line_number                                      
            ,prd.distribution_id                    AS req_distribution_id
            ,INITCAP(prh.closed_code)               AS req_status
            ,INITCAP(prh.authorization_status)      AS req_workflow_phase
            ,prh.attribute1                         AS purchasing_authority_number
            ,prh.attribute4                         AS quick_quote_number
            ,(CASE   
                WHEN SUBSTR(prh.attribute1,1,1) = 'Q' THEN prh.attribute1||' '||prh.attribute4
                ELSE prh.attribute1 END)    
                                                    AS purchasing_authority
            ,(prl.unit_price * prl.quantity)        AS req_line_amount
            ,prd.distribution_num                   AS req_line_distribution_number
            ,INITCAP(prd.allocation_type)           AS distribution_allocation_type
            ,prd.allocation_value                   AS distribution_allocation_value
            ,prd.req_line_quantity                  AS distribution_amount
            ,TRUNC(prd.gl_encumbered_date)          AS req_line_gl_preencumbrance_date
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(TRUNC(prd.gl_encumbered_date),4,3)) IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(TRUNC(prd.gl_encumbered_date),8,4))+1)
                WHEN TO_CHAR(SUBSTR(TRUNC(prd.gl_encumbered_date),4,3)) IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(TRUNC(prd.gl_encumbered_date),8,4)) END)                   
                                                    AS gl_preencumbrance_fiscal_year
            ,(CASE
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'JUL'    THEN '01 JUL.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'AUG'    THEN '02 AUG.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'SEP'    THEN '03 SEP.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'OCT'    THEN '04 OCT.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'NOV'    THEN '05 NOV.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'DEC'    THEN '06 DEC.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'JAN'    THEN '07 JAN.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'FEB'    THEN '08 FEB.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'MAR'    THEN '09 MAR.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'APR'    THEN '10 APR.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'MAY'    THEN '11 MAY.'
                WHEN SUBSTR(TRUNC(prd.gl_encumbered_date),4,3) = 'JUN'    THEN '12 JUN.' END)   
                                                    AS gl_preencumbrance_month   
            ,prd.encumbered_amount                  AS req_line_preencumbered_amount
            ,prh.description                        AS req_header_description
            ,prh.note_to_authorizer                 AS req_header_notes
            ,prl.item_description                   AS req_line_description
            ,prl.note_to_agent                      AS req_line_note_to_buyer
            ,prh.preparer_id                        AS req_preparer_id
            ,prl.requester_email                    AS req_preparer_email
            ,prl.requester_phone                    AS req_preparer_phone
            ,TRUNC(prh.creation_date)               AS req_creation_date
            ,prh.approved_date                      AS req_approved_datetime
            ,prh.attribute2                         AS contact_person
            ,prh.attribute3                         AS contact_phone_number
            ,prh.attribute5                         AS po_ship_to_location
            ,prl.suggested_vendor_contact           AS supplier_contact_name
            ,prl.suggested_vendor_phone             AS supplier_contact_phone
            ,prl.category_id
            ,prd.code_combination_id                AS code_combination_id
            ,prh.requisition_header_id              AS req_header_id
            ,prl.vendor_id                          AS vendor_id
            ,prl.suggested_buyer_id                 AS suggested_buyer_id
            
        FROM PO_REQ_DISTRIBUTIONS_ALL prd
            
        LEFT OUTER JOIN PO_REQUISITION_LINES_ALL prl
            ON prd.requisition_line_id = prl.requisition_line_id
            
        LEFT OUTER JOIN PO_REQUISITION_HEADERS_ALL prh
            ON prl.requisition_header_id = prh.requisition_header_id)
    
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
        
    ,purchase_orders AS
        (SELECT
            pod.po_distribution_id
            ,pod.req_distribution_id
            ,poh.attribute1                                 AS purchasing_authority_number
            ,poh.attribute4                                 AS quick_quote_number
            ,(CASE
                WHEN SUBSTR(poh.attribute1,1,1) = 'Q' THEN poh.attribute1||' '||poh.attribute4
                ELSE poh.attribute1 END) 
                                                            AS purchasing_authority
            ,poh.segment1                                   AS po_number
            ,pol.line_num                                   AS po_line_number
            ,INITCAP(poh.closed_code)            			AS po_status
            ,INITCAP(pol.closed_code)            			AS po_line_status
            ,TRUNC(pod.gl_encumbered_date)                  AS po_line_gl_date
            
        FROM PO_DISTRIBUTIONS_ALL pod

        LEFT OUTER JOIN PO_HEADERS_ALL poh
            ON pod.po_header_id = poh.po_header_id
            
        LEFT OUTER JOIN PO_LINES_ALL pol
            ON pod.po_line_id = pol.po_line_id)
            
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
    req.req_unique_id
    ,req.req_status                         AS req_status
    ,req.req_workflow_phase                 AS req_workflow_phase
    ,INITCAP(TRIM(s.vendor_name))           AS supplier_name
    ,req.req_number                         AS req_number
    ,req.req_line_number                    AS req_line_number
    ,req.req_line_distribution_number       AS req_line_distribution_number
    ,req.req_line_amount                    AS req_line_amount
    ,req.distribution_allocation_type       AS distribution_allocation_type
    ,req.distribution_allocation_value      AS distribution_allocation_value
    ,req.distribution_amount                AS distribution_amount
    ,req.purchasing_authority_number
    ,req.quick_quote_number
    ,req.purchasing_authority               AS purchasing_authority
    ,po.po_number                           AS po_number
    ,po.po_line_number                      AS po_line_number
-- requisition dates
    ,req.req_line_gl_preencumbrance_date
    ,req.gl_preencumbrance_fiscal_year
    ,req.gl_preencumbrance_month
-- requisition detailed info
    ,reqprep.employee_name                  AS req_preparer_name
    ,req.req_preparer_email
    ,req.req_preparer_phone       
    ,buyer.employee_name                    AS req_buyer_name
    ,req.req_header_description             AS req_header_description
    ,req.req_header_notes                   AS req_header_notes
    ,req.req_line_description               AS req_line_description
    ,req.req_line_note_to_buyer             AS req_line_note_to_buyer
    ,req.req_creation_date                  AS req_creation_date
    ,req.req_approved_datetime              AS req_approved_datetime
-- additional supplier info
    ,req.supplier_contact_name              AS supplier_contact_name
    ,req.supplier_contact_phone             AS supplier_contact_phone
    ,req.contact_person                     AS contact_person
    ,req.contact_phone_number               AS contact_phone_number
    ,req.po_ship_to_location                AS po_ship_to_location
-- general ledger account info, includes _x fields for power platform use
    ,gla.department
    ,gla.fund_code
    ,gla.natural_account_code
    ,gla.cost_center_code
    ,gla.project_code
    ,gla.source_of_funds_code
    ,gla.task_code
    ,gla.fund_code||'_x'                    AS fund_code_x
    ,gla.natural_account_code||'_x'         AS natural_account_code_x
    ,gla.cost_center_code||'_x'             AS cost_center_code_x
    ,gla.project_code||'_x'                 AS project_code_x
    ,gla.source_of_funds_code||'_x'         AS source_of_funds_code_x
    ,gla.task_code||'_x'                    AS task_code_x
    ,req.req_line_gl_preencumbrance_date    AS gl_preencumbrace_date_x
    ,TRUNC(sysdate)                         AS report_run_date

-- id fields for reference
    ,req.req_header_id
    ,req.req_distribution_id
    ,req.vendor_id
    ,req.category_id
    
FROM REQUISITIONS req
    
LEFT OUTER JOIN EMPLOYEES reqprep
    ON req.req_preparer_id = reqprep.employee_id
    
LEFT OUTER JOIN EMPLOYEES buyer
    ON req.suggested_buyer_id = buyer.employee_id
    
LEFT OUTER JOIN AP_SUPPLIERS s
    ON req.vendor_id = s.vendor_id
    
LEFT OUTER JOIN GL_ACCOUNTS gla
    ON req.code_combination_id = gla.code_combination_id
    
LEFT OUTER JOIN PURCHASE_ORDERS po
    ON req.req_distribution_id = po.req_distribution_id

WHERE 
    gla.department = '22 Environmental Services'
    AND req.req_line_gl_preencumbrance_date BETWEEN '01-JUL-2022' AND '31-OCT-2022'
--    req.req_number = '324388'
    
ORDER BY
--    req.req_number,
--    req.req_creation_date DESC
    req.req_unique_id