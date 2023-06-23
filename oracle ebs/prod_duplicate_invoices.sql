WITH
    invoices AS
        (SELECT
            i.invoice_id
            ,i.vendor_id
            ,INITCAP(s.vendor_name)         AS supplier_name
            ,i.invoice_num                  AS invoice_number
            ,i.invoice_amount
            ,i.invoice_received_date
            ,i.gl_date
            ,i.invoice_date
            ,i.creation_date                AS invoice_create_date
            ,i.created_by                   AS invoice_author_user_id
            ,i.payment_method_code
            ,INITCAP(i.wfapproval_status)   AS workflow_status
            ,LENGTH(i.invoice_num)          AS length
            ,i.vendor_id||'-'||
                RPAD(
                    SUBSTR(
                        TRIM(LEADING 0 FROM i.invoice_num)
                    ,1,4)
                ,4,0)||'-'||
                i.invoice_amount            AS vendor_id_base_invoice_number_amount

        FROM AP_INVOICES_ALL i
        LEFT OUTER JOIN AP_SUPPLIERS s
            ON i.vendor_id = s.vendor_id
        WHERE
            i.invoice_type_lookup_code <> 'EXPENSE REPORT')

    ,duplicates AS
        (SELECT
            vendor_id_base_invoice_number_amount
            ,(CASE
                WHEN COUNT(invoice_id) > 1 THEN 'Possible Duplicate'
                ELSE 'Unique' END) AS duplicate_status
        FROM INVOICES
        GROUP BY 
            vendor_id_base_invoice_number_amount)
    
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
            ON e.organization_id = org.organization_id)    

SELECT
    i.invoice_id
    ,i.supplier_name
    ,i.invoice_number
    ,i.invoice_amount
    ,i.invoice_date
    ,i.invoice_create_date
    ,ROUND((MAX(i.invoice_create_date) OVER(PARTITION BY i.vendor_id_base_invoice_number_amount) -
        MIN(i.invoice_create_date) OVER(PARTITION BY i.vendor_id_base_invoice_number_amount))/30,0)
                                                AS invoice_create_date_gap_months
    ,e.employee_name                            AS invoice_author
    ,e.department                               AS invoice_author_department
    ,i.workflow_status
    ,d.vendor_id_base_invoice_number_amount     AS duplicate_reference
    ,d.duplicate_status
    
FROM INVOICES i

LEFT OUTER JOIN DUPLICATES d
    ON i.vendor_id_base_invoice_number_amount = d.vendor_id_base_invoice_number_amount
    
LEFT OUTER JOIN EMPLOYEES e
    ON i.invoice_author_user_id = e.user_id

WHERE
    d.duplicate_status = 'Possible Duplicate'
--    AND d.vendor_id_base_invoice_number LIKE '1002-0501%'
    AND i.invoice_create_date BETWEEN '01-APR-2022' AND '31-JAN-2023'
--    AND i.invoice_date > '01-JUL-2022'

ORDER BY 
--    d.duplicate_status
    d.vendor_id_base_invoice_number_amount
    ,i.invoice_number