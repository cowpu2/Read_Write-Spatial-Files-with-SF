## =================Managing/Writing spatial data ===========================
##
## CodeMonkey:  Mike Proctor
## ======================================================================
# 2025-02-28 15:23:59.135478 ------------------------------mdp

source("Spatial.R")
source("Setup.R") # just load the libraries and paths - no data

# Write multiple layers to file ----------
DEMList <- c("CR_DEM","OR_DEM_1", "OR_DEM_2", "RR_DEM")

### Loop over a list of sf data frames -----
for (i in DEMList) {
  
  write_sf(get(i), paste0(spatial_path, "DEMs.gpkg"), i) # i is an object in first instance but chracter in layer name
  
}

### With lapply over a list --------
lapply(DEMList,function(z) write_sf(get(z), paste0(spatial_path, "DEM2.gpkg"), z)) # get() gets the object not the name

# Lists layers in geopackage -------
st_layers(paste0(spatial_path, "DEMs.gpkg"))
st_layers(paste0(spatial_path, "DEM2.gpkg"))


# Removes layers in geopackage ---------
st_delete(paste0(spatial_path, "DEMs.gpkg"), "CR_DEM")



# Write out a shape file -------
### Write a file with a timestamp in filename -----
### This works with any filename - csv, xlsx etc

timestamp <- format(Sys.time(), "%Y%m%d_%H%M")

# function is different here!!!!!
st_write(CR_DEM, paste0(spatial_path, "CR_DEM", "_", timestamp,".shp")) # CR_DEM_20250228_1518.shp

# Read shape file we just wrote -----
CR_DEM_shape <- st_read(paste0(spatial_path, "CR_DEM_20250228_1518.shp"))

plot(CR_DEM_shape$geometry)





#  Below is for RAP project --------

# Reading from a geopackage ---------

#https://disasters.amerigeoss.org/datasets/geoplatform::historic-perimeters-combined-2000-2018-geomac/explore?location=36.089043%2C-105.783498%2C4.77
#https://data-nifc.opendata.arcgis.com/datasets/5b3ff19978be49208d41a9d9a461ecfb/about
st_layers(paste0(source_path, "Historic_Geomac_Perimeters_Combined_2000_2018_-7007592357689317076.gpkg")) 

# Historical fires 2000-2018 --------
HistFires <- st_read(paste0(source_path, "Historic_Geomac_Perimeters_Combined_2000_2018_-7007592357689317076.gpkg"), "US_HIST_FIRE_PERIMTRS_2000_2018_DD83") |> 
             filter(state == "OK")
HistFires <- st_transform(HistFires, crs = 32614)

# Just the Ferguson fire --------
Ferguson <- HistFires |> filter(incidentname == "Ferguson")
Ferguson_buffered_20 <- Ferguson |> st_buffer(dist = -20) # buffered by -20m to get away from edge effects along roads etc

# Just the burn scar
plot(Ferguson$SHAPE) 

  # add the buffer
plot(Ferguson$SHAPE) +
plot(Ferguson_buffered_20$SHAPE, add = TRUE)


# Get the county from tigris in Spatial.R -------
Comanche <- OKCounties |> filter(NAME == "Comanche")

# General vicinity
plot(OKCounties$geometry) +
  plot(Ferguson$SHAPE, add = TRUE)


# Create random sample sites ---------
set.seed(10) # run this and st_sample in same call
SampleSites <- st_sample(Ferguson_buffered_20, size = 30, type = "random") 

  plot(Ferguson$SHAPE) +
  plot(SampleSites, add = TRUE)


# Write out polygon and sites to geopackage ------
  
  write_sf(Ferguson, paste0(spatial_path, "Ferguson_Fire.gpkg"), "Ferguson_Fire") 
  write_sf(SampleSites, paste0(spatial_path, "Ferguson_Fire.gpkg"), "SampleSites") 
  
  st_layers(paste0(spatial_path, "Ferguson_Fire.gpkg")) 
  
  


