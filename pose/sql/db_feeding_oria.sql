
--ORIA
INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('AZTI');
INSERT INTO dbeel.data_provider(dp_name, dp_et_id) VALUES ('Esti Diaz',3);


DROP TABLE if exists oria.stationdbeel CASCADE;
CREATE TABLE oria.stationdbeel (
	LIKE oria.estaciones_st,
	CONSTRAINT pk_so_op_id PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);

INSERT INTO oria.stationdbeel
	SELECT  uuid_generate_v4() AS op_id,
	'oria' AS op_gis_systemname ,
	'AZTI' AS op_gis_layername, 
	st.st_id AS op_gislocation,
	CASE WHEN st.st_name is not null then st.st_name
	else st.st_ecoregion|| st.st_river end AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	st.* FROM oria.estaciones_st st ; -- 486 lines

----------------------------------------------------
-- oria.electrofishing
---------------------------------------------------

select substring(op_id,1,6)||'_'||substring(op_id,8,11) from oria.operation_op where char_length(op_id)=11;

update  oria.operation_op set op_id=substring(op_id,1,6)||'_'||substring(op_id,8,11) where char_length(op_id)=11;

DROP TABLE if exists oria.electrofishing CASCADE;
CREATE TABLE oria.electrofishing (
	LIKE oria.operation_op INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
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
		ON UPDATE CASCADE ON DELETE RESTRICT,
	constraint c_fk_op_st_id FOREIGN KEY (op_st_id) REFERENCES oria.estaciones_st(st_id)
		MATCH SIMPLE 	ON UPDATE CASCADE ON DELETE RESTRICT 
) INHERITS (dbeel.electrofishing);

select * from oria.operation_op;

INSERT INTO oria.electrofishing (ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		ef_no_fishingmethod,ef_no_electrofishing_mean,ef_wetted_area,ef_fished_length,ef_fished_width,ef_duration,ef_nbpas,ob_op_id,
		  op_date ,
		op_river ,
		op_st_id ,
		op_id ,
		op_surf,
		op_methodest ,
		op_fishingobj ,
		op_nbpas ,
		op_effort ,
		op_density ,
		op_nbtot ,
		op_nbp1 ,
		op_nbp2 ,
		op_nbp3 ,
		op_nb150 ,
		op_nb150_300 ,
		op_nb300_450 ,
		op_nb_450_600,
		op_nb_600 ,
		op_glass_eel_transport )
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_date AS ob_starting_date,
	NULL AS ob_ending_date,
	data_provider.dp_id AS ob_dp_id, -- oria
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	op.op_surf AS ef_wetted_area, 
	NULL AS ef_fished_length,
	NULL AS ef_fished_width,
	NULL AS ef_duration,
	op.op_nbpas AS ef_nbpas, 
	op.* 	
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		(select st.op_id as op_ob_id, op.* from oria.operation_op op join oria.stationdbeel st on op.op_st_id=st.st_id) as op
		
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Whole'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Esti Diaz'; --1341 lines

-- Batch integration, the first level will reference operation again, the second will reference the fish table


DROP TABLE if exists oria.batch_ope CASCADE;
CREATE TABLE oria.batch_ope (
		op_st_id character varying(10),
		op_id character varying(20), -- here I'm not setting like operation but only choosing some columns
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
	CONSTRAINT c_fk_batch_ope_op_st_id FOREIGN KEY (op_st_id)
		REFERENCES oria.estaciones_st (st_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
		) INHERITS (dbeel.batch);
/*
select ob_id as ba_ob_id,op_nb_total,op_p1,op_p2,op_p3,op_p4,op_p5 from oria.electrofishing  where op_equipment='Handset';
select * from oria.electrofishing  where op_yellow !=op_nbtotal; -- two lines do not know why
*/
-- nb_total
INSERT INTO oria.batch_ope
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
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_nbtot as op_nb, cast(NULL as integer) as pa_numero from oria.electrofishing ) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--1341 lines

-- op_nbp1
INSERT INTO oria.batch_ope
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
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_nbp1 as op_nb, 1 as pa_numero from oria.electrofishing) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--1341 lines

	-- op_nbp2
INSERT INTO oria.batch_ope
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
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_nbp2 as op_nb, 2 as pa_numero from oria.electrofishing) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--1341 lines

	-- op_nbp3
INSERT INTO oria.batch_ope
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
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_nbp3 as op_nb, 3 as pa_numero from oria.electrofishing ) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--1341 lines

--density
INSERT INTO oria.batch_ope
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
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_density as op_nb, cast(Null as integer) as pa_numero from oria.electrofishing) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';-- 1341 lines	

	

-- Batch integration, the second level will reference the fish table

drop table if exists oria.fish_fi CASCADE;
create table oria.fish_fi (
        fi_op_id character varying(20),
       fi_op_pas integer,
       fi_length numeric,
       fi_weight numeric       
);

set client_encoding to 'LATIN1';
COPY oria.fish_fi from 'C:/eda/oria/POSE/EDA/DATOSPARAEDA/GV/fishGV.csv' with CSV header delimiter as ';' null as 'NA';--3782
update  oria.fish_fi set fi_op_id= substring(fi_op_id,1,6)||'_'||substring(fi_op_id,8,11) where char_length(fi_op_id)=11;
--delete from oria.fish_fi where fi_id>=3783;

alter table oria.fish_fi add column fi_id serial;
alter table oria.fish_fi add constraint c_pk_fi_id PRIMARY KEY (fi_id);
alter table oria.fish_fi add CONSTRAINT fk_fi_op_id FOREIGN KEY (fi_op_id) references oria.operation_op(op_id);
-- additional data from the deputation
copy oria.fish_fi(fi_op_id,
  fi_op_pas ,
  fi_length ,
  fi_weight ) from 'C:/eda/oria/POSE/EDA/DATOSPARAEDA/DIPU/fish_fi.csv' with CSV header delimiter as ';' null as 'NA'; --18356 (9 lines with  bad numbers removed)


DROP TABLE if exists oria.batch_fish CASCADE;
CREATE TABLE oria.batch_fish (
	LIKE oria.fish_fi INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
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
		REFERENCES oria.operation_op (op_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
		) INHERITS (dbeel.batch);
/*
-- inner request like this
select * from oria.fish_fi		
select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from oria.electrofishing 
	join oria.fish_fi fi on fi_op_id=op_id 
	;
*/
INSERT INTO oria.batch_fish
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
	(select ob_id as ba_ob_id, cast(NULL AS uuid) as ba_ba_id, fi.* from oria.electrofishing 
	join oria.fish_fi fi on fi_op_id=op_id 
	) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--221138 

DROP TABLE if exists oria.mensurationindiv_biol_charac CASCADE;
CREATE TABLE oria.mensurationindiv_biol_charac  (
	CONSTRAINT pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_value_type 	FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES oria.batch_fish (ba_id) ON DELETE RESTRICT ON UPDATE CASCADE
)INHERITS (dbeel.biological_characteristic);

select * from oria.electrofishing;
select * from oria.batch_fish;
select fi_weight from oria.electrofishing 
	join oria.batch_fish  on ob_id=ba_ob_id 

INSERT INTO oria.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 fi_weight AS bc_numvalue
	FROM oria.batch_fish, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 	
		fi_weight>0 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --21882 lines

INSERT INTO oria.mensurationindiv_biol_charac
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 batch_fish.fi_length AS bc_numvalue
	FROM oria.batch_fish, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		fi_length>0 
		AND biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; --22138 lines


--THIS IS NOT FINISHED THERE ARE SOME FISHES IN ANOTHER FILE NOT FROM GV