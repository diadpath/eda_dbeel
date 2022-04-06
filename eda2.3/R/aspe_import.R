# setwd("C:\\workspace\\eda_dbeel")
# memory.limit(size =4000)

#---------------------Libraries---------------------#
library(aspe)
library(tidyverse)
library(sf)
library(RPostgres)
library(aspeQual)

# remotes::install_github("PascalIrz/aspeQual")
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

# Load Rdata tables sent by OFB (Pascal Irz),
# Remember to ask if/when data set will be integrated in hub'eau API 

load(str_c(datawd,"/loire/data/tables_sauf_mei_2022_01_13_14_22_07.RData")) # all data except biometry
load(str_c(datawd,"/loire/data/mei_2022_01_13_14_22_07.RData")) # biometry



#--------------- Create tables to be written in the database-------------------#

# Station table

station_aspe <- station %>%
	left_join(y = ref_type_projection,
	          by = c("sta_typ_id" = "typ_id")) %>%
  filter(typ_code_epsg==2154) %>%  # filter data from metropolitan France 
  filter(sta_coordonnees_y > 6000000) # some station have wrong coordinates
# we limit the south extent to south Corsica for now...

# TODO filter locations based on a polygon of France ...

# TODO LATER recuperer les stations historiques pour voir les manques d'import depuis bd_map

# reproject coordinates in European system

coords <- aspe::geo_convertir_coords_df(df = station_aspe,
		var_x = sta_coordonnees_x,
		var_y = sta_coordonnees_y,
		var_id = "sta_id",
		var_crs_initial = "typ_code_epsg",
		crs_sortie = 3035) 

station_aspe <- station_aspe %>%
		left_join(y = coords) %>% # add reprojected coordinates
		dplyr::select(-(sta_geometrie)) %>%
		mutate(typ_code_epsg=3035) 

station_aspe <- station_aspe[,	!grepl("typ",colnames(station_aspe))] # remove all column starting with "typ"
# we probably should use select(!start_with) by it daesn't work

# nrow(station_aspe)  #32727 => 32720

# Converting table as a sf object to get functionning geometry (the one in the 
# table is stored as text and not recognized by postgis)
station_aspe_sf <- st_as_sf(station_aspe, coords=c("X","Y"),crs=3035) 

# Just checking that everything works fine
mapview::mapview(station_aspe_sf, color = "green") # some points in Africa, to remove


# Write station table in the database
DBI::dbExecute(con, "DROP TABLE if exists france.station_aspe;")
DBI::dbWriteTable(con, "station_aspe", station_aspe_sf) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE station_aspe set schema france")

# Sampling locations

# Some sampling locations do not have sta_id : we need to import their coordinates
# from point_prelevement

point_prelevement[point_prelevement$pop_id==100971,] # 136346
point_prelevement_aspe[point_prelevement_aspe$pop_id==100971,] # 115323

point_prelevement_aspe <- point_prelevement %>%
		left_join(y = ref_type_projection,
				by = c("pop_typ_id" = "typ_id")) %>%
		filter(typ_code_epsg==2154) %>%  #limit points to metropolitan France
    filter(pop_coordonnees_y > 6000000 & pop_coordonnees_y <8000000) %>%  # some station have wrong coordinates
# we limit the south extent to south Corsica for now...
    filter(pop_coordonnees_x < 1500000) %>% 
    filter(pop_coordonnees_x > 0) # filter some wrong coordinates

coords <- geo_convertir_coords_df(df = point_prelevement_aspe,
		var_x = pop_coordonnees_x,
		var_y = pop_coordonnees_y,
		var_id = "pop_id",
		var_crs_initial = "typ_code_epsg",
		crs_sortie = 3035) 


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

# Just checking that everything works fine
mapview::mapview(point_prelevement_aspe_sf, color = "green")  # some points in Africa, to remove

# Write prelevement table in the database
DBI::dbExecute(con, "DROP TABLE if exists france.point_prelevement_aspe;")
DBI::dbWriteTable(con, "point_prelevement_aspe", point_prelevement_aspe_sf) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE point_prelevement_aspe set schema france")


# Table operation


# Based on the code from aspe::mef_creer_passerelle() without lots
operation_aspe <- 
		point_prelevement %>%
		left_join(operation, by=c("pop_id"="ope_pop_id")) %>%
		left_join(operation_description_peche, by = c("ope_id" = "odp_ope_id")) %>%
		left_join(ref_moyen_prospection, by = c("odp_mop_id"="mop_id"))%>%
		select(-odp_mop_id, mop_ordre_affichage)%>%
		left_join(ref_protocole %>% select(pro_id,pro_libelle), by=c("ope_pro_id"="pro_id")) %>%
		left_join(ref_modele_materiel, by=c("odp_mom_id"="mom_id")) %>%
		select(-c(odp_mom_id,mom_fam_id,mom_ordre_affichage)) %>%
		left_join(station, by=c("pop_sta_id"="sta_id")) %>%			
		rename(sta_id=pop_sta_id) %>%
		# in the aim of the operations we can find out if it was dedicated to eels
		# someties one operation has several aims, we only keep eel related ones
		left_join(operation_objectif %>%
						left_join(ref_objectif, by=c("opo_obj_id"="obj_id")) %>%
						filter(opo_obj_id==9) %>%
						select(opo_ope_id) %>%
						distinct() %>%
						mutate(objectif="Suivi des populations d'anguilles"), by=c("ope_id"="opo_ope_id")) %>%	
		# Add number of sampling poinst for large habitats
		left_join(
				prelevement_elementaire %>%
						left_join(y = groupe_points %>% rename(pre_id = grp_id)) %>%
						group_by(pre_ope_id) %>%
						summarize(nb_point=sum(grp_nombre)), 
				by=c("ope_id"="pre_ope_id")) %>%
		# group passages and prelevements elementaires and count nb of passages		
		left_join(
				prelevement_elementaire %>%
						left_join(y = passage %>% rename(pre_id = pas_id)) %>%
						group_by(pre_ope_id) %>%
						summarize(nb_pas=max(pas_numero)), 
				by=c("ope_id"="pre_ope_id")) %>%
		filter(ope_pro_id %in% c(1,2,3,4,7)) %>% # remove IA SAT and vigie truite
		select(-ope_pro_id) %>%
		rename(op_typ = pro_libelle)

# write operation table in the database
DBI::dbExecute(con, "DROP TABLE if exists france.operation_aspe;")
DBI::dbWriteTable(con, "operation_aspe", operation_aspe) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE operation_aspe set schema france")




# lots


# the left join ensures that operations with no eels have zero after replace_na
batch_aspe <- operation %>%   # 48387
		select(ope_id)%>%
		left_join(
				prelevement_elementaire %>%
						left_join(y =  lot_poissons, by = c("pre_id"="lop_pre_id")) %>%
						filter(lop_esp_id==14) %>%
						group_by(pre_ope_id) %>%
						summarize(nb_eel=sum(lop_effectif)),
				by=c("ope_id"="pre_ope_id"))%>%
		mutate(nb_eel=replace_na(nb_eel,0)) %>%
		# add number of eels per passage
		left_join(
				prelevement_elementaire %>%
						left_join(y = passage %>% rename(pre_id = pas_id), by="pre_id") %>%
						left_join(y =  lot_poissons, by = c("pre_id"="lop_pre_id")) %>%
						filter(lop_esp_id==14) %>%
						group_by(pre_ope_id, pas_numero) %>%
						summarize(nb_eel_per_pass=sum(lop_effectif)),
				by=c("ope_id"="pre_ope_id")
		) %>%
		mutate(pas_numero=replace_na(pas_numero,1))  %>% # on fait un join entre prelevement elt et lot_poisson, certains prelevements n'ont pas de passage (p?che grand milieu) on consid?re que le passage c'est 1
		pivot_wider(id_cols=c(ope_id, nb_eel),values_from=nb_eel_per_pass, names_from=pas_numero, values_fill=0, names_prefix="pas_") %>% 
		mutate("pas_1"=replace_na(pas_1,0))  

DBI::dbExecute(con, "DROP TABLE if exists france.batch_aspe;")
DBI::dbWriteTable(con, "batch_aspe", batch_aspe) # written in public scheme
DBI::dbExecute(con, "ALTER TABLE batch_aspe set schema france")


# ------------------------------ Biometry--------------------------------------#
# When there are too many fish people usually group them and will only mesure a 
# subsample (usually 30 individuals).
# Here we use the function qta_ajouter_mei_taille_alt() to randomly sample sizes
# from the mesured individuals

# First create a (large) table with all fish mesured
data <- mef_creer_passerelle() %>%
  mef_ajouter_lots() %>%
  mef_ajouter_type_lot() %>%
  mef_ajouter_mei() %>%
  filter(mei_taille > 0) %>% # positive length
  mef_ajouter_libelle() %>%
  mef_ajouter_esp() %>% 
  select(
    mei_id,
    lop_id,
    ope_id,
    tyl_libelle,
    pop_id,
    mei_taille,
    mei_mesure_reelle,
    mei_poids,
    mei_poids_estime,
    mei_mep_id,
    esp_code_alternatif
  ) %>%
  distinct() # remove doublons / opérations on several aims (networks)

# keep only eels
data_ang <- data %>% 
  filter(esp_code_alternatif == "ANG")

# count sample mesures to use the function only when the sample is large enough
n_measures <- data_ang %>%
  filter(tyl_libelle == "S/L") %>% # only lots with measures on on a subsample
  group_by(lop_id, mei_mesure_reelle) %>%
  tally() %>%
  ungroup() %>%
  pivot_wider(
    names_from = mei_mesure_reelle,
    values_from = n
  )
# Select lots with at least 30 mesures
mes_lots <- n_measures %>%
  filter(t > 29) %>%
  pull(lop_id)

# Finaly add estimated measures
data_lots <- data_ang %>%
  filter(lop_id %in% mes_lots) %>%
  qta_ajouter_mei_taille_alt()

