WITH
    positions AS
        (SELECT 
            pos.position_id
            ,pd.segment1                            AS job_class_number
            ,pd.segment2                            AS job_class_name
            ,pd.segment3                            AS position_schedule
            ,pd.segment4                            AS position_number
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
        FROM HR_ALL_POSITIONS_F pos
        
        LEFT OUTER JOIN PER_POSITION_DEFINITIONS pd
            ON pos.position_definition_id = pd.position_definition_id)

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
            
    ,pay_changes AS
        (SELECT
            ppp.pay_proposal_id
            ,ppp.assignment_id
            ,TO_CHAR(ppp.proposed_salary_n,'999.99')         AS rate_of_pay
            ,TO_CHAR(ppp.proposed_salary_n * 2080, '999,999.99')                
                                                            AS annual_salary
            ,(CASE
                WHEN ppp.proposal_reason = 'NEWH'    THEN 'New Hire'
                WHEN ppp.proposal_reason = 'PROM'    THEN 'Promotion'
                WHEN ppp.proposal_reason = 'MI'      THEN 'Merit Increase'
                WHEN ppp.proposal_reason = 'MPA'     THEN 'Merit Pay Adjustment'
                WHEN ppp.proposal_reason = 'API'     THEN 'Annual Performance Increase'
                WHEN ppp.proposal_reason = 'RCLS'    THEN 'Reclassification'   
                END)
                                                            AS pay_adjustment_reason
            ,(CASE
                WHEN a.assignment_record_status = 'Current Record' AND 
                    MAX(ppp.change_date) OVER (PARTITION BY ppp.assignment_id) = ppp.change_date
                THEN 'Current Record'
                ELSE 'Historic' END)                        AS pay_record_status
            ,ppp.proposal_reason                            AS pay_adjustment_code
            ,ppp.change_date                                AS pay_effective_date
            ,ppp.approved                                   AS approved_flag
            ,ppp.last_change_date                           AS previous_pay_effective_date
            --,ppp.change_date - ppp.last_change_date         AS days_between_pay_changes
            --,ppp.created_by
            --,ppp.creation_date
            --,ppp.last_updated_by
            --,ppp.last_update_date

            FROM PER_PAY_PROPOSALS ppp
            
            LEFT OUTER JOIN ASSIGNMENTS a
                ON ppp.assignment_id = a.assignment_id
                AND ppp.change_date  BETWEEN a.assignment_valid_start AND a.assignment_valid_end

            ORDER BY 
                ppp.change_date DESC)
            
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
    DISTINCT a.assignment_id
    ,pc.pay_record_status                           AS record_status
    ,assorg.department                              AS assignment_department
    ,assorg.organization_name          	            AS assignment_org
    ,emp.employee_number              			    AS employee_number
    ,emp.employee_name               			    AS employee_name
    ,emp.user_name                                  AS prism_user_name
    ,pos.position_number
    ,pos.job_class_name
    ,pos.job_class_number
    ,pos.position_schedule
    ,a.assignment_grade            		            AS assignment_grade
     
    ,pc.rate_of_pay
    ,pc.annual_salary
    ,pc.pay_effective_date
    ,pc.pay_adjustment_code
    ,pc.pay_adjustment_reason

    ,a.assignment_valid_start
    ,a.assignment_valid_end       
    ,sup.employee_name           			        AS supervisor_name
    ,pos.position_name
    ,pos.position_status                            AS position_status 
    ,pos.position_validity                          AS position_validity
    ,pos.position_valid_start
    ,pos.position_valid_end
    ,emp.employee_status
    ,emp.employee_inactive_date                       				
    ,a.assignment_status                          				
    ,a.assignment_status_type_id
    ,a.grade_id
    ,pos.position_id
    ,a.assignment_id
    ,emp.assignment_id             			        AS employee_assignment_id
    ,a.person_id                 			        AS assignment_person_id
    ,emp.employee_id
 
FROM ASSIGNMENTS a

LEFT OUTER JOIN POSITIONS pos
    ON a.position_id = pos.position_id

LEFT OUTER JOIN EMPLOYEES emp
    ON a.person_id = emp.employee_id

LEFT OUTER JOIN EMPLOYEES sup
    ON a.supervisor_id = sup.employee_id

LEFT OUTER JOIN ORGS assorg
    ON a.organization_id = assorg.organization_id
    
LEFT OUTER JOIN PAY_CHANGES pc
    ON a.assignment_id = pc.assignment_id
    AND pc.pay_effective_date BETWEEN a.assignment_valid_start AND a.assignment_valid_end

WHERE 
    a.assignment_valid_start BETWEEN pos.position_valid_start AND pos.position_valid_end
    AND a.assignment_valid_end >= pos.position_valid_start
    AND pc.rate_of_pay IS NOT NULL
    AND emp.employee_name LIKE '%Caravalho%'
--    pos.position_number = '008326'

ORDER BY 
    emp.employee_name
    ,a.assignment_valid_end DESC
    ,pc.pay_effective_date DESC