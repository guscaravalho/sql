WITH
    fiscal_years AS
        (SELECT '2010' AS fiscal_year FROM dual
            UNION SELECT '2011' FROM dual
            UNION SELECT '2012' FROM dual
            UNION SELECT '2013' FROM dual
            UNION SELECT '2014' FROM dual
            UNION SELECT '2015' FROM dual
            UNION SELECT '2016' FROM dual
            UNION SELECT '2017' FROM dual
            UNION SELECT '2018' FROM dual
            UNION SELECT '2019' FROM dual
            UNION SELECT '2020' FROM dual
            UNION SELECT '2021' FROM dual
            UNION SELECT '2022' FROM dual
            UNION SELECT '2023' FROM dual)
SELECT
    fiscal_year
FROM fiscal_years
ORDER BY fiscal_year DESC