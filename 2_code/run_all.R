# Here is functionally an order of operations for reproducing this repo
source("2_code/1_function_library/run_all_functions.R")

# Update the CSV with all of the stations I've geolocated and matched w construction
# delays. This is my manual work. 
source("2_code/2_cleaning/1_clean_station_geographies/update_stations.R")
update_stations()

# Update the CSV with the most updated version of the TCP data. 
source("2_code/2_cleaning/2_clean_TCP/transit_costs.R")

# Process the LODES origin-destination data
source("2_code/2_cleaning/3_clean_LODES/LODEing_data.R")

# This is pretty much what I've got for now. The next step is standardizing the distance calculations and buffer
# zones in the analysis folder; I think this is going to be very region-specific so I'll probably have a bunch 
# of state/system subfolders. Want to think about how to organize data wrangling vs image generation. Honestly 
# probably "analysis" is way too broad of a folder but for now it works. 