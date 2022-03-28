-------------------------------------------
-- OBSTACLES database
--	Import obstacles data to the dbeel
--	Import HPP data to the dbeel
-------------------------------------------

---- SPAIN: fichas table (data from Spanish Inventory of Dams): (sent by Belen Muñoz) - 
---------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.spain_obstruction limit 10;
SELECT * FROM spain.rivers limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','spain_obstruction','geom', 25830, 'point',2);
update sudoang.spain_obstruction set geom= ST_SetSRID(ST_MakePoint("XUTM", "YUTM"),25830) where "HUSO" = 30; -- 2334 rows, 78 msec
update sudoang.spain_obstruction set geom= st_transform(ST_SetSRID(ST_MakePoint("XUTM", "YUTM"),25829), 25830) where "HUSO" = 29; -- 556
update sudoang.spain_obstruction set geom= st_transform(ST_SetSRID(ST_MakePoint("XUTM", "YUTM"),25831), 25830) where "HUSO" = 31; -- 213

-- Add the distance to the sea from spain.rivers (eda2.0 database) to spain.obstruction (dbeel database)
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
Finally, the view isn't used because of the time of queries when the view is used.
A schema sudoang is created in eda2.0 database and spain.obstruction is also imported (line 102):

pg_dump -U postgres --table sudoang.spain_obstruction -f spain_obstruction.sql  dbeel
psql -U postgres -c "create schema sudoang" eda2.0
*/

create index idx_geom_spain_obstruction on sudoang.spain_obstruction using GIST(geom);

update  sudoang.spain_obstruction  set dmer= sub2.dmer from (
select distinct on("PRESA") "PRESA", dmer from (
SELECT  
"PRESA",
rivers.dmer,
 st_distance(rivers.geom,so.geom) as distance
 from  sudoang.spain_obstruction so join
	spain.rivers on st_dwithin(rivers.geom,so.geom,500)
 order by "PRESA", distance asc) sub) sub2
 where sub2."PRESA"=spain_obstruction."PRESA";

select * from sudoang.spain_obstruction limit 100

/* Looking for the dams with hydropower plants associated:
select * from sudoang.spain_obstruction where "DESCRIPCIO" like 'ENDESA%'
select * from sudoang.spain_obstruction where SITUATION like 'Explotaci%' 
select * from sudoang.spain_obstruction where "TIPOPRESA" ='9' -- We don't know what is "TIPOPRESA"
*/

/*
pg_dump -U postgres --table sudoang.spain_obstruction -f spain_obstruction.sql  eda2.0
psql -U postgres -c "drop table sudoang.spain_obstruction" dbeel
psql -U postgres -f spain_obstruction.sql dbeel

Used later in script upstream_silver_spain (line 268)
select dmer from spain.rivers limit 10
select dens_silver_pred from spain.rivers limit 10
*/

/*
For eelconsensus project, we need to identify the COMPANY and the POWER of each hydropower plant.
For that, spain_obstruction must be joined with spain_obstruction_hpp, which has the information of power.
Firstly, spain_obstruction_hpp (central.shp) must be imported in both databases (dbeel and eda2.0).
*/


---- SPAIN: central.shp (data from Spanish Government): (sent by Belen Muñoz) - 
----	It is the information about hydopower plant (aprovechamiento hidroelectrico) that isn't downloadable because it's obsolete
---------------------------------------------------------------------------------------------------------------------------------------
/*	shp2pgsql -s 4258 -W LATIN1 -I central.shp sudoang.spain_obstruction_hpp > spain_obstruction_hpp.sql
	psql -U postgres -f spain_obstruction_hpp.sql dbeel
	psql -U postgres -f spain_obstruction_hpp.sql eda2.0
*/

select * from sudoang.spain_obstruction limit 100;
select * from sudoang.spain_obstruction_hpp limit 10;

-- Returns the id of hpp (spain_obstruction_hpp) closest to the dam (spain_obstruction)
alter table sudoang.spain_obstruction add column id_hpp numeric;
alter table sudoang.spain_obstruction add column potencia_t numeric;
alter table sudoang.spain_obstruction add column corriente character varying(50);
alter table sudoang.spain_obstruction add column sbruto_m numeric;

select* from sudoang.spain_obstruction

update  sudoang.spain_obstruction set (id_hpp, potencia_t, corriente, sbruto_m)= (sub2.id, sub2.potencia_t, sub2.corriente, sub2.sbruto_m) from (
select distinct on("PRESA") id, "PRESA", potencia_t, corriente, sbruto_m , dist from (
select hpp.*, "PRESA", 
 st_distance(st_transform(hpp.geom, 25830), obs.geom) as dist
 from (select * from sudoang.spain_obstruction_hpp where geom is not null) hpp join
      (select * from sudoang.spain_obstruction where geom is not null) obs on 
st_dwithin(st_transform(hpp.geom, 25830), obs.geom, 1000)
 order by "PRESA", dist asc) sub) sub2
 where sub2."PRESA"=spain_obstruction."PRESA"; -- 624 rows, 438 msec

/* Test because we had problems to do the update (reason: bad projection of spain_obstruction_hpp in line 121 (shp2pgsql))
select st_geometrytype(geom) from sudoang.spain_obstruction_hpp;
select st_geometrytype(geom) from sudoang.spain_obstruction;

select *, st_distance(st_transform(hpp.geom, 25830), obs.geom) from
sudoang.spain_obstruction_hpp hpp, sudoang.spain_obstruction obs 
where id = 1122 and "PRESA" = 9010018;
*/

/*
624 hydropower plants are projected on spain_obstruction.
348 have to been added (total of id 876 in spain_obstruction_hpp).
*/

-- For the not projected
select max("PRESA") from sudoang.spain_obstruction;
create temporary sequence presa start 23110009; 
-- select nextval('presa')

delete from sudoang.spain_obstruction where "PRESA" >= 23110009;

select * from sudoang.spain_obstruction_hpp where id in (
select id from sudoang.spain_obstruction_hpp
except
select id from sudoang.spain_obstruction_hpp
where id in (
select distinct id_hpp as id from sudoang.spain_obstruction))
and (sbruto_m >0 or potencia_t>0) ; -- 415

/*
select distinct id_hpp as id from sudoang.spain_obstruction --270
select distinct id from sudoang.spain_obstruction_hpp 
select id from sudoang.spain_obstruction_hpp where id =2252
*/

-- Alter sequence presa restart with 231100089;
 /*
Insertion of 415 lines not already joined with the other table
when both potenta_t and s_bruto are zero we don't use, often it's canal or whatever...
 */

insert into sudoang.spain_obstruction("PRESA", id_hpp, potencia_t, corriente, sbruto_m, geom) 
select 
 nextval('presa') as "PRESA",
 id as id_hpp,
 sub.potencia_t,
 sub.corriente,
 sub.sbruto_m,
 st_transform(geom,25830) from (
 select * from sudoang.spain_obstruction_hpp where id in (
select id from sudoang.spain_obstruction_hpp
except
select id from sudoang.spain_obstruction_hpp
where id in (
select distinct id_hpp as id from sudoang.spain_obstruction))
and (sbruto_m >0 or potencia_t>0)  
) sub --415

select * from sudoang.spain_obstruction where id_hpp is not null and dmer>0 limit 100

update sudoang.spain_obstruction set "ALT_CAU" = sbruto_m where "ALT_CAU" is null and sbruto_m is not null; -- 415

delete from sudoang.spain_obstruction where "PRESA" in (618.2,585.6)
alter table  sudoang.spain_obstruction add column no_eel_above boolean default FALSE;

update  sudoang.spain_obstruction set no_eel_above = TRUE where "PRESA" in
(
select "PRESA" from (
select "PRESA",
case when "ALT_CAU" is not null then "ALT_CAU"
       else "ALT_CIM"::numeric end as alt 
       from  sudoang.spain_obstruction) sub
where alt>20); --628

select * from sudoang.spain_obstruction limit 100
select * from sudoang.spain_obstruction where "SITUACION" like 'Explot%'

/*
pg_dump -U postgres --table sudoang.spain_obstruction -f "spain_obstruction_dbeel.sql" dbeel
pg_dump -U postgres --table sudoang.spain_obstruction -f "spain_obstruction_eda2.sql" eda2.0
psql -U postgres -c "drop table sudoang.spain_obstruction" eda2.0
psql -U postgres -f spain_obstruction_dbeel.sql eda2.0
*/

-- Remise à jour de dmer pour les lignes ajoutées

alter table sudoang.spain_obstruction add column riverwidth numeric;
update  sudoang.spain_obstruction  set (dmer,n_silver_pred_upstream,riverwidth)= (sub2.dmer,sub2.n_silver_pred_upstream,sub2.riverwidth) from (
select distinct on("PRESA") "PRESA", dmer, n_silver_pred_upstream,riverwidth from (
SELECT  
"PRESA",
rivers.dmer,
rivers.riverwidth,
silver_production.n_silver_pred_upstream,
 st_distance(rivers.geom,so.geom) as distance
 from  sudoang.spain_obstruction so join
	spain.rivers on st_dwithin(rivers.geom,so.geom,500)
	left join spain.silver_production on rivers.gid=silver_production.gid
 order by "PRESA", distance asc) sub
 ) sub2
where sub2."PRESA"=spain_obstruction."PRESA"; --2802

select * from sudoang.spain_obstruction  where dmer is not null; --2759

/*
pg_dump -U postgres --table sudoang.spain_obstruction -f spain_obstruction_eda2_2nd.sql eda2.0
psql -U postgres -c "drop table sudoang.spain_obstruction" dbeel
psql -U postgres -f spain_obstruction_eda2_2nd.sql dbeel
*/

with dam_type_sub as (
SELECT
CASE WHEN dmer< 250000 then '<250 km' 
     WHEN dmer>= 250000 then '>=250 km' 
     WHEN dmer is null then 'not projected'
END AS dmer_group,
CASE WHEN no_eel_above then 'too high >20 m no eel above'
     WHEN NOT no_eel_above then 'height ok <20 m' 
     WHEN no_eel_above IS NULL then 'no information on dam height'
END AS passage,
CASE WHEN  id_hpp>0 then 'hpp inspire'
     WHEN id_hpp is null and "SITUACION" like 'Explot%' and riverwidth>10  then 'other dam hpp (explotacion)'
     WHEN id_hpp is null and ("SITUACION" not like 'Explot%' or riverwidth<10) then 'other dam  (no explotacion)'
END AS dam_type,
*
FROM sudoang.spain_obstruction) 
select count(*) as number, 
round(sum(n_silver_pred_upstream)) as silver_eel,
round(sum(potencia_t)) as potentia,
dam_type, dmer_group,passage from dam_type_sub 
group by dam_type, dmer_group,passage
order by dmer_group, dam_type, passage;


---- Amber table: sent by Rosa (data befor November 2017. Portugal is in other tables)
---------------------------------------------------------------------------------------

SELECT * FROM sudoang.amber limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','amber','geom', 25830, 'point',2);
update sudoang.amber set geom= ST_TRANSFORM(st_setsrid(ST_MakePoint("longitude_wgs84", "latitude_wgs84"), 4326),25830); -- 261634 rows, 8.5 secs

select * from sudoang.amber where dbname_ like '%SPAIN%'; -- 17 896 obstacles (filtered in QGis)
SELECT * FROM sudoang.amber WHERE guidatlas = 'FDEAEF56-545F-4185-8DB1-217D976892BD'; -- pb coordonate to be solved


---- Amber Portugal layers: sent by Rosa
---------------------------------------------------------------------------------------
/*
-- the prj corresponds to 102164 https://epsg.io/102164
ESRI:102164: "Lisboa Hayford Gauss IGeoE" is equivalent to EPSG:20790
ESRI:102165: "Lisboa Hayford Gauss IPCC" is equivalent to EPSG:20791
ESRI:104106: "GCS Datum Lisboa Hayford" is equivalent to EPSG:4207
ESRI:102161: "Datum 73 Hayford Gauss IPCC" is equivalent to EPSG:27493
ESRI: "GCS_Datum_73" is equivalent to EPSG:4274: Datum 73
-- Barragens layer
shp2pgsql  -s shp2pgsql -s 20790 -W "latin1" -I -k Barragens.shp sudoang.barragens>barragens.sql
psql -U postgres -f barragens.sql dbeel

psql:barragens.sql:16: ERREUR:  syntaxe en entrÃ©e invalide pour le type numeric : Â« 000000000000,000000 Â»
LIGNE 1 : ...LUES ('1','Lindoso',NULL,NULL,NULL,NULL,NULL,NULL,'000000000...

shp2pgsql  -s shp2pgsql -s 20790 -W "latin1" -I -i -k Barragens.shp sudoang.barragens>barragens.sql
-- pas mieux
-- Anyways there is almost nothing in this layer ... not sure it's worth the effort

shp2pgsql  -s shp2pgsql -s 20790 -W "latin1" -I -i -k Grandes_barragens.shp sudoang.Grandes_barragens>Grandes_barragens.sql
psql -U postgres -f Grandes_barragens.sql dbeel
Does not work, same pb

Open in Qgis, delete two last column (empty)
OK works

Same treatment for mini hydricas (delete two last columns)
shp2pgsql  -s shp2pgsql -s 20790 -W "latin1" -I -i -k Mini_hidricas.shp sudoang.Mini_hidricas>Mini_hidricas.sql
psql -U postgres -f Mini_hidricas.sql dbeel
*/

---- Inventari estructures database: Catalan Water Agency (sent by Lluis Zamora) 
----------------------------------------------------------------------------------
SELECT * FROM sudoang.catalonia_obstruction limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','catalonia_obstruction','geom', 25830, 'point',2);
update sudoang.catalonia_obstruction set geom= ST_SetSRID(ST_MakePoint("X_ETRS89", "Y_ETRS89"),25830); -- 1229 rows affected, 44 msec


---- SUDOANG_dams_powerplants_UdG table: Catalan Water Agency (sent by Lluis Zamora)
----	In addition to catalonia_obstruction
---- 	But most of them are duplicates: check if they are more information
---------------------------------------------------------------------------------------
-- DAMS table
SELECT * FROM sudoang.catalonia_obstruction_dams limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','catalonia_obstruction_dams','geom', 25830, 'point',2);
update sudoang.catalonia_obstruction_dams set geom= ST_TRANSFORM(st_setsrid(ST_MakePoint("X", "Y"), 4326),25830); -- 261634 rows, 8.5 secs

SELECT * FROM sudoang.catalonia_obstruction_dams WHERE "X" = 4.68763e;
update sudoang.catalonia_obstruction_dams set geom= ST_SetSRID(ST_MakePoint("X", "Y"),25830); -- 984 rows, 14 msec

-- Hydorpower PLANTS table
SELECT * FROM sudoang.catalonia_obstruction_hpp limit 10;

---- Notes: powerplant_id from catalonia_obstruction_dams = dam_id from catalonia_obstruction_hpp
SELECT * FROM sudoang.catalonia_obstruction_dams WHERE powerplant_id = 'CHS1001'
SELECT * FROM sudoang.catalonia_obstruction_hpp WHERE dam_id = 'CHS1001';





 ---- BARRAGENS_BACIA table: Dams in the Minho basin (sent by Carlos Antunes)
---------------------------------------------------------------------------------------

SELECT * FROM sudoang.minho_obstruction limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','minho_obstruction','geom', 25830, 'point',2);
update sudoang.minho_obstruction set geom = ST_SetSRID(ST_MakePoint("UTM_X", "UTM_Y"),25830); -- 45 rows, 21 msec


/* This table was deleted because the information was missing (height of dams)
 ---- obstaclesturbines_datacollectionFCUL_Portugal table: (sent by Isabel Domingos) - 70 lare dams without length
--------------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.fcul_obstruction limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25831 - ETRS89/UTM zone 31N)
select addgeometrycolumn('sudoang','fcul_obstruction','geom', 25830, 'point',2);
update sudoang.fcul_obstruction set geom = ST_TRANSFORM(st_setsrid(ST_MakePoint("X", "Y"), 4326),25830); -- 70 rows, 35 msec
*/

 ---- obstaculos_portugal_datacollectionFCULMARE_04_2019 table: (sent by Isabel Domingos) - dams and hpp
-------------------------------------------------------------------------------------------------------------
SELECT * FROM sudoang.fcul_obstruction_dams limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','fcul_obstruction_dams','geom', 25830, 'point',2);
update sudoang.fcul_obstruction_dams set geom = ST_TRANSFORM(st_setsrid(ST_MakePoint("X", "Y"), 4326),25830); -- 277 rows, 13 msec


----  GALICIA_Obstaculos.shp: Catalan Water Agency (sent by Lluis Zamora)
----------------------------------------------------------------------------------------------------------------------
/*	shp2pgsql -s 25830 -W LATIN1 -I GALICIA_Obstaculos.shp sudoang.galicia_obstruction > galicia_obstruction.sql
	psql -U postgres -f galicia_obstruction.sql dbeel
*/
--TODO MARIA
SELECT UpdateGeometrySRID('sudoang','galicia_obstruction','geom', 3041);
 

---- tabla_obstaculos_SUDOANG_E.2.1-15-04-19_ANDALUCIA table: Iberdrola from Andalucía (sent by Carlos Fernandez)
----	There are two tables: DAM and POWER PLANT
-----------------------------------------------------------------------------------------------------------------------
-- DAMS table
SELECT * FROM sudoang.andalucia_obstruction_dams limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
--alter table sudoang.andalucia_obstruction_dams drop column geom
select addgeometrycolumn('sudoang','andalucia_obstruction_dams','geom', 3035, 'point',2);
update sudoang.andalucia_obstruction_dams set geom= ST_TRANSFORM(st_setsrid(ST_MakePoint("Y", "X"), 4326),3035); -- 186 rows

/* Correct two dams with wrong coordinates:
SELECT * FROM sudoang.andalucia_obstruction_dams WHERE id = 'AOD_164';
UPDATE sudoang.andalucia_obstruction_dams SET "Y" = -6.71489 WHERE id = 'AOD_164';
SELECT * FROM sudoang.andalucia_obstruction_dams WHERE id = 'AOD_113';
UPDATE sudoang.andalucia_obstruction_dams SET "Y" = -3.36889 WHERE id = 'AOD_113';
*/

-- Hydorpower PLANTS table
SELECT * FROM sudoang.andalucia_obstruction_hpp limit 10;


---- EELCONSENSUSobstaculos.SPAIN: CCAA (sent by Esti Diaz)
---------------------------------------------------------------------------------------
----	eelconsensus_obstruction_block: for each important river that flows into the sea, the first obstacle that prevents the eels from 
---- 	colonizing the rest of the basin. Possible solution (steps, elevators) to evaluate the economic cost (if it is possible). 
SELECT * FROM sudoang.eelconsensus_obstruction_block limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','eelconsensus_obstruction_block','geom', 25830, 'point',2);
update sudoang.eelconsensus_obstruction_block set geom= ST_SetSRID(ST_MakePoint("XUTM", "YUTM"),25830); -- 49 rows, 22 msec

---- 	eelconsensus_obstruction_mort: for each river the central that is causing a greater mortality of silver eel.
----	Possible solution (temporary closures, turbine type changes...) to evaluate the economic cost (if it is possible).
SELECT * FROM sudoang.eelconsensus_obstruction_mort limit 10;

---- Adding a geometry column ("X" and "Y" in UTM system)
select addgeometrycolumn('sudoang','eelconsensus_obstruction_mort','geom', 25830, 'point',2);
update sudoang.eelconsensus_obstruction_mort set geom= ST_SetSRID(ST_MakePoint("XUTM", "YUTM"),25830); -- 46 rows, 11 msec

SET search_path TO sudoang, public;
SELECT eelconsensus_obstruction_block."Nombre", spain_obstruction."NOMBRE"
FROM eelconsensus_obstruction_block
LEFT JOIN spain_obstruction ON eelconsensus_obstruction_block."Nombre" = spain_obstruction."NOMBRE";

SELECT eelconsensus_obstruction_block."Nombre" FROM eelconsensus_obstruction_block;
SELECT spain_obstruction."NOMBRE" FROM spain_obstruction;