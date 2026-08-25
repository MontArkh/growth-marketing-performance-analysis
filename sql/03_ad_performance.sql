-- ============================================================
-- GROWTH MARKETING PERFORMANCE ANALYSIS
-- 03 - ANALYTICAL VIEW
--
-- Grain:
-- One row = one advertising event
--
-- This view combines campaign, ad and user information while
-- preserving the original event-level granularity.
-- ============================================================


CREATE OR REPLACE VIEW `marketing_ads.ad_performance` AS

SELECT

  -- ==========================================================
  -- EVENT
  -- ==========================================================

  e.event_id,
  e.ad_id,
  e.user_id,

  SAFE_CAST(e.timestamp AS TIMESTAMP) AS event_timestamp,

  e.day_of_week,
  e.time_of_day,
  e.event_type,


  -- ==========================================================
  -- AD
  -- ==========================================================

  a.campaign_id,

  a.ad_platform,
  a.ad_type,

  a.target_gender,
  a.target_age_group,
  a.target_interests,


  -- ==========================================================
  -- CAMPAIGN
  -- ==========================================================

  c.name AS campaign_name,

  SAFE_CAST(c.start_date AS DATE)
    AS campaign_start_date,

  SAFE_CAST(c.end_date AS DATE)
    AS campaign_end_date,

  c.duration_days
    AS campaign_duration_days,

  c.total_budget
    AS campaign_total_budget,


  -- ==========================================================
  -- USER DEMOGRAPHICS
  -- ==========================================================

  u.user_gender,
  u.user_age,

  u.age_group
    AS user_age_group,

  u.country
    AS user_country,

  u.location
    AS user_location,

  u.interests
    AS user_interests,


  -- ==========================================================
  -- DATA QUALITY FLAGS
  -- ==========================================================

  CASE

    WHEN u.user_id IS NULL
      THEN 'Ambiguous user'

    ELSE 'Valid user'

  END AS user_data_status,


  CASE

    WHEN DATE(
      SAFE_CAST(e.timestamp AS TIMESTAMP)
    )
    BETWEEN
      SAFE_CAST(c.start_date AS DATE)
      AND SAFE_CAST(c.end_date AS DATE)

      THEN 'Within campaign period'

    ELSE 'Outside campaign period'

  END AS campaign_date_status


FROM `marketing_ads.ad_events` e


LEFT JOIN `marketing_ads.ads` a
  ON e.ad_id = a.ad_id


LEFT JOIN `marketing_ads.campaigns` c
  ON a.campaign_id = c.campaign_id


LEFT JOIN `marketing_ads.valid_users` u
  ON e.user_id = u.user_id;
