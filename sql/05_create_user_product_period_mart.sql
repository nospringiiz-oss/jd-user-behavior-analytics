USE jd_user_behavior;


-- User-product behavior summary for the complete period

DROP TABLE IF EXISTS mart_user_product_period;

CREATE TABLE mart_user_product_period (
    user_id               BIGINT NOT NULL,
    sku_id                BIGINT NOT NULL,

    category_id           SMALLINT,
    brand_id              INT,

    active_days           SMALLINT UNSIGNED NOT NULL,

    browse_count          INT UNSIGNED NOT NULL DEFAULT 0,
    cart_add_count        INT UNSIGNED NOT NULL DEFAULT 0,
    cart_remove_count     INT UNSIGNED NOT NULL DEFAULT 0,
    purchase_count        INT UNSIGNED NOT NULL DEFAULT 0,
    follow_count          INT UNSIGNED NOT NULL DEFAULT 0,
    click_count           INT UNSIGNED NOT NULL DEFAULT 0,
    total_action_count    INT UNSIGNED NOT NULL DEFAULT 0,

    first_action_time     DATETIME NOT NULL,
    last_action_time      DATETIME NOT NULL,

    interest_flag         TINYINT(1) NOT NULL DEFAULT 0,
    follow_flag           TINYINT(1) NOT NULL DEFAULT 0,
    cart_add_flag         TINYINT(1) NOT NULL DEFAULT 0,
    purchase_flag         TINYINT(1) NOT NULL DEFAULT 0,
    cart_abandon_flag     TINYINT(1) NOT NULL DEFAULT 0
) ENGINE = InnoDB;


-- Aggregate daily behavior into period-level behavior

INSERT INTO mart_user_product_period (
    user_id,
    sku_id,
    category_id,
    brand_id,
    active_days,
    browse_count,
    cart_add_count,
    cart_remove_count,
    purchase_count,
    follow_count,
    click_count,
    total_action_count,
    first_action_time,
    last_action_time,
    interest_flag,
    follow_flag,
    cart_add_flag,
    purchase_flag,
    cart_abandon_flag
)
SELECT
    user_id,
    sku_id,

    MAX(category_id) AS category_id,
    MAX(brand_id) AS brand_id,

    COUNT(*) AS active_days,

    SUM(browse_count) AS browse_count,
    SUM(cart_add_count) AS cart_add_count,
    SUM(cart_remove_count) AS cart_remove_count,
    SUM(purchase_count) AS purchase_count,
    SUM(follow_count) AS follow_count,
    SUM(click_count) AS click_count,
    SUM(total_action_count) AS total_action_count,

    MIN(first_action_time) AS first_action_time,
    MAX(last_action_time) AS last_action_time,

    CASE
        WHEN SUM(browse_count) + SUM(click_count) > 0
        THEN 1
        ELSE 0
    END AS interest_flag,

    CASE
        WHEN SUM(follow_count) > 0
        THEN 1
        ELSE 0
    END AS follow_flag,

    CASE
        WHEN SUM(cart_add_count) > 0
        THEN 1
        ELSE 0
    END AS cart_add_flag,

    CASE
        WHEN SUM(purchase_count) > 0
        THEN 1
        ELSE 0
    END AS purchase_flag,

    CASE
        WHEN SUM(cart_add_count) > 0
         AND SUM(purchase_count) = 0
        THEN 1
        ELSE 0
    END AS cart_abandon_flag

FROM fact_user_product_daily

GROUP BY
    user_id,
    sku_id;


-- Add keys and indexes after loading

ALTER TABLE mart_user_product_period
ADD PRIMARY KEY (
    user_id,
    sku_id
);

CREATE INDEX idx_upp_sku
ON mart_user_product_period (
    sku_id
);

CREATE INDEX idx_upp_category
ON mart_user_product_period (
    category_id
);

CREATE INDEX idx_upp_brand
ON mart_user_product_period (
    brand_id
);

CREATE INDEX idx_upp_purchase
ON mart_user_product_period (
    purchase_flag
);

CREATE INDEX idx_upp_cart_abandon
ON mart_user_product_period (
    cart_abandon_flag
);


-- Verification 1: row and action totals

SELECT
    COUNT(*) AS user_product_rows,
    COUNT(DISTINCT user_id) AS active_users,
    COUNT(DISTINCT sku_id) AS active_products,
    SUM(total_action_count) AS reconstructed_actions,
    MIN(first_action_time) AS earliest_action,
    MAX(last_action_time) AS latest_action
FROM mart_user_product_period;


-- Verification 2: behavior totals

SELECT
    SUM(browse_count) AS browse_actions,
    SUM(cart_add_count) AS cart_add_actions,
    SUM(cart_remove_count) AS cart_remove_actions,
    SUM(purchase_count) AS purchase_actions,
    SUM(follow_count) AS follow_actions,
    SUM(click_count) AS click_actions
FROM mart_user_product_period;

-- Verification 3: user-product conversion status

SELECT
    SUM(interest_flag) AS interested_user_products,
    SUM(follow_flag) AS followed_user_products,
    SUM(cart_add_flag) AS cart_user_products,
    SUM(purchase_flag) AS purchased_user_products,
    SUM(cart_abandon_flag) AS abandoned_user_products,

    ROUND(
        100.0 * SUM(purchase_flag)
        / NULLIF(SUM(cart_add_flag), 0),
        2
    ) AS cart_to_purchase_rate_pct,

    ROUND(
        100.0 * SUM(cart_abandon_flag)
        / NULLIF(SUM(cart_add_flag), 0),
        2
    ) AS cart_abandonment_rate_pct

FROM mart_user_product_period;
