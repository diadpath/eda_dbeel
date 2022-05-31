--------------------------------------------------------------------------------------------
--  Stations
--------------------------------------------------------------------------------------------


ALTER TABLE france.station_fdloire RENAME COLUMN geometry TO geom;


CREATE INDEX 
  ON france.station_fdloire
  USING gist
  (geom);
  

-- to store the link for dbeel
ALTER TABLE sudoang.gt6_station ADD COLUMN dbeel_op_id uuid;
  


-- add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name)
SELECT DISTINCT sf.sta_source from station_fdloire sf ;

-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	VALUES 
	('François-Xavier Ripoche', 28),
	('Cyril Lombardot', 29),
	('David Maffre', 30),
	('Barbara Gérard',31),
	('Brice Nowosielski', 32),
	('Mélanie Hilaire', 33),
	('Laurent Delliaux', 34);


-- Create the stationdbeel table from dbeel
DROP TABLE if exists france.dbeel_station_fdloire CASCADE;
CREATE TABLE france.dbeel_station_fdloire (
	sta_id integer,
	country character varying(2),		
	CONSTRAINT pk_so_op_id_loire PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id_loire FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);

--select * from france.dbeel_station_aspe limit 10;

DELETE FROM france.dbeel_batch_ope_aspe; --75666
DELETE FROM france.dbeel_electrofishing_aspe; --33300
DELETE FROM france.dbeel_station_fdloire; 


-- Insert data into the dbeel table
INSERT INTO france.dbeel_station_fdloire 
	SELECT  uuid_generate_v4() AS op_id, -- UNIQUE identifier
	'3035' AS op_gis_systemname ,
	'fdloire' AS op_gis_layername, 
	NULL AS op_gislocation, 
	sta_lib AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, -- already 3035
   sta_id,
   'FR' AS country 
	FROM france.station_fdloire ;  --32720 17s => 31734 après filtre contour france

------------------------------
--Add uuid to original table
--------------------------------
	
	
	ALTER TABLE france.station_fdloire  ADD COLUMN sta_dbeel_op_id UUID;
	UPDATE france.station_fdloire SET sta_dbeel_op_id = op_id FROM
 france.dbeel_station_fdloire WHERE dbeel_station_fdloire.sta_id=station_fdloire.sta_id; --2550
 
 
 
 /*--------------------------------------------------
-- fdloire.electrofishing
-------------------------------------------------*/
	
DROP TABLE if exists france.dbeel_electrofishing_fdloire CASCADE;

CREATE TABLE france.dbeel_electrofishing_fdloire(
  odp_nombre_points_anguilles INTEGER,
  nb_point INTEGER,
  op_typ TEXT,
  mom_libelle TEXT,
  ope_id INTEGER,
  pop_id INTEGER,
  sta_id INTEGER,
  CONSTRAINT pk_oo_ob_id PRIMARY KEY (ob_id),
	CONSTRAINT fk_oo_op_id FOREIGN KEY (ob_op_id)	
		REFERENCES france.dbeel_station_aspe (op_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_oo_dp_id FOREIGN KEY (ob_dp_id)	
		REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_electrofishing_mean FOREIGN KEY (ef_no_electrofishing_mean)
		REFERENCES dbeel_nomenclature.electrofishing_mean (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_electrofishing_method FOREIGN KEY (ef_no_fishingmethod)
		REFERENCES dbeel_nomenclature.scientific_observation_method (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_ob_no_origin FOREIGN KEY (ob_no_origin)
		REFERENCES dbeel_nomenclature.observation_origin (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_ob_no_period FOREIGN KEY (ob_no_period)
		REFERENCES dbeel_nomenclature.period_type (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_ob_no_type FOREIGN KEY (ob_no_type)
		REFERENCES dbeel_nomenclature.observation_type (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.electrofishing);

-- duplicate with data already in dbeel, there is one internal duplicate in dbeel that we ignore
-- we choose the closest station to join with

--update sudoang.gt6_station set dbeel_op_id IS NULL;
WITH 
projection_fdL AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.station_fdloire g
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_gt6 AS (
SELECT distinct on (id) * from projection_gt6
)
--SELECT * from closest_gt6; -- 16 rows
UPDATE sudoang.gt6_station SET dbeel_op_id = op_id
	FROM closest_gt6 c
	WHERE c.id=gt6_station.id; -- 16 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)

--SELECT Find_SRID('sudoang', 'dbeel_station', 'the_geom'); --3035
-- SELECT * from sudoang.dbeel_station limit 10;
-- select * from sudoang.gt6_station limit 10

begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'GT6' AS op_gis_layername, -- GT6 or sta_source (not correspond with the information in dbeel.establishment)
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS op_op_id,
	geom as the_geom, 	
	NULL as locationid,
	case when sta_source in ('ecobiop', 'bages_sigean') then 'FR'
	WHEN sta_source in ('fcup_ciimar', 'fcul_mare') then 'PT' 
	WHEN sta_source in ('udg', 'AZTI', 'uco') then 'ES' END as country,
	sta_cod as place_classification,
	NULL as codhb,	
	null as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.gt6_station 
	where dbeel_op_id is null -- as those lines are not reprojected
	; -- 83 rows
COMMIT;

-- We put back the op_id into the source table
begin;
With jointure as (
SELECT * from sudoang.dbeel_station JOIN
sudoang.gt6_station ON op_gislocation=id)
update sudoang.gt6_station set dbeel_op_id=op_id from jointure where jointure.id = gt6_station.id; -- 83 rows
commit;


---------------------------------------
-- INSERTING GT6 OPERATIONS 2018/2019
---------------------------------------

-- select * from sudoang.gt6_ope; -- 98 rows
-- select * from sudoang.gt6_station;
delete from sudoang.gt6_ope where op_cod in ('gro_50001','gro_60001','gro_160001','gro_190001'); -- 4 empty lines, 94 rows

---- Add dbeel_ob_id in guipuz_operation table
ALTER TABLE sudoang.gt6_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with g_station_operation as(
select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
)-- joining the two tables on the gt6 side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 231 rows (but the date it is not the same)


-- Checking the duplicates for year: real duplicates
with g_station_operation as(
select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
)-- joining the two tables on the gt6 side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 15 rows from Gipuzkoa

-- for those lines where there is a join, add ob_id in gt6 tables
ALTER TABLE sudoang.gt6_ope ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)

--select * from op_duplicates; -- 15 rows
update sudoang.gt6_ope set is_duplicate = TRUE where op_cod in (select op_cod from op_duplicates); -- 15rows

-- We search into the dbeel the duplicated operations. We will supress them as we have better information from GT6:
-- We have to do three times for different tables because we have on delete restrict clause in the table:
begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	),

fish_duplicates as (
	select * from sudoang.dbeel_batch_fish where ba_ob_id in (select ob_id from op_duplicates)
	)

--select * from sudoang.dbeel_mensurationindiv_biol_charac where bc_ba_id in (select ba_id from fish_duplicates);
delete from sudoang.dbeel_mensurationindiv_biol_charac where bc_ba_id in (select ba_id from fish_duplicates); -- 1681 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from sudoang.dbeel_batch_fish where ba_ob_id in (select ob_id from op_duplicates);
delete from sudoang.dbeel_batch_fish where ba_ob_id in (select ob_id from op_duplicates); -- 816 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from sudoang.dbeel_batch_ope where ba_ob_id in (select ob_id from op_duplicates); -- 60 rows
delete from sudoang.dbeel_batch_ope where ba_ob_id in (select ob_id from op_duplicates); -- 60 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from sudoang.dbeel_electrofishing where ob_id in (select ob_id from op_duplicates); -- 15 rows
delete from sudoang.dbeel_electrofishing where ob_id in (select ob_id from op_duplicates); -- 15 rows
commit;

---- STEP 2: integrate all new data operations and then fish....there are no longer any duplicates

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (op_cod, op_dat)) from sudoang.gt6_ope; -- 94 operations
-- select * from sudoang.dbeel_station where op_gis_layername = ''; --  stations

-- 		The id of sudoang.gt6_ope is 'op_cod', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'gt6_ob_id' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table sudoang.gt6_ope add column gt6_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO sudoang.dbeel_electrofishing (
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
	ef_nbpas,
	ob_op_id
	)
	SELECT
	gt6_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, -- Isabel Domingos or each pilot basin leader?
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length*op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass AS ef_nbpas, -- 1, 2 or 3
	dbeel_op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.gt6_station
	join
		sudoang.gt6_ope on gt6_ope.op_sta_id = gt6_station.sta_cod
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Isabel Domingos'  -- or each pilot basin leader?
	ANd dp_et_id = 22 -- two lines for Isabel Domingos (fcul and GT6)
	; -- 94 rows
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.gt6_ope there is only information about eels
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 94 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope,
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
	; -- 94 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope,
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
	and op_p2 is not null -- this will be used for next time but we didn't use it during first integration
	; -- 94 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope,
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
	and op_p3 is not null
	; -- 4 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_dens AS ba_quantity, -- ind/m2
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.gt6_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 94 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.gt6_fish add column fish_id serial;
alter table sudoang.gt6_fish add column ba_id uuid; -- We can't generate hte ba_id for the whole table because there are more than 200 000 rows!

---- 		Check duplicates: Joining gt6_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.gt6_fish a join sudoang.gt6_ope o on a.op_cod = o.op_cod
	join sudoang.dbeel_electrofishing l on l.ob_id = o.gt6_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	

begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN ang_silver='FALSE' THEN 226 --'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 -- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	gt6_ope.gt6_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	gt6_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.gt6_fish
	join sudoang.gt6_ope
	on gt6_fish.op_cod = gt6_ope.op_cod	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 4 463 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in gt6_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from sudoang.dbeel_station;

with fish_from_gt6 as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 20) -- 4463 rows
--select * from fish_from_gt6 join sudoang.gt6_fish on fish_from_gt6.fish_id = gt6_fish.fish_id; -- 4463 rows
UPDATE sudoang.gt6_fish b
SET ba_id = fish_from_gt6.ba_id
FROM fish_from_gt6
WHERE fish_from_gt6.fish_id = b.fish_id; -- 4463 rows
-- select * from sudoang.gt6_fish where ba_id is null; -- 3 rows


---- 		Insert LENGTH (no_id = 39)
-- with gt6_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from sudoang.gt6e_fish order by locationid),
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 4463 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 4354 rows  (109 rows with weight NULL)
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 385 rows (4079 rows with ang_eye_diam_vert NULL)
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz > 0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 381 rows (total: 387 rows)
commit;


---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect > 0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 382 rows (total: 391 rows)
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" from amber_portugal is text, it must be converted into boolean:
alter table sudoang.gt6_fish
alter column ang_neuromast
set data type boolean
using case
    when ang_neuromast = 'TRUE' then true
    when ang_neuromast = 'FALSE' then false
    else null
end;

/* postgresql stops working when I run this query:
alter table sudoang.gt6_fish
alter column ang_neuromast
set data type integer
using case
    when ang_neuromast = 'TRUE' then 1
    when ang_neuromast = 'FALSE' then 0
    else null
end;
*/


/*	ERROR:  insertion or update in the table «dbeel_mensurationindiv_biol_charac» violates the foreign key «fk_mensindivbiocho_bc_value_type»
	DETAIL:  The key (bc_no_value_type)=(0) isn't present in the table «value_type».
	CORRECTED: error in value_type.no_name
*/

begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null and ang_neuromast is not null) -- 3832
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast = FALSE THEN 0 -- DOESN'T WORK (because of '')
	     WHEN ang_neuromast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3832 rows
commit;


---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" from gt6_fish is text, it must be converted into boolean:
alter table sudoang.gt6_fish
alter column ang_contrast
set data type boolean
using case
    when ang_contrast = 'TRUE' then true
    when ang_contrast = 'FALSE' then false
    else null
end;

begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null and ang_contrast is not null) -- 4037
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_contrast = FALSE THEN 0
	     WHEN ang_contrast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_contrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 4037 rows
commit;