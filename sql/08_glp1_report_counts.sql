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
)
SELECT
    d.prod_ai,
    COUNT(DISTINCT d.primaryid) AS total_reports

FROM latest_cases AS l

JOIN read_csv(
    'data/raw/*/DRUG*.txt',
    delim='$',
    header=true
) AS d
    ON l.primaryid = d.primaryid

WHERE d.role_cod = 'PS'
  AND d.prod_ai IN ('SEMAGLUTIDE', 'TIRZEPATIDE')

GROUP BY d.prod_ai
ORDER BY total_reports DESC;