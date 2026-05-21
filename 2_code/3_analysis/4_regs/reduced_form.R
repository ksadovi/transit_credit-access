# Name: reduced_form.R
# Purpose: Static TWFE and event study regressions for inflows/outflows
# Last updated: 4/18/2026
# Preliminaries --------
source("2_code/3_analysis/4_regs/regs_prep.R")

controls <- c("transit_share", "drove_share", "walk_share",
              "median_hh_inc", "poverty_rate")

feols(
  as.formula(paste0(
    "c(log_inflows, log_outflows) ~ open*factor(isochrone) + station_type +",
    paste(controls, collapse = " + "),
    " | tracts + j"
  )),
  data    = working_df,
  cluster = ~tracts
) 

es = feols(
  as.formula(paste0(
    "c(log_inflows, log_outflows) ~ i(k, factor(isochrone), ref = -1) + ",
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

inflows = bind_rows(
  tidy_es(es[[1]], "Log Inflows"),
  tidy_es(es[[2]], "Log Outflows")
) %>%
  filter(isochrone == "15", outcome == "Log Outflows", k >= -16) %>%
  ggplot(aes(x = k, y = estimate, ymin = conf.low, ymax = conf.high)) +
  geom_ribbon(alpha = 0.15, fill = "steelblue") +
  geom_hline(yintercept = 0, color = "grey40", linewidth = 0.4) +
  geom_vline(xintercept = -1, linetype = "dashed", color = "grey40", linewidth = 0.4) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_point(color = "steelblue", size = 1.8) +
  scale_x_continuous(breaks = c(-15, -10, -5, 0, 5, 10, 15)) + 
  facet_wrap(~outcome, scales = "free_y") +
  labs(
    x = "Years relative to opening",
    y = "Coefficient (log points)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor  = element_blank(),
    panel.grid.major  = element_line(color = "grey92"),
    strip.text        = element_text(face = "bold"),
    axis.title        = element_text(size = 11),
    plot.background   = element_rect(fill = "white", color = NA)
  )

ggsave("3_output/2_figures/3_reg_output_plots/inflows_es.pdf", inflows)
