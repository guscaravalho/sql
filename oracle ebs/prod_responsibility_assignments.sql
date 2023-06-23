WITH
    user_roles AS
        (SELECT
            user_name                   AS prism_user_name
            ,role_name                  AS responsibility_role_key
            ,TRUNC(start_date)          AS role_valid_start_date
            ,TRUNC(end_date)            AS role_valid_end_date
            ,(CASE
                WHEN TRUNC(end_date) IS NULL OR
                    TRUNC(end_date) >= TRUNC(sysdate) THEN 'Active'
                ELSE 'Not Active' END)
                                        AS role_status
            ,role_orig_system_id        AS responsibility_id
            ,TRUNC(creation_date)       AS role_create_date
            ,created_by                 AS role_created_by_user_id
            ,TRUNC(last_update_date)    AS role_last_update_date
            ,last_updated_by            AS role_last_updated_by_user_id
        
        FROM WF_USER_ROLE_ASSIGNMENTS
        
        WHERE 
            role_orig_system = 'FND_RESP')

    ,responsibilities AS
        (SELECT
            resp.responsibility_id
            ,resp.responsibility_key
            ,resptl.responsibility_name
            ,resptl.description                 AS responsibility_description
            ,TRUNC(resp.last_update_date)       AS last_update_date
            ,resp.last_updated_by               AS last_updated_by_user_id
            ,TRUNC(resp.creation_date)          AS create_date
            ,resp.created_by                    AS created_by_user_id
            ,resp.start_date
            ,resp.end_date
            ,resp.version                       AS responsibility_version

        FROM FND_RESPONSIBILITY resp

        LEFT OUTER JOIN FND_RESPONSIBILITY_TL resptl
            ON resp.responsibility_id = resptl.responsibility_id)

    ,employees AS 
        (SELECT 
            e.employee_id
            ,e.assignment_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
            ,e.global_name||' '||e.employee_num AS employee_name_number
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

    ,developers AS
        (SELECT
            user_id
            ,description    AS developer_name

        FROM FND_USER)
        
SELECT
    emp.department
    ,emp.employee_name
    ,emp.employee_number
    ,emp.employee_name_number
    ,emp.prism_user_name
    ,emp.employee_status

    ,resp.responsibility_name
    ,resp.responsibility_description
    
    ,role.role_valid_start_date
    ,role.role_valid_end_date
    ,role.role_status
    
    ,COALESCE(updater.employee_name,dev.developer_name)    AS role_last_updated_by
    ,role.role_last_update_date 
    
    ,resp.responsibility_id
    ,resp.responsibility_key
    ,resp.responsibility_version
    ,TRUNC(sysdate)                                     AS report_run_date

FROM USER_ROLES role

LEFT OUTER JOIN RESPONSIBILITIES resp
    ON SUBSTR(role.responsibility_role_key,INSTR(role.responsibility_role_key,'|',1,2) +1) =
        resp.responsibility_key||'|STANDARD'

LEFT OUTER JOIN EMPLOYEES emp
    ON role.prism_user_name = emp.prism_user_name
    
LEFT OUTER JOIN EMPLOYEES updater
    ON role.role_last_updated_by_user_id = updater.user_id
    
LEFT OUTER JOIN DEVELOPERS dev
    ON role.role_created_by_user_id = dev.user_id
    
WHERE
--    resp.responsibility_name LIKE '%%'
    emp.employee_name LIKE '%Caravalho%'

ORDER BY 
    resp.responsibility_name
    ,emp.employee_name