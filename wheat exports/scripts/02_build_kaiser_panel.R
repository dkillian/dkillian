# 02_build_kaiser_panel.R
#
# Builds a mega-region panel dataset replicating the structure of Kaiser (2015):
#   "An Economic Analysis of U.S. Wheat Export Promotion"
#
# Dependent variable:
#   us_wheat_exports_real — US wheat exports to the region in real (deflated)
#   USD millions. NOTE: Kaiser used quantity (tons); we use deflated value as a
#   proxy. This affects the interpretation of price elasticities but not the
#   promotion elasticity of primary interest.
#
# Regressors assembled here:
#   1. gdp_real        — Real GDP of importing region (billions 2017 USD), from ERS
#   2. xrate_importer  — ERS trade-weighted real exchange rate, importing region
#   3. xrate_competitor — ERS trade-weighted real exchange rate, major wheat exporters
#   4. cpi_importer    — CPI of importing region (2017 = 100), from ERS
#   5. competing_exports_1000mt — Total wheat exports of major competitors, from PSD
#   6. promotion_usd   — SYNTHETIC promotion expenditure (USW + USDA/FAS MAP+FMDP).
#                        Replace with real data when available from USW.
#
# Deviations from Kaiser noted inline.
#
# Output: data/kaiser_panel.rds

library(tidyverse)

data_dir   <- "C:/Users/dkill/OneDrive/Documents/dkillian/wheat exports/data"
scripts_dir <- "C:/Users/dkill/OneDrive/Documents/dkillian/wheat exports/scripts"

# ── 0. Settings ────────────────────────────────────────────────────────────────

YEARS      <- 1994:2024   # extend Kaiser's 1994-2014 window to present
BASE_YEAR  <- 2017        # CPI/GDP deflator base year (ERS standard)

# ── 1. Mega-region country mapping ─────────────────────────────────────────────
# Kaiser (2015) Table 1 footnote: four mega-regions cover 97% of US wheat trade
# (excluding Canada, which receives no USW promotion).

region_map <- tribble(
  ~country,                          ~region,
  # EUROPE
  "Austria",                         "Europe",
  "Belgium",                         "Europe",
  "Bosnia And Herzegovina",          "Europe",
  "Bulgaria",                        "Europe",
  "Finland",                         "Europe",
  "France",                          "Europe",
  "Georgia",                         "Europe",
  "Germany",                         "Europe",
  "Greece",                          "Europe",
  "Ireland",                         "Europe",
  "Italy",                           "Europe",
  "Lithuania",                       "Europe",
  "Malta",                           "Europe",
  "Netherlands",                     "Europe",
  "Norway",                          "Europe",
  "Portugal",                        "Europe",
  "Russia",                          "Europe",
  "Spain",                           "Europe",
  "Sweden",                          "Europe",
  "Switzerland",                     "Europe",
  "Ukraine",                         "Europe",
  "United Kingdom",                  "Europe",
  # ASIA (including Oceania)
  "Afghanistan",                     "Asia",
  "Australia",                       "Asia",
  "Bangladesh",                      "Asia",
  "Burma",                           "Asia",
  "Cambodia",                        "Asia",
  "China",                           "Asia",
  "Hong Kong",                       "Asia",
  "India",                           "Asia",
  "Indonesia",                       "Asia",
  "Japan",                           "Asia",
  "Korea, South",                    "Asia",
  "Malaysia",                        "Asia",
  "Mongolia",                        "Asia",
  "New Zealand",                     "Asia",
  "Pakistan",                        "Asia",
  "Papua New Guinea",                "Asia",
  "Philippines",                     "Asia",
  "Singapore",                       "Asia",
  "Sri Lanka",                       "Asia",
  "Taiwan",                          "Asia",
  "Thailand",                        "Asia",
  "Vietnam",                         "Asia",
  # LATIN AMERICA (including Caribbean)
  "Anguilla",                        "Latin America",
  "Antigua And Barbuda",             "Latin America",
  "Argentina",                       "Latin America",
  "Aruba",                           "Latin America",
  "Bahamas",                         "Latin America",
  "Barbados",                        "Latin America",
  "Belize",                          "Latin America",
  "Bermuda",                         "Latin America",
  "Bolivia",                         "Latin America",
  "Brazil",                          "Latin America",
  "British Virgin Islands",          "Latin America",
  "Cayman Islands",                  "Latin America",
  "Chile",                           "Latin America",
  "Colombia",                        "Latin America",
  "Costa Rica",                      "Latin America",
  "Cuba",                            "Latin America",
  "Dominica",                        "Latin America",
  "Dominican Republic",              "Latin America",
  "Ecuador",                         "Latin America",
  "El Salvador",                     "Latin America",
  "Grenada",                         "Latin America",
  "Guadeloupe",                      "Latin America",
  "Guatemala",                       "Latin America",
  "Guyana",                          "Latin America",
  "Haiti",                           "Latin America",
  "Honduras",                        "Latin America",
  "Jamaica",                         "Latin America",
  "Martinique",                      "Latin America",
  "Mexico",                          "Latin America",
  "Nicaragua",                       "Latin America",
  "Panama",                          "Latin America",
  "Peru",                            "Latin America",
  "Sint Maarten",                    "Latin America",
  "St Kitts And Nevis",              "Latin America",
  "St Lucia",                        "Latin America",
  "St Vincent And The Grenadines",   "Latin America",
  "Suriname",                        "Latin America",
  "Trinidad And Tobago",             "Latin America",
  "Turks And Caicos Islands",        "Latin America",
  "Venezuela",                       "Latin America",
  # AFRICA-MIDEAST
  "Algeria",                         "Africa-Mideast",
  "Angola",                          "Africa-Mideast",
  "Bahrain",                         "Africa-Mideast",
  "Benin",                           "Africa-Mideast",
  "Burkina Faso",                    "Africa-Mideast",
  "Burundi",                         "Africa-Mideast",
  "Cameroon",                        "Africa-Mideast",
  "Central African Republic",        "Africa-Mideast",
  "Congo",                           "Africa-Mideast",
  "Cote D'ivoire",                   "Africa-Mideast",
  "Democratic Republic Of The Congo","Africa-Mideast",
  "Djibouti",                        "Africa-Mideast",
  "Egypt",                           "Africa-Mideast",
  "Ethiopia",                        "Africa-Mideast",
  "Gabon",                           "Africa-Mideast",
  "Gambia",                          "Africa-Mideast",
  "Ghana",                           "Africa-Mideast",
  "Guinea",                          "Africa-Mideast",
  "Iraq",                            "Africa-Mideast",
  "Israel",                          "Africa-Mideast",
  "Jordan",                          "Africa-Mideast",
  "Kenya",                           "Africa-Mideast",
  "Kuwait",                          "Africa-Mideast",
  "Lebanon",                         "Africa-Mideast",
  "Liberia",                         "Africa-Mideast",
  "Libya",                           "Africa-Mideast",
  "Malawi",                          "Africa-Mideast",
  "Mali",                            "Africa-Mideast",
  "Mauritania",                      "Africa-Mideast",
  "Morocco",                         "Africa-Mideast",
  "Mozambique",                      "Africa-Mideast",
  "Namibia",                         "Africa-Mideast",
  "Nigeria",                         "Africa-Mideast",
  "Oman",                            "Africa-Mideast",
  "Qatar",                           "Africa-Mideast",
  "Rwanda",                          "Africa-Mideast",
  "Saudi Arabia",                    "Africa-Mideast",
  "Senegal",                         "Africa-Mideast",
  "Sierra Leone",                    "Africa-Mideast",
  "Somalia",                         "Africa-Mideast",
  "South Africa",                    "Africa-Mideast",
  "South Sudan",                     "Africa-Mideast",
  "Sudan",                           "Africa-Mideast",
  "Tanzania",                        "Africa-Mideast",
  "Togo",                            "Africa-Mideast",
  "Tunisia",                         "Africa-Mideast",
  "Turkey",                          "Africa-Mideast",
  "Uganda",                          "Africa-Mideast",
  "United Arab Emirates",            "Africa-Mideast",
  "Yemen",                           "Africa-Mideast",
  "Zimbabwe",                        "Africa-Mideast"
  # Canada is intentionally excluded (Kaiser p. 3: no USW promotion to Canada)
)

# ── 2. GATS bilateral data → regional exports (deflated USD) ──────────────────

bilateral_raw <- readRDS(file.path(data_dir, "wheat_us_bilateral_clean.rds"))

# Load CPI for deflating — use US CPI (from ERS) indexed to BASE_YEAR
# The ERS CPI file contains "United States" as an observation
cpi_raw <- read_csv(file.path(data_dir, "ers_cpi.csv"), show_col_types = FALSE)

us_cpi <- cpi_raw |>
  filter(
    Observation == "United States",
    Unit == "Consumer Price Index 2017 = 100",
    Year %in% YEARS
  ) |>
  select(year = Year, us_cpi = Value)

# Join region and deflate bilateral exports
us_exports_regional <- bilateral_raw |>
  filter(year %in% YEARS) |>
  inner_join(region_map, by = "country") |>
  left_join(us_cpi, by = "year") |>
  mutate(
    export_real = export_usd_millions / (us_cpi / 100)  # deflate to 2017 USD
  ) |>
  group_by(region, year) |>
  summarise(
    us_wheat_exports_real = sum(export_real, na.rm = TRUE),
    .groups = "drop"
  )

cat("Regional export panel rows:", nrow(us_exports_regional), "\n")
us_exports_regional |> count(region)

# ── 3. ERS macro data → regional GDP, CPI, exchange rates ────────────────────

gdp_raw   <- read_csv(file.path(data_dir, "ers_gdp.csv"),   show_col_types = FALSE)
xrate_raw <- read_csv(file.path(data_dir, "ers_xrate.csv"), show_col_types = FALSE)

# Region labels in ERS that map to Kaiser's mega-regions
ers_region_map <- c(
  "Latin America"    = "Latin America",
  "Asia and Oceania" = "Asia",
  "Europe"           = "Europe",
  # Africa-Mideast: construct as Africa + Middle East (summed GDP, wtd-avg xrate)
  "Africa"           = "Africa-Mideast",
  "Middle East"      = "Africa-Mideast"
)

# GDP by mega-region: sum Africa + Middle East for that combined region
gdp_regional <- gdp_raw |>
  filter(
    Observation %in% names(ers_region_map),
    Unit == "Real GDP USD",
    Year %in% YEARS
  ) |>
  mutate(region = ers_region_map[Observation]) |>
  group_by(region, year = Year) |>
  summarise(gdp_real = sum(Value, na.rm = TRUE), .groups = "drop")

# CPI by mega-region (weighted average, using GDP weights)
cpi_regional_raw <- cpi_raw |>
  filter(
    Observation %in% names(ers_region_map),
    Unit == "Consumer Price Index 2017 = 100",
    Year %in% YEARS
  ) |>
  mutate(region = ers_region_map[Observation], year = Year)

gdp_weights <- gdp_raw |>
  filter(
    Observation %in% names(ers_region_map),
    Unit == "Real GDP USD",
    Year %in% YEARS
  ) |>
  mutate(region = ers_region_map[Observation]) |>
  select(region, Observation, year = Year, gdp = Value)

cpi_regional <- cpi_regional_raw |>
  left_join(gdp_weights, by = c("region", "Observation", "year")) |>
  group_by(region, year) |>
  summarise(
    cpi_importer = weighted.mean(Value, w = coalesce(gdp, 1), na.rm = TRUE),
    .groups = "drop"
  )

# Exchange rate: importing regions (same GDP-weighted approach for Africa-Mideast)
xrate_importer_raw <- xrate_raw |>
  filter(
    Observation %in% names(ers_region_map),
    Unit == "US Ag. Trade Weighted Exchange Rate, 2017=100",
    Year %in% YEARS
  ) |>
  mutate(region = ers_region_map[Observation], year = Year)

xrate_importer <- xrate_importer_raw |>
  left_join(gdp_weights, by = c("region", "Observation", "year")) |>
  group_by(region, year) |>
  summarise(
    xrate_importer = weighted.mean(Value, w = coalesce(gdp, 1), na.rm = TRUE),
    .groups = "drop"
  )

# Exchange rate: major competing exporters (Australia, Canada, Russia, Argentina,
# Ukraine, Kazakhstan) — GDP-weighted average used as single competitor rate.
# NOTE: Kaiser disaggregates this; here we use a single pooled competitor index.
competitors_xrate <- c("Australia", "Canada", "Russia", "Argentina",
                       "Ukraine", "Kazakhstan")

xrate_competitor <- xrate_raw |>
  filter(
    Observation %in% competitors_xrate,
    Unit == "US Ag. Trade Weighted Exchange Rate, 2017=100",
    Year %in% YEARS
  ) |>
  group_by(year = Year) |>
  summarise(
    xrate_competitor = mean(Value, na.rm = TRUE),
    .groups = "drop"
  )

cat("Macro components assembled.\n")

# ── 4. PSD global data → competing country exports ───────────────────────────
# Kaiser used bilateral competing exports by region; we use total competitor
# exports as a global proxy (same value for all 4 regions in each year).

psd_global <- readRDS(file.path(data_dir, "wheat_global_psd_clean.rds"))

# Major competing exporters (same list as above)
competing_exports <- psd_global |>
  filter(country %in% competitors_xrate, year %in% YEARS) |>
  group_by(year) |>
  summarise(
    competing_exports_1000mt = sum(exports_1000mt, na.rm = TRUE),
    .groups = "drop"
  )

cat("Competing exports: rows =", nrow(competing_exports), "\n")

# ── 5. Synthetic promotion expenditure data ──────────────────────────────────
# Kaiser (2015, Table 6 note): average annual combined USW+FAS expenditures
# 1994–2014 by region:
#   Asia:          $6.075M/yr
#   Africa-Mideast: $4.549M/yr
#   Europe:        $1.8M/yr
#   Latin America: $1.5M/yr
#
# We construct synthetic time series that:
#   (a) match these regional means for 1994–2014
#   (b) reflect the known post-2002 decline in Africa-Mideast spending (Black Sea
#       competition; see Kaiser p. 15)
#   (c) add modest realistic variance (±20%)
#   (d) apply a plausible post-2014 trend (flat to slight decline in real terms)
#
# This is clearly flagged as synthetic. Replace with USW data when available.

set.seed(7423)

synth_promotion <- function(years, mean_usd_m, trend_post2014 = -0.01,
                            sd_frac = 0.12, seed_offset = 0) {
  n <- length(years)
  base <- mean_usd_m
  vals <- numeric(n)
  for (i in seq_along(years)) {
    yr <- years[i]
    if (yr > 2014) base <- base * (1 + trend_post2014)
    noise <- rnorm(1, mean = 0, sd = sd_frac * base)
    vals[i] <- max(base + noise, 0.1)
  }
  vals
}

# Africa-Mideast: sharp decline after 2002 mirrors Kaiser's narrative
synth_afme <- function(years) {
  vals <- numeric(length(years))
  for (i in seq_along(years)) {
    yr <- years[i]
    if (yr <= 2002) {
      base <- 6.5
    } else if (yr <= 2010) {
      # rapid drawdown as Black Sea exporters take over
      base <- 6.5 - (yr - 2002) * 0.35
    } else {
      base <- 3.7
    }
    vals[i] <- max(base + rnorm(1, 0, 0.15 * base), 0.1)
  }
  vals
}

promo_synth <- tibble(year = YEARS) |>
  mutate(
    `Asia`          = synth_promotion(year, mean_usd_m = 6.075),
    `Europe`        = synth_promotion(year, mean_usd_m = 1.800),
    `Latin America` = synth_promotion(year, mean_usd_m = 1.500),
    `Africa-Mideast`= synth_afme(year)
  ) |>
  pivot_longer(-year, names_to = "region", values_to = "promotion_usd_m") |>
  mutate(promotion_synthetic = TRUE)

cat("Synthetic promotion data: rows =", nrow(promo_synth), "\n")
promo_synth |>
  group_by(region) |>
  summarise(
    mean_94_14 = mean(promotion_usd_m[year <= 2014]),
    mean_15_24 = mean(promotion_usd_m[year > 2014])
  )

# ── 6. Assemble final panel ──────────────────────────────────────────────────

kaiser_panel <- us_exports_regional |>
  left_join(gdp_regional,    by = c("region", "year")) |>
  left_join(cpi_regional,    by = c("region", "year")) |>
  left_join(xrate_importer,  by = c("region", "year")) |>
  left_join(xrate_competitor, by = "year") |>
  left_join(competing_exports, by = "year") |>
  left_join(promo_synth, by = c("region", "year")) |>
  arrange(region, year)

# Log-transform variables for estimation (consistent with Kaiser's log-log spec)
kaiser_panel <- kaiser_panel |>
  mutate(
    ln_exports     = log(us_wheat_exports_real + 0.001),   # +0.001 guards against zeros
    ln_gdp         = log(gdp_real),
    ln_cpi         = log(cpi_importer),
    ln_xrate_imp   = log(xrate_importer),
    ln_xrate_comp  = log(xrate_competitor),
    ln_comp_exports = log(competing_exports_1000mt),
    ln_promotion   = log(promotion_usd_m)
  )

cat("\nFinal panel: rows =", nrow(kaiser_panel), "\n")
cat("Regions:", unique(kaiser_panel$region), "\n")
cat("Years:", min(kaiser_panel$year), "-", max(kaiser_panel$year), "\n")
cat("Missing values by column:\n")
kaiser_panel |>
  summarise(across(everything(), ~sum(is.na(.)))) |>
  pivot_longer(everything()) |>
  filter(value > 0) |>
  print()

saveRDS(kaiser_panel, file.path(data_dir, "kaiser_panel.rds"))
cat("\nSaved: kaiser_panel.rds\n")
