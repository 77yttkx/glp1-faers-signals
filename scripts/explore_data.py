import duckdb

with open("sql/13_quarterly_trend.sql", "r") as file:
    query = file.read()

result = duckdb.sql(query)

print(result)