library(tidyverse)
library(data.table)
library(readxl)
library(janitor)
library(tidycensus)
library(tmap)
library(osrm)
library(sf)
library(tmaptools)
options(tigris_use_cache = TRUE)

# Census Data API key
# census_api_key("195869cb0610c91bd120c0c19a46f6560d3a3961", install = T)
