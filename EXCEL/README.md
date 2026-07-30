# Excel Analysis

## Workbook

`JD_User_Behavior_Excel_Analysis.xlsx`

## Purpose

This workbook complements the Tableau portfolio by demonstrating spreadsheet-based analysis, auditable formulas, refreshable source tables, native PivotTables, PivotCharts, a connected category slicer, conditional formatting, and executive dashboard reporting.

## Data Sources

Five Power Query queries load summary CSV files produced from these MySQL analytical marts:

| Power Query | Excel Table | MySQL analytical mart |
|---|---|---|
| `qExecutiveKPI` | `tExecutive` | `mart_dashboard_executive` |
| `qCustomerSegments` | `tSegments` | `mart_segment_performance` |
| `qCategoryPerformance` | `tCategory` | `mart_category_performance` |
| `qProductPerformance` | `tProduct` | `mart_product_performance` |
| `qHourlyPerformance` | `tHourly` | `mart_hourly_performance` |

The 50-million-row raw action table is not loaded directly into Excel. The workbook uses analytical marts at the appropriate reporting grain. The product source contains all 28,710 rows from `mart_product_performance`; it is not the earlier 1,000-row limited export.

## Workbook Sheets

- `Dashboard` — executive KPIs, four native PivotCharts, a category slicer, product XLOOKUP, and selected-category SUMIFS/COUNTIFS analysis.
- `Executive_KPI` — refreshable executive metrics table `tExecutive`.
- `Customer_Segments` — refreshable segment table `tSegments` with data bars and a percentage colour scale.
- `Category_Performance` — refreshable category table `tCategory`, operational-priority and abandonment-rank formulas, and risk formatting.
- `Product_Performance` — refreshable complete product table `tProduct`, conversion-rank and product-risk formulas, and conversion/risk formatting.
- `Hourly_Performance` — refreshable hourly table `tHourly`, ordered from hour 0 to 23.
- `Data_Dictionary` — field definitions in `tDictionary`.
- `Pivot_Data` — hidden support sheet containing native PivotTables used by the dashboard.

## Excel Skills Demonstrated

- Power Query
- Refreshable Excel Tables
- Structured references
- Native PivotTables
- Native PivotCharts
- Native slicer with two report connections
- Conditional formatting
- XLOOKUP
- INDEX
- IF
- AND
- RANK.EQ
- SUMIFS
- COUNTIFS
- Custom number formatting
- Dashboard design and business reporting

## Formula Columns

`tCategory` contains:

- `Operational Priority` — nested `IF` and `AND` classification based on abandonment rate and affected-user volume.
- `Abandonment Rank` — `RANK.EQ` against `tCategory[cart_abandon_users]`.

`tProduct` contains:

- `Conversion Rank` — `RANK.EQ` against `tProduct[cart_to_purchase_rate]`.
- `Product Risk` — nested `IF` and `AND` classification based on abandonment rate and cart-user volume.

The Dashboard contains:

- `INDEX` formulas for executive KPI cards.
- `XLOOKUP` formulas driven by the editable SKU input.
- `SUMIFS` and `COUNTIFS` formulas driven by the editable category input.

## PivotTables and PivotCharts

Required native PivotTables:

- `pvtCustomerSegments`
- `pvtCategoryAbandonment`
- `pvtCategoryConversion`
- `pvtHourlyPurchases`

An additional helper PivotTable, `pvtCustomerSegmentsChart`, keeps the customer-segment chart limited to user count while the required customer-segment PivotTable retains both user count and user percentage.

Dashboard PivotCharts:

- Customer Segment Distribution
- Category Abandonment Impact
- Purchase Performance by Hour
- Category Conversion Performance

The `Category Filter` slicer is connected to both `pvtCategoryAbandonment` and `pvtCategoryConversion`.

## Refresh Instructions

1. Keep the processed CSV files in `data/processed/excel/`:
   - `executive_kpi.csv`
   - `customer_segments.csv`
   - `category_performance.csv`
   - `product_performance.csv`
   - `hourly_performance.csv`
2. Open `JD_User_Behavior_Excel_Analysis.xlsx` in Microsoft Excel.
3. Select **Data > Refresh All**.
4. Wait for all five Power Query tables to finish refreshing.
5. Select **Data > Refresh All** again only if Excel reports that a PivotTable refreshed before its source query finished.
6. Confirm the dashboard KPIs and the Category 8 / SKU 33955 validation values below.

If the project folder is moved, open **Data > Queries & Connections**, edit each query's `File.Contents` source path, and point it to the new `data/processed/excel/` folder.

To refresh directly from MySQL, first export the five analytical marts to the corresponding CSV files. Do not export `stg_actions`, `fact_user_product_daily`, or `mart_user_product_period` into Excel.

## Validation Benchmarks

| Check | Expected value |
|---|---:|
| Registered Users | 105,321 |
| Active Users | 105,180 |
| Buyers | 29,485 |
| Total Actions | 50,601,736 |
| Purchase Actions | 48,252 |
| Observed Days | 76 |
| Customer segment total | 105,180 |
| Category 8 Cart Abandon Users | 41,016 |
| Category 11 Cart Abandonment Rate | 100.00% |
| Category 7 Cart Conversion Rate | 34.24% |
| SKU 33955 Cart Users | 42 |
| SKU 33955 Cart Conversion Rate | 45.24% |
| SKU 33955 Cart Abandonment Rate | 54.76% |

## Metric Notes

- Percentage fields are stored as percentage-point values. A stored value of `28.03` is formatted as `28.03%` with `0.00\%`; it is not multiplied by 100.
- Strict cart conversion requires the same user to add and purchase the same product during the defined analysis period.
- Same-day and same-hour conversion metrics are distinct from full-period strict conversion metrics.
- Users may skip behavioural funnel stages.
- The selected-category `SUMIFS` section sums product-level metrics. A user interacting with multiple products may be counted more than once, so these totals should not be interpreted as de-duplicated category-level users. Use `tCategory` for category-level distinct-user KPIs.

## Limitations

- Historical observation period: 31 January 2016 to 15 April 2016.
- User, product, category, and brand identifiers are anonymised.
- Product price and revenue data are unavailable.
- The purchase-intent score is rule-based.
- Purchase events may not represent completed fulfilment, payment, delivery, cancellation, or return outcomes.
- Power Query file paths are local to this Windows project and must be updated if the project directory moves.

## Security

Database credentials are not stored in the workbook, Power Query formulas, README, or screenshot. The workbook refreshes from processed summary CSV files and never loads raw JData action files.
