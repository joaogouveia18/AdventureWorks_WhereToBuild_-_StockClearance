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
-- views.sql Script
--
--------------------------------------------------------------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [AdventureWorks]
GO
-- Objective #1: Get insights concerning the financial impact of auctions
--@considers all bids, even the ones in progress
CREATE OR ALTER VIEW [Auction].[_vFinancialImpacts_NetRevenue]
AS
-- Get the ProductSubCategoryName from the ProductSubCategoryID to the SELECT below
SELECT a_bid_impact_revenue_final.[SumNetRevenue],
		p_ps.[Name] as [ProductSubCategoryName],
		 a_bid_impact_revenue_final.[Rank] FROM
		  (
			-- Sum the NetRevenue by ProductSubCategoryID and Rank the results
			SELECT SUM(a_bid_impact_revenue.[NetRevenue]) as [SumNetRevenue],
					a_bid_impact_revenue.[ProductSubcategoryID],
					 RANK() OVER (ORDER BY SUM(a_bid_impact_revenue.[NetRevenue]) DESC) AS [Rank] FROM
					  (
					   -- Determine the NetRevenue, Margin and get the ProductSubCategoryID 
					   --(filter the results by the items that were not removed from Auction)
					   SELECT a_bid_impact.*,
							   a_bid_impact.[MaxBidAmmount]-a_bid_impact.[StandardCost] AS [NetRevenue],
								(a_bid_impact.[MaxBidAmmount]-a_bid_impact.[StandardCost])/a_bid_impact.[StandardCost] as [Margin],
								 p_ps.[ProductSubcategoryID] FROM 
								  (
								   SELECT * FROM 
					  				   (
									    -- Join the fields from table Auction.Product to the SELECT below
										SELECT a_bidsum .*,
												a_p.[ProductID],
												 a_p.[AuctionStatus],
												  a_p.[Removed],
												   a_p.[StandardCost] FROM
												   (
												    -- SELECT the lastest Bid Ammount for each AuctionProductID
													--(filter the results by the lastest year when bids occurred)
													SELECT [AuctionProductID],
															MAX([BidAmmount]) AS [MaxBidAmmount] FROM
															 [Auction].[ProductBid]
														   WHERE YEAR([BidTimestamp]) = COALESCE((SELECT MAX(YEAR(a_pd.[BidTimestamp])) FROM [Auction].[ProductBid] as a_pd),
															   YEAR(GETDATE()))
														   GROUP BY [AuctionProductID]
												   ) AS a_bidsum 
										INNER JOIN [Auction].[Product] AS a_p
										 ON a_bidsum.[AuctionProductID] = a_p.[AuctionProductID]
										) AS a_bidsum_prod
								 ) as a_bid_impact
					   INNER JOIN [Production].[Product] as p_p
						ON a_bid_impact.[ProductID] = p_p.[ProductID]
						 INNER JOIN [Production].[ProductSubcategory] as p_ps
						  ON p_p.[ProductSubcategoryID] = p_ps.[ProductSubcategoryID]
					   WHERE a_bid_impact.[Removed] = 0
					  ) AS a_bid_impact_revenue
		   GROUP BY a_bid_impact_revenue.[ProductSubcategoryID]
		  ) AS a_bid_impact_revenue_final
		 LEFT JOIN [Production].[ProductSubcategory] as p_ps 
		  ON a_bid_impact_revenue_final.[ProductSubcategoryID]= p_ps.[ProductSubcategoryID]
GO


-- Objective #2: Check if products are being sold below 95% of standard cost
--@only for the products already sold ([Auction].[Product].[AuctionStatus] = 0)
CREATE OR ALTER VIEW [Auction].[_vFinancialImpacts_Margin]
AS
-- Get the ProductSubCategoryName from the ProductSubCategoryID to the SELECT below
SELECT a_bid_impact_margin_final.[AverageMargin],
		p_ps.[Name] as [ProductSubCategoryName],
		 a_bid_impact_margin_final.[Rank] FROM
		  (
		   -- Average the Margin by ProductSubCategoryID and Rank the results
		   SELECT AVG(a_bid_impact_margin.[Margin]) as [AverageMargin],
				   a_bid_impact_margin.[ProductSubcategoryID],
					RANK() OVER (ORDER BY AVG(a_bid_impact_margin.[Margin]) DESC) AS [Rank] FROM
					(
					 -- Determine the NetRevenue, Margin and get the ProductSubCategoryID 
					 --(filter the results by the items that are still active in the Auction)
					 SELECT a_bid_impact.*,
							 a_bid_impact.[MaxBidAmmount]-a_bid_impact.[StandardCost] AS [NetRevenue],
							 (a_bid_impact.[MaxBidAmmount]-a_bid_impact.[StandardCost])/a_bid_impact.[StandardCost] as [Margin],
							  p_ps.[ProductSubcategoryID] FROM 
								(
								 SELECT * FROM 
					  				 (
									  -- Join the fields from table Auction.Product to the SELECT below
									  SELECT a_bidsum .*,
											  a_p.[ProductID],
											   a_p.[AuctionStatus],
												a_p.[Removed],
												 a_p.[StandardCost] FROM
												  (
												   -- SELECT the lastest Bid Ammount for each AuctionProductID
												   --(filter the results by the lastest year when bids occurred)
												   SELECT [AuctionProductID],
														   MAX([BidAmmount]) AS [MaxBidAmmount] FROM
															[Auction].[ProductBid]
														  WHERE YEAR([BidTimestamp]) = COALESCE((SELECT MAX(YEAR(a_pd.[BidTimestamp])) FROM [Auction].[ProductBid] as a_pd),
														   YEAR(GETDATE()))
														  GROUP BY [AuctionProductID]
												  ) AS a_bidsum 
										INNER JOIN [Auction].[Product] AS a_p
										ON a_bidsum.[AuctionProductID] = a_p.[AuctionProductID]
									) AS a_bidsum_prod
								) as a_bid_impact
					INNER JOIN [Production].[Product] as p_p
					ON a_bid_impact.[ProductID] = p_p.[ProductID]
						INNER JOIN [Production].[ProductSubcategory] as p_ps
						ON p_p.[ProductSubcategoryID] = p_ps.[ProductSubcategoryID]
					WHERE a_bid_impact.[Removed] = 0 AND a_bid_impact.[AuctionStatus] = 0 
					) AS a_bid_impact_margin
		GROUP BY a_bid_impact_margin.[ProductSubcategoryID]
		) AS a_bid_impact_margin_final
			LEFT JOIN [Production].[ProductSubcategory] as p_ps 
			ON a_bid_impact_margin_final.[ProductSubcategoryID]= p_ps.[ProductSubcategoryID]
GO


-- Objective #3: Relation between sales from auction and total sales
--@only for the products already sold ([Auction].[Product].[AuctionStatus] = 0)
CREATE OR ALTER VIEW [Auction].[_vFinancialImpacts_SalesComparison]
AS
-- Get the ProductSubCategoryName from the ProductSubCategoryID to the SELECT below
SELECT p_ps.[Name] as [ProductSubCategoryName],
		a_totalsales_bid.[Total Sales],
		 a_totalsales_bid.[TotalBidSales],
		  a_totalsales_bid.[BidSalesPercent] FROM
		   (
		   -- JOIN the 2 SELECTS below (the first from the Sales schema and the second from the Auction schema
			SELECT s_totalsales.*,
					a_totalbidsales.[TotalBidSales],
					 a_totalbidsales.[TotalBidSales]/s_totalsales.[Total Sales] AS [BidSalesPercent] FROM
					  (
					   -- #1: Sum the LineTotal from Sales.SalesOrderDetail for each ProductSubcategoryID
					   SELECT s_so.[ProductSubcategoryID],
							   SUM(s_so.[LineTotal]) as [Total Sales] FROM
								(
								 --JOIN Sales.SalesOrderHeader, Sales.SalesOrderDetail, Production.Product and ProductionSubcategory
								 --to retrieve all the fields required to evaluate the sales in a certain year by ProductSubcategory
								 --(filter the results by the lastest year when bids occurred)
								 SELECT s_soh.[SalesOrderID],
										 YEAR(s_soh.[OrderDate]) AS [OrderYear],
										  s_sod.[ProductID],
										   s_sod.[LineTotal],
											p_ps.[Name] as [ProductSubCategoryName],
											 p_ps.[ProductSubcategoryID]
											 FROM [Sales].[SalesOrderHeader] as s_soh
								 LEFT JOIN [Sales].[SalesOrderDetail] as s_sod
								  ON s_soh.[SalesOrderID] = s_sod.[SalesOrderID]
								   LEFT JOIN [Production].[Product] as p_p
									ON s_sod.[ProductID] = p_p.[ProductID]
									 LEFT JOIN [Production].[ProductSubcategory] as p_ps
									  ON p_p.[ProductSubcategoryID] = p_ps.[ProductSubcategoryID]
								 WHERE YEAR(s_soh.[OrderDate]) = COALESCE((SELECT MAX(YEAR(a_pd.[BidTimestamp])) FROM [Auction].[ProductBid] as a_pd),
								  YEAR(GETDATE()))
								) AS s_so
					   GROUP BY s_so.[ProductSubcategoryID]
					  ) AS s_totalsales
			LEFT JOIN 
			(
			 SELECT a_bidsales.* FROM
			  (
			   -- #2: Sum the Sales from Auction by ProductSubCategoryID
			   SELECT SUM(a_bid_impact_sales.[MaxBidAmmount]) as [TotalBidSales],
					   a_bid_impact_sales.[ProductSubcategoryID] FROM
						(
						 -- Determine the NetRevenue, Margin and get the ProductSubCategoryID 
					     --(filter the results by the items that are still active in the Auction)
						 SELECT a_bid_impact.*,
								 a_bid_impact.[MaxBidAmmount]-a_bid_impact.[StandardCost] AS [NetRevenue],
								  (a_bid_impact.[MaxBidAmmount]-a_bid_impact.[StandardCost])/a_bid_impact.[StandardCost] as [Margin],
								   p_ps.[ProductSubcategoryID] FROM 
									(
									 SELECT * FROM 
					  				  (
									  -- Join the fields from table Auction.Product to the SELECT below
									   SELECT a_bidsum .*,
											   a_p.[ProductID],
												a_p.[AuctionStatus],
												 a_p.[Removed],
												  a_p.[StandardCost] FROM
												   (
												   -- SELECT the lastest Bid Ammount for each AuctionProductID
												   --(filter the results by the lastest year when bids occurred)
													SELECT [AuctionProductID],
															MAX([BidAmmount]) AS [MaxBidAmmount] FROM
															 [Auction].[ProductBid]
														   WHERE YEAR([BidTimestamp]) = COALESCE((SELECT MAX(YEAR(a_pd.[BidTimestamp])) FROM [Auction].[ProductBid] as a_pd),
															   YEAR(GETDATE()))	
														   GROUP BY [AuctionProductID]
													) AS a_bidsum 
										INNER JOIN [Auction].[Product] AS a_p
										 ON a_bidsum.[AuctionProductID] = a_p.[AuctionProductID]
										) AS a_bidsum_prod
									) as a_bid_impact
						 INNER JOIN [Production].[Product] as p_p
						  ON a_bid_impact.[ProductID] = p_p.[ProductID]
						   INNER JOIN [Production].[ProductSubcategory] as p_ps
							ON p_p.[ProductSubcategoryID] = p_ps.[ProductSubcategoryID]
						 WHERE a_bid_impact.[Removed] = 0 AND a_bid_impact.[AuctionStatus] = 0 
						) AS a_bid_impact_sales
			   GROUP BY a_bid_impact_sales.[ProductSubcategoryID]
			  ) AS a_bidsales
			) AS a_totalbidsales 
			 ON s_totalsales.[ProductSubcategoryID] = a_totalbidsales.[ProductSubcategoryID]
		   ) AS a_totalsales_bid
		    LEFT JOIN [Production].[ProductSubcategory] as p_ps 
			  ON a_totalsales_bid.[ProductSubcategoryID]= p_ps.[ProductSubcategoryID]
 GO