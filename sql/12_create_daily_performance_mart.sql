USE jd_user_behavior;

-- =========================================================
-- 12 Create Daily Performance Mart
--
-- Grain:
-- One row per calendar date.
--
-- Same-day cart conversion:
-- A user adds and purchases the same product
-- on the same calendar date.
--
-- Same-day cart abandonment:
-- A user adds at least one product on the date,
-- but has no same-product cart conversion on that date.
-- =========================================================


-- =========================================================
-- 1. Create daily performance table
-- =========================================================

DROP TABLE IF EXISTS mart_daily_performance;

CREATE TABLE mart_daily_performance (
    action_date                       DATE NOT NULL,

    year_number                       SMALLINT NOT NULL,
    month_number                      TINYINT NOT NULL,
    month_start_date                  DATE NOT NULL,
    day_of_week_number                TINYINT NOT NULL,
    day_name                          VARCHAR(10) NOT NULL,
    is_weekend                        TINYINT(1) NOT NULL,

    active_users                      INT UNSIGNED NOT NULL,
    active_products                   INT UNSIGNED NOT NULL,

    interested_users                  INT UNSIGNED NOT NULL,
    followed_users                    INT UNSIGNED NOT NULL,
    cart_users                        INT UNSIGNED NOT NULL,
    same_day_cart_converted_users     INT UNSIGNED NOT NULL,
    same_day_cart_abandon_users       INT UNSIGNED NOT NULL,
    buyers                            INT UNSIGNED NOT NULL,

    browse_count                      BIGINT UNSIGNED NOT NULL,
    cart_add_count                    BIGINT UNSIGNED NOT NULL,
    cart_remove_count                 BIGINT UNSIGNED NOT NULL,
    purchase_count                    BIGINT UNSIGNED NOT NULL,
    follow_count                      BIGINT UNSIGNED NOT NULL,
    click_count                       BIGINT UNSIGNED NOT NULL,
    total_action_count                BIGINT UNSIGNED NOT NULL,

    interest_to_cart_rate             DECIMAL(10, 4),
    same_day_cart_conversion_rate     DECIMAL(10, 4),
    same_day_cart_abandonment_rate    DECIMAL(10, 4),
    active_user_conversion_rate       DECIMAL(10, 4),

    PRIMARY KEY (action_date),

    INDEX idx_daily_month (
        month_start_date
    ),

    INDEX idx_daily_weekday (
        day_of_week_number
    )
) ENGINE = InnoDB;


-- =========================================================
-- 2. Insert daily metrics
-- =========================================================

INSERT INTO mart_daily_performance (
    action_date,

    year_number,
    month_number,
    month_start_date,
    day_of_week_number,
    day_name,
    is_weekend,

    active_users,
    active_products,

    interested_users,
    followed_users,
    cart_users,
    same_day_cart_converted_users,
    same_day_cart_abandon_users,
    buyers,

    browse_count,
    cart_add_count,
    cart_remove_count,
    purchase_count,
    follow_count,
    click_count,
    total_action_count,

    interest_to_cart_rate,
    same_day_cart_conversion_rate,
    same_day_cart_abandonment_rate,
    active_user_conversion_rate
)

SELECT
    action_metrics.action_date,

    YEAR(action_metrics.action_date)
        AS year_number,

    MONTH(action_metrics.action_date)
        AS month_number,

    DATE_SUB(
        action_metrics.action_date,
        INTERVAL DAY(action_metrics.action_date) - 1 DAY
    ) AS month_start_date,

    WEEKDAY(action_metrics.action_date) + 1
        AS day_of_week_number,

    DAYNAME(action_metrics.action_date)
        AS day_name,

    CASE
        WHEN WEEKDAY(action_metrics.action_date) IN (5, 6)
        THEN 1
        ELSE 0
    END AS is_weekend,

    user_metrics.active_users,
    action_metrics.active_products,

    user_metrics.interested_users,
    user_metrics.followed_users,
    user_metrics.cart_users,
    user_metrics.same_day_cart_converted_users,
    user_metrics.same_day_cart_abandon_users,
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
        * user_metrics.same_day_cart_converted_users
        / NULLIF(user_metrics.cart_users, 0),
        4
    ) AS same_day_cart_conversion_rate,

    ROUND(
        100.0
        * user_metrics.same_day_cart_abandon_users
        / NULLIF(user_metrics.cart_users, 0),
        4
    ) AS same_day_cart_abandonment_rate,

    ROUND(
        100.0
        * user_metrics.buyers
        / NULLIF(user_metrics.active_users, 0),
        4
    ) AS active_user_conversion_rate

FROM (
    -- -----------------------------------------------------
    -- Daily action totals
    -- -----------------------------------------------------

    SELECT
        action_date,

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
            AS total_action_count

    FROM fact_user_product_daily

    GROUP BY action_date
) AS action_metrics

INNER JOIN (
    -- -----------------------------------------------------
    -- Daily distinct-user metrics
    -- -----------------------------------------------------

    SELECT
        user_day.action_date,

        COUNT(*)
            AS active_users,

        SUM(user_day.interest_flag)
            AS interested_users,

        SUM(user_day.follow_flag)
            AS followed_users,

        SUM(user_day.cart_add_flag)
            AS cart_users,

        SUM(user_day.same_day_cart_converted_flag)
            AS same_day_cart_converted_users,

        SUM(
            CASE
                WHEN user_day.cart_add_flag = 1
                 AND user_day.same_day_cart_converted_flag = 0
                THEN 1
                ELSE 0
            END
        ) AS same_day_cart_abandon_users,

        SUM(user_day.purchase_flag)
            AS buyers

    FROM (
        SELECT
            action_date,
            user_id,

            MAX(
                CASE
                    WHEN browse_count + click_count > 0
                    THEN 1
                    ELSE 0
                END
            ) AS interest_flag,

            MAX(
                CASE
                    WHEN follow_count > 0
                    THEN 1
                    ELSE 0
                END
            ) AS follow_flag,

            MAX(
                CASE
                    WHEN cart_add_count > 0
                    THEN 1
                    ELSE 0
                END
            ) AS cart_add_flag,

            MAX(
                CASE
                    WHEN purchase_count > 0
                    THEN 1
                    ELSE 0
                END
            ) AS purchase_flag,

            MAX(
                CASE
                    WHEN cart_add_count > 0
                     AND purchase_count > 0
                    THEN 1
                    ELSE 0
                END
            ) AS same_day_cart_converted_flag

        FROM fact_user_product_daily

        GROUP BY
            action_date,
            user_id
    ) AS user_day

    GROUP BY user_day.action_date
) AS user_metrics
    ON action_metrics.action_date =
       user_metrics.action_date;


-- =========================================================
-- 3. Validate date coverage and action totals
--
-- Expected:
-- daily_rows = 76
-- reconstructed_actions = 50,601,736
-- =========================================================

SELECT
    COUNT(*) AS daily_rows,

    MIN(action_date)
        AS earliest_date,

    MAX(action_date)
        AS latest_date,

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

FROM mart_daily_performance;


-- =========================================================
-- 4. Validate daily cart-user consistency
--
-- Expected:
-- inconsistent_dates = 0
-- =========================================================

SELECT
    COUNT(*) AS inconsistent_dates

FROM mart_daily_performance

WHERE cart_users <>
      same_day_cart_converted_users
      + same_day_cart_abandon_users;


-- =========================================================
-- 5. Daily performance report
-- =========================================================

SELECT
    action_date,
    day_name,

    active_users,
    active_products,

    interested_users,
    cart_users,
    same_day_cart_converted_users,
    same_day_cart_abandon_users,
    buyers,

    total_action_count,
    purchase_count,

    interest_to_cart_rate,
    same_day_cart_conversion_rate,
    same_day_cart_abandonment_rate,
    active_user_conversion_rate

FROM mart_daily_performance

ORDER BY action_date;


-- =========================================================
-- 6. Highest purchase-volume dates
-- =========================================================

SELECT
    action_date,
    day_name,

    active_users,
    buyers,
    purchase_count,

    active_user_conversion_rate,

    cart_users,
    same_day_cart_converted_users,
    same_day_cart_conversion_rate

FROM mart_daily_performance

ORDER BY
    purchase_count DESC,
    buyers DESC

LIMIT 15;


-- =========================================================
-- 7. Monthly summary
--
-- January and April contain partial periods.
-- =========================================================

SELECT
    month_start_date,

    COUNT(*) AS observed_days,

    SUM(active_users)
        AS daily_active_user_total,

    ROUND(
        AVG(active_users),
        2
    ) AS avg_daily_active_users,

    SUM(total_action_count)
        AS total_actions,

    SUM(purchase_count)
        AS total_purchases,

    SUM(buyers)
        AS daily_buyer_total,

    ROUND(
        AVG(active_user_conversion_rate),
        4
    ) AS avg_daily_user_conversion_rate,

    ROUND(
        AVG(same_day_cart_conversion_rate),
        4
    ) AS avg_same_day_cart_conversion_rate

FROM mart_daily_performance

GROUP BY month_start_date

ORDER BY month_start_date;


-- =========================================================
-- 8. Weekday performance
-- =========================================================

SELECT
    day_of_week_number,
    day_name,

    COUNT(*) AS observed_days,

    ROUND(
        AVG(active_users),
        2
    ) AS avg_active_users,

    ROUND(
        AVG(total_action_count),
        2
    ) AS avg_total_actions,

    ROUND(
        AVG(purchase_count),
        2
    ) AS avg_purchase_count,

    ROUND(
        AVG(active_user_conversion_rate),
        4
    ) AS avg_user_conversion_rate,

    ROUND(
        AVG(same_day_cart_abandonment_rate),
        4
    ) AS avg_same_day_cart_abandonment_rate

FROM mart_daily_performance

GROUP BY
    day_of_week_number,
    day_name

ORDER BY day_of_week_number;