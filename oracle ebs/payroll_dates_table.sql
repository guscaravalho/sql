
SELECT
    time_period_id
    ,period_name                                AS pay_period_name
    ,LPAD(period_num,2,'0')                     AS pay_period_number
    ,period_type                                AS pay_period_type
    ,start_date                                 AS pay_period_start_date
    ,end_date                                   AS pay_period_end_date
    ,cut_off_date       
    ,pay_advice_date
    ,regular_payment_date                       AS pay_period_paycheck_friday
    ,payslip_view_date
    ,EXTRACT(YEAR FROM regular_payment_date)    AS calendar_year
    ,'Pay ' || LPAD(period_num,2,'0')           AS cy_pay_number
    ,'CY ' || EXTRACT(YEAR FROM regular_payment_date) || ' Pay ' || LPAD(period_num,2,'0') 
                                                AS cy_pay_name
    ,'20'||(CASE 
        WHEN TO_CHAR(SUBSTR(regular_payment_date,4,3)) 
        IN ('JUL','AUG','SEP','OCT','NOV','DEC')
        THEN TO_CHAR(TO_NUMBER(SUBSTR(regular_payment_date,8,4))+1)
        WHEN TO_CHAR(SUBSTR(regular_payment_date,4,3)) 
        IN ('JAN','FEB','MAR','APR','MAY','JUN')
        THEN TO_CHAR(SUBSTR(regular_payment_date,8,4)) END)					
                                                AS fiscal_year
        
FROM PER_TIME_PERIODS   
    
WHERE
    period_type = 'Bi-Week'
    AND regular_payment_date BETWEEN '01-JUL-2023' AND '30-JUN-2024'
    
ORDER BY
    regular_payment_date DESC
