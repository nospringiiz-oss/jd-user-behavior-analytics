USE jd_user_behavior;

-- =========================================================
-- 11 Create Brand Performance Mart
--
-- Grain:
-- One row per active brand.
-- =========================================================


-- =========================================================
-- 1. Create table
-- =========================================================

DROP TABLE IF EXISTS mart_brand_performance;

CREATE TABLE mart_brand_performance (
    brand_id                    INT NOT NULL,

    active_products             INT UNSIGNED NOT NULL,
    interacting_users           INT UNSIGNED NOT NULL,
    interested_users            INT UNSIGNED NOT NULL,
    followed_users              INT UNSIGNED NOT NULL,
    cart_users                  INT UNSIGNED NOT NULL,
    cart_converted_users        INT UNSIGNED NOT NULL,
    cart_abandon_users          INT UNSIGNED NOT NULL,
    buyers                      INT UNSIGNED NOT NULL,

    browse_count                BIGINT UNSIGNED NOT NULL,
    cart_add_count              BIGINT UNSIGNED NOT NULL,
    cart_remove_count           BIGINT UNSIGNED NOT NULL,
    purchase_count              BIGINT UNSIGNED NOT NULL,
    follow_count                BIGINT UNSIGNED NOT NULL,
    click_count                 BIGINT UNSIGNED NOT NULL,
    total_action_count          BIGINT UNSIGNED NOT NULL,

    interest_to_cart_rate       DECIMAL(10, 4),
    cart_to_purchase_rate       DECIMAL(10, 4),
    cart_abandonment_rate       DECIMAL(10, 4),
    overall_conversion_rate     DECIMAL(10, 4),

    products_with_comments      INT UNSIGNED NOT NULL DEFAULT 0,
    avg_bad_comment_rate        DECIMAL(10, 6),

    first_action_time           DATETIME NOT NULL,
    last_action_time            DATETIME NOT NULL,

    PRIMARY KEY (brand_id),

    INDEX idx_brand_cart_conversion (
        cart_to_purchase_rate
    ),

    INDEX idx_brand_cart_abandonment (
        cart_abandonment_rate
    ),

    INDEX idx_brand_buyers (
        buyers
    )
) ENGINE = InnoDB;


-- =========================================================
-- 2. Insert brand performance metrics
-- =========================================================

INSERT INTO mart_brand_performance (
    brand_id,

    active_products,
    interacting_users,
    interested_users,
    followed_users,
    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,

    browse_count,
    cart_add_count,
    cart_remove_count,
    purchase_count,
    follow_count,
    click_count,
    total_action_count,

    interest_to_cart_rate,
    cart_to_purchase_rate,
    cart_abandonment_rate,
    overall_conversion_rate,

    products_with_comments,
    avg_bad_comment_rate,

    first_action_time,
    last_action_time
)

SELECT
    action_metrics.brand_id,

    action_metrics.active_products,

    user_metrics.interacting_users,
    user_metrics.interested_users,
    user_metrics.followed_users,
    user_metrics.cart_users,
    user_metrics.cart_converted_users,
    user_metrics.cart_abandon_users,
    user_metrics.buyers,

    action_metrics.browse_count,
    action_metrics.cart_add_count,
    action_metrics.cart_remove_count,
    action_metrics.purchase_count,
    action_metrics.follow_count,
    action_metrics.click_count,
    action_metrics.total_action_count,

    ROUND(
        100.0
        * user_metrics.cart_users
        / NULLIF(user_metrics.interested_users, 0),
        4
    ) AS interest_to_cart_rate,

    ROUND(
        100.0
        * user_metrics.cart_converted_users
        / NULLIF(user_metrics.cart_users, 0),
        4
    ) AS cart_to_purchase_rate,

    ROUND(
        100.0
        * user_metrics.cart_abandon_users
        / NULLIF(user_metrics.cart_users, 0),
        4
    ) AS cart_abandonment_rate,

    ROUND(
        100.0
        * user_metrics.buyers
        / NULLIF(user_metrics.interacting_users, 0),
        4
    ) AS overall_conversion_rate,

    COALESCE(
        comment_metrics.products_with_comments,
        0
    ) AS products_with_comments,

    comment_metrics.avg_bad_comment_rate,

    action_metrics.first_action_time,
    action_metrics.last_action_time

FROM (
    SELECT
        brand_id,

        COUNT(DISTINCT sku_id)
            AS active_products,

        SUM(browse_count)
            AS browse_count,

        SUM(cart_add_count)
            AS cart_add_count,

        SUM(cart_remove_count)
            AS cart_remove_count,

        SUM(purchase_count)
            AS purchase_count,

        SUM(follow_count)
            AS follow_count,

        SUM(click_count)
            AS click_count,

        SUM(total_action_count)
            AS total_action_count,

        MIN(first_action_time)
            AS first_action_time,

        MAX(last_action_time)
            AS last_action_time

    FROM mart_user_product_period

    WHERE brand_id IS NOT NULL

    GROUP BY brand_id
) AS action_metrics

INNER JOIN (
    SELECT
        user_brand.brand_id,

        COUNT(*) AS interacting_users,

        SUM(user_brand.interest_flag)
            AS interested_users,

        SUM(user_brand.follow_flag)
            AS followed_users,

        SUM(user_brand.cart_add_flag)
            AS cart_users,

        SUM(user_brand.cart_converted_flag)
            AS cart_converted_users,

        SUM(
            CASE
                WHEN user_brand.cart_add_flag = 1
                 AND user_brand.cart_converted_flag = 0
                THEN 1
                ELSE 0
            END
        ) AS cart_abandon_users,

        SUM(user_brand.purchase_flag)
            AS buyers

    FROM (
        SELECT
            user_id,
            brand_id,

            MAX(interest_flag)
                AS interest_flag,

            MAX(follow_flag)
                AS follow_flag,

            MAX(cart_add_flag)
                AS cart_add_flag,

            MAX(purchase_flag)
                AS purchase_flag,

            MAX(
                CASE
                    WHEN cart_add_flag = 1
                     AND purchase_flag = 1
                    THEN 1
                    ELSE 0
                END
            ) AS cart_converted_flag

        FROM mart_user_product_period

        WHERE brand_id IS NOT NULL

        GROUP BY
            user_id,
            brand_id
    ) AS user_brand

    GROUP BY user_brand.brand_id
) AS user_metrics
    ON action_metrics.brand_id =
       user_metrics.brand_id

LEFT JOIN (
    SELECT
        brand_id,

        SUM(
            latest_comment_date IS NOT NULL
        ) AS products_with_comments,

        ROUND(
            AVG(bad_comment_rate),
            6
        ) AS avg_bad_comment_rate

    FROM mart_product_performance

    WHERE brand_id IS NOT NULL

    GROUP BY brand_id
) AS comment_metrics
    ON action_metrics.brand_id =
       comment_metrics.brand_id;


-- =========================================================
-- 3. Validate reconstructed actions
--
-- Expected:
-- reconstructed_actions = 50,601,736
-- =========================================================

SELECT
    COUNT(*) AS active_brands,

    SUM(total_action_count)
        AS reconstructed_actions,

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
        AS click_actions

FROM mart_brand_performance;


-- =========================================================
-- 4. Validate cart-user consistency
--
-- Expected:
-- inconsistent_brands = 0
-- =========================================================

SELECT
    COUNT(*) AS inconsistent_brands

FROM mart_brand_performance

WHERE cart_users <>
      cart_converted_users + cart_abandon_users;


-- =========================================================
-- 5. Highest-sales brands
-- =========================================================

SELECT
    brand_id,
    active_products,
    interacting_users,
    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,
    purchase_count,
    cart_to_purchase_rate,
    cart_abandonment_rate,
    overall_conversion_rate,
    avg_bad_comment_rate

FROM mart_brand_performance

ORDER BY
    buyers DESC,
    purchase_count DESC

LIMIT 20;


-- =========================================================
-- 6. Brands with strongest cart conversion
--
-- Require at least 100 cart users to reduce
-- small-sample distortion.
-- =========================================================

SELECT
    brand_id,
    active_products,
    interacting_users,
    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,
    cart_to_purchase_rate,
    cart_abandonment_rate,
    overall_conversion_rate

FROM mart_brand_performance

WHERE cart_users >= 100

ORDER BY
    cart_to_purchase_rate DESC,
    cart_users DESC

LIMIT 20;


-- =========================================================
-- 7. Brands with severe cart abandonment
-- =========================================================

SELECT
    brand_id,
    active_products,
    interacting_users,
    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,
    cart_to_purchase_rate,
    cart_abandonment_rate,
    overall_conversion_rate

FROM mart_brand_performance

WHERE cart_users >= 100

ORDER BY
    cart_abandonment_rate DESC,
    cart_users DESC

LIMIT 20;