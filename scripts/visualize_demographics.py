import duckdb
import matplotlib.pyplot as plt

with open("sql/12_demographics.sql", "r") as f:
    query = f.read()

df = duckdb.sql(query).df()

plot_df = df.pivot(
    index="age_group",
    columns="prod_ai",
    values="percentage"
)
age_order = [
    "<18",
    "18-34",
    "35-49",
    "50-64",
    "65+"
]

plot_df = plot_df.reindex(age_order)
print(plot_df)

plot_df.plot(
    kind="bar",
    figsize=(9, 5)
)

plt.title( "Age Distribution of Primary-Suspect FAERS Reports\n"
    "Among Reports with Age Recorded in Years")
plt.xlabel("Age Group")
plt.ylabel("Percentage of Reports (%)")

plt.xticks(rotation=0)

plt.legend(
    ["Semaglutide", "Tirzepatide"]
)

plt.tight_layout()

plt.savefig(
    "figures/age_distribution.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()