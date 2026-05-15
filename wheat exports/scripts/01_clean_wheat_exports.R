# 01_clean_wheat_exports.R
#
# Loads raw USDA FAS data files and produces cleaned objects for analysis.
#
# Sources:
#   - wheat_us_exports_by_country.csv  : USDA FAS GATS bilateral exports, 2013-2024
#   - wheat_global_exports_psd.csv     : USDA FAS PSD global wheat exports, 1960-2025
#   - wheat_us_exports_psd.csv         : USDA FAS PSD US wheat exports, 1960-2025
#
# Outputs (saved to data/):
#   - wheat_us_bilateral_clean.rds
#   - wheat_global_psd_clean.rds
#   - wheat_us_psd_clean.rds

library(tidyverse)

data_dir <- "C:/Users/dkill/OneDrive/Documents/dkillian/wheat exports/data"

# ── 1. GATS bilateral: US wheat exports by destination country ─────────────────

bilateral_raw <- read_csv(
  file.path(data_dir, "wheat_us_exports_by_country.csv"),
  col_types = cols(
    year       = col_double(),
    cty_code   = col_double(),
    country    = col_character(),
    export_usd = col_double()
  )
)

# The raw file is a sparse panel: a country only appears in years when exports
# occurred. Absent rows represent zero exports, not missing data. We complete
# the panel so every country appears in every year, with export_usd = 0 where
# no exports were recorded.

wheat_us_bilateral_clean <- bilateral_raw |>
  complete(
    year,
    nesting(cty_code, country),
    fill = list(export_usd = 0)
  ) |>
  # Convert export_usd to millions for readability in analysis
  mutate(export_usd_millions = export_usd / 1e6) |>
  arrange(country, year)

saveRDS(
  wheat_us_bilateral_clean,
  file.path(data_dir, "wheat_us_bilateral_clean.rds")
)

cat("wheat_us_bilateral_clean:", nrow(wheat_us_bilateral_clean), "rows,",
    n_distinct(wheat_us_bilateral_clean$country), "countries,",
    "years", min(wheat_us_bilateral_clean$year), "-", max(wheat_us_bilateral_clean$year), "\n")


# ── 2. PSD: US wheat exports (aggregated, long time series) ───────────────────

wheat_us_psd_clean <- read_csv(
  file.path(data_dir, "wheat_us_exports_psd.csv"),
  col_types = cols(
    country        = col_character(),
    market_year    = col_double(),
    exports_1000mt = col_double()
  )
) |>
  # market_year is June-May; label is the start year
  rename(year = market_year) |>
  select(-country)   # single-country file; country column redundant

saveRDS(
  wheat_us_psd_clean,
  file.path(data_dir, "wheat_us_psd_clean.rds")
)

cat("wheat_us_psd_clean:", nrow(wheat_us_psd_clean), "rows,",
    "years", min(wheat_us_psd_clean$year), "-", max(wheat_us_psd_clean$year), "\n")


# ── 3. PSD: Global wheat exports by country ────────────────────────────────────

wheat_global_psd_clean <- read_csv(
  file.path(data_dir, "wheat_global_exports_psd.csv"),
  col_types = cols(
    country        = col_character(),
    market_year    = col_double(),
    exports_1000mt = col_double()
  )
) |>
  rename(year = market_year)

saveRDS(
  wheat_global_psd_clean,
  file.path(data_dir, "wheat_global_psd_clean.rds")
)

cat("wheat_global_psd_clean:", nrow(wheat_global_psd_clean), "rows,",
    n_distinct(wheat_global_psd_clean$country), "countries,",
    "years", min(wheat_global_psd_clean$year), "-", max(wheat_global_psd_clean$year), "\n")
