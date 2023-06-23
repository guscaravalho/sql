WITH 
    flex_values AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fv.flex_value_id
            ,fv.flex_value              AS fund_code
            ,fv.flex_value_meaning
            ,fv.description             AS fund_name
            ,(CASE   
                WHEN fv.summary_flag = 'Y' THEN 'Parent'
                WHEN fv.summary_flag = 'N' THEN 'Child' END) AS hierarchy_role
            ,fv.enabled_flag
            ,(CASE
                WHEN fv.enabled_flag = 'Y' THEN 'Enabled'
                WHEN fv.enabled_flag = 'N' THEN 'Not Enabled' END)
                                        AS flex_value_status
            ,fv.start_date_active       AS valid_start_date
            ,fv.end_date_active         AS valid_end_date
            ,(CASE
                WHEN fv.start_date_active IS NULL AND fv.end_date_active IS NULL THEN 'Valid'
                WHEN fv.start_date_active IS NULL AND TRUNC(fv.end_date_active) > sysdate THEN 'Valid'
                WHEN fv.end_date_active IS NULL AND TRUNC(fv.start_date_active) < sysdate THEN 'Valid'
                WHEN sysdate BETWEEN TRUNC(fv.start_date_active) AND TRUNC(fv.end_date_active) THEN 'Valid' 
                ELSE 'Not Valid' END)
                                        AS flex_value_validity

        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_FUND'
            AND fv.flex_value NOT IN ('000','001'))
            
    ,fund_types AS
        (SELECT 
            fv.flex_value                                       AS fund_code
            ,fv.description                               	    AS fund_name
            ,fv.flex_value||' '||fv.description    	    	    AS fund
            ,fv.flex_value||'_x'                                AS fund_code_x
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,1) = '1' THEN '01 General Funds'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('201','202','206','208') THEN '02 Special Revenue'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('203','204','205') THEN '03 Special Revenue BID'
                WHEN SUBSTR(fv.flex_value,1,2) IN ('31','32','33','34') THEN '04 Capital Funds'
                WHEN SUBSTR(fv.flex_value,1,2) = '35' THEN '05 Accounting Funds'
                WHEN SUBSTR(fv.flex_value,1,2) IN ('50','51','52','53') THEN '06 Enterprise Utilities'
                WHEN SUBSTR(fv.flex_value,1,2) IN ('54','57') THEN '07 Enterprise Funds'
                WHEN SUBSTR(fv.flex_value,1,1) = '6' THEN '08 Internal Service Funds'
                WHEN SUBSTR(fv.flex_value,1,1) = '7' THEN '09 Trust Funds'
                WHEN SUBSTR(fv.flex_value,1,1) = '8' THEN '10 Schools Funds' END)
                                                                AS fund_type
            ,fv.flex_value_id                             		AS flex_value_id
            ,fvs.flex_value_set_name                      		AS flex_value_set_name
            ,fv.flex_value_set_id                         		AS flex_value_set_id
           
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACGA_GL_FUND')

SELECT 
    ft.fund_code
    ,ft.fund_name
    ,ft.fund
    ,ft.fund_type
    ,fv.hierarchy_role
    ,fv.flex_value_status
    ,fv.flex_value_validity
    ,fv.valid_start_date
    ,fv.valid_end_date
    ,ft.fund_code_x
    ,fv.flex_value_id
    ,fv.flex_value_set_name

FROM FLEX_VALUES fv

LEFT OUTER JOIN FUND_TYPES ft
    ON fv.fund_code = ft.fund_code
    
WHERE
    fv.hierarchy_role <> 'Parent'
    
ORDER BY
    ft.fund_code