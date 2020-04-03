--------------------------------------------------------------------------------
-- A Work Project, presented as part of the requirements for the course
-- Managing Relational & Non-Relational Databases 
-- 
-- Post-Graduation in Enterprise Data Science & Analytics from the 
-- NOVA – Information Management School
-- 
-- RELATIONAL DATA: 
-- STOCK CLEARANCE & BRICK AND MORTAR STORES
--
-- Francisco Costa, 20181393
-- João Gouveia, 20181399
-- Nuno Rocha, 20181407
-- Pedro Rivera, 20181411
--
--------------------------------------------------------------------------------
--
-- Brick_and_Mortal_Stores_Views.sql Script
--
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION [Sales].[ufnGetIndividualAddress](@AddressID int)
RETURNS @addressInformation TABLE 
(
    [AddressID] int NOT NULL,
	[AddressLine1][nvarchar](60) NOT NULL,
	[AddressLine2][nvarchar](60) NULL,
	[City] [nvarchar](30) NOT NULL,
	[StateProvinceID] int NOT NULL,
	[StateProvinceCode][nvarchar](3) NULL,
	[StateProvinceName][nvarchar](50) NULL,
	[StateProvinceCountryRegionCode] [nvarchar](3) NULL,
	[StateProvinceCountryRegionName] [nvarchar](50) NULL,
	[StateProvinceIsOnlyStateProvinceFlag] bit NULL,
	[StateProvinceTerritoryID] int NULL,
	[PostalCode] [nvarchar](15) NOT NULL,
	[SpatialLocation] geography NULL
)
AS 
BEGIN
	INSERT INTO @addressInformation SELECT q_address.[AddressID],
		q_address.[AddressLine1],
		q_address.[AddressLine2],
		q_address.[City],
		q_address.[StateProvinceID],
		q_address.[StateProvinceCode],
		q_address.[StateProvinceName],
		q_address.[StateProvinceCountryRegionCode],
		q_address.[StateProvinceCountryRegionName],
		q_address.[StateProvinceIsOnlyStateProvinceFlag],
		q_address.[StateProvinceTerritoryID],
		q_address.[PostalCode],
		q_address.[SpatialLocation]
	FROM [Person].[_vAddressStateRegion] as q_address
	WHERE q_address.[AddressID]=@AddressID;
	RETURN;
END;
GO


CREATE FUNCTION [Sales].[ufnGetStoreAddressID](@StoreID [int])
RETURNS [int] 
AS 
BEGIN
    DECLARE @AddressID as int;
	SELECT @AddressID = q_Address.[AddressID]
	FROM [Sales].[Customer] AS q_salescustomer LEFT OUTER JOIN [Sales].[Store] AS q_store
	 ON q_salescustomer.[StoreID] = q_store.[BusinessEntityID] INNER JOIN [Person].[BusinessEntityAddress] as q_Address
	 ON q_store.[BusinessEntityID] = q_Address.[BusinessEntityID] INNER JOIN [Person].[AddressType] as q_AddressType
	 ON q_Address.[AddressTypeID] = q_AddressType.[AddressTypeID] 
	WHERE [PersonID] IS NULL AND q_AddressType.[Name]=N'Main Office' AND q_salescustomer.[StoreID]=@StoreID;
	RETURN @AddressID;
END;
GO


CREATE OR ALTER FUNCTION [Sales].[ufnGetStoreAddress](@StoreID int)
RETURNS @addressInformation TABLE 
(
    [AddressID] int NOT NULL,
	[AddressLine1][nvarchar](60) NOT NULL,
	[AddressLine2][nvarchar](60) NULL,
	[City] [nvarchar](30) NOT NULL,
	[StateProvinceID] int NOT NULL,
	[StateProvinceCode][nvarchar](3) NULL,
	[StateProvinceName][nvarchar](50) NULL,
	[StateProvinceCountryRegionCode] [nvarchar](3) NULL,
	[StateProvinceCountryRegionName] [nvarchar](50) NULL,
	[StateProvinceIsOnlyStateProvinceFlag] bit NULL,
	[StateProvinceTerritoryID] int NULL,
	[PostalCode] [nvarchar](15) NOT NULL,
	[SpatialLocation] geography NULL
)
AS 
BEGIN
	DECLARE @AddressID as int;
	SELECT @AddressID = (SELECT [Sales].[ufnGetStoreAddressID] (@StoreID)); 
	
	INSERT INTO @addressInformation SELECT q_address.[AddressID],
		q_address.[AddressLine1],
		q_address.[AddressLine2],
		q_address.[City],
		q_address.[StateProvinceID],
		q_address.[StateProvinceCode],
		q_address.[StateProvinceName],
		q_address.[StateProvinceCountryRegionCode],
		q_address.[StateProvinceCountryRegionName],
		q_address.[StateProvinceIsOnlyStateProvinceFlag],
		q_address.[StateProvinceTerritoryID],
		q_address.[PostalCode],
		q_address.[SpatialLocation]
	FROM [Person].[_vAddressStateRegion] as q_address
	WHERE q_address.[AddressID]=@AddressID;
	RETURN;
END;
GO


CREATE OR ALTER FUNCTION [Production].[ufnGetProductCost](@ProductID [int], @OrderDate [datetime])
RETURNS [money] 
AS 
BEGIN
    DECLARE @StandardCost as money;
    SELECT @StandardCost = p.[StandardCost] 
    FROM [Production].[ProductCostHistory] as p
	WHERE p.[ProductID] = @ProductID AND (@OrderDate BETWEEN p.[StartDate] AND COALESCE(p.[EndDate], CONVERT(datetime, '99991231', 112)));
    RETURN @StandardCost;
END;
GO


CREATE OR ALTER VIEW [Person].[_vAddressStateRegion]
AS
SELECT        q_address.AddressID, q_address.AddressLine1, q_address.AddressLine2, q_address.City, q_address.StateProvinceID, q_stateprovince.StateProvinceCode, q_stateprovince.Name AS StateProvinceName, 
                         q_stateprovince.CountryRegionCode AS StateProvinceCountryRegionCode, q_countryregion.Name AS StateProvinceCountryRegionName, q_stateprovince.IsOnlyStateProvinceFlag AS StateProvinceIsOnlyStateProvinceFlag, 
                         q_stateprovince.TerritoryID AS StateProvinceTerritoryID, q_address.PostalCode, q_address.SpatialLocation
FROM            Person.Address AS q_address LEFT OUTER JOIN
                         Person.StateProvince AS q_stateprovince ON q_address.StateProvinceID = q_stateprovince.StateProvinceID LEFT OUTER JOIN
                         Person.CountryRegion AS q_countryregion ON q_stateprovince.CountryRegionCode = q_countryregion.CountryRegionCode
GO


CREATE OR ALTER VIEW [Production].[_vProductCat_FinishedGoods]
AS
SELECT        q_product.ProductID, q_product.Name AS ProductName, q_product.ProductNumber, q_product.MakeFlag, q_product.Color, q_product.StandardCost AS _tempProductStandardCost, q_product.ListPrice AS ProductListPrice, 
                         q_product.Size AS ProductSize, q_product.ProductLine, q_product.Class AS ProductClass, q_product.Style, q_product.ProductSubcategoryID, q_productSubCat.Name AS ProductSubcategoryName, 
                         q_productSubCat.ProductCategoryID, q_productCat.Name AS ProductCategoryName, q_product.ProductModelID, q_product.SellStartDate, q_product.SellEndDate, q_product.DiscontinuedDate
FROM            Production.Product AS q_product LEFT OUTER JOIN
                         Production.ProductSubcategory AS q_productSubCat ON q_product.ProductSubcategoryID = q_productSubCat.ProductSubcategoryID LEFT OUTER JOIN
                         Production.ProductCategory AS q_productCat ON q_productSubCat.ProductCategoryID = q_productCat.ProductCategoryID
WHERE        (q_product.FinishedGoodsFlag = 1)
GO


CREATE OR ALTER VIEW [Sales].[_vProductMargins_US]
AS
SELECT        SalesOrderID, BillToAddressID, Country, ShipToAddressID, Status, OnlineOrderFlag, OrderDate, OrderYear, OrderQ, CustomerID, SalesPersonID, TerritoryID, SubTotal, TaxAmt, Freight, TotalDue, SalesOrderDetailID, 
                         CarrierTrackingNumber, OrderQty, ProductID, ProductName, ProductNumber, MakeFlag, Color, ProductStandardCost, ProductListPrice, ProductSize, ProductLine, ProductClass, Style, ProductSubcategoryID, 
                         ProductSubcategoryName, ProductCategoryID, ProductCategoryName, ProductModelID, SellStartDate, SellEndDate, DiscontinuedDate, SpecialOfferID, UnitPrice, UnitPriceDiscount, LineTotal, 
                         LineTotal - ProductStandardCost * OrderQty AS LineGrossMargin, UnitPrice * (1 - UnitPriceDiscount) - ProductStandardCost AS ProductGrossMargin, (UnitPrice - ProductStandardCost) 
                         / ProductStandardCost AS ProductGrossMargin_percent_wo_disc, (UnitPrice * (1 - UnitPriceDiscount) - ProductStandardCost) / ProductStandardCost AS ProductGrossMargin_percent
FROM            (SELECT        q_salesorderdetail.SalesOrderID, q_salesorderheader.BillToAddressID, q_address.StateProvinceCountryRegionName AS Country, q_salesorderheader.ShipToAddressID, q_salesorderheader.Status, 
                                                    q_salesorderheader.OnlineOrderFlag, q_salesorderheader.OrderDate, YEAR(q_salesorderheader.OrderDate) AS OrderYear, CONVERT(VARCHAR, YEAR(q_salesorderheader.OrderDate)) + 'Q' + CONVERT(VARCHAR, 
                                                    (MONTH(q_salesorderheader.OrderDate) - 1) / 3 + 1) AS OrderQ, q_salesorderheader.CustomerID, q_salesorderheader.SalesPersonID, q_salesorderheader.TerritoryID, q_salesorderheader.SubTotal, 
                                                    q_salesorderheader.TaxAmt, q_salesorderheader.Freight, q_salesorderheader.TotalDue, q_salesorderdetail.SalesOrderDetailID, q_salesorderdetail.CarrierTrackingNumber, q_salesorderdetail.OrderQty, 
                                                    q_salesorderdetail.ProductID, q_product.ProductName, q_product.ProductNumber, q_product.MakeFlag, q_product.Color,
                                                        (SELECT        Production.ufnGetProductCost(q_product.ProductID, q_salesorderheader.OrderDate) AS Expr1) AS ProductStandardCost, q_product.ProductListPrice, q_product.ProductSize, q_product.ProductLine, 
                                                    q_product.ProductClass, q_product.Style, q_product.ProductSubcategoryID, q_product.ProductSubcategoryName, q_product.ProductCategoryID, q_product.ProductCategoryName, q_product.ProductModelID, 
                                                    q_product.SellStartDate, q_product.SellEndDate, q_product.DiscontinuedDate, q_salesorderdetail.SpecialOfferID, q_salesorderdetail.UnitPrice, q_salesorderdetail.UnitPriceDiscount, 
                                                    q_salesorderdetail.LineTotal
                          FROM            Sales.SalesOrderDetail AS q_salesorderdetail LEFT OUTER JOIN
                                                    Production._vProductCat_FinishedGoods AS q_product ON q_salesorderdetail.ProductID = q_product.ProductID LEFT OUTER JOIN
                                                    Sales.SalesOrderHeader AS q_salesorderheader ON q_salesorderdetail.SalesOrderID = q_salesorderheader.SalesOrderID INNER JOIN
                                                    Person._vAddressStateRegion AS q_address ON q_salesorderheader.BillToAddressID = q_address.AddressID) AS q_salesorders
WHERE        (Country = 'United States')
GO


CREATE OR ALTER VIEW [Sales].[_vStoresTotalSalesMargins_US]
AS
SELECT        q_storemargins.[OrderQ], q_storemargins.[StoreID], q_store.[Name] AS StoreName, q_storemargins.[TotalSales], q_storemargins.[TotalGrossMargin], q_address.[AddressID], q_address.[AddressLine1], 
                         q_address.[AddressLine2], q_address.[City], q_address.[StateProvinceID], q_address.[StateProvinceCode], q_address.[StateProvinceName] AS State, q_address.[StateProvinceCountryRegionCode], 
                         q_address.[StateProvinceCountryRegionName] AS Country, ISNULL(q_address.[City], '') + ' (' + ISNULL(q_address.[StateProvinceCountryRegionName], '') + ')' AS City_Country, ISNULL(q_address.[City], '') 
                         + ' (' + ISNULL(q_address.[StateProvinceName], '') + ')' AS City_State, ISNULL(REPLACE(q_address.[AddressLine1], ',', ' '), '') + ', ' + ISNULL(q_address.[City], '') + ', ' + ISNULL(q_address.[StateProvinceName], '') 
                         + ', ' + ISNULL(q_address.[StateProvinceCountryRegionName], '') AS Address, q_address.[StateProvinceIsOnlyStateProvinceFlag], q_address.[StateProvinceTerritoryID], q_address.[PostalCode], q_address.[SpatialLocation], 
                         q_address.[SpatialLocation].Lat AS Latitude, q_address.[SpatialLocation].Long AS Longitude
FROM            (SELECT        q_prodmargins.[OrderQ], q_store.[StoreID], SUM([LineTotal]) AS TotalSales, SUM([LineGrossMargin]) AS TotalGrossMargin
                          FROM            [Sales].[_vProductMargins_US] AS q_prodmargins INNER JOIN
                                                    [Sales].[_vCustomerStore] AS q_store ON q_prodmargins.CustomerID = q_store.CustomerID
                          GROUP BY q_store.[StoreID], q_prodmargins.[OrderQ]) AS q_storemargins OUTER APPLY[Sales].[ufnGetStoreAddress](q_storemargins.[StoreID]) q_address INNER JOIN
                         [Sales].[Store] AS q_store ON q_storemargins.[StoreID] = q_store.[BusinessEntityID]
GO


CREATE OR ALTER VIEW [Sales].[_vIndividualsTotalSalesMargins_US]
AS
SELECT q_prodmargins_city.[OrderQ],
	q_prodmargins_city.[Country],
	q_prodmargins_city.[State],
	q_prodmargins_city.[City],
	SUM(q_prodmargins_city.[LineTotal]) as TotalSales,
	SUM(q_prodmargins_city.[LineGrossMargin]) as TotalGrossMargin
	FROM (SELECT q_prodmargins_individuals.[OrderQ],
	q_prodmargins_individuals.[BilltoAddressID],
	q_prodmargins_individuals.[LineTotal],
	q_prodmargins_individuals.[LineGrossMargin],
	q_address.[AddressID],
	q_address.[AddressLine1],
	q_address.[AddressLine2],
	q_address.[City],
	q_address.[StateProvinceID],
	q_address.[StateProvinceCode],
	q_address.[StateProvinceName] as State,
	q_address.[StateProvinceCountryRegionCode],
	q_address.[StateProvinceCountryRegionName] as Country,
	ISNULL(q_address.[City], '') + ' (' + ISNULL(q_address.[StateProvinceCountryRegionName], '') + ')' as City_Country,
	ISNULL(q_address.[City], '') + ' (' + ISNULL(q_address.[StateProvinceName], '') + ')' as City_State,
	ISNULL(REPLACE(q_address.[AddressLine1],',',' '), '') + ', '+ ISNULL(q_address.[City], '') + ', ' + ISNULL(q_address.[StateProvinceName], '') + ', ' + ISNULL(q_address.[StateProvinceCountryRegionName], '')  as Address,
	q_address.[StateProvinceIsOnlyStateProvinceFlag],
	q_address.[StateProvinceTerritoryID],
	q_address.[PostalCode],
	q_address.[SpatialLocation],
	q_address.[SpatialLocation].Lat as Latitude,
	q_address.[SpatialLocation].Long as Longitude
FROM (SELECT q_prodmargins.* FROM [Sales].[_vProductMargins_US] as q_prodmargins WHERE [OnlineOrderFlag]=1) as q_prodmargins_individuals
OUTER APPLY [Sales].[ufnGetIndividualAddress](q_prodmargins_individuals.[BilltoAddressID]) as q_address) as q_prodmargins_city
GROUP BY [Country], [State], [City], [OrderQ]
GO


CREATE OR ALTER VIEW [Sales].[_vCustomerStore]
AS
SELECT        q_salescustomer.CustomerID, q_salescustomer.TerritoryID, q_territory.Name, q_territory.CountryRegionCode, q_territory.[Group], q_territory.SalesYTD, q_territory.SalesLastYear, q_territory.CostYTD, q_territory.CostLastYear, 
                         q_salescustomer.AccountNumber, q_salescustomer.StoreID, q_store.Name AS StoreName, q_store.Demographics AS StoreDemographics, q_store.SalesPersonID, 
                         CASE WHEN q_person.[PersonType] = 'SC' THEN 'Store Contact' WHEN q_person.[PersonType] = 'IN' THEN 'Individual' WHEN q_person.[PersonType] = 'SP' THEN 'SalesPerson' WHEN q_person.[PersonType] = 'EM' THEN 'Employee'
                          WHEN q_person.[PersonType] = 'VC' THEN 'Vendor Contact' WHEN q_person.[PersonType] = 'GC' THEN 'General Contatc' END AS SalesPersonTypeDesc, q_person.Title AS SalesPersonTitle, 
                         q_person.FirstName AS SalesPersonFirstName, q_person.MiddleName AS SalesPersonMiddleName, q_person.LastName AS SalesPersonLastName, q_person.Suffix AS SalesPersonSuffix, ISNULL(q_person.Title, '') 
                         + q_person.FirstName + ' ' + ISNULL(q_person.MiddleName, '') + ' ' + q_person.LastName AS SalesPersonCompleteName, q_person.Demographics AS SalesPersonDemographics
FROM            Sales.Customer AS q_salescustomer INNER JOIN
                         Sales.Store AS q_store ON q_salescustomer.StoreID = q_store.BusinessEntityID INNER JOIN
                         Person.Person AS q_person ON q_store.SalesPersonID = q_person.BusinessEntityID INNER JOIN
                         Sales.SalesTerritory AS q_territory ON q_salescustomer.TerritoryID = q_territory.TerritoryID
WHERE        (q_salescustomer.PersonID IS NULL)
GO


CREATE OR ALTER VIEW [Sales].[_vStoresTotalSalesMargins_US_TOP30]
AS
SELECT        TOP (30) q_storemargins.[StoreID], q_store.[Name] AS StoreName, q_storemargins.[TotalGrossMargin], RANK() OVER (ORDER BY q_storemargins.[TotalGrossMargin] DESC) AS [Rank], q_address.[AddressID], 
q_address.[AddressLine1], q_address.[AddressLine2], q_address.[City], q_address.[StateProvinceID], q_address.[StateProvinceCode], q_address.[StateProvinceName] AS State, q_address.[StateProvinceCountryRegionCode], 
q_address.[StateProvinceCountryRegionName] AS Country, ISNULL(q_address.[City], '') + ' (' + ISNULL(q_address.[StateProvinceCountryRegionName], '') + ')' AS City_Country, ISNULL(q_address.[City], '') 
+ ' (' + ISNULL(q_address.[StateProvinceName], '') + ')' AS City_State, ISNULL(REPLACE(q_address.[AddressLine1], ',', ' '), '') + ', ' + ISNULL(q_address.[City], '') + ', ' + ISNULL(q_address.[StateProvinceName], '') 
+ ', ' + ISNULL(q_address.[StateProvinceCountryRegionName], '') AS Address, q_address.[StateProvinceIsOnlyStateProvinceFlag], q_address.[StateProvinceTerritoryID], q_address.[PostalCode], q_address.[SpatialLocation], 
q_address.[SpatialLocation].Lat AS Latitude, q_address.[SpatialLocation].Long AS Longitude
FROM            (SELECT        q_store.[StoreID], SUM([LineGrossMargin]) AS TotalGrossMargin
                          FROM            [Sales].[_vProductMargins_US] AS q_prodmargins INNER JOIN
                                                    [Sales].[_vCustomerStore] AS q_store ON q_prodmargins.CustomerID = q_store.CustomerID
                          GROUP BY q_store.[StoreID]) AS q_storemargins OUTER APPLY[Sales].[ufnGetStoreAddress](q_storemargins.[StoreID]) q_address INNER JOIN
                         [Sales].[Store] AS q_store ON q_storemargins.[StoreID] = q_store.[BusinessEntityID]
ORDER BY q_storemargins.[TotalGrossMargin] DESC
GO

