SELECT prod_ai,
COUNT(DISTINCT primaryid) AS report_count
FROM read_csv(
'data/raw/2026Q2/DRUG26Q2.txt',
delim='$',
header=true
)
WHERE prod_ai IS NOT NULL
AND role_cod= 'PS'
GROUP BY prod_ai
ORDER BY report_count DESC

LIMIT 10;