----------------------------------
-- Creating schema SUDOANG
-----------------------------------
CREATE SCHEMA sudoang;
SET search_path TO sudoang, spain, public;
-- SHOW search_path;

----------------------------------
-- SIBIC database
-----------------------------------
select * from sudoang.location limit 10;
alter table sudoang.location add constraint c_pk_locationid primary key (locationid);

---- Ckecking some columns (character encoding): the problem was the name of columns
SELECT * FROM sudoang.location WHERE locationid = '1437'; 
SELECT * FROM sudoang.location WHERE "HydrographicBasin_ES" = 'Tajo';

select * from sudoang.species_location limit 10;

---- Adding a geometry column 
select addgeometrycolumn('sudoang','location','geom', 25830, 'point',2);
update sudoang.location set geom= ST_Transform(ST_SetSRID(ST_MakePoint("Y", "X"),4326), 25830); -- 10839 rows, 334 msec


---------------------------------------------
-- PRIMARY RESOURCES FROM SIBIC DATABASE:
---- JOINING ID STATIONS 
---------------------------------------------

---- EBRO data
---------------
SELECT * FROM sudoang.ebro_location limit 10;
SELECT * FROM sudoang.ebro_location WHERE "Localidad" LIKE ('Sanavastre');

-- SET client_encoding = 'UTF8'; 

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','ebro_location','geom', 25830, 'point',2);
-- UPDATE sudoang.ebro_location SET "UTM.Y" = '4684398' WHERE "UTM.Y" = '46884398'; -- Error 
update sudoang.ebro_location set geom= ST_SetSRID(ST_MakePoint("UTM.X", "UTM.Y"),25830); -- WHERE "IBI" NOT IN ('IBI 341', 'IBI 345', 'IBI 361', 'IBI 348'); -- 369 rows affected, 47 msec

-- place_classification corresponds to the operations, but only 3 rows are duplicated
SELECT count(*) FROM sudoang.ebro_location; -- 369 rows
SELECT count(distinct geom) FROM sudoang.ebro_location; -- 366 rows

-- Length and width aren't included in the sibic table (check in the dbeel database where sibic table has already imported)
SELECT * FROM sudoang.ebro_location where place_classification='(IBI033)'; -- 54 m length and 6.3 m width
SELECT * FROM sudoang.stationdbeel where place_classification='(IBI033)';  -- locationid = 258166863
SELECT * FROM sudoang.electrofishing where locationid = '258166863'; -- no length no width

SELECT * FROM sudoang.ebro_location where place_classification='(IBI072)'; -- 60 m length and 2.37 m width
SELECT * FROM sudoang.stationdbeel where place_classification='(IBI072)';  -- locationid = 27649674


---- DOADRIO DATABASE (data from 11 communities)
-------------------------------------------------
SELECT * FROM sudoang.doadrio_location limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','doadrio_location','geom', 25830, 'point',2);
update sudoang.doadrio_location set geom= ST_SetSRID(ST_MakePoint("X", "Y"),25830); -- 754 rows affected, 62 msec
-- Notes: Like in EBRO, there are data that are showing in wrong location (Andalucia, Galicia, etc)


---- CATALONIA data 07/08 (BD_IBICAT CPE)
------------------------------------------
SELECT * FROM sudoang.ibicat_location limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','ibicat_location','geom', 25830, 'point',2);
update sudoang.ibicat_location set geom= ST_SetSRID(ST_MakePoint("UTM_ED50_X", "UTM_ED50_Y"),25830); -- 364 rows affected, 34 msec
-- Notes: "COD_EST" from BD_IBICAT CPE table corresponds to "place_classification" from location (sibic database)
-- Notes II: all data are showing in wrong location (the opossite)


---- CANTABRIA data 10-13 (Datos peces Cantabria 2010-2013)
-------------------------------------------------------------
SELECT * FROM sudoang.cantabria_location limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','cantabria_location','geom', 25830, 'point',2);
update sudoang.cantabria_location set geom= ST_SetSRID(ST_MakePoint("X", "Y"),25830); -- 276 rows affected, 30 msec
-- Notes: ID station is missing!!!


---- LEVANTE data 2011 (Levante PECES_2011)
---------------------------------------------
SELECT * FROM sudoang.levante_location limit 10;

---- Impossible to add a geometry column because there are not coordinates (but they are in location table from SIBIC)
-- Notes: "PMSPCOD" and "OTROS_CODIGOS" correspond to "place_classification" from location (sibic database)


---- NSp_EFIplus DATABASE (4 northern communities involved)
-------------------------------------------------------------
SELECT * FROM sudoang.nsp_efiplus_location limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','nsp_efiplus_location','geom', 25830, 'point',2);
update sudoang.nsp_efiplus_location set geom= ST_Transform(ST_SetSRID(ST_MakePoint("longitude", "latitude"),4326), 25830); -- 1848 rows affected, 44 msec


---- BASQUE COUNTRY data 93-13 (PECES_URSAREA)
-----------------------------------------------
SELECT * FROM sudoang.ursarea_location limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','ursarea_location','geom', 25830, 'point',2);
update sudoang.ursarea_location set geom= ST_SetSRID(ST_MakePoint("UTMXETRS89", "UTMYETRS89"),25830); -- 16601 rows affected, 443 msec
-- Notes: "COD_ESTACION " corresponds to "place_classification" from location (sibic database)

SELECT distinct "ESTACION" FROM sudoang.ursarea_location -- 192 stations
CREATE TABLE sudoang.ursarea_loc_eels_measure
AS
SELECT * FROM sudoang.ursarea_location WHERE "VARIABLE" = 'Longitud media' and "ESPECIE" = 'Anguilla anguilla';
SELECT * FROM ursarea_loc_eels_measure



----------------------------------
-- UPDATED database
-----------------------------------

---- Peixos_SUDOANG database: Catalan Water Agency (sent by Lluis Zamora) 2016/2017
------------------------------------------------------------------------------------
SELECT * FROM sudoang.catalonia_station limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system and Huso = 31, change in QGis for a good projection)
select addgeometrycolumn('sudoang','catalonia_station','geom', 32631, 'point',2);
update sudoang.catalonia_station set geom= ST_SetSRID(ST_MakePoint(utm_x, utm_y), 32631); -- 300 rows affected
-- 300 stations

---- Adding id
create temporary sequence seq;
alter sequence seq restart with 1;

alter table sudoang.catalonia_station add column id text;
update sudoang.catalonia_station set id = 'CAT_'||nextval('seq');  -- 300 rows
alter table sudoang.catalonia_station add constraint c_uk_cata_id unique (id);


---- ASTURIAS_pesca_electrica: the government agency of Asturias (sent by Lucía García Florez) 2011/2018
---------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.asturias_location limit 10;

---- Adding a geometry column (SRID 4326, it needs to be transformed)
select addgeometrycolumn('sudoang','asturias_location','geom', 25830, 'point',2);
update sudoang.asturias_location set geom= ST_Transform(ST_SetSRID(ST_MakePoint("sta_X.", "sta_Y"),4326), 25830); -- 36 rows affected, 22 msec
-- 36 stations
select count(*) from sudoang.asturias_location where sta_id is not null;
select distinct "sta_id" from sudoang.asturias_location;

---- Adding id
create temporary sequence seq;
alter sequence seq restart with 1;

alter table sudoang.asturias_location add column id text;
update sudoang.asturias_location set id = 'AST_'||nextval('seq');  --  rows
alter table sudoang.asturias_location add constraint c_uk_astu_id unique (id);


---- ANGUILAS_GALICIA_2017 table: the Xunta of Galicia (sent by Fernando Tilves Pazos) 1988/2017 -> In his mail there are more information about some estimations
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.galicia_ope limit 10;

/*---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','galicia_ope','geom', 25830, 'point',2);
update sudoang.galicia_ope set geom= ST_SetSRID(ST_MakePoint("UTM_X", "UTM_Y"),25830); -- 3700 rows affected, 82 msec
-- 36 stations
select distinct cod_stat from sudoang.galicia_ope; -- 5302 rows
select distinct station from sudoang.galicia_ope; -- 2232 rows
select distinct geom from sudoang.galicia_ope; -- 3796 rows
*/

---- This dataset has been updated with a shapefile sent by Francisco Hervella, containing the operations without eels (SIBIC.R script)
----	All the id's found are corresponding to the operations, so an id is created taking into account only the geometry of the operation
----	The id 'GAL_' has been created in SIBIC.R script, but we updated it to correspond to the station and not to the operation
create temporary sequence seq;
alter sequence seq restart with 1;

alter table sudoang.galicia_station add column id text;
update sudoang.galicia_station set id = 'GAL_'||nextval('seq');  -- rows
alter table sudoang.galicia_station add constraint c_uk_galicia_id unique (id);

---- PORTUGAL Anguillaanguilla_datacollectionFCUL_Portugal_Review.xlsx
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.portugal_location limit 10;
select addgeometrycolumn('sudoang','portugal_location','geom', 25830, 'point',2);
update sudoang.portugal_location set geom= ST_TRANSFORM(ST_SetSRID(ST_MakePoint("X.longitude", "Y.latitude"),4326),25830); --754 rows affected, 22 msec execution time.

---- Adding id
create temporary sequence seq;
alter sequence seq restart with 1;

alter table sudoang.portugal_location add column id text;
update sudoang.portugal_location set id = 'POR_'||nextval('seq');  -- 745 rows
alter table sudoang.portugal_location add constraint c_uk_portugal_id unique (id);


---- PORTUGAL silver eels_portugal_sampling prior to SUDOANG Apr 2019.xlsx
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.portugal_location_bis limit 10;
select addgeometrycolumn('sudoang','portugal_location_bis','geom', 3035, 'point',2);
update sudoang.portugal_location_bis set geom= ST_TRANSFORM(ST_SetSRID(ST_MakePoint("sta_Y", "sta_X"),4326),3035); -- 53 rows

---- Adding id
create temporary sequence seq;
alter sequence seq restart with 746;

alter table sudoang.portugal_location_bis add column id text;
update sudoang.portugal_location_bis set id = 'POR_'||nextval('seq');  -- 53 rows
alter table sudoang.portugal_location_bis add constraint c_uk_portugal_bis_id unique (id);


---- SPAIN Belen_pesca_electrica_SUDOANG_E.1.1
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.sp_location limit 10;
select addgeometrycolumn('sudoang','sp_location','geom', 25830, 'point',2);
comment on TABLE sudoang.sp_location is 'table sent by belen from the spanish ministry';
alter table sudoang.sp_location rename column "sta_X." to "sta_X";
update sudoang.sp_location set geom= ST_TRANSFORM(ST_SetSRID(ST_MakePoint("sta_X", "sta_Y"),4258),25830); --251 rows affected, 22 msec execution time.


---- DFG_GIPUZKOA FISH DATABASE_12_11_2018.xlsx table: Diputación Foral de Gipuzkoa (sent by Iker Azpiroz) 1996-2018 -> In his mail there are more information 
------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.guipuz_station limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','guipuz_station','geom', 25830, 'point',2);
update sudoang.guipuz_station set geom= ST_SetSRID(ST_MakePoint("UTMX_ETRS89", "UTMY_ETRS89"),25830); -- 427 rows, 32 msec

---- Adding id
create temporary sequence seq;
alter sequence seq restart with 1;

alter table sudoang.guipuz_station add column id text;
update sudoang.guipuz_station set id = 'GIP_'||nextval('seq');  --427 rows
alter table sudoang.guipuz_station add constraint c_uk_guipuz_id unique (id);


---- VALENCIA table: VAERSA (sent by Nacho Ferrando) 1987/2018 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
---- All the id's found are corresponding to the operations, so an id is created taking into account only the geometry of the operation
----	The id 'VAL_' has been created in SIBIC.R script, but we updated it to correspond to the station and not to the operation
create temporary sequence seq;
alter sequence seq restart with 1;

alter table sudoang.valencia_station add column id text;
update sudoang.valencia_station set id = 'VAL_'||nextval('seq');  -- 112 rows
alter table sudoang.valencia_station add constraint c_uk_valencia_id unique (id);
