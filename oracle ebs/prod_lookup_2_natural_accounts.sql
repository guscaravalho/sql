WITH 
    flex_values AS
        (SELECT 
            fv.flex_value_set_id
            ,fvs.flex_value_set_name
            ,fv.flex_value_id
            ,fv.flex_value              AS natural_account_code
            ,fv.flex_value_meaning
            ,fv.description             AS natural_account_name
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
            fvs.flex_value_set_name = 'ACGA_GL_NATURAL_ACCOUNT')
            
    ,natural_account_levels AS
        (SELECT 
            fv.flex_value                                       AS natural_account_code
            ,fv.description                               	    AS natural_account_name
            ,fv.flex_value||' '||fv.description    	    	    AS natural_account
            ,fv.flex_value||'_x'                                AS natural_account_code_x
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,1) = '1' THEN '1 Asset'
                WHEN SUBSTR(fv.flex_value,1,1) = '2' THEN '2 Liability'
                WHEN SUBSTR(fv.flex_value,1,3) BETWEEN '300' AND '348'
                    OR SUBSTR(fv.flex_value,1,3) BETWEEN '350' AND '399' THEN '3 Revenue'
                WHEN SUBSTR(fv.flex_value,1,1) = '4'
                    OR SUBSTR(fv.flex_value,1,3) = '349' THEN '4 Expenditure'
                WHEN SUBSTR(fv.flex_value,1,1) = '5' THEN '5 Owner''s Equity' END)
                                                                AS natural_account_level_1
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,2) IN ('41','42') THEN '01 Personnel'
                WHEN SUBSTR(fv.flex_value,1,2) IN ('43','44','45','46','47','48','49')
                    OR SUBSTR(fv.flex_value,1,3) = '349' THEN '02 Operating' END)
                                                                AS natural_account_level_1_5
            ,(CASE
            -- Assets
                WHEN SUBSTR(fv.flex_value,1,3) = '110' OR fv.flex_value = '111210' THEN '01 Cash'
                WHEN SUBSTR(fv.flex_value,1,4) IN ('1110','1111','1270','1280') THEN '02 Cash and Investments Held with Trustee'
                WHEN SUBSTR(fv.flex_value,1,4) IN ('1113','1114','1115') THEN '03 Investments'
            -- Revenues
                WHEN SUBSTR(fv.flex_value,1,3) = '310' THEN '01 Local Taxes'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('311','312','316') THEN '02 Property Taxes'
                WHEN SUBSTR(fv.flex_value,1,5) = '31491' THEN '02 Property Taxes'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('313','315') THEN '03 Other Local Taxes'
                WHEN SUBSTR(fv.flex_value,1,4) IN ('3140','3141','3142','3143','3144','3145'
                    ,'3146','3147','3148') THEN '03 Other Local Taxes'
                WHEN SUBSTR(fv.flex_value,1,5) = '31490' THEN '03 Other Local Taxes'
                WHEN SUBSTR(fv.flex_value,1,2) = '32' THEN '04 Licenses, Permits, and Fees'
                WHEN SUBSTR(fv.flex_value,1,3) = '330' THEN '05 Fines and Forfeitures'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('331','332','333','334','335','336','337','338','339')
                    THEN '06 Use of Property and Money'
                WHEN SUBSTR(fv.flex_value,1,3) BETWEEN '340' AND '348' 
                    THEN '07 Outside Charges for Services'
                WHEN SUBSTR(fv.flex_value,1,4) BETWEEN '3500' AND '3598' THEN '08 Miscellaneous Revenue'
                WHEN SUBSTR(fv.flex_value,1,4) = '3599' THEN '09 Gifts and Donations'
                WHEN SUBSTR(fv.flex_value,1,2) = '36' THEN '10 Revenue from Commonwealth of VA'
                WHEN SUBSTR(fv.flex_value,1,2) = '37' THEN '11 Revenue from Federal Government'
                WHEN SUBSTR(fv.flex_value,1,2) = '38' THEN '12 Other Revenue'
                WHEN SUBSTR(fv.flex_value,1,2) = '39' THEN '13 Transfers and Budget' 
            -- Expenditures
                WHEN SUBSTR(fv.flex_value,1,2) IN ('41','42') THEN '01 Personnel'
                WHEN SUBSTR(fv.flex_value,1,2) IN ('43','44','45','46','47') THEN '02 Operating'
                WHEN SUBSTR(fv.flex_value,1,2) = '48' THEN '03 Capital Outlay'
                WHEN SUBSTR(fv.flex_value,1,2) = '49' THEN '04 Other'
                WHEN SUBSTR(fv.flex_value,1,3) = '349' THEN '05 Work For Others'END)
                                                                AS natural_account_level_2
            ,(CASE
            -- Assets
                WHEN SUBSTR(fv.flex_value,1,5) IN ('11001','11003') THEN '01 Cash on Hand'
                WHEN SUBSTR(fv.flex_value,1,5) IN ('11004','11005') THEN '02 Truist Bank'
                WHEN SUBSTR(fv.flex_value,1,5) = '11007' THEN '03 First Virginia Community Bank'
                WHEN SUBSTR(fv.flex_value,1,5) = '11008' THEN '04 Sandy Spring Bank'
                WHEN SUBSTR(fv.flex_value,1,4) = '1102' OR fv.flex_value = '111210' THEN '05 Wells Fargo Bank'
                WHEN SUBSTR(fv.flex_value,1,5) = '11030' THEN '06 John Marshall Bank'
                WHEN SUBSTR(fv.flex_value,1,5) = '11032' THEN '07 PNC Bank'
                WHEN SUBSTR(fv.flex_value,1,5) = '11033' THEN '08 US Bank'
                WHEN SUBSTR(fv.flex_value,1,5) IN ('11035','11037','11038') THEN '09 Mercantile Bank'
                WHEN SUBSTR(fv.flex_value,1,5) IN ('11040','11042','11043') THEN '10 Bank of America'
                WHEN SUBSTR(fv.flex_value,1,5) = '11045' THEN '11 Commerce Bank'
                WHEN SUBSTR(fv.flex_value,1,6) IN ('110470','110471','110472') THEN '12 CitiBank'
                WHEN SUBSTR(fv.flex_value,1,4) = '1105' THEN '13 BB and T'
                WHEN SUBSTR(fv.flex_value,1,4) = '1106' OR SUBSTR(fv.flex_value,1,5) = '11075' THEN '14 United Bank'
                WHEN SUBSTR(fv.flex_value,1,5) = '11070' THEN '15 Bank of Georgetown'
                WHEN SUBSTR(fv.flex_value,1,5) = '11071' THEN '16 JP Morgan Bank'
                WHEN SUBSTR(fv.flex_value,1,4) = '1108' THEN '17 Burke and Hurbert'
                WHEN SUBSTR(fv.flex_value,1,4) = '1109' THEN '18 Miscellaneous Cash'
                WHEN SUBSTR(fv.flex_value,1,4) = '1110' THEN '19 US Bank IDA Lease Bond'
                WHEN SUBSTR(fv.flex_value,1,5) = '11110' THEN '20 Ballston Parking Garage'
                WHEN SUBSTR(fv.flex_value,1,5) = '11115' THEN '21 Suntrust Solid Waste'
                WHEN SUBSTR(fv.flex_value,1,3) = '127' THEN '22 First Virginia Community Bank'              
                WHEN SUBSTR(fv.flex_value,1,3) = '128' THEN '23 John Marshall Bank'                   
                WHEN SUBSTR(fv.flex_value,1,4) = '1113' AND SUBSTR(fv.flex_value,1,6) <> '111319' THEN '24 Certificates of Deposit'
                WHEN SUBSTR(fv.flex_value,1,6) = '111319' THEN '25 Repurchase Argeements'
                WHEN SUBSTR(fv.flex_value,1,4) = '1114' THEN '26 Money Market Accounts'
                WHEN SUBSTR(fv.flex_value,1,4) = '1115' THEN '27 Other Investments'
            -- Revenues
                WHEN SUBSTR(fv.flex_value,1,3) = '310' THEN '01 Real Estate Taxes'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('311','312') THEN '02 Personal Property Tax'
                WHEN SUBSTR(fv.flex_value,1,5) = '31491' THEN '03 Business Tangible Personal Property Tax'
                WHEN SUBSTR(fv.flex_value,1,3) = '316' THEN '03 Business Tangible Personal Property Tax'
                WHEN SUBSTR(fv.flex_value,1,3) = '313' THEN '04 Business (BPOL) Taxes'
                WHEN SUBSTR(fv.flex_value,1,4) = '3141' THEN '05 Local Sales Tax'
                WHEN SUBSTR(fv.flex_value,1,5) = '31490' THEN '06 Meals Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3146' THEN '07 Transient Occupancy Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3147' THEN '08 Utility Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3144' THEN '09 Recordation Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3140' THEN '10 Car Rental Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3142' THEN '11 Vehicle License Tags'
                WHEN SUBSTR(fv.flex_value,1,4) = '3143' THEN '12 Bank Stock Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3145' THEN '13 Cigarette Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3148' THEN '14 Short Term Rental Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3151' THEN '15 Estate Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3152' THEN '16 Consumption Tax'
                WHEN SUBSTR(fv.flex_value,1,4) = '3153' THEN '17 Communication Tax'
            -- Expenditures
                WHEN SUBSTR(fv.flex_value,1,2) = '41' THEN '01 Salaries'
                WHEN SUBSTR(fv.flex_value,1,2) = '42' THEN '02 Benefits'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('430','431','432','433','434','435','436')
                    THEN '03 Contract Services'
                WHEN SUBSTR(fv.flex_value,1,4) IN ('4370','4371','4372') THEN '04 Repairs / Maintenance'
                WHEN SUBSTR(fv.flex_value,1,4) IN ('4374','4375','4376','4377') THEN '05 Outside Services'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('438','439') THEN '05 Outside Services'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('440','444','446') THEN '06 Internal Services'
                WHEN SUBSTR(fv.flex_value,1,3) = '447' THEN '07 Intra-County Charges'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('450','451','465','456','457','458','459') 
                    THEN '08 Other Charges'
                WHEN SUBSTR(fv.flex_value,1,4) = '4550' THEN '09 Transfers Out'
                WHEN SUBSTR(fv.flex_value,1,4) IN ('4551','4552','4553','4554','4555')
                    THEN '08 Other Charges'
                WHEN SUBSTR(fv.flex_value,1,2) = '46' THEN '10 Materials / Supplies'
                WHEN SUBSTR(fv.flex_value,1,2) = '47' THEN '11 Accurals'
                WHEN SUBSTR(fv.flex_value,1,3) = '480' THEN '12 Capital Outlay'
                WHEN SUBSTR(fv.flex_value,1,3) = '481' THEN '13 Land'
                WHEN SUBSTR(fv.flex_value,1,3) = '482' THEN '14 Building'
                WHEN SUBSTR(fv.flex_value,1,3) IN ('483','484') THEN '15 Equipment'
                WHEN SUBSTR(fv.flex_value,1,3) = '484' THEN '16 Infrastructure'
                WHEN SUBSTR(fv.flex_value,1,3) = '485' THEN '17 Plant'
                WHEN SUBSTR(fv.flex_value,1,3) = '486' THEN '18 Auto Equipment'
                WHEN SUBSTR(fv.flex_value,1,3) = '487' THEN '19 Expensed Assets'
                WHEN SUBSTR(fv.flex_value,1,3) = '488' THEN '20 Construction in Progress'
                WHEN SUBSTR(fv.flex_value,1,3) = '489' THEN '21 Capital Lease'
                WHEN SUBSTR(fv.flex_value,1,2) = '49' THEN '22 Other Uses'
                WHEN SUBSTR(fv.flex_value,1,3) = '349' THEN '23 Work For Others' END)
                                                                AS natural_account_level_3
            ,fv.flex_value_id                             		AS flex_value_id
            ,fvs.flex_value_set_name                      		AS flex_value_set_name
            ,fv.flex_value_set_id                         		AS flex_value_set_id
           
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACGA_GL_NATURAL_ACCOUNT')

SELECT 
    nal.natural_account_code
    ,nal.natural_account_name
    ,nal.natural_account
    ,nal.natural_account_level_1                AS account_class
    ,nal.natural_account_level_2                AS account_type
    ,nal.natural_account_level_3                AS account_subtype
    ,fv.hierarchy_role
    ,fv.flex_value_status
    ,fv.flex_value_validity
    ,fv.valid_start_date
    ,fv.valid_end_date
    ,nal.natural_account_code_x
    ,fv.flex_value_id
    ,fv.flex_value_set_name

FROM FLEX_VALUES fv

LEFT OUTER JOIN NATURAL_ACCOUNT_LEVELS nal
    ON fv.natural_account_code = nal.natural_account_code

WHERE
    nal.natural_account_level_1 = '3 Revenue'
    
ORDER BY
    nal.natural_account_code