SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';
CREATE TABLE city_day (
    City varchar(50),
    Date date,
    `PM2.5` float,
    PM10 float,
    NO float,
    NO2 float,
    NOx float,
    NH3 float,
    CO float,
    SO2 float,
    O3 float,
    Benzene float,
    Toulene float,
    Xylene float,
    AQI float,
    AQI_Bucket varchar(50)
);

drop table city_day;

LOAD DATA LOCAL INFILE 'C:/Users/Rishita/OneDrive/Desktop/FTN/Batch7 project/city_day.csv'
INTO TABLE city_day
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(City, Date, `PM2.5`, PM10, NO,NO2, NOx, NH3, CO, SO2, O3, Benzene, Toulene, Xylene, AQI, AQI_Bucket);

select * from city_day;

-- 1. Validating Datatypes
desc city_day;

-- 2. Counting zeros and Null values
SELECT
    sum(case WHEN `PM2.5` IS NULL OR `PM2.5` = 0 THEN 1 ELSE 0 END) AS pm25_missing,
    sum(case WHEN PM10 IS NULL OR PM10 = 0 THEN 1 ELSE 0 END) AS pm10_missing,
    sum(case WHEN NO IS NULL OR NO = 0 THEN 1 ELSE 0 END) AS no_missing,
    sum(case WHEN NO2 IS NULL OR NO2 = 0 THEN 1 ELSE 0 END) AS no2_missing,
    sum(case WHEN NOx IS NULL OR NOx = 0 THEN 1 ELSE 0 END) AS nox_missing,
    sum(case WHEN NH3 IS NULL OR NH3 = 0 THEN 1 ELSE 0 END) AS nh3_missing,
    sum(case WHEN CO IS NULL OR CO = 0 THEN 1 ELSE 0 END) AS co_missing,
    sum(case WHEN SO2 IS NULL OR SO2 = 0 THEN 1 ELSE 0 END) AS so2_missing,
    sum(case WHEN O3 IS NULL OR O3 = 0 THEN 1 ELSE 0 END) AS o3_missing,
    sum(case WHEN Benzene IS NULL OR Benzene = 0 THEN 1 ELSE 0 END) AS benzene_missing,
    sum(case WHEN Toulene IS NULL OR Toulene = 0 THEN 1 ELSE 0 END) AS toulene_missing,
    sum(case WHEN Xylene IS NULL OR Xylene = 0 THEN 1 ELSE 0 END) AS xylene_missing,
    sum(case WHEN AQI IS NULL OR AQI = 0 THEN 1 ELSE 0 END) AS aqi_missing
FROM city_day;

select count(AQI_Bucket) from city_day where AQI_Bucket is null;

-- 3.Creating Raw Data
create table city_day_raw as select * from city_day;
select * from city_day_raw;

select count(*) from city_day;

update city_day set AQI_Bucket=NULL where AQI_Bucket='';

select * from city_day;

CREATE TABLE city_day_clean (
    City VARCHAR(100),
    Date DATE,
    `PM2.5` FLOAT,
    PM10 FLOAT,
    NO FLOAT,
    NO2 FLOAT,
    NOx FLOAT,
    NH3 FLOAT,
    CO FLOAT,
    SO2 FLOAT,
    O3 FLOAT,
    Benzene FLOAT,
    Toulene FLOAT,
    Xylene FLOAT,
    AQI FLOAT,
    AQI_Bucket VARCHAR(50),
    Month INT,
    Monthly_AQI FLOAT,
    PM25_PM10_Ratio FLOAT
);
select * from city_day_clean;

create table city_summary as 
select City,avg(AQI) as avg_city_aqi from city_day_clean
group by City;
select * from city_summary;

-- Join AQI data with derived city/month tables
select c.City,c.Date,c.AQI,cs.avg_city_aqi from city_day_clean c join city_summary  cs 
on c.City=cs.City;

-- Identify cities with AQI above national average
select City,round(avg(AQI),2) as avg_city_aqi from city_day_clean 
group by City
having avg(AQI)>(select avg(AQI) from city_day_clean);

-- Rank cities by AQI within each year
select year(Date) as year,City,avg(AQI) as avg_yearly_aqi ,rank() over(partition by year(Date) order by avg(AQI)
desc) as city_rank
from city_day_clean
group by year(Date),City;

-- Compute moving average AQI per city
select City,Date,AQI,avg(AQI) over(partition by City order by Date rows between 6 preceding and current row)
as moving_avg_7days 
from city_day_clean
order by City,Date;