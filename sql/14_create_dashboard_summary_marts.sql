USE jd_user_behavior;

-- =========================================================
-- 14 Create Dashboard Summary Marts
--
-- Output tables:
-- 1. mart_dashboard_executive
-- 2. mart_funnel_summary
-- 3. mart_segment_performance
-- =========================================================


-- =========================================================
-- PART 1: Executive KPI Summary
-- One row represents the complete observation period.
-- =========================================================

DROP TABLE IF EXISTS mart_dashboard_executive;

CREATE TABLE mart_dashboard_executive (
    snapshot_id                       TINYINT NOT NULL,

    dataset_start_date                DATE NOT NULL,
    dataset_end_date                  DATE NOT NULL,
    observed_days                     SMALLINT UNSIGNED NOT NULL,

    registered_users                  INT UNSIGNED NOT NULL,
    active_users                      INT UNSIGNED NOT NULL,
    inactive_registered_users         INT UNSIGNED NOT NULL,

    active_products                   INT UNSIGNED NOT NULL,
    buyers                            INT UNSIGNED NOT NULL,
    repeat_buyers                     INT UNSIGNED NOT NULL,

    total_actions                     BIGINT UNSIGNED NOT NULL,
    browse_actions                    BIGINT UNSIGNED NOT NULL,
    cart_add_actions                  BIGINT UNSIGNED NOT NULL,
    cart_remove_actions               BIGINT UNSIGNED NOT NULL,
    purchase_actions                  BIGINT UNSIGNED NOT NULL,
    follow_actions                    BIGINT UNSIGNED NOT NULL,
    click_actions                     BIGINT UNSIGNED NOT NULL,

    active_user_conversion_rate       DECIMAL(10, 4),
    repeat_buyer_rate                 DECIMAL(10, 4),
    avg_actions_per_active_user       DECIMAL(14, 2),

    cart_users                        INT UNSIGNED NOT NULL,
    cart_converted_users              INT UNSIGNED NOT NULL,
    pure_cart_abandon_users           INT UNSIGNED NOT NULL,

    user_cart_conversion_rate         DECIMAL(10, 4),
    user_cart_abandonment_rate        DECIMAL(10, 4),

    cart_user_product_pairs           BIGINT UNSIGNED NOT NULL,
    converted_cart_pairs              BIGINT UNSIGNED NOT NULL,
    abandoned_cart_pairs              BIGINT UNSIGNED NOT NULL,

    pair_cart_conversion_rate         DECIMAL(10, 4),
    pair_cart_abandonment_rate        DECIMAL(10, 4),

    PRIMARY KEY (snapshot_id)
) ENGINE = InnoDB;


INSERT INTO mart_dashboard_executive (
    snapshot_id,

    dataset_start_date,
    dataset_end_date,
    observed_days,

    registered_users,
    active_users,
    inactive_registered_users,

    active_products,
    buyers,
    repeat_buyers,

    total_actions,
    browse_actions,
    cart_add_actions,
    cart_remove_actions,
    purchase_actions,
    follow_actions,
    click_actions,

    active_user_conversion_rate,
    repeat_buyer_rate,
    avg_actions_per_active_user,

    cart_users,
    cart_converted_users,
    pure_cart_abandon_users,

    user_cart_conversion_rate,
    user_cart_abandonment_rate,

    cart_user_product_pairs,
    converted_cart_pairs,
    abandoned_cart_pairs,

    pair_cart_conversion_rate,
    pair_cart_abandonment_rate
)

SELECT
    1 AS snapshot_id,

    date_metrics.dataset_start_date,
    date_metrics.dataset_end_date,
    date_metrics.observed_days,

    profile_metrics.registered_users,
    user_metrics.active_users,

    GREATEST(
        profile_metrics.registered_users
        - user_metrics.active_users,
        0
    ) AS inactive_registered_users,

    product_metrics.active_products,
    user_metrics.buyers,
    user_metrics.repeat_buyers,

    user_metrics.total_actions,
    user_metrics.browse_actions,
    user_metrics.cart_add_actions,
    user_metrics.cart_remove_actions,
    user_metrics.purchase_actions,
    user_metrics.follow_actions,
    user_metrics.click_actions,

    ROUND(
        100.0
        * user_metrics.buyers
        / NULLIF(user_metrics.active_users, 0),
        4
    ) AS active_user_conversion_rate,

    ROUND(
        100.0
        * user_metrics.repeat_buyers
        / NULLIF(user_metrics.buyers, 0),
        4
    ) AS repeat_buyer_rate,

    ROUND(
        1.0
        * user_metrics.total_actions
        / NULLIF(user_metrics.active_users, 0),
        2
    ) AS avg_actions_per_active_user,

    cart_user_metrics.cart_users,
    cart_user_metrics.cart_converted_users,
    cart_user_metrics.pure_cart_abandon_users,

    ROUND(
        100.0
        * cart_user_metrics.cart_converted_users
        / NULLIF(cart_user_metrics.cart_users, 0),
        4
    ) AS user_cart_conversion_rate,

    ROUND(
        100.0
        * cart_user_metrics.pure_cart_abandon_users
        / NULLIF(cart_user_metrics.cart_users, 0),
        4
    ) AS user_cart_abandonment_rate,

    pair_metrics.cart_user_product_pairs,
    pair_metrics.converted_cart_pairs,
    pair_metrics.abandoned_cart_pairs,

    ROUND(
        100.0
        * pair_metrics.converted_cart_pairs
        / NULLIF(pair_metrics.cart_user_product_pairs, 0),
        4
    ) AS pair_cart_conversion_rate,

    ROUND(
        100.0
        * pair_metrics.abandoned_cart_pairs
        / NULLIF(pair_metrics.cart_user_product_pairs, 0),
        4
    ) AS pair_cart_abandonment_rate

FROM (
    SELECT
        MIN(action_date) AS dataset_start_date,
        MAX(action_date) AS dataset_end_date,
        COUNT(*) AS observed_days

    FROM mart_daily_performance
) AS date_metrics

CROSS JOIN (
    SELECT
        COUNT(*) AS registered_users

    FROM dim_users
) AS profile_metrics

CROSS JOIN (
    SELECT
        COUNT(*) AS active_users,

        SUM(buyer_flag) AS buyers,

        SUM(
            CASE
                WHEN purchase_count >= 2
                THEN 1
                ELSE 0
            END
        ) AS repeat_buyers,

        SUM(total_action_count) AS total_actions,
        SUM(browse_count) AS browse_actions,
        SUM(cart_add_count) AS cart_add_actions,
        SUM(cart_remove_count) AS cart_remove_actions,
        SUM(purchase_count) AS purchase_actions,
        SUM(follow_count) AS follow_actions,
        SUM(click_count) AS click_actions

    FROM mart_user_summary
) AS user_metrics

CROSS JOIN (
    SELECT
        COUNT(*) AS active_products

    FROM mart_product_performance
) AS product_metrics

CROSS JOIN (
    SELECT
        COUNT(*) AS cart_users,

        SUM(strict_cart_conversion_flag)
            AS cart_converted_users,

        SUM(
            CASE
                WHEN strict_cart_conversion_flag = 0
                THEN 1
                ELSE 0
            END
        ) AS pure_cart_abandon_users

    FROM (
        SELECT
            user_id,

            MAX(
                CASE
                    WHEN cart_add_flag = 1
                    THEN 1
                    ELSE 0
                END
            ) AS cart_user_flag,

            MAX(
                CASE
                    WHEN cart_add_flag = 1
                     AND purchase_flag = 1
                    THEN 1
                    ELSE 0
                END
            ) AS strict_cart_conversion_flag

        FROM mart_user_product_period

        GROUP BY user_id
    ) AS user_cart

    WHERE cart_user_flag = 1
) AS cart_user_metrics

CROSS JOIN (
    SELECT
        SUM(cart_users)
            AS cart_user_product_pairs,

        SUM(cart_converted_users)
            AS converted_cart_pairs,

        SUM(cart_abandon_users)
            AS abandoned_cart_pairs

    FROM mart_product_performance
) AS pair_metrics;


-- =========================================================
-- PART 2: User Behaviour Funnel
--
-- This is a behavioural reach funnel.
-- Each stage shows users who performed that behaviour.
-- Users may skip stages, such as purchasing directly
-- without following or adding to cart.
-- =========================================================

DROP TABLE IF EXISTS mart_funnel_summary;

CREATE TABLE mart_funnel_summary (
    stage_order                 TINYINT NOT NULL,
    stage_name                  VARCHAR(40) NOT NULL,
    user_count                  INT UNSIGNED NOT NULL,
    active_user_share_pct       DECIMAL(10, 4) NOT NULL,
    stage_definition            VARCHAR(255) NOT NULL,

    PRIMARY KEY (stage_order),
    UNIQUE KEY uk_funnel_stage_name (stage_name)
) ENGINE = InnoDB;


INSERT INTO mart_funnel_summary (
    stage_order,
    stage_name,
    user_count,
    active_user_share_pct,
    stage_definition
)

SELECT
    1,
    'Active Users',
    COUNT(*),
    100.0000,
    'Users with at least one recorded action'

FROM mart_user_summary

UNION ALL

SELECT
    2,
    'Interested Users',
    SUM(interest_flag),

    ROUND(
        100.0
        * SUM(interest_flag)
        / NULLIF(COUNT(*), 0),
        4
    ),

    'Users with at least one browse or click action'

FROM mart_user_summary

UNION ALL

SELECT
    3,
    'Followed Users',
    SUM(follow_flag),

    ROUND(
        100.0
        * SUM(follow_flag)
        / NULLIF(COUNT(*), 0),
        4
    ),

    'Users who followed at least one product'

FROM mart_user_summary

UNION ALL

SELECT
    4,
    'Cart Users',
    SUM(cart_add_flag),

    ROUND(
        100.0
        * SUM(cart_add_flag)
        / NULLIF(COUNT(*), 0),
        4
    ),

    'Users who added at least one product to cart'

FROM mart_user_summary

UNION ALL

SELECT
    5,
    'Buyers',
    SUM(buyer_flag),

    ROUND(
        100.0
        * SUM(buyer_flag)
        / NULLIF(COUNT(*), 0),
        4
    ),

    'Users who purchased at least one product'

FROM mart_user_summary;


-- =========================================================
-- PART 3: Customer Segment Performance
-- One row per customer segment.
-- =========================================================

DROP TABLE IF EXISTS mart_segment_performance;

CREATE TABLE mart_segment_performance (
    customer_segment             VARCHAR(40) NOT NULL,

    user_count                   INT UNSIGNED NOT NULL,
    user_percentage              DECIMAL(10, 4) NOT NULL,

    buyers                       INT UNSIGNED NOT NULL,
    cart_users                   INT UNSIGNED NOT NULL,
    abandoned_cart_users         INT UNSIGNED NOT NULL,

    avg_intent_score             DECIMAL(12, 2),
    avg_recency_days             DECIMAL(12, 2),
    avg_active_days              DECIMAL(12, 2),
    avg_interacted_products      DECIMAL(14, 2),

    total_actions                BIGINT UNSIGNED NOT NULL,
    purchase_actions             BIGINT UNSIGNED NOT NULL,

    avg_actions_per_user         DECIMAL(14, 2),
    avg_purchases_per_user       DECIMAL(14, 4),

    PRIMARY KEY (customer_segment)
) ENGINE = InnoDB;


INSERT INTO mart_segment_performance (
    customer_segment,

    user_count,
    user_percentage,

    buyers,
    cart_users,
    abandoned_cart_users,

    avg_intent_score,
    avg_recency_days,
    avg_active_days,
    avg_interacted_products,

    total_actions,
    purchase_actions,

    avg_actions_per_user,
    avg_purchases_per_user
)

SELECT
    customer_segment,

    COUNT(*) AS user_count,

    ROUND(
        100.0
        * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        4
    ) AS user_percentage,

    SUM(buyer_flag) AS buyers,
    SUM(cart_add_flag) AS cart_users,
    SUM(cart_abandon_flag) AS abandoned_cart_users,

    ROUND(
        AVG(purchase_intent_score),
        2
    ) AS avg_intent_score,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days,

    ROUND(
        AVG(active_days),
        2
    ) AS avg_active_days,

    ROUND(
        AVG(interacted_products),
        2
    ) AS avg_interacted_products,

    SUM(total_action_count) AS total_actions,
    SUM(purchase_count) AS purchase_actions,

    ROUND(
        1.0
        * SUM(total_action_count)
        / NULLIF(COUNT(*), 0),
        2
    ) AS avg_actions_per_user,

    ROUND(
        1.0
        * SUM(purchase_count)
        / NULLIF(COUNT(*), 0),
        4
    ) AS avg_purchases_per_user

FROM mart_user_summary

GROUP BY customer_segment;


-- =========================================================
-- VALIDATION 1: Executive KPI result
-- =========================================================

SELECT *
FROM mart_dashboard_executive;


-- =========================================================
-- VALIDATION 2: Funnel result
-- =========================================================

SELECT *
FROM mart_funnel_summary
ORDER BY stage_order;


-- =========================================================
-- VALIDATION 3: Segment result
-- =========================================================

SELECT *
FROM mart_segment_performance
ORDER BY user_count DESC;


-- =========================================================
-- VALIDATION 4: User-level cart consistency
--
-- Expected:
-- cart_user_difference = 0
-- =========================================================

SELECT
    cart_users,
    cart_converted_users,
    pure_cart_abandon_users,

    cart_users
    - cart_converted_users
    - pure_cart_abandon_users
        AS cart_user_difference

FROM mart_dashboard_executive;


-- =========================================================
-- VALIDATION 5: User-product pair consistency
--
-- Expected:
-- cart_pair_difference = 0
-- =========================================================

SELECT
    cart_user_product_pairs,
    converted_cart_pairs,
    abandoned_cart_pairs,

    cart_user_product_pairs
    - converted_cart_pairs
    - abandoned_cart_pairs
        AS cart_pair_difference

FROM mart_dashboard_executive;


-- =========================================================
-- VALIDATION 6: Segment users equal active users
--
-- Expected:
-- user_difference = 0
-- =========================================================

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