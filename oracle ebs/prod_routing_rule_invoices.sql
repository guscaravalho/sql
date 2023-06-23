WITH
    flex_values AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fvs.description            AS flex_value_set_description
            ,fv.flex_value_id
            ,fv.flex_value
            ,REGEXP_SUBSTR(fv.flex_value, '[^-]+',1,2)  AS author_position_name
            ,fv.flex_value_meaning      AS person_or_role
            ,fv.description             AS approver_position_name
            ,fv.enabled_flag
            ,(CASE 
                WHEN fv.enabled_flag = 'Y' THEN 'Enabled'
                WHEN fv.enabled_flag = 'N' THEN 'Not Enabled' END) 						
                                                    AS rule_status
            ,(CASE 
                WHEN fv.end_date_active < sysdate OR fv.start_date_active > sysdate
                THEN 'Not Valid' ELSE 'Valid' END)
                                                    AS rule_validity
            ,fv.start_date_active           AS valid_start_date
            ,fv.end_date_active             AS valid_end_date
            ,TRUNC(fv.last_update_date)     AS last_update_date
            ,fv.last_updated_by
            ,fv.creation_date
            ,fv.created_by
            ,fv.value_category
            ,fv.attribute1
            ,fv.attribute2
            ,fv.attribute3
            ,fv.attribute4
            ,fv.attribute5
            ,fv.attribute6
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,3) = 'AED' THEN '25 Economic Development'
                WHEN SUBSTR(fv.flex_value,1,3) = 'CAO' THEN '07 County Attorney'
                WHEN SUBSTR(fv.flex_value,1,3) = 'CBO' THEN '01 County Board'
                WHEN SUBSTR(fv.flex_value,1,3) = 'CCJ' THEN '11 Circuit Court Judiciary'
                WHEN SUBSTR(fv.flex_value,1,3) = 'CCT' THEN '12 Circuit Court Clerk'
                WHEN SUBSTR(fv.flex_value,1,3) = 'CMO' THEN '02 County Manager'
                WHEN SUBSTR(fv.flex_value,1,3) = 'COR' THEN '08 Commissioner of Revenue'
                WHEN SUBSTR(fv.flex_value,1,3) = 'CPH' THEN '26 Planning and Housing'
                WHEN SUBSTR(fv.flex_value,1,3) = 'CWA' THEN '15 Commonwealth''s Attorney'
                WHEN SUBSTR(fv.flex_value,1,3) = 'DES' THEN '22 Environmental Services'
                WHEN SUBSTR(fv.flex_value,1,3) = 'DHS' THEN '23 Human Services'
                WHEN SUBSTR(fv.flex_value,1,3) = 'DMF' THEN '03 Management and Finance'
                WHEN SUBSTR(fv.flex_value,1,3) = 'DPR' THEN '27 Parks and Recreation'
                WHEN SUBSTR(fv.flex_value,1,3) = 'DTS' THEN '06 Technology Services'
                WHEN SUBSTR(fv.flex_value,1,3) = 'FIR' THEN '21 Fire'
                WHEN SUBSTR(fv.flex_value,1,3) = 'GDC' THEN '13 District Court'
                WHEN SUBSTR(fv.flex_value,1,3) = 'HRD' THEN '05 Human Resources'
                WHEN SUBSTR(fv.flex_value,1,3) = 'JDR' THEN '14 Juvenile / Domestic Court'
                WHEN SUBSTR(fv.flex_value,1,3) = 'LIB' THEN '24 Libraries'
                WHEN SUBSTR(fv.flex_value,1,3) = 'MAG' THEN '16 Magistrate'
                WHEN SUBSTR(fv.flex_value,1,3) = 'OEM' THEN '20 Emergency Management'
                WHEN SUBSTR(fv.flex_value,1,3) = 'PDO' THEN '17 Public Defender'
                WHEN SUBSTR(fv.flex_value,1,3) = 'POL' THEN '19 Police'
                WHEN SUBSTR(fv.flex_value,1,3) = 'PPO' THEN '19 Police'
                WHEN SUBSTR(fv.flex_value,1,3) = 'PSC' THEN '20 Emergency Management'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('REG','VOT') THEN '10 Registrar'
                WHEN SUBSTR(fv.flex_value,1,3) = 'SRF' THEN '18 Sheriff'
                WHEN SUBSTR(fv.flex_value,1,3) = 'TRS' THEN '09 Treasurer'
                WHEN SUBSTR(fv.flex_value,1,3) = 'OFF' THEN '17 Public Defender'
                WHEN SUBSTR(fv.flex_value,1,3) = 'RET' THEN '30 Retirement' END)
                                            AS department     

        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACG_APINV_DEPT_APPROVER_VS')
    
    ,positions AS
        (SELECT     
            p.position_id
            ,p.effective_start_date
            ,p.effective_end_date
            ,p.organization_id
            ,p.name                     AS position_name_concat
            ,p.fte
            ,p.max_persons
            ,p.availability_status_id
            ,pd.position_definition_id
            ,pd.segment1                AS job_class_number
            ,pd.segment2                AS job_class_name
            ,pd.segment2||' '||pd.segment1  AS job_class
            ,pd.segment3                AS position_schedule_code
            ,fv.description             AS position_schedule
            ,pd.segment4                AS position_number
            
        FROM HR_ALL_POSITIONS_F p

        LEFT OUTER JOIN PER_POSITION_DEFINITIONS pd
            ON p.position_definition_id = pd.position_definition_id
            
        LEFT OUTER JOIN FND_FLEX_VALUES_VL fv
            ON pd.segment3 = fv.flex_value
        
        INNER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            AND fvs.flex_value_set_name = 'ACGA_HR_POS_CAT'
            
        WHERE
            p.effective_end_date > sysdate
            AND availability_status_id <> 5)

    ,assignments AS
        (SELECT
            a.assignment_id
            ,a.effective_start_date
            ,a.effective_end_date
            ,(CASE 
                WHEN MAX(a.effective_start_date) OVER (PARTITION BY a.person_id) = a.effective_start_date
                AND MAX(a.effective_end_date) OVER (PARTITION BY a.person_id) = a.effective_end_date
                THEN 'Current Record'
                ELSE 'Historic' END)                AS assignment_record_status
            ,a.person_id
            ,a.position_id
            ,a.supervisor_id
            ,a.organization_id
            ,a.assignment_status_type_id 
            ,a.grade_id
            ,g.name                      		    AS assignment_grade
            ,astat.user_status              	    AS assignment_status                          				
            
        FROM PER_ALL_ASSIGNMENTS_F a

        LEFT OUTER JOIN PER_ASSIGNMENT_STATUS_TYPES astat
            ON a.assignment_status_type_id = astat.assignment_status_type_id
            
        LEFT OUTER JOIN PER_GRADES g
            ON a.grade_id = g.grade_id
            
        INNER JOIN PER_EMPLOYEES_X e
            ON a.assignment_id = e.assignment_id
            
        WHERE
            a.effective_end_date > sysdate
            AND e.inactive_date IS NULL)
               
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
            ON e.organization_id = org.organization_id
         
        WHERE
            e.inactive_date IS NULL)
    
SELECT
    fv.flex_value_id
    ,'Invoice Workflow Departmental Approvers'       AS workflow_name
    ,fv.department
    ,fv.person_or_role
    ,(CASE
        WHEN approver.employee_name IS NULL THEN '...vacant...'
            ELSE approver.employee_name END)
                                            AS approver_name
    ,fv.approver_position_name
    ,fv.rule_status
    ,fv.rule_validity
    ,fv.valid_start_date
    ,fv.valid_end_date
    ,fv.last_update_date
    ,updat.employee_name    AS last_update_by
    ,updat.prism_user_name  AS last_update_by_username
    ,fv.flex_value_set_name
    ,fv.flex_value_set_id
    ,fv.flex_value
    ,TRUNC(sysdate) AS report_run_date

FROM FLEX_VALUES fv

LEFT OUTER JOIN POSITIONS p
    ON fv.approver_position_name = p.position_name_concat

LEFT OUTER JOIN ASSIGNMENTS a
    ON p.position_id = a.position_id
    AND p.effective_end_date BETWEEN a.effective_start_date AND a.effective_end_date

LEFT OUTER JOIN EMPLOYEES approver
    ON a.assignment_id = approver.assignment_id
    
LEFT OUTER JOIN EMPLOYEES updat
    ON fv.last_updated_by = updat.user_id
    
ORDER BY
    fv.department
    ,approver.employee_name