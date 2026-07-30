USE jd_user_behavior;

-- Daily user-product behavior fact table

DROP TABLE IF EXISTS fact_user_product_daily;

CREATE TABLE fact_user_product_daily (
    action_date          DATE NOT NULL,
    user_id              BIGINT NOT NULL,
    sku_id               BIGINT NOT NULL,

    category_id          SMALLINT,
    brand_id             INT,

    browse_count         INT UNSIGNED NOT NULL DEFAULT 0,
    cart_add_count       INT UNSIGNED NOT NULL DEFAULT 0,
    cart_remove_count    INT UNSIGNED NOT NULL DEFAULT 0,
    purchase_count       INT UNSIGNED NOT NULL DEFAULT 0,
    follow_count         INT UNSIGNED NOT NULL DEFAULT 0,
    click_count          INT UNSIGNED NOT NULL DEFAULT 0,

    total_action_count   INT UNSIGNED NOT NULL DEFAULT 0,

    first_action_time    DATETIME NOT NULL,
    last_action_time     DATETIME NOT NULL
) ENGINE = InnoDB;


-- Aggregate 50 million raw actions

INSERT INTO fact_user_product_daily (
    action_date,
    user_id,
    sku_id,
    category_id,
    brand_id,
    browse_count,
    cart_add_count,
    cart_remove_count,
    purchase_count,
    follow_count,
    click_count,
    total_action_count,
    first_action_time,
    last_action_time
)
SELECT
    DATE(action_time) AS action_date,
    CAST(user_id AS UNSIGNED) AS user_id,
    sku_id,

    MAX(cate) AS category_id,
    MAX(brand) AS brand_id,

    SUM(action_type = 1) AS browse_count,
    SUM(action_type = 2) AS cart_add_count,
    SUM(action_type = 3) AS cart_remove_count,
    SUM(action_type = 4) AS purchase_count,
    SUM(action_type = 5) AS follow_count,
    SUM(action_type = 6) AS click_count,

    COUNT(*) AS total_action_count,

    MIN(action_time) AS first_action_time,
    MAX(action_time) AS last_action_time

FROM stg_actions

GROUP BY
    DATE(action_time),
    CAST(user_id AS UNSIGNED),
    sku_id;


-- Add indexes after loading

ALTER TABLE fact_user_product_daily
ADD PRIMARY KEY (
    action_date,
    user_id,
    sku_id
);

CREATE INDEX idx_daily_user_date
ON fact_user_product_daily (
    user_id,
    action_date
);

CREATE INDEX idx_daily_sku_date
ON fact_user_product_daily (
    sku_id,
    action_date
);

CREATE INDEX idx_daily_category_date
ON fact_user_product_daily (
    category_id,
    action_date
);

CREATE INDEX idx_daily_brand_date
ON fact_user_product_daily (
    brand_id,
    action_date
);



-- Verification 1: total actions
SELECT
    COUNT(*) AS aggregated_rows,
    SUM(total_action_count) AS reconstructed_actions,
    MIN(action_date) AS earliest_date,
    MAX(action_date) AS latest_date
FROM fact_user_product_daily;



-- Verification 2: behavior totals

SELECT
    SUM(browse_count) AS browse_actions,
    SUM(cart_add_count) AS cart_add_actions,
    SUM(cart_remove_count) AS cart_remove_actions,
    SUM(purchase_count) AS purchase_actions,
    SUM(follow_count) AS follow_actions,
    SUM(click_count) AS click_actions
FROM fact_user_product_daily;
