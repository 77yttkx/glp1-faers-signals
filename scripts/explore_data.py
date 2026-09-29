import duckdb

with open("sql/15_clinical_group_ror.sql", "r") as file:
    query = file.read()

result = duckdb.sql(query)

print(result)