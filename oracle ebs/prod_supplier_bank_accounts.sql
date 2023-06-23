WITH
    employees AS
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
                WHEN SUBSTR(org.name,1,3) = 'RET' THEN '30 Retirement'
                ELSE 'Error' END)
                                            AS department
        FROM PER_EMPLOYEES_X e
        
        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id

        LEFT OUTER JOIN PER_ALL_ORGANIZATION_UNITS org
            ON e.organization_id = org.organization_id)

    ,bank_accounts AS
        (SELECT
            ep.supplier_site_id
            ,ba.ext_bank_account_id
            ,INITCAP(bank.party_name)          AS bank_name
            ,rout.party_name                   AS bank_routing_number
            ,ba.bank_account_num               AS bank_account_number
            ,ba.bank_account_name              AS bank_account_name
            ,ba.creation_date                  AS bank_account_created_date
            ,ba.last_update_date               AS bank_account_updated_date
            ,ba.country_code                   AS bank_account_country_code
            ,ba.currency_code                  AS bank_account_currency_code
            ,ba.last_updated_by                AS bank_account_updated_user_id
            ,pi.order_of_preference
            ,pi.payment_flow
            ,pi.instrument_type
            ,ba.bank_id
            ,ba.branch_id
             
        FROM IBY_EXT_BANK_ACCOUNTS ba

        LEFT OUTER JOIN IBY_PMT_INSTR_USES_ALL pi
            ON ba.ext_bank_account_id = pi.instrument_id

        LEFT OUTER JOIN IBY_EXTERNAL_PAYEES_ALL ep
            ON pi.ext_pmt_party_id = ep.ext_payee_id
            
        LEFT OUTER JOIN HZ_PARTIES bank
            ON ba.bank_id = bank.party_id

        LEFT OUTER JOIN HZ_PARTIES rout
            ON ba.branch_id = rout.party_id
        
        WHERE
            pi.instrument_type = 'BANKACCOUNT')

    ,suppliers AS
        (SELECT
            s.vendor_id
            ,s.party_id
            ,INITCAP(s.vendor_type_lookup_code)     AS supplier_type
            ,s.segment1                             AS supplier_number
            ,s.vendor_name                          AS supplier_name
            ,s.num_1099                             AS federal_1099_tax_number
            ,s.employee_id
            ,(CASE   
                WHEN s.enabled_flag = 'Y' THEN 'Enabled'
                WHEN s.enabled_flag = 'N' THEN 'Not Enabled' END)
                                                    AS supplier_status
            ,(CASE
                WHEN TRUNC(sysdate) >= TRUNC(s.start_date_active) AND s.end_date_active IS NULL THEN 'Valid'
                WHEN TRUNC(sysdate) >= TRUNC(s.start_date_active) AND TRUNC(sysdate) <= TRUNC(s.end_date_active) THEN 'Valid'
                ELSE 'Not Valid' END)              
                                                    AS supplier_validity
            ,s.hold_all_payments_flag
            ,TRUNC(s.start_date_active)             AS supplier_active_date_start
            ,TRUNC(s.end_date_active)               AS supplier_active_date_end
            ,TRUNC(s.creation_date)                 AS supplier_created_date
            ,s.created_by                           AS supplier_created_user_id
            ,s.last_update_date                     AS supplier_updated_datetime
            ,s.last_updated_by                      AS supplier_updated_user_id
            ,s.women_owned_flag
            ,s.small_business_flag       
            ,s.state_reportable_flag
            ,s.federal_reportable_flag
            ,ss.vendor_site_id
            ,ss.primary_pay_site_flag
            ,(CASE
                WHEN ss.primary_pay_site_flag = 'N' THEN 'Alternative' ELSE 'Primary' END)
                                                    AS pay_site_preference
            ,INITCAP(ss.vendor_site_code)           AS pay_site_name 
            ,(CASE 
                WHEN ss.inactive_date < sysdate OR ss.inactive_date > sysdate THEN 'Not Valid'
                ELSE 'Valid' END)   
                                                    AS pay_site_validity
            ,ss.creation_date                       AS pay_site_created_datetime
            ,ss.created_by                          AS pay_site_created_user_id
            ,ss.last_update_date                    AS pay_site_updated_datetime
            ,ss.last_updated_by                     AS pay_site_updated_user_id
            ,INITCAP(s.pay_group_lookup_code)       AS payment_group
            ,(CASE
                WHEN s.payment_method_lookup_code = 'EFT' THEN 'EFT'
                ELSE INITCAP(s.payment_method_lookup_code) END)
                                                    AS payment_method
            ,ss.address_line1
            ,ss.address_line2
            ,ss.address_line3
            ,ss.address_lines_alt
            ,INITCAP(ss.city)
            ,ss.state
            ,ss.zip
            ,ss.country
            ,ss.party_site_id
            ,ss.location_id
            
        FROM AP_SUPPLIERS s
        
        LEFT OUTER JOIN AP_SUPPLIER_SITES_ALL ss
            ON s.vendor_id = ss.vendor_id)
SELECT
-->> Supplier Information
    DISTINCT s.supplier_number
    ,s.supplier_name
    ,s.supplier_type
    ,s.supplier_status
    ,e.employee_name
    ,e.employee_number
    ,e.department                   AS employee_department
    ,s.supplier_created_date
    ,s.supplier_active_date_start
    ,s.supplier_active_date_end
    ,s.hold_all_payments_flag
-->> Pay Site Information
    ,s.primary_pay_site_flag
    ,s.pay_site_preference
    ,s.pay_site_name
    ,s.pay_site_validity
    ,s.payment_group
    ,s.payment_method
-->> Bank Account Information
    ,ba.bank_name
    ,ba.bank_routing_number
    ,ba.bank_account_number
    ,ba.bank_account_name
    ,ba.bank_account_created_date
    ,ba.bank_account_updated_date
    ,updat.employee_name            AS bank_account_updated_by
    ,updat.prism_user_name          AS updated_by_user_name
    ,ba.bank_account_country_code
    ,ba.order_of_preference
-->> IDs
    ,s.vendor_id
    ,s.vendor_site_id
    ,ba.bank_id
    ,ba.branch_id
    ,s.party_id
    ,s.party_site_id
    ,ba.ext_bank_account_id

FROM SUPPLIERS s

LEFT OUTER JOIN BANK_ACCOUNTS ba
    ON s.vendor_site_id = ba.supplier_site_id

LEFT OUTER JOIN EMPLOYEES updat
    ON ba.bank_account_updated_user_id = updat.user_id

LEFT OUTER JOIN EMPLOYEES e
    ON s.employee_id = e.employee_id

--  WHERE 
--    s.supplier_type <> 'Employee'

ORDER BY
    ba.bank_account_updated_date DESC