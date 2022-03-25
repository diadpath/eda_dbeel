-- dump de bd_map sch public vers EDA2 onema:
pg_dump -h 1.100.1.6 -U postgres bd_map| psql -h 1.100.1.6 -U postgres eda2


INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('ONEMA');
INSERT INTO dbeel.data_provider(dp_name, dp_et_id) VALUES ('Laurent Beaulaton',1);


DROP TABLE if exists onema.station_onema CASCADE;
CREATE TABLE onema.station_onema (
	LIKE bdmap.station,
	CONSTRAINT pk_so_op_id PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);
-- TODO: insert trigger
-- Stations treated the same AS a riversegment... OK.

INSERT INTO onema.station_onema
	SELECT  uuid_generate_v4() AS op_id,
	'onema' AS op_gis_systemname ,
	'BDMAP' AS op_gis_layername, 
	s.st_id AS op_gislocation,
	s.st_localisation AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	s.* FROM bdmap.station s ;


DROP TABLE if exists onema.operation_onema CASCADE;
CREATE TABLE onema.operation_onema (
	LIKE bdmap.operation,
	CONSTRAINT pk_oo_ob_id PRIMARY KEY (ob_id),
	CONSTRAINT fk_oo_ob_op_id FOREIGN KEY (ob_op_id)	
		REFERENCES onema.station_onema (op_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,	
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
-- TODO: insert trigger

INSERT INTO onema.operation_onema
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_datedebut AS ob_starting_date,
	op_datedebut AS ob_ending_date,
	station.op_id AS ob_op_id, 
	data_provider.dp_id AS ob_dp_id, -- ONEMA
	61 AS ef_no_fishingmethod, -- TODO update this correctly here it is electrofishing unknown
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	case when operation.op_surfaceechantillon >0 then operation.op_surfaceechantillon
		else NULL
		end AS ef_wetted_area, 
	case when operation.op_longueur>0  then operation.op_longueur
		else NULL
		end AS ef_fished_length,
	case when operation.op_cs_largeurlameeau>0 then operation.op_cs_largeurlameeau
		else null
		end AS ef_fished_width,
	operation.op_tempspeche AS ef_duration,
	operation.op_nbrpassage AS ef_nbpas, 
	operation.* 
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		onema.station_onema AS station join bdmap.operation AS operation on station.st_id = operation.op_st_id,
		dbeel_nomenclature.electrofishing_mean
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_id=61
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='Unknown' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Laurent Beaulaton';

---------------------------------------------------------------------------------------
-- optaxon

DROP TABLE if exists onema.optaxon_onema CASCADE;
CREATE TABLE onema.optaxon_onema (
	LIKE bdmap.optaxon,
	CONSTRAINT pk_opo_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_opo_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_opo_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_opo_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_opo_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,			
	CONSTRAINT fk_opo_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_opo_ba_ob_id FOREIGN KEY (ba_ob_id)
		REFERENCES onema.operation_onema(ob_id) --setting the constraint to the uppermost level dbeel.observations(ob_id) does not work !
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_opo_ba_ba_id FOREIGN KEY (ba_ba_id)
		REFERENCES dbeel.batch(ba_id) -- here I'm setting the constraint to the uppermost level
		ON DELETE RESTRICT ON UPDATE CASCADE
		) INHERITS (dbeel.batch);
-- TODO: insert trigger

INSERT INTO onema.optaxon_onema
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	optaxon.ot_effectif AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	operation_onema.ob_id AS ba_ob_id,
	NULL AS ba_ba_id,
	optaxon.* 
	FROM dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status,
	onema.operation_onema AS operation_onema,
	bdmap.optaxon
	WHERE species.no_name='Anguilla anguilla'
	 AND stage.no_name='Yellow & silver eel mixed'
	 AND biological_characteristic_type.no_name='Number'
	 AND value_type.no_name='Raw data or Individual data'
	 AND individual_status.no_name='Alive'
	 AND operation_onema.op_id = optaxon.ot_op_id
	 AND optaxon.ot_ta_id=2; --9781 lines

UPDATE onema.optaxon_onema SET ba_quantity = 0 WHERE ba_quantity IS NULL; --0 lines

---------------------------------------------------------------------------------------

DROP TABLE if exists onema.passtaxon_onema CASCADE;
CREATE TABLE onema.passtaxon_onema (
	LIKE bdmap.passtaxon,
	CONSTRAINT pk_pao_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_pao_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_pao_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_pao_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_pao_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_pao_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_pao_ba_ob_id FOREIGN KEY (ba_ob_id)
		REFERENCES onema.operation_onema(ob_id) --setting the constraint to the uppermost level dbeel.observations(ob_id) does not work !
		ON DELETE RESTRICT ON UPDATE CASCADE,
--	CONSTRAINT fk_pao_ba_ba_id FOREIGN KEY (ba_ba_id)
--		REFERENCES dbeel.batch(ba_id) -- here I'm setting the constraint to the uppermost level
--		ON DELETE RESTRICT ON UPDATE CASCADE
		
) INHERITS (dbeel.batch);
-- TODO: insert trigger

INSERT INTO onema.passtaxon_onema
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	passtaxon.pa_effectif AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	operation_onema.ob_id AS ba_ob_id,
	NULL AS ba_ba_id,
	passtaxon.* 
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	onema.operation_onema AS operation_onema, 
	bdmap.passtaxon
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow & silver eel mixed' 
	AND biological_characteristic_type.no_name='Number' 
	AND value_type.no_name='Raw data or Individual data'
	AND individual_status.no_name='Alive' 
	AND operation_onema.op_id = passtaxon.pa_op_id;

-- UPDATE onema.passtaxon_onema SET quantity = 0 WHERE quantity ISNULL;

UPDATE onema.passtaxon_onema pao SET ba_ba_id = optaxon_onema.ba_id FROM onema.optaxon_onema opo WHERE opo.fk_observation_id = pao.fk_observation_id;
-- select * from onema.passtaxon_onema limit 100;
DELETE FROM onema.passtaxon_onema where pa_ta_id!=2; --235769 lines modified

/*--------------------------------------------------------------------------------------
		lotpeche
--------------------------------------------------------------------------------------*/
DROP TABLE if exists onema.lotpeche_onema CASCADE;
CREATE TABLE onema.lotpeche_onema (
	LIKE bdmap.lotpeche,
	CONSTRAINT pk_lopeo_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_lopeo_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_lopeo_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_lopeo_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_lopeo_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_lopeo_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_lopeo_ba_ob_id FOREIGN KEY (ba_ob_id)
		REFERENCES onema.operation_onema(ob_id) --setting the constraint to the uppermost level dbeel.observations(ob_id) does not work !
		ON DELETE RESTRICT ON UPDATE CASCADE,
--	CONSTRAINT fk_lopeo_ba_ba_id FOREIGN KEY (ba_ba_id)
--		REFERENCES dbeel.batch(ba_id) -- Il ne peut pas y avoir de contraintes de clé étrangères dans la table
--		ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (dbeel.batch);

-- TODO: insert trigger
-- this is way too long, I'm only inserting the eels
SELECT * FROM 	onema.operation_onema  join bdmap.lotpeche on operation_onema.op_id = lotpeche.lo_op_id limit 10;

INSERT INTO onema.lotpeche_onema
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	lotpeche.lo_effectif AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	3 AS ba_batch_level,
	operation_onema.ob_id AS ba_ob_id,
	NULL AS ba_ba_id,
	lotpeche.* 
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	onema.operation_onema  join bdmap.lotpeche on operation_onema.op_id = lotpeche.lo_op_id 
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow & silver eel mixed' 
	AND biological_characteristic_type.no_name='Number' 
	AND value_type.no_name='Raw data or Individual data' 
	AND individual_status.no_name='Alive' 
	AND lo_ta_id=2;

UPDATE onema.lotpeche_onema lopeo SET ba_ba_id = pao.ba_id 
	FROM onema.passtaxon_onema  pao 
	WHERE lopeo.ba_ob_id = pao.ba_ob_id 
	AND lopeo.lo_numeropassage = pao.pa_numero;


---------------------------------------------------------------------------------------
-- Biological characteristic for lotpeche
---------------------------------------------------------------------------------------

DROP TABLE if exists onema.lotpeche_biol_charac_onema CASCADE;
CREATE TABLE onema.lotpeche_biol_charac_onema (
	CONSTRAINT lotpeche_biol_charac_onema_id PRIMARY KEY (bc_id),
	CONSTRAINT fk_lopebiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_lopebiocho_bc_value_type 	FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_lopebiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES onema.lotpeche_onema (ba_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (dbeel.biological_characteristic);
-- TODO: insert trigger

-- Lt min --> lot G et lot L
INSERT INTO onema.lotpeche_biol_charac_onema
	SELECT 
		 uuid_generate_v4() AS bc_id,
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS  bc_no_value_type, 
		lo_taillemin/10 AS  bc_numvalue
	FROM 	onema.lotpeche_onema,
		dbeel_nomenclature.biological_characteristic_type, 
		dbeel_nomenclature.value_type
	WHERE 
		(lo_cd_type = 1059 OR lo_cd_type =1061)  
		AND lo_taillemin>0 
		AND biological_characteristic_type.no_name = 'Lower length'
		AND value_type.no_name = 'Class value';

-- Lt max --> lot G et lot L
INSERT INTO onema.lotpeche_biol_charac_onema
	SELECT 
		 uuid_generate_v4() AS bc_id,
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS  bc_no_value_type, 
		 lo_taillemax/10 AS bc_numvalue
	FROM 	onema.lotpeche_onema, 
		dbeel_nomenclature.biological_characteristic_type, 
		dbeel_nomenclature.value_type
	WHERE 
		(lo_cd_type = 1059 OR lo_cd_type =1061)  
		AND lo_taillemin>0 
		AND biological_characteristic_type.no_name = 'Upper length' 
		AND value_type.no_name = 'Class value';

-- P total --> lot G, lot I, lot L
INSERT INTO onema.lotpeche_biol_charac_onema
	SELECT 
		 uuid_generate_v4() AS bc_id,
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS  bc_no_value_type, 		 
		 lo_poids AS biological_characteristic_numvalue
	FROM onema.lotpeche_onema, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		(lo_cd_type = 1059 OR lo_cd_type =1060 OR lo_cd_type =1061)  
		AND lo_poids>0 
		AND lo_cd_codeestimpoids=752  -- only real weight
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Cumulated data'
;-- 3527

-- L individual --> lot N

INSERT INTO onema.lotpeche_biol_charac_onema
	SELECT 
		 uuid_generate_v4() AS bc_id,
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS  bc_no_value_type, 	
		 lo_taille/10 AS biological_characteristic_numvalue
	FROM onema.lotpeche_onema, dbeel_nomenclature.biological_characteristic_type, dbeel_nomenclature.value_type
	WHERE 
		lo_cd_type = 1062  AND lo_taille>0 AND
		biological_characteristic_type.no_name = 'Length' AND
		value_type.no_name = 'Raw data or Individual data'
; --161428

-- P individual --> lot N
INSERT INTO onema.lotpeche_biol_charac_onema
	SELECT 
		uuid_generate_v4() AS bc_id,
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS  bc_no_value_type, 	
		 lo_poids AS biological_characteristic_numvalue
	FROM onema.lotpeche_onema, dbeel_nomenclature.biological_characteristic_type, dbeel_nomenclature.value_type
	WHERE 
		lo_cd_type = 1062 
		AND lo_poids>0 
		AND lo_cd_codeestimpoids=752 -- only real weight 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --66006


-- PB 1 lot S sans lot L : id = 279346
---------------------------------------------------------------------------------------
-- mensurationindiv
------------------------------------------------------------------------------------
DROP TABLE if exists onema.mensurationindiv_onema CASCADE;
CREATE TABLE onema.mensurationindiv_onema (
	LIKE bdmap.mensurationindiv,
		CONSTRAINT pk_mensindivonema_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_mensindivonema_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivonema_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_mensindivonema_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_mensindivonema_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_mensindivonema_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) MATCH SIMPLE
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_mensindivonema_ba_ob_id FOREIGN KEY (ba_ob_id)
		REFERENCES onema.operation_onema(ob_id) --setting the constraint to the uppermost level dbeel.observations(ob_id) does not work !
		ON DELETE RESTRICT ON UPDATE CASCADE
--	CONSTRAINT fk_lopeo_ba_ba_id FOREIGN KEY (ba_ba_id)
--		REFERENCES dbeel.batch(ba_id) -- Il ne peut pas y avoir de contraintes de clé étrangères dans la table
--		ON DELETE RESTRICT ON UPDATE CASCADE
	) INHERITS (dbeel.batch);
-- TODO: insert trigger

(select * from 	onema.operation_onema 
	join onema.lotpeche_onema  on ob_id=ba_ob_id 
	join bdmap.mensurationindiv on mi_lo_id=lotpeche_onema.lo_id limit 10) as sub


INSERT INTO onema.mensurationindiv_onema
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
o	4 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id,ba_id AS ba_ba_id, mensurationindiv.* from 	onema.operation_onema 
	join onema.lotpeche_onema  on ob_id=ba_ob_id 
	join bdmap.mensurationindiv on mi_lo_id=lotpeche_onema.lo_id 
	where lo_ta_id=2) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow & silver eel mixed' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--40722 lines


---------------------------------------------------------------------------------------
-- Biological characteristic for mensurationindiv

DROP TABLE if exists onema.mensurationindiv_biol_charac_onema CASCADE;
CREATE TABLE onema.mensurationindiv_biol_charac_onema (
	CONSTRAINT pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_value_type 	FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES onema.mensurationindiv_onema (ba_id) ON DELETE RESTRICT ON UPDATE CASCADE
)INHERITS (dbeel.biological_characteristic);
-- TODO: insert trigger

INSERT INTO onema.mensurationindiv_biol_charac_onema
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 mi_poids AS bc_numvalue
	FROM onema.mensurationindiv_onema, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		mi_cd_codeestimationpoids = 752 
		AND mi_poids>0 
		AND biological_characteristic_type.no_name = 'Weight' 
		AND value_type.no_name = 'Raw data or Individual data'
; --146 lines

INSERT INTO onema.mensurationindiv_biol_charac_onema
	SELECT 
		uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 mi_taille AS bc_numvalue
	FROM onema.mensurationindiv_onema, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE 
		mi_taille>0 
		AND biological_characteristic_type.no_name = 'Length' 
		AND value_type.no_name = 'Raw data or Individual data'
; --40721
