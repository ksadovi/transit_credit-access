# This file contains a function that can load new Transit Costs Project data and saves it as a CSV. 
# Then it wrangles and cleans the data and produces new CSVs in the 3_output/TSP folder. For more info
# on the Transit Costs Project, see their website: https://transitcosts.com/data/

#################
# Preliminaries #
#################
source("2_code/packages+defaults.R")
library(googledrive)
path_in = "1_data/TCP/"
path_out = "3_output/TCP/"

#############################
# Load Newest Transit Data? #
#############################

load_tcp = function(execute){
  if(tolower(execute) %in% c("yes", "y")){
    src_file = as_id('https://docs.google.com/spreadsheets/d/16GoHcbW-eVzHUUP_XCWVXS1s_i3ZBnmZh4kvdSX7muU/edit?gid=1828904092#gid=1828904092')
    drive_download(src_file, path = paste0(path_in, "transit_projects.csv"), overwrite = T)
    drive_download(src_file, path = paste0(path_in, "transit_projects.xlsx"), overwrite = T)
    
    dict = read_xlsx(paste0(path_in, "transit_projects.xlsx"), sheet = 6) %>% as_tibble
    fwrite(dict, file = "4_data_dictionaries/TCP_dictionary.csv")
    file.remove(paste0(path_in, "transit_projects.xlsx"))
  }
}

########################
# Wrangle Transit Data #
########################

tcp = fread(paste0(path_in, "transit_projects.csv")) %>% as_tibble 
tcp_fin = tcp[,2:ncol(tcp)] %>% row_to_names(row_number = 1) 
colnames(tcp_fin) = c("country", "city", "line", "phase", "start_yr", "end_yr", "rr", "length", 
                      "tunnel_per", "tunnel", "elevated", "at_grade", "stations", "platform_length", 
                      "source1", "cost", "currency", "yr", "ppp_rate", "real_cost", "cost_km",
                      "cheap", "clength", "ctunnel", "anglo", "infl_ind", "real_cost_23", "real_cost_km_23", 
                      "source2", "ref", "src_link", "addl_src_link")
tcp_fin$tunnel_per = tcp_fin$tunnel_per %>% str_remove_all("%")
cols_num = c("start_yr", "end_yr", "length", "tunnel_per", "tunnel", "elevated", "at_grade", 
             "stations", "platform_length", "cost", "yr", "ppp_rate", "real_cost", "cost_km", 
             "clength", "ctunnel", "infl_ind", "real_cost_23", "real_cost_km_23")
tcp_fin[cols_num] = sapply(tcp_fin[cols_num], as.numeric) %>% suppressWarnings()
rm(tcp, cols_num)

########################
# Produce Transit Data # 
########################
us_transit = tcp_fin %>% filter(country == "US" & start_yr >= 2000) %>% subset(select = -c(country))
fwrite(tcp_fin, file = paste0(path_out, "all_transit.csv"))
fwrite(us_transit, file = paste0(path_out, "us_transit.csv"))
rm(tcp_fin, us_transit, path_in,path_out)
