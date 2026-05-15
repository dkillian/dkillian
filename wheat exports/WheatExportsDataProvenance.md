# US Wheat Exports — Data Provenance & Cleaning Notes

**Last modified:** April 28, 2026

---

## Overview

Three CSV files reside in `data/`. All originate from the **USDA Foreign Agricultural Service (FAS)**, which is the authoritative source for US agricultural trade data. The two distinct FAS databases used are described below.

---

## Source 1: USDA FAS Production, Supply and Distribution (PSD) Online

**URL:** https://apps.fas.usda.gov/psdonline/app/index.html#/app/downloads

**Files from this source:**

| File | Description |
|------|-------------|
| `wheat_global_exports_psd.csv` | Annual wheat export volumes for all countries worldwide, 1960–2025 |
| `wheat_us_exports_psd.csv` | Annual wheat export volumes for the United States only, 1960–2025 |

**Variables:**

| Variable | Type | Description |
|----------|------|-------------|
| `country` | character | Exporting country name |
| `market_year` | numeric | Marketing year (wheat marketing year runs June–May; the year label reflects the start year) |
| `exports_1000mt` | numeric | Exports in thousand metric tons |

**Coverage:**
- Years: 1960–2025 (66 annual observations per country)
- Countries: 145 in the global file; United States only in the US file

**Notes on PSD data:**
- The PSD database is maintained and updated regularly by USDA FAS commodity analysts, incorporating official country data, attache reports, and modeled estimates for years where official data are incomplete.
- The `market_year` variable reflects the **wheat marketing year**, which begins June 1 and ends May 31 of the following calendar year. A `market_year` value of 2024 corresponds to June 2024–May 2025.
- Data for the most recent year(s) are subject to revision.
- Values of `0` are genuine zeros (no exports), not missing data.

---

## Source 2: USDA FAS Global Agricultural Trade System (GATS)

**URL:** https://apps.fas.usda.gov/gats/default.aspx

**File from this source:**

| File | Description |
|------|-------------|
| `wheat_us_exports_by_country.csv` | Annual US wheat export values by destination country, 2013–2024 |

**Variables:**

| Variable | Type | Description |
|----------|------|-------------|
| `year` | numeric | Calendar year |
| `cty_code` | numeric | USDA/Census Bureau country code |
| `country` | character | Destination country name |
| `export_usd` | numeric | US wheat exports to that country, in USD |

**Coverage:**
- Years: 2013–2024 (12 annual observations per country where exports occurred)
- Countries: 136 destination countries with non-zero exports in at least one year

**Notes on GATS data:**
- GATS draws from US Census Bureau export declaration data (Automated Export System / Electronic Export Information filings).
- Values represent the declared value of exports at time of export (free alongside ship, FAS basis).
- `export_usd` is in **current (nominal) US dollars**. Inflation adjustment will be needed for any real-terms trend analysis.
- `cty_code` follows USDA's country coding scheme, which is derived from the Census Bureau's Schedule B country codes.
- The dataset covers calendar years (not marketing years), which means it is on a different time basis than the PSD files above.

---

## Derived Object: `wheat_us_bilateral_clean`

The R script `scripts/01_explore_wheat_exports.R` references an object `wheat_us_bilateral_clean`. This is a cleaned version of `wheat_us_exports_by_country.csv`. The cleaning steps applied in the prior session have not yet been documented here.

**TODO:** Reconstruct and document the cleaning script as `scripts/01_clean_wheat_exports.R`, which should include:
- Loading raw CSVs
- Any renaming, filtering, or recoding steps applied
- How the clean object was produced and saved

---

## Key Alignment Notes

The three files use **different time bases** and **different units**:

| File | Time basis | Unit | Years |
|------|-----------|------|-------|
| `wheat_global_exports_psd.csv` | Marketing year (June–May) | 1,000 metric tons | 1960–2025 |
| `wheat_us_exports_psd.csv` | Marketing year (June–May) | 1,000 metric tons | 1960–2025 |
| `wheat_us_exports_by_country.csv` | Calendar year | USD (nominal) | 2013–2024 |

Joining or comparing across these files requires care:
- Volume (metric tons) and value (USD) measure different things; use in conjunction, not interchangeably.
- Marketing year vs. calendar year offsets can cause apparent discrepancies near year boundaries.
- Nominal USD values should be deflated before comparing trends across years.

---

## Suggested Next Steps

- [ ] Reconstruct and formalize the cleaning script that produces `wheat_us_bilateral_clean`
- [ ] Confirm whether `export_usd` in GATS data needs deflation for the analysis period
- [ ] Verify country name consistency across PSD and GATS files if joining is needed
