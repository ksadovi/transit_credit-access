# Name: LODEing_data.R 
# Purpose: Creates a function that loads LODES data by state required, cleans
# it a bit, and saves it as an RDS file.
# Last updated: 7/9/2025

# Preliminaries  --------
source("2_code/packages+defaults.R")

# Load LODES data --------
# This function allows the user to specify the states she wishes to save LODES
# data from, clean it, and save it as an RDS file in the output subdirectory. My
# intent here was to allow the user to combine states which will appear in a 
# given metro (for example, DC, MD, VA, and WV in the DC metro area) and save 
# that as a single RDS file to be used later. 
# Note that this data is at the Census block level. 
LODEing_data = function(states, metro_name){
  dat = data.frame() %>% as_tibble()
  for(i in list.files(paste0("1_data/3_LODES/1_raw_files/", states), recursive = T, pattern = "*.csv", full.names = T)){
    df = fread(i) %>% as_tibble %>% 
      mutate(census_year = as.numeric(str_sub(i, start = -8, end = -5)), 
             w_geocode = as.character(w_geocode), 
             h_geocode = as.character(h_geocode)) %>% 
      subset(select = c(w_geocode, h_geocode, S000, census_year))
    dat = rbind(dat, df)
    rm(df)
  }
  saveRDS(dat, file = paste0("3_output/1_cleaned_data/3_LODES/", "worker_flows_blocks_", metro_name, ".rds"))
  return(dat)
}

# Note that LODES only started to add federal jobs in 2010, so this really throws off the worker counts for 
# the DC area.
DMV_LODES_blocks = LODEing_data(c("WV", "VA", "DC", "MD"), "DMV")
IL_LODES_blocks = LODEing_data(c("IL"), "IL")

# Sanity Check: --------
# Here I'm calculating the number of employed people who live in one of the Hyde 
# Park census tracts in Chicago. I'm checking this against this source, and it seems
# approximately correct: 
# https://datacommons.org/browser/geoId/17031410200?statVar=Count_Person_Years16Onwards_Employed_ResidesInHousehold

# IL_LODES_blocks = read_rds("3_output/1_cleaned_data/3_LODES/worker_flows_blocks_IL.rds")
# hp_home_tract = IL_LODES_blocks %>% filter(substr(h_geocode, start = 1, stop = 11) == '17031410200') %>% 
#   aggregate(S000 ~ census_year, FUN = sum)
# ggplot(data = hp_home_tract) +
#   geom_line(aes(x = census_year, y = S000)) +
#   labs(y = "Number of workers", x = "Year", title = "Employed Residents of Hyde Park, Chicago",
#        subtitle = "Census Tract No. 17031410200") +
#   theme_classic()
