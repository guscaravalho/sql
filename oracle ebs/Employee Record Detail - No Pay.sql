WITH
    positions AS
        (SELECT 
            pos.position_id
            ,REGEXP_SUBSTR(pos.name, '[^.]+',1,4)   AS position_number
            ,REGEXP_SUBSTR(pos.name, '[^.]+',1,2)||' '||REGEXP_SUBSTR(pos.name, '[^.]+',1,1)  
                                                    AS position_job_class
            ,REGEXP_SUBSTR(pos.name, '[^.]+',1,3)   AS position_schedule
            ,pos.name                      			AS position_name
            ,(CASE  
                WHEN pos.availability_status_id = '1' THEN '1 Active'
                WHEN pos.availability_status_id = '4' THEN '4 Frozen'
                WHEN pos.availability_status_id = '5' THEN '5 Eliminated'
                ELSE TO_CHAR(pos.availability_status_id) END)                        
                                                    AS position_status 
            ,(CASE 
                WHEN pos.effective_end_date < sysdate OR pos.effective_start_date > sysdate THEN 'Not Valid'
                ELSE 'Valid' END)                                   		
                                                    AS position_validity
            ,pos.effective_start_date      			AS position_valid_start
            ,pos.effective_end_date        			AS position_valid_end
        FROM HR_ALL_POSITIONS_F pos)

    ,assignments AS
        (SELECT
        a.assignment_id
        ,a.effective_start_date                 AS assignment_valid_start
        ,a.effective_end_date                   AS assignment_valid_end
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
        ON a.grade_id = g.grade_id)

    ,employees AS 
        (SELECT 
            e.employee_id
            ,e.assignment_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
            ,e.global_name ||' '|| e.employee_num   AS employee_name_number
            ,e.employee_num ||' '|| e.global_name AS employee_number_name
            ,u.user_id
            ,u.user_name                    AS user_name
            ,e.inactive_date                AS employee_inactive_date
            ,(CASE   
                WHEN e.inactive_date IS NULL THEN 'Active'
                ELSE 'Not Active' END)
                                            AS employee_status
            ,e.organization_id
  
        FROM PER_EMPLOYEES_X e
        
        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id)
            
    ,orgs AS
        (SELECT
            o.organization_id
            ,o.location_id
            ,o.cost_allocation_keyflex_id
            ,o.type                         AS organization_type
            ,o.name                         AS organization_name
            ,(CASE
                WHEN SUBSTR(o.name,1,3) = 'AED' THEN '25 Economic Development'
                WHEN SUBSTR(o.name,1,3) = 'CAO' THEN '07 County Attorney'
                WHEN SUBSTR(o.name,1,3) = 'CBO' THEN '01 County Board'
                WHEN SUBSTR(o.name,1,3) = 'CCJ' THEN '11 Circuit Court Judiciary'
                WHEN SUBSTR(o.name,1,3) = 'CCT' THEN '12 Circuit Court Clerk'
                WHEN SUBSTR(o.name,1,3) = 'CMO' THEN '02 County Manager'
                WHEN SUBSTR(o.name,1,3) = 'COR' THEN '08 Commissioner of Revenue'
                WHEN SUBSTR(o.name,1,3) = 'CPH' THEN '26 Planning and Housing'
                WHEN SUBSTR(o.name,1,3) = 'CWA' THEN '15 Commonwealth''s Attorney'
                WHEN SUBSTR(o.name,1,3) = 'DES' THEN '22 Environmental Services'
                WHEN SUBSTR(o.name,1,3) = 'DHS' THEN '23 Human Services'
                WHEN SUBSTR(o.name,1,3) = 'DMF' THEN '03 Management and Finance'
                WHEN SUBSTR(o.name,1,3) = 'DPR' THEN '27 Parks and Recreation'
                WHEN SUBSTR(o.name,1,3) = 'DTS' THEN '06 Technology Services'
                WHEN SUBSTR(o.name,1,3) = 'FIR' THEN '21 Fire'
                WHEN SUBSTR(o.name,1,3) = 'GDC' THEN '13 District Court'
                WHEN SUBSTR(o.name,1,3) = 'HRD' THEN '05 Human Resources'
                WHEN SUBSTR(o.name,1,3) = 'JDR' THEN '14 Juvenile / Domestic Court'
                WHEN SUBSTR(o.name,1,3) = 'LIB' THEN '24 Libraries'
                WHEN SUBSTR(o.name,1,3) = 'MAG' THEN '16 Magistrate'
                WHEN SUBSTR(o.name,1,3) = 'OEM' THEN '20 Emergency Management'
                WHEN SUBSTR(o.name,1,3) = 'PDO' THEN '17 Public Defender'
                WHEN SUBSTR(o.name,1,3) = 'POL' THEN '19 Police'
                WHEN SUBSTR(o.name,1,3) = 'PPO' THEN '19 Police'
                WHEN SUBSTR(o.name,1,3) = 'PSC' THEN '20 Emergency Management'
                WHEN SUBSTR(o.name,1,3) = 'REG' THEN '10 Registrar'
                WHEN SUBSTR(o.name,1,3) = 'SRF' THEN '18 Sheriff'
                WHEN SUBSTR(o.name,1,3) = 'TRS' THEN '09 Treasurer'
                WHEN SUBSTR(o.name,1,3) = 'OFF' THEN '17 Public Defender'
                WHEN SUBSTR(o.name,1,3) = 'RET' THEN '30 Retirement'
                ELSE 'Error' END)
                                            AS department   
            ,o.date_from                    AS valid_date_start
            ,o.date_to                      AS valid_date_end
        FROM PER_ALL_ORGANIZATION_UNITS o
        ORDER BY o.name)

SELECT
--    DISTINCT ass.assignment_id
    ass.assignment_record_status                    AS record_status
    ,assorg.department                              AS assignment_department
    ,assorg.organization_name          	            AS assignment_org
    ,emp.employee_number              			    AS employee_number
    ,emp.employee_name               			    AS employee_name
    ,emp.user_name                                  AS prism_user_name
    ,pos.position_number                            AS position_number
    ,pos.position_job_class                         AS position_job_class
    ,pos.position_schedule                          AS position_schedule 
    ,ass.assignment_grade            		        AS assignment_grade
    ,ass.assignment_valid_start
    ,ass.assignment_valid_end       
    ,sup.employee_name           			        AS supervisor_name
    ,pos.position_name                              AS position_name
    ,pos.position_status                            AS position_status 
    ,pos.position_validity                          AS position_validity
    ,pos.position_valid_start
    ,pos.position_valid_end
    ,emp.employee_status
    ,emp.employee_inactive_date                       				
    ,ass.assignment_status
    ,emp.employee_name_number
    ,emp.employee_number_name                          				
    ,ass.assignment_status_type_id
    ,ass.grade_id
    ,pos.position_id
    ,ass.assignment_id
    ,ass.person_id                 			        AS assignment_person_id
    ,emp.employee_id

FROM ASSIGNMENTS ass

LEFT OUTER JOIN POSITIONS pos
    ON ass.position_id = pos.position_id

LEFT OUTER JOIN EMPLOYEES emp
    ON ass.person_id = emp.employee_id

LEFT OUTER JOIN EMPLOYEES sup
    ON ass.supervisor_id = sup.employee_id

LEFT OUTER JOIN ORGS assorg
    ON ass.organization_id = assorg.organization_id

WHERE 
    ass.assignment_valid_start BETWEEN pos.position_valid_start AND pos.position_valid_end
    AND
    ass.assignment_valid_end >= pos.position_valid_start
    AND 
    emp.employee_name LIKE '%Caravalho%'
--    pos.position_number = '008326'

ORDER BY 
    emp.employee_name
    ,ass.assignment_valid_start DESC
