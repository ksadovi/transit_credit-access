# This file contains a function that can load new Transit Costs Project data and saves it as a CSV. 
# Then it wrangles and cleans the data and produces new CSVs in the 3_output/TSP folder. For more info
# on the Transit Costs Project, see their website: https://transitcosts.com/data/ or their permanent 
# data-access URL: https://ultraviolet.library.nyu.edu/records/9wnjp-kez15.

#################
# Preliminaries #
#################
source("2_code/packages+defaults.R")

update_TCP_data = function(){
  ############################
  # Load Newest Transit Data #
  ############################
  path_in = "1_data/1_TCP/"
  path_out = "3_output/1_cleaned_data/1_TCP/"
  
  url = "https://ultraviolet.library.nyu.edu/records/9wnjp-kez15/files/Merged-Costs-1-4.csv"
  file_name = "transit_projects.csv"
  file_path = file.path(getwd(), path_in)
  
  download.file(url = url, destfile = paste0(file_path, file_name, sep = ""))
  
  ########################
  # Wrangle Transit Data #
  ########################
  
  tcp = fread(paste0(path_in, "transit_projects.csv")) %>% as_tibble 
  
  ########################
  # Produce Transit Data # 
  ########################
  us_transit = tcp %>% filter(Country == "US" & Start_year >= 2000) %>% subset(select = -c(Country))
  fwrite(tcp, file = paste0(path_out, "all_transit.csv"))
  fwrite(us_transit, file = paste0(path_out, "us_transit.csv"))
}
