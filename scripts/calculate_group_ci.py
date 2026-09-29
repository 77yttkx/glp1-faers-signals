import duckdb
import numpy as np

with open("sql/15_clinical_group_ror.sql", "r") as f:
    query = f.read()

result = duckdb.sql(query).df()

result["se_log_ror"] = np.sqrt(
    1 / result["a"]
    + 1 / result["b"]
    + 1 / result["c"]
    + 1 / result["d"]
)

result["ci_lower"] = np.exp(
    np.log(result["ror"])
    - 1.96 * result["se_log_ror"]
)

result["ci_upper"] = np.exp(
    np.log(result["ror"])
    + 1.96 * result["se_log_ror"]
)

print(
    result[
        [
            "prod_ai",
            "outcome_group",
            "a",
            "ror",
            "ci_lower",
            "ci_upper"
        ]
    ]
)

result.to_csv(
    "data/clinical_group_ror.csv",
    index=False
)