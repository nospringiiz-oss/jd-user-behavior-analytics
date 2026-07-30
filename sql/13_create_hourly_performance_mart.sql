USE jd_user_behavior;

-- 13 Create Hourly Performance Mart

-- 1. Remove previous working and output tables

DROP TABLE IF EXISTS mart_hourly_performance;
DROP TABLE IF EXISTS mart_date_hour_performance;
DROP TABLE IF EXISTS work_user_hourly;
DROP TABLE IF EXISTS work_user_product_hourly;



-- 2. Create hourly user-product working table

CREATE TABLE work_user_product_hourly (
    action_date          DATE NOT NULL,
    hour_of_day          TINYINT UNSIGNED NOT NULL,
    user_id              BIGINT NOT NULL,
    sku_id               BIGINT NOT NULL,

    browse_count         INT UNSIGNED NOT NULL DEFAULT 0,
    cart_add_count       INT UNSIGNED NOT NULL DEFAULT 0,
    cart_remove_count    INT UNSIGNED NOT NULL DEFAULT 0,
    purchase_count       INT UNSIGNED NOT NULL DEFAULT 0,
    follow_count         INT UNSIGNED NOT NULL DEFAULT 0,
    click_count          INT UNSIGNED NOT NULL DEFAULT 0,
    total_action_count   INT UNSIGNED NOT NULL DEFAULT 0
) ENGINE = InnoDB;


-- 3. Aggregate raw actions to date-hour-user-product level

INSERT INTO work_user_product_hourly (
    action_date,
    hour_of_day,
    user_id,
    sku_id,

    browse_count,
    cart_add_count,
    cart_remove_count,
    purchase_count,
    follow_count,
    click_count,
    total_action_count
)

SELECT
    DATE(action_time) AS action_date,
    HOUR(action_time) AS hour_of_day,
    CAST(user_id AS UNSIGNED) AS user_id,
    sku_id,

    SUM(action_type = 1) AS browse_count,
    SUM(action_type = 2) AS cart_add_count,
    SUM(action_type = 3) AS cart_remove_count,
    SUM(action_type = 4) AS purchase_count,
    SUM(action_type = 5) AS follow_count,
    SUM(action_type = 6) AS click_count,

    COUNT(*) AS total_action_count

FROM stg_actions

GROUP BY
    DATE(action_time),
    HOUR(action_time),
    CAST(user_id AS UNSIGNED),
    sku_id;


-- 4. Create date-hour-user working table

CREATE TABLE work_user_hourly (
    action_date                       DATE NOT NULL,
    hour_of_day                       TINYINT UNSIGNED NOT NULL,
    user_id                           BIGINT NOT NULL,

    interest_flag                     TINYINT(1) NOT NULL,
    follow_flag                       TINYINT(1) NOT NULL,
    cart_add_flag                     TINYINT(1) NOT NULL,
    same_hour_cart_converted_flag     TINYINT(1) NOT NULL,
    purchase_flag                     TINYINT(1) NOT NULL,

    PRIMARY KEY (
        action_date,
        hour_of_day,
        user_id
    )
) ENGINE = InnoDB;


INSERT INTO work_user_hourly (
    action_date,
    hour_of_day,
    user_id,

    interest_flag,
    follow_flag,
    cart_add_flag,
    same_hour_cart_converted_flag,
    purchase_flag
)

SELECT
    action_date,
    hour_of_day,
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
            WHEN cart_add_count > 0
             AND purchase_count > 0
            THEN 1
            ELSE 0
        END
    ) AS same_hour_cart_converted_flag,

    MAX(
        CASE
            WHEN purchase_count > 0
            THEN 1
            ELSE 0
        END
    ) AS purchase_flag

FROM work_user_product_hourly

GROUP BY
    action_date,
    hour_of_day,
    user_id;


-- 5. Create date-hour performance table

CREATE TABLE mart_date_hour_performance (
    action_date                       DATE NOT NULL,
    hour_of_day                       TINYINT UNSIGNED NOT NULL,

    active_users                      INT UNSIGNED NOT NULL,
    active_products                   INT UNSIGNED NOT NULL,

    interested_users                  INT UNSIGNED NOT NULL,
    followed_users                    INT UNSIGNED NOT NULL,
    cart_users                        INT UNSIGNED NOT NULL,
    same_hour_cart_converted_users    INT UNSIGNED NOT NULL,
    same_hour_cart_abandon_users      INT UNSIGNED NOT NULL,
    buyers                            INT UNSIGNED NOT NULL,

    browse_count                      BIGINT UNSIGNED NOT NULL,
    cart_add_count                    BIGINT UNSIGNED NOT NULL,
    cart_remove_count                 BIGINT UNSIGNED NOT NULL,
    purchase_count                    BIGINT UNSIGNED NOT NULL,
    follow_count                      BIGINT UNSIGNED NOT NULL,
    click_count                       BIGINT UNSIGNED NOT NULL,
    total_action_count                BIGINT UNSIGNED NOT NULL,

    interest_to_cart_rate             DECIMAL(10, 4),
    same_hour_cart_conversion_rate    DECIMAL(10, 4),
    same_hour_cart_abandonment_rate   DECIMAL(10, 4),
    active_user_conversion_rate       DECIMAL(10, 4),

    PRIMARY KEY (
        action_date,
        hour_of_day
    ),

    INDEX idx_date_hour_hour (
        hour_of_day
    )
) ENGINE = InnoDB;


-- 6. Insert date-hour performance

INSERT INTO mart_date_hour_performance (
    action_date,
    hour_of_day,

    active_users,
    active_products,

    interested_users,
    followed_users,
    cart_users,
    same_hour_cart_converted_users,
    same_hour_cart_abandon_users,
    buyers,

    browse_count,
    cart_add_count,
    cart_remove_count,
    purchase_count,
    follow_count,
    click_count,
    total_action_count,

    interest_to_cart_rate,
    same_hour_cart_conversion_rate,
    same_hour_cart_abandonment_rate,
    active_user_conversion_rate
)

SELECT
    action_metrics.action_date,
    action_metrics.hour_of_day,

    user_metrics.active_users,
    action_metrics.active_products,

    user_metrics.interested_users,
    user_metrics.followed_users,
    user_metrics.cart_users,
    user_metrics.same_hour_cart_converted_users,
    user_metrics.same_hour_cart_abandon_users,
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
        * user_metrics.same_hour_cart_converted_users
        / NULLIF(user_metrics.cart_users, 0),
        4
    ) AS same_hour_cart_conversion_rate,

    ROUND(
        100.0
        * user_metrics.same_hour_cart_abandon_users
        / NULLIF(user_metrics.cart_users, 0),
        4
    ) AS same_hour_cart_abandonment_rate,

    ROUND(
        100.0
        * user_metrics.buyers
        / NULLIF(user_metrics.active_users, 0),
        4
    ) AS active_user_conversion_rate

FROM (
    SELECT
        action_date,
        hour_of_day,

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

    FROM work_user_product_hourly

    GROUP BY
        action_date,
        hour_of_day
) AS action_metrics

INNER JOIN (
    SELECT
        action_date,
        hour_of_day,

        COUNT(*)
            AS active_users,

        SUM(interest_flag)
            AS interested_users,

        SUM(follow_flag)
            AS followed_users,

        SUM(cart_add_flag)
            AS cart_users,

        SUM(same_hour_cart_converted_flag)
            AS same_hour_cart_converted_users,

        SUM(
            CASE
                WHEN cart_add_flag = 1
                 AND same_hour_cart_converted_flag = 0
                THEN 1
                ELSE 0
            END
        ) AS same_hour_cart_abandon_users,

        SUM(purchase_flag)
            AS buyers

    FROM work_user_hourly

    GROUP BY
        action_date,
        hour_of_day
) AS user_metrics

    ON action_metrics.action_date =
       user_metrics.action_date

   AND action_metrics.hour_of_day =
       user_metrics.hour_of_day;



-- 7. Create final hourly performance table


CREATE TABLE mart_hourly_performance (
    hour_of_day                       TINYINT UNSIGNED NOT NULL,
    hour_label                        VARCHAR(20) NOT NULL,

    observed_date_hours               SMALLINT UNSIGNED NOT NULL,

    avg_active_users                  DECIMAL(14, 2),
    avg_active_products               DECIMAL(14, 2),
    avg_interested_users              DECIMAL(14, 2),
    avg_cart_users                    DECIMAL(14, 2),
    avg_buyers                        DECIMAL(14, 2),

    avg_browse_count                  DECIMAL(16, 2),
    avg_cart_add_count                DECIMAL(16, 2),
    avg_cart_remove_count             DECIMAL(16, 2),
    avg_purchase_count                DECIMAL(16, 2),
    avg_follow_count                  DECIMAL(16, 2),
    avg_click_count                   DECIMAL(16, 2),
    avg_total_action_count            DECIMAL(16, 2),

    total_action_count                BIGINT UNSIGNED NOT NULL,
    total_purchase_count              BIGINT UNSIGNED NOT NULL,

    avg_interest_to_cart_rate         DECIMAL(10, 4),
    avg_cart_conversion_rate          DECIMAL(10, 4),
    avg_cart_abandonment_rate         DECIMAL(10, 4),
    avg_user_conversion_rate          DECIMAL(10, 4),

    action_share_pct                  DECIMAL(10, 4),
    purchase_share_pct                DECIMAL(10, 4),

    PRIMARY KEY (hour_of_day)
) ENGINE = InnoDB;


-- 8. Insert hourly performance


INSERT INTO mart_hourly_performance (
    hour_of_day,
    hour_label,

    observed_date_hours,

    avg_active_users,
    avg_active_products,
    avg_interested_users,
    avg_cart_users,
    avg_buyers,

    avg_browse_count,
    avg_cart_add_count,
    avg_cart_remove_count,
    avg_purchase_count,
    avg_follow_count,
    avg_click_count,
    avg_total_action_count,

    total_action_count,
    total_purchase_count,

    avg_interest_to_cart_rate,
    avg_cart_conversion_rate,
    avg_cart_abandonment_rate,
    avg_user_conversion_rate,

    action_share_pct,
    purchase_share_pct
)

SELECT
    hourly.hour_of_day,

    CONCAT(
        LPAD(hourly.hour_of_day, 2, '0'),
        ':00-',
        LPAD(
            MOD(hourly.hour_of_day + 1, 24),
            2,
            '0'
        ),
        ':00'
    ) AS hour_label,

    hourly.observed_date_hours,

    hourly.avg_active_users,
    hourly.avg_active_products,
    hourly.avg_interested_users,
    hourly.avg_cart_users,
    hourly.avg_buyers,

    hourly.avg_browse_count,
    hourly.avg_cart_add_count,
    hourly.avg_cart_remove_count,
    hourly.avg_purchase_count,
    hourly.avg_follow_count,
    hourly.avg_click_count,
    hourly.avg_total_action_count,

    hourly.total_action_count,
    hourly.total_purchase_count,

    hourly.avg_interest_to_cart_rate,
    hourly.avg_cart_conversion_rate,
    hourly.avg_cart_abandonment_rate,
    hourly.avg_user_conversion_rate,

    ROUND(
        100.0
        * hourly.total_action_count
        / NULLIF(totals.all_actions, 0),
        4
    ) AS action_share_pct,

    ROUND(
        100.0
        * hourly.total_purchase_count
        / NULLIF(totals.all_purchases, 0),
        4
    ) AS purchase_share_pct

FROM (
    SELECT
        hour_of_day,

        COUNT(*)
            AS observed_date_hours,

        ROUND(AVG(active_users), 2)
            AS avg_active_users,

        ROUND(AVG(active_products), 2)
            AS avg_active_products,

        ROUND(AVG(interested_users), 2)
            AS avg_interested_users,

        ROUND(AVG(cart_users), 2)
            AS avg_cart_users,

        ROUND(AVG(buyers), 2)
            AS avg_buyers,

        ROUND(AVG(browse_count), 2)
            AS avg_browse_count,

        ROUND(AVG(cart_add_count), 2)
            AS avg_cart_add_count,

        ROUND(AVG(cart_remove_count), 2)
            AS avg_cart_remove_count,

        ROUND(AVG(purchase_count), 2)
            AS avg_purchase_count,

        ROUND(AVG(follow_count), 2)
            AS avg_follow_count,

        ROUND(AVG(click_count), 2)
            AS avg_click_count,

        ROUND(AVG(total_action_count), 2)
            AS avg_total_action_count,

        SUM(total_action_count)
            AS total_action_count,

        SUM(purchase_count)
            AS total_purchase_count,

        ROUND(
            AVG(interest_to_cart_rate),
            4
        ) AS avg_interest_to_cart_rate,

        ROUND(
            AVG(same_hour_cart_conversion_rate),
            4
        ) AS avg_cart_conversion_rate,

        ROUND(
            AVG(same_hour_cart_abandonment_rate),
            4
        ) AS avg_cart_abandonment_rate,

        ROUND(
            AVG(active_user_conversion_rate),
            4
        ) AS avg_user_conversion_rate

    FROM mart_date_hour_performance

    GROUP BY hour_of_day
) AS hourly

CROSS JOIN (
    SELECT
        SUM(total_action_count)
            AS all_actions,

        SUM(purchase_count)
            AS all_purchases

    FROM mart_date_hour_performance
) AS totals;


-- 9. Validate date-hour action totals

SELECT
    COUNT(*) AS date_hour_rows,

    COUNT(DISTINCT action_date)
        AS observed_dates,

    MIN(action_date)
        AS earliest_date,

    MAX(action_date)
        AS latest_date,

    SUM(total_action_count)
        AS reconstructed_actions,

    SUM(purchase_count)
        AS reconstructed_purchases

FROM mart_date_hour_performance;

-- 10. Validate hourly table

SELECT
    COUNT(*) AS hourly_rows,

    SUM(total_action_count)
        AS reconstructed_actions,

    SUM(total_purchase_count)
        AS reconstructed_purchases,

    ROUND(
        SUM(action_share_pct),
        2
    ) AS total_action_share_pct,

    ROUND(
        SUM(purchase_share_pct),
        2
    ) AS total_purchase_share_pct

FROM mart_hourly_performance;


-- 11. Hourly performance report

SELECT
    hour_of_day,
    hour_label,

    observed_date_hours,

    avg_active_users,
    avg_total_action_count,
    avg_purchase_count,

    avg_user_conversion_rate,
    avg_cart_conversion_rate,
    avg_cart_abandonment_rate,

    action_share_pct,
    purchase_share_pct

FROM mart_hourly_performance

ORDER BY hour_of_day;


-- 12. Peak purchase hours

SELECT
    hour_of_day,
    hour_label,

    avg_active_users,
    avg_buyers,
    avg_purchase_count,

    avg_user_conversion_rate,
    avg_cart_conversion_rate,
    avg_cart_abandonment_rate,

    purchase_share_pct

FROM mart_hourly_performance

ORDER BY
    avg_purchase_count DESC,
    avg_user_conversion_rate DESC

LIMIT 10;

-- 13. Remove processing tables

DROP TABLE IF EXISTS work_user_hourly;
DROP TABLE IF EXISTS work_user_product_hourly;
