WITH 
    flex_values AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fvs.description            AS flex_value_set_description
            ,fv.flex_value_id
            ,fv.flex_value
            ,fv.flex_value_meaning
            ,fv.description             AS flex_value_description
            ,fv.enabled_flag
            ,(CASE 
                WHEN fv.enabled_flag = 'Y' THEN 'Enabled'
                WHEN fv.enabled_flag = 'N' THEN 'Not Enabled' END) 						
                                                    AS flex_value_status
            ,(CASE 
                WHEN fv.end_date_active < sysdate OR fv.start_date_active > sysdate
                THEN 'Not Valid' ELSE 'Valid' END)
                                        AS flex_value_validity
            ,fv.start_date_active       AS valid_start_date
            ,fv.end_date_active         AS valid_end_date
            ,TRUNC(fv.last_update_date) AS last_update_date
            ,fv.last_updated_by         AS last_update_by_user_id
            ,TRUNC(fv.creation_date)    AS create_date
            ,fv.created_by              AS created_by_user_id
            ,fv.value_category
            ,fv.attribute1
            ,fv.attribute2
            ,fv.attribute3
            ,fv.attribute4
            ,fv.attribute5
            ,fv.attribute6

        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id)

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
    fv.flex_value_set_id
    ,fv.flex_value_set_name
    ,fv.flex_value_set_description
    ,fv.flex_value_id
    ,fv.flex_value
    ,fv.flex_value_meaning
    ,fv.flex_value_description
    ,fv.flex_value_status
    ,fv.flex_value_validity
    ,fv.last_update_date
    ,fv.last_update_by_user_id
    ,updat.employee_name    AS fv_update_by
    ,updat.prism_user_name  AS fv_update_by_username
    ,fv.create_date
    ,fv.created_by_user_id
    ,creat.employee_name    AS fv_create_by
    ,creat.prism_user_name  AS fv_create_by_username
    ,fv.valid_start_date
    ,fv.valid_end_date
    ,fv.value_category
    ,fv.enabled_flag
    ,fv.attribute1
    ,fv.attribute2
    ,fv.attribute3
    ,fv.attribute4
    ,fv.attribute5

FROM FLEX_VALUES fv

LEFT OUTER JOIN EMPLOYEES creat
    ON fv.created_by_user_id = creat.user_id

LEFT OUTER JOIN EMPLOYEES updat
    ON fv.last_update_by_user_id = updat.user_id
    
WHERE
    fv.flex_value_set_name LIKE '%ACG_APINV_DEPT_APPROVER_VS%'
--    fv.flex_value LIKE '%%'

ORDER BY
    fv.flex_value_set_name
    ,fv.flex_value_id