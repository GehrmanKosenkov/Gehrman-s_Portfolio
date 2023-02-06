/*

Exploring, Cleaning, Organizing And Analyzing agricultural data by USDA using SQL. Two tables used: 1. psd_grains_pulses 2.psd_oilseeds.
It should be noted that the tables have identical columns' names and those columns go in the same order. 

Mysql is used. 

Skills Used: CTE, JOIN, subqueries, PARTITION,CASE 


COMMENTS FOR GEHRMAN: 1)table names 2)code style 3)huighlighting and demonstrating sql results 

*/


-----------------------------------------------------------------------------

--------------Data Exploration

--First, learning about the contents of the tables using SELECT DISTINCT 

SELECT DISTINCT Commodity_Description
FROM hello.psd_grains_pulses

--Result:'Barley','Corn','Millet','Mixed Grain','Oats','Rice, Milled'

SELECT DISTINCT Commodity_Description
FROM hello.psd_oilseeds

--Result: 'Meal, Copra', 'Meal, Cottonseed', 'Meal, Fish','Meal, Palm Kernel', 'Meal, Peanut', 'Meal, Rapeseed', 'Meal, Soybean', 'Meal, Soybean (Local)', 'Meal, Sunflowerseed'

--Using SELECT DISTINCT for other important columns. 

--Market_Year: 1) psd_oilseeds: 1961 - 2021 2)psd_grains_pulses: 1960 - 2020 (slightly different!!!)

--Attribute_Description: 1) psd_oilseeds: 'Beginning Stocks', 'Crush', 'Domestic Consumption','Ending Stocks','Exports','Extr. Rate, 999.9999','Feed Waste Dom. Cons.','Food Use Dom. Cons.','Imports','Industrial Dom. Cons.','Production','SME','Total Distribution','Total Supply', 'Catch For Reduction'

--Attribute_Description: 1) psd_grains_pulses: 'Area Harvested','Beginning Stocks','Domestic Consumption','Ending Stocks','Exports','Feed Dom. Consumption','FSI Consumption','Imports','Production','Total Distribution','Total Supply','TY Exports','TY Imp. from U.S.','TY Imports','Yield','Milling Rate (.9999)','Rough Production'

--It's important to note that when it comes to Attribute_Description there are matching and not matching attributes. 

--Then applying SELECT DISTINCT to Unit_Description: 1) psd_oilseeds: '(1000 MT)', '(PERCENT)' 2) psd_grains_pulses: '(1000 HA)','(1000 MT)','(MT/HA)'

--(again! differences and similiarities) 

--Finally exploring countries. First, want to see how many countries represented in both tables using SELECT COUNT (DISTINCT) 

SELECT COUNT(DISTINCT Country_Name)
FROM hello.oilseeds_new

--result: 152 countries. 

SELECT COUNT(DISTINCT Country_Name)
FROM hello.full_psd_grains_pulses

--result: 150 countries - we should be aware of that when further working with the file!!! Do smth about it.


--Findings/conclusions: 


-----------------------------------------------------------------------------

-- Data Cleaning 

--Cheking if there are any nulls 

SELECT *
FROM hello.oilseeds_new
WHERE Commodity_Description IS NULL 
OR Country_Name IS NULL 
OR Market_Year IS NULL 
OR Attribute_Description IS NULL 
OR Value IS NULL

--Result no nulls. Same for the second table. We should be aware that there are zero's in values. 

--Checking for duplicates using CTE and PARTITION

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
FROM hello.oilseeds_new)

SELECT *
FROM row_num_CTE
WHERE row_num > 1

--#Result - no duplicates. Same for the second table.

--#adding final figure for more convenience 



--#After two tables joined - substring will be applied for more convenient formatting. 


ALTER TABLE hello.new_psd_grains_pulses
ADD final_figure integer

UPDATE hello.new_psd_grains_pulses
SET final_figure = Round((value*1000),1) 

#Dropping confusing calendar year 

ALTER TABLE hello.new_psd_grains_pulses
DROP COLUMN Calendar_Year


--#Findings/conclusions: 


-----------------------------------------------------------------------------

-- Inserting one table into another. For analysis purposes we need to make sure that countries, attribute description and years range match (change table names)

INSERT INTO hello.new_psd_grains_pulses
SELECT * FROM hello.oilseeds_new
WHERE hello.oilseeds_new.Market_Year IN (SELECT Market_Year FROM hello.new_psd_grains_pulses) 
AND hello.oilseeds_new.Country_Name IN (SELECT Country_Name FROM hello.new_psd_grains_pulses)
AND hello.oilseeds_new.Attribute_Description IN (SELECT Attribute_Description FROM hello.new_psd_grains_pulses)

--#Checking the correctness - commodity distinct and market year distinct and attribute distinct 

--#checking for duplicates - no duplicates 

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
FROM hello.new_psd_grains_pulses)

SELECT *
FROM row_num_CTE
WHERE row_num > 1

--#Changing the name of the table 

ALTER TABLE hello.psd_grains_pulses RENAME hello.grains_pulses_oilseeds

-----------------------------------------------------------------------------

-----Analysis 

--#Checking average production for each country for the last 20 years. 

ALTER TABLE hello.new_psd_grains_pulses
ADD Average_Production_2000_2022 integer;

UPDATE hello.new_psd_grains_pulses X
JOIN 
(SELECT Attribute_Description, Commodity_Description, Country_Name , AVG(value*1000) AS AVG_Production_20Y 
	FROM hello.new_psd_grains_pulses
	WHERE Market_Year > 2000 AND Attribute_Description = 'Production'
	GROUP BY Country_Name, Commodity_Description) Y
ON X.Country_Name = Y.Country_Name AND X.Attribute_Description = Y.Attribute_Description AND X.Commodity_Description = Y.Commodity_Description
SET Average_Production_2000_2022 = AVG_Production_20Y; 

--#Setting above_or_below_average column 

ALTER TABLE hello.new_psd_grains_pulses
ADD above_or_below_average text; 

UPDATE hello.new_psd_grains_pulses
SET above_or_below_average = CASE
			WHEN  (final_figure < Average_Production_2000_2022 AND Market_Year >= 2000 AND Attribute_Description = 'Production')
                        THEN 'BELOW AVERAGE'
			WHEN (final_figure > Average_Production_2000_2022 AND Market_Year >= 2000 AND Attribute_Description = 'Production') 
			THEN 'ABOVE AVERAGE'
                        WHEN (final_figure = Average_Production_2000_2022 AND Market_Year >= 2000 AND Attribute_Description = 'Production') 
			THEN 'NORMAL'
                        ELSE NULL
                        END;
			
			
			
--#Adding precipitation table using JOIN for further analysis in Python (NEED TO ADD UNIT OF MEASURE) 

ALTER TABLE hello.new_psd_grains_pulses
ADD Annual_Precipitation integer; 



SET SQL_SAFE_UPDATES = 0;
UPDATE hello.new_psd_grains_pulses X
JOIN
(SELECT Market_Year, Precipitation
 FROM hello.us_annual_precipitation) Y
 ON X.Market_Year = Y.Market_Year
 SET Annual_Precipitation = Precipitation