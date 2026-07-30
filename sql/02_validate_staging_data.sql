USE jd_user_behavior;

-- =========================================================
-- 1. Check action-table validity
-- This query scans the 50-million-row table once.
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(user_id IS NULL) AS null_user_id,
    SUM(sku_id IS NULL) AS null_sku_id,
    SUM(action_time IS NULL) AS null_action_time,
    SUM(action_type IS NULL) AS null_action_type,

    SUM(user_id <> FLOOR(user_id)) AS fractional_user_id,

    SUM(
        model_id IS NOT NULL
        AND model_id <> FLOOR(model_id)
    ) AS fractional_model_id,

    SUM(
        action_type NOT BETWEEN 1 AND 6
    ) AS invalid_action_type,

    SUM(sku_id <= 0) AS invalid_sku_id,

    MIN(action_time) AS earliest_action,
    MAX(action_time) AS latest_action
FROM stg_actions;


-- =========================================================
-- 2. Check duplicate user IDs
-- Expected result: 0 duplicate_user_ids
-- =========================================================

SELECT
    COUNT(*) AS duplicate_user_ids
FROM (
    SELECT user_id
    FROM stg_users
    GROUP BY user_id
    HAVING COUNT(*) > 1
) AS duplicated_users;


-- =========================================================
-- 3. Check duplicate product IDs
-- Expected result: 0 duplicate_product_ids
-- =========================================================

SELECT
    COUNT(*) AS duplicate_product_ids
FROM (
    SELECT sku_id
    FROM stg_products
    GROUP BY sku_id
    HAVING COUNT(*) > 1
) AS duplicated_products;


-- =========================================================
-- 4. Check duplicate comment snapshots
-- One product should have one record per snapshot date.
-- =========================================================

SELECT
    COUNT(*) AS duplicate_comment_snapshots
FROM (
    SELECT
        comment_date,
        sku_id
    FROM stg_comments
    GROUP BY
        comment_date,
        sku_id
    HAVING COUNT(*) > 1
) AS duplicated_comments;


-- =========================================================
-- 5. Check user profile values
-- =========================================================

SELECT
    age,
    COUNT(*) AS user_count
FROM stg_users
GROUP BY age
ORDER BY user_count DESC;


SELECT
    sex,
    COUNT(*) AS user_count
FROM stg_users
GROUP BY sex
ORDER BY sex;


SELECT
    user_lv_cd,
    COUNT(*) AS user_count
FROM stg_users
GROUP BY user_lv_cd
ORDER BY user_lv_cd;


-- =========================================================
-- 6. Check product category distribution
-- =========================================================

SELECT
    cate,
    COUNT(*) AS product_count
FROM stg_products
GROUP BY cate
ORDER BY product_count DESC;


-- =========================================================
-- 7. Check comment values
-- =========================================================

SELECT
    COUNT(*) AS total_comment_rows,
    SUM(comment_num < 0) AS invalid_comment_num,
    SUM(
        bad_comment_rate < 0
        OR bad_comment_rate > 1
    ) AS invalid_bad_comment_rate,
    MIN(comment_date) AS earliest_comment_date,
    MAX(comment_date) AS latest_comment_date
FROM stg_comments;