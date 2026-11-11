-- cleaning of the table MACHINE 
-- First we make a duplicate and create a column named data_isues to flag the issues with the data

SET SQL_SAFE_UPDATES = 0;
 
DROP TABLE IF EXISTS production_runs2;
 
CREATE TABLE production_runs2 AS
SELECT distinct *
FROM production_runs;

ALTER TABLE production_runs2
ADD COLUMN data_issues VARCHAR(255);

-- the product, line and sshift column needs to be uniform in spelling, so as to produce a clear result 

update production_runs2
set product = case 
when trim(product) in ('Orange Juice 1L', 'Orange Juice 1 L', ' Orange Juice 1L ', 'Orange Jucie 1L', ' Orange Juice 1 L ', ' Orange Jucie 1L ', 'oj 1l', ' OJ 1L ') then 'Orange Juice 1L'
when trim(product) in ('Zobo 35cl', 'ZOBO DRINK 35CL', ' Zobo Drink 35cl ', 'Zobo Drink 350ml', ' Zobo 35cl ') then 'Zobo Drink 35cl'
when trim(product) in (' Ginger Shot 10cl ', 'Ginger Shot 10cl') then 'Ginger Shot 10cl'
when trim(product) in (' Malt Drink 33cl ', 'Malt Drink 33cl' )then 'Malt Drink 33cl'
 when trim(product) in ('sparkle water 50cl', 'sparkle wtr 50cl', 'sparkle water 500ml') then 'Sparkle Water 50cl'
when trim(product) in ('sparkle water 75cl') then 'Sparkle Water 75cl'
when trim(product) in ('tigernut drink 50cl', 'tiger nut drink 50cl', 'tigernut drink 500ml') then 'Tigernut Drink 50cl'
when trim(product) in (' Pineapple Juice 1L ', 'Pineapple Juice 1L') then 'Pineapple Juice 1L'
else product
end;

update production_runs2
set line = case 
when trim(line) in ('Line1', 'L1', 'Line 1') then 'Line 1'
when trim(line) in ('Line2', 'L2', 'Line 2') then 'Line 2'
when trim(line) in ('L3', 'Line3', 'Line 3') then 'Line 3'
when trim(line) in ('Line4', 'L4', 'Line 4') then 'Line 4'
else line
end;


update production_runs2
set shift = case 
when trim(shift) in ('night', 'Shift C', 'Nite') then 'Night' 
when trim(shift) in ('morning', 'Mrn', 'Shift A', 'AM') then 'Morning'
when trim(shift) in ('Shift B', 'Aftn', 'Afternoon', 'PM') then 'Afternoon'
else shift 
end;

-- the run_date column has to be in proper format and flag missig date, then we change the abnormal records to null and lastly convert the column to date 

UPDATE production_runs2
SET run_date = CASE
	WHEN run_date = '00/00/0000' THEN NULL
    WHEN run_date LIKE '__/__/____' THEN DATE_FORMAT(STR_TO_DATE(run_date, '%d/%m/%Y'), '%Y-%m-%d')
    WHEN run_date LIKE '__-__-____' THEN DATE_FORMAT(STR_TO_DATE(run_date, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN run_date LIKE '__ ___ ____' THEN DATE_FORMAT(STR_TO_DATE(run_date, '%d %b %Y'), '%Y-%m-%d')
    WHEN run_date LIKE '%, ____' THEN DATE_FORMAT(STR_TO_DATE(run_date, '%M %d, %Y'), '%Y-%m-%d')
    WHEN run_date LIKE '__.__.__' THEN DATE_FORMAT(STR_TO_DATE(run_date, '%d.%m.%y'), '%Y-%m-%d')
    ELSE run_date
END;

UPDATE production_runs2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'missing run date'
WHEN data_issues NOT LIKE '%missing run date%' THEN CONCAT(data_issues, '; missing run date')
ELSE data_issues
END
WHERE run_date IS NULL
   OR TRIM(run_date) = ''
   OR UPPER(TRIM(run_date)) IN ('TBC', 'N/A');
   
   
   UPDATE production_runs2
SET run_date = NULL
WHERE run_date IS NULL
   OR TRIM(run_date) = ''
   OR UPPER(TRIM(run_date)) IN ('TBC', 'N/A');
   
   ALTER TABLE production_runs2
MODIFY run_date DATE;


-- the supervisor columns needs standerdization and the spelling needs to be corected so as not to have multiple data 

UPDATE production_runs2
SET supervisor = CONCAT(UPPER(LEFT(TRIM(supervisor), 1)), LOWER(SUBSTRING(TRIM(supervisor), 2)));

update production_runs2
set supervisor = case 
when trim(supervisor) in ('Chinedu  okafor','Chinedu okafor', 'Okafor chinedu', 'Chinedu' ) then 'Chinedu  okafor'
when trim(supervisor) in ('Funke', 'Funke adeyemi', 'Adeyemi funke', 'Funke  adeyemi') then 'Funke adeyemi'
when trim(supervisor) in ('Emeka eze', 'Emeka', 'Emeka  eze', 'Eze emeka') then 'Emeka eze'
when trim(supervisor) in ('Ngozi  obi', 'Ngozi obi', 'Ngozi', 'Obi ngozi')then 'Ngozi obi'
 when trim(supervisor) in ('Blessing', 'Blessing  udoh', 'Blessing udoh', 'Udoh blessing') then 'Blessing udoh'
when trim(supervisor) in ('Ibrahim musa', 'Musa ibrahim', 'Ibrahim', 'Ibrahim  musa') then 'Ibrahim musa'
when trim(supervisor) in ('Aisha bello', 'Aisha  bello', 'Aisha', 'Bello aisha') then 'Aisha bello'
when trim(supervisor) in ('Tunde bakare', 'Bakare tunde', 'Tunde', 'Tunde  bakare') then 'Tunde bakare'
else supervisor
end;

-- moving on to planned_qty, it needs to be int nor varcahr 50 because its a number column 

ALTER TABLE production_runs2
MODIFY COLUMN planned_qty INT;

-- moving to actual_qty, there are some negatibe figures that needs to be flagged and changeds to null and it need to be in proper format as well for better calculations 

UPDATE production_runs2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'Negative actual quantity'
WHEN data_issues NOT LIKE '%Negative actual quantity%' THEN CONCAT(data_issues, '; Negative actual quantity')
ELSE data_issues
END
WHERE TRIM(actual_qty) REGEXP '^-[0-9]+([.][0-9]+)?$';

--  flag the missing ones 
UPDATE production_runs2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'missing actual qty'
WHEN data_issues NOT LIKE '%missing actual qty%' THEN CONCAT(data_issues, '; missing actual qty')
ELSE data_issues
END
WHERE actual_qty IS NULL
   OR REGEXP_REPLACE(actual_qty, '[[:space:]]', '') = '';

-- changing negatives to null 

UPDATE production_runs2
SET actual_qty = NULL
WHERE TRIM(actual_qty) REGEXP '^-[0-9]+([.][0-9]+)?$';

-- then we give it a proper format 

UPDATE production_runs2
SET actual_qty = CASE
WHEN actual_qty IS NULL OR REGEXP_REPLACE(actual_qty, '[[:space:]]', '') = '' THEN NULL
ELSE REGEXP_REPLACE(TRIM(actual_qty), '[a-zA-Z[:space:],]', '')
END;

ALTER TABLE production_runs2
MODIFY COLUMN actual_qty INT;


-- moving to rejected_qty
-- needs proper standard 

UPDATE production_runs2
SET rejected_qty = CASE
WHEN rejected_qty IS NULL OR REGEXP_REPLACE(rejected_qty, '[[:space:]]', '') = '' THEN NULL
ELSE REGEXP_REPLACE(TRIM(rejected_qty), '[a-zA-Z[:space:],]', '')
END;


ALTER TABLE production_runs2
MODIFY COLUMN rejected_qty INT;

-- moving to start_time, it needs to be in proper format 

UPDATE production_runs2
SET start_time = CASE
WHEN TRIM(start_time) REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$'
    THEN TIME_FORMAT(STR_TO_DATE(TRIM(start_time), '%H:%i:%s'), '%H:%i:%s')
WHEN TRIM(start_time) REGEXP '^[0-9]{2}:[0-9]{2}$'
    THEN TIME_FORMAT(STR_TO_DATE(TRIM(start_time), '%H:%i'), '%H:%i:%s')
WHEN UPPER(TRIM(start_time)) REGEXP '^[0-9]{1,2}:[0-9]{2} (AM|PM)$'
    THEN TIME_FORMAT(STR_TO_DATE(UPPER(TRIM(start_time)), '%h:%i %p'), '%H:%i:%s')
ELSE start_time
END
WHERE start_time IS NOT NULL;


ALTER TABLE production_runs2
MODIFY COLUMN start_time TIME;

-- moving to end_time, i flag the missing time, give it a proper format 

UPDATE production_runs2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'Missing end time'
WHEN data_issues NOT LIKE '%Missing end time%' THEN CONCAT(data_issues, '; Missing end time')
ELSE data_issues
END
WHERE end_time IS NULL OR TRIM(end_time) = '';

-- set empty values to null 

UPDATE production_runs2
SET end_time = NULL
WHERE end_time IS NOT NULL
AND TRIM(end_time) = '';

-- standerdize column 

UPDATE production_runs2
SET end_time = CASE
WHEN TRIM(end_time) REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$'
    THEN TIME_FORMAT(STR_TO_DATE(TRIM(end_time), '%H:%i:%s'), '%H:%i:%s')
WHEN TRIM(end_time) REGEXP '^[0-9]{2}:[0-9]{2}$'
    THEN TIME_FORMAT(STR_TO_DATE(TRIM(end_time), '%H:%i'), '%H:%i:%s')
WHEN UPPER(TRIM(end_time)) REGEXP '^[0-9]{1,2}:[0-9]{2} (AM|PM)$'
    THEN TIME_FORMAT(STR_TO_DATE(UPPER(TRIM(end_time)), '%h:%i %p'), '%H:%i:%s')
ELSE end_time
END
WHERE end_time IS NOT NULL;

ALTER TABLE production_runs2
MODIFY COLUMN end_time TIME;

-- on the status colums it needs to be in standard format no spacing and capital letter should be fixed 

UPDATE production_runs2
SET status = CONCAT(UPPER(LEFT(TRIM(status), 1)), LOWER(SUBSTRING(TRIM(status), 2)));


-- the unit_cost_ngn need to be in proper format as well 

UPDATE production_runs2
SET unit_cost_ngn = REGEXP_REPLACE(
    TRIM(unit_cost_ngn),
    '[^0-9.-]',
    ''
)
WHERE unit_cost_ngn IS NOT NULL;

ALTER TABLE production_runs2
MODIFY COLUMN unit_cost_ngn DECIMAL(12,2);


-- Moving throught this table ibserved that some actual_qty are higher that the planned qty so i will flag that, although its possible that it can happen but i think if its more than 2x the planned qty then its worth flagging
  
 UPDATE production_runs2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'actual qty more than 2x planned'
WHEN data_issues NOT LIKE '%actual qty more than 2x planned%' THEN CONCAT(data_issues, '; actual qty more than 2x planned')
ELSE data_issues
END
WHERE actual_qty > planned_qty * 2;
