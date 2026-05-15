
d <- wheat_us_bilateral_clean

d2 <- d %>%
    filter(country=="Jamaica" |
               country == "Dominican Republic")

d2

ggplot(d2, aes(year, export_usd, group=country, color=country)) + 
    geom_line() + 
    geom_point()
