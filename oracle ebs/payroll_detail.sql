WITH
    payroll_costs AS
        (SELECT
            pc.cost_id
            ,ppa.payroll_action_id
            ,ppa.effective_date
            ,ppa.effective_date         AS effective_date_x
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(ppa.effective_date,4,3)) 
                IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(ppa.effective_date,8,4))+1)
                WHEN TO_CHAR(SUBSTR(ppa.effective_date,4,3)) 
                IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(ppa.effective_date,8,4))
                ELSE 'Error' END)					
                                                        AS fiscal_year
            ,(CASE
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'JUL'    THEN '01 JUL.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'AUG'    THEN '02 AUG.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'SEP'    THEN '03 SEP.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'OCT'    THEN '04 OCT.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'NOV'    THEN '05 NOV.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'DEC'    THEN '06 DEC.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'JAN'    THEN '07 JAN.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'FEB'    THEN '08 FEB.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'MAR'    THEN '09 MAR.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'APR'    THEN '10 APR.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'MAY'    THEN '11 MAY.'
                WHEN SUBSTR(TRUNC(ppa.effective_date),4,3) = 'JUN'    THEN '12 JUN.' END)  
                                                        AS fiscal_month
            ,paa.assignment_action_id
            ,paa.assignment_id
            ,pc.input_value_id
            ,(CASE
                WHEN pc.balance_or_cost = 'B' THEN 'Balance'
                WHEN pc.balance_or_cost = 'C' THEN 'Cost' END)
                                        AS charge_type
            ,pc.costed_value
            ,(CASE 
                WHEN pc.debit_or_credit = 'C' THEN 'Credit'
                WHEN pc.debit_or_credit = 'D' THEN 'Debit' END)
                                        AS transaction_type
            ,(CASE  
                WHEN pc.debit_or_credit = 'D' THEN pc.costed_value
                WHEN pc.debit_or_credit = 'C' THEN pc.costed_value * -1 END)            
                                AS amount
            ,cakf.segment1      AS fund_code
            ,cakf.segment2      AS natural_account_code
            ,cakf.segment3      AS cost_center_code
            ,cakf.segment4      AS project_code
            ,cakf.segment5      AS source_of_funds_code
            ,cakf.segment6      AS task_code
            ,(CASE  
                WHEN SUBSTR(cakf.segment3,1,3) = '101'  THEN '01 County Board'
                WHEN SUBSTR(cakf.segment3,1,3) = '102'  THEN '02 County Manager'
                WHEN SUBSTR(cakf.segment3,1,3) = '103'  THEN '03 Management and Finance'
                WHEN SUBSTR(cakf.segment3,1,3) = '104'  THEN '04 Civil Service Commission'
                WHEN SUBSTR(cakf.segment3,1,2) = '12'   THEN '05 Human Resources'
                WHEN SUBSTR(cakf.segment3,1,2) = '13'   THEN '06 Technology Services'
                WHEN SUBSTR(cakf.segment3,1,3) = '141'  THEN '07 County Attorney'
                WHEN SUBSTR(cakf.segment3,1,3) = '142'  THEN '08 Commissioner of Revenue'
                WHEN SUBSTR(cakf.segment3,1,3) = '143'  THEN '09 Treasurer'
                WHEN SUBSTR(cakf.segment3,1,3) = '144'  THEN '10 Registrar'
                WHEN SUBSTR(cakf.segment3,1,3) = '201'  THEN '11 Circuit Court Judiciary'
                WHEN SUBSTR(cakf.segment3,1,3) = '202'  THEN '12 Circuit Court Clerk'
                WHEN SUBSTR(cakf.segment3,1,3) = '203'  THEN '13 District Court'
                WHEN SUBSTR(cakf.segment3,1,3) IN ('204','206') THEN '14 Juvenile / Domestic Court'
                WHEN SUBSTR(cakf.segment3,1,3) = '207'  THEN '15 Commonwealth''s Attorney'
                WHEN SUBSTR(cakf.segment3,1,3) = '208'  THEN '16 Magistrate'
                WHEN SUBSTR(cakf.segment3,1,3) = '209'  THEN '17 Public Defender'
                WHEN SUBSTR(cakf.segment3,1,2) = '22'   THEN '18 Sheriff'
                WHEN SUBSTR(cakf.segment3,1,2) = '31'   THEN '19 Police'
                WHEN SUBSTR(cakf.segment3,1,2) = '32'   THEN '20 Emergency Management'
                WHEN SUBSTR(cakf.segment3,1,2) = '34'   THEN '21 Fire'
                WHEN SUBSTR(cakf.segment3,1,1) = '4'    THEN '22 Environmental Services'
                WHEN SUBSTR(cakf.segment3,1,1) = '5'    THEN '23 Human Services'
                WHEN SUBSTR(cakf.segment3,1,1) = '6'    THEN '24 Libraries'
                WHEN SUBSTR(cakf.segment3,1,2) = '71'   THEN '25 Economic Development'
                WHEN SUBSTR(cakf.segment3,1,2) = '72'   THEN '26 Planning and Housing'
                WHEN SUBSTR(cakf.segment3,1,1) = '8'    THEN '27 Parks and Recreation'
                WHEN SUBSTR(cakf.segment3,1,3) IN ('910','911','912') 
                    OR SUBSTR(cakf.segment3,1,2) IN ('00','99') 
                    OR cakf.segment3 = '10001' THEN '28 Non-Departmental'
                WHEN SUBSTR(cakf.segment3,1,3) = '913'  THEN '29 Schools'
                WHEN SUBSTR(cakf.segment3,1,3) = '914'  THEN '30 Retirement' END)
                                                    AS department
            ,pc.cost_allocation_keyflex_id
            ,piv.element_type_id
                
        FROM PAY_COSTS pc
        
        LEFT OUTER JOIN PAY_ASSIGNMENT_ACTIONS paa
            ON pc.assignment_action_id = paa.assignment_action_id
            
        LEFT OUTER JOIN PAY_PAYROLL_ACTIONS ppa
            ON paa.payroll_action_id = ppa.payroll_action_id

        LEFT OUTER JOIN PAY_COST_ALLOCATION_KEYFLEX cakf
            ON pc.cost_allocation_keyflex_id = cakf.cost_allocation_keyflex_id
            
        LEFT OUTER JOIN PAY_INPUT_VALUES_F piv
            ON pc.input_value_id = piv.input_value_id)
        
    ,funds AS
        (SELECT 
            fv.flex_value_meaning               AS fund_code
            ,fv.flex_value_meaning||'_x'        AS fund_code_x
            ,fv.description                     AS fund_name
            ,fv.flex_value_meaning||' '||fv.description AS fund
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_FUND')
    
    ,natural_accounts AS
        (SELECT     
            DISTINCT fv.flex_value_id
            ,fv.flex_value_meaning              AS natural_account_code
            ,fv.flex_value_meaning||'_x'        AS natural_account_code_x
            ,fv.description                     AS natural_account_name
            ,fv.flex_value_meaning||' '||fv.description     AS natural_account
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,1) = '1' THEN 'Asset'
                WHEN SUBSTR(fv.flex_value,1,1) = '2' THEN 'Liability'
                WHEN SUBSTR(fv.flex_value,1,3) BETWEEN '300' AND '348' 
                    OR SUBSTR(fv.flex_value,1,3) BETWEEN '350' AND '399' THEN 'Revenue'
                WHEN SUBSTR(fv.flex_value,1,1) = '4' 
                    OR SUBSTR(fv.flex_value,1,3) = '349' THEN 'Expenditure'
                WHEN SUBSTR(fv.flex_value,1,1) = '5' THEN 'Owner''s Equity' END)
                                        AS natural_account_type

        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id

        WHERE 
            fvs.flex_value_set_name LIKE '%ACGA_GL_NATURAL_ACCOUNT%')
            
    ,cost_centers AS
        (SELECT 
            fv.flex_value_meaning               AS cost_center_code
            ,fv.flex_value_meaning||'_x'        AS cost_center_code_x
            ,fv.description                     AS cost_center_name
            ,fv.flex_value_meaning||' '||fv.description AS cost_center
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_COST_CENTER')
            
    ,projects AS
        (SELECT 
            fv.flex_value_meaning               AS project_code
            ,fv.flex_value_meaning||'_x'        AS project_code_x
            ,fv.description                     AS project_name
            ,fv.flex_value_meaning||' '||fv.description AS project
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_PROJECT')
            
    ,sources_of_funds AS
        (SELECT 
            fv.flex_value_meaning               AS source_of_funds_code
            ,fv.flex_value_meaning||'_x'        AS source_of_funds_code_x
            ,fv.description                     AS source_of_funds_name
            ,fv.flex_value_meaning||' '||fv.description AS source_of_funds
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_SOURCE_OF_FUNDS')            
            
    ,tasks AS
        (SELECT 
            fv.flex_value_meaning               AS task_code
            ,fv.flex_value_meaning||'_x'        AS task_code_x
            ,fv.description                     AS task_name
            ,fv.flex_value_meaning||' '||fv.description AS task
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_TASK')

    ,payroll_periods AS
        (SELECT 
            time_period_id
            ,period_name            AS pay_period_name
            ,period_type
            ,start_date
            ,end_date
            ,cut_off_date
            ,pay_advice_date AS pay_advance_date
            ,regular_payment_date AS paycheck_friday
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
                ELSE SUBSTR(period_name,1,2) END) || ' - ' ||            
                SUBSTR(regular_payment_date,4,3) || ' ' ||
                SUBSTR(regular_payment_date,1,2) || ', 20' ||
                SUBSTR(regular_payment_date,8,2)
                                        AS payroll_name_and_date
        FROM PER_TIME_PERIODS
        WHERE period_type = 'Bi-Week')
        
    ,pay_elements AS
        (SELECT
            pe.element_type_id
            ,pe.effective_start_date
            ,pe.effective_end_date
            ,pe.element_name
            ,pe.reporting_name
            ,pe.element_information_category
            
        FROM PAY_ELEMENT_TYPES_F pe)

    ,employees AS 
        (SELECT 
            e.employee_id
            ,e.assignment_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
            ,e.inactive_date                AS employee_inactive_date
            ,(CASE   
                WHEN e.inactive_date IS NULL THEN 'Active'
                ELSE 'Not Active' END)
                                            AS employee_status
  
        FROM PER_EMPLOYEES_X e) 
   
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
            ,name                               AS org_name
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
    pc.cost_id
    ,pc.effective_date
    ,pc.fiscal_year
    ,pc.fiscal_month
    ,pp.pay_period_name	
    ,pp.payroll_name_cal_year
    ,pp.payroll_name_and_date
    ,emp.employee_name
    ,emp.employee_number
    ,d.department                   AS department_assigned
    ,d.org_name
    ,pe.element_name
    ,pc.charge_type
    ,pc.transaction_type
    ,pc.amount
    ,p.position_number
    ,p.job_class
    ,p.position_schedule
    ,p.position_schedule_code
    ,p.position_name_concat
    ,na.natural_account_type
    ,pc.department                  AS department_charged
    ,f.fund
    ,na.natural_account
    ,cc.cost_center
    ,proj.project
    ,sof.source_of_funds
    ,t.task
    ,f.fund_code_x
    ,na.natural_account_code_x
    ,cc.cost_center_code_x
    ,proj.project_code_x
    ,sof.source_of_funds_code_x
    ,t.task_code_x
    ,pc.effective_date_x
    ,pc.fund_code
    ,pc.natural_account_code
    ,pc.cost_center_code
    ,pc.project_code
    ,pc.source_of_funds_code
    ,pc.task_code
    ,pe.element_type_id
    ,pc.payroll_action_id
    ,pc.assignment_action_id
    ,pc.input_value_id
    ,TRUNC(sysdate)     AS report_run_date
    
FROM PAYROLL_COSTS pc
    
LEFT OUTER JOIN PAY_ELEMENTS pe
    ON pc.element_type_id = pe.element_type_id

LEFT OUTER JOIN PER_ALL_ASSIGNMENTS_F paf
    ON pc.assignment_id = paf.assignment_id
    AND (pc.effective_date - 6) BETWEEN paf.effective_start_date AND paf.effective_end_date

LEFT OUTER JOIN PAYROLL_PERIODS pp
    ON pc.effective_date BETWEEN pp.end_date AND (pp.end_date + 7)

LEFT OUTER JOIN EMPLOYEES emp
    ON paf.person_id = emp.employee_id

INNER JOIN POSITIONS p
    ON paf.position_id = p.position_id  

LEFT OUTER JOIN DEPARTMENTS d
    ON paf.organization_id = d.organization_id
    
LEFT OUTER JOIN FUNDS f
    ON pc.fund_code = f.fund_code

LEFT OUTER JOIN NATURAL_ACCOUNTS na
    ON pc.natural_account_code = na.natural_account_code

LEFT OUTER JOIN COST_CENTERS cc
    ON pc.cost_center_code = cc.cost_center_code
    
LEFT OUTER JOIN PROJECTS proj
    ON pc.project_code = proj.project_code
    
LEFT OUTER JOIN SOURCES_OF_FUNDS sof
    ON pc.source_of_funds_code = sof.source_of_funds_code
    
LEFT OUTER JOIN TASKS t
    ON pc.task_code = t.task_code

WHERE 
    pc.effective_date BETWEEN p.effective_start_date AND p.effective_end_date
    AND pc.charge_type = 'Cost'
    AND na.natural_account_type = 'Expenditure'
    AND emp.employee_name LIKE '%Caravalho%'
    AND pc.effective_date > '01-JAN-2023'
    
ORDER BY 
    pc.effective_date DESC
    ,pc.department 
    ,emp.employee_name