library(tidyverse)
library(data.table)
library(readxl)
library(janitor)
library(maps)
library(tidycensus)
library(tmap)
library(osrm)
library(tigris)
library(sf)
library(tmaptools)
options(tigris_use_cache = TRUE)

# Be sure to have a Census API key before running this code! 