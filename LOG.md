# Project Log

## 2026-09-23

### Tried
- Created the `glp1-faers-signals` project structure with folders for raw data, SQL, and notebooks.
- Set up a Python virtual environment (`.venv`) in PyCharm.
- Installed and tested DuckDB.
- Loaded the 2026 Q2 FAERS `DEMO26Q2.txt` file with DuckDB.
- Verified that the FAERS ASCII file uses `$` as the delimiter and that the header row is read correctly.
- Counted the total number of rows and compared total rows, unique `primaryid`, and unique `caseid`.
- Queried duplicate `caseid` values and inspected one case with multiple versions.

### Problems
- The project initially contained both the extracted FDA folder and the cleaned `data/raw/2026Q2/` folder, which could create confusion about file paths.
- The README first opened in Markdown preview mode in PyCharm, so it was not directly editable.

### Findings
- `DEMO26Q2.txt` contains 422,459 rows.
- All 422,459 `primaryid` values are unique.
- There are 422,458 unique `caseid` values, meaning one case appears twice in this quarter.
- The duplicated case had:
  - `caseid = 26012757`
  - `caseversion = 6` with `primaryid = 260127576`
  - `caseversion = 7` with `primaryid = 260127577`

### Decisions
- Raw FAERS data will stay inside the local `data/` folder and will not be committed to GitHub.
- DuckDB will be used to query FAERS files directly with SQL.
- `caseid` will be treated as the identifier for the underlying case, while `primaryid` identifies a specific report version.
- During deduplication, only the row with the highest `caseversion` for each `caseid` will be kept.
- For now, analysis will stay limited to one quarter before combining multiple quarters.

## 2026-09-26 — Week 1: Exploring FAERS Data and Organizing SQL Workflow

### What I did

- Loaded and explored the 2026 Q2 FAERS ASCII files using DuckDB.
- Inspected the structure and columns of the DEMO, DRUG, and REAC datasets using `DESCRIBE` and sample rows.
- Learned the roles of important FAERS fields:
  - `primaryid`: unique identifier for a specific report/version.
  - `caseid`: identifier for the underlying adverse-event case.
  - `caseversion`: version number of a case.
  - `prod_ai`: active ingredient of the reported drug.
  - `role_cod`: role of the drug in the report; `PS` means Primary Suspect.
  - `pt`: Preferred Term describing the reported adverse event.
- Counted unique primary-suspect reports by active ingredient using:
  - `COUNT(DISTINCT primaryid)`
  - `WHERE`
  - `GROUP BY`
  - `ORDER BY`
- Confirmed that tirzepatide and semaglutide appear among the most frequently reported primary-suspect active ingredients in 2026 Q2.
- Counted the most frequently reported adverse-event terms in the REAC table.
- Reorganized the project so reusable SQL queries are stored separately from Python:
  - `sql/01_top_drugs.sql`
  - `sql/02_top_reactions.sql`
  - `scripts/explore_data.py`
- Used Python to read a `.sql` file and execute the query through DuckDB.

### What broke / what I debugged

- Initially counted rows with `COUNT(*)`, then realized that one FAERS report can contain multiple drug rows. Changed the query to `COUNT(DISTINCT primaryid)` to count reports rather than rows.
- Initially included records where `prod_ai` was NULL. Added `WHERE prod_ai IS NOT NULL`.
- Added `role_cod = 'PS'` so the drug analysis focuses on primary-suspect drugs instead of concomitant or secondary-suspect drugs.
- Encountered SQL syntax errors from putting conditions in the wrong clause and using `LIMIT=10` instead of `LIMIT 10`.
- After moving Python files into `scripts/` and SQL queries into `sql/`, relative file paths stopped working.
- Learned that relative paths are resolved from Python's current working directory, not automatically from the location of the Python script.
- Fixed the PyCharm run configuration so the working directory points to the project root:
  `/Users/shuyuqi/Documents/glp1-faers-signals`

### Decisions and why

- Use `prod_ai` rather than `drugname` as the main drug identifier because active ingredients are more standardized than reported product names.
- Restrict the main drug analysis to `role_cod = 'PS'` because the project focuses on drugs identified as the primary suspect in adverse-event reports.
- Use `COUNT(DISTINCT primaryid)` when counting reports to avoid overcounting reports that contain multiple rows.
- Keep SQL queries in `.sql` files and use Python mainly to execute queries and later perform statistical analysis/visualization.
- Keep the project working directory at the repository root so paths such as `sql/...` and `data/...` remain consistent.

### What I learned

The main lesson today was that understanding the unit of observation matters before aggregating data. A row in the DRUG table is not necessarily one adverse-event report, so `COUNT(*)` and `COUNT(DISTINCT primaryid)` answer different questions.

I also learned that project structure affects code execution: moving files into folders can break relative paths even when the files still exist. Understanding the working directory makes the project easier to organize and debug.

### Next step

Finish Week 1 by making sure I can independently answer three basic questions for one FAERS quarter:

1. How many reports are in the quarter?
2. What are the most frequently reported primary-suspect active ingredients?
3. What are the most frequently reported adverse-event terms?

Then move to Week 2: join DRUG and REAC using `primaryid` and isolate reports involving semaglutide or tirzepatide.

## 2026-09-26 — Multi-Quarter Loading & FAERS Case Deduplication

### What I did
- Expanded the FAERS analysis from one quarter (2026 Q2) to four quarters:
  - 2025 Q3
  - 2025 Q4
  - 2026 Q1
  - 2026 Q2
- Used DuckDB wildcard paths (`data/raw/*/DRUG*.txt`) to read multiple quarterly files at once.
- Used `filename=true` to verify that all four DRUG and REAC quarterly files were loaded.
- Joined multi-quarter DRUG and REAC data using `primaryid`.
- Generated reaction counts for semaglutide and tirzepatide using:
  - `role_cod = 'PS'`
  - `prod_ai`
  - `COUNT(DISTINCT primaryid)`
- Used `RANK() OVER (PARTITION BY prod_ai ORDER BY report_count DESC)` to rank reactions separately for each drug.
- Investigated duplicate FAERS case versions using DEMO data.
- Confirmed that one `caseid` can have multiple `caseversion` values and different `primaryid` values.
- Built a deduplication workflow using `RANK()` to keep only the latest `caseversion` for each `caseid`.
- Joined the deduplicated `primaryid` list back to DRUG and REAC.
- Recalculated adverse-event counts after deduplication.

### Key result
Deduplication reduced several reaction counts, confirming that using all quarterly records without case-version filtering can double-count updated cases.

Examples:

| Drug | Reaction | Before Dedup | After Dedup |
|---|---|---:|---:|
| Semaglutide | Nausea | 4,936 | 4,812 |
| Semaglutide | Vomiting | 3,088 | 2,993 |
| Semaglutide | Diarrhoea | 2,546 | 2,459 |
| Tirzepatide | Nausea | 8,642 | 8,218 |
| Tirzepatide | Diarrhoea | 5,452 | 5,177 |
| Tirzepatide | Vomiting | 4,708 | 4,316 |

### SQL concepts practiced
- Multi-file wildcard reads
- `filename=true`
- `HAVING`
- `MAX()`
- Common Table Expressions (`WITH ... AS`)
- Multiple CTEs
- `RANK() OVER (...)`
- `PARTITION BY`
- Multi-table `JOIN`
- `COUNT(DISTINCT ...)`
- `GROUP BY`
- Deduplication by latest record

### Problems / debugging
- Used `headers=true` instead of `header=true` in `read_csv()`.
- Had extra/misplaced parentheses when chaining multiple CTEs.
- Initially tried to define a CTE inside `GROUP BY`.
- Learned that CTEs must be defined in the `WITH` section before the final query.
- Learned that `RANK()` uses `RANK() OVER (...) AS name`, not `RANK() AS (...)`.

### Decisions and why
- Use four consecutive quarters instead of one quarter to create a more meaningful analysis window.
- Use `prod_ai` instead of free-text `drugname` to identify semaglutide and tirzepatide consistently.
- Restrict drugs to `role_cod = 'PS'` (Primary Suspect).
- Deduplicate FAERS cases before final analysis by keeping the highest `caseversion` for each `caseid`.
- Continue counting unique `primaryid` values rather than raw rows because one report can contain multiple drug/reaction rows.

### Main lesson
The unit of analysis matters. A FAERS row is not necessarily a unique adverse-event case. The same case can be updated across quarters, so multi-quarter analysis requires case-version deduplication before interpreting report counts.

### Next step
Calculate the total number of deduplicated Primary Suspect reports for semaglutide and tirzepatide separately. This will provide the denominator needed to understand why raw reaction counts alone cannot be interpreted as comparative risk and will prepare the data for later disproportionality analysis (ROR).

## 2026-09-29 — Final Analysis and Project Deliverables

### Clinical Outcome Analysis

Defined four pre-specified clinical outcome groups for the primary semaglutide vs. tirzepatide comparison:

1. **Common GI symptoms**
   - Nausea
   - Vomiting
   - Diarrhoea
   - Constipation

2. **Pancreatitis**
   - Pancreatitis
   - Pancreatitis acute

3. **Gallbladder events**
   - Cholelithiasis
   - Cholecystitis
   - Cholecystitis acute

4. **GI motility / obstruction**
   - Impaired gastric emptying
   - Ileus
   - Intestinal obstruction

Initially considered `Gastroparesis`, but the general Preferred Term was not present in the four-quarter REAC data. Only `Diabetic gastroparesis` and `Gastroparesis postoperative` were found, so these were not substituted into the predefined group.

Created:

```text
sql/14_check_clinical_outcomes.sql
sql/15_clinical_group_ror.sql
scripts/calculate_group_ci.py
```

### Clinical Group ROR Results

Constructed 2 × 2 contingency tables using deduplicated latest-version FAERS cases and Primary Suspect (`PS`) reports.

Final results:

| Outcome Group | Semaglutide ROR (95% CI) | Tirzepatide ROR (95% CI) |
|---|---:|---:|
| Common GI symptoms | 3.45 (3.36–3.54) | 3.12 (3.06–3.18) |
| GI motility / obstruction | 18.65 (17.80–19.54) | 2.84 (2.67–3.03) |
| Gallbladder events | 5.82 (5.27–6.42) | 3.72 (3.40–4.07) |
| Pancreatitis | 5.17 (4.74–5.64) | 3.46 (3.20–3.74) |

Saved final group-level results to:

```text
data/clinical_group_ror.csv
```

Important interpretation decision:

- ROR is treated as a measure of **reporting disproportionality**.
- ROR is not interpreted as incidence, relative risk, or causality.
- Numerical differences between the two drug-specific RORs are treated as differences in reporting profiles, not direct head-to-head risk estimates.

### Known-Signal Validation

The individual Preferred Term pipeline successfully recovered known gastrointestinal reporting signals.

Selected results:

| Drug | Reaction | ROR | 95% CI |
|---|---|---:|---:|
| Semaglutide | Nausea | 3.96 | 3.84–4.09 |
| Tirzepatide | Nausea | 3.51 | 3.43–3.60 |
| Semaglutide | Constipation | 5.57 | 5.33–5.82 |
| Tirzepatide | Constipation | 4.20 | 4.05–4.36 |

This was used as a sanity check for the FAERS processing and disproportionality-analysis pipeline.

### Demographic Analysis

Created:

```text
sql/12_demographics.sql
scripts/visualize_demographics.py
```

Sex distributions were calculated after deduplication and Primary Suspect filtering.

Age analysis was restricted to:

```sql
age_cod = 'YR'
AND age IS NOT NULL
```

Age groups:

```text
<18
18-34
35-49
50-64
65+
```

Among reports with valid age recorded in years:

| Age Group | Semaglutide | Tirzepatide |
|---|---:|---:|
| <18 | 0.6% | 0.1% |
| 18-34 | 6.5% | 7.7% |
| 35-49 | 18.2% | 21.6% |
| 50-64 | 34.9% | 36.6% |
| 65+ | 39.8% | 34.1% |

Decision: demographic distributions are interpreted as characteristics of submitted FAERS reports, not estimates of age- or sex-specific adverse-event risk.

### Quarterly Trend Analysis

Created:

```text
sql/13_quarterly_trend.sql
scripts/visualize_quarterly_trend.py
```

Quarterly Primary Suspect report counts after latest-case-version deduplication:

| Quarter | Semaglutide | Tirzepatide |
|---|---:|---:|
| 2025 Q3 | 13,553 | 16,411 |
| 2025 Q4 | 3,052 | 16,238 |
| 2026 Q1 | 3,312 | 18,390 |
| 2026 Q2 | 15,749 | 18,998 |

Sanity checks:

```text
Semaglutide total = 35,666
Tirzepatide total = 70,037
```

These exactly matched the previously calculated deduplicated Primary Suspect report totals.

Important limitation: quarter is based on the file containing the retained latest case version. It should therefore be interpreted as a latest-version reporting pattern, not an adverse-event incidence trend.

### Final Visualizations

Completed three final figures:

```text
figures/glp1_ror_comparison.png
figures/quarterly_reporting_trend.png
figures/age_distribution.png
```

Figure 1:
- Individual adverse-event ROR comparison
- 95% confidence intervals
- Log-scaled ROR axis
- ROR = 1 reference line

Figure 2:
- Quarterly Primary Suspect FAERS report counts
- Semaglutide vs. tirzepatide

Figure 3:
- Age-group distribution
- Percentages rather than raw counts
- Restricted to reports with age recorded in years

Decision: stop at three figures rather than adding additional visualizations without a clear analytical purpose.

### Documentation

Expanded `README.md` to include:

- Research question
- Key findings
- Visualizations
- FAERS data structure
- Multi-quarter processing
- Case-version deduplication
- Primary Suspect filtering
- Clinical outcome definitions
- ROR methodology
- 95% confidence intervals
- Descriptive analysis
- Limitations
- Project structure
- Reproduction instructions
- Tech stack

Created:

```text
SUMMARY.md
```

The summary provides a one-page nontechnical explanation of the research question, findings, interpretation, and limitations.

### Final Project Status

Analysis:

- [x] Four FAERS quarters loaded
- [x] Latest case versions retained
- [x] Semaglutide and tirzepatide Primary Suspect reports identified
- [x] High-frequency adverse events explored
- [x] Age and sex distributions analyzed
- [x] Quarterly reporting patterns analyzed
- [x] Known GI signals validated
- [x] Four pre-specified clinical outcome groups analyzed
- [x] ROR calculated
- [x] 95% confidence intervals calculated

Deliverables:

- [x] README
- [x] Three final figures
- [x] One-page nontechnical summary
- [x] Analysis log

### Key Lessons

- Multi-quarter FAERS analysis requires case-version deduplication to avoid counting updated cases multiple times.
- `primaryid` is used to join FAERS tables, while `caseid` and `caseversion` are needed to identify updated versions of the same case.
- `COUNT(DISTINCT primaryid)` prevents multiple reactions or drug rows within a report from inflating report counts.
- ROR measures reporting disproportionality rather than clinical risk.
- Clinical outcomes should be defined before interpreting the final signal results rather than selected only because they have high RORs.
- Data-quality issues such as missing demographics and inconsistent or highly specific MedDRA terms must be handled explicitly and documented.