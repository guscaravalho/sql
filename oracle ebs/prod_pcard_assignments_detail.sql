WITH
    pcards AS
        (SELECT
            c.card_id
            ,cc.ccnumber                AS card_number
            ,cc.masked_cc_number        AS card_number_masked    
            ,c.limit_override_amount    AS card_charge_limit
            ,cc.expirydate              AS card_expiration_date
            ,(CASE
                WHEN cc.expirydate > sysdate THEN 'Valid'
                ELSE 'Not Valid' END)
                                        AS card_validity
            ,(CASE
                WHEN cc.active_flag = 'Y' THEN 'Active'
                WHEN cc.active_flag = 'N' THEN 'Not Active' END)
                                        AS card_status
            ,INITCAP(cc.chname)         AS name_on_card 
            ,TRUNC(cc.creation_date)    AS create_date
            ,c.created_by               AS creator_user_id
            ,TRUNC(cc.last_update_date) AS last_update_date
            ,c.last_updated_by          AS last_updater_user_id
            ,cc.active_flag
            ,cc.expired_flag
            ,c.card_reference_id
            ,cc.instrid
            ,c.employee_id              AS cc_holder_employee_id
            ,c.attribute1               AS cc_manager_employee_id
                            
        FROM AP_CARDS_ALL c

        LEFT OUTER JOIN IBY_CREDITCARD cc
            ON c.card_reference_id = cc.instrid)

    ,employees AS 
        (SELECT 
            e.employee_id
            ,e.assignment_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
            ,e.global_name ||' '||e.employee_num
                                            AS employee_name_number
            ,u.user_id                      AS user_id
            ,e.inactive_date                AS employee_inactive_date
            ,(CASE   
                WHEN e.inactive_date IS NULL THEN 'Active Employee'
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
    pc.card_id
    ,pc.card_number
    ,pc.card_number_masked    
    ,holder.employee_name           AS card_holder_name
    ,holder.employee_status         AS card_holder_status
    ,holder.employee_name_number    AS cc_holder_name_number
    ,holder.department              AS card_holder_department
    ,manager.employee_name          AS card_manager_name
    ,manager.employee_name_number   AS cc_manager_name_number
    ,pc.card_charge_limit
    ,pc.card_expiration_date
    ,pc.card_validity
    ,pc.card_status
    ,pc.name_on_card 
    ,pc.create_date
    ,(CASE
        WHEN pc.creator_user_id = '72912' THEN 'Kumar, Deepak'
        WHEN pc.creator_user_id = '72915' THEN 'Kumar, Sravan'
        WHEN pc.creator_user_id = '72911' THEN 'Anand, Sunil'
        WHEN pc.creator_user_id = '60511' THEN 'ACGA_SCHEDULER'
        ELSE creator.employee_name END)
                                    AS created_by
    ,pc.last_update_date
    ,(CASE
        WHEN pc.last_updater_user_id = '72912' THEN 'Kumar, Deepak'
        WHEN pc.last_updater_user_id = '72915' THEN 'Kumar, Sravan'
        WHEN pc.last_updater_user_id = '72911' THEN 'Anand, Sunil'
        WHEN pc.last_updater_user_id = '60511' THEN 'ACGA_SCHEDULER'
        ELSE updater.employee_name END)
                                    AS last_updated_by
    ,pc.active_flag
    ,pc.expired_flag
    ,pc.card_reference_id
    ,pc.instrid
    ,pc.cc_holder_employee_id
    ,pc.cc_manager_employee_id
    ,pc.creator_user_id
    ,pc.last_updater_user_id
    ,TRUNC(sysdate)             AS report_run_date

FROM PCARDS pc
    
LEFT OUTER JOIN EMPLOYEES holder
    ON pc.cc_holder_employee_id = holder.employee_id
    
LEFT OUTER JOIN EMPLOYEES manager
    ON pc.cc_manager_employee_id = manager.employee_id
    
LEFT OUTER JOIN EMPLOYEES creator
    ON pc.creator_user_id = creator.user_id
    
LEFT OUTER JOIN EMPLOYEES updater
    ON pc.last_updater_user_id = updater.user_id

WHERE
    pc.card_validity = 'Valid'
--    AND holder.employee_status = 'Active Employee'
    AND holder.department = '03 Management and Finance'

ORDER BY 
    holder.employee_name