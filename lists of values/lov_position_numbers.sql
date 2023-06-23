SELECT 
    DISTINCT segment4 AS position_number
FROM PER_POSITION_DEFINITIONS
WHERE segment4 <> '00'
ORDER BY
    segment4