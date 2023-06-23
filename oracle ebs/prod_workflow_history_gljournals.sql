WITH 
    gl_journals AS
        (SELECT
            glh.je_header_id
            ,(CASE  
                WHEN glh.actual_flag = 'A' THEN 'Actual'
                WHEN glh.actual_flag = 'B' THEN 'Budget'
                WHEN glh.actual_flag = 'E' THEN 'Encumbrance' END)
                                                    AS je_type
            ,gljc.user_je_category_name             AS je_category     
            ,glh.name                               AS je_header_name
            ,glh.description                        AS je_header_description
            ,glh.running_total_accounted_dr         AS debit
            ,glh.running_total_accounted_cr         AS credit
            ,COALESCE(glh.running_total_accounted_dr,0) - COALESCE(glh.running_total_accounted_cr,0)
                                                    AS net_amount
            ,glh.created_by                         AS journal_author_user_id
            ,TRUNC(glh.creation_date)               AS create_date
            ,glh.posted_date                        AS posted_datetime
            ,glh.default_effective_date             AS effective_date
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(glh.default_effective_date,4,3)) 
                IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(glh.default_effective_date,8,4))+1)
                WHEN TO_CHAR(SUBSTR(glh.default_effective_date,4,3)) 
                IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(glh.default_effective_date,8,4)) END)					
                                                    AS fiscal_year
            ,(CASE
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'JUL' THEN '01 JUL.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'AUG' THEN '02 AUG.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'SEP' THEN '03 SEP.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'OCT' THEN '04 OCT.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'NOV' THEN '05 NOV.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'DEC' THEN '06 DEC.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'JAN' THEN '07 JAN.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'FEB' THEN '08 FEB.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'MAR' THEN '09 MAR.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'APR' THEN '10 APR.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'MAY' THEN '11 MAY.'
                WHEN SUBSTR(glh.default_effective_date,4,3) = 'JUN' THEN '12 JUN.' END)   
                                                    AS fiscal_month
            ,glh.period_name                        AS accounting_period
            ,glh.je_batch_id
            ,glb.name                               AS je_batch_name
            ,glb.description                        AS je_batch_description   
            
        FROM GL_JE_HEADERS glh

        LEFT OUTER JOIN GL_JE_BATCHES glb
            ON glh.je_batch_id = glb.je_batch_id
            
        LEFT OUTER JOIN GL_JE_CATEGORIES gljc
            ON glh.je_category = gljc.je_category_name)
            
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
    ,j.fiscal_year
    ,j.fiscal_month
    ,j.accounting_period
    ,j.create_date
    ,j.effective_date
    ,j.je_type
    ,j.je_category
    ,j.je_batch_name
    ,j.je_header_name
    ,j.je_header_description
    ,j.debit
    ,j.credit
    ,j.net_amount
    ,author.department                       AS department
    ,author.employee_name                    AS journal_author
    ,w.workflow_action_timestamp
    ,w.workflow_action_date
    ,w.workflow_action_time
    ,approv.employee_name                    AS approver_name
    ,w.workflow_step_status
    ,w.workflow_level
    ,j.je_header_id
    ,j.je_batch_id
    ,w.transaction_id
    ,w.trans_history_id
    ,TRUNC(sysdate)                         AS report_run_date

FROM GL_JOURNALS j

LEFT OUTER JOIN WORKFLOW w
    ON j.je_batch_id = w.transaction_id

LEFT OUTER JOIN EMPLOYEES approv
    ON w.approver_username = approv.prism_user_name

LEFT OUTER JOIN EMPLOYEES author
    ON j.journal_author_user_id = author.user_id

WHERE
    w.workflow_name = 'GL Journal Approval'
    AND j.create_date > '01-NOV-2022'
    AND j.je_header_name LIKE 'DES-CC-Budbal%'
    --AND author.department = '22 Environmental Services'

ORDER BY
    w.transaction_id DESC
    ,w.trans_history_id DESC