# Script d'intégration des données RSA
###############################################################################
# setwd("C:\\workspace\\eda_dbeel")

# pg_restore -U postgres -d eda2.3 rsa.backup

# -- snap des stations sur les rivières EDA
#CREATE VIEW rsa.v_sudoang AS(	WITH distance AS	(		SELECT st_distance(station.geom,st_setsrid(rn_fr.geom, 2154)) 
#AS distance, sta_cod, idsegment		FROM rsa.station,  rsa.bassin_bas bas, rsa.series series, "EDA2.3_sudoang".rn_fr	
#WHERE sta_bas_id = bas_id AND bas.bas_seasegment = series.bas_seasegment AND		
#seaidsegme =  series.bas_seasegment  AND  st_distance(station.geom, st_setsrid(rn_fr.geom, 2154)) < 1000	),
#min_dist AS	(		SELECT sta_cod, min(distance) AS min_dist FROM distance GROUP BY sta_cod	) SELECT sta_cod, 
#min_dist, idsegment FROM min_dist JOIN  distance using(sta_cod) WHERE distance = min_dist)

library(tidyverse)
library(sf)
library(RPostgres)


source("common/init.r")

# Set up database connection

con = dbConnect(Postgres(),
		dbname=baseODBCrios[1],
		host="localhost",
		port=5432,
		user=baseODBCrios[2], 
		password=baseODBCrios[3])

# TODO work with samples see ticket https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/issues/5