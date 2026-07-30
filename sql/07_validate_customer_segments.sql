USE jd_user_behavior;

-- =========================================================
-- 1. Average behavior metrics by segment
-- =========================================================

SELECT
    customer_segment,
    COUNT(*) AS user_count,

    ROUND(AVG(purchase_intent_score), 2)
        AS avg_intent_score,

    MIN(purchase_intent_score)
        AS min_intent_score,

    MAX(purchase_intent_score)
        AS max_intent_score,

    ROUND(AVG(active_days), 2)
        AS avg_active_days,

    ROUND(AVG(interacted_products), 2)
        AS avg_interacted_products,

    ROUND(AVG(browse_count), 2)
        AS avg_browse_count,

    ROUND(AVG(click_count), 2)
        AS avg_click_count,

    ROUND(AVG(follow_count), 2)
        AS avg_follow_count,

    ROUND(AVG(cart_add_count), 2)
        AS avg_cart_add_count,

    ROUND(AVG(cart_remove_count), 2)
        AS avg_cart_remove_count,

    ROUND(AVG(purchase_count), 2)
        AS avg_purchase_count,

    ROUND(AVG(recency_days), 2)
        AS avg_recency_days

FROM mart_user_summary

GROUP BY customer_segment

ORDER BY avg_intent_score DESC;


-- =========================================================
-- 2. Flag distribution within each segment
-- =========================================================

SELECT
    customer_segment,
    COUNT(*) AS user_count,

    SUM(follow_flag) AS users_with_follow,
    SUM(cart_add_flag) AS users_with_cart,
    SUM(cart_abandon_flag) AS users_with_abandoned_cart,
    SUM(buyer_flag) AS buyers,

    ROUND(
        100.0 * SUM(follow_flag) / COUNT(*),
        2
    ) AS follow_user_pct,

    ROUND(
        100.0 * SUM(cart_add_flag) / COUNT(*),
        2
    ) AS cart_user_pct,

    ROUND(
        100.0 * SUM(cart_abandon_flag) / COUNT(*),
        2
    ) AS cart_abandon_user_pct,

    ROUND(
        100.0 * SUM(buyer_flag) / COUNT(*),
        2
    ) AS buyer_pct

FROM mart_user_summary

GROUP BY customer_segment

ORDER BY user_count DESC;


-- =========================================================
-- 3. Purchase-intent score distribution
-- =========================================================

SELECT
    CASE
        WHEN purchase_intent_score < 10
            THEN '00-09'

        WHEN purchase_intent_score < 20
            THEN '10-19'

        WHEN purchase_intent_score < 30
            THEN '20-29'

        WHEN purchase_intent_score < 40
            THEN '30-39'

        WHEN purchase_intent_score < 50
            THEN '40-49'

        ELSE '50+'
    END AS score_range,

    COUNT(*) AS user_count,

    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS user_percentage

FROM mart_user_summary

GROUP BY score_range

ORDER BY score_range;


-- =========================================================
-- 4. High-intent segment validation
-- =========================================================

SELECT
    COUNT(*) AS high_intent_users,

    SUM(recency_days <= 3)
        AS active_within_3_days,

    SUM(follow_flag = 1)
        AS users_with_follow,

    SUM(cart_add_flag = 1)
        AS users_with_cart,

    SUM(cart_abandon_flag = 1)
        AS users_with_abandoned_cart,

    ROUND(AVG(carted_products), 2)
        AS avg_carted_products,

    ROUND(AVG(abandoned_cart_products), 2)
        AS avg_abandoned_products,

    ROUND(AVG(purchase_intent_score), 2)
        AS avg_score

FROM mart_user_summary

WHERE customer_segment = 'High Purchase Intent';


-- =========================================================
-- 5. Sample users from each segment
-- =========================================================

WITH ranked_users AS (
    SELECT
        user_id,
        customer_segment,
        purchase_intent_score,
        recency_days,
        active_days,
        browse_count,
        click_count,
        follow_count,
        cart_add_count,
        cart_remove_count,
        purchase_count,

        ROW_NUMBER() OVER (
            PARTITION BY customer_segment
            ORDER BY
                purchase_intent_score DESC,
                last_action_time DESC
        ) AS segment_rank

    FROM mart_user_summary
)

SELECT
    user_id,
    customer_segment,
    purchase_intent_score,
    recency_days,
    active_days,
    browse_count,
    click_count,
    follow_count,
    cart_add_count,
    cart_remove_count,
    purchase_count

FROM ranked_users

WHERE segment_rank <= 5

ORDER BY
    customer_segment,
    segment_rank;