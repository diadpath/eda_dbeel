exit
# just to be safe and not launch this
# remove existing tables
psql -U postgres -c "drop table if exists sudoang.spain_obstruction" dbeel
psql -U postgres -c "drop table if exists sudoang.catalonia_obstruction" dbeel
psql -U postgres -c "drop table if exists sudoang.catalonia_obstruction_dams" dbeel
psql -U postgres -c "drop table if exists  sudoang.catalonia_obstruction_hpp" dbeel
psql -U postgres -c "drop table if exists  sudoang.minho_obstruction" dbeel
psql -U postgres -c "drop table if exists  sudoang.amber" dbeel
psql -U postgres -c "drop table if exists  sudoang.fcul_obstruction" dbeel
psql -U postgres -c "drop table if exists  sudoang.galicia_obstruction" dbeel
psql -U postgres -c "drop table if exists  sudoang.catalonia_obstruction_join_dams_hpp" dbeel
psql -U postgres -c "drop table if exists  sudoang.spain_obstruction_in_spain" dbeel
psql -U postgres -c "drop table if exists  sudoang.spain_obstruction_not_in_spain" dbeel

-- go to GT2 A21 Définition of data.... I've put three dump there ....
psql -U postgres -f "all_obstacle_tables_except_dbeel.sql"  dbeel
psql -U postgres -f "portugese_dam.sql"  dbeel
psql -U postgres -f "dbeel_tables.sql"  dbeel

Maria also to do (but it's too slow from home you can do this much faster and it will save a bear!!)
dump of rivers to dbeel 

pg_dump -U postgres --table spain.rivers -f "spain.rivers.sql" eda2.0
psql -U postgres  -c "create extension ltree" dbeel
psql -U postgres -f "spain.rivers.sql" dbeel


ALTER TABLE spain.rivers
 ALTER COLUMN geom TYPE geometry(MultiLineString,3035) 
  USING ST_Transform(geom,3035);

REINDEX TABLE spain.rivers;

-----------------
-- DUMP QUERIES (for memory)
----------------
-- we have copied rivers to dbeel, and created an index
pg_dump -U postgres --table spain.rivers -f "spain_rivers_dbeel.sql" dbeel

pg_dump -U postgres --table sudoang.spain_obstruction --table sudoang.catalonia_obstruction --table sudoang.catalonia_obstruction_dams --table sudoang.catalonia_obstruction_hpp --table sudoang.minho_obstruction --table sudoang.amber  --table sudoang.fcul_obstruction --table sudoang.galicia_obstruction  --table sudoang.catalonia_obstruction_join_dams_hpp  --table sudoang.spain_obstruction_in_spain  --table sudoang.spain_obstruction_not_in_spain -f "all_obstacle_tables_except_dbeel.sql" dbeel

pg_dump -U postgres --table sudoang.dbeel_physical_obstruction  --table sudoang.dbeel_obstruction_place -f "dbeel_tables.sql" dbeel

pg_dump -U postgres --table sudoang.grandes_barragens --table sudoang.mini_hidricas -f "portugese_dam.sql" dbeel


# restauration de obstacle dbeel (envoyé par maria avant le crash)


02/04/2019 ------------------------------------------------------

f:
cd f:/eda/base/eda2.3/
psql -U postgres -f obstacles_dbeel2.sql eda2.3


-- restauration des fichiers envoyés le 02/04 par Maria

MARIA :
pg_dump -U postgres -f update_dbeel_guipuz.sql --table sudoang.guipuz_ope --table sudoang.guipuz_fish --table sudoang.dbeel_electrofishing --table sudoang.dbeel_batch_ope --table sudoang.dbeel_batch_fish eda2.3
CEDRIC
psql -U postgres -c "drop table sudoang.guipuz_ope" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_electrofishing CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_batch_ope  CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_batch_fish  CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.guipuz_fish  CASCADE" eda2.3

psql -U postgres -f update_dbeel_guipuz.sql  eda2.3


#restauration 08/04
-- la sauvegarde ne marche pas, il y a deux c a chcocc
pg_dump -U postgres -f "cantabria_obstacles.sql" --table sudoang.chcocc_obstruction --table sudoang.chcocc_obstruction_gen --table sudoang.chcocc_obstruction_tec --table sudoang.dbeel_obstruction_place --table sudoang.dbeel_physical_obstruction eda2.3

psql -U postgres -c "drop table sudoang.chcocc_obstruction" eda2.3
psql -U postgres -c "drop table sudoang.chcocc_obstruction_gen CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.chcocc_obstruction_tec  CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_obstruction_place  CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_physical_obstruction  CASCADE" eda2.3

psql -U postgres -f cantabria_obstacles.sql  eda2.3

#-------------------------------------------------------------------------------------------
# restauration 17/04

# pg_dump -U postgres -f "all_obstacles_miteco.sql" --table sudoang.dbeel_obstruction_place --table sudoang.dbeel_physical_obstruction --table dbeel_hpp --table sudoang.chcoc_obstruction --table sudoang.chcoc_obstruction_gen --table sudoang.chcoc_obstruction_tec --table sudoang.chebro_obstruction --table sudoang.chebro_obstruction_gen --table sudoang.chebro_obstruction_tec --table sudoang.chguad_obstruction --table sudoang.chguad_obstruction_gen --table sudoang.chguad_obstruction_tec --table sudoang.chmin_obstruction --table sudoang.chmin_obstruction_gen --table sudoang.chmin_obstruction_tec --table sudoang.chseg_obstruction --table sudoang.chseg_obstruction_gen --table sudoang.chseg_obstruction_tec eda2.3

f:
cd f:/eda/base/eda2.3/

# drop the tables
psql -U postgres -c "drop table if exists sudoang.dbeel_obstruction_place CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.dbeel_physical_obstruction CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.dbeel_hpp  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chcoc_obstruction  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chcoc_obstruction_gen  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chcoc_obstruction_tec  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chebro_obstruction  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chebro_obstruction_tec  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chguad_obstruction  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chguad_obstruction_gen  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chguad_obstruction_tec  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chmin_obstruction  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chmin_obstruction_gen  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chmin_obstruction_tec  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chseg_obstruction  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chseg_obstruction_gen  CASCADE" eda2.3
psql -U postgres -c "drop table if exists sudoang.chseg_obstruction_tec  CASCADE" eda2.3
# restauration
psql -U postgres -f cantabria_obstacles.sql  eda2.3
# 17/04/2019 OK done

#-------------------------------------------------------------------------------------------


#pg_dump -U postgres -f "all_dams_ura.sql" --table sudoang.dbeel_obstruction_place --table sudoang.dbeel_physical_obstruction --table sudoang.bc_obstruction_dams eda2.3


f:
cd f:/eda/base/eda2.3/
psql -U postgres -c "drop table sudoang.dbeel_obstruction_place  CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_physical_obstruction  CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.bc_obstruction_dams   CASCADE" eda2.3
psql -U postgres -f all_dams_ura.sql  eda2.3
psql -U postgres -c "reindex table sudoang.dbeel_obstruction_place" eda2.3
psql -U postgres -c "reindex table sudoang.dbeel_physical_obstruction" eda2.3



#--------------------------------------------------------------------------------------------------
15/05/2019
#pg_dump -U postgres -f "dams_portugal.sql" --table sudoang.dbeel_obstruction_place --table sudoang.dbeel_physical_obstruction --table sudoang.fcul_obstruction_dams --table sudoang.fcul_obstruction_hpp eda2.3
f:
cd f:/eda/base/eda2.3/

psql -U postgres -c "drop table sudoang.dbeel_obstruction_place  CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_physical_obstruction  CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.fcul_obstruction_dams   CASCADE" eda2.3
psql -U postgres -c "drop table sudoang.fcul_obstruction_hpp   CASCADE" eda2.3
psql -U postgres -f dams_portugal.sql  eda2.3
psql -U postgres -c "reindex table sudoang.dbeel_obstruction_place" eda2.3
psql -U postgres -c "reindex table sudoang.dbeel_physical_obstruction" eda2.3


#-------------------------------------------------------------------------------------------
# pg_dump -U postgres -f "rna_portugal.sql" --table portugal.rna eda2.3
f:
cd f:/eda/base/eda2.3/
psql -U postgres -c "drop table portugal.rna  CASCADE" eda2.3
psql -U postgres -f rna_portugal.sql  eda2.3
psql -U postgres -c "reindex table portugal.rna" eda2.3

#------------------------------------------------------------------------------------------------
17/05 missing data for distance sea
f:
cd f:/eda/base/eda2.3/
pg_dump -U postgres -f "temp_missing_rios_frontier_portugal.sql" --table spain.temp_missing_rios_frontier_portugal eda2.3
#--------------------------------------------------------------------------------------------------
# dump to Maria
E:
cd E:/eda/base/eda2.3/
pg_dump -U postgres --clean -f "rn_rna_portugal.sql" --table portugal.rn --table portugal.rna eda2.3

pg_dump -U postgres --clean -f "rn_rna_spain.sql" --table spain.rn --table spain.rna eda2.3

# Restore database ROE

psql -U postgres -c "create database geobs092019"
psql -U postgres -c "create extension postgis" geobs092019
psql -U postgres -c "create user geobs_p password 'geobs_p';   create user geobs_r password 'geobs_r';" geobs092019
# 2>&1 dumps error stream to stdout 
PGPASSWORD=postgres psql -U postgres -f 2019_09_12_111038_geobs.sql geobs092019 2>&1> 1.log
psql -U postgres -c "drop table geobs.utilisateur cascade" geobs092019 

# iEn passant par un pipe il y a des problèmes d'encoding, test sans pour roe
pg_dump -U postgres -f "roe.sql" --verbose --schema roe geobs092019
psql -U postgres -c "drop schema roe cascade" eda2.3
psql -U postgres -f "roe.sql" eda2.3

pg_dump -U postgres -f "ice.sql" --verbose --schema ice geobs092019
psql -U postgres -c "drop schema ice cascade" eda2.3
psql -U postgres -f "ice.sql" eda2.3

pg_dump -U postgres -f "bdoe.sql" --verbose --schema bdoe geobs092019
psql -U postgres -c "drop schema bdoe cascade" eda2.3
psql -
U postgres -f "bdoe.sql" eda2.3

#----------------------------------------------------------------------------------------------------
#-------------------------------- Basins ------------------------------------------------------------
#---------------------------------------------------------------------------------------------------

cd E:\eda\shape\sudoang\subcuencas
shp2pgsql -s 25830 -W LATIN1 -I A_Cuencas_1.shp spain.basin_uni > basin_uni.sql
psql -U postgres -f basin_uni.sql eda2.3

shp2pgsql -s 25830 -W LATIN1 -a -I A_Cuencas_2.shp spain.basin_uni > basin_uni2.sql
psql -U postgres -f basin_uni2.sql eda2.3

shp2pgsql -s 25830 -W LATIN1 -a -I M_Cuencas_1.shp spain.basin_uni > basin_uni3.sql
psql -U postgres -f basin_uni3.sql eda2.3

shp2pgsql -s 25830 -W LATIN1 -a -I M_Cuencas_2.shp spain.basin_uni > basin_uni4.sql
psql -U postgres -f basin_uni4.sql eda2.3

cd C:\use\azti\sudoang\data\base
# pg_dump -U postgres -f "basin_uni.sql" --table spain.basin_uni eda2.3 -- so big, it doesn't work to share!
pg_dump -U postgres -f "basin_uni_without_geom.sql" --table spain.basin_uni_bis eda2.3

# notes


#-----------------
#restoration MARIA 17/10/2019 Rennes
#-----------------

DROP TABLE if exists sudoang.catalonia_location CASCADE;
DROP TABLE if exists sudoang.fcul_obstruction CASCADE;
DROP TABLE if exists sudoang.galicia_location CASCADE;
DROP TABLE if exists sudoang.sp_location CASCADE;

E:
cd E:\eda\base\eda2.3

#2.	PG DUMP FAITES par María (tout est sur le drive https://drive.google.com/drive/u/1/folders/1L5EPymQR9gxyfvzny_N5Ph71_O7XyTwu) :
psql -U postgres -f "andalucia_asturias.sql" eda2.3
--table sudoang.andalucia_fish
--table sudoang.andalucia_obstruction_hpp 
--table sudoang.andalucia_ope 
--table sudoang.andalucia_station 
--table sudoang.asturias_fish 
--table sudoang.asturias_ope 


psql -U postgres -f "basque_country_catalonia_electro.sql" eda2.3
--table sudoang.bc_fish_bis 
--table sudoang.bc_ope 
--table sudoang.bc_ope_bis 
--table sudoang.bc_station 
--table sudoang.bc_station_bis 
--table sudoang.catalonia_fish 
--table sudoang.catalonia_ope 
--table sudoang.catalonia_station 


psql -U postgres -f "basin_miteco_obstruction.sql" eda2.3
--table sudoang.chebro_obstruction 
--table sudoang.chebro_obstruction_tec 
--table sudoang.chguad_obstruction 
--table sudoang.chguad_obstruction_tec 
--table sudoang.chguad_obstruction_gen 
--table sudoang.chmin_obstruction 
--table sudoang.chmin_obstruction_tec 
--table sudoang.chmin_obstruction_gen 
--table sudoang.chseg_obstruction 
--table sudoang.chseg_obstruction_tec 
--table sudoang.chseg_obstruction_gen 

psql -U postgres -c "drop table sudoang.dbeel_mensurationindiv_biol_charac cascade" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_batch_fish cascade" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_batch_ope cascade" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_electrofishing cascade" eda2.3
psql -U postgres -c "drop table sudoang.dbeel_station cascade" eda2.3
psql -U postgres -f "dbeel_electro.sql" eda2.3
--table sudoang.dbeel_batch_fish 
--table sudoang.dbeel_batch_ope 
--table sudoang.dbeel_electrofishing 
--table sudoang.dbeel_mensurationindiv_biol_charac 
--table sudoang.dbeel_station 
eda2.3

psql -U postgres -f "mensuration.sql" eda2.3

psql -U postgres -f "galicia_gt6_electro.sql" eda2.3 
--table sudoang.galicia_fish 
--table sudoang.galicia_ope 
--table sudoang.galicia_station 
--table sudoang.gt6_bages_fish 
--table sudoang.gt6_fish 
--table sudoang.gt6_ope 
--table sudoang.gt6_station 


psql -U postgres -f "minho_navarra_electro.sql" eda2.3
--table sudoang.minho_fish 
--table sudoang.minho_ope 
--table sudoang.minho_station 
--table sudoang.navarra_fish 
--table sudoang.navarra_ope 
--table sudoang.navarra_station 

#belen 
psql -U postgres -f "portugal_spain_electro.sql" eda2.3
--table sudoang.portugal_fish 
--table sudoang.portugal_fish_bis 
--table sudoang.portugal_location_bis 
--table sudoang.portugal_ope_bis 
--table sudoang.spain_fish 
--table sudoang.spain_ope 
--table sudoang.spain_station 


psql -U postgres -f "valencia_electro_width.sql" eda2.3
--table sudoang.valencia_fish 
--table sudoang.valencia_sta_ope 
--table sudoang.valencia_station 
--table sudoang.width_electro2 
eda2.3

pg_dump -U postgres -f 'barrage.sql' --table sudoang.dbeel_obstruction_place --table sudoang.dbeel_physical_obstruction --table sudoang.dbeel_hpp --table sudoang.dbeel_turbine --table sudoang.dbeel_bypass eda2.3
dbeel_bypass
dbeel_hpp
dbeel_obstruction
dbeel_physical_obstruction
dbeel_turbine


psql -U postgres -c "drop table dbeel_bypass cascade" eda2.3
psql -U postgres -c "drop table dbeel_turbine cascade" eda2.3
psql -U postgres -c "drop table dbeel_hpp cascade" eda2.3
psql -U postgres -c "drop table dbeel_physical_obstruction cascade" eda2.3
psql -U postgres -c "drop table dbeel_obstruction_place cascade" eda2.3
psql -U postgres -f 'barrage.sql' eda2.3



select count(*) from sudoang.dbeel_physical_obstruction; 10571

select count(*), date_last_update from sudoang.dbeel_physical_obstruction group by (date_last_update);
count;date_last_update
20492;
80324;2019-10-14
738;2019-04-16
25;2019-04-09

select date_last_update 

select count(*), country from sudoang.dbeel_obstruction_place group by country

count;country
20606;SP
666;PT
80324;FR


select count(*) from sudoang.dbeel_hpp
select count(*) from sudoang.dbeel_bypass
select count(*) from sudoang.dbeel_turbine

#Dump for soizic
F:
cd eda/base/eda2.3
pg_dump -U postgres -f "dbeel_schema.sql" --schema dbeel_nomenclature --schema dbeel --verbose eda2.3
pg_dump -U postgres -f "river_schema.sql" --schema dbeel_rivers --schema france --schema spain --verbose eda2.3



cd F:\eda\shape\bd_carthage_2016
F:
shp2pgsql -s 2154 -W LATIN1 -I SousSecteurHydro.shp france.soussecteurhydro > soussecteur.sql
shp2pgsql -s 2154 -W LATIN1 -I - p SousSecteurHydro.shp france.soussecteurhydro > soussecteur.sql
psql -U postgres -f soussecteur.sql eda2.3 


F:
cd eda/base/eda2.3
psql -U postgres -f dbeel_mensuration.sql eda2.3



F:
cd eda/base/eda2.3
psql -U postgres -f width_andalucia.sql eda2.3


F:
cd eda/base/eda2.3

pg_dump -U postgres -f "width.sql" --table raster_width.rnsubset --table raster_width.rnsubsetpo  eda2.3
pg_dump -U postgres -f "river_schema.sql" --schema dbeel_rivers --schema france --verbose eda2.3
-- A lancer
psql -U postgres -c "create schema raster_width" eda2.3
psql -U postgres -f "width.sql" eda2.3

# Pour Marion
F:
cd eda/base/eda2.3
pg_dump -U postgres -f "dbeel_schema.sql" --schema dbeel_nomenclature --schema dbeel --verbose eda2.3
pg_dump -U postgres -f "river_schema_france.sql" --schema dbeel_rivers --schema france --verbose eda2.3
pg_dump -U postgres -f "river_schema_spain.sql"  --table spain.rn --table spain.rn_rna --table spain.rna --verbose eda2.3


F:
cd eda/base/eda2.3
pg_dump -U postgres -f "ref.tr_country_cou.sql" --table ref.tr_country_cou --verbose wgeel
pg_dump -U postgres -f "france.join_obstruction_rn" --table france.join_obstruction_rn --verbose eda2.3


############
#Sauvegarde de la table de prediction des river width
10/11/2019
###########


F:
cd eda/base/eda2.3
pg_dump -U postgres -f "ref.riverwidth_spain_portugal.sql" --table riverwidth_spain_portugal eda2.3


#####################
# Tranfert des données de station dans eda2.3 
########################

F:
cd eda/base/eda2.3
pg_dump -U postgres -f "bdmap_rht.sql" --table bd_agglo_2017.bdmap_rht eda2.2
pg_dump -U postgres -f "rsa_rht.sql" --table rsa.rsa_rht eda2.2
psql -U postgres -c "create schema bd_agglo_2017" eda2.3
psql -U postgres -c "create schema rsa" eda2.3
psql -U postgres -f "bdmap_rht.sql" eda2.3
psql -U postgres -f "rsa_rht.sql" eda2.3
psql -U postgres -c "ALTER TABLE rsa.rsa_rht set schema france" eda2.3
psql -U postgres -c "ALTER TABLE bd_agglo_2017.bdmap_rht DROP CONSTRAINT pk_id" eda2.3
psql -U postgres -c "ALTER TABLE bd_agglo_2017.bdmap_rht set schema france" eda2.3
psql -U postgres -c "drop schema bd_agglo_2017 CASCADE" eda2.3
psql -U postgres -c "drop schema rsa CASCADE" eda2.3


################################
#06/12/2019 sauvegarde du wgeel
#################################
cd wgeel
C:/"Program Files"/PostgreSQL/10/bin/pg_dump -U postgres -f "wgeel.sql" wgeel


######################################
# 10/01/2020
# saved from CEDRIC restored to MARIA
######################################
F:
cd eda/base/eda2.3
pg_dump -U postgres -f 'barrage.sql' --table sudoang.dbeel_obstruction_place --table sudoang.dbeel_physical_obstruction --table sudoang.dbeel_hpp --table sudoang.dbeel_turbine --table sudoang.dbeel_bypass eda2.3
dbeel_bypass
dbeel_hpp
dbeel_obstruction
dbeel_physical_obstruction
dbeel_turbine

######################################
# 14/01/2020
# saved from CEDRIC restored to MARIA
######################################
F:
cd eda/base/eda2.3
# rna.zip
pg_dump -U postgres -f 'francerna.sql' --table france.rna eda2.3
pg_dump -U postgres -f 'spainrna.sql' --table spain.rna eda2.3
pg_dump -U postgres -f 'portugalrna.sql' --table portugal.rna eda2fra.3

# france_surface.zip
pg_dump -U postgres -f 'france.surface_hydrographique_bdtopo.sql' --table france.surface_hydrographique_bdtopo eda2.3
pg_dump -U postgres -f 'france.surface_hydrographique_bdtopo_unitrht.sql' --table france.surface_hydrographique_bdtopo_unitrht eda2.3
pg_dump -U postgres -f 'france.unit_basin.sql' --table france.unit_basin eda2.3

# spain_surface.zip
#il faut que tu supprimes ta table des bassins unitaires spain.basin_uni
pg_dump -U postgres -f 'spain.masas_agua_unitbv.sql' --table spain.masas_agua_unitbv eda2.3
pg_dump -U postgres -f 'spain.masas_agua.sql' --table spain.masas_agua eda2.3
pg_dump -U postgres -f 'spain.unit_basin.sql' --table spain.unit_basin eda2.3

# portugal_surface.zip

pg_dump -U postgres -f 'portugal.wisewaterbody_unitbv.sql' --table portugal.wisewaterbody_unitbv eda2.3
pg_dump -U postgres -f 'portugal.wisewaterbody.sql' --table portugal.wisewaterbody eda2.3
pg_dump -U postgres -f 'portugal.unit_basin.sql' --table portugal.unit_basin eda2.3



# dump from Maria

pg_dump -U postgres -f 'obstacle_minho.sql' --table sudoang.minho_obstruction_bis eda2.3
F:
cd eda/base/eda2.3
psql -U postgres -f 'obstacle_minho.sql' eda2.3
# STUPIDE IL FAUT LE MEMES UUID

psql -U postgres -c 'drop table sudoang.dbeel_bypass' eda2.3
psql -U postgres -c 'drop table sudoang.dbeel_turbine' eda2.3
psql -U postgres -c 'drop table sudoang.dbeel_hpp CASCADE' eda2.3
psql -U postgres -c 'drop table sudoang.dbeel_physical_obstruction CASCADE' eda2.3
psql -U postgres -c 'drop table sudoang.dbeel_obstruction_place' eda2.3
psql -U postgres -f 'obstacle_restore.sql' eda2.3


# 10/02/2019 saving river Atlas tables to Maria


/*
F:
cd eda/base/eda2.3
pg_dump -U postgres -f "river_atlas.sql" --table france.join_atlas_rn --table portugal.join_atlas_rn --table spain.join_atlas_rn --table europe.riveratlas_v10_eu eda2.3
*/


# 16/02/2019
# saving spain.rn to MARIA
# chained endoreic
# set all stream finishing by an endoreic stream as endoreic
# added path, and seaidsegment for missing basins.
# added function spain.write_path, dbeel_rivers.upstream_segments, spain.get_path
pg_dump -U postgres -f "spain.rn.sql" --table spain.rn eda2.3   




# dump for hilaire

F:
cd eda/base/eda2.3
pg_dump -U postgres -f "rht.dumpforhilaire.sql" --table rht.dcdf2017 --table rht.silver2017 --verbose eda2.3
psql -U postgres -f "rht.dumpforhilaire.sql" eda2.3     


#Width Spain and Portugal for Maria 20/02/2020


F:
cd eda/base/eda2.3
pg_dump -U postgres -f "riverwidth_merit_not_updated.sql" --table public.riverwidth_merit_not_updated eda2.3

# dump for hilaire

F:
cd eda/base/eda2.3
pg_dump -U postgres -f "rht.dumpforhilaire.sql" --table rht.dcdf2017 --table rht.silver2017 --verbose eda2.3
psql -U postgres -f "rht.dumpforhilaire.sql" eda2.3    


# dump didson

F:
cd F:\sauv_base
 C:/"Program Files"/PostgreSQL/10/bin/pg_dump -U postgres -h w3.eptb-vilaine.fr -p 5434 -f "didson.sql" didson    




# dump for hilaire2
F:
cd eda/base/eda2.3
pg_dump -U postgres -f "dbeel_rivers.sql" --table dbeel_rivers.rn --table dbeel_rivers.rna --table dbeel_rivers.rn_rna --verbose eda2.3

pg_dump -U postgres -f "france.sql" --table france.rn --table france.rna --table france.rn_rna --table france.unit_basin --table france.surface_hydrographique_bdtopo_unitrht --verbose eda2.3

pg_dump -U postgres -f "spain.sql" --table spain.rn --table spain.rna --table spain.rn_rna --table spain.unit_basin --table spain.masas_agua_unitbv --verbose eda2.3

pg_dump -U postgres -f "portugal.sql" --table portugal.rn --table portugal.rna --table portugal.rn_rna --table portugal.unit_basin --table portugal.portugal.wisewaterbody_unitbv --verbose eda2.3

# cedric  a les chocottes de tout foutre en l'air

cd "C:/Users/cedric.briand/OneDrive - EPTB Vilaine/partage/EDA"
pg_dump -U postgres -f "c_temp.sql" --table dbeel_rivers.c_temp --verbose eda2.3


# après correction des chemins
# 11/03/2020 

cd "C:/Users/cedric.briand/OneDrive - EPTB Vilaine/partage/EDA"
pg_dump -U postgres -F c -f "dbeel_rivers.backup" --table dbeel_rivers.rn --table dbeel_rivers.rna --table dbeel_rivers.rn_rna --verbose eda2.3

pg_dump -U postgres -F c -f "france.backup" --table france.rn --table france.rna --table france.rn_rna --verbose eda2.3

pg_dump -U postgres -F c -f "spain.backup" --table spain.rn --table spain.rna --table spain.rn_rna  --verbose eda2.3

pg_dump -U postgres -F c -f "portugal.backup" --table portugal.rn --table portugal.rna --table portugal.rn_rna --verbose eda2.3
pg_restore -U postgres -d eda2.3  dbeel_rivers.backup

#SAVE TO MARIA 12/03 after corrections error silver portugal (missing data)



pg_dump -U postgres -F c  -U postgres -f "electro_batch_mensuration.backup" --table sudoang.dbeel_batch_fish --table sudoang.dbeel_batch_ope --table sudoang.dbeel_electrofishing --table sudoang.dbeel_mensurationindiv_biol_charac --table sudoang.portugal_fish_bis --table sudoang.portugal_ope_bis eda2.3

-- script to restore
psql -U postgres -c "DROP TABLE sudoang.dbeel_mensurationindiv_biol_charac  CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.dbeel_batch_fish CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.dbeel_batch_ope  CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.dbeel_electrofishing CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.portugal_fish_bis CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.portugal_ope_bis CASCADE" eda2.3
pg_restore --clean -O -x -U postgres -d eda2.3  electro_batch_mensuration.backup

cd "C:/Users/cedric.briand/OneDrive - EPTB Vilaine/partage/EDA"
pg_dump -U postgres -F c -f "unit_basins.backup" --table france.unit_basin --table france.surface_hydrographique_bdtopo_unitrht --table spain.unit_basin --table spain.masas_agua_unitbv --table portugal.unit_basin --table portugal.portugal.wisewaterbody_unitbv --verbose eda2.3

pg_dump -U postgres -F c -f "riverwidth_spain_portugal.backup" --table riverwidth_spain_portugal --verbose eda2.3


# save to hilaire

pg_dump -U postgres -F c -f "basinunit.backup" --table dbeel_rivers.basinunit_bu  --table france.basinunit_bu --table france.basinunitout_buo --table spain.basinunit_bu --table spain.basinunitout_buo --table portugal.basinunit_bu --table portugal.basinunitout_buo --verbose eda2.3

# save ouvrage
F:
cd F:/sauv_base
C:/"Program Files"/PostgreSQL/10/bin/pg_dump -U postgres -f "ouvrage.backup" -F c --verbse -p 5434 -h w3.eptb-vilaine.fr ouvrage

# 17/03/2020 => corrections basque fish

cd "C:/Users/cedric.briand/OneDrive - EPTB Vilaine/partage/EDA"
 pg_dump -U postgres -F c  -U postgres -f "basque.backup" --table sudoang.dbeel_batch_fish --table sudoang.dbeel_batch_ope --table sudoang.dbeel_electrofishing --table sudoang.dbeel_mensurationindiv_biol_charac --table sudoang.bc_fish_bis  --table sudoang.bc_ope_bis eda2.3
 
 
# restore hilaire table
F:
cd eda/base/eda2.3
C:/"Program Files"/PostgreSQL/10/bin/pg_restore -O -x -U postgres -d eda2.3 asso_eda_gerem.backup
C:/"Program Files"/PostgreSQL/10/bin/pg_restore -O -x -U postgres -d eda2.3 basins2.backup

C:/"Program Files"/PostgreSQL/10/bin/pg_restore -O -c -x -U postgres -d eda2.3 asso_eda_gerem.backup


# dump schema IAV
F:
cd F:\sauv_base
pg_dump -U postgres -h w3.eptb-vilaine.fr -F c  -U postgres -f "iav.backup" --schema iav --verbose bd_contmig_nat_iav
psql -U postgres -c "drop schema iav cascade" bd_contmig_nat
C:/"Program Files"/PostgreSQL/10/bin/pg_restore -U postgres -d bd_contmig_nat iav.backup


pg_dump -U postgres -h w3.eptb-vilaine.fr -U postgres -f "iav.sql" --schema iav --verbose bd_contmig_nat_iav
psql -U postgres -c "drop schema iav cascade" bd_contmig_nat
psql -U postgres -d bd_contmig_nat iav.sqlf:



# restoration des tables de MARIA barrages

# MARIA launched
pg_dump -U postgres -F c  -U postgres -f "shiny_dams_hpp.backup" --table sudoang.dbeel_hpp --table sudoang.dbeel_obstruction_place --table sudoang.dbeel_physical_obstruction --table sudoang.dbeel_turbine --table sudoang.andalucia_obstruction_turbine --table sudoang.andalucia_obstruction_hpp --table sudoang.andalucia_obstruction_dams_shiny --table sudoang.bc_obstruction_hpp --table sudoang.bc_obstruction_turbine --table sudoang.catalonia_obstruction_hpp --table sudoang.catalonia_obstruction_join_dams_hpp --table sudoang.fcul_obstruction_dams_shiny --table sudoang.fcul_obstruction_hpp --table sudoang.fcul_obstruction_turbine --table sudoang.galicia_obstruction_hpp --table sudoang.galicia_obstruction_turbine --table sudoang.spain_obstruction_hpp_bis eda2.3

psql -U postgres -c "DROP TABLE IF EXISTS sudoang.dbeel_turbine CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.dbeel_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.dbeel_physical_obstruction CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.dbeel_obstruction_place CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.andalucia_obstruction_turbine CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.andalucia_obstruction_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.bc_obstruction_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.bc_obstruction_turbine CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.catalonia_obstruction_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.catalonia_obstruction_join_dams_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.fcul_obstruction_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.fcul_obstruction_turbine CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.galicia_obstruction_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.galicia_obstruction_turbine CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.spain_obstruction_hpp_bis CASCADE" eda2.3

C:/"Program Files"/PostgreSQL/10/bin/pg_restore -U postgres -d eda2.3 shiny_dams_hpp.backup

# restoration des tables de MARIA barrages

# MARIA launched

pg_dump -U postgres -F c -U postgres -f "hpp_spain.backup" --table sudoang.dbeel_hpp --table sudoang.dbeel_turbine --table sudoang.spain_obstruction_hpp_bis --table sudoang.spain_obstruction_turbine eda2.3																


psql -U postgres -c "DROP TABLE sudoang.dbeel_turbine CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.dbeel_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE  sudoang.spain_obstruction_hpp_bis CASCADE" eda2.3
C:/"Program Files"/PostgreSQL/10/bin/pg_restore -U postgres -d eda2.3 "hpp_spain.backup"

cd "C:/Users/cedric.briand/OneDrive - EPTB Vilaine/partage/EDA"
pg_dump -U postgres -F c -U postgres -f "dbeel_rivers.transport.sql" --table dbeel_rivers.transport eda2.3


# envoi à Clarisse

C:/"Program Files"/PostgreSQL/10/bin/pg_dump -U postgres -F c -U postgres -f "rsa.backup" --schema rsa eda2.2
C:/"Program Files"/PostgreSQL/10/bin/pg_restore -U postgres -d EDA rsa.backup


# restoration de la table de Maria pour comparaison
F:
cd eda/base/eda2.3
C:/"Program Files"/PostgreSQL/10/bin/pg_restore -U postgres -d EDA fr_join_obstruction_rn_downstream.backup


# changement pour toutes les bases

cd sauv_base
C:/"Program Files"/PostgreSQL/12/bin/pg_dumpall -U postgres -f "sauv_all.sql
# sauvegarde que les rôles
-- marche pas

C:/"Program Files"/PostgreSQL/12/bin/pg_dumpall -g -U postgres -f "sauv_all.sql"
C:/"Program Files"/PostgreSQL/12/bin/psql -U postgres -p 5433 -f "sauv_all.sql"

C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -C -f bd_capt_nat.sql bd_capt_nat
C:/"Program Files"/PostgreSQL/12/bin/psql -U postgres -p 5433 -f "bd_capt_nat.sql 
C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -C --inserts --schema migadotemp --schema adourtemp -f bd_contmig_nat_migadotemp_adourtemp.sql bd_contmig_nat
psql -U postgres -c "drop schema migadotemp CASCADE" bd_contmig_nat
psql -U postgres -c "drop schema adourtemp CASCADE" bd_contmig_nat
C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -C --inserts -f bd_contmig_nat.sql bd_contmig_nat
C:/"Program Files"/PostgreSQL/12/bin/psql -U postgres -p 5433 -f "bd_contmig_nat.sql 
C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -C -F c -f datawgeel.backup datawgeel
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -U postgres -p 5433 -f datawgeel.backup
C:\Program Files\PostgreSQL\9.5\data postgresql.conf edit change port for 9.6 and 12
service postgresql restart



C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -C -Fc --verbose -f eda2.3.backup eda2.3
C:/"Program Files"/PostgreSQL/12/bin/createdb "eda2.2" -p 5433
C:/"Program Files"/PostgreSQL/12/bin/psql -U postgres -p 5433 create extension postgis eda2.3
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5433 -U postgres -f eda2.3.backup eda2.3

C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -Fc --verbose -f eda2.2.backup eda2.2
C:/"Program Files"/PostgreSQL/12/bin/createdb -U postgres -p 5432 eda2.2
C:/"Program Files"/PostgreSQL/12/bin/psql -U postgres -p 5432 -c "create extension postgis" eda2.2
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5432 -U postgres -d eda2.2 eda2.2.backup



C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -Fc --verbose -f datawgeel.backup datawgeel
C:/"Program Files"/PostgreSQL/12/bin/createdb -U postgres -p 5433 datawgeel
C:/"Program Files"/PostgreSQL/12/bin/psql -U postgres -p 5432 -c "create extension postgis" datawgeel
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5432 -U postgres -d datawgeel datawgeel.backup





C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -Fc --verbose -f expor.backup expor
C:/"Program Files"/PostgreSQL/12/bin/createdb -U postgres -p 5432 expor
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5432 -U postgres -d expor expor.backup

C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -Fc --verbose -f geobs092019.backup geobs092019
C:/"Program Files"/PostgreSQL/12/bin/createdb -U postgres -p 5432 geobs092019
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5432 -U postgres -d geobs092019 geobs092019.backup


C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -Fc --verbose -p 5436 -f hilaire_rht.backup hilaire_rht
C:/"Program Files"/PostgreSQL/12/bin/createdb -U postgres -p 5432 hilaire_rht
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5432 -U postgres -d hilaire_rht hilaire_rht.backup

C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres -Fc --verbose -p 5436 -f wgeel.backup wgeel
C:/"Program Files"/PostgreSQL/12/bin/createdb -U postgres -p 5432 wgeel
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5432 -U postgres -d wgeel wgeel.backup

C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres --verbose -f eda_gerem.temp_gerem.sql --table eda_gerem.temp_gerem eda2.3
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5432 -U postgres -d eda2.3 assoc_dbeel_rivers.backup


C:/"Program Files"/PostgreSQL/12/bin/pg_dump -U postgres --verbose -Fc -f assoc_dbeel_rivers.backup --table eda_gerem.assoc_dbeel_rivers eda2.3



pg_dump -U postgres -F c -U postgres -f "gt6_19_20.backup" --table sudoang.gt6_station2 --table sudoang.gt6_ope2 --table sudoang.gt6_fish2 --table sudoang.dbeel_station --table sudoang.dbeel_electrofishing --table sudoang.dbeel_batch_ope --table sudoang.dbeel_batch_fish --table sudoang.dbeel_mensurationindiv_biol_charac eda2.3											

Avant tu pg_restore, tu devrais faire : 

psql -U postgres -c "DROP TABLE sudoang.dbeel_station CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.dbeel_electrofishing CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.dbeel_batch_ope CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.dbeel_batch_fish CASCADE" eda2.3
psql -U postgres -c "DROP TABLE sudoang.dbeel_mensurationindiv_biol_charac CASCADE" eda2.3

F:
cd eda/base/eda2.3
C:/"Program Files"/PostgreSQL/12/bin/pg_restore -p 5432 -U postgres -d eda2.3 gt6_19_20.backup


-- fichiers pour hilaire




restoration de la base de données geobs

-- creation d'une base geobs072020
-- creation d'une base postgis
cd F:\eda\data\eda2.3\damsfr
CREATE EXTENSION postgis;
ALTER SCHEMA public RENAME TO postgis;
CREATE SCHEMA public;
CREATE EXTENSION tablefunc;


pg_restore -p 5432 -U postgres -d geobs072020 geobs_export_eptb_vilaine_20200721.backup


--18/12


pg_dump -U postgres -F c -f "dams_hpp.backup" --table sudoang.dbeel_hpp --table sudoang.dbeel_obstruction_place --table sudoang.dbeel_physical_obstruction --table sudoang.dbeel_turbine --table sudoang.view_dbeel_hpp   eda2.3
# pour maria
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.dbeel_turbine CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.dbeel_hpp CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.dbeel_physical_obstruction CASCADE" eda2.3
psql -U postgres -c "DROP TABLE IF EXISTS sudoang.dbeel_obstruction_place CASCADE" eda2.3



# lancer vues ....
view_obstruction.sql

Import flow
pg_dump -U postgres -F c -f "flows.backup" --table dbeel_rivers.rn_gt2 --table dbeel_rivers.basins_gt2 --table france.rn_gt2 --table spain.rn_gt2 --table portugal.rn_gt2 --table sudoang.hydro_stations_gt2 --table sudoang.sous_secteurs_hydros_gt2 --table sudoang.hydro_station_gt2_quantile --table sudoang.hydro_segment_gt2_quantile eda2.3



pg_dump -U postgres -F c -f "predictions.backup" --table dbeel_rivers.rn_rna_cumul_silver --table dbeel_rivers.rn_rna_model eda2.3



pg_dump -U postgres -F c  -U postgres -f "schema_sudoang.backup" --schema sudoang   eda2.3
pg_dump -U postgres -F c  -U postgres -f "schema_france.backup" --schema france   eda2.3
pg_dump -U postgres -F c  -U postgres -f "schema_spain.backup" --schema spain   eda2.3
pg_dump -U postgres -F c  -U postgres -f "schema_portugal.backup" --schema portugal   eda2.3



# eda2.2
pg_dump -U postgres -Fc -f "rht.ers_full_2017.backup" --table rht.ers_full_2017 eda2.2



#  Problems with path in Maria table
F:
cd eda/base/eda2.3
pg_dump -U postgres -Fc -f "spain.temp_correct_path.sql" --table spain.temp_correct_path eda2.3
pg_restore -U postgres -f "spain.temp_correct_path.sql" eda2.3
psql -U postgres -c "update spain.rn set path = ttt.path FROM spain.temp_correct_path ttt where ttt.idsegment=rn.idsegment" eda2.3



pg_dump -U postgres -Fc -f "temp_temporales_rn.backup" --table spain.temp_temporales_rn --table portugal.temp_temporales_rn eda2.3
pg_restore -U postgres -f "spain.temp_temporales_rn.backup" eda2.3


F:
cd eda/base/eda2.3

-----
script noemie
------

attention mot de passe postgre 

createdb -U postgres eda2.3
create schema dbeel_rivers
create schema france;
create schema spain;
create schema portugal;
create extension "postgis";
create extension "uuid-ossp"; 
create extension "dblink"; 
create extension "ltree"; 
create extension "tablefunc";

pg_dump -U posgtres -Fc -f "rn.backup" --table dbeel_rivers.rn --table france.rn --verbose eda2.3
pg_restore -U postgres -d eda2.3 rn.backup 

code pour vues rn_rna
code pour vues rn_rne
dump rna rne surface_hydrographique_bdtopo_unitrht
basin_uni
view dams
view electrofishing 


# exchange Colm

pg_dump -U postgres -f "dbeel.backup" -Fc -h 185.135.126.250 --schema dbeel_nomenclature --schema dbeel eda2.0
pg_restore -U postgres -d eda2.0 dbeel.backup

pg_dump -U postgres -Fc  -h 185.135.126.250 -p 5432 --schema ccm21 -f "ccm.backup" eda2.0 
pg_restore -U postgres -d eda2.0 ccm.backup

pg_dump -U postgres -Fc  -h 185.135.126.250 -p 5432 --schema europe -f "europe.backup" eda2.0 
pg_restore -U postgres -d eda2.0 europe.backup


pg_dump -U postgres -Fc  -h 185.135.126.250 -p 5432 --schema wrbd --schema ireland -f "ireland.backup" eda2.0 
pg_restore -U postgres -d eda2.0 ireland.backup

pg_dump -U postgres -Fc  -h 185.135.126.250 -p 5432 --schema dmeer2003 --schema europe --schema ecoregion2003 --schema european_wise2008   eda2.0


F:\eda\base\eda2.3>pg_dump -U postgres -f "portugalrne.backup" --table portugal.rne --verbose -Fc eda2.3
pg_restore -U postgres -d eda2.3 portugalrne.backup


-- EXPORT LAURENT ET THIBAULT
cd f:/eda/base/eda2.2.1


psql -U postgres -c "create schema rht" eda2.2
psql -U postgres -f "devalaison.sql" eda2.2

-- export Noémie

pg_dump -U postgres -f "coutry_emu.backup" --table ref.tr_emu_emu --table ref.tr_country_cou --verbose -Fc wgeel



createdb wgeel
psql -U postgres -c "create schema ref" wgeel
pg_restore -U postgres -d wgeel coutry_emu.backup


-- pour MARIA

cd F:\eda\base\eda2.3
f: 
pg_dump -U postgres -f "france.tr_lagunes.backup" --table france.tr_lagunes -Fc eda2.3
pg_dump -U postgres -f "france.waterbody_unitbv.backup" --table france.waterbody_unitbv -Fc eda2.3


pg_dump -U postgres -f "portugal.waterbody_unitbv.backup" --table portugal.waterbody_unitbv -Fc eda2.3


psql -U postgres -c "DROP table portugal.waterbody_unitbv" eda2.3
pg_restore -d eda2.3 -U postgres portugal_waterbody_unitbv.backup 

cd F:\eda\base\eda2.3
f: 
psql -U postgres -c "drop table spain.join_obstruction_rn_downstream;" eda2.3
psql -U postgres -c "drop table dbeel.join_obstruction_rn_downstream;" eda2.3
pg_restore -U postgres -d  eda2.3 "join_obstruction_rn_downstream.backup"


-- Pour Denis 07/02/2021 ------------------------------------------------------------
-- structure de la base

pg_dump -U postgres -s  -c -Fc "eda2.3.backup" eda2.3
pg_dump -U postgres --schema dbeel --schema dbeel_nomenclature -Fc -f "dbeel.backup" eda2.3
pg_dump -U postgres --schema dbeel_rivers --schema france -Fc -f "dbeel_rivers.backup" eda2.3
pg_dump -U postgres --schema sudoang -Fc -f "sudoang.backup" eda2.3



