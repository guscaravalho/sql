SELECT    
    fv.flex_value_meaning AS fund_code
    
FROM FND_FLEX_VALUES_VL fv

LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
    ON fv.flex_value_set_id = fvs.flex_value_set_id

WHERE 
/* List of the six GL segment names (the names of their flex value sets):
        'ACGA_GL_FUND'
        'ACGA_GL_NATURAL_ACCOUNT'
        'ACGA_GL_COST_CENTER'
        'ACGA_GL_PROJECT'
        'ACGA_GL_SOURCE_OF_FUNDS'
        'ACGA_GL_TASK'      */
    fvs.flex_value_set_name = 'ACGA_GL_FUND'
    AND fv.flex_value_meaning NOT IN ('000','001','387','612')
    AND SUBSTR(fv.flex_value_meaning,3,1) BETWEEN '0' AND '9'
ORDER BY 
    fund_code