
setwd("C:/Users/jraitif/Documents/GIT/dbeel")
#---------------------Libraries---------------------#
library(tidyverse)
library(sf)
library(RPostgres)
library(rnaturalearth)
library(rnaturalearthdata)
library(leafsync)
library(ggplot2)
library(maps)

rivernetwork <- "RIOS"

#--------------------- Load data---------------------#

source("common/init.r")

# Set up database connection

con = dbConnect(Postgres(),
                dbname=baseODBCrios[1],
                host="localhost",
                port=5432,
                user=baseODBCrios[2], 
                password=baseODBCrios[3])

#Contrôles et visualisation des stations RSA

#get all stations
#RSA
ds_stations_rsa <- dbGetQuery(con, "select * from france.dbeel_station_rsa;")
#transform pg_geometry column to a sf compatible
ds_stations_rsa$sf_geometry <- st_as_sfc(ds_stations_rsa[]$the_geom, EWKB = TRUE)
sf_stations_rsa_3035 <- st_as_sf(ds_stations_rsa,crs=3035)
sf_stations_rsa_3035$the_geom <- NULL

# mapview::mapview(sf_stations_rsa_3035, color="blue",alpha.regions = 0.1, aplha = 0.1,legend=FALSE,cex =1)
#all stations are within french territory

ds_stations_aspe <- dbGetQuery(con, "select * from france.dbeel_station_aspe;")
#transform pg_geometry column to a sf compatible
ds_stations_aspe$sf_geometry <- st_as_sfc(ds_stations_aspe[]$the_geom, EWKB = TRUE)
sf_stations_aspe_3035 <- st_as_sf(ds_stations_aspe,crs=3035)
sf_stations_aspe_3035$the_geom <- NULL
# mapview::mapview(sf_stations_aspe_3035, color="blue",alpha.regions = 0.1, aplha = 0.1,legend=FALSE,cex =1)

dist <- as.data.frame(st_distance(sf_stations_aspe_3035, sf_stations_rsa_3035, by_element=FALSE))
dist$aspe <- rownames(dist)
#line = stations ASPE
#column = stations RSA

#remove all distances > 1km
maxdist <- 1000
dist2 <- dist %>%
  pivot_longer(cols = !aspe, names_to = "rsa", values_to = "dist")

# summary(dist2$dist), bcp de NA, pkoi ?

# sf_stations_aspe_3035[4,]
# sf_stations_rsa_3035[1006,]


dist2$dist <- as.numeric(dist2$dist)
dist2 <- dist2 %>%
  filter(dist <= maxdist)

