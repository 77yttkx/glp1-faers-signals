SELECT prod_ai, primaryid
FROM read_csv(
'data/raw/2026Q2/DRUG26Q2.txt',
delim='$',
header=true
)
WHERE prod_ai = 'SEMAGLUTIDE'
AND role_cod = 'PS'

LIMIT 10