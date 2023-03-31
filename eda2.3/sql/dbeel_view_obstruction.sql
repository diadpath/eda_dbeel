






DROP MATERIALIZED VIEW IF EXISTS  montepomi.view_obstruction CASCADE;
CREATE MATERIALIZED VIEW montepomi.view_obstruction AS (
 SELECT dbeel_obstruction_place.op_id,
    dbeel_obstruction_place.op_gis_systemname,
    dbeel_obstruction_place.op_gis_layername,
    dbeel_obstruction_place.op_gislocation,
    dbeel_obstruction_place.op_placename,
    observation_place_type.no_name AS observation_place_type_name,
    dbeel_obstruction_place.op_op_id,
    dbeel_obstruction_place.the_geom,
    dbeel_obstruction_place.id_original,
    dbeel_obstruction_place.country,    
    dbeel_physical_obstruction.ob_id,
    dbeel_physical_obstruction.ob_no_origin,
    dbeel_physical_obstruction.ob_no_type,
    dbeel_physical_obstruction.ob_no_period,
    dbeel_physical_obstruction.ob_starting_date,
    dbeel_physical_obstruction.ob_ending_date,
    dbeel_physical_obstruction.ob_op_id,
    data_provider.dp_name,
    obstruction_type.no_code AS obstruction_type_code,
    obstruction_type.no_name AS obstruction_type_name,
    dbeel_physical_obstruction.ot_obstruction_number,
    dbeel_physical_obstruction.ot_no_mortality_type,
    dbeel_physical_obstruction.ot_no_mortality,
    obstruction_impact.no_code AS obstruction_impact_code,
    obstruction_impact.no_name AS obstruction_impact_name,
    dbeel_physical_obstruction.po_obstruction_height,
    dbeel_physical_obstruction.po_downs_pb,
    dbeel_physical_obstruction.po_downs_water_depth,
    dbeel_physical_obstruction.po_presence_eel_pass,
    dbeel_physical_obstruction.po_method_perm_ev,
    dbeel_physical_obstruction.po_date_presence_eel_pass,
    --dbeel_physical_obstruction.po_turbine_number,
    fishway_type.no_code AS fishway_type_code,
    fishway_type.no_name AS fishway_type_name,
    downstream_mitigation_measure.no_name AS downstream_mitigation_measure_name,
    'http://maps.google.fr/maps?q='||st_y(st_transform(the_geom,4326))||','||st_x(st_transform(the_geom,4326)) AS googlemapscoods
   FROM montepomi.dbeel_obstruction_place
   JOIN montepomi.dbeel_physical_obstruction ON dbeel_physical_obstruction.ob_op_id = dbeel_obstruction_place.op_id
   LEFT JOIN dbeel_nomenclature.observation_place_type ON op_no_observationplacetype=observation_place_type.no_id
   LEFT JOIN dbeel_nomenclature.obstruction_type ON obstruction_type.no_id=dbeel_physical_obstruction.ot_no_obstruction_type
   LEFT JOIN dbeel_nomenclature.obstruction_impact ON obstruction_impact.no_id= dbeel_physical_obstruction.po_no_obstruction_passability
   LEFT JOIN dbeel_nomenclature.fishway_type ON fishway_type.no_id= dbeel_physical_obstruction.fishway_type
   LEFT JOIN dbeel_nomenclature.downstream_mitigation_measure ON downstream_mitigation_measure.no_id= dbeel_physical_obstruction.mitigation_measure_no_id
   JOIN dbeel.data_provider ON ob_dp_id=dp_id)
; --  103309




--SELECT count(*) FROM montepomi.view_obstruction;





/*
REINDEX TABLE montepomi.dbeel_obstruction_place;
VACUUM ANALYSE montepomi.dbeel_obstruction_place;
REINDEX TABLE spain.rn ; --46.42
*/
DROP TABLE IF EXISTS spain.join_obstruction_rn CASCADE;
CREATE TABLE spain.join_obstruction_rn as(
  
   with projection as (	
               SELECT r.idsegment, 
               op_id,               						
		geom,
		st_distance(r.geom,d.the_geom) as distance ,
        1-ST_LineLocatePoint(ST_GeometryN(r.geom,1),ST_ClosestPoint(r.geom,d. the_geom)) AS position_ouvrage_segment

		FROM spain.rn r
		JOIn montepomi.dbeel_obstruction_place  d
		ON st_dwithin(r.geom, d.the_geom,0.01)
		order by idsegment, distance desc)
SELECT distinct on (op_id) op_id, idsegment, position_ouvrage_segment  from projection
);
-- 20468
--REINDEX TABLE spain.join_obstruction_rn;
create index idx_spain_join_obstruction_rn_idsegment ON spain.join_obstruction_rn using btree(idsegment); --183msec
--select count(*) from spain.join_obstruction_rn;

--REINDEX TABLE FRANCE.rn;
DROP TABLE IF EXISTS france.join_obstruction_rn;
CREATE TABLE france.join_obstruction_rn as(
  
   with projection as (	
        SELECT r.idsegment, 
          op_id,               						
		  geom,
		  st_distance(r.geom,d.the_geom) as distance,
		  1-ST_LineLocatePoint(ST_GeometryN(r.geom,1),ST_ClosestPoint(r.geom,d. the_geom)) AS position_ouvrage_segment
		FROM france.rn r
		JOIN montepomi.dbeel_obstruction_place  d
		ON st_dwithin(r.geom, d.the_geom,0.01)
		order by idsegment, distance desc)
SELECT distinct on (op_id) op_id, idsegment, position_ouvrage_segment from projection
);
create index idx_france_join_obstruction_rn_idsegment ON france.join_obstruction_rn using btree(idsegment); --183msec

--85037 10s
/*
select count(*) from france.join_obstruction_rn;--84270
select count(*) FROM montepomi.dbeel_obstruction_place; --105662
select count(*) FROM dbeel_rivers.rn --515011
*/


DROP TABLE IF EXISTS portugal.join_obstruction_rn;
CREATE TABLE portugal.join_obstruction_rn as(
  
   with projection as (	
        SELECT r.idsegment, 
          op_id,               						
		  geom,
		  st_distance(r.geom,d.the_geom) as distance,
		  1-ST_LineLocatePoint(ST_GeometryN(r.geom,1),ST_ClosestPoint(r.geom,d. the_geom)) AS position_ouvrage_segment
		FROM portugal.rn r
		JOIN montepomi.dbeel_obstruction_place  d
		ON st_dwithin(r.geom, d.the_geom,0.01)
		order by idsegment, distance desc)
SELECT distinct on (op_id) op_id, idsegment, position_ouvrage_segment from projection
);--857
CREATE INDEX idxjoidsegment ON portugal.join_obstruction_rn USING btree(idsegment);
--select count(*) from portugal.join_obstruction_rn;--857

DROP TABLE IF EXISTS dbeel_rivers.join_obstruction_rn CASCADE ;
CREATE TABLE dbeel_rivers.join_obstruction_rn as (
SELECT * from portugal.join_obstruction_rn 
UNION
SELECT * FROM spain.join_obstruction_rn
UNION
SELECT * FROM france.join_obstruction_rn
); --106362 C; 105596 M

SELECT count(*) FROM dbeel_rivers.join_obstruction_rn
/*
 this view allows to remove dams from the main streams when they are projected on the border
*/
 
DROP VIEW IF EXISTS montepomi.downstream_badly_projected;
create view montepomi.downstream_badly_projected as(
select  o.*,   
rn_rna.seaidsegment, 
  rn_rna.basin, 
  rn_rna.riverwidthm, 
  rn_rna.dis_m3_pyr_riveratlas from dbeel_rivers.join_obstruction_rn d
JOIn dbeel_rivers.rn_rna on rn_rna.idsegment=d.idsegment
JOIN montepomi.view_obstruction o on o.op_id=d.op_id
where dis_m3_pyr_riveratlas>150
and po_obstruction_height is NULL
and op_op_id is NULL
order by dis_m3_pyr_riveratlas);--0

--select * from montepomi.downstream_badly_projected ;--83
/*
SELECT count(*) FROM dbeel_rivers.join_obstruction_rn; --105602
SELECT count(*) FROM spain.join_obstruction_rn; --20474
SELECT count(*) FROM portugal.join_obstruction_rn; --858
SELECT count(*) FROM france.join_obstruction_rn; --84270
*/
create index idx_dbeel_rivers_join_obstruction_rn_idsegment ON dbeel_rivers.join_obstruction_rn using btree(idsegment);


--SELECT * FROM spain.join_obstruction_rn

DROP MATERIALIZED VIEW IF EXISTS spain.view_join_obstruction_rn ;
CREATE MATERIALIZED VIEW spain.view_join_obstruction_rn as(
select r.*,
op_gis_systemname,
op_gis_layername,
op_gislocation,
op_placename,
observation_place_type_name,
op_op_id,
the_geom,
id_original,
country,
ob_id,
ob_no_origin,
ob_no_type,
ob_no_period,
ob_starting_date,
ob_ending_date,
ob_op_id,
dp_name,
obstruction_type_code,
obstruction_type_name,
ot_obstruction_number,
ot_no_mortality_type,
ot_no_mortality,
obstruction_impact_code,
obstruction_impact_name,
po_obstruction_height,
po_downs_pb,
po_downs_water_depth,
po_presence_eel_pass,
po_method_perm_ev,
po_date_presence_eel_pass,
fishway_type_code,
fishway_type_name
downstream_mitigation_measure_name,
googlemapscoods
from montepomi.view_obstruction o JOIN 
(SELECT * FROM spain.join_obstruction_rn 
UNION
SELECT * FROM portugal.join_obstruction_rn 
) r
 ON r.op_id=o.op_id);
--Query returned successfully: 21323 C rows affected, 712 msec execution time; 21324 rows affected, 959 msec M



--------------------------------------------------------------------------------
-- this table groups joins a dam with all segments downtream not including itself
--------------------------------------------------------------------------------
/*
WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as vecteurchemin,
  rn.idsegment AS idsegmentsource  
  from france.rn 
) SELECT count(*) FROM downstreamjoin; --6199371 rows
*/
DROP TABLE IF EXISTS france.join_obstruction_rn_downstream;
CREATE TABLE france.join_obstruction_rn_downstream as(
WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as vecteurchemin,
  rn.idsegment AS idsegmentsource  
  from france.rn 
)
 SELECT j.op_id, 
 j.position_ouvrage_segment, 
 downstreamjoin.* FROm downstreamjoin 
 JOIN france.join_obstruction_rn j ON j.idsegment=downstreamjoin.vecteurchemin
);-- CB: 6268275 38sC; MM: 6268230
--SELECT count(*) FROM france.join_obstruction_rn_downstream


-- comparaison à la table de maria
WITH antijoin AS (
SELECT * FROM france.maria_join_obstruction_rn_downstream EXCEPT 
SELECT * FROM france.join_obstruction_rn_downstream)
SELECT DISTINCT ON (op_id) op_id,  position_ouvrage_segment ,
  vecteurchemin FROM antijoin;

SELECT * FROM france.join_obstruction_rn_downstream LIMIT 100

SELECT * FROM france.join_obstruction_rn WHERE op_id='1e4a0f25-b83e-44d5-b2f6-77a4ba9af1d1'
SELECT * FROM france.join_obstruction_rn WHERE op_id='1e4a0f25-b83e-44d5-b2f6-77a4ba9af1d1'

--Portugal
--REINDEX TABLE portugal.rn;
DROP TABLE IF EXISTS portugal.join_obstruction_rn_downstream;
CREATE TABLE portugal.join_obstruction_rn_downstream as(
WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as vecteurchemin,
  rn.idsegment AS idsegmentsource  
  from portugal.rn 
)
 SELECT j.op_id, 
 j.position_ouvrage_segment, 
 downstreamjoin.* FROm downstreamjoin 
 JOIN portugal.join_obstruction_rn j ON j.idsegment=downstreamjoin.vecteurchemin
); --224382 rows affected, 1:56 minutes execution time; 224382 rows affected, 16.6 secs M
--SELECT * FROM portugal.join_obstruction_rn_downstream where idsegmentsource='PT9621' ;

--SELECT count(*) FROM portugal.join_obstruction_rn_downstream

-- spain

--SELECT count(*) FROM spain.rn;325399 OK
--VACUUM ANALYSE  spain.rn;
--REINDEX TABLE spain.rn; --26.9

DROP TABLE IF EXISTS spain.join_obstruction_rn_downstream;
CREATE TABLE spain.join_obstruction_rn_downstream as(
WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as vecteurchemin,
  rn.idsegment AS idsegmentsource  
  from spain.rn 
)
 SELECT j.op_id, 
 j.position_ouvrage_segment, 
 downstreamjoin.* FROM downstreamjoin 
 JOIN spain.join_obstruction_rn j ON j.idsegment=downstreamjoin.vecteurchemin
); --Query returned successfully: 10244858 rows affected, 02:29 minutes C / 10245811 rows M
--SELECT count(*) FROM spain.join_obstruction_rn_downstream;
--# dbeel_rivers

DROP TABLE IF EXISTS dbeel_rivers.join_obstruction_rn_downstream;
CREATE TABLE dbeel_rivers.join_obstruction_rn_downstream as(
WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as vecteurchemin,
  rn.idsegment AS idsegmentsource  
  from dbeel_rivers.rn 
)
 SELECT j.op_id, 
 j.position_ouvrage_segment, 
 downstreamjoin.* FROm downstreamjoin 
 JOIN dbeel_rivers.join_obstruction_rn j ON j.idsegment=downstreamjoin.vecteurchemin
);
--NOTICE:  la table « join_obstruction_rn_downstream » n'existe pas, poursuite du traitement
--Query returned successfully:  rows affected, 04:17 minutes C /  17248551 M

--SELECT sum(nlevel(path)) FROM dbeel_rivers.rn
/*

DROP MATERIALIZED VIEW IF EXISTS spain.pbdamsimplified ;
create materialized view spain.pbdamsimplified as(
SELECT 
idsegment,
CASE WHEN delta >= 300 then '>300'
     WHEN (delta >=50 and delta <300)  THEN '>50'
     WHEN (delta >=10 and delta <50) THEN '>10'
     WHEN (delta >= 0 AND delta <10) THEN '>0' END AS deltaclass,
 st_simplify(geom,1) as geom 
 from spain.pbdam where delta>0
 UNION
SELECT 
idsegment,
CASE WHEN delta >= 300 then '>300'
     WHEN (delta >=50 and delta <300)  THEN '>50'
     WHEN (delta >=10 and delta <50) THEN '>10'
     WHEN (delta >= 0 AND delta <10) THEN '>0' END AS deltaclass,
 st_simplify(geom,1) as geom 
 from portugal.pbdam where delta>0)
 ;


/*
EXPORT TO MARIA KORTA
cd C:\Users\cedric.briand\Desktop
pgsql2shp -u postgres -g geom -f "pbdamsimplified.shp" eda2.3 spain.pbdamsimplified
*/


-----------------------------------
-- EXPORT INTO CSV FILE TO AMBER:
-----------------------------------

select count(*), op_gis_layername from montepomi.view_obstruction group by op_gis_layername; -- MISSING 'UP' from Minho river: 8 rows???

*/
/* The 8 dams from UP are in dbeel_obstruction_place but not in dbeel_physical_obstruction:
select * from montepomi.dbeel_obstruction_place where op_gis_layername = 'UP'
select * from montepomi.dbeel_physical_obstruction where ob_op_id = '68c896b4-3583-40c5-8bd4-1a2ef022fc65'
select * from montepomi.dbeel_physical_obstruction where ob_op_id = 'dfbf78d9-39a8-4f6b-9b55-ffee6bcc7742'
select * from montepomi.dbeel_physical_obstruction where ob_op_id = '6c6443c6-3155-4912-9b02-d8e16d89cc2b'
select * from montepomi.dbeel_physical_obstruction where ob_op_id = '6b627d68-05db-49ae-866c-c55f650f8a1b'
select * from montepomi.dbeel_physical_obstruction where ob_op_id = '4498ea2b-5722-4b83-83cd-36d3e3f690c3'
select * from montepomi.dbeel_physical_obstruction where ob_op_id = '97b435e4-1adb-4f49-9080-c8a3c057e8d1'
select * from montepomi.dbeel_physical_obstruction where ob_op_id = 'fba8a283-f706-4927-a880-ff344fb74fa8'
select * from montepomi.dbeel_physical_obstruction where ob_op_id = 'ee118426-1b4c-47f2-ab88-c9f6061aee48'
select * from montepomi.minho_obstruction where id = 'MIO_44' or id = 'MIO_21' or id = 'MIO_29' or id = 'MIO_40' or id = 'MIO_34' or id = 'MIO_16' or id = 'MIO_28' or id = 'MIO_2';

So, The line 1537 (dbeel_sudonag_obstruction_creation.sql script) is run to insert these information!
Run again the materialized view!
*/

/*
Data from AMBER must be deleted to avoid duplicates: (op_gis_layername = 'amber')
Data from The Xunta of Galicia must be deleted because María sent these data to AMBER (op_gis_layername = 'The Xunta of Galicia')
Data from spanish gouvernment and basque gouvernment mus be deleted because we are waiting confirmation: (op_gis_layername = 'miteco', 'spain_obstruction_in_spain', 'URA')
*/
select *, st_x(st_transform(the_geom, 3035)) as x, st_y(st_transform(the_geom,3035)) as y
	 from montepomi.view_obstruction where op_gis_layername = 'UCO' Or op_gis_layername = 'ACA' Or op_gis_layername = 'FCUL/MARE' or op_gis_layername = 'UP'
-- or op_gis_layername = 'URA' or op_gis_layername = 'miteco' or op_gis_layername = 'spain_obstruction_in_spain';

-- To export into csv:
-- COPY montepomi.view_obstruction_table TO 'C:\use\test.csv' DELIMITER ',' CSV HEADER --Permission dennied!!!


/*
Confirmation of the data from spanish gouvernment : (op_gis_layername = 'miteco', 'spain_obstruction_in_spain')
*/
select *, st_x(st_transform(the_geom, 3035)) as x, st_y(st_transform(the_geom,3035)) as y
	 from montepomi.view_obstruction where op_gis_layername = 'miteco' or op_gis_layername = 'spain_obstruction_in_spain'; -- 2172 rows

/*
Confirmation of the data from URA : (op_gis_layername = 'URA')
*/
select op_id, op_gis_systemname, the_geom, id_original, country, po_no_obstruction_passability, po_obstruction_height, po_presence_eel_pass,
	fishway_type, googlemapscoods, st_x(st_transform(the_geom, 3035)) as x, st_y(st_transform(the_geom,3035)) as y, tipologia, rio
	 from montepomi.view_obstruction join montepomi.bc_obstruction_dams on op_id = dbeel_op_id where op_gis_layername = 'URA'; -- 686 rows

	 
/*
 * CREATE TABLE OF GT2 basins
 */	 
	 
	 
SELECT * FROM eda_gerem.assoc_dbeel_rivers adr   WHERE name_basin LIKE '%Pau%'

DROP TABLE IF EXISTS eda_gerem.pilot_basins;
CREATE TABLE eda_gerem.pilot_basins (
seaidsegment TEXT PRIMARY KEY,
name TEXT);

INSERT INTO eda_gerem.pilot_basins VALUES ('FR118671', 'Adour');
INSERT INTO eda_gerem.pilot_basins VALUES ('PT56183', 'Mondego');
INSERT INTO eda_gerem.pilot_basins VALUES ('SP224290', 'Oria');
INSERT INTO eda_gerem.pilot_basins VALUES ('SP109916', 'Guadalquivir');
INSERT INTO eda_gerem.pilot_basins VALUES ('SP118297', 'Guadiaro');
INSERT INTO eda_gerem.pilot_basins VALUES ('SP128132', 'Ter');

SELECT * FROM dbeel_rivers.rn_rna WHERE lower(basin) LIKE '%guad%' 



	 
	 