import duckdb
import numpy as np

def calculate_ci(result):
    result["se_log_ror"] = np.sqrt(
        1 / result["a"]
        + 1 / result["b"]
        + 1 / result["c"]
        + 1 / result["d"]
    )

    result["ci_lower"] = np.exp(
        np.log(result["ror"]) - 1.96 * result["se_log_ror"]
    )

    result["ci_upper"] = np.exp(
        np.log(result["ror"]) + 1.96 * result["se_log_ror"]
    )

    return result

with open("sql/10_semaglutide_ror.sql", "r") as file:
    sema_query = file.read()

with open("sql/11_tirzepatide_ror.sql", "r") as file:
    tirz_query = file.read()

sema_result = duckdb.sql(sema_query).df()
tirz_result = duckdb.sql(tirz_query).df()

sema_result = calculate_ci(sema_result)
tirz_result = calculate_ci(tirz_result)


sema_result = sema_result.rename(columns={
    "a": "sema_a",
    "ror": "sema_ror",
    "ci_lower": "sema_ci_lower",
    "ci_upper": "sema_ci_upper"
})

tirz_result = tirz_result.rename(columns={
    "a": "tirz_a",
    "ror": "tirz_ror",
    "ci_lower": "tirz_ci_lower",
    "ci_upper": "tirz_ci_upper"
})

comparison = sema_result.merge(
    tirz_result,
    on="pt"
)

comparison = comparison[
    [
        "pt",
        "sema_a",
        "sema_ror",
        "sema_ci_lower",
        "sema_ci_upper",
        "tirz_a",
        "tirz_ror",
        "tirz_ci_lower",
        "tirz_ci_upper"
    ]
]

comparison["ror_difference"] = (
    comparison["sema_ror"] - comparison["tirz_ror"]
)

comparison.to_csv(
    "data/glp1_ror_comparison.csv",
    index=False
)


known_gi = [
    "Nausea",
    "Vomiting",
    "Diarrhoea",
    "Constipation"
]

stable_comparison = comparison[
    (comparison["sema_a"] >= 100)
    & (comparison["tirz_a"] >= 100)
]

print(
    stable_comparison[
        [
            "pt",
            "sema_a",
            "sema_ror",
            "tirz_a",
            "tirz_ror",
            "ror_difference"
        ]
    ]
    .sort_values("ror_difference", ascending=True)
    .head(10)
)