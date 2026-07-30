# Data Cleaning and Quality Report

## 1. Purpose

This report documents the profiling, cleaning, validation, and data-quality decisions applied to the JD.com JData2016 dataset.

The project retains valid behavioural activity while standardising encodings, identifiers, dates, unknown values, and analytical definitions.

---

## 2. Dataset Overview

The project contains six source CSV files:

- One user file
- One product file
- One comment file
- Three monthly action files

### Profiled Files

| File | Approximate Size | Encoding | Columns |
|---|---:|---|---:|
| `JData_Action_201602.csv` | 497.70 MB | UTF-8-SIG | 7 |
| `JData_Action_201603.csv` | 1.10 GB | UTF-8-SIG | 7 |
| `JData_Action_201604.csv` | 572.79 MB | UTF-8-SIG | 7 |
| `JData_Comment.csv` | 14.16 MB | UTF-8-SIG | 5 |
| `JData_Product.csv` | 441.90 KB | UTF-8-SIG | 6 |
| `JData_User.csv` | 2.95 MB | GBK | 5 |

Validated action rows:

```text
50,601,736
```

Validated action period:

```text
2016-01-31 23:59:02
to
2016-04-15 23:59:59
```

---

## 3. Data-Profiling Method

The Python script:

```text
scripts/01_profile_raw_data.py
```

was used to inspect:

- File availability
- File size
- Encoding
- Column names
- Sample values
- Preliminary data types
- Sample missing values

Only a small sample was read during profiling. Large action files were not loaded fully into memory.

---

## 4. Encoding Handling

The source files use different encodings.

| File Group | Encoding Used |
|---|---|
| `JData_User.csv` | `GBK` |
| Product, comment, and action files | `UTF-8-SIG` |

This handling preserves Chinese age-group values in the user file and prevents malformed text during ingestion.

---

## 5. Identifier Cleaning

### 5.1 User IDs

The action files store user IDs in decimal-like form, such as:

```text
266079.0
```

The staging layer preserves this source representation using:

```sql
DECIMAL(15,1)
```

Analytical tables convert the value to an integer user ID using:

```sql
CAST(user_id AS UNSIGNED)
```

Validation confirmed:

```text
fractional_user_ids = 0
```

This means no source user ID contained a non-zero fractional component.

### 5.2 Model IDs

`model_id` contains many missing values. These values were retained as `NULL` because the field is not required for the selected business analyses.

Validated missing `model_id` count:

```text
20,655,896
```

Validation confirmed that non-null model IDs did not contain unexpected fractional components.

---

## 6. Date and Time Cleaning

The following source fields were standardised:

| Source Field | Target Type |
|---|---|
| `user_reg_tm` | `DATE` |
| `dt` | `DATE` |
| `time` | `DATETIME` |

Invalid dates are converted to `NULL` during ingestion and then audited.

The action-file names do not define the exact analysis month. Some files begin with records from the final seconds of the previous calendar date. All time-based analysis therefore uses `action_time`, not the filename.

---

## 7. Missing and Unknown Values

### 7.1 User Age

The source value:

```text
-1
```

represents an unknown age group.

Cleaning rule:

```text
-1 → Unknown
```

The clean field is:

```text
dim_users.age_group
```

An additional field:

```text
age_unknown_flag
```

records whether the source value was unknown.

### 7.2 User Sex

Supported sex codes are retained. Unsupported or invalid codes are converted to `NULL`.

Three active users had `NULL` sex values after cleaning.

### 7.3 Product Attributes

The source uses `-1` for unknown product attributes.

Cleaning rules:

```text
a1 = -1 → NULL
a2 = -1 → NULL
a3 = -1 → NULL
```

Validated clean unknown counts:

| Attribute | Unknown Count |
|---|---:|
| `attribute_a1` | 1,701 |
| `attribute_a2` | 4,050 |
| `attribute_a3` | 3,815 |

These records were retained because the product and behavioural data remain analytically useful.

---

## 8. Duplicate Validation

### 8.1 User Profiles

The user table was checked for duplicate `user_id` values.

Expected and validated result:

```text
duplicate_user_ids = 0
```

### 8.2 Product Profiles

The product table was checked for duplicate `sku_id` values.

Expected and validated result:

```text
duplicate_product_ids = 0
```

### 8.3 Comment Snapshots

Comment snapshots were checked using the composite business key:

```text
comment_date + sku_id
```

Expected and validated result:

```text
duplicate_comment_snapshots = 0
```

### 8.4 Behavioural Events

Repeated behavioural rows were not automatically removed.

Reason:

- Repeated clicks may represent valid customer activity.
- Repeated browsing may represent genuine product comparison.
- Events are recorded at second-level timestamps.
- The source does not provide a unique event ID that can reliably distinguish duplicate logging from repeated user actions.

The project therefore preserves source behavioural events and validates downstream totals instead of deleting repeated actions without evidence.

---

## 9. Behaviour-Type Validation

Valid action types are:

```text
1, 2, 3, 4, 5, 6
```

Validated action totals:

| Action Type | Behaviour | Count |
|---:|---|---:|
| 1 | Browse | 18,981,373 |
| 2 | Add to cart | 575,418 |
| 3 | Remove from cart | 256,053 |
| 4 | Purchase | 48,252 |
| 5 | Follow | 109,896 |
| 6 | Click | 30,630,744 |
|  | **Total** | **50,601,736** |

Validation confirmed:

```text
invalid_action_types = 0
```

---

## 10. Referential-Integrity Treatment

The project checks for:

- Active users without user profiles
- Registered users without activity
- Active products without product profiles
- Comment records without product profiles
- Category inconsistencies
- Brand inconsistencies

Missing dimension records do not automatically cause behavioural records to be deleted.

Decision:

- Behavioural activity is retained.
- Missing profile attributes are represented as unknown where practical.
- Analytical metrics are based on valid behaviour even when descriptive profile data is unavailable.

This approach avoids losing real customer activity because of incomplete reference data.

---

## 11. Category and Brand Consistency

The project compares category and brand values from behavioural records with `dim_products`.

Analytical preference:

1. Use product-dimension category and brand values when a matching product profile exists.
2. Use action-record category and brand values when the product dimension is unavailable.

This rule provides consistent reporting while retaining activity for products missing from the product profile.

---

## 12. Comment Data Treatment

The comment table contains repeated product snapshots over time.

Cleaning and modelling rules:

- Preserve each product-date snapshot.
- Use `(comment_date, sku_id)` as the primary key.
- Use the latest available comment snapshot for product-performance analysis.
- Treat `bad_comment_rate` as a proportion between `0` and `1`.
- Use comment analysis descriptively.

The project does not claim that bad comments cause lower conversion.

---

## 13. Cart-Conversion Definition

An early product-level calculation used:

```text
all buyers / cart users
```

This could misclassify direct buyers as cart conversions.

The metric was corrected.

### Strict Cart Conversion

A converted user-product pair requires:

```text
cart_add_flag = 1
and
purchase_flag = 1
```

for the same user and same product during the observation period.

### Cart Abandonment

A user-product pair is abandoned when:

```text
cart_add_flag = 1
and
purchase_flag = 0
```

Validation rule:

```text
cart_users
=
cart_converted_users
+
cart_abandon_users
```

Validated result:

```text
inconsistent_products = 0
```

This strict definition is used in product, category, brand, and executive analyses.

---

## 14. Time-Bound Conversion Metrics

The project also calculates:

- Same-day cart conversion
- Same-hour cart conversion

These metrics use stricter time boundaries than the full-period cart metric.

Example:

A user who adds a product at `22:50` and purchases it at `23:10` is:

- A full-period converted cart pair
- Not a same-hour converted cart pair

Same-day and same-hour abandonment rates are clearly labelled in Tableau and documentation. They are not presented as full-period cart-abandonment rates.

---

## 15. User Segmentation Quality

The customer-segmentation model uses:

- Browsing
- Clicking
- Following
- Cart additions
- Cart removals
- Purchases
- Recency

Segments are mutually exclusive.

Validated segment counts:

| Segment | Users | Share |
|---|---:|---:|
| Medium Purchase Intent | 31,843 | 30.27% |
| Existing Customer | 29,485 | 28.03% |
| High Purchase Intent | 28,565 | 27.16% |
| Cart-Abandonment User | 14,079 | 13.39% |
| Low Purchase Intent | 1,207 | 1.15% |
| Other Active User | 1 | 0.00% |
| **Total** | **105,180** | **100.00%** |

Validation result:

```text
active_users = 105,180
segment_users = 105,180
user_difference = 0
```

The purchase-intent score is rule-based and should be validated before production deployment.

---

## 16. Analytical Reconciliation

Every action-based analytical layer was reconciled to the staging action total.

Expected value:

```text
50,601,736
```

Reconciled layers include:

- `stg_actions`
- `fact_user_product_daily`
- `mart_user_product_period`
- `mart_user_summary`
- `mart_product_performance`
- `mart_category_performance`
- `mart_brand_performance`
- `mart_daily_performance`
- `mart_hourly_performance`

Final validation:

| Metric | Source | Analytical Result | Difference |
|---|---:|---:|---:|
| Total actions | 50,601,736 | 50,601,736 | 0 |
| Active users | 105,180 | 105,180 | 0 |

This confirms that aggregation did not lose or duplicate source behaviour.

---

## 17. Data-Quality Decisions

| Issue | Decision |
|---|---|
| Mixed file encodings | Read each source with its correct encoding |
| Decimal-like user IDs | Convert to integer in analytical tables |
| Missing `model_id` | Retain as `NULL` |
| Unknown age `-1` | Convert to `Unknown` |
| Unknown product attributes `-1` | Convert to `NULL` |
| Unsupported sex codes | Convert to `NULL` |
| Repeated behaviour | Retain unless a reliable event-level duplicate key exists |
| Missing dimension profiles | Retain valid behaviour and use unknown attributes |
| Comment snapshots | Preserve by date and use the latest snapshot for product analysis |
| Direct buyers | Keep separate from strict cart-converted users |
| Same-day/hour metrics | Label explicitly to prevent misinterpretation |

---

## 18. Limitations

- The dataset is historical and covers 2016.
- The observation period is limited.
- January and April are partial periods.
- Product, category, brand, and user identifiers are anonymised.
- Price and revenue are unavailable.
- Purchase actions may not represent completed payment, fulfilment, cancellation, or returns.
- Behavioural logs do not provide a unique event ID.
- The purchase-intent score is rule-based.
- Comment analysis is descriptive and does not establish causality.

---

## 19. Conclusion

The cleaning and quality process standardised the source data without removing valid customer behaviour.

The final analytical layer:

- Preserves all `50,601,736` actions
- Covers all `105,180` active users
- Uses consistent dates, identifiers, and unknown-value handling
- Applies a strict same-user, same-product cart-conversion definition
- Supports reproducible SQL analysis and Tableau dashboards
