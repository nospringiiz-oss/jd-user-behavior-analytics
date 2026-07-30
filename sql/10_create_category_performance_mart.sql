USE jd_user_behavior;

-- 10 Create Category Performance Mart



-- 1. Create category performance table


DROP TABLE IF EXISTS mart_category_performance;

CREATE TABLE mart_category_performance (
    category_id                 SMALLINT NOT NULL,

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

    PRIMARY KEY (category_id),

    INDEX idx_category_cart_conversion (
        cart_to_purchase_rate
    ),

    INDEX idx_category_abandonment (
        cart_abandonment_rate
    ),

    INDEX idx_category_buyers (
        buyers
    )
) ENGINE = InnoDB;



-- 2. Insert category-level performance

INSERT INTO mart_category_performance (
    category_id,

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
    action_metrics.category_id,

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
        category_id,

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

    WHERE category_id IS NOT NULL

    GROUP BY category_id
) AS action_metrics

INNER JOIN (
    SELECT
        user_category.category_id,

        COUNT(*)
            AS interacting_users,

        SUM(user_category.interest_flag)
            AS interested_users,

        SUM(user_category.follow_flag)
            AS followed_users,

        SUM(user_category.cart_add_flag)
            AS cart_users,

        SUM(user_category.cart_converted_flag)
            AS cart_converted_users,

        SUM(
            CASE
                WHEN user_category.cart_add_flag = 1
                 AND user_category.cart_converted_flag = 0
                THEN 1
                ELSE 0
            END
        ) AS cart_abandon_users,

        SUM(user_category.purchase_flag)
            AS buyers

    FROM (
        SELECT
            user_id,
            category_id,

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

        WHERE category_id IS NOT NULL

        GROUP BY
            user_id,
            category_id
    ) AS user_category

    GROUP BY user_category.category_id
) AS user_metrics
    ON action_metrics.category_id =
       user_metrics.category_id

LEFT JOIN (
    SELECT
        category_id,

        SUM(
            latest_comment_date IS NOT NULL
        ) AS products_with_comments,

        ROUND(
            AVG(bad_comment_rate),
            6
        ) AS avg_bad_comment_rate

    FROM mart_product_performance

    WHERE category_id IS NOT NULL

    GROUP BY category_id
) AS comment_metrics
    ON action_metrics.category_id =
       comment_metrics.category_id;


-- 3. Validation: reconstruct all actions

SELECT
    COUNT(*) AS active_categories,

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

FROM mart_category_performance;



-- 4. Validation: cart-user consistency

SELECT
    COUNT(*) AS inconsistent_categories

FROM mart_category_performance

WHERE cart_users <>
      cart_converted_users + cart_abandon_users;


-- 5. Category performance report

SELECT
    category_id,

    active_products,
    interacting_users,
    interested_users,
    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,

    purchase_count,

    interest_to_cart_rate,
    cart_to_purchase_rate,
    cart_abandonment_rate,
    overall_conversion_rate,

    products_with_comments,
    avg_bad_comment_rate

FROM mart_category_performance

ORDER BY
    buyers DESC,
    cart_to_purchase_rate DESC;



-- 6. Categories with strongest cart conversion

SELECT
    category_id,

    cart_users,
    cart_converted_users,
    cart_abandon_users,

    cart_to_purchase_rate,
    cart_abandonment_rate,

    buyers,
    overall_conversion_rate

FROM mart_category_performance

ORDER BY
    cart_to_purchase_rate DESC,
    cart_users DESC;


-- 7. Categories with severe cart abandonment

SELECT
    category_id,

    cart_users,
    cart_converted_users,
    cart_abandon_users,

    cart_to_purchase_rate,
    cart_abandonment_rate,

    interested_users,
    buyers

FROM mart_category_performance

ORDER BY
    cart_abandonment_rate DESC,
    cart_users DESC;
