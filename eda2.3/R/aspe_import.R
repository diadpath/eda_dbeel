# setwd("C:\\workspace\\eda_dbeel")
memory.limit(size =4000)
library(aspe)
library(tidyverse)
library(sf)
library(RPostgres)

rivernetwork <- "RIOS"
# Load data
source("common/init.r")

con = dbConnect(Postgres(),
		dbname=baseODBCrios[1],
		host="localhost",
		port=5432,
		user=baseODBCrios[2], 
		password=baseODBCrios[3])
# tables envoyées par Pascal, on devrait pouvoir l'interroger par API hub eau d'ici la fin de l'année
load(str_c(datawd,"/loire/data/tables_sauf_mei_2022_01_13_14_22_07.RData"))
load(str_c(datawd,"/loire/data/mei_2022_01_13_14_22_07.RData"))

# temp 2022 correction d'un renommage dans la table
# normalement ne devrait pas être là

operation_description_peche <- operation_description_peche %>% rename("odp_largeur_lame_eau"="largeur")



# Table correspondance globale
passerelle <- mef_creer_passerelle()

# Distinct

dist_passerelle <- passerelle %>% 
		dplyr::select(ope_id, sta_id, pop_id) %>% 
		distinct()


# Table station

station_aspe <- station %>%
		left_join(y = ref_type_projection,
				by = c("sta_typ_id" = "typ_id"))

# filter data from metropolitan France
# TODO LATER récupérer les stations historiques pour voir les manques d'import depuis bd_map

station_aspe <- station_aspe %>%
		filter(typ_code_epsg==2154)

coords <- geo_convertir_coords_df(df = station_aspe,
		var_x = sta_coordonnees_x,
		var_y = sta_coordonnees_y,
		var_id = "sta_id",
		var_crs_initial = "typ_code_epsg",
		crs_sortie = 3035) 

station_aspe <- station_aspe %>%
		left_join(y = coords) %>%
		dplyr::select(-(sta_geometrie))%>%
		mutate(typ_code_epsg=3035) 
station_aspe <- station_aspe[,	!grepl("typ",colnames(station_aspe))]
nrow(station_aspe)  #32727

station_aspe_sf <- st_as_sf(station_aspe, coords=c("X","Y"),crs=3035)

mapview::mapview(station_aspe_sf, color = "green")


# import des stations en base ---------------------
DBI::dbExecute(con, "DROP TABLE if exists france.station_aspe;")
DBI::dbWriteTable(con, "station_aspe", station_aspe_sf)
DBI::dbExecute(con, "ALTER TABLE station_aspe set schema france")

# Points de prélèvements-----------------------------

# certaines stations n'ont pas de sta_id et il faut importer leurs coord des points de prélèvement

point_prelevement_aspe <- point_prelevement %>%
		left_join(y = ref_type_projection,
				by = c("pop_typ_id" = "typ_id")) %>%
		filter(typ_code_epsg==2154)

coords <- geo_convertir_coords_df(df = point_prelevement_aspe,
		var_x = pop_coordonnees_x,
		var_y = pop_coordonnees_y,
		var_id = "pop_id",
		var_crs_initial = "typ_code_epsg",
		crs_sortie = 3035) 
# clipr::write_clip(colnames(point_prelevement_aspe))

point_prelevement_aspe <- point_prelevement_aspe %>%
		left_join(y = coords, by= "pop_id") %>%
		dplyr::select(-c(pop_distance_mer,
						pop_distance_maree_dynamique,
						pop_fog_id_cerema,
						pop_ocs_id,
						pop_zoh_id,
						pop_reh_id_cerema,
						pop_cap_id,
						pop_acc_id,
						pop_unh_id,
						pop_distance_source,
						pop_altitude,
						pop_pente_ign_cours_eau,
						pop_surface_bassin_versant_amont,
						pop_temperature_moyenne_janvier,
						pop_temperature_moyenne_juillet,
						pop_uti_id,
						pop_bas_id,
						typ_code_sandre,
						typ_libelle_sandre,
						typ_libelle,
						typ_ordre_affichage
				))%>%
		mutate(typ_code_epsg=3035) 

nrow(point_prelevement_aspe)  #115355

point_prelevement_aspe_sf <- st_as_sf(point_prelevement_aspe, coords=c("X","Y"),crs=3035)



# import des points de prélèvement en base ---------------------
DBI::dbExecute(con, "DROP TABLE if exists france.point_prelevement_aspe;")
DBI::dbWriteTable(con, "point_prelevement_aspe", point_prelevement_aspe_sf)
DBI::dbExecute(con, "ALTER TABLE point_prelevement_aspe set schema france")


# Table operation -------------------------------------- (en cours)


# expl_trouver_table() et expl_trouver_variable() pour trouver table et variable

#mef_creer_passerelle() %>%
#		mef_ajouter_type_protocole() %>% 
#		mef_ajouter_passage() %>%
#		mef_ajouter_lots

   dist_passerelle %>%  
			 left_join(operation) %>% 
		mef_ajouter_type_protocole() %>% 
		mef_ajouter_passage()


		

operation_description_peche <- operation_description_peche %>% 
		rename(largeur = odp_largeur_lame_eau) # for reason this name is not recognised by select


# On repart de mef_creer_passerelle() en enlevant les lots
operation_aspe <- 
		point_prelevement %>%
		left_join(operation, by=c("pop_id"="ope_pop_id")) %>%
		left_join(operation_description_peche, by = c("ope_id" = "odp_ope_id")) %>%
		left_join(ref_protocole %>% select(pro_id,pro_libelle), by=c("ope_pro_id"="pro_id")) %>%
		left_join(prelevement_elementaire, by=c("ope_id"="pre_ope_id")) %>%
		left_join(station, by=c("pop_sta_id"="sta_id")) %>%
		rename(sta_id=pop_sta_id) %>%
		left_join(y = passage %>%
						rename(pre_id = pas_id)) %>%
		filter(ope_pro_id %in% c(1,2,3,4,7)) %>% # on vire IA SAT et vigietruite
		select(-ope_pro_id) %>%
		rename(op_typ = pro_libelle)


DBI::dbExecute(con, "DROP TABLE if exists france.operation_aspe;")
DBI::dbWriteTable(con, "operation_aspe", operation_aspe)
DBI::dbExecute(con, "ALTER TABLE operation_aspe set schema france")




# TODO lots





