WITH
    employees AS
        (SELECT
            employee_num          AS employee_number
            ,global_name          AS employee_name
            ,email_address        AS employee_email
            ,employee_id
            ,supervisor_id
            ,inactive_date
            
        FROM PER_EMPLOYEES_X)
        
    ,supervisors AS
        (SELECT
            employee_num          AS supervisor_employee_number
            ,global_name          AS supervisor_name
            ,email_address        AS supervisor_email
            ,employee_id
            
        FROM PER_EMPLOYEES_X)

SELECT
    e.employee_number
    ,e.employee_name
    ,e.employee_email
    ,s.supervisor_employee_number
    ,s.supervisor_name
    ,s.supervisor_email    
    
FROM EMPLOYEES e

LEFT OUTER JOIN SUPERVISORS s
    ON e.supervisor_id = s.employee_id
    
WHERE
    e.inactive_date IS NULL
    
ORDER BY
    e.employee_name
