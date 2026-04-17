# Derives the states needed from completed tract_station_pairings files.
lodes_states_needed <- function(pairings_dir = "3_output/1_cleaned_data/2_station_geographies") {
  pairing_files <- list.files(pairings_dir,
                              pattern    = "_tract_station_pairings\\.rds$",
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
      dplyr::select(GEOID, STATEFP) %>%
      mutate(state_code = str_pad(STATEFP, 2, pad = "0"))
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
                           pairings_dir = "3_output/1_cleaned_data/2_station_geographies") {
  
  states_needed <- lodes_states_needed(pairings_dir)
  message("States to process: ", paste(states_needed, collapse = ", "))
  
  # Get affected GEOIDs once upfront
  pairing_files   <- list.files(pairings_dir, pattern = "_tract_station_pairings\\.rds$",
                                recursive = TRUE, full.names = TRUE)
  affected_geoids <- map_dfr(pairing_files, ~{
    read_rds(.x) %>% st_drop_geometry() %>% dplyr::select(GEOID)
  }) %>% pull(GEOID) %>% unique()
  
  for (st in states_needed) {
    message("\nProcessing ", st, "...")
    dir.create(file.path(cache_dir,    st), recursive = TRUE, showWarnings = FALSE)
    dir.create(file.path(filtered_dir, st), recursive = TRUE, showWarnings = FALSE)
    
    for (yr in years) {
      filtered_file <- file.path(filtered_dir, st, paste0(st, "_", yr, "_filtered.rds"))
      
      if (file.exists(filtered_file)) {
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
          mutate(w_tract     = as.character(w_geocode),
                 h_tract     = as.character(h_geocode),
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
  
  pairings <- map_dfr(pairing_files, ~{
    read_rds(.x) %>%
      st_drop_geometry() %>%
      dplyr::select(GEOID, starts_with("within_"))
  })
  
  affected_geoids <- unique(pairings$GEOID)
  
  # Bind all filtered files --------------------------------------------------
  filtered_files <- list.files(filtered_dir, pattern = "_filtered\\.rds$",
                               recursive = TRUE, full.names = TRUE)
  if (length(filtered_files) == 0)
    stop("No filtered files found. Run download_lodes() first.")
  
  message("Reading ", length(filtered_files), " filtered files...")
  raw_lodes <- map_dfr(filtered_files, read_rds)
  
  # Aggregate to (GEOID, year) inflows and outflows --------------------------
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
  
  # Join station pairing metadata --------------------------------------------
  result <- flows %>%
    left_join(pairings %>% dplyr::select(GEOID, starts_with("within_")),
              by = "GEOID")
  
  write_rds(result, out_path)
  message("Saved ", nrow(result), " tract-year observations to ", out_path)
  invisible(result)
}
