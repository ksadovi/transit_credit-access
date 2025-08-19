# Name: 
# Purpose: 
# Last updated: 
# Preliminaries  --------
source("2_code/1_utilities/packages+defaults.R")

flow_calcs = function(states=c("all"), overwrite = F){
  states_preag = c()
  for(i in list.files("3_output/1_cleaned_data/3_LODES/1_preaggregated_metros/")){
    stat = str_extract(i, "(?<=_)[^_\\.]+(?=\\.)")
    states_preag = append(states_preag, stat)
  }
  states_completed = c()
  for(i in list.files("3_output/1_cleaned_data/3_LODES/2_workerflow_tabs/")){
    stat = str_extract(i, "(?<=_)[^_\\.]+(?=\\.)")
    states_completed = append(states_completed, stat)
  }
  if(overwrite == F){
    if((states %in% state.abb) == F & (states != c("all"))[1]) {
      stop("Error: You didn't error a correct state abbreviation or the string 'all'. Please check your argument inputs.")
    } else if((states != c("all"))[1]){
      states_new = setdiff(states, states_completed)
    } else if((states == c("all"))[1]){
      states_new = setdiff(states_preag, states_completed)
    }
  } else{ # the case where overwrite == T
    if((states %in% state.abb) == F & (states != c("all"))[1]) {
      stop("Error: You didn't error a correct state abbreviation or the string 'all'. Please check your argument inputs.")
    } else if((states != c("all"))[1]){
      states_new = states
    } else if((states == c("all"))[1]){
      states_new = states_preag
    }
  }
  for(i in states_new){
    blocks = read_rds(paste0("3_output/1_cleaned_data/3_LODES/1_preaggregated_metros/worker_flows_blocks_", i, ".rds"))
    # Outflows  --------
    # Here, I sum the number of people who live in each tract and go to work anywhere 
    # (including in their own home tract). Since I've included main and aux LODES files
    # in this, this often means that it includes people who live very far outside of the 
    # metro. For example, the Illinois file contains at least one tract from Delaware 
    # indicating that one person's residence was in Delaware but they worked in Chicago. 
    # This type of observation isn't really of interest here for the purposes of urban
    # and spatial econ. I deal with this in later files. 
    # Outflows --------
    outflows_main = blocks %>% filter(h_geocode != w_geocode) %>% 
      mutate(h_tract = substr(h_geocode, start = 1, stop = 11) %>% as.factor, 
             S000 = as.numeric(S000)) %>% subset(select = -c(w_geocode))
    outflows_tab = aggregate(S000 ~ h_tract + census_year, data = outflows_main, FUN = sum) %>% 
      mutate(outflows = S000, tract = h_tract) %>% subset(select = -c(S000, h_tract))
    
    # Inflows --------
    inflows_main = blocks %>% filter(h_geocode != w_geocode) %>% 
      mutate(w_tract = substr(w_geocode, start = 1, stop = 11) %>% as.factor, 
             S000 = as.numeric(S000)) %>% subset(select = -c(h_geocode))
    inflows_tab = aggregate(S000 ~ w_tract + census_year, data = inflows_main, FUN = sum) %>% 
      mutate(inflows = S000, tract = w_tract) %>% subset(select = -c(S000, w_tract))
    
    # All flows  --------
    flows = inflows_tab %>% full_join(outflows_tab) %>% 
      mutate(inflows = ifelse(is.na(inflows), 0, inflows), 
             outflows = ifelse(is.na(outflows), 0, outflows)) 
      # There are quite a few census blocks with 0 inflows -- this makes sense, these would be 
      # neighborhoods that are primarily residential where no one works. I'm not too concerned 
      # about this. 
    
    write_rds(x = flows, file = paste0("3_output/1_cleaned_data/3_LODES/2_workerflow_tabs/flows_tracts_", i, ".rds"))
  }
}
  

