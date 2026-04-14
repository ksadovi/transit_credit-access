library(sf)
library(tigris)
library(tidycensus)
library(fixest)
library(dplyr)
library(purrr)
library(ggplot2)
library(broom)

options(tigris_use_cache = TRUE)

# Output directory ─────────────────────────────────────────────────────────────
out_dir <- file.path("3_output", "2_figures", "3_delay_robustness")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ── Data loading ───────────────────────────────────────────────────────────────
all_stations <- update_stations() %>%
  mutate(
    initial_expected_open_date = as.Date(initial_expected_open_date, format = "%m/%d/%y"),
    initial_DEIS_date          = as.Date(initial_DEIS_date,          format = "%m/%d/%y")
  ) %>%
  mutate(delay = difftime(open_date, initial_expected_open_date))

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
m1 <- feols(delay_days ~ income_scaled  | state + system, data = df_full, vcov = "HC3")

cat("=== Income → delay, within state + system (HC3 SEs) ===\n")
etable(m0, m1, vcov = "HC3",
       dict    = c(income_scaled = "Median income (SD)"),
       title   = "Delay (days) regressed on neighborhood income",
       headers = c("No covariates", "Income"))

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
df_lm <- st_join(
  all_stations %>%
    filter(!is.na(delay)) %>%
    mutate(delay_days = as.numeric(delay, units = "days")),
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

m_ws_null <- feols(fml_null, data = df_lm, vcov = "HC3")
m_ws_full <- feols(fml_full, data = df_lm, vcov = "HC3")

cat("=== Within-system: labor market → delay (system FE, HC3 SEs) ===\n")
etable(
  m_ws_null, m_ws_full,
  dict = c(
    median_incomeE_z = "Median income",
    lfpr_z           = "LFP rate",
    unemp_rate_z     = "Unemployment rate",
    emp_rate_z       = "Employment rate",
    ba_share_z       = "Bachelor's share",
    poverty_rate_z   = "Poverty rate"
  ),
  title   = "Delay (days) on within-system labor market characteristics",
  headers = c("Null", "Full")
)

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
    subtitle = "System fixed effects | HC3 robust 95% CIs",
    x        = "Effect on delay (days per SD)",
    y        = NULL
  ) +
  theme_minimal()

ggsave(file.path(out_dir, "within_system_coef_plot.png"),
       p_coef, width = 7, height = 5, dpi = 300)
