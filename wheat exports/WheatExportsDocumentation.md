# US Wheat Exports — Activity Documentation

**Last modified:** April 28, 2026

---

## Overview

This activity analyzes US wheat export trends, with a particular focus on bilateral exports to Jamaica and the Dominican Republic. The ultimate output is a **position paper** that:

1. Reviews available export data
2. Summarizes the extant literature on US wheat exports (and Caribbean/regional trade dynamics)
3. Proposes concrete next steps to improve US wheat export performance

The analysis is intended to be evidence-based and policy-relevant.

---

## Research Questions

- What are the broad trends in US wheat exports over time, by volume and value?
- How do Jamaica and the Dominican Republic figure within that broader picture?
- What structural, competitive, and policy factors shape US wheat export performance?
- What actionable recommendations can be drawn from the data and literature?

---

## Methods

- **Data analysis:** R-based exploratory and descriptive analysis of bilateral trade data
- **Literature review:** Review of USDA reports, academic literature, and trade policy documents
- **Position paper:** Quarto document synthesizing data findings and literature into policy recommendations

---

## Folder Convention

```
wheat exports/
├── scripts/    # R code files (numbered by stage)
├── data/       # Raw and processed data
├── viz/        # Visualizations
├── tables/     # Output tables
└── models/     # (as needed)
```

---

## File Locations

| File | Location | Description |
|------|----------|-------------|
| `wheat exports.R` (migrated) | `scripts/01_explore_wheat_exports.R` | Initial exploration script — filters to Jamaica and Dominican Republic, plots export_usd over time |
| *(data TBD)* | `data/` | Source: `wheat_us_bilateral_clean` object in R session |

*Update this table as new files are created.*

---

## Pipeline Description

1. **Explore** — load and examine `wheat_us_bilateral_clean`; inspect coverage, key variables, missingness
2. **Analyze** — generate descriptive statistics and visualizations of global and bilateral trends
3. **Report** — produce Quarto position paper drawing on analysis and literature review

---

## Data Notes

- The session variable `wheat_us_bilateral_clean` appears to be the primary data source. Its provenance, schema, and coverage need to be confirmed at the start of the next session.
- Key variables identified so far: `country`, `year`, `export_usd`

---

## Script Naming Convention

| Prefix | Stage | Purpose |
|--------|-------|---------|
| `01_explore_*` | Exploration | Initial inspection, summary stats |
| `02_analyze_*` | Analysis | Produce findings, save to `tables/` or `viz/` |
| `03_report_*` | Reporting | Quarto document, final outputs |

---

## Broader Goals

- Develop a position paper suitable for policy or advocacy audiences
- Establish a reusable analytical framework that could extend to other US agricultural export commodities or country pairs
