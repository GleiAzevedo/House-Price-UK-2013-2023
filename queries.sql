CREATE DATABASE HouseMarketUK2013_2023
-- Import tables

-- Create column 'Year' as the analysis is based by year:

ALTER TABLE Average_prices_2023_12
ADD [Year] int
UPDATE Average_prices_2023_12
SET [Year] = YEAR([Date]);

ALTER TABLE Buyer_Position_2023_12
ADD [Year] int
UPDATE Buyer_Position_2023_12
SET [Year] = YEAR([Date]);

ALTER TABLE Index_2023_12
ADD [Year] int
UPDATE Index_2023_12
SET [Year] = YEAR([Date]);

-- Remove unnecessary rows period studied is from 2013 - 2023:

DELETE FROM Average_prices_2023_12
WHERE [Year] < 2013;

DELETE FROM Buyer_Position_2023_12
WHERE [Year] < 2013;

DELETE FROM Index_2023_12
WHERE [Year] < 2013;

-- Check for duplicate values, confirming same number of rows:

SELECT DISTINCT *
FROM Average_prices_2023_12;

SELECT DISTINCT *
FROM Buyer_Position_2023_12;

SELECT DISTINCT *
FROM Index_2023_12;

-- Check for null values:

SELECT *
FROM Average_prices_2023_12
WHERE 
	[Date] IS NULL 
	OR Region_Name IS NULL 
	OR Area_Code IS NULL
	OR Average_Price IS NULL
	OR [Year] IS NULL;

SELECT * 
FROM Buyer_Position_2023_12
WHERE 
	[Date] IS NULL
	OR Region_Name IS NULL
	OR Area_Code IS NULL
	OR First_Time_Buyer_Average_Price IS NULL
	OR Former_Owner_Occupier_Average_Price IS NULL
	OR Former_Owner_Occupier_Index IS NULL
	OR [Year] IS NULL;

SELECT * 
FROM Index_2023_12
WHERE 
	[Date] IS NULL
	OR Region_Name IS NULL
	OR Area_Code IS NULL
	OR [Index] IS NULL
	OR [Year] IS NULL;

-- Create a new table with average Price by region and year:

SELECT	
	Region_Name,
	Area_Code,
	AVG(Average_Price) AS [Yearly_Average_Price],
	[Year]
INTO tblYearlyAverage
FROM Average_prices_2023_12
GROUP BY
	Region_Name,
	Area_Code, 
	[Year]
ORDER BY Region_Name;

-- Create a new table with buyer position by year:

SELECT
	Region_Name, 
	Area_Code,
	AVG(First_Time_Buyer_Average_Price) AS [FTB_ Yearly_Average_Price],
	AVG(First_Time_Buyer_Index) AS [FTB_ Yearly_Index_Price],
	AVG(Former_Owner_Occupier_Average_Price) AS [FWO_Yearly_Average_Price],
	AVG(Former_Owner_Occupier_Index) AS [FWO_Index_Price],
	[Year]
INTO tblYearlyBuyerPosition
FROM Buyer_Position_2023_12
GROUP BY
	Region_Name,
	Area_Code,
	[Year]
ORDER BY Region_Name;

-- Create a new table with index values by year:

SELECT
	Region_Name,
	Area_Code,
	AVG([Index]) AS [Yearly_Index],
	[Year]
INTO tblYearlyIndex
FROM Index_2023_12
GROUP BY
	Region_Name,
	Area_Code,
	[Year];

-- Here we could notice that we don't have the same number of rows in all tblYearlyBuyerPosition as in the other two tables

SELECT DISTINCT ya.PriceID
FROM tblYearlyAverage AS ya
LEFT JOIN tblYearlyBuyerPosition bp ON ya.PriceID = bp.PriceID
WHERE bp.PriceID IS NULL;

SELECT DISTINCT yi.PriceID
FROM tblYearlyIndex AS yi
LEFT JOIN tblYearlyBuyerPosition bp ON yi.PriceID = bp.PriceID
WHERE bp.PriceID IS NULL;

INSERT INTO tblYearlyBuyerPosition (PriceID, Area_Code,[Year],[FTB_ Yearly_Average_Price],[FTB_ Yearly_Index_Price],FWO_Yearly_Average_Price,FWO_Index_Price)
SELECT ya.PriceID, ya.Area_Code, -11,-0.1,-0.1,-0.1,-0.1
FROM tblYearlyAverage AS ya
LEFT JOIN tblYearlyBuyerPosition bp ON ya.PriceID = bp.PriceID
WHERE bp.PriceID IS NULL;

-- Create new column to be used to join the tables:

ALTER TABLE tblYearlyAverage
ADD PriceID nvarchar(50);
UPDATE tblYearlyAverage
SET PriceID = CONCAT(Region_Name,'_',[Year]);
ALTER TABLE tblYearlyAverage
ADD PRIMARY KEY (PriceID);

ALTER TABLE tblYearlyBuyerPosition
ADD PriceID nvarchar(50);
UPDATE tblYearlyBuyerPosition
SET PriceID = CONCAT(Region_Name,'_',[Year]);
ALTER TABLE tblYearlyBuyerPosition
ADD PRIMARY KEY (PriceID);

ALTER TABLE tblYearlyIndex
ADD PriceID nvarchar(50);
UPDATE tblYearlyIndex
SET PriceID = CONCAT(Region_Name,'_',[Year]);
ALTER TABLE tblYearlyIndex
ADD PRIMARY KEY (PriceID);

-- Create Regions table:

SELECT DISTINCT
	Area_Code,
	Region_Name
INTO tblRegions
FROM tblYearlyAverage;

ALTER TABLE tblRegions
ADD PRIMARY KEY (Area_Code);

ALTER TABLE tblYearlyAverage
ADD FOREIGN KEY (Area_Code) REFERENCES tblRegions(Area_Code);
ALTER TABLE tblYearlyBuyerPosition
ADD FOREIGN KEY (Area_Code) REFERENCES tblRegions(Area_Code);
ALTER TABLE tblYearlyIndex
ADD FOREIGN KEY (Area_Code) REFERENCES tblRegions(Area_Code);

-- Drop Region Name on tables:

ALTER TABLE tblYearlyAverage
DROP COLUMN Region_Name;

ALTER TABLE tblYearlyBuyerPosition
DROP COLUMN Region_Name;

ALTER TABLE tblYearlyIndex
DROP COLUMN Region_Name;

-- Minimum and maximum average price, across all regions, between 2013 and 2023:

SELECT 
	r.Region_Name,
	y.Area_Code,
	FORMAT(Yearly_Average_Price, 'C','en-gb') AS [Yearly_Average_Price],
	[Year]
FROM tblYearlyAverage AS y
	INNER JOIN tblRegions AS r ON y.Area_Code = r.Area_Code
WHERE FORMAT(Yearly_Average_Price, 'C','en-gb') IN 
	((SELECT FORMAT(MIN(Yearly_Average_Price), 'C', 'en-gb') FROM tblYearlyAverage),
	(SELECT FORMAT(MAX(Yearly_Average_Price), 'C', 'en-gb') FROM tblYearlyAverage));

SELECT
	y.Area_Code,
	r.Region_Name,
	FORMAT(Yearly_Average_Price,'C','en-gb') AS [Yearly_Average_Price,]
FROM tblYearlyAverage y
	INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
WHERE r.Region_Name = 'Kensington and Chelsea'
	AND [Year] = 2013

-- The 10 regions with the highest average value and the 10 with the lowest value:

SELECT TOP 10 r.Region_Name AS [Regions_with_highest_average_value]
FROM tblYearlyAverage y
	INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
GROUP BY r.Region_Name
ORDER BY AVG(Yearly_Average_Price) DESC;

SELECT TOP 10 r.Region_Name AS [Regions_with_lowest_average_value]
FROM tblYearlyAverage y
	INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
GROUP BY r.Region_Name
ORDER BY AVG(Yearly_Average_Price) ASC;

-- Top 10 highest and lowest yearly average price:

SELECT 
	TOP 10 FORMAT(Yearly_Average_Price, 'C', 'en-gb') AS [Yearly_Average_Price],
	r.Region_Name,
	y.Area_Code,
	[Year]
FROM tblYearlyAverage y
	INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
GROUP BY 
	r.Region_Name,
	y.Area_Code,
	[Year],
	Yearly_Average_Price
ORDER BY CAST(Yearly_Average_Price AS decimal) DESC;

SELECT 
	TOP 10 FORMAT(Yearly_Average_Price, 'C', 'en-gb')  AS [Yearly_Average_Price],
	r.Region_Name,
	y.Area_Code,
	[Year]
FROM tblYearlyAverage y
	INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
GROUP BY
	r.Region_Name,
	y.Area_Code,
	[Year],
	Yearly_Average_Price
ORDER BY CAST(Yearly_Average_Price AS decimal) ASC;

-- Maximum values by region:

WITH Max_Average_Price_cte AS (
	SELECT
		r.Region_Name,
		y.Area_Code,
		MAX(Yearly_Average_Price) AS [Max_Price]
	FROM tblYearlyAverage y
		INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
	GROUP BY
		r.Region_Name,
		y.Area_Code
)
SELECT
	Max_Average_Price_cte.Region_Name,
	Max_Average_Price_cte.Area_Code,
	FORMAT(Max_Average_Price_cte.[Max_Price],'C','en-gb') AS [Max_Price],
	[Year]
FROM tblYearlyAverage
	INNER JOIN Max_Average_Price_cte ON tblYearlyAverage.Yearly_Average_Price = Max_Average_Price_cte.[Max_Price];

-- Minimum values by region

WITH Min_Average_Price AS (
	SELECT
		r.Region_Name,
		y.Area_Code,
		MIN(Yearly_Average_Price) AS [Min_Price]
	FROM tblYearlyAverage y
		INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
	GROUP BY
		r.Region_Name,
		y.Area_Code
)
SELECT
	Min_Average_Price.Region_Name,
	FORMAT(Min_Average_Price.[Min_Price], 'C','en-gb') AS Min_Price,
	[Year]
FROM tblYearlyAverage
	INNER JOIN Min_Average_Price ON tblYearlyAverage.Yearly_Average_Price = Min_Average_Price.Min_Price;

-- Procedure for average price by region:

CREATE PROCEDURE SelectByRegion @Region nvarchar(50)
AS 
SELECT
	PriceID,
	r.Region_Name,
	y.Area_Code,
	FORMAT((Yearly_Average_Price),'C','en-gb') AS Yearly_Average_Price,
	[Year]
FROM tblYearlyAverage  y
	INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
WHERE r.Region_Name IN (@Region);

EXEC SelectByRegion @Region = 'United Kingdom' 
EXEC SelectByRegion @Region = 'Northern Ireland'
EXEC SelectByRegion @Region = 'Wales'
EXEC SelectByRegion @Region = 'Scotland'
EXEC SelectByRegion @Region = 'England';

-- Average price, index, first time buyer and former owner price in 2013, 2022 and 2023:

SELECT
	r.Region_Name,
	ya.Area_Code,
	FORMAT(ya.Yearly_Average_Price, 'C','en-gb') AS [Total_Average_Price],
	ROUND(yi.Yearly_Index, 2) AS [Yearly_Index],
	FORMAT(yb.[FTB_ Yearly_Average_Price],'C','en-gb') AS [First_Time_Buyer_Price],
	FORMAT(yb.FWO_Yearly_Average_Price,'C','en-gb') AS [Former_Owner_Price],
	ya.[Year]
FROM tblYearlyAverage AS ya
	INNER JOIN tblRegions r ON ya.Area_Code = r.Area_Code
	INNER JOIN tblYearlyBuyerPosition yb ON ya.PriceID = yb.PriceID
	INNER JOIN tblYearlyIndex yi ON ya.PriceID = yi.PriceID
WHERE r.Region_Name IN ('England','Wales','Northern Ireland','Scotland')
	AND ya.[Year] IN (2013,2022,2023);

-- Top 10 highest and lowest difference between first time buyer price and former owner price:

WITH Buyer_Position_cte AS (
	SELECT
		r.Region_Name,
		yb.Area_Code,
		[Year],
		FORMAT(yb.[FTB_ Yearly_Average_Price],'C','en-gb') AS [FTB_ Yearly_Average_Price],
		FORMAT(yb.[FWO_Yearly_Average_Price],'C','en-gb') AS [FWO_Yearly_Average_Price],
		ROUND((FWO_Yearly_Average_Price / [FTB_ Yearly_Average_Price]) * 100,2) AS [Difference_Percentage]
	FROM tblYearlyBuyerPosition AS yb
		INNER JOIN tblRegions r ON yb.Area_Code = r.Area_Code
)
SELECT TOP 10 *
FROM Buyer_Position_cte
ORDER BY CAST([Difference_Percentage] AS DECIMAL) ASC;

WITH Buyer_Position_cte AS (
	SELECT
		r.Region_Name,
		yb.Area_Code,
		[Year],
		FORMAT(yb.[FTB_ Yearly_Average_Price],'C','en-gb') AS [FTB_ Yearly_Average_Price],
		FORMAT(yb.[FWO_Yearly_Average_Price],'C','en-gb') AS [FWO_Yearly_Average_Price],
		ROUND((FWO_Yearly_Average_Price / [FTB_ Yearly_Average_Price]) * 100,2) AS [Difference_Percentage]
	FROM tblYearlyBuyerPosition AS yb
		INNER JOIN tblRegions r ON yb.Area_Code = r.Area_Code
)
SELECT TOP 10 *
FROM Buyer_Position_cte
ORDER BY CAST([Difference_Percentage] AS DECIMAL) DESC;

-- Top 10 lowest price and most expensive regions for first time buyers:

SELECT
	TOP 10
	r.Region_Name,
	yb.Area_Code,
	FORMAT(AVG([FTB_ Yearly_Average_Price]),'C','en-gb') AS Total_Average_Price
FROM tblYearlyBuyerPosition AS yb
		INNER JOIN tblRegions r ON yb.Area_Code = r.Area_Code
WHERE yb.[FTB_ Yearly_Average_Price] <> -£0.10
GROUP BY
	r.Region_Name,
	yb.Area_Code
ORDER BY AVG([FTB_ Yearly_Average_Price]) ASC;

SELECT
	TOP 10
	r.Region_Name,
	yb.Area_Code,
	FORMAT(AVG([FTB_ Yearly_Average_Price]),'C','en-gb') AS Total_Average_Price
FROM tblYearlyBuyerPosition AS yb
		INNER JOIN tblRegions r ON yb.Area_Code = r.Area_Code
GROUP BY
	r.Region_Name,
	yb.Area_Code
ORDER BY AVG([FTB_ Yearly_Average_Price]) DESC;

-- Index:

SELECT TOP 10 *
FROM tblYearlyIndex
ORDER BY Yearly_Index DESC;

SELECT TOP 10 *
FROM tblYearlyIndex
ORDER BY Yearly_Index ASC;

-- House Price Index difference in UK from 2013 to 2023:

WITH IndexDiff_cte AS (
    SELECT
		r.Region_Name,
		Yearly_Index,
		[Year],
        LAG(Yearly_Index) OVER (PARTITION BY Region_Name ORDER BY Region_Name) AS Previous_index,
        ABS(Yearly_Index - LAG(Yearly_Index) OVER (PARTITION BY Region_Name ORDER BY Region_Name)) AS Index_difference
    FROM
        tblYearlyIndex AS yi
			INNER JOIN tblRegions r ON yi.Area_Code = r.Area_Code
)
SELECT
	TOP 10
	Region_Name,
    ROUND(Yearly_Index, 2) AS Yearly_Index,
	[Year],
    ROUND(Previous_index, 2) AS Previous_index,
    ROUND(Index_difference, 2) AS Index_difference
FROM IndexDiff_cte
WHERE Region_Name IN ('United Kingdom')
	AND [Year] BETWEEN 2013 AND 2023 
ORDER BY Index_difference DESC;

--United Kingdom and countries values ranked:

SELECT 
	r.Region_Name,
	y.Area_Code,
	FORMAT(Yearly_Average_Price, 'C','en-gb') AS Yearly_Average_Price,
	ROUND(yi.Yearly_Index, 2) AS Yearly_Index,
	ROW_NUMBER () OVER (PARTITION BY r.Region_Name ORDER BY Yearly_Average_Price DESC) AS Price_Rank,
	y.[Year]
FROM tblYearlyAverage AS y
	INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
	INNER JOIN tblYearlyIndex AS yi ON y.PriceID = yi.PriceID
WHERE r.Region_Name IN ('United Kingdom', 'England', 'Wales', 'Scotland', 'Northern Ireland');
