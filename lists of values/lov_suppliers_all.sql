SELECT 
    INITCAP(TRIM(vendor_name)) AS supplier_name
FROM AP_SUPPLIERS
ORDER BY 
    supplier_name