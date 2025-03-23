--1. Rank Regions by Average Male and Female Wages Across All Work Types

SELECT 
    g.geography_name, 
    AVG(w.male) AS avg_male_wage,
    AVG(w.female) AS avg_female_wage,
    AVG((w.male + w.female) / 2) AS avg_combined_wage,
    RANK() OVER (ORDER BY AVG((w.male + w.female) / 2) DESC) AS rank
FROM wages w
JOIN geography g ON w.geography_id = g.geography_id
GROUP BY g.geography_name
ORDER BY rank;


--2 Average Male wage across the Education levels by Years

SELECT 
    d.education_level,
    w.year,
    AVG(w.male) AS avg_male_wage
FROM wages w
JOIN demographics d ON w.demographic_id = d.demographic_id
GROUP BY d.education_level, w.year
ORDER BY w.year, d.education_level;


--3 Average Female wage across the Education levels by Years

SELECT 
    d.education_level,
    w.year,
    AVG(w.female) AS avg_female_wage
FROM wages w
JOIN demographics d ON w.demographic_id = d.demographic_id
GROUP BY d.education_level, w.year
ORDER BY w.year, d.education_level;



--4. Yearly Wage Gap Between Genders for Each Education Level

SELECT 
    year, 
    education_level, 
    AVG(male - female) AS wage_gap
FROM wages
JOIN demographics ON wages.demographic_id = demographics.demographic_id
GROUP BY year, education_level
ORDER BY year, education_level;



--5. Work Types With the Largest Gender Wage Gap

SELECT 
    wt.work_type, 
    AVG(w.male - w.female) AS avg_wage_gap
FROM wages w
JOIN worktypes wt ON w.work_type_id = wt.work_type_id
GROUP BY wt.work_type
ORDER BY avg_wage_gap DESC;


--6. Yearly Comparison of Male and Female Wages Across All Work Types

SELECT 
    w.year, 
    wt.work_type, 
    AVG(w.male) AS avg_male_wage, 
    AVG(w.female) AS avg_female_wage
FROM wages w
JOIN worktypes wt ON w.work_type_id = wt.work_type_id
GROUP BY w.year, wt.work_type
ORDER BY w.year, wt.work_type;


--7. Wage Trends by Work Type Over Time Using Window Functions

SELECT 
    wt.work_type, 
    w.year, 
    AVG((w.male + w.female) / 2) AS avg_wage,
    LAG(AVG((w.male + w.female) / 2)) OVER (PARTITION BY wt.work_type ORDER BY w.year) AS previous_avg_wage,
    AVG((w.male + w.female) / 2) - LAG(AVG((w.male + w.female) / 2)) OVER (PARTITION BY wt.work_type ORDER BY w.year) AS wage_change
FROM wages w
JOIN worktypes wt ON w.work_type_id = wt.work_type_id
GROUP BY wt.work_type, w.year
ORDER BY wt.work_type, w.year;
	


--8. Identify Regions Where Female Wages Exceed Male Wages

SELECT 
    g.geography_name, 
    wt.work_type, 
    SUM(CASE WHEN w.female > w.male THEN 1 ELSE 0 END) AS female_exceeds_male_count,
    COUNT(*) AS total_entries,
    ROUND((SUM(CASE WHEN w.female > w.male THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS percentage
FROM wages w
JOIN geography g ON w.geography_id = g.geography_id
JOIN worktypes wt ON w.work_type_id = wt.work_type_id
GROUP BY g.geography_name, wt.work_type
ORDER BY percentage DESC;


--9. Yearly Wage Disparities Between Work Types

SELECT 
    w1.year, 
    wt1.work_type AS work_type_1, 
    wt2.work_type AS work_type_2, 
    ABS(AVG(w1.male + w1.female) - AVG(w2.male + w2.female)) AS wage_disparity
FROM wages w1
JOIN worktypes wt1 ON w1.work_type_id = wt1.work_type_id
JOIN wages w2 ON w1.year = w2.year 
              AND w1.geography_id = w2.geography_id 
              AND w1.demographic_id = w2.demographic_id
JOIN worktypes wt2 ON w2.work_type_id = wt2.work_type_id
WHERE wt1.work_type_id < wt2.work_type_id
GROUP BY w1.year, wt1.work_type, wt2.work_type
ORDER BY w1.year, wage_disparity DESC;


--10. Top Regions for Each Work Type by Wage

WITH RankedRegions AS (
    SELECT 
        g.geography_name, 
        wt.work_type, 
        AVG((w.male + w.female) / 2) AS avg_wage,
        RANK() OVER (PARTITION BY wt.work_type ORDER BY AVG((w.male + w.female) / 2) DESC) AS rank
    FROM wages w
    JOIN geography g ON w.geography_id = g.geography_id
    JOIN worktypes wt ON w.work_type_id = wt.work_type_id
    GROUP BY g.geography_name, wt.work_type
)
SELECT *
FROM RankedRegions
WHERE rank = 1
ORDER BY avg_wage DESC;
