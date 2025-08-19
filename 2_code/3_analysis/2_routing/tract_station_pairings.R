# Name: 
# Purpose: 
# Last updated: 
# Preliminaries  --------
source("2_code/1_utilities/packages+defaults.R")

tract_station_pairings = function(transit_system, map_title = "Map title", year = 2024, 
                                  overwrite_all = F){
  # Paths as strings 
  data_in_path = paste0("1_data/2_station_geographies/") 
  data_out_path = paste0("3_output/1_cleaned_data/2_station_geographies/", transit_system)
  
  # Need to load the state geographies to identify which states we need to pull 
  # Census tracts from. 
  usa = st_as_sf(map("state", plot = F, fill = TRUE)) %>%
    st_transform(4326) 
  
  sf_use_s2(FALSE)
  # Updating stations using our function previously defined in eponymous file. 
  station_poly = update_stations() %>%
    st_join(usa) %>%
    # Focusing on one transit system at a time
    filter(system == transit_system & year(open_date) <= year) %>% 
    mutate(# Finding states for mapping
           state = append(state.abb, "DC")[match(str_to_title(ID), append(state.name, "District Of Columbia"))]) %>% 
    subset(select = -c(ID))
  
  sf_use_s2(T)
  
  # Grab tracts by state
  metro_tracts <- map_dfr(unique(station_poly$state), ~{
    tracts(.x, cb = TRUE, year = year)
  }, geometry = T) %>%
    st_transform(4326) 
  
  # Want to load the worker flow data because it's only worth looking at the stations
  # which have opened after the beginning of the LODES data. We do this because some 
  # metro areas are so large it's impossible to load, so this helps narrow the geographic
  # area down for the r5r package. 
  lodes_data = tibble()
  for(i in unique(station_poly$state)){
    lodes_data = read_rds(paste0("3_output/1_cleaned_data/3_LODES/2_workerflow_tabs/flows_tracts_", i, ".rds")) %>% 
      rbind(lodes_data)
  }
  first_lodes_year = min(lodes_data$census_year)
  
  affected_area = st_bbox(station_poly$geometry[which(year(as.Date(station_poly$initial_DEIS_date, format = "%m/%d/%y")) >= 
                                                       first_lodes_year)]) 
  
  affected_tracts <- metro_tracts[st_intersects(metro_tracts, affected_area %>% st_as_sfc %>%
                                              st_transform(4326) , sparse = FALSE)[,1], ] %>%
    erase_water(year = year)
  
  # Check that all of the relevant Open Street Maps packages are installed. 
  osmosis_path = Sys.which("osmosis")[[1]]
  osmfilter_path = Sys.which("osmfilter")[[1]]
  osmconvert_path = Sys.which("osmconvert")[[1]]
  necessary_packages = tibble(names = c("Osmosis", "OSMFilter", "OSMConvert"), 
                              paths = c(osmosis_path, osmfilter_path, osmconvert_path))
  if("" %in% necessary_packages$paths){
    stop(paste0("You need to install the following packages: ", paste0(necessary_packages$names[which(necessary_packages$paths == "")], collapse = ", "),"."))
  }
  
  large_pbf_path = paste(getwd(), data_in_path, basename(oe_match(affected_area)$url), sep = "/") %>% suppressMessages()
  # path where you want to save the smaller .pbf file
  smaller_pbf = paste(getwd(), data_out_path, paste0(transit_system, ".pbf"), sep = "/")
  
  # See if either of the above PBFs have already been downloaded. 
  if(!file.exists(smaller_pbf)){
    if(!file.exists(large_pbf_path)){
      if(oe_match(affected_area)[2] >= 1.5) {
        stop(paste0("The file you need is too big. Try downloading it from ", oe_match(affected_area)$url, " from your browser and save it as ", large_pbf_path, "."))
      }
      oe_download(oe_match(affected_area)$url, download_directory = data_path, max_file_size = 1.5, quiet = T)
    }
    # prepare call to osmosis
    osmosis_cmd = sprintf("%s --read-pbf %s --bounding-box left=%s bottom=%s right=%s top=%s --write-pbf %s",
                          osmosis_path, large_pbf_path, 
                          affected_area$xmin, affected_area$ymin, affected_area$xmax, affected_area$ymax,
                          smaller_pbf)
    
    osm_path = str_replace(smaller_pbf, ".pbf", ".osm")
    newosm_path = paste(getwd(), data_in_path, "highways.osm", sep = "/")
    osmconvert_cmd = sprintf("osmconvert %s -o=%s", 
                             smaller_pbf, osm_path)
    osmfilter_cmd = sprintf("osmfilter %s --keep='highway=' -o=%s", 
                            osm_path, newosm_path)
    osmconvertback_cmd = sprintf("osmconvert %s -o=%s", 
                                 newosm_path, smaller_pbf)
    
    # call to osmosis
    system(osmosis_cmd)
    system(osmconvert_cmd)
    system(osmfilter_cmd)
    system(osmconvertback_cmd)
  }
  
  
  
  ###################################################################################
  # 1.2 Setup elevation data 
  affected_area2 = affected_area %>% st_as_sfc() %>% st_as_sf()
  elev = get_elev_raster(locations = affected_area2, z = 10) # something's wrong here
  try(writeRaster(elev, paste0(data_out_path, '/elev.tif'), options=c('TFW=NO'), overwrite = overwrite_all)) %>% 
    suppressWarnings() %>% suppressMessages()
  # Setup r5r core
  r5r_core = setup_r5(data_path = data_out_path, verbose = F, overwrite = overwrite_all)
  
  # 2) load origin/destination points and set arguments
  stations = station_poly %>% 
    mutate(lat = st_coordinates(geometry)[,2], 
           lon = st_coordinates(geometry)[,1], 
           id = station) %>%
    #Really, we only care about the stations that opened after our first LODES observation 
    filter(year(as.Date(initial_DEIS_date, format = "%m/%d/%y")) >= first_lodes_year)
  
  mode <- c("WALK")
  max_walk_time <- 30 # minutes
  max_trip_duration <- max_walk_time # minutes
  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                   format = "%d-%m-%Y %H:%M:%S", tz = 'America/New_York')
  iso_poly <- isochrone(
    r5r_core = r5r_core,
    origins = stations %>% subset(select = c(id, lon, lat)),
    mode = mode,
    polygon_output = T,
    departure_datetime = departure_datetime, 
    cutoffs = c(5,15,30), verbose = F
  ) 
  
  iso_poly$tracts <- lapply(iso_poly$polygons, function(p) {
    metro_tracts$GEOID[st_intersects(p, metro_tracts$geometry)[[1]]]
  })
  
  merge = affected_tracts %>% st_drop_geometry() %>% 
    left_join(
      iso_poly %>%
        unnest(tracts) %>%
        pivot_wider(names_from = isochrone, 
                    values_from = id, 
                    names_prefix = "within_", 
                    values_fill = NA) %>% group_by(tracts) %>% 
        mutate(GEOID = tracts) %>% subset(select = -c(tracts)) %>% st_drop_geometry()
    ) %>% 
    left_join(metro_tracts) 
  
  write_rds(merge, file = paste0("3_output/1_cleaned_data/2_station_geographies/", transit_system, 
                                 "_tract_station_pairings.rds"))
  # plot
  plot = ggplot() +
    geom_sf(data = affected_tracts, color = "black") +
    geom_sf(data = stations, aes(color = "Station Location"), show.legend = TRUE) +
    geom_sf(data = iso_poly, aes(fill = as.factor(isochrone)), color = "black") + 
    scale_color_manual(values = c("Station Location" = "purple")) +
    theme_void() + 
    guides(
      fill = guide_legend(title = "Station Travel Time Isochrones", nrow = 1),
      color = guide_legend(title = "", override.aes = list(size = 4))
    ) +
    theme(
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.key.size = unit(0.5, "lines"),
      legend.text = element_text(size = 8)
    ) +
    labs(title = map_title, subtitle = paste0("Transit System: ", transit_system, ", open stations as of ", year))
  
  ggsave(filename = paste0("3_output/2_figures/1_maps/1_station_geographies/", transit_system, ".png"), plot)
}

