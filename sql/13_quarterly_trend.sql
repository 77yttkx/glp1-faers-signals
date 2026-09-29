WITH ranked_cases AS (
    SELECT
        primaryid,
        caseid,
        caseversion,

        regexp_extract(
            filename,
            '20[0-9]{2}Q[1-4]'
        ) AS quarter,

        RANK() OVER (
            PARTITION BY caseid
            ORDER BY caseversion DESC
        ) AS version_rank

    FROM read_csv(
        'data/raw/*/DEMO*.txt',
        delim='$',
        header=true,
        filename=true
    )
),

latest_cases AS (
    SELECT
        primaryid,
        quarter
    FROM ranked_cases
    WHERE version_rank = 1
)

SELECT
    l.quarter,
    d.prod_ai,
    COUNT(DISTINCT l.primaryid) AS report_count

FROM latest_cases AS l

JOIN read_csv(
    'data/raw/*/DRUG*.txt',
    delim='$',
    header=true
) AS d
    ON l.primaryid = d.primaryid

WHERE d.role_cod = 'PS'
  AND d.prod_ai IN ('SEMAGLUTIDE', 'TIRZEPATIDE')

GROUP BY
    l.quarter,
    d.prod_ai

ORDER BY
    l.quarter,
    d.prod_ai;
