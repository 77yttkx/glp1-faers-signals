SELECT
    pt,
    COUNT(DISTINCT primaryid) AS report_count

FROM read_csv(
    'data/raw/*/REAC*.txt',
    delim='$',
    header=true
)

WHERE LOWER(pt) LIKE '%gastropar%'

GROUP BY pt

ORDER BY report_count DESC;