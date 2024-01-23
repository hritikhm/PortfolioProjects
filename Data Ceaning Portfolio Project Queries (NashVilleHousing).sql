/*

Cleaning Data in SQL Queries
Data-Nashville Housing 
*/

SELECT * 
FROM PortfolioProject..NashvilleHousing
--------------------------------------------------------------------------------------------------------------------------

--Standardize Date Format
--Removing the time at the end of it 
--CONVERT function is same as CAST

SELECT SaleDate, CONVERT(date,SaleDate)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing		
ALTER COLUMN SaleDate date							--MODIFY does not work in SQLServer

SELECT SaleDate
FROM PortfolioProject..NashvilleHousing

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
-- Same ParcelID have same PropertyAddress ; we need to do self join to fill the null values
-- ISNULL is used to populate the null values with the value after the comma, we can also populate the null values with a string 'No Address'
SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b
	ON a.ParcelID=b.ParcelID AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET a.PropertyAddress=ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b
	ON a.ParcelID=b.ParcelID AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT																						--CHARINDEX gives us the INDEX of comma
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address					--(-1 is used to remove the comma from output)
,SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City		
FROM PortfolioProject..NashvilleHousing	

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress=SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) 

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitCity=SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

--ALTER TABLE PortfolioProject..NashvilleHousing
--DROP COLUMN PropertyAddress

--now we have to dissect city and state from the OwnerAddress, for this we will use PARSENAME
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT												--PARSENAME take periods not commas so we have to replace commas with periods
PARSENAME(REPLACE(OwnerAddress,',','.') ,1)			--PARSENAME does it's job backwards
,PARSENAME(REPLACE(OwnerAddress,',','.') ,2)
,PARSENAME(REPLACE(OwnerAddress,',','.') ,3)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress= PARSENAME(REPLACE(OwnerAddress,',','.') ,3)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitCity= PARSENAME(REPLACE(OwnerAddress,',','.') ,2)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitState nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitState= PARSENAME(REPLACE(OwnerAddress,',','.') ,1)


--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVAcant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
,CASE
	WHEN SoldAsVacant='N' THEN 'No'
	WHEN SoldAsVacant='Y' THEN 'Yes'
	ELSE SoldAsVacant
END
FROM PortfolioProject..NashvilleHousing


UPDATE PortfolioProject..NashvilleHousing 
SET SoldAsVacant=
CASE
	WHEN SoldAsVacant='N' THEN 'No'
	WHEN SoldAsVacant='Y' THEN 'Yes'
	ELSE SoldAsVacant
END




-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- we will use a CTE and windows functions like rank/ order rank/ row number for this

WITH RowNumCTE AS(
SELECT *, 
ROW_NUMBER() OVER (PARTITION BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference
				  ORDER BY UniqueID) AS row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT *														--DELETE
FROM RowNumCTE
WHERE row_num>1


--there are different UniqueID for these duplicates

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
