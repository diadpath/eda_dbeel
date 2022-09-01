--------------------------------------------------------------------------------------------
--  Stations
--------------------------------------------------------------------------------------------
SELECT * FROM france.station_fdloire;

--ALTER TABLE france.station_fdloire RENAME COLUMN geometry TO geom;


CREATE INDEX 
  ON france.station_fdloire
  USING gist
  (geom);
  

-- to store the link for dbeel
ALTER TABLE france.station_fdloire ADD COLUMN dbeel_op_id uuid;
  


-- add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name)
SELECT DISTINCT sf.sta_source from france.station_fdloire sf ; --8

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

-- DELETE FROM france.dbeel_batch_ope_aspe; --75666
-- DELETE FROM france.dbeel_electrofishing_aspe; --33300
-- DELETE FROM france.dbeel_station_fdloire; 


-- Insert data into the dbeel table
INSERT INTO france.dbeel_station_fdloire 
	SELECT  uuid_generate_v4() AS op_id, -- UNIQUE identifier
	'3035' AS op_gis_systemname ,
	'fdloire' AS op_gis_layername, 
	NULL AS op_gislocation, 
	sta_lib AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, 
   sta_id,
   'FR' AS country 
	FROM france.station_fdloire ;  --2714

------------------------------
--Add uuid to original table
--------------------------------
	
	
	ALTER TABLE france.station_fdloire  ADD COLUMN sta_dbeel_op_id UUID;
	UPDATE france.station_fdloire SET sta_dbeel_op_id = op_id FROM
 france.dbeel_station_fdloire WHERE dbeel_station_fdloire.sta_id=station_fdloire.sta_id; --2714
 
 
 
 /*--------------------------------------------------
-- fdloire.electrofishing
-------------------------------------------------*/
	
DROP TABLE if exists france.dbeel_electrofishing_fdloire CASCADE;

CREATE TABLE france.dbeel_electrofishing_fdloire(
  nb_point INTEGER,
  op_typ TEXT,
  ope_id INTEGER,
  sta_id INTEGER,
  CONSTRAINT pk_oo_ob_id_loire PRIMARY KEY (ob_id),
	CONSTRAINT fk_oo_op_id FOREIGN KEY (ob_op_id)	
		REFERENCES france.dbeel_station_fdloire (op_id) MATCH SIMPLE
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



INSERT INTO france.dbeel_electrofishing_fdloire  (
ob_id,
ob_no_origin,
ob_no_type,
ob_no_period,
ob_starting_date,
ob_ending_date,
ob_op_id,
ob_dp_id,
ef_no_fishingmethod,
ef_no_electrofishing_mean,
--ef_wetted_area,
ef_fished_length,
ef_fished_width,
--ef_duration,
ef_nbpas,
nb_point,
op_typ,
ope_id,
sta_id)
SELECT 
	uuid_generate_v4() AS ob_id ,
	11 AS ob_no_origin,
	22 AS ob_no_type, 
	75 AS ob_no_period,
	op_dat::date AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	dsf.op_id as ob_op_id,
	CASE WHEN sta_source LIKE 'FD72' THEN 32
		 WHEN sta_source LIKE 'FD49' THEN 31
		 WHEN sta_source LIKE 'EPLoire' THEN 33
		 WHEN sta_source LIKE 'FD44' THEN 34
		 WHEN sta_source LIKE 'FD86' THEN 35
		 WHEN sta_source LIKE 'FD43' THEN 36
		 WHEN sta_source LIKE 'FD45' THEN 37
		 WHEN sta_source LIKE 'FD37' THEN 40
	END AS ob_dp_id, 
	CASE WHEN op_typ ILIKE '%artielle sur berge%' THEN 302
	     WHEN (op_typ ILIKE '%compl%' OR op_typ ILIKE 'Sauvetage' OR op_typ ILIKE '%passage%') THEN 62
	     WHEN (op_typ ILIKE '%partielle%' OR op_typ ILIKE 'Par points' OR op_typ ILIKE 'Echantillonnage ponctuel d''abondance') THEN 301
	     WHEN (op_typ ILIKE '%mbiance%' OR op_typ ILIKE 'Stratifiée%' OR op_typ ILIKE 'EPA') THEN 301 -- ambiance IS a sort OF deep habitat electrofishing WITH point FOR LARGE streams
	     WHEN op_typ ILIKE '%partielle sur berge%' THEN 63
         WHEN (op_typ ILIKE '%anguille%' OR op_typ ILIKE '%IAA%' OR op_typ ILIKE 'EPA ANG') THEN 303
         WHEN op_typ ILIKE 'peche_pied_barrage' THEN 303 
       ELSE 61 -- si y a des des 61 se m�fier
	END AS ef_no_fishingmethod,
	CASE WHEN moyenprospection ILIKE '%pied%'  THEN 71
	     WHEN moyenprospection ILIKE '%bateau%' THEN 72
	     WHEN moyenprospection ILIKE '%mixte%' THEN 73
	     ELSE 70 -- unknown
	END AS ef_no_electrofishing_mean,
	--ope.ope_surface_calculee AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	--odp_duree_peche AS ef_duration,
	CASE WHEN op_nbpas IS NULL THEN 1 ELSE op_nbpas END AS ef_nbpas,
	"n_EPA" AS nb_point,
    op_typ,
    of2.op_id,
  	op_sta_id
  FROM france.dbeel_station_fdloire dsf 
  JOIN france.operation_fdloire of2 ON dsf.sta_id = of2.op_sta_id; --2511
	

ALTER TABLE france.operation_fdloire  ADD COLUMN ope_dbeel_ob_id UUID;
UPDATE france.operation_fdloire  SET ope_dbeel_ob_id = NULL; --2511
UPDATE france.operation_fdloire  SET ope_dbeel_ob_id = ob_id FROM
france.dbeel_electrofishing_fdloire  WHERE dbeel_electrofishing_fdloire.ope_id=france.operation_fdloire.op_id ; --2511

-- DROP TABLE france.dbeel_batch_ope_fdloire;
CREATE TABLE france.dbeel_batch_ope_fdloire (
  ope_id int4 NULL,
  CONSTRAINT pk_batch_ba_id_fdloire PRIMARY KEY (ba_id),
  CONSTRAINT c_fk_ba_ob_id FOREIGN KEY (ba_ob_id) REFERENCES france.dbeel_electrofishing_fdloire(ob_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_no_biological_characteristic_type FOREIGN KEY (ba_no_biological_characteristic_type) REFERENCES dbeel_nomenclature.biological_characteristic_type(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_no_individual_status FOREIGN KEY (ba_no_individual_status) REFERENCES dbeel_nomenclature.individual_status(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_no_species_id FOREIGN KEY (ba_no_species) REFERENCES dbeel_nomenclature.species(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_no_stage_id FOREIGN KEY (ba_no_stage) REFERENCES dbeel_nomenclature.stage(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_value_type FOREIGN KEY (ba_no_value_type) REFERENCES dbeel_nomenclature.value_type(no_id) ON DELETE RESTRICT ON UPDATE CASCADE
)
INHERITS (dbeel.batch);

-- nbeel
DELETE FROM france.dbeel_batch_ope_fdloire;
INSERT INTO france.dbeel_batch_ope_fdloire
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  of2.op_nbeel AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  eef.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  of2.op_id
  FROM france.dbeel_electrofishing_fdloire eef JOIN
  france.operation_fdloire of2  ON of2.op_id  = eef.ope_id,
  dbeel_nomenclature.species, 
  dbeel_nomenclature.stage, 
  dbeel_nomenclature.biological_characteristic_type,
  dbeel_nomenclature.value_type,
  dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
  AND stage.no_name='Yellow eel' -- we actually don't know that...
  AND biological_characteristic_type.no_name='Number' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  ; -- 2523 rows

  
-- number p1
INSERT INTO france.dbeel_batch_ope_fdloire
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  of2.op_p1  AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  eef.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  of2.op_id
  FROM france.dbeel_electrofishing_fdloire eef JOIN
  france.operation_fdloire of2  ON of2.op_id  = eef.ope_id,
  dbeel_nomenclature.species, 
  dbeel_nomenclature.stage, 
  dbeel_nomenclature.biological_characteristic_type,
  dbeel_nomenclature.value_type,
  dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
  AND stage.no_name='Yellow eel' -- we actually don't know that...
  AND biological_characteristic_type.no_name='Number p1' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  ; -- 2523 rows

-- number p2
	
INSERT INTO france.dbeel_batch_ope_fdloire
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  of2.op_p2  AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  eef.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  of2.op_id
  FROM france.dbeel_electrofishing_fdloire eef JOIN
  france.operation_fdloire of2  ON of2.op_id  = eef.ope_id,
  dbeel_nomenclature.species, 
  dbeel_nomenclature.stage, 
  dbeel_nomenclature.biological_characteristic_type,
  dbeel_nomenclature.value_type,
  dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
  AND stage.no_name='Yellow eel' -- we actually don't know that...
  AND biological_characteristic_type.no_name='Number p2' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  AND ef_nbpas > 1 
  ; -- 335 rows
  
