-- see http://trac.eptb-vilaine.fr:8066/trac/wiki/electrofishing%20data for creation of tables stations, survey, fishlength in ireland

--INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('Marine Institute');
--INSERT INTO dbeel.data_provider(dp_name, dp_et_id) VALUES ('Russell Poole & Elvira de Eito',2);

--select * from wrbd.stationdbeel;
--select * from dbeel.observation_places;
--select * from ireland.stationdbeel;
--select count (*) from ireland.stations
--SELECT count(*) FROM ireland.stationdbeel
-- select count (*) from ireland.stations

/*
 * shifting some broken tables from the server
 * psql -U postgres -    eda2.0
 * pg_dump -U postgres -Fc --table ireland.station --table ireland.batch_ope eda2.3 | pg_restore -d eda2.0
 * 
 * 
 * 
 */
ALTER TABLE ireland.stations DROP CONSTRAINT enforce_dims_the_geom;
ALTER TABLE ireland.stations DROP CONSTRAINT enforce_geotype_the_geom;
ALTER TABLE ireland.stations DROP CONSTRAINT enforce_srid_the_geom;
DROP TABLE ireland.stations
DROP TABLE ireland.batch_ope -- 975

-- Cedric connect SSH to the database currently on the server
/*
 * Editing the station table, add geometry column pull unique values, check with old database
 * The file contains three datasets two with 2157, the one from MI has a different projection IRISH GRID ESPG 29903
 *
 */

--select * FROM ireland.ireland_2021_stations

SELECT addgeometrycolumn('ireland', 'ireland_2021_stations','geom','2157','POINT',2); 
UPDATE ireland.ireland_2021_stations SET geom=st_setsrid(ST_MakePoint(easting,northing),2157) ; --1706

-- the projection is still wrong for MI

UPDATE  ireland.ireland_2021_stations SET geom=st_transform(st_setSRID(geom,29903),2157)  
WHERE SOURCE='MI';--35


SELECT count(*) FROM ireland.stations s ; -- 975


/*
 * CHECKING FOR DUPLICATES STATIONS BETWEEN NEW AND OLDER DATA
 */

SELECT * FROM ireland.ireland_2021_stations LIMIT 10

ALTER TABLE ireland.ireland_2021_stations ADD COLUMN isduplicated boolean;

SELECT * FROM ireland.ireland_2021_stations s2 JOIN IRELAND.stationdbeel s ON 
s2.sitecode = s.sitecode ;




SELECT ST_SRID(geom) FROM ireland.ireland_2021_stations; --2157
SELECT ST_SRID(the_geom) FROM ireland.stationdbeel s ; --3035

SELECT * FROM ireland.ireland_2021_stations s2 JOIN IRELAND.stationdbeel s ON 
st_dwithin(st_transform(s2.geom, 3035), s.the_geom, 50)


-- first are there any duplicated values in the current dataset

SELECT s1.sitecode, s2.sitecode, s1.SOURCE, s2.SOURCE, s1.YEAR, s2.YEAR, s1.site, s2.site FROM ireland.ireland_2021_stations s1 JOIN ireland.ireland_2021_stations s2 ON 
st_dwithin(s1.geom, s2.geom, 100)
AND s1.sitecode != s2.sitecode
ORDER BY s1.sitecode;

SELECT * FROM ireland.ireland_2021_stations WHERE sitecode LIKE '%\_b';
UPDATE  ireland.ireland_2021_stations SET sitecode = '09_347_35A' WHERE sitecode ='09_347_35A_b'; --1
-- TODO COLM NEXT LINE
UPDATE  ireland.eel_wfd_survey SET "SiteCode" = '09_347_35A' WHERE "SiteCode" ='09_347_35A_b'; --1
-- START with WFD for code 

ALTER TABLE ireland.ireland_2021_stations ADD COLUMN op_id UUID ;
UPDATE ireland.ireland_2021_stations SET op_id = uuid_generate_v1();
ALTER TABLE ireland.ireland_2021_stations  ADD CONSTRAINT c_pk_op_id PRIMARY KEY (op_id);

UPDATE ireland.ireland_2021_stations  SET isduplicated=TRUE;

WITH noduplicated100 AS (
	SELECT op_id FROM ireland.ireland_2021_stations
	EXCEPT 
	SELECT  DISTINCT s1.op_id FROM ireland.ireland_2021_stations s1 JOIN ireland.ireland_2021_stations s2 ON 
	st_dwithin(s1.geom, s2.geom, 100)
	WHERE s1.sitecode != s2.sitecode --205 duplicates
)
 UPDATE ireland.ireland_2021_stations SET isduplicated=FALSE FROM noduplicated100 
 WHERE ireland_2021_stations.op_id=noduplicated100.op_id; -- 1501
 
 
 SELECT count(*) FROM ireland.ireland_2021_stations WHERE  isduplicated; --205 duplicates

-- WFD

 WITH wfd AS (
  SELECT * FROM ireland.ireland_2021_stations WHERE isduplicated AND SOURCE='WFD')
 SELECT round(st_distance(s1.geom,s2.geom)),s1.sitecode, s2.sitecode, s1.SOURCE, s2.SOURCE, s1.YEAR, s2.YEAR, s1.site, s2.site FROM wfd s1 JOIN wfd s2 ON 
	st_dwithin(s1.geom, s2.geom, 100)
	WHERE s1.sitecode != s2.sitecode 
  ;

/*
 * THIS QUERY WILL FIND ALL SPATIAL DUPLICATES AND EXTRACT ONLY THE "unique"
 */
WITH wfd AS (
  SELECT * FROM ireland.ireland_2021_stations WHERE isduplicated AND SOURCE='WFD'
  ),
 duplicate AS
(
	SELECT s1.op_id AS op_id1, s2.op_id  AS op_id2, s1.sitecode AS sitecode  
	FROM wfd AS s1, wfd AS s2
	WHERE s1.sitecode < s2.sitecode 
	AND ST_Distance(s1.geom, s2.geom)<100
) ,
 uniqueswfd100 AS (
SELECT *, rank() OVER(PARTITION BY op_id1 ORDER BY op_id2) 
FROM duplicate ORDER BY 
sitecode)

SELECT DISTINCT ON (op_id1) * FROM uniqueswfd100
; --61 lines "unique" site



/*
 * IDENTIFYING 61 sites only from WFD that will be the unique sites among duplicates (up to 5 lines with spatial duplicates)
 */
WITH wfd AS (
  SELECT * FROM ireland.ireland_2021_stations WHERE isduplicated AND SOURCE='WFD'
  ),
 duplicate AS
(
	SELECT s1.op_id AS op_id1, s2.op_id  AS op_id2, s1.sitecode AS sitecode  
	FROM wfd AS s1, wfd AS s2
	WHERE s1.sitecode < s2.sitecode 
	AND ST_Distance(s1.geom, s2.geom)<100
) ,
 wfd100 AS (
SELECT *, rank() OVER(PARTITION BY op_id1 ORDER BY op_id2) 
FROM duplicate ORDER BY 
sitecode),
 uniquewfd100 AS(
SELECT DISTINCT ON (op_id1) * FROM wfd100
) 
--SELECT isduplicated FROM ireland.ireland_2021_stations JOIN uniquewfd100 ON op_id = uniquewfd100.op_id1
UPDATE ireland.ireland_2021_stations SET isduplicated=FALSE FROM  uniquewfd100 WHERE op_id = uniquewfd100.op_id1
; --61 lines "unique" site

/*
 * now the remaining duplicated in the ireland.ireland_2021_stations table have to change "unique" id to select only one station... or even better, they will not be integrated
 * 
 */

-- just checking that there shouln't be any duplicated
 WITH noduplleft AS (
  SELECT * FROM ireland.ireland_2021_stations WHERE NOT isduplicated)
 SELECT round(st_distance(s1.geom,s2.geom)),s1.sitecode, s2.sitecode, s1.SOURCE, s2.SOURCE, s1.YEAR, s2.YEAR, s1.site, s2.site FROM noduplleft s1 JOIN noduplleft s2 ON 
	st_dwithin(s1.geom, s2.geom, 100)
	WHERE s1.sitecode != s2.sitecode 
  ;
 
 -- CHECK WHICH ONE WE WILL UPDATE
 
--Same coordintes WITH two different names;
/*
0	14_571_288A	14_571_288A (LHB)	WFD	WFD	2015	2015	Belview_A	Belview_A
0	14_571_288A (LHB)	14_571_288A	WFD	WFD	2015	2015	Belview_A	Belview_A
0	16S020500A	16S020500B	WFD	WFD	2016	2016	Rossestown_A	Rossestown_B
0	16S020500B	16S020500A	WFD	WFD	2016	2016	Rossestown_B	Rossestown_A
*/
 
 
 /*
  * FIND DUPLICATES WITH IFI 
  */
 
SELECT distinct(source) FROM ireland.ireland_2021_stations;

WITH ifi AS (
  SELECT * FROM ireland.ireland_2021_stations WHERE isduplicated AND SOURCE='IFI'
  ),
  existing_unique AS (
  SELECT * FROM ireland.ireland_2021_stations WHERE NOT isduplicated
  ),
 duplicate AS
(
	SELECT s1.op_id AS op_id1, s2.op_id  AS op_id2, s1.sitecode AS sitecode  
	FROM ifi AS s1, 
	ifi AS s2,
	existing_unique AS s3
	WHERE s1.sitecode < s2.sitecode 
	AND ST_Distance(s1.geom, s2.geom)<100
	AND NOT ST_distance(s1.geom, s3.geom)<100 -- not a duplicate with existing ones otherwise dropped
) ,
 ifi100 AS (
SELECT *, rank() OVER(PARTITION BY op_id1 ORDER BY op_id2) 
FROM duplicate ORDER BY 
sitecode),
 uniqueifi100 AS(
SELECT DISTINCT ON (op_id1) * FROM ifi100
) 
--SELECT * FROM uniqueifi100
UPDATE ireland.ireland_2021_stations SET isduplicated=FALSE FROM  uniqueifi100 WHERE op_id = uniqueifi100.op_id1
--2 

/*
  * FIND DUPLICATES WITH MI 
  */

WITH mi AS (
  SELECT * FROM ireland.ireland_2021_stations WHERE isduplicated AND SOURCE='MI'
  ),
  existing_unique AS (
  SELECT * FROM ireland.ireland_2021_stations WHERE NOT isduplicated
  ),
 duplicate AS
(
	SELECT s1.op_id AS op_id1, s2.op_id  AS op_id2, s1.sitecode AS sitecode  
	FROM mi AS s1, 
	mi AS s2,
	existing_unique AS s3
	WHERE s1.sitecode < s2.sitecode 
	AND ST_Distance(s1.geom, s2.geom)<100
	AND NOT ST_distance(s1.geom, s3.geom)<100 -- not a duplicate with existing ones otherwise dropped
) ,
 mi100 AS (
SELECT *, rank() OVER(PARTITION BY op_id1 ORDER BY op_id2) 
FROM duplicate ORDER BY 
sitecode),
 uniquemi100 AS(
SELECT DISTINCT ON (op_id1) * FROM mi100
) 

--SELECT * FROM uniquemi100 -- 1 duplicate
UPDATE ireland.ireland_2021_stations SET isduplicated=FALSE FROM  uniquemi100 WHERE op_id = uniquemi100.op_id1
--1

 /*
  * UPDATE WHERE POSSIBLE, sidecode IN THE OLD DATABASE
  * the sitecode _original column will keep the sitecode
  */


SELECT s2.site,s2.YEAR, s2.sitecode,  op_placename, s.site, s.sitecode, s.sitecode_original FROM ireland.ireland_2021_stations s2
JOIN ireland.stationdbeel s ON st_dwithin(s.the_geom, st_transform(s2.geom,3035),100)
WHERE NOT isduplicated -- remove only spatial duplicates for NEW  ('266 lines)

-- This will UPDATE sitecode in the old database to make it match the new codes, using spatial join
-- with ireland.ireland_2021_stations where we have removed spatial duplicates (so only one stations will be selected)
-- note if we have selected the wrong one it will not be OK, a quick manual check showed that it was mostly correct.

WITH jjj AS (
SELECT s2.site,s2.YEAR, s2.sitecode,  op_placename, s.op_id, s.site AS dbeelsite, s.sitecode AS dbeelsitecode, s.sitecode_original 
FROM ireland.ireland_2021_stations s2
JOIN ireland.stationdbeel s ON st_dwithin(s.the_geom, st_transform(s2.geom,3035),100)
WHERE NOT isduplicated 
)
UPDATE ireland.stationdbeel SET sitecode = jjj.sitecode FROM jjj WHERE jjj.op_id= stationdbeel.op_id; --171



 /*
  * INSERT IN THE DATABASE 
  */
-- insert all stations that are not already in the database
-- FOR this I join all stations except those for which a stationcode already exists in the stationdbeel

SELECT DISTINCT op_gis_systemname FROM ireland.stationdbeel
SELECT DISTINCT dbeel_op_id FROM ireland.stationdbeel; --nothing
ALTER TABLE ireland.stationdbeel DROP COLUMN dbeel_op_id; --0


DELETE FROM ireland.stationdbeel WHERE  op_gis_systemname = 'ireland2021';
INSERT INTO ireland.stationdbeel (
op_id,
op_gis_systemname,
op_gis_layername,
op_gislocation,
op_placename,
op_no_observationplacetype,
op_op_id,
id,
locationcode,
sourcefile,
easting,
northing,
catchment,
waterbody,
site,
sitecode,
sitecode_original,
the_geom)
SELECT 
op_id,
'ireland2021' AS op_gis_systemname,
SOURCE AS op_gis_layername,
NULL AS op_gislocation,
catchment||'|'::text||waterbody||'|'::text||site AS op_placename,
10 AS op_no_observationplacetype,
NULL::uuid AS op_op_id,
"row.names"::INTEGER AS id,
NULL::integer AS locationcode,
sourcefile,
easting,
northing,
catchment,
waterbody,
site,
sitecode,
NULL AS sitecode_original, 
st_transform(geom, 3035) AS the_geom
FROM ireland.ireland_2021_stations 

EXCEPT

SELECT 
s.op_id,
'ireland2021' AS op_gis_systemname,
s.source AS op_gis_layername,
NULL AS op_gislocation,
s.catchment||'|'::text||s.waterbody||'|'::text||s.site AS op_placename,
10 AS op_no_observationplacetype,
NULL::uuid  AS op_op_id,
s."row.names"::INTEGER AS id,
NULL::integer AS locationcode,
s.sourcefile,
s.easting,
s.northing,
s.catchment,
s.waterbody,
s.site,
s.sitecode,
NULL AS sitecode_original, 
st_transform(s.geom, 3035) AS the_geom
FROM ireland.ireland_2021_stations s
JOIN
ireland.stationdbeel ON 
stationdbeel.sitecode = s.sitecode; -- 1474 (for 1706 lines in the original table.

-- now I'm returning the op_id back in the original table, I have already created it so now it's transfered in ireland.stationdbeel 
-- but 


SELECT DISTINCT sitecode FROM ireland.stationdbeel; -- 1912 => 1550 AFTER removing duplicates ON sitecode
SELECT DISTINCT sitecode FROM ireland.ireland_2021_stations; --1196


SELECT DISTINCT ss.sitecode FROM ireland.stationdbeel s
JOIN ireland.ireland_2021_stations ss ON s.sitecode=ss.sitecode 
; --1196 all are there .... => 836

-- since there will now be repeated op_id i need to drop the primary key constraint
ALTER TABLE ireland.ireland_2021_stations DROP CONSTRAINT c_pk_op_id;
UPDATE  ireland.ireland_2021_stations SET op_id=NULL;

WITH ii AS (
SELECT  s.sitecode, s.op_id FROM ireland.stationdbeel s
JOIN ireland.ireland_2021_stations ss ON s.sitecode=ss.sitecode
)
UPDATE ireland.ireland_2021_stations SET op_id=ii.op_id FROM ii WHERE ii.sitecode=ireland_2021_stations.sitecode; --1706

SELECT * FROM ireland.ireland_2021_stations WHERE op_id IS NULL; -- NO ROWS OK

SELECT * FROM ireland.stationdbeel WHERE sitecode IS NULL;



DROP TABLE IF EXISTS ireland.ireland_station_ccm_500;
CREATE TABLE ireland.ireland_station_ccm_500 as (
        SELECT distinct on (sitecode) sitecode , 
        wso1_id,
        distance, 
        op_id,
        the_geom FROM (
               SELECT 
               sitecode,
               op_id,
               wso1_id, 
               st_distance(r.the_geom, s.the_geom) as distance,
               s.the_geom 
               FROM ireland.stationdbeel As s
               INNER JOIN  ccm21.riversegments r ON ST_DWithin(r.the_geom, s.the_geom,500)
               WHERE s.the_geom IS NOT NULL
               AND sitecode IS NOT NULL -- one row
               ORDER BY sitecode, st_distance(r.the_geom, s.the_geom)) AS sub 
        GROUP BY sitecode,distance, wso1_id, op_id,  the_geom
); --1651
alter table ireland.ireland_station_ccm_500 add column id serial;

--SELECT count(*) FROM ireland.stationdbeel; --2363
--SELECT count(*) FROM ireland.ireland_station_ccm_500; --1651


ALTER TABLE ireland.stationdbeel ADD COLUMN wso1_id integer;
UPDATE ireland.stationdbeel SET wso1_id=ss.wso1_id FROM ireland.ireland_station_ccm_500 ss WHERE ss.op_id=stationdbeel.op_id; -- 1651

/*
SELECT * FROM ireland.stationdbeel WHERE op_id IN (
SELECT op_id FROM ireland.stationdbeel
EXCEPT
SELECT op_id FROM ireland.ireland_station_ccm_500)
*/

CREATE INDEX indexstation_ccm_500 ON ireland.ireland_station_ccm_500
  USING GIST(the_geom);

----------------------------------------------------
-- ireland.electrofishing (WE STOPPED HERE LAST TIME Colm)
-- see R script, I have imported the three survey tables in the database
/*
 * dbWriteTable(con,"eel_ifi_survey",eel_ifi_survey)
dbWriteTable(con,"eel_mi_survey",eel_mi_survey)
dbWriteTable(con,"eel_wfd_survey",eel_wfd_survey)
DBI::dbExecute(con, "ALTER TABLE eel_ifi_survey set SCHEMA ireland;")
DBI::dbExecute(con, "ALTER TABLE eel_mi_survey set SCHEMA ireland;")
DBI::dbExecute(con, "ALTER TABLE eel_wfd_survey set SCHEMA ireland;")
*/
-- they didn't have the same column so I kept them separated
---------------------------------------------------
 
 
select * from ireland.electrofishing
SELECT count(*) FROM ireland.eel_wfd_survey; --Samplingcode SiteCode --1253
SELECT * FROM ireland.stationdbeel LIMIT 10



SELECT * FROM ireland.eel_wfd_survey s JOIN
ireland.ireland_2021_stations st ON 
(s."SiteCode",s."Year"::TEXT)=(st.sitecode,st.year) 


/*
ALTER TABLE ireland.eel_wfd_survey DROP COLUMN geom;
SELECT addgeometrycolumn('ireland', 'eel_wfd_survey','geom','3035','POINT',2); 
UPDATE ireland.eel_wfd_survey SET geom=st_transform(st_setsrid(ST_MakePoint("Easting","Northing"),2157),3035) ; --1253
*/
-- TODO RUN HERE COLM 08/10

ALTER TABLE ireland.eel_wfd_survey ADD CONSTRAINT c_pk_id PRIMARY KEY ("row.names");
ALTER TABLE ireland.eel_wfd_survey RENAME COLUMN "row.names" to id;

ALTER TABLE ireland.eel_wfd_survey ADD COLUMN op_id uuid;
WITH joined as (
SELECT s21.op_id,id FROM ireland.ireland_2021_stations s21
JOIN ireland.eel_wfd_survey  su ON (su."SiteCode",su."Samplingcode")=(s21.sitecode,s21.samplingcode))
UPDATE ireland.eel_wfd_survey set op_id = joined.op_id FROM joined where joined.id=eel_wfd_survey.id; --1253

/*
-- spatial join
SELECT count(*), source FROM ireland.eel_wfd_survey su
JOIN ireland.stationdbeel st ON st_dwithin(st.the_geom,su.geom, 5) 
JOIN ireland.ireland_2021_stations s21 on s21.op_id=st.op_id
group by source; -- WFD 

4	IFI
1559	WFD

-- spatial join
SELECT count(*), source FROM ireland.eel_wfd_survey su
JOIN ireland.stationdbeel st ON su.op_id= st.op_id
JOIN ireland.ireland_2021_stations s21 on s21.op_id=st.op_id
group by source; 
-- 2303 WFD 

SELECT count(*) FROM ireland.eel_wfd_survey su
JOIN ireland.stationdbeel st ON su.op_id= st.op_id;--1252
*/



/*
WITH duplicates AS (
SELECT *, count(*) OVER (PARTITION BY sitecode)  FROM ireland.stationdbeel
)
DELETE FROM ireland.stationdbeel WHERE op_id IN (
SELECT op_id FROM duplicates  where count>1); --813 duplicates WITH same site code removed
-- no way to know if we have removed the right or wrong line.....
*/
-- This does not work because there are duplicated sitecodes but also some codes are not entered
-- in the station table as they were spatial duplicates.
-- The correct thing would be to renew the "sitecode" in the survey station
-- the only way to do that is to use survey and station names by joining the original station file (see above)




ALTER TABLE ireland.stationdbeel ADD CONSTRAINT c_uk_sitecode unique(sitecode); --0

-- which sitecodes are in the survey table but not the station

SELECT * FROM ireland.eel_wfd_survey
EXCEPT
SELECT eel_wfd_survey.* FROM ireland.eel_wfd_survey
JOIN ireland.stationdbeel ON stationdbeel.sitecode="SiteCode"



----------------------------
--Checking FOR duplicates
----------------------------


WITH j1 AS(
SELECT *, EXTRACT(year FROM ob_starting_date) AS year FROM ireland.stationdbeel 
JOIN ireland.electrofishing  ON ob_op_id=op_id)
SELECT * FROM j1
JOIN ireland.eel_wfd_survey s ON (s."Year", s."SiteCode")=(j1.year,j1.sitecode); -- NO duplicates

-- OK let's check year to be sure

SELECT DISTINCT "Year" FROM ireland.eel_wfd_survey ORDER BY "Year"; -- 2012:2019

WITH j1 AS(
SELECT *, EXTRACT(year FROM ob_starting_date) AS year FROM ireland.stationdbeel 
JOIN ireland.electrofishing  ON ob_op_id=op_id)
SELECT DISTINCT "year" FROM j1 ORDER BY "year"; -- 2005:2011

-- so no duplicates there. I can insert everything


SELECT * FROM dbeel.data_provider;
INSERT INTO dbeel.data_provider SELECT 8, 'Colm & Ciara', 2;

-- SamplingCode is text, survey id used in the previous database was text... I'm changing it
ALTER TABLE ireland.electrofishing ADD COLUMN samplingcode TEXT;
-- When inserting problem with samplingcode
-- note the use of double quotes every time an uppercase is in the column names.
-- This is why it is better not to have uppercase in column names when using postgres, it's always trickyer to type and it messes a bit when you use postgres

SELECT DISTINCT "Numfishingpasses" FROM ireland.eel_wfd_survey;
-- I need to cast a numeric, this is a text so I correct it
UPDATE ireland.eel_wfd_survey SET "Numfishingpasses"=1 WHERE "Numfishingpasses"='1?'; --16


-- electroshising mean

-- SELECT DISTINCT "EfishingEquipment" FROM ireland.eel_wfd_survey;
/*
 * 
boat
backpack
handset
bankset
 * 
 */

-- SELECT * FROM dbeel_nomenclature.electrofishing_mean em ;
/*
70		Electrofishing mean	Unknown	
71		Electrofishing mean	By foot	
72		Electrofishing mean	By boat	
73		Electrofishing mean	Mix	
*/
-- will translate into : (do not run this)
/*
CASE WHEN "EfishingEquipment" = 'boat' THEN 72
     WHEN "EfishingEquipment"  = 'backpack' THEN 71
     WHEN "EfishingEquipment"  = 'handset' THEN 71     
     WHEN "EfishingEquipment"  = 'bankset' THEN 71 
     END AS ef_no_electrofishing_mean
 */    
/*
SELECT DISTINCT wfdmethod FROM ireland.eel_wfd_survey;
SELECT count(*), wfdmethod FROM ireland.eel_wfd_survey GROUP BY wfdmethod ORDER BY count DESC;
*/
/*
503	10 Min (Handset)  305
275	Depletion (Handset)  62
210	TEF (Handset) 305
79	Boom Boat (Pulsed) 304 DH 301
62	Single Pass (Boat) DH 301
39	Depletion (Boat) DH 301
27	ADEF (Handset) 62  Area delimited Electrofishing  --Technically depletions as far as I can gather
23	10 Min (Boat) DH 301
17	Separate sides (Boat) DH 301
12	ADEF (Boat) DH 301
6	SPASE (Boat) DH 301-- I guess this is point sampling
*/
/*
SELECT * FROM dbeel_nomenclature.scientific_observation_method;

60		Scientific observation type	Unknown	Unknown	
61		Scientific observation type	Unknown	Electro-fishing	
62		Scientific observation type	Whole	Electro-fishing	
63		Scientific observation type	Partial1bank	Electro-fishing	
64		Scientific observation type	Partial2banks	Electro-fishing	
65		Scientific observation type	Partialrandom	Electro-fishing	
66		Scientific observation type	Partialprop	Electro-fishing	
67		Scientific observation type	Other	Electro-fishing	
68		Scientific observation type	Unknown	Gear fishing	
69		Scientific observation type	Unknown	Migration monitoring	
*/

/*
 * FIRST UPDATE using eda2.3 code
 * 
 */

UPDATE dbeel_nomenclature.scientific_observation_method set (no_code,sc_definition)=('NA','Unknown scientific observation of unknown category') where no_id=60;
UPDATE dbeel_nomenclature.scientific_observation_method set (no_code,sc_definition)=('UN','Electrofishing, method unknown') where no_id=61;
UPDATE dbeel_nomenclature.scientific_observation_method set (no_code,sc_definition)=('WH','Electrofishing, full two pass by foot') where no_id=62;
UPDATE dbeel_nomenclature.scientific_observation_method set (no_code,sc_definition)=('P1','Electrofishing, partial on one bank') where no_id=63;
UPDATE dbeel_nomenclature.scientific_observation_method set (no_code,sc_definition)=('P2','Electrofishing, partial on two banks') where no_id=64;
UPDATE dbeel_nomenclature.scientific_observation_method set (no_code,sc_definition)=('PR','Electrofishing, partial random') where no_id=65;
UPDATE dbeel_nomenclature.scientific_observation_method set (no_code,sc_definition)=('PP','Electrofishing, partial proportional') where no_id=66;
UPDATE dbeel_nomenclature.scientific_observation_method set (no_code,sc_definition)=('OT','Electrofishing, other method') where no_id=67;

-- START HERE COLM 08/10

INSERT INTO dbeel_nomenclature.scientific_observation_method(no_id,no_code,no_type,no_name,sc_observation_category,sc_definition) 
SELECT 301,'DH','Scientific_observation_type','Deep habitat','Electro-fishing','Normalized method for deep habitat (Belliard et al.,2018)';-- P�che grands milieux
INSERT INTO dbeel_nomenclature.scientific_observation_method(no_id,no_code,no_type,no_name,sc_observation_category,sc_definition) 
SELECT 302,'WE','Scientific_observation_type','Whole eel','Electro-fishing','Electrofishing, whole eel specific';-- COA
SELECT 303,'PE','Scientific_observation_type','Point sampling eel','Electro-fishing','Electrofishing, eel specific point sampling (Germis, 2009)';-- point sampling

/* 
 * NOW UPDATE USING SOME TYPES FROM IRELAND
 * we have grouped all boat electrofishing into a single category (deep habitat electrofishing) 
 * as there are very few of those sampling available.
 */




INSERT INTO dbeel_nomenclature.scientific_observation_method(no_id,no_code,no_type,no_name,sc_observation_category,sc_definition) 
SELECT 304,'TE','Scientific_observation_type','TEF','Electro-fishing','Timed electrofishing, 10 min in Ireland';--1
--DELETE FROM dbeel_nomenclature.scientific_observation_method where no_id=305 ;

INSERT INTO dbeel_nomenclature.scientific_observation_method(no_id,no_code,no_type,no_name,sc_observation_category,sc_definition) 
SELECT 305,'BB','Scientific_observation_type','Boom boat','Electro-fishing','Boom boat (Pulsed)';--1


ALTER SEQUENCE dbeel_nomenclature.nomenclature_no_id_seq RESTART WITH 303;
/*
SELECT CASE WHEN wfdmethod = 'Depletion (Handset)' THEN 62 --whole
WHEN wfdmethod = 'TEF (Handset)' THEN  305 
WHEN wfdmethod = 'Separate sides (Boat)' THEN  301 -- deep habitat
WHEN wfdmethod = 'Boom Boat (Pulsed)' THEN 301 -- deep habitat
WHEN wfdmethod = '10 Min (Handset)' THEN 305 -- deep habitat
WHEN wfdmethod = 'SPASE (Boat)' THEN 301 -- deep habitat
WHEN wfdmethod = 'Single Pass (Boat)' THEN 301 -- deep habitat
WHEN wfdmethod = 'ADEF (Handset)' THEN 62 -- Area delimited Electrofishing  --Technically depletions as far as I can gather
WHEN wfdmethod = 'Depletion (Boat)' THEN 301
WHEN wfdmethod = 'ADEF (Boat)' THEN 301
WHEN wfdmethod = '10 Min (Boat)' THEN 301
END AS 
*/

-- TABLE OF FISH COUNTS WICH ARE NOT IN THE WFD file
-- We need to extract the numbers per pass in the wfd file not need to do that for the other two tables
-- What we do is generate a table with just 0 and the surveys and the three pass from the survey table
-- and we combine it with the table of counts per passs and survey
-- the order by allows to first select the row with positive counts
-- and then the distinct remove duplicates rows with zero

-- SELECT * FROM ireland.eel_wfd_length
--SELECT DISTINCT "Pass_number" FROM ireland.eel_wfd_length


DROP TABLE IF EXISTS ireland.wfd_count;
CREATE TABLE ireland.wfd_count AS (
WITH new_wfd_length AS (
SELECT
"Samplingcode" AS samplingcode,
CASE WHEN "Pass_number" ILIKE '%H%' THEN 1
ELSE "Pass_number"::numeric END AS pass_number 
FROM ireland.eel_wfd_length
), 
wfdcount AS (
SELECT samplingcode, pass_number, count(*) AS n 
FROM new_wfd_length
GROUP by samplingcode,pass_number), 
mixing_with_empty AS (
SELECT wfdcount.* FROM wfdcount INNER JOIN
ireland.eel_wfd_survey ON "Samplingcode"=samplingcode 

-- the INNER JOIN removes samples that ARE NOT IN the survey
--NRSP18R_10_1277_18A_a
--WFD12R_30O010180A_a
--NRSP15R_14B011000A_a (X_Abandoned_X)

UNION

-- this generates the combination of all surveys
SELECT "Samplingcode" AS samplingcode, 
pass_number,
0 AS n FROM
ireland.eel_wfd_survey
CROSS JOIN
(SELECT 1 AS pass_number 
UNION
SELECT 2 AS pass_number
UNION
SELECT 3 AS pass_number)sub
ORDER BY samplingcode, pass_number, n DESC)
SELECT DISTINCT ON (samplingcode, pass_number) * FROM mixing_with_empty
);-- 3759 

-- this one has fish in the third pass but is indicated with only two passes
UPDATE ireland.eel_wfd_survey SET "Numfishingpasses" = '3' WHERE "Samplingcode"='NRSP15R_15_1425_37A_a';--1
UPDATE ireland.eel_wfd_survey SET "Numfishingpasses" = '1' WHERE "Numfishingpasses"='1?'; --16
ALTER TABLE ireland.wfd_count ADD COLUMN id_count SERIAL PRIMARY KEY; --0

WITH jj AS(
SELECT * FROM ireland.wfd_count JOIN
ireland.eel_wfd_survey ON "Samplingcode"= samplingcode
WHERE eel_wfd_survey."Numfishingpasses"::integer =2
AND n=0 AND pass_number=3)
DELETE FROM ireland.wfd_count WHERE id_count IN (SELECT DISTINCT id_count FROM jj); --41

WITH jj AS(
SELECT * FROM ireland.wfd_count JOIN
ireland.eel_wfd_survey ON "Samplingcode"= samplingcode
WHERE eel_wfd_survey."Numfishingpasses"::integer =1
AND n=0 AND pass_number=3)
DELETE FROM ireland.wfd_count WHERE id_count IN (SELECT DISTINCT id_count FROM jj); --818

UPDATE ireland.eel_wfd_survey SET "Numfishingpasses" = '2' WHERE "Samplingcode" 
IN ('NRSP18R_10V010200A_a',
	'WFD14R_14B011000B_a',
	'WFD14R_16S022700A_a',
	'NRSP18R_10V010300A_a');--4

WITH jj AS(
SELECT * FROM ireland.wfd_count JOIN
ireland.eel_wfd_survey ON "Samplingcode"= samplingcode
WHERE eel_wfd_survey."Numfishingpasses"::integer =1
AND n=0 AND pass_number=2)
DELETE FROM ireland.wfd_count WHERE id_count IN (SELECT DISTINCT id_count FROM jj); --818




--DELETE FROM ireland.electrofishing WHERE ob_dp_id=8;
-- run the inner query (starting with SELECT before running the insert if you want to see the data prior to inserting.
INSERT INTO ireland.electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_duration,
	ef_nbpas,
	ob_op_id,
	surveyid,
	samplingcode
	)
	
WITH survey AS(
	SELECT st.op_id AS ob_op_id, -- this will become the foreign key in the new table
	s.*
	FROM ireland.stationdbeel st
	JOIN ireland.eel_wfd_survey s ON s.op_id=st.op_id
	--LEFT JOIN ireland.wfd_count c ON s."Samplingcode"= c.samplingcode
	)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	"Date" AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	CASE WHEN wfdmethod = 'Depletion (Handset)' THEN 62 --whole
				WHEN wfdmethod = 'TEF (Handset)' THEN  305 
				WHEN wfdmethod = 'Separate sides (Boat)' THEN  301 -- deep habitat
				WHEN wfdmethod = 'Boom Boat (Pulsed)' THEN 301 -- deep habitat
				WHEN wfdmethod = '10 Min (Handset)' THEN 305 -- deep habitat
				WHEN wfdmethod = 'SPASE (Boat)' THEN 301 -- deep habitat
				WHEN wfdmethod = 'Single Pass (Boat)' THEN 301 -- deep habitat
				WHEN wfdmethod = 'ADEF (Handset)' THEN 62 -- Area delimited Electrofishing  --Technically depletions as far as I can gather
				WHEN wfdmethod = 'Depletion (Boat)' THEN 301
				WHEN wfdmethod = 'ADEF (Boat)' THEN 301
				WHEN wfdmethod = '10 Min (Boat)' THEN 301
	END AS  ef_no_fishingmethod,
	CASE WHEN "EfishingEquipment" = 'boat' THEN 72
     WHEN "EfishingEquipment"  = 'backpack' THEN 71
     WHEN "EfishingEquipment"  = 'handset' THEN 71     
     WHEN "EfishingEquipment"  = 'bankset' THEN 71 
     END AS ef_no_electrofishing_mean,
	sitewettedarea AS ef_wetted_area, 
	sitelength AS ef_fished_length,
	siteaveragewettedwidth AS ef_fished_width,
	cast(NULL as numeric) AS ef_duration,
	survey."Numfishingpasses"::integer AS ef_nbpas,
	survey.ob_op_id as ob_op_id,
	NULL AS survey_id,
	survey."Samplingcode" AS samplingcode
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		survey	
	WHERE observation_origin.no_name='Raw data' 
	AND observation_type.no_name='Electro-fishing'  
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Colm & Ciara';--1253

--UPDATE back IN the orinal database 	;
	
ALTER TABLE ireland.eel_wfd_survey ADD COLUMN ob_id uuid;

UPDATE ireland.eel_wfd_survey s SET ob_id = e.ob_id 
FROM ireland.electrofishing e 
WHERE e.samplingcode = s."Samplingcode"; --1253

	
-- NUMBER PER PASS... AND TOTAL NUMBER
-- Batch integration, the first level will reference operation again, the second will reference the fish table


-- number per pass and total number are  
-- referenced by biological_characteristic_type.no_name='Number' (see biological_characteristic_type.no_id=47)

CREATE TABLE 	ireland.batch_ope (
			op_locationcode TEXT,
			op_surveyid INTEGER,
			op_nb INTEGER,
			pa_numero INTEGER,
			samplingcode TEXT,
				
		CONSTRAINT pk_batch_ope_id PRIMARY KEY (ba_id),
		CONSTRAINT fk_batch_ope_ba_no_biological_characteristic_type FOREIGN KEY (ba_no_biological_characteristic_type) REFERENCES dbeel_nomenclature.biological_characteristic_type(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT fk_batch_ope_ba_no_individual_status FOREIGN KEY (ba_no_individual_status) REFERENCES dbeel_nomenclature.individual_status(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT fk_batch_ope_ba_no_species_id FOREIGN KEY (ba_no_species) REFERENCES dbeel_nomenclature.species(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT fk_batch_ope_ba_no_stage_id FOREIGN KEY (ba_no_stage) REFERENCES dbeel_nomenclature.stage(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT fk_batch_ope_ba_value_type FOREIGN KEY (ba_no_value_type) REFERENCES dbeel_nomenclature.value_type(no_id) ON DELETE RESTRICT ON UPDATE CASCADE
) 
		INHERITS (dbeel.batch); --0

DELETE FROM ireland.batch_ope;
INSERT INTO ireland.batch_ope(
			ba_id,
			ba_no_species,
			ba_no_stage,
			ba_no_value_type,
			ba_no_biological_characteristic_type,
			ba_quantity,
			ba_no_individual_status,
			ba_batch_level,
			ba_ob_id,
			ba_ba_id,
			op_locationcode,
			op_surveyid,
			op_nb,
			pa_numero,
			samplingcode	
)
		select 
		uuid_generate_v4() AS ba_id,
		species.no_id AS ba_no_species,
		stage.no_id AS ba_no_stage,
		value_type.no_id AS ba_no_value_type,
		biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
		"Totaleel" AS ba_quantity,
		individual_status.no_id AS ba_no_individual_status,
		0 AS ba_batch_level,
		ob_id as ba_ob_id,  
		cast(NULL as uuid) as ba_ba_id, 
		"SiteCode" as op_locationcode,
		id::integer as op_surveyid,	
		"Totaleel" as op_nb,
		 cast(NULL as integer) as pa_numero,	
		 "Samplingcode" AS samplingcode	
	FROM 
	ireland.eel_wfd_survey,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';    --1253

-- op_p1 (this batch is of level 2, 1 is total number, the pass is identified by the number in pa_numero)


	INSERT INTO ireland.batch_ope(
			ba_id,
			ba_no_species,
			ba_no_stage,
			ba_no_value_type,
			ba_no_biological_characteristic_type,
			ba_quantity,
			ba_no_individual_status,
			ba_batch_level,
			ba_ob_id,
			ba_ba_id,
			op_locationcode,
			op_surveyid,
			op_nb,
			pa_numero,
			samplingcode	
)
		SELECT 
		--wfd_count.*,
		uuid_generate_v4() AS ba_id,
		species.no_id AS ba_no_species,
		stage.no_id AS ba_no_stage,
		value_type.no_id AS ba_no_value_type,
		biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
		"Totaleel" AS ba_quantity,
		individual_status.no_id AS ba_no_individual_status,
		1 AS ba_batch_level,
		ob_id as ba_ob_id,  
		cast(NULL as uuid) as ba_ba_id, 
		"SiteCode" as op_locationcode,
		id::integer as op_surveyid,	
		n as op_nb,
		 cast(NULL as integer) as pa_numero,	
		 "Samplingcode" AS samplingcode	
	FROM 
	ireland.eel_wfd_survey JOIN
	ireland.wfd_count ON  "Samplingcode"= samplingcode,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND pass_number=1;  --1253 OK

	-- op_p2
INSERT INTO ireland.batch_ope(
			ba_id,
			ba_no_species,
			ba_no_stage,
			ba_no_value_type,
			ba_no_biological_characteristic_type,
			ba_quantity,
			ba_no_individual_status,
			ba_batch_level,
			ba_ob_id,
			ba_ba_id,
			op_locationcode,
			op_surveyid,
			op_nb,
			pa_numero,
			samplingcode	
)
		SELECT 
		--wfd_count.*,
		uuid_generate_v4() AS ba_id,
		species.no_id AS ba_no_species,
		stage.no_id AS ba_no_stage,
		value_type.no_id AS ba_no_value_type,
		biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
		"Totaleel" AS ba_quantity,
		individual_status.no_id AS ba_no_individual_status,
		2 AS ba_batch_level,
		ob_id as ba_ob_id,  
		cast(NULL as uuid) as ba_ba_id, 
		"SiteCode" as op_locationcode,
		id::integer as op_surveyid,	
		n as op_nb,
		 cast(NULL as integer) as pa_numero,	
		 "Samplingcode" AS samplingcode	
	FROM 
	ireland.eel_wfd_survey JOIN
	ireland.wfd_count ON  "Samplingcode"= samplingcode,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND pass_number=2;  -- 435



	-- op_p3
INSERT INTO ireland.batch_ope(
			ba_id,
			ba_no_species,
			ba_no_stage,
			ba_no_value_type,
			ba_no_biological_characteristic_type,
			ba_quantity,
			ba_no_individual_status,
			ba_batch_level,
			ba_ob_id,
			ba_ba_id,
			op_locationcode,
			op_surveyid,
			op_nb,
			pa_numero,
			samplingcode	
)
		SELECT 
		--wfd_count.*,
		uuid_generate_v4() AS ba_id,
		species.no_id AS ba_no_species,
		stage.no_id AS ba_no_stage,
		value_type.no_id AS ba_no_value_type,
		biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
		"Totaleel" AS ba_quantity,
		individual_status.no_id AS ba_no_individual_status,
		3 AS ba_batch_level,
		ob_id as ba_ob_id,  
		cast(NULL as uuid) as ba_ba_id, 
		"SiteCode" as op_locationcode,
		id::integer as op_surveyid,	
		n as op_nb,
		 cast(NULL as integer) as pa_numero,	
		 "Samplingcode" AS samplingcode	
	FROM 
	ireland.eel_wfd_survey JOIN
	ireland.wfd_count ON  "Samplingcode"= samplingcode,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND pass_number=3;  -- 394
	
	

	
-- densities as below are also calculated later but still I integrate them here
-- referenced by biological_characteristic_type.no_name='density' and the corresponding biological_characteristic_type.no_id


	
/*

DROP TABLE if exists ireland.batch_fish CASCADE;
CREATE TABLE ireland.batch_fish (
	LIKE ireland.fish_fi INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
	CONSTRAINT pk_fish_fi_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_fish_fi_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_fish_fi_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_fish_fi_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_fish_fi_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,			
	CONSTRAINT fk_fish_fi_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT c_fk_fi_op_id FOREIGN KEY (fi_op_id)
		REFERENCES ireland.operation_op (op_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT c_fk_fi_st_id FOREIGN KEY (fi_st_id)
		REFERENCES ireland.station_st (st_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
		) INHERITS (dbeel.batch);
/*
-- inner request like this		
select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from ireland.electrofishing 
	join ireland.fish_fi fi on fi_op_id=op_id 
	where op_equipment='Handset';
*/
INSERT INTO ireland.batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from ireland.electrofishing 
	join ireland.fish_fi fi on fi_op_id=op_id 
	where op_equipment='Handset') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';

DROP TABLE if exists ireland.mensurationindiv_biol_charac CASCADE;
CREATE TABLE ireland.mensurationindiv_biol_charac  (
	CONSTRAINT pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_value_type 	FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES ireland.batch_fish (ba_id) ON DELETE RESTRICT ON UPDATE CASCADE
)INHERITS (dbeel.biological_characteristic);
/*

select op_id,op_nbtotal,ob_starting_date,op_equipment,op_main_survey_target,fi_length,fi_lifestage,fi_year,fi_folio_no from ireland.electrofishing join ireland.fish_fi fi on fi_op_id=op_id 
select * from ireland.electrofishing join ireland.fish_fi fi on fi_op_id=op_id ;

select op_nbtotal, count from ireland.operation_op e join 
(select op_id, count(*) from ireland.operation_op 
	join ireland.fish_fi fi on fi_op_id=op_id 
	where op_equipment='Handset'
	group by op_id) as aa on aa.op_id=e.op_id

select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from ireland.electrofishing ee
	join ireland.fish_fi fi on fi.fi_op_id=ee.op_id 
	where op_equipment='Handset'
*/
-- attention toutes les lignes de batch_fish sont int�gr�es modifier pour le prochain
INSERT INTO ireland.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_weight AS bc_numvalue
	FROM ireland.batch_fish, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		fi_weight>0 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; 

INSERT INTO ireland.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 batch_fish.fi_length*10 AS bc_numvalue
	FROM ireland.batch_fish, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_length>0 
		AND biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; --2291 lines



INSERT INTO ireland.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 CASE when batch_fish.fi_sex='not recorded'  then 180
		 when batch_fish.fi_sex='male' then 181
		 when batch_fish.fi_sex='female' then 182
		 when batch_fish.fi_sex='unknown' then 183 -- unidentified
		 ELSE null
		 END  as bc_numvalue
	FROM ireland.batch_fish,
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_sex IS NOT NULL 
		AND biological_characteristic_type.no_name = 'Sex' 
		AND value_type.no_name = 'Raw data or Individual data'; -- 0 lines

--------------------------------------
-- II electrofishing boat
-- checking below if I can select operations using op_equipment and correcting holes
--------------------------------------
/*
"Boat"
"fixed trap - silver trap"
"fyke net"
"glass eel fishing"
"Handset"
"juvenile trap"
"longline standard bait"
*/
/*
update ireland.operation_op set op_equipment='fixed trap - silver trap' where op_equipment IS NULL;
select * from ireland.stationdbeel st join ireland.operation_op AS op on st.st_id = op.op_st_id where op_equipment='Handset'
*/
INSERT INTO ireland.electrofishing (ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		ef_no_fishingmethod,ef_no_electrofishing_mean,ef_wetted_area,ef_fished_length,ef_fished_width,ef_duration,ef_nbpas,ob_op_id,
		op_folio_no , op_st_id , op_date , op_year , op_area , op_glass , op_elver , op_yellow , op_silver , op_not_recorded , 
		op_eels_anaesthetized , op_nb_pass , op_p1 , op_p2 , op_p3 , op_p4 , op_p5 , op_nbtotal , op_abundance_rating , op_distribution , 
		op_main_survey_target , opedisthwm , op_density , op_equipment , op_nbfem , op_nbmal , op_nbind , op_totalestim , op_totalweight , 
		op_nbsets , op_nbimmat , op_id , op_nbnets , op_cpue , op_nbnights , op_datasource , op_silvereelcatchwt)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_date AS ob_starting_date,
	NULL AS ob_ending_date,
	data_provider.dp_id AS ob_dp_id, -- wrbd
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	op.op_area AS ef_wetted_area, 
	NULL AS ef_fished_length,
	NULL AS ef_fished_width,
	NULL AS ef_duration,
	op.op_nb_pass AS ef_nbpas, 
	op.* 	
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		(select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='Boat') as op
		
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Partialprop'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By boat' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --6 lines


-- batch already exists
		
/*
select ob_id as ba_ob_id,op_nb_total,op_p1,op_p2,op_p3,op_p4,op_p5 from wrbd.electrofishing  where op_equipment='Handset';
select * from wrbd.electrofishing  where op_yellow !=op_nbtotal; -- two lines do not know why
*/
-- nb_total
INSERT INTO wrbd.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.op_nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_nbtotal as op_nb, cast(NULL as integer) as pa_numero from wrbd.electrofishing  
		where op_equipment='Boat') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--6 lines

-- op_p1
INSERT INTO wrbd.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.op_nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_p1 as op_nb, 1 as pa_numero from wrbd.electrofishing  where op_equipment='Boat') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--6 lines

	-- op_p2
INSERT INTO wrbd.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.op_nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_p2 as op_nb, 2 as pa_numero from wrbd.electrofishing  where op_equipment='Boat' and op_p2 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--3 lines

	-- op_p3
INSERT INTO wrbd.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.op_nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_p3 as op_nb, 3 as pa_numero from wrbd.electrofishing  where op_equipment='Boat' and op_p3 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';-- 3 lines
delete from wrbd.batch_ope where pa_numero=3;
-- op_p4
INSERT INTO wrbd.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.op_nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_p4 as op_nb, 4 as pa_numero from wrbd.electrofishing  where op_equipment='Boat' and op_p4 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--0 lines



-- Batch integration, the second level will reference the fish table
-- wrbd.batch_fish already created


-- inner request like this	
/*	
select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from wrbd.electrofishing 
	join wrbd.fish_fi fi on fi_op_id=op_id 
	where op_equipment='Boat';
*/
INSERT INTO wrbd.batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from wrbd.electrofishing 
	join wrbd.fish_fi fi on fi_op_id=op_id 
	where op_equipment='Boat') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--79 lines

/*
select ba_id AS bc_ba_id,fi_weight from wrbd.electrofishing 
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='Boat'
	*/



INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 joineel.bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 joineel.fi_weight AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_weight from wrbd.electrofishing 
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='Boat') as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		fi_weight>0 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --79 lines

INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		joineel.bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		  joineel.fi_length*10 AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_length from wrbd.electrofishing 
		join wrbd.batch_fish  on ob_id=ba_ob_id 
		where op_equipment='Boat')as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_length>0 
		AND biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; --79 lines
INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 joineel.bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 CASE when joineel.fi_sex='not recorded'  then 180
		 when joineel.fi_sex='male' then 181
		 when joineel.fi_sex='female' then 182
		 when joineel.fi_sex='unknown' then 183 -- unidentified
		 ELSE null
		 END  as bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_sex from wrbd.electrofishing 
		join wrbd.batch_fish  on ob_id=ba_ob_id 
		where op_equipment='Boat')as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_sex IS NOT NULL 
		AND biological_characteristic_type.no_name = 'Sex' 
		AND value_type.no_name = 'Raw data or Individual data'; -- 0 lines
---------------------------
-- III gear fishing
----------------------------------

DROP TABLE if exists wrbd.gear_exp_fishery CASCADE;
CREATE TABLE wrbd.gear_exp_fishery (
	LIKE wrbd.operation_op INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
CONSTRAINT gear_fishing_id PRIMARY KEY (ob_id),
  CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id)
      REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_gf_effort_type FOREIGN KEY (gf_no_effort_type)
      REFERENCES dbeel_nomenclature.effort_type (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_gf_geartype FOREIGN KEY (gf_no_gear_type)
      REFERENCES dbeel_nomenclature.gear_type (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ob_origin FOREIGN KEY (ob_no_origin)
      REFERENCES dbeel_nomenclature.observation_origin (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ob_period FOREIGN KEY (ob_no_period)
      REFERENCES dbeel_nomenclature.period_type (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ob_type FOREIGN KEY (ob_no_type)
      REFERENCES dbeel_nomenclature.observation_type (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT
      ) INHERITS (dbeel.gear_fishing);
------------------------------
-- fyke net fishing
--------------------------------
-- check below what is gf_no_name
INSERT INTO wrbd.gear_exp_fishery(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		gf_no_gear_type,gf_gear_number,gf_no_effort_type,gf_effort_value,gf_no_name,ob_op_id,
		op_folio_no , op_st_id , op_date , op_year , op_area , op_glass , op_elver , op_yellow , op_silver , op_not_recorded , 
		op_eels_anaesthetized , op_nb_pass , op_p1 , op_p2 , op_p3 , op_p4 , op_p5 , op_nbtotal , op_abundance_rating , op_distribution , 
		op_main_survey_target , opedisthwm , op_density , op_equipment , op_nbfem , op_nbmal , op_nbind , op_totalestim , op_totalweight , 
		op_nbsets , op_nbimmat , op_id , op_nbnets , op_cpue , op_nbnights , op_datasource , op_silvereelcatchwt)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_date AS ob_starting_date,
	NULL AS ob_ending_date,
	data_provider.dp_id AS ob_dp_id, -- wrbd
	gear_type.no_id AS gf_no_gear_type ,
	op.op_nbnets as gf_gear_number ,
	effort_type.no_id as gf_no_effort_type ,
	op.op_nbnights as gf_effort_value,
	NULL as gf_no_name, -- check what is this, nothing references gear_characteristic_type
	op.* 	
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.effort_type,
		dbeel_nomenclature.gear_type,
		(select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='fyke net') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND gear_type.no_name='Fyke Nets' 
	AND effort_type.no_name='Duration days'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --695 lines 

INSERT INTO wrbd.gear_exp_fishery(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		gf_no_gear_type,gf_gear_number,gf_no_effort_type,gf_effort_value,gf_no_name,ob_op_id,
		op_folio_no , op_st_id , op_date , op_year , op_area , op_glass , op_elver , op_yellow , op_silver , op_not_recorded , 
		op_eels_anaesthetized , op_nb_pass , op_p1 , op_p2 , op_p3 , op_p4 , op_p5 , op_nbtotal , op_abundance_rating , op_distribution , 
		op_main_survey_target , opedisthwm , op_density , op_equipment , op_nbfem , op_nbmal , op_nbind , op_totalestim , op_totalweight , 
		op_nbsets , op_nbimmat , op_id , op_nbnets , op_cpue , op_nbnights , op_datasource , op_silvereelcatchwt)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_date AS ob_starting_date,
	NULL AS ob_ending_date,
	data_provider.dp_id AS ob_dp_id, -- wrbd
	gear_type.no_id AS gf_no_gear_type ,
	op.op_nbnets as gf_gear_number ,
	effort_type.no_id as gf_no_effort_type ,
	op.op_nbnights as gf_effort_value,
	NULL as gf_no_name, -- check what is this, and by the way nothing references gear_characteristic_type
	op.* 	
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.effort_type,
		dbeel_nomenclature.gear_type,
		(select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='longline standard bait') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND gear_type.isscfg_code='09.0.0' --Handlines and Pole-Lines (Hand Operated) two lines no idea why...
	AND effort_type.no_name='Duration days'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --1 line 


-- Batch integration, the first level will reference operation again, the second will reference the fish table
--wrbd.batch_ope has already been created
--  here I'm changing according to data filled in the table sometimes op_p1 sometimes op_nbtotal, sometimes the two are different
/*
select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,
CASE WHEN op_p1 is not null then op_p1
WHEN op_nbtotal is null then 0
ELSE op_nbtotal 
end as op_nb,
 cast(NULL as integer) as pa_numero from wrbd.gear_exp_fishery  where op_equipment='fyke net';


*/
-- nb_total
INSERT INTO wrbd.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.op_nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,
		CASE WHEN op_p1 is not null then op_p1
		WHEN op_nbtotal is null then 0
		ELSE op_nbtotal 
		end as op_nb,
		cast(NULL as integer) as pa_numero
		from wrbd.gear_exp_fishery  
		where op_equipment='fyke net') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--695 lines

-- op_p1 ignored
-- op_p2 ignored
-- op_p3 ignored ...
-- density ignored
-- Batch integration, the second level will reference the fish table
-- wrbd.batch_fish already exists;

-- inner request like this	
/*	
select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from wrbd.gear_exp_fishery 
	join wrbd.fish_fi fi on fi_op_id=op_id 
	where op_equipment='fyke net';
*/
INSERT INTO wrbd.batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from wrbd.gear_exp_fishery 
	join wrbd.fish_fi fi on fi_op_id=op_id 
	where op_equipment='fyke net') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--10984 lines


/*
select ba_id AS bc_ba_id,fi_weight from wrbd.gear_exp_fishery
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net'
	*/
-- attention toutes les lignes de batch_fish sont int�gr�es modifier pour le prochain
INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_weight AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_weight from wrbd.gear_exp_fishery
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net') as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		fi_weight>0 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --9278 lines

INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_length*10 AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_length from wrbd.gear_exp_fishery
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net') as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_length>0 
		AND biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; --10968 lines
INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 CASE when fi_sex='not recorded'  then 180
		 when fi_sex='male' then 181
		 when fi_sex='female' then 182
		 when fi_sex='unknown' then 183 -- unidentified
		 ELSE null
		 END  as bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_sex from wrbd.gear_exp_fishery
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net') as joineel,
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_sex IS NOT NULL 
		AND biological_characteristic_type.no_name = 'Sex' 
		AND value_type.no_name = 'Raw data or Individual data'; -- 7732 lines



-----------------------------
-- migration monitoring
----------------------------

DROP TABLE if exists wrbd.migration_monitoring CASCADE;
CREATE TABLE wrbd.migration_monitoring (
	LIKE wrbd.operation_op INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
  CONSTRAINT migration_monitoring_id PRIMARY KEY (ob_id),
  CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id)
      REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mm_monitoring_direction FOREIGN KEY (mm_no_monitoring_direction)
      REFERENCES dbeel_nomenclature.migration_direction (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mm_monitoring_type FOREIGN KEY (mm_no_monitoring_type)
      REFERENCES dbeel_nomenclature.control_type (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ob_origin FOREIGN KEY (ob_no_origin)
      REFERENCES dbeel_nomenclature.observation_origin (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ob_period FOREIGN KEY (ob_no_period)
      REFERENCES dbeel_nomenclature.period_type (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ob_type FOREIGN KEY (ob_no_type)
      REFERENCES dbeel_nomenclature.observation_type (no_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.migration_monitoring);
/*
select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='glass eel fishing'
*/

INSERT INTO wrbd.migration_monitoring(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		mm_no_monitoring_type ,
		mm_no_monitoring_direction ,
		mm_escapment_rate ,
		mm_no_name ,
		ob_op_id,
		op_folio_no , op_st_id , op_date , op_year , op_area , op_glass , op_elver , op_yellow , op_silver , op_not_recorded , 
		op_eels_anaesthetized , op_nb_pass , op_p1 , op_p2 , op_p3 , op_p4 , op_p5 , op_nbtotal , op_abundance_rating , op_distribution , 
		op_main_survey_target , opedisthwm , op_density , op_equipment , op_nbfem , op_nbmal , op_nbind , op_totalestim , op_totalweight , 
		op_nbsets , op_nbimmat , op_id , op_nbnets , op_cpue , op_nbnights , op_datasource , op_silvereelcatchwt)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_date AS ob_starting_date,
	case when op_nbnights is null then op_date+ op_nbnights 
	else op_date
	end AS ob_ending_date, -- some operations are not daily, beware !
	data_provider.dp_id AS ob_dp_id, -- wrbd
	control_type.no_id AS mm_no_monitoring_type ,
	migration_direction.no_id AS mm_no_monitoring_direction ,
	NULL	AS mm_escapment_rate ,
	NULL	As mm_no_name ,
	op.* 	
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.control_type,
		dbeel_nomenclature.migration_direction,
		(select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='glass eel fishing') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND control_type.no_name='Trapping'  --monitoring type
	AND migration_direction.no_name='Upstream migration'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --18 lines 

/*
select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='juvenile trap' -- this is elver
*/

INSERT INTO wrbd.migration_monitoring(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		mm_no_monitoring_type ,
		mm_no_monitoring_direction ,
		mm_escapment_rate ,
		mm_no_name ,
		ob_op_id,
		op_folio_no , op_st_id , op_date , op_year , op_area , op_glass , op_elver , op_yellow , op_silver , op_not_recorded , 
		op_eels_anaesthetized , op_nb_pass , op_p1 , op_p2 , op_p3 , op_p4 , op_p5 , op_nbtotal , op_abundance_rating , op_distribution , 
		op_main_survey_target , opedisthwm , op_density , op_equipment , op_nbfem , op_nbmal , op_nbind , op_totalestim , op_totalweight , 
		op_nbsets , op_nbimmat , op_id , op_nbnets , op_cpue , op_nbnights , op_datasource , op_silvereelcatchwt)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_date AS ob_starting_date,
	case when op_nbnights is null then op_date+ op_nbnights 
	else op_date
	end AS ob_ending_date, -- some operations are not daily, beware !
	data_provider.dp_id AS ob_dp_id, -- wrbd
	control_type.no_id AS mm_no_monitoring_type ,
	migration_direction.no_id AS mm_no_monitoring_direction ,
	NULL	AS mm_escapment_rate ,
	NULL	As mm_no_name ,
	op.* 	
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.control_type,
		dbeel_nomenclature.migration_direction,
		(select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='juvenile trap') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND control_type.no_name='Trapping'  --monitoring type
	AND migration_direction.no_name='Upstream migration'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --2 lines 

/*
select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='fixed trap - silver trap' -- this is elver
*/
-- glass eel and elver integration
-- nb_total
INSERT INTO wrbd.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.op_nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,
		CASE WHEN op_p1 is not null then op_p1
		WHEN op_nbtotal is null then 0
		ELSE op_nbtotal 
		end as op_nb,
		cast(NULL as integer) as pa_numero
		from wrbd.migration_monitoring  
		where op_equipment='juvenile trap'
		or op_equipment='glass eel fishing') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--20 lines OK

-- op_p1 ignored
-- op_p2 ignored
-- op_p3 ignored ...
-- density ignored
-- Batch integration, the second level will reference the fish table
-- wrbd.batch_fish already exists;	


INSERT INTO wrbd.batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from wrbd.migration_monitoring   
	join wrbd.fish_fi fi on fi_op_id=op_id 
	where op_equipment='juvenile trap'
	or op_equipment='glass eel fishing') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='extracted from the aqu. env.' 
	AND value_type.no_name='Raw data or Individual data';--690 lines


/*
select ba_id AS bc_ba_id,fi_weight from wrbd.gear_exp_fishery
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net'
	*/
-- attention toutes les lignes de batch_fish sont int�gr�es modifier pour le prochain
INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_weight AS bc_numvalue
	FROM (
		select ba_id AS bc_ba_id,
		CASE WHEN fi_weight>100 then fi_weight/1000
		else fi_weight 
		end as fi_weight  
		from wrbd.migration_monitoring
		join wrbd.batch_fish  on ob_id=ba_ob_id 
		where op_equipment='juvenile trap'
		or op_equipment='glass eel fishing'
		and fi_weight>0 -- to avoid -99
		) as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		fi_weight>0 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --679

INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_length AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,
		fi_length*10 as fi_length -- mm  
		from wrbd.migration_monitoring
		join wrbd.batch_fish  on ob_id=ba_ob_id 
		where op_equipment='juvenile trap'
		or op_equipment='glass eel fishing'
		and fi_length>0 -- to avoid -99
		) as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; -- 682 lines





INSERT INTO wrbd.migration_monitoring(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		mm_no_monitoring_type ,
		mm_no_monitoring_direction ,
		mm_escapment_rate ,
		mm_no_name ,
		ob_op_id,
		op_folio_no , op_st_id , op_date , op_year , op_area , op_glass , op_elver , op_yellow , op_silver , op_not_recorded , 
		op_eels_anaesthetized , op_nb_pass , op_p1 , op_p2 , op_p3 , op_p4 , op_p5 , op_nbtotal , op_abundance_rating , op_distribution , 
		op_main_survey_target , opedisthwm , op_density , op_equipment , op_nbfem , op_nbmal , op_nbind , op_totalestim , op_totalweight , 
		op_nbsets , op_nbimmat , op_id , op_nbnets , op_cpue , op_nbnights , op_datasource , op_silvereelcatchwt)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_date AS ob_starting_date,
	case when op_nbnights is null then op_date+ op_nbnights 
	else op_date
	end AS ob_ending_date, -- some operations are not daily, beware !
	data_provider.dp_id AS ob_dp_id, -- wrbd
	control_type.no_id AS mm_no_monitoring_type ,
	migration_direction.no_id AS mm_no_monitoring_direction ,
	NULL	AS mm_escapment_rate ,
	NULL	As mm_no_name ,
	op.* 	
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.control_type,
		dbeel_nomenclature.migration_direction,
		(select st.op_id as op_ob_id, op.* from wrbd.operation_op op join wrbd.stationdbeel st on op.op_st_id=st.st_id where op_equipment='fixed trap - silver trap') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND control_type.no_name='Trapping'  --monitoring type
	AND migration_direction.no_name='Upstream migration'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --303 lines 	

-- silver eel integration
-- nb_total
INSERT INTO wrbd.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.op_nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,
		CASE WHEN op_p1 is not null then op_p1
		WHEN op_nbtotal is null then 0
		ELSE op_nbtotal 
		end as op_nb,
		cast(NULL as integer) as pa_numero
		from wrbd.migration_monitoring  
		where op_equipment='fixed trap - silver trap') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Silver eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--303 lines OK

-- op_p1 ignored
-- op_p2 ignored
-- op_p3 ignored ...
-- density ignored
-- Batch integration, the second level will reference the fish table
-- wrbd.batch_fish already exists;	


INSERT INTO wrbd.batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from wrbd.migration_monitoring   
	join wrbd.fish_fi fi on fi_op_id=op_id 
	where op_equipment='fixed trap - silver trap') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Silver eel'
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--14606 lines


/* 
select ba_id AS bc_ba_id,fi_weight from wrbd.gear_exp_fishery
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net'
	*/
-- attention toutes les lignes de batch_fish sont int�gr�es modifier pour le prochain
INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_weight AS bc_numvalue
	FROM (
		select ba_id AS bc_ba_id,
		fi_weight   
		from wrbd.migration_monitoring
		join wrbd.batch_fish  on ob_id=ba_ob_id 
		where op_equipment='fixed trap - silver trap'
		and fi_weight>0 -- to avoid -99
		) as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		
		biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --7335

INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_length AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,
		fi_length*10 as fi_length -- mm  
		from wrbd.migration_monitoring
		join wrbd.batch_fish  on ob_id=ba_ob_id 
		where op_equipment='fixed trap - silver trap'
		and fi_length>0 -- to avoid -99
		) as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; -- 14578 lines


INSERT INTO wrbd.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 CASE when fi_sex='not recorded'  then 180
		 when fi_sex='male' then 181
		 when fi_sex='female' then 182
		 when fi_sex='unknown' then 183 -- unidentified
		 ELSE null
		 END  as bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_sex from wrbd.migration_monitoring
	join wrbd.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fixed trap - silver trap') as joineel,
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_sex IS NOT NULL 
		AND biological_characteristic_type.no_name = 'Sex' 
		AND value_type.no_name = 'Raw data or Individual data'; --13506

/*


