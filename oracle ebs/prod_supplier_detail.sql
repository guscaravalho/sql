WITH
    suppliers AS
        (SELECT
            s.vendor_id
            ,s.party_id
            ,INITCAP(s.vendor_type_lookup_code)     AS supplier_type
            ,s.segment1                             AS supplier_number
            ,INITCAP(TRIM(s.vendor_name))           AS supplier_name
            ,s.num_1099                             AS federal_1099_tax_number
            ,INITCAP(s.pay_group_lookup_code)       AS supplier_payment_group
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
            ,TRUNC(s.last_update_date)              AS supplier_last_update_date
            ,s.last_updated_by                      AS supplier_last_update_user_id
            ,s.women_owned_flag
            ,s.small_business_flag       
            ,s.state_reportable_flag
            ,s.federal_reportable_flag
            ,s.vendor_type_lookup_code
            ,ss.vendor_site_id
            ,ss.primary_pay_site_flag
            ,(CASE
                WHEN ss.primary_pay_site_flag <> 'N' THEN 'Primary' END)
                                                    AS pay_site_priority
            ,INITCAP(ss.vendor_site_code)           AS pay_site_name 
            ,ss.inactive_date                       AS pay_site_inactive_date
            ,(CASE 
                WHEN ss.inactive_date < sysdate OR ss.inactive_date > sysdate THEN 'Not Valid'
                ELSE 'Valid' END)   
                                                    AS pay_site_validity
            ,ss.creation_date                       AS pay_site_created_datetime
            ,ss.created_by                          AS pay_site_created_user_id
            ,ss.last_update_date                    AS pay_site_updated_datetime
            ,ss.last_updated_by                     AS pay_site_updated_user_id

            ,(CASE
                WHEN s.payment_method_lookup_code = 'EFT' THEN 'EFT'
                ELSE INITCAP(s.payment_method_lookup_code) END)
                                                    AS payment_method
            ,ss.address_line1
            ,ss.address_line2
            ,ss.address_line3
            ,ss.address_lines_alt
            ,INITCAP(ss.city)           AS city
            ,ss.state
            ,ss.zip
            ,ss.country
            ,ss.party_site_id
            ,ss.location_id
            
        FROM AP_SUPPLIERS s
        
        LEFT OUTER JOIN AP_SUPPLIER_SITES_ALL ss
            ON s.vendor_id = ss.vendor_id)
            
    ,employees AS
        (SELECT
            e.employee_id
            ,e.assignment_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
            ,u.user_id
            ,e.inactive_date                AS employee_inactive_date
            ,(CASE   
                WHEN e.inactive_date IS NULL THEN 'Active'
                ELSE 'Not Active' END)
                                            AS employee_status

        FROM PER_EMPLOYEES_X e
        
        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id)
            
SELECT
-->> Supplier Information
    s.supplier_type
    ,s.supplier_payment_group
    ,s.supplier_number
    ,s.federal_1099_tax_number
    ,s.supplier_name
    ,s.supplier_status
    ,s.supplier_validity
    ,s.supplier_active_date_start
    ,s.supplier_active_date_end
    ,s.supplier_last_update_date
    ,e.employee_name        AS last_update_by
    
-->> Pay Site Information
    ,s.pay_site_priority
    ,s.pay_site_name
    ,s.payment_method
    ,s.address_line1
    ,s.address_line2
    ,s.city
    ,s.state
    ,s.zip
    ,s.pay_site_validity
    ,s.pay_site_inactive_date
    ,s.primary_pay_site_flag
    ,s.hold_all_payments_flag
    ,s.vendor_id
    ,s.vendor_site_id
    ,s.party_id
    ,s.party_site_id
    ,TRUNC(sysdate)     AS report_run_date

FROM SUPPLIERS s

LEFT OUTER JOIN EMPLOYEES e
    ON s.supplier_last_update_user_id = e.user_id

WHERE 
    s.supplier_type NOT IN ('Electoral Board'
                            ,'Employee'
                            ,'Hidta'
                            ,'Matf')
    AND s.supplier_validity = 'Valid'