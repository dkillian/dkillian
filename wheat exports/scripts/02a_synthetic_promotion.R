# 02a_synthetic_promotion.R
#
# Generates synthetic USW + USDA/FAS wheat export promotion expenditure data
# by mega-region, 1994–2024.
#
# IMPORTANT: This is placeholder data for model development only.
# Replace with actual expenditure data from U.S. Wheat Associates (USW)
# before any substantive analysis or publication.
#
# Calibration basis (Kaiser 2015, Table 6 note):
#   Average annual combined USW+FAS expenditures, 1994–2014:
#     Asia:           $6.075M/yr
#     Africa-Mideast: $4.549M/yr  (but declining sharply post-2002; see below)
#     Europe:         $1.800M/yr
#     Latin America:  $1.500M/yr
#
# Additional known facts from Kaiser pp. 15–16:
#   - USDA/FAS pays ~70% of total; USW pays ~30%
#   - Africa-Mideast spending fell sharply after ~2002 as Black Sea exporters
#     took market share and USW reallocated resources
#   - Asia was consistently the top-funded region
#   - Expenditures are deflated by the importing region's CPI in Kaiser's model
#
# Synthetic series design:
#   - Spline-interpolated trends anchored to Kaiser's regional means
#   - Africa-Mideast: step-down from ~$6.5M to ~$3.5M, 2002–2008
#   - Post-2014: modest real decline (~1–2%/yr) reflecting budget pressures
#   - Variance: ~10% coefficient of variation, AR(1) noise to avoid i.i.d. choppiness

library(tidyverse)

set.seed(8312)

data_dir <- "C:/Users/dkill/OneDrive/Documents/dkillian/wheat exports/data"

YEARS <- 1994:2024

# ── Helper: AR(1) noise ───────────────────────────────────────────────────────
ar1_noise <- function(n, sd, phi = 0.5) {
  e <- numeric(n)
  e[1] <- rnorm(1, 0, sd)
  for (i in 2:n) e[i] <- phi * e[i - 1] + rnorm(1, 0, sd * sqrt(1 - phi^2))
  e
}

# ── Asia ──────────────────────────────────────────────────────────────────────
# Mean 1994–2014: $6.075M. Slight upward trend through ~2008, then flat/slight
# decline as Black Sea competition intensifies globally.

asia_trend <- approx(
  x = c(1994, 2000, 2008, 2014, 2019, 2024),
  y = c(5.2,  6.1,  7.0,  6.2,  5.8,  5.4),
  xout = YEARS
)$y

asia <- tibble(
  year   = YEARS,
  region = "Asia",
  trend  = asia_trend,
  noise  = ar1_noise(length(YEARS), sd = 0.08 * mean(asia_trend))
) |>
  mutate(promotion_usd_m = pmax(trend + noise, 0.5))

# ── Africa-Mideast ─────────────────────────────────────────────────────────────
# Pre-2002: high spending (~$6.5M). Post-2002 sharp decline as Black Sea
# exporters displace US from Mediterranean/Mideast markets (Kaiser pp. 15–16).

afme_trend <- approx(
  x = c(1994, 2001, 2004, 2008, 2014, 2019, 2024),
  y = c(5.5,  6.0,  4.6,  3.6,  3.0,  2.8,  2.6),
  xout = YEARS
)$y

afme <- tibble(
  year   = YEARS,
  region = "Africa-Mideast",
  trend  = afme_trend,
  noise  = ar1_noise(length(YEARS), sd = 0.08 * mean(afme_trend))
) |>
  mutate(promotion_usd_m = pmax(trend + noise, 0.2))

# ── Europe ────────────────────────────────────────────────────────────────────
# Mean 1994–2014: $1.8M. Gradually declining as the EU improves its own wheat
# quality and Black Sea suppliers undercut on price.

europe_trend <- approx(
  x = c(1994, 2002, 2010, 2014, 2019, 2024),
  y = c(2.1,  2.0,  1.7,  1.5,  1.3,  1.1),
  xout = YEARS
)$y

europe <- tibble(
  year   = YEARS,
  region = "Europe",
  trend  = europe_trend,
  noise  = ar1_noise(length(YEARS), sd = 0.09 * mean(europe_trend))
) |>
  mutate(promotion_usd_m = pmax(trend + noise, 0.1))

# ── Latin America ─────────────────────────────────────────────────────────────
# Mean 1994–2014: $1.5M. Modest upward trend reflecting growing market
# importance; BCR was highest of any region (Kaiser Table 6: $24.36 per $1).

latam_trend <- approx(
  x = c(1994, 2002, 2010, 2014, 2019, 2024),
  y = c(1.2,  1.4,  1.6,  1.7,  1.6,  1.5),
  xout = YEARS
)$y

latam <- tibble(
  year   = YEARS,
  region = "Latin America",
  trend  = latam_trend,
  noise  = ar1_noise(length(YEARS), sd = 0.09 * mean(latam_trend))
) |>
  mutate(promotion_usd_m = pmax(trend + noise, 0.1))

# ── Combine and save ──────────────────────────────────────────────────────────

promo_synthetic <- bind_rows(asia, afme, europe, latam) |>
  select(year, region, promotion_usd_m, trend) |>
  mutate(
    promotion_synthetic = TRUE,
    ln_promotion = log(promotion_usd_m)
  )

# Verify against Kaiser's reported means
cat("Checking against Kaiser (2015) reported means (1994–2014):\n\n")
promo_synthetic |>
  filter(year <= 2014) |>
  group_by(region) |>
  summarise(
    mean_synthetic = round(mean(promotion_usd_m), 3),
    .groups = "drop"
  ) |>
  mutate(
    kaiser_reported = case_when(
      region == "Asia"           ~ 6.075,
      region == "Africa-Mideast" ~ 4.549,
      region == "Europe"         ~ 1.800,
      region == "Latin America"  ~ 1.500
    ),
    pct_diff = round(100 * (mean_synthetic - kaiser_reported) / kaiser_reported, 1)
  ) |>
  print()

saveRDS(promo_synthetic, file.path(data_dir, "promo_synthetic.rds"))
write_csv(promo_synthetic, file.path(data_dir, "promo_synthetic.csv"))
cat("\nSaved: promo_synthetic.rds / .csv\n")
