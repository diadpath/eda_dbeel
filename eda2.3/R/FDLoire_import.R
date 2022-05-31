# Libraries ----

library(readr)
library(stringr)
#library(DBI)
library(RPostgres)
library(sf)
library(dplyr)

# Options
options(scipen=999)

# Set up database connection ----

con = dbConnect(Postgres(),
                dbname=baseODBCrios[1],
                host="localhost",
                port=5432,
                user=baseODBCrios[2], 
                password=baseODBCrios[3])


# Load data ----

# Load csv file from template. Data where included by hand from whatever was 
# transmitted by FDAPPMAs

## Stations ----

stations_FD <- readr::read_csv(str_c(datawd,"/loire/data/stations_FD_EDALoire.csv"))

## Peches ----

peches_FD <-readr::read_csv(str_c(datawd,"/loire/data/peches_FD_EDALoire.csv")) %>% 
  left_join(stations_FD %>% select(sta_id, sta_source), by = c("op_sta_id" = "sta_id"))

## Biometry

biometry_FD <- readr::read_csv(str_c(datawd,"/loire/data/bio_FD_EDALoire.csv"))

# Geographic conversion ----

stations_FD_sf <- st_as_sf(x = stations_FD, coords = c("sta_X", "sta_Y"), crs = 2154) %>% 
  st_transform(crs = 3035) %>% 
  mutate(SRID = 3035)

coords_FD <-st_coordinates(stations_FD_sf)

stations_FD_sf <- stations_FD_sf %>% 
  bind_cols(coords_FD)

# Write data into the database ----

## Stations ----

DBI::dbExecute(con, "DROP TABLE if exists france.station_fdloire;")
DBI::dbWriteTable(con, "station_fdloire", stations_FD_sf) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE station_fdloire set schema france")

## Peches ----

DBI::dbExecute(con, "DROP TABLE if exists france.operation_fdloire;")
DBI::dbWriteTable(con, "operation_fdloire", peches_FD) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE operation_fdloire set schema france")

## Biometry

DBI::dbExecute(con, "DROP TABLE if exists france.batch_fish_fdloire;")
DBI::dbWriteTable(con, "batch_fish_fdloire", biometry_FD) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE batch_fish_fdloire set schema france")
