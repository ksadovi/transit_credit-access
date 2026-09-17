# Name: reduced_form.R
# Purpose: Static TWFE and event study regressions for inflows/outflows
# Last updated: 6/19/2026
# Preliminaries --------
source("2_code/3_analysis/4_regs/regs_prep.R")

controls <- c("median_hh_inc", "poverty_rate")
iso_levels <- c(5, 15, 30)

working_df = working_df %>%
  mutate(
    station_type = recode(station_type,
                          "residential: suburban" = "Residential Suburban",
                          "residential: urban"    = "Residential Urban"
    ),
    station_type = factor(station_type),
    station_type = fct_relevel(station_type, "Residential Urban")
  ) %>%
  filter(!is.na(open_date))

mods <- lapply(iso_levels, \(iso) feols(
  as.formula(paste0("c(log_inflows, log_outflows) ~ open*station_type + pre_existing_access +",
                    paste(controls, collapse = " + "),
                    " | tracts + j")),
  data    = working_df[working_df$isochrone == iso, ],
  cluster = ~tracts
))

# Split into inflow and outflow models
mods_in  <- lapply(mods, \(m) m[[1]])
mods_out <- lapply(mods, \(m) m[[2]])

# Event study: interact event time with isochrone band so each curve shows
# the effect at each distance from the new station.
# Reference: k = -1. pre_existing_bin is too sparse (95% "none") to use as a
# moderator; it's absorbed by tract FEs if included as a plain control.
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
  # Term format from fixest i(): "k::<k_val>:factor(isochrone)::<level>"
  # e.g. "k::-3:factor(isochrone)::5"
  broom::tidy(model, conf.int = TRUE) %>%
    filter(str_detect(term, "^k::")) %>%
    mutate(
      k         = as.integer(str_extract(term, "(?<=k::)-?\\d+")),
      isochrone = str_extract(term, "\\d+$"),
      outcome   = label
    )
}

es_data <- bind_rows(
  tidy_es(es[[1]], "Log Inflows"),
  tidy_es(es[[2]], "Log Outflows")
) %>%
  filter(k >= -16)

# Heterogeneity by pre-existing transit access: run the same ES on the
# "no prior access" majority and the "some prior access" minority separately,
# then compare event-study profiles visually.
es_prior    <- feols(
  as.formula(paste0(
    "c(log_inflows, log_outflows) ~ i(k, factor(isochrone), ref = -1) + station_type +",
    paste(controls, collapse = " + "),
    " | j"
  )),
  data    = working_df[working_df$pre_existing_bin != "none", ],
  cluster = ~tracts
)

es_no_prior <- feols(
  as.formula(paste0(
    "c(log_inflows, log_outflows) ~ i(k, factor(isochrone), ref = -1) + station_type +",
    paste(controls, collapse = " + "),
    " | j"
  )),
  data    = working_df[working_df$pre_existing_bin == "none", ],
  cluster = ~tracts
)

es_data_prior <- bind_rows(
  tidy_es(es_prior[[1]], "Log Inflows"),
  tidy_es(es_prior[[2]], "Log Outflows")
) %>% filter(k >= -16) %>% mutate(prior_access = "Some prior access")

es_data_no_prior <- bind_rows(
  tidy_es(es_no_prior[[1]], "Log Inflows"),
  tidy_es(es_no_prior[[2]], "Log Outflows")
) %>% filter(k >= -16) %>% mutate(prior_access = "No prior access")

es_data_strat <- bind_rows(es_data_prior, es_data_no_prior) %>%
  mutate(prior_access = factor(prior_access,
                               levels = c("No prior access", "Some prior access")))

# One PDF per isochrone x outcome
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
      title = paste0(out, " — ", iso, " min isochrone"),
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

# Stratified plot: prior vs. no prior access, same isochrone, faceted
plot_es_strat <- function(data, iso, out) {
  data %>%
    filter(isochrone == iso, outcome == out) %>%
    ggplot(aes(x = k, y = estimate, ymin = conf.low, ymax = conf.high)) +
    geom_ribbon(alpha = 0.15, fill = "steelblue") +
    geom_hline(yintercept = 0, color = "grey40", linewidth = 0.4) +
    geom_vline(xintercept = -1, linetype = "dashed", color = "grey40", linewidth = 0.4) +
    geom_line(color = "steelblue", linewidth = 0.8) +
    geom_point(color = "steelblue", size = 1.8) +
    facet_wrap(~prior_access) +
    scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15)) +
    labs(
      title = paste0(out, " — ", iso, " min isochrone"),
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

# Main ES: one PDF per isochrone x outcome
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

# Stratified ES: one PDF per isochrone x outcome (two panels side by side)
for (iso in unique(es_data_strat$isochrone)) {
  for (out in unique(es_data_strat$outcome)) {
    p     <- plot_es_strat(es_data_strat, iso, out)
    fname <- paste0(
      "3_output/2_figures/3_reg_output_plots/es_iso", iso, "_",
      tolower(gsub(" ", "_", out)), "_by_prior_access.pdf"
    )
    ggsave(fname, p, width = 11, height = 4.5)
  }
}

dict = c(
  # Treatment
  "open"                              = "Station Open",
  
  # Station types
  "station_typeResidential Suburban" = "Suburban Residential",
  "station_typeCBD"                   = "CBD",
  "station_typecommuter-rail-interchange" = "Commuter Rail Interchange",
  "station_typeairport"               = "Airport",
  
  # Isochrones
  "factor(isochrone)5"                = "5 min",
  "factor(isochrone)15"               = "15 min",
  "factor(isochrone)30"               = "30 min",
  
  #depvars
  "log_outflows" = "Log Worker Outflows",
  "log_inflows" = "Log Worker Inflows"
)


etable(mods_in, keep = "%^open",
       depvar = T,
       headers = list("Isochrone" = .("5 min", "15 min", "30 min")),
       extralines = list("Controls" = list("Yes", "Yes", "Yes")),
       drop.section = "fixef",
       replace = T,
       dict = dict,
       tex = TRUE,
       file = "3_output/3_tables/2_regression_tabs/inflows_by_isochrone.tex", 
       notes = "Reference category: Residential Urban.")

etable(mods_out, keep = "%^open",
       depvar = T,
       dict = dict,
       headers = list("Isochrone" = .("5 min", "15 min", "30 min")),
       extralines = list("Controls" = list("Yes", "Yes", "Yes")),
       tex = TRUE, drop.section = "fixef",
       notes = "Reference category: Residential Urban.",
       file = "3_output/3_tables/2_regression_tabs/outflows_by_isochrone.tex",
       replace = T)