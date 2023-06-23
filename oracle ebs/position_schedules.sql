SELECT
    fv.flex_value_id
    ,fv.flex_value
    ,fv.flex_value_meaning
    ,fv.description
    ,fvs.flex_value_set_id
    ,fvs.flex_value_set_name

FROM FND_FLEX_VALUES_VL fv

LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
    ON fv.flex_value_set_id = fvs.flex_value_set_id

WHERE
    fvs.flex_value_set_name = 'ACGA_HR_POS_CAT'

/*
other HR flex value sets
'ACGA_HR_CLASS_CODE'
'ACGA_HR_POSITION_TITLE'
'ACGA_HR_JOB_CLASS'
'ACGA_HR_GRADE'
*/