library(sf)
library(geogrid)
library(geojsonio)

# Change this according to your folder
setwd("~/Projects/journocoders-geogrid/")

df <- read_polygons("src/Local_Authority_Districts_December_2017_Super_Generalised_Clipped_Boundaries_in_Great_Britain.shp")

# Set arguments for plot
par(mfrow = c(2, 3), mar = c(0, 0, 2, 0))

# Hexagonal grid with 6 seeds (takes a while…)
for (i in 1:6) {
  grid_hexagon <- calculate_grid(shape = df, learning_rate = 0.05, grid_type = "hexagonal", seed = i)
  plot(grid_hexagon, main = paste("Seed", i, sep = " "))
}

# Square grid
for (i in 1:6) {
  grid_square <- calculate_grid(shape = df, grid_type = "regular", seed = i)
  sp::plot(grid_square, main = paste("Seed", i, sep = " "))
}

# Get a SpatialDataFrame from our desired grid (takes ages…)
tmp <- calculate_grid(shape = df, grid_type = "hexagonal", seed = 6)
df_hex <- assign_polygons(df, tmp)

# And export to TopoJSON
topojson_write(df_hex, object_name = "local_authorities", file = "output/local_authorities.json")
