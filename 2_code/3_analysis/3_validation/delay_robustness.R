source("2_code/1_utilities/packages+defaults.R")
source("2_code/2_cleaning/1_clean_station_geographies/update_stations.R")
options(tigris_use_cache = TRUE)

# Output directories ───────────────────────────────────────────────────────────
out_dir <- file.path("3_output", "2_figures", "3_delay_robustness")
tab_dir <- file.path("3_output", "3_tables", "3_delay_robustness")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# ── Data loading ───────────────────────────────────────────────────────────────
all_stations <- update_stations() 

# ── 1. Extract state from geometry ────────────────────────────────────────────
states_sf <- states(cb = TRUE, resolution = "20m") %>%
  st_transform(st_crs(all_stations)) %>%
  dplyr::select(state = NAME, state_abbr = STUSPS)

df_state <- st_join(
  all_stations %>% filter(!is.na(delay)),
  states_sf,
  join = st_within
) %>%
  mutate(delay_days = as.numeric(delay, units = "days"))

# ── 1b. Descriptive summary table + delay histogram ──────────────────────────
library(knitr)
library(kableExtra)

# Wrap the tabular environment in \resizebox{\linewidth}{!}{...} so every
# table file is self-sizing.  Beamer frames then only need \input{file.tex}
# with no adjustbox wrapper in the .tex source.
wrap_for_beamer <- function(filepath) {
  lines <- readLines(filepath, warn = FALSE)
  begin_tab <- grep("\\\\begin\\{tabular", lines)[1]
  end_tab   <- tail(grep("\\\\end\\{tabular", lines), 1)
  lines[begin_tab] <- paste0("\\resizebox{!}{0.35\\textheight}{%\n", lines[begin_tab])
  lines[end_tab]   <- paste0(lines[end_tab], "%\n}")
  writeLines(lines, filepath)
}

desc_tab_dir <- file.path("3_output", "3_tables", "0_descriptive")
desc_fig_dir <- file.path("3_output", "2_figures", "0_descriptive")
dir.create(desc_tab_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(desc_fig_dir, showWarnings = FALSE, recursive = TRUE)

df_desc <- df_state %>% filter(!is.na(delay_days))

n_sta <- nrow(df_desc)
n_sys <- n_distinct(df_desc$system)

sum_tbl <- tibble::tribble(
  ~Statistic,                            ~Value,
  "Stations",                            formatC(n_sta, format = "d", big.mark = ","),
  "Transit systems",                     as.character(n_sys),
  "Avg.\\ stations per system",          sprintf("%.1f", n_sta / n_sys),
  "Stations with any delay (\\%)",       sprintf("%.1f", mean(df_desc$delay_days > 0) * 100),
  "Mean delay (days)",                   sprintf("%.0f", mean(df_desc$delay_days)),
  "Median delay (days)",                 sprintf("%.0f", median(df_desc$delay_days)),
  "SD of delay (days)",                  sprintf("%.0f", sd(df_desc$delay_days)),
  "Min / max delay (days)",              sprintf(
                                           "%d / %d",
                                           as.integer(min(df_desc$delay_days)),
                                           as.integer(max(df_desc$delay_days))
                                         )
)

# Write bare LaTeX fragments (no \documentclass wrapper) so \input{} works in Beamer.
# save_kable() adds a full document preamble; writeLines(as.character()) does not.
# Also omit hold_position: it wraps in a table float, which Beamer can't place.
writeLines(
  as.character(
    kable(
      sum_tbl,
      format    = "latex",
      booktabs  = TRUE,
      escape    = FALSE,
      col.names = c("", ""),
      linesep   = ""
    ) %>%
      kable_styling(font_size = 10, full_width = FALSE)
  ),
  file.path(desc_tab_dir, "delay_descriptive.tex")
)
wrap_for_beamer(file.path(desc_tab_dir, "delay_descriptive.tex"))

# Per-system breakdown (for appendix)
sys_sum <- df_desc %>%
  group_by(system) %>%
  summarise(
    N              = n(),
    `Mean (days)`  = round(mean(delay_days)),
    `Median (days)`= round(median(delay_days)),
    `SD (days)`    = round(sd(delay_days)),
    `Max (days)`   = round(max(delay_days)),
    .groups = "drop"
  ) %>%
  arrange(desc(`Mean (days)`))

writeLines(
  as.character(
    kable(
      sys_sum,
      format   = "latex",
      booktabs = TRUE,
      linesep  = ""
    ) %>%
      kable_styling(latex_options = "scale_down", font_size = 9)
  ),
  file.path(desc_tab_dir, "delay_by_system.tex")
)
wrap_for_beamer(file.path(desc_tab_dir, "delay_by_system.tex"))

# Delay distribution histogram (x-axis in years for readability)
df_desc <- df_desc %>% mutate(delay_yrs = delay_days / 365.25)

p_hist <- ggplot(df_desc, aes(x = delay_yrs)) +
  geom_histogram(
    binwidth = 0.5, boundary = 0,
    fill = "#8b0000", color = "white", alpha = 0.85
  ) +
  geom_vline(
    xintercept = mean(df_desc$delay_yrs),
    linetype = "dashed", color = "grey30", linewidth = 0.7
  ) +
  annotate(
    "text",
    x = mean(df_desc$delay_yrs) + 0.15, y = Inf,
    vjust = 1.5, hjust = 0,
    label = sprintf("Mean = %.1f yrs", mean(df_desc$delay_yrs)),
    size = 3, color = "grey30"
  ) +
  scale_x_continuous(
    breaks = seq(0, ceiling(max(df_desc$delay_yrs)), by = 1),
    labels = function(x) paste0(x, " yr")
  ) +
  labs(
    title = "Distribution of station opening delays",
    x     = "Delay (years past projected opening)",
    y     = "Number of stations"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

ggsave(
  file.path(desc_fig_dir, "delay_distribution.png"),
  p_hist, width = 7, height = 4, dpi = 300
)

# ── 2. Join Census tract median household income ──────────────────────────────
target_states <- unique(df_state$state_abbr)
target_states <- target_states[!is.na(target_states)]

income_tracts <- map_dfr(target_states, ~{
  get_acs(
    geography = "tract",
    variables = "B19013_001",   # median household income
    state     = .x,
    year      = 2022,
    geometry  = TRUE
  )
}) %>%
  st_transform(st_crs(all_stations)) %>%
  dplyr::select(GEOID, median_income = estimate)

df_full <- st_join(df_state, income_tracts, join = st_within) %>%
  st_drop_geometry() %>%
  filter(!is.na(median_income), !is.na(delay_days)) %>%
  mutate(income_scaled = scale(median_income)[, 1])

# ── 3. Income → delay, absorbing state + system FEs ──────────────────────────
# Replaces the multilevel lmer models; feols absorbs state and system as
# two-way fixed effects, which is directly exportable via etable().
m0 <- feols(delay_days ~ 1              | state + system, data = df_full)
m1 <- feols(delay_days ~ income_scaled  | state + system, data = df_full, vcov = "hetero")

cat("=== Income → delay, within state + system (HC3 SEs) ===\n")
etable(m0, m1, vcov = "hetero",
       dict    = c(income_scaled = "Median income (SD)", 
                   delay_days = "Delay (days)"),
       title   = "Delay (days) regressed on neighborhood income",
       headers = c("No covariates", "Income"),
       file    = file.path(tab_dir, "delay_income_state_system_fe.tex"),
       replace = T)
wrap_for_beamer(file.path(tab_dir, "delay_income_state_system_fe.tex"))

# ── 4. Plot: delay vs. income, colored by system ──────────────────────────────
p_income <- ggplot(df_full, aes(x = median_income / 1000, y = delay_days, color = system)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.7, aes(group = 1), color = "black") +
  scale_x_continuous(labels = scales::dollar_format(suffix = "k", prefix = "$")) +
  labs(
    title = "Delay vs. neighborhood median income",
    x     = "Median household income (tract)",
    y     = "Delay (days)",
    color = "System"
  ) +
  theme_minimal()

ggsave(file.path(out_dir, "delay_vs_income.png"),
       p_income, width = 8, height = 5, dpi = 300)

# ── 5. State-level means forest plot ──────────────────────────────────────────
state_stats <- df_full %>%
  group_by(state) %>%
  summarise(
    n     = n(),
    mean  = mean(delay_days),
    se    = sd(delay_days) / sqrt(n),
    lo95  = mean - 1.96 * se,
    hi95  = mean + 1.96 * se,
    .groups = "drop"
  )

p_state <- ggplot(state_stats, aes(x = mean, y = reorder(state, mean))) +
  geom_vline(xintercept = mean(df_full$delay_days),
             linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lo95, xmax = hi95),
                 height = 0.3, color = "steelblue") +
  geom_point(aes(size = n), color = "steelblue") +
  scale_size_continuous(range = c(2, 6), guide = "none") +
  labs(title = "Mean delay by state (95% CI)", x = "Delay (days)", y = NULL) +
  theme_minimal()

ggsave(file.path(out_dir, "mean_delay_by_state.png"),
       p_state, width = 7, height = 5, dpi = 300)

# ── 6. System-level means forest plot ─────────────────────────────────────────
system_stats <- df_full %>%
  group_by(system) %>%
  summarise(
    n     = n(),
    mean  = mean(delay_days),
    se    = sd(delay_days) / sqrt(n),
    lo95  = mean - 1.96 * se,
    hi95  = mean + 1.96 * se,
    .groups = "drop"
  )

p_system <- ggplot(system_stats, aes(x = mean, y = reorder(system, mean))) +
  geom_vline(xintercept = mean(df_full$delay_days),
             linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lo95, xmax = hi95),
                 height = 0.3, color = "steelblue") +
  geom_point(aes(size = n), color = "steelblue") +
  scale_size_continuous(range = c(2, 6), guide = "none") +
  labs(title = "Mean delay by transit system (95% CI)", x = "Delay (days)", y = NULL) +
  theme_minimal()

ggsave(file.path(out_dir, "mean_delay_by_system.png"),
       p_system, width = 7, height = 5, dpi = 300)

# ── 7. Pull battery of labor market variables from ACS ────────────────────────
lm_vars <- c(
  median_income       = "B19013_001",
  in_labor_force      = "B23025_002",
  employed            = "B23025_003",
  unemployed          = "B23025_005",
  pop_16plus          = "B23025_001",
  bachelors_plus      = "B15003_022",
  in_poverty          = "B17001_002",
  total_poverty_denom = "B17001_001"
)

tracts_lm <- map_dfr(target_states, ~{
  get_acs(
    geography = "tract",
    variables = lm_vars,
    state     = .x,
    year      = 2022,
    geometry  = TRUE,
    output    = "wide"
  )
}) %>%
  st_transform(st_crs(all_stations)) %>%
  mutate(
    lfpr         = in_labor_forceE / pop_16plusE,
    unemp_rate   = unemployedE     / in_labor_forceE,
    emp_rate     = employedE       / pop_16plusE,
    ba_share     = bachelors_plusE / pop_16plusE,
    poverty_rate = in_povertyE     / total_poverty_denomE
  ) %>%
  dplyr::select(GEOID, median_incomeE, lfpr, unemp_rate,
                emp_rate, ba_share, poverty_rate)

# ── 8. Spatial join onto stations ─────────────────────────────────────────────
# Use df_state (already joined to states_sf) so the state column carries through
# to section 11's cross-system regressions and feols(... | state) FE.
df_lm <- st_join(
  df_state %>% filter(!is.na(delay_days)),
  tracts_lm,
  join = st_within
) %>%
  st_drop_geometry() %>%
  filter(!is.na(median_incomeE))

lm_covars <- c("median_incomeE", "lfpr", "unemp_rate",
               "emp_rate", "ba_share", "poverty_rate")

df_lm <- df_lm %>%
  mutate(across(all_of(lm_covars), ~ scale(.)[, 1], .names = "{.col}_z"))

# ── 9. Within-system regressions via feols (system FE absorbed) ───────────────
# feols with | system replaces the manual demeaning + lm approach.
# HC3 robust SEs are set at estimation time.
covar_z    <- paste0(lm_covars, "_z")
fml_null   <- as.formula("delay_days ~ 1                         | system")
fml_full   <- as.formula(paste("delay_days ~", paste(covar_z, collapse = " + "), "| system"))

m_ws_null <- feols(fml_null, data = df_lm, vcov = "hetero")
m_ws_full <- feols(fml_full, data = df_lm, vcov = "hetero")

cat("=== Within-system: labor market → delay (system FE, HC3 SEs) ===\n")

# Joint Wald test: all labor market coefficients simultaneously zero
cat("\n=== Joint Wald test: labor market vars jointly zero? ===\n")
wald(m_ws_full, covar_z)

# ── 10. Coefficient plot ───────────────────────────────────────────────────────
coef_labels <- c(
  median_incomeE_z = "Median income",
  lfpr_z           = "Labor force participation",
  unemp_rate_z     = "Unemployment rate",
  emp_rate_z       = "Employment rate",
  ba_share_z       = "Bachelor's share",
  poverty_rate_z   = "Poverty rate"
)

coef_df <- tidy(m_ws_full, conf.int = TRUE) %>%
  filter(term %in% names(coef_labels)) %>%
  mutate(term = recode(term, !!!coef_labels))

p_coef <- ggplot(coef_df, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high),
                 height = 0.3, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  labs(
    title    = "Within-system: labor market predictors of station delay",
    subtitle = "System fixed effects | HC1 robust 95% CIs",
    x        = "Effect on delay (days per SD)",
    y        = NULL
  ) +
  theme_minimal()

ggsave(file.path(out_dir, "within_system_coef_plot.png"),
       p_coef, width = 7, height = 5, dpi = 300)

# ── 11. Cross-system regressions (no FEs) ─────────────────────────────────────
# Tests whether systems serving lower-income / worse-labor-market neighborhoods
# have systematically longer delays. Both system and state FEs are dropped so
# that the full cross-system variation is visible with no absorption.
fml_cs_null <- as.formula("delay_days ~ 1")
fml_cs_full <- as.formula(paste("delay_days ~", paste(covar_z, collapse = " + ")))

m_cs_null <- feols(fml_cs_null, data = df_lm, vcov = "hetero")
m_cs_full <- feols(fml_cs_full, data = df_lm, vcov = "hetero")

cat("=== Combined labor market → delay table ===\n")
etable(
  m_ws_full, m_cs_null, m_cs_full,
  dict = c(
    median_incomeE_z = "Median income",
    lfpr_z           = "LFP rate",
    unemp_rate_z     = "Unemployment rate",
    emp_rate_z       = "Employment rate",
    ba_share_z       = "Bachelor's share",
    poverty_rate_z   = "Poverty rate",
    delay_days       = "Delay (days)"
  ),
  title   = "Delay (days) on labor market characteristics",
  file    = file.path(tab_dir, "delay_labormarket_combined.tex"),
  replace = TRUE
)
wrap_for_beamer(file.path(tab_dir, "delay_labormarket_combined.tex"))

cat("\n=== Joint Wald test (cross-system): labor market vars jointly zero? ===\n")
wald(m_cs_full, covar_z)

# ── 12. Cross-system coefficient plot ─────────────────────────────────────────
coef_df_cs <- tidy(m_cs_full, conf.int = TRUE) %>%
  filter(term %in% names(coef_labels)) %>%
  mutate(term = recode(term, !!!coef_labels))

# Combine within- and cross-system results for a side-by-side comparison
coef_combined <- bind_rows(
  coef_df    %>% mutate(spec = "Within-system (system FE)"),
  coef_df_cs %>% mutate(spec = "Cross-system (no FEs)")
)

p_coef_cs <- ggplot(coef_combined,
                    aes(x = estimate, y = reorder(term, estimate),
                        color = spec, shape = spec)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high),
                 height = 0.25, position = position_dodgev(height = 0.5)) +
  geom_point(size = 3,           position = position_dodgev(height = 0.5)) +
  scale_color_manual(values = c("Within-system (system FE)" = "steelblue",
                                "Cross-system (no FEs)"     = "#c0392b")) +
  scale_shape_manual(values = c("Within-system (system FE)" = 16,
                                "Cross-system (no FEs)"     = 17)) +
  labs(
    title    = "Labor market predictors of station delay",
    subtitle = "No FEs (cross-system) vs. system FE (within-system) | HC1 robust 95% CIs",
    x        = "Effect on delay (days per SD)",
    y        = NULL,
    color    = NULL,
    shape    = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave(file.path(out_dir, "cross_vs_within_system_coef_plot.png"),
       p_coef_cs, width = 8, height = 5.5, dpi = 300)

# quick delay visuals 
summary(df_full$delay_days)
