WITH
    journals AS
        (SELECT
            DISTINCT gll.je_header_id||'-'||gll.je_line_num      AS je_header_and_line_number
            ,gll.je_header_id                           AS je_header_id
            ,gll.je_line_num                            AS je_line_number
            ,gll.period_name||'.'                       AS period_name
            ,(CASE
                WHEN SUBSTR(gll.period_name,1,3) = 'JUL' THEN '01 JUL.'
                WHEN SUBSTR(gll.period_name,1,3) = 'AUG' THEN '02 AUG.'
                WHEN SUBSTR(gll.period_name,1,3) = 'SEP' THEN '03 SEP.'
                WHEN SUBSTR(gll.period_name,1,3) = 'OCT' THEN '04 OCT.'
                WHEN SUBSTR(gll.period_name,1,3) = 'NOV' THEN '05 NOV.'
                WHEN SUBSTR(gll.period_name,1,3) = 'DEC' THEN '06 DEC.'
                WHEN SUBSTR(gll.period_name,1,3) = 'JAN' THEN '07 JAN.'
                WHEN SUBSTR(gll.period_name,1,3) = 'FEB' THEN '08 FEB.'
                WHEN SUBSTR(gll.period_name,1,3) = 'MAR' THEN '09 MAR.'
                WHEN SUBSTR(gll.period_name,1,3) = 'APR' THEN '10 APR.'
                WHEN SUBSTR(gll.period_name,1,3) = 'MAY' THEN '11 MAY.'
                WHEN SUBSTR(gll.period_name,1,3) = 'JUN' THEN '12 JUN.'
                WHEN SUBSTR(gll.period_name,1,4) = 'ADJ1' THEN '13 ADJ1.'
                WHEN SUBSTR(gll.period_name,1,4) = 'ADJ2' THEN '14 ADJ2.' END)
                                                        AS accounting_period
            ,(CASE
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'JUL'    THEN '01 JUL.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'AUG'    THEN '02 AUG.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'SEP'    THEN '03 SEP.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'OCT'    THEN '04 OCT.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'NOV'    THEN '05 NOV.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'DEC'    THEN '06 DEC.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'JAN'    THEN '07 JAN.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'FEB'    THEN '08 FEB.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'MAR'    THEN '09 MAR.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'APR'    THEN '10 APR.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'MAY'    THEN '11 MAY.'
                WHEN SUBSTR(TRUNC(gll.effective_date),4,3) = 'JUN'    THEN '12 JUN.' END)
                                                        AS fiscal_month
            ,(CASE 
                WHEN TO_CHAR(SUBSTR(gll.effective_date,4,3)) 
                IN ('JUL','AUG','SEP','OCT','NOV','DEC')
                THEN TO_CHAR(TO_NUMBER(SUBSTR(gll.effective_date,8,4))+1)
                WHEN TO_CHAR(SUBSTR(gll.effective_date,4,3)) 
                IN ('JAN','FEB','MAR','APR','MAY','JUN')
                THEN TO_CHAR(SUBSTR(gll.effective_date,8,4)) END)
                                                        AS fiscal_year
            ,TRUNC(gll.creation_date)   			    AS je_line_creation_date
            ,TO_CHAR(gll.creation_date,'HH12:MI:SS AM') AS je_line_created_time
            ,TRUNC(glh.posted_date)     			    AS je_header_posted_date
            ,gll.effective_date         			    AS je_line_effective_date
            ,(CASE  
                WHEN glh.actual_flag = 'A' THEN '4 Actual'
                WHEN glh.actual_flag = 'B' THEN '1 Budget'
                WHEN glh.actual_flag = 'E' AND glet.encumbrance_type = 'Commitment'
                THEN '2 Pre-Encumbrance'
                WHEN glh.actual_flag = 'E' AND glet.encumbrance_type <> 'Commitment'
                THEN '3 Encumbrance' END)   			
                                                        AS je_type
            ,(CASE  
                WHEN glet.encumbrance_type = 'Commitment'   THEN '1 Commitment'
                WHEN glet.encumbrance_type = 'Obligation'   THEN '2 Obligation'
                WHEN glet.encumbrance_type = 'Invoices'     THEN '3 Invoice In Process' END)
                                                        AS encumbrance_type
            ,COALESCE(gll.accounted_dr,0)  			    AS debit
            ,COALESCE(gll.accounted_cr,0)  			    AS credit
            ,COALESCE(gll.accounted_dr,0) - COALESCE(gll.accounted_cr,0)
                                                        AS amount
            ,COALESCE(glh.running_total_accounted_dr,0) AS je_total_debit
            ,COALESCE(glh.running_total_accounted_cr,0) AS je_total_credit
            ,COALESCE(glh.running_total_accounted_dr,0) - COALESCE(glh.running_total_accounted_cr,0)
                                                        AS je_total_amount
            ,gll.code_combination_id                    AS code_combination_id
            ,gll.reference_5       
            ,gll.reference_7                            AS ae_header_id
            ,glbv.budget_name                           AS budget_name     
            ,gll.gl_sl_link_table       
            ,glh.je_category
            ,gljc.user_je_category_name                 AS je_category_name
            ,gljc.description                           AS je_category_description
            ,glh.je_source
            ,glh.created_by
            ,glh.name                                   AS je_header_name
            ,glh.description                            AS je_header_description
            ,gll.description                            AS je_line_description 
            ,(CASE  	
                WHEN glh.status = 'P' THEN 'Posted'
                WHEN glh.status = 'U' THEN 'Not Posted' END)     
                                                        AS je_status
            ,glh.je_batch_id
            ,glb.name                                   AS je_batch_name
            ,glb.description                            AS je_batch_description
            ,glh.ledger_id
            ,ledg.name                                  AS set_of_books
            ,glh.encumbrance_type_id
            ,glh.budget_version_id
            ,glh.balanced_je_flag
            ,glh.je_from_sla_flag
            ,glh.actual_flag
    
        FROM GL_JE_LINES gll 

        LEFT OUTER JOIN GL_JE_HEADERS glh
            ON gll.je_header_id = glh.je_header_id
            
        LEFT OUTER JOIN GL_LEDGERS ledg
            ON glh.ledger_id = ledg.ledger_id
            
        LEFT OUTER JOIN GL_JE_BATCHES glb
            ON glh.je_batch_id = glb.je_batch_id

        LEFT OUTER JOIN GL_JE_CATEGORIES gljc
            ON glh.je_category = gljc.je_category_name

        LEFT OUTER JOIN GL_ENCUMBRANCE_TYPES glet
            ON glh.encumbrance_type_id = glet.encumbrance_type_id
            
        LEFT OUTER JOIN GL_BUDGET_VERSIONS glbv
            ON glh.budget_version_id = glbv.budget_version_id
            
        WHERE
/*
These four filters restrict the output of this journals CTE to
(1) Set of Books 1 ('ACGA Set of Books')
(2) The revised budget (as opposed to adopted)
(3) Non-technical accounting transactions (excluding consolidation and depreciation)
(4) Only "commitment" and "obligation" encumbrance transactions, omitting "invoice in process"
    due to the GL journal aggregation issues related to that transaction type 
*/
            ledg.name = 'ACGA Set of Books'
            AND glbv.budget_name LIKE '%REVISED%' OR glbv.budget_name IS NULL
            AND gljc.user_je_category_name NOT IN ('Consolidation','Depreciation')
            AND glet.encumbrance_type IN ('Commitment','Obligation')
                OR glet.encumbrance_type IS NULL)
    
    ,funds AS
        (SELECT 
            fv.flex_value_meaning       AS fund_code
            ,fv.description             AS fund_name
            ,fv.flex_value_meaning||' '||fv.description AS fund
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_FUND')
            
    ,natural_accounts AS
        (SELECT 
            fv.flex_value_meaning       AS natural_account_code
            ,fv.description             AS natural_account_name
            ,fv.flex_value_meaning||' '||fv.description AS natural_account
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_NATURAL_ACCOUNT')
            
    ,cost_centers AS
        (SELECT 
            fv.flex_value_meaning       AS cost_center_code
            ,fv.description             AS cost_center_name
            ,fv.flex_value_meaning||' '||fv.description AS cost_center
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_COST_CENTER')
            
    ,projects AS
        (SELECT 
            fv.flex_value_meaning       AS project_code
            ,fv.description             AS project_name
            ,fv.flex_value_meaning||' '||fv.description AS project
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_PROJECT')
            
    ,sources_of_funds AS
        (SELECT 
            fv.flex_value_meaning       AS source_of_funds_code
            ,fv.description             AS source_of_funds_name
            ,fv.flex_value_meaning||' '||fv.description AS source_of_funds
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_SOURCE_OF_FUNDS')
            
    ,tasks AS
        (SELECT 
            fv.flex_value_meaning       AS task_code
            ,fv.description             AS task_name
            ,fv.flex_value_meaning||' '||fv.description AS task
                
        FROM FND_FLEX_VALUES_VL fv
        
        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
        
        WHERE
            fvs.flex_value_set_name = 'ACGA_GL_TASK')
            
    ,gl_accounts AS
        (SELECT
            glcc.code_combination_id
            ,glcc.segment1              			    AS fund_code
            ,f.fund_name
            ,f.fund
            ,glcc.segment2              			    AS natural_account_code
            ,na.natural_account_name
            ,na.natural_account
            ,glcc.segment3              			    AS cost_center_code
            ,cc.cost_center_name
            ,cc.cost_center
            ,glcc.segment4              			    AS project_code
            ,p.project_name
            ,p.project
            ,glcc.segment5              			    AS source_of_funds_code
            ,sof.source_of_funds_name
            ,sof.source_of_funds
            ,glcc.segment6              			    AS task_code
            ,t.task_name
            ,t.task
            ,glcc.segment1||'.'||glcc.segment2||'.'||glcc.segment3||'.'||
                glcc.segment4||'.'||glcc.segment5||'.'||glcc.segment6
                                                        AS account_string_concat
            ,(CASE  
                WHEN SUBSTR(glcc.segment3,1,3) = '101'  THEN '01 County Board'
                WHEN SUBSTR(glcc.segment3,1,3) = '102'  THEN '02 County Manager'
                WHEN SUBSTR(glcc.segment3,1,3) = '103'  THEN '03 Management and Finance'
                WHEN SUBSTR(glcc.segment3,1,3) = '104'  THEN '04 Civil Service Commission'
                WHEN SUBSTR(glcc.segment3,1,2) = '12'   THEN '05 Human Resources'
                WHEN SUBSTR(glcc.segment3,1,2) = '13'   THEN '06 Technology Services'
                WHEN SUBSTR(glcc.segment3,1,3) = '141'  THEN '07 County Attorney'
                WHEN SUBSTR(glcc.segment3,1,3) = '142'  THEN '08 Commissioner of Revenue'
                WHEN SUBSTR(glcc.segment3,1,3) = '143'  THEN '09 Treasurer'
                WHEN SUBSTR(glcc.segment3,1,3) = '144'  THEN '10 Registrar'
                WHEN SUBSTR(glcc.segment3,1,3) = '201'  THEN '11 Circuit Court Judiciary'
                WHEN SUBSTR(glcc.segment3,1,3) = '202'  THEN '12 Circuit Court Clerk'
                WHEN SUBSTR(glcc.segment3,1,3) = '203'  THEN '13 District Court'
                WHEN SUBSTR(glcc.segment3,1,3) IN ('204','206') THEN '14 Juvenile / Domestic Court'
                WHEN SUBSTR(glcc.segment3,1,3) = '207'  THEN '15 Commonwealth''s Attorney'
                WHEN SUBSTR(glcc.segment3,1,3) = '208'  THEN '16 Magistrate'
                WHEN SUBSTR(glcc.segment3,1,3) = '209'  THEN '17 Public Defender'
                WHEN SUBSTR(glcc.segment3,1,2) = '22'   THEN '18 Sheriff'
                WHEN SUBSTR(glcc.segment3,1,2) = '31'   THEN '19 Police'
                WHEN SUBSTR(glcc.segment3,1,2) = '32'   THEN '20 Emergency Management'
                WHEN SUBSTR(glcc.segment3,1,2) = '34'   THEN '21 Fire'
                WHEN SUBSTR(glcc.segment3,1,1) = '4'    THEN '22 Environmental Services'
                WHEN SUBSTR(glcc.segment3,1,1) = '5'    THEN '23 Human Services'
                WHEN SUBSTR(glcc.segment3,1,1) = '6'    THEN '24 Libraries'
                WHEN SUBSTR(glcc.segment3,1,2) = '71'   THEN '25 Economic Development'
                WHEN SUBSTR(glcc.segment3,1,2) = '72'   THEN '26 Planning and Housing'
                WHEN SUBSTR(glcc.segment3,1,1) = '8'    THEN '27 Parks and Recreation'
                WHEN SUBSTR(glcc.segment3,1,3) IN ('910','911','912') 
                    OR SUBSTR(glcc.segment3,1,2) IN ('00','99') 
                    OR glcc.segment3 = '10001' THEN '28 Non-Departmental'
                WHEN SUBSTR(glcc.segment3,1,3) = '913'  THEN '29 Schools'
                WHEN SUBSTR(glcc.segment3,1,3) = '914'  THEN '30 Retirement' END)
                                                        AS department
                                                        
        FROM GL_CODE_COMBINATIONS glcc
        
        LEFT OUTER JOIN FUNDS f
            ON glcc.segment1 = f.fund_code
        
        LEFT OUTER JOIN NATURAL_ACCOUNTS na
            ON glcc.segment2 = na.natural_account_code
            
        LEFT OUTER JOIN COST_CENTERS cc
            ON glcc.segment3 = cc.cost_center_code
        
        LEFT OUTER JOIN PROJECTS p
            ON glcc.segment4 = p.project_code
            
        LEFT OUTER JOIN SOURCES_OF_FUNDS sof
            ON glcc.segment5 = sof.source_of_funds_code

        LEFT OUTER JOIN TASKS t
            ON glcc.segment6 = t.task_code)
    
    ,natural_account_levels AS
        (SELECT 
            fv.flex_value                                       AS natural_account_code
            ,fv.description                               	    AS natural_account_name
            ,fv.flex_value||' '||fv.description    	    	    AS natural_account
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,1) = '1' THEN '1 Asset'
                WHEN SUBSTR(fv.flex_value,1,1) = '2' THEN '2 Liability'
                WHEN SUBSTR(fv.flex_value,1,3) BETWEEN '300' AND '348'
                    OR SUBSTR(fv.flex_value,1,3) BETWEEN '350' AND '399' THEN '3 Revenue'
                WHEN SUBSTR(fv.flex_value,1,1) = '4'
                    OR SUBSTR(fv.flex_value,1,3) = '349' THEN '4 Expenditure'
                WHEN SUBSTR(fv.flex_value,1,1) = '5' THEN '5 Owner''s Equity'
                WHEN fv.flex_value = '0' THEN '4 Expenditure'
                WHEN fv.flex_value = '1' THEN '1 Asset'
                WHEN fv.flex_value = '34511' THEN '3 Revenue'
                WHEN fv.flex_value = '48001' THEN '4 Expenditure'
                WHEN fv.flex_value = '53612' THEN '4 Expenditure'
                WHEN fv.flex_value = '900001' THEN '1 Asset'
                WHEN fv.flex_value = '990000' THEN '4 Expenditure'
                WHEN fv.flex_value = 'NE32' THEN '4 Expenditure'
                WHEN fv.flex_value = 'T' THEN '1 Asset'
                WHEN fv.flex_value = 'TASK' THEN '4 Expenditure' END)
                                                                AS natural_account_level_1
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,2) IN ('41','42') THEN '01 Personnel'
                WHEN SUBSTR(fv.flex_value,1,2) IN ('43','44','45','46','47','48','49')
                    OR SUBSTR(fv.flex_value,1,3) = '349' THEN '02 Non Personnel' END)
                                                                AS natural_account_level_1_5
            ,(CASE
                WHEN SUBSTR(fv.flex_value,1,3) = '110' OR fv.flex_value = '111210' THEN '01 Cash'
                WHEN SUBSTR(fv.flex_value,1,4) IN ('1110','1111','1270','1280') THEN '02 Cash and Investments Held with Trustee'
                WHEN SUBSTR(fv.flex_value,1,4) IN ('1113','1114','1115') THEN '03 Investments'
                WHEN SUBSTR(fv.flex_value,1,2) IN ('41','42') THEN '01 Personnel'
                WHEN SUBSTR(fv.flex_value,1,2) IN ('43','44','45','46','47') THEN '02 Operating'
                WHEN SUBSTR(fv.flex_value,1,2) = '48' THEN '03 Capital Outlay'
                WHEN SUBSTR(fv.flex_value,1,2) = '49' THEN '04 Other'
                WHEN SUBSTR(fv.flex_value,1,3) = '349' THEN '05 Work For Others'
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
                WHEN SUBSTR(fv.flex_value,1,2) = '39' THEN '13 Transfers and Budget' END)
                                                                AS natural_account_level_2
            ,(CASE
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
                WHEN SUBSTR(fv.flex_value,1,3) = '349' THEN '23 Work For Others'
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
                WHEN SUBSTR(fv.flex_value,1,4) = '3153' THEN '17 Communication Tax' END)
                                                                AS natural_account_level_3
            ,fv.flex_value_id                             		AS flex_value_id
            ,fvs.flex_value_set_name                      		AS flex_value_set_name
            ,fv.flex_value_set_id                         		AS flex_value_set_id
           
        FROM FND_FLEX_VALUES_VL fv

        LEFT OUTER JOIN FND_FLEX_VALUE_SETS fvs
            ON fv.flex_value_set_id = fvs.flex_value_set_id
            
        WHERE 
            fvs.flex_value_set_name = 'ACGA_GL_NATURAL_ACCOUNT')
            
    ,accounting_events AS
        (SELECT
            gir.je_header_id                AS je_header_id
            ,gir.je_line_num                AS je_line_number
            ,ael.ae_header_id
            ,ael.description
            ,ael.accounting_class_code
            ,aed.source_distribution_id_num_1   AS subledger_dist_id
            ,aed.source_distribution_type
            
        FROM GL_IMPORT_REFERENCES gir
        
        LEFT OUTER JOIN XLA_AE_LINES ael
            ON gir.gl_sl_link_id = ael.gl_sl_link_id
            AND gir.gl_sl_link_table = ael.gl_sl_link_table
            
        LEFT OUTER JOIN XLA_AE_HEADERS aeh
            ON ael.ae_header_id = aeh.ae_header_id
            
        LEFT OUTER JOIN XLA_DISTRIBUTION_LINKS aed
            ON ael.ae_header_id = aed.ae_header_id
            AND ael.ae_line_num = aed.ae_line_num)

--These are the four source_distribution_type values that push up to the accounting events tables
--from the subledgers:
--AP_INV_DIST                 (invoices)
--PO_DISTRIBUTIONS_ALL        (purchase_orders)
--PO_REQ_DISTRIBUTIONS_ALL    (requisitions)
--AP_PMT_DIST                 (payments)

    ,invoices AS
        (SELECT
            id.invoice_distribution_id      AS payables_subledger_dist_id
            ,id.distribution_line_number
            ,id.amount                      AS distribution_amount
            ,i.invoice_id
            ,i.vendor_id
            ,i.invoice_num                  AS invoice_number                       
            ,poh.po_header_id
            ,poh.segment1                   AS po_number
            ,poh.attribute1                 AS purchasing_authority_number
            ,poh.attribute4                 AS quick_quote_number
            ,(CASE
                WHEN SUBSTR(poh.attribute1,1,1) = 'Q' THEN poh.attribute1||' '||poh.attribute4
                ELSE poh.attribute1 END) 
                                            AS purchasing_authority

        FROM AP_INVOICE_DISTRIBUTIONS_ALL id
            
        LEFT OUTER JOIN AP_INVOICES_ALL i
            ON id.invoice_id = i.invoice_id
            
        LEFT OUTER JOIN PO_DISTRIBUTIONS_ALL pod
            ON id.po_distribution_id = pod.po_distribution_id
            
        LEFT OUTER JOIN PO_HEADERS_ALL poh
            ON pod.po_header_id = poh.po_header_id)
            
    ,suppliers AS
        (SELECT
            s.vendor_id
            ,s.segment1                             AS supplier_number
            ,INITCAP(s.vendor_name)                 AS supplier_name            
            ,(CASE   
                WHEN s.enabled_flag = 'Y' THEN 'Enabled'
                WHEN s.enabled_flag = 'N' THEN 'Not Enabled' END)                                   		
                                                    AS supplier_status
            ,(CASE
                WHEN TRUNC(sysdate) >= TRUNC(s.start_date_active) AND s.end_date_active IS NULL THEN 'Valid'
                ELSE 'Not Valid' END)              
                                                    AS supplier_validity
            ,TRUNC(s.start_date_active)             AS supplier_active_date_start
            ,TRUNC(s.end_date_active)               AS supplier_active_date_end
            ,s.hold_all_payments_flag
            
            ,INITCAP(s.vendor_type_lookup_code)     AS supplier_type
            ,s.employee_id
            ,(CASE
                WHEN s.payment_method_lookup_code = 'EFT' THEN 'EFT'
                ELSE INITCAP(s.payment_method_lookup_code) END)
                                                    AS payment_method
            ,INITCAP(s.pay_group_lookup_code)       AS payment_group

        FROM AP_SUPPLIERS s)
    
    ,employees AS 
        (SELECT 
            e.employee_id
            ,e.assignment_id
            ,e.employee_num                 AS employee_number
            ,e.global_name                  AS employee_name
            ,u.user_id
            ,u.user_name                    AS prism_user_name
            ,e.inactive_date                AS employee_inactive_date
            ,(CASE   
                WHEN e.inactive_date IS NULL THEN 'Active'
                ELSE 'Not Active' END)
                                            AS employee_status
            ,e.organization_id
            ,org.name                       AS org_name
            ,(CASE
                WHEN SUBSTR(org.name,1,3) = 'AED' THEN '25 Economic Development'
                WHEN SUBSTR(org.name,1,3) = 'CAO' THEN '07 County Attorney'
                WHEN SUBSTR(org.name,1,3) = 'CBO' THEN '01 County Board'
                WHEN SUBSTR(org.name,1,3) = 'CCJ' THEN '11 Circuit Court Judiciary'
                WHEN SUBSTR(org.name,1,3) = 'CCT' THEN '12 Circuit Court Clerk'
                WHEN SUBSTR(org.name,1,3) = 'CMO' THEN '02 County Manager'
                WHEN SUBSTR(org.name,1,3) = 'COR' THEN '08 Commissioner of Revenue'
                WHEN SUBSTR(org.name,1,3) = 'CPH' THEN '26 Planning and Housing'
                WHEN SUBSTR(org.name,1,3) = 'CWA' THEN '15 Commonwealth''s Attorney'
                WHEN SUBSTR(org.name,1,3) = 'DES' THEN '22 Environmental Services'
                WHEN SUBSTR(org.name,1,3) = 'DHS' THEN '23 Human Services'
                WHEN SUBSTR(org.name,1,3) = 'DMF' THEN '03 Management and Finance'
                WHEN SUBSTR(org.name,1,3) = 'DPR' THEN '27 Parks and Recreation'
                WHEN SUBSTR(org.name,1,3) = 'DTS' THEN '06 Technology Services'
                WHEN SUBSTR(org.name,1,3) = 'FIR' THEN '21 Fire'
                WHEN SUBSTR(org.name,1,3) = 'GDC' THEN '13 District Court'
                WHEN SUBSTR(org.name,1,3) = 'HRD' THEN '05 Human Resources'
                WHEN SUBSTR(org.name,1,3) = 'JDR' THEN '14 Juvenile / Domestic Court'
                WHEN SUBSTR(org.name,1,3) = 'LIB' THEN '24 Libraries'
                WHEN SUBSTR(org.name,1,3) = 'MAG' THEN '16 Magistrate'
                WHEN SUBSTR(org.name,1,3) = 'OEM' THEN '20 Emergency Management'
                WHEN SUBSTR(org.name,1,3) = 'PDO' THEN '17 Public Defender'
                WHEN SUBSTR(org.name,1,3) = 'POL' THEN '19 Police'
                WHEN SUBSTR(org.name,1,3) = 'PPO' THEN '19 Police'
                WHEN SUBSTR(org.name,1,3) = 'PSC' THEN '20 Emergency Management'
                WHEN SUBSTR(org.name,1,3) = 'REG' THEN '10 Registrar'
                WHEN SUBSTR(org.name,1,3) = 'SRF' THEN '18 Sheriff'
                WHEN SUBSTR(org.name,1,3) = 'TRS' THEN '09 Treasurer'
                WHEN SUBSTR(org.name,1,3) = 'OFF' THEN '17 Public Defender'
                WHEN SUBSTR(org.name,1,3) = 'RET' THEN '30 Retirement' END)
                                            AS department      
        FROM PER_EMPLOYEES_X e
        
        LEFT OUTER JOIN FND_USER u
            ON e.employee_id = u.employee_id

        LEFT OUTER JOIN PER_ALL_ORGANIZATION_UNITS org
            ON e.organization_id = org.organization_id)
            
SELECT 
    DISTINCT j.je_header_and_line_number        AS je_header_and_line_number
    ,j.je_header_id                             AS je_header_id
    ,j.je_line_number                           AS je_line_number
    ,j.period_name
    ,j.accounting_period
    ,j.fiscal_month
    ,j.fiscal_year
    ,j.je_line_creation_date    			    AS created_date
    ,j.je_line_created_time                     AS created_time
    ,j.je_header_posted_date      			    AS posted_date
    ,j.je_line_effective_date      			    AS effective_date
    ,j.je_type
    ,j.je_category_name                

    ,j.debit
    ,j.credit
    ,j.amount                                   AS net_amount
    
    ,sinv.supplier_name
    ,inv.invoice_number
    
    ,gla.department                             AS department
    ,nal.natural_account_level_1                AS account_class
    ,nal.natural_account_level_2                AS account_type
    ,nal.natural_account_level_3                AS account_subtype
    
    ,gla.fund_code
    ,gla.natural_account_code
    ,gla.cost_center_code
    ,gla.project_code
    ,gla.source_of_funds_code
    ,gla.task_code
    ,gla.account_string_concat
    
    ,gla.fund_name
    ,gla.natural_account_name
    ,gla.cost_center_name
    ,gla.project_name
    ,gla.source_of_funds_name
    ,gla.task_name
    
    ,gla.fund
    ,gla.natural_account
    ,gla.cost_center
    ,gla.project
    ,gla.source_of_funds
    ,gla.task
    
    ,gla.fund_code||'_x'              			AS fund_code_x
    ,gla.natural_account_code||'_x'             AS natural_account_code_x
    ,gla.cost_center_code||'_x'                 AS cost_center_code_x
    ,gla.project_code||'_x'                		AS project_code_x
    ,gla.source_of_funds_code||'_x'             AS source_of_funds_code_x
    ,gla.task_code||'_x'                		AS task_code_x
    ,j.je_line_effective_date                   AS effective_date_x
    
    ,j.je_source
    ,COALESCE(e.employee_name,'System Generated')   AS je_author

    ,j.je_header_name
    ,j.je_header_description
    ,j.je_line_description
    ,j.je_batch_name
    ,j.je_batch_description

    ,j.je_status
    ,j.set_of_books                             AS gl_set_of_books
    ,j.budget_name                              as gl_budget_name
    ,j.je_batch_id
    ,j.ledger_id
    ,j.budget_version_id
    ,j.balanced_je_flag
    ,j.je_from_sla_flag
    ,j.actual_flag
    ,TRUNC(sysdate)                             AS report_run_date

FROM JOURNALS j

LEFT OUTER JOIN ACCOUNTING_EVENTS ae
    ON j.je_header_id = ae.je_header_id
    AND j.je_line_number = ae.je_line_number

LEFT OUTER JOIN INVOICES inv
    ON ae.subledger_dist_id = inv.payables_subledger_dist_id
    AND ae.source_distribution_type = 'AP_INV_DIST'
    
LEFT OUTER JOIN SUPPLIERS sinv
    ON inv.vendor_id = sinv.vendor_id

LEFT OUTER JOIN GL_ACCOUNTS gla
    ON j.code_combination_id = gla.code_combination_id
    
LEFT OUTER JOIN NATURAL_ACCOUNT_LEVELS nal
    ON gla.natural_account_code = nal.natural_account_code

LEFT OUTER JOIN EMPLOYEES e
    ON j.created_by = e.user_id
    
WHERE
    j.je_type = '4 Actual'
    AND nal.natural_account_level_1 = '1 Asset'
--    gla.natural_account_code = '110431'
    AND j.je_category_name <> 'Consolidation'
--    AND gla.fund_code = '101'
--    AND gla.department = '03 Management and Finance'
    AND j.je_line_effective_date BETWEEN '01-DEC-2022' AND '31-DEC-2022'
--    AND j.accounting_period = 'DEC-22.'

ORDER BY 
    j.je_line_effective_date DESC