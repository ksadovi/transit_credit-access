# Preliminaries  --------
source("2_code/1_utilities/packages+defaults.R")

# Aggregating station locations across systems  --------
# I have collected this data by hand in CSVs housed in 1_data/2_station_geographies/. I 
# will have one CSV per transit system I cover. I will continue to add to it as I incorporate 
# more transit systems into this analysis. I am making this a function so that it can be 
# called from any other file in this project, achieving easy updating for the stations whenever I add more.

update_stations = function(){
  stations = data.frame()
  for(i in list.files("1_data/2_station_geographies/", pattern = "*.csv")){
    stations = rbind(stations, fread(paste0("1_data/2_station_geographies/", i)))
  }
  stations = stations %>% 
    mutate(open_date = as.Date(stations$open_date, format = "%m/%d/%y")) %>%
    mutate(
      initial_expected_open_date = as.Date(initial_expected_open_date, format = "%m/%d/%y"),
      initial_DEIS_date          = as.Date(initial_DEIS_date,          format = "%m/%d/%y")
    ) %>%
    mutate(delay = difftime(open_date, initial_expected_open_date))
  # Here I am converting these coordinates to geometric points
  station_poly <- st_as_sf(stations, coords = c("longitude", "latitude"), 
                           crs = 4326, agr = "constant")
  
  write_rds(station_poly, file = "3_output/1_cleaned_data/2_station_geographies/stations_timeline_comprehensive.rds")
  return(station_poly)
}
