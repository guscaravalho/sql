SELECT    
    fv.flex_value_meaning AS source_of_funds_code
    
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
    fvs.flex_value_set_name = 'ACGA_GL_SOURCE_OF_FUNDS'
    
ORDER BY 
    source_of_funds_code