source("code/packages+defaults.R")
aux  = fread("data/LODES/raw_files/dc_od_aux_JT04_2021.csv") %>% as_tibble
main = fread("data/LODES/raw_files/dc_od_main_JT04_2021.csv") %>% as_tibble

crosswalk = fread("data/LODES/dc_xwalk.csv") %>% as_tibble
