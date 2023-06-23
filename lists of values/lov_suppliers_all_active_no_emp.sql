SELECT 
    INITCAP(TRIM(vendor_name)) AS supplier_name
FROM AP_SUPPLIERS
WHERE 
    end_date_active IS NULL
    AND vendor_type_lookup_code NOT IN (
        'ELECTORAL BOARD'
        ,'EMPLOYEE'
        ,'HIDTA'
        ,'MATF')
ORDER BY 
    supplier_name