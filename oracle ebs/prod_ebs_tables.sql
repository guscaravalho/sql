SELECT 
    at.owner        AS schema
    ,t.table_name
    ,at.num_rows    AS rows_in_table
    ,t.description  AS table_description

FROM FND_TABLES t
    
LEFT OUTER JOIN ALL_TABLES at
    ON t.table_name = at.table_name

WHERE
    t.table_name LIKE '%AP_PAYMENT%'
    AND at.num_rows > 0
    
ORDER BY
    schema
    ,table_name