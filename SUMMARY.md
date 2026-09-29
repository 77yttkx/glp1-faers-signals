# Semaglutide vs. Tirzepatide: FDA Adverse-Event Reporting Signals

## Overview

Semaglutide and tirzepatide are widely used GLP-1–based medications. This project examined whether the two drugs show different patterns of adverse-event reporting in the U.S. Food and Drug Administration's Adverse Event Reporting System (FAERS).

The analysis used four quarters of FAERS data, from **2025 Q3 through 2026 Q2**. Because the same case can be updated multiple times, duplicate case versions were removed and only the latest available version was retained.

The final analysis included:

- **35,666 reports** listing semaglutide as the primary suspect drug
- **70,037 reports** listing tirzepatide as the primary suspect drug

## What Was Examined?

Four clinically relevant groups of adverse events were selected for comparison:

1. **Common gastrointestinal symptoms** — nausea, vomiting, diarrhoea, and constipation
2. **Pancreatitis**
3. **Gallbladder events** — including gallstones and cholecystitis
4. **Gastrointestinal motility and obstruction events** — including impaired gastric emptying, ileus, and intestinal obstruction

For each group, the analysis measured whether the events were reported disproportionately often with each drug compared with other reports in FAERS.

## Main Findings

Both semaglutide and tirzepatide showed elevated reporting signals for all four clinical outcome groups.

| Clinical Outcome | Semaglutide ROR | Tirzepatide ROR |
|---|---:|---:|
| Common GI symptoms | 3.45 | 3.12 |
| GI motility / obstruction | 18.65 | 2.84 |
| Gallbladder events | 5.82 | 3.72 |
| Pancreatitis | 5.17 | 3.46 |

The largest difference in reporting profiles appeared in **gastrointestinal motility and obstruction events**, where semaglutide had a substantially higher reporting odds ratio than tirzepatide.

The analysis also successfully recovered well-known gastrointestinal reporting signals such as nausea, vomiting, diarrhoea, and constipation. This served as a validation check for the data-processing and signal-detection pipeline.

## What Do These Results Mean?

A Reporting Odds Ratio (ROR) measures whether an adverse event appears disproportionately often in reports involving a particular drug.

For example, an ROR above 1 indicates that the event appears more frequently in the drug's FAERS reporting profile than in the comparison reports.

However, an ROR is **not the same as medical risk**.

The results do **not** mean that a patient taking semaglutide is 18.65 times more likely to experience a gastrointestinal motility problem, nor do they establish that either medication caused the reported events.

Instead, these results identify reporting patterns that may be useful for further pharmacovigilance investigation.

## Important Limitations

FAERS is a voluntary and spontaneous reporting system. It does not provide the total number of people taking each medication, and reports can be influenced by publicity, prescribing patterns, patient characteristics, regulatory attention, and reporting behavior.

Therefore, this analysis cannot determine:

- How often an adverse event occurs among all patients taking a drug
- Whether one drug is clinically safer than the other
- Whether a drug caused a reported adverse event
- Whether differences between the two drugs are explained by patient characteristics or prescribing patterns

The findings should be interpreted as **drug-safety reporting signals that can generate questions for further study**, rather than estimates of incidence, relative risk, or causality.

## Takeaway

Across four quarters of FDA FAERS data, semaglutide and tirzepatide showed overlapping but distinct adverse-event reporting profiles. Both showed clear gastrointestinal, pancreatitis, and gallbladder reporting signals, while the largest observed difference was in gastrointestinal motility and obstruction events.

The analysis demonstrates how large-scale post-market safety data can be cleaned, validated, and analyzed to identify signals worth investigating further.