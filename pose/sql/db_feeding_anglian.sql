-- TODO line 1106 integrate gear fishing if necessary
/*
Integration of english data for electrofishing 
anglian.station all stations
anglian.operation contains all operations
anglian.electrofishing all electrofishing but not other surveys
anglian.batchope all operations
anglian.batchfish all fishes
anglian.mensurationindiv_biol_charac data for fish length and weight

three kind of stages are entered at the batch level. Glass eel, Yellow eel, and glass yellow and silver mixed.
The data for gear fishing are still to be integrated at line 1102
I've kept the example of western to do that.
*/

-- run once
INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('Environment agency');
INSERT INTO dbeel.data_provider(dp_name, dp_et_id) VALUES ('Miran Apprahamian',2);
create schema anglian;
INSERT INTO dbeel_nomenclature.biological_characteristic_type (no_type,no_name,bc_label,bc_unit,bc_data_type) values ('Biological','Number p6','Number in the 6th pass','Dimensionless','Integer');
-- end run once

drop table if exists anglian.quantitative_cs_number_estimates;
create table anglian.quantitative_cs_number_estimates(
location_name character varying(50),
abc_site character varying(200),
top_tier_site character varying(50),
site_parent_name character varying(50),
site_id integer,
site_name character varying(100),
survey_id integer,
event_date date,
event_date_year integer,
survey_ranked_ngr character varying(50),
survey_length_m numeric,
survey_width_m numeric,
survey_area_m2 numeric,
catch_method_name character varying(50),
survey_method_name character varying(30),
no_of_runs integer,
species_id integer,
species_name character varying(50),
latin_name character varying(50),
run_1 integer,
run_2 integer,
run_3 integer,
run_4 integer,
run_5 integer,
run_6 integer,
total_nos_all_runs integer,
cs_pop_est numeric,
cs_pe_se numeric,
cs_catch_eff numeric,
cs_ce_se numeric,
lat84 float,
long84 float);
copy anglian.quantitative_cs_number_estimates from 'E:/IAV/eda/anglian/MAprahamian_04/quantitativecs.csv' with CSV header delimiter as ';';--11362

drop table if exists anglian.single_run_including_trac;
create table anglian.single_run_including_trac(
location_name character varying(50),
abc_site character varying(200),
top_tier_site character varying(50),
site_parent_name character varying(50),
site_id integer,
site_name character varying(50),
survey_id integer,
event_date date,
event_date_year integer,
survey_ranked_ngr character varying(50),
survey_length_m numeric,
survey_width_m numeric,
survey_area_m2 numeric,
catch_method_name character varying(50),
survey_method_name character varying(30),
no_of_runs integer,
species_id integer,
species_name character varying(50),
latin_name character varying(50),
run_1 integer,
run_2 integer,
run_3 integer,
run_4 integer,
run_5 integer,
run_6 integer,
total_nos_all_runs integer,
lat84 float,
long84 float);
copy anglian.single_run_including_trac from 'E:/IAV/eda/anglian/MAprahamian_04/single_run_including_trac.csv' with CSV header delimiter as ';';----7385

--Eel_Length_&_Weights_All_Years_All_Locations_Quantitative_Surveys.txt
drop table if exists anglian.length_weight_qs;
create table anglian.length_weight_qs(
location_name character varying(50),
abc_site character varying(200),
top_tier_site character varying(50),
site_parent_name character varying(50),
site_id integer,
site_name character varying(50),
survey_id integer,
event_date date,
event_date_year integer,
survey_ranked_ngr character varying(50),
survey_length_m numeric,
survey_width_m numeric,
survey_area_m2 numeric,
catch_method_name character varying(50),
survey_method_name character varying(30),
no_of_runs integer,
species_id integer,
species_name character varying(50),
latin_name character varying(50),
run_number integer,
lw_measured_id integer,
length_mm numeric,
weight_g numeric);

copy anglian.length_weight_qs from 'E:/IAV/eda/anglian/MAprahamian_04/Length_Weights_QS.csv' with CSV header delimiter as ';'; --85897

--Eel_Length_&_Weights_All_Years_All_Locations_SingleRun_IncludingTraC.txt
drop table if exists anglian.length_weight_singlerun;
create table anglian.length_weight_singlerun(
location_name character varying(50),
abc_site character varying(200),
top_tier_site character varying(50),
site_parent_name character varying(50),
site_id integer,
site_name character varying(50),
survey_id integer,
event_date date,
event_date_year integer,
survey_ranked_ngr character varying(50),
survey_length_m numeric,
survey_width_m numeric,
survey_area_m2 numeric,
catch_method_name character varying(50),
survey_method_name character varying(30),
no_of_runs integer,
species_id integer,
species_name character varying(50),
latin_name character varying(50),
run_number integer,
lw_measured_id integer,
length_mm numeric,
weight_g numeric);

copy anglian.length_weight_singlerun from 'E:/IAV/eda/anglian/MAprahamian_04/Eel_Length_&_Weights_All_Years_All_Locations_SingleRun_IncludingTraC.csv' with CSV header delimiter as ';'; --30092
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- INTEGRATION DES DONNEES DANS LA DBEEL
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++=
-- creation de la table des stations
drop table if exists anglian.station;
create table anglian.station as(
select distinct on (site_id) * from (
SELECT location_name, abc_site, top_tier_site, site_parent_name, site_id, site_name,lat84,long84  FROM anglian.quantitative_cs_number_estimates 
UNION
SELECT location_name, abc_site, top_tier_site, site_parent_name, site_id, site_name,lat84,long84  FROM anglian.single_run_including_trac) as stationunion
order by site_id); --7065
alter table anglian.station add constraint c_pk_anglianstation primary key(site_id);
select addgeometrycolumn('anglian', 'station', 'the_geom', 3035, 'POINT', 2);
--alter table anglian.station add constraint enforce_srid_the_geom   CHECK (st_srid(the_geom) = 3035);
UPDATE anglian.station set the_geom= ST_Transform(ST_GeomFromText('POINT('||long84||' '||lat84||')',4326),3035) ;
/*
select long84, lat84 from anglian.station
SELECT
  'lat: ' || ST_Y(a.the_geom) as Latitude,
  'long: ' || ST_X(a.the_geom) as Longitude
FROM (
    SELECT ST_Transform(the_geom,4326) AS the_geom
    FROM  anglian.station
    )as a;
*/

DROP TABLE if exists anglian.stationdbeel CASCADE;
CREATE TABLE anglian.stationdbeel (
	LIKE anglian.station,
	CONSTRAINT pk_so_op_id PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);
ALTER TABLE anglian.stationdbeel  add constraint c_uk_site_id unique(site_id);
-- TODO: insert trigger
-- Stations treated the same AS a riversegment... OK.
-- select * from anglian.stationdbeel
INSERT INTO anglian.stationdbeel
	SELECT  uuid_generate_v4() AS op_id,
	'Environment Agency' AS op_gis_systemname ,
	'NFPD' AS op_gis_layername, 
	st.site_id AS op_gislocation,
	st.site_name AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	the_geom,
	location_name,
	abc_site,
	top_tier_site,
	site_parent_name,
	site_id,
	site_name,
	lat84,
	long84 FROM anglian.station st ; -- 7065 lines

----------------------------------------------------
-- anglian.electrofishing
---------------------------------------------------
--All surveys are integrated below, the column catch_method_name explains if it is quantitative depletion or single run
-- according to the catch_method_name, the data will be integrated below
drop table if exists anglian.operation;
create table anglian.operation as(
SELECT DISTINCT ON (survey_id) * FROM(
SELECT  site_id, survey_id,event_date, event_date_year,survey_ranked_ngr,survey_length_m,survey_width_m,survey_area_m2,catch_method_name,survey_method_name,no_of_runs,run_1,run_2,run_3,run_4,run_5,run_6,total_nos_all_runs 
  FROM anglian.quantitative_cs_number_estimates 
UNION
SELECT site_id, survey_id,event_date, event_date_year,survey_ranked_ngr,survey_length_m,survey_width_m,survey_area_m2,catch_method_name,survey_method_name,no_of_runs,run_1,run_2,run_3,run_4,run_5,run_6,total_nos_all_runs 
  FROM anglian.single_run_including_trac) as operationunion
order by survey_id); --18 364
alter table anglian.operation add constraint c_pk_anglianoperation primary key(survey_id);
alter table anglian.operation add constraint c_fk_site_id FOREIGN KEY (site_id) references anglian.station (site_id);

-- select * from anglian.operation;
--select distinct on (survey_method_name) survey_method_name from anglian.operation
/*
'AC ELECTRIC FISHING'
'BEAM TRAWL NETTING' =>gear_fishing 
'Beam Trawl Netting 1.5m' =>gear_fishing 
'Beam Trawl Netting 2.0m' =>gear_fishing 
'DC ELECTRIC FISHING'
'DIP NETTING'=>gear_fishing 
'ELECTRIC FISHING'
'FIXED TRAP FISHING' gear_fishing 
'FYKE NETTING' =>gear_fishing 
'INTAKE SCREEN SAMPLING' =>gear_fishing 
'KICK NETTING' =>gear_fishing 
'NETTING' =>gear_fishing 
'NOT RECORDED'
'OTTER TRAWL NETTING' =>gear_fishing 
'PDC ELECTRIC FISHING'
'PORTABLE TRAP FISHING' =>gear_fishing 
'ROD AND LINE' =>gear_fishing 
'SEINE NETTING' =>gear_fishing 
'TRAPPING' =>gear_fishing 
'TRAWL NETTING' =>gear_fishing 
'WRAP AROUND SEINE NETTING' =>gear_fishing 
*/
-----------------------------
-- I electrofishing 
----------------------------
--'AC ELECTRIC FISHING','DC ELECTRIC FISHING','ELECTRIC FISHING','PDC ELECTRIC FISHING'
--catch_method_name='CATCH DEPLETION SAMPLE'

DROP TABLE if exists anglian.electrofishing CASCADE;
CREATE TABLE anglian.electrofishing (
	LIKE anglian.operation INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
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




INSERT INTO anglian.electrofishing (ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		ef_no_fishingmethod,ef_no_electrofishing_mean,ef_wetted_area,ef_fished_length,ef_fished_width,ef_duration,ef_nbpas,ob_op_id,
		site_id, survey_id,event_date, event_date_year,survey_ranked_ngr,survey_length_m,survey_width_m,survey_area_m2,catch_method_name,
		survey_method_name,no_of_runs,run_1,run_2,run_3,run_4,run_5,run_6,total_nos_all_runs)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	event_date AS ob_starting_date,
	NULL AS ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	op.survey_area_m2 AS ef_wetted_area, 
	survey_length_m ef_fished_length,
	survey_width_m ef_fished_width,
	NULL AS ef_duration,
	op.no_of_runs AS ef_nbpas, 
	op.* 	
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		(select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.site_id=st.site_id 
		where catch_method_name='CATCH DEPLETION SAMPLE'
		and survey_method_name in ('AC ELECTRIC FISHING','DC ELECTRIC FISHING','ELECTRIC FISHING','PDC ELECTRIC FISHING')) as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Whole'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Miran Apprahamian'; --9997 lines

-- Batch integration, the first level will reference operation again, the second will reference the fish table
-- TODO THERE AND ADD SOME DATA 

DROP TABLE if exists anglian.batch_ope CASCADE;
CREATE TABLE anglian.batch_ope (
                -- column added to the standard below
		site_id integer,
		survey_id integer, 
		nb numeric,		
		pa_numero integer,
	CONSTRAINT pk_batch_ba_id PRIMARY KEY (ba_id),
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
	CONSTRAINT c_fk_batch_ope_op_st_id FOREIGN KEY (site_id)
		REFERENCES anglian.station (site_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
		) INHERITS (dbeel.batch);
/*
select distinct on (species_id)species_id,species_name from  anglian.quantitative_cs_number_estimates
"Glass eel" 243
"Yellow eel" 242
"G, Y & S eel mixed" 241
*/ 
-- nb_total G, Y & S eel mixed
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.total_nos_all_runs as nb, cast(NULL as integer) as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =241) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--4113 out of 9997 lines
-- nb_total Yellow eel	
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.total_nos_all_runs as nb, cast(NULL as integer) as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =242) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--5862 out of 9997 lines
-- nb_total elvers !! AN ELVER IS NOT A GLASS EEL BUT THIS IS THE BEST I CAN DO !

INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.total_nos_all_runs as nb, cast(NULL as integer) as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =243) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--225 out of 9997 lines

-- op_p1 Batch level=2 yellow eel
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_1 as nb, 1 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =242) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--5862 lines
-- op_p1 Batch level=2 not precised
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_1 as nb, 1 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =241) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--4113 lines
-- op_p1 Batch level=2 glass
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_1 as nb, 1 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =243) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--225 lines	


	-- op_p2 level=2 yellow eel
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_2 as nb, 2 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =242 and e.run_2 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--5862/9997 lines
	--all stages
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_2 as nb, 2 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =241 and e.run_2 is not null) as joineel	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--4113 lines
	-- glass eel (elver)
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_2 as nb, 2 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =243 and e.run_2 is not null) as joineel	
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel'  
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--225 lines
	
-- op_p3
--5043 lines
	-- op_p2 level=2 yellow eel
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_3 as nb, 3 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =242 and e.run_3 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--2280 lines
	--all stages
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_3 as nb, 3 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =241 and e.run_3 is not null) as joineel	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--2742 lines
	-- glass eel (elver)
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_3 as nb, 3 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =243 and e.run_3 is not null) as joineel	
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel'  
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--156 lines
-- op_p4
--184 lines
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_4 as nb, 4 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =242 and e.run_4 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p4' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--96 lines
	--all stages
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_4 as nb, 4 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =241 and e.run_4 is not null) as joineel	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Number p4' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';
	-- glass eel (elver)
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_4 as nb, 4 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =243 and e.run_4 is not null) as joineel	
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel'  
	AND biological_characteristic_type.no_name='Number p4' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--156 lines


	-- op_p5
	--41 line
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_5 as nb, 5 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =242 and e.run_5 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p5' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--96 lines
	--all stages
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_5 as nb, 5 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =241 and e.run_5 is not null) as joineel	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Number p5' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';
	-- glass eel (elver)
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_5 as nb, 5 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =243 and e.run_5 is not null) as joineel	
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel'  
	AND biological_characteristic_type.no_name='Number p5' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';

	-- op_p6
	--29 line
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_6 as nb, 6 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =242 and e.run_6 is not null) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p6' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--21 lines
	--all stages
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_6 as nb, 6 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =241 and e.run_6 is not null) as joineel	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Number p6' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--8
	-- glass eel (elver)
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,e.run_6 as nb, 6 as pa_numero from anglian.electrofishing e
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id where species_id =243 and e.run_6 is not null) as joineel	
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel'  
	AND biological_characteristic_type.no_name='Number p6' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--0 lines
-- density yellow eel
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,cs_pop_est as nb, cast(Null as integer) as pa_numero from anglian.electrofishing e  
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id
	where species_id =242) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';-- 5862 lines
-- density glass eel
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,cs_pop_est as nb, cast(Null as integer) as pa_numero from anglian.electrofishing e  
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id
	where species_id =243) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';-- 225 lines	
-- density all stages
INSERT INTO anglian.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,e.site_id,e.survey_id,cs_pop_est as nb, cast(Null as integer) as pa_numero from anglian.electrofishing e  
	join anglian.quantitative_cs_number_estimates cs on e.survey_id=cs.survey_id
	where species_id =241) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';-- 4113 lines

-- Batch integration, the second level will reference the fish table


DROP TABLE if exists anglian.batch_fish CASCADE;
CREATE TABLE anglian.batch_fish (
	LIKE anglian.length_weight_qs INCLUDING DEFAULTS INCLUDING CONSTRAINTS, -- que ce soit l'une ou l'autre des tables (CS ou singlerun) elles ont la même structure
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
		CONSTRAINT c_fk_fi_op_id FOREIGN KEY (survey_id)
		REFERENCES anglian.operation (survey_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT c_fk_fi_st_id FOREIGN KEY (site_id)
		REFERENCES anglian.stationdbeel(site_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
		) INHERITS (dbeel.batch);

/*
-- inner request like this		
select * from (
select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing e
	join anglian.length_weight_qs fi on fi.survey_id=e.survey_id 
	union
select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing e
	join anglian.length_weight_singlerun fi on fi.survey_id=e.survey_id ) as sub
where species_id=241
	
-- je remet comme western batch level =4 même si ici ça pourrait être 3, il s'agit des lots individuels
operation batch level =1 pour density et nbtotal
Puis batch level =2 pour chaque passage...	
	*/
--241
INSERT INTO anglian.batch_fish
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
	(select * from (
	select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing e
	join anglian.length_weight_qs fi on fi.survey_id=e.survey_id 
	union
	select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing e
	join anglian.length_weight_singlerun fi on fi.survey_id=e.survey_id ) as sub
	where species_id=241) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='G, Y & S eel mixed' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--43247 lines

	--242
INSERT INTO anglian.batch_fish
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
	(select * from (
	select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing e
	join anglian.length_weight_qs fi on fi.survey_id=e.survey_id 
	union
	select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing e
	join anglian.length_weight_singlerun fi on fi.survey_id=e.survey_id ) as sub
	where species_id=242) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--41118 lines

	--243
INSERT INTO anglian.batch_fish
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
	(select * from (
	select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing e
	join anglian.length_weight_qs fi on fi.survey_id=e.survey_id 
	union
	select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing e
	join anglian.length_weight_singlerun fi on fi.survey_id=e.survey_id ) as sub
	where species_id=243) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--953 lines

DROP TABLE if exists anglian.mensurationindiv_biol_charac CASCADE;
CREATE TABLE anglian.mensurationindiv_biol_charac  (
	CONSTRAINT pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_value_type 	FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES anglian.batch_fish (ba_id) ON DELETE RESTRICT ON UPDATE CASCADE
)INHERITS (dbeel.biological_characteristic);

/*

select op_id,op_nbtotal,ob_starting_date,op_equipment,op_main_survey_target,fi_length,fi_lifestage,fi_year,fi_folio_no from anglian.electrofishing join anglian.fish_fi fi on fi_op_id=op_id 
select * from anglian.electrofishing join anglian.fish_fi fi on fi_op_id=op_id ;

select op_nbtotal, count from anglian.operation e join 
(select op_id, count(*) from anglian.operation 
	join anglian.fish_fi fi on fi_op_id=op_id 
	where op_equipment='Handset'
	group by op_id) as aa on aa.op_id=e.op_id

select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.electrofishing ee
	join anglian.fish_fi fi on fi.fi_op_id=ee.op_id 
	where op_equipment='Handset'
*/
-- attention toutes les lignes de batch_fish sont int modifier pour le prochain
INSERT INTO anglian.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 weight_g  AS bc_numvalue
	FROM anglian.batch_fish, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		weight_g >0 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --29081 lines
-- length in mm
INSERT INTO anglian.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 batch_fish.length_mm AS bc_numvalue
	FROM anglian.batch_fish, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		length_mm>0 
		AND biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; --85317 lines

/*
Pas de sex pour la base de donnée
INSERT INTO anglian.mensurationindiv_biol_charac
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
	FROM anglian.batch_fish,
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_sex IS NOT NULL 
		AND biological_characteristic_type.no_name = 'Sex' 
		AND value_type.no_name = 'Raw data or Individual data'; -- 0 lines
*/
-- TODO here
-- MODIFIER LE SCRIPT POUR INTEGRER LES DONNEES DE PECHE AUX ENGINS

---------------------------
-- III gear fishing (example taken from wrbd to be adapted)
----------------------------------

DROP TABLE if exists anglian.gear_exp_fishery CASCADE;
CREATE TABLE anglian.gear_exp_fishery (
	LIKE anglian.operation INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
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
INSERT INTO anglian.gear_exp_fishery(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
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
	data_provider.dp_id AS ob_dp_id, -- anglian
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
		(select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.op_st_id=st.st_id where op_equipment='fyke net') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND gear_type.no_name='Fyke Nets' 
	AND effort_type.no_name='Duration days'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --695 lines 

INSERT INTO anglian.gear_exp_fishery(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
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
	data_provider.dp_id AS ob_dp_id, -- anglian
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
		(select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.op_st_id=st.st_id where op_equipment='longline standard bait') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND gear_type.isscfg_code='09.0.0' --Handlines and Pole-Lines (Hand Operated) two lines no idea why...
	AND effort_type.no_name='Duration days'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --1 line 


-- Batch integration, the first level will reference operation again, the second will reference the fish table
--anglian.batch_ope has already been created
--  here I'm changing according to data filled in the table sometimes op_p1 sometimes op_nbtotal, sometimes the two are different
/*
select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,
CASE WHEN op_p1 is not null then op_p1
WHEN op_nbtotal is null then 0
ELSE op_nbtotal 
end as op_nb,
 cast(NULL as integer) as pa_numero from anglian.gear_exp_fishery  where op_equipment='fyke net';


*/
-- nb_total
INSERT INTO anglian.batch_ope
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
		from anglian.gear_exp_fishery  
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
-- anglian.batch_fish already exists;

-- inner request like this	
/*	
select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.gear_exp_fishery 
	join anglian.fish_fi fi on fi_op_id=op_id 
	where op_equipment='fyke net';
*/
INSERT INTO anglian.batch_fish
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
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.gear_exp_fishery 
	join anglian.fish_fi fi on fi_op_id=op_id 
	where op_equipment='fyke net') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--10984 lines


/*
select ba_id AS bc_ba_id,fi_weight from anglian.gear_exp_fishery
	join anglian.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net'
	*/
-- attention toutes les lignes de batch_fish sont intꨲ꦳ modifier pour le prochain
INSERT INTO anglian.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_weight AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_weight from anglian.gear_exp_fishery
	join anglian.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net') as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		fi_weight>0 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --9278 lines

INSERT INTO anglian.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_length*10 AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,fi_length from anglian.gear_exp_fishery
	join anglian.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net') as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_length>0 
		AND biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; --10968 lines
INSERT INTO anglian.mensurationindiv_biol_charac
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
	FROM (select ba_id AS bc_ba_id,fi_sex from anglian.gear_exp_fishery
	join anglian.batch_fish  on ob_id=ba_ob_id 
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

DROP TABLE if exists anglian.migration_monitoring CASCADE;
CREATE TABLE anglian.migration_monitoring (
	LIKE anglian.operation INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
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
select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.op_st_id=st.st_id where op_equipment='glass eel fishing'
*/

INSERT INTO anglian.migration_monitoring(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
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
	data_provider.dp_id AS ob_dp_id, -- anglian
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
		(select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.op_st_id=st.st_id where op_equipment='glass eel fishing') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND control_type.no_name='Trapping'  --monitoring type
	AND migration_direction.no_name='Upstream migration'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --18 lines 

/*
select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.op_st_id=st.st_id where op_equipment='juvenile trap' -- this is elver
*/

INSERT INTO anglian.migration_monitoring(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
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
	data_provider.dp_id AS ob_dp_id, -- anglian
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
		(select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.op_st_id=st.st_id where op_equipment='juvenile trap') as op
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Gear fishing'
	AND observation_type.no_name='Scientific Observation'
	AND control_type.no_name='Trapping'  --monitoring type
	AND migration_direction.no_name='Upstream migration'
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Russell Poole & Elvira de Eito'; --2 lines 

/*
select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.op_st_id=st.st_id where op_equipment='fixed trap - silver trap' -- this is elver
*/
-- glass eel and elver integration
-- nb_total
INSERT INTO anglian.batch_ope
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
		from anglian.migration_monitoring  
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
-- anglian.batch_fish already exists;	


INSERT INTO anglian.batch_fish
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
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.migration_monitoring   
	join anglian.fish_fi fi on fi_op_id=op_id 
	where op_equipment='juvenile trap'
	or op_equipment='glass eel fishing') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Glass eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='extracted from the aqu. env.' 
	AND value_type.no_name='Raw data or Individual data';--690 lines


/*
select ba_id AS bc_ba_id,fi_weight from anglian.gear_exp_fishery
	join anglian.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net'
	*/
-- attention toutes les lignes de batch_fish sont intꨲ꦳ modifier pour le prochain
INSERT INTO anglian.mensurationindiv_biol_charac
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
		from anglian.migration_monitoring
		join anglian.batch_fish  on ob_id=ba_ob_id 
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

INSERT INTO anglian.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_length AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,
		fi_length*10 as fi_length -- mm  
		from anglian.migration_monitoring
		join anglian.batch_fish  on ob_id=ba_ob_id 
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





INSERT INTO anglian.migration_monitoring(ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
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
	data_provider.dp_id AS ob_dp_id, -- anglian
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
		(select st.op_id as op_ob_id, op.* from anglian.operation op join anglian.stationdbeel st on op.op_st_id=st.st_id where op_equipment='fixed trap - silver trap') as op
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
INSERT INTO anglian.batch_ope
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
		from anglian.migration_monitoring  
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
-- anglian.batch_fish already exists;	


INSERT INTO anglian.batch_fish
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
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from anglian.migration_monitoring   
	join anglian.fish_fi fi on fi_op_id=op_id 
	where op_equipment='fixed trap - silver trap') as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Silver eel'
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--14606 lines


/* 
select ba_id AS bc_ba_id,fi_weight from anglian.gear_exp_fishery
	join anglian.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fyke net'
	*/
-- attention toutes les lignes de batch_fish sont intꨲ꦳ modifier pour le prochain
INSERT INTO anglian.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_weight AS bc_numvalue
	FROM (
		select ba_id AS bc_ba_id,
		fi_weight   
		from anglian.migration_monitoring
		join anglian.batch_fish  on ob_id=ba_ob_id 
		where op_equipment='fixed trap - silver trap'
		and fi_weight>0 -- to avoid -99
		) as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		
		biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --7335

INSERT INTO anglian.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_length AS bc_numvalue
	FROM (select ba_id AS bc_ba_id,
		fi_length*10 as fi_length -- mm  
		from anglian.migration_monitoring
		join anglian.batch_fish  on ob_id=ba_ob_id 
		where op_equipment='fixed trap - silver trap'
		and fi_length>0 -- to avoid -99
		) as joineel, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; -- 14578 lines


INSERT INTO anglian.mensurationindiv_biol_charac
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
	FROM (select ba_id AS bc_ba_id,fi_sex from anglian.migration_monitoring
	join anglian.batch_fish  on ob_id=ba_ob_id 
	where op_equipment='fixed trap - silver trap') as joineel,
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_sex IS NOT NULL 
		AND biological_characteristic_type.no_name = 'Sex' 
		AND value_type.no_name = 'Raw data or Individual data'; --13506


-- I have forgotten to put in mm for yellow eels... now corrected in script
/*
update anglian.mensurationindiv_biol_charac set bc_numvalue=bc_numvalue*10 where bc_id in(
select bc_id from anglian.mensurationindiv_biol_charac 
join dbeel_nomenclature.biological_characteristic_type on bc_no_characteristic_type=biological_characteristic_type.no_id 
join anglian.batch_fish on bc_ba_id=ba_id
where no_name='Length'
and fi_lifestage='yellow') -- 10489
*/