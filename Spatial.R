## ================ Load spatial data  =======================
##
## CodeMonkey:  Mike Proctor
## ======================================================================


source("Setup.R")
library(tigris)
options(tigris_use_cache = TRUE)

# Read the file in and explicitly set the crs ------
Geology <- st_read(paste0(source_path, "/OK_Geology/OK_geol_poly.shp"))
Geology <- st_transform(Geology, crs = 32614)

RR_DEM <- st_read(paste0(source_path, "/DEM/NRCS_DEM_BARE_EARTH.shp"))
RR_DEM <- st_transform(RR_DEM, crs = 32614)

OR_DEM_2 <- st_read(paste0(source_path, "/DEM/NRCS_DEM_BARE_EARTH_1.shp"))
OR_DEM_2 <- st_transform(OR_DEM_2, crs = 32614)

OR_DEM_1 <- st_read(paste0(source_path, "/DEM/NRCS_DEM_BARE_EARTH_2.shp"))
OR_DEM_1 <- st_transform(OR_DEM_1, crs = 32614)

CR_DEM <- st_read(paste0(source_path, "/DEM/NRCS_DEM_BARE_EARTH_3.shp"))
CR_DEM <- st_transform(CR_DEM, crs = 32614)





# These come out of tigris 
# roads <- roads("OK", "Marshall")
# roads <- st_transform(roads, crs = 32614)

state <- states() |> filter(STUSPS == "OK")
state <- st_transform(state, crs = 32614)

marshall <- counties("OK") |> filter(NAME == "Marshall")
marshall <- st_transform(marshall, crs = 32614)

OKCounties <- counties("OK")
OKCounties <- st_transform(OKCounties, crs = 32614)

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
#   #geom_sf(data = Geology, aes(fill = ORIG_LABEL) ) +
#   geom_sf(data = RR_DEM, aes(color = "red") ) +
#   geom_sf(data = CR_DEM, aes(color = "blue") ) +
#   # geom_sf(data = OR_DEM_1, aes(color = "green") ) +
#   # geom_sf(data = OR_DEM_2, aes(color = "purple") ) +
# 
#     theme(legend.position = "none")


