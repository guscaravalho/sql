WITH 

    invoices AS
        (SELECT
            DISTINCT ai.invoice_id
            ,ai.invoice_num                                  		AS invoice_number
            ,INITCAP(ai.invoice_type_lookup_code)                   AS invoice_source 
            ,TRUNC(ai.creation_date)                                AS invoice_create_date
            ,ai.created_by                                          AS invoice_author_user_id
            ,ai.invoice_date                                 		AS invoice_date
            ,ai.gl_date                                             AS effective_date        

            ,(CASE 
                WHEN TO_CHAR(SUBSTR(ai.gl_date,4,3)) IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(ai.gl_date,8,4))+1)
                WHEN TO_CHAR(SUBSTR(ai.gl_date,4,3)) IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(ai.gl_date,8,4)) END)    
                                                                    AS fiscal_year
            ,(CASE
                WHEN SUBSTR(ai.gl_date,4,3) = 'JUL'    THEN '01 JUL.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'AUG'    THEN '02 AUG.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'SEP'    THEN '03 SEP.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'OCT'    THEN '04 OCT.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'NOV'    THEN '05 NOV.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'DEC'    THEN '06 DEC.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'JAN'    THEN '07 JAN.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'FEB'    THEN '08 FEB.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'MAR'    THEN '09 MAR.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'APR'    THEN '10 APR.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'MAY'    THEN '11 MAY.'
                WHEN SUBSTR(ai.gl_date,4,3) = 'JUN'    THEN '12 JUN.' END)   
                                                                    AS fiscal_month                                                               
            ,ai.description                                  	    AS invoice_description
            ,ai.invoice_amount                                      AS invoice_amount
            ,poh.segment1                                           AS po_number
            ,poh.attribute1                                         AS purchasing_authority_number
            ,poh.attribute4                                         AS quick_quote_number
            ,(CASE
                WHEN SUBSTR(poh.attribute1,1,1) = 'Q' THEN poh.attribute1||' '||poh.attribute4
                ELSE poh.attribute1 END) 
                                                            AS purchasing_authority
            ,INITCAP(s.vendor_name)                                 AS supplier_name  
            ,ai.vendor_id
            ,ai.batch_id                                            AS invoice_batch_id

        FROM AP_INVOICES_ALL ai
        
        LEFT OUTER JOIN AP_INVOICE_LINES_ALL ail
            ON ai.invoice_id = ail.invoice_id
            
        LEFT OUTER JOIN PO_HEADERS_ALL poh
            ON ail.po_header_id = poh.po_header_id
            
        LEFT OUTER JOIN AP_SUPPLIERS s
            ON ai.vendor_id = s.vendor_id)
     
    ,workflow AS
        (SELECT
            tah.transaction_id
            ,tah.trans_history_id
            ,INITCAP(tah.status)                        AS workflow_step_status
            ,tah.order_number                           AS workflow_level
            ,tah.name                                   AS approver_username
            ,tah.row_timestamp                          AS workflow_action_timestamp
            ,TO_CHAR(tah.row_timestamp, 'MM/DD/YYYY')   AS workflow_action_date
            ,TO_CHAR(tah.row_timestamp, 'hh24:mi:ss')   AS workflow_action_time
            ,app.application_name                       AS workflow_name
            
        FROM AME_TRANS_APPROVAL_HISTORY tah

        LEFT OUTER JOIN AME_CALLING_APPS_TL app
            ON tah.application_id = app.application_id
            
        LEFT OUTER JOIN AME_ACTION_TYPES_TL att
            ON tah.action_type_id = att.action_type_id)              
    
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
    w.workflow_name
    ,i.fiscal_year
    ,i.fiscal_month
    ,i.invoice_create_date
    ,i.effective_date
    ,i.invoice_source
    ,i.supplier_name
    ,i.purchasing_authority_number
    ,i.quick_quote_number
    ,i.purchasing_authority
    ,i.po_number
    ,i.invoice_number
    ,i.invoice_description
    ,i.invoice_amount
    ,author.department                       AS department
    ,author.employee_name                    AS invoice_author
    ,w.workflow_action_timestamp
    ,w.workflow_action_date
    ,w.workflow_action_time
    ,approv.employee_name                    AS approver_name
    ,w.workflow_step_status
    ,w.workflow_level
    ,i.invoice_id
    ,i.invoice_batch_id
    ,w.transaction_id
    ,w.trans_history_id
    ,TRUNC(sysdate)                         AS report_run_date

FROM INVOICES i

LEFT OUTER JOIN WORKFLOW w
    ON i.invoice_id = w.transaction_id

LEFT OUTER JOIN EMPLOYEES approv
    ON w.approver_username = approv.prism_user_name

LEFT OUTER JOIN EMPLOYEES author
    ON i.invoice_author_user_id = author.user_id

WHERE
    w.workflow_name = 'Payables Invoice Approval'	
    AND i.invoice_create_date > '01-JAN-2023'
--    AND i.invoice_number = '%%'
    --AND author.department = '22 Environmental Services'

ORDER BY
    w.transaction_id DESC
    ,w.trans_history_id DESC