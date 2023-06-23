WITH 
    flex_values AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fv.flex_value_id
            ,fv.flex_value              AS task_code
            ,fv.flex_value_meaning
            ,fv.description             AS task_name
            ,(CASE   
                WHEN fv.summary_flag = 'Y' THEN 'Parent'
                WHEN fv.summary_flag = 'N' THEN 'Child' END) AS hierarchy_role
            ,fv.enabled_flag
            ,(CASE
                WHEN fv.enabled_flag = 'Y' THEN 'Enabled'
                WHEN fv.enabled_flag = 'N' THEN 'Not Enabled' END)
                                        AS flex_value_status
            ,fv.start_date_active       AS valid_start_date
            ,fv.end_date_active         AS valid_end_date
            ,(CASE
                WHEN fv.start_date_active IS NULL AND fv.end_date_active IS NULL THEN 'Valid'
                WHEN fv.start_date_active IS NULL AND TRUNC(fv.end_date_active) > sysdate THEN 'Valid'
                WHEN fv.end_date_active IS NULL AND TRUNC(fv.start_date_active) < sysdate THEN 'Valid'
                WHEN sysdate BETWEEN TRUNC(fv.start_date_active) AND TRUNC(fv.end_date_active) THEN 'Valid' 
                ELSE 'Not Valid' END)
                                        AS flex_value_validity

        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_TASK')
            
    ,tasks AS
        (SELECT 
            fv.flex_value                                       AS task_code
            ,fv.description                               	    AS task_name
            ,fv.flex_value||' '||fv.description    	    	    AS task
            ,fv.flex_value||'_x'                                AS task_code_x

            ,fv.flex_value_id                             		AS flex_value_id
            ,fvs.flex_value_set_name                      		AS flex_value_set_name
            ,fv.flex_value_set_id                         		AS flex_value_set_id
           
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACGA_GL_TASK')

SELECT 
    t.task_code
    ,t.task_name
    ,t.task
    ,fv.hierarchy_role
    ,fv.flex_value_status
    ,fv.flex_value_validity
    ,fv.valid_start_date
    ,fv.valid_end_date
    ,t.task_code_x
    ,fv.flex_value_id
    ,fv.flex_value_set_name

FROM FLEX_VALUES fv

LEFT OUTER JOIN TASKS t
    ON fv.task_code = t.task_code
   
ORDER BY
    t.task_code