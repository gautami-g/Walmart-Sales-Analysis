-- Create database
CREATE DATABASE IF NOT EXISTS walmartSales;

-- Create table
CREATE TABLE sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT(2, 1)
);

-- Data cleaning
SELECT
	*
FROM sales;


-- Add the time_of_day column
SELECT
	time,
	(CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END) AS time_of_day
FROM sales;


ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

-- For this to work turn off safe mode for update
-- Edit > Preferences > SQL Edito > scroll down and toggle safe mode
-- Reconnect to MySQL: Query > Reconnect to server
UPDATE sales
SET time_of_day = (
	CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END
);

-- Add day_name column
SELECT
	date,
	DAYNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(date);


-- Add month_name column
SELECT
	date,
	MONTHNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales
SET month_name = MONTHNAME(date);


-- Generic Questions --
-- 1. How many unique cities does the data have?
SELECT 
	DISTINCT city
FROM sales;

-- 2. In which city is each branch?
SELECT 
	DISTINCT city,
    branch
FROM sales;

-- Business Questions --
-- a. Questions related to Products --

-- 1.How many unique product lines does the data have?
SELECT
	DISTINCT product_line
FROM sales;

-- 2.What is the most selling product line?
SELECT
	SUM(quantity) as qty,
    product_line
FROM sales
GROUP BY product_line
ORDER BY qty DESC limit 1;

-- 3. What is the total revenue by month?
SELECT
	month_name AS month,
	SUM(total) AS total_revenue
FROM sales
GROUP BY month_name 
ORDER BY total_revenue;
 
 -- 4. What month had the largest COGS?
select month_name as month, sum(cogs) as cogs
from sales
group by month_name
order by cogs desc limit 1;

-- 5.What product line had the largest revenue?
select product_line, sum(total) as total_rev
from sales
group by 1
order by total_rev desc limit 1;

-- 6. What is the city with the largest revenue?
select branch,city, sum(total) as total_rev
from sales
group by branch,city
order by total_rev desc limit 1;

-- 7. What product line had the largest VAT?
select product_line, avg(tax_pct) as VAT
from sales
group by product_line
order by VAT desc limit 1;

-- 8. Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales
select avg(quantity) as avg_qnt
from sales;

select product_line, case
when avg(Quantity) > 6 then 'Good'
else 'Bad'
end as remark
from sales
group by product_line;

-- 9. Which branch sold more products than average product sold?
SELECT branch, 
       COUNT(quantity) AS products_sold 
FROM sales 
GROUP BY branch 
HAVING COUNT(quantity) > 
      (SELECT AVG(products_sold) 
       FROM (SELECT COUNT(quantity) AS products_sold 
       
             FROM sales 
             GROUP BY branch) AS subquery);
             
-- 10.What is the most common product line by gender?
with ranked_products as(select gender,product_line, 
count(product_line) as product_count,
rank() over (partition by gender order by count(product_line)desc) as rnk
from sales
group by gender,product_line
)
select gender, product_line,product_count
from ranked_products
where rnk=1;

-- 11. What is the average rating of each product line?
select product_line, avg(rating) as avgerage
from sales
group by product_line
order by avg(rating) desc;

-- b. Questions related to customers --

-- 1.How many unique customer types does the data have?
SELECT
	DISTINCT customer_type
FROM sales;

-- 2.How many unique payment methods does the data have?
select distinct payment from sales;

-- 3. What is the most common customer type?
select customer_type, count(*)
from sales
group by customer_type
order by count(*) desc;

-- 4. Which customer type buys the most?
select customer_type, count(*)
from sales
group by customer_type
order by count(*) desc;

-- 5.  What is the gender of most of the customers?
SELECT
	gender,
	COUNT(*) as gender_cnt
FROM sales
GROUP BY gender
ORDER BY gender_cnt DESC;

-- 6. What is the gender distribution per branch?
select branch, gender,count(gender) as gender_count
from sales
group by branch, gender
order by branch, gender desc; 

-- Interpretation: Gender per branch is more or less the same hence, I don't think has an effect of the sales per branch and other factors.

-- 7. Which time of the day do customers give most ratings?
select time_of_day , avg(rating) as avg_rating
from sales
group by time_of_day
order by avg_rating desc;
-- Interpretation: Looks like time of the day does not really affect the rating, its more or less the same rating each time of the day


-- 8. Which time of the day do customers give most ratings per branch?
with ratingcounts as (select branch,time_of_day,
count(rating) as rating_count,
rank () over(partition by branch order by count(rating) desc) as rnk
from sales
where rating is not null
group by branch,time_of_day
)
select branch,time_of_day,rating_count
from ratingcounts
where rnk=1;

-- 9. Which day of the week has the best avg ratings?
select day_name, avg(rating)
from sales
group by day_name
order by avg(rating) desc;

-- 10. Which day of the week has the best average ratings per branch?
WITH AvgRatings AS (
    SELECT branch, 
           day_name, 
           AVG(rating) AS avg_rating,
           RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rnk
    FROM sales
    WHERE rating IS NOT NULL
    GROUP BY branch, day_name
)
SELECT branch, day_name, avg_rating
FROM AvgRatings
WHERE rnk = 1;

-- c. Questions related to Walmart Sales --

-- 1. Number of sales made in each time of the day per weekday?
SELECT day_name, 
       time_of_day, 
       COUNT(invoice_id) AS sales_count
FROM sales
GROUP BY day_name, time_of_day
ORDER BY day_name, sales_count DESC;

-- 2. Which of the customer types brings the most revenue?
select customer_type, sum(total) as total_revenue
from sales
group by customer_type
order by sum(total) desc limit 1;

-- 3. Which city has the largest tax/VAT percent?
SELECT city, ROUND(AVG(tax_pct), 2) AS avg_tax_pct
FROM sales
GROUP BY city 
ORDER BY avg_tax_pct DESC;

-- 4. Which customer type pays the most in VAT?
SELECT customer_type, AVG(tax_pct) AS total_tax
FROM sales
GROUP BY customer_type
ORDER BY total_tax desc limit 1;

-- END --




