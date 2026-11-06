-- Q1. How many unique post types are found in fact_content?
SELECT
    COUNT(DISTINCT post_type) AS unique_post_type_count,
    GROUP_CONCAT(DISTINCT post_type ORDER BY post_type SEPARATOR ', ') AS post_type_names
FROM fact_content;


-- Q2. What are the highest and lowest recorded impressions for each post type?
SELECT
    post_type,
    MAX(impressions) AS highest_impressions,
    MIN(impressions) AS lowest_impressions
FROM fact_content
GROUP BY post_type
ORDER BY post_type;


-- Q3. Filter weekend posts published in March and April
SELECT
    fc.*,
    dd.month_name,
    dd.weekday_name,
    dd.weekday_or_weekend
FROM fact_content AS fc
JOIN dim_dates AS dd
    ON fc.date = dd.date
WHERE dd.month_name IN ('March', 'April')
  AND dd.weekday_or_weekend = 'Weekend'
ORDER BY fc.date;


/* 4. Create a report to get the statistics for the account. The final output
includes the following fields:
• month_name
• total_profile_visits
• total_new_followers  */

SELECT
    dd.month_name,
    SUM(fa.profile_visits) AS total_profile_visits,
    SUM(fa.new_followers) AS total_new_followers
FROM fact_account AS fa
JOIN dim_dates AS dd
    ON fa.date = dd.date
GROUP BY MONTH(dd.date), dd.month_name
ORDER BY MONTH(dd.date);


/* 5. Write a CTE that calculates the total number of 'likes’ for each
'post_category' during the month of 'July' and subsequently, arrange the
'post_category' values in descending order according to their total likes. */

WITH july_likes AS (
    SELECT
        fc.post_category,
        SUM(fc.likes) AS total_likes
    FROM fact_content AS fc
    JOIN dim_dates AS dd
        ON fc.date = dd.date
    WHERE dd.month_name = 'July'
    GROUP BY fc.post_category
)
SELECT
    post_category,
    total_likes
FROM july_likes
ORDER BY total_likes DESC;


/* 6. Create a report that displays the unique post_category names alongside
their respective counts for each month. The output should have three
columns:
• month_name
• post_category_names
• post_category_count
Example:
• 'April', 'Earphone,Laptop,Mobile,Other Gadgets,Smartwatch', '5'
• 'February', 'Earphone,Laptop,Mobile,Smartwatch', '4 */

SELECT
    dd.month_name,
    GROUP_CONCAT(
        DISTINCT fc.post_category
        ORDER BY fc.post_category
        SEPARATOR ','
    ) AS post_category_names,
    COUNT(DISTINCT fc.post_category) AS post_category_count
FROM fact_content AS fc
JOIN dim_dates AS dd
    ON fc.date = dd.date
GROUP BY MONTH(dd.date), dd.month_name
ORDER BY MONTH(dd.date);


/* 7. What is the percentage breakdown of total reach by post type? The final
output includes the following fields:
• post_type
• total_reach
• reach_percentage */

SELECT
    post_type,
    SUM(reach) AS total_reach,
    ROUND(
        100.0 * SUM(reach) /
        NULLIF((SELECT SUM(reach) FROM fact_content), 0),
        2
    ) AS reach_percentage
FROM fact_content
GROUP BY post_type
ORDER BY total_reach DESC;


/* 8. Create a report that includes the quarter, total comments, and total
saves recorded for each post category. Assign the following quarter
groupings:
(January, February, March) → “Q1”
(April, May, June) → “Q2”
(July, August, September) → “Q3”
The final output columns should consist of:
• post_category
• quarter
• total_comments
• total_saves */

SELECT
    fc.post_category,
    CASE
        WHEN MONTH(fc.date) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(fc.date) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(fc.date) BETWEEN 7 AND 9 THEN 'Q3'
    END AS quarter,
    SUM(fc.comments) AS total_comments,
    SUM(fc.saves) AS total_saves
FROM fact_content AS fc
WHERE MONTH(fc.date) BETWEEN 1 AND 9
GROUP BY
    fc.post_category,
    CASE
        WHEN MONTH(fc.date) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(fc.date) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(fc.date) BETWEEN 7 AND 9 THEN 'Q3'
    END
ORDER BY fc.post_category, quarter;



/* 9. List the top three dates in each month with the highest number of new
followers. The final output should include the following columns:
• month
• date
• new_followers */

WITH ranked_dates AS (
    SELECT
        dd.month_name AS month,
        MONTH(fa.date) AS month_num,
        fa.date,
        fa.new_followers,
        ROW_NUMBER() OVER (
            PARTITION BY MONTH(fa.date)
            ORDER BY fa.new_followers DESC, fa.date ASC
        ) AS date_rank
    FROM fact_account AS fa
    JOIN dim_dates AS dd
        ON fa.date = dd.date
)
SELECT
    month,
    date,
    new_followers
FROM ranked_dates
WHERE date_rank <= 3
ORDER BY month_num, date_rank;


/* 10. Create a stored procedure that takes the 'Week_no' as input and
generates a report displaying the total shares for each 'Post_type'. The
output of the procedure should consist of two columns:
• post_type
• total_shares */

DROP PROCEDURE IF EXISTS GetWeeklySharesByPostType;

DELIMITER $$

CREATE PROCEDURE GetWeeklySharesByPostType(IN p_week_no VARCHAR(10))
BEGIN
    SELECT
        fc.post_type,
        SUM(fc.shares) AS total_shares
    FROM fact_content AS fc
    JOIN dim_dates AS dd
        ON fc.date = dd.date
    WHERE dd.week_no = p_week_no
    GROUP BY fc.post_type
    ORDER BY total_shares DESC, fc.post_type;
END $$

DELIMITER ;

CALL GetWeeklySharesByPostType('W1');

