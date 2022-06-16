# Libraries ----

library(readr)
library(stringr)
#library(DBI)
library(RPostgres)
library(sf)
library(dplyr)

# Options
options(scipen=999)
rivernetwork <- "RIOS"
source("common/init.r")
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
# max(stations_FD$sta_id)
## Peches ----

peches_FD <-readr::read_csv(str_c(datawd,"/loire/data/peches_FD_EDALoire.csv")) %>% 
		left_join(stations_FD %>% select(sta_id, sta_source), by = c("op_sta_id" = "sta_id")) %>% 
		filter(!op_typ %in% c("IA_Borchet", "Indice d'abondance truite (IAT)",
						"IA BRO 0+", "Transfert")) # remove pike and trout related operations

## Biometry

biometry_FD <- readr::read_csv(str_c(datawd,"/loire/data/bio_FD_EDALoire.csv"))

# Geographic conversion ----

stations_FD_sf <- st_as_sf(x = stations_FD, coords = c("sta_X", "sta_Y"), crs = 2154) %>% 
		st_transform(crs = 3035) %>% 
		mutate(SRID = 3035)

coords_FD <-st_coordinates(stations_FD_sf)

stations_FD_sf <- stations_FD_sf %>% 
		bind_cols(coords_FD)

# ajout tardif des données 37 provenant de WAMA dont on a trouvé le COOOOOOOODDDDDE !
load(file=str_c(datawd,"/loire/data/st_wama37.Rdata")) # st_wama37

st_wama37 <- st_wama37   %>% 		
		select(-sta_X2154,-sta_Y2154) 

stations_FD_sf2 <- rbind(stations_FD_sf, st_wama37) %>% rename(geom=geometry)


# Write data into the database ----

## Stations ----

DBI::dbExecute(con, "DROP TABLE if exists france.station_fdloire;")
st_write(stations_FD_sf2,con,"station_fdloire") # written in public schema with geometry
DBI::dbExecute(con, "ALTER TABLE station_fdloire set schema france")

## Peches ----

load(file=str_c(datawd,"/loire/data/operationsWAMA.Rdata")) # operationsWAMA
operationsWAMA$op_cod <- as.character(operationsWAMA$op_cod)
peches_FD1 <- bind_rows(peches_FD, operationsWAMA)
DBI::dbExecute(con, "DROP TABLE if exists france.operation_fdloire;")
DBI::dbWriteTable(con, "operation_fdloire", peches_FD1) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE operation_fdloire set schema france")

## Biometry
load(file=str_c(datawd,"/loire/data/biometry_WAMA.Rdata"))
biometry_FD1 <- bind_rows(biometry_FD, biometry_WAMA)
biometry_FD$ang_pds <- as.numeric(biometry_FD$ang_pds)

DBI::dbExecute(con, "DROP TABLE if exists france.batch_fish_fdloire;")
DBI::dbWriteTable(con, "batch_fish_fdloire", biometry_FD) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE batch_fish_fdloire set schema france")

