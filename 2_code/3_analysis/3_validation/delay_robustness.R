library(sf)
library(tigris)
library(tidycensus)
library(lme4)
library(dplyr)

options(tigris_use_cache = TRUE)

all_stations = update_stations() %>% 
  mutate(initial_expected_open_date = as.Date(initial_expected_open_date, format = "%m/%d/%y"), 
         initial_DEIS_date = as.Date(initial_DEIS_date, format = "%m/%d/%y")) %>% 
  mutate(delay = difftime(open_date, initial_expected_open_date))

# ── 1. Extract state from geometry ───────────────────────────────────────────
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
# You'll need a Census API key: census_api_key("YOUR_KEY", install = TRUE)
# Get all relevant states from your data
target_states <- unique(df_state$state_abbr)
target_states <- target_states[!is.na(target_states)]

income_tracts <- map_dfr(target_states, ~{
  get_acs(
    geography = "tract",
    variables = "B19013_001",   # median household income
    state = .x,
    year = 2022,
    geometry = TRUE
  )
}) %>%
  st_transform(st_crs(all_stations)) %>%
  dplyr::select(GEOID, median_income = estimate)

df_full <- st_join(df_state, income_tracts, join = st_within) %>%
  st_drop_geometry() %>%
  filter(!is.na(median_income), !is.na(delay_days)) %>%
  mutate(income_scaled = scale(median_income)[,1])

# ── 3. Nested multilevel model: station within system within state ─────────────
# Models to compare
m0 <- lmer(delay_days ~ 1 + (1 | state/system), data = df_full, REML = TRUE)
m1 <- lmer(delay_days ~ income_scaled + (1 | state/system), data = df_full, REML = TRUE)

# ICC at each level before and after income
icc_components <- function(model) {
  vc <- as.data.frame(VarCorr(model))
  vc$pct <- round(100 * vc$vcov / sum(vc$vcov), 1)
  vc[, c("grp", "vcov", "pct")]
}

cat("=== Variance components (no covariates) ===\n"); print(icc_components(m0))
cat("\n=== Variance components (controlling for income) ===\n"); print(icc_components(m1))
cat(sprintf("\nIncome β: %.1f days per SD  (p ≈ %.3f)\n",
            fixef(m1)["income_scaled"],
            2 * pnorm(-abs(summary(m1)$coefficients["income_scaled", "t value"]))))

# ── 4. Visualize: delay vs. income, colored by system ─────────────────────────
ggplot(df_full, aes(x = median_income / 1000, y = delay_days, color = system)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.7, aes(group = 1), color = "black") +
  scale_x_continuous(labels = scales::dollar_format(suffix = "k", prefix = "$")) +
  labs(title = "Delay vs. neighborhood median income",
       x = "Median household income (tract)", y = "Delay (days)", color = "System") +
  theme_minimal()

# ── 5. State-level means forest plot ──────────────────────────────────────────
state_stats <- df_full %>%
  group_by(state) %>%
  summarise(n = n(), mean = mean(delay_days),
            se = sd(delay_days)/sqrt(n),
            lo95 = mean - 1.96*se, hi95 = mean + 1.96*se)

ggplot(state_stats, aes(x = mean, y = reorder(state, mean))) +
  geom_vline(xintercept = mean(df_full$delay_days), linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lo95, xmax = hi95), height = 0.3, color = "steelblue") +
  geom_point(aes(size = n), color = "steelblue") +
  scale_size_continuous(range = c(2, 6), guide = "none") +
  labs(title = "Mean delay by state (95% CI)", x = "Delay (days)", y = NULL) +
  theme_minimal()

system_stats <- df_full %>%
  group_by(system) %>%
  summarise(n = n(), mean = mean(delay_days),
            se = sd(delay_days)/sqrt(n),
            lo95 = mean - 1.96*se, hi95 = mean + 1.96*se)

ggplot(system_stats, aes(x = mean, y = reorder(system, mean))) +
  geom_vline(xintercept = mean(df_full$delay_days), linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lo95, xmax = hi95), height = 0.3, color = "steelblue") +
  geom_point(aes(size = n), color = "steelblue") +
  scale_size_continuous(range = c(2, 6), guide = "none") +
  labs(title = "Mean delay by transit system (95% CI)", x = "Delay (days)", y = NULL) +
  theme_minimal()

# ── 1. Pull a battery of labor market variables from ACS ─────────────────────
lm_vars <- c(
  median_income      = "B19013_001",
  in_labor_force     = "B23025_002",
  employed           = "B23025_003",
  unemployed         = "B23025_005",
  pop_16plus         = "B23025_001",
  bachelors_plus     = "B15003_022",
  in_poverty         = "B17001_002",
  total_poverty_denom = "B17001_001"
)

tracts_lm <- map_dfr(target_states, ~{
  get_acs(geography = "tract", variables = lm_vars,
          state = .x, year = 2022, geometry = TRUE, output = "wide")
}) %>%
  st_transform(st_crs(all_stations)) %>%
  mutate(
    lfpr        = in_labor_forceE / pop_16plusE,        # labor force participation
    unemp_rate  = unemployedE / in_labor_forceE,        # unemployment rate
    emp_rate    = employedE / pop_16plusE,              # employment rate
    ba_share    = bachelors_plusE / pop_16plusE,        # educational attainment
    poverty_rate = in_povertyE / total_poverty_denomE
  ) %>%
  dplyr::select(GEOID, median_incomeE, lfpr, unemp_rate, emp_rate, ba_share, poverty_rate)

# ── 2. Spatial join onto stations ─────────────────────────────────────────────
df_lm <- st_join(
  all_stations %>% filter(!is.na(delay)) %>%
    mutate(delay_days = as.numeric(delay, units = "days")),
  tracts_lm,
  join = st_within
) %>%
  st_drop_geometry() %>%
  filter(!is.na(median_incomeE))

# Scale all labor market vars for comparability
lm_covars <- c("median_incomeE", "lfpr", "unemp_rate", "emp_rate", "ba_share", "poverty_rate")
df_lm <- df_lm %>%
  mutate(across(all_of(lm_covars), ~ scale(.)[,1], .names = "{.col}_z"))

# ── 3. Within-system regressions (system FE absorbed via demeaning) ───────────
# Partial out system FEs first
df_lm <- df_lm %>%
  group_by(system) %>%
  mutate(
    delay_dm = delay_days - mean(delay_days),
    across(ends_with("_z"), ~ . - mean(.), .names = "{.col}_dm")
  ) %>%
  ungroup()

# Regression of demeaned delay on demeaned labor market vars
covar_cols_dm <- paste0(lm_covars, "_z_dm")
formula_full  <- as.formula(paste("delay_dm ~", paste(covar_cols_dm, collapse = " + ")))
formula_null  <- delay_dm ~ 1

m_full_ols <- lm(formula_full, data = df_lm)
m_null_ols <- lm(formula_null, data = df_lm)

# Heteroskedasticity-robust standard errors
cat("=== Within-system: labor market → delay (robust SEs) ===\n")
print(coeftest(m_full_ols, vcov = vcovHC(m_full_ols, type = "HC3")))

# Joint F-test (robust)
cat("\n=== Joint F-test: all labor market vars jointly zero? ===\n")
print(waldtest(m_null_ols, m_full_ols, vcov = vcovHC(m_full_ols, type = "HC3")))

# ── 4. Coefficient plot ───────────────────────────────────────────────────────
library(ggplot2)
library(broom)

robust_se <- sqrt(diag(vcovHC(m_full_ols, type = "HC3")))
coef_df <- tidy(m_full_ols) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    std.error = robust_se[term],
    lo95 = estimate - 1.96 * std.error,
    hi95 = estimate + 1.96 * std.error,
    term = recode(term,
                  median_incomeE_z_dm = "Median income",
                  lfpr_z_dm           = "Labor force participation",
                  unemp_rate_z_dm     = "Unemployment rate",
                  emp_rate_z_dm       = "Employment rate",
                  ba_share_z_dm       = "Bachelor's share",
                  poverty_rate_z_dm   = "Poverty rate"
    )
  )

ggplot(coef_df, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lo95, xmax = hi95), height = 0.3, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  labs(
    title = "Within-system: labor market predictors of station delay",
    subtitle = "System fixed effects absorbed via demeaning | Robust 95% CIs",
    x = "Effect on delay (days per SD)", y = NULL
  ) +
  theme_minimal()