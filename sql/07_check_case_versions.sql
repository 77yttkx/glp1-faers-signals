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
reaction_counts AS (

SELECT
d.prod_ai,
    r.pt,
    COUNT(DISTINCT d.primaryid) AS report_count

FROM latest_cases AS l

JOIN read_csv(
'data/raw/*/DRUG*.txt',
delim='$',
header=true
) AS d
    ON l.primaryid=d.primaryid

JOIN read_csv(
'data/raw/*/REAC*.txt',
delim='$',
header=true
) AS r
    ON l.primaryid=r.primaryid

WHERE d.role_cod='PS'
AND d.prod_ai IN ('SEMAGLUTIDE', 'TIRZEPATIDE')

GROUP BY
d.prod_ai,
r.pt),

ranked_reactions AS (

SELECT prod_ai, pt,report_count,

RANK() OVER(
PARTITION BY prod_ai
ORDER BY report_count DESC
) AS reaction_rank

FROM reaction_counts

)
SELECT *
FROM ranked_reactions
WHERE reaction_rank <= 10
ORDER BY prod_ai, reaction_rank
LIMIT 20;

