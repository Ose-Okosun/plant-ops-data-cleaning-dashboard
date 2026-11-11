-- cleaning of downtime_log
-- made a duplicate copy of the original work to downtime_log2

SET SQL_SAFE_UPDATES = 0;

DROP TABLE IF EXISTS downtime_log2;

CREATE TABLE downtime_log2 AS
SELECT distinct *
FROM downtime_log;

-- then we standerdize the letters in all the columns of this tables
UPDATE downtime_log2
SET Reason = CONCAT(UPPER(LEFT(TRIM(reason), 1)), LOWER(SUBSTRING(TRIM(reason), 2))),
    Action_taken  = CONCAT(UPPER(LEFT(TRIM(Action_taken), 1)),  LOWER(SUBSTRING(TRIM(Action_taken), 2))),
    reported_by_role = CONCAT(UPPER(LEFT(TRIM( reported_by_role), 1)),  LOWER(SUBSTRING(TRIM( reported_by_role), 2)));

-- setting date on downtime_date to the right format 
UPDATE downtime_log2
SET downtime_date = CASE
    WHEN downtime_date = '00/00/0000'
        THEN NULL
    WHEN downtime_date LIKE '__/__/____'
        THEN DATE_FORMAT(STR_TO_DATE(downtime_date, '%d/%m/%Y'), '%Y-%m-%d')
    WHEN downtime_date LIKE '__-__-____'
        THEN DATE_FORMAT(STR_TO_DATE(downtime_date, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN downtime_date LIKE '__ ___ ____'
        THEN DATE_FORMAT(STR_TO_DATE(downtime_date, '%d %b %Y'), '%Y-%m-%d')
    WHEN downtime_date LIKE '%, ____'
        THEN DATE_FORMAT(STR_TO_DATE(downtime_date, '%M %d, %Y'), '%Y-%m-%d')
    WHEN downtime_date LIKE '__.__.__'
        THEN DATE_FORMAT(STR_TO_DATE(downtime_date, '%d.%m.%y'), '%Y-%m-%d')
    ELSE downtime_date
END;

-- setting invalid dates to null because they will affect the data
UPDATE downtime_log2
SET downtime_date = NULL
WHERE downtime_date NOT LIKE '____-__-__';


-- flag missing machine_id as missing id for result purpose 
UPDATE downtime_log2
SET machine_id = 'missing id'
WHERE machine_id = '' OR machine_id IS NULL;

-- i created a new column data_issue to write and flag  all the errors in it 
-- made it varchar(255) because a row can have more than one issue and the labels add up
ALTER TABLE downtime_log2
ADD COLUMN data_issues VARCHAR(255);

UPDATE downtime_log2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'missing machine id'
        ELSE CONCAT(data_issues, '; missing machine id')
    END
WHERE machine_id = 'missing id' OR machine_id IS NULL;

-- some machine_id had a dash in the middle (M-007) and some were in small letters (m012), so i removed the dash and made them all capital 
UPDATE downtime_log2
SET machine_id = UPPER(REPLACE(TRIM(machine_id), '-', ''))
WHERE machine_id <> 'missing id';

-- then i flagged the machine_id that are not in the machines table (like M999)
UPDATE downtime_log2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'machine_id not in machines'
        ELSE CONCAT(data_issues, '; machine_id not in machines')
    END
WHERE machine_id <> 'missing id'
  AND NOT EXISTS (
    SELECT 1
    FROM machines
    WHERE machines.machine_id = downtime_log2.machine_id
);

-- i updated the action_taken column so that the null values are uniform 
UPDATE downtime_log2
SET action_taken = CASE
    WHEN LOWER(TRIM(action_taken)) IN ('', '-', 'n/a', 'na', 'null') THEN NULL
    ELSE action_taken
END;

-- some of the date values were null so i updates the data_issue column to reflect that 
UPDATE downtime_log2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'missing date'
        ELSE CONCAT(data_issues, '; missing date')
    END
WHERE downtime_date IS NULL;

-- then we change the downtime_date column from text to date
ALTER TABLE downtime_log2
MODIFY downtime_date DATE;


   
-- for estimated_loss_ngn  i noticed that some of the figures are negatives, some are just 0.0, some are empty, some are null
-- i flagged them on the data_issue column  to reflct the different issues they are face, then after i changed all the figures to Null on the estimated_loss_ngn column, so as to have a uniform look 
  -- firstly we standerdize the column before we are able to alter it , i chnaged the column from text to numbers 
   
UPDATE downtime_log2
SET estimated_loss_ngn = NULL
WHERE UPPER(TRIM(estimated_loss_ngn)) IN (
    'NA',
    'N/A',
    '-',
    '',
    'NULL'
);

-- then we alter the table and change to numeric format
ALTER TABLE downtime_log2
MODIFY estimated_loss_ngn DECIMAL(12,2);

-- and now we flag the abnormal figures
-- each issue is flagged on its own so one label does not overwrite another

UPDATE downtime_log2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'negative loss'
        ELSE CONCAT(data_issues, '; negative loss')
    END
WHERE estimated_loss_ngn < 0;

UPDATE downtime_log2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'zero loss'
        ELSE CONCAT(data_issues, '; zero loss')
    END
WHERE estimated_loss_ngn = 0;

UPDATE downtime_log2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'missing value'
        ELSE CONCAT(data_issues, '; missing value')
    END
WHERE estimated_loss_ngn IS NULL;

-- after flagging, the negatives and zeros are set to null so the column looks uniform
UPDATE downtime_log2
SET estimated_loss_ngn = NULL
WHERE estimated_loss_ngn <= 0;
   
--  
   
   
   -- I checked the duration column and it needs to be standerdized 
   -- and then some of the time are in negatives which i have to flag  so as to be aware of the issue 
   
   -- standerdised duration 
   UPDATE downtime_log2
SET duration = CASE
    WHEN LOWER(TRIM(duration)) REGEXP '^-?[0-9]+[[:space:]]*h[[:space:]]*[0-9]+[[:space:]]*m$'
    THEN
        CASE
            WHEN LEFT(TRIM(duration), 1) = '-'
            THEN -1
            ELSE 1
        END
        *
        (
            CAST(
                REPLACE(
                    TRIM(SUBSTRING_INDEX(LOWER(TRIM(duration)), 'h', 1)),
                    '-', ''
                ) AS SIGNED
            ) * 60
            +
            CAST(
                TRIM(
                    SUBSTRING_INDEX(
                        SUBSTRING_INDEX(LOWER(TRIM(duration)), 'h', -1),
                        'm', 1
                    )
                ) AS SIGNED
            )
        )
    ELSE
        CAST(
            REGEXP_REPLACE(
                LOWER(TRIM(duration)),
                '[[:space:]]*(min|mins|minute|minutes)$',
                ''
            ) AS SIGNED
        )
END
WHERE duration IS NOT NULL;

--  then we change the column from text to time INT so we can accomate the values of time measured in minutes 

ALTER TABLE downtime_log2
MODIFY duration INT;


-- then we flag the negative duration 

   UPDATE downtime_log2
SET data_issues = CASE
    WHEN data_issues IS NULL OR TRIM(data_issues) = ''
        THEN 'negative time'
    WHEN data_issues NOT LIKE '%negative time%'
        THEN CONCAT(data_issues, '; negative time')
    ELSE data_issues
END
WHERE duration < 0;

-- i checked the smallest and biggest duration to see the ones that dont make sense
SELECT MIN(duration) AS smallest, MAX(duration) AS biggest
FROM downtime_log2;

-- then i flagged the zero and the abnormal duration (more than 720 mins which is 12 hours)
UPDATE downtime_log2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'zero or abnormal time'
        ELSE CONCAT(data_issues, '; zero or abnormal time')
    END
WHERE duration = 0 OR duration > 720;



--   looking at the reason column, some of the reasons are the same things but written in differnt ways so i made them uniform so they can represent a single data instead of multiple 
UPDATE downtime_log2
SET reason = CASE
    WHEN LOWER(TRIM(reason)) IN ('power outage', 'nepa', 'power cut', 'grid failure')
        THEN 'Power outage'
    WHEN LOWER(TRIM(reason)) IN ('mechanical failure', 'mechanical fault', 'mech failure')
        THEN 'Mechanical failure'
    WHEN LOWER(TRIM(reason)) IN ('changeover', 'change-over', 'change over')
        THEN 'Changeover'
    WHEN LOWER(TRIM(reason)) IN ('material shortage', 'shortage - preform', 'no materials')
        THEN 'Material shortage'
    WHEN LOWER(TRIM(reason)) IN ('scheduled maint', 'scheduled maintenance', 'sched. maintenance', 'pm')
        THEN 'Scheduled maintenance'
	WHEN LOWER(TRIM(reason)) IN ('jam') 
        THEN 'Mechanical failure'
    ELSE reason
END;

