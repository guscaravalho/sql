WITH 
    flex_values AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fv.flex_value_id
            ,fv.flex_value              AS project_code
            ,fv.flex_value_meaning
            ,fv.description             AS project_name
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
            fvs.flex_value_set_name = 'ACGA_GL_PROJECT'
            AND fv.flex_value NOT IN ('00715','T'))
            
    ,programs AS
        (SELECT 
            fv.flex_value                                       AS project_code
            ,fv.description                               	    AS project_name
            ,fv.flex_value||' '||fv.description    	    	    AS project
            ,fv.flex_value||'_x'                                AS project_code_x
            ,(CASE  
                WHEN fv.flex_value = 'PV' OR SUBSTR(fv.flex_value,1,3) IN ('PV0','PV1','PV2') 
                    THEN 'Paving Program'
                WHEN SUBSTR(fv.flex_value,1,2) = 'NF' OR SUBSTR(fv.flex_value,1,3) IN ('NF0','NF1','NF2') 
                    THEN 'Infiltration and Inflow Program'
                WHEN SUBSTR(fv.flex_value,1,2) = 'RL' OR SUBSTR(fv.flex_value,1,3) IN ('RL0','RL1','RL2') 
                    THEN 'Cleaning and Relining Program'
                WHEN fv.description LIKE '%Lease%' THEN 'Lease Program' END)
                                                                AS program
            ,fv.flex_value_id                             		AS flex_value_id
            ,fvs.flex_value_set_name                      		AS flex_value_set_name
            ,fv.flex_value_set_id                         		AS flex_value_set_id
           
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACGA_GL_PROJECT')

SELECT 
    p.project_code
    ,p.project_name
    ,p.project
    ,p.program
    ,fv.hierarchy_role
    ,fv.flex_value_status
    ,fv.flex_value_validity
    ,fv.valid_start_date
    ,fv.valid_end_date
    ,p.project_code_x
    ,fv.flex_value_id
    ,fv.flex_value_set_name

FROM FLEX_VALUES fv

LEFT OUTER JOIN PROGRAMS p
    ON fv.project_code = p.project_code
    
ORDER BY
    p.project_code