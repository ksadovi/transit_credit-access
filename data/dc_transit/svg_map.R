######################
##   HOUSEKEEPING   ##
######################

# Loading libraries

library(readxl)
library(dplyr)
library(tidyr)
library(psych)
library(ggplot2)
library(RColorBrewer)
library(sp)
library(broom)
library(sf)
library(scales)
library(viridis)
library(data.table)
library(ggpubr)
library(ggmap)
library(maps)
library(mapdata)
library(ggrepel)
library(table1)
library(stringr) 
library(fixest)
library(stats)
library(lubridate)
library(gtools)
# library(devtools)
library(cowplot)

# if (!require("ggsflabel")) devtools::install_github("yutannihilation/ggsflabel")

# Color palette 
col_light = "#b1f2ff"
col_white = "white"
col_black = "black"
col_grey_dark = "grey20"
col_grey_med = "grey40"
col_grey_light = "grey80"
col_grey_lightest = "grey85"
pal <- c("lightskyblue2", "steelblue2", "dodgerblue2", "dodgerblue3", "dodgerblue4", "darkblue")


# Setting directories - change these to your local directory

path <- getwd()
dc_tracts <- paste0(path,'/dc_tracts', sep = "/")
transt   <- paste0(path, '/dc_transit', sep = "/")

## loading shape files

map_tracts <- st_read(paste0(dc_tracts, 
                           "Census_Tracts_in_2010.shp"))
map_transt <- st_read(paste0(transt, 
                            "washington_dc.shp"))

trsit_vals = tibble(map_transt$transit,map_transt$geometry)
map_tracts = left_join(map_tracts, trsit_vals, by = geometry)


# map_transt %>%
  ggplot() +
  geom_sf(data = map_tracts, fill = NA) + 
  geom_sf(data = map_transt, size = 0.01, aes(color = transit))+
  # geom_sf(data = map_adm1,
  #         size = .5,
  #         color = col_grey_med,
  #         fill = NA) +
  # geom_sf(data = map_adm0,
  #         size = .5,
  #         color = col_black,
  #         fill = NA) +
  theme_void() + 
  scale_fill_viridis()


#  Saint Vincent and The Grenadines

map_adm1 <- st_read(paste0(mappath,"/", 
                           "vct_admbnda_adm1_2021.shp"))
map_adm0 <- st_read(paste0(mappath,"/", 
                           "vct_admbnda_adm0_2021.shp"))
map_health <- st_read(paste0(mappath,"/",
                             "hotosm-vct-Health-Facilities-point_56119203-fc25-466d-8ec3-85f914b864fc_shp_point.shp"))

# Let's set coordinates for the inset map for Kingstown
xmin = -61.23 
ymin = 13.15
xmax = -61.222
ymax = 13.158

# First, we make the main map

main_map <- map_health %>%
  ggplot(aes(geometry=geometry)) +
  

  
  # This draws a dark line around the national borders

  geom_sf(data = map_adm0,
          size = 6,
          alpha = 0.03,
          color = col_light,
          fill = NA) +
    geom_sf(data = map_adm0,
          size = 5,
          color = col_white,
          fill = NA) +
  geom_sf(data = map_adm0,
          size = 4,
          alpha = 0.03,
          color = col_light,
          fill = NA) +
  geom_sf(data = map_adm0,
          size = 2.5,
          color = col_white,
          fill = NA) +
  geom_sf(data = map_adm0,
          size = 2,
          alpha = 0.03,
          color = col_light,
          fill = NA) +
  geom_sf(data = map_adm0,
          size = 0.5,
          color = col_white,
          fill = NA) +
  geom_sf(data = map_adm0,
          size = 0.2,
          color = col_black,
          fill = col_white) +  
  # This draws light borders around the subnational units
  geom_sf(data = map_adm1,
          size = 0.2,
          color = col_grey_med,
          fill = col_white) +
  # This adds the names of the subnational units to the map
  geom_sf_text(data = map_adm1, aes(label = toupper(ADM1_EN)),
               size = 1.5, color = col_grey_med) +
  
  # Here, health facilities are colored by the type of service they provide
  
  geom_sf(alpha = .8, aes(color = amenity)) +
  theme_void()+
  theme(legend.position = "left") +
  labs(title = "Map of health facilities",
       color = "Name") +
  
  # Here, we make the ocean blue
  # theme(panel.background = element_rect(fill = col_light)) +
  
  # This section draws a box around the Kingstown inset
  geom_rect(
    xmin = xmin,
    ymin = ymin,
    xmax = xmax,
    ymax = ymax,
    fill = NA, 
    colour = col_black,
    size = 0.7
  ) + 
  scale_alpha_continuous(range = c(0,1))



combo_map <- ggdraw(main_map) +
  
  # Let's create an inset map for Kingstown
  
  draw_plot(
    {
      main_map + 
        coord_sf(
          xlim = c(xmin, xmax),
          ylim = c(ymin, ymax),
          expand = FALSE) +
        theme(legend.position = "none") +
        theme(plot.caption = element_text(color = col_black, face = "italic")
        ) +
        labs(caption = "Kingstown", title = "")
    },
    # The distance along a (0,1) x-axis to draw the left edge of the plot
    x = 0.38,
    # The distance along a (0,1) y-axis to draw the bottom edge of the plot
    y = 0.55,
    # The width and height of the plot expressed as proportion of the entire ggdraw object
    width = 0.2, 
    height = 0.2)

ggsave(filename = "svg_map.jpg", plot = combo_map,
       path = path,
       width = 7,
       height = 8)


## Generate PPT editable map

library(officer)
library(here)
library(rvg)



p_dml <- rvg::dml(ggobj = main_map)

# initialize PowerPoint slide ----
officer::read_pptx() %>%
  # add slide ----
officer::add_slide() %>%
  # specify object and location of object ----
officer::ph_with(p_dml, ph_location(
  width = 10, height = 6)) %>%
  # export slide -----
base::print(
  target = here::here(
    path,
    "svg_map.pptx"
  )
)



