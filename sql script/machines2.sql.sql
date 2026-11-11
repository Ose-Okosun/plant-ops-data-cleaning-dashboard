-- cleaning of the table MACHINE 
-- First we make a duplicate

SET SQL_SAFE_UPDATES = 0;

DROP TABLE IF EXISTS Machines2;

CREATE TABLE Machines2 AS
SELECT distinct *
FROM machines;

-- the table lettes needs to be standerdized except manufacturer so as not to change the names 

update machines2
SET machine_name = CONCAT(UPPER(LEFT(TRIM(machine_name), 1)), LOWER(SUBSTRING(TRIM(machine_name), 2))),
    machine_type  = CONCAT(UPPER(LEFT(TRIM( machine_type), 1)),  LOWER(SUBSTRING(TRIM(machine_type), 2))),
   production_line  = CONCAT(UPPER(LEFT(TRIM(production_line), 1)),  LOWER(SUBSTRING(TRIM(production_line), 2))),
    status = CONCAT(UPPER(LEFT(TRIM(status), 1)),  LOWER(SUBSTRING(TRIM(status), 2)));

-- the install_date column need a clear date format 

UPDATE machines2
SET install_date = CASE
     WHEN install_date = '00/00/0000' THEN NULL
    WHEN install_date LIKE '__/__/____'
        THEN DATE_FORMAT(STR_TO_DATE(install_date, '%d/%m/%Y'), '%Y-%m-%d')
    WHEN install_date LIKE '__-__-____'
        THEN DATE_FORMAT(STR_TO_DATE(install_date, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN install_date LIKE '__ ___ ____'
        THEN DATE_FORMAT(STR_TO_DATE(install_date, '%d %b %Y'), '%Y-%m-%d')
    WHEN install_date LIKE '%, ____'
        THEN DATE_FORMAT(STR_TO_DATE(install_date, '%M %d, %Y'), '%Y-%m-%d')
    WHEN install_date LIKE '__.__.__'
        THEN DATE_FORMAT(STR_TO_DATE(install_date, '%d.%m.%y'), '%Y-%m-%d')
    ELSE install_date
END;


-- setting invalid dates to null because they will affect the data
UPDATE machines2
SET install_date = NULL
WHERE install_date NOT LIKE '____-__-__';

-- then we change the install_date column from text to date
ALTER TABLE machines2
MODIFY install_date DATE;

-- the production_line column has some misrepresented words and i wil correct that

update machines2
set production_line = case 
when production_line in ('L4') then 'Line 4'
ELSE PRODUCTION_LINE
END;