# Business Requirements Document

## 1. Project Title

**JD.com User Behavior Funnel and Purchase Intention Analytics**

## 2. Business Background

JD.com records a large number of customer interactions, including product browsing, clicking, following, adding to cart, removing from cart, and purchasing.

Although many users interact with products, only a portion of them complete an order. E-commerce operation teams need to understand where users leave the purchasing process, which products generate strong interest but weak sales, and which users are most likely to make a future purchase.

This project uses the JD.com JData2016 dataset to analyse customer behaviour and support data-driven marketing, product, and customer-retention decisions.

## 3. Business Problem

The business currently lacks a consolidated analytical view of the customer purchasing journey.

Key operational problems include:

* A large number of users browse products without purchasing.
* Some products receive many clicks or cart additions but have low order conversion.
* The business cannot easily identify users with strong purchase intention.
* Marketing resources may be spent on users who are unlikely to convert.
* Differences in purchasing behaviour across user groups, products, brands, and time periods are unclear.
* Cart abandonment and product removal behaviour are not sufficiently monitored.

The project will transform raw behavioural records into business metrics, customer segments, and actionable insights.

## 4. Project Objectives

The project aims to:

1. Measure the complete customer conversion funnel.
2. Identify major user-drop-off points before purchase.
3. Analyse product, category, and brand conversion performance.
4. Detect products with high interest but low purchase conversion.
5. Identify users with high purchase intention.
6. Analyse shopping behaviour across different time periods.
7. Compare behaviour among different user groups and membership levels.
8. Provide recommendations for targeted marketing and product operations.

## 5. Stakeholders

The main stakeholders are:

* E-commerce Operations Team
* Marketing Team
* Customer Relationship Management Team
* Product and Category Managers
* Business Intelligence Analysts
* Senior Management

## 6. Dataset Scope

The project uses the JD.com JData2016 dataset.

The main source files include:

| Dataset                   | Description                                                              |
| ------------------------- | ------------------------------------------------------------------------ |
| `JData_User.csv`          | User profile, age group, gender, membership level, and registration date |
| `JData_Product.csv`       | Product ID, product attributes, category, and brand                      |
| `JData_Comment.csv`       | Product comment count, review level, and positive review rate            |
| `JData_Action_201602.csv` | User behaviour records from February 2016                                |
| `JData_Action_201603.csv` | User behaviour records from March 2016                                   |
| `JData_Action_201604.csv` | User behaviour records from April 2016                                   |

The user action table contains the following behaviour types:

| Type | User Behaviour           |
| ---: | ------------------------ |
|    1 | Browse product           |
|    2 | Add product to cart      |
|    3 | Remove product from cart |
|    4 | Purchase product         |
|    5 | Follow product           |
|    6 | Click product            |

## 7. Key Business Questions

### 7.1 Customer Conversion Funnel

* How many users browse, follow, add to cart, and purchase products?
* What is the conversion rate between each funnel stage?
* At which stage does the largest customer drop-off occur?
* How does the conversion funnel change over time?

### 7.2 Cart Abandonment

* How many users add products to their carts without purchasing?
* Which products and brands have the highest cart-abandonment rates?
* How often do users remove products after adding them to their carts?
* How long does it usually take for a cart addition to result in a purchase?

### 7.3 Product and Brand Performance

* Which products, categories, and brands generate the most interactions?
* Which products have the highest purchase conversion rates?
* Which products have high browsing activity but low sales?
* Which products have high cart additions but low purchase conversion?
* Does positive customer feedback correspond with stronger conversion?

### 7.4 Customer Segmentation

* Which users demonstrate strong purchase intention?
* How do new and existing customers behave differently?
* How does purchasing behaviour vary by age group, gender, and membership level?
* Which users are suitable for cart reminders, coupons, or product recommendations?

### 7.5 Time-Based Behaviour

* What hours and days generate the highest shopping activity?
* When do users most frequently place orders?
* Are there periods with high browsing activity but low conversion?
* How do user actions change across February, March, and April?

## 8. Key Performance Indicators

The project will calculate the following KPIs:

| KPI                     | Business Definition                                                       |
| ----------------------- | ------------------------------------------------------------------------- |
| Active Users            | Number of users who perform at least one recorded action                  |
| Product Views           | Total number of product browsing actions                                  |
| Product Clicks          | Total number of product click actions                                     |
| Product Follows         | Total number of product-following actions                                 |
| Cart Additions          | Total number of add-to-cart actions                                       |
| Cart Removals           | Total number of cart-removal actions                                      |
| Orders                  | Total number of purchase actions                                          |
| Unique Buyers           | Number of users who complete at least one purchase                        |
| View-to-Cart Rate       | Users who add to cart divided by users who browse                         |
| Cart-to-Purchase Rate   | Users who purchase divided by users who add to cart                       |
| Overall Conversion Rate | Unique buyers divided by active users                                     |
| Cart-Abandonment Rate   | Users who add to cart without purchasing divided by users who add to cart |
| Product Conversion Rate | Product buyers divided by users who interact with the product             |
| Repeat Purchase Rate    | Buyers with multiple purchases divided by all buyers                      |

## 9. Purchase Intention Segmentation

Users will be assigned a purchase-intention score based on their recent behaviour.

A preliminary scoring model may use:

| Behaviour        |              Suggested Score |
| ---------------- | ---------------------------: |
| Browse product   |                           +1 |
| Click product    |                           +1 |
| Follow product   |                           +3 |
| Add to cart      |                           +5 |
| Remove from cart |                           -3 |
| Purchase product |                           +8 |
| Recent activity  | Additional recency weighting |

Users can then be grouped into:

* High Purchase Intent
* Medium Purchase Intent
* Low Purchase Intent
* Existing Customer
* Cart-Abandonment User
* Inactive User

These segments can support targeted actions such as:

* Sending cart reminders
* Offering discount coupons
* Recommending related products
* Promoting membership benefits
* Re-engaging inactive users

## 10. Analytical Deliverables

The final project will include:

### SQL Analysis

* Data cleaning and validation
* Multi-table joins
* Customer funnel calculations
* Cart-abandonment analysis
* Product and brand performance analysis
* Customer segmentation
* Time-series analysis
* Common Table Expressions
* Window functions
* Ranking and cohort-style queries

### Tableau Dashboard

The Tableau dashboard will contain four main pages:

1. Executive Overview
2. Customer Behaviour Funnel
3. Product and Brand Performance
4. Purchase Intention and Customer Segmentation

### Project Documentation

* Business requirements
* Dataset description
* Data dictionary
* Database schema
* SQL scripts
* Analysis findings
* Business recommendations
* Project README

## 11. Business Recommendations Expected

The analysis should produce recommendations related to:

* Reducing cart abandonment
* Improving product conversion
* Targeting high-intent users
* Optimising campaign timing
* Identifying underperforming products
* Improving customer-retention strategies
* Allocating marketing resources more effectively

## 12. Project Success Criteria

The project will be considered successful when it can:

* Produce a reliable customer conversion funnel.
* Identify major customer drop-off points.
* Calculate product and user-level conversion metrics.
* Identify high-intent and cart-abandonment users.
* Present business findings through an interactive dashboard.
* Translate analytical results into practical operational recommendations.

## 13. Project Limitations

* The dataset represents historical JD.com activity from 2016.
* Customer and product information has been anonymised.
* Product names and brand names may not be directly available.
* The analysis measures behavioural relationships and does not prove causation.
* A purchase action represents an order event and may not include final payment, cancellation, or return information.
* The purchase-intention score is an analytical business rule and should be validated before production use.
