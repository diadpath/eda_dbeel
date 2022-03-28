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
update sudoang.nsp_efiplus_location set geom= ST_Transform(ST_SetSRID(ST_MakePoint("Longitude", "Latitude"),4326), 25830); -- 1848 rows affected, 44 msec


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
SELECT * FROM sudoang.catalonia_location limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system and Huso = 31, change in QGis for a good projection)
select addgeometrycolumn('sudoang','catalonia_location','geom', 25830, 'point',2);
update sudoang.catalonia_location set geom= ST_SetSRID(ST_MakePoint("UTMX", "UTMY"),25830); -- 314 rows affected, 25msec
-- 314 stations


---- ASTURIAS_pesca_electrica: the government agency of Asturias (sent by Lucía García Florez) 2011/2018
---------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.asturias_location limit 10;

---- Adding a geometry column (SRID 4326, it needs to be transformed)
select addgeometrycolumn('sudoang','asturias_location','geom', 25830, 'point',2);
update sudoang.asturias_location set geom= ST_Transform(ST_SetSRID(ST_MakePoint("sta_X.", "sta_Y"),4326), 25830); -- 36 rows affected, 22 msec
-- 36 stations
select count(*) from sudoang.asturias_location where sta_id is not null;
select distinct "sta_id" from sudoang.asturias_location;


---- ANGUILAS_GALICIA_2017 table: the Xunta of Galicia (sent by Fernando Tilves Pazos) 1988/2017 -> In his mail there are more information about some estimations
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.galicia_location limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','galicia_location','geom', 25830, 'point',2);
update sudoang.galicia_location set geom= ST_SetSRID(ST_MakePoint("UTM_X", "UTM_Y"),25830); -- 3700 rows affected, 82 msec
-- 36 stations
select distinct "Cod_Est" from sudoang.galicia_location;
select distinct "Estación" from sudoang.galicia_location;

---- PORTUGAL Anguillaanguilla_datacollectionFCUL_Portugal_Review.xlsx
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.portugal_location limit 10;
select addgeometrycolumn('sudoang','portugal_location','geom', 25830, 'point',2);
update sudoang.portugal_location set geom= ST_TRANSFORM(ST_SetSRID(ST_MakePoint("X.longitude", "Y.latitude"),4326),25830); --754 rows affected, 22 msec execution time.


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



----------------------------------
-- OBSTACLES database
-----------------------------------
 ---- Inventari estructures database: Catalan Water Agency (sent by Lluis Zamora) 
----------------------------------------------------------------------------------
SELECT * FROM sudoang.catalonia_obstruction limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','catalonia_obstruction','geom', 25830, 'point',2);
update sudoang.catalonia_obstruction set geom= ST_SetSRID(ST_MakePoint("X_ETRS89", "Y_ETRS89"),25830); -- 1229 rows affected, 44 msec


 ---- Amber table: sent by Rosa (data befor November 2017. Portugal is in other tables)
---------------------------------------------------------------------------------------

SELECT * FROM sudoang.amber limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','amber','geom', 25830, 'point',2);
update sudoang.amber set geom= ST_TRANSFORM(st_setsrid(ST_MakePoint("longitude_wgs84", "latitude_wgs84"), 4326),25830); -- 261634 rows, 8.5 secs

select * from sudoang.amber where dbname_ like '%SPAIN%'; -- 17 896 obstacles (filtered in QGis)


 ---- BARRAGENS_BACIA table: Dams in the Minho basin (sent by Carlos Antunes)
---------------------------------------------------------------------------------------

SELECT * FROM sudoang.minho_obstruction limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','minho_obstruction','geom', 25830, 'point',2);
update sudoang.minho_obstruction set geom= ST_SetSRID(ST_MakePoint("UTM_X", "UTM_Y"),25830); -- 45 rows, 21 msec


 ---- bstaclesturbines_datacollectionFCUL_Portugal table: (sent by Isabel Domingos) - 70 lare dams
---------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.fcul_obstruction limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','fcul_obstruction','geom', 25830, 'point',2);
update sudoang.fcul_obstruction set geom= ST_TRANSFORM(st_setsrid(ST_MakePoint("X", "Y"), 4326),25830); -- 70 rows, 35 msec


 ---- fichas table (data from Spanish Inventory of Dams): (sent by Belen Muñoz) - 
---------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.spain_obstruction limit 10;
SELECT * FROM spain.rivers limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','spain_obstruction','geom', 25830, 'point',2);
update sudoang.spain_obstruction set geom= ST_SetSRID(ST_MakePoint("X30", "Y30"),25830); -- 3229 rows, 78 msec

-- Add the distance to the sea from spain.rivers (eda2.2 database) to spain.obstruction (dbeel database)
alter table sudoang.spain_obstruction add column dmer numeric;
--	First, create a view with dblink extension
-- drop view if exists sudoang.spain_obstruction_union_dmer
CREATE VIEW sudoang.spain_obstruction_union_dmer AS
  SELECT *
    FROM dblink('dbname=eda2.0 host=localhost user=postgres password=postgres',
                'SELECT gid, geom, dmer from spain.rivers')
    AS t1(gid int, geom geometry, dmer numeric);


select * from sudoang.spain_obstruction_union_dmer limit 10
select st_srid(geom) from  sudoang.spain_obstruction_union_dmer limit 1

/*
pg_dump -U postgres --table sudoang.spain_obstruction -f spain_obstruction.sql  dbeel
psql -U postgres -c "create schema sudoang" eda2.0
 psql -U postgres -f spain_obstruction.sql eda2.0
*/

create index idx_geom_spain_obstruction on sudoang.spain_obstruction using GIST(geom);



update  sudoang.spain_obstruction  set dmer= sub2.dmer from (
select distinct on("PRESA") "PRESA", dmer from (
SELECT  
"PRESA",
rivers.dmer,
 st_distance(rivers.geom,so.geom) as distance
 from  sudoang.spain_obstruction so join
	spain.rivers  on st_dwithin(rivers.geom,so.geom,500)
 order by "PRESA", distance asc ) sub) sub2
 where sub2."PRESA"=spain_obstruction."PRESA"


/*
pg_dump -U postgres --table sudoang.spain_obstruction -f spain_obstruction.sql  eda2.0
psql -U postgres -c "drop table sudoang.spain_obstruction" dbeel
 psql -U postgres -f spain_obstruction.sql dbeel
*/


alter table spain.rivers add column dens_silver_pred numeric;
update spain.rivers set dens_silver_pred=round(exp(-3.09-0.004*dmer/1000),3)

select dmer from spain.rivers limit 10
select dens_silver_pred from spain.rivers limit 10




		