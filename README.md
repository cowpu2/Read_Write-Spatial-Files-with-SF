# Reading & Writing Spatial Files in R with sf package

Mike Proctor

## Some setup first –

``` r
source("Setup.R") # just load the libraries and paths - no data - depends on what I'm doing
source("Spatial.R") # load libraries, paths, and data from tigris package

library(tictoc) # an extra library used for timing
```

# Write a single layer to a geopackage

``` r
sf::write_sf(marshall, paste0(spatial_path, "one_layer.gpkg"), "Marshall")
sf::st_layers(paste0(spatial_path, "one_layer.gpkg"))
```

# Writing multiple layers to a geopackage

First off we need a bunch of layers to write

``` r
rm(list = c("marshall", "state", "TX_OK_Counties"))# These are in the way at the moment so lets get rid of them.
```

## Extract a list of the counties in the data frame

`CountyList <- unique(OK_Counties$NAME)`

## Write a function to pull each row out as a layer into the environment and name it according to the value in the NAME column

``` r
 Create_County_df <- function(x) { 
  df <- OK_Counties |> filter(NAME == x) |> distinct(NAME, .keep_all = TRUE)
  df_name <- paste0(x)
  assign(df_name, df, envir = .GlobalEnv)
}
```

## Apply the function to the list of county names

`lapply(CountyList, Create_County_df)`

Now we have a bunch of layers to write

## Write multiple data frames to a geopackage

There’s two approaches here.

### Loop over a list of sf data frames

``` r
tic() 
for (i in CountyList) {
  
  sf::write_sf(get(i), paste0(spatial_path, "OK_Counties.gpkg"), i) # i is an object in first instance but character in layer name
  
}
toc()#110.23 sec
```

### lapply over a vector of names

Applies a function (in this case an anonymous function) to each object within a vector( a list - CountyList).

``` r
tic()
lapply(CountyList,function(z) sf::write_sf(get(z), paste0(spatial_path, "OK_Counties2.gpkg"), z)) # get() gets the object not the name
toc()#107.41 sec
```

# Remove layers from geopackage

### List the layers in the geopackages we just wrote

There should be 77 layers in each file

`sf::st_layers(paste0(spatial_path, "OK_Counties.gpkg"))`

`sf::st_layers(paste0(spatial_path, "OK_Counties2.gpkg"))`

### Delete one layer - should get 76 rows

``` r
sf::st_delete(paste0(spatial_path, "OK_Counties.gpkg"), "Marshall")
sf::st_layers(paste0(spatial_path, "OK_Counties.gpkg")) # Check to see if it worked
```

### Delete a list of layers - deleting 10 layers

``` r
delList <- head(CountyList,10) # take the first 10 rows
lapply(delList, function(y)      
sf::st_delete(paste0(spatial_path, "OK_Counties2.gpkg"), y))
sf::st_layers(paste0(spatial_path, "OK_Counties2.gpkg")) # Check to see if it worked
```

# Shapefiles

Most common format for spatial data - has some limitations - requires 4 files - column names are limited in length. When writing to a shapefile, column names may get truncated - this could be a problem if mulitple columns have similar names. Each layer requires a separate set of files. Writing the 77 layers above would require 4x77 files.

## Write out a shape file

### Write a file with a timestamp in filename

### This works with any filename - csv, xlsx etc

### GDAL complains here because there are too many digits in the ALAND and AWATER fields - the answer is to not use a shape file.

``` r
timestamp <- format(Sys.time(), "%Y%m%d_%H%M")

sf::st_write(Osage, paste0(spatial_path, "Osage_County_", timestamp,".shp")) # Osage_County_20250303_1613.shp
```

## Read a shape file - the one we just wrote out

``` r
Osage_Shape <- sf::st_read(paste0(spatial_path, "Osage_County_", timestamp,".shp")) # I cheated here - how?

plot(Osage_Shape$geometry)
```

# Clean out environment and reset

We’re done with all those objects in the environment pane so let’s do some house cleaning.\
The following code will remove the objects and reload everything that we’ll need.

# Comma Separated Values - csv

# Write to csv

We don’t need all the rows so let’s filter some out

```` markdown
```{r}
TexomaList <- c("Marshall", "Bryan", "Cooke", "Grayson")
  TexomaCounties <- TX_OK_Counties |> filter(NAME %in% TexomaList) # an "infix" symbol
```
````

### Find the centroid for each county and plot it

This will give us a set of points. Saving polygons to a csv isn’t going to be all that useful - it would be really difficult to parse that out and get it back into a GIS system. If you aren’t using the polygon data it will work fine.

```` markdown
```{r}
TexomaCentroids <- sf::st_centroid(TexomaCounties)

plot(TexomaCounties$geometry) + 
  plot(TexomaCentroids$geometry, add = TRUE, pch = 19, col = 2)
```
````

### Create columns for coordinates from geometry column

Already having columns for x and y will make it much easier to import this back into a GIS system.

```` markdown
```{r}
Centroids <- TexomaCentroids %>% mutate("northing" = sf::st_coordinates(.)[,2],
                                        "easting"  = sf::st_coordinates(.)[,1]) |> 
# and then drop the geometry column -----------
             sf::st_drop_geometry() # This is necessary when using minicharts with leaflet maps 
```
````

### Write out the file

I use a “.dat” extension often so that I know that date columns haven’t been modified by excel. Otherwise they are just a csv.

```` markdown
```{r}
timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
write_csv(Centroids, paste0(csv_path, "TexomaCountyCentroids", "_", timestamp, ".csv"))
write_csv(Centroids, paste0(dat_path, "TexomaCountyCentroids", "_", timestamp, ".dat")) # Excel can't jack it up if it can't open it.
```
````

### Too many columns - let’s get rid of some

*I use the names of characters from the Dilbert comic strip when I can’t come up with a meaningful df name.*

#### Select by column name

```` markdown
```{r}
# Include by column name
dilbert <- Centroids |> select(STATEFP, COUNTYFP, NAME, ALAND, AWATER, northing, easting )
# Exclude by column name
wally <- Centroids |> select(-CBSAFP, -CLASSFP, -COUNTYNS, -CSAFP, -FUNCSTAT, -GEOID, -INTPTLAT,
                             -INTPTLON,-METDIVFP,-MTFCC,-NAMELSAD, -LSAD )
```
````

#### Select by a list of column names

In this case I’m deleting everything in the list - if I remove the “-” in front of “all_of” I’d keep everything in the list.

```` markdown
```{r}
delList <-  c("CBSAFP", "CLASSFP", "COUNTYNS", "CSAFP", "FUNCSTAT", "GEOID", "INTPTLAT",
             "INTPTLON","METDIVFP","MTFCC","NAMELSAD", "LSAD" )
alice <- Centroids |> select(-all_of(delList))
```
````

#### Select by index (location)

Be careful with indexing columns. If for some reason the number of columns, or order of columns changes upstream, it will wreak havoc on your data frame.

I use indexing when I first load a df - sometimes its easier to index a column than to type some bizarre column name.

If the df is already in some type of workflow where the columns could change I avoid indexing. But by then I’ve changed the column name to something reasonable anyway.

```` markdown
```{r}
# Include by index
dogbert <- Centroids |> dplyr::select(1,5,14:19)

# Exclude by index
ratbert <- Centroids |> dplyr::select(-2:-4, -6:-13)
```
````

### The dogbert df has the most useful data so lets write it to a csv.

I’m using the same name with a time stamp so it won’t overwrite what we did previously. It might be worthwhile to compare the files. Time stamps in file names are sometimes useful and other times not so much. Early in a project when I’m making lots of changes to the data I use them. Once I get downstream projects going that use the data, I take the time stamp off, so I don’t have to change the file name every time I reload it in downstream scripts.

```` markdown
```{r}
timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
write_csv(dogbert, paste0(csv_path, "TexomaCountyCentroids", "_", timestamp, ".csv"))
write_csv(dogbert, paste0(dat_path, "TexomaCountyCentroids", "_", timestamp, ".dat")) 
```
````

# Read from a csv and convert to sf

Used “Import Dataset” here because the file name was so long

```` markdown
```{r}
CountyCentroids <- read_csv(paste0(csv_path, "TexomaCountyCentroids_20250303_1434.csv"), 
                                                col_types = cols(INTPTLAT = col_number(), 
                                                                 INTPTLON = col_number(), 
                                                                 northing = col_number(), # these cols need to be numeric
                                                                 easting = col_number()))
```
````

## Convert csv with coordinate columns to sf object

```` markdown
```{r}
fred <- CountyCentroids |> st_as_sf(coords=c("northing","easting"), crs=32614)

plot(fred$geometry) # that don't look right!
```
````

### Something’s not quite right about that!

Make sure you get x and y coords in right order

```` markdown
```{r}
fred <- CountyCentroids |> 
  st_as_sf(coords=c("easting","northing"), crs=32614) # make sure you get x and y coords in right order

plot(TexomaCounties$geometry, col = 3) +
plot(fred$geometry, col = 2, pch = 19, add = TRUE)
```
````
