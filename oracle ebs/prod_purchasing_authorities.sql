WITH 
    pa_table AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fvs.description            AS flex_value_set_description
            ,fv.flex_value_id
            ,fv.flex_value              AS pa_number
            ,(CASE 
                WHEN fv.flex_value IN ('16-361-ss','20-748-ep','21*POL-SS-246','21-DES-up-360','258-09LW')
                THEN 'Duplicate' END)   
                                        AS duplicate_flag
            ,fv.flex_value_meaning
            ,fv.description             AS pa_description
            ,(CASE
                WHEN LENGTH(fv.description) >25 THEN (SUBSTR(fv.description,1,25)||'...')
                ELSE fv.description END)
                                        AS pa_description_short
            ,(CASE
                WHEN fv.flex_value LIKE '%ITB%' THEN 'Invitation To Bid'
                WHEN fv.flex_value LIKE '%RFP%' THEN 'Request For Proposal'
                WHEN fv.flex_value LIKE '%SS%' THEN 'Sole Source'
                WHEN fv.flex_value LIKE '%AG%' THEN 'Agreement'
                WHEN fv.flex_value LIKE '%-EP' OR fv.flex_value LIKE '%-EP-%'
                    THEN 'Exempt Purchase'
                WHEN fv.flex_value LIKE '%EPA%' THEN 'Emergency Purchase Agreement'
                WHEN fv.flex_value LIKE '%SFA%' THEN 'Standard Form Agreement'
                WHEN fv.flex_value LIKE '%SLA%' THEN 'Service Level Agreement'
                WHEN fv.flex_value LIKE '%-R' OR fv.flex_value LIKE '%-R-%'
                    THEN 'Rider'
                WHEN fv.flex_value LIKE '%-LE%' THEN 'Lease'
                WHEN fv.flex_value LIKE '%BA%' THEN 'Board Award'
                WHEN fv.flex_value LIKE '%SP%' THEN 'Sponsorship Agreement'
                WHEN fv.flex_value LIKE '%UP%' THEN 'Unauthorized Purchase'
                WHEN fv.flex_value LIKE '%QQ%' THEN 'Quick Quote' END)
                                        AS contract_type          
            ,fv.last_update_date        AS pa_last_update_datetime
            ,fv.last_updated_by         AS pa_last_update_by
            ,fv.creation_date           AS pa_created_datetime
            ,fv.created_by              AS pa_created_by
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(TRUNC(fv.creation_date),4,3)) IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(TRUNC(fv.creation_date),8,4))+1)
                WHEN TO_CHAR(SUBSTR(TRUNC(fv.creation_date),4,3)) IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(TRUNC(fv.creation_date),8,4)) END)
                                        AS pa_created_fiscal_year
            ,fv.enabled_flag
            ,(CASE
                WHEN fv.enabled_flag = 'Y' THEN 'Enabled'
                WHEN fv.enabled_flag = 'N' THEN 'Not Enabled' END)
                                        AS pa_status
            ,fv.start_date_active       AS valid_start_date
            ,fv.end_date_active         AS valid_end_date
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(fv.start_date_active,4,3)) IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(fv.start_date_active,8,4))+1)
                WHEN TO_CHAR(SUBSTR(fv.start_date_active,4,3)) IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(fv.start_date_active,8,4)) END)
                                        AS valid_start_fiscal_year
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(fv.end_date_active,4,3)) IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(fv.end_date_active,8,4))+1)
                WHEN TO_CHAR(SUBSTR(fv.end_date_active,4,3)) IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(fv.end_date_active,8,4)) END)
                                        AS valid_end_fiscal_year                            
            ,(CASE
                WHEN sysdate BETWEEN TRUNC(fv.start_date_active) AND TRUNC(fv.end_date_active)
                    THEN 'Valid' ELSE 'Not Valid' END)
                                        AS pa_validity
            ,(CASE
                WHEN (TRUNC(fv.end_date_active) - TRUNC(sysdate)) BETWEEN 0 AND 90  THEN 'Expiring Soon'
                WHEN (TRUNC(fv.end_date_active) - TRUNC(sysdate)) < 0    THEN 'Expired'
                WHEN (TRUNC(fv.end_date_active) - TRUNC(sysdate)) > 90   THEN '90+ Days Remaining' 
                WHEN fv.end_date_active IS NULL THEN 'Unknown' END)
                                        AS valid_time_horizon
            ,(CASE 
                WHEN TRUNC(fv.end_date_active) >= TRUNC(sysdate) 
                    THEN TRUNC(fv.end_date_active) - TRUNC(sysdate) 
                ELSE 0 END)             AS valid_days_remaining
            ,fv.value_category
            ,fv.attribute1              AS project_officer_dept_username
            ,fv.attribute2              AS procurement_officer_dmf_username
            ,TO_NUMBER(fv.attribute3)   AS authorized_amount
            ,fv.attribute4              AS owner_department
            ,fv.attribute5              AS in_vendor_registry
            ,fv.attribute6              AS lease_saas_gasb8796

        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE
            fvs.flex_value_set_name LIKE 'ACGA_PO_PURCHASE_AUTHORITY'

        ORDER BY
            fv.last_update_date DESC)

    ,payments AS
        (SELECT
            DISTINCT poh.attribute1         AS pa_number
            ,SUM(aid.amount)                AS spend_to_date
            ,SUM(
                (CASE
                    WHEN aid.accounting_date < pa.valid_start_date THEN aid.amount 
                    ELSE 0 END))
                                            AS spend_before_valid
            ,SUM(
                (CASE
                    WHEN aid.accounting_date BETWEEN pa.valid_start_date AND pa.valid_end_date
                    THEN aid.amount ELSE 0 END))
                                            AS valid_spend
            ,SUM(
                (CASE
                    WHEN aid.accounting_date > pa.valid_end_date THEN aid.amount 
                    ELSE 0 END))
                                            AS spend_after_valid

        FROM AP_INVOICE_DISTRIBUTIONS_ALL aid

        LEFT OUTER JOIN PO_DISTRIBUTIONS_ALL pod
            ON aid.po_distribution_id = pod.po_distribution_id
            
        LEFT OUTER JOIN PO_HEADERS_ALL poh
            ON pod.po_header_id = poh.po_header_id
            
        LEFT OUTER JOIN PA_TABLE pa
            ON poh.attribute1 = pa.pa_number

        WHERE 
            aid.posted_flag = 'Y'
            
        GROUP BY 
            poh.attribute1)   

    ,employees AS 
        (SELECT 
            e.employee_id
            ,e.assignment_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
            ,u.user_id                      AS user_id
            ,u.user_name                    AS user_name
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
                WHEN SUBSTR(org.name,1,3) = 'RET' THEN '30 Retirement'
                ELSE 'Error' END)
                                            AS department      
        FROM PER_EMPLOYEES_X e
        
        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id

        LEFT OUTER JOIN PER_ALL_ORGANIZATION_UNITS org
            ON e.organization_id = org.organization_id)

SELECT
    pa.flex_value_set_description       AS flex_value_type
    ,pa.pa_number
    ,pa.pa_description
    ,pa.pa_description_short
    ,pa.pa_number||' '||pa.pa_description_short
                                        AS purchasing_authority
    ,pa.contract_type
    ,pa.pa_status
    ,pa.pa_validity
    ,pa.valid_start_date
    ,pa.valid_end_date
    ,pa.valid_start_fiscal_year
    ,pa.valid_end_fiscal_year
    ,pa.valid_days_remaining
    ,pa.valid_time_horizon
    ,(CASE
        WHEN pa.pa_number IN('X5000','X10000') THEN '03 Management and Finance'
        ELSE dept.department END)                    
                                        AS project_officer_department
    ,dept.employee_name                 AS project_officer
    ,dmf.employee_name                  AS procurement_officer
    ,pa.authorized_amount
    ,COALESCE(pay.spend_to_date,0)      AS spend_to_date
    ,COALESCE(pay.spend_before_valid,0) AS spend_before_valid   
    ,COALESCE(pay.valid_spend,0)        AS valid_spend
    ,COALESCE(pay.spend_after_valid,0)  AS spend_after_valid  
    ,COALESCE(pa.authorized_amount,0) - COALESCE(pay.spend_to_date,0)
                                        AS authorized_amount_remaining
    ,pa.owner_department
    ,pa.in_vendor_registry
    ,pa.lease_saas_gasb8796
    ,pa.pa_last_update_datetime         AS pa_last_update_datetime
    ,updat.employee_name                AS pa_last_updated_by_name
    ,pa.pa_created_datetime
    ,pa.pa_created_fiscal_year              
    ,creat.employee_name                AS pa_created_by_name
    ,pa.project_officer_dept_username
    ,pa.procurement_officer_dmf_username
    ,pa.duplicate_flag
    ,pa.flex_value_set_id
    ,pa.flex_value_id
    ,pa.flex_value_set_name
    ,TRUNC(sysdate)                     AS report_run_date

FROM PA_TABLE pa

LEFT OUTER JOIN PAYMENTS pay
    ON pa.pa_number = pay.pa_number

LEFT OUTER JOIN EMPLOYEES creat
    ON pa.pa_created_by = creat.user_id
    
LEFT OUTER JOIN EMPLOYEES updat
    ON pa.pa_last_update_by = updat.user_id

LEFT OUTER JOIN EMPLOYEES dept
    ON pa.project_officer_dept_username = dept.user_name

LEFT OUTER JOIN EMPLOYEES dmf
    ON pa.procurement_officer_dmf_username = dmf.user_name
    
WHERE
    pa.duplicate_flag IS NULL

ORDER BY
    pa.pa_created_datetime DESC