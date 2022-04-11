-- updated TABLES 04/04 => Maria

/*
dbeel.establishment
dbeel.data_provider
*/


---------------------------------------------
-- SCRIPT INTEGRATION SIBIC => DBEEL
---------------------------------------------


-- select * from dbeel.establishment;
INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('OFB');
--select * from dbeel.data_provider
--select max(dp_id) from dbeel.data_provider; -- 25
INSERT INTO  dbeel.data_provider (dp_id, dp_name, dp_et_id) VALUES (30, 'Pascal Irz',27);
ALTER SEQUENCE dbeel.data_provider_dp_id_seq RESTART WITH 31;


-- TABLES FOR IMPORT will be created IN France AND IN loire schema (for electrofishing from f�d�rations de p�che)
-- script for creating station is in eda_dbeel/eda2.3/R/aspe_import.R


select * from dbeel.observation_places limit 10;




-- select * from france.station_aspe limit 10;

SELECT DISTINCT  count(*), sta_statut FROM france.station_aspe GROUP BY sta_statut; -- 32727 true

-- Create the stationdbeel table from dbeel
DROP TABLE if exists france.dbeel_station_aspe CASCADE;
CREATE TABLE france.dbeel_station_aspe (
	sta_id integer,
	sta_code_sandre TEXT,
  country character varying(2),		
	CONSTRAINT pk_so_op_id PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);

--select * from france.dbeel_station_aspe limit 10;

DELETE FROM france.dbeel_batch_ope_aspe; --75666
DELETE FROM france.dbeel_electrofishing_aspe; --33300
DELETE FROM france.dbeel_station_aspe; -- 2 min 32720


-- SELECT * FROM france.station_aspe
-- Insert data into the dbeel table
INSERT INTO france.dbeel_station_aspe 
	SELECT  uuid_generate_v4() AS op_id, -- UNIQUE identifier
	'3035' AS op_gis_systemname ,
	'ASPE' AS op_gis_layername, 
	NULL AS op_gislocation, 
	sta_libelle_sandre AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geometry  as the_geom, -- already 3035
   sta_id,
   sta_code_sandre,
  'FR' AS country 
	FROM france.station_aspe;  --32720 17s => 31734 après filtre contour france

------------------------------
--retour des identifiants dans la TABLE mère
--------------------------------
	
	
	ALTER TABLE france.station_aspe ADD COLUMN sta_dbeel_op_id UUID;
	UPDATE france.station_aspe SET sta_dbeel_op_id = op_id FROM
 france.dbeel_station_aspe WHERE dbeel_station_aspe.sta_id=station_aspe.sta_id; --31734

	

/*--------------------------------------------------
-- ASPE.electrofishing
	https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/R/aspe_import.R#L69
-------------------------------------------------*/
	
-- SELECT * FROM france.operation_aspe oa ;


--SELECT * from dbeel.electrofishing limit 10;


DROP TABLE if exists france.dbeel_electrofishing_aspe CASCADE;

CREATE TABLE france.dbeel_electrofishing_aspe(
  odp_nombre_anodes NUMERIC,
  odp_nombre_epuisettes NUMERIC,
  odp_maille_epuisette NUMERIC,
  odp_tension NUMERIC,
  odp_intensite NUMERIC,
  odp_puissance NUMERIC,
  odp_nombre_points_anguilles INTEGER,
  nb_point INTEGER,
  odp_duree_peche NUMERIC,
  op_typ TEXT,
  mom_libelle TEXT,
  ope_id INTEGER,
  pop_id INTEGER,
  sta_id INTEGER,
  sta_code_sandre TEXT,  
  pop_code_sandre TEXT, -- ATTENTION CONVERTIT EN NUMERIQUE DANS LE RDATA
  pop_code_wama TEXT, 
  ope_code_wama TEXT, -- ATTENTION CONVERTIT EN NUMERIQUE DANS LE RDATA
  ope_id_wama INTEGER,
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

-----------------------------
-- I electrofishing 
----------------------------

/*
For the moment we set the type of electrofishing to unknown (61), later for some fishing we with use whole (62)
*/
select * from france.dbeel_station_aspe limit 10;
select * from france.operation_aspe limit 10; --43695
SELECT * FROM  france.dbeel_station_aspe sta
   JOIN france.operation_aspe ope ON sta.sta_id=ope.sta_id

-- The import is done in two times as some operations do not have sta_id, it must be loaded from point_prelevement_aspe

DELETE FROM france.dbeel_electrofishing_aspe;
/*
electrofishing mean
70    Electrofishing mean Unknown 
71    Electrofishing mean By foot 
72    Electrofishing mean By boat 
73    Electrofishing mean Mix 
scientific observation method
no_id no_code no_type no_name sc_observation_category sc_definition
68    Scientific observation type Unknown Gear fishing  
69    Scientific observation type Unknown Migration monitoring  
60  NA  Scientific observation type Unknown Unknown Unknown scientific observation of unknown category
61  UN  Scientific observation type Unknown Electro-fishing Electrofishing, method unknown
62  WH  Scientific observation type Whole Electro-fishing Electrofishing, full two pass by foot
63  P1  Scientific observation type Partial1bank  Electro-fishing Electrofishing, partial on one bank
64  P2  Scientific observation type Partial2banks Electro-fishing Electrofishing, partial on two banks
65  PR  Scientific observation type Partialrandom Electro-fishing Electrofishing, partial random
66  PR  Scientific observation type Partialprop Electro-fishing Electrofishing, partial proportional
67  OT  Scientific observation type Other Electro-fishing Electrofishing, other method
301 DH  Scientific_observation_type Deep habitat  Electro-fishing Normalized method for deep habitat (Belliard et al.,2018)
302 WE  Scientific_observation_type Whole eel Electro-fishing Electrofishing, whole eel specific
303 PE  Scientific_observation_type Point sampling eel  Electro-fishing Electrofishing, eel specific point sampling (Germis, 2009)
*/

INSERT INTO france.dbeel_electrofishing_aspe (
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
	odp_tension,
	odp_intensite,
	odp_puissance,
	odp_nombre_anodes ,
  odp_nombre_epuisettes,
  odp_maille_epuisette,
  odp_nombre_points_anguilles,
  nb_point,
  odp_duree_peche,
  op_typ,
  mom_libelle,
  ope_id,
  pop_id,
  sta_id,
  sta_code_sandre,
  pop_code_wama,
  ope_code_wama,
  ope_id_wama
	)
SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	ope.ope_date::date AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	CASE WHEN (op_typ ILIKE '%compl%' OR op_typ ILIKE '%partielle sur berge%') AND objectif ILIKE '%anguilles%' THEN 302
	     WHEN op_typ ILIKE '%compl%' THEN 62
	     WHEN op_typ ILIKE '%partielle par points%' THEN 301
	     WHEN op_typ ILIKE '%ambiance%' THEN 301 -- ambiance IS a sort OF deep habitat electrofishing WITH point FOR LARGE streams
	     WHEN op_typ ILIKE '%partielle sur berge%' THEN 63
       WHEN op_typ ILIKE '%anguille%' THEN 303	
       ELSE 61 -- si y a des des 61 se m�fier
	END AS ef_no_fishingmethod,
	CASE WHEN mop_libelle ILIKE '%pied%'  THEN 71
	     WHEN mop_libelle ILIKE '%bateau%' THEN 72
	     WHEN mop_libelle ILIKE '%mixte%' THEN 73
	     ELSE 70 -- unknown
	END AS ef_no_electrofishing_mean,	
	ope.ope_surface_calculee AS ef_wetted_area, 
	odp_longueur AS ef_fished_length,
	odp_largeur_lame_eau AS ef_fished_width,
	odp_duree_peche AS ef_duration,
	CASE WHEN nb_pas IS NULL THEN 1 ELSE nb_pas END AS ef_nbpas,	     
	sta.op_id as ob_op_id,
	ope.odp_tension,
  ope.odp_intensite,
  ope.odp_puissance,
  ope.odp_nombre_anodes ,
  ope.odp_nombre_epuisettes,
  ope.odp_maille_epuisette,
  ope.odp_nombre_points_anguilles,
  ope.nb_point,
  ope.odp_duree_peche,
  ope.op_typ,
  ope.mom_libelle,
  ope.ope_id,
  ope.pop_id,
  ope.sta_id,
  ope.sta_code_sandre,
  ope.pop_code_wama,
  ope.ope_code_wama,
  ope.ope_id_wama
	FROM 	
        france.dbeel_station_aspe sta
   JOIN france.operation_aspe ope ON sta.sta_id=ope.sta_id,  -- JOIN donc les operations sans sta_id sont gardées
   -- nomenclatures 	 

	
	 dbeel_nomenclature.observation_origin,
	dbeel_nomenclature.observation_type,
	 dbeel_nomenclature.period_type,
	 dbeel.data_provider  			
	WHERE observation_origin.no_name='Raw data' 
	AND observation_type.no_name='Electro-fishing' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Pascal Irz'
	; --31919 ROWS 28s
	

ALTER TABLE france.operation_aspe ADD COLUMN ope_dbeel_ob_id UUID;
UPDATE france.operation_aspe SET ope_dbeel_ob_id = NULL; --43695
UPDATE france.operation_aspe SET ope_dbeel_ob_id = ob_id FROM
 france.dbeel_electrofishing_aspe WHERE dbeel_electrofishing_aspe.ope_id=operation_aspe.ope_id; --31919
 
 
 SELECT  * FROM france.dbeel_electrofishing_aspe WHERE dbeel_electrofishing_aspe.ope_id=operation_aspe.ope_id
	
-- INSERT DES OPERATIONS MANQUANTES A PARTIR DES POINTS DE PRELEVEMENT
-- IL N'en reste que 24 après jointure.... on oublie....
/*	
	
SELECT * FROM   france.dbeel_station_aspe sta WHERE sta_id IS NULL; --0
SELECT *  FROM france.point_prelevement_aspe
SELECT count(*)  FROM france.point_prelevement_aspe;--115323
SELECT count(*) FROM  france.operation_aspe ope WHERE ope.sta_id IS NULL; --10394


SELECT * FROM  france.operation_aspe ope WHERE ope.sta_id IS NULL; 

SELECT *  FROM france.point_prelevement_aspe pop
JOIN  france.operation_aspe ope ON ope.pop_id=pop.pop_id
WHERE ope.sta_id IS NULL; --10394 => 24

SELECT * FROM france.point_prelevement_aspe WHERE pop_id=100971
*/

-- Some verifs
	
/*	
SELECT * FROM france.dbeel_electrofishing_aspe LIMIT 10;

-- no duplicate for operations
WITH count_ope AS (
SELECT ROW_NUMBER()  OVER (PARTITION BY ope_id) nb FROM france.dbeel_electrofishing_aspe
)
SELECT * FROM count_ope WHERE nb > 1
;--0 lines

SELECT op_typ, count(*) FROM france.dbeel_electrofishing_aspe GROUP BY op_typ;
/*
op_typ  count
Peche partielle par points (grand milieu) 8759
Peche par ambiances 2232
Peche partielle sur berge 3033
Peche complete à un ou plusieurs passages 18189
Indice Abondance Anguille 1088
*/
SELECT mom_libelle, count(*) FROM france.dbeel_electrofishing_aspe GROUP BY mom_libelle;
SELECT op_typ, count(*) FROM france.dbeel_electrofishing_aspe GROUP BY op_typ
/*
 FEG 1700 381
FEG 8000  2613
EL64 II 11
  163
5.0 GPP 2
FEG 13000 78
EL64 IIGI 7
FEG 3000  30
Inconnu 22895
FEG 1500  83
FEG 5000  138
HERON 5638
FEG 7000  547
IG600T  16
Pulsium 5
MARTIN PECHEUR  302
FEG 3000S 263
AIGRETTE  129
 */

select count(*) from france.dbeel_electrofishing_aspe where ob_starting_date is null; --0


SELECT ef_no_fishingmethod, no_name, count(*) FROM france.dbeel_electrofishing_aspe
JOIN dbeel_nomenclature.scientific_observation_method sc ON sc.no_id=ef_no_fishingmethod
GROUP BY ef_no_fishingmethod, no_name;
/*
|ef_no_fishingmethod|no_name           |count|
|-------------------|------------------|-----|
|302                |Whole eel         |23   |
|63                 |Partial1bank      |3033 |
|303                |Point sampling eel|1088 |
|301                |Deep habitat      |10991|
|62                 |Whole             |18166|
*/
select * from france.dbeel_electrofishing_aspe  where ope_id=85705
*/
	


--------------------------------------------	
-- NUMBER PER PASS... AND TOTAL NUMBER
-- BATCH INTEGRATION
-- WE DON'T NEED DENSITY, WILL BE RECALCULATED LATER
--------------------------------------------

-- Drop table

-- SELECT  * FROM france.batch_aspe 

 
-- DROP TABLE france.dbeel_batch_ope_aspe;
CREATE TABLE france.dbeel_batch_ope_aspe (
  ope_id int4 NULL,
  CONSTRAINT pk_batch_ba_id PRIMARY KEY (ba_id),
  CONSTRAINT c_fk_ba_ob_id FOREIGN KEY (ba_ob_id) REFERENCES france.dbeel_electrofishing_aspe(ob_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_no_biological_characteristic_type FOREIGN KEY (ba_no_biological_characteristic_type) REFERENCES dbeel_nomenclature.biological_characteristic_type(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_no_individual_status FOREIGN KEY (ba_no_individual_status) REFERENCES dbeel_nomenclature.individual_status(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_no_species_id FOREIGN KEY (ba_no_species) REFERENCES dbeel_nomenclature.species(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_no_stage_id FOREIGN KEY (ba_no_stage) REFERENCES dbeel_nomenclature.stage(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_ba_value_type FOREIGN KEY (ba_no_value_type) REFERENCES dbeel_nomenclature.value_type(no_id) ON DELETE RESTRICT ON UPDATE CASCADE
)
INHERITS (dbeel.batch);

-- nbeel
DELETE FROM france.dbeel_batch_ope_aspe;
INSERT INTO france.dbeel_batch_ope_aspe
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  ba.nb_eel AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ba.ope_id
  FROM 
  france.dbeel_electrofishing_aspe ee JOIN
  france.batch_aspe ba ON ba.ope_id=ee.ope_id,
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
  ; -- 31919 rows

  
-- number p1
INSERT INTO france.dbeel_batch_ope_aspe
SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  ba.pas_1 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ba.ope_id
  FROM 
  france.dbeel_electrofishing_aspe ee JOIN
  france.batch_aspe ba ON ba.ope_id=ee.ope_id,
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
	; -- 31919 rows

-- number p2
	
--	SELECT * FROM france.dbeel_electrofishing_aspe
	
INSERT INTO france.dbeel_batch_ope_aspe
SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  ba.pas_2 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ba.ope_id
  FROM 
  france.dbeel_electrofishing_aspe ee JOIN
  france.batch_aspe ba ON ba.ope_id=ee.ope_id,
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
  AND ef_nbpas>1
  ; -- 8745 ROWS
  
 -- number p3
  
INSERT INTO france.dbeel_batch_ope_aspe
SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  ba.pas_3 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ba.ope_id
  FROM 
  france.dbeel_electrofishing_aspe ee JOIN
  france.batch_aspe ba ON ba.ope_id=ee.ope_id,
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
  AND ef_nbpas>2
  ; -- 154 ROWS
  
 -- number p4   
  
 INSERT INTO france.dbeel_batch_ope_aspe
SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  ba.pas_4 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ba.ope_id
  FROM 
  france.dbeel_electrofishing_aspe ee JOIN
  france.batch_aspe ba ON ba.ope_id=ee.ope_id,
  dbeel_nomenclature.species, 
  dbeel_nomenclature.stage, 
  dbeel_nomenclature.biological_characteristic_type,
  dbeel_nomenclature.value_type,
  dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
  AND stage.no_name='Yellow eel' 
  AND biological_characteristic_type.no_name='Number p4' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  AND ef_nbpas>3
  ; -- 4 ROWS
    
  
  
  
----------------------------------------------------------------------
-- Batch integration, the second level will reference the fish table
----------------------------------------------------------------------
  
DROP TABLE if exists france.dbeel_dbeel_batch_fish_aspe_aspe CASCADE;
CREATE TABLE france.dbeel_batch_fish_aspe (
  ope_id INTEGER,
  mei_id INTEGER,
  lop_id INTEGER,
  tyl_libelle TEXT, 
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
	CONSTRAINT c_fk_fi_ob_id FOREIGN KEY (ba_ob_id) 
		REFERENCES france.dbeel_electrofishing_aspe (ob_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
		) INHERITS (dbeel.batch);


SELECT * FROM france.batch_fish_aspe baf 

-- On rentre les lots correspondant au premier passage.

INSERT INTO france.dbeel_batch_fish_aspe

  WITH bap1 AS (
    SELECT * FROM france.dbeel_batch_ope_aspe boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p1'  
  ),

  bafp1 AS (SELECT * FROM france.batch_fish_aspe
          WHERE pas_numero = 1 OR pas_numero IS NULL) -- AS we entered ALL fish AS p1 even IF they ARE point sample
        
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	bap1.ba_ob_id as ba_ob_id, 
	ba_id as ba_ba_id,
	bap1.ope_id ,
  bafp1.mei_id ,
  bafp1.lop_id ,
  bafp1.tyl_libelle
	FROM 
	bafp1
	JOIN bap1 ON (bap1.ope_id=bafp1.ope_id),
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
	; -- 285 096 poissons mesurés au premier passage

-- To integrate length and weight of fish, we need the "ba_id" 
-- that corresponds to the batch (each line must be different) 


DROP TABLE if exists france.dbeel_mensurationindiv_biol_charac_aspe CASCADE;
CREATE TABLE france.dbeel_mensurationindiv_biol_charac_aspe  (
	mei_id integer,
	ope_id integer,
	CONSTRAINT pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_value_type FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES france.dbeel_batch_fish_aspe (ba_id) ON DELETE CASCADE ON UPDATE CASCADE

)INHERITS (dbeel.biological_characteristic); --0

select * from france.batch_fish_aspe limit 10;



SELECT * FROM   france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id;-- 285096


-- Insert WEIGHT (gr)
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)
	SELECT 
	uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type,	
   CASE WHEN (mei_poids =0 OR mei_poids IS NULL) AND mei_poids_estime IS NULL THEN 54 -- Unkown
       WHEN mei_poids >0 THEN 55 --'Raw data or Individual data'
       WHEN (mei_poids =0 OR mei_poids IS NULL)  AND mei_poids_estime IS NOT NULL THEN 58 -- elaborated DATA
  END AS bc_no_value_type,
	CASE WHEN (mei_poids =0 OR mei_poids IS NULL) AND mei_poids_estime IS NULL THEN NULL 
	     WHEN mei_poids >0 THEN mei_poids
	     WHEN (mei_poids =0 OR mei_poids IS NULL)  AND mei_poids_estime IS NOT NULL THEN mei_poids_estime
	ELSE NULL END AS bc_numvalue,	
  baf.mei_id,
  baf.ope_id
	FROM 
	france.dbeel_batch_fish_aspe dbaf JOIN
	france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
	dbeel_nomenclature.biological_characteristic_type 
	WHERE (COALESCE(mei_poids_estime,0)+COALESCE(mei_poids,0))>0
	AND biological_characteristic_type.no_name = 'Weight'; --142654

-- Insert LENGTH (mm)
	
-- checks
	/*
  WITH TEST AS (
SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type, 
  CASE WHEN mei_mesure_reelle='f' THEN 55 --'Raw data or Individual data'
        WHEN mei_mesure_reelle='t' THEN 58-- elaborated DATA
        ELSE 54 -- Unknown 
        END AS bc_no_value_type,
  mei_taille AS  bc_numvalue,
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type
  WHERE biological_characteristic_type.no_name = 'Length')
  
  SELECT * FROM test WHERE bc_numvalue IS NULL
  SELECT * FROM france.dbeel_batch_fish_aspe WHERE mei_id='5527401'
 */ 	
	
	
	
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)
  
SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type, 
  CASE WHEN mei_mesure_reelle='f' THEN 55 --'Raw data or Individual data'
        WHEN mei_mesure_reelle='t' THEN 58-- elaborated DATA
        ELSE 54 -- Unknown 
        END AS bc_no_value_type,
  mei_taille AS  bc_numvalue,
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type
  WHERE biological_characteristic_type.no_name = 'Length'; -- 285 096



-- SECOND PASS


INSERT INTO france.dbeel_batch_fish_aspe

  WITH bap2 AS (
    SELECT * FROM france.dbeel_batch_ope_aspe boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p2'  
  ),

  bafp2 AS (SELECT * FROM france.batch_fish_aspe
          WHERE pas_numero = 2 OR pas_numero IS NULL) -- AS we entered ALL fish AS p1 even IF they ARE point sample
        
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  1 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  2 AS ba_batch_level,
  bap2.ba_ob_id as ba_ob_id, 
  ba_id as ba_ba_id,
  bap2.ope_id ,
  bafp2.mei_id ,
  bafp2.lop_id ,
  bafp2.tyl_libelle
  FROM 
  bafp2
  JOIN bap2 ON (bap2.ope_id=bafp2.ope_id),
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
  ; -- 34 292 p2


-- Insert WEIGHT (gr)
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)
  SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type,  
   CASE WHEN (mei_poids =0 OR mei_poids IS NULL) AND mei_poids_estime IS NULL THEN 54 -- Unkown
       WHEN mei_poids >0 THEN 55 --'Raw data or Individual data'
       WHEN (mei_poids =0 OR mei_poids IS NULL)  AND mei_poids_estime IS NOT NULL THEN 58 -- elaborated DATA
  END AS bc_no_value_type,
  CASE WHEN (mei_poids =0 OR mei_poids IS NULL) AND mei_poids_estime IS NULL THEN NULL 
       WHEN mei_poids >0 THEN mei_poids
       WHEN (mei_poids =0 OR mei_poids IS NULL)  AND mei_poids_estime IS NOT NULL THEN mei_poids_estime
  ELSE NULL END AS bc_numvalue, 
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type 
  WHERE (COALESCE(mei_poids_estime,0)+COALESCE(mei_poids,0))>0
  AND baf.pas_numero=2
  AND biological_characteristic_type.no_name = 'Weight'; --19272

-- Insert LENGTH (mm)
  
  
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)
  
SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type, 
  CASE WHEN mei_mesure_reelle='f' THEN 55 --'Raw data or Individual data'
        WHEN mei_mesure_reelle='t' THEN 58-- elaborated DATA
        ELSE 54 -- Unknown 
        END AS bc_no_value_type,
  mei_taille AS  bc_numvalue,
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type
  WHERE biological_characteristic_type.no_name = 'Length'
    AND baf.pas_numero=2; -- 34 292

-- THIRD PASS


INSERT INTO france.dbeel_batch_fish_aspe

  WITH bap3 AS (
    SELECT * FROM france.dbeel_batch_ope_aspe boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p3'  
  ),

  bafp3 AS (SELECT * FROM france.batch_fish_aspe
          WHERE pas_numero = 3 OR pas_numero IS NULL) -- AS we entered ALL fish AS p1 even IF they ARE point sample
        
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  1 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  2 AS ba_batch_level,
  bap3.ba_ob_id as ba_ob_id, 
  ba_id as ba_ba_id,
  bap3.ope_id ,
  bafp3.mei_id ,
  bafp3.lop_id ,
  bafp3.tyl_libelle
  FROM 
  bafp3
  JOIN bap3 ON (bap3.ope_id=bafp3.ope_id),
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
  ; -- 143 fish measured with infinite delicacy on the third pass


-- Insert WEIGHT (gr)
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)
  SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type,  
   CASE WHEN (mei_poids =0 OR mei_poids IS NULL) AND mei_poids_estime IS NULL THEN 54 -- Unkown
       WHEN mei_poids >0 THEN 55 --'Raw data or Individual data'
       WHEN (mei_poids =0 OR mei_poids IS NULL)  AND mei_poids_estime IS NOT NULL THEN 58 -- elaborated DATA
  END AS bc_no_value_type,
  CASE WHEN (mei_poids =0 OR mei_poids IS NULL) AND mei_poids_estime IS NULL THEN NULL 
       WHEN mei_poids >0 THEN mei_poids
       WHEN (mei_poids =0 OR mei_poids IS NULL)  AND mei_poids_estime IS NOT NULL THEN mei_poids_estime
  ELSE NULL END AS bc_numvalue, 
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type 
  WHERE (COALESCE(mei_poids_estime,0)+COALESCE(mei_poids,0))>0
  AND baf.pas_numero=3
  AND biological_characteristic_type.no_name = 'Weight'; --35

-- Insert LENGTH (mm)
  
  
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)
  
SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type, 
  CASE WHEN mei_mesure_reelle='f' THEN 55 --'Raw data or Individual data'
        WHEN mei_mesure_reelle='t' THEN 58-- elaborated DATA
        ELSE 54 -- Unknown 
        END AS bc_no_value_type,
  mei_taille AS  bc_numvalue,
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type
  WHERE biological_characteristic_type.no_name = 'Length'
    AND baf.pas_numero=3; -- 143
    
    
-- FOURTH PASS


INSERT INTO france.dbeel_batch_fish_aspe

  WITH bap4 AS (
    SELECT * FROM france.dbeel_batch_ope_aspe boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p4'  
  ),

  bafp4 AS (SELECT * FROM france.batch_fish_aspe
          WHERE pas_numero = 4 OR pas_numero IS NULL) -- AS we entered ALL fish AS p1 even IF they ARE point sample
        
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  1 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  2 AS ba_batch_level,
  bap4.ba_ob_id as ba_ob_id, 
  ba_id as ba_ba_id,
  bap4.ope_id ,
  bafp4.mei_id ,
  bafp4.lop_id ,
  bafp4.tyl_libelle
  FROM 
  bafp4
  JOIN bap4 ON (bap4.ope_id=bafp4.ope_id),
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
  ; -- 4 fish measured WITH a lot OF effort IN fourth pass


-- Insert WEIGHT (gr)
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)
  SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type,  
   CASE WHEN (mei_poids =0 OR mei_poids IS NULL) AND mei_poids_estime IS NULL THEN 54 -- Unkown
       WHEN mei_poids >0 THEN 55 --'Raw data or Individual data'
       WHEN (mei_poids =0 OR mei_poids IS NULL)  AND mei_poids_estime IS NOT NULL THEN 58 -- elaborated DATA
  END AS bc_no_value_type,
  CASE WHEN (mei_poids =0 OR mei_poids IS NULL) AND mei_poids_estime IS NULL THEN NULL 
       WHEN mei_poids >0 THEN mei_poids
       WHEN (mei_poids =0 OR mei_poids IS NULL)  AND mei_poids_estime IS NOT NULL THEN mei_poids_estime
  ELSE NULL END AS bc_numvalue, 
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type 
  WHERE (COALESCE(mei_poids_estime,0)+COALESCE(mei_poids,0))>0
  AND baf.pas_numero=4
  AND biological_characteristic_type.no_name = 'Weight'; --4

-- Insert LENGTH (mm)
  
  
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)
  
SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type, 
  CASE WHEN mei_mesure_reelle='f' THEN 55 --'Raw data or Individual data'
        WHEN mei_mesure_reelle='t' THEN 58-- elaborated DATA
        ELSE 54 -- Unknown 
        END AS bc_no_value_type,
  mei_taille AS  bc_numvalue,
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type
  WHERE biological_characteristic_type.no_name = 'Length'
    AND baf.pas_numero=4; -- 4  
    
    

-- TODO 11/04/2022 Other silvering creteria, seel import_sibic_dbeel for code