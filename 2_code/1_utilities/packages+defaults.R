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
library(rJava)
library(rJavaEnv)
library(osmextract)
library(raster)
library(elevatr)
###### allocate RAM memory to Java **before** loading the {r5r} library
options(java.parameters = "-Xmx64G")
# check version of Java currently installed (if any) 
if(java_check_version_rjava() == F){
  # install Java 21
  java_quick_install(version = 21)
}
library(r5r)
options(tigris_use_cache = TRUE)
Sys.which(c("osmosis", "osmfilter", "osmconvert", "fake"))
# Be sure to have a Census API key before running this code! 