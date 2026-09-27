SELECT primaryid, pt
FROM read_csv(
'data/raw/2026Q2/REAC26Q2.txt',
delim='$',
header=true
)
WHERE primaryid = 165743083


