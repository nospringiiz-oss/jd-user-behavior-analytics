USE jd_user_behavior;

-- =========================================================
-- 16 Business Analysis
--
-- Business questions:
-- 1. What is the overall business performance?
-- 2. Where does user conversion drop?
-- 3. Which customer groups should be targeted?
-- 4. Which categories, brands, and products underperform?
-- 5. When should marketing campaigns be launched?
-- 6. Does product feedback relate to conversion?
--
-- Important limitation:
-- The dataset does not contain product price or revenue.
-- Purchase analysis therefore uses buyers and purchase events.
-- =========================================================


-- =========================================================
-- 1. EXECUTIVE OVERVIEW
-- =========================================================

SELECT
    dataset_start_date,
    dataset_end_date,
    observed_days,

    registered_users,
    active_users,
    inactive_registered_users,

    active_products,
    buyers,
    repeat_buyers,

    total_actions,
    purchase_actions,

    active_user_conversion_rate,
    repeat_buyer_rate,
    avg_actions_per_active_user,

    cart_users,
    cart_converted_users,
    pure_cart_abandon_users,

    user_cart_conversion_rate,
    user_cart_abandonment_rate,

    pair_cart_conversion_rate,
    pair_cart_abandonment_rate

FROM mart_dashboard_executive;


-- =========================================================
-- 2. USER BEHAVIOUR FUNNEL
--
-- This is a behavioural reach funnel.
-- Users may skip stages, such as purchasing directly.
-- =========================================================

SELECT
    stage_order,
    stage_name,
    user_count,
    active_user_share_pct,
    stage_definition

FROM mart_funnel_summary

ORDER BY stage_order;


-- =========================================================
-- 3. CUSTOMER SEGMENT DISTRIBUTION
-- =========================================================

SELECT
    customer_segment,
    user_count,
    user_percentage,

    avg_intent_score,
    avg_recency_days,
    avg_active_days,
    avg_interacted_products,

    cart_users,
    abandoned_cart_users,
    buyers,

    avg_actions_per_user,
    avg_purchases_per_user

FROM mart_segment_performance

ORDER BY
    CASE customer_segment
        WHEN 'Existing Customer' THEN 1
        WHEN 'High Purchase Intent' THEN 2
        WHEN 'Cart-Abandonment User' THEN 3
        WHEN 'Medium Purchase Intent' THEN 4
        WHEN 'Low Purchase Intent' THEN 5
        ELSE 6
    END;


-- =========================================================
-- 4. MARKETING TARGET SUMMARY
--
-- Suggested actions are analytical recommendations.
-- =========================================================

SELECT
    customer_segment,
    COUNT(*) AS target_users,

    ROUND(
        AVG(purchase_intent_score),
        2
    ) AS avg_intent_score,

    ROUND(
        AVG(recency_days),
        2
    ) AS avg_recency_days,

    ROUND(
        AVG(cart_add_count),
        2
    ) AS avg_cart_add_count,

    ROUND(
        AVG(abandoned_cart_products),
        2
    ) AS avg_abandoned_cart_products,

    CASE
        WHEN customer_segment = 'High Purchase Intent'
        THEN 'Limited-time coupon or personalised reminder'

        WHEN customer_segment = 'Cart-Abandonment User'
        THEN 'Cart reminder, discount, or product availability alert'

        WHEN customer_segment = 'Medium Purchase Intent'
        THEN 'Product recommendation and follow-up campaign'

        WHEN customer_segment = 'Low Purchase Intent'
        THEN 'Awareness and discovery campaign'

        WHEN customer_segment = 'Existing Customer'
        THEN 'Cross-sell, membership, and retention campaign'

        ELSE 'Review unusual activity'
    END AS recommended_action

FROM mart_user_summary

GROUP BY customer_segment

ORDER BY target_users DESC;


-- =========================================================
-- 5. HIGH-PURCHASE-INTENT USERS
--
-- Excludes existing buyers.
-- Suitable for personalised marketing campaigns.
-- =========================================================

SELECT
    user_id,
    age_group,
    sex_code,
    user_level,

    customer_segment,
    purchase_intent_score,
    recency_days,
    active_days,

    interacted_products,
    followed_products,
    carted_products,
    abandoned_cart_products,

    browse_count,
    click_count,
    follow_count,
    cart_add_count,
    cart_remove_count,

    last_action_time

FROM mart_user_summary

WHERE buyer_flag = 0
  AND customer_segment = 'High Purchase Intent'

ORDER BY
    purchase_intent_score DESC,
    recency_days ASC,
    cart_add_count DESC

LIMIT 100;


-- =========================================================
-- 6. CART-ABANDONMENT CAMPAIGN TARGETS
--
-- Prioritises users with more abandoned products
-- and more recent activity.
-- =========================================================

SELECT
    user_id,
    age_group,
    sex_code,
    user_level,

    purchase_intent_score,
    recency_days,
    active_days,

    carted_products,
    abandoned_cart_products,

    cart_add_count,
    cart_remove_count,
    follow_count,

    last_action_time

FROM mart_user_summary

WHERE customer_segment = 'Cart-Abandonment User'

ORDER BY
    abandoned_cart_products DESC,
    recency_days ASC,
    purchase_intent_score DESC

LIMIT 100;


-- =========================================================
-- 7. CATEGORY PERFORMANCE
-- =========================================================

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

    avg_bad_comment_rate

FROM mart_category_performance

ORDER BY buyers DESC;


-- =========================================================
-- 8. CATEGORY PRIORITY MATRIX
--
-- Priority is based on both abandonment rate
-- and the number of affected users.
-- =========================================================

SELECT
    category_id,

    cart_users,
    cart_converted_users,
    cart_abandon_users,

    cart_to_purchase_rate,
    cart_abandonment_rate,

    buyers,
    overall_conversion_rate,

    CASE
        WHEN cart_abandonment_rate >= 85
         AND cart_abandon_users >= 1000
        THEN 'Critical Priority'

        WHEN cart_abandonment_rate >= 75
         AND cart_abandon_users >= 1000
        THEN 'High Priority'

        WHEN cart_abandonment_rate >= 65
        THEN 'Medium Priority'

        ELSE 'Lower Priority'
    END AS operational_priority

FROM mart_category_performance

ORDER BY
    CASE
        WHEN cart_abandonment_rate >= 85
         AND cart_abandon_users >= 1000
        THEN 1

        WHEN cart_abandonment_rate >= 75
         AND cart_abandon_users >= 1000
        THEN 2

        WHEN cart_abandonment_rate >= 65
        THEN 3

        ELSE 4
    END,
    cart_abandon_users DESC;


-- =========================================================
-- 9. TOP BRANDS BY BUYER VOLUME
-- =========================================================

SELECT
    brand_id,

    active_products,
    interacting_users,

    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,

    purchase_count,

    cart_to_purchase_rate,
    cart_abandonment_rate,
    overall_conversion_rate,

    avg_bad_comment_rate

FROM mart_brand_performance

ORDER BY
    buyers DESC,
    purchase_count DESC

LIMIT 20;


-- =========================================================
-- 10. BRANDS WITH SEVERE CART ABANDONMENT
--
-- Require at least 100 cart users to reduce
-- small-sample distortion.
-- =========================================================

SELECT
    brand_id,

    active_products,
    interacting_users,

    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,

    cart_to_purchase_rate,
    cart_abandonment_rate,
    overall_conversion_rate

FROM mart_brand_performance

WHERE cart_users >= 100

ORDER BY
    cart_abandonment_rate DESC,
    cart_abandon_users DESC

LIMIT 20;


-- =========================================================
-- 11. HIGH-INTEREST, LOW-CONVERSION PRODUCTS
--
-- Products with substantial user traffic but
-- weak overall conversion.
-- =========================================================

SELECT
    sku_id,
    category_id,
    brand_id,

    interacting_users,
    interested_users,
    cart_users,
    cart_converted_users,
    cart_abandon_users,
    buyers,

    overall_conversion_rate,
    cart_to_purchase_rate,
    cart_abandonment_rate,

    bad_comment_rate

FROM mart_product_performance

WHERE interacting_users >= 500
  AND overall_conversion_rate < 1.00

ORDER BY
    interacting_users DESC,
    overall_conversion_rate ASC

LIMIT 30;


-- =========================================================
-- 12. PRODUCTS WITH THE LARGEST CART-ABANDONMENT IMPACT
--
-- Ranks products by number of abandoned cart users,
-- rather than rate alone.
-- =========================================================

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
    cart_abandonment_rate,

    latest_comment_level,
    bad_comment_rate

FROM mart_product_performance

WHERE cart_users >= 20

ORDER BY
    cart_abandon_users DESC,
    cart_abandonment_rate DESC

LIMIT 30;


-- =========================================================
-- 13. PRODUCTS WITH STRONG CART CONVERSION
-- =========================================================

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
    cart_abandonment_rate,
    overall_conversion_rate

FROM mart_product_performance

WHERE cart_users >= 20

ORDER BY
    cart_to_purchase_rate DESC,
    cart_users DESC

LIMIT 20;


-- =========================================================
-- 14. DAILY PURCHASE TREND
-- =========================================================

SELECT
    action_date,
    day_name,
    is_weekend,

    active_users,
    buyers,
    purchase_count,

    total_action_count,

    active_user_conversion_rate,
    same_day_cart_conversion_rate,
    same_day_cart_abandonment_rate

FROM mart_daily_performance

ORDER BY action_date;


-- =========================================================
-- 15. HIGHEST-PURCHASE DATES
-- =========================================================

SELECT
    action_date,
    day_name,
    is_weekend,

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
-- 16. WEEKDAY PERFORMANCE
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


-- =========================================================
-- 17. HOURLY PERFORMANCE
-- =========================================================

SELECT
    hour_of_day,
    hour_label,

    avg_active_users,
    avg_buyers,
    avg_purchase_count,
    avg_total_action_count,

    avg_user_conversion_rate,
    avg_cart_conversion_rate,
    avg_cart_abandonment_rate,

    action_share_pct,
    purchase_share_pct

FROM mart_hourly_performance

ORDER BY hour_of_day;


-- =========================================================
-- 18. PEAK PURCHASE HOURS
-- =========================================================

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


-- =========================================================
-- 19. PRODUCT FEEDBACK AND CONVERSION
--
-- This is descriptive analysis.
-- It does not prove that bad comments cause low conversion.
-- =========================================================

SELECT
    CASE
        WHEN bad_comment_rate IS NULL
        THEN 'No Comment Data'

        WHEN bad_comment_rate = 0
        THEN '0%'

        WHEN bad_comment_rate <= 0.01
        THEN '0%-1%'

        WHEN bad_comment_rate <= 0.03
        THEN '1%-3%'

        WHEN bad_comment_rate <= 0.05
        THEN '3%-5%'

        ELSE 'Above 5%'
    END AS bad_comment_rate_band,

    COUNT(*) AS product_count,

    SUM(interacting_users)
        AS interacting_user_total,

    SUM(buyers)
        AS buyer_total,

    ROUND(
        AVG(overall_conversion_rate),
        4
    ) AS avg_product_conversion_rate,

    ROUND(
        AVG(cart_to_purchase_rate),
        4
    ) AS avg_cart_conversion_rate,

    ROUND(
        AVG(cart_abandonment_rate),
        4
    ) AS avg_cart_abandonment_rate

FROM mart_product_performance

GROUP BY bad_comment_rate_band

ORDER BY
    CASE bad_comment_rate_band
        WHEN '0%' THEN 1
        WHEN '0%-1%' THEN 2
        WHEN '1%-3%' THEN 3
        WHEN '3%-5%' THEN 4
        WHEN 'Above 5%' THEN 5
        ELSE 6
    END;


-- =========================================================
-- 20. FINAL RECONCILIATION
--
-- Expected:
-- total_actions = 50,601,736
-- user_difference = 0
-- product_difference = 0
-- =========================================================

SELECT
    executive.total_actions,

    (
        SELECT SUM(total_action_count)
        FROM mart_product_performance
    ) AS product_actions,

    executive.total_actions
    - (
        SELECT SUM(total_action_count)
        FROM mart_product_performance
    ) AS product_difference,

    executive.active_users,

    (
        SELECT SUM(user_count)
        FROM mart_segment_performance
    ) AS segment_users,

    executive.active_users
    - (
        SELECT SUM(user_count)
        FROM mart_segment_performance
    ) AS user_difference

FROM mart_dashboard_executive AS executive;