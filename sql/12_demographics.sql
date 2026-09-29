WITH ranked_cases AS (
    SELECT
        primaryid,
        caseid,
        caseversion,
        sex,
        age,
        age_cod,

        RANK() OVER (
            PARTITION BY caseid
            ORDER BY caseversion DESC
        ) AS version_rank

    FROM read_csv(
        'data/raw/*/DEMO*.txt',
        delim='$',
        header=true
    )
),

latest_cases AS (
    SELECT
        primaryid,
        sex,
        age,
        age_cod
    FROM ranked_cases
    WHERE version_rank = 1
),
age_counts AS (
    SELECT
        d.prod_ai,
        CASE
            WHEN l.age < 18 THEN '<18'
            WHEN l.age BETWEEN 18 AND 34 THEN '18-34'
            WHEN l.age BETWEEN 35 AND 49 THEN '35-49'
            WHEN l.age BETWEEN 50 AND 64 THEN '50-64'
            WHEN l.age >= 65 THEN '65+'
        END AS age_group,
        COUNT(DISTINCT l.primaryid) AS report_count

    FROM latest_cases AS l

    JOIN read_csv(
        'data/raw/*/DRUG*.txt',
        delim='$',
        header=true
    ) AS d
        ON l.primaryid = d.primaryid

    WHERE d.role_cod = 'PS'
      AND d.prod_ai IN ('SEMAGLUTIDE', 'TIRZEPATIDE')
      AND l.age_cod = 'YR'
      AND l.age IS NOT NULL

    GROUP BY
        d.prod_ai,
        age_group
)
SELECT
    prod_ai,
    age_group,
    report_count,
    ROUND(
        100.0 * report_count
        / SUM(report_count) OVER (PARTITION BY prod_ai),
        1
    ) AS percentage
FROM age_counts
ORDER BY
    prod_ai,
    CASE age_group
        WHEN '<18' THEN 1
        WHEN '18-34' THEN 2
        WHEN '35-49' THEN 3
        WHEN '50-64' THEN 4
        WHEN '65+' THEN 5
    END;