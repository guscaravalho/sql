WITH
    gl_accounts AS
        (SELECT
            glcc.code_combination_id
            ,(CASE   	
                WHEN glcc.account_type = 'R' THEN 'Revenue'
                WHEN glcc.account_type = 'E' THEN 'Expenditure'
                WHEN glcc.account_type = 'A' THEN 'Asset'
                WHEN glcc.account_type = 'O' THEN 'Owner''s Equity'
                WHEN glcc.account_type = 'L' THEN 'Liability'
                ELSE 'Error' END)                   		
                                                            AS account_type
            ,(CASE   
                WHEN glcc.enabled_flag = 'Y' THEN 'Enabled'
                WHEN glcc.enabled_flag = 'N' THEN 'Not Enabled'
                ELSE 'Error' END)                     		
                                                            AS string_status
            ,(CASE 
                WHEN glcc.end_date_active < sysdate OR glcc.start_date_active > sysdate THEN 'Not Valid'
                ELSE 'Valid' END)                     		
                                                            AS string_validity
            ,glcc.start_date_active                  		AS valid_start_date
            ,glcc.end_date_active                    		AS valid_end_date
            ,glcc.last_updated_by
            ,TRUNC(glcc.last_update_date)    		        AS last_update_date                           
            ,(CASE 
                WHEN glcc.detail_posting_allowed_flag = 'Y' THEN 'Posting Allowed'
                WHEN glcc.detail_posting_allowed_flag = 'N' THEN 'Posting Not Allowed'
                ELSE 'Error' END)                     
                                                            AS posting_status
            ,(CASE 
                WHEN glcc.detail_budgeting_allowed_flag = 'Y' THEN 'Budgeting Allowed'
                WHEN glcc.detail_budgeting_allowed_flag = 'N' THEN 'Budgeting Not Allowed'
                ELSE 'Error' END)                     
                                                            AS budgeting_status
            ,glcc.segment1                                  AS fund_code
            ,glcc.segment2                                  AS natural_account_code
            ,glcc.segment3                                  AS cost_center_code
            ,glcc.segment4                                  AS project_code
            ,glcc.segment5                                  AS source_of_funds_code
            ,glcc.segment6                                  AS task_code
            ,glcc.segment1||'.'||glcc.segment2||'.'||glcc.segment3||'.'||
                glcc.segment4||'.'||glcc.segment5||'.'||glcc.segment6
                                                            AS account_string_concat
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
            ,u.user_id                                      AS user_id
            ,u.user_name                                    AS user_name
            ,u.description                                  AS description
            
        FROM PER_EMPLOYEES_X e

        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id)

    ,funds AS
        (SELECT 
            fv.flex_value_meaning       AS fund_code
            ,fv.description             AS fund_name
            ,fv.flex_value_meaning||' '||fv.description AS fund
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_FUND')

    ,natural_accounts AS
        (SELECT 
            fv.flex_value_meaning       AS natural_account_code
            ,fv.description             AS natural_account_name
            ,fv.flex_value_meaning||' '||fv.description AS natural_account
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_NATURAL_ACCOUNT')
            
    ,cost_centers AS
        (SELECT 
            fv.flex_value_meaning       AS cost_center_code
            ,fv.description             AS cost_center_name
            ,fv.flex_value_meaning||' '||fv.description AS cost_center

        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_COST_CENTER')
            
    ,projects AS
        (SELECT 
            fv.flex_value_meaning       AS project_code
            ,fv.description             AS project_name
            ,fv.flex_value_meaning||' '||fv.description AS project

        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_PROJECT')

    ,sources_of_funds AS
        (SELECT 
            fv.flex_value_meaning       AS source_of_funds_code
            ,fv.description             AS source_of_funds_name
            ,fv.flex_value_meaning||' '||fv.description AS source_of_funds

        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_SOURCE_OF_FUNDS')
            
    ,tasks AS
        (SELECT 
            fv.flex_value_meaning       AS task_code
            ,fv.description             AS task_name
            ,fv.flex_value_meaning||' '||fv.description AS task
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_TASK')
            
SELECT  
    gla.code_combination_id
    ,gla.account_type
    ,gla.department   
    ,gla.fund_code
    ,f.fund_name
    ,f.fund
    ,gla.natural_account_code
    ,na.natural_account_name
    ,na.natural_account
    ,gla.cost_center_code
    ,cc.cost_center_name
    ,cc.cost_center
    ,gla.project_code
    ,p.project_name
    ,p.project
    ,gla.source_of_funds_code
    ,sof.source_of_funds_name
    ,sof.source_of_funds
    ,gla.task_code
    ,t.task_name
    ,t.task
    ,gla.account_string_concat
    ,gla.string_status
    ,gla.string_validity
    ,gla.valid_start_date
    ,gla.valid_end_date
    ,gla.posting_status
    ,gla.budgeting_status
    ,gla.last_update_date
    ,(CASE   
        WHEN emp.user_name = 'AUTOINSTALL' THEN 'Auto Install'
        WHEN emp.employee_name IS NULL THEN emp.description
        ELSE emp.employee_name END)               		
                                                        AS last_updated_by_name
    ,emp.user_name                             			AS last_updated_by_username
        
FROM GL_ACCOUNTS gla

LEFT OUTER JOIN FUNDS f
    ON gla.fund_code = f.fund_code
    
LEFT OUTER JOIN NATURAL_ACCOUNTS na
    ON gla.natural_account_code = na.natural_account_code
    
LEFT OUTER JOIN COST_CENTERS cc
    ON gla.cost_center_code = cc.cost_center_code
    
LEFT OUTER JOIN PROJECTS p
    ON gla.project_code = p.project_code
    
LEFT OUTER JOIN SOURCES_OF_FUNDS sof
    ON gla.source_of_funds_code = sof.source_of_funds_code
    
LEFT OUTER JOIN TASKS t
    ON gla.task_code = t.task_code
 
LEFT OUTER JOIN EMPLOYEES emp
    ON gla.last_updated_by = emp.user_id
    
WHERE
    gla.project_code <> 'T' AND gla.source_of_funds_code <> 'T' AND gla.task_code <> 'T'
    AND gla.department = '01 County Board'

ORDER BY 
    gla.fund_code
    ,gla.cost_center_code
    ,gla.natural_account_code