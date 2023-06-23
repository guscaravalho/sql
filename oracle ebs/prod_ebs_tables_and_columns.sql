SELECT 
    at.owner        AS schema
    ,t.table_name
    ,c.column_name
    ,at.num_rows    AS rows_in_table
    ,c.description  AS column_description
    ,t.description  AS table_description

FROM FND_COLUMNS c

LEFT OUTER JOIN FND_TABLES t
    ON c.table_id = t.table_id
    
LEFT OUTER JOIN ALL_TABLES at
    ON t.table_name = at.table_name

WHERE
--    t.table_name LIKE '%FND_USER%'
    c.column_name LIKE 'PAYMENT_ID'
    AND at.num_rows > 0
    
ORDER BY
    schema
    ,table_name
    ,column_name