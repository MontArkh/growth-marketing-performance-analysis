-- ============================================================
-- GROWTH MARKETING PERFORMANCE ANALYSIS
-- 02 - USER DATA QUALITY VIEWS
-- ============================================================


-- ============================================================
-- VALID USERS
--
-- Keeps only user IDs that appear exactly once.
--
-- Duplicated IDs represented different users and could not be
-- reliably associated with advertising events.
-- ============================================================

CREATE OR REPLACE VIEW `marketing_ads.valid_users` AS

SELECT *
FROM `marketing_ads.users`

QUALIFY
  COUNT(*) OVER (
    PARTITION BY user_id
  ) = 1;



-- ============================================================
-- CONFLICTING USERS
--
-- Audit view containing ambiguous user IDs.
-- These records are preserved for transparency but are not
-- used for demographic enrichment.
-- ============================================================

CREATE OR REPLACE VIEW `marketing_ads.conflicting_users` AS

SELECT *
FROM `marketing_ads.users`

QUALIFY
  COUNT(*) OVER (
    PARTITION BY user_id
  ) > 1;
