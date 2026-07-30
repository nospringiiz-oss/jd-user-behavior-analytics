# Business Findings

## 1. Executive Summary

This project analyses JD.com JData2016 customer behaviour across browsing, clicking, following, cart, and purchase activities.

The final analytical pipeline processed and reconciled:

- **50,601,736 behavioural actions**
- **105,180 active users**
- **29,485 buyers**
- **48,252 purchase actions**
- An observation period from **31 January 2016 to 15 April 2016**

The analysis identifies three major business priorities:

1. Convert users who already show strong purchase intent.
2. Recover users who add products to cart but do not purchase.
3. Improve categories and brands with both high abandonment rates and high affected-user volumes.

The results also show that campaign timing matters. Tuesday performs best among weekdays, while midnight and late morning are strong purchase windows. Evening traffic is high, but conversion efficiency is weaker.

---

## 2. Data Scope

### Observation Period

```text
31 January 2016 – 15 April 2016
```

### Core Metrics

| Metric | Value |
|---|---:|
| Registered Users | 105,321 |
| Active Users | 105,180 |
| Buyers | 29,485 |
| Total Actions | 50,601,736 |
| Browse Actions | 18,981,373 |
| Add-to-Cart Actions | 575,418 |
| Cart-Removal Actions | 256,053 |
| Purchase Actions | 48,252 |
| Follow Actions | 109,896 |
| Click Actions | 30,630,744 |

The source actions were fully reconciled against the analytical marts:

```text
Product action difference = 0
Customer segment user difference = 0
```

This confirms that the transformation pipeline did not lose or duplicate behavioural records.

---

## 3. Customer Behaviour Findings

### 3.1 Discovery Behaviour Dominates Platform Activity

Browsing and clicking account for most actions, while purchase events remain limited.

This indicates a large gap between customer interest and completed purchase. Many users interact with products repeatedly but do not progress to conversion.

Recommended actions:

- Improve product-page clarity.
- Strengthen trust signals.
- Reduce checkout friction.
- Use personalised reminders for recent high-intent activity.
- Investigate whether delivery cost, stock availability, or product information creates hesitation.

### 3.2 Customer Segmentation Identifies Clear Marketing Targets

| Customer Segment | Users | Share |
|---|---:|---:|
| Medium Purchase Intent | 31,843 | 30.27% |
| Existing Customer | 29,485 | 28.03% |
| High Purchase Intent | 28,565 | 27.16% |
| Cart-Abandonment User | 14,079 | 13.39% |
| Low Purchase Intent | 1,207 | 1.15% |
| Other Active User | 1 | 0.00% |
| **Total** | **105,180** | **100.00%** |

The most commercially important non-buyer groups are:

- **28,565 High Purchase Intent users**
- **14,079 Cart-Abandonment users**

These users have already demonstrated meaningful behavioural interest.

| Segment | Recommended Action |
|---|---|
| Existing Customer | Cross-sell, membership, retention, and loyalty campaigns |
| High Purchase Intent | Limited-time offers, personalised reminders, and product recommendations |
| Cart-Abandonment User | Cart reminders, stock alerts, delivery reassurance, and targeted discounts |
| Medium Purchase Intent | Follow-up recommendations and discovery campaigns |
| Low Purchase Intent | Awareness and engagement campaigns |
| Other Active User | Manual review of unusual activity |

### 3.3 Cart Abandonment Is a Major Conversion Problem

The project uses a strict cart-conversion definition:

```text
same user
+ same product
+ cart-add action
+ purchase action
```

A cart-abandonment user-product pair occurs when the same user adds the same product to cart but does not purchase it during the observation period.

Recommended actions:

- Trigger cart reminders shortly after abandonment.
- Test time-limited coupons.
- Display delivery time and fees earlier.
- Notify users when stock is limited.
- Recommend substitute products when availability is poor.
- Investigate mobile-checkout friction.

---

## 4. Category Performance Findings

### 4.1 Category 8 Has the Largest Abandonment Impact

| Metric | Value |
|---|---:|
| Cart Users | 52,544 |
| Converted Cart Users | 11,528 |
| Cart-Abandonment Users | 41,016 |
| Cart Conversion Rate | 21.94% |
| Cart Abandonment Rate | 78.06% |
| Buyers | 12,921 |

Category 8 does not have the worst abandonment rate, but it affects the largest number of cart users. This makes it the highest operational priority.

Recommended actions:

- Identify the highest-volume abandoned products within Category 8.
- Review delivery, pricing, stock, and product information.
- Run product-level conversion tests.
- Compare with Category 7 best practices.

### 4.2 Categories 10 and 11 Have Severe Conversion Weakness

| Category | Cart Users | Converted Users | Abandoned Users | Conversion Rate | Abandonment Rate |
|---:|---:|---:|---:|---:|---:|
| 11 | 1,401 | 0 | 1,401 | 0.00% | 100.00% |
| 10 | 1,474 | 137 | 1,337 | 9.29% | 90.71% |

Recommended investigation areas:

- Stock availability
- Delivery restrictions
- Shipping fees
- Product-page quality
- Trust and review signals
- Price competitiveness
- Checkout errors
- Product substitution

### 4.3 Category 7 Has the Strongest Relative Conversion

Category 7 achieved approximately:

```text
34.24% strict cart conversion
```

It can be used as an internal benchmark for weaker categories.

### 4.4 Category 9 Also Performs Relatively Well

Category 9 achieved approximately:

```text
32.57% strict cart conversion
```

This suggests category-level operational practices may influence conversion.

---

## 5. Brand Performance Findings

| Brand | Cart Users | Converted Users | Abandoned Users | Conversion Rate | Abandonment Rate |
|---:|---:|---:|---:|---:|---:|
| 447 | 149 | 5 | 144 | 3.36% | 96.64% |
| 655 | 317 | 12 | 305 | 3.79% | 96.21% |
| 596 | 251 | 10 | 241 | 3.98% | 96.02% |
| 890 | 676 | 32 | 644 | 4.73% | 95.27% |
| 200 | 3,528 | 348 | 3,180 | 9.86% | 90.14% |
| 752 | 2,471 | 237 | 2,234 | 9.59% | 90.41% |

Brand priority should consider both abandonment rate and affected-user volume.

Recommended priority logic:

- High rate and high volume: urgent investigation
- High rate and low volume: targeted review
- Moderate rate and high volume: large-scale conversion opportunity
- Lower rate and low volume: routine monitoring

---

## 6. Product Performance Findings

### 6.1 Strong Products Still Lose More Than Half of Cart Users

| SKU | Cart Users | Converted Users | Abandoned Users | Conversion Rate | Abandonment Rate |
|---:|---:|---:|---:|---:|---:|
| 33955 | 42 | 19 | 23 | 45.24% | 54.76% |
| 80130 | 50 | 22 | 28 | 44.00% | 56.00% |
| 126831 | 53 | 23 | 30 | 43.40% | 56.60% |
| 145705 | 146 | 63 | 83 | 43.15% | 56.85% |
| 160485 | 55 | 22 | 33 | 40.00% | 60.00% |

Even the strongest products lose more than half of users who add them to cart. This suggests cart abandonment is a platform-level issue.

### 6.2 Product Ranking Requires Volume Thresholds

A product with very few cart users can show an artificially high conversion rate.

Recommended minimum threshold:

```text
Cart Users >= 20
```

Recommended interpretation:

- High conversion, high volume: benchmark products
- High conversion, low volume: monitor
- Low conversion, high volume: urgent opportunity
- Low conversion, low volume: lower priority

---

## 7. Weekday Performance Findings

| Day | Average Active Users | Average Purchases | User Conversion Rate | Same-Day Cart Abandonment |
|---|---:|---:|---:|---:|
| Monday | 17,720.73 | 705.36 | 3.18% | 87.50% |
| Tuesday | 17,681.73 | 806.27 | 3.40% | 86.84% |
| Wednesday | 17,367.91 | 569.27 | 2.68% | 88.58% |
| Thursday | 17,602.09 | 734.36 | 3.30% | 86.97% |
| Friday | 17,158.73 | 682.27 | 3.24% | 86.91% |
| Saturday | 16,683.40 | 514.30 | 2.55% | 89.14% |
| Sunday | 15,624.45 | 421.45 | 2.03% | 89.71% |

### 7.1 Tuesday Is the Strongest Weekday

Tuesday recorded the highest average purchase count and user conversion.

Recommended uses:

- Purchase-focused campaigns
- Limited-time offers
- High-intent user targeting
- Cart-recovery promotions

### 7.2 Thursday Is Another Strong Purchase Day

Thursday also recorded strong purchase activity and conversion, making it suitable as a second conversion-focused campaign day.

### 7.3 Sunday Is the Weakest Day

Sunday recorded the lowest active users, purchases, and conversion, with the highest same-day cart abandonment.

Recommended uses:

- Awareness campaigns
- Product discovery
- Cart reminders
- Re-engagement
- Monday pre-conversion campaigns

---

## 8. Hourly Performance Findings

| Hour | Average Active Users | Average Purchases | User Conversion | Same-Hour Cart Conversion | Same-Hour Cart Abandonment |
|---|---:|---:|---:|---:|---:|
| 00:00–01:00 | 1,018.72 | 46.72 | 3.11% | 10.63% | 89.37% |
| 10:00–11:00 | 1,728.41 | 46.09 | 2.26% | 9.71% | 90.29% |
| 20:00–21:00 | 1,912.57 | 41.47 | 1.77% | 8.17% | 91.83% |
| 21:00–22:00 | 2,126.21 | 39.80 | 1.55% | 6.70% | 93.30% |
| 22:00–23:00 | 2,069.95 | 40.36 | 1.59% | 6.44% | 93.56% |

### 8.1 Midnight Has Strong Purchase Performance

The 00:00–01:00 period produced the highest average purchase count.

Recommended uses:

- Recent cart users
- High-intent users
- Time-limited offers
- Late-night flash promotions

### 8.2 Late Morning Is Another Strong Window

The 10:00–11:00 period also produced strong average purchase activity.

Recommended uses:

- Purchase reminders
- Product recommendations
- Coupon campaigns
- Workday conversion messages

### 8.3 Evening Traffic Is High but Conversion Is Weak

The 20:00–23:00 period has high traffic but weaker purchase efficiency.

Recommended uses:

- Product discovery
- Recommendations
- Retargeting
- Cart reminders for the next morning

---

## 9. Comment and Product-Quality Findings

The product-performance mart includes:

- Latest comment snapshot
- Bad-comment indicator
- Bad-comment rate

These fields can support product-quality review, but the analysis does not establish that negative comments cause lower conversion.

Recommended uses:

- Flag high-abandonment products with high bad-comment rates.
- Compare products within the same category.
- Review repeated quality issues.
- Combine comments with delivery, stock, and product-page data.

---

## 10. Priority Action Plan

### Priority 1: Recover High-Intent and Cart-Abandonment Users

Target:

- 28,565 High Purchase Intent users
- 14,079 Cart-Abandonment users

Actions:

- Personalised reminders
- Cart recovery messages
- Limited-time coupons
- Delivery reassurance
- Stock notifications
- Alternative-product suggestions

### Priority 2: Improve Category 8

Reason:

```text
41,016 abandoned cart users
```

Actions:

- Identify the highest-impact SKUs.
- Review price, stock, delivery, and product information.
- Run product-level conversion tests.
- Compare with Category 7.

### Priority 3: Investigate Categories 10 and 11

Reason:

```text
Category 10 abandonment = 90.71%
Category 11 abandonment = 100.00%
```

Actions:

- Validate stock and purchase availability.
- Check fulfilment and checkout problems.
- Review product substitution.

### Priority 4: Target High-Impact Brands

Focus on brands with both high abandonment rates and large abandoned-user counts.

### Priority 5: Optimise Campaign Timing

| Campaign Type | Recommended Timing |
|---|---|
| Direct conversion offers | Tuesday and Thursday |
| High-intent reminders | 00:00–01:00 and 10:00–11:00 |
| Product recommendations | 20:00–23:00 |
| Cart recovery | Evening activity followed by next-morning reminders |
| Awareness and discovery | Weekend periods |

---

## 11. Recommended Experiments

1. Cart reminder versus no reminder
2. Coupon versus no coupon
3. Immediate versus delayed reminder
4. Delivery-message variants
5. Product-page improvements
6. Category-specific offers
7. Purchase-intent threshold validation
8. Tuesday versus Sunday campaign timing
9. Midnight versus morning campaign delivery
10. Product-specific versus category-wide incentives

Suggested evaluation metrics:

- Purchase conversion rate
- Cart recovery rate
- Incremental buyers
- Incremental purchase actions
- Coupon cost per conversion
- Repeat purchase rate
- Notification-dismissal rate

---

## 12. Limitations

- The dataset covers a historical period in 2016.
- January and April contain partial observation periods.
- User, product, category, and brand identifiers are anonymised.
- Product price and revenue are unavailable.
- Purchase actions may not represent final payment, fulfilment, cancellation, or return.
- Users may skip funnel stages.
- Same-day and same-hour metrics are stricter than full-period metrics.
- The purchase-intent score is rule-based.
- Product-comment analysis is descriptive.
- Customer behaviour outside JD.com is unavailable.

---

## 13. Conclusion

The analysis shows strong browsing and clicking activity but substantial conversion leakage.

The main business opportunities are:

- High-intent user conversion
- Cart-abandonment recovery
- Category 8 optimisation
- Investigation of Categories 10 and 11
- High-impact brand review
- Better weekday and hourly campaign timing

The completed Python, MySQL, SQL, Tableau, and Excel pipeline provides a reproducible foundation for customer segmentation, conversion analysis, product optimisation, and campaign planning.
