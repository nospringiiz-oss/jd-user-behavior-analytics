USE jd_user_behavior;

-- =========================================================
-- Product performance analytical mart
-- Grain: one row per active product
-- =========================================================

DROP TABLE IF EXISTS mart_product_performance;

CREATE TABLE mart_product_performance (
    sku_id                    BIGINT NOT NULL,
    category_id               SMALLINT,
    brand_id                  INT,

    attribute_a1              SMALLINT,
    attribute_a2              SMALLINT,
    attribute_a3              SMALLINT,

    interacting_users         INT UNSIGNED NOT NULL,
    interested_users          INT UNSIGNED NOT NULL,
    followed_users            INT UNSIGNED NOT NULL,
    cart_users                INT UNSIGNED NOT NULL,
    buyers                    INT UNSIGNED NOT NULL,
    cart_abandon_users        INT UNSIGNED NOT NULL,

    browse_count              BIGINT UNSIGNED NOT NULL,
    cart_add_count            BIGINT UNSIGNED NOT NULL,
    cart_remove_count         BIGINT UNSIGNED NOT NULL,
    purchase_count            BIGINT UNSIGNED NOT NULL,
    follow_count              BIGINT UNSIGNED NOT NULL,
    click_count               BIGINT UNSIGNED NOT NULL,
    total_action_count        BIGINT UNSIGNED NOT NULL,

    interest_to_cart_rate     DECIMAL(10, 4),
    cart_to_purchase_rate     DECIMAL(10, 4),
    overall_conversion_rate   DECIMAL(10, 4),
    cart_abandonment_rate     DECIMAL(10, 4),

    latest_comment_date       DATE,
    latest_comment_level      INT,
    has_bad_comment           TINYINT,
    bad_comment_rate          DECIMAL(10, 6),

    first_action_time         DATETIME NOT NULL,
    last_action_time          DATETIME NOT NULL,

    PRIMARY KEY (sku_id)
) ENGINE = InnoDB;


-- =========================================================
-- Insert product-level performance metrics
-- =========================================================

INSERT INTO mart_product_performance (
    sku_id,
    category_id,
    brand_id,

    attribute_a1,
    attribute_a2,
    attribute_a3,

    interacting_users,
    interested_users,
    followed_users,
    cart_users,
    buyers,
    cart_abandon_users,

    browse_count,
    cart_add_count,
    cart_remove_count,
    purchase_count,
    follow_count,
    click_count,
    total_action_count,

    interest_to_cart_rate,
    cart_to_purchase_rate,
    overall_conversion_rate,
    cart_abandonment_rate,

    latest_comment_date,
    latest_comment_level,
    has_bad_comment,
    bad_comment_rate,

    first_action_time,
    last_action_time
)

SELECT
    product_metrics.sku_id,

    COALESCE(
        products.category_id,
        product_metrics.category_id
    ) AS category_id,

    COALESCE(
        products.brand_id,
        product_metrics.brand_id
    ) AS brand_id,

    products.attribute_a1,
    products.attribute_a2,
    products.attribute_a3,

    product_metrics.interacting_users,
    product_metrics.interested_users,
    product_metrics.followed_users,
    product_metrics.cart_users,
    product_metrics.buyers,
    product_metrics.cart_abandon_users,

    product_metrics.browse_count,
    product_metrics.cart_add_count,
    product_metrics.cart_remove_count,
    product_metrics.purchase_count,
    product_metrics.follow_count,
    product_metrics.click_count,
    product_metrics.total_action_count,

    ROUND(
        100.0 * product_metrics.cart_users
        / NULLIF(product_metrics.interested_users, 0),
        4
    ) AS interest_to_cart_rate,

    ROUND(
        100.0 * product_metrics.buyers
        / NULLIF(product_metrics.cart_users, 0),
        4
    ) AS cart_to_purchase_rate,

    ROUND(
        100.0 * product_metrics.buyers
        / NULLIF(product_metrics.interacting_users, 0),
        4
    ) AS overall_conversion_rate,

    ROUND(
        100.0 * product_metrics.cart_abandon_users
        / NULLIF(product_metrics.cart_users, 0),
        4
    ) AS cart_abandonment_rate,

    latest_comments.comment_date,
    latest_comments.comment_num,
    latest_comments.has_bad_comment,
    latest_comments.bad_comment_rate,

    product_metrics.first_action_time,
    product_metrics.last_action_time

FROM (
    SELECT
        sku_id,

        MAX(category_id) AS category_id,
        MAX(brand_id) AS brand_id,

        COUNT(*) AS interacting_users,
        SUM(interest_flag) AS interested_users,
        SUM(follow_flag) AS followed_users,
        SUM(cart_add_flag) AS cart_users,
        SUM(purchase_flag) AS buyers,
        SUM(cart_abandon_flag) AS cart_abandon_users,

        SUM(browse_count) AS browse_count,
        SUM(cart_add_count) AS cart_add_count,
        SUM(cart_remove_count) AS cart_remove_count,
        SUM(purchase_count) AS purchase_count,
        SUM(follow_count) AS follow_count,
        SUM(click_count) AS click_count,
        SUM(total_action_count) AS total_action_count,

        MIN(first_action_time) AS first_action_time,
        MAX(last_action_time) AS last_action_time

    FROM mart_user_product_period

    GROUP BY sku_id
) AS product_metrics

LEFT JOIN dim_products AS products
    ON product_metrics.sku_id = products.sku_id

LEFT JOIN (
    SELECT
        comments.comment_date,
        comments.sku_id,
        comments.comment_num,
        comments.has_bad_comment,
        comments.bad_comment_rate

    FROM fact_comments AS comments

    INNER JOIN (
        SELECT
            sku_id,
            MAX(comment_date) AS latest_comment_date

        FROM fact_comments

        GROUP BY sku_id
    ) AS latest
        ON comments.sku_id = latest.sku_id
       AND comments.comment_date = latest.latest_comment_date
) AS latest_comments
    ON product_metrics.sku_id = latest_comments.sku_id;


-- =========================================================
-- Add indexes
-- =========================================================

CREATE INDEX idx_product_category
ON mart_product_performance (category_id);

CREATE INDEX idx_product_brand
ON mart_product_performance (brand_id);

CREATE INDEX idx_product_buyers
ON mart_product_performance (buyers);

CREATE INDEX idx_product_cart_abandonment
ON mart_product_performance (cart_abandonment_rate);


-- =========================================================
-- Verification 1
-- reconstructed_actions must equal 50,601,736
-- =========================================================

SELECT
    COUNT(*) AS active_products,
    SUM(total_action_count) AS reconstructed_actions,

    SUM(browse_count) AS browse_actions,
    SUM(cart_add_count) AS cart_add_actions,
    SUM(cart_remove_count) AS cart_remove_actions,
    SUM(purchase_count) AS purchase_actions,
    SUM(follow_count) AS follow_actions,
    SUM(click_count) AS click_actions

FROM mart_product_performance;


-- =========================================================
-- Verification 2: highest cart-abandonment products
-- Require at least 20 cart users to reduce small-sample noise.
-- =========================================================

SELECT
    sku_id,
    category_id,
    brand_id,
    interacting_users,
    cart_users,
    buyers,
    cart_abandon_users,
    cart_to_purchase_rate,
    cart_abandonment_rate

FROM mart_product_performance

WHERE cart_users >= 20

ORDER BY
    cart_abandonment_rate DESC,
    cart_users DESC

LIMIT 20;