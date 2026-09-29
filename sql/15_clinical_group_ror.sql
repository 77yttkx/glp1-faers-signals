WITH ranked_cases AS (
    SELECT
        primaryid,
        caseid,
        caseversion,

        RANK() OVER (
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
    SELECT
        primaryid
    FROM ranked_cases
    WHERE version_rank = 1
),

grouped_reactions AS (
    SELECT
        primaryid,

        CASE
            WHEN pt IN (
                'Nausea',
                'Vomiting',
                'Diarrhoea',
                'Constipation'
            )
            THEN 'Common GI symptoms'

            WHEN pt IN (
                'Pancreatitis',
                'Pancreatitis acute'
            )
            THEN 'Pancreatitis'

            WHEN pt IN (
                'Cholelithiasis',
                'Cholecystitis',
                'Cholecystitis acute'
            )
            THEN 'Gallbladder events'

            WHEN pt IN (
                'Impaired gastric emptying',
                'Ileus',
                'Intestinal obstruction'
            )
            THEN 'GI motility / obstruction'

        END AS outcome_group

    FROM read_csv(
        'data/raw/*/REAC*.txt',
        delim='$',
        header=true
    )
),

all_group_counts AS (
    SELECT
        g.outcome_group,
        COUNT(DISTINCT l.primaryid) AS all_group_reports

    FROM latest_cases AS l

    JOIN grouped_reactions AS g
        ON l.primaryid = g.primaryid

    WHERE g.outcome_group IS NOT NULL

    GROUP BY g.outcome_group
),
drug_totals AS (
    SELECT
        d.prod_ai,
        COUNT(DISTINCT l.primaryid) AS drug_total

    FROM latest_cases AS l

    JOIN read_csv(
        'data/raw/*/DRUG*.txt',
        delim='$',
        header=true
    ) AS d
        ON l.primaryid = d.primaryid

    WHERE d.role_cod = 'PS'
      AND d.prod_ai IN (
          'SEMAGLUTIDE',
          'TIRZEPATIDE'
      )

    GROUP BY d.prod_ai
),

all_reports_total AS (
    SELECT
        COUNT(DISTINCT primaryid) AS total_reports
    FROM latest_cases
),
drug_group_counts AS (
    SELECT
        d.prod_ai,
        g.outcome_group,
        COUNT(DISTINCT l.primaryid) AS a

    FROM latest_cases AS l

    JOIN read_csv(
        'data/raw/*/DRUG*.txt',
        delim='$',
        header=true
    ) AS d
        ON l.primaryid = d.primaryid

    JOIN grouped_reactions AS g
        ON l.primaryid = g.primaryid

    WHERE d.role_cod = 'PS'
      AND d.prod_ai IN (
          'SEMAGLUTIDE',
          'TIRZEPATIDE'
      )
      AND g.outcome_group IS NOT NULL

    GROUP BY
        d.prod_ai,
        g.outcome_group
),
contingency_tables AS (
    SELECT
        dg.prod_ai,
        dg.outcome_group,

        dg.a AS a,

        dt.drug_total - dg.a AS b,

        ag.all_group_reports - dg.a AS c,

        art.total_reports
            - dg.a
            - (dt.drug_total - dg.a)
            - (ag.all_group_reports - dg.a) AS d

    FROM drug_group_counts AS dg

    JOIN drug_totals AS dt
        ON dg.prod_ai = dt.prod_ai

    JOIN all_group_counts AS ag
        ON dg.outcome_group = ag.outcome_group

    CROSS JOIN all_reports_total AS art
)

SELECT
    prod_ai,
    outcome_group,
    a,
    b,
    c,
    d,

    (a * d * 1.0) / (b * c) AS ror

FROM contingency_tables

ORDER BY
    outcome_group,
    prod_ai;