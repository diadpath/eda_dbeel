
-- see http://trac.eptb-vilaine.fr:8066/trac/wiki/electrofishing%20data for creation of tables stations, survey, fishlength in ireland

--INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('Marine Institute');
--INSERT INTO dbeel.data_provider(dp_name, dp_et_id) VALUES ('Russell Poole & Elvira de Eito',2);

--select * from wrbd.stationdbeel;
--select * from dbeel.observation_places;
--select * from ireland.stationdbeel;
--select count (*) from ireland.stations
--SELECT count(*) FROM ireland.stationdbeel


DROP TABLE IF EXISTS ireland.ireland_station_ccm_500;
CREATE TABLE ireland.ireland_station_ccm_500 as (
        SELECT distinct on (locationcode) locationcode as st_id ,
        gid, 
        wso1_id,
        min(distance) as distance, 
        op_id,
        the_geom FROM (
               SELECT locationcode, gid , wso1_id, CAST(st_distance(r.the_geom, s.the_geom) as  decimal(15,1)) as distance,s.the_geom, op_id 
               FROM ireland.stationdbeel As s
               INNER JOIN  ccm21.riversegments r ON ST_DWithin(r.the_geom, s.the_geom,500)
               WHERE s.the_geom IS NOT NULL
               ORDER BY locationcode, st_distance(r.the_geom, s.the_geom)) AS sub 
        GROUP BY locationcode,distance, gid, wso1_id, op_id,  the_geom
); --801
alter table ireland.ireland_station_ccm_500 add column id serial;
SELECT * FROM ireland.ireland_station_ccm_500
-- mise à jour de la table geometry_columns



CREATE INDEX indexstation_ccm_500 ON ireland.ireland_station_ccm_500
  USING GIST(the_geom);






DROP SEQUENCE ireland.ireland_station_ccm_500_id_seq
DROP TABLE if exists ireland.stationdbeel CASCADE;
CREATE TABLE ireland.stationdbeel (
	LIKE ireland.stations,
	CONSTRAINT pk_so_op_id PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);

-- Stations treated the same AS a riversegment... OK.

update ireland.stations set site=NULL where site='n/a'; --267
--COALESCE RETRUNS THE FIRST NON NULL VALUE
select coalesce(sitecode,site) from ireland.stations
select * from ireland.stations
-- I'm using where dbeel_op_id is null to avoid duplicates
-- In this table the first columns are contrained and I'm keeping the structure of the rest of the files.
INSERT INTO ireland.stationdbeel
	SELECT  uuid_generate_v4() AS op_id,
	'wrbd' AS op_gis_systemname ,
	'Marine Institute' AS op_gis_layername, 
	locationcode AS op_gislocation,
	coalesce(sitecode,site) as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	  the_geom, 
	  id, 
	  locationcode, 
	  sourcefile, 
	  easting, 
	  northing, 
	  catchment, 
	  waterbody, 
	  site, 
	  sitecode 
	   FROM ireland.stations 
	where dbeel_op_id is null; -- 889 lines

----------------------------------------------------
-- ireland.electrofishing
---------------------------------------------------
select * from ireland.electrofishing
DROP TABLE if exists ireland.electrofishing CASCADE;
CREATE TABLE ireland.electrofishing (
	surveyid integer,
	--LIKE ireland.survey INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
	CONSTRAINT pk_oo_ob_id PRIMARY KEY (ob_id),
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

-----------------------------
-- I electrofishing handset
----------------------------
select * from ireland.survey
update ireland.survey set sitelength=NULL where sitelength=-99;--27
update ireland.survey set sitewettedarea=NULL where sitewettedarea=-99;--34
select * from ireland.electrofishing
-- below I'm merging the stations inserted in ireland.stationdbeel and those that were identified as already inserted (and having a dbeel_op_id is not null)
-- for those I'm using the column dbeel_op_id uuid inserted previously for spatial duplicated located less than 20 m from  a station
-- so I get the survey table with a the beginning a column with op_ob_id which is the code for the observation place.
-- I can't (for no obvious reason) put all survey in electrofishing table. I don't know why but I've spent a lot of time trying to do it and it does not work
-- so I just use surveyid and will join the electrofishing table with survey later to get the content of the survey table
-- the reason for the script not working is unclear, guess using a LIKE ireland.survey INCLUDING DEFAULTS INCLUDING CONSTRAINTS predicate
-- creates an autoincremented serial that it does not like, or there is a problem with the_geom
--ERREUR:  l'attribut 34 a un type invalide
--DETAIL:  La table a le type integer alors que la requête attend geometry.
-- What't weird is that I get this message even if I don't tell postgres to integrate the_geom column.
drop table if exists ireland.temp_electrofishing;
create table ireland.temp_electrofishing as(
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	thedate AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	sitewettedarea AS ef_wetted_area, 
	sitelength AS ef_fished_length,
	siteaveragewettedwidth AS ef_fished_width,
	cast(NULL as numeric) AS ef_duration,
	op.numfishingpasses AS ef_nbpas,
	op.ob_op_id as ob_op_id,
	op.surveyid as survey_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		(select st.op_id as ob_op_id, op.* from ireland.survey op join ireland.stationdbeel st on op.locationcode=st.locationcode
		UNION
		select sta.dbeel_op_id as ob_op_id,op.* from ireland.survey op join ireland.stations sta on op.locationcode=sta.locationcode where sta.dbeel_op_id is not null
		order by surveyid
		) as op	
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Whole'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'); --1256

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
	surveyid
	)
	SELECT * from ireland.temp_electrofishing; --1256
drop table ireland.temp_electrofishing;
	
-- NUMBER PER PASS... AND TOTAL NUMBER
-- Batch integration, the first level will reference operation again, the second will reference the fish table


DROP TABLE if exists ireland.batch_ope CASCADE;
CREATE TABLE ireland.batch_ope (
		op_locationcode integer,
		op_surveyid integer, -- here I'm not setting like operation but only choosing some columns
		op_nb numeric,		
		pa_numero integer,
	CONSTRAINT pk_batch_ope_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_batch_ope_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_batch_ope_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_batch_ope_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_batch_ope_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,			
	CONSTRAINT fk_batch_ope_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT c_fk_batch_ope_op_locationcode FOREIGN KEY (op_locationcode)
		REFERENCES ireland.stations (locationcode) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
		) INHERITS (dbeel.batch);

-- select * from ireland.batch_ope;
-- nb_total -- here pa_numero is null ;
-- select * from ireland.electrofishing e join ireland.survey s on e.surveyid=s.surveyid
-- number per pass and total number are  
-- referenced by biological_characteristic_type.no_name='Number' (see biological_characteristic_type.no_id=47)
INSERT INTO ireland.batch_ope
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
		(select ob_id as ba_ob_id, 
		cast(NULL as uuid) as ba_ba_id,
		locationcode as op_locationcode,
		s.surveyid as op_surveyid,
		totaleel as op_nb,
		 cast(NULL as integer) as pa_numero
		from ireland.electrofishing e join ireland.survey s on e.surveyid=s.surveyid) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--1256 lines done 20/04/2012

-- op_p1 (this batch is of level 2, 1 is total number, the pass is identified by the number in pa_numero)
-- I kept this as in the first version of the dbeel there was not number_p1 the new version corrects this
-- also referenced by biological_characteristic_type.no_name='Number p1' (i.e. biological_characteristic_type.no_id=231)
INSERT INTO ireland.batch_ope
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
			(select ob_id as ba_ob_id, 
		cast(NULL as uuid) as ba_ba_id,
		locationcode as op_locationcode,
		s.surveyid as op_surveyid,
		fishing1 as op_nb,
		1 as pa_numero
		from ireland.electrofishing e join ireland.survey s on e.surveyid=s.surveyid) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; --1256 done 20/04/2012

	-- op_p2
INSERT INTO ireland.batch_ope
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
		(select ob_id as ba_ob_id, 
		cast(NULL as uuid) as ba_ba_id,
		locationcode as op_locationcode,
		s.surveyid as op_surveyid,
		fishing2 as op_nb,
		2 as pa_numero
		from ireland.electrofishing e join ireland.survey s on e.surveyid=s.surveyid where fishing2 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2'
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; --788 done 20/04/2012
	-- op_p3
INSERT INTO ireland.batch_ope
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
		(select ob_id as ba_ob_id, 
		cast(NULL as uuid) as ba_ba_id,
		locationcode as op_locationcode,
		s.surveyid as op_surveyid,
		fishing3 as op_nb,
		3 as pa_numero
		from ireland.electrofishing e join ireland.survey s on e.surveyid=s.surveyid where fishing3 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; --540 done 20/04/2012
-- op_p4
INSERT INTO ireland.batch_ope
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
		(select ob_id as ba_ob_id, 
		cast(NULL as uuid) as ba_ba_id,
		locationcode as op_locationcode,
		s.surveyid as op_surveyid,
		fishing4 as op_nb,
		4 as pa_numero
		from ireland.electrofishing e join ireland.survey s on e.surveyid=s.surveyid where fishing4 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p4' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; --1 done 20/04/2012

	-- op_p5
INSERT INTO ireland.batch_ope
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
		(select ob_id as ba_ob_id, 
		cast(NULL as uuid) as ba_ba_id,
		locationcode as op_locationcode,
		s.surveyid as op_surveyid,
		fishing5 as op_nb,
		5 as pa_numero
		from ireland.electrofishing e join ireland.survey s on e.surveyid=s.surveyid where fishing5 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p5'
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; --0 done 20/04/2012
	
-- densities as below are also calculated later but still I integrate them here
-- referenced by biological_characteristic_type.no_name='density' and the corresponding biological_characteristic_type.no_id

INSERT INTO ireland.batch_ope
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
		(select ob_id as ba_ob_id, 
		cast(NULL as uuid) as ba_ba_id,
		locationcode as op_locationcode,
		s.surveyid as op_surveyid,
		estimate_for_site as op_nb,
		cast(NULL as integer) as pa_numero
		from ireland.electrofishing e join ireland.survey s on e.surveyid=s.surveyid where estimate_for_site is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';	--457
*/
	

-- Batch integration, the second level will reference the fish table
-- 20/04/2012 I'm stopping there , the integration of fish will have to wait !




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
-- attention toutes les lignes de batch_fish sont intégrées modifier pour le prochain
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
-- attention toutes les lignes de batch_fish sont intégrées modifier pour le prochain
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
-- attention toutes les lignes de batch_fish sont intégrées modifier pour le prochain
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
-- attention toutes les lignes de batch_fish sont intégrées modifier pour le prochain
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


-- I have forgotten to put in mm for yellow eels... now corrected in script
/*
update wrbd.mensurationindiv_biol_charac set bc_numvalue=bc_numvalue*10 where bc_id in(
select bc_id from wrbd.mensurationindiv_biol_charac 
join dbeel_nomenclature.biological_characteristic_type on bc_no_characteristic_type=biological_characteristic_type.no_id 
join wrbd.batch_fish on bc_ba_id=ba_id
where no_name='Length'
and fi_lifestage='yellow') -- 10489
*/