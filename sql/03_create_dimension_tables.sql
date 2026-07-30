USE jd_user_behavior;

-- =========================================================
-- 1. Clean user dimension
-- =========================================================

DROP TABLE IF EXISTS dim_users;

CREATE TABLE dim_users (
    user_id             BIGINT NOT NULL,
    age_group           VARCHAR(20) NOT NULL,
    sex_code            TINYINT,
    user_level          TINYINT,
    registration_date   DATE,
    age_unknown_flag    TINYINT(1) NOT NULL DEFAULT 0,

    PRIMARY KEY (user_id),
    INDEX idx_user_level (user_level),
    INDEX idx_registration_date (registration_date)
) ENGINE = InnoDB;


INSERT INTO dim_users (
    user_id,
    age_group,
    sex_code,
    user_level,
    registration_date,
    age_unknown_flag
)
SELECT
    user_id,

    CASE
        WHEN age IS NULL
          OR TRIM(age) = ''
          OR age = '-1'
        THEN 'Unknown'
        ELSE age
    END AS age_group,

    CASE
        WHEN sex IN (0, 1, 2)
        THEN sex
        ELSE NULL
    END AS sex_code,

    user_lv_cd,
    user_reg_tm,

    CASE
        WHEN age IS NULL
          OR TRIM(age) = ''
          OR age = '-1'
        THEN 1
        ELSE 0
    END AS age_unknown_flag

FROM stg_users;


-- =========================================================
-- 2. Clean product dimension
-- -1 values are converted to NULL.
-- =========================================================

DROP TABLE IF EXISTS dim_products;

CREATE TABLE dim_products (
    sku_id        BIGINT NOT NULL,
    attribute_a1  SMALLINT,
    attribute_a2  SMALLINT,
    attribute_a3  SMALLINT,
    category_id   SMALLINT,
    brand_id      INT,

    PRIMARY KEY (sku_id),
    INDEX idx_product_category (category_id),
    INDEX idx_product_brand (brand_id)
) ENGINE = InnoDB;


INSERT INTO dim_products (
    sku_id,
    attribute_a1,
    attribute_a2,
    attribute_a3,
    category_id,
    brand_id
)
SELECT
    sku_id,
    NULLIF(a1, -1),
    NULLIF(a2, -1),
    NULLIF(a3, -1),
    cate,
    brand
FROM stg_products;


-- =========================================================
-- 3. Clean comment fact table
-- One row represents one product comment snapshot on one date.
-- =========================================================

DROP TABLE IF EXISTS fact_comments;

CREATE TABLE fact_comments (
    comment_date       DATE NOT NULL,
    sku_id             BIGINT NOT NULL,
    comment_num        INT,
    has_bad_comment    TINYINT,
    bad_comment_rate   DECIMAL(10, 6),

    PRIMARY KEY (comment_date, sku_id),
    INDEX idx_comment_sku (sku_id),
    INDEX idx_bad_comment_rate (bad_comment_rate)
) ENGINE = InnoDB;


INSERT INTO fact_comments (
    comment_date,
    sku_id,
    comment_num,
    has_bad_comment,
    bad_comment_rate
)
SELECT
    comment_date,
    sku_id,
    comment_num,
    has_bad_comment,
    bad_comment_rate
FROM stg_comments;


-- =========================================================
-- 4. Verify row counts
-- =========================================================

SELECT
    'dim_users' AS table_name,
    COUNT(*) AS row_count
FROM dim_users

UNION ALL

SELECT
    'dim_products',
    COUNT(*)
FROM dim_products

UNION ALL

SELECT
    'fact_comments',
    COUNT(*)
FROM fact_comments;


-- =========================================================
-- 5. Verify cleaned values
-- =========================================================

SELECT
    age_group,
    COUNT(*) AS user_count
FROM dim_users
GROUP BY age_group
ORDER BY user_count DESC;


SELECT
    COUNT(*) AS total_products,
    SUM(attribute_a1 IS NULL) AS unknown_a1,
    SUM(attribute_a2 IS NULL) AS unknown_a2,
    SUM(attribute_a3 IS NULL) AS unknown_a3
FROM dim_products;