## =================Managing/Writing spatial data ===========================
##
## CodeMonkey:  Mike Proctor
## ======================================================================
# 2025-02-28 15:23:59.135478 ------------------------------mdp
# 2025-03-03 11:49:11.672251 ------------------------------mdp


source("Spatial.R")
source("Setup.R") # just load the libraries and paths - no data
library(tictoc)

rm(list = c("marshall", "state", "TX_OK_Counties"))

# Create a list of names
CountyList <- unique(OK_Counties$NAME)

# Write a function to pull each row out as a layer into environment
Create_County_df <- function(x) { 
  df <- OK_Counties |> filter(NAME == x) |> distinct(NAME, .keep_all = TRUE)
  df_name <- paste0(x)
  assign(df_name, df, envir = .GlobalEnv)
}
# Apply the function to the list of county names
lapply(CountyList, Create_County_df) 

# Now we have a bunch of layers to write 

# Write multiple dfs to file ----------

### Loop over a list of sf data frames -----
tic() #110.23 sec
for (i in CountyList) {
  
  sf::write_sf(get(i), paste0(spatial_path, "OK_Counties.gpkg"), i) # i is an object in first instance but character in layer name
  
}
toc() 

### With lapply over a list of names --------
tic()#107.41 sec
lapply(CountyList,function(z) sf::write_sf(get(z), paste0(spatial_path, "OK_Counties2.gpkg"), z)) # get() gets the object not the name
toc()

### Lists layers in geopackage -------
sf::st_layers(paste0(spatial_path, "OK_Counties.gpkg"))
sf::st_layers(paste0(spatial_path, "OK_Counties2.gpkg"))


## Removes layers in geopackage ---------

# Should be 77 layers in geopackages
#### Delete one layer ----
sf::st_delete(paste0(spatial_path, "OK_Counties.gpkg"), "Marshall")
sf::st_layers(paste0(spatial_path, "OK_Counties.gpkg")) # Check to see if it worked

#### Delete a list of layers ----
delList <- head(CountyList)
lapply(delList, function(y)      
sf::st_delete(paste0(spatial_path, "OK_Counties2.gpkg"), y))
sf::st_layers(paste0(spatial_path, "OK_Counties2.gpkg")) # Check to see if it worked


# Write out a shape file -------
### Write a file with a timestamp in filename -----
### This works with any filename - csv, xlsx etc

timestamp <- format(Sys.time(), "%Y%m%d_%H%M")

# function is different here!!!!!
sf::st_write(Osage, paste0(spatial_path, "Osage_County_", timestamp,".shp")) # Osage_County_20250303_1613.shp
# GDAL complains here because there are too many digits in the ALAND and AWATER fields - the answer is to not use a shape file.


# Read shape file we just wrote -----
Osage_Shape <- sf::st_read(paste0(spatial_path, "Osage_County_", timestamp,".shp")) # I cheated here

plot(Osage_Shape$geometry)


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
  

# Write to csv ----
   # Will probably only do this with point data
  TexomaList <- c("Marshall", "Bryan", "Cooke", "Grayson")
  TexomaCounties <- TX_OK_Counties |> filter(NAME %in% TexomaList) # an "infix" symbol
  
### Find the centroid for each county -----------
   # Because polygons in csv files aren't much fun
  #https://gis.stackexchange.com/questions/43543/how-to-calculate-polygon-centroids-in-r-for-non-contiguous-shapeshttps://gis.stackexchange.com/questions/43543/how-to-calculate-polygon-centroids-in-r-for-non-contiguous-shapes

 TexomaCentroids <- sf::st_centroid(TexomaCounties) # calculates a single point for each county
 
plot(TexomaCounties$geometry) + 
  plot(TexomaCentroids$geometry, add = TRUE, pch = 19, col = 2)


### Create columns for coordinates from geometry column -----------
Centroids <- TexomaCentroids %>% mutate("northing" = sf::st_coordinates(.)[,2],
                                        "easting"  = sf::st_coordinates(.)[,1]) |> 
### and then drop the geometry column -----------
             sf::st_drop_geometry() # This is necessary when using minicharts with leaflet maps - you can still write out a csv that includes it but the data in that column may not be useful.

## Write out the csv
timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
write_csv(Centroids, paste0(csv_path, "TexomaCountyCentroids", "_", timestamp, ".csv"))
write_csv(Centroids, paste0(dat_path, "TexomaCountyCentroids", "_", timestamp, ".dat")) # Excel can't jack it up if it can't open it.

### Too many columns - let's get rid of some ----------


# Include by column name
dilbert <- Centroids |> select(STATEFP, COUNTYFP, NAME, ALAND, AWATER, northing, easting )
# Exclude by column name
wally <- Centroids |> select(-CBSAFP, -CLASSFP, -COUNTYNS, -CSAFP, -FUNCSTAT, -GEOID, -INTPTLAT,
                             -INTPTLON,-METDIVFP,-MTFCC,-NAMELSAD, -LSAD )

# Exclude by a list of columns
delList <-  c("CBSAFP", "CLASSFP", "COUNTYNS", "CSAFP", "FUNCSTAT", "GEOID", "INTPTLAT",
             "INTPTLON","METDIVFP","MTFCC","NAMELSAD", "LSAD" )
alice <- Centroids |> select(-all_of(delList))


# Include by index
dogbert <- Centroids |> dplyr::select(1,5,14:19)

# Exclude by index
ratbert <- Centroids |> dplyr::select(-2:-4, -6:-13)

#  Be careful with indexing columns.  If for some reason the number of columns,  
#  or order of columns even changes upstream, it will wreak havoc on your data frame.
#  I use indexing when I first bring in a df - sometimes easier to index a column than to type some bizarre column name.
#  If the df is already in some type of workflow where the columns could change I avoid indexing.  But by then I've 
#  changed the column name to something reasonable anyway

# dogbert has the most useful data so lets write it to a csv

timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
write_csv(dogbert, paste0(csv_path, "TexomaCountyCentroids", "_", timestamp, ".csv"))
write_csv(dogbert, paste0(dat_path, "TexomaCountyCentroids", "_", timestamp, ".dat")) # Excel can't jack it up if it can't open it.

# I used the same file name as before but the timestamp will be different.
# The timestamp is sometimes useful and other times not so much.  Early in a project when I'm making lots of 
# changes to the data I use it.  Once I get downstream projects going that use the data I take the timestamp 
# off so the file name doesn't change and downstream scripts don't have to be changed to reload it.
# The timestamp is handy when writing to xlsx files - if excel has a file open you'll get an error message 
# when trying to write to it.  Using the timestamp means you're writing to new file so R can't complain about excel.

# Read from a csv and convert to sf ----------

# Used "Import Dataset" here because the file name was so long

CountyCentroids <- read_csv(paste0(csv_path, "TexomaCountyCentroids_20250303_1434.csv"), 
                                                col_types = cols(INTPTLAT = col_number(), 
                                                                 INTPTLON = col_number(), northing = col_number(), 
                                                                 easting = col_number()))

# Convert csv with coordinate columns to sf object
fred <- CountyCentroids |> 
st_as_sf(coords=c("northing","easting"), crs=32614)

plot(fred$geometry) # that don't look right!

fred <- CountyCentroids |> 
  st_as_sf(coords=c("easting","northing"), crs=32614) # make sure you get x and y coords in right order

plot(TexomaCounties$geometry, col = 3) +
plot(fred$geometry, col = 2, pch = 19, add = TRUE)

