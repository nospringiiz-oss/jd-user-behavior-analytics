USE jd_user_behavior;


-- 15 Data Quality Audit

-- 1. Source and staging row counts

SELECT
    'stg_users' AS table_name,
    COUNT(*) AS row_count
FROM stg_users

UNION ALL

SELECT
    'stg_products',
    COUNT(*)
FROM stg_products

UNION ALL

SELECT
    'stg_comments',
    COUNT(*)
FROM stg_comments

UNION ALL

SELECT
    'stg_actions',
    COUNT(*)
FROM stg_actions;



-- 2. Action-field completeness and validity

SELECT
    COUNT(*) AS total_action_rows,

    SUM(user_id IS NULL)
        AS null_user_ids,

    SUM(sku_id IS NULL)
        AS null_sku_ids,

    SUM(action_time IS NULL)
        AS null_action_times,

    SUM(action_type IS NULL)
        AS null_action_types,

    SUM(cate IS NULL)
        AS null_categories,

    SUM(brand IS NULL)
        AS null_brands,

    SUM(
        action_type NOT BETWEEN 1 AND 6
    ) AS invalid_action_types,

    SUM(
        user_id <> FLOOR(user_id)
    ) AS fractional_user_ids,

    SUM(
        model_id IS NOT NULL
        AND model_id <> FLOOR(model_id)
    ) AS fractional_model_ids,

    SUM(sku_id <= 0)
        AS invalid_sku_ids,

    MIN(action_time)
        AS earliest_action,

    MAX(action_time)
        AS latest_action

FROM stg_actions;


-- 3. Action-type distribution


SELECT
    action_type,
    COUNT(*) AS action_count,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        4
    ) AS action_percentage

FROM stg_actions

GROUP BY action_type

ORDER BY action_type;


-- 4. Duplicate primary identifiers

SELECT
    COUNT(*) AS duplicate_user_ids

FROM (
    SELECT user_id
    FROM stg_users
    GROUP BY user_id
    HAVING COUNT(*) > 1
) AS duplicate_users;


SELECT
    COUNT(*) AS duplicate_product_ids

FROM (
    SELECT sku_id
    FROM stg_products
    GROUP BY sku_id
    HAVING COUNT(*) > 1
) AS duplicate_products;


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
) AS duplicate_comments;



-- 5. User-profile quality

SELECT
    COUNT(*) AS total_users,

    SUM(
        age IS NULL
        OR TRIM(age) = ''
        OR age = '-1'
    ) AS unknown_age_users,

    SUM(
        sex NOT IN (0, 1, 2)
        OR sex IS NULL
    ) AS invalid_or_unknown_sex_users,

    SUM(
        user_lv_cd IS NULL
        OR user_lv_cd <= 0
    ) AS invalid_user_levels,

    SUM(user_reg_tm IS NULL)
        AS invalid_registration_dates,

    MIN(user_reg_tm)
        AS earliest_registration_date,

    MAX(user_reg_tm)
        AS latest_registration_date

FROM stg_users;


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


-- 6. Product quality

SELECT
    COUNT(*) AS total_products,

    SUM(a1 = -1)
        AS unknown_a1_source,

    SUM(a2 = -1)
        AS unknown_a2_source,

    SUM(a3 = -1)
        AS unknown_a3_source,

    SUM(cate IS NULL OR cate <= 0)
        AS invalid_categories,

    SUM(brand IS NULL OR brand <= 0)
        AS invalid_brands

FROM stg_products;


SELECT
    COUNT(*) AS cleaned_products,

    SUM(attribute_a1 IS NULL)
        AS unknown_a1_cleaned,

    SUM(attribute_a2 IS NULL)
        AS unknown_a2_cleaned,

    SUM(attribute_a3 IS NULL)
        AS unknown_a3_cleaned

FROM dim_products;


-- 7. Comment quality
SELECT
    COUNT(*) AS total_comment_rows,

    SUM(comment_date IS NULL)
        AS invalid_comment_dates,

    SUM(sku_id IS NULL OR sku_id <= 0)
        AS invalid_comment_sku_ids,

    SUM(comment_num < 0)
        AS invalid_comment_levels,

    SUM(
        has_bad_comment NOT IN (0, 1)
        OR has_bad_comment IS NULL
    ) AS invalid_bad_comment_flags,

    SUM(
        bad_comment_rate < 0
        OR bad_comment_rate > 1
        OR bad_comment_rate IS NULL
    ) AS invalid_bad_comment_rates,

    MIN(comment_date)
        AS earliest_comment_date,

    MAX(comment_date)
        AS latest_comment_date

FROM stg_comments;


-- 8. Referential integrity: active users

SELECT
    COUNT(*) AS active_users_without_profile

FROM mart_user_summary AS summary

LEFT JOIN dim_users AS users
    ON summary.user_id = users.user_id

WHERE users.user_id IS NULL;


-- 9. Registered users without activity

SELECT
    COUNT(*) AS registered_users_without_activity

FROM dim_users AS users

LEFT JOIN mart_user_summary AS summary
    ON users.user_id = summary.user_id

WHERE summary.user_id IS NULL;


-- 10. Referential integrity: active products


SELECT
    COUNT(*) AS active_products_without_product_profile

FROM mart_product_performance AS performance

LEFT JOIN dim_products AS products
    ON performance.sku_id = products.sku_id

WHERE products.sku_id IS NULL;

-- 11. Comment records without product profile


SELECT
    COUNT(DISTINCT comments.sku_id)
        AS commented_products_without_product_profile

FROM fact_comments AS comments

LEFT JOIN dim_products AS products
    ON comments.sku_id = products.sku_id

WHERE products.sku_id IS NULL;



-- 12. Category and brand consistency

SELECT
    SUM(
        products.sku_id IS NOT NULL
        AND behavior.category_id <> products.category_id
    ) AS category_mismatch_user_product_pairs,

    SUM(
        products.sku_id IS NOT NULL
        AND behavior.brand_id <> products.brand_id
    ) AS brand_mismatch_user_product_pairs

FROM mart_user_product_period AS behavior

LEFT JOIN dim_products AS products
    ON behavior.sku_id = products.sku_id;



-- 13. Analytical action reconciliation

SELECT
    'stg_actions' AS data_layer,
    COUNT(*) AS reconstructed_actions
FROM stg_actions

UNION ALL

SELECT
    'fact_user_product_daily',
    SUM(total_action_count)
FROM fact_user_product_daily

UNION ALL

SELECT
    'mart_user_product_period',
    SUM(total_action_count)
FROM mart_user_product_period

UNION ALL

SELECT
    'mart_user_summary',
    SUM(total_action_count)
FROM mart_user_summary

UNION ALL

SELECT
    'mart_product_performance',
    SUM(total_action_count)
FROM mart_product_performance

UNION ALL

SELECT
    'mart_category_performance',
    SUM(total_action_count)
FROM mart_category_performance

UNION ALL

SELECT
    'mart_brand_performance',
    SUM(total_action_count)
FROM mart_brand_performance

UNION ALL

SELECT
    'mart_daily_performance',
    SUM(total_action_count)
FROM mart_daily_performance

UNION ALL

SELECT
    'mart_hourly_performance',
    SUM(total_action_count)
FROM mart_hourly_performance;



-- 14. Behaviour-total reconciliation

SELECT
    SUM(browse_count)
        AS browse_actions,

    SUM(cart_add_count)
        AS cart_add_actions,

    SUM(cart_remove_count)
        AS cart_remove_actions,

    SUM(purchase_count)
        AS purchase_actions,

    SUM(follow_count)
        AS follow_actions,

    SUM(click_count)
        AS click_actions,

    SUM(total_action_count)
        AS total_actions

FROM mart_user_summary;


-- 15. Customer-segment reconciliation

SELECT
    executive.active_users,

    segment.segment_users,

    executive.active_users
    - segment.segment_users
        AS user_difference

FROM mart_dashboard_executive AS executive

CROSS JOIN (
    SELECT
        SUM(user_count) AS segment_users
    FROM mart_segment_performance
) AS segment;


-- 16. Cart-pair consistency

SELECT
    COUNT(*) AS inconsistent_products

FROM mart_product_performance

WHERE cart_users <>
      cart_converted_users
      + cart_abandon_users;


SELECT
    cart_user_product_pairs,
    converted_cart_pairs,
    abandoned_cart_pairs,

    cart_user_product_pairs
    - converted_cart_pairs
    - abandoned_cart_pairs
        AS cart_pair_difference

FROM mart_dashboard_executive;
