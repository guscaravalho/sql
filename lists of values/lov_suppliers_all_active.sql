SELECT 
    INITCAP(TRIM(vendor_name)) AS supplier_name
FROM AP_SUPPLIERS
WHERE 
    end_date_active IS NULL
ORDER BY 
    supplier_name