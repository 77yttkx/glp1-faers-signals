import duckdb
import matplotlib.pyplot as plt

with open("sql/13_quarterly_trend.sql", "r") as f:
    query = f.read()

df = duckdb.sql(query).df()

plot_df = df.pivot(
    index="quarter",
    columns="prod_ai",
    values="report_count"
)


plot_df.plot(
    kind="line",
    marker="o",
    figsize=(9, 5)
)

plt.title("Quarterly Primary-Suspect FAERS Reports")
plt.xlabel("Quarter")
plt.ylabel("Number of Reports")
plt.legend(["Semaglutide", "Tirzepatide"])

plt.tight_layout()

plt.savefig(
    "figures/quarterly_reporting_trend.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()