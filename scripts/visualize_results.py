import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

df = pd.read_csv("data/glp1_ror_comparison.csv")

selected_reactions = [
    "Constipation",
    "Nausea",
    "Vomiting",
    "Diarrhoea",
    "Impaired gastric emptying",
    "Eructation",
    "Ileus",
    "Injection site pain"
]

plot_df = df[df["pt"].isin(selected_reactions)]

print(
    plot_df[
        ["pt", "sema_ror", "tirz_ror"]
    ]
)

sema_error = [
    plot_df["sema_ror"] - plot_df["sema_ci_lower"],
    plot_df["sema_ci_upper"] - plot_df["sema_ror"]
]

y = np.arange(len(plot_df))

sema_error = [
    plot_df["sema_ror"] - plot_df["sema_ci_lower"],
    plot_df["sema_ci_upper"] - plot_df["sema_ror"]
]

tirz_error = [
    plot_df["tirz_ror"] - plot_df["tirz_ci_lower"],
    plot_df["tirz_ci_upper"] - plot_df["tirz_ror"]
]

plt.errorbar(
    x=plot_df["sema_ror"],
    y=y + 0.1,
    xerr=sema_error,
    fmt="o",
    capsize=4,
    label="Semaglutide"
)

plt.errorbar(
    x=plot_df["tirz_ror"],
    y=y - 0.1,
    xerr=tirz_error,
    fmt="o",
    capsize=4,
    label="Tirzepatide"
)

plt.axvline(
    x=1,
    linestyle="--",
    linewidth=1
)

plt.yticks(y, plot_df["pt"])

plt.xlabel("Reporting Odds Ratio (ROR)")
plt.ylabel("Adverse Event")
plt.title("Adverse Event Reporting Signals: Semaglutide vs Tirzepatide")
plt.legend()

plt.tight_layout()

plt.savefig(
    "figures/glp1_ror_comparison.png",
    dpi=300,
    bbox_inches="tight"
)
plt.show()