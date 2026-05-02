# Name: tract_station_pairings.R
# Purpose: For a given transit system, identify the region it falls in with a 
# square box. Pull the street network for that box. Overlay Census tracts from 
# all three vintages (2000, 2010, 2020) and save them as three distinct CSVs. 
# Calculate and write isochrones to identify tracts that corrolate to stations. 
# Last updated: Apr 17, 2026
# Preliminaries  --------
source("2_code/1_utilities/packages+defaults.R")
source("2_code/2_cleaning/1_clean_station_geographies/update_stations.R")

tract_station_pairings = function(transit_system, overwrite_all = F){
  # Register an on.exit handler so the r5r Java core is *always* stopped, even
  # if the function errors before reaching the explicit stop_r5() call below.
  # Without this, each failed iteration in "all" mode leaks a live Java core,
  # and subsequent setup_r5() calls accumulate on top of stale ones.
  r5r_core = NULL
  on.exit({
    if (!is.null(r5r_core)) {
      tryCatch(r5r::stop_r5(r5r_core), error = function(e) NULL)
      rJava::.jgc()
    }
  }, add = TRUE, after = TRUE)
  
  
  # Paths as strings
  data_in_path = paste0("1_data/2_station_geographies/")
  data_out_path = paste0("3_output/1_cleaned_data/2_station_geographies/", transit_system)
  dir.create(data_out_path, recursive = TRUE, showWarnings = FALSE)
  
  # Load state boundaries from tigris (covers all 50 states + DC, including Hawaii)
  # and spatial-join to identify which state each station falls in.
  usa = tigris::states(cb = TRUE) %>%
    st_transform(4326) %>%
    dplyr::select(state = STUSPS)
  
  sf_use_s2(FALSE)
  
  # Updating stations using our function previously defined in eponymous file.
  station_poly = update_stations() %>%
    st_join(usa) %>%
    # Focusing on one transit system at a time
    filter(system == transit_system) %>%
    # Drop any rows where spatial join didn't match a state (shouldn't happen, but safe)
    filter(!is.na(state))
  
  sf_use_s2(T)
  
  # Compute the affected bounding area once — used for the OSM clip below and
  # re-used inside the per-vintage tract loop to filter tracts to the metro area.
  affected_area = st_bbox(station_poly$geometry)
  affected_sfc  = (affected_area + c(-0.05, -0.05, 0.05, 0.05)) %>% st_as_sfc() %>% st_transform(4326)
  
  # Verify all OSM CLI tools are available before doing any work
  osmosis_path   = Sys.which("osmosis")[[1]]
  osmfilter_path = Sys.which("osmfilter")[[1]]
  osmconvert_path = Sys.which("osmconvert")[[1]]
  missing_tools = c(Osmosis = osmosis_path, OSMFilter = osmfilter_path, OSMConvert = osmconvert_path)
  missing_tools = names(missing_tools[missing_tools == ""])
  if (length(missing_tools) > 0)
    stop("Missing required CLI tools: ", paste(missing_tools, collapse = ", "))
  
  best_match = suppressMessages(oe_match(st_make_valid(affected_sfc)))
  message("Using Geofabrik extract for ", transit_system, ": ", best_match$url)
  
  large_pbf_path = paste(getwd(), data_in_path, basename(best_match$url), sep = "/")
  system_pbf     = paste(getwd(), data_out_path, paste0(transit_system, ".pbf"), sep = "/")
  
  # overwrite_all = TRUE forces a fresh download of the full Geofabrik extract.
  # The clipped system_pbf is always rebuilt whenever the large PBF is (re)downloaded.
  if(!file.exists(large_pbf_path) || file.size(large_pbf_path) < 1000 || overwrite_all){
    large_pbf_path = oe_download(best_match$url, download_directory = data_in_path,
                                 max_file_size = Inf)
    if(!file.exists(large_pbf_path))
      stop("Download of ", best_match$url, " failed. ",
           "Try downloading it manually and saving it as ", large_pbf_path, ".")
  }
  
  if(!file.exists(system_pbf) || file.size(system_pbf) < 1000 || overwrite_all){
    # Helper to run a system command and stop immediately on non-zero exit
    run_cmd = function(cmd, step){
      exit = system(cmd)
      if(exit != 0) stop(step, " failed (exit code ", exit, ").\nCommand was: ", cmd)
    }
    
    # Step 1: Clip large PBF to the bounding box, padded by ~5 km in each direction
    # so that isochrones from edge stations aren't cut off at the network boundary.
    # At walking speed (~5 km/h), a 30-min isochrone can reach ~2.5 km; 0.05 degrees
    # is ~5 km — enough headroom for the full walkable extent.
    osmosis_area = affected_area + c(-0.05, -0.05, 0.05, 0.05)
    osmosis_cmd = sprintf('%s --read-pbf "%s" --bounding-box left=%s bottom=%s right=%s top=%s --write-pbf "%s"',
                          osmosis_path, large_pbf_path,
                          osmosis_area["xmin"], osmosis_area["ymin"],
                          osmosis_area["xmax"], osmosis_area["ymax"],
                          system_pbf)
    run_cmd(osmosis_cmd, "osmosis bbox clip")
    if(file.size(system_pbf) < 1000)
      stop("osmosis produced an empty or near-empty PBF for ", transit_system,
           ". The bounding box may not overlap the extract — check that the correct PBF was downloaded.")
    
    # Steps 2–4: PBF → OSM → filter highways → PBF (reduces r5r network size)
    osm_path = str_replace(system_pbf, ".pbf", ".osm")
    newosm_path = paste(getwd(), data_in_path, "highways.osm", sep = "/")
    run_cmd(sprintf('osmconvert "%s" -o="%s"', system_pbf, osm_path),  "osmconvert pbf→osm")
    run_cmd(sprintf('osmfilter "%s" --keep="highway=" -o="%s"', osm_path, newosm_path), "osmfilter")
    if(file.size(newosm_path) < 1000)
      stop("osmfilter produced an empty result for ", transit_system,
           ". The clipped area may contain no highway features.")
    run_cmd(sprintf('osmconvert "%s" -o="%s"', newosm_path, system_pbf), "osmconvert osm→pbf")
  }
  
  # Setup elevation data
  elev = get_elev_raster(locations = affected_sfc %>% st_as_sf(), z = 10) 
  try(writeRaster(elev, paste0(data_out_path, '/elev.tif'), options = c('TFW=NO'), overwrite = overwrite_all)) %>%
    suppressWarnings() %>% suppressMessages()
  
  if (!file.exists(system_pbf) || file.size(system_pbf) < 1000)
    stop("PBF file for ", transit_system, " is missing or empty: ", system_pbf)
  
  r5r_core = setup_r5(data_path = data_out_path, verbose = FALSE, overwrite = overwrite_all)
  if(is.null(r5r_core) || !inherits(r5r_core, "jobjRef")){
    stop("setup_r5() failed for ", transit_system, " — check that the PBF file in ",
         data_out_path, " is valid and that Java has enough memory.")
  }
  
  # 2) load origin/destination points and set arguments
  stations = station_poly %>%
    mutate(lat = st_coordinates(geometry)[,2],
           lon = st_coordinates(geometry)[,1],
           id = station) 
  
  mode <- c("WALK")
  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                   format = "%d-%m-%Y %H:%M:%S", tz = 'America/New_York')
  
  origins_df = stations %>% subset(select = c(id, lon, lat))
  
  net = r5r::street_network_to_sf(r5r_core)
  
  # Keep only vertices that sit on at least one walkable edge
  walk_edges    = net$edges %>% dplyr::filter(walk == TRUE)
  walkable_vids = unique(c(walk_edges$from_vertex, walk_edges$to_vertex))
  walk_verts    = net$vertices %>% dplyr::filter(index %in% walkable_vids) %>%
    st_transform(4326)
  
  # Snap each origin to the nearest such vertex
  origins_sf     = st_as_sf(origins_df, coords = c("lon", "lat"), crs = 4326)
  nearest_idx    = st_nearest_feature(origins_sf, walk_verts)
  snapped_coords = st_coordinates(walk_verts)[nearest_idx, , drop = FALSE]
  origins_snapped = origins_df %>%
    mutate(lon = snapped_coords[, "X"],
           lat = snapped_coords[, "Y"])
  
  iso_poly <- isochrone(r5r_core = r5r_core, origins = origins_snapped, mode = mode,
                        polygon_output = TRUE, departure_datetime = departure_datetime,
                        cutoffs = c(5, 15, 30), verbose = FALSE)
  
  # Free the r5r core as soon as we're done with routing
  r5r::stop_r5(r5r_core)
  rJava::.jgc()
  r5r_core = NULL
  
  iso_geom_col = attr(iso_poly, "sf_column")
  
  # --- Loop over Census vintages -------------------------------------------
  # The street network (and therefore isochrones) is vintage-agnostic: we built
  # it once above from a contemporary OSM extract. All that changes per vintage
  # is which set of tract boundaries we use to label the isochrone polygons.
  #
  # tigris note: cb = TRUE (cartographic boundary files) is reliable for 2010
  # and 2020. For 2000, cb support is inconsistent across states in tigris, so
  # we fall back to the full TIGER/Line files (cb = FALSE).
  for (vintage in c(2000, 2010, 2020)) {
    message("  Processing Census vintage: ", vintage)
    
    cb_flag = vintage >= 2010
    
    metro_tracts_v <- map_dfr(unique(station_poly$state), ~{
      tracts(.x, year = vintage, cb = cb_flag)
    }, geometry = T) %>%
      st_transform(4326) %>%
      st_make_valid() %>%
      # Some Census vintages (e.g. 2010 GEO_ID) include a "1400000US" prefix —
      # strip it wherever it appears so tract IDs are consistently bare GEOIDs.
      mutate(across(where(is.character), ~str_remove(.x, "^1400000US")))
    
    # Clip to the metro area and remove water bodies for this vintage's boundaries
    affected_tracts_v <- metro_tracts_v[st_intersects(metro_tracts_v, affected_sfc, sparse = FALSE)[, 1], ] %>%
      erase_water()
    
    # Tag each isochrone polygon with the tract GEOIDs it overlaps (this vintage)
    iso_poly_v = iso_poly 
    if(vintage == 2020){
      iso_poly_v$tracts <- lapply(iso_poly_v[[iso_geom_col]], function(p) {
        metro_tracts_v$GEOID[st_intersects(p, metro_tracts_v$geometry)[[1]]]
      })
      iso_poly_v$state = lapply(iso_poly_v[[iso_geom_col]], function(p) {
        unique(metro_tracts_v$STATEFP[st_intersects(p, metro_tracts_v$geometry)[[1]]])
      })
    } else if(vintage == 2010){
      iso_poly_v$tracts <- lapply(iso_poly_v[[iso_geom_col]], function(p) {
        metro_tracts_v$GEO_ID[st_intersects(p, metro_tracts_v$geometry)[[1]]]
      })
      iso_poly_v$state = lapply(iso_poly_v[[iso_geom_col]], function(p) {
        unique(metro_tracts_v$STATEFP[st_intersects(p, metro_tracts_v$geometry)[[1]]])
      })
    } else{
      iso_poly_v$tracts <- lapply(iso_poly_v[[iso_geom_col]], function(p) {
        metro_tracts_v = metro_tracts_v %>% 
          mutate(GEO_ID = paste0(STATEFP00, COUNTYFP00, TRACTCE00))
        metro_tracts_v$GEO_ID[st_intersects(p, metro_tracts_v$geometry)[[1]]]
      })
      iso_poly_v$state = lapply(iso_poly_v[[iso_geom_col]], function(p) {
        metro_tracts_v$STATEFP00[st_intersects(p, metro_tracts_v$geometry)[[1]]]
      })
    }
    
    write_rds(iso_poly_v, file = paste0("3_output/1_cleaned_data/2_station_geographies/",
                                        transit_system, "_", vintage, "_tract_station_pairings.rds"))
    
    # Map for this vintage
    plot_v =
      ggplot() +
      geom_sf(data = affected_tracts_v, color = "black") +
      geom_sf(data = iso_poly_v, aes(fill = as.factor(isochrone)), color = "black") +
      geom_sf(data = stations, aes(color = "Station Location"), show.legend = TRUE) +
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
      labs(title = "Census Tracts' Proximities to Closest Transit Station",
           subtitle = paste0("Transit System: ", transit_system, ", open stations. Census vintage: ", vintage, "."))
    
    graph_path = paste0("3_output/2_figures/1_maps/1_station_geographies/", transit_system, "_", vintage, ".pdf")
    dir.create(dirname(graph_path), recursive = TRUE, showWarnings = FALSE)
    ggsave(filename = graph_path, plot_v)
    system(sprintf('pdfcrop "%s" "%s"', graph_path, graph_path))
  }
}

for(system in unique(all_stations$system)){
    tract_station_pairings(transit_system = system, overwrite_all = F)
  }
