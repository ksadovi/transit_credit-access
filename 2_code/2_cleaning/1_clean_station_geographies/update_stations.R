# Preliminaries  --------
source("2_code/packages+defaults.R")

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
    mutate(open_date = as.Date(stations$open_date, format = "%m/%d/%y"))
  # Here I am converting these coordinates to geometric points
  station_poly <- st_as_sf(stations, coords = c("longitude", "latitude"), 
                           crs = 4326, agr = "constant")
  
  fwrite(stations, file = "3_output/1_cleaned_data/2_station_geographies/stations_timeline_comprehensive.csv")
  return(station_poly)
}
