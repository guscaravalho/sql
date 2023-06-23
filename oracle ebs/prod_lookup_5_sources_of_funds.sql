WITH 
    flex_values AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fv.flex_value_id
            ,fv.flex_value              AS source_of_funds_code
            ,fv.flex_value_meaning
            ,fv.description             AS source_of_funds_name
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
            fvs.flex_value_set_name = 'ACGA_GL_SOURCE_OF_FUNDS')
            
    ,revenue_types AS
        (SELECT 
            fv.flex_value                                       AS source_of_funds_code
            ,fv.description                               	    AS source_of_funds_name
            ,fv.flex_value||' '||fv.description    	    	    AS source_of_funds
            ,fv.flex_value||'_x'                                AS source_of_funds_code_x
            ,(CASE  
                WHEN fv.description LIKE '%Bond %' THEN 'Bonds'
                WHEN SUBSTR(fv.description,1,4) IN ('CDBG','CSBG','HOME','DOJ ') THEN 'Federal Grants'
                WHEN fv.flex_value IN ('4512','ARPA','ARP2','ARP3','CRF','CV19','CVCN','CVST') THEN 'COVID-19 Revenues'
                WHEN fv.flex_value IN ('AHIF','COMC','VRZN') THEN 'Arlington Housing Investment Fund AHIF'
                END)
                                                                AS revenue_type
            ,(CASE  
            -- Bonds    
                WHEN fv.description LIKE '%Bond Premium%' THEN 'Bond Premium'
                WHEN fv.description LIKE '%Comm Cons%' AND SUBSTR(fv.flex_value,1,1) = 'C' THEN 'Neighborhood Cons Bond CPHD'
                WHEN fv.description LIKE '%DPW Comm Cons%' THEN 'Neighborhood Cons Bond DES'
                WHEN fv.description LIKE '%Schools Bond%' THEN 'Schools Bond'
                WHEN fv.description LIKE '%Fire Station Bond%' THEN 'Fire Station Bond'
                WHEN fv.description LIKE '%Gov Facilities Bond%' THEN 'Gov Facilities Bond'
                WHEN fv.description LIKE '%Library Bond%' THEN 'Library Bond'
                WHEN fv.description LIKE '%Metro Bond%' THEN 'Metro Bond'
                WHEN fv.description LIKE '%AWT Plant Bond%' THEN 'AWT Plant Bond'
                WHEN fv.description LIKE '%Parks and Rec Bond%' THEN 'Parks and Rec Bond'
                WHEN fv.description LIKE '%Highway Bond%' THEN 'Street and Highway Bond'
                WHEN fv.description LIKE '%Water Bond%' THEN 'Utility Water Bond'
                WHEN fv.description LIKE '%Sewer Bond%' THEN 'Utility Sewer Bond'
                WHEN fv.description LIKE '%Technology Bond%' THEN 'Gov Technology Bond'
                WHEN fv.description LIKE '%Stormwater Bond%' THEN 'Stormwater Bond'
                WHEN fv.description LIKE '%IDA Bond%' THEN 'IDA Bond'
            -- Federal Grants
                WHEN fv.description LIKE 'CDBG%' THEN 'Community Development Block Grant'
                WHEN fv.description LIKE 'CSBG%' THEN 'Community Services Block Grant'
                WHEN fv.description LIKE 'HOME%' THEN 'HOME Investment Partnership Grant'
                WHEN fv.description LIKE 'DOJ JAG%' THEN 'DOJ Justice Assistance Grant'
                END)
                                                                AS revenue_subtype
            ,fv.flex_value_id                             		AS flex_value_id
            ,fvs.flex_value_set_name                      		AS flex_value_set_name
            ,fv.flex_value_set_id                         		AS flex_value_set_id
           
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACGA_GL_SOURCE_OF_FUNDS')

SELECT 
    rt.source_of_funds_code
    ,rt.source_of_funds_name
    ,rt.source_of_funds
    ,rt.revenue_type
    ,rt.revenue_subtype
    ,fv.hierarchy_role
    ,fv.flex_value_status
    ,fv.flex_value_validity
    ,fv.valid_start_date
    ,fv.valid_end_date
    ,rt.source_of_funds_code_x
    ,fv.flex_value_id
    ,fv.flex_value_set_name

FROM FLEX_VALUES fv

LEFT OUTER JOIN REVENUE_TYPES rt
    ON fv.source_of_funds_code = rt.source_of_funds_code
    
ORDER BY
    rt.source_of_funds_code