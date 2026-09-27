WITH ranked_cases AS (

SELECT
primaryid,
caseid,
caseversion,

RANK() OVER(
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

SELECT primaryid
FROM ranked_cases
WHERE version_rank=1
),
semaglutide_reports AS (
    SELECT DISTINCT d.primaryid
    FROM latest_cases AS l
    JOIN read_csv(
        'data/raw/*/DRUG*.txt',
        delim='$',
        header=true
    ) AS d
        ON l.primaryid = d.primaryid
    WHERE d.role_cod = 'PS'
      AND d.prod_ai = 'SEMAGLUTIDE'
),
nausea_reports AS (
    SELECT DISTINCT r.primaryid
    FROM latest_cases AS l
    JOIN read_csv(
        'data/raw/*/REAC*.txt',
        delim='$',
        header=true
    ) AS r
        ON l.primaryid = r.primaryid
    WHERE r.pt = 'Nausea'
),
report_flags AS (
    SELECT
        l.primaryid,

        CASE
            WHEN l.primaryid IN (
                SELECT primaryid FROM semaglutide_reports
            ) THEN 1
            ELSE 0
        END AS is_semaglutide,

        CASE
            WHEN l.primaryid IN (
                SELECT primaryid FROM nausea_reports
            ) THEN 1
            ELSE 0
        END AS has_nausea

    FROM latest_cases AS l
),
contingency_table AS (
    SELECT
        SUM(CASE WHEN is_semaglutide = 1 AND has_nausea = 1 THEN 1 ELSE 0 END) AS a,
        SUM(CASE WHEN is_semaglutide = 1 AND has_nausea = 0 THEN 1 ELSE 0 END) AS b,
        SUM(CASE WHEN is_semaglutide = 0 AND has_nausea = 1 THEN 1 ELSE 0 END) AS c,
        SUM(CASE WHEN is_semaglutide = 0 AND has_nausea = 0 THEN 1 ELSE 0 END) AS d
    FROM report_flags
)
SELECT
    a,
    b,
    c,
    d,
    (a * d * 1.0) / (b * c) AS ror
FROM contingency_table