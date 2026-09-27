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