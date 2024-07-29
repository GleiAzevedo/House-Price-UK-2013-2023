# House Price UK - 2013-2023

Is the price of the house really increasing? If yes, for how much? Is this true for all regions? The focus of this analysis is the UK house price series from 2013 to 2023, where we can answer all these questions and much more.

# Dataset description

For this project the datasets used can be found in the [UK government website](https://www.gov.uk/government/statistical-data-sets/uk-house-price-index-data-downloads-december-2023?utm_medium=GOV.UK&utm_source=summary&utm_campaign=UK_HPI_Summary&utm_term=9.30_14_02_24&utm_content=download_data). The data is available at a national and regional level, as well as counties, local authorities and London boroughs.
The database used here presents 4 tables:
+ The tblYearlyAverage contains Average House price; 
+ The Average House Price and House Price Index by buyer position, whether it is a first time buyer or a previous owner, can be found in the tblYearlyBuyerPosition;
+ The general House Price Index is another attribute studied, in the table tblYearlyIndex;
+ In the process of data cleaning and modeling, a Regions table was also created.

For the purposes of this analysis, we studied annual values ​​from 2013 to 2023, but it is interesting to note that the datasets available goes back to 1968, for average price, and they are broken down in monthly values.
Belows a diagram of the database:

PICTURE

# Tools

Microsoft SQL Server Management Studios for data analysis - View [SQL Scripts]

# Key Points Explored

1 - Average price and House Price Index in the United Kingdom between 2013 and 2023:

'''
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
'''

PICTURE

Although this point focuses on the values ​​of the United Kingdom, the code above returns the values ​​of all countries that are part of the United Kingdom.
The average house price has increased by £111,692 or 39% from 2013 to 2023.

2 - Minimum and maximum average price, across all regions, between 2013 and 2023:

```
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
'''
PICTURE

As expected, the minimum average price is at the beginning of the historical series we are analyzing, in 2013, in the town of Burnley in Lancashire, England. Kensington and Chelsea has the highest average house price, in 2023. It is a royal borough in inner London and in addition to Kensington Palace, it has embassies from several countries, taking the average price to another level. For better comparisson, we can see below that the average house price in Kensington and Chelsea in 2013 it was £1,126,572.70, 16 times higher than that recorded in Burnley.

PICTURE

'''
SELECT
	y.Area_Code,
	r.Region_Name,
	FORMAT(Yearly_Average_Price,'C','en-gb') AS [Yearly_Average_Price,]
FROM tblYearlyAverage y
	INNER JOIN tblRegions r ON y.Area_Code = r.Area_Code
WHERE r.Region_Name = 'Kensington and Chelsea'
	AND [Year] = 2013
'''

3 - The 10 regions with the highest average value and the 10 with the lowest value:

'''
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
'''
PICTURE

All the regions in the first block are in the London area. While the second one shows a bit more of variety, presenting regions in England, Scotland and Wales.

4 - Average price, index, first time buyer and former owner price in 2013, 2022 and 2023:

'''
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
'''

PICTURE

> [!NOTE]
> We don't have data for first time buyer and former owner occupier average price for Northern Ireland.

England consistently has the highest average prices across all categories, followed by Wales and Scotland. On the other hand, although Northern Ireland has the lowest average price among all countries in the United Kingdom, its Index is the highest in 2023 and presents the largest increase compare to 2013, 75%.

5 - Top 10 highest and lowest difference between first time buyer price and former owner price:

'''
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
'''
PICTURE

There are many other aspects, which are not part of the dataset studied here, that would probably help us understand the above results. However, can we speculate that perhaps London's intense and unique property market, where there is a huge demand and not quite the same number of new developments, does not leave much room for a price difference for First time buyers and Former owner occupier? Indeed, the top 10 highest average price for First time buyers are in London, as shown below.

'''
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
'''

PICTURE

6 - House Price Index difference in UK from 2013 to 2023:

'''
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
'''

PICTURE

Although the Housing Price Index saw its biggest increase after Covid-2019, mainly in 2021 and 2022, at the other extreme, 2023 has the smallest increase in the index, reflecting the political and economic instability of the period - the invasion of Ukraine by Russia in 2022, the inflation it brought with it and rising interest rates for example.