WITH
    time_type_lov AS
        (SELECT 'Hours Worked' AS time_type FROM DUAL 
            UNION SELECT 'Adjustment' FROM DUAL
            UNION SELECT 'Bonus' FROM DUAL)
SELECT
    time_type
FROM TIME_TYPE_LOV
ORDER BY
    time_type DESC