# Preliminaries  --------
source("2_code/1_utilities/packages+defaults.R")

# Aggregating station locations across systems  --------
# I have collected this data by hand in CSVs housed in 1_data/2_station_geographies/. I 
# will have one CSV per transit system I cover. I will continue to add to it as I incorporate 
# more transit systems into this analysis. I am making this a function so that it can be 
# called from any other file in this project, achieving easy updating for the stations whenever I add more.

update_stations = function(){
  # Parse dates that may be 2-digit ("%m/%d/%y", e.g. "9/13/15" → 2015) or
  # 4-digit ("%m/%d/%Y", e.g. "6/22/1915" → 1915).  Try 4-digit first so that
  # "1904" is not silently truncated to "19" → 2019 by %y.
  parse_date_flex = function(x) {
    # Route by string structure, not by coalesce — coalesce fails because R's
    # %Y will parse "25" as year AD 25 (a valid date, not NA), so the fallback
    # to %m/%d/%y never fires.  Check whether the year field is 4 digits first.
    dplyr::case_when(
      is.na(x) | x == "NA"          ~ as.Date(NA_character_),
      grepl("/\\d{4}$", trimws(x))  ~ as.Date(x, format = "%m/%d/%Y"),
      TRUE                           ~ as.Date(x, format = "%m/%d/%y")
    )
  }
  
  stations = data.frame()
  for(i in list.files("1_data/2_station_geographies/", pattern = "*.csv")){
    stations = rbind(stations, fread(paste0("1_data/2_station_geographies/", i)))
  }
  stations = stations %>%
    distinct() %>%   # drop exact-duplicate rows introduced by CSV edits
    mutate(
      open_date                  = parse_date_flex(open_date),
      initial_expected_open_date = parse_date_flex(initial_expected_open_date),
      initial_DEIS_date          = parse_date_flex(initial_DEIS_date)
    ) %>%
    mutate(delay = difftime(open_date, initial_expected_open_date))
  # Here I am converting these coordinates to geometric points
  station_poly <- st_as_sf(stations, coords = c("longitude", "latitude"), 
                           crs = 4326, agr = "constant")
  
  write_rds(station_poly, file = "3_output/1_cleaned_data/2_station_geographies/stations_timeline_comprehensive.rds")
  return(station_poly)
}