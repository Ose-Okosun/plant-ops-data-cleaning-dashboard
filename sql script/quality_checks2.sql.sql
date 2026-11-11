-- cleaning quality_checks 
-- made a duplicate copy of the original work to quality_checks2

SET SQL_SAFE_UPDATES = 0;

DROP TABLE IF EXISTS quality_checks2;

CREATE TABLE quality_checks2 AS
SELECT distinct *
FROM quality_checks;

-- i created a new column data_issue to write and flag  all the errors in it 
-- made it varchar(255) because a row can have more than one issue and the labels add up
ALTER TABLE quality_checks2
ADD COLUMN data_issues VARCHAR(255);

-- the run_id table  needs to be in proper format and some id are missing in the production runs so i'll flga those as well 

UPDATE quality_checks2
SET run_id = UPPER(TRIM(run_id));

UPDATE quality_checks2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'run_id not in production_runs'
WHEN data_issues NOT LIKE '%run_id not in production_runs%' THEN CONCAT(data_issues, '; run_id not in production_runs')
ELSE data_issues
END
WHERE NOT EXISTS (
    SELECT 1
    FROM production_runs2
    WHERE production_runs2.run_id = quality_checks2.run_id
);


-- the date table needs to be standard, missing dates, or invalid dates has to be labelled and set to null
UPDATE quality_checks2
SET check_date = CASE
    WHEN check_date = '00/00/0000'
        THEN NULL
    WHEN check_date LIKE '__/__/____'
        THEN DATE_FORMAT(STR_TO_DATE(check_date, '%d/%m/%Y'), '%Y-%m-%d')
    WHEN check_date LIKE '__-__-____'
        THEN DATE_FORMAT(STR_TO_DATE(check_date, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN check_date LIKE '__ ___ ____'
        THEN DATE_FORMAT(STR_TO_DATE(check_date, '%d %b %Y'), '%Y-%m-%d')
    WHEN check_date LIKE '%, ____'
        THEN DATE_FORMAT(STR_TO_DATE(check_date, '%M %d, %Y'), '%Y-%m-%d')
    WHEN check_date LIKE '__.__.__'
        THEN DATE_FORMAT(STR_TO_DATE(check_date, '%d.%m.%y'), '%Y-%m-%d')
    ELSE check_date
END;

-- flagging the missing, null, N/A to missing dates in date_issues 

UPDATE quality_checks2
SET data_issues = CASE
WHEN data_issues IS NULL THEN 'missing date'
ELSE CONCAT(data_issues, '; missing date')
END
WHERE TRIM(check_date) IN ('', 'N/A', 'TBC')
   OR check_date IS NULL;
   
   -- then we update the check_date column  and give it a proper format 
   UPDATE quality_checks2
SET check_date = NULL
WHERE check_date NOT LIKE '____-__-__';

-- 
ALTER TABLE quality_checks2
MODIFY COLUMN check_date DATE;


-- the inspector column needs to be in proper format and the names needs to be standerdized because there are duplicates of the same name but they give different result
UPDATE quality_checks2
SET inspector = CONCAT(UPPER(LEFT(TRIM(inspector), 1)), LOWER(SUBSTRING(TRIM(inspector), 2)));

-- editing 2 names that represent the same person 

update quality_checks2
set inspector = CASE 
WHEN trim(inspector) in ('Kelechi  obi', 'Kelechi', 'Kelechi obi', 'Obi kelechi') THEN 'Kelechi obi'
WHEN TRIM(inspector) IN ('Samuel ade', 'Samuel', 'Samuel  ade', 'Ade samuel') THEN 'Samuel ade'
WHEN TRIM(inspector) IN ('Zainab yusuf', 'Zainab', 'Yusuf zainab', 'Zainab  yusuf') THEN 'Zainab yusuf'
WHEN TRIM(inspector) IN ('Peter', 'Peter nwosu', 'Nwosu peter', 'Peter  nwosu') THEN 'Peter nwosu'
WHEN TRIM(inspector) IN ('Hauwa  lawal', 'Hauwa lawal', 'Lawal hauwa', 'Hauwa') THEN 'Hauwa lawal'

ELSE inspector 
end ;


-- on the parameter column, it needs to be in proper standard and format 
UPDATE quality_checks2
SET parameter = CONCAT(UPPER(LEFT(TRIM(parameter), 1)), LOWER(SUBSTRING(TRIM(parameter), 2)));

-- the reading column should contain numbers only so i will flag the one that has no numbers first then we change them to null 

UPDATE quality_checks2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'missing reading'
ELSE CONCAT(data_issues, '; missing reading')
END
WHERE reading IS NULL
   OR TRIM(reading) = ''
   OR TRIM(reading) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';
   
 -- 
   UPDATE quality_checks2
SET reading = CASE
WHEN TRIM(reading) NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$' THEN NULL
ELSE reading
END;

-- proper format for the reading column 
ALTER TABLE quality_checks2
MODIFY COLUMN reading DECIMAL(10,2);

-- the result column needs to be in proper format as well words like f and fail means the same things, so we convert them to one name 

UPDATE quality_checks2
set result = CASE 
WHEN TRIM(result) IN ('Pass','Pass ','P', 'Passed') THEN 'Pass'
WHEN TRIM(result) IN ('F','Fail')THEN 'Fail'
else result
end;

-- then we flag the missing result as missing result in data_issues and further set those missing result to null

UPDATE quality_checks2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'missing result'
WHEN data_issues NOT LIKE '%missing result%' THEN CONCAT(data_issues, '; missing result')
ELSE data_issues
END
WHERE result IS NULL OR TRIM(result) = '';

update quality_checks2
set result = null 
where result = ''
;

-- the remark columns needs proper format and removing placeholders like na or n/a
UPDATE quality_checks2
SET remarks = CASE
    WHEN TRIM(remarks) IN ('', '-', 'n/a', 'na', 'null') THEN NULL
    ELSE remarks
END;

-- the we standerdized it 
UPDATE quality_checks2
SET remarks = CONCAT(UPPER(LEFT(TRIM(remarks), 1)), LOWER(SUBSTRING(TRIM(remarks), 2)))
WHERE remarks IS NOT NULL;


-- i observed that some result says fail but the remarks says OK, so i flag those as well 
UPDATE quality_checks2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'fail result marked ok'
WHEN data_issues NOT LIKE '%fail result marked ok%' THEN CONCAT(data_issues, '; fail result marked ok')
ELSE data_issues
END
WHERE result = 'Fail' AND remarks = 'Ok';

