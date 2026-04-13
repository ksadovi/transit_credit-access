LODEing_data <- function(overwrite   = FALSE,
                         version     = "LODES8",
                         job_type    = "JT01",
                         segment     = "S000") {
  
  out_path     <- "3_output/1_cleaned_data/3_LODES/tract_station_lodes.rds"
  cache_dir    <- "1_data/3_LODES/1_raw_files"
  pairings_dir <- "3_output/1_cleaned_data/2_station_geographies"
  
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  dir.create(cache_dir,         recursive = TRUE, showWarnings = FALSE)
  
  if (file.exists(out_path) && !overwrite) {
    message("Output already exists. Use overwrite = TRUE to regenerate.")
    return(invisible(read_rds(out_path)))
  }
  
  # Step 1: collect all completed tract-station pairings --------------------
  pairing_files <- list.files(pairings_dir,
                              pattern   = "_tract_station_pairings\\.rds$",
                              recursive = TRUE,
                              full.names = TRUE)
  if (length(pairing_files) == 0)
    stop("No tract_station_pairings files found. Run tract_station_pairings() first.")
  
  pairings <- map_dfr(pairing_files, ~{
    read_rds(.x) %>%
      st_drop_geometry() %>%
      dplyr::select(GEOID, STATEFP, starts_with("within_"))
  })
  
  affected_geoids <- unique(pairings$GEOID)
  
  # Step 2: FIPS -> state abbreviation lookup --------------------------------
  fips_lookup <- tigris::fips_codes %>%
    dplyr::select(state_abb = state, state_code) %>%
    distinct() %>%
    mutate(state_code = str_pad(state_code, 2, pad = "0"))
  
  pairings <- pairings %>%
    mutate(state_code = str_pad(STATEFP, 2, pad = "0")) %>%
    left_join(fips_lookup, by = "state_code")
  
  states_needed <- unique(pairings$state_abb) %>% na.omit()
  
  # Step 3: download LODES for each state, filter immediately ----------------
  years <- 2002:2023
  
  raw_lodes <- map_dfr(states_needed, function(st) {
    message("Fetching LODES for ", st, "...")
    map_dfr(years, function(yr) {
      tryCatch(
        lehdr::grab_lodes(
          state        = tolower(st),
          year         = yr,
          version      = version,
          lodes_type   = "od",
          job_type     = job_type,
          segment      = segment,
          state_part   = "main",
          agg_geo      = "tract",
          download_dir = file.path(cache_dir, st),
          use_cache    = TRUE
        ) %>%
          mutate(w_tract     = as.character(w_tract),
                 h_tract     = as.character(h_tract),
                 S000        = as.numeric(S000),
                 census_year = yr) %>%
          filter(w_tract %in% affected_geoids | h_tract %in% affected_geoids),
        error = function(e) {
          message("  No data for ", st, " ", yr, ": ", conditionMessage(e))
          tibble()
        }
      )
    })
  })
  
  # Step 4: aggregate to (GEOID, year) inflows and outflows ------------------
  inflows <- raw_lodes %>%
    filter(w_tract %in% affected_geoids, h_tract != w_tract) %>%
    group_by(GEOID = w_tract, census_year) %>%
    summarise(inflows = sum(S000, na.rm = TRUE), .groups = "drop")
  
  outflows <- raw_lodes %>%
    filter(h_tract %in% affected_geoids, h_tract != w_tract) %>%
    group_by(GEOID = h_tract, census_year) %>%
    summarise(outflows = sum(S000, na.rm = TRUE), .groups = "drop")
  
  flows <- full_join(inflows, outflows, by = c("GEOID", "census_year")) %>%
    mutate(inflows  = replace_na(inflows,  0),
           outflows = replace_na(outflows, 0))
  
  # Step 5: join station pairing metadata ------------------------------------
  result <- flows %>%
    left_join(
      pairings %>% dplyr::select(GEOID, starts_with("within_")),
      by = "GEOID"
    )
  
  write_rds(result, out_path)
  message("Saved ", nrow(result), " tract-year observations to ", out_path)
  invisible(result)
}