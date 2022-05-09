# Libraries ----

library(readr)
library(DBI)


# Set up database connection ----

con = dbConnect(Postgres(),
                dbname=baseODBCrios[1],
                host="localhost",
                port=5432,
                user=baseODBCrios[2], 
                password=baseODBCrios[3])


# Load data ----

# Load xls file from template. Data where included by hand from whathever was 
# transmeted by FDAPPMAs

## Stations ----

stations_FD <- readxl::read_excel("../donneesFD_EDALoire.xlsx", sheet = "Station")

## Peches ----

peches_FD <-readxl::read_excel("../donneesFD_EDALoire.xlsx", sheet = "Peche")


## Biometry

biometry_FD <- readxl::read_excel("../donneesFD_EDALoire.xlsx", sheet = "Biometrie")


# Write data into the database ----

## Stations ----

DBI::dbExecute(con, "DROP TABLE if exists france.station_FDLoire;")
DBI::dbWriteTable(con, "station_FDLoire", station_FD) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE station_FDLoire set schema france")

## Peches ----

DBI::dbExecute(con, "DROP TABLE if exists france.operation_FDLoire;")
DBI::dbWriteTable(con, "operation_FDLoire", peches_FD) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE operation_FDLoire set schema france")

## Biometry

DBI::dbExecute(con, "DROP TABLE if exists france.batch_fish_FDLoire;")
DBI::dbWriteTable(con, "batch_fish_FDLoire", biometry_FD) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE batch_fish_FDLoire set schema france")
