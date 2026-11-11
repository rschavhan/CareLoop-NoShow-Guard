
USE noshowguard;

SELECT COUNT(*) AS total_clinics
FROM clinics;

SELECT
    COUNT(*) AS total_appointments,
    SUM(no_show) AS total_no_shows,
    ROUND(100.0 * AVG(no_show), 1) AS no_show_pct
FROM appointments;


-- Task 2.2: No-show rate by clinic

SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1)
        AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
HAVING COUNT(*) >= 95
ORDER BY no_show_pct DESC;

-- Task 2.3: Lead-time analysis

SELECT
    CASE
        WHEN lead_days <= 7 THEN '1-7'
        WHEN lead_days <= 14 THEN '8-14'
        WHEN lead_days <= 30 THEN '15-30'
        ELSE '31+'
    END AS lead_band,
    COUNT(*) AS appointments,
    SUM(no_show) AS no_shows,
    ROUND(100.0 * AVG(no_show), 1) AS no_show_pct
FROM appointments
GROUP BY lead_band
ORDER BY MIN(lead_days);

-- Task 2.4: Monthly trends

WITH monthly AS (
    SELECT
        SUBSTR(appt_date, 1, 7) AS month,
        COUNT(*) AS appointments,
        ROUND(100.0 * AVG(no_show), 1) AS no_show_pct
    FROM appointments
    GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT
    month,
    appointments,
    no_show_pct,
    ROUND(
        no_show_pct -
        LAG(no_show_pct) OVER (ORDER BY month),
        1
    ) AS change_pp
FROM monthly
ORDER BY month;



-- Task 2.5: Rank clinics within each city

WITH clinic_rates AS (
    SELECT
        c.clinic_name,
        c.city,
        ROUND(100.0 * AVG(a.no_show), 1) AS no_show_pct
    FROM appointments a
    JOIN clinics c ON a.clinic_id = c.clinic_id
    GROUP BY c.clinic_id, c.clinic_name, c.city
)
SELECT
    clinic_name,
    city,
    no_show_pct,
    RANK() OVER (
        PARTITION BY city
        ORDER BY no_show_pct DESC
    ) AS rank_in_city,
    CASE
        WHEN no_show_pct > (
            SELECT 100.0 * AVG(no_show)
            FROM appointments
        ) THEN 'above'
        WHEN no_show_pct < (
            SELECT 100.0 * AVG(no_show)
            FROM appointments
        ) THEN 'below'
        ELSE 'equal'
    END AS vs_overall
FROM clinic_rates
ORDER BY city, rank_in_city;




INSERT INTO appointments
SELECT *
FROM appointments
WHERE appointment_id = 'A0001';

