### This rly needs to be updated and I need to come up with better ways to do this 


# Name: worker_flows.R 
# Purpose: Clean LODES data and calculate worker flows by Census tract
# Last updated: 1/5/2025
# Preliminaries  --------
source("2_code/packages+defaults.R")

# Data: Worker Flows --------

## Load LODES data --------
# Here, I recursively search through the raw data folder and load all of the states with data 
# I've downloaded from Census. I save this as the object DMVW_full_state_tracts, which is a 
# dataframe showing the number of workers in a unique residence-workplace tract pair in a 
# specific year. 
# For example, the tract containing the national mall has 0 residential inhabitants and 
DMVW_full_state_tracts = data.frame() %>% as_tibble()
for(i in dir("1_data/3_LODES/1_raw_files/", recursive = T, pattern = "*.csv")){
  df = fread(paste0("1_data/3_LODES/1_raw_files/",i)) %>% as_tibble %>% 
    mutate(census_year = as.numeric(str_sub(i, start = -8, end = -5))) %>% 
    subset(select = c(w_geocode, h_geocode, S000, census_year))
  DMVW_full_state_tracts = rbind(DMVW_full_state_tracts, df)
  rm(df)
}

# Example code for checking: 
gwu_work_tract = (DMVW_full_state_tracts %>% filter(substr(w_geocode, start = 1, stop = 11) == 11001010800)) 
gwu_home_tract = (DMVW_full_state_tracts %>% filter(substr(h_geocode, start = 1, stop = 11) == 11001010800)) 
gwu_work_tract_count = aggregate(data = gwu_work_tract, S000 ~ census_year, FUN = sum) %>% 
  mutate(home_is = "Outside FB")
gwu_home_tract_count = aggregate(data = gwu_home_tract, S000 ~ census_year, FUN = sum) %>% 
  mutate(home_is = "Foggy Bottom")
gwu_tract_count = rbind(gwu_home_tract_count, gwu_work_tract_count)
ggplot(data = gwu_tract_count) + 
  geom_line(aes(x = census_year, y = S000, color = home_is)) + 
  labs(y = "Number of workers", x = "Year", title = "Workers in Foggy Bottom") + 
  guides(color=guide_legend(title="Resident of:")) + 
  theme(legend.position.inside = c(.8,.5)) + 
  theme_classic() + 
  geom_vline(xintercept = 2020)
# Seems right to me. 

## Crosswalks --------
crosswalk = data.frame()
for(i in list.files("1_data/3_LODES/2_crosswalks/", pattern = "*_xwalk.csv")){
  crosswalk = rbind(crosswalk, fread(paste0("1_data/3_LODES/2_crosswalks/", i)))
}

# Here, I only want to keep the Census tract code ('trct') and the 2020 Census
# Tabulation Block Code ('tabblk2020')
crosswalk = crosswalk %>% subset(select = c(tabblk2020, trct)) %>% 
  as_tibble %>% 
  mutate(tabblk2020 = as.factor(tabblk2020), 
         w_geocode = as.factor(tabblk2020), 
         trct = as.factor(trct))

# Need to align the name of the Census Block Code in the Crosswalk with the one in 
# the actual dataset. 
colnames(crosswalk) = c("h_geocode", "tract", "w_geocode")

# Outflows  --------
# Here, I sum the number of people who live in each tract and go to work anywhere 
# (including in their own home tract). 
outflows_main = DMVW_full_state_tracts %>% subset(select = c(h_geocode, S000)) %>% 
  mutate(h_geocode = as.factor(h_geocode), 
         S000 = as.numeric(S000))

outflows_main = aggregate(S000 ~ h_geocode, data = outflows_main, FUN = sum) %>% 
  left_join(crosswalk) %>% na.omit %>% subset(select = c(h_geocode, tract, S000)) # I'm losing a lot of data here. I think this is because it includes people who live or work outside the DMV, so it doesn't actually matter that much. But there are probably some marginal cases worth checking. 
colnames(outflows_main) = c("geocode", "tract", "outflows")

# Inflows  --------

inflows_main = DMVW_full_state_tracts %>% subset(select = c(w_geocode, S000)) %>% 
  mutate(w_geocode = as.factor(w_geocode), 
         S000 = as.numeric(S000))

inflows_main = aggregate(S000 ~ w_geocode, data = inflows_main, FUN = sum) %>% 
  left_join(crosswalk, by = 'w_geocode') %>% subset(select = c(w_geocode, tract, S000))
colnames(inflows_main) = c("geocode", "tract", "inflows")

# Scale by population --------
# The actual scaling happens in the next chunk, this is just grabbing population data
population <- get_decennial(
  geography = "tract",
  variables = "P1_001N",
  state = str_sub(list.files("1_data/3_LODES/2_crosswalks/", full.names = F), start = 1, end = 2) %>% toupper() %>% unique, 
  year = 2020,
  geometry = TRUE
) %>% as_tibble %>% 
  mutate(pop = as.numeric(value), 
         GEOID = as.factor(GEOID)) %>% 
  subset(select = c(GEOID, value))

# All flows  --------

flows = outflows_main %>% left_join(inflows_main) %>% 
  mutate(inflows = ifelse(is.na(inflows), 0, inflows), 
         outflows = ifelse(is.na(outflows), 0, outflows)) %>%
  # Need to aggregate again because was disaggregated by census block before which is too fine 
  aggregate(cbind(inflows, outflows) ~ tract, FUN = sum) %>% 
  mutate(flows = inflows - outflows)
colnames(flows) = c("GEOID", "inflows", "outflows","flows") 
flows = flows %>% left_join(population) %>% 
  mutate(out_scaled = outflows/value, 
         in_scaled = inflows/value, 
         flow_scaled = flows/value, 
         population = value, 
         tract = GEOID) %>% subset(select = -c(value, GEOID))

fwrite(flows, file = "3_output/1_cleaned_data/3_LODES/worker_flows.csv")

# Cleanup --------
# Removing all objects generated by this file that won't be necessary elsewhere
try(rm(i, population, crosswalk, inflows_main, outflows_main, DMVW_full_state_tracts, flows)) %>% 
  suppressWarnings()

