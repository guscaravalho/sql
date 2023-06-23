WITH 
    gl_segment_values AS
        (SELECT 
            fv.flex_value_id                             			AS flex_value_id
            ,fv.flex_value                                          AS flex_value
            ,fv.flex_value_meaning                        			AS segment_code
            ,fv.description                               			AS segment_name
            ,fv.flex_value_meaning||' '||fv.description    	    	AS segment
            ,(CASE   
                WHEN fv.enabled_flag = 'Y' THEN 'Enabled'
                WHEN fv.enabled_flag = 'N' THEN 'Not Enabled'
                ELSE 'Error' END)                                   		
                                                                    AS segment_status
            ,(CASE 
                WHEN fv.end_date_active < sysdate OR fv.start_date_active > sysdate THEN 'Not Valid'
                ELSE 'Valid' END)                                   		
                                                                    AS segment_validity
            ,fv.start_date_active                         			AS valid_start_date
            ,fv.end_date_active                           			AS valid_end_date
            ,(CASE   
                WHEN fv.summary_flag = 'Y' THEN 'Parent'
                WHEN fv.summary_flag = 'N' THEN 'Child'
                ELSE 'Error' END)                                       		
                                                                    AS hierarchy_role
            ,TRUNC(fv.last_update_date)                   			AS last_update_date
            ,TRUNC(fv.created_date)                                 AS created_date
            ,fv.last_updated_by   
            ,fvs.flex_value_set_name                      			AS flex_value_set_name
            ,(CASE
                WHEN fvs.flex_value_set_name = 'ACGA_GL_FUND' THEN '1 Fund'
                WHEN fvs.flex_value_set_name = 'ACGA_GL_NATURAL_ACCOUNT' THEN '2 Natural Account'
                WHEN fvs.flex_value_set_name = 'ACGA_GL_COST_CENTER' THEN '3 Cost Center'
                WHEN fvs.flex_value_set_name = 'ACGA_GL_PROJECT' THEN '4 Project'
                WHEN fvs.flex_value_set_name = 'ACGA_GL_SOURCE_OF_FUNDS' THEN '5 Source of Funds'
                WHEN fvs.flex_value_set_name = 'ACGA_GL_TASK' THEN '6 Task' END)
                                                                    AS segment_type
            ,fv.flex_value_set_id                         			AS flex_value_set_id
       
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id)
    
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

SELECT 
    glsv.flex_value_id
    ,glsv.flex_value
    ,glsv.flex_value_set_name
    ,glsv.segment_type
    ,glsv.segment_code
    ,glsv.segment_name
    ,glsv.segment
    ,glsv.segment_status
    ,glsv.segment_validity
    ,glsv.valid_start_date
    ,glsv.valid_end_date
    ,glsv.hierarchy_role
    ,glsv.created_date
    ,glsv.last_update_date
    ,(CASE  
        WHEN emp.user_name = 'INITIAL SETUP' THEN 'Initial Setup'
        WHEN emp.user_name = 'SYSADMIN' THEN 'System Administrator'
        WHEN emp.user_name = 'AUTOINSTALL' THEN 'Auto Install'
        WHEN emp.user_name = 'PSHUKLA' THEN emp.description
        WHEN emp.employee_name IS NULL THEN emp.description
        ELSE emp.employee_name END)             			    
                                                            AS last_updated_by_name     
    ,emp.user_name                                 			AS last_updated_by_username
    ,glsv.last_updated_by                                   AS last_updated_by_user_id
    ,glsv.flex_value_set_id
    ,TRUNC(sysdate)                                         AS report_run_date
   
FROM GL_SEGMENT_VALUES glsv
    
LEFT OUTER JOIN EMPLOYEES emp
    ON glsv.last_updated_by = emp.user_id
    
WHERE 
/* List of the six GL segment names (the names of their flex value sets):
        'ACGA_GL_FUND'
        'ACGA_GL_NATURAL_ACCOUNT'
        'ACGA_GL_COST_CENTER'
        'ACGA_GL_PROJECT'
        'ACGA_GL_SOURCE_OF_FUNDS'
        'ACGA_GL_TASK'      */
    glsv.flex_value_set_name = 'ACGA_GL_TASK'

ORDER BY 
    glsv.segment_code