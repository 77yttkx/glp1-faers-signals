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
reaction_a AS (
    SELECT
        r.pt,
        COUNT(DISTINCT r.primaryid) AS a

    FROM semaglutide_reports AS s

    JOIN read_csv(
        'data/raw/*/REAC*.txt',
        delim='$',
        header=true
    ) AS r
        ON s.primaryid = r.primaryid

    WHERE r.pt IS NOT NULL

    GROUP BY r.pt
),
semaglutide_total AS (
    SELECT COUNT(*) AS total
    FROM semaglutide_reports
),
all_reaction_counts AS (
    SELECT
        r.pt,
        COUNT(DISTINCT r.primaryid) AS all_reaction_reports

    FROM latest_cases AS l

    JOIN read_csv(
        'data/raw/*/REAC*.txt',
        delim='$',
        header=true
    ) AS r
        ON l.primaryid = r.primaryid

    WHERE r.pt IS NOT NULL

    GROUP BY r.pt
),
all_reports_total AS (
    SELECT COUNT(*) AS total
    FROM latest_cases
),
contingency_tables AS (
    SELECT
        r.pt,
        r.a,
        s.total - r.a AS b,
        ar.all_reaction_reports - r.a AS c,
        (t.total - s.total)
            - (ar.all_reaction_reports - r.a) AS d

    FROM reaction_a AS r
    CROSS JOIN semaglutide_total AS s
    CROSS JOIN all_reports_total AS t

    JOIN all_reaction_counts AS ar
        ON r.pt = ar.pt
)
SELECT
    pt,
    a,
    b,
    c,
    d,
    (a * d * 1.0) / (b * c) AS ror
FROM contingency_tables

WHERE a >= 10

ORDER BY ror DESC
