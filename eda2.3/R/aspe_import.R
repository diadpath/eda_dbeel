# Library
library(aspe)
library(tidyverse)
rivernetwork <- "RIOS"
# Load data
source("common/init.R")
load("./tables_sauf_mei_2022_01_13_14_22_07.RData")

# Table correspondance globale
passerelle <- mef_creer_passerelle()

# Distinct

dist_passerelle <- passerelle %>% 
  select(ope_id, sta_id) %>% 
  distinct()


# Table station

station_aspe <- station %>% 
  mutate(sta_source= "OFB", 
         SRID = 2154) %>% 
  dplyr::select(sta_id, sta_source, sta_code_sandre, sta_libelle_sandre, sta_coordonnees_x,
                sta_coordonnees_y, SRID) %>% 
  dplyr::rename(sta_cod = sta_code_sandre,
                sta_lib = sta_libelle_sandre,
                sta_X = sta_coordonnees_x,
                sta_Y = sta_coordonnees_y)

write_csv(station_aspe, "D://temp/stations_aspe.csv")

# Table operation

operation_description_peche <- operation_description_peche %>% 
  rename(largeur = odp_largeur_lame_eau) # for reason this name is not recognised by select

operation_aspe <- dist_passerelle %>% 
  left_join(operation) %>% 
  left_join(select(ref_protocole, pro_id, pro_libelle), by = c("ope_pro_id" = "pro_id")) %>% 
  filter(ope_pro_id %in% c(1,2,3,4,7)) %>% 
  left_join(operation_description_peche, by = c("ope_id" = "odp_ope_id")) %>% 
  mutate(op_cod = "") %>% 
  dplyr::select(ope_id, op_cod, sta_id, ope_date, pro_libelle, odp_longueur,
                largeur) %>% 
    rename(op_id = ope_id, op_sta_id = sta_id, op_dat = ope_date,
           op_typ = pro_libelle, op_length = odp_longueur, op_width = largeur)

test <- dist_passerelle %>% 
  left_join(operation) %>% 
  left_join(dispositif_station, by = c("sta_id" = "dis_sta_id")) %>% 
  left_join(dispositif_collecte, by = c("dis_dic_id" = "dic_id")) %>% 
  left_join(select(ref_protocole, pro_id, pro_libelle), by = c("ope_pro_id" = "pro_id")) %>% 
  filter(pro_libelle =="Indice Abondance Anguille")
  

# Selection anguilles BV Loire

data_ang <- passerelle %>% 
  mef_ajouter_dept() %>% 
  filter(dept %in% c(03, 17, 18, 36, 37, 41, 43, 44, 45, 49, 53, 58, 63, 71, 72,
                   85, 86)) %>% 
  left_join(y = lot_poissons %>%
              select(lop_id,
                     esp_id = lop_esp_id,
                     lop_effectif)) %>%
  left_join(y = ref_espece %>%
              select(esp_id,
                     esp_code_alternatif)) %>% 
  select(-esp_id) %>% 
  filter(esp_code_alternatif == "ANG")

# Calcul densités

data_ang <- data_ang %>% 
  left_join(y = operation %>%
              select(ope_id, ope_date, ope_surface_calculee)) %>% 
  group_by(ope_id, ope_date,
           esp_code_alternatif,
           ope_surface_calculee) %>% 
  summarise(effectif = sum(lop_effectif)) %>% 
  ungroup() %>% 
  mutate(densite_p_1000_m2 = 1000 * effectif / ope_surface_calculee) %>% 
  select(-ope_surface_calculee) # suppressio de la variable désormais inutile

# Ajout date et localisation

## conversion coordonnées

station <- station %>%
  left_join(y = ref_type_projection,
            by = c("sta_typ_id" = "typ_id"))

coords_wgs84 <- geo_convertir_coords_df(df = station,
                                        var_x = "sta_coordonnees_x",
                                        var_y = "sta_coordonnees_y",
                                        var_id = "sta_id",
                                        var_crs_initial = "typ_code_epsg",
                                        crs_sortie = 4326) %>%
  rename(x_wgs84 = X, y_wgs84 = Y)

station <- station %>%
  left_join(y = coords_wgs84) %>%
  select(-(sta_geometrie:typ_code_epsg))



## Ajout sta_id

data_loc <- data_ang %>% 
  left_join(y = dist_passerelle,
            by = "ope_id") %>% 
  left_join(y = coords_wgs84,
            by = "sta_id") %>% 
  filter(!is.na(x_wgs84))

station_geo <- data_loc %>%
  sf::st_as_sf(coords = c("x_wgs84", "y_wgs84"),
               crs = 4326)

station_ASPE <- station %>%
  sf::st_as_sf(coords = c("x_wgs84", "y_wgs84"),
               crs = 4326)

mapview::mapview(station_geo, color = "green")+ mapview::mapview(station_ASPE)




################
# Data Hub'eau
################


