--This project contains the queries necessary for cleaning a Nashville housing data set that was imported from Excel

--First, select the entire dataset to begin identifying any issues

Select *
From PortfolioProject..NashvilleHousing

--Convert date from datetime format to date format
--Start by adding an additional column to the table: UpdatedSaleDate

ALTER TABLE NashvilleHousing
Add UpdatedSaleDate Date;

--Update the table 

Update NashvilleHousing
SET UpdatedSaleDate = CONVERT(Date,SaleDate)

--Select the new converted sale date

Select UpdatedSaleDate
From PortfolioProject..NashvilleHousing

--Clean data where Property Address data is null. ParcelID is correlated with Property Address, so a self join can be used to fill in null 
--Property Address results. However, it must be specified that the UniqueID cannot be the same 

Select *
From PortfolioProject..NashvilleHousing
Order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<> b.[UniqueID ]
Where a.PropertyAddress is null

--This update can be run to replace the null values. Running the above query will then return data where Property Address is null, 
--which should return no results

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<> b.[UniqueID ]
Where a.PropertyAddress is null

--The PropertyAddress column can be further separated into Address, City, and State for more effective analysis of the data

Select PropertyAddress
From PortfolioProject..NashvilleHousing

--This query can be used to remove the ',' from the Address column

Select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
From PortfolioProject..NashvilleHousing

--Two new columns can be added, one for the address and one for the city. Once these columns are added, they can be updated respecitvely

Alter table NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

Alter table NashvilleHousing
Add PropertyCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

--OwnerAddress must also be updated in a similar fashion

Select OwnerAddress
From PortfolioProject..NashvilleHousing

--However, this can be separated using PARSENAME rather than SUBSTRING

Select PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
	   PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
	   PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProject..NashvilleHousing

--Next, individual columns can be added for the Address, City, and State. Then, each column can be updated accordingly

Alter table NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

Alter table NashvilleHousing
Add OwnerCity Nvarchar(255);

UPDATE NashvilleHousing
Set OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

Alter table NashvilleHousing
Add OwnerState Nvarchar(255);

UPDATE NashvilleHousing
Set OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

--The Sold as Vacant column contains some cells with Y or N instead of Yes or No. These entries must be changed to match the others

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group by SoldAsVacant
Order by 2

--A case statement can be used to replace the entires with Y or N with Yes or No respecively

Select SoldAsVacant,
	Case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end
From PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
set SoldAsVacant = Case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end

--Duplicate entries must also be removed from the table using a CTE and windows functions

With RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	partition by ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		order by
		UniqueID
		) row_num
From PortfolioProject..NashvilleHousing
)

Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

--Finally, the columns that are no longer being used can be dropped from the table

Alter table PortfolioProject..NashvilleHousing
Drop column OwnerAddress, PropertyAddress, SaleDate

Select * 
From PortfolioProject..NashvilleHousing