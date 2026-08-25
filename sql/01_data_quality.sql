-- ============================================================
-- GROWTH MARKETING PERFORMANCE ANALYSIS
-- 01 - DATA QUALITY CHECKS
-- BigQuery Standard SQL
-- ============================================================


-- ============================================================
-- 1. TABLE SIZE, PRIMARY KEY UNIQUENESS AND NULL CHECKS
-- ============================================================

-- Ad Events
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT event_id) AS unique_event_ids,
  COUNTIF(event_id IS NULL) AS null_event_id,
  COUNTIF(ad_id IS NULL) AS null_ad_id,
  COUNTIF(user_id IS NULL) AS null_user_id,
  COUNTIF(timestamp IS NULL) AS null_timestamp,
  COUNTIF(day_of_week IS NULL) AS null_day_of_week,
  COUNTIF(time_of_day IS NULL) AS null_time_of_day,
  COUNTIF(event_type IS NULL) AS null_event_type
FROM `marketing_ads.ad_events`;


-- Ads
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT ad_id) AS unique_ad_ids,
  COUNTIF(ad_id IS NULL) AS null_ad_id,
  COUNTIF(campaign_id IS NULL) AS null_campaign_id,
  COUNTIF(ad_platform IS NULL) AS null_platform,
  COUNTIF(ad_type IS NULL) AS null_ad_type,
  COUNTIF(target_gender IS NULL) AS null_target_gender,
  COUNTIF(target_age_group IS NULL) AS null_target_age_group,
  COUNTIF(target_interests IS NULL) AS null_target_interests
FROM `marketing_ads.ads`;


-- Campaigns
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT campaign_id) AS unique_campaign_ids,
  COUNTIF(campaign_id IS NULL) AS null_campaign_id,
  COUNTIF(name IS NULL) AS null_campaign_name,
  COUNTIF(start_date IS NULL) AS null_start_date,
  COUNTIF(end_date IS NULL) AS null_end_date,
  COUNTIF(duration_days IS NULL) AS null_duration,
  COUNTIF(total_budget IS NULL) AS null_budget
FROM `marketing_ads.campaigns`;


-- Users
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT user_id) AS unique_user_ids,
  COUNTIF(user_id IS NULL) AS null_user_id,
  COUNTIF(user_gender IS NULL) AS null_gender,
  COUNTIF(user_age IS NULL) AS null_age,
  COUNTIF(age_group IS NULL) AS null_age_group,
  COUNTIF(country IS NULL) AS null_country
FROM `marketing_ads.users`;



-- ============================================================
-- 2. DUPLICATED USER IDS
-- ============================================================

SELECT
  user_id,
  COUNT(*) AS occurrences
FROM `marketing_ads.users`
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- Number of duplicated user IDs
SELECT
  COUNT(*) AS duplicated_user_ids
FROM (
  SELECT user_id
  FROM `marketing_ads.users`
  GROUP BY user_id
  HAVING COUNT(*) > 1
);


-- Events affected by ambiguous user IDs
SELECT
  COUNT(*) AS affected_events,
  ROUND(
    100 * SAFE_DIVIDE(COUNT(*), 400000),
    2
  ) AS affected_events_pct
FROM `marketing_ads.ad_events`
WHERE user_id IN (
  SELECT user_id
  FROM `marketing_ads.users`
  GROUP BY user_id
  HAVING COUNT(*) > 1
);



-- ============================================================
-- 3. JOIN FANOUT CHECK
-- ============================================================

-- Joining the original users table generates additional rows
SELECT
  COUNT(*) AS rows_after_original_users_join
FROM `marketing_ads.ad_events` e
LEFT JOIN `marketing_ads.users` u
  ON e.user_id = u.user_id;


-- Expected after cleaning: 400,000 rows
SELECT
  COUNT(*) AS rows_after_valid_users_join
FROM `marketing_ads.ad_events` e
LEFT JOIN `marketing_ads.valid_users` u
  ON e.user_id = u.user_id;



-- ============================================================
-- 4. REFERENTIAL INTEGRITY
-- ============================================================

-- Events without a corresponding ad
SELECT
  COUNT(*) AS events_without_ad
FROM `marketing_ads.ad_events` e
WHERE NOT EXISTS (
  SELECT 1
  FROM `marketing_ads.ads` a
  WHERE a.ad_id = e.ad_id
);


-- Ads without a corresponding campaign
SELECT
  COUNT(*) AS ads_without_campaign
FROM `marketing_ads.ads` a
WHERE NOT EXISTS (
  SELECT 1
  FROM `marketing_ads.campaigns` c
  WHERE c.campaign_id = a.campaign_id
);


-- Events referencing users that do not exist
SELECT
  COUNT(*) AS events_without_user
FROM `marketing_ads.ad_events` e
WHERE NOT EXISTS (
  SELECT 1
  FROM `marketing_ads.users` u
  WHERE u.user_id = e.user_id
);



-- ============================================================
-- 5. DERIVED FIELD CONSISTENCY
-- ============================================================

-- Day of week vs timestamp
SELECT
  COUNT(*) AS inconsistent_day_of_week
FROM `marketing_ads.ad_events`
WHERE day_of_week != FORMAT_TIMESTAMP(
  '%A',
  SAFE_CAST(timestamp AS TIMESTAMP)
);


-- Time of day vs timestamp
SELECT
  COUNT(*) AS inconsistent_time_of_day
FROM `marketing_ads.ad_events`
WHERE time_of_day !=
  CASE
    WHEN EXTRACT(HOUR FROM SAFE_CAST(timestamp AS TIMESTAMP))
      BETWEEN 0 AND 5 THEN 'Night'
    WHEN EXTRACT(HOUR FROM SAFE_CAST(timestamp AS TIMESTAMP))
      BETWEEN 6 AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM SAFE_CAST(timestamp AS TIMESTAMP))
      BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM SAFE_CAST(timestamp AS TIMESTAMP))
      BETWEEN 18 AND 23 THEN 'Evening'
  END;


-- User age vs age group
SELECT
  COUNT(*) AS inconsistent_age_group
FROM `marketing_ads.users`
WHERE age_group !=
  CASE
    WHEN user_age BETWEEN 16 AND 17 THEN '16-17'
    WHEN user_age BETWEEN 18 AND 24 THEN '18-24'
    WHEN user_age BETWEEN 25 AND 34 THEN '25-34'
    WHEN user_age BETWEEN 35 AND 44 THEN '35-44'
    WHEN user_age BETWEEN 45 AND 54 THEN '45-54'
    WHEN user_age BETWEEN 55 AND 65 THEN '55-65'
    ELSE 'OUT_OF_RANGE'
  END;


-- Campaign duration
SELECT
  COUNT(*) AS inconsistent_campaign_duration
FROM `marketing_ads.campaigns`
WHERE duration_days != DATE_DIFF(
  SAFE_CAST(end_date AS DATE),
  SAFE_CAST(start_date AS DATE),
  DAY
);



-- ============================================================
-- 6. CAMPAIGN DATE VS EVENT DATE
-- ============================================================

WITH event_campaign_dates AS (
  SELECT
    e.event_id,
    SAFE_CAST(e.timestamp AS TIMESTAMP) AS event_timestamp,
    SAFE_CAST(c.start_date AS DATE) AS campaign_start_date,
    SAFE_CAST(c.end_date AS DATE) AS campaign_end_date

  FROM `marketing_ads.ad_events` e

  LEFT JOIN `marketing_ads.ads` a
    ON e.ad_id = a.ad_id

  LEFT JOIN `marketing_ads.campaigns` c
    ON a.campaign_id = c.campaign_id
)

SELECT
  COUNT(*) AS total_events,

  COUNTIF(
    DATE(event_timestamp) < campaign_start_date
    OR DATE(event_timestamp) > campaign_end_date
  ) AS events_outside_campaign_period,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(
        DATE(event_timestamp) < campaign_start_date
        OR DATE(event_timestamp) > campaign_end_date
      ),
      COUNT(*)
    ),
    2
  ) AS outside_campaign_period_pct

FROM event_campaign_dates;



-- ============================================================
-- 7. EVENT JOURNEY CONSISTENCY
-- ============================================================

WITH user_ad_journey AS (
  SELECT
    user_id,
    ad_id,

    COUNTIF(event_type = 'Impression') AS impressions,
    COUNTIF(event_type = 'Click') AS clicks,
    COUNTIF(event_type = 'Purchase') AS purchases,

    MIN(IF(
      event_type = 'Impression',
      SAFE_CAST(event_timestamp AS TIMESTAMP),
      NULL
    )) AS first_impression,

    MIN(IF(
      event_type = 'Click',
      SAFE_CAST(event_timestamp AS TIMESTAMP),
      NULL
    )) AS first_click,

    MIN(IF(
      event_type = 'Purchase',
      SAFE_CAST(event_timestamp AS TIMESTAMP),
      NULL
    )) AS first_purchase

  FROM `marketing_ads.ad_performance`

  WHERE user_data_status = 'Valid user'

  GROUP BY
    user_id,
    ad_id
)

SELECT
  COUNT(*) AS total_user_ad_pairs,

  COUNTIF(
    clicks > 0
    AND impressions = 0
  ) AS clicks_without_impression,

  COUNTIF(
    purchases > 0
    AND clicks = 0
  ) AS purchases_without_click,

  COUNTIF(
    first_click IS NOT NULL
    AND first_impression IS NOT NULL
    AND first_click < first_impression
  ) AS click_before_impression,

  COUNTIF(
    first_purchase IS NOT NULL
    AND first_click IS NOT NULL
    AND first_purchase < first_click
  ) AS purchase_before_click

FROM user_ad_journey;
