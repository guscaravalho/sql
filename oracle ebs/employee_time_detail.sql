WITH
    payroll_periods AS
            (SELECT 
                time_period_id
                ,period_name                        AS payroll_name
                ,period_type
                ,start_date
                ,end_date
                ,cut_off_date
                ,pay_advice_date                    AS pay_advance_date
                ,regular_payment_date               AS paycheck_friday_date
                ,payslip_view_date
                ,'CY '||REGEXP_SUBSTR(period_name, '[^'' '']+',1,2)||' Pay '||
                (CASE   
                    WHEN SUBSTR(period_name,1,2) IN ('1 ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ')
                    THEN '0'||SUBSTR(period_name,1,1) 
                    ELSE SUBSTR(period_name,1,2) END)
                                                    AS payroll_name_cal_year
                ,'CY '||REGEXP_SUBSTR(period_name, '[^'' '']+',1,2)||' Pay '||
                (CASE   
                    WHEN SUBSTR(period_name,1,2) IN ('1 ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ')
                    THEN '0'||SUBSTR(period_name,1,1) 
                    ELSE SUBSTR(period_name,1,2) END)
                    || ' - ' ||            
                    SUBSTR(regular_payment_date,4,3) || ' ' ||
                    SUBSTR(regular_payment_date,1,2) || ', 20' ||
                    SUBSTR(regular_payment_date,10,2)
                                                    AS payroll_name_and_date
                ,(CASE 
                    WHEN TO_CHAR(SUBSTR(regular_payment_date,4,3)) 
                    IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                    THEN TO_CHAR(TO_NUMBER(SUBSTR(regular_payment_date,8,4))+1)
                    WHEN TO_CHAR(SUBSTR(regular_payment_date,4,3)) 
                    IN ('JAN','FEB','MAR','APR','MAY','JUN')
                    THEN TO_CHAR(SUBSTR(regular_payment_date,8,4)) END)
                                                    AS paycheck_fiscal_year
                ,(CASE
                    WHEN SUBSTR(regular_payment_date,4,3) = 'JUL' THEN '01 JUL.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'AUG' THEN '02 AUG.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'SEP' THEN '03 SEP.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'OCT' THEN '04 OCT.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'NOV' THEN '05 NOV.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'DEC' THEN '06 DEC.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'JAN' THEN '07 JAN.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'FEB' THEN '08 FEB.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'MAR' THEN '09 MAR.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'APR' THEN '10 APR.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'MAY' THEN '11 MAY.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'JUN' THEN '12 JUN.'
                    WHEN SUBSTR(regular_payment_date,4,3) = 'ADJ' THEN '12 JUN.' END)
                                                        AS paycheck_month
                                            
            FROM PER_TIME_PERIODS
        
            WHERE 
                period_type = 'Bi-Week')
            
    ,batches AS
        (SELECT
            DISTINCT bl.batch_line_id
            ,bl.batch_id
            ,bh.batch_name
            ,bh.batch_reference
            ,bh.batch_source
            ,bl.assignment_id
            ,bl.effective_date
            ,bl.date_earned
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(bl.date_earned,4,3)) 
                IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(bl.date_earned,8,4))+1)
                WHEN TO_CHAR(SUBSTR(bl.date_earned,4,3)) 
                IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(bl.date_earned,8,4)) END)				
                                                        AS earned_fiscal_year
            ,(CASE
                WHEN SUBSTR(bl.date_earned,4,3) = 'JUL' THEN '01 JUL.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'AUG' THEN '02 AUG.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'SEP' THEN '03 SEP.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'OCT' THEN '04 OCT.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'NOV' THEN '05 NOV.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'DEC' THEN '06 DEC.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'JAN' THEN '07 JAN.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'FEB' THEN '08 FEB.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'MAR' THEN '09 MAR.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'APR' THEN '10 APR.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'MAY' THEN '11 MAY.'
                WHEN SUBSTR(bl.date_earned,4,3) = 'JUN' THEN '12 JUN.' END)
                                    AS earned_month
            ,bl.element_name
            ,(CASE
                WHEN bl.element_name LIKE '%Bonus%' OR
                    bl.element_name LIKE '%Merit%' THEN 'Bonus'
                WHEN bl.element_name LIKE '%Adj' THEN 'Adjustment'
                ELSE 'Hours Worked' END)
                                    AS time_type
                
            ,bl.value_1             AS special_hours
            ,bl.value_2             AS normal_hours
            ,(CASE
                WHEN bl.element_name LIKE '%Adj' THEN CAST(bl.value_2 AS int)
                WHEN bl.element_name LIKE '%Bonus%' 
                    OR bl.element_name LIKE '%Merit%' 
                    OR bl.element_name LIKE '%Acting%' THEN 0
                ELSE (COALESCE(bl.value_1,'0') + COALESCE(bl.value_2,'0')) END)
                                    AS total_hours
            
        FROM PAY_BATCH_LINES bl

        LEFT OUTER JOIN PAY_BATCH_HEADERS bh
            ON bl.batch_id = bh.batch_id
            
        ORDER BY 
            bl.date_earned)

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
            ,e.global_name||' '||e.employee_num AS employee_name_number
            ,e.employee_num||' '||e.global_name AS employee_number_name
  
        FROM PER_EMPLOYEES_X e
        
        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id
            
        LEFT OUTER JOIN PER_ALL_ORGANIZATION_UNITS org
            ON e.organization_id = org.organization_id)
            
    ,positions AS
        (SELECT     
            p.position_id
            ,p.effective_start_date
            ,p.effective_end_date
            ,p.organization_id
            ,p.name                     AS position_name_concat
            ,p.fte
            ,p.max_persons
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
            AND fvs.flex_value_set_name = 'ACGA_HR_POS_CAT')
            
    ,departments AS
        (SELECT     
            organization_id
            ,name                               AS organization
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
        FROM PER_ALL_ORGANIZATION_UNITS org)

SELECT
    DISTINCT b.batch_line_id
    ,d.department
    ,d.organization
    ,e.employee_name
    ,e.employee_number
    ,b.element_name
    ,b.date_earned
    ,b.normal_hours
    ,b.special_hours
    ,b.total_hours
    ,b.time_type
    ,b.earned_fiscal_year
    ,b.earned_month
    ,p.job_class
    ,p.position_number
    ,p.position_schedule
    ,p.position_name_concat
    ,pp.payroll_name
    ,pp.payroll_name_cal_year
    ,pp.payroll_name_and_date
    ,pp.paycheck_friday_date
    ,pp.paycheck_fiscal_year
    ,pp.paycheck_month
    ,b.batch_id
    ,b.assignment_id
    ,e.employee_name_number
    ,e.employee_number_name

FROM BATCHES b

LEFT OUTER JOIN PAYROLL_PERIODS pp
    ON b.effective_date BETWEEN pp.start_date AND pp.end_date 

LEFT OUTER JOIN PER_ALL_ASSIGNMENTS_F a
    ON b.assignment_id = a.assignment_id
    AND b.effective_date BETWEEN a.effective_start_date AND a.effective_end_date

LEFT OUTER JOIN EMPLOYEES e
    ON a.person_id = e.employee_id
    
LEFT OUTER JOIN POSITIONS p
    ON a.position_id = p.position_id
    AND b.date_earned BETWEEN p.effective_start_date AND p.effective_end_date
    
LEFT OUTER JOIN DEPARTMENTS d
    ON a.organization_id = d.organization_id
    
WHERE 
    e.employee_name LIKE '%Caravalho%'
--    AND b.time_type = 'Adjustment'
--    d.department = '03 Management and Finance'
--    AND pp.payroll_name IN ('6 2022 Bi-Week','5 2022 Bi-Week')

ORDER BY 
    b.date_earned DESC