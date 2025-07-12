run_all = function(){
  answer <- readline(prompt = "Are you sure you want to run this? It will take a long time and will 
                     run all states and files. Type 'yes' to continue: ")
  
  if (tolower(answer) != "yes") {
    message("Aborted.")
    return(invisible(NULL))
  }
  
  # Here is functionally an order of operations for reproducing this repo
  source("2_code/1_function_library/run_all_functions.R")
  
  # Update the TCP data. This doesn't get updated too often, so not really necessary,
  # but doesn't take long. 
  source("2_code/2_cleaning/2_clean_TCP/update_TCP_data.R")
  update_TCP_data()
  
  # Update the CSV with all of the stations I've geolocated and matched w construction
  # delays. This is my manual work. 
  source("2_code/2_cleaning/1_clean_station_geographies/update_stations.R")
  update_stations()
  
  # Process the LODES origin-destination data
  source("2_code/2_cleaning/3_clean_LODES/LODEing_data.R")
  LODEing_data()
  
  # Calculate the worker flow numbers by Census tract, year, and state. 
  source("2_code/3_analysis/1_worker_flows/flow_calcs.R")
  flow_calcs()
  
  # Identify closest transit station to each Census tract 
  # Should make this into a for loop at some point
  source("2_code/3_analysis/2_routing/tract_station_pairings.R")
  tract_station_pairings(transit_system = "WMATA", map_title = "Census Tracts' Proximities to Closest Transit Station")
}

run_all()

# This is pretty much what I've got for now. The next step is standardizing the distance calculations analysis folder; 
# I think this is going to be very region-specific so I'll probably have a bunch 
# of state/system subfolders. Want to think about how to organize data wrangling vs image generation. Honestly 
# probably "analysis" is way too broad of a folder but for now it works. 