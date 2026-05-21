# Name: regs_prep.R
# Purpose: Merging and cleaning for clean regressions
# Last updated: 4/18/2026
# Preliminaries --------
data_out = "3_output/1_cleaned_data/"
source("2_code/1_utilities/packages+defaults.R")
lodes_stations = read_rds(paste0(data_out, "3_LODES/tract_station_lodes.rds"))
delays = update_stations()

# For each (tract, vintage), identify the single station projected to open
# first (by initial_expected_open_date). Since isochrones are cumulative
# (within_5 ⊆ within_15 ⊆ within_30), we first resolve each station to its
# closest band, then pick the earliest-projected station across all bands.
# Built at the vintage level (not year level) since pairings don't change
# year-to-year within a vintage.
best_station = lodes_stations %>%
  distinct(tracts, census_vintage, within_5, within_15, within_30) %>%
  pivot_longer(c(within_5, within_15, within_30),
               names_to     = "isochrone",
               names_prefix = "within_",
               values_to    = "station") %>%
  unnest(station) %>%
  mutate(isochrone = as.integer(isochrone)) %>%
  # Keep only the closest isochrone band for each station
  group_by(tracts, census_vintage, station) %>%
  slice_min(isochrone, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  left_join(
    delays %>%
      st_drop_geometry() %>%
      dplyr::select(station, station_type, system, open_date, initial_expected_open_date, initial_DEIS_date, delay) %>% 
      filter(station %in% c("Silver Spring", "Wilshire/Fairfax") == F), # don't know why these are causing issues
    by = "station"
  ) %>%
  group_by(tracts, census_vintage) %>%
  slice_min(initial_expected_open_date, n = 1, with_ties = FALSE) %>%
  ungroup()

# Working df: all LODES rows, list columns replaced with single-valued
# station/system/delay fields from the earliest-projected station.
working_df = lodes_stations %>%
  dplyr::select(-within_5, -within_15, -within_30, -transit_system) %>%
  left_join(best_station, by = c("tracts", "census_vintage"))

working_df = working_df %>%
  mutate(
    log_inflows  = log(inflows  + 1),
    log_outflows = log(outflows + 1),
    j = census_year - year(initial_expected_open_date),
    k = census_year - ifelse(year(initial_expected_open_date) > year(Sys.Date()), 
                             year(initial_expected_open_date), year(open_date)),
    open = as.integer(!is.na(open_date) & census_year >= year(open_date))
  ) 

# ACS 5-year tract-level controls, pulled annually and matched by year.
# Coverage begins in 2009 (first ACS 5-year release); LODES years 2002-2008
# will have NA controls. Note that 5-year estimates are rolling averages
# (e.g. the "2019" release covers 2015-2019), so adjacent years overlap heavily.
acs_vars = c(
  # Employment
  labor_force    = "B23025_003",
  employed       = "B23025_004",
  unemployed     = "B23025_005",
  # Commute mode
  commuters      = "B08301_001",
  drove_alone    = "B08301_003",
  transit        = "B08301_010",
  walked         = "B08301_019",
  wfh            = "B08301_021",
  # Income
  median_hh_inc  = "B19013_001",
  # Poverty
  poverty_denom  = "B17001_001",
  poverty_count  = "B17001_002"
  # Educational attainment (population 25+)
  # educ_total     = "B15003_001",
  # hs_diploma     = "B15003_017",
  # bachelors      = "B15003_022",
  # masters        = "B15003_023",
  # professional   = "B15003_024",
  # doctorate      = "B15003_025"
  # Industry (civilian employed 16+)
  # ind_total      = "C24030_001",
  # ind_agric      = "C24030_003",
  # ind_construct  = "C24030_004",
  # ind_manuf      = "C24030_005",
  # ind_wholesale  = "C24030_006",
  # ind_retail     = "C24030_007",
  # ind_transport  = "C24030_008",
  # ind_info       = "C24030_009",
  # ind_finance    = "C24030_010",
  # ind_prof       = "C24030_011",
  # ind_educ_hlth  = "C24030_012",
  # ind_arts       = "C24030_013",
  # ind_other      = "C24030_014",
  # ind_pubadmin   = "C24030_015"
)

if (file.exists(acs_cache_path)) {
  message("Loading ACS controls from cache...")
  acs_raw = read_rds(acs_cache_path)
} else {
  message("No cache found — pulling ACS from API...")
  dir.create(dirname(acs_cache_path), recursive = TRUE, showWarnings = FALSE)
  acs_raw = map_dfr(2009:2023, ~{
    message("Pulling ACS ", .x, "...")
    get_acs(
      geography = "tract",
      variables = acs_vars,
      state     = states_needed,
      year      = .x,
      survey    = "acs5",
      output    = "wide"
    ) %>%
      mutate(census_year = .x)
  })
  write_rds(acs_raw, acs_cache_path)
  message("ACS controls cached to ", acs_cache_path)
}

acs_controls = acs_raw %>%
  transmute(
    tracts         = GEOID,
    census_year,
    transit_share  = transitE     / commutersE,
    drove_share    = drove_aloneE / commutersE,
    walk_share     = walkedE      / commutersE,
    wfh_share      = wfhE         / commutersE,
    median_hh_inc  = median_hh_incE,
    poverty_rate   = poverty_countE  / poverty_denomE,
    manuf_share    = ind_manufE   / ind_totalE,
    transport_share = ind_transportE / ind_totalE,
    pubadmin_share = ind_pubadminE / ind_totalE
  )

working_df = working_df %>%
  left_join(acs_controls, by = c("tracts", "census_year")) %>%
  mutate(log_med_inc = log(median_hh_inc  + 1))

