source("2_code/packages+defaults.R")
source("2_code/function_library/run_all_functions.R")
stations = fread("3_output/cleaned_data/station_polygons.csv") %>% as_tibble
station_poly = update_stations()

library(sf)
library(dplyr)
library(ggplot2)
library(tidycensus)

source("2_code/figures/maps/DMV_flows.R")

# buffer of 50 miles around Raleigh city centre
station_poly = update_stations()
bf = st_buffer(station_poly$geometry %>% st_transform(2264), .25*5280) %>% st_transform(4326)

# intersection with buffer as a polygon
near_brookland <- ifelse(sf::st_intersects(dmv_tracts, bf, sparse = F), 
                                 TRUE, 
                                 FALSE)
dmv_tracts = dmv_tracts %>% mutate(near_bkld = near_brookland)
dc_metro_tracts <- dmv_tracts[dc_boundary, ] %>% 
  erase_water() 
ggplot() +
  geom_sf(data = dmv_tracts, color = "black") + #, aes(fill = near_bkld)) +
  geom_sf(data = dc_boundary, fill = NA, color = "blue") +
  geom_sf(data = bf, fill = NA, color = "darkgreen") + 
  geom_sf(data = station_poly, fill = "red", color = "red") +
  theme_classic() +
  coord_sf(default_crs = sf::st_crs(4326),
           xlim = c(-77.17, -76.92),
           ylim = c(38.8, 39.0)
  )
