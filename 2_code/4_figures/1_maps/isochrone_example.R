# Name: isochrone_example.R
# Purpose: Clean single-station isochrone figure for paper
# Shows 5/15/30-min walking isochrones for one MBTA station
# Last updated: Oct 2, 2026

source("2_code/1_utilities/packages+defaults.R")

# ── Parameters ────────────────────────────────────────────────────────────────
chosen_station  <- "Kenmore"   # change to any station name in MBTA_stations.csv
transit_system  <- "MBTA"
census_vintage  <- 2020

out_path <- "3_output/2_figures/1_maps/1_station_geographies/isochrone_example.pdf"
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

# ── Load data ─────────────────────────────────────────────────────────────────
iso_all <- read_rds(paste0(
  "3_output/1_cleaned_data/2_station_geographies/",
  transit_system, "_", census_vintage, "_tract_station_pairings.rds"
))

# Filter to the one station we want
iso_station <- iso_all %>%
  filter(id == chosen_station)

if (nrow(iso_station) == 0)
  stop("Station '", chosen_station, "' not found. Check spelling against MBTA_stations.csv.")

# Station point (centroid of the innermost isochrone)
station_pt <- iso_station %>%
  filter(isochrone == min(isochrone)) %>%
  st_centroid()

# ── Pull census tracts for context ────────────────────────────────────────────
# Clip to a generous buffer around the isochrones so we get enough road/tract
# context without showing the entire metro area.
iso_bbox    <- st_bbox(iso_station %>% filter(isochrone == max(isochrone)))
buffer_deg  <- 0.02   # ~2 km padding around the outermost isochrone

context_bbox <- iso_bbox + c(-buffer_deg, -buffer_deg, buffer_deg, buffer_deg)
context_sfc  <- context_bbox %>% st_as_sfc() %>% st_set_crs(4326)

# Suffolk + Middlesex + Norfolk counties cover central Boston / Cambridge area
# (adjust if switching to a station far outside this corridor)
tracts_ma <- tracts("MA", cb = TRUE, year = census_vintage) %>%
  st_transform(4326) %>%
  st_make_valid()

tracts_context <- tracts_ma[
  st_intersects(tracts_ma, context_sfc, sparse = FALSE)[, 1], ]

# Water erase for cleaner boundaries
tracts_context <- erase_water(tracts_context)

# ── Labels for isochrone bands ─────────────────────────────────────────────────
iso_labels <- c("5" = "0–5 min walk",
                "15" = "5–15 min walk",
                "30" = "15–30 min walk")

iso_station <- iso_station %>%
  mutate(band = factor(iso_labels[as.character(isochrone)],
                       levels = iso_labels))

# ── Plot ──────────────────────────────────────────────────────────────────────
# Color palette: light to dark for increasing distance bands
band_colors <- c("0–5 min walk"   = "#9C2007",
                 "5–15 min walk"  = "#F54927",
                 "15–30 min walk" = "#FAA18F")

p = ggplot() +
  # Tract outlines for geographic context
  geom_sf(data = tracts_context,
          fill = "#FFEAB8", color = "grey70", linewidth = 0.25) +
  # Isochrone polygons, plotted outermost first so inner rings sit on top
  geom_sf(data = iso_station %>% arrange(desc(isochrone)),
          aes(fill = band),
          color = "white", linewidth = 0.4, alpha = 0.85) +
  # Station location
  geom_sf(data = station_pt,
          shape = 21, size = 3, stroke = 1.2,
          fill = "white", color = "#1a1a1a") +
  # Station label
  geom_sf_label(data = station_pt,
                label = chosen_station,
                nudge_y = 0.005,
                size = 2.8, fontface = "bold",
                label.size = 0, fill = alpha("white", 0.8)) +
  scale_fill_manual(values = band_colors, name = "Walking distance") +
  coord_sf(xlim = c(context_bbox["xmin"], context_bbox["xmax"]),
           ylim = c(context_bbox["ymin"], context_bbox["ymax"]),
           expand = FALSE) +
  theme_void(base_size = 11) +
  theme(
    legend.position      = "bottom",
    legend.title         = element_text(size = 9, face = "bold"),
    legend.text          = element_text(size = 8),
    legend.key.size      = unit(0.8, "lines"),
    plot.margin          = margin(6, 6, 6, 6), 
    panel.background = element_rect(fill = "#c6e8f0", color = NA)
  ) +
  labs(caption = paste0("Census tracts: ", census_vintage,
                        " TIGER/Line. Walking isochrones via r5r / OpenStreetMap."))

ggsave(out_path, p, width = 5, height = 5)
system(sprintf('pdfcrop "%s" "%s"', out_path, out_path))
message("Saved to ", out_path)