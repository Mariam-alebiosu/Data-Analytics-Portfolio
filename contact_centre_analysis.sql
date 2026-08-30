-- Contact Centre Performance Analytics


-- 1. Executive KPI summary
SELECT
    COUNT(*) AS total_interactions,
    ROUND(AVG(wait_time_seconds), 1) AS avg_wait_seconds,
    ROUND(AVG(handle_time_seconds), 1) AS avg_handle_seconds,
    ROUND(100.0 * AVG(abandoned), 2) AS abandonment_rate_pct,
    ROUND(100.0 * AVG(resolved_first_contact), 2) AS fcr_rate_pct,
    ROUND(100.0 * AVG(within_sla_120s), 2) AS sla_120_rate_pct,
    ROUND(AVG(csat_score), 2) AS avg_csat
FROM contact_centre_interactions;


-- 2. Monthly trend
SELECT
    month,
    COUNT(*) AS interactions,
    ROUND(AVG(wait_time_seconds), 1) AS avg_wait_seconds,
    ROUND(100.0 * AVG(abandoned), 2) AS abandonment_rate_pct,
    ROUND(100.0 * AVG(resolved_first_contact), 2) AS fcr_rate_pct,
    ROUND(AVG(csat_score), 2) AS avg_csat
FROM contact_centre_interactions
GROUP BY month
ORDER BY month;


-- 3. Channel performance
SELECT
    channel,
    COUNT(*) AS interactions,
    ROUND(AVG(wait_time_seconds), 1) AS avg_wait_seconds,
    ROUND(AVG(handle_time_seconds), 1) AS avg_handle_seconds,
    ROUND(100.0 * AVG(abandoned), 2) AS abandonment_rate_pct,
    ROUND(100.0 * AVG(resolved_first_contact), 2) AS fcr_rate_pct,
    ROUND(AVG(csat_score), 2) AS avg_csat
FROM contact_centre_interactions
GROUP BY channel
ORDER BY interactions DESC;


-- 4. Contact reasons generating the most operational pressure
SELECT
    contact_reason,
    COUNT(*) AS interactions,
    ROUND(AVG(wait_time_seconds), 1) AS avg_wait_seconds,
    ROUND(AVG(handle_time_seconds), 1) AS avg_handle_seconds,
    ROUND(100.0 * AVG(repeat_contact_7d), 2) AS repeat_7d_pct,
    ROUND(AVG(csat_score), 2) AS avg_csat
FROM contact_centre_interactions
GROUP BY contact_reason
ORDER BY interactions DESC;


-- 5. Relationship between waiting time and customer satisfaction
SELECT
    CASE
        WHEN wait_time_seconds <= 60 THEN '0-60 sec'
        WHEN wait_time_seconds <= 120 THEN '61-120 sec'
        WHEN wait_time_seconds <= 180 THEN '121-180 sec'
        WHEN wait_time_seconds <= 300 THEN '181-300 sec'
        ELSE '300+ sec'
    END AS wait_band,
    COUNT(*) AS interactions,
    ROUND(AVG(csat_score), 2) AS avg_csat,
    ROUND(100.0 * AVG(abandoned), 2) AS abandonment_rate_pct
FROM contact_centre_interactions
GROUP BY 1
ORDER BY
    CASE wait_band
        WHEN '0-60 sec' THEN 1
        WHEN '61-120 sec' THEN 2
        WHEN '121-180 sec' THEN 3
        WHEN '181-300 sec' THEN 4
        ELSE 5
    END;


-- 6. Peak operational periods
SELECT
    day_of_week,
    hour,
    COUNT(*) AS interactions,
    ROUND(AVG(wait_time_seconds), 1) AS avg_wait_seconds,
    ROUND(100.0 * AVG(abandoned), 2) AS abandonment_rate_pct
FROM contact_centre_interactions
GROUP BY day_of_week, hour
HAVING COUNT(*) >= 20
ORDER BY abandonment_rate_pct DESC, interactions DESC;


-- 7. Team performance with ranking
WITH team_metrics AS (
    SELECT
        team,
        COUNT(*) AS interactions,
        AVG(csat_score) AS avg_csat,
        AVG(resolved_first_contact) AS fcr_rate,
        AVG(abandoned) AS abandonment_rate
    FROM contact_centre_interactions
    GROUP BY team
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY avg_csat DESC) AS csat_rank,
    DENSE_RANK() OVER (ORDER BY fcr_rate DESC) AS fcr_rank
FROM team_metrics
ORDER BY csat_rank, fcr_rank;
