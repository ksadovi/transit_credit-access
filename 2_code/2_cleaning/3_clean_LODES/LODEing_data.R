# Derives the states needed from completed tract_station_pairings files.
lodes_states_needed <- function(pairings_dir = "3_output/1_cleaned_data/2_station_geographies") {
  pairing_files <- list.files(pairings_dir,
                              pattern    = "2020_tract_station_pairings\\.rds$",
                              recursive  = TRUE,
                              full.names = TRUE)
  if (length(pairing_files) == 0)
    stop("No tract_station_pairings files found. Run tract_station_pairings() first.")
  
  fips_lookup <- tigris::fips_codes %>%
    dplyr::select(state_abb = state, state_code) %>%
    distinct() %>%
    mutate(state_code = str_pad(state_code, 2, pad = "0"))
  
  map_dfr(pairing_files, ~{
    read_rds(.x) %>%
      st_drop_geometry() %>%
      dplyr::select(tracts, state) %>%
      unnest(state) %>%
      mutate(state_code = str_pad(state, 2, pad = "0"))
  }) %>%
    left_join(fips_lookup, by = "state_code") %>%
    pull(state_abb) %>%
    unique() %>%
    na.omit() %>%
    sort()
}

# Downloads raw LODES files and immediately filters to affected tracts,
# saving a small filtered .rds per state x year. Skips if filtered file
# already exists. Run this first — it can take a while for large states.
download_lodes <- function(version      = "LODES8",
                           job_type     = "JT01",
                           years        = 2002:2023,
                           cache_dir    = "1_data/3_LODES/1_raw_files",
                           filtered_dir = "1_data/3_LODES/2_filtered",
                           pairings_dir = "3_output/1_cleaned_data/2_station_geographies",
                           overwrite    = FALSE) {
  
  states_needed <- lodes_states_needed(pairings_dir)
  message("States to process: ", paste(states_needed, collapse = ", "))
  
  # Get affected GEOIDs once upfront
  pairing_files   <- list.files(pairings_dir, pattern = "_tract_station_pairings\\.rds$",
                                recursive = TRUE, full.names = TRUE)
  affected_geoids <- map_dfr(pairing_files, ~{
    read_rds(.x) %>% st_drop_geometry() %>% dplyr::select(tracts)
  }) %>% pull(tracts) %>% unlist() %>% unique()
  
  for (st in states_needed) {
    message("\nProcessing ", st, "...")
    dir.create(file.path(cache_dir,    st), recursive = TRUE, showWarnings = FALSE)
    dir.create(file.path(filtered_dir, st), recursive = TRUE, showWarnings = FALSE)
    
    for (yr in years) {
      filtered_file <- file.path(filtered_dir, st, paste0(st, "_", yr, "_filtered.rds"))
      
      if (file.exists(filtered_file) && !overwrite) {
        message("  ", yr, " already filtered — skipping.")
        next
      }
      
      raw_file <- file.path(cache_dir, st,
                            paste0(tolower(st), "_od_main_", job_type, "_", yr, ".csv.gz"))
      
      # Download if raw file is missing or bad
      if (!file.exists(raw_file) || file.size(raw_file) < 2000) {
        tryCatch({
          lehdr::grab_lodes(
            state        = tolower(st),
            year         = yr,
            version      = version,
            lodes_type   = "od",
            job_type     = job_type,
            segment      = "S000",
            state_part   = "main",
            agg_geo      = "tract",
            download_dir = file.path(cache_dir, st),
            use_cache    = T
          )
          message("  ", yr, " downloaded.")
        }, error = function(e) {
          message("  ", yr, " not available: ", conditionMessage(e))
        })
      }
      
      # Filter and save — skip if raw still missing after download attempt
      if (!file.exists(raw_file) || file.size(raw_file) < 2000) next
      
      tryCatch({
        filtered <- fread(raw_file) %>%
          # Raw LODES files are block-level (15-digit w_geocode/h_geocode).
          # Truncate to 11 characters to get the tract GEOID:
          # [2 state][3 county][6 tract] = 11, dropping the trailing [4 block].
          mutate(w_tract     = str_sub(str_pad(as.character(w_geocode), 15, pad = "0"), 1, 11),
                 h_tract     = str_sub(str_pad(as.character(h_geocode), 15, pad = "0"), 1, 11),
                 S000        = as.numeric(S000),
                 census_year = yr) %>%
          dplyr::select(w_tract, h_tract, S000, census_year) %>%
          filter(w_tract %in% affected_geoids | h_tract %in% affected_geoids)
        
        write_rds(filtered, filtered_file)
        message("  ", yr, " filtered and saved (", nrow(filtered), " rows).")
      }, error = function(e) {
        message("  ", yr, " failed to filter: ", conditionMessage(e))
      })
    }
  }
  message("\nAll downloads and filtering complete.")
}


# Reads all filtered state x year files, aggregates to (GEOID x year)
# inflows/outflows, and joins station pairing metadata.
aggregate_lodes <- function(overwrite    = FALSE,
                            filtered_dir = "1_data/3_LODES/2_filtered",
                            pairings_dir = "3_output/1_cleaned_data/2_station_geographies",
                            out_path     = "3_output/1_cleaned_data/3_LODES/tract_station_lodes.rds") {
  
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  
  if (file.exists(out_path) && !overwrite) {
    message("Output already exists. Use overwrite = TRUE to regenerate.")
    return(invisible(read_rds(out_path)))
  }
  
  # Collect pairings metadata ------------------------------------------------
  pairing_files <- list.files(pairings_dir,
                              pattern    = "_tract_station_pairings\\.rds$",
                              recursive  = TRUE,
                              full.names = TRUE)
  if (length(pairing_files) == 0)
    stop("No tract_station_pairings files found.")
  
  # Invert pairings: from station-centric (one row per station x isochrone,
  # tracts as a list) to tract-centric (one row per tract, one column per
  # isochrone containing the list of stations that reach it).
  # Grouping directly by (tracts, census_vintage, state) and building each
  # isochrone column inline means multi-system tracts (e.g. LIRR + MTA both
  # covering Manhattan) naturally get their stations appended into one list
  # rather than creating duplicate rows.
  fips_lookup <- tigris::fips_codes %>%
    dplyr::select(state = state, state_code) %>%
    distinct() %>%
    mutate(state_code = str_pad(state_code, 2, pad = "0"))
  
  pairings_inverted <- map_dfr(pairing_files, ~{
    vintage <- as.integer(str_extract(basename(.x), "2000|2010|2020"))
    system  <- str_remove(basename(.x), "_(?:2000|2010|2020)_tract_station_pairings\\.rds$")
    read_rds(.x) %>%
      st_drop_geometry() %>%
      dplyr::select(id, isochrone, tracts) %>%
      mutate(census_vintage = vintage,
             transit_system = system)
  }) %>%
    unnest(tracts) %>%
    mutate(tracts     = str_remove(tracts, "^1400000US"),
           state_code = str_sub(tracts, 1, 2)) %>%
    left_join(fips_lookup, by = "state_code") %>%
    group_by(tracts, census_vintage, state) %>%
    summarise(
      within_5       = list(unique(id[isochrone == 5])),
      within_15      = list(unique(id[isochrone == 15])),
      within_30      = list(unique(id[isochrone == 30])),
      transit_system = list(unique(transit_system)),
      .groups = "drop"
    )
  
  affected_geoids <- unique(pairings_inverted$tracts)
  
  # Bind all filtered files --------------------------------------------------
  filtered_files <- list.files(filtered_dir, pattern = "_filtered\\.rds$",
                               recursive = TRUE, full.names = TRUE)
  if (length(filtered_files) == 0)
    stop("No filtered files found. Run download_lodes() first.")
  
  message("Reading ", length(filtered_files), " filtered files...")
  raw_lodes <- map_dfr(filtered_files, read_rds)
  
  # Aggregate to (tract, year) inflows and outflows --------------------------
  inflows <- raw_lodes %>%
    filter(w_tract %in% affected_geoids, h_tract != w_tract) %>%
    group_by(tract = w_tract, census_year) %>%
    summarise(inflows = sum(S000, na.rm = TRUE), .groups = "drop")
  
  outflows <- raw_lodes %>%
    filter(h_tract %in% affected_geoids, h_tract != w_tract) %>%
    group_by(tract = h_tract, census_year) %>%
    summarise(outflows = sum(S000, na.rm = TRUE), .groups = "drop")
  
  flows <- full_join(inflows, outflows, by = c("tract", "census_year")) %>%
    mutate(inflows  = replace_na(inflows,  0),
           outflows = replace_na(outflows, 0)) %>%
    rename(tracts = tract) %>%
    mutate(census_vintage = case_when(
      census_year < 2010 ~ 2000L,
      census_year < 2020 ~ 2010L,
      TRUE               ~ 2020L
    ))
  
  # Join inverted pairings, matching each LODES year to the correct tract vintage
  result <- flows %>%
    left_join(pairings_inverted, by = c("tracts", "census_vintage"))
  
  write_rds(result, out_path)
  message("Saved ", nrow(result), " tract-year observations to ", out_path)
  invisible(result)
}
