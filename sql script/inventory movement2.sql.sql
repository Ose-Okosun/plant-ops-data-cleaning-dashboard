-- cleaning of inventory_movements
-- made a duplicate copy of the original work to inventory_movements2
 
SET SQL_SAFE_UPDATES = 0;
 
DROP TABLE IF EXISTS inventory_movements2;
 
CREATE TABLE inventory_movements2 AS
SELECT distinct *
FROM inventory_movements;

-- i created a new column data_issue to write and flag  all the errors in it 
-- made it varchar(255) because a row can have more than one issue and the labels add up
ALTER TABLE inventory_movements2
ADD COLUMN data_issues VARCHAR(255);

-- setting movement_date to the right format 
 
UPDATE inventory_movements2
SET movement_date = CASE
    WHEN movement_date = '00/00/0000'
        THEN NULL
    WHEN movement_date LIKE '__/__/____'
        THEN DATE_FORMAT(STR_TO_DATE(movement_date, '%d/%m/%Y'), '%Y-%m-%d')
    WHEN movement_date LIKE '__-__-____'
        THEN DATE_FORMAT(STR_TO_DATE(movement_date, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN movement_date LIKE '__ ___ ____'
        THEN DATE_FORMAT(STR_TO_DATE(movement_date, '%d %b %Y'), '%Y-%m-%d')
    WHEN movement_date LIKE '%, ____'
        THEN DATE_FORMAT(STR_TO_DATE(movement_date, '%M %d, %Y'), '%Y-%m-%d')
    WHEN movement_date LIKE '__.__.__'
        THEN DATE_FORMAT(STR_TO_DATE(movement_date, '%d.%m.%y'), '%Y-%m-%d')
    ELSE movement_date
END;

-- setting invalid dates to null because they will affect the data
UPDATE inventory_movements2
SET movement_date = NULL
WHERE movement_date NOT LIKE '____-__-__';

-- and then i label the missing dates in the data_issue column

UPDATE inventory_movements2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'missing date'
        ELSE CONCAT(data_issues, '; missing date')
    END
WHERE movement_date IS NULL;

-- then we change the movement_date column from text to date
ALTER TABLE inventory_movements2
MODIFY movement_date DATE;


-- the material column has some data that are represented twice or more, i make them one so they can give accurate data 
-- first i standerdize the data

UPDATE inventory_movements2
SET material = CONCAT(UPPER(LEFT(TRIM(material), 1)), LOWER(SUBSTRING(TRIM(material), 2)));

 -- then rename some materials properly so as to be groped in one name

update inventory_movements2
set material = CASE
		WHEN LOWER(TRIM(material)) IN ('Co2  (new)', 'Co2s','Co2' ) THEN 'CO2'
		WHEN LOWER(TRIM(material)) IN ('Bottle caps  (new)', 'Bottle capss') THEN 'Bottle caps'
		WHEN LOWER(TRIM(material)) IN ('Orange concentrate  (new)', 'Orange concentrates') THEN 'Orange concentrate'
		WHEN LOWER(TRIM(material)) IN ('Tigernutss', 'Tigernuts  (new)') THEN 'Tigernuts'
        WHEN LOWER(TRIM(material)) IN ('Cartons  (new)', 'Cartonss') THEN 'Cartons'
        WHEN LOWER(TRIM(material)) IN ('Pet preform  (new)', 'Pet preforms') THEN 'Pet preform'
        WHEN LOWER(TRIM(material)) IN ('Pineapple concentrate  (new)', 'Pineapple concentrates') THEN 'Pineapple concentrate'
        WHEN LOWER(TRIM(material)) IN ('Shrink films', 'Shrink film  (new)') THEN 'Shrink film'
        WHEN LOWER(TRIM(material)) IN ('Hibiscus leaves  (new)', 'Hibiscus leavess') THEN 'Hibiscus leaves'
		WHEN LOWER(TRIM(material)) IN ('Labelss', 'Labels  (new)') THEN 'Labels'
        WHEN LOWER(TRIM(material)) IN ('Sugars', 'Sugar  (new)')  THEN 'Sugar'
	ELSE material 
    end; 
    
    -- looking at the quantity column some are negative figures which is incorrect so i will flag that so it can be observed and i saw that some numbers contains letter so i cleaned that up first
    -- then changed the negative values to Null because they will affect my results when i try to calculate 
    --  i also modifuied the column from varchar(500) to INT 
    
    
    UPDATE inventory_movements2
SET quantity = REPLACE(TRIM(quantity), ',', '')
WHERE quantity LIKE '%,%';



    UPDATE inventory_movements2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'negative figure'
        ELSE CONCAT(data_issues, '; negative figure')
    END
WHERE quantity  < 0;

ALTER TABLE inventory_movements2
MODIFY COLUMN quantity INT;

-- i checked where the negative quantity are before changing them, to be sure they are errors
SELECT movement_type, COUNT(*) AS total
FROM inventory_movements2
WHERE quantity < 0
GROUP BY movement_type;

-- then the negative values are set to null after they were flagged
UPDATE inventory_movements2
SET quantity = NULL
WHERE quantity < 0;

-- I obersrved the unit column and it is not uniform, so i fix them buy standerdizing the removing spaces from the words 
--  some units were written twice in different ways so i corrected that by spelling it proper 

UPDATE inventory_movements2
SET unit = CASE 
WHEN unit IN ('Kgs','Kg') THEN 'Kilograms'
WHEN unit IN ('Liters', 'Litres', 'L', 'Ltrs') THEN 'Liters'
WHEN unit IN ('Roll', 'Rolls', 'Rls') THEN 'Rolls'
WHEN unit IN ('Pcs', 'Pieces', 'Units') THEN 'Pieces'
ELSE CONCAT(UPPER(LEFT(TRIM(unit), 1)), LOWER(SUBSTRING(TRIM(unit), 2)))
END;

-- some materials are in units that dont belong to them (like sugar in pieces) so i flagged them 
-- i only flagged them because the data cant tell if the unit or the material is the wrong one
UPDATE inventory_movements2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'unit does not match material'
        ELSE CONCAT(data_issues, '; unit does not match material')
    END
WHERE (material IN ('Pet preform', 'Bottle caps', 'Labels', 'Cartons') AND unit <> 'Pieces')
   OR (material IN ('Sugar', 'Hibiscus leaves', 'Tigernuts', 'CO2') AND unit <> 'Kilograms')
   OR (material IN ('Orange concentrate', 'Pineapple concentrate') AND unit <> 'Liters')
   OR (material = 'Shrink film' AND unit <> 'Rolls');

-- the Movement_type had imilar error like the previous column above so i i follwed the same pprocess or cleaning it 

UPDATE inventory_movements2
SET movement_type = CASE
WHEN movement_type IN ('Issue to production', 'Issu') THEN 'Issue to production'
WHEN movement_type IN ('Return', 'Retu') THEN 'Return'
WHEN movement_type IN ('Adju', 'Adjustment') THEN 'Adjustment'
WHEN movement_type IN ('Write-off', 'Writ') THEN 'Write-off'
WHEN movement_type IN ('Rece', 'Receipt') THEN 'Receipt'
ELSE CONCAT(UPPER(LEFT(TRIM(movement_type), 1)),
        LOWER(SUBSTRING(TRIM(movement_type), 2))
    )
END;



 -- i moved on to the supplier column and there was some blanks, null, n/A, so they all had to be named unknown and i removed the spaces as well 
 
 update inventory_movements2
SET supplier = CASE
    WHEN supplier IS NULL THEN 'Unknown'
    WHEN TRIM(supplier) IN ('', '-', 'N/A', 'NA', 'NULL') THEN 'Unknown'
    ELSE CONCAT(UPPER(LEFT(TRIM(supplier), 1)), LOWER(SUBSTRING(TRIM(supplier), 2))
    )
END;

-- from the unti_price_ngn column i made the figure uniform so as to produce good result 
-- and because it involves a monetary value, i also swich the column to decimal 

UPDATE inventory_movements2
SET unit_price_ngn = REGEXP_REPLACE(LOWER(TRIM(unit_price_ngn)), '[^0-9.-]', '')
WHERE unit_price_ngn IS NOT NULL;

ALTER TABLE inventory_movements2
MODIFY COLUMN unit_price_ngn DECIMAL(12,2);

-- some prices are zero which is not correct, so i flagged them first then changed them to null
-- this is done after the column is a number so the 0 can be compared properly
UPDATE inventory_movements2
SET data_issues = CASE
        WHEN data_issues IS NULL THEN 'zero price'
        ELSE CONCAT(data_issues, '; zero price')
    END
WHERE unit_price_ngn = 0;

UPDATE inventory_movements2
SET unit_price_ngn = NULL
WHERE unit_price_ngn = 0;

-- on the location column some had wrong spelling and that produced 2 data and some were blank, 
-- i would label the blank in data_issues and correct the spelling as well 


UPDATE inventory_movements2
SET data_issues = CASE
WHEN data_issues IS NULL OR TRIM(data_issues) = '' THEN 'missing location'
WHEN data_issues NOT LIKE '%missing location%' THEN CONCAT(TRIM(data_issues), '; missing location')
ELSE data_issues
END
WHERE TRIM(location) = '';




UPDATE inventory_movements2
SET location = CASE
WHEN TRIM(location) = '' THEN 'Unknown'
WHEN TRIM(location) = 'Wh-2' THEN 'Warehouse 2'
ELSE CONCAT(UPPER(LEFT(TRIM(location), 1)), LOWER(SUBSTRING(TRIM(location), 2)))
END;

-- final checks
SELECT material, unit, COUNT(*) AS total FROM inventory_movements2 GROUP BY material, unit ORDER BY material, total DESC;
SELECT data_issues, COUNT(*) AS total FROM inventory_movements2 GROUP BY data_issues ORDER BY total DESC;
DESCRIBE inventory_movements2;