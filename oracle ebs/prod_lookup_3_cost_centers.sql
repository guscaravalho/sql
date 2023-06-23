WITH 
    flex_values AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fv.flex_value_id
            ,fv.flex_value              AS cost_center_code
            ,fv.flex_value_meaning
            ,fv.description             AS cost_center_name
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
            fvs.flex_value_set_name = 'ACGA_GL_COST_CENTER'
            AND fv.flex_value NOT IN ('00715','T','PVA','WVPA'))
            
    ,departments AS
        (SELECT 
            fv.flex_value                                       AS cost_center_code
            ,fv.description                               	    AS cost_center_name
            ,fv.flex_value||' '||fv.description    	    	    AS cost_center
            ,fv.flex_value||'_x'                                AS cost_center_code_x
            ,(CASE  
                WHEN SUBSTR(fv.flex_value,1,3) = '101'  THEN '01 County Board'
                WHEN SUBSTR(fv.flex_value,1,3) = '102'  THEN '02 County Manager'
                WHEN SUBSTR(fv.flex_value,1,3) = '103'  THEN '03 Management and Finance'
                WHEN SUBSTR(fv.flex_value,1,3) = '104'  THEN '04 Civil Service Commission'
                WHEN SUBSTR(fv.flex_value,1,2) = '12'   THEN '05 Human Resources'
                WHEN SUBSTR(fv.flex_value,1,2) = '13'   THEN '06 Technology Services'
                WHEN SUBSTR(fv.flex_value,1,3) = '141'  THEN '07 County Attorney'
                WHEN SUBSTR(fv.flex_value,1,3) = '142'  THEN '08 Commissioner of Revenue'
                WHEN SUBSTR(fv.flex_value,1,3) = '143'  THEN '09 Treasurer'
                WHEN SUBSTR(fv.flex_value,1,3) = '144'  THEN '10 Registrar'
                WHEN SUBSTR(fv.flex_value,1,3) = '201'  THEN '11 Circuit Court Judiciary'
                WHEN SUBSTR(fv.flex_value,1,3) = '202'  THEN '12 Circuit Court Clerk'
                WHEN SUBSTR(fv.flex_value,1,3) = '203'  THEN '13 District Court'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('204','206') THEN '14 Juvenile / Domestic Court'
                WHEN SUBSTR(fv.flex_value,1,3) = '207'  THEN '15 Commonwealth''s Attorney'
                WHEN SUBSTR(fv.flex_value,1,3) = '208'  THEN '16 Magistrate'
                WHEN SUBSTR(fv.flex_value,1,3) = '209'  THEN '17 Public Defender'
                WHEN SUBSTR(fv.flex_value,1,2) = '22'   THEN '18 Sheriff'
                WHEN SUBSTR(fv.flex_value,1,2) = '31'   THEN '19 Police'
                WHEN SUBSTR(fv.flex_value,1,2) = '32'   THEN '20 Emergency Management'
                WHEN SUBSTR(fv.flex_value,1,2) = '34'   THEN '21 Fire'
                WHEN SUBSTR(fv.flex_value,1,1) = '4'    THEN '22 Environmental Services'
                WHEN SUBSTR(fv.flex_value,1,1) = '5'    THEN '23 Human Services'
                WHEN SUBSTR(fv.flex_value,1,1) = '6'    THEN '24 Libraries'
                WHEN SUBSTR(fv.flex_value,1,2) = '71'   THEN '25 Economic Development'
                WHEN SUBSTR(fv.flex_value,1,2) = '72'   THEN '26 Planning and Housing'
                WHEN SUBSTR(fv.flex_value,1,1) = '8'    THEN '27 Parks and Recreation'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('910','911','912') 
                    OR SUBSTR(fv.flex_value,1,2) IN ('00','99') 
                    OR fv.flex_value = '10001' THEN '28 Non-Departmental'
                WHEN SUBSTR(fv.flex_value,1,3) = '913'  THEN '29 Schools'
                WHEN SUBSTR(fv.flex_value,1,3) = '914'  THEN '30 Retirement' END)
                                                                AS department
            ,(CASE
            -- 23 Human Services (DHS)
                WHEN SUBSTR(fv.flex_value,1,2) = '51'  THEN '01 Economic Independence Division'
                WHEN SUBSTR(fv.flex_value,1,2) = '52'  THEN '02 Behavioral Health Division'
                WHEN SUBSTR(fv.flex_value,1,2) = '53'  THEN '03 Aging and Disability Services Division'
                WHEN SUBSTR(fv.flex_value,1,2) = '54'  THEN '04 DHS Director''s Office'
                WHEN SUBSTR(fv.flex_value,1,2) = '55'  THEN '05 Public Health Division'
                WHEN SUBSTR(fv.flex_value,1,2) = '56'  THEN '06 Child and Family Services Division' END)
                                                                AS division
            ,fv.flex_value_id                             		AS flex_value_id
            ,fvs.flex_value_set_name                      		AS flex_value_set_name
            ,fv.flex_value_set_id                         		AS flex_value_set_id
           
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACGA_GL_COST_CENTER')

SELECT 
    d.cost_center_code
    ,d.cost_center_name
    ,d.cost_center
    ,d.department
    ,d.division  
    ,fv.hierarchy_role
    ,fv.flex_value_status
    ,fv.flex_value_validity
    ,fv.valid_start_date
    ,fv.valid_end_date
    ,d.cost_center_code_x
    ,fv.flex_value_id
    ,fv.flex_value_set_name

FROM FLEX_VALUES fv

LEFT OUTER JOIN DEPARTMENTS d
    ON fv.cost_center_code = d.cost_center_code
    
ORDER BY
    d.cost_center_code