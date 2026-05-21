# Name: reduced_form.R
# Purpose: Static TWFE and event study regressions for inflows/outflows
# Last updated: 4/18/2026
# Preliminaries --------
source("2_code/3_analysis/4_regs/regs_prep.R")

controls <- c("median_hh_inc", "poverty_rate")
iso_levels <- c(5, 15, 30)

working_df <- working_df %>%
  mutate(station_type = recode(station_type,
                               "residential: suburban" = "Residential Suburban",
                               "residential: urban"    = "Residential Urban"
  ))

mods <- lapply(iso_levels, \(iso) feols(
  as.formula(paste0("c(log_inflows, log_outflows) ~ open*station_type +",
                    paste(controls, collapse = " + "),
                    " | tracts + j")),
  data    = working_df[working_df$isochrone == iso, ],
  cluster = ~tracts
))

# Split into inflow and outflow models
mods_in  <- lapply(mods, \(m) m[[1]])
mods_out <- lapply(mods, \(m) m[[2]])

es <- feols(
  as.formula(paste0(
    "c(log_inflows, log_outflows) ~ i(k, factor(isochrone), ref = -1) + station_type +",
    paste(controls, collapse = " + "),
    " | j"
  )),
  data    = working_df,
  cluster = ~tracts
)

tidy_es <- function(model, label) {
  broom::tidy(model, conf.int = TRUE) %>%
    filter(str_detect(term, "^k::")) %>%
    mutate(k         = as.integer(str_extract(term, "-?\\d+(?=:factor)")),
           isochrone = str_extract(term, "\\d+$"),
           outcome   = label)
}

es_data <- bind_rows(
  tidy_es(es[[1]], "Log Inflows"),
  tidy_es(es[[2]], "Log Outflows")
) %>%
  filter(k >= -16)

plot_es <- function(data, iso, out) {
  data %>%
    filter(isochrone == iso, outcome == out) %>%
    ggplot(aes(x = k, y = estimate, ymin = conf.low, ymax = conf.high)) +
    geom_ribbon(alpha = 0.15, fill = "steelblue") +
    geom_hline(yintercept = 0, color = "grey40", linewidth = 0.4) +
    geom_vline(xintercept = -1, linetype = "dashed", color = "grey40", linewidth = 0.4) +
    geom_line(color = "steelblue", linewidth = 0.8) +
    geom_point(color = "steelblue", size = 1.8) +
    scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15)) +
    labs(
      title = paste0(out, " \u2014 ", iso, " min isochrone"),
      x     = "Years relative to opening",
      y     = "Coefficient (log points)"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey92"),
      axis.title       = element_text(size = 11),
      plot.background  = element_rect(fill = "white", color = NA)
    )
}

# One PDF per isochrone × outcome
for (iso in unique(es_data$isochrone)) {
  for (out in unique(es_data$outcome)) {
    p     <- plot_es(es_data, iso, out)
    fname <- paste0(
      "3_output/2_figures/3_reg_output_plots/es_iso", iso, "_",
      tolower(gsub(" ", "_", out)), ".pdf"
    )
    ggsave(fname, p, width = 7, height = 4.5)
  }
}

dict <- c(
  # Treatment
  "open"                              = "Station Open",
  
  # Station types
  "station_typeResidential Suburban" = "Suburban Residential",
  "station_typeResidential Urban"    = "Urban Residential",
  "station_typeCBD"                   = "CBD",
  "station_typecommuter-rail-interchange" = "Commuter Rail Interchange",
  
  # Isochrones
  "factor(isochrone)5"                = "5 min",
  "factor(isochrone)15"               = "15 min",
  "factor(isochrone)30"               = "30 min"
)


etable(mods_in, keep = "%^open",
       depvar = FALSE,
       headers = list("Isochrone" = .("5 min", "15 min", "30 min")),
       extralines = list("Controls" = list("Yes", "Yes", "Yes")),
       drop.section = "fixef",
       replace = T,
       dict = dict, 
       tex = TRUE, 
       file = "3_output/3_tables/2_regression_tabs/inflows_by_isochrone.tex")

etable(mods_out, keep = "%^open",
       depvar = FALSE,
       dict = dict,
       headers = list("Isochrone" = .("5 min", "15 min", "30 min")),
       extralines = list("Controls" = list("Yes", "Yes", "Yes")),
       tex = TRUE, drop.section = "fixef",
       file = "3_output/3_tables/2_regression_tabs/outflows_by_isochrone.tex",
       replace = T)
