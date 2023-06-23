WITH
    status_options AS
        (SELECT 'Posted' AS je_status FROM DUAL
            UNION SELECT 'Not Posted' FROM DUAL)
SELECT
    je_status
FROM STATUS_OPTIONS
ORDER BY 
    je_status DESC