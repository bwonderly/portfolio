-- ------------------------------------------------------------------------------------------------------------------------
# The purpose of this project is to clean/prepare a dataset of housing information taken from
# https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx
# This data cleaning is adapted from the procedure outlined by AlexTheAnalys and found in the video:
# https://youtu.be/8rO7ztF4NtU?si=dadUjEMGVRrT73kp

-- For the new project ensure that the desired database doesn't exist
DROP DATABASE IF EXISTS nashvilleHousing;

-- Create the desired database
CREATE DATABASE nashvillehousing;

-- Select the newly created database
USE nashvilleHousing;

-- Loading the data from CSV file
DROP TABLE IF EXISTS nashvilleHousing;


-- Create an empty table
CREATE TABLE nashvilleHousing (
    UniqueID INT,
    ParcelID VARCHAR(20),
    LandUse VARCHAR(50),
    PropertyAddress VARCHAR(255),
    SaleDate DATE,
    SalePrice DECIMAL(15, 2),
    LegalReference VARCHAR(50),
    SoldAsVacant VARCHAR(3),
    OwnerName VARCHAR(100),
    OwnerAddress VARCHAR(255),
    Acreage DECIMAL(5, 2),
    TaxDistrict VARCHAR(100),
    LandValue DECIMAL(15, 2),
    BuildingValue DECIMAL(15, 2),
    TotalValue DECIMAL(15, 2),
    YearBuilt YEAR,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);

-- Load the data from the CSV file
-- csv file created by the following steps:
-- 1) save as tab delimited file in Excel
-- 2) use the following command to  tr '\t' '\|' <nashvilleHousingData.txt> nashvilleHousing_converted.txt
--    to make the delimiter '|' because there are commas in the addresses
-- 3) load into SQLite, export as a csv
-- 4) now we are prepared to import here
LOAD DATA LOCAL INFILE '/Users/williamwonderly/Documents/SQL/nashvilleHousingData/nashvilleHousing_converted.csv'
INTO TABLE nashvilleHousing
FIELDS TERMINATED BY '|'
IGNORE 1 LINES
(
UniqueID,
ParcelID,
LandUse,
PropertyAddress,
SaleDate,
SalePrice,
LegalReference,
SoldAsVacant,
OwnerName,
OwnerAddress,
Acreage,
TaxDistrict,
LandValue,
BuildingValue,
TotalValue,
YearBuilt,
Bedrooms,
FullBath,
HalfBath
);

-- Check the head of the data to see if everything worked
SELECT 
    *
FROM
    nashvilleHousing;

-- ------------------------------------------------------------------------------------------------------------------------
-- fill the empty strings with null values
UPDATE nashvilleHousing
SET 
	PropertyAddress = NULLIF(PropertyAddress,''),
    OwnerName = NULLIF(OwnerName, ''),
    OwnerAddress = NULLIF(OwnerAddress, ''),
    TaxDistrict = NULLIF(TaxDistrict, '');

-- ------------------------------------------------------------------------------------------------------------------------
-- Clean the SoldAsVacant to make it an ENUM datatype
-- change the Normalize the entries in SoldAsVacant to be only 'Yes' or 'No'
UPDATE nashvilleHousing 
SET 
    SoldAsVacant = CASE
        WHEN SoldAsVacant IN ('Y' , 'Yes') THEN 'Yes'
        WHEN SoldAsVacant IN ('N' , 'No') THEN 'No'
    END;

-- check if the normalization worked
SELECT DISTINCT
    SoldAsVacant, COUNT(SoldAsVacant)
FROM
    nashvilleHousing
GROUP BY
	SoldAsVacant;

-- Change the Datatype to ENUM('Yes','No') so that we can work with this data more easily
ALTER TABLE nashvilleHousing
MODIFY COLUMN SoldAsVacant ENUM('Yes', 'No');

-- ------------------------------------------------------------------------------------------------------------------------
-- Standardize the date format 

UPDATE NashvilleHousing 
SET 
    SaleDate = CONVERT( SaleDate , DATE);

-- Verify the update worked
SELECT 
    SaleDate
FROM
    nashvilleHousing;

-- ------------------------------------------------------------------------------------------------------------------------
-- populate property address data
SELECT 
    *
FROM
    nashvilleHousing
-- WHERE PropertyAddress IS NULL;
ORDER BY ParcelID;

-- Find the entries where PropertyAddress is null but we know the address from duplicate entries with the same propertyID
SELECT 
    a.ParcelID,
    a.PropertyAddress,
    b.ParcelID,
    b.PropertyAddress,
    COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM
    nashvilleHousing a
        JOIN
    nashvilleHousing b ON a.ParcelID = b.ParcelID
        AND a.UniqueID != b.UniqueID
WHERE
    a.PropertyAddress IS NULL;

-- Update these null values of property Address
UPDATE nashvilleHousing a
        JOIN
    nashvilleHousing b ON a.ParcelID = b.ParcelID
        AND a.UniqueID != b.UniqueID 
SET 
    a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE
    a.PropertyAddress IS NULL
        AND b.PropertyAddress IS NOT NULL;

-- ------------------------------------------------------------------------------------------------------------------------
-- breaking property address up into separate columns (address, city)

SELECT PropertyAddress
FROM nashvilleHousing;

-- Show that we can split the address into the street/house number and the city
SELECT
SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1) AS Address,
SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',')+1, LENGTH(PropertyAddress)) AS City
FROM nashvilleHousing;

-- Add a new column for the street/house number
ALTER TABLE nashvilleHousing
ADD PropertySplitAddress VARCHAR(255);

-- Update the new column with the street/house number
UPDATE  nashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1);

-- Add a new column for the city
ALTER TABLE nashvilleHousing
ADD PropertySplitCity VARCHAR(255);

-- Update the new column for the city in which the property is found
UPDATE  nashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',')+1, LENGTH(PropertyAddress));

-- Validate our results
SELECT 
    *
FROM
    nashvilleHousing;
    
-- ------------------------------------------------------------------------------------------------------------------------
-- breaking owner address up into separate columns (address, city, state)

-- Functino to split the string up using a specific delimiter
CREATE FUNCTION SPLIT_STR(
  x VARCHAR(255),
  delim VARCHAR(12),
  pos INT
)
RETURNS VARCHAR(255) DETERMINISTIC
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '');

-- Verify the function works to split the owner address
SELECT
	SPLIT_STR(OwnerAddress, ',', 1) as  address,
    SPLIT_STR(OwnerAddress, ',', 2) as  city,
    SPLIT_STR(OwnerAddress, ',', 3) as  state
FROM
	nashvilleHousing;
    
-- Add a new column for the owners street/house number
ALTER TABLE nashvilleHousing
ADD OwnerSplitAddress VARCHAR(255);

-- Update the new column with the owner street/house number
UPDATE nashvilleHousing
SET OwnerSplitAddress = SPLIT_STR(OwnerAddress, ',', 1);

-- Add a new column for the city
ALTER TABLE nashvilleHousing
ADD OwnerSplitCity VARCHAR(255);

-- Update the new column for the city in which the property is found
UPDATE  nashvilleHousing
SET OwnerSplitCity = SPLIT_STR(OwnerAddress, ',', 2);

-- Add a new column for the State
ALTER TABLE nashvilleHousing
ADD OwnerSplitState VARCHAR(255);

-- Update the new column for the State in which the owner is found
UPDATE  nashvilleHousing
SET OwnerSplitState = SPLIT_STR(OwnerAddress, ',', 3);

-- Verify success
Select * FROM nashvilleHousing;

-- ------------------------------------------------------------------------------------------------------------------------
-- Removing duplicate entries

-- First, find duplicate data entries by creating partitions where 
-- ParcelID,  PropertyAddress, SalePrice, SaleDate, LegalReference are identical.
-- then apply ROW_NUMBER() to see which partitions have more than one row, and filter for 
-- rows > 1
SELECT *
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                ParcelID, 
                PropertyAddress, 
                SalePrice, 
                SaleDate, 
                LegalReference
            ORDER BY 
                UniqueID
        ) AS row_num
    FROM nashvilleHousing
) AS subquery
WHERE row_num > 1;

-- same as above, but with CTE
WITH rowNumCTE AS(
SELECT
	*,
	ROW_NUMBER() OVER(
		PARTITION BY
			ParcelID, 
			PropertyAddress, 
			SalePrice, 
			SaleDate, 
			LegalReference
            ORDER BY
				UniqueID) row_num
FROM
	nashvilleHousing)
SELECT
	*
FROM
	rowNumCTE
WHERE
	row_num > 1
ORDER BY
	PropertyAddress;
    
-- Delete the duplicate values

WITH rowNumCTE AS(
	SELECT 
		UniqueID
	FROM(
		SELECT
			UniqueID,
			ROW_NUMBER() OVER(
				PARTITION BY
				ParcelID, 
				PropertyAddress, 
				SalePrice, 
				SaleDate, 
				LegalReference
            ORDER BY
				UniqueID
		) AS row_num
	FROM
		nashvilleHousing) AS subquery
	WHERE row_num > 1)
DELETE FROM nashvilleHousing
WHERE UniqueID IN (SELECT UniqueID FROM rowNumCTE);
                
-- ------------------------------------------------------------------------------------------------------------------------
-- drop unused columns

ALTER TABLE nashvilleHousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress;

select * from nashvilleHousing;