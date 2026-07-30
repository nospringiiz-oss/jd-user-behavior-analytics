
-- JD.com User Behavior Analytics

DROP DATABASE IF EXISTS jd_user_behavior;

CREATE DATABASE jd_user_behavior
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE jd_user_behavior;


-- 1. User staging table

CREATE TABLE stg_users (
    user_id        BIGINT NOT NULL,
    age            VARCHAR(20),
    sex            TINYINT,
    user_lv_cd     TINYINT,
    user_reg_tm    DATE
);



-- 2. Product staging table


CREATE TABLE stg_products (
    sku_id         BIGINT NOT NULL,
    a1             SMALLINT,
    a2             SMALLINT,
    a3             SMALLINT,
    cate           SMALLINT,
    brand          INT
);


-- 3. Comment staging table


CREATE TABLE stg_comments (
    comment_date       DATE,
    sku_id             BIGINT,
    comment_num        INT,
    has_bad_comment    TINYINT,
    bad_comment_rate   DECIMAL(10, 6)
);



-- 4. Action staging table

CREATE TABLE stg_actions (
    user_id         DECIMAL(15, 1),
    sku_id          BIGINT,
    action_time     DATETIME,
    model_id        DECIMAL(15, 1),
    action_type     TINYINT,
    cate            SMALLINT,
    brand           INT
);


-- Check table creation


SHOW TABLES;

DESCRIBE stg_users;
DESCRIBE stg_products;
DESCRIBE stg_comments;
DESCRIBE stg_actions;