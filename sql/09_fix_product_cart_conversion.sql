USE jd_user_behavior;


-- 09 Fix Product Cart Conversion Metrics


-- 1. Add cart_converted_users only when it does not exist


SET @column_exists = (
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'mart_product_performance'
      AND column_name = 'cart_converted_users'
);

SET @add_column_sql = IF(
    @column_exists = 0,

    'ALTER TABLE mart_product_performance
     ADD COLUMN cart_converted_users
     INT UNSIGNED NOT NULL DEFAULT 0
     AFTER cart_users',

    'SELECT
        ''cart_converted_users already exists''
        AS column_status'
);

PREPARE add_column_statement
FROM @add_column_sql;

EXECUTE add_column_statement;

DEALLOCATE PREPARE add_column_statement;


-- 2. Temporarily disable safe update mode

SET @previous_safe_updates = @@SQL_SAFE_UPDATES;

SET SQL_SAFE_UPDATES = 0;


-- 3. Recalculate strict cart conversion metrics

UPDATE mart_product_performance AS product

INNER JOIN (
    SELECT
        sku_id,

        SUM(
            CASE
                WHEN cart_add_flag = 1
                 AND purchase_flag = 1
                THEN 1
                ELSE 0
            END
        ) AS cart_converted_users,

        SUM(
            CASE
                WHEN cart_add_flag = 1
                 AND purchase_flag = 0
                THEN 1
                ELSE 0
            END
        ) AS cart_abandon_users

    FROM mart_user_product_period

    GROUP BY sku_id
) AS conversion
    ON product.sku_id = conversion.sku_id

SET
    product.cart_converted_users =
        conversion.cart_converted_users,

    product.cart_abandon_users =
        conversion.cart_abandon_users,

    product.cart_to_purchase_rate =
        ROUND(
            100.0
            * conversion.cart_converted_users
            / NULLIF(product.cart_users, 0),
            4
        ),

    product.cart_abandonment_rate =
        ROUND(
            100.0
            * conversion.cart_abandon_users
            / NULLIF(product.cart_users, 0),
            4
        );


-- 4. Restore previous safe update setting

SET SQL_SAFE_UPDATES = @previous_safe_updates;



-- 5. Validation: product-level consistency

SELECT
    COUNT(*) AS inconsistent_products

FROM mart_product_performance

WHERE cart_users <>
      cart_converted_users + cart_abandon_users;


-- 6. Validation: overall cart-user totals


SELECT
    SUM(cart_users)
        AS total_cart_users,

    SUM(cart_converted_users)
        AS total_converted_cart_users,

    SUM(cart_abandon_users)
        AS total_abandoned_cart_users,

    SUM(cart_converted_users)
    + SUM(cart_abandon_users)
        AS reconstructed_cart_users

FROM mart_product_performance;


-- 7. Overall strict cart conversion rates


SELECT
    SUM(cart_users) AS total_cart_users,

    SUM(cart_converted_users)
        AS converted_cart_users,

    SUM(cart_abandon_users)
        AS abandoned_cart_users,

    ROUND(
        100.0
        * SUM(cart_converted_users)
        / NULLIF(SUM(cart_users), 0),
        2
    ) AS overall_cart_to_purchase_rate_pct,

    ROUND(
        100.0
        * SUM(cart_abandon_users)
        / NULLIF(SUM(cart_users), 0),
        2
    ) AS overall_cart_abandonment_rate_pct

FROM mart_product_performance;


-- 8. Products with severe cart abandonment

SELECT
    sku_id,
    category_id,
    brand_id,

    interacting_users,
    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,

    cart_to_purchase_rate,
    cart_abandonment_rate

FROM mart_product_performance

WHERE cart_users >= 20

ORDER BY
    cart_abandonment_rate DESC,
    cart_users DESC,
    sku_id

LIMIT 20;


-- 9. Products with the strongest cart conversion

SELECT
    sku_id,
    category_id,
    brand_id,

    interacting_users,
    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,

    cart_to_purchase_rate,
    cart_abandonment_rate

FROM mart_product_performance

WHERE cart_users >= 20

ORDER BY
    cart_to_purchase_rate DESC,
    cart_users DESC,
    sku_id

LIMIT 20;
