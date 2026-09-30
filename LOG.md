# Project Log

This log records the major analytical decisions, validation checks, and methodological changes made during the FAERS project. Routine syntax debugging and local IDE setup details are intentionally omitted.

## 2026-09-23 — Project Setup and Initial Data Inspection

### Data Setup

- Created the `glp1-faers-signals` project structure for raw data, SQL, scripts, and documentation.
- Set up Python, DuckDB, and the initial 2026 Q2 FAERS data.
- Verified that the FAERS ASCII files use `$` as the delimiter.
- Inspected report identifiers and case-version structure in `DEMO26Q2.txt`.

### Initial Findings

`DEMO26Q2.txt` contained:

- 422,459 rows
- 422,459 unique `primaryid` values
- 422,458 unique `caseid` values

One case appeared in two versions:

| caseid | caseversion | primaryid |
|---|---:|---:|
| 26012757 | 6 | 260127576 |
| 26012757 | 7 | 260127577 |

This confirmed that `caseid` identifies the underlying case, while `primaryid` identifies a specific report version.

### Methodological Decisions

- Keep raw FAERS data local and exclude it from GitHub.
- Use DuckDB to query the FAERS ASCII files directly.
- Use `primaryid` to join FAERS tables.
- Use `caseid` and `caseversion` to identify updated versions of the same case.
- Retain the highest available `caseversion` for each `caseid` during multi-quarter deduplication.

---

## 2026-09-26 — Initial FAERS Exploration

### Data Exploration

- Inspected the DEMO, DRUG, and REAC tables and their key fields.
- Identified `prod_ai` as the primary drug identifier and `pt` as the MedDRA Preferred Term for reported reactions.
- Counted unique Primary Suspect reports by active ingredient.
- Examined the most frequently reported adverse-event terms.
- Separated reusable SQL queries from Python execution scripts.

### Methodological Decisions

- Use `prod_ai` instead of free-text `drugname` because active ingredient names are more standardized.
- Restrict the main drug analysis to `role_cod = 'PS'` so the analysis focuses on drugs identified as the Primary Suspect.
- Use `COUNT(DISTINCT primaryid)` when counting reports to avoid inflation from one-to-many DRUG or REAC rows.
- Keep SQL analysis in `.sql` files and use Python for execution, statistical calculations, and visualization.

### Key Analytical Lesson

The unit of observation must be defined before aggregation. A row in the DRUG or REAC table is not necessarily a unique adverse-event report, so raw row counts can overstate report counts after joins.

---

## 2026-09-26 — Multi-Quarter Processing and Case Deduplication

### Multi-Quarter Expansion

Expanded the analysis from 2026 Q2 to four consecutive FAERS quarters:

- 2025 Q3
- 2025 Q4
- 2026 Q1
- 2026 Q2

Used DuckDB wildcard reads to query quarterly files together and verified that all four DRUG and REAC files were included.

### Deduplication

Investigated repeated `caseid` values across quarters and confirmed that a case can have multiple `caseversion` values with different `primaryid` values.

Built a latest-version workflow that:

1. Ranks versions within each `caseid` by descending `caseversion`.
2. Retains the latest available version.
3. Joins the retained `primaryid` values to DRUG and REAC.
4. Recalculates adverse-event counts using the deduplicated case set.

### Deduplication Validation

Several reaction counts decreased after deduplication:

| Drug | Reaction | Before Dedup | After Dedup |
|---|---|---:|---:|
| Semaglutide | Nausea | 4,936 | 4,812 |
| Semaglutide | Vomiting | 3,088 | 2,993 |
| Semaglutide | Diarrhoea | 2,546 | 2,459 |
| Tirzepatide | Nausea | 8,642 | 8,218 |
| Tirzepatide | Diarrhoea | 5,452 | 5,177 |
| Tirzepatide | Vomiting | 4,708 | 4,316 |

This confirmed that combining quarterly files without case-version filtering can double-count updated cases.

### Final Deduplicated Primary-Suspect Report Counts

- **Semaglutide: 35,666**
- **Tirzepatide: 70,037**

### Methodological Decisions

- Deduplicate cases before the final multi-quarter analysis.
- Continue counting distinct `primaryid` values after joins.
- Treat report counts as FAERS reporting counts, not patient exposure or adverse-event incidence.

---

## 2026-09-29 — Final Analysis and Project Deliverables

### Pre-Specified Clinical Outcome Groups

Defined four clinically relevant outcome groups for the primary semaglutide vs. tirzepatide comparison:

1. **Common GI symptoms:** Nausea, Vomiting, Diarrhoea, Constipation
2. **Pancreatitis:** Pancreatitis, Pancreatitis acute
3. **Gallbladder events:** Cholelithiasis, Cholecystitis, Cholecystitis acute
4. **GI motility / obstruction:** Impaired gastric emptying, Ileus, Intestinal obstruction

`Gastroparesis` was initially considered for the motility group. The general Preferred Term was not present in the analyzed REAC data; only `Diabetic gastroparesis` and `Gastroparesis postoperative` were observed. These more specific terms were not substituted into the predefined group.

Created:

```text
sql/14_check_clinical_outcomes.sql
sql/15_clinical_group_ror.sql
scripts/calculate_group_ci.py
```

### Clinical Group ROR Analysis

Constructed 2 × 2 contingency tables from deduplicated FAERS reports and calculated Reporting Odds Ratios (RORs) with 95% confidence intervals.

| Outcome Group | Semaglutide ROR (95% CI) | Tirzepatide ROR (95% CI) |
|---|---:|---:|
| Common GI symptoms | 3.45 (3.36–3.54) | 3.12 (3.06–3.18) |
| GI motility / obstruction | 18.65 (17.80–19.54) | 2.84 (2.67–3.03) |
| Gallbladder events | 5.82 (5.27–6.42) | 3.72 (3.40–4.07) |
| Pancreatitis | 5.17 (4.74–5.64) | 3.46 (3.20–3.74) |

Saved the group-level results to `data/clinical_group_ror.csv`.

### Interpretation Decision

- Treat ROR as a measure of **reporting disproportionality**.
- Do not interpret ROR as incidence, relative risk, or causality.
- Treat numerical differences between semaglutide and tirzepatide RORs as differences in reporting profiles rather than direct head-to-head risk estimates.

### Known-Signal Validation

Used common gastrointestinal reactions as a validation check for the processing and disproportionality pipeline.

| Drug | Reaction | ROR | 95% CI |
|---|---|---:|---:|
| Semaglutide | Nausea | 3.96 | 3.84–4.09 |
| Tirzepatide | Nausea | 3.51 | 3.43–3.60 |
| Semaglutide | Constipation | 5.57 | 5.33–5.82 |
| Tirzepatide | Constipation | 4.20 | 4.05–4.36 |

The pipeline recovered elevated reporting signals for known gastrointestinal adverse events, providing a sanity check before interpreting broader comparisons.

### Demographic Analysis

Created `sql/12_demographics.sql` and `scripts/visualize_demographics.py`.

Age analysis was restricted to reports satisfying:

```sql
age_cod = 'YR'
AND age IS NOT NULL
```

Among reports with valid age recorded in years:

| Age Group | Semaglutide | Tirzepatide |
|---|---:|---:|
| <18 | 0.6% | 0.1% |
| 18-34 | 6.5% | 7.7% |
| 35-49 | 18.2% | 21.6% |
| 50-64 | 34.9% | 36.6% |
| 65+ | 39.8% | 34.1% |

Demographic distributions are interpreted as characteristics of submitted FAERS reports, not estimates of age- or sex-specific adverse-event risk.

### Quarterly Reporting Analysis

Created `sql/13_quarterly_trend.sql` and `scripts/visualize_quarterly_trend.py`.

| Quarter | Semaglutide | Tirzepatide |
|---|---:|---:|
| 2025 Q3 | 13,553 | 16,411 |
| 2025 Q4 | 3,052 | 16,238 |
| 2026 Q1 | 3,312 | 18,390 |
| 2026 Q2 | 15,749 | 18,998 |

The quarterly totals sum to the final deduplicated Primary Suspect report counts.

Because quarter assignment reflects the file containing the retained latest case version, these values describe latest-version reporting patterns rather than event incidence or necessarily the quarter of initial reporting.

### Final Visualizations

Completed three portfolio figures:

```text
figures/glp1_ror_comparison.png
figures/quarterly_reporting_trend.png
figures/age_distribution.png
```

The figures cover individual adverse-event RORs and confidence intervals, quarterly reporting patterns, and age distributions.

The project was intentionally limited to three final figures rather than adding visualizations without a distinct analytical purpose.

### Documentation

Completed documentation covering:

- Research question and key findings
- FAERS data and table structure
- Multi-quarter processing and case-version deduplication
- Primary Suspect filtering
- Clinical outcome definitions
- ROR methodology and confidence intervals
- Descriptive analysis
- Interpretation limitations
- Reproduction instructions
- Project structure and technology stack
- One-page nontechnical summary

---

## Key Methodological Decisions

- Use `primaryid` for joins across FAERS tables.
- Use `caseid` and `caseversion` to identify and deduplicate updated cases.
- Use `COUNT(DISTINCT primaryid)` after one-to-many joins.
- Identify target drugs using standardized `prod_ai`.
- Restrict target-drug analyses to Primary Suspect (`PS`) reports.
- Define clinically relevant outcome groups before interpreting the final group-level comparison.
- Treat ROR as reporting disproportionality rather than clinical risk.
- Restrict age analysis to non-missing ages recorded in years.
- Explicitly document missing data, reporting bias, and the limitations of spontaneous-report data.

## Final Project Status

### Analysis

- [x] Four FAERS quarters loaded
- [x] Latest case versions retained
- [x] Semaglutide and tirzepatide Primary Suspect reports identified
- [x] High-frequency adverse events explored
- [x] Demographic distributions analyzed
- [x] Quarterly reporting patterns analyzed
- [x] Known GI signals validated
- [x] Four pre-specified clinical outcome groups analyzed
- [x] RORs and 95% confidence intervals calculated

### Deliverables

- [x] README
- [x] Three final figures
- [x] One-page nontechnical summary
- [x] Analysis decision log