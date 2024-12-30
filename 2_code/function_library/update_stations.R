# Preliminaries  --------
source("2_code/packages+defaults.R")
path_in = "3_output/cleaned_data/LODES/"
path_out = "3_output/"

# Aggregating station locations across systems  --------
# I have collected this data by hand in the CSV that is called. I will continue to add 
# to it as I incorporate more transit systems into this analysis. I am making this a 
# function so that it can be called from any other file in this project, achieving easy 
# updating for the stations whenever I add more.

update_stations = function(){
  stations = data.frame()
  for(i in list.files("1_data/station_geographies")){
    stations = rbind(stations, fread(paste0("1_data/station_geographies/", i)))
  }
  
  # Here I am converting these coordinates to geometric points
  station_poly <- st_as_sf(stations, coords = c("longitude", "latitude"), 
                           crs = 4326, agr = "constant")
  
  fwrite(stations, file = "3_output/cleaned_data/station_polygons.csv")
  return(station_poly)
}
