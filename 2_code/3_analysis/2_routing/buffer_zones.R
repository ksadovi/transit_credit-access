source("2_code/packages+defaults.R")
source("2_code/function_library/run_all_functions.R")

# buffer of 50 miles around Raleigh city centre
station_poly = update_stations() %>% 
  mutate(station_buffers = st_buffer(station_poly$geometry %>% st_transform(2264), .25*5280) %>% st_transform(4326)) %>% 
  mutate(tract_intersections = map(
    station_buffers,
    ~ dmv_tracts %>%
      filter(st_intersects(., .x, sparse = FALSE)) %>%
      pull(GEOID)))

# intersection with buffer as a polygon
near_brookland <- ifelse(sf::st_intersects(dmv_tracts, station_poly$station_buffers[which(station_poly$station == "Brookland-CUA")], sparse = F), 
                                 TRUE, 
                                 FALSE)
dmv_tracts = dmv_tracts %>% mutate(near_station = ifelse(GEOID %in% station_poly$tract_intersections, T, F))
# dc_metro_tracts <- dmv_tracts[dc_boundary, ] %>% 
#   erase_water() 
ggplot() +
  geom_sf(data = dmv_tracts, color = "black", aes(fill = near_station)) +
  geom_sf(data = dc_boundary, fill = NA, color = "blue") +
  geom_sf(data = bf, fill = NA, color = "darkgreen") + 
  geom_sf(data = station_poly, color = "purple") +
  theme_classic() +
  coord_sf(default_crs = sf::st_crs(4326),
           xlim = c(-77.17, -76.92),
           ylim = c(38.8, 39.0)
  )
