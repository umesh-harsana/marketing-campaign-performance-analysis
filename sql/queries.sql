-- ==================================================================================================================
-- Title: Marketing Campaign Analysis
-- Author: Umesh Harsana
-- ==================================================================================================================

-- Creating database

CREATE DATABASE marketing_project;
USE marketing_project;

-- ---------------------------------------------TABLE--------------------------------------------------------------

-- 1. Creating and defining table

CREATE TABLE campaigns (
	date DATE,
    campaign_id INT,
    channel VARCHAR(50),
    campaign_type VARCHAR(50),
    region VARCHAR(20),
    device VARCHAR(20),
    impressions INT,
    clicks INT,
    conversions INT,
    cost FLOAT,
    revenue FLOAT,
    ctr FLOAT,
    conversion_rate FLOAT,
    roi FLOAT
);
-- ----------------------------------

-- 2. Importing data into the table

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/marketing_campaign_dataset_12k.csv'
INTO TABLE campaigns
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM campaigns LIMIT 5;

-- -------------------------------------------DATA CLEANING--------------------------------------------------------

-- 1. checking duplicates

-- count of rows

SELECT COUNT(*) FROM campaigns;

-- count of distinct rows

SELECT DISTINCT COUNT(*) FROM campaigns;

-- DISTINCT IS EQUAL TO TOTAL WHICH MEANS NO DUPLICATES
-- -------------------------

-- 2. checking null values

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN impressions IS NULL THEN 1 ELSE 0 END) AS null_impressions,
    SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS null_clicks,
    SUM(CASE WHEN conversions IS NULL THEN 1 ELSE 0 END) AS null_conversions,
    SUM(CASE WHEN cost IS NULL THEN 1 ELSE 0 END) AS null_cost,
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue
FROM campaigns;

-- NO NULL VALUES
-- ------------------------

-- 3. checking logical consistency

SELECT COUNT(*)
FROM campaigns
WHERE clicks > impressions 
OR conversions > clicks;

SELECT COUNT(*)
FROM campaigns
WHERE cost < 0 OR revenue < 0;

SELECT COUNT(*)
FROM campaigns
WHERE roi < -1;

-- NO INCONSISTENCY FOUND
-- -----------------------

-- 4. recalculate metrics

SELECT 
    campaign_id,
    (clicks / impressions) AS ctr_calc,
    ctr,
    (conversions / clicks) AS conversion_rate_calc,
    conversion_rate,
    ((revenue - cost) / cost) AS roi_calc,
    roi
FROM campaigns
LIMIT 10;

-- ALL VALUES MATCHED

-- -------------------------------------------DATA ANALYSIS-----------------------------------------------------

-- 1. ROI

SELECT 
    MIN(roi), 
    MAX(roi), 
    AVG(roi)
FROM campaigns;

-- Min = -0.97, Max = 69.31, Avg = 1.36
-- THIS SHOWS THAT AVERAGE IS IMPACTED BY EXCEPTIONALLY HIGH VALUES

-- checking roi levels
SELECT 
    CASE 
        WHEN roi < 0 THEN 'Loss-making'
        WHEN roi BETWEEN 0 AND 1 THEN 'Low ROI'
        WHEN roi BETWEEN 1 AND 3 THEN 'Moderate ROI'
        WHEN roi BETWEEN 3 AND 8 THEN 'High ROI'
        ELSE 'Very High ROI'
    END AS roi_category,
    COUNT(*) AS campaigns
FROM campaigns
GROUP BY roi_category;

SELECT AVG(roi) FROM campaigns WHERE roi < 8;

-- COUNT OF Very High Roi = 577
-- AVG WITHOUT Very High Roi = 0.61
-- AVG ROI AFTER REMOVING TOP 5%  IS LESS THEN HALF OF ORIGINAL AVG
-- THIS SHOWS THAT THE DATA IS SKEWED AND HIGH VALUES IMPACT THE AVG

SELECT 
    channel,
    COUNT(*) AS high_roi_campaigns
FROM campaigns
WHERE roi > 8
GROUP BY channel
ORDER BY high_roi_campaigns DESC;

-- 485 OUT OF 577 Very High Roi CAMPAIGNS ARE FROM EMAIL (>80%)

SELECT 
    channel,
    AVG(cost) AS avg_cost,
    AVG(revenue) AS avg_revenue,
    AVG(roi) AS avg_roi
FROM campaigns
GROUP BY channel;

-- LOW COST IN EMAIL CAMPAIGNS (LOWEST) IS THE REASON FOR HIGH ROI (HIGHEST)
-- -------------------------

-- 2. Channel-wise Performance

SELECT 
    channel,
    SUM(cost) AS total_cost,
    SUM(revenue) AS total_revenue,
    ROUND(((SUM(revenue) - SUM(cost)) / SUM(cost)) * 100, 2) AS roi
FROM campaigns
GROUP BY channel
ORDER BY roi DESC;

-- Email - very high ROI (~738%), very low cost
-- Display / Affiliate / YouTube - profitable (good ROI range)
-- Instagram - barely profitable (~15%)
-- Facebook - slightly loss-making
-- Google Search - heavily loss-making (~-50%)

SELECT 
    channel,
    SUM(cost) * 100 / (SELECT SUM(cost) FROM campaigns) AS cost_share,
    SUM(revenue) * 100 / (SELECT SUM(revenue) FROM campaigns) AS revenue_share
FROM campaigns
GROUP BY channel;

-- Google Search CONSUMES > 60% OF THE TOTAL BUDGET AND CONTRIBUTES ONLY 35% OF REVENUE
-- Email CONSUMES < 1% AND CONTRIBUTES 8%

-- --------------------

-- 3. Monthly Revenue Trend

SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(revenue) AS total_revenue,
    SUM(cost) AS total_cost
FROM campaigns
GROUP BY month
ORDER BY month;

-- CAMPAIGNS ARE CONSISTENTLY LOSS MAKING

-- ---------------------

-- 4. Conversion Rate by Channel

SELECT 
    channel,
    ROUND(SUM(conversions) / SUM(clicks) * 100, 2) AS conversion_rate
FROM campaigns
GROUP BY channel
ORDER BY conversion_rate DESC;

-- ALMOST IDENTICAL ACROSS ALL CHANNELS

-- 5. Worst Campaigns

SELECT 
    campaign_id,
    SUM(cost) AS total_cost,
    SUM(revenue) AS total_revenue,
    ROUND(((SUM(revenue) - SUM(cost)) / SUM(cost)) * 100, 2) AS roi
FROM campaigns
GROUP BY campaign_id
HAVING roi < 0
ORDER BY roi ASC
LIMIT 10;

SELECT channel, COUNT(*) 
FROM campaigns
WHERE campaign_id IN (105207,107987,101295,108036,107029,102373,106654,106782,102931,111794)
GROUP BY channel;

-- BOTTOM 10 WORST PERFORMING CAMPAIGN ARE ALL FROM Google Search