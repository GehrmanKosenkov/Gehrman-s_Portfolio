/*

Exploring, Cleaning, Organizing And Analyzing agricultural data by USDA using MySQL. Two tables were used: 1. psd_grains_pulses 2.psd_oilseeds.
It should be noted that the tables have identical columns' names and the colums are arranged in identical order.

Skills Used: CTE, JOIN, Subqueries, PARTITION BY,CASE Expression, Aggregate Functions, String Slicing 


COMMENTS FOR GEHRMAN: 1)table names  

*/


--------------------Data Exploration-------------------------

--First, I needed to learn about the content of both table, in particular: Commodity_Description, Market_Year, Attribute_Description, Unit_Description.
--SELECT DISTINCT was used for this purpose. 

SELECT DISTINCT Commodity_Description
FROM hello.psd_oilseeds

--Result:'Barley','Corn','Millet','Mixed Grain','Oats','Rice, Milled'

SELECT DISTINCT Commodity_Description
FROM hello.psd_grains_pulses

--Result: 'Meal, Copra', 'Meal, Cottonseed', 'Meal, Fish','Meal, Palm Kernel', 'Meal, Peanut', 'Meal, Rapeseed', 'Meal, Soybean', 'Meal, Soybean (Local)', 'Meal, Sunflowerseed'

--Then I used SELECT DISTINCT for other columns. 

--Market_Year: 1) psd_oilseeds: 1961 - 2021 
--Market_Year: 2)psd_grains_pulses: 1960 - 2020
--(The difference should be taken into account!)

--Attribute_Description: 1) psd_oilseeds: 'Beginning Stocks', 'Crush', 'Domestic Consumption','Ending Stocks','Exports','Extr. Rate, 999.9999','Feed Waste Dom. Cons.','Food Use Dom. Cons.','Imports','Industrial Dom. Cons.','Production','SME','Total Distribution','Total Supply', 'Catch For Reduction'
--Attribute_Description: 2) psd_grains_pulses: 'Area Harvested','Beginning Stocks','Domestic Consumption','Ending Stocks','Exports','Feed Dom. Consumption','FSI Consumption','Imports','Production','Total Distribution','Total Supply','TY Exports','TY Imp. from U.S.','TY Imports','Yield','Milling Rate (.9999)','Rough Production'
--(It should be noted that some attribute descriptions are the same in both tables and some are different). 

--Unit_Description: 1) psd_oilseeds: '(1000 MT)', '(PERCENT)' 
--Unit_Description: 2) psd_grains_pulses: '(1000 HA)','(1000 MT)','(MT/HA)'
--(It should be noted that some attribute descriptions are the same in both tables and some are different). 
 
--Finally, exploring Country_Names. First, I wanted to see how many countries represented in both tables. Used SELECT COUNT (DISTINCT) for this purpose.

SELECT COUNT(DISTINCT Country_Name)
FROM hello.psd_oilseeds

--result: 152 countries. 

SELECT COUNT(DISTINCT Country_Name)
FROM hello.psd_grains_pulses

--result: 150 countries 
--(152 and 150. The difference should be taken into account!)


--Findings/conclusions:
--It was found that the two tables represent data on different commodities. 
--The tables have some matching content and some content that differ (e.g. Unit_Description in psd_oilseeds: '(1000 MT)', '(PERCENT)' whereas Unit_Description in psd_grains_pulses: '(1000 HA)','(1000 MT)','(MT/HA)'. Both tables have '1000 MT' the rest of the content in Unit_Desrciption differs).
--The above points are crticial as the tables will be merged at a further stage of this analysis project. Hence, the analysis will need to be focused on the overlapping content. 



--------------------Data Cleaning -------------------------

--Cheking if there are any nulls in the tables 

SELECT *
FROM hello.psd_oilseeds
WHERE Commodity_Description IS NULL 
      OR Country_Name IS NULL 
      OR Market_Year IS NULL 
      OR Attribute_Description IS NULL 
      OR Value IS NULL

--Result - no nulls. Same for psd_grains_pulses. However, we should be aware that there are some zeros in the 'Values' column. 

--Checking if there are any duplicates in the tables using CTE and PARTITION BY. 

WITH row_num_CTE AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY 
		    Commodity_Description,
                    Country_Name,
                    Market_Year,
                    Attribute_Description,
                    Value 
                    ORDER BY Value
                    ) row_num
FROM hello.psd_oilseeds)

SELECT *
FROM row_num_CTE
WHERE row_num > 1

--#Result - no duplicates. Same for psd_grains_pulses.

--#For more convenience, numbers in the 'Value' column needs to be multiplied by 1000 to see the final numbers. This will be done in both tables. 

ALTER TABLE hello.psd_oilseeds
ADD Final_figure integer;

UPDATE hello.psd_oilseeds
SET Final_figure = ROUND((value*1000),1)


--As Calendar_Year displays incorrect and confusing data - this will be dropped in both tables.

ALTER TABLE hello.psd_oilseeds
DROP COLUMN Calendar_Year

--NOTE:More data organization will be done at the end of the project.


--#Findings/conclusions: 
--No Nulls.
--Some zero values in the 'Values' column which however doesn't affect the analysis. 
--No duplications. 
--'Final_figure' column added for more convenience. 
--'Calendar_Year' column dropped for more convenience. 


--------------------Inserting One Table Tnto Another -------------------------

-- INSERT INTO used. For the analysis purposes we need to make sure that only matching countries, attribute descriptions and years match appear in the updated table.

INSERT INTO hello.psd_grains_pulses
SELECT * FROM hello.psd_oilseeds
         WHERE hello.psd_oilseeds.Market_Year IN (SELECT Market_Year FROM hello.psd_grains_pulses) 
         AND hello.psd_oilseeds.Country_Name IN (SELECT Country_Name FROM hello.psd_grains_pulses)
         AND hello.psd_oilseeds.Attribute_Description IN (SELECT Attribute_Description FROM hello.psd_grains_pulses)

--Checking if the tables were merged correctly: 

SELECT DISTINCT Commodity_Description
FROM hello.psd_grains_pulses

--Result of the query: 'Barley','Corn','Millet','Mixed Grain','Oats','Rice, Milled','Meal, Copra','Meal, Cottonseed','Meal, Fish','Meal, Palm Kernel','Meal, Peanut','Meal, Rapeseed','Meal, Soybean','Meal, Soybean (Local)','Meal, Sunflowerseed'

SELECT DISTINCT Market_Year
FROM hello.psd_grains_pulses

--Result of the query: 1960 - 2020 

SELECT DISTINCT Attribute_Description 
FROM hello.psd_grains_pulses
--(HERE'S IN THE MISTAKE THAT NEEDS TO BE FIXED. Milling rate shouldn't be there)
--Result of the query:'Area Harvested'
'Beginning Stocks'
'Domestic Consumption'
'Ending Stocks'
'Exports'
'Feed Dom. Consumption'
'FSI Consumption'
'Imports'
'Production'
'Total Distribution'
'Total Supply'
'TY Exports'
'TY Imp. from U.S.'
'TY Imports'
'Yield'
'Milling Rate (.9999)'
'Rough Production'

--Checking for duplicates 

WITH row_num_CTE AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY 
		    Commodity_Description,
                    Country_Name,
                    Market_Year,
                    Attribute_Description,
                    Value 
                    ORDER BY Value
                    ) row_num
FROM hello.psd_grains_pulses)

SELECT *
FROM row_num_CTE
WHERE row_num > 1

--Result: No duplicates. 

--Changing the name of the table 

ALTER TABLE hello.psd_grains_pulses RENAME hello.grains_pulses_oilseeds

--#Findings/conclusions: 


--------------------Analysis -------------------------


--Calculating average annual production for each country for the last 20 years. 

ALTER TABLE hello.grains_pulses_oilseeds
ADD Average_Production_2000_2022 integer;

UPDATE hello.grains_pulses_oilseeds X
JOIN 
(SELECT Attribute_Description, Commodity_Description, Country_Name , AVG(value*1000) AS AVG_Production_20Y 
	FROM hello.grains_pulses_oilseeds
	WHERE Market_Year >= 2000 AND Attribute_Description = 'Production'
	GROUP BY Country_Name, Commodity_Description) Y
ON X.Country_Name = Y.Country_Name AND X.Attribute_Description = Y.Attribute_Description AND X.Commodity_Description = Y.Commodity_Description
SET Average_Production_2000_2022 = AVG_Production_20Y; 

--Adding above_or_below_average column indicating if the production volume was above average, below average or normal. This is important for further analysis.

ALTER TABLE hello.grains_pulses_oilseeds
ADD above_or_below_average text; 

UPDATE hello.grains_pulses_oilseeds
SET above_or_below_average = CASE
			WHEN  (final_figure < Average_Production_2000_2022 AND Market_Year >= 2000 AND Attribute_Description = 'Production')
                        THEN 'BELOW AVERAGE'
			WHEN (final_figure > Average_Production_2000_2022 AND Market_Year >= 2000 AND Attribute_Description = 'Production') 
			THEN 'ABOVE AVERAGE'
                        WHEN (final_figure = Average_Production_2000_2022 AND Market_Year >= 2000 AND Attribute_Description = 'Production') 
			THEN 'NORMAL'
                        ELSE NULL
                        END;
			
			
			
--Joining US annual precipitation table to grains_pulses_oilseeds. Precipitation data for US will be needed for further correlation analysis in Python.

ALTER TABLE hello.new_psd_grains_pulses
ADD Annual_Precipitation_Inches integer; 



SET SQL_SAFE_UPDATES = 0;
UPDATE hello.grains_pulses_oilseeds X
JOIN 
 (SELECT Market_Year, Precipitation,Country_Name, Attribute_Description
  FROM hello.us_precipitation) Y
ON X.Market_Year = Y.Market_Year AND X.Country_Name = Y.Country_Name  AND X.Attribute_Description = Y.Attribute_Description
SET Annual_Precipitation_Inches  = Precipitation;


--Final data cleaning and organization 

-- Adding more convenient Unit_Description

UPDATE hello.grains_pulses_oilseeds
SET Unit_Description = CASE
		       WHEN Unit_Description = '(MT/HA)' THEN SUBSTRING(Unit_Description,2,5)
                       ELSE SUBSTRING(Unit_Description,7,2)
		       END;

--Dropping Value as not needed.


ALTER TABLE hello.grains_pulses_oilseeds
DROP COLUMN Value


-- reorganize column 

ALTER TABLE hello.grains_pulses_oilseeds
MODIFY COLUMN Unit_Description TEXT AFTER final_figure;

 
--Now the file is ready for further correlation analysis in Python
 
