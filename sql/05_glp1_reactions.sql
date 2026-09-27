WITH reaction_counts AS(
SELECT d.prod_ai, r.pt, COUNT(DISTINCT d.primaryid) AS report_count
FROM read_csv(
'data/raw/2026Q2/DRUG26Q2.txt',
delim='$',
header=true
)
AS d
JOIN read_csv(
'data/raw/2026Q2/REAC26Q2.txt',
delim='$',
header=true
)
AS r
    ON d.primaryid = r.primaryid

WHERE d.role_cod='PS'
AND d.prod_ai IN ('SEMAGLUTIDE','TIRZEPATIDE')

GROUP BY d.prod_ai, r.pt
),
ranked_reactions AS(
SELECT prod_ai, pt, report_count,

RANK() OVER(
    PARTITION BY prod_ai
    ORDER BY report_count DESC
)reaction_rank
FROM reaction_counts
)

SELECT *
FROM ranked_reactions
WHERE reaction_rank<=10
ORDER BY prod_ai,reaction_rank;
