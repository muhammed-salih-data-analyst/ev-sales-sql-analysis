
CREATE TABLE ElectricVehicles (
    Vehicle_ID INT PRIMARY KEY,
    Manufacturer VARCHAR(50),
    Model VARCHAR(50),
    YEAR INT,
    Battery_Type VARCHAR(50),
    Battery_Capacity_kWh DECIMAL(5,2),
    Range_km INT,
    Charging_Type VARCHAR(50),
    Charge_Time_hr DECIMAL(4,2),
    Price_USD DECIMAL(10,2),
    Color VARCHAR(30),
    Country_of_Manufacture VARCHAR(50),
    Autonomous_Level INT,
    CO2_Emissions_g_per_km INT,
    Safety_Rating DECIMAL(2,1),
    Units_Sold_2024 INT,
    Warranty_Years INT)
    
SELECT * FROM electricvehicles

-- Market & Sales analyis

-- Top 5 manufacturers from 2015 to 2024:

SELECT Manufacturer,
SUM(Units_Sold_2024) AS Total_Units_Sold
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY Manufacturer
ORDER BY Total_Units_Sold DESC
LIMIT 5;

-- Market share percentage of each manufacturer in 2024 based on units sold:

SELECT 
Manufacturer,
ROUND(SUM(Units_Sold_2024)::NUMERIC, 2) AS Units_Sold,
ROUND(
(SUM(Units_Sold_2024) * 100.0 / 
(SELECT SUM(Units_Sold_2024) FROM electricvehicles WHERE YEAR = 2024))::NUMERIC, 2
) AS Market_Share_Percentage
FROM electricvehicles
WHERE YEAR = 2024
GROUP BY Manufacturer
ORDER BY Market_Share_Percentage DESC;


-- Year-over-Year growth rate in units sold by manufacturer:

SELECT a.YEAR,a.Units_Sold,
ROUND(CAST(
CASE 
WHEN b.Units_Sold IS NULL THEN NULL
ELSE ((a.Units_Sold::NUMERIC - b.Units_Sold::NUMERIC) / NULLIF(b.Units_Sold::NUMERIC, 0)) * 100
END
AS NUMERIC), 2) AS YoY_Growth_Percentage
FROM (
SELECT YEAR, SUM(Units_Sold_2024) AS Units_Sold
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR
) a
LEFT JOIN (
SELECT YEAR, SUM(Units_Sold_2024) AS Units_Sold
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR
) b ON a.YEAR = b.YEAR + 1
ORDER BY a.YEAR;


-- Best seller(model) per manufacturer in 2024

SELECT Manufacturer, Model, Units_Sold_2024
FROM 
(SELECT Manufacturer, Model, Units_Sold_2024,
 RANK() OVER (PARTITION BY Manufacturer ORDER BY Units_Sold_2024 DESC) AS Sales_Rank
 FROM electricvehicles
 WHERE YEAR = 2024)
 AS Ranked_Models
 WHERE Sales_Rank = 1
 ORDER BY Manufacturer;


-- Average units sold by color across all years:

SELECT Color,
AVG(Units_Sold_2024) AS Avg_Units_Sold
FROM electricvehicles
GROUP BY Color
ORDER BY Avg_Units_Sold DESC;


-- Changes Over Time

-- Change in average price of vehicles each year

SELECT YEAR, round( AVG(Price_USD),2) AS Avg_Price
FROM electricvehicles
GROUP BY YEAR
ORDER BY YEAR;

-- Change in total units sold annually:

SELECT YEAR, SUM(Units_Sold_2024) AS Total_Units_Sold
FROM electricvehicles
GROUP BY YEAR
ORDER BY YEAR;

-- Change in average autonomous level over years:

SELECT YEAR, round(AVG(Autonomous_Level),2) AS Avg_Autonomous_Level
FROM electricvehicles
GROUP BY YEAR
ORDER BY YEAR;



-- Change in average battery capacity over years

SELECT YEAR, ROUND(AVG(Battery_Capacity_kWh), 2) AS Avg_Battery_Capacity
FROM electricvehicles
GROUP BY YEAR
ORDER BY YEAR



-- change in charging time 

SELECT YEAR, ROUND(AVG(Charge_Time_hr)::NUMERIC, 2) AS Avg_Charge_Time
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR
ORDER BY YEAR;

-- Autonomous Driving and Safety Insights

-- Average Safety Rating by Year

SELECT YEAR, ROUND(AVG(Safety_Rating)::NUMERIC, 2) AS Avg_Safety_Rating
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR
ORDER BY YEAR

-- Top 5 Models with Highest Safety Rating in 2015 & 2024

(SELECT '2015' AS YEAR, Manufacturer, Model, Safety_Rating
 FROM electricvehicles
 WHERE YEAR = 2015
 ORDER BY Safety_Rating DESC
 LIMIT 5)
UNION ALL
(SELECT '2024' AS YEAR, Manufacturer, Model, Safety_Rating
 FROM electricvehicles
 WHERE YEAR = 2024
 ORDER BY Safety_Rating DESC
 LIMIT 5)
ORDER BY YEAR ASC, Safety_Rating DESC;

-- Correlation b/w Autonomous Level and Safety Rating (2024)

SELECT Autonomous_Level, ROUND(AVG(Safety_Rating)::NUMERIC, 2) AS Avg_Safety_Rating
FROM electricvehicles
WHERE YEAR = 2024
GROUP BY Autonomous_Level
ORDER BY Autonomous_Level;




-- 3-Year Moving Average of Sales (2015–2024)

SELECT 
YEAR,
ROUND(AVG(Avg_Yearly_Sales) OVER (
ORDER BY YEAR 
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
)::NUMERIC, 2) AS Moving_Avg_Sales
FROM (
SELECT 
YEAR, 
AVG(Units_Sold_2024) AS Avg_Yearly_Sales
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR
) yearly_sales
ORDER BY YEAR;



-- Category-wise safety rating by manufacturer


SELECT YEAR,
Manufacturer,
ROUND(AVG(Safety_Rating)::NUMERIC, 2) AS Avg_Safety_Rating
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR, Manufacturer
ORDER BY YEAR, Manufacturer;


--Relation between different factors affecting sales



-- correlation between price and sales

SELECT 
YEAR,
ROUND(AVG(Price_USD)::NUMERIC, 2) AS Avg_Price,
SUM(Units_Sold_2024) AS Total_Units_Sold
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR
ORDER BY YEAR;

-- correlation between warranty and sales

SELECT
AVG(Warranty_Years)::NUMERIC(5,2) AS Avg_Warranty_Years,
SUM(Units_Sold_2024) AS Total_Units_Sold
FROM electricvehicles
GROUP BY Manufacturer
ORDER BY Avg_Warranty_Years DESC;

-- Relation b/w Avg range_km & sales

SELECT 
YEAR,
ROUND(AVG(range_km)::NUMERIC, 2) AS Avg_km,
SUM(Units_Sold_2024) AS Total_Units_Sold
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR
ORDER BY YEAR


-- Preference Insights


-- percentage share of units sold per moodel


WITH RankedModels AS (
  SELECT
    YEAR,
    model,
    SUM(Units_Sold_2024) AS Units_Sold,
    ROUND(
      100.0 * SUM(Units_Sold_2024) / NULLIF(SUM(SUM(Units_Sold_2024)) OVER (PARTITION BY YEAR), 0)
    , 2) AS Percentage_Share,
    ROW_NUMBER() OVER (PARTITION BY YEAR ORDER BY SUM(Units_Sold_2024) DESC) AS rn
  FROM electricvehicles
  WHERE YEAR BETWEEN 2015 AND 2024
  GROUP BY YEAR, model
)

SELECT YEAR, model, Units_Sold, Percentage_Share
FROM RankedModels
WHERE rn = 1
ORDER BY YEAR;

-- data segmentation by price category


SELECT 
YEAR,
CASE
WHEN Price_USD < 30000 THEN 'Low'
WHEN Price_USD BETWEEN 30000 AND 60000 THEN 'Mid'
ELSE 'High'
END AS Price_Segment,
COUNT(*) AS Vehicle_Count,
ROUND(AVG(Price_USD), 2) AS Avg_Price
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR, Price_Segment
ORDER BY YEAR, Price_Segment;
;

-- Manufacturers by country

SELECT 
  country_of_manufacture,
  COUNT(DISTINCT Manufacturer) AS Number_of_Manufacturers
FROM electricvehicles
GROUP BY country_of_manufacture
ORDER BY Number_of_Manufacturers DESC
LIMIT 10;


-- Sales per colour

SELECT 
Color,
SUM(Units_Sold_2024) AS Total_Units_Sold
FROM electricvehicles
GROUP BY Color
ORDER BY Total_Units_Sold DESC LIMIT 5;


-- Sales volume per year by manufacturer

SELECT 
YEAR,
Manufacturer,
SUM(Units_Sold_2024) AS Total_Units_Sold,
CASE
WHEN SUM(Units_Sold_2024) >= 100000 THEN 'High Selling'
WHEN SUM(Units_Sold_2024) BETWEEN 10000 AND 99999 THEN 'Moderate Selling'
ELSE 'Low Selling'
END AS Sales_Category
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR, Manufacturer
ORDER BY YEAR, Total_Units_Sold DESC;


--Most preferred battery type (top 5)

SELECT
Battery_Type,
SUM(Units_Sold_2024) AS Total_Units_Sold
FROM electricvehicles
GROUP BY Battery_Type
ORDER BY Total_Units_Sold DESC LIMIT 5;

-- Category-wise average price per model


SELECT YEAR,
model,
ROUND(AVG(Price_USD)::NUMERIC, 2) AS Avg_Price,
SUM(Units_Sold_2024) AS Total_Units_Sold
FROM electricvehicles
WHERE YEAR BETWEEN 2015 AND 2024
GROUP BY YEAR, model
ORDER BY YEAR, model;