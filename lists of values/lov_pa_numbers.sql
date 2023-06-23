SELECT 
        fv.flex_value_meaning        AS pa_number

FROM FND_FLEX_VALUES_VL fv

LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
    ON fv.flex_value_set_id = fvs.flex_value_set_id

WHERE 
    fvs.flex_value_set_name LIKE '%ACGA_PO_PURCHASE_AUTHORITY%'

ORDER BY 
    fv.flex_value_meaning