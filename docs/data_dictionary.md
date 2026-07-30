# Data Dictionary

## 1. Purpose

This document describes the source files, MySQL tables, analytical grains, field meanings, and business use of the JD.com User Behaviour Analytics project.

The project uses the JD.com JData2016 dataset and transforms raw user, product, comment, and action data into analysis-ready tables for SQL reporting and Tableau dashboards.

---

## 2. Source Files

### 2.1 `JData_User.csv`

| Source Field | Type | Description | Cleaning Rule |
|---|---|---|---|
| `user_id` | Integer | Anonymised user identifier | Retained as `BIGINT` |
| `age` | Text | User age group | `-1` is converted to `Unknown` |
| `sex` | Integer | Anonymised sex code | Valid values retained; unsupported values converted to `NULL` |
| `user_lv_cd` | Integer | JD.com user membership level | Retained as `TINYINT` |
| `user_reg_tm` | Date | User registration date | Converted to `DATE` |

Encoding: `GBK`

---

### 2.2 `JData_Product.csv`

| Source Field | Type | Description | Cleaning Rule |
|---|---|---|---|
| `sku_id` | Integer | Anonymised product identifier | Retained as `BIGINT` |
| `a1` | Integer | Anonymised product attribute 1 | `-1` is converted to `NULL` |
| `a2` | Integer | Anonymised product attribute 2 | `-1` is converted to `NULL` |
| `a3` | Integer | Anonymised product attribute 3 | `-1` is converted to `NULL` |
| `cate` | Integer | Product category identifier | Renamed to `category_id` in analytical tables |
| `brand` | Integer | Product brand identifier | Renamed to `brand_id` in analytical tables |

Encoding: `UTF-8-SIG`

---

### 2.3 `JData_Comment.csv`

| Source Field | Type | Description | Cleaning Rule |
|---|---|---|---|
| `dt` | Date | Product-comment snapshot date | Renamed to `comment_date` and converted to `DATE` |
| `sku_id` | Integer | Product identifier | Retained as `BIGINT` |
| `comment_num` | Integer | An anonymised comment-volume level supplied by the dataset | Retained as `INT` |
| `has_bad_comment` | Integer | Indicates whether the product has bad comments | Valid values are `0` and `1` |
| `bad_comment_rate` | Decimal | Proportion of bad comments | Expected range is `0` to `1` |

Encoding: `UTF-8-SIG`

---

### 2.4 `JData_Action_201602.csv`, `JData_Action_201603.csv`, `JData_Action_201604.csv`

| Source Field | Type | Description | Cleaning Rule |
|---|---|---|---|
| `user_id` | Decimal-like numeric | Anonymised user identifier, sometimes stored as values such as `266079.0` | Converted to an integer user ID in analytical tables |
| `sku_id` | Integer | Product identifier | Retained as `BIGINT` |
| `time` | Datetime | Exact action timestamp | Renamed to `action_time` and converted to `DATETIME` |
| `model_id` | Decimal-like numeric | An anonymised model or action-context identifier | Missing values retained as `NULL` |
| `type` | Integer | Behaviour type code | Renamed to `action_type`; valid values are `1` to `6` |
| `cate` | Integer | Category identifier recorded in the action log | Renamed to `category_id` in analytical tables |
| `brand` | Integer | Brand identifier recorded in the action log | Renamed to `brand_id` in analytical tables |

Encoding: `UTF-8-SIG`

### Action-Type Mapping

| `action_type` | Behaviour |
|---:|---|
| 1 | Browse |
| 2 | Add to cart |
| 3 | Remove from cart |
| 4 | Purchase |
| 5 | Follow |
| 6 | Click |

---

## 3. Staging Tables

Staging tables preserve the source structure as closely as practical. They are used for ingestion, profiling, validation, and reproducibility.

### 3.1 `stg_users`

Grain: one row per source user.

| Field | MySQL Type | Nullable | Description |
|---|---|---:|---|
| `user_id` | `BIGINT` | No | User identifier |
| `age` | `VARCHAR(20)` | Yes | Source age-group value |
| `sex` | `TINYINT` | Yes | Source sex code |
| `user_lv_cd` | `TINYINT` | Yes | Source user level |
| `user_reg_tm` | `DATE` | Yes | Registration date |

---

### 3.2 `stg_products`

Grain: one row per source product.

| Field | MySQL Type | Nullable | Description |
|---|---|---:|---|
| `sku_id` | `BIGINT` | No | Product identifier |
| `a1` | `SMALLINT` | Yes | Source product attribute 1 |
| `a2` | `SMALLINT` | Yes | Source product attribute 2 |
| `a3` | `SMALLINT` | Yes | Source product attribute 3 |
| `cate` | `SMALLINT` | Yes | Source category identifier |
| `brand` | `INT` | Yes | Source brand identifier |

---

### 3.3 `stg_comments`

Grain: one row per product and comment snapshot date.

| Field | MySQL Type | Nullable | Description |
|---|---|---:|---|
| `comment_date` | `DATE` | Yes | Comment snapshot date |
| `sku_id` | `BIGINT` | Yes | Product identifier |
| `comment_num` | `INT` | Yes | Comment-volume level |
| `has_bad_comment` | `TINYINT` | Yes | Bad-comment indicator |
| `bad_comment_rate` | `DECIMAL(10,6)` | Yes | Bad-comment proportion |

---

### 3.4 `stg_actions`

Grain: one row per recorded behavioural event.

| Field | MySQL Type | Nullable | Description |
|---|---|---:|---|
| `user_id` | `DECIMAL(15,1)` | Yes | Source-form user identifier |
| `sku_id` | `BIGINT` | Yes | Product identifier |
| `action_time` | `DATETIME` | Yes | Action timestamp |
| `model_id` | `DECIMAL(15,1)` | Yes | Model/context identifier |
| `action_type` | `TINYINT` | Yes | Behaviour type code |
| `cate` | `SMALLINT` | Yes | Category identifier from action log |
| `brand` | `INT` | Yes | Brand identifier from action log |

Validated source-action total: `50,601,736`

---

## 4. Dimension and Fact Tables

### 4.1 `dim_users`

Grain: one row per user profile.

Primary key: `user_id`

| Field | MySQL Type | Description |
|---|---|---|
| `user_id` | `BIGINT` | Unique user identifier |
| `age_group` | `VARCHAR(20)` | Clean age group; unknown source values become `Unknown` |
| `sex_code` | `TINYINT` | Clean sex code; unsupported values become `NULL` |
| `user_level` | `TINYINT` | Membership level |
| `registration_date` | `DATE` | User registration date |
| `age_unknown_flag` | `TINYINT(1)` | `1` when the source age is missing or unknown |

Indexes:

- `idx_user_level`
- `idx_registration_date`

---

### 4.2 `dim_products`

Grain: one row per product profile.

Primary key: `sku_id`

| Field | MySQL Type | Description |
|---|---|---|
| `sku_id` | `BIGINT` | Unique product identifier |
| `attribute_a1` | `SMALLINT` | Clean product attribute 1 |
| `attribute_a2` | `SMALLINT` | Clean product attribute 2 |
| `attribute_a3` | `SMALLINT` | Clean product attribute 3 |
| `category_id` | `SMALLINT` | Product category identifier |
| `brand_id` | `INT` | Product brand identifier |

Indexes:

- `idx_product_category`
- `idx_product_brand`

---

### 4.3 `fact_comments`

Grain: one product-comment snapshot per date.

Primary key: `(comment_date, sku_id)`

| Field | MySQL Type | Description |
|---|---|---|
| `comment_date` | `DATE` | Comment snapshot date |
| `sku_id` | `BIGINT` | Product identifier |
| `comment_num` | `INT` | Anonymised comment-volume level |
| `has_bad_comment` | `TINYINT` | Bad-comment indicator |
| `bad_comment_rate` | `DECIMAL(10,6)` | Bad-comment proportion |

Indexes:

- `idx_comment_sku`
- `idx_bad_comment_rate`

---

### 4.4 `fact_user_product_daily`

Grain: one row per date, user, and product.

Primary key: `(action_date, user_id, sku_id)`

| Field | MySQL Type | Description |
|---|---|---|
| `action_date` | `DATE` | Calendar date of activity |
| `user_id` | `BIGINT` | User identifier |
| `sku_id` | `BIGINT` | Product identifier |
| `category_id` | `SMALLINT` | Category associated with the activity |
| `brand_id` | `INT` | Brand associated with the activity |
| `browse_count` | `INT UNSIGNED` | Browse actions for the date-user-product combination |
| `cart_add_count` | `INT UNSIGNED` | Cart-add actions |
| `cart_remove_count` | `INT UNSIGNED` | Cart-removal actions |
| `purchase_count` | `INT UNSIGNED` | Purchase actions |
| `follow_count` | `INT UNSIGNED` | Follow actions |
| `click_count` | `INT UNSIGNED` | Click actions |
| `total_action_count` | `INT UNSIGNED` | Total actions across all six behaviour types |
| `first_action_time` | `DATETIME` | Earliest action in the combination |
| `last_action_time` | `DATETIME` | Latest action in the combination |

Indexes:

- `idx_daily_user_date`
- `idx_daily_sku_date`
- `idx_daily_category_date`
- `idx_daily_brand_date`

---

## 5. Analytical Marts

### 5.1 `mart_user_product_period`

Grain: one row per user and product across the complete observation period.

Primary key: `(user_id, sku_id)`

| Field | Description |
|---|---|
| `user_id` | User identifier |
| `sku_id` | Product identifier |
| `category_id` | Category identifier |
| `brand_id` | Brand identifier |
| `active_days` | Number of dates on which the user interacted with the product |
| `browse_count` | Total browse actions |
| `cart_add_count` | Total cart-add actions |
| `cart_remove_count` | Total cart-removal actions |
| `purchase_count` | Total purchase actions |
| `follow_count` | Total follow actions |
| `click_count` | Total click actions |
| `total_action_count` | Total behavioural actions |
| `first_action_time` | First observed user-product action |
| `last_action_time` | Last observed user-product action |
| `interest_flag` | `1` when browse or click activity exists |
| `follow_flag` | `1` when follow activity exists |
| `cart_add_flag` | `1` when cart-add activity exists |
| `purchase_flag` | `1` when purchase activity exists |
| `cart_abandon_flag` | `1` when the user added the product but did not purchase it |

Business use:

- Strict user-product cart conversion
- Cart abandonment
- User purchase intent
- Product, category, and brand aggregation

---

### 5.2 `mart_user_summary`

Grain: one row per active user.

Primary key: `user_id`

| Field | Description |
|---|---|
| `user_id` | User identifier |
| `age_group` | Clean user age group |
| `sex_code` | Clean sex code |
| `user_level` | Membership level |
| `active_days` | Number of active dates |
| `interacted_products` | Number of distinct products interacted with |
| `interested_products` | Number of products browsed or clicked |
| `followed_products` | Number of products followed |
| `carted_products` | Number of products added to cart |
| `purchased_products` | Number of products purchased |
| `abandoned_cart_products` | Number of products added to cart but not purchased |
| `interacted_categories` | Number of distinct categories interacted with |
| `browse_count` | Total browse actions |
| `cart_add_count` | Total cart-add actions |
| `cart_remove_count` | Total cart-removal actions |
| `purchase_count` | Total purchase actions |
| `follow_count` | Total follow actions |
| `click_count` | Total click actions |
| `total_action_count` | Total user actions |
| `first_action_time` | First action timestamp |
| `last_action_time` | Last action timestamp |
| `recency_days` | Days between last activity and dataset end date |
| `interest_flag` | Indicates browse or click activity |
| `follow_flag` | Indicates follow activity |
| `cart_add_flag` | Indicates cart-add activity |
| `buyer_flag` | Indicates purchase activity |
| `cart_abandon_flag` | Indicates at least one abandoned cart product |
| `purchase_intent_score` | Rule-based purchase-intent score |
| `customer_segment` | Final mutually exclusive customer segment |

Customer segments:

- `Existing Customer`
- `High Purchase Intent`
- `Cart-Abandonment User`
- `Medium Purchase Intent`
- `Low Purchase Intent`
- `Other Active User`

---

### 5.3 `mart_product_performance`

Grain: one row per active product.

Primary key: `sku_id`

| Field | Description |
|---|---|
| `sku_id` | Product identifier |
| `category_id` | Product category |
| `brand_id` | Product brand |
| `attribute_a1` | Clean product attribute 1 |
| `attribute_a2` | Clean product attribute 2 |
| `attribute_a3` | Clean product attribute 3 |
| `interacting_users` | Distinct users who interacted with the product |
| `interested_users` | Users who browsed or clicked the product |
| `followed_users` | Users who followed the product |
| `cart_users` | Users who added the product to cart |
| `cart_converted_users` | Users who both added and purchased the same product |
| `buyers` | All users who purchased the product, including direct buyers |
| `cart_abandon_users` | Users who added the product but did not purchase it |
| `browse_count` | Browse actions |
| `cart_add_count` | Cart-add actions |
| `cart_remove_count` | Cart-removal actions |
| `purchase_count` | Purchase actions |
| `follow_count` | Follow actions |
| `click_count` | Click actions |
| `total_action_count` | Total actions |
| `interest_to_cart_rate` | `cart_users / interested_users × 100` |
| `cart_to_purchase_rate` | `cart_converted_users / cart_users × 100` |
| `overall_conversion_rate` | `buyers / interacting_users × 100` |
| `cart_abandonment_rate` | `cart_abandon_users / cart_users × 100` |
| `latest_comment_date` | Latest available comment snapshot date |
| `latest_comment_level` | Latest anonymised comment-volume level |
| `has_bad_comment` | Latest bad-comment flag |
| `bad_comment_rate` | Latest bad-comment proportion |
| `first_action_time` | First product activity |
| `last_action_time` | Last product activity |

---

### 5.4 `mart_category_performance`

Grain: one row per active category.

Primary key: `category_id`

| Field | Description |
|---|---|
| `category_id` | Category identifier |
| `active_products` | Active products in the category |
| `interacting_users` | Distinct users interacting with the category |
| `interested_users` | Users with browse or click activity |
| `followed_users` | Users with follow activity |
| `cart_users` | Users adding at least one category product to cart |
| `cart_converted_users` | Users converting at least one same-product cart pair |
| `cart_abandon_users` | Category cart users with no same-product conversion |
| `buyers` | Users purchasing at least one category product |
| `browse_count` | Browse actions |
| `cart_add_count` | Cart-add actions |
| `cart_remove_count` | Cart-removal actions |
| `purchase_count` | Purchase actions |
| `follow_count` | Follow actions |
| `click_count` | Click actions |
| `total_action_count` | Total category actions |
| `interest_to_cart_rate` | Cart-user share among interested users |
| `cart_to_purchase_rate` | Strict cart conversion rate |
| `cart_abandonment_rate` | Strict cart abandonment rate |
| `overall_conversion_rate` | Buyer share among interacting users |
| `products_with_comments` | Products with available latest comment data |
| `avg_bad_comment_rate` | Average latest bad-comment rate |
| `first_action_time` | First category action |
| `last_action_time` | Last category action |

---

### 5.5 `mart_brand_performance`

Grain: one row per active brand.

Primary key: `brand_id`

Fields follow the same definitions as `mart_category_performance`, aggregated by brand.

Main fields:

- `active_products`
- `interacting_users`
- `interested_users`
- `followed_users`
- `cart_users`
- `cart_converted_users`
- `cart_abandon_users`
- `buyers`
- Behaviour counts
- Conversion rates
- Comment indicators
- First and last action timestamps

---

### 5.6 `mart_daily_performance`

Grain: one row per calendar date.

Primary key: `action_date`

| Field | Description |
|---|---|
| `action_date` | Calendar date |
| `year_number` | Calendar year |
| `month_number` | Calendar month number |
| `month_start_date` | First date of the month |
| `day_of_week_number` | Monday = 1 through Sunday = 7 |
| `day_name` | English weekday name |
| `is_weekend` | `1` for Saturday or Sunday |
| `active_users` | Distinct active users |
| `active_products` | Distinct active products |
| `interested_users` | Users browsing or clicking |
| `followed_users` | Users following products |
| `cart_users` | Users adding products to cart |
| `same_day_cart_converted_users` | Users adding and purchasing the same product on the same date |
| `same_day_cart_abandon_users` | Daily cart users without a same-day same-product conversion |
| `buyers` | Daily buyers |
| Behaviour count fields | Daily totals for all six action types |
| `interest_to_cart_rate` | Daily cart-user share among interested users |
| `same_day_cart_conversion_rate` | Same-day strict cart conversion |
| `same_day_cart_abandonment_rate` | Same-day strict cart abandonment |
| `active_user_conversion_rate` | Daily buyer share among active users |

---

### 5.7 `mart_date_hour_performance`

Grain: one row per date and hour.

Primary key: `(action_date, hour_of_day)`

Main use:

- Date-hour trend analysis
- Source table for hourly aggregation
- Same-hour conversion analysis

Key fields:

- `action_date`
- `hour_of_day`
- `active_users`
- `active_products`
- `interested_users`
- `followed_users`
- `cart_users`
- `same_hour_cart_converted_users`
- `same_hour_cart_abandon_users`
- `buyers`
- Behaviour counts
- Same-hour conversion and abandonment rates
- Active-user conversion rate

---

### 5.8 `mart_hourly_performance`

Grain: one row per hour of day.

Primary key: `hour_of_day`

| Field | Description |
|---|---|
| `hour_of_day` | Hour number from `0` to `23` |
| `hour_label` | Display label such as `10:00-11:00` |
| `observed_date_hours` | Number of date-hour observations |
| `avg_active_users` | Average active users |
| `avg_active_products` | Average active products |
| `avg_interested_users` | Average interested users |
| `avg_cart_users` | Average cart users |
| `avg_buyers` | Average buyers |
| `avg_browse_count` | Average browse actions |
| `avg_cart_add_count` | Average cart-add actions |
| `avg_cart_remove_count` | Average cart-removal actions |
| `avg_purchase_count` | Average purchase actions |
| `avg_follow_count` | Average follow actions |
| `avg_click_count` | Average click actions |
| `avg_total_action_count` | Average total actions |
| `total_action_count` | Total actions in the hour across all dates |
| `total_purchase_count` | Total purchases in the hour |
| `avg_interest_to_cart_rate` | Average interest-to-cart rate |
| `avg_cart_conversion_rate` | Average same-hour cart conversion |
| `avg_cart_abandonment_rate` | Average same-hour cart abandonment |
| `avg_user_conversion_rate` | Average active-user conversion |
| `action_share_pct` | Share of all actions |
| `purchase_share_pct` | Share of all purchases |

---

### 5.9 `mart_dashboard_executive`

Grain: one row representing the full observation period.

Primary key: `snapshot_id`

| Field | Description |
|---|---|
| `snapshot_id` | Snapshot identifier |
| `dataset_start_date` | Earliest action date |
| `dataset_end_date` | Latest action date |
| `observed_days` | Number of observed dates |
| `registered_users` | Users in `dim_users` |
| `active_users` | Users with at least one action |
| `inactive_registered_users` | Registered users without observed activity |
| `active_products` | Active products |
| `buyers` | Users with at least one purchase |
| `repeat_buyers` | Buyers with at least two purchase actions |
| Behaviour action fields | Full-period totals |
| `active_user_conversion_rate` | Buyers divided by active users |
| `repeat_buyer_rate` | Repeat buyers divided by buyers |
| `avg_actions_per_active_user` | Total actions divided by active users |
| `cart_users` | Users who added at least one product |
| `cart_converted_users` | Users with at least one strict same-product cart conversion |
| `pure_cart_abandon_users` | Cart users with no strict cart conversion |
| `user_cart_conversion_rate` | Converted cart users divided by cart users |
| `user_cart_abandonment_rate` | Pure cart-abandon users divided by cart users |
| `cart_user_product_pairs` | User-product pairs with a cart-add action |
| `converted_cart_pairs` | Strictly converted cart pairs |
| `abandoned_cart_pairs` | Abandoned cart pairs |
| `pair_cart_conversion_rate` | Converted pairs divided by cart pairs |
| `pair_cart_abandonment_rate` | Abandoned pairs divided by cart pairs |

---

### 5.10 `mart_funnel_summary`

Grain: one row per behavioural reach stage.

Primary key: `stage_order`

| Field | Description |
|---|---|
| `stage_order` | Display order |
| `stage_name` | Funnel-stage label |
| `user_count` | Users reaching the stage |
| `active_user_share_pct` | Stage users as a share of active users |
| `stage_definition` | Business definition |

Stages:

1. Active Users
2. Interested Users
3. Followed Users
4. Cart Users
5. Buyers

This is a behavioural reach funnel. It is not assumed to be strictly sequential.

---

### 5.11 `mart_segment_performance`

Grain: one row per customer segment.

Primary key: `customer_segment`

| Field | Description |
|---|---|
| `customer_segment` | Segment label |
| `user_count` | Users in the segment |
| `user_percentage` | Share of active users |
| `buyers` | Buyers in the segment |
| `cart_users` | Users with cart activity |
| `abandoned_cart_users` | Users with at least one abandoned product |
| `avg_intent_score` | Average purchase-intent score |
| `avg_recency_days` | Average recency |
| `avg_active_days` | Average active days |
| `avg_interacted_products` | Average distinct products |
| `total_actions` | Segment action total |
| `purchase_actions` | Segment purchase-action total |
| `avg_actions_per_user` | Average actions per segment user |
| `avg_purchases_per_user` | Average purchase actions per segment user |

---

## 6. Verified Totals

| Metric | Verified Value |
|---|---:|
| Registered users | 105,321 |
| Active users | 105,180 |
| Buyers | 29,485 |
| Total actions | 50,601,736 |
| Browse actions | 18,981,373 |
| Cart-add actions | 575,418 |
| Cart-removal actions | 256,053 |
| Purchase actions | 48,252 |
| Follow actions | 109,896 |
| Click actions | 30,630,744 |

All action-based analytical marts reconcile to the source action total.
