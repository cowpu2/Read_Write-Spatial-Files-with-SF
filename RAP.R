




#  Setup for RAP project --------

### Reading from a geopackage ---------

#https://disasters.amerigeoss.org/datasets/geoplatform::historic-perimeters-combined-2000-2018-geomac/explore?location=36.089043%2C-105.783498%2C4.77
#https://data-nifc.opendata.arcgis.com/datasets/5b3ff19978be49208d41a9d9a461ecfb/about

st_layers(paste0(source_path, "Historic_Geomac_Perimeters_Combined_2000_2018_-7007592357689317076.gpkg")) 

### Historical fires 2000-2018 --------
HistFires <- sf::st_read(paste0(source_path, "Historic_Geomac_Perimeters_Combined_2000_2018_-7007592357689317076.gpkg"), "US_HIST_FIRE_PERIMTRS_2000_2018_DD83") |> 
  dplyr::filter(state == "OK")
HistFires <- sf::st_transform(HistFires, crs = 32614)

### Just the Ferguson fire --------
Ferguson <- HistFires |> dplyr::filter(incidentname == "Ferguson")
Ferguson_buffered_20 <- Ferguson |> sf::st_buffer(dist = -20) # buffered by -20m to get away from edge effects along roads etc

### Just the burn scar
plot(Ferguson$SHAPE) 

### add the buffer
plot(Ferguson$SHAPE) +
  plot(Ferguson_buffered_20$SHAPE, add = TRUE)


### Get the county from tigris in Spatial.R -------
Comanche <- TX_OK_Counties |> filter(NAME == "Comanche" & STATEFP == "40") # TX has a Comanche county as well

### General vicinity
ggplot() +
  geom_sf(data = OK_Counties$geometry) + # using the layer with the largest extents first
  geom_sf(data = Ferguson$SHAPE, aes(fill = "blue")) +
  theme(legend.position = "none") +
  ggtitle(paste0("Location of Ferguson Fire - Comanche County, OK - 2011-09-08")) 

### General vicinity County level
ggplot() +
  geom_sf(data = Comanche$geometry) +
  geom_sf(data = Ferguson$SHAPE, aes(fill = "blue")) +
  theme(legend.position = "none") +
  ggtitle(paste0("Location of Ferguson Fire - Comanche County, OK - 2011-09-08")) 



### Create random sample sites ---------
set.seed(10) # run this and st_sample in same call
SampleSites <- sf::st_sample(Ferguson_buffered_20, size = 30, type = "random") 

plot(Ferguson$SHAPE) +
  plot(SampleSites, add = TRUE, pch = 19, col = 3)


### Write out polygon and sites to geopackage ------

sf::write_sf(Ferguson, paste0(spatial_path, "Ferguson_Fire.gpkg"), "Ferguson_Fire") 
sf::write_sf(SampleSites, paste0(spatial_path, "Ferguson_Fire.gpkg"), "SampleSites") 

sf::st_layers(paste0(spatial_path, "Ferguson_Fire.gpkg")) 

# End of RAP stuff

