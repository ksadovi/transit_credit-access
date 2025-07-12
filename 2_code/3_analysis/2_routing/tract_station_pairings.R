source("2_code/packages+defaults.R")

tract_station_pairings = function(transit_system, rads = c(0.25,1), map_title = "Map title", year = 2024){
  stopifnot(length(rads) == 2)
  
  # Need to load the state geographies to identify which states we need to pull 
  # Census tracts from. 
  usa = st_as_sf(map("state", fill = T, plot = F)) %>%
    st_transform(4326) 
  
  # Updating stations using our function previously defined in eponymous file. 
  station_poly = update_stations() %>%
    st_join(usa) %>%
    # Focusing on one transit system at a time
    filter(system == transit_system & year(open_date)<=year) %>% 
    # We want to identify tracts which are close by and tracts that are farther 
    # by creating two buffers (circles) of different radii. This is imprecise and 
    # should be rewritten using the r5r package.
    mutate(station_buffers_small = st_buffer(geometry %>% st_transform(2264), min(rads)*5280) %>% st_transform(4326),
           station_buffers_big = st_buffer(geometry %>% st_transform(2264), max(rads)*5280) %>% st_transform(4326), 
           # Finding states for mapping
           state = append(state.abb, "DC")[match(str_to_title(ID), append(state.name, "District Of Columbia"))]) %>% 
    subset(select = -c(ID))
  
  # Grab tracts by state
  metro_tracts <- map_dfr(unique(station_poly$state), ~{
    tracts(.x, cb = TRUE, year = year)
  }, geometry = T) %>%
    st_transform(4326) 
  
  # Perform spatial join between tracts and station buffers
  tract_station_pairs_small <- st_join(metro_tracts, st_set_geometry(station_poly, "station_buffers_small"), 
                                       join = st_intersects)
  tract_station_pairs_big <- st_join(metro_tracts, st_set_geometry(station_poly, "station_buffers_big"), 
                                     join = st_intersects)
  
  # Now summarize to get station(s) per tract
  tract_station_summary_small <- tract_station_pairs_small %>%
    group_by(GEOID) %>%
    summarise(stations_close = paste(unique(station), collapse = ", "), .groups = "drop") %>%
    st_drop_geometry() %>%
    mutate(stations_close = ifelse(stations_close == "NA", NA, stations_close))
  
  tract_station_summary_big <- tract_station_pairs_big %>%
    group_by(GEOID) %>%
    summarise(stations_far = paste(unique(station), collapse = ", "), .groups = "drop") %>%
    st_drop_geometry() %>%
    mutate(stations_far = ifelse(stations_far == "NA", NA, stations_far))
  
  metro_tracts <- metro_tracts %>%
    left_join(tract_station_summary_small, by = "GEOID") %>%
    left_join(tract_station_summary_big, by = "GEOID") %>%
    mutate(station_proximity = ifelse(!is.na(stations_close), "<=0.25 miles", 
                                      ifelse(!is.na(stations_far), "<=1 mile", ">1 mile"))) %>%
    erase_water()
  
  write_rds(metro_tracts, file = "3_output/1_cleaned_data/2_station_geographies/tract_station_pairings.rds")
  
  # Let's calculate the ggplot coordinates we should use: 
  ggplot_borders = function(x, dim = "long"){
    stopifnot((dim %in% c("long", "lat")))
    dims = ifelse(dim == "long", 1, 2)
    
    extreme_coords = function(x, extreme){
      st_coordinates(x)[,dims] 
    }
    
    max = lapply(x, extreme_coords, extreme = max) %>% unlist %>% max
    min = lapply(x, extreme_coords, extreme = min) %>% unlist %>% min
    return(c(min, max))
  }
  plot = ggplot() +
    geom_sf(data = metro_tracts, color = "black", aes(fill = station_proximity)) +
    geom_sf(data = station_poly, color = "purple") +
    theme_classic() + 
    coord_sf(default_crs = sf::st_crs(4326),
             xlim = ggplot_borders(metro_tracts$geometry[which(!is.na(metro_tracts$stations_far))], dim = "long"),
             ylim = ggplot_borders(metro_tracts$geometry[which(!is.na(metro_tracts$stations_far))], dim = "lat")) + 
    guides(fill = guide_legend(title = "Proximity to Closest Station")) + 
    theme(legend.position = "bottom") + 
    labs(title = map_title, subtitle = paste0("Transit System: ", transit_system, ", open stations as of ", year))
  
  ggsave(filename = paste0("3_output/2_figures/1_maps/1_station_geographies/", transit_system, ".png"), plot)
}
# buffer of 50 miles around Raleigh city centre

