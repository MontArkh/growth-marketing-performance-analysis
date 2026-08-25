# Growth Marketing Performance Analysis

## Overview

This project analyzes paid media performance across campaigns, platforms, ad formats, audiences and time periods using a synthetic social media advertising dataset.

The goal was to simulate a real-world Growth Analytics workflow: starting from raw relational data, validating data quality, building an analytical layer with SQL, developing interactive Tableau dashboards and translating the findings into actionable marketing recommendations.

**Tools:** BigQuery · SQL · Tableau Public  
**Dataset:** 400K events · 200 ads · 50 campaigns · 10K user records

---

## Dashboard

**Tableau Public:**

https://public.tableau.com/views/AudienceTargeting_17876856231030/AudienceTargeting
https://public.tableau.com/views/GrowthMarketingPerformance/GrowthMarketingPerformance

---

## Business Problem

The marketing team needs to understand:

- Which campaigns and ad formats generate the strongest performance?
- Are Facebook and Instagram meaningfully different in efficiency?
- Which campaigns combine scale with strong CTR and purchase-related performance?
- Are specific audience segments or time periods associated with better results?
- Does the observed audience align with the declared targeting strategy?
- Where should the team prioritize further testing and optimization?

---

## Data Structure

The original dataset contained four relational tables:

**campaigns**  
Campaign metadata, dates, duration and total budget.

**ads**  
Ad platform, format and targeting attributes.

**ad_events**  
Individual advertising events including impressions, clicks, likes, shares and purchases.

**users**  
User demographics, location and interests.

The relational model was:

`campaigns → ads → ad_events ← users`

A consolidated analytical view called `ad_performance` was created in BigQuery to provide one event-level source for analysis and visualization.

---

## Data Quality & Preparation

Before analyzing performance, I performed data profiling and quality checks covering null values, duplicate keys, referential integrity, categorical consistency, derived date fields and temporal logic.

### User ID collisions

The `users` table contained 50 duplicated `user_id` values representing different users rather than duplicate records.

These IDs affected **3,967 of 400,000 events (0.99%)**.

Joining the original user table to the event table increased the number of rows from:

**400,000 → 403,967**

demonstrating a join fanout problem.

To preserve event-level granularity, I created a `valid_users` view containing only unambiguous user IDs and joined it to the event data using a `LEFT JOIN`.

The resulting analytical view preserved exactly:

**400,000 events = 400,000 unique event IDs**

Events associated with ambiguous users were retained for campaign-level analysis but excluded from demographic enrichment.

### Campaign date inconsistency

Approximately **55.63% of events occurred outside the declared start/end dates of their associated campaigns**.

Because the dataset is synthetic and this inconsistency was widespread, these events were retained rather than removing more than half of the dataset.

Campaign start/end dates were therefore not used for campaign pacing or active-period performance analysis.

### Event sequencing

The event data did not consistently represent a sequential user journey.

Among valid user-ad combinations:

- 33,249 clicks occurred without a recorded impression
- 1,987 purchases occurred without a recorded click
- 2,979 first clicks occurred before the first recorded impression
- 11 purchases occurred before the first recorded click

Because of this, the analysis does **not** interpret Impression → Click → Purchase as a true user-level conversion funnel.

Metrics such as Purchase / Impression are treated as **aggregate event ratios**, not causal conversion rates.

---

## Core Performance

Across the full dataset:

| KPI | Result |
|---|---:|
| Impressions | 339.8K |
| Clicks | 40.1K |
| CTR | 11.79% |
| Engagements | 14.0K |
| Engagement Rate | 4.11% |
| Purchases | 2.0K |
| Purchase / Impression | 0.60% |

---

## Dashboard 1 — Growth Marketing Performance

The first dashboard focuses on overall advertising performance across campaigns, platforms and formats.

It includes:

- Core marketing KPIs
- Facebook vs Instagram performance
- Ad format comparison
- Campaign volume vs CTR analysis
- CTR evolution over time
- Interactive filters for date, platform and campaign

### Key Insight 1 — Platform scale differs more than platform efficiency

Facebook generated substantially more volume:

- **Facebook:** 216.0K impressions
- **Instagram:** 123.8K impressions

However, efficiency remained very similar.

| Metric | Facebook | Instagram |
|---|---:|---:|
| CTR | 11.76% | 11.86% |
| Engagement Rate | 4.07% | 4.19% |
| Purchase / Impression | 0.61% | 0.57% |

**Insight:** Platform choice alone does not explain meaningful differences in performance. Optimization opportunities are more likely to exist at campaign, creative or timing level.

---

### Key Insight 2 — The strongest format depends on the objective

Video produced the highest observed CTR:

**Video CTR: 11.90%**

However, Stories generated the strongest:

- **Engagement Rate: 4.14%**
- **Purchase / Impression: 0.63%**

Image ads also generated a relatively strong CTR of **11.88%**, but the lowest Purchase / Impression ratio at **0.55%**.

**Insight:** The format generating the most clicks is not necessarily the format associated with stronger downstream actions.

---

### Key Insight 3 — Campaign-level variation is more meaningful than platform-level variation

Campaign performance showed substantially more variation than the aggregated platform results.

Two campaigns stood out for combining scale and strong downstream performance.

#### Campaign_17_Launch

- 13.5K impressions
- 12.2% CTR
- 91 purchases
- 0.67% Purchase / Impression

#### Campaign_38_Q3

- 13.4K impressions
- 11.9% CTR
- 96 purchases
- **0.72% Purchase / Impression**

Both outperformed the overall Purchase / Impression baseline of **0.60%** while maintaining significant volume.

---

### Key Insight 4 — Higher CTR does not necessarily mean stronger purchase performance

Campaign_12_Q3 recorded the highest CTR among the highlighted campaigns:

**CTR: 12.9%**

However:

- Impressions: 3.4K
- Purchases: 16
- Purchase / Impression: **0.47%**

By contrast, Campaign_38_Q3 recorded:

- CTR: 11.9%
- Purchase / Impression: **0.72%**

**Insight:** Optimizing exclusively for CTR can favor campaigns that generate clicks without producing similarly strong downstream results.

---

### Key Insight 5 — Some high-volume campaigns deserve further investigation

Campaign_42_Summer generated:

- 13.7K impressions
- 11.7% CTR
- 67 purchases
- **0.49% Purchase / Impression**

The campaign delivered significant scale but below-average downstream efficiency.

Campaign_24_Summer also had high volume and lower CTR:

- 13.6K impressions
- 11.5% CTR
- 0.59% Purchase / Impression

These campaigns should be investigated before additional budget is allocated.

---

## Dashboard 2 — Audience & Targeting

The second dashboard explores audience composition, targeting alignment and differences in CTR by age, country, day and time.

It includes:

- Age Target Match Rate
- Gender Target Match Rate
- Target vs actual demographic distributions
- CTR by age group
- CTR by country
- CTR by day and time
- Interactive platform and campaign filters

### Key Insight 6 — Declared targeting does not meaningfully change observed demographics

Overall:

**Age Target Match Rate: 28.49%**  
**Gender Target Match Rate: 41.95%**

More importantly, the demographic distributions remain almost identical across targeting groups.

For gender:

| Target | Female | Male | Other |
|---|---:|---:|---:|
| All | 34.5% | 55.4% | 10.1% |
| Female | 34.5% | 55.5% | 10.1% |
| Male | 34.4% | 55.4% | 10.2% |

The same pattern is visible across age targeting groups.

The effect also remains similar across platforms:

| Platform | Age Match | Gender Match |
|---|---:|---:|
| Facebook | 28.85% | 41.36% |
| Instagram | 27.95% | 43.01% |

**Interpretation:** The lack of alignment appears dataset-wide rather than platform-specific and likely reflects independent synthetic generation of targeting and user demographic attributes.

For this reason, this finding is treated as a **data limitation rather than a marketing performance issue**.

---

### Key Insight 7 — Time of day shows a stronger optimization signal

Friday Afternoon generated above-average CTR on both platforms:

**Facebook:** 12.4%  
**Instagram:** 12.9%

Thursday Afternoon underperformed on both:

**Facebook:** 11.1%  
**Instagram:** 11.0%

This pattern is more consistent than most platform, country or audience-level differences.

**Insight:** Timing may represent a more meaningful optimization lever than platform selection alone.

---

## Recommendations

### 1. Test incremental scaling of strong campaigns

Campaign_17_Launch and Campaign_38_Q3 combine meaningful scale with above-average purchase-event performance.

They should be prioritized for controlled budget scaling tests while monitoring whether efficiency remains stable at higher volumes.

### 2. Match creative format to campaign objective

Use different optimization criteria depending on the business objective.

- Traffic-oriented campaigns: prioritize testing Video and Image
- Engagement or downstream-event objectives: prioritize Stories testing

Creative decisions should not be based exclusively on CTR.

### 3. Run a controlled dayparting experiment

Increase exposure during Friday Afternoon and compare performance against lower-performing periods such as Thursday Afternoon.

CTR should be evaluated together with Purchase / Impression before making permanent budget changes.

### 4. Review high-volume campaigns with weaker downstream efficiency

Campaign_42_Summer should be investigated because it combines high scale with a below-average Purchase / Impression ratio.

Potential areas for investigation include creative, audience, placement and campaign objective.

### 5. Avoid CTR-only optimization

Campaign_12_Q3 demonstrates that a high CTR does not necessarily translate into stronger downstream event performance.

Campaign evaluation should combine:

**volume + CTR + engagement + purchase-event efficiency**

rather than relying on a single metric.

---

## Limitations

This project uses synthetic advertising data.

Several quality checks suggest that some fields were generated independently:

- campaign dates and event timestamps are not consistently aligned;
- user targeting attributes do not meaningfully influence observed demographics;
- event sequences do not represent a reliable user conversion journey;
- campaign budget represents planned budget rather than confirmed media spend.

Therefore, metrics such as ROAS, CPA and true user-level conversion rates were intentionally not calculated.

The project focuses instead on event-level advertising performance, comparative analysis and analytical decision-making.

---

## Project Workflow

`Raw CSVs`  
↓  
`BigQuery`  
↓  
`Data Profiling & Quality Checks`  
↓  
`SQL Cleaning & Modeling`  
↓  
`ad_performance Analytical View`  
↓  
`Tableau Public`  
↓  
`Interactive Dashboards`  
↓  
`Insights & Growth Recommendations`

---

## Skills Demonstrated

- SQL querying and transformation
- Relational data modeling
- Data quality validation
- Join cardinality and fanout detection
- BigQuery
- KPI definition
- Marketing and Growth Analytics
- Tableau dashboard development
- Interactive data visualization
- Data storytelling
- Analytical decision-making
