SELECT * FROM nashville_housing;

-- STANDARDIZE DATE FORMAT

ALTER TABLE nashville_housing
DROP COLUMN IF EXISTS standardized_saledate,
ADD COLUMN standardized_saledate DATE;

UPDATE nashville_housing
SET standardized_saledate = TO_DATE(saledate, 'Month DD, YYYY');

-- POPULATE PROPERTY ADDRESS DATA

UPDATE nashville_housing
SET propertyaddress = COALESCE(a.propertyaddress, b.propertyaddress)
FROM nashville_housing a
JOIN nashville_housing b
	ON a.parcelid = b.parcelid
	AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NULL;

SELECT propertyaddress  
FROM nashville_housing
WHERE propertyaddress IS NULL;

-- BREAK ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

-- Property Address

ALTER TABLE nashville_housing
DROP COLUMN IF EXISTS address,
DROP COLUMN IF EXISTS city,
ADD COLUMN address VARCHAR(255),
ADD COLUMN city VARCHAR(255);

UPDATE nashville_housing
SET 
	address = SPLIT_PART(propertyaddress, ',', 1),
	city = SPLIT_PART(propertyaddress, ',', 2);

-- Owner Address

ALTER TABLE nashville_housing
DROP COLUMN IF EXISTS ownersplitaddress, 
DROP COLUMN IF EXISTS ownercity,
DROP COLUMN IF EXISTS ownerstate,
ADD COLUMN ownersplitaddress VARCHAR(255),
ADD COLUMN ownercity VARCHAR(255),
ADD COLUMN ownerstate VARCHAR(255);

UPDATE nashville_housing
SET 
	ownersplitaddress = SPLIT_PART(owneraddress, ',', 1),
	ownercity = SPLIT_PART(owneraddress, ',', 2),
	ownerstate = SPLIT_PART(owneraddress, ',', 3);
	
SELECT owneraddress, ownersplitaddress, ownercity, ownerstate
FROM nashville_housing;

-- CHANGE Y AND Y TO YES AND NO IN "SOLD AS VACANT" FIELD

UPDATE nashville_housing
SET soldasvacant = 
	CASE soldasvacant
		WHEN 'Y' THEN 'Yes'
		WHEN 'N' THEN 'No'
		ELSE soldasvacant
	END;

SELECT DISTINCT soldasvacant
FROM nashville_housing;

-- REMOVE DUPLICATES

WITH cte AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                parcelid,
                propertyaddress,
                saleprice,
                saledate,
                legalreference
            ORDER BY uniqueid
        ) AS row_num
    FROM nashville_housing
)
DELETE 
FROM nashville_housing
USING cte
WHERE
	nashville_housing.uniqueid = cte.uniqueid 
	AND row_num > 1;

-- DELETE UNUSED COLUMNS

-- ALTER TABLE nashville_housing
-- DROP COLUMN IF EXISTS owneraddress, taxdistrict, propertyaddress, saledate












