SELECT
    pt,
    COUNT(DISTINCT primaryid) AS report_count
FROM read_csv(
    'data/raw/2026Q2/REAC26Q2.txt',
    delim='$',
    header=true
)
WHERE pt IS NOT NULL
GROUP BY pt
ORDER BY report_count DESC
LIMIT 10;