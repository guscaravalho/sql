WITH
    employees AS
        (SELECT 
            e.employee_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
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
                WHEN SUBSTR(org.name,1,3) = 'RET' THEN '30 Retirement'
                ELSE 'Error' END)
                                            AS department 
            ,u.user_id                                      
            ,u.user_name
            
        FROM PER_EMPLOYEES_X e
        
        LEFT OUTER JOIN PER_ALL_ORGANIZATION_UNITS org
            ON e.organization_id = org.organization_id

        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id)
     
SELECT
    vl.user_profile_option_name
    ,o.bc_option_name           AS budget_control
    ,e.department
    ,e.employee_name
    ,e.user_name
    ,INITCAP(hierarchy_type)    AS hierarchy_type
    ,creat.employee_name        AS created_by
    ,v.creation_date            AS creation_datetime
    ,updat.employee_name        AS updated_by
    ,v.last_update_date         AS last_update_datetime
    ,TRUNC(v.last_update_date)  AS valid_date_start
    ,v.profile_option_value
    ,v.level_value              AS user_id
    ,v.application_id
    ,v.profile_option_id
    ,v.level_id

FROM FND_PROFILE_OPTION_VALUES v

LEFT OUTER JOIN FND_PROFILE_OPTIONS_VL vl
    ON v.profile_option_id = vl.profile_option_id

LEFT OUTER JOIN FND_APPLICATION_TL a
    ON v.level_value = a.application_id

LEFT OUTER JOIN GL_BC_OPTIONS o
    ON v.profile_option_value = o.bc_option_id
 
LEFT OUTER JOIN EMPLOYEES creat
    ON v.created_by = creat.user_id

LEFT OUTER JOIN EMPLOYEES updat
    ON v.last_updated_by = updat.user_id
    
LEFT OUTER JOIN EMPLOYEES e
    ON v.level_value = e.user_id

WHERE
    vl.user_profile_option_name like 'Budgetary Control Group'
    AND e.employee_name IS NOT NULL
    
ORDER BY 
    v.last_update_date DESC