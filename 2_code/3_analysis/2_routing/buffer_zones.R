source("2_code/packages+defaults.R")
source("2_code/function_library/run_all_functions.R")

func = function(transit_system, rads = c(0.25,1), station_update = F){
  stopifnot(length(rads) == 2)
  station_poly = update_stations() %>% filter(system == transit_system) %>% 
    mutate(station_buffers_small = st_buffer(station_poly$geometry %>% st_transform(2264), min(rads)*5280) %>% st_transform(4326),
           station_buffers_big = st_buffer(station_poly$geometry %>% st_transform(2264), max(rads)*5280) %>% st_transform(4326)) %>% 
    mutate(tract_intersections_small = map(
      station_buffers_small,
      ~ dmv_tracts %>%
        filter(st_intersects(., .x, sparse = FALSE)) %>%
        pull(GEOID) %>% as.numeric),
      tract_intersections_big = map(
        station_buffers_big,
        ~ dmv_tracts %>%
          filter(st_intersects(., .x, sparse = FALSE)) %>%
          pull(GEOID) %>% as.numeric))
  dmv_tracts = dmv_tracts %>% mutate(near_station = ifelse(GEOID %in% unlist(station_poly$tract_intersections_small), "0.25", 
                                                           ifelse(GEOID %in% unlist(station_poly$tract_intersections_big), "1", NA)))
  # dc_metro_tracts <- dmv_tracts[dc_boundary, ] %>% 
  #   erase_water() 
  ggplot() +
    geom_sf(data = dmv_tracts, color = "black", aes(fill = near_station)) +
    geom_sf(data = dc_boundary, fill = NA, color = "blue") +
    geom_sf(data = bf, fill = NA, color = "darkgreen") + 
    geom_sf(data = station_poly, color = "purple") +
    theme_classic() +
    coord_sf(default_crs = sf::st_crs(4326),
             xlim = c(-77.5, -76.85),
             ylim = c(38.74, 39.2)
    )
}
# buffer of 50 miles around Raleigh city centre

