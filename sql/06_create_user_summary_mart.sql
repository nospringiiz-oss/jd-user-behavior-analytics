USE jd_user_behavior;

-- =========================================================
-- User-level analytical mart
-- Grain: one row per active user
-- =========================================================

DROP TABLE IF EXISTS mart_user_summary;

CREATE TABLE mart_user_summary (
    user_id                    BIGINT NOT NULL,

    age_group                  VARCHAR(20) NOT NULL,
    sex_code                   TINYINT,
    user_level                 TINYINT,

    active_days                SMALLINT UNSIGNED NOT NULL,
    interacted_products        INT UNSIGNED NOT NULL,
    interested_products        INT UNSIGNED NOT NULL,
    followed_products          INT UNSIGNED NOT NULL,
    carted_products            INT UNSIGNED NOT NULL,
    purchased_products         INT UNSIGNED NOT NULL,
    abandoned_cart_products    INT UNSIGNED NOT NULL,
    interacted_categories      INT UNSIGNED NOT NULL,

    browse_count               BIGINT UNSIGNED NOT NULL,
    cart_add_count             BIGINT UNSIGNED NOT NULL,
    cart_remove_count          BIGINT UNSIGNED NOT NULL,
    purchase_count             BIGINT UNSIGNED NOT NULL,
    follow_count               BIGINT UNSIGNED NOT NULL,
    click_count                BIGINT UNSIGNED NOT NULL,
    total_action_count         BIGINT UNSIGNED NOT NULL,

    first_action_time          DATETIME NOT NULL,
    last_action_time           DATETIME NOT NULL,
    recency_days               SMALLINT UNSIGNED NOT NULL,

    interest_flag              TINYINT(1) NOT NULL,
    follow_flag                TINYINT(1) NOT NULL,
    cart_add_flag              TINYINT(1) NOT NULL,
    buyer_flag                 TINYINT(1) NOT NULL,
    cart_abandon_flag          TINYINT(1) NOT NULL,

    purchase_intent_score      INT NOT NULL,
    customer_segment           VARCHAR(40) NOT NULL,

    PRIMARY KEY (user_id),

    INDEX idx_user_segment (customer_segment),
    INDEX idx_user_level (user_level),
    INDEX idx_user_score (purchase_intent_score),
    INDEX idx_user_buyer (buyer_flag),
    INDEX idx_user_cart_abandon (cart_abandon_flag)
) ENGINE = InnoDB;


-- =========================================================
-- Insert user-level metrics
-- =========================================================

INSERT INTO mart_user_summary (
    user_id,
    age_group,
    sex_code,
    user_level,

    active_days,
    interacted_products,
    interested_products,
    followed_products,
    carted_products,
    purchased_products,
    abandoned_cart_products,
    interacted_categories,

    browse_count,
    cart_add_count,
    cart_remove_count,
    purchase_count,
    follow_count,
    click_count,
    total_action_count,

    first_action_time,
    last_action_time,
    recency_days,

    interest_flag,
    follow_flag,
    cart_add_flag,
    buyer_flag,
    cart_abandon_flag,

    purchase_intent_score,
    customer_segment
)

SELECT
    scored.user_id,

    COALESCE(users.age_group, 'Unknown') AS age_group,
    users.sex_code,
    users.user_level,

    scored.active_days,
    scored.interacted_products,
    scored.interested_products,
    scored.followed_products,
    scored.carted_products,
    scored.purchased_products,
    scored.abandoned_cart_products,
    scored.interacted_categories,

    scored.browse_count,
    scored.cart_add_count,
    scored.cart_remove_count,
    scored.purchase_count,
    scored.follow_count,
    scored.click_count,
    scored.total_action_count,

    scored.first_action_time,
    scored.last_action_time,
    scored.recency_days,

    scored.interest_flag,
    scored.follow_flag,
    scored.cart_add_flag,
    scored.buyer_flag,
    scored.cart_abandon_flag,

    scored.purchase_intent_score,

    CASE
        WHEN scored.buyer_flag = 1
        THEN 'Existing Customer'

        WHEN scored.cart_add_flag = 1
         AND scored.buyer_flag = 0
         AND scored.recency_days <= 7
         AND scored.purchase_intent_score >= 20
        THEN 'High Purchase Intent'

        WHEN scored.cart_abandon_flag = 1
         AND scored.buyer_flag = 0
        THEN 'Cart-Abandonment User'

        WHEN scored.follow_flag = 1
          OR scored.purchase_intent_score >= 10
        THEN 'Medium Purchase Intent'

        WHEN scored.interest_flag = 1
        THEN 'Low Purchase Intent'

        ELSE 'Other Active User'
    END AS customer_segment

FROM (
    SELECT
        base.*,

        GREATEST(
            0,

            CAST(LEAST(base.browse_count, 10) AS SIGNED)

            + CAST(LEAST(base.click_count, 20) AS SIGNED)

            + 3 * CAST(
                LEAST(base.follow_count, 5) AS SIGNED
            )

            + 5 * CAST(
                LEAST(base.cart_add_count, 5) AS SIGNED
            )

            - 3 * CAST(
                LEAST(base.cart_remove_count, 5) AS SIGNED
            )

            + 8 * CAST(
                LEAST(base.purchase_count, 3) AS SIGNED
            )

            + CASE
                WHEN base.recency_days <= 3 THEN 10
                WHEN base.recency_days <= 7 THEN 6
                WHEN base.recency_days <= 14 THEN 3
                ELSE 0
              END
        ) AS purchase_intent_score

    FROM (
        SELECT
            daily.user_id,

            daily.active_days,
            daily.interacted_products,
            daily.interested_products,
            daily.followed_products,
            daily.carted_products,
            daily.purchased_products,

            COALESCE(
                abandoned.abandoned_cart_products,
                0
            ) AS abandoned_cart_products,

            daily.interacted_categories,

            daily.browse_count,
            daily.cart_add_count,
            daily.cart_remove_count,
            daily.purchase_count,
            daily.follow_count,
            daily.click_count,
            daily.total_action_count,

            daily.first_action_time,
            daily.last_action_time,

            DATEDIFF(
                data_period.dataset_end_date,
                DATE(daily.last_action_time)
            ) AS recency_days,

            CASE
                WHEN daily.browse_count + daily.click_count > 0
                THEN 1
                ELSE 0
            END AS interest_flag,

            CASE
                WHEN daily.follow_count > 0
                THEN 1
                ELSE 0
            END AS follow_flag,

            CASE
                WHEN daily.cart_add_count > 0
                THEN 1
                ELSE 0
            END AS cart_add_flag,

            CASE
                WHEN daily.purchase_count > 0
                THEN 1
                ELSE 0
            END AS buyer_flag,

            CASE
                WHEN COALESCE(
                    abandoned.abandoned_cart_products,
                    0
                ) > 0
                THEN 1
                ELSE 0
            END AS cart_abandon_flag

        FROM (
            SELECT
                user_id,

                COUNT(DISTINCT action_date)
                    AS active_days,

                COUNT(DISTINCT sku_id)
                    AS interacted_products,

                COUNT(
                    DISTINCT CASE
                        WHEN browse_count + click_count > 0
                        THEN sku_id
                    END
                ) AS interested_products,

                COUNT(
                    DISTINCT CASE
                        WHEN follow_count > 0
                        THEN sku_id
                    END
                ) AS followed_products,

                COUNT(
                    DISTINCT CASE
                        WHEN cart_add_count > 0
                        THEN sku_id
                    END
                ) AS carted_products,

                COUNT(
                    DISTINCT CASE
                        WHEN purchase_count > 0
                        THEN sku_id
                    END
                ) AS purchased_products,

                COUNT(DISTINCT category_id)
                    AS interacted_categories,

                SUM(browse_count) AS browse_count,
                SUM(cart_add_count) AS cart_add_count,
                SUM(cart_remove_count) AS cart_remove_count,
                SUM(purchase_count) AS purchase_count,
                SUM(follow_count) AS follow_count,
                SUM(click_count) AS click_count,
                SUM(total_action_count) AS total_action_count,

                MIN(first_action_time) AS first_action_time,
                MAX(last_action_time) AS last_action_time

            FROM fact_user_product_daily

            GROUP BY user_id
        ) AS daily

        LEFT JOIN (
            SELECT
                user_id,
                SUM(cart_abandon_flag)
                    AS abandoned_cart_products
            FROM mart_user_product_period
            GROUP BY user_id
        ) AS abandoned
            ON daily.user_id = abandoned.user_id

        CROSS JOIN (
            SELECT
                DATE(MAX(last_action_time))
                    AS dataset_end_date
            FROM mart_user_product_period
        ) AS data_period
    ) AS base
) AS scored

LEFT JOIN dim_users AS users
    ON scored.user_id = users.user_id;


-- =========================================================
-- Verification 1: totals
-- =========================================================

SELECT
    COUNT(*) AS active_users,
    SUM(total_action_count) AS reconstructed_actions,
    SUM(browse_count) AS browse_actions,
    SUM(cart_add_count) AS cart_add_actions,
    SUM(cart_remove_count) AS cart_remove_actions,
    SUM(purchase_count) AS purchase_actions,
    SUM(follow_count) AS follow_actions,
    SUM(click_count) AS click_actions
FROM mart_user_summary;


-- =========================================================
-- Verification 2: customer segment distribution
-- =========================================================

SELECT
    customer_segment,
    COUNT(*) AS user_count,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS user_percentage

FROM mart_user_summary

GROUP BY customer_segment

ORDER BY user_count DESC;


-- =========================================================
-- Verification 3: profile matching
-- =========================================================

SELECT
    COUNT(*) AS active_users,
    SUM(age_group = 'Unknown') AS unknown_age_users,
    SUM(sex_code IS NULL) AS unknown_sex_users,
    SUM(user_level IS NULL) AS unknown_level_users
FROM mart_user_summary;