import duckdb

with open("sql/11_tirzepatide_ror.sql", "r") as file:
    query = file.read()

result = duckdb.sql(query)

print(result)