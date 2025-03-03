## ================ Load spatial data  =======================
##
## CodeMonkey:  Mike Proctor
## ======================================================================


source("Setup.R")
library(tigris)
options(tigris_use_cache = TRUE)

# Read the file in and explicitly set the crs ------
# Geology <- st_read(paste0(source_path, "/OK_Geology/OK_geol_poly.shp"))
# Geology <- st_transform(Geology, crs = 32614)


# These come out of tigris 
# roads <- roads("OK", "Marshall")
# roads <- st_transform(roads, crs = 32614)

state <- tigris::states() |> filter(STUSPS == "OK" | STUSPS == "TX")
state <- sf::st_transform(state, crs = 32614)

marshall <- tigris::counties("OK") |> filter(NAME == "Marshall")
marshall <- sf::st_transform(marshall, crs = 32614)

OK_Counties <- tigris::counties() |> filter(STATEFP == "40")
OK_Counties <- sf::st_transform(OK_Counties, crs = 32614)

TX_OK_Counties <- tigris::counties() |> filter(STATEFP == "40" | STATEFP == "48")
TX_OK_Counties <- sf::st_transform(TX_OK_Counties, crs = 32614)


# plot(state$geometry)
# 
# plot(OKCounties$geometry)
# 
# 
# ggplot(data = marshall, aes(color = NAME)) +
#   geom_sf() # geom_sf doesn't know where the data is on it's own
# 
# 
# ggplot() +
#   geom_sf(data = state, aes(fill = STUSPS) ) +
#   geom_sf(data = TX_OK_Counties, aes(fill = NAME) ) +
#   # geom_sf(data = CR_DEM, aes(color = "blue") ) +
#   # geom_sf(data = OR_DEM_1, aes(color = "green") ) +
#   # geom_sf(data = OR_DEM_2, aes(color = "purple") ) +
# 
#     theme(legend.position = "none")


