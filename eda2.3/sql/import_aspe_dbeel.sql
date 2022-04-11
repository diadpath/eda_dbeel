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
SELECT (coalesce(mei_poids_estime,0)+COALESCE(mei_poids,0))>0 AS toto
FROM   france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id;
SELECT 1>0
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
	--WHERE (COALESCE(mei_poids_estime,0)+COALESCE(mei_poids,0))>0
	AND biological_characteristic_type.no_name = 'Weight';

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
   CASE WHEN mei_taille_reelle='f' THEN 55 --'Raw data or Individual data'
       WHEN mei_taille_reelle='t' THEN 58-- elaborated DATA
       ELSE 54 -- Unknown 
  END AS bc_no_value_type,
  mei_taille AS  bc_numvalue,
  baf.mei_id,
  baf.ope_id
  FROM 
  france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id, 
  dbeel_nomenclature.biological_characteristic_type, 
  dbeel_nomenclature.value_type  
  WHERE biological_characteristic_type.no_name = 'Length';


-- SECOND PASS

-- Insert SEX: for this table, the sex is missing!
select count(*) from france.ebro_fish where codspecies='aang' and "Sexo" = ''; -- 170 rows

INSERT INTO france.mensurationindiv_biol_charac
	SELECT 	uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	CASE when ebro_fish."Sexo" = 'not recorded' then 180
	when ebro_fish."Sexo" ='M' then 181
	when ebro_fish."Sexo" ='F' then 182
	when ebro_fish."Sexo" ='unknown' then 183 -- unidentified
	ELSE null
	END  as bc_numvalue
	FROM france.ebro_fish,
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE "Sexo" IS NOT NULL 
	AND codspecies='aang'
	AND "Sexo" !=''
	AND biological_characteristic_type.no_name = 'Sex' 
	AND value_type.no_name = 'Raw data or Individual data'; -- 0 lines

alter table france.ebro_fish add column ba_id uuid;

UPDATE france.ebro_fish b
SET ba_id = a.ba_id
FROM france.dbeel_batch_fish_aspe a
WHERE a.fish_id = b.fish_id; -- 21298 rows (total rows: 21504)
/*----------------------------------------------------
INTEGRATING MISSING DATA OF SIBIC (mostly about size)

2. North of Spain (from NSp_EFIplus.mdb):
-----------------------------------------------------------
	"place_classification" corresponds to the station:
		SELECT * FROM france.nsp_efiplus_location where locationid = -2061689289;
		SELECT count(*) FROM france.nsp_efiplus_location; -- 1848 rows
		SELECT count(distinct geom) FROM france.nsp_efiplus_location; -- 1848 rows
		SELECT count(distinct place_classification) FROM france.nsp_efiplus_location; -- 1848 rows

	We have to include missing information about:
	-- nsp_efiplus_location:	"locality_length" = length of station (as "ef_fished_length") 
					"locality_width" = width of station (as "ef_fished_width")
		SELECT * FROM france.nsp_efiplus_location where place_classification='(ES_35_0008)'; 	-- 53m length and 13.8m width but NOT "locationid"
		SELECT * FROM france.dbeel_station_aspe where place_classification='(ES_35_0008)';  	-- locationid = -1823349679
		SELECT * FROM france.dbeel_electrofishing where locationid = '1952416621'; 		-- no length no width
	But "fished_area" = Surface is included in the SIBIC db!

	-- nsp_efiplus_ope:	"Catch_id"
				"run_1" as "run1" in SIBIC
				"run_2"
				"run_3"
				"run_4"
				"total_nb" = total nb of fishes (do we need to include?)
				"total_abundance" = as "ind/ha" in SIBIC (but is it the real density? I don't know how they estimate it)
				"estimated_efficiency" (do we need to include?)
		SELECT * FROM france.nsp_efiplus_ope limit 10;
		SELECT * FROM france.nsp_efiplus_ope where place_classification='(ES_35_0440)';	-- "Species" but not codspecies
		SELECT * FROM france.dbeel_electrofishing where locationid = '1952416621'; 		-- "codspecies" but not the name of species
		SELECT * FROM france.temp_pesca_electrica where locationid = '1952416621';
		SELECT * FROM france.dbeel_batch_ope where locationid = '-2061689289';
		SELECT count(distinct "Catch_id") FROM france.nsp_efiplus_ope; 			-- 4210 rows that corresponds to "Batch ID" (dbeel) and 1837 rows for locationid
		
	-- nsp_efiplus_fish:	"lenth_id" = id of individual
				"total_length" = length
				"run" = nb pass when fish was caught (do we need to include?)
		SELECT * FROM france.nsp_efiplus_fish limit 10;
		SELECT * FROM france.nsp_efiplus_fish where place_classification='(ES_35_0008)';
		SELECT * FROM france.temp_pesca_electrica where locationid = '1952416621';
-----------------------------------------------------------------------------------------------------------------------------------------------*/	
-- We need a previous step (before insert length and width of stations) since nsp_efiplus_location has "place_classification" and 
-- dbeel_electrofishing has "locationid". Using dbeel_station, we update nsp_efiplus_location with the corresponding "locationid"
alter table france.nsp_efiplus_location add column locationid integer;

UPDATE france.nsp_efiplus_location b
SET locationid = a.locationid
FROM france.dbeel_station_aspe a
WHERE a.place_classification = b.place_classification; -- 1848 rows, 67 msec

update france.dbeel_electrofishing
set (ef_fished_length,ef_fished_width) = (locality_length,locality_width) from 
	france.nsp_efiplus_location WHERE nsp_efiplus_location.locationid = dbeel_electrofishing.locationid; -- 1836 rows (12 rows missing?)

-- Before insert length of fish, we need: 
--	"locationid"
--	"codspecies" (nsp_efiplus_ope has the name of species but not the code)
-- 	"ob_id"
-- In different queries since there aren't tables with all parameters together

alter table france.nsp_efiplus_ope add column locationid integer;
UPDATE france.nsp_efiplus_ope b
SET locationid = a.locationid
FROM france.dbeel_station_aspe a
WHERE a.place_classification = b.place_classification; -- 4210 rows

alter table france.nsp_efiplus_ope add column codspecies text;
UPDATE france.nsp_efiplus_ope set codspecies = 'aang' where "Species" = 'Anguilla anguilla'; -- 681 rows
UPDATE france.nsp_efiplus_ope set codspecies = 'oth' where "Species" != 'Anguilla anguilla'; -- 3529 rows

alter table france.nsp_efiplus_ope add column ob_id uuid;
UPDATE france.nsp_efiplus_ope b
SET ob_id = a.ob_id
FROM france.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 4208 rows (total rows: 4210)
 

-- op_p1
begin;
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from france.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from france.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

join_electro as (select ba_id, electro.* from electro join france.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 231) 

update france.dbeel_batch_ope 
set ba_quantity = run1 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 1839 rows
commit;


-- op_p2
begin;
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from france.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from france.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

-- select * from electro order by locationid --1836 rows
join_electro as (select ba_id, electro.* from electro join france.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 232) 

update france.dbeel_batch_ope 
set ba_quantity = run2 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 1839 rows
commit;

-- select count(*) from france.dbeel_batch_ope where locationid in (select distinct locationid from france.nsp_efiplus_ope); --9180
-- select * from electro where locationid = '1952416621';
-- select * from france.dbeel_batch_ope where dbeel_batch_ope.locationid = '1952416621' and ba_no_biological_characteristic_type = 232;


-- op_p3
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from france.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from france.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

join_electro as (select ba_id, electro.* from electro join france.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 233) 

update france.dbeel_batch_ope 
set ba_quantity = run3 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 1839 rows


-- op_p4
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from france.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from france.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

join_electro as (select ba_id, electro.* from electro join france.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 234) 

update france.dbeel_batch_ope 
set ba_quantity = run4 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 0 rows


-- total_number
begin;
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from france.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from france.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

join_electro as (select ba_id, electro.* from electro join france.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 47) 

update france.dbeel_batch_ope 
set ba_quantity = total_nb 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 1839 rows
commit;


-- Density
-- Before calculate the density, "fished_area" should be included in the nsp_efiplus_batch_ope table:
alter table france.nsp_efiplus_ope add column fished_area integer;
UPDATE france.nsp_efiplus_ope b
SET fished_area = a.fished_area
FROM france.nsp_efiplus_location a
WHERE a.locationid = b.locationid; -- 4210 rows

-- Calculate eel density by bassin
begin;
with anguila as (
select ob_id,
locationid,
place_classification,
round(coalesce(total_nb::numeric/fished_area,0),3) as density -- TO DO: should it be "10000*total_nb::numeric/fished_area" ha?
from france.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null and total_nb is not null and fished_area is not null),

-- select distinct locationid from france.nsp_efiplus_ope 
--	where codspecies='oth' and locationid not in (select locationid from france.nsp_efiplus_ope where codspecies='aang'); -- 1156 rows

join_anguila as (select ba_id, anguila.* from anguila join france.dbeel_batch_ope on dbeel_batch_ope.locationid = anguila.locationid
where ba_no_biological_characteristic_type = 48) 

update france.dbeel_batch_ope 
set ba_quantity = density 
	from join_anguila where dbeel_batch_ope.ba_id = join_anguila.ba_id;
-- 680 rows
commit;


-- Before insert length of fish, we need: 
--	"locationid"
--	"codspecies" (ebro_fish has the name of species but not the code)
-- 	"ob_id"
-- In different queries since there aren't tables with all parameters together

-- Rename the id of fish
alter table france.nsp_efiplus_fish rename column lenth_id to fish_id;

alter table france.nsp_efiplus_fish add column locationid integer;
UPDATE france.nsp_efiplus_fish b
SET locationid = a.locationid
FROM france.dbeel_station_aspe a
WHERE a.place_classification = b.place_classification; -- 163010 rows

alter table france.nsp_efiplus_fish add column codspecies text;
UPDATE france.nsp_efiplus_fish set codspecies = 'aang' where species = 'Anguilla anguilla'; -- 9029 rows
UPDATE france.nsp_efiplus_fish set codspecies = 'oth' where species != 'Anguilla anguilla'; -- 153981 rows

alter table france.nsp_efiplus_fish add column ob_id uuid;
UPDATE france.nsp_efiplus_fish b
SET ob_id = a.ob_id
FROM france.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 162971 rows (39 rows are missing)

-- Insert into dbeel_dbeel_batch_fish_aspe the individuals which were caught
-- select count(*) from france.nsp_efiplus_fish where codspecies='aang' and ob_id is not null -- 9028
-- select sum(total_nb) from france.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null -- 9028 rows
with count_fish as
(select count(*) as count_fish, ob_id as ob_id_fish from france.nsp_efiplus_fish where codspecies='aang' and ob_id is not null group by ob_id), -- 468 rows
count_ope as 
(select sum(total_nb) as count_ope, ob_id as ob_id_ope from france.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null
	 group by ob_id), -- 680 rows
differents as 
(select * from count_fish full outer join count_ope on count_fish.ob_id_fish = count_ope.ob_id_ope
	where (count_fish != count_ope or count_ope is null or count_fish is null))
select * from differents;--france.nsp_efiplus_fish where ob_id in (select ob_id from differents) and codspecies='aang';

-- There are three cases to correct:
-- 	1. In nsp_efiplus_ope "Fishlength" = 'No' when ob_id is null in nsp_efiplus_fish (77 ob_id not found in count_fish (= 1046 eels counted but not measured))
begin;
with anguila as
(select ob_id as ob_id_ang, locationid from france.nsp_efiplus_fish where codspecies='aang' and ob_id is not null), -- 9028 rows
ope as 
(select ob_id as ob_id_ope, locationid from france.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null), -- 464 rows
differents as 
(select * from anguila full outer join ope on anguila.ob_id_ang = ope.ob_id_ope where 
	(anguila != ope or ope is null or anguila is null))
--select * from differents; -- 78 rows
update france.nsp_efiplus_ope set "Fishlength" = 'No' 
	from differents where nsp_efiplus_ope.ob_id = differents.ob_id_ope; -- 255 rows
commit;

-- 	2. (UPDATE) In nsp_efiplus_ope add nb of fish that are measured but not counted (10 ob_id = 381 eels measured but not counted)
-- select * from france.nsp_efiplus_ope where ob_id = 'b0c62cd0-a5c5-4bd8-b6f6-641645f66a4a' and codspecies = 'aang';  -- 35 eel counted
-- select * from france.nsp_efiplus_fish where ob_id = 'b0c62cd0-a5c5-4bd8-b6f6-641645f66a4a' and codspecies = 'aang'; -- 68 eels measured
begin;
with count_fish as
(select count(*) as count_fish, ob_id as ob_id_fish 
	from france.nsp_efiplus_fish where codspecies='aang' and ob_id is not null group by ob_id), -- 468 rows
count_fish_run1 as 
(select count(*) as run1, ob_id as ob_id_fish 
	from france.nsp_efiplus_fish where run = '1' and codspecies='aang' and ob_id is not null group by ob_id),
count_fish_run2 as 
(select count(*) as run2, ob_id as ob_id_fish 
	from france.nsp_efiplus_fish where run = '2' and codspecies='aang' and ob_id is not null group by ob_id),
count_fish_run3 as 
(select count(*) as run3, ob_id as ob_id_fish 
	from france.nsp_efiplus_fish where run = '3' and codspecies='aang' and ob_id is not null group by ob_id),
count_ope as 
(select sum(total_nb) as count_ope, ob_id as ob_id_ope from france.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null
	 group by ob_id), -- 680 rows
differents as 
(select count_fish, count_ope, run1, run2, run3, ob_id_ope from count_fish full outer join count_ope on count_fish.ob_id_fish = count_ope.ob_id_ope
	left join count_fish_run1 on count_fish_run1.ob_id_fish = count_ope.ob_id_ope 
	left join count_fish_run2 on count_fish_run2.ob_id_fish = count_ope.ob_id_ope
	left join count_fish_run3 on count_fish_run3.ob_id_fish = count_ope.ob_id_ope
	where (count_fish != count_ope or count_ope is null or count_fish is null))
--select * from differents; -- 8 rows
update france.nsp_efiplus_ope set (total_nb, run_1, run_2, run_3) = (count_fish, run1, run2, run3) 
	from differents where differents.ob_id_ope = nsp_efiplus_ope.ob_id; -- 48 rows
commit;

-- 	3. (INSERT INTO) In nsp_efiplus_ope add 4 ob_id (= 56 eels) that don't exist
-- select * from france.nsp_efiplus_ope where ob_id = '7aa31e13-d193-41a6-b9ee-52f3ac7afd2e' and codspecies = 'aang';  -- 0 eel counted
-- select * from france.nsp_efiplus_fish where ob_id = '7aa31e13-d193-41a6-b9ee-52f3ac7afd2e' and codspecies = 'aang'; -- 3 eels measured
with count_fish as
(select count(*) as count_fish, ob_id as ob_id_fish, site_code, "Date", species, place_classification, locationid, codspecies
	from france.nsp_efiplus_fish where codspecies='aang' and ob_id is not null 
	group by ob_id, site_code, "Date", species, place_classification, locationid, codspecies), -- 468 rows
count_fish_run1 as 
(select count(*) as run1, ob_id as ob_id_fish, site_code, "Date", species, place_classification, locationid, codspecies 
	from france.nsp_efiplus_fish where run = '1' and codspecies='aang' and ob_id is not null 
	group by ob_id, site_code, "Date", species, place_classification, locationid, codspecies),
count_fish_run2 as 
(select count(*) as run2, ob_id as ob_id_fish, site_code, "Date", species, place_classification, locationid, codspecies 
	from france.nsp_efiplus_fish where run = '2' and codspecies='aang' and ob_id is not null 
	group by ob_id, site_code, "Date", species, place_classification, locationid, codspecies),
count_fish_run3 as 
(select count(*) as run3, ob_id as ob_id_fish 
	from france.nsp_efiplus_fish where run = '3' and codspecies='aang' and ob_id is not null group by ob_id),
count_ope as 
(select sum(total_nb) as count_ope, ob_id as ob_id_ope 
	from france.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null group by ob_id),
anguila as 
--(select * from count_fish_run1 full outer join count_ope on count_fish_run1.ob_id_fish = count_ope.ob_id_ope where count_ope is null)
(select count_fish.*, run1, run2, run3 from count_fish
	left join count_fish_run1 on count_fish_run1.ob_id_fish = count_fish.ob_id_fish 
	left join count_fish_run2 on count_fish_run2.ob_id_fish = count_fish.ob_id_fish
	left join count_fish_run3 on count_fish_run3.ob_id_fish = count_fish.ob_id_fish
	where count_fish_run1.ob_id_fish not in (select ob_id_ope from count_ope))
--select * from anguila; -- 4 rows
INSERT INTO france.nsp_efiplus_ope(
	site_code, "Date", "Species", run_1, run_2, run_3, total_nb, "Fishlength", place_classification, locationid, codspecies, ob_id)
	SELECT anguila.site_code,
	anguila."Date",
	anguila.species as "Species",
	anguila.run1 AS run_1,
	anguila.run2 AS run_2,
	anguila.run3 AS run_3,
	anguila.count_fish AS total_nb,
	'Yes' as "Fishlength",
	anguila.place_classification,
	anguila.locationid,
	anguila.codspecies,
	anguila.ob_id_fish as ob_id
	FROM anguila; -- 4 rows


-- Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe
begin;
with anguila as (
select fish_id,
locationid,
place_classification,
ob_id,
coalesce(total_length,0) as length
from france.nsp_efiplus_fish 
where codspecies='aang' and ob_id is not null)

INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id,		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	anguila.locationid,
	anguila.place_classification
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; -- 9028 rows
commit;

-- To integrate length and weight of fish, "ba_id" must be included before 
alter table france.nsp_efiplus_fish add column ba_id uuid;
begin;
UPDATE france.nsp_efiplus_fish b
SET ba_id = a.ba_id
FROM france.dbeel_dbeel_batch_fish_aspe a
WHERE (a.fish_id, a.locationid) = (b.fish_id, b.locationid); -- 9028 rows
commit;



ALTER TABLE france.mensurationindiv_biol_charac RENAME TO dbeel_mensurationindiv_biol_charac;
-- Insert LENGTH (mm)
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	total_length AS bc_numvalue,
	fish_id,
	locationid, 
	place_classification
	FROM france.nsp_efiplus_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE total_length >0
	AND codspecies='aang' 
	AND ob_id is not null
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 9028 rows
commit;

/*----------------------------------------------------
INTEGRATING MISSING DATA OF SIBIC (mostly about size)

2. Levante PECES_2011:
	There aren't the coordinates of the stations in levante_location, but there are included in the sibic database!
	We have to include missing information about:
	-- levante_location:	"LONG_TRAMO" = length of station (as "ef_fished_length") 
				"ANCH_TRAMO" = width of station (as "ef_fished_width")
				"SUP_MUESTREADA" = surface of station (as "ef_wetted_area")
	But "fished_area" = Surface is included in the SIBIC db!

	-- levante_ope:		"NINDIVIDUOS" = run1 and total number
				"SUP_MUESTREADA" = surface of station (it must be included in levante_ope)
		
	-- levante_fish:
-----------------------------------------------------------------------------------------------------------------------------------------------*/	
-- Location in levante_location: don't necessary because there is place_classification
alter table france.levante_location add column locationid integer;

UPDATE france.levante_location b
SET locationid = a.locationid
FROM france.dbeel_station_aspe a
WHERE a.place_classification = b.place_classification; -- 567 rows

-- In dbeel_station there are the stations of Levante, but NOT in dbeel_electrofishing and temp_pesca_electrica
with dbeel_electrofishing1 as
(select dbeel_station.locationid, place_classification, dbeel_electrofishing.* 
	from france.dbeel_station_aspe join france.dbeel_electrofishing on op_id = ob_op_id)

select * from dbeel_electrofishing1 de full outer join france.levante_location ll on de.place_classification = ll.place_classification -- 6334 rows

-- 	1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (locationid,"ANSPFMUES")) from france.levante_location; -- 104 rows
begin;
INSERT INTO france.dbeel_electrofishing (
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
	ob_op_id,
	locationid,
	capture_date
	)
	SELECT 
	distinct on (locationid,"ANSPFMUES")
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	"ANSPFMUES" AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	"SUP_MUESTREADA" AS ef_wetted_area, 
	"LONG_TRAMO" AS ef_fished_length,
	"ANCH_TRAMO" AS ef_fished_width,
	1 AS ef_nbpas,	     
	op.op_id as ob_op_id,
	op.locationid as locationid, -- locationid coming from france.dbeel_station_aspe
	"ANSPFMUES" as capture_date -- the date is ok
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join
		france.levante_location on levante_location.locationid=op.locationid
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Rafael Miranda Ferreiro'
	; -- 98 rows (6 station are missing because the locationid is missing)
commit;


-- 	2. INSERT into dbeel_batch_ope: total number, run1 and density
---- 		Before insert number of fish, we need: "locationid", "codspecies", "ob_id"
alter table france.levante_ope add column "SUP_MUESTREADA" integer;
UPDATE france.levante_ope b
SET "SUP_MUESTREADA" = a.ef_wetted_area
FROM france.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 720 rows

alter table france.levante_ope add column codspecies text;
UPDATE france.levante_ope set codspecies = 'aang' where "NOMBRE_TAXON" = 'Anguilla anguilla'; -- 69 rows
UPDATE france.levante_ope set codspecies = 'oth' where "NOMBRE_TAXON" != 'Anguilla anguilla'; -- 651 rows

alter table france.levante_ope add column ob_id uuid;
UPDATE france.levante_ope b
SET ob_id = a.ob_id
FROM france.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 720 rows

----- DOESN'T WORK		Verify "ob_id" from levante_ope table
select france.levante_ope.* from france.levante_ope join france.dbeel_electrofishing on ob_id = ob_id
	except (select * from france.levante_ope);

select * from france.dbeel_batch_ope where locationid = '-115938694' -- 3 rows for number, run1 and density OK!

-- 		TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
--			There is only one pass, so we have to insert total number, run1 and density
begin;
with anguila as (
select distinct on ("ANSPFMUES",ob_id) 
ob_id,
locationid,
coalesce("NINDIVIDUOS",0) as run1, -- It is also total number!
0 as run2,
0 as run3,
round(coalesce("NINDIVIDUOS"::numeric/"SUP_MUESTREADA",0),3) as density -- TO DO: should it be "10000*total_nb::numeric/fished_area" ha?
from france.levante_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on ("ANSPFMUES",ob_id) 
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from france.levante_ope 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)
-- select * from electrofishing order by locationid;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.run1+electrofishing.run2+electrofishing.run3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM 
        electrofishing,
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
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 91 rows
commit;

-- op_p1
begin;
with anguila as (
select distinct on ("ANSPFMUES",ob_id) 
ob_id,
locationid,
coalesce("NINDIVIDUOS",0) as run1, -- It is also the total number!
0 as run2,
0 as run3,
round(coalesce("NINDIVIDUOS"::numeric/"SUP_MUESTREADA",0),3) as density -- TO DO: should it be "10000*total_nb::numeric/fished_area" ha?
from france.levante_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on ("ANSPFMUES",ob_id) 
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from france.levante_ope 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM 
	electrofishing,
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
	AND ob_id is not null
	; -- 91 rows
commit;

-- op_density
begin;
with anguila as (
select distinct on ("ANSPFMUES",ob_id)
ob_id, 
locationid,
coalesce("NINDIVIDUOS",0) as run1,
0 as run2,
0 as run3,
round(coalesce("NINDIVIDUOS"::numeric/"SUP_MUESTREADA",0),3) as density -- TO DO: should it be "10000*total_nb::numeric/fished_area" ha?
from france.levante_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on ("ANSPFMUES",ob_id)
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from france.levante_ope 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM
	electrofishing, 
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
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 91 rows
commit;


-- 	3. INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- Before insert length of fish, we need: "fish_id", "locationid", "codspecies", "ob_id"

alter table france.levante_fish add column fish_id serial;

alter table france.levante_fish add column locationid integer;
UPDATE france.levante_fish b
SET locationid = a.locationid
FROM france.dbeel_station_aspe a
WHERE a.place_classification = b.place_classification; -- 13170 rows

alter table france.levante_fish add column codspecies text;
UPDATE france.levante_fish set codspecies = 'aang' where "NOMBRE_TAXON" = 'Anguilla anguilla'; -- 864 rows
UPDATE france.levante_fish set codspecies = 'oth' where "NOMBRE_TAXON" != 'Anguilla anguilla'; -- 12306 rows

alter table france.levante_fish add column ob_id uuid;
UPDATE france.levante_fish b
SET ob_id = a.ob_id
FROM france.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 13170 rows

--		Insert individuals that were measured
---- Example to see that are three eels with the same length and weight.
---- the only difference is the effort code ("COD_ESFUERZO") and the description ("DESCRIPCION")
select * from france.levante_fish where locationid = '-2064312883' and codspecies = 'aang';
select * from france.levante_ope where locationid = '-2064312883' and codspecies = 'aang';

---- For a same "locationid" some individuals can be fished but they are repeated:
select * from france.levante_fish where locationid = '618122735' and codspecies = 'aang' order by "CPEZLTOTAL"; -- 81 eels
select * from france.levante_ope where locationid = '618122735' and codspecies = 'aang'; -- 27 eels
---- There isn't a code with which we can filter the duplicates. So, we used:
---- 	Row_number function that assigns a sequencial integer to each row in a result set.
---- 	Window function (OVER (PARTITION BY ... ORDER BY ... DESC)) that performs a calculation across a set of table rows 
----		which are somehow related to the current row, retaining its separate identity.
begin;
with levante_fish_extract as (
select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from france.levante_fish order by locationid),

anguila as (
select
locationid,
place_classification,
fish_id,
ob_id,
coalesce("CPEZLTOTAL",0) as length,
coalesce("CPEZPESO",0) as weight
from levante_fish_extract
where codspecies='aang' and modulo = 0)

--select * from anguila; -- 289 rows
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id,		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	anguila.locationid,
	anguila.place_classification
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; -- 289 rows
commit;



-- 	4. INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		Before insert length of fish, we need: "ba_id" (we had some problems to obtain it, but they are solved)
alter table france.levante_fish add column ba_id uuid;

---- Joining levante_fish and dbeel_dbeel_batch_fish_aspe by "fish_id" and "locationid"
select * from france.levante_fish a full outer join france.dbeel_dbeel_batch_fish_aspe b on (a.fish_id, a.locationid) = (b.fish_id, b.locationid)
	where b.locationid in (select locationid from france.levante_ope); -- 289 rows
-- delete from france.dbeel_dbeel_batch_fish_aspe where ba_id in (select ba_id from france.levante_fish);
-- update france.levante_fish set ba_id = null;

with l as
	(select a.fish_id, b.ba_id from france.levante_fish a join france.dbeel_dbeel_batch_fish_aspe b on (a.fish_id, a.locationid) = (b.fish_id, b.locationid)
	where b.locationid in (select locationid from france.levante_ope))
-- select * from l
UPDATE france.levante_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; -- 289 rows

---- Insert LENGTH
begin;
-- with levante_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from france.levante_fish order by locationid),

with levante_fish_extract as (
select * from france.levante_fish where ba_id is not null),

anguila as (
select
fish_id,
locationid,
place_classification,
ob_id,
codspecies,
ba_id,
coalesce("CPEZLTOTAL",0) as length,
coalesce("CPEZPESO",0) as weight
from levante_fish_extract
where codspecies='aang') --  and modulo = 0
-- select * from anguila; -- 290 rows
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length AS bc_numvalue,
	fish_id,
	locationid, 
	place_classification
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length >0
	AND codspecies='aang' 
	AND ob_id is not null
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 289 rows
commit;

---- Insert WEIGHT
begin;
with levante_fish_extract as (
select * from france.levante_fish where ba_id is not null),

anguila as (
select
fish_id,
locationid,
place_classification,
ob_id,
codspecies,
ba_id,
coalesce("CPEZLTOTAL",0) as length,
coalesce("CPEZPESO",0) as weight
from levante_fish_extract
where codspecies='aang')
-- select * from anguila; -- 290 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id,
	locationid, 
	place_classification
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight >0
	AND codspecies='aang' 
	AND ob_id is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 289 rows
commit;


/*----------------------------------------------------
INTEGRATING MISSING DATA OF SIBIC

3. Doadrio.mdb (individuals fished during the second pass are missing in the Sibic database)
-- Data on size is missing
--Example of one station that doesn't exists in the dbeel database but you can find in the source table (doadrio.mdb):
select * from france.dbeel_station_aspe where place_classification='AT3978';

-- Other examples with species fished in the first pass, but not in the second:
select * from france.dbeel_station_aspe where place_classification = 'AT3995'; -- locationid = '476583617'
select * from france.temp_pesca_electrica where locationid = '476583617' -- run1 OK, but run2 26 individuals fished not counted (oth species)
select * from france.dbeel_electrofishing where locationid = '476583617'

select * from france.dbeel_station_aspe where place_classification = 'AT4233';  -- It doesn't appear but in doadrio db there are 20 eels!
select * from france.dbeel_station_aspe where place_classification = 'AT4318'; -- lcoationid = '854720744'
select * from france.temp_pesca_electrica where locationid = '854720744' 

select * from france.dbeel_station_aspe where place_classification = 'AT4258';  -- locationid = '-282329194'
select * from france.temp_pesca_electrica where locationid = '-2055656564' 

*/-----------------------------------------------------


/*----------------------------------
INTEGRATION NEW DATA 
*/------------------------------------

---------------------------------
 -- Reprojection of dbeel on the river network
 ------------------------------------

--------------------------------------------------------------------------------------------
-- with reprojection on the river
-- these are only those that are in spain, a lot of points were outside from the country
--------------------------------------------------------------------------------------------

select addgeometrycolumn('france','dbeel_station','geom_reproj',3035,'POINT',2);
-- select * from france.dbeel_station_aspe limit 10 --3120
-- select st_srid(geom) from spain.rn
update france.dbeel_station_aspe set geom_reproj = sub2.geom_reproj from (
select distinct on (op_id) op_id, geom_reproj,distance from(
select
op_id, 
ST_ClosestPoint(r.geom,s.the_geom) as geom_reproj,
ST_distance(r.geom,s.the_geom) as distance
from france.dbeel_station_aspe s join
spain.rn r on st_dwithin(r.geom,s.the_geom,300) 
order by op_id, distance
)sub )sub2
where sub2.op_id= dbeel_station.op_id;

CREATE INDEX 
  ON france.dbeel_station_aspe
  USING gist
  (geom_reproj);


--------------------------------------------------------------------------------------------
--  GIPUZKOA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Reprojection

select st_srid(geom) from france.guipuz_station; -- 25830

ALTER TABLE france.guipuz_station
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035);


select addgeometrycolumn('france','guipuz_station','geom_reproj',3035,'POINT',2);
-- select * from france.guipuz_station limit 10 --3120
update france.guipuz_station set geom_reproj = sub2.geom_reproj from (
select distinct on ("Station") "Station", geom_reproj,distance from(
select
"Station", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.guipuz_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by "Station", distance
)sub )sub2
where sub2."Station"= guipuz_station."Station"; -- 397 rows (427 total)

CREATE INDEX 
  ON france.guipuz_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.guipuz_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (GIP_) from ligne 188 script "dbeel_france_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.guipuz_station AS sp1, france.guipuz_station AS sp2
	WHERE substring(sp1.id from 4) < substring(sp2.id from 4) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 4)::integer
; -- 0 no internal duplicates

select * from france.dbeel_station_aspe limit 10;
-- add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('Diputación de Gipuzkoa'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Iker Azpiroz', et_id FROM dbeel.establishment WHERE et_establishment_name = 'Diputación de Gipuzkoa'
; --TODO: TO BE MODIFIED


-- duplicate with data already in dbeel, there is one internal duplicate in dbeel that we ignore
-- we choose the closest station to join with

--update france.guipuz_station set dbeel_op_id IS NULL;
WITH 
projection_gipuzkoa AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.guipuz_station g
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_gipuzkoa AS (
SELECT distinct on (id) * from projection_gipuzkoa
)
--SELECT * from closest_gipuzkoa
UPDATE france.guipuz_station SET dbeel_op_id = op_id
	FROM closest_gipuzkoa c
	WHERE c.id=guipuz_station.id; -- 34 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)

--SELECT Find_SRID('france', 'dbeel_station', 'the_geom'); --3035
update france.dbeel_station_aspe set op_gis_systemname ='3035'; --10839
-- SELECT * from france.dbeel_station_aspe limit 10;
-- select * from france.guipuz_station limit 10
delete from france.guipuz_station  where id in ('GIP_1','GIP_2','GIP_3'); -- 3 lines of rubbish
--393

DELETE FROM france.dbeel_station_aspe where op_gis_layername='Diputación de Gipuzkoa';
INSERT INTO france.dbeel_station_aspe(
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
	'3035' AS op_gis_systemname ,
	'Diputación de Gipuzkoa' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	'Estación' as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, 	
	NULL as locationid,
	NULL as country,
	"Station" as place_classification,
	NULL as codhb,	
	'Localización' as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(st_transform(geom,25830)) as x,
	st_y(st_transform(geom,25830)) as y,
	geom_reproj as geom_reproj
	from france.guipuz_station 
	where dbeel_op_id is null -- as those lines are not reprojected
	 ; --390 lines

-- We put back the op_id into the source table
With jointure as (
SELECT * from france.dbeel_station_aspe JOIN
france.guipuz_station ON op_gislocation=id)
update france.guipuz_station set dbeel_op_id=op_id from jointure where jointure.id = guipuz_station.id; --390

-----------------------------------
-- INSERTING GIPUZKOA OPERATIONS
-----------------------------------

-- select * from france.guipuz_ope limit 10 -- 1575 rows
delete from france.guipuz_ope where sampling in ('PA2009024','PA2010007','PB2015024'); -- 3 lines of rubbish, 1572 rows
delete from france.guipuz_ope where station in ('0'); -- 1 lines of rubbish, 1571 rows

---- Add dbeel_ob_id in guipuz_operation table
ALTER TABLE france.guipuz_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year

-- Checking the duplicates of the stations (we know, line , that there are 34 stations as duplicates)
with g_station_operation as(
select guipuz_station.dbeel_op_id, guipuz_station.id, guipuz_ope.* from france.guipuz_station 
	join france.guipuz_ope on guipuz_station."Station" = guipuz_ope.station -- 1571 rows
)-- joining the two tables on the guipuz side
select * from g_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 89 rows (but the date it is not the same)


-- Checking the duplicates for year
with g_station_operation as(
select guipuz_station.dbeel_op_id, guipuz_station.id, guipuz_ope.* from france.guipuz_station 
	join france.guipuz_ope on guipuz_station."Station" = guipuz_ope.station -- 1571 rows
)-- joining the two tables on the guipuz side
select * from g_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (date, dbeel_op_id) -- 0 rows: NO DUPLICATES IN OPE

-- for those lines where there is a join, add ob_id in gipuzkoa tables
-- add also a boolean indicating if it's a duplicate.... is_SIBIC_duplicate
ALTER TABLE france.guipuz_ope ADD COLUMN is_sibic_duplicate boolean;

begin;
with sibic_duplicates as(
select guipuz_station.dbeel_op_id, guipuz_station."Station", dbeel_station.* from france.guipuz_station 
	join france.dbeel_station_aspe on guipuz_station.dbeel_op_id = dbeel_station.op_id where op_gis_layername = 'SIBIC'-- 34 rows
)
update france.guipuz_ope
set is_sibic_duplicate = TRUE from sibic_duplicates where guipuz_ope.station = sibic_duplicates."Station"; -- 261 rows

UPDATE france.guipuz_ope set is_sibic_duplicate = FALSE WHERE is_sibic_duplicate IS NULL; -- 1310 rows
-- select count(*), station from france.guipuz_ope where is_sibic_duplicate = TRUE group by station; -- 23 rows
select count(sampling), station from france.guipuz_ope where is_sibic_duplicate = TRUE group by station; -- 26 stations: 5 STATIONS ARE MISSING
commit;


---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)

---- STEP 2: integrate new data operations and then fish.... using where is_SIBIC_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (station,date)) from france.guipuz_ope; -- 1570 operations (1316)
select * from france.dbeel_station_aspe where op_gis_layername = 'Diputación de Gipuzkoa'; -- 390 stations

-- 		The id of france.guipuz_ope is 'sampling', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'guipu_ob_is' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table france.guipuz_ope add column guipuz_ob_id uuid default uuid_generate_v4 ();


begin;
INSERT INTO france.dbeel_electrofishing (
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
	guipuz_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	date AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	sampling_surface AS ef_wetted_area, 
	sampling_length AS ef_fished_length,
	sampling_width AS ef_fished_width,
	2 AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.guipuz_station on dbeel_op_id=op_id
	join
		france.guipuz_ope on guipuz_ope.station=guipuz_station."Station"
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Iker Azpiroz'
	; -- 1317 rows
commit;
SELECT * FROM france.dbeel_station_aspe LIMIT 10;
SELECT * FROM france.guipuz_station LIMIT 10;
SELECT * FROM france.guipuz_ope LIMIT 10
SELECT * from france.dbeel_dbeel_batch_fish_aspe;
SELECT * from france.dbeel_batch_ope;

-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.guipuz_ope there is no information about species, only the number of species captured ('nb_species').
--			So, it is not possible to know the number of individuals captured by species.
--			One option could be estimate the number of individuals using france.guipuz_fish: we add the individuals by operation and species.
--			The problem is that the number of individuals measured ('N' by 'sampling' and 'species') doesn't always correspond with 
--			the number of infividuals captured by operation ('nb_tot'). See these examples for two stations:

select nb_tot from france.guipuz_ope where sampling = 'PA1996004'; -- 221 individuals
select sum("N"), species from france.guipuz_fish where sampling = 'PA1996004' group by species;  -- 139 individuals

select nb_tot from france.guipuz_ope where sampling = 'PB2009005'; -- 374 individuals
select sum("N"), species from france.guipuz_fish where sampling = 'PB2009005' group by species;  -- 374 individuals (Maria did a mistake using count("N")


ALTER TABLE france.guipuz_ope ADD COLUMN run1_ang integer;
ALTER TABLE france.guipuz_ope ADD COLUMN run2_ang integer;
ALTER TABLE france.guipuz_ope ADD COLUMN run1_oth integer;
ALTER TABLE france.guipuz_ope ADD COLUMN run2_oth integer;

with run1_anguila as (
select
sampling as sampling,
sum("N") as run1_anguila
from france.guipuz_fish
where species='Anguilla anguilla' and pass = 1 group by sampling),

run2_anguila as (
select
sampling as sampling2,
sum("N") as run2_anguila
from france.guipuz_fish
where species='Anguilla anguilla' and pass = 2 group by sampling),

run1_other as (
select
sampling as sampling3,
sum("N") as run1_other
from france.guipuz_fish
where species!='Anguilla anguilla' and pass = 1 group by sampling),

run2_other as (
select
sampling as sampling4,
sum("N") as run2_other
from france.guipuz_fish
where species!='Anguilla anguilla' and pass = 2 group by sampling),

electro as (select coalesce(sampling, sampling2, sampling3, sampling4) as sampling, run1_anguila, run2_anguila, run1_other, run2_other from run1_anguila 
	FULL OUTER JOIN run2_anguila on sampling = sampling2
	FULL OUTER JOIN run1_other on sampling = sampling3
	FULL OUTER JOIN run2_other on sampling = sampling4
)
-- select * from electro; -- 1464 rows (compared to 1571 in guipuz_ope table)
update france.guipuz_ope
set (run1_ang, run2_ang, run1_oth, run2_oth) = (run1_anguila, run2_anguila, run1_other, run2_other) from electro where guipuz_ope.sampling = electro.sampling; -- 1231 rows

--			Delete rows where we didn't count fish in the operation
delete from france.guipuz_ope where run1_ang is null and run2_ang is null and run1_oth is null and run2_oth is null and nb_species > 0
; -- 340 rows: 32 rows that indicating there are no fish! DO WE CONSERV THESE OPE AS 0? (254 rows)

begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from france.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from france.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)
--select * from electrofishing_temp order by sampling;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run1+electrofishing_temp.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
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
	--AND ob_id is not null
	; -- 1317 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from france.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from france.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
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
	; -- 1317 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from france.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from france.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
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
	; -- 1317 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from france.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from france.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	electrofishing_temp, 
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
	; -- 1317 rows
commit;

---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.guipuz_fish add column fish_id serial;
alter table france.guipuz_fish add column ba_id uuid; -- We can't generate hte ba_id for the whole table because there are more than 200 000 rows!

---- 		Check duplicates: Joining levante_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.guipuz_fish a join france.guipuz_ope o on a.sampling = o.sampling
	join france.dbeel_electrofishing l on l.ob_id = o.guipuz_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows
	
-- delete from france.dbeel_dbeel_batch_fish_aspe where ba_id in (select ba_id from france.guipuz_fish);
-- update france.guipuz_fish set ba_id = null;

/*   There aren't fishes in dbeel_dbeel_batch_fish_aspe from guipuz_fish, so this query is not necessary
with l as
	(select * from france.guipuz_fish a join france.guipuz_ope o on a.sampling = o.sampling
	join france.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id)) -- 0 rows
UPDATE france.levante_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; -- 0 rows
*/

----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
select * from france.guipuz_fish where lap_mm = '2.024,00';
update france.guipuz_fish set lap_mm = '2024,00' where lap_mm = '2.024,00';

begin;	
with anguila as (
select
fish_id,
a.sampling,
guipuz_ob_id as ba_ob_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from france.guipuz_fish a 
	join france.guipuz_ope o on a.sampling = o.sampling
	where species = 'Anguilla anguilla')
--SELECT * FROM anguila; -- 31 972 rows

INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN typeang='Amarilla' THEN 226 --'Yellow eel' 
	     WHEN typeang='Plateada' THEN 227 -- 'Silver eel'
	     WHEN typeang='Indefinida' THEN 224 -- unknown
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ba_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
--	anguila.sampling 		-- DOESN'T WORK because "locationid" is an integer and "sampling" is text
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; -- 31 972 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in guipuz_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from france.dbeel_station_aspe;

with fish_from_iker as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 14) -- 31 972 rows	
--select * from fish_from_iker join france.guipuz_fish on fish_from_iker.fish_id = guipuz_fish.fish_id limit 10;

UPDATE france.guipuz_fish b
SET ba_id = fish_from_iker.ba_id
FROM fish_from_iker
WHERE fish_from_iker.fish_id = b.fish_id; -- 31 972 rows
--select * from france.guipuz_fish where ba_id is not null limit 10;


---- 		Insert LENGTH
-- with levante_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from france.levante_fish order by locationid),
begin;
with guipuz_fish_extract as (
select * from france.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 31 972 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,  -- ERROR
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 31925 rows (47 rows with length NULL)
commit; 

-- Update LENGTH
select * from france.dbeel_electrofishing join france.dbeel_dbeel_batch_fish_aspe on ob_id = ba_ob_id
join france.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id where ob_dp_id = 14 and bc_no_characteristic_type = 39 -- 31110 rows

begin;
with guipuz_fish_extract as (
select * from france.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select fish_id, ba_id, length_mm, typeang
from guipuz_fish_extract),

batch as (
select bc_id, anguila.* from france.dbeel_mensurationindiv_biol_charac m 
join anguila on (anguila.ba_id, anguila.fish_id) = (m.bc_ba_id, m.fish_id) where bc_no_characteristic_type = 39
)
--select * from batch order by fish_id -- 31110 rows
update france.dbeel_mensurationindiv_biol_charac m set bc_numvalue = length_mm from batch where m.bc_id = batch.bc_id -- 31110 rows
commit;

---- 		Insert WEIGHT
begin;
with guipuz_fish_extract as (
select * from france.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 31 972 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 31664 rows (308 rows with weight NULL)
commit;

---- 		Insert VERTICAL EYE DIAMETER
begin;
with guipuz_fish_extract as (
select * from france.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 2346 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	eye_diam_vert AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE eye_diam_vert >0
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2346 rows
commit;
--select * from dbeel_nomenclature.biological_characteristic_type where biological_characteristic_type.no_name = 'eye_diam_vert'

---- 		Insert HORIZONTAL EYE DIAMETER
begin;
with guipuz_fish_extract as (
select * from france.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 2346 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE eye_diam_horiz >0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2334 rows
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN
begin;
with guipuz_fish_extract as (
select * from france.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 2346 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length_pect AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length_pect >0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2196 rows
commit;



/*
Corrections for the view
there were a lot more lines than operation
the first was due to counts from dbeel_batch_fish_aspe integrated in the batch file, solved by setting batch level to 4 in dbeel_batch_fish_aspe as the view only takes 1 as batch_level
The second was duplicated values, every second rows was removed from 5 operations
*/


begin;
update france.dbeel_dbeel_batch_fish_aspe set ba_batch_level=4 --41743
--select count(*) from dbeel.view_electrofishing; --7311
COMMIT;

/*
  select  op_gis_layername, count(*) from dbeel.view_electrofishing group by op_gis_layername;
  select count(*) from dbeel.view_electrofishing;
  --7156

select * from dbeel.view_electrofishing limit 10
select * from dbeel.batch where ba_ob_id='0006cd83-93a7-45cc-8b46-96372def8b29'
SELECT * from  dbeel_nomenclature.nomenclature where no_id in (47,48,231,232)

select * from france.dbeel_batch_ope where ba_ob_id='0006cd83-93a7-45cc-8b46-96372def8b29'

select * from france.dbeel_dbeel_batch_fish_aspe where ba_ob_id='0006cd83-93a7-45cc-8b46-96372def8b29'

select  ob_id, count(*) from dbeel.view_electrofishing group by ob_id ;
select * from dbeel.view_electrofishing where ob_id='2d56351d-596a-4379-8d02-0d7e4b87fd29';
select * from france.dbeel_batch_ope where ba_ob_id='2d56351d-596a-4379-8d02-0d7e4b87fd29';
SELECT * from france.dbeel_electrofishing where ob_id='2d56351d-596a-4379-8d02-0d7e4b87fd29';
*/
BEGIN;
with the_culprit as (select  ob_id, count(*) from dbeel.view_electrofishing group by ob_id),

 counts as (
select 
    ba_id, 
    ROW_NUMBER() OVER(
    PARTITION BY ba_ob_id, ba_no_biological_characteristic_type
    ORDER BY ba_ob_id, ba_no_biological_characteristic_type)
    from france.dbeel_batch_ope 
where ba_ob_id in (select ob_id from the_culprit where count>1))

DELETE FROM france.dbeel_batch_ope where ba_id in (
 SELECT ba_id from counts where row_number=2
); --25

-- select  ob_id, count(*) from dbeel.view_electrofishing group by ob_id order by count desc; -- yeahhh
COMMIT;



--------------------------------------------------------------------------------------------
-- PORTUGAL: reprojection and stations
--------------------------------------------------------------------------------------------

select * from france.portugal_location limit 10; -- 745 rows
select count("Code") from france.portugal_location; -- 745 rows

---- Reprojection
SELECT Find_SRID('france', 'portugal_location', 'geom'); -- 3035

ALTER TABLE france.portugal_location
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035);

CREATE INDEX 
  ON france.portugal_location
  USING gist
  (geom);
  
-- Add geom_reproj
select addgeometrycolumn('france','portugal_location','geom_reproj',3035,'POINT',2);

update france.portugal_location set geom_reproj = sub2.geom_reproj from (
select distinct on ("Code") "Code", geom_reproj,distance from(
select
"Code", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.portugal_location s join
portugal.rn r on st_dwithin(r.geom,s.geom,300) 
order by "Code", distance
)sub )sub2
where sub2."Code"= portugal_location."Code"; -- 739 rows

CREATE INDEX 
  ON france.portugal_location
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.portugal_location ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (POR_) from ligne 163 script "dbeel_france_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.portugal_location AS sp1, france.portugal_location AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 1 no internal duplicates: POR_741 and POR_742

/* TO DO: ask to Isabel the exact location of these two stations
select * from france.portugal_location where id in ('POR_741', 'POR_742');
select * from france.portugal_ope where op_sta_id in ('MI_008', 'MI_009');
*/

/* Establishment and provider
select * from dbeel.establishment	-- FCUL/MARE et_id = 21
select * from dbeel.data_provider	-- Isabel Domingos dp_id = 19
*/


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.portugal_location set dbeel_op_id IS NULL;
WITH 
projection_portugal AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.portugal_location g
	-- join france.portugal_ope on op_sta_id = "Code"
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_portugal AS (
SELECT distinct on (id) * from projection_portugal
)
--SELECT * from closest_portugal -- 0 row
UPDATE france.portugal_location SET dbeel_op_id = op_id
	FROM closest_portugal c
	WHERE c.id = portugal_location.id; -- 0 duplicates

/* The only duplicate in the dbeel is not in the electrofishing table:
select * from france.portugal_location where id = 'POR_736'
select * from france.dbeel_station_aspe where locationid = '1947';
select* from france.dbeel_electrofishing where locationid = '1947';
*/

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='FCUL/MARE'; -- 0 rows
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'FCUL/MARE' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	'Label' as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, 	
	NULL as locationid,
	'PT' as country,
	'Code' as place_classification,
	NULL as codhb,	
	NULL as observations,
	'Basin' as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.portugal_location
	where dbeel_op_id is null -- as those lines are not reprojected
	 ; -- 745 lines
commit;

-- We put back the op_id into the source table
begin;
update france.portugal_location set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 745 rows
commit;


-----------------------------------
-- INSERTING PORTUGUESE OPERATIONS
-----------------------------------

-- select * from france.portugal_ope limit 10; -- 868 rows
-- ALTER TABLE france.portugal_ope RENAME COLUMN "ï»¿op_id" TO op_id;

---- Add dbeel_ob_id in portugal_ope table
ALTER TABLE france.portugal_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year

-- Checking the duplicates of the stations (we know, line , that there are 2 stations as duplicates)
with p_station_operation as(
select portugal_location.dbeel_op_id, portugal_location.id, portugal_ope.* from france.portugal_location 
	join france.portugal_ope on portugal_location."Code" = portugal_ope.op_sta_id -- 879 rows
)-- joining the two tables on the portugal side
select * from p_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 0 rows


-- Checking the duplicates for year
with p_station_operation as(
select portugal_location.dbeel_op_id, portugal_location.id, portugal_ope.* from france.portugal_location 
	join france.portugal_ope on portugal_location."Code" = portugal_ope.op_sta_id -- 879 rows
)-- joining the two tables on the portugal side
select * from p_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id); -- 0 rows: NO DUPLICATES IN OPE

-- for those lines where there is a join, add ob_id in portugal tables
-- add also a boolean indicating if it's a duplicate.... is_SIBIC_duplicate
ALTER TABLE france.portugal_ope ADD COLUMN is_sibic_duplicate boolean default false;

/* No duplicates in Portugal
begin;
with sibic_duplicates as(
select portugal_location.dbeel_op_id, guipuz_station."Station", dbeel_station.* from france.guipuz_station 
	join france.dbeel_station_aspe on guipuz_station.dbeel_op_id = dbeel_station.op_id where op_gis_layername = 'SIBIC'-- 34 rows
)
update france.guipuz_ope
set is_sibic_duplicate = TRUE from sibic_duplicates where guipuz_ope.station = sibic_duplicates."Station"; -- 261 rows

UPDATE france.guipuz_ope set is_sibic_duplicate = FALSE WHERE is_sibic_duplicate IS NULL; -- 1310 rows
-- select count(*), station from france.guipuz_ope where is_sibic_duplicate = TRUE group by station; -- 23 rows
select count(sampling), station from france.guipuz_ope where is_sibic_duplicate = TRUE group by station; -- 26 stations: 5 STATIONS ARE MISSING
commit;
*/

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)

---- STEP 2: integrate new data operations and then fish.... using where is_SIBIC_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from france.portugal_ope; -- 868 rows
select count(distinct (op_sta_id,op_dat)) from france.portugal_ope; -- 868 operations
select * from france.dbeel_station_aspe where op_gis_layername = 'FCUL/MARE'; -- 745 stations

alter table france.portugal_ope add column portugal_ob_id uuid default uuid_generate_v4 ();
alter table france.portugal_ope add column problem_duplicates boolean default false;

begin;
with duplicates as (
			select portugal_ob_id, count(*) from france.portugal_location 
			join
			france.portugal_ope on portugal_ope.op_sta_id=portugal_location."Code" group by portugal_ob_id order by count desc
		    ),
burnt as (select portugal_ob_id from duplicates where count > 1)
update france.portugal_ope set problem_duplicates = TRUE where portugal_ob_id in (select portugal_ob_id from burnt); -- 11 rows
commit;


begin;
INSERT INTO france.dbeel_electrofishing (
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
	portugal_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.portugal_location on dbeel_op_id=op_id
	join
		france.portugal_ope on portugal_ope.op_sta_id=portugal_location."Code"
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Isabel Domingos'
	and problem_duplicates = FALSE
	; -- 857 rows
commit;

-- SOLVED PROBLEM WITH DATA FORMAT: update date of dbeel_electrofishing using the ob_id key (from portugal_ope with portugal_ob_id key)
begin;
update france.dbeel_electrofishing as de set ob_starting_date = po.op_dat from france.portugal_ope as po where po.portugal_ob_id = de.ob_id;

select * from france.dbeel_electrofishing where ob_id in (select portugal_ob_id from france.portugal_ope); 
COMMIT;


/* TO DO Isabel: check duplicates - 11 rows - 
select distinct op_sta_id from france.portugal_ope where problem_duplicates = TRUE; 			-- A3 and A1
SELECT * FROM france.portugal_ope where portugal_ob_id = 'bbb8c153-de70-4940-8fa0-7834c992f7d5';
SELECT * FROM france.portugal_location where "Code" = 'A1' or "Code" = 'A3'; 				-- More than one operation
*/


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.portugal_ope there is only information about eels ('op_nbeel').

select * from france.portugal_ope where op_length is null or op_width is null; -- 676 rows
select * from france.portugal_ope where (op_length is null or op_width is null) and op_dens > 0; -- 150 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.portugal_ope,
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
	and problem_duplicates = FALSE
	--AND ob_id is not null
	; -- 857 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	portugal_ope.op_dens AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.portugal_ope, 
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
	and problem_duplicates = FALSE
	; -- 857 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	portugal_ope.op_nbeel AS ba_quantity, -- We think that there is only one passage
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.portugal_ope, 
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
	and problem_duplicates = FALSE
	; -- 857 rows
commit;

---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.portugal_fish add column fish_id serial;
alter table france.portugal_fish add column ba_id uuid;

select sum(op_nbeel) as quantity from france.portugal_ope; -- 4 202 rows
select count(*) from france.portugal_fish; -- 4 202 rows

---- 		Check duplicates: Joining portugal_fish and dbeel_dbeel_batch_fish_aspe by "op_sta_id" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.portugal_fish a join france.portugal_ope o on a.ang_op_id = o.op_sta_id
	join france.dbeel_electrofishing l on ob_id = o.portugal_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = ba_ob_id; -- 0 rows

/*   There aren't fishes in dbeel_dbeel_batch_fish_aspe from _fish, so this query is not necessary
with l as
	(select * from france.portugal_fish a join france.portugal_ope o on a.ang_op_id = o.op_sta_id
	join france.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id)) --  rows
UPDATE france.portugal_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; --  rows
*/


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy
select distinct on (fish_id) * from france.portugal_fish; -- 4202 rows
-- todo
begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope.portugal_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	portugal_fish.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 	 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.portugal_fish
	join france.portugal_ope
	on (ang_op_id, portugal_ope.op_dat) = (op_sta_id,dat)	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	AND stage.no_name='Yellow eel'  
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = 'FALSE'
	; -- 4089 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length
---- 		To integrate length and weight of fish, "ba_id" must be included before in portugal_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in portugal_fish table! 

with fish_from_portugal as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 19) -- Verify that ob_dp_id = 19: 4089 rows
--select * from fish_from_portugal join france.portugal_fish on fish_from_portugal.fish_id = portugal_fish.fish_id; -- 4089 rows
UPDATE france.portugal_fish b
SET ba_id = fish_from_portugal.ba_id
FROM fish_from_portugal
WHERE fish_from_portugal.fish_id = b.fish_id; -- 4089 rows
-- select ang_op_id from france.portugal_fish where ba_id is null; -- 113 rows: ang_op_id are TRUE in problem_duplicates (they haven't been inserted)


---- 		Insert LENGTH (no_id = 39)
begin;
with portugal_fish_extract as (
select * from france.portugal_fish where ba_id is not null) -- 4089 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 4089 rows
commit; 



--------------------------------------------------------------------------------------------
-- PORTUGAL BIS: reprojection and stations
--------------------------------------------------------------------------------------------

select * from france.portugal_location_bis; -- 53 rows

---- Reprojection
SELECT Find_SRID('france', 'portugal_location_bis', 'geom'); -- 3035

CREATE INDEX 
  ON france.portugal_location_bis
  USING gist
  (geom);
  
-- Add geom_reproj
select addgeometrycolumn('france','portugal_location_bis','geom_reproj',3035,'POINT',2);

update france.portugal_location_bis set geom_reproj = sub2.geom_reproj from (
select distinct on ("sta_id") "sta_id", geom_reproj,distance from(
select
"sta_id", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.portugal_location_bis s join
portugal.rn r on st_dwithin(r.geom,s.geom,300) 
order by "sta_id", distance
)sub )sub2
where sub2."sta_id"= portugal_location_bis."sta_id"; -- 53 rows

CREATE INDEX 
  ON france.portugal_location_bis
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.portugal_location_bis ADD COLUMN dbeel_op_id uuid;

-- internal duplicate here (added id (POR_) from ligne 163 script "dbeel_france_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.portugal_location_bis AS sp1, france.portugal_location_bis AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 1 no internal duplicates: POR_778 and POR_788

/* TO DO: ask to Isabel the exact location of these two stations
select * from france.portugal_location_bis where id in ('POR_778', 'POR_788');
select * from france.portugal_ope_bis where op_sta_id in ('MJ10', 'MARE10');
select * from france.portugal_ope_bis where op_sta_id = 'MJ10'; -- 0 rows: Delete this station from portugal_location_bis
delete from france.portugal_location_bis where id = 'POR_778'; -- 1 row
*/

/* Establishment and provider
select * from dbeel.establishment	-- FCUL/MARE et_id = 21
select * from dbeel.data_provider	-- Isabel Domingos dp_id = 19
*/


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.portugal_location_bis set dbeel_op_id IS NULL;
WITH 
projection_portugal AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.portugal_location_bis g
	-- join france.portugal_ope_bis on op_sta_id = "Code"
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_portugal AS (
SELECT distinct on (id) * from projection_portugal
)
--SELECT * from closest_portugal -- 50 rows
UPDATE france.portugal_location_bis SET dbeel_op_id = op_id
	FROM closest_portugal c
	WHERE c.id = portugal_location_bis.id; -- 50 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='FCUL/MARE'; -- 745 rows
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'FCUL/MARE' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	NULL as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, 	
	NULL as locationid,
	'PT' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.portugal_location_bis
	where dbeel_op_id is null -- as those lines are not reprojected
	; -- 2 lines
commit;

-- We put back the op_id into the source table
update france.portugal_location_bis set dbeel_op_id = op_id from france.dbeel_station_aspe where id = op_gislocation; -- 2 rows


----------------------------------------
-- INSERTING PORTUGUESE OPERATIONS BIS
----------------------------------------
-- select * from france.portugal_ope_bis; -- 100 rows

---- Add dbeel_ob_id in portugal_ope_bis table
ALTER TABLE france.portugal_ope_bis ADD COLUMN dbeel_ob_id uuid;

---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with p_station_operation as(
select portugal_location_bis.dbeel_op_id, portugal_location_bis.id, portugal_ope_bis.* from france.portugal_location_bis 
	join france.portugal_ope_bis on portugal_location_bis.sta_id = portugal_ope_bis.op_sta_id -- 100 rows
)-- joining the two tables on the portugal side
select * from p_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 286 rows

-- Checking the duplicates for year: real duplicates
with p_station_operation as(
select portugal_location_bis.dbeel_op_id, portugal_location_bis.id, portugal_ope_bis.* from france.portugal_location_bis 
	join france.portugal_ope_bis on portugal_location_bis.sta_id = portugal_ope_bis.op_sta_id -- 100 rows
)-- joining the two tables on the portugal side
select * from p_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id); -- 56 rows

-- for those lines where there is a join, add ob_id in portugal tables
ALTER TABLE france.portugal_ope_bis ADD COLUMN is_duplicate boolean;
-- update france.portugal_ope_bis set is_duplicate = FALSE;  -- 100 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select portugal_location_bis.dbeel_op_id, portugal_location_bis.id, portugal_location_bis.sta_id, portugal_ope_bis.* from france.portugal_location_bis 
	join france.portugal_ope_bis on portugal_location_bis.sta_id = portugal_ope_bis.op_sta_id -- 100 rows
	),-- joining the two tables on the portugal side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates; -- 56 rows
update france.portugal_ope_bis set is_duplicate = TRUE where op_id in (select op_id from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 56 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from france.portugal_ope_bis; -- 100 rows
select count(distinct (op_sta_id,op_dat)) from france.portugal_ope_bis; -- 868 operations
select * from france.dbeel_station_aspe where op_gis_layername = 'FCUL/MARE'; -- 747 stations

alter table france.portugal_ope_bis add column portugal_ob_id uuid default uuid_generate_v4 ();

begin;
with operation as (
	select * from france.portugal_ope_bis where is_duplicate = FALSE -- 44 rows
	)
INSERT INTO france.dbeel_electrofishing (
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
	portugal_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.portugal_location_bis on dbeel_op_id = op_id
	join
		operation on operation.op_sta_id = portugal_location_bis.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_id = 19 -- There is an error in data provider: Isabel Domingos is repeated!!
	; -- 44 rows
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.portugal_ope there is only information about eels ('op_nbeel').

select * from france.portugal_ope_bis where op_length is null or op_width is null; -- 0 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.portugal_ope_bis,
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
	and is_duplicate = FALSE
	; -- 44 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	round(cast(portugal_ope_bis.op_nbeel / (portugal_ope_bis.op_length * portugal_ope_bis.op_width) as numeric), 3) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.portugal_ope_bis, 
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
	and is_duplicate = FALSE
	; -- 44 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	portugal_ope_bis.op_p1 AS ba_quantity, -- There is only one passage
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.portugal_ope_bis, 
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
	and is_duplicate = FALSE
	; -- 44 rows
commit;

---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.portugal_fish_bis add column fish_id serial;
alter table france.portugal_fish_bis add column ba_id uuid;

select sum(op_nbeel) as quantity from france.portugal_ope_bis; -- 1 496 rows
select sum(op_nbeel) as quantity from france.portugal_ope_bis where is_duplicate = FALSE; -- 861 rows
select count(*) from france.portugal_fish_bis; -- 1 496 rows
select count(*) from france.portugal_fish_bis
	join france.portugal_ope_bis
	on ang_op_id = op_id			-- 1035 rows
	where is_duplicate = FALSE; 		-- 400 rows

---- 		Check duplicates: Joining portugal_fish and dbeel_dbeel_batch_fish_aspe by "op_sta_id" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.portugal_fish_bis a join france.portugal_ope_bis o on a.ang_op_id = o.op_sta_id
	join france.dbeel_electrofishing l on ob_id = o.portugal_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = ba_ob_id; -- 0 rows

/*   There aren't fishes in dbeel_dbeel_batch_fish_aspe from _fish, so this query is not necessary
with l as
	(select * from france.portugal_fish_bis a join france.portugal_ope_bis o on a.ang_op_id = o.op_sta_id
	join france.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id)) --  rows
UPDATE france.portugal_fish_bis b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; --  rows
*/


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy
begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.portugal_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	portugal_fish_bis.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 	 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.portugal_fish_bis
	join france.portugal_ope_bis
	on ang_op_id = op_id	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	AND stage.no_name='Yellow eel'  
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = 'FALSE'
	; -- 400 rows
commit;

-- SOLVED PROBLEM WITH STAGE: update stage of dbeel_dbeel_batch_fish_aspe using the ba_id key (from portugal_fish_bis with ba_id key)
begin;
update france.dbeel_dbeel_batch_fish_aspe as fi set ba_no_stage = CASE WHEN ang_silver = 'FALSE' THEN 226 -- 'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 	-- 'Silver eel'
	     when ang_silver is null then 226   -- 'Yellow eel' 
	     END
from france.portugal_fish_bis as po where po.ba_id = fi.ba_id; -- 400 rows
COMMIT;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length, weight, etc
---- 		To integrate length and weight of fish, "ba_id" must be included before in portugal_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in portugal_fish table! 
select * from france.dbeel_electrofishing where ob_dp_id = 19
with fish_from_portugal as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 19
	and ob_starting_date in (select op_dat from france.portugal_ope_bis where is_duplicate = FALSE) -- ba_id is repeated because fish_id is the same in portugal_fish table and portugal_fish_bis
	) -- 809 rows
UPDATE france.portugal_fish_bis b
SET ba_id = fish_from_portugal.ba_id
FROM fish_from_portugal
WHERE fish_from_portugal.fish_id = b.fish_id; -- 400 rows
-- select ang_op_id from france.portugal_fish_bis where ba_id is null; -- 1096 rows

---- 		Insert LENGTH (no_id = 39)
begin;
with portugal_fish_extract as (
select * from france.portugal_fish_bis where ba_id is not null) -- 400 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 400 rows
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with portugal_fish_extract as (
select * from france.portugal_fish_bis where ba_id is not null)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	round(cast(ang_pds as NUMERIC), 3) AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds::NUMERIC > 0
	and ang_pds is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 399 rows
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
with portugal_fish_extract as (
select * from france.portugal_fish_bis where ba_id is not null)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
with portugal_fish_extract as (
select * from france.portugal_fish_bis where ba_id is not null)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
with portugal_fish_extract as (
select * from france.portugal_fish_bis where ba_id is not null)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" is text
begin;
with portugal_fish_extract as (
select * from france.portugal_fish_bis where ba_id is not null)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast is null THEN 0
	     WHEN ang_neuromast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" is text
begin;
with portugal_fish_extract as (
select * from france.portugal_fish_bis where ba_id is not null)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_constrast is null THEN 0
	     WHEN ang_constrast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_constrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

----------------------------------------------------------------------------------------------
-- INSERT MISSING DATA 
---------------------------------------------------------------------------------------------
SELECT * from france.dbeel_electrofishing;
select * from france.portugal_ope_bis limit 10;
-- the op_id column is portugal_ob_id, dropping empty column

SELECT count(*) FROM france.portugal_ope_bis; --100
SELECT count(*) FROM france.portugal_ope_bis pp JOIN france.dbeel_electrofishing ee on pp.portugal_ob_id=ee.ob_id; --44


BEGIN;
WITH friend as (
SELECT * FROM france.portugal_ope_bis pp JOIN france.dbeel_electrofishing ee on pp.portugal_ob_id=ee.ob_id
) --44
UPDATE france.portugal_ope_bis set dbeel_ob_id=friend.portugal_ob_id from friend where friend.portugal_ob_id=portugal_ope_bis.portugal_ob_id; --44
COMMIT;

BEGIN;
with duplicates as (
	Select portugal_location_bis.dbeel_op_id, portugal_location_bis.id, portugal_location_bis.sta_id, portugal_ope_bis.* from france.portugal_location_bis 
	join france.portugal_ope_bis on portugal_location_bis.sta_id = portugal_ope_bis.op_sta_id -- 100 rows
	),-- joining the two tables on the portugal side

op_duplicates as (
	select  ob_id, portugal_ob_id  from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
UPDATE france.portugal_ope_bis set dbeel_ob_id=ob_id FROM op_duplicates 
where op_duplicates.portugal_ob_id=portugal_ope_bis.portugal_ob_id
AND is_duplicate;--56
COMMIT;

-- Checking already inserted batch_ope
WITH toto as (
SELECT distinct ON (ba_ob_id) * FROM france.dbeel_batch_ope JOIN france.portugal_ope_bis ON ba_ob_id=dbeel_ob_id )
select count (*) from toto; --100 OK

SELECT * from france.portugal_fish_bis where ba_id is NULL; --1496


SELECT * from  	france.portugal_ope_bis 
		JOIN  france.portugal_fish_bis on ang_op_id=portugal_ope_bis.op_id

SELECT dbeel_dbeel_batch_fish_aspe.* FROM france.dbeel_dbeel_batch_fish_aspe JOIN 
 france.portugal_ope_bis ON dbeel_ob_id= ba_ob_id --1035
-- not more datat
SELECT dbeel_dbeel_batch_fish_aspe.* FROM france.dbeel_dbeel_batch_fish_aspe JOIN 
 france.portugal_ope_bis ON dbeel_ob_id= ba_ob_id
 UNION
SELECT dbeel_dbeel_batch_fish_aspe.* FROM france.dbeel_dbeel_batch_fish_aspe JOIN 
 france.portugal_ope ON dbeel_ob_id= ba_ob_id;	--1035
		

-- which are the fish already in the database for which we have the size and for which we have new rows in dbeel_dbeel_batch_fish_aspe : we want to delete them
SELECT * FROM france.dbeel_dbeel_batch_fish_aspe JOIN 
 france.portugal_ope_bis ON dbeel_ob_id= ba_ob_id 
 where is_duplicate; --635

SELECT * FROM france.dbeel_dbeel_batch_fish_aspe 


SELECT * FROM 
france.dbeel_mensurationindiv_biol_charac 
JOIN
france.dbeel_dbeel_batch_fish_aspe on bc_ba_id=ba_id
JOIN 
 france.portugal_ope_bis ON dbeel_ob_id= ba_ob_id 
 where is_duplicate; --635
 

-- france.dbeel_mensurationindiv_biol_charac has delete cascade on ba_id,
-- so we delete one line per fish in dbeel_dbeel_batch_fish_aspe and all lines corresponding to length (there was only this) in dbeel_mensurationindiv_biol_charac

BEGIN;
DELETE FROM france.dbeel_dbeel_batch_fish_aspe WHERE ba_id in (
SELECT ba_id FROM france.dbeel_dbeel_batch_fish_aspe JOIN 
 france.portugal_ope_bis ON dbeel_ob_id= ba_ob_id 
 where is_duplicate);--635
COMMIT; 


SELECT portugal_ope_bis.* FROM france.portugal_ope_bis
EXCEPT 
SELECT portugal_ope_bis.* FROM france.dbeel_batch_ope 
JOIN 
france.portugal_ope_bis ON ba_ob_id=dbeel_ob_id 




-- Now it's time to insert the fish that were marked 'as duplicate' in portugal_ope_bis 
begin;	

INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.dbeel_ob_id as ba_ob_id, 	-- this one is not longer portugal_ob_id
	cast(NULL as uuid) as ba_ba_id,
	portugal_fish_bis.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 	 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.portugal_fish_bis
	join france.portugal_ope_bis
	on ang_op_id = op_id
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	AND stage.no_name='Yellow eel'  
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = 'TRUE'
	; -- 635 rows


with fishinserteddupl as
	(
	select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate
	),
      fish_from_portugal AS 
      (
SELECT fishinserteddupl.fish_id, dbeel_dbeel_batch_fish_aspe.ba_id from fishinserteddupl 
	join france.dbeel_dbeel_batch_fish_aspe on (fishinserteddupl.fish_id,fishinserteddupl.dbeel_ob_id) = (dbeel_dbeel_batch_fish_aspe.fish_id, dbeel_dbeel_batch_fish_aspe.ba_ob_id)
	)

UPDATE france.portugal_fish_bis b
SET ba_id = fish_from_portugal.ba_id
FROM fish_from_portugal
WHERE fish_from_portugal.fish_id = b.fish_id; -- 635 rows
COMMIT;

---- 		Insert LENGTH (no_id = 39)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate) 

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 635 rows
COMMIT;

---- 		Insert WEIGHT (no_id = 42)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	round(cast(ang_pds as NUMERIC), 3) AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds::NUMERIC > 0
	and ang_pds is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 635 rows
COMMIT;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
COMMIT;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
COMMIT;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
COMMIT;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" is text
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast is null THEN 0
	     WHEN ang_neuromast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
COMMIT;

---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" is text
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_constrast is null THEN 0
	     WHEN ang_constrast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_constrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
commit;


SELECT * FROM  france.portugal_fish_bis where ba_id is NOT NULL;--1035

select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where dbeel_ob_id is NULL;--0

select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where ba_id is NULL;--0
	
-- DE LA PUREEEEEEEEE pas de ang_op_id MJ3 001 instead of MJ30001

ALTER TABLE france.portugal_fish_bis ADD COLUMN isbigpuree boolean default FALSE;
UPDATE france.portugal_fish_bis set isbigpuree=TRUE where fish_id in (
SELECT fish_id FROM (
SELECT * FROM france.portugal_fish_bis EXCEPT
select portugal_fish_bis.* FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id)sub);-- 461
	
BEGIN;
UPDATE 	france.portugal_fish_bis set ang_op_id=
regexp_replace(ang_op_id, '001', '0001')  WHERE isbigpuree; --461
COMMIT;

begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.dbeel_ob_id as ba_ob_id, 	-- this one is not longer portugal_ob_id
	cast(NULL as uuid) as ba_ba_id,
	portugal_fish_bis.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 	 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.portugal_fish_bis
	join france.portugal_ope_bis
	on ang_op_id = op_id
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	AND stage.no_name='Yellow eel'  
	AND value_type.no_name='Raw data or Individual data'
	and isbigpuree
	; -- 461 rows
COMMIT;

BEGIN;
with fishinserteddupl as
	(
	select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree
	),
      fish_from_portugal AS 
      (
SELECT fishinserteddupl.fish_id, dbeel_dbeel_batch_fish_aspe.ba_id from fishinserteddupl 
	join france.dbeel_dbeel_batch_fish_aspe on (fishinserteddupl.fish_id,fishinserteddupl.dbeel_ob_id) = (dbeel_dbeel_batch_fish_aspe.fish_id, dbeel_dbeel_batch_fish_aspe.ba_ob_id)
	)

UPDATE france.portugal_fish_bis b
SET ba_id = fish_from_portugal.ba_id
FROM fish_from_portugal
WHERE fish_from_portugal.fish_id = b.fish_id; -- 461 rows
COMMIT;

---- 		Insert LENGTH (no_id = 39)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree) 

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 461 rows
COMMIT;

---- 		Insert WEIGHT (no_id = 42)
BEGIN;
UPDATE france.portugal_fish_bis set ang_pds = NULL WHERE ang_pds = '-';
COMMIT;

BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	round(cast(ang_pds as NUMERIC), 3) AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds::NUMERIC > 0
	and ang_pds is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 460 rows
COMMIT;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
COMMIT;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
COMMIT;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
COMMIT;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" is text
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast is null THEN 0
	     WHEN ang_neuromast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
COMMIT;

---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" is text
BEGIN;
with portugal_fish_extract as (
select * FROM france.portugal_fish_bis
	join france.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_constrast is null THEN 0
	     WHEN ang_constrast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_constrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
commit;



--------------------------------------------------------------------------------------------
-- HARMONIZED SURFACE IN M2 IN dbeel_electrofishing TABLE:
--------------------------------------------------------------------------------------------
select * from france.dbeel_electrofishing limit 10;
select round(coalesce(ef_fished_length::numeric*ef_fished_width::numeric/10000,0), 4) from france.dbeel_electrofishing; -- Surface in ha
-- select * from france.dbeel_electrofishing where ob_id = 'c111e9af-f813-4c8a-a1b5-1488e3e52ee8'; -- length but not width

begin;
with corrected as (
		  select 
		  ob_id,
		  ef_wetted_area,
		  ef_fished_length,
		  ef_fished_width,		    
		  (case when ef_fished_length is not null and ef_fished_width is not null
			then round(coalesce(ef_fished_length::numeric*ef_fished_width::numeric,0), 3)
			when ef_fished_length is null or ef_fished_width is null
			then ef_wetted_area::numeric * 10000
			when ef_fished_length is not null and ef_wetted_area > ef_fished_length
			then ef_wetted_area
			else ef_wetted_area
			END) AS surface_sm
		  from france.dbeel_electrofishing
		  )
--select * from corrected;
update france.dbeel_electrofishing set ef_wetted_area = surface_sm from corrected where corrected.ob_id = dbeel_electrofishing.ob_id; -- 8013 rows
commit;



--------------------------------------------------------------------------------------------
-- ASTURIAS: reprojection and stations
--------------------------------------------------------------------------------------------

select * from france.asturias_location; -- 36 rows
--ALTER TABLE france.asturias_location DROP COLUMN "X";
--ALTER TABLE france.asturias_location DROP COLUMN "X.1";
select count(sta_id) from france.asturias_location; -- 36 rows

---- Reprojection
SELECT Find_SRID('france', 'asturias_location', 'geom'); -- 25830

ALTER TABLE france.asturias_location
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035); -- 3035

CREATE INDEX 
  ON france.asturias_location
  USING gist
  (geom);
  
-- Add geom_reproj
select addgeometrycolumn('france','asturias_location','geom_reproj',3035,'POINT',2);

update france.asturias_location set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.asturias_location s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= asturias_location.sta_id; -- 36 rows

CREATE INDEX 
  ON france.asturias_location
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.asturias_location ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (AST_) from ligne 145 script "dbeel_france_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.asturias_location AS sp1, france.asturias_location AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment
-- select * from dbeel.data_provider

INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('DGPM Asturias'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Lucía García Florez', et_id FROM dbeel.establishment WHERE et_establishment_name = 'DGPM Asturias'
; --TODO: TO BE MODIFIED


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.asturias_location set dbeel_op_id = NULL;
WITH 
projection_asturias AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.asturias_location g
	-- join france.asturias_location on op_sta_id = sta_id
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_asturias AS (
SELECT distinct on (id) * from projection_asturias
)
--SELECT * from closest_asturias; -- 1 row: id = AST_10; place_classification: (ES_35_1771)
UPDATE france.asturias_location SET dbeel_op_id = op_id
	FROM closest_asturias c
	WHERE c.id = asturias_location.id; -- 1 duplicates

/* The only duplicate is ignored:
select * from france.asturias_location where id = 'AST_10'
select * from france.dbeel_station_aspe where place_classification = '(ES_35_1771)';
select* from france.dbeel_electrofishing where locationid = '1249093214'; -- ob_starting_date = '2007-09-01'; ob_op_id = 'e78e83e5-07aa-46ae-b690-2f1317226552'
*/

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='FCUL/MARE'; -- 0 rows
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'DGPM Asturias' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.asturias_location
	where dbeel_op_id is null
	; -- 35 lines
commit;

-- We put back the op_id into the source table
begin;
update france.asturias_location set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 36 rows
commit;


--------------------------------------
-- INSERTING OPERATIONS FROM ASTURIAS
--------------------------------------

-- select * from france.asturias_ope limit 10; -- 210 rows

---- Add dbeel_ob_id in asturias_ope table
ALTER TABLE france.asturias_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select asturias_location.dbeel_op_id, asturias_location.id, asturias_ope.* from france.asturias_location 
	join france.asturias_ope on asturias_location.sta_id = asturias_ope.op_sta_id -- 210 rows
)-- joining the two tables on the asturias side
select * from a_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 0 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select asturias_location.dbeel_op_id, asturias_location.id, asturias_ope.* from france.asturias_location 
	join france.asturias_ope on asturias_location.sta_id = asturias_ope.op_sta_id -- 210 rows
)-- joining the two tables on the asturias side
select * from a_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 0 rows

-- for those lines where there is a join, add ob_id in asturias tables
ALTER TABLE france.asturias_ope ADD COLUMN is_duplicate boolean;
-- update france.asturias_ope set is_duplicate = FALSE;  -- 210 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from france.asturias_ope; -- 210 rows
select count(distinct (op_sta_id,op_dat)) from france.asturias_ope; -- 210 operations
select * from france.dbeel_station_aspe where op_gis_layername = 'DGPM Asturias'; -- 36 stations

alter table france.asturias_ope add column asturias_ob_id uuid default uuid_generate_v4 ();
alter table france.asturias_ope add column problem_duplicates boolean default false;

/* No duplicates
with duplicates as (
			select asturias_ob_id, count(*) from france.asturias_location 
			join
			france.asturias_ope on asturias_ope.op_sta_id=asturias_location.sta_id group by asturias_ob_id order by count desc
		    ),
burnt as (select asturias_ob_id from duplicates where count > 1)
update france.asturias_ope set problem_duplicates = TRUE where asturias_ob_id in (select asturias_ob_id from burnt); -- 0 rows
*/

begin;
INSERT INTO france.dbeel_electrofishing (
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
	asturias_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.asturias_location on dbeel_op_id=op_id
	join
		france.asturias_ope on asturias_ope.op_sta_id = asturias_location.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Lucía García Florez'
	and problem_duplicates = FALSE
	; -- 210 rows
commit;

select * from france.dbeel_electrofishing where ob_id in (select asturias_ob_id from france.asturias_ope); -- 210 rows


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.asturias_ope there is only information about eels ('op_nbeel').

select * from france.asturias_ope where op_length is null or op_width is null; -- 10 rows
select * from france.asturias_ope where (op_length is null or op_width is null) and op_dens > 0; -- 0 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ope.asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.asturias_ope,
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
	and problem_duplicates = FALSE
	; -- 210 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	asturias_ope.op_dens AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ope.asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.asturias_ope, 
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
	and problem_duplicates = FALSE
	and asturias_ope.op_dens is not null
	; -- 200 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	asturias_ope.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ope.asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.asturias_ope, 
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
	and problem_duplicates = FALSE
	and op_p1 is not null
	; -- 209 rows
commit;


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.asturias_ope,
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
	and problem_duplicates = FALSE
	and op_p2 is not null -- this will be used for next time but we didn't use it during first integration
	; -- 191 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.asturias_ope,
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
	and problem_duplicates = FALSE
	and op_p3 is not null
	; -- 188 rows
commit;

-- 			op_p4 (biological_characteristic_type.no_name='Number p4') (see biological_characteristic_type.no_id=234)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p4 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.asturias_ope,
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
	and problem_duplicates = FALSE
	and op_p4 is not null
	; -- 12 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.asturias_fish add column fish_id serial;
alter table france.asturias_fish add column ba_id uuid;

/* Some rows in fish table are empty, we remove them:
select * from france.asturias_fish where ang_lng is null; -- 11 rows where everything IS NULL
DELETE FROM france.asturias_fish WHERE ang_lng is null; -- 11 rows
*/


---- 		Check duplicates: Joining asturias_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.asturias_fish a join france.asturias_ope o on a.ang_op_id = o.op_id
	join france.dbeel_electrofishing l on l.ob_id = o.asturias_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows

/* Problem wiht silvering state: in most of the lines where the silvering fields are given, the column on the silvering state is false 
select * from france.asturias_fish where ang_silver = FALSE and ang_pect is not null; -- 1120 rows
select * from france.asturias_fish where ang_silver = TRUE and ang_pect is not null; -- 431 rows
*/

----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN ang_silver='FALSE' THEN 226 	--'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 	-- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	asturias_ope.asturias_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	asturias_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.asturias_fish
	join france.asturias_ope
	on asturias_fish.ang_op_id = asturias_ope.op_id	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 12819 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from france.dbeel_station_aspe;

with fish_from_asturias as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 21) -- 12819 rows
--select * from fish_from_asturias join france.asturias_fish on fish_from_asturias.fish_id = asturias_fish.fish_id; -- 12819 rows
UPDATE france.asturias_fish b
SET ba_id = fish_from_asturias.ba_id
FROM fish_from_asturias
WHERE fish_from_asturias.fish_id = b.fish_id; -- 12819 rows
-- select * from france.asturias_fish where ba_id is null; -- 0 rows


---- 		Insert LENGTH
begin;
with asturias_fish_extract as (
select * from france.asturias_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 12819 rows (0 rows with length NULL)
commit; 


---- 		Insert WEIGHT
begin;
with asturias_fish_extract as (
select * from france.asturias_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 12819 rows (0 rows with weight NULL)
commit;


---- 		Insert VERTICAL EYE DIAMETER
begin;
with asturias_fish_extract as (
select * from france.asturias_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert > 0
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1551 rows (11268 rows with ang_eye_diam_vert NULL)
commit;


---- 		Insert HORIZONTAL EYE DIAMETER
begin;
with asturias_fish_extract as (
select * from france.asturias_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz > 0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1552 rows (total: 11267 rows)
commit;


---- 		Insert LENGTH OF THE PECTORAL FIN
begin;
with asturias_fish_extract as (
select * from france.asturias_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect > 0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1152 rows (total: 11267 rows)
commit;



--------------------------------------------------------------------------------------------
-- CATALONIA: reprojection and stations
--------------------------------------------------------------------------------------------

select * from france.catalonia_station; -- 300 rows
select count(id_stat) from france.catalonia_station; -- 300 rows
select count(cod_stat) from france.catalonia_station; -- 300 rows


---- Reprojection
SELECT Find_SRID('france', 'catalonia_station', 'geom'); -- 32631

ALTER TABLE france.catalonia_station
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035); -- 3035

CREATE INDEX 
  ON france.catalonia_station
  USING gist
  (geom);
  
-- Add geom_reproj
select addgeometrycolumn('france','catalonia_station','geom_reproj',3035,'POINT',2);

update france.catalonia_station set geom_reproj = sub2.geom_reproj from (
select distinct on (id_stat) id_stat, geom_reproj, distance from(
select
id_stat, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.catalonia_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by id_stat, distance
)sub )sub2
where sub2.id_stat= catalonia_station.id_stat; -- 299 rows (of 300 stations)

CREATE INDEX 
  ON france.catalonia_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.catalonia_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (CAT_) from ligne 134 script "dbeel_france_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.catalonia_station AS sp1, france.catalonia_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment (et_id = 13 = ACA)
-- select * from dbeel.data_provider (dp_id = 11 = Lluis Zamora)


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

-- update france.catalonia_station set dbeel_op_id = NULL;
begin;
WITH 
projection_catalonia AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.catalonia_station g
	-- join france.catalonia_station on op_sta_id = id_stat
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_catalonia AS (
SELECT distinct on (id) * from projection_catalonia
)
-- SELECT * from closest_catalonia; -- 26 rows (one station from GT6, others from SIBIC)
UPDATE france.catalonia_station SET dbeel_op_id = op_id
	FROM closest_catalonia c
	WHERE c.id = catalonia_station.id; -- 26 duplicates
commit;

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='ACA'; -- 0 rows
-- select * from france.dbeel_station_aspe limit 10;
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'ACA' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	name_stat as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	cod_stat as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.catalonia_station
	where dbeel_op_id is null
	; -- 274 lines
commit;

-- We put back the op_id into the source table
begin;
update france.catalonia_station set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- rows
commit; -- 274 rows


-----------------------------------
-- INSERTING CATALONIA OPERATIONS
-----------------------------------

select * from france.catalonia_ope limit 10 -- 443 rows

---- Add dbeel_ob_id in catalonia_operation table
ALTER TABLE france.catalonia_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations (there are 26 stations duplicated)
with g_station_operation as(
select catalonia_station.dbeel_op_id, catalonia_station.id, catalonia_ope.* from france.catalonia_station 
	join france.catalonia_ope on catalonia_station.cod_stat = catalonia_ope.cod_stat -- 401 rows
)-- joining the two tables on the catalonia side
select * from g_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 49 rows


-- Checking the duplicates for year: real duplicates
with g_station_operation as(
select catalonia_station.dbeel_op_id, catalonia_station.id, catalonia_ope.* from france.catalonia_station 
	join france.catalonia_ope on catalonia_station.cod_stat = catalonia_ope.cod_stat -- 401 rows
)-- joining the two tables on the catalonia side
select * from g_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (date_ope, dbeel_op_id); -- 0 rows: NO DUPLICATES IN OPE


-- for those lines where there is a join, add ob_id in catalonia tables
ALTER TABLE france.catalonia_ope ADD COLUMN is_duplicate boolean;


---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES
UPDATE france.catalonia_ope SET is_duplicate is FALSE; -- 443 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (cod_stat, date_ope)) from france.catalonia_ope; -- 155 operations
select count(cod_stat) from france.catalonia_ope; -- 443 rows: species catched by row

select distinct id_ope from france.catalonia_ope; -- 140 operations (15 nulls)
select count(id_stat) from france.catalonia_ope; -- 401 rows
select * from france.catalonia_ope where id_stat is null or fihsed_length is null; 
--		The rows without id_stat don't have information about fished surface. So, we remove them:
--delete from france.catalonia_ope where id_stat is null; -- 42 rows

-- 		The id of france.catalonia_ope is 'cod_stat', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'cat_ob_is' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table france.catalonia_ope add column cat_ob_id uuid default uuid_generate_v4 ();
-- 		The cat_ob_id must be updated because it's unique for each row, but each row doesn't correspond with an operation
with test as (
	select  distinct on (id_ope, date_ope) * from france.catalonia_ope order by id_ope, date_ope -- 140 rows
	)
update france.catalonia_ope ope set cat_ob_id = test.cat_ob_id from test where ope.id_ope = test.id_ope -- 401 rows

-- delete from france.dbeel_electrofishing where ob_id in (select cat_ob_id from france.catalonia_ope); -- 401 rows
begin;
with operation as (
	select  distinct on (id_ope, date_ope) * from france.catalonia_ope order by id_ope, date_ope -- 140 rows
	)

INSERT INTO france.dbeel_electrofishing (
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
	cat_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	date_ope AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	fishing_surface AS ef_wetted_area, 
	fihsed_length AS ef_fished_length,
	fihsed_width AS ef_fished_width,
	1 AS ef_nbpas, -- The number of pass isn't indicated
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.catalonia_station on dbeel_op_id=op_id
	join
		operation on operation.cod_stat=catalonia_station.cod_stat
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Lluis Zamora'
	and is_duplicate = FALSE
	; -- 140 rows
commit;

select * from france.dbeel_station_aspe where op_gis_layername = 'ACA'; -- 274 stations
-- 274 stations are inserted and only 155 operations!?!?


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
begin;
with anguila as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
nb_indiv,
round(cast(density as numeric)/10000,3) as density
from france.catalonia_ope
where name_species='Anguilla anguilla'), -- 29 rows

other as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
0 as nb_indiv,
0 density
from france.catalonia_ope 
where name_species!='Anguilla anguilla'
and cat_ob_id not in (select cat_ob_id from anguila)), -- 111 rows

electrofishing as (select * from anguila 
union
select * from other 
order by cod_stat)

--select * from electrofishing; -- 140 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_indiv AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.cat_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing,
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
	; -- 140 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with anguila as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
nb_indiv,
round(cast(density as numeric)/10000,3) as density
from france.catalonia_ope
where name_species='Anguilla anguilla'), -- 29 rows

other as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
0 as nb_indiv,
0 density
from france.catalonia_ope 
where name_species!='Anguilla anguilla'
and cat_ob_id not in (select cat_ob_id from anguila)), -- 111 rows

electrofishing as (select * from anguila 
union
select * from other 
order by cod_stat)

--select * from electrofishing order by cod_stat; -- 140 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_indiv AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.cat_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing,
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
	; -- 140 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with anguila as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
nb_indiv,
round(cast(density as numeric)/10000,3) as density
from france.catalonia_ope
where name_species='Anguilla anguilla'), -- 29 rows

other as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
0 as nb_indiv,
0 density
from france.catalonia_ope 
where name_species!='Anguilla anguilla'
and cat_ob_id not in (select cat_ob_id from anguila)), -- 111 rows

electrofishing as (select * from anguila 
union
select * from other 
order by cod_stat)

--select * from electrofishing order by cod_stat; -- 140 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.cat_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing,
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
	; -- rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.catalonia_fish add column fish_id serial;
alter table france.catalonia_fish add column ba_id uuid;

-- 		id_species = 8 corresponds to Anguilla anguilla: the rest of individuals are other species
select * from france.catalonia_fish where id_species = 8; -- 220 rows

select sum(nb_indiv) from france.catalonia_ope where name_species='Anguilla anguilla'; -- 193 rows
select * from france.catalonia_fish where id_species = 8 and id_ope in (
	select distinct id_ope from france.catalonia_ope where name_species='Anguilla anguilla'); -- 193 rows

--delete from france.catalonia_fish where id_species = 8 and id_ope not in (
--	select distinct id_ope from france.catalonia_ope where name_species='Anguilla anguilla'); -- 27 rows
select * from france.catalonia_fish where id_species = 8; -- 193 rows


---- 		Check duplicates: Joining catalonia_fish and dbeel_dbeel_batch_fish_aspe by "cod_stat" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.catalonia_fish a join france.catalonia_ope o on cod_stat = o.cod_stat
	join france.dbeel_electrofishing l on ob_id = o.cat_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = ba_ob_id; -- 0 rows
	
-- delete from france.dbeel_dbeel_batch_fish_aspe where ba_id in (select ba_id from france.catalonia_fish);
-- update france.catalonia_fish set ba_id = null;

/*   There aren't fishes in dbeel_dbeel_batch_fish_aspe from _fish, so this query is not necessary
with l as
	(select * from france.catalonia_fish a join france.catalonia_ope o on a.cod_stat = o.cod_stat
	join france.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id)) --  rows
UPDATE france.catalonia_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; --  rows
*/

----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	begin;	
select distinct on (fish_id) * from france.catalonia_fish where id_species = 8; -- 193 rows

begin;
with anguila as (
select distinct on (fish_id)
fish_id,
a.id_ope,
cat_ob_id as ba_ob_id,
ba_id,
length,
weight,
id_species
from france.catalonia_fish a 
	join france.catalonia_ope o on a.id_ope = o.id_ope
	where id_species = 8)
--SELECT * FROM anguila order by ba_ob_id; -- 193 rows
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ba_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND stage.no_name='Yellow eel' 
	AND value_type.no_name='Raw data or Individual data'; -- 193 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in catalonia_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 

with fish_from_catalonia as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 11) -- Verify that ob_dp_id = 11: 193 rows
--select * from fish_from_catalonia join france.catalonia_fish on fish_from_catalonia.fish_id = catalonia_fish.fish_id; -- 193 rows
UPDATE france.catalonia_fish b
SET ba_id = fish_from_catalonia.ba_id
FROM fish_from_catalonia
WHERE fish_from_catalonia.fish_id = b.fish_id; -- 193 rows
-- select * from france.catalonia_fish where ba_id is null and id_species = 8; -- 0 rows


---- 		Insert LENGTH
begin;
with catalonia_fish_extract as (
select * from france.catalonia_fish where ba_id is NOT null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length,
weight,
id_species
from catalonia_fish_extract)
--select * from anguila; -- 193 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 193 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT
begin;
with catalonia_fish_extract as (
select * from france.catalonia_fish where ba_id is NOT null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length,
weight,
id_species
from catalonia_fish_extract)
--select * from anguila; -- 193 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 193 rows ( rows with weight NULL)
commit;


--------------------------------------------------------------------------------------------
--  GALICIA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to france schema from public
ALTER TABLE galicia_ope
    SET SCHEMA france;

ALTER TABLE france.galicia_ope RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.galicia_ope
  USING gist
  (geom);
  
-- Reprojection

select st_srid(geom) from france.galicia_ope; -- 3035 (SELECT Find_SRID doesn't work)

select addgeometrycolumn('france','galicia_ope','geom_reproj',3035,'POINT',2);
update france.galicia_ope set geom_reproj = sub2.geom_reproj from (
select distinct on ("cod_stat") "cod_stat", geom_reproj,distance from(
select
"cod_stat", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.galicia_ope s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by "cod_stat", distance
)sub )sub2
where sub2."cod_stat"= galicia_ope."cod_stat"; -- 5032 rows

CREATE INDEX 
  ON france.galicia_ope
  USING gist
  (geom_reproj);

select count(distinct geom_reproj) from france.galicia_ope; -- 3795 rows (total: 5302 rows)

/* france.galicia_ope has several problems:

-- 1. There isn't an ID to identify the stations:
select distinct on (cod_stat) * from france.galicia_ope order by cod_stat; -- 5302 rows = OPERATIONS (NOT code of stations)
ALTER TABLE france.galicia_ope RENAME COLUMN cod_stat TO cod_ope;
ALTER TABLE france.galicia_fish RENAME COLUMN cod_stat TO cod_ope;

select distinct on (sta_id) * from france.galicia_ope order by sta_id; -- 5302 rows = OPERATIONS (NOT code of stations)
ALTER TABLE france.galicia_ope RENAME COLUMN sta_id TO ope_id;

select distinct on (station) * from france.galicia_ope order by station; -- 2232 rows
ALTER TABLE france.galicia_ope RENAME COLUMN station TO stat_ope;

select distinct on (geom) * from france.galicia_ope; -- 3796 (total: 5302 rows)

-- 	Solution: create a table for stations
-- 	For that, the id's ('GAL_') created in the SIBIC.R script is deleted because it's corresponded to operations
	ALTER TABLE france.galicia_ope DROP COLUMN id;
-- 	The table galicia_station is created taken into account the geometry of operations
	CREATE TABLE france.galicia_station AS
		SELECT distinct on (geom) cod_ope, data_source, stat_ope, river, place, province, efi_code, "ZEC", geom, geom_reproj from france.galicia_ope; -- 3796 rows
-- 	Adding the ID: dbeel_france_electrofishing.sql script (175 line)
--	Insert the ID of the station in galicia_ope table:
	ALTER TABLE france.galicia_ope ADD COLUMN id_station text;
	UPDATE france.galicia_ope set id_station = id from france.galicia_station where galicia_station.geom = galicia_ope.geom; -- 5302 rowws

	
-- 2. The number of fish catched in each operation isn't appeared, only the number of pass (nb_pass)
--	Solution: take galicia.fish table and add the number of eels per pass and operation
ALTER TABLE france.galicia_ope ADD COLUMN run1_ang integer;
ALTER TABLE france.galicia_ope ADD COLUMN run2_ang integer;
ALTER TABLE france.galicia_ope ADD COLUMN run3_ang integer;
ALTER TABLE france.galicia_ope ADD COLUMN run4_ang integer;
ALTER TABLE france.galicia_ope ADD COLUMN run5_ang integer;

with run1_anguila as (
select
cod_ope as sampling,
sum(frequency) as run1_anguila
from france.galicia_fish
where species='Anguila' and op_pass = 1 group by sampling), -- 3346 rows

run2_anguila as (
select
cod_ope as sampling2,
sum(frequency) as run2_anguila
from france.galicia_fish
where species='Anguila' and op_pass = 2 group by sampling2), -- 2537 rows

run3_anguila as (
select
cod_ope as sampling3,
sum(frequency) as run3_anguila
from france.galicia_fish
where species='Anguila' and op_pass = 3 group by sampling3), -- 1626 rows

run4_anguila as (
select
cod_ope as sampling4,
sum(frequency) as run4_anguila
from france.galicia_fish
where species='Anguila' and op_pass = 4 group by sampling4), -- 17 rows

run5_anguila as (
select
cod_ope as sampling5,
sum(frequency) as run5_anguila
from france.galicia_fish
where species='Anguila' and op_pass = 5 group by sampling5), -- 1 row

electro as (select coalesce(sampling, sampling2, sampling3, sampling4, sampling5) as sampling, run1_anguila, run2_anguila, run3_anguila, run4_anguila, run5_anguila from run1_anguila 
	FULL OUTER JOIN run2_anguila on sampling = sampling2
	FULL OUTER JOIN run3_anguila on sampling = sampling3
	FULL OUTER JOIN run4_anguila on sampling = sampling4
	FULL OUTER JOIN run5_anguila on sampling = sampling5
)
--select * from electro; -- 3778 rows (compared to 5302 in guipuz_ope table)
update france.galicia_ope
set (run1_ang, run2_ang, run3_ang, run4_ang, run5_ang) = (run1_anguila, run2_anguila, run3_anguila, run4_anguila, run5_anguila) from electro where galicia_ope.cod_ope = electro.sampling; -- 3699 rows
*/


-- to store the link for dbeel
-- ALTER TABLE france.galicia_ope DROP COLUMN dbeel_op_id;
ALTER TABLE france.galicia_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (GAL_) from dbeel_france_electrofishing.sql script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.galicia_station AS sp1, france.galicia_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 internal duplicates


-- select * from dbeel.establishment; -- et_id = 14; 'The Xunta of Galicia'
-- select * from dbeel.data_provider; -- dp_id = 12 : 'Francisco Hervella' (Fernando Tilves Pazos has also participated)

-- duplicate with data already in dbeel
-- we choose the closest station to join with

WITH 
projection_galicia AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.galicia_station g
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_galicia AS (
SELECT distinct on (id) * from projection_galicia
)
--SELECT * from closest_galicia; -- 412 rows
UPDATE france.galicia_station SET dbeel_op_id = op_id
	FROM closest_galicia c
	WHERE c.id=galicia_station.id; -- 412 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='The Xunta of Galicia'; -- 0 rows
-- select * from france.dbeel_station_aspe limit 10;
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'The Xunta of Galicia' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	place as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	NULL as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.galicia_station
	where dbeel_op_id is null
	; -- 3384 lines
commit;

-- We put back the op_id into the source table
update france.galicia_station set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 3384 rows


--------------------------------
-- INSERTING GALICIA OPERATIONS
--------------------------------
select * from france.galicia_ope limit 10; -- 5302 rows
---- Add dbeel_ob_id in andalucia_ope table
ALTER TABLE france.galicia_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select galicia_station.dbeel_op_id, galicia_station.id, galicia_ope.* from france.galicia_station 
	join france.galicia_ope on galicia_station.id = galicia_ope.id_station -- 5302 rows
)-- joining the two tables on the galicia side
select * from a_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 439 rows

-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select galicia_station.dbeel_op_id, galicia_station.id, galicia_ope.* from france.galicia_station 
	join france.galicia_ope on galicia_station.id = galicia_ope.id_station -- 5302 rows
)-- joining the two tables on the galicia side
select * from a_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 4 rows

-- for those lines where there is a join, add ob_id in galicia tables
ALTER TABLE france.galicia_ope ADD COLUMN is_duplicate boolean;
-- update france.galicia_ope set is_duplicate = FALSE;  -- 5302 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select galicia_station.dbeel_op_id, galicia_station.id, galicia_ope.* from france.galicia_station 
	join france.galicia_ope on galicia_station.id = galicia_ope.id_station -- 5302 rows
	),-- joining the two tables on the andalucia side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
update france.galicia_ope set is_duplicate = TRUE where id_station in (select id_station from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 4 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from france.galicia_ope; -- 5302 rows
select count(distinct (ope_id,op_dat)) from france.galicia_ope; -- 5300 operations
select count(distinct (id_station,op_dat)) from france.galicia_ope; -- 5300 operations

select * from france.dbeel_station_aspe where op_gis_layername = 'The Xunta of Galicia'; -- 3384 stations

alter table france.galicia_ope add column galicia_ob_id uuid default uuid_generate_v4 ();

--delete from france.dbeel_electrofishing where ob_dp_id = 12; -- 5298 rows
--delete from france.galicia_ope where fished_length is null or fished_width is null; -- 33 rows

begin;
INSERT INTO france.dbeel_electrofishing (
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
	galicia_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(galicia_ope.fished_length * galicia_ope.fished_width) AS ef_wetted_area, 
	galicia_ope.fished_length AS ef_fished_length,
	fished_width AS ef_fished_width,
	nb_pass AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.galicia_station on dbeel_op_id=op_id
	join
		france.galicia_ope on galicia_ope.id_station = galicia_station.id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Francisco Hervella'
	and is_duplicate = FALSE
	; -- 5263 rows
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2, run3, run4, run5 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.galicia_ope the information about the number of eels catched per pass is calculated: 4973 line

/* Errors with froeign key and the restriction of the unicity. It has been corrected by removing the electrofishing without information for the surface.	
--DELETE FROM france.galicia_ope WHERE cod_ope = 'INVANG13_056';

ALTER TABLE france.galicia_ope DROP COLUMN galicia_ob_id;
alter table france.galicia_ope add column galicia_ob_id uuid default uuid_generate_v4 ();
*/

with duplicates as (
	Select galicia_station.dbeel_op_id, galicia_station.id, galicia_ope.* from france.galicia_station 
	join france.galicia_ope on galicia_station.id = galicia_ope.id_station -- 5302 rows
	),-- joining the two tables on the galicia side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id, ef_fished_length) = (op_dat, dbeel_op_id, fished_length)
	)
--select * from op_duplicates; -- 5267 rows
update france.galicia_ope set galicia_ob_id = ob_id from op_duplicates od where galicia_ope.op_dat = od.op_dat and galicia_ope.cod_ope = od.cod_ope; -- 5267 rows
select galicia_ob_id, is_duplicate, count(*) from france.galicia_ope group by galicia_ob_id, is_duplicate having count(*) > 1; -- 0 row

select * from france.galicia_ope where galicia_ob_id not in (select ob_id from france.dbeel_electrofishing where ob_dp_id = 12) -- 4 duplicates

begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from france.galicia_ope),

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5
from surface)
--select * from anguila order by cod_ope; -- 5267 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run1 + anguila.run2 + anguila.run3 + anguila.run4 + anguila.run5 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
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
	and is_duplicate = FALSE
	; -- 5263 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from france.galicia_ope),

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 5267 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
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
	and is_duplicate = FALSE
	; -- 5263 rows
commit;
-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from france.galicia_ope where nb_pass >= 2), -- 4607 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 5267 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
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
	and is_duplicate = FALSE
	; -- 4603 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from france.galicia_ope where nb_pass >= 3), -- 3604 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 3604 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
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
	and is_duplicate = FALSE
	; -- 3600 rows
commit;

-- 			op_p4 (biological_characteristic_type.no_name='Number p4') (see biological_characteristic_type.no_id=234)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from france.galicia_ope where nb_pass >= 4), -- 44 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 44 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run4 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
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
	and is_duplicate = FALSE
	; -- 44 rows
commit;

-- 			op_p5 (biological_characteristic_type.no_name='Number p5') (see biological_characteristic_type.no_id=235)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from france.galicia_ope where nb_pass >= 5), -- 1 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 1 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run5 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p5' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 1 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from france.galicia_ope), -- 5267 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila where density > 0; -- 3658 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	anguila, 
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
	and density > 0
	and is_duplicate = FALSE
	; -- 3658 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.galicia_fish add column fish_id serial;
alter table france.galicia_fish add column ba_id uuid;

select sum((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0))) as quantity from france.galicia_ope; -- 50 035 rows
select count(*) from france.galicia_fish; -- 44 191 rows

---- 		Check duplicates: Joining galicia_fish and dbeel_dbeel_batch_fish_aspe by "cod_ope" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.galicia_fish a join france.galicia_ope o on a.cod_ope = o.cod_ope
	join france.dbeel_electrofishing l on ob_id = o.galicia_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = ba_ob_id; -- 0 rows

/*   There aren't fishes in dbeel_dbeel_batch_fish_aspe from _fish, so this query is not necessary
with l as
	(select * from france.galicia_fish a join france.galicia_ope o on a.cod_ope = o.cod_ope
	join france.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id)) --  rows
UPDATE france.galicia_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; --  rows
*/


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	begin;	
select distinct on (fish_id) * from france.galicia_fish; -- 44 191 rows

begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN stage='Amarilla' THEN 226 	--'Yellow eel' 
	     WHEN stage='Plateada' THEN 227 	-- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	galicia_ope.galicia_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	galicia_fish.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.galicia_fish
	join france.galicia_ope
	on galicia_fish.cod_ope = galicia_ope.cod_ope	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 43 897 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in catalonia_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 

with fish_from_galicia as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 12) -- Verify that ob_dp_id = 12: 43 897 rows
--select * from fish_from_galicia join france.galicia_fish on fish_from_galicia.fish_id = galicia_fish.fish_id; -- 43 897 rows
UPDATE france.galicia_fish b
SET ba_id = fish_from_galicia.ba_id
FROM fish_from_galicia
WHERE fish_from_galicia.fish_id = b.fish_id; -- 43897 rows
-- select cod_ope from france.galicia_fish where ba_id is null; -- 294 rows: the cod_ope doesn't appear in galicia_ope table!


---- 		Insert LENGTH (no_id = 39)
begin;
with galicia_fish_extract as (
select * from france.galicia_fish where ba_id is not null) -- 43 897 rows

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length AS bc_numvalue,
	fish_id
	FROM galicia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 43337 rows (560 empty rows)
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with galicia_fish_extract as (
select * from france.galicia_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM galicia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 43337 rows (560 empty rows)
commit;



--------------------------------------------------------------------------------------------
--  BASQUE COUNTRY: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to france schema from public
ALTER TABLE bc_station
    SET SCHEMA france;

ALTER TABLE france.bc_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.bc_station
  USING gist
  (geom);


select * from france.bc_station; -- 179 rows
select count(sta_id) from france.bc_station; -- 179 rows

---- Reprojection
select st_srid(geom) from france.bc_station; -- 3035

-- Add geom_reproj
select addgeometrycolumn('france','bc_station','geom_reproj',3035,'POINT',2);

update france.bc_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.bc_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= bc_station.sta_id; -- 179 rows

CREATE INDEX 
  ON france.bc_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.bc_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (BAS_) from R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.bc_station AS sp1, france.bc_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- "BAS_163"; "BAS_164" internal duplicates

-- add establishment
-- select * from dbeel.establishment
-- select * from dbeel.data_provider

INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('ANBIOTEK'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'ALberto Aguirre', et_id FROM dbeel.establishment WHERE et_establishment_name = 'ANBIOTEK'
; --TODO: TO BE MODIFIED


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.bc_station set dbeel_op_id = NULL;
WITH 
projection_bc AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.bc_station g
	-- join france.bc_station on op_sta_id = sta_id
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_bc AS (
SELECT distinct on (id) * from projection_bc
)
--SELECT * from closest_bc; -- 19 rows
UPDATE france.bc_station SET dbeel_op_id = op_id
	FROM closest_bc c
	WHERE c.id = bc_station.id; -- 19 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='FCUL/MARE'; -- 0 rows
select * from france.bc_station;
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'ANBIOTEK' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.bc_station
	where dbeel_op_id is null
	; -- 160 lines
commit;

-- We put back the op_id into the source table
begin;
update france.bc_station set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 160 rows
commit;


---------------------------------------
-- INSERTING BASQUE COUNTRY OPERATIONS
---------------------------------------

select * from france.bc_ope limit 10;
select op_dat from france.bc_ope order by op_dat

---- Add dbeel_ob_id in bc_ope table
ALTER TABLE france.bc_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select bc_station.dbeel_op_id, bc_station.id, bc_ope.* from france.bc_station 
	join france.bc_ope on bc_station.sta_id = bc_ope.op_sta_id -- 885 rows
)-- joining the two tables on the basque country side
select * from a_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 734 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select bc_station.dbeel_op_id, bc_station.id, bc_ope.* from france.bc_station 
	join france.bc_ope on bc_station.sta_id = bc_ope.op_sta_id -- 885 rows
)-- joining the two tables on the asturias side
select * from a_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 0 rows

-- for those lines where there is a join, add ob_id in basque country tables
ALTER TABLE france.bc_ope ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES
update france.bc_ope set is_duplicate = FALSE;  -- 885 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from france.bc_ope; -- 885 rows
select count(distinct (op_sta_id,op_dat)) from france.bc_ope; -- 885 operations
select * from france.dbeel_station_aspe where op_gis_layername = 'ANBIOTEK'; -- 160 stations

alter table france.bc_ope add column bc_ob_id uuid default uuid_generate_v4 ();


begin;
INSERT INTO france.dbeel_electrofishing (
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
	bc_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.bc_station on dbeel_op_id=op_id
	join
		france.bc_ope on bc_ope.op_sta_id = bc_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='ALberto Aguirre'
	; -- 885 rows
commit;

select * from france.dbeel_electrofishing where ob_id in (select bc_ob_id from france.bc_ope); -- 885 rows


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.asturias_ope there is only information about eels ('op_nbeel').

select * from france.bc_ope where op_length is null or op_width is null; -- 0 rows
select * from france.bc_ope where (op_length is null or op_width is null) and op_dens > 0; -- 0 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ope.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.bc_ope,
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
	; -- 885 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	bc_ope.op_dens AS ba_quantity, -- nbeel/surface * 100
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ope.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.bc_ope, 
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
	and bc_ope.op_dens is not null
	; -- 885 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	bc_ope.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ope.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.bc_ope, 
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
	and op_p1 is not null
	; -- 885 rows
commit;


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.bc_ope,
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
	and op_p2 is not null
	; -- 885 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.bc_fish add column fish_id serial;
alter table france.bc_fish add column ba_id uuid;


---- 		Check duplicates: Joining bc_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.bc_fish a join france.bc_ope o on a.ang_op_id = o.op_id
	join france.dbeel_electrofishing l on l.ob_id = o.bc_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	bc_ope.bc_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	bc_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.bc_fish
	join france.bc_ope
	on bc_fish.ang_op_id = bc_ope.op_id	

	WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel'  
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 5972 rows
commit;

-- Add silvering information in bc_fish table
begin;
update france.bc_fish bc set (pectoral_fin_mm, horiz_diam_mm, vert_diam_mm, back_color, belly_color, lateral_line) = 
	(si.pectoral_fin_mm, si.horiz_diam_mm, si.vert_diam_mm, si.back_color, si.belly_color, si.lateral_line) 
	from france.bc_silv si where bc.ang_op_id = si.ang_op_id::TEXT and bc.ang_lng_cm = si.ang_lng_cm and bc.ang_pds_estimated_g = si.ang_pds_estimated_g -- 219 rows
commit;

-- Update fish_id from dbeel into bc_fish table
begin;
WITH fish_ope AS	(
			select (ang_lng_cm*10) as bc_length, * from france.bc_fish a join france.bc_ope o on a.ang_op_id = o.op_id -- 5972 rows
			),

dbeel as		(
			SELECT ob_id, ba_id, bc_id, bc_numvalue as length, dbeel_mensurationindiv_biol_charac.fish_id FROM 
			france.dbeel_electrofishing join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id join 
			france.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id 
			join dbeel_nomenclature.biological_characteristic_type nn on no_id = bc_no_characteristic_type
			where no_name = 'Length' and ob_dp_id = 23 -- 9137 rows (bc_fish + bc_fish_bis)
			),
 
dbeel_fish as 		(
			select distinct on (dbeel.fish_id) ang_op_id, ang_lng_cm, op_id, ob_id, dbeel.ba_id, bc_id, dbeel.fish_id, pectoral_fin_mm from fish_ope 
			join dbeel on (fish_ope.bc_length, fish_ope.bc_ob_id) = (length, ob_id)
			)
--select * from dbeel_fish where pectoral_fin_mm is not null; -- 219 rows
UPDATE france.bc_fish a
SET fish_id = b.fish_id
FROM dbeel_fish b
WHERE (a.ang_lng_cm, a.ang_op_id) = (b.ang_lng_cm, b.op_id); -- 5972 rows


-- Update ba_id from dbeel into bc_fish table
WITH fish_ope AS	(
			select (ang_lng_cm*10) as bc_length, * from france.bc_fish a join france.bc_ope o on a.ang_op_id = o.op_id -- 5972 rows
			),

dbeel as		(
			select dbeel_dbeel_batch_fish_aspe.*, fish_ope.op_id, fish_ope.ang_lng_cm from france.dbeel_dbeel_batch_fish_aspe join fish_ope on (fish_ope.fish_id, bc_ob_id) = (dbeel_dbeel_batch_fish_aspe.fish_id, ba_ob_id)
			)
--select * from dbeel; -- 5972 rows
UPDATE france.bc_fish a
SET ba_id = b.ba_id
FROM dbeel b
WHERE (a.fish_id, a.ang_lng_cm, a.ang_op_id) = (b.fish_id, b.ang_lng_cm, b.op_id); -- 5972 rows

/* Test not working
WITH fish_ope AS	(
			select * from france.bc_fish a join france.bc_ope o on a.ang_op_id = o.op_id -- 5972 rows
			),		
fish_count_basque as 	(
			SELECT *, row_number() OVER(PARTITION BY bc_ob_id, ang_lng_cm, ang_pds_estimated_g ORDER BY ang_lng_cm desc) FROM fish_ope -- 5972 rows
			),
dbeel_l as 		(
			SELECT ob_id, ba_id, bc_id, bc_numvalue as length FROM 
			france.dbeel_electrofishing join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id join 
			france.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id 
			join dbeel_nomenclature.biological_characteristic_type nn on no_id = bc_no_characteristic_type
			where no_name = 'Length' and ob_dp_id = 23 -- 9137 rows (bc_fish + bc_fish_bis)
			),
dbeel_w as 		(
			SELECT ob_id, ba_id, bc_id, bc_numvalue as weight FROM 
			france.dbeel_electrofishing join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id join 
			france.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id 
			join dbeel_nomenclature.biological_characteristic_type nn on no_id = bc_no_characteristic_type
			where no_name = 'Weight' and ob_dp_id = 23 -- 9137 rows (bc_fish + bc_fish_bis)
			),
dbeel as 		(
			select l.*, weight from dbeel_l l join dbeel_w w on l.ba_id = w.ba_id
			),
fish_count_dbeel as 	(
			SELECT *, row_number() OVER(PARTITION BY ob_id, length, weight) FROM dbeel -- 9137 rows (bc_fish + bc_fish_bis)
			)
select db.ba_id,  length, weight, cb.* from fish_count_dbeel db join fish_count_basque cb on 
	(cb.row_number, cb.bc_ob_id,ang_lng_cm, ang_pds_estimated_g) = (db.row_number, db.ob_id, length, weight)
	where pectoral_fin_mm is not null or horiz_diam_mm is not null or vert_diam_mm is not Null or back_color is not null or belly_color is not null or lateral_line is not null
; -- 0 rows
*/

---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from france.dbeel_station_aspe;

with fish_from_bc as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 23) -- 5972 rows
--select * from fish_from_bc join france.bc_fish on fish_from_bc.fish_id = bc_fish.fish_id; -- 5972 rows
UPDATE france.bc_fish b
SET ba_id = fish_from_bc.ba_id
FROM fish_from_bc
WHERE fish_from_bc.fish_id = b.fish_id; -- 5972 rows
-- select * from france.bc_fish where ba_id is null; -- 9 rows


---- 		Insert LENGTH
begin;
with bc_fish_extract as (
select * from france.bc_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng_cm AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng_cm >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 5972 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT
begin;
with bc_fish_extract as (
select * from france.bc_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds_estimated_g AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds_estimated_g >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 5972 rows (0 rows with weight NULL)
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262) (mm)
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	vert_diam_mm AS bc_numvalue,
	fish_id
	FROM france.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE vert_diam_mm IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263) (mm)
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	horiz_diam_mm AS bc_numvalue,
	fish_id
	FROM france.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE horiz_diam_mm is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264) (mm)
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	pectoral_fin_mm AS bc_numvalue,
	fish_id
	FROM france.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE pectoral_fin_mm is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;

---- 		Insert CONTRAST COLORS (no_id = 266)
alter table france.bc_fish add column ang_contrast boolean;
update france.bc_fish 
set ang_contrast = case
    when back_color = 'NG' or back_color = 'OS' and belly_color = 'BL' or belly_color = 'PL' then true
    when back_color = 'PR' or back_color = 'OR'or back_color = 'OS' and belly_color = 'BA' or belly_color = 'AM' or belly_color = 'BL'  then false
   else null
end;

begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_contrast = FALSE THEN 0
	     WHEN ang_contrast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM france.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_contrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "lateral_line" from bc_fish is text, it must be converted into boolean:
alter table france.bc_fish
alter column lateral_line
set data type boolean
using case
    when lateral_line = 1 or lateral_line = 2 then true
    when lateral_line = 0 then false
    else null
end;

begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN lateral_line = FALSE THEN 0
	     WHEN lateral_line = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM france.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and lateral_line is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;



--------------------------------------------------------------------------------------------
--  BASQUE COUNTRY BIS: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to france schema from public
ALTER TABLE bc_station_bis
    SET SCHEMA france;

ALTER TABLE france.bc_station_bis RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.bc_station_bis
  USING gist
  (geom);


select * from france.bc_station_bis; -- 128 rows
select  distinct sta_id from france.bc_station_bis; -- 116 rows
select  distinct (dbeel_op_id) dbeel_op_id from france.bc_station_bis; -- 116 rows
---- Reprojection
select st_srid(geom) from france.bc_station_bis; -- 3035

-- Add geom_reproj
select addgeometrycolumn('france','bc_station_bis','geom_reproj',3035,'POINT',2);

update france.bc_station_bis set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj, distance from(
select
sta_id, 
ST_ClosestPoint(r.geom, s.geom) as geom_reproj,
ST_distance(r.geom, s.geom) as distance
from france.bc_station_bis s join
spain.rn r on st_dwithin(r.geom, s.geom, 300) 
order by sta_id, distance
) sub) sub2
where sub2.sta_id= bc_station_bis.sta_id; -- 128 rows

CREATE INDEX 
  ON france.bc_station_bis
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.bc_station_bis ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (BAS_) from R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.bc_station_bis AS sp1, france.bc_station_bis AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 14 internal duplicates

-- add establishment
-- select * from dbeel.establishment -- 24: ANBIOTEK
-- select * from dbeel.data_provider -- 23: Alberto Aguirre


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.bc_station_bis set dbeel_op_id = NULL;
WITH 
projection_bc AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.bc_station_bis g
	-- join france.bc_station_bis on op_sta_id = sta_id
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_bc AS (
SELECT distinct on (id) * from projection_bc
)
--SELECT * from closest_bc; -- 70 rows
UPDATE france.bc_station_bis SET dbeel_op_id = op_id
	FROM closest_bc c
	WHERE c.id = bc_station_bis.id; -- 70 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='ANBIOTEK'; -- 160 rows
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'ANBIOTEK' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	null as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	sta_basin as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.bc_station_bis
	where dbeel_op_id is null
	; -- 58 lines
commit;

-- We put back the op_id into the source table
update france.bc_station_bis set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 58 rows


-------------------------------------------
-- INSERTING BASQUE COUNTRY OPERATIONS BIS
-------------------------------------------

select * from france.bc_ope_bis; -- 324 rows
select op_dat from france.bc_ope_bis order by op_dat; -- 2002/2009

---- Add dbeel_ob_id in bc_ope table
ALTER TABLE france.bc_ope_bis ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id -- 275 rows
)-- joining the two tables on the basque country side
select * from a_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 273 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id -- 275 rows
)-- joining the two tables on the basque country side
select * from a_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 1 rows

-- for those lines where there is a join, add ob_id in basque country tables
ALTER TABLE france.bc_ope_bis ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES
update france.bc_ope_bis set is_duplicate = FALSE;  -- 324 rows

with duplicates as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id -- 275 rows
	),-- joining the two tables on the basque country side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates; -- 1 rows
update france.bc_ope_bis set is_duplicate = TRUE where op_id in (select op_id from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 1 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)

select * from france.bc_ope_bis; -- 324 rows
select count(distinct (op_sta_id,op_dat)) from france.bc_ope_bis; -- 324 operations
select * from france.dbeel_station_aspe where op_gis_layername = 'ANBIOTEK'; -- 218 stations

alter table france.bc_ope_bis add column bc_ob_id uuid default uuid_generate_v4 ();

/* In bc_station_bis there are duplicated rows!
begin;
WITH uniques AS
    (SELECT DISTINCT ON (dbeel_op_id, geom_reproj) * FROM france.bc_station_bis) -- 124 rows
DELETE FROM france.bc_station_bis WHERE france.bc_station_bis.id NOT IN (SELECT id FROM uniques); -- 4rows
commit;

begin;
WITH uniques AS
    (SELECT DISTINCT ON (sta_id) * FROM france.bc_station_bis) -- 116 rows
DELETE FROM france.bc_station_bis WHERE france.bc_station_bis.id NOT IN (SELECT id FROM uniques); -- 8rows
commit;
*/
begin;
INSERT INTO france.dbeel_electrofishing (
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
	bc_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	op_surface_m2 AS ef_wetted_area, 
	null AS ef_fished_length,
	null AS ef_fished_width,
	nb_pass AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.bc_station_bis on dbeel_op_id = op_id
	join
		france.bc_ope_bis on bc_ope_bis.op_sta_id = bc_station_bis.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='ALberto Aguirre'
	and is_duplicate = FALSE
	; -- 252 rows
commit;

select * from france.dbeel_electrofishing where ob_id in (select bc_ob_id from france.bc_ope_bis); -- 252 rows





-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2, run3 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-
select * from france.bc_ope_bis where op_surface_m2 is null; -- 0 rows
select * from france.bc_ope_bis where op_surface_m2 is null and op_nb_eels > 0; -- 0 rows

-- There is one row with density but no number of eels, so remove it!
--DELETE FROM france.bc_ope_bis WHERE op_nb_eels is null; -- 1rows

BEGIN;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id
	) -- 252 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
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
	and is_duplicate = FALSE
	; -- 251 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
-- 			Density is calculated with different methods: estimation_method (Relative abundance, Seber Lecren, Carle Strab)
BEGIN;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id
	) -- 252 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	round(coalesce(uniques.op_dens_nha::NUMERIC/10000,0),3) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	uniques, 
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
	and is_duplicate = FALSE
	; -- 251 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id
	) -- 252 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	uniques.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	uniques, 
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
	and is_duplicate = FALSE
	; -- 251 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id where nb_pass >= 2
	) -- 224 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
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
	and is_duplicate = FALSE
	; -- 223 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id where nb_pass >= 3
	) -- 11 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
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
	and is_duplicate = FALSE
	; -- 11 rows
commit;




select * from france.bc_ope_bis 
except select * from france.bc_ope_bis 
where op_sta_id in (select sta_id from france.bc_station_bis); -- 71 rows

select * from france.bc_station_bis 
--except select * from france.bc_ope_bis 
where sta_id in (select op_sta_id from france.bc_ope_bis);




---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.bc_fish_bis add column fish_id serial;
alter table france.bc_fish_bis add column ba_id uuid;

---- 		Check duplicates: Joining bc_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select count(*) from france.bc_fish_bis; -- 3790 rows
select sum(op_nb_eels) from france.bc_ope_bis; -- 3771 roxs

select * from france.bc_fish_bis a join france.bc_ope_bis o on ang_op_id = op_id -- 3758 rows
	join france.dbeel_electrofishing l on l.ob_id = o.bc_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from france.bc_station_bis 
	join france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id
	) -- 11 rows
	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	bc_fish_bis.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.bc_fish_bis
	join uniques
	on ang_op_id = op_id	

	WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel'  
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 3174 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
with fish_from_bc as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 23
	and ob_starting_date in (select op_dat from france.bc_ope_bis where is_duplicate = FALSE) -- ba_id is repeated because fish_id is the same in bc_fish table and bc_fish_bis
) -- 3174 rows
--select * from fish_from_bc join france.bc_fish_bis on fish_from_bc.fish_id = bc_fish_bis.fish_id; -- 3174 rows
UPDATE france.bc_fish_bis b
SET ba_id = fish_from_bc.ba_id
FROM fish_from_bc
WHERE fish_from_bc.fish_id = b.fish_id; -- 3174 rows
-- select * from france.bc_fish_bis where ba_id is null; -- 616 rows

/* There are 9 rows that are more than one individual: nag_nb_indiv > 1 (with length and weigth as a mean): Remove them!
delete from france.dbeel_dbeel_batch_fish_aspe where ba_id in (select ba_id from france.bc_fish_bis where ang_nb_indiv > 1); -- 9 rows
update france.bc_fish_bis set ba_id = NULL where ang_nb_indiv > 1;  -- 9 rows
*/
---- 		Insert LENGTH
begin;
with bc_fish_extract as (
select * from france.bc_fish_bis where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_length_cm AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_length_cm > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3165 rows
commit; 


---- 		Insert WEIGHT
begin;
with bc_fish_extract as (
select * from france.bc_fish_bis where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds_g AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds_g > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3165 rows
commit;




--------------------------------------------------------------------------------------------
--  NAVARRA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to france schema from public
ALTER TABLE navarra_station
    SET SCHEMA france;

ALTER TABLE france.navarra_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.navarra_station
  USING gist
  (geom);


select * from france.navarra_station; -- 12 rows
select count(sta_id) from france.navarra_station; -- 12 rows

---- Reprojection
select st_srid(geom) from france.navarra_station; -- 3035

  
-- Add geom_reproj
select addgeometrycolumn('france','navarra_station','geom_reproj',3035,'POINT',2);

update france.navarra_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.navarra_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= navarra_station.sta_id; -- 12 rows

CREATE INDEX 
  ON france.navarra_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.navarra_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (NAV_) from R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.navarra_station AS sp1, france.navarra_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment
-- select * from dbeel.data_provider

INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('The Navarra Environmental Management'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Josu Iñaki Elso Huarte', et_id FROM dbeel.establishment WHERE et_establishment_name = 'The Navarra Environmental Management'
; --TODO: TO BE MODIFIED


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.navarra_station set dbeel_op_id = NULL;
WITH 
projection_navarra AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.navarra_station g
	-- join france.navarra_station on op_sta_id = sta_id
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_navarra AS (
SELECT distinct on (id) * from projection_navarra
)
--SELECT * from closest_navarra; -- 9 rows
UPDATE france.navarra_station SET dbeel_op_id = op_id
	FROM closest_navarra c
	WHERE c.id = navarra_station.id; -- 9 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='The Navarra Environmental Management'; -- 0 rows
-- select * from france.navarra_station;
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'The Navarra E. M.' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS op_op_id,
	geom as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_cod as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.navarra_station
	where dbeel_op_id is null
	; -- 3 lines
commit;

-- We put back the op_id into the source table
begin;
update france.navarra_station set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 3 rows
commit;

------------------------------
-- INSERTING NAVARRA OPERATIONS
------------------------------
select * from france.navarra_ope limit 10;
---- Add dbeel_ob_id in navarra_ope table
ALTER TABLE france.navarra_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select navarra_station.dbeel_op_id, navarra_station.id, navarra_ope.* from france.navarra_station 
	join france.navarra_ope on navarra_station.sta_id = navarra_ope.op_sta_id -- 66 rows
)-- joining the two tables on the navarra side
select * from a_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 112 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select navarra_station.dbeel_op_id, navarra_station.id, navarra_ope.* from france.navarra_station 
	join france.navarra_ope on navarra_station.sta_id = navarra_ope.op_sta_id -- 210 rows
)-- joining the two tables on the navarra side
select * from a_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) order by is_duplicate -- 9 rows

-- for those lines where there is a join, add ob_id in navarra tables
ALTER TABLE france.navarra_ope ADD COLUMN is_duplicate boolean;
-- update france.navarra_ope set is_duplicate = FALSE;  -- 66 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select navarra_station.dbeel_op_id, navarra_station.id, navarra_ope.* from france.navarra_station 
	join france.navarra_ope on navarra_station.sta_id = navarra_ope.op_sta_id -- 66 rows
	),-- joining the two tables on the navarra side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)

select * from op_duplicates order by is_duplicate; -- 9 rows
update france.navarra_ope set is_duplicate = TRUE where op_cod in (select op_cod from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 9 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from france.navarra_ope; -- 66 rows
select count(distinct (op_sta_id,op_dat)) from france.navarra_ope; -- 66 operations
select * from france.dbeel_station_aspe where op_gis_layername = 'The Navarra E. M.'; -- 3 stations

alter table france.navarra_ope add column navarra_ob_id uuid default uuid_generate_v4 ();


begin;
INSERT INTO france.dbeel_electrofishing (
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
	navarra_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.navarra_station on dbeel_op_id=op_id
	join
		france.navarra_ope on navarra_ope.op_sta_id = navarra_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Josu Iñaki Elso Huarte'
	and is_duplicate = FALSE
	; -- 57 rows
commit;

select * from france.dbeel_electrofishing where ob_id in (select navarra_ob_id from france.navarra_ope); -- 57 rows


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.asturias_ope there is only information about eels ('op_nbeel').

select * from france.navarra_ope where op_length is null or op_width is null; -- 0 rows
select * from france.navarra_ope where (op_length is null or op_width is null) and op_dens > 0; -- 0 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	navarra_ope.navarra_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.navarra_ope,
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
	and is_duplicate = FALSE
	; -- 57 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	navarra_ope.op_dens AS ba_quantity, -- It is not nb/m2! (may be c&s?)
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	navarra_ope.navarra_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.navarra_ope, 
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
	and is_duplicate = FALSE
	and navarra_ope.op_dens is not null
	; -- 57 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	navarra_ope.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	navarra_ope.navarra_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.navarra_ope, 
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
	and is_duplicate = FALSE
	and op_p1 is not null
	; -- 57 rows
commit;


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	navarra_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.navarra_ope,
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
	and is_duplicate = FALSE
	and op_p2 is not null
	; -- 11 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.navarra_fish add column fish_id serial;
alter table france.navarra_fish add column ba_id uuid;


---- 		Check duplicates: Joining navarra_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.navarra_fish a join france.navarra_ope o on a.ang_op_id = o.op_id
	join france.dbeel_electrofishing l on l.ob_id = o.navarra_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows

/*  
select * from france.navarra_fish where ang_silver = FALSE; -- 446 rows
select * from france.navarra_fish where ang_silver = TRUE; -- 287 rows
*/

----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy

/* ERROR: insertion or update in the table  «dbeel_dbeel_batch_fish_aspe» violates foreign key «c_fk_fi_ob_id»
   DETAIL:  The key (ba_ob_id)=(ead4d27d-b9cd-4532-b861-20681b23464f) is not present in the table «dbeel_electrofishing»

select * from france.dbeel_electrofishing where ob_op_id = 'a3d7c74e-8bd8-4075-a130-b0a27ab18a8a';
select * from france_navarra_ope where navarra_ob_id = 'ead4d27d-b9cd-4532-b861-20681b23464f';

The error was that navarra_ob_id from navarra_ope didn't correspond with the ob_id from dbeel_electrofishing for duplicates (is_duplicate = TRUE).
The error has been corrected (following lines)
*/
begin;
with duplicates as (
	Select navarra_station.dbeel_op_id, navarra_station.id, navarra_ope.* from france.navarra_station 
	join france.navarra_ope on navarra_station.sta_id = navarra_ope.op_sta_id -- 66 rows
	),-- joining the two tables on the navarra side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates order by is_duplicate; -- 
update france.navarra_ope set navarra_ob_id = ob_id from op_duplicates od where navarra_ope.op_dat = od.op_dat and navarra_ope.op_cod = od.op_cod;
commit;

begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN ang_silver='FALSE' THEN 226 	--'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 	-- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	navarra_ope.navarra_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	navarra_fish.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.navarra_fish
	join france.navarra_ope
	on navarra_fish.ang_op_id = navarra_ope.op_id	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 3973 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length, weight, silvering, pect_eye_diam_vert, ang_diam_horiz
---- 		To integrate length and weight of fish, "ba_id" must be included before in navarra_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in navarra_fish table! 

with fish_from_navarra as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 24) -- 3627 rows
-- select * from fish_from_navarra join france.navarra_fish on fish_from_navarra.fish_id = navarra_fish.fish_id; -- 3627 rows
UPDATE france.navarra_fish b
SET ba_id = fish_from_navarra.ba_id
FROM fish_from_navarra
WHERE fish_from_navarra.fish_id = b.fish_id; -- 3627 rows
-- select * from france.navarra_fish where ba_id is null; -- 346 rows


---- 		Insert LENGTH (no_id = 39)
begin;
with navarra_fish_extract as (
select * from france.navarra_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3627 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with navarra_fish_extract as (
select * from france.navarra_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 662 rows (3239 rows with weight NULL)
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
with navarra_fish_extract as (
select * from france.navarra_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 659 rows (3259 rows with ang_eye_diam_vert NULL)
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
with navarra_fish_extract as (
select * from france.navarra_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz > 0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 660 rows (3258 rows with ang_eye_diam_horiz null)
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
with navarra_fish_extract as (
select * from france.navarra_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect > 0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 661 rows (3242 rows with ang_pect NULL)
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
select * from france.navarra_fish where ang_neuromast is not null; -- 0 rows

---- 		Insert CONTRAST COLORS (no_id = 266)
select * from france.navarra_fish where ang_constrast is not null; -- 0 rows



--------------------------------------------------------------------------------------------
--  ANDALUCIA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to france schema from public
--	Station:
ALTER TABLE andalucia_station
    SET SCHEMA france;

ALTER TABLE france.andalucia_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.andalucia_station
  USING gist
  (geom);

--	Operation:
ALTER TABLE andalucia_ope
    SET SCHEMA france;

ALTER TABLE france.andalucia_ope RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.andalucia_ope
  USING gist
  (geom);


select * from france.andalucia_station; -- 62 (15 rows without surface)
--delete from france.andalucia_station where surface_m2 is null; -- 15 rows

select count(distinct sta_id) from france.andalucia_station; -- 47 rows

---- Reprojection
select st_srid(geom) from france.andalucia_station; -- 3035

-- Add geom_reproj
select addgeometrycolumn('france','andalucia_station','geom_reproj',3035,'POINT',2);

update france.andalucia_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.andalucia_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= andalucia_station.sta_id; -- 47 rows

CREATE INDEX 
  ON france.andalucia_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.andalucia_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (AST_) from ligne 145 script "dbeel_france_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.andalucia_station AS sp1, france.andalucia_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment (et_id = 18, UCO)
-- select * from dbeel.data_provider (dp_id = 16, Carlos Fernandez, dp_et_id = 18)


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.andalucia_station set dbeel_op_id = NULL;
WITH 
projection_andalucia AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 g.sta_id,
	 d.place_classification
	FROM france.andalucia_station g
	-- join france.andalucia_station on op_sta_id = sta_id
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_andalucia AS (
SELECT distinct on (id) * from projection_andalucia
)
--SELECT * from closest_andalucia; -- 31 rows
UPDATE france.andalucia_station SET dbeel_op_id = op_id
	FROM closest_andalucia c
	WHERE c.id = andalucia_station.id; -- 31 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='UCO'; -- 0 rows
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'UCO' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	NULL as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.andalucia_station
	where dbeel_op_id is null
	; -- 16 lines
commit;

-- We put back the op_id into the source table
begin;
update france.andalucia_station set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 16 rows
commit;



----------------------------------
-- INSERTING ANDALUCIA OPERATIONS
----------------------------------
select * from france.andalucia_ope limit 10;
---- Add dbeel_ob_id in andalucia_ope table
ALTER TABLE france.andalucia_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select andalucia_station.dbeel_op_id, andalucia_station.id, andalucia_ope.* from france.andalucia_station 
	join france.andalucia_ope on andalucia_station.sta_id = andalucia_ope.sta_id -- 93 rows
)-- joining the two tables on the andalucia side
select * from a_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 61 rows

-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select andalucia_station.dbeel_op_id, andalucia_station.id, andalucia_ope.* from france.andalucia_station 
	join france.andalucia_ope on andalucia_station.sta_id = andalucia_ope.sta_id -- 93 rows
)-- joining the two tables on the andalucia side
select * from a_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 1 rows

-- for those lines where there is a join, add ob_id in andalucia tables
ALTER TABLE france.andalucia_ope ADD COLUMN is_duplicate boolean;
-- update france.andalucia_ope set is_duplicate = FALSE;  -- 93 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select andalucia_station.dbeel_op_id, andalucia_station.id, andalucia_ope.* from france.andalucia_station 
	join france.andalucia_ope on andalucia_station.sta_id = andalucia_ope.sta_id -- 93 rows
	),-- joining the two tables on the andalucia side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
update france.andalucia_ope set is_duplicate = TRUE where sta_id in (select sta_id from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 1 rows

DELETE FROM france.andalucia_ope WHERE sta_id = '1.37.1' and op_dat = '2012-03-13'; -- This row is empty

---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from france.andalucia_ope; -- 93 rows
select count(distinct (sta_id,op_dat)) from france.andalucia_ope; -- 93 operations
select * from france.dbeel_station_aspe where op_gis_layername = 'UCO'; -- 16 stations

alter table france.andalucia_ope add column andalucia_ob_id uuid default uuid_generate_v4 ();


begin;
INSERT INTO france.dbeel_electrofishing (
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
	andalucia_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	andalucia_ope.surface_m2 AS ef_wetted_area, 
	andalucia_ope.meter_fished::REAL AS ef_fished_length,
	NULL AS ef_fished_width,
	1 AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.andalucia_station on dbeel_op_id=op_id
	join
		france.andalucia_ope on andalucia_ope.sta_id = andalucia_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Carlos Fernandez'
	and is_duplicate = FALSE
	; -- 91 rows
commit;

select * from france.dbeel_electrofishing where ob_id in (select andalucia_ob_id from france.andalucia_ope); -- 91 rows

-- The riverbed corresponds to the width of the river: it must be included!
begin;
with join_electro as (
	select * from france.andalucia_ope JOIN france.dbeel_electrofishing on(ob_starting_date, ob_id) = (op_dat, andalucia_ob_id)
	)
--select * from join_electro; -- 91 rows
update france.dbeel_electrofishing set ef_fished_width = riverbed from join_electro 
	where dbeel_electrofishing.ob_id = join_electro.ob_id and dbeel_electrofishing.ob_starting_date = join_electro.ob_starting_date; -- 91 rows
COMMIT;

-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.andalucia_ope there is only information about eels ('nb_eels').

select * from france.andalucia_ope where meter_fished is null or riverbed is null; -- 0 rows
select * from france.andalucia_ope where (meter_fished is null or riverbed is null) and nb_eels > 0; -- 0 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	andalucia_ope.andalucia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.andalucia_ope,
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
	and is_duplicate = FALSE
	; -- 91 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	coalesce(andalucia_ope.nb_eels/andalucia_ope.surface_m2,0) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	andalucia_ope.andalucia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.andalucia_ope, 
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
	and is_duplicate = FALSE
	; -- 91 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	andalucia_ope.nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	andalucia_ope.andalucia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.andalucia_ope, 
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
	and is_duplicate = FALSE
	; -- 91 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.andalucia_fish add column fish_id serial;
alter table france.andalucia_fish add column ba_id uuid;


---- 		Check duplicates: Joining andalucia_fish and dbeel_dbeel_batch_fish_aspe by "sta_id" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.andalucia_fish a join france.andalucia_ope o on a.fish_sta_id = o.sta_id
	join france.dbeel_electrofishing l on l.ob_id = o.andalucia_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows (NOT sure that it's right)


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT distinct on (andalucia_fish.fish_id)
	uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	andalucia_ope.andalucia_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	andalucia_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.andalucia_fish
	join france.andalucia_ope
	on (andalucia_fish.fish_sta_id, andalucia_fish.fish_op_dat) = (andalucia_ope.sta_id, andalucia_ope.op_dat)	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 29 rows (2 rows are missing, I don't know why...)
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in andalucia_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in andalucia_fish table! 

with fish_from_andalucia as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 16) 
--select * from fish_from_andalucia join france.andalucia_fish on fish_from_andalucia.fish_id = andalucia_fish.fish_id; -- 29 rows
UPDATE france.andalucia_fish b
SET ba_id = fish_from_andalucia.ba_id
FROM fish_from_andalucia
WHERE fish_from_andalucia.fish_id = b.fish_id; -- 29 rows
-- select * from france.andalucia_fish where ba_id is null; -- 2 rows


---- 		Insert LENGTH
begin;
with andalucia_fish_extract as (
select * from france.andalucia_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length_mm AS bc_numvalue,
	fish_id
	FROM andalucia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length_mm >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 29 rows (0 rows with length NULL)
commit; 


---- 		Insert WEIGHT
begin;
with andalucia_fish_extract as (
select * from france.andalucia_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weigth_g AS bc_numvalue,
	fish_id
	FROM andalucia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weigth_g >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 21 rows (8 rows with weight NULL)
commit;


--------------------------------------------------------------------------------------------
--  MINHO: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to france schema from public
ALTER TABLE minho_station
    SET SCHEMA france;

ALTER TABLE france.minho_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.minho_station
  USING gist
  (geom);

select * from france.minho_station; -- 29 rows
select count(sta_id) from france.minho_station; -- 29 rows

---- Reprojection
SELECT Find_SRID('france', 'minho_station', 'geom'); -- 25830
  
-- Add geom_reproj
select addgeometrycolumn('france','minho_station','geom_reproj',3035,'POINT',2);

update france.minho_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.minho_station s join
portugal.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= minho_station.sta_id; -- 27 rows

CREATE INDEX 
  ON france.minho_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.minho_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (AST_) from ligne 145 script "dbeel_france_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.minho_station AS sp1, france.minho_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment -- UP (et_id = 15)
-- select * from dbeel.data_provider -- Carlos Antunes (dp_id = 13)


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.minho_station set dbeel_op_id = NULL;
WITH 
projection_minho AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.minho_station g
	-- join france.minho_station on op_sta_id = sta_id
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_minho AS (
SELECT distinct on (id) * from projection_minho
)
--SELECT * from closest_minho; -- 0 row
UPDATE france.minho_station SET dbeel_op_id = op_id
	FROM closest_minho c
	WHERE c.id = minho_station.id; -- 0 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='FCUL/MARE'; -- 0 rows
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'UP' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'PT' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.minho_station
	where dbeel_op_id is null
	; -- 29 lines
commit;

-- We put back the op_id into the source table
begin;
update france.minho_station set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 29 rows
commit;


------------------------------
-- INSERTING MINHO OPERATIONS
------------------------------
select * from france.minho_ope limit 10; -- 89 rows
---- Add dbeel_ob_id in asturias_ope table
ALTER TABLE france.minho_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select minho_station.dbeel_op_id, minho_station.id, minho_ope.* from france.minho_station 
	join france.minho_ope on minho_station.sta_id = minho_ope.op_sta_id -- 89 rows
)-- joining the two tables on the minho side
select * from a_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 19 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select minho_station.dbeel_op_id, minho_station.id, minho_ope.* from france.minho_station 
	join france.minho_ope on minho_station.sta_id = minho_ope.op_sta_id -- 89 rows
)-- joining the two tables on the minho side
select * from a_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id); -- 0 rows

-- for those lines where there is a join, add ob_id in asturias tables
ALTER TABLE france.minho_ope ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES
-- update france.minho_ope set is_duplicate = FALSE;  -- 89 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from france.minho_ope; -- 89 rows
select count(distinct (op_sta_id,op_dat)) from france.minho_ope; -- 89 operations
select * from france.dbeel_station_aspe where op_gis_layername = 'UP'; -- 29 stations

alter table france.minho_ope add column minho_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO france.dbeel_electrofishing (
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
	minho_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.minho_station on dbeel_op_id=op_id
	join
		france.minho_ope on minho_ope.op_sta_id = minho_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Carlos Antunes'
	and is_duplicate = FALSE
	; -- 89 rows ERROR: 11 rows without surface data!!!
commit;

select * from france.dbeel_electrofishing where ob_id in (select minho_ob_id from france.minho_ope); -- 89 rows


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.asturias_ope there is only information about eels ('op_nbeel').

-- Remove rows without surface data:
UPDATE france.minho_ope SET op_area = op_length * op_width WHERE op_area is null; -- 42 rows
DELETE FROM france.minho_ope WHERE op_area is null; -- 11 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ope.minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.minho_ope,
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
	and is_duplicate = FALSE
	; -- 78 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
--ALTER TABLE france.minho_ope DROP COLUMN op_dens;
--ALTER TABLE france.minho_ope ADD COLUMN op_dens double precision;
UPDATE france.minho_ope SET op_dens = coalesce(op_nbeel/op_area,0) WHERE op_dens is null; -- 78 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	round(op_dens::NUMERIC,3) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ope.minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.minho_ope, 
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
	and is_duplicate = FALSE
	and minho_ope.op_dens is not null
	; -- 78 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	minho_ope.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ope.minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	france.minho_ope, 
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
	and is_duplicate = FALSE
	and op_p1 is not null
	; -- 78 rows
commit;


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.minho_ope,
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
	and is_duplicate = FALSE
	and op_p2 is not null
	; -- 34 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.minho_ope,
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
	and is_duplicate = FALSE
	and op_p3 is not null
	; -- 2 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.minho_fish add column fish_id serial;
alter table france.minho_fish add column ba_id uuid;


---- 		Check duplicates: Joining asturias_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.minho_fish a join france.minho_ope o on a.ang_op_id = o.op_id
	join france.dbeel_electrofishing l on l.ob_id = o.minho_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	minho_ope.minho_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	minho_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.minho_fish
	join france.minho_ope
	on minho_fish.ang_op_id = minho_ope.op_id	

	WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel'
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 1896 rows (total: 2010)
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
with fish_from_minho as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 13) -- 1896 rows
--select * from fish_from_minho join france.minho_fish on fish_from_minho.fish_id = minho_fish.fish_id; -- 1896 rows
UPDATE france.minho_fish b
SET ba_id = fish_from_minho.ba_id
FROM fish_from_minho
WHERE fish_from_minho.fish_id = b.fish_id; -- 1860 rows
-- select * from france.minho_fish where ba_id is null; -- 150 rows


---- 		Insert LENGTH
begin;
with minho_fish_extract as (
select * from france.minho_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM minho_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1860 rows
commit; 


---- 		Insert WEIGHT
begin;
with minho_fish_extract as (
select * from france.minho_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM minho_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1860 rows
commit;


--------------------------------------------------------------------------------------------
--  SPAIN (MITECO): reprojection and stations
--------------------------------------------------------------------------------------------

ALTER TABLE spain_station
    SET SCHEMA france;

ALTER TABLE france.spain_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.spain_station
  USING gist
  (geom);

select * from france.spain_station; -- 717 rows
select count(sta_id) from france.spain_station; -- 717 rows

---- Reprojection
select st_srid(geom) from france.spain_station; -- 3035
  
-- Add geom_reproj
select addgeometrycolumn('france','spain_station','geom_reproj',3035,'POINT',2);

update france.spain_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from (
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.spain_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= spain_station.sta_id; -- 711 rows

CREATE INDEX 
  ON france.spain_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.spain_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (SPA_) from R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.spain_station AS sp1, france.spain_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment -- miteco (et_id = 17)
-- select * from dbeel.data_provider -- Belén Muñoz (dp_id = 15)


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update france.spain_station set dbeel_op_id = NULL;
WITH 
projection_spain AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.spain_station g
	-- join france.spain_station on op_sta_id = sta_id
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join france.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_spain AS (
SELECT distinct on (id) * from projection_spain
)
--SELECT * from closest_spain; -- 224 row
UPDATE france.spain_station SET dbeel_op_id = op_id
	FROM closest_spain c
	WHERE c.id = spain_station.id; -- 224 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='miteco'; -- 0 rows (and 'min esp')
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'miteco' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_cod as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.spain_station
	where dbeel_op_id is null
	; -- 493 lines
commit;

-- We put back the op_id into the source table
begin;
update france.spain_station set dbeel_op_id = op_id from france.dbeel_station_aspe where id = op_gislocation; -- 493 rows
commit;

---------------------------------------
-- INSERTING SPAIN (MITECO) OPERATIONS
---------------------------------------
-- Duplicates with the same information:
SELECT op_sta_id, op_dat, count(*) FROM france.spain_ope GROUP BY op_sta_id, op_dat HAVING count(*) > 1;
/*
WITH uniq AS
    (SELECT op_sta_id, op_dat, count(*) FROM france.spain_ope GROUP BY op_sta_id, op_dat HAVING count(*) > 1)
DELETE FROM france.spain_ope op WHERE op.op_sta_id IN (SELECT op_sta_id FROM uniq) and op.op_dat IN (SELECT op_dat FROM uniq); -- 32 rows 
*/
select count(*) from france.spain_ope; -- 1184 rows

-- Update the surface when length and width data are available
update france.spain_ope set op_surface = case
	when spain_ope.op_surface is null then round(cast(coalesce(spain_ope.op_length, 0) * coalesce(spain_ope.op_width, 0)/1000000 as numeric), 3)
	when spain_ope.op_surface is not null then round(cast(spain_ope.op_surface as numeric), 3)
	end; --1184

/* There are rows with eels but without information about surface: remove it!
delete from france.spain_ope where op_surface = 0 and (op_length is null or op_width is null); -- 109 rows
*/

-- Update sta_cod: when it is null, the op_cod has been split to take the first part of the string
update france.spain_ope set sta_cod = case
						when sta_cod is not null then sta_cod
						when sta_cod is null then (select split_part(op_cod, '-', 1))
					END; -- 1075 rows

---- Add dbeel_ob_id in spain_ope table
ALTER TABLE france.spain_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with s_station_operation as(
select spain_station.dbeel_op_id, spain_station.id, spain_station.sta_cod, spain_ope.* from france.spain_station 
	join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod -- 1071 rows
)-- joining the two tables on the spain side
select * from s_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 401 rows (but the date it is not the same)

-- Checking the duplicates for year: real duplicates
with s_station_operation as(
select spain_station.dbeel_op_id, spain_station.id, spain_station.sta_cod, spain_ope.* from france.spain_station 
	join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod -- 1071 rows
)-- joining the two tables on the spain side
select * from s_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 99 rows

-- for those lines where there is a join, add ob_id in spain tables
ALTER TABLE france.spain_ope ADD COLUMN is_duplicate boolean;
update france.spain_ope set is_duplicate = FALSE; -- 1075 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from france.spain_station 
	join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod -- 1071 rows
	),-- joining the two tables on the spain side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates; -- 99 rows
update france.spain_ope set is_duplicate = TRUE where spain_ope.sta_cod in (select op_duplicates.sta_cod from op_duplicates) 
							and spain_ope.op_dat in (select op_duplicates.op_dat from op_duplicates); -- 99 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with surface)
select * from france.spain_ope; -- 1075 rows
select count(distinct (sta_cod,op_dat)) from france.spain_ope; -- 1075 operations
select count(distinct (op_sta_id,op_dat)) from france.spain_ope; -- 1075 operations

select * from france.dbeel_station_aspe where op_gis_layername = 'miteco'; -- 493 stations

alter table france.spain_ope add column spain_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO france.dbeel_electrofishing (
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
	spain_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	spain_ope.op_surface AS ef_wetted_area, 
	spain_ope.op_length AS ef_fished_length,
	spain_ope.op_width AS ef_fished_width,
	spain_ope.op_nbpass AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.spain_station on dbeel_op_id=op_id
	join
		france.spain_ope on spain_ope.sta_cod = spain_station.sta_cod
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Belén Muñoz'
	and is_duplicate = FALSE
	; -- 972 rows (1075 operations - 99 duplicates - 4 with the same sta_cod)
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2, run3 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.spain_ope there is only information about eels
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from france.spain_station 
		join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ) -- joining the two tables on the spain side

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	ope,
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
	; -- 972 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from france.spain_station 
		join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ) -- joining the two tables on the spain side
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	ope,
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
	; -- 972 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from france.spain_station 
		join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ) -- joining the two tables on the spain side
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2::NUMERIC AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	ope,
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
	and op_p2 is not null
	; -- 50 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from france.spain_station 
		join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ) -- joining the two tables on the spain side
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3::NUMERIC AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	ope,
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
	; -- 2 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from france.spain_station 
		join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ),
ope_dens as (
		select *,
				case
				when op_nbeel = 0 then 0
				else round(cast(op_nbeel/op_surface as numeric), 3)
				end as density
		from ope
	     )
-- select * from ope_dens -- 972 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	density AS ba_quantity, -- I don't know the unit of the surface!
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	ope_dens, 
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
	and density > 0
	; -- 143 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.spain_fish add column fish_id serial;
alter table france.spain_fish add column ba_id uuid;

---- 		Check duplicates: Joining spain_fish and dbeel_dbeel_batch_fish_aspe by "ang_op_id" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.spain_fish a join france.spain_ope o on a.ang_op_id = o.op_id 	-- 2828 rows (where is_duplicate = FALSE : 2380 rows)
	join france.dbeel_electrofishing l on l.ob_id = o.spain_ob_id			-- 2363 rows
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe
select sum(op_nbeel) from france.spain_ope; 	-- 5423 eels
select count(*) from france.spain_fish; 	-- 3488 eels
-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	

begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from france.spain_station 
		join france.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     )
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	ope.spain_ob_id as ba_ob_id,
	cast(NULL as uuid) as ba_ba_id,
	spain_fish.fish_id 			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.spain_fish
	join ope
	on spain_fish.ang_op_id = ope.op_id	

	WHERE species.no_name='Anguilla anguilla'
	and stage.no_name='Yellow eel'
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and ope.is_duplicate = FALSE
	; -- 2363 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in gt6_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
with fish_from_spain as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 15) -- 2363 rows
--select * from fish_from_spain join france.spain_fish on fish_from_spain.fish_id = spain_fish.fish_id; -- 2363 rows
UPDATE france.spain_fish b
SET ba_id = fish_from_spain.ba_id
FROM fish_from_spain
WHERE fish_from_spain.fish_id = b.fish_id; -- 2363 rows
-- select * from france.spain_fish where ba_id is null; -- 1125 rows


---- 		Insert LENGTH (no_id = 39)
begin;
with spain_fish_extract as (
select * from france.spain_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM spain_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2363 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT (no_id = 42)
/* NOT INSERTED BECAUSE THE VALUE IS SOMETIMES STRANGE: EXAMPLE 1 !?!?
begin;
with spain_fish_extract as (
select * from france.spain_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM spain_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1587 rows
commit;
*/



--------------------------------------------------------------------------------------------
--  VALENCIA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to france schema from public
ALTER TABLE valencia_sta_ope
    SET SCHEMA france;

ALTER TABLE france.valencia_sta_ope RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON france.valencia_sta_ope
  USING gist
  (geom);
  
/* france.valencia_sta_ope has several problems:

-- 1. There isn't an ID to identify the stations:
select distinct on (op_sta_id) * from france.valencia_sta_ope order by op_sta_id; -- 197 rows = OPERATIONS (NOT code of stations)
ALTER TABLE france.valencia_sta_ope RENAME COLUMN op_sta_id TO op_id;

select distinct on (geom) * from france.valencia_sta_ope; -- 150 (total: 197 rows)

-- 	Solution: create a table for stations
-- 	For that, the id's ('VAL_') created in the SIBIC.R script is deleted because it's corresponded to operations
	ALTER TABLE france.valencia_sta_ope DROP COLUMN id;
-- 	The table valencia_station is created taken into account the geometry of operations
	CREATE TABLE france.valencia_station AS
		SELECT distinct on (geom) observer, place_name, water_body, basin, town, province, geom from france.valencia_sta_ope; -- 112 rows
-- 	Adding the ID: dbeel_france_electrofishing.sql script (241 line)
--	Insert the ID of the station in valencia_sta_ope table:
	ALTER TABLE france.valencia_sta_ope ADD COLUMN id_station text;
	UPDATE france.valencia_sta_ope set id_station = id from france.valencia_station where valencia_station.geom = valencia_sta_ope.geom; -- 197 rowws
*/

-- Reprojection

select st_srid(geom) from france.valencia_station; -- 3035 (SELECT Find_SRID doesn't work)

select addgeometrycolumn('france','valencia_station','geom_reproj',3035,'POINT',2);
update france.valencia_station set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id,
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.valencia_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by s.geom, distance
)sub )sub2
where sub2.id= valencia_station.id; -- 140 rows

CREATE INDEX 
  ON france.valencia_station
  USING gist
  (geom_reproj);

select count(distinct geom_reproj) from france.valencia_station; -- 132 rows (total: 197 rows)

-- to store the link for dbeel
-- ALTER TABLE france.valencia_station DROP COLUMN dbeel_op_id;
ALTER TABLE france.valencia_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (VAL_) from dbeel_france_electrofishing.sql script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.valencia_station AS sp1, france.valencia_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 internal duplicates

INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('VAERSA'); --TODO: TO BE MODIFIED (et_id = 26)
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Nacho Ferrando Belloch', et_id FROM dbeel.establishment WHERE et_establishment_name = 'VAERSA'; --TODO: TO BE MODIFIED (dp_id = 25: 'Nacho Ferrando Belloch')

-- duplicate with data already in dbeel
-- we choose the closest station to join with

WITH 
projection_valencia AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.valencia_station g
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_valencia AS (
SELECT distinct on (id) * from projection_valencia
)
--SELECT * from closest_valencia; -- 5 rows
UPDATE france.valencia_station SET dbeel_op_id = op_id
	FROM closest_valencia c
	WHERE c.id=valencia_station.id; -- 5 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM france.dbeel_station_aspe where op_gis_layername='VAERSA'; -- 0 rows
-- select * from france.dbeel_station_aspe limit 10;
begin;
INSERT INTO france.dbeel_station_aspe(
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
	'VAERSA' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	place_name as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	NULL as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	basin as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.valencia_station
	where dbeel_op_id is null
	; -- 145 lines
commit;

-- We put back the op_id into the source table
update france.valencia_station set dbeel_op_id=op_id from france.dbeel_station_aspe where id = op_gislocation; -- 145 rows


---------------------------------
-- INSERTING VALENCIA OPERATIONS
---------------------------------
-- select * from france.valencia_sta_ope; -- 197 rows
-- select * from france.valencia_station; -- 150 rows

---- Add dbeel_ob_id in valencia operation table
ALTER TABLE france.valencia_sta_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with v_station_operation as(
select valencia_station.dbeel_op_id, valencia_station.id, valencia_sta_ope.* from france.valencia_station 
	join france.valencia_sta_ope on valencia_station.id = valencia_sta_ope.id_station -- 197 rows
)-- joining the two tables on the valencia side
select * from v_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 15 rows (but the date it is not the same)


-- Checking the duplicates for year: real duplicates
with v_station_operation as(
select valencia_station.dbeel_op_id, valencia_station.id, valencia_sta_ope.* from france.valencia_station 
	join france.valencia_sta_ope on valencia_station.id = valencia_sta_ope.id_station -- 197 rows
)-- joining the two tables on the valencia side
select * from v_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 0 rows from Valencia

-- for those lines where there is a join, add ob_id in valencia tables
ALTER TABLE france.valencia_sta_ope ADD COLUMN is_duplicate boolean;
update france.valencia_sta_ope set is_duplicate = NULL; -- 197 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- No duplicates!

---- STEP 2: integrate all new data operations and then fish....there are no longer any duplicates

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length and width)
select count(distinct (op_sta_id, op_dat)) from france.valencia_sta_ope; -- 197 operations

--		There are 3 operations that are repeated with different number of eels catched
select distinct (id_station,op_dat), count(*) from france.valencia_sta_ope group by (id_station,op_dat) having count(*) > 1; -- 3 rows
/*
begin;
WITH uniques AS
    (SELECT DISTINCT ON (id_station,op_dat) * FROM france.valencia_sta_ope) -- 193 rows
DELETE FROM france.valencia_sta_ope WHERE france.valencia_sta_ope.op_sta_id NOT IN (SELECT op_sta_id FROM uniques); -- 4rows
commit;
*/
-- 		The id of france.valencia_sta_ope is 'op_sta_id', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'val_ob_id' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table france.valencia_sta_ope add column val_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO france.dbeel_electrofishing (
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
	val_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id,
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(length * mean_width_m) AS ef_wetted_area, 
	length AS ef_fished_length,
	mean_width_m AS ef_fished_width,
	1 AS ef_nbpas, -- Not info about that, by default: 1
	dbeel_op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.valencia_station
	join
		france.valencia_sta_ope on valencia_sta_ope.id_station = valencia_station.id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Nacho Ferrando Belloch'
	ANd dp_et_id = 26
	; -- 193 rows
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.valencia_sta_ope there is only information about nb of eels (and total nb of species)
update france.valencia_sta_ope set nb_eels = 0 where nb_eels is null; -- 67 rows

begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	val_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.valencia_sta_ope,
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
	; -- 193 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	val_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.valencia_sta_ope,
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
	; -- 193 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with dens as (
	      select round(cast(nb_eels/(length*mean_width_m) as numeric),3) as density, * from france.valencia_sta_ope where nb_eels > 0
	      )
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	density AS ba_quantity, -- ind/m2
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	val_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	dens, 
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
	; -- 125 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.valencia_fish add column fish_id serial;
alter table france.valencia_fish add column ba_id uuid; -- We can't generate hte ba_id for the whole table because there are more than 200 000 rows!

-- There are individuals without total length but furcal length appears (as a proxy, in comments it's indicated)
update france.valencia_fish set tl = fl where tl is null -- 1257 rows
select count(*) from france.valencia_fish where tl is null; -- 749
--DELETE FROM france.valencia_fish where tl is null; -- 749 rows

---- 		Check duplicates: Joining valencia_fish and dbeel_dbeel_batch_fish_aspe by "ang_sta" and "ob_id" (to join "ob_id" we need to go through different tables)
select count(*) from france.valencia_fish a join france.valencia_sta_ope o on a.ang_sta_id = o.op_sta_id -- 2208 rows (3435 TOTAL)

select * from france.valencia_fish a join france.valencia_sta_ope o on a.ang_sta_id = o.op_sta_id
	join france.dbeel_electrofishing l on l.ob_id = o.val_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows

-- There are 1594 fish that miss because of the id of the operation, which doesn't match!
----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	valencia_sta_ope.val_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	valencia_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.valencia_fish
	join france.valencia_sta_ope
	on valencia_fish.ang_sta_id = valencia_sta_ope.op_sta_id

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	and stage.no_name='Yellow eel'
	AND value_type.no_name='Raw data or Individual data'
	; -- 2 208 rows
commit;

--TO DO
---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in valencia_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
with fish_from_valencia as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 25) -- 2208 rows
--select * from fish_from_valencia join france.valencia_fish on fish_from_valencia.fish_id = valencia_fish.fish_id; -- 2208 rows
UPDATE france.valencia_fish b
SET ba_id = fish_from_valencia.ba_id
FROM fish_from_valencia
WHERE fish_from_valencia.fish_id = b.fish_id; -- 2208 rows
-- select * from france.valencia_fish where ba_id is null; -- 1227 rows


---- 		Insert LENGTH (no_id = 39)
begin;
with valencia_fish_extract as (
select * from france.valencia_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	tl AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE tl > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2208 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with valencia_fish_extract as (
select * from france.valencia_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1475 rows
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
with valencia_fish_extract as (
select * from france.valencia_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	diam_vert AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1018 rows
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
with valencia_fish_extract as (
select * from france.valencia_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	diam_horiz AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE diam_horiz is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1018 rows
commit;


---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
with valencia_fish_extract as (
select * from france.valencia_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	pect_fin AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE pect_fin is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1017 rows
commit;



--------------------------------------------------------------------------------------------
--  GT6: reprojection and stations in 2018/2019
--------------------------------------------------------------------------------------------

-- Move the teble to france schema from public
ALTER TABLE gt6_station
    SET SCHEMA france;

ALTER TABLE france.gt6_station RENAME COLUMN geometry TO geom;

select * from france.gt6_station; -- 99 rows

CREATE INDEX 
  ON france.gt6_station
  USING gist
  (geom);
  
-- Reprojection

select st_srid(geom) from france.gt6_station; -- 3035 (SELECT Find_SRID doesn't work)

select addgeometrycolumn('france','gt6_station','geom_reproj',3035,'POINT',2);
update france.gt6_station set geom_reproj = sub2.geom_reproj from (
select distinct on ("sta_cod") "sta_cod", geom_reproj,distance from(
select
"sta_cod", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.gt6_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by "sta_cod", distance
)sub )sub2
where sub2."sta_cod"= gt6_station."sta_cod"; -- 67 rows (98 total)

CREATE INDEX 
  ON france.gt6_station
  USING gist
  (geom_reproj);



-- to store the link for dbeel
ALTER TABLE france.gt6_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (GT6_) from SIBIC.R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.gt6_station AS sp1, france.gt6_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- GT6_92 and TG6_97 internal duplicates


-- add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('GT6'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Isabel Domingos', et_id FROM dbeel.establishment WHERE et_establishment_name = 'GT6'
; --TODO: TO BE MODIFIED


-- duplicate with data already in dbeel, there is one internal duplicate in dbeel that we ignore
-- we choose the closest station to join with

--update france.gt6_station set dbeel_op_id IS NULL;
WITH 
projection_gt6 AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.gt6_station g
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_gt6 AS (
SELECT distinct on (id) * from projection_gt6
)
--SELECT * from closest_gt6; -- 16 rows
UPDATE france.gt6_station SET dbeel_op_id = op_id
	FROM closest_gt6 c
	WHERE c.id=gt6_station.id; -- 16 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)

--SELECT Find_SRID('france', 'dbeel_station', 'the_geom'); --3035
-- SELECT * from france.dbeel_station_aspe limit 10;
-- select * from france.gt6_station limit 10

begin;
INSERT INTO france.dbeel_station_aspe(
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
	from france.gt6_station 
	where dbeel_op_id is null -- as those lines are not reprojected
	; -- 83 rows
COMMIT;

-- We put back the op_id into the source table
begin;
With jointure as (
SELECT * from france.dbeel_station_aspe JOIN
france.gt6_station ON op_gislocation=id)
update france.gt6_station set dbeel_op_id=op_id from jointure where jointure.id = gt6_station.id; -- 83 rows
commit;


---------------------------------------
-- INSERTING GT6 OPERATIONS 2018/2019
---------------------------------------

-- select * from france.gt6_ope; -- 98 rows
-- select * from france.gt6_station;
delete from france.gt6_ope where op_cod in ('gro_50001','gro_60001','gro_160001','gro_190001'); -- 4 empty lines, 94 rows

---- Add dbeel_ob_id in guipuz_operation table
ALTER TABLE france.gt6_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with g_station_operation as(
select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from france.gt6_station 
	join france.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
)-- joining the two tables on the gt6 side
select * from g_station_operation JOIN france.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 231 rows (but the date it is not the same)


-- Checking the duplicates for year: real duplicates
with g_station_operation as(
select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from france.gt6_station 
	join france.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
)-- joining the two tables on the gt6 side
select * from g_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 15 rows from Gipuzkoa

-- for those lines where there is a join, add ob_id in gt6 tables
ALTER TABLE france.gt6_ope ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from france.gt6_station 
	join france.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)

--select * from op_duplicates; -- 15 rows
update france.gt6_ope set is_duplicate = TRUE where op_cod in (select op_cod from op_duplicates); -- 15rows

-- We search into the dbeel the duplicated operations. We will supress them as we have better information from GT6:
-- We have to do three times for different tables because we have on delete restrict clause in the table:
begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from france.gt6_station 
	join france.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	),

fish_duplicates as (
	select * from france.dbeel_dbeel_batch_fish_aspe where ba_ob_id in (select ob_id from op_duplicates)
	)

--select * from france.dbeel_mensurationindiv_biol_charac where bc_ba_id in (select ba_id from fish_duplicates);
delete from france.dbeel_mensurationindiv_biol_charac where bc_ba_id in (select ba_id from fish_duplicates); -- 1681 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from france.gt6_station 
	join france.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from france.dbeel_dbeel_batch_fish_aspe where ba_ob_id in (select ob_id from op_duplicates);
delete from france.dbeel_dbeel_batch_fish_aspe where ba_ob_id in (select ob_id from op_duplicates); -- 816 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from france.gt6_station 
	join france.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from france.dbeel_batch_ope where ba_ob_id in (select ob_id from op_duplicates); -- 60 rows
delete from france.dbeel_batch_ope where ba_ob_id in (select ob_id from op_duplicates); -- 60 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from france.gt6_station 
	join france.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from france.dbeel_electrofishing where ob_id in (select ob_id from op_duplicates); -- 15 rows
delete from france.dbeel_electrofishing where ob_id in (select ob_id from op_duplicates); -- 15 rows
commit;

---- STEP 2: integrate all new data operations and then fish....there are no longer any duplicates

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (op_cod, op_dat)) from france.gt6_ope; -- 94 operations
-- select * from france.dbeel_station_aspe where op_gis_layername = ''; --  stations

-- 		The id of france.gt6_ope is 'op_cod', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'gt6_ob_id' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table france.gt6_ope add column gt6_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO france.dbeel_electrofishing (
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
		france.gt6_station
	join
		france.gt6_ope on gt6_ope.op_sta_id = gt6_station.sta_cod
		
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
-- 			In france.gt6_ope there is only information about eels
begin;
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope,
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
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope,
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
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope,
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
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope,
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
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope, 
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


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.gt6_fish add column fish_id serial;
alter table france.gt6_fish add column ba_id uuid; -- We can't generate hte ba_id for the whole table because there are more than 200 000 rows!

---- 		Check duplicates: Joining gt6_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.gt6_fish a join france.gt6_ope o on a.op_cod = o.op_cod
	join france.dbeel_electrofishing l on l.ob_id = o.gt6_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	

begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
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

	france.gt6_fish
	join france.gt6_ope
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
select distinct op_gislocation from france.dbeel_station_aspe;

with fish_from_gt6 as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 20) -- 4463 rows
--select * from fish_from_gt6 join france.gt6_fish on fish_from_gt6.fish_id = gt6_fish.fish_id; -- 4463 rows
UPDATE france.gt6_fish b
SET ba_id = fish_from_gt6.ba_id
FROM fish_from_gt6
WHERE fish_from_gt6.fish_id = b.fish_id; -- 4463 rows
-- select * from france.gt6_fish where ba_id is null; -- 3 rows


---- 		Insert LENGTH (no_id = 39)
-- with gt6_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from france.gt6e_fish order by locationid),
begin;
with gt6_fish_extract as (
select * from france.gt6_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
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
select * from france.gt6_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
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
select * from france.gt6_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
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
select * from france.gt6_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
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
select * from france.gt6_fish where ba_id is not null)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
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
alter table france.gt6_fish
alter column ang_neuromast
set data type boolean
using case
    when ang_neuromast = 'TRUE' then true
    when ang_neuromast = 'FALSE' then false
    else null
end;

/* postgresql stops working when I run this query:
alter table france.gt6_fish
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
select * from france.gt6_fish where ba_id is not null and ang_neuromast is not null) -- 3832
INSERT INTO france.dbeel_mensurationindiv_biol_charac
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
alter table france.gt6_fish
alter column ang_contrast
set data type boolean
using case
    when ang_contrast = 'TRUE' then true
    when ang_contrast = 'FALSE' then false
    else null
end;

begin;
with gt6_fish_extract as (
select * from france.gt6_fish where ba_id is not null and ang_contrast is not null) -- 4037
INSERT INTO france.dbeel_mensurationindiv_biol_charac
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


--------------------------------------------------------------------------------------------
--  GT6 II: reprojection and stations in 2019/2020
--------------------------------------------------------------------------------------------

-- Move the teble to france schema from public
ALTER TABLE gt6_station2
    SET SCHEMA france;

ALTER TABLE france.gt6_station2 RENAME COLUMN geometry TO geom;

select * from france.gt6_station2; -- 13 rows

CREATE INDEX 
  ON france.gt6_station2
  USING gist
  (geom);
  
-- Reprojection

select st_srid(geom) from france.gt6_station2; -- 3035 (SELECT Find_SRID doesn't work)

select addgeometrycolumn('france','gt6_station2','geom_reproj',3035,'POINT',2);
update france.gt6_station2 set geom_reproj = sub2.geom_reproj from (
select distinct on ("sta_cod") "sta_cod", geom_reproj,distance from(
select
"sta_cod", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from france.gt6_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by "sta_cod", distance
)sub )sub2
where sub2."sta_cod"= gt6_station."sta_cod"; -- 67 rows (98 total)

CREATE INDEX 
  ON france.gt6_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE france.gt6_station2 ADD COLUMN dbeel_op_id uuid;
 
-- internal duplicate here (added id (GT6_) from SIBIC.R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM france.gt6_station2 AS sp1, france.gt6_station2 AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 internal duplicates


-- Establishment and data provider
-- select * from dbeel.establishment; -- et_id = 22
-- select * from dbeel.data_provider; -- dp_id = 20 (dp_et_id = 22)


--update france.gt6_station set dbeel_op_id IS NULL;
WITH 
projection_gt6 AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM france.gt6_station2 g
        JOIN  france.dbeel_station_aspe d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_gt6 AS (
SELECT distinct on (id) * from projection_gt6
)
--SELECT * from closest_gt6; -- 1 rows
UPDATE france.gt6_station2 SET dbeel_op_id = op_id
	FROM closest_gt6 c
	WHERE c.id=gt6_station2.id; -- 1 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)

-- SELECT * from france.dbeel_station_aspe limit 10;
-- select * from france.gt6_station2; -- 13 rows

begin;
INSERT INTO france.dbeel_station_aspe(
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
	SELECT uuid_generate_v4() AS op_id,
	'3035' AS op_gis_systemname,
	'GT6' AS op_gis_layername, -- GT6 or sta_source (not correspond with the information in dbeel.establishment)
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS op_op_id,
	geom as the_geom, 	
	NULL as locationid,
	case when sta_source in ('fcup_ciimar') then 'PT'
	WHEN sta_source in ('udg', 'AZTI') then 'ES' END as country,
	sta_cod as place_classification,
	NULL as codhb,	
	null as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from france.gt6_station2 
	where dbeel_op_id is null -- as those lines are not reprojected
	; -- 12 rows
COMMIT;

-- We put back the op_id into the source table
With jointure as (
SELECT * from france.dbeel_station_aspe JOIN
france.gt6_station2 ON op_gislocation=id)
update france.gt6_station2 set dbeel_op_id=op_id from jointure where jointure.id = gt6_station2.id; -- 12 rows


-- In GT6_station2 there is only the NEW STATIONS added, but we need to have all the stations to insert the operations
select count(*) from france.gt6_station; -- 99 rows

begin;
INSERT INTO france.gt6_station2 (sta_id, sta_source, sta_layername, sta_cod, sta_lib, srid, id, geom, geom_reproj, dbeel_op_id)
SELECT cast(sta_id as text), sta_source, sta_layername, sta_cod, sta_lib, srid, id, geom, geom_reproj, dbeel_op_id FROM france.gt6_station; -- 99 rows
commit;

-----------------------------------------
-- INSERTING GT6 II OPERATIONS 2019/2020
-----------------------------------------

-- select * from france.gt6_ope2; -- 107 rows
-- select * from france.gt6_station2; -- 13 rows

---- Add dbeel_ob_id in guipuz_operation table
ALTER TABLE france.gt6_ope2 ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates for year: real duplicates
with g_station_operation as(
select gt6_station2.dbeel_op_id, gt6_station2.id, gt6_ope2.* from france.gt6_station2 
	join france.gt6_ope2 on gt6_station2.sta_cod = gt6_ope2.op_sta_id -- 106 rows
)-- joining the two tables on the gt6 side
select * from g_station_operation JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 10 rows from Minho

-- Duplicates are deleted from the table because they are the operations from the previous year that are already included in the dbeel
-- Do the same in fish_table!!!
with duplicates as (
	select gt6_station2.dbeel_op_id, gt6_station2.id, gt6_ope2.* from france.gt6_station2
	join france.gt6_ope2 on gt6_station2.sta_cod = gt6_ope2.op_sta_id -- 106 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)

--select * from op_duplicates; -- 10 rows
delete from france.gt6_ope2 where op_cod in (select op_cod from op_duplicates); -- 10 rows


---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- It's the same information they sent us last year (Carlos Antunes)

---- STEP 2: integrate all new data operations and then fish....be careful with duplicates
select * from france.gt6_ope2; -- 97 rows
-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (op_cod, op_dat)) from france.gt6_ope2; -- 97 operations
-- select * from france.dbeel_station_aspe where op_gis_layername = ''; --  stations

-- 		The id of france.gt6_ope2 is 'op_cod', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'gt6_ob_id' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table france.gt6_ope2 add column gt6_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO france.dbeel_electrofishing (
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
	data_provider.dp_id AS ob_dp_id,
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
		france.gt6_station2
	join
		france.gt6_ope2 on gt6_ope2.op_sta_id = gt6_station2.sta_cod
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Isabel Domingos'
	AND dp_et_id = 22 -- two lines for Isabel Domingos (fcul and GT6)
	; -- 96 rows
commit;
rollback;

-- One ope is not inserted, because there is a mistake in the id station (from TER)
update france.gt6_ope2 set op_sta_id = 'TER12' where gt6_ob_id = '74834426-ef98-4df6-9d29-f3bd1522ef8e';
-- This row is imported into dbeel_electrofishing!

-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In france.gt6_ope2 there is only information about eels
begin;
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope2,
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
	; -- 97 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope2,
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
	; -- 97 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope2,
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
	and op_p2 is not null
	; -- 93 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope2,
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
	; -- 11 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO france.dbeel_batch_ope
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
	france.gt6_ope2, 
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
	; -- 97 rows
commit;


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
/* Delete fish from the previous year (Minho)
with is_2020 as (select fi.* from france.gt6_ope2 op join france.gt6_fish2 fi on op.op_cod = fi.op_cod)
delete from france.gt6_fish2 where op_cod not in (select op_cod from is_2020); -- 211 rows
*/

---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table france.gt6_fish2 add column fish_id serial;
alter table france.gt6_fish2 add column ba_id uuid;

---- 		Check duplicates: Joining gt6_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from france.gt6_fish2 a join france.gt6_ope2 o on a.op_cod = o.op_cod
	join france.dbeel_electrofishing l on l.ob_id = o.gt6_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	

begin;	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
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
	gt6_ope2.gt6_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	gt6_fish2.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.gt6_fish2
	join france.gt6_ope2
	on gt6_fish2.op_cod = gt6_ope2.op_cod	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 3 848 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in gt6_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from france.dbeel_station_aspe;

with fish_from_gt6 as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	where ob_dp_id = 20), -- 8311 rows
final_select as (
	select * from fish_from_gt6 join france.gt6_ope2 on fish_from_gt6.ob_id = gt6_ope2.gt6_ob_id
	join france.gt6_fish2 on fish_from_gt6.fish_id = gt6_fish2.fish_id
	) -- 3848 rows
UPDATE france.gt6_fish2 b
SET ba_id = fish_from_gt6.ba_id
FROM fish_from_gt6
WHERE fish_from_gt6.fish_id = b.fish_id; -- 3848 rows


---- 		Insert LENGTH (no_id = 39)
-- with gt6_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from france.gt6e_fish order by locationid),
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM france.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3848 rows
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM france.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3848 rows
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM france.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1902 rows
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM france.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz > 0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 369 rows
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM france.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect > 0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 370 rows
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" from amber_portugal is text, it must be converted into boolean:
alter table france.gt6_fish2
alter column ang_neuromast
set data type boolean
using case
    when ang_neuromast = 'TRUE' then true
    when ang_neuromast = 'FALSE' then false
    else null
end;

begin;
with gt6_fish_extract as (
select * from france.gt6_fish2 where ba_id is not null and ang_neuromast is not null) -- 1382 rows
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast = FALSE THEN 0
	     WHEN ang_neuromast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1382 rows
commit;


---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" from gt6_fish is text, it must be converted into boolean:
alter table france.gt6_fish2
alter column ang_contrast
set data type boolean
using case
    when ang_contrast = 'TRUE' then true
    when ang_contrast = 'FALSE' then false
    else null
end;

begin;
with gt6_fish_extract as (
select * from france.gt6_fish2 where ba_id is not null and ang_contrast is not null) -- 3448
INSERT INTO france.dbeel_mensurationindiv_biol_charac
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
; -- 3448 rows
commit;



/*-------------------------------
	DATABASE CORRECTION
*/-------------------------------

--------------------------------------------------------------------------------------------
-- In pb_totalnumber.csv there are 112 ob_id with problem in the number of catchs:
-- missing catches are inserted and tables are corrected when necessary
--------------------------------------------------------------------------------------------

-- VAERSA Valencia
select * from france.valencia_sta_ope where val_ob_id = '89d1166e-af61-41fd-90e9-f9b6e6a965f3'; -- 38 eels 
select * from france.valencia_fish where ang_sta_id = 1998; -- 39 eels

begin;
with correct as		(
			select * from france.dbeel_batch_ope where ba_ob_id = '89d1166e-af61-41fd-90e9-f9b6e6a965f3' and 
				(ba_no_biological_characteristic_type = 47 or ba_no_biological_characteristic_type = 231)
			)
update france.dbeel_batch_ope set ba_quantity = 39 from correct where dbeel_batch_ope.ba_id = correct.ba_id
commit;

-- Galicia
select * from france.galicia_ope where galicia_ob_id = '001b158a-94da-4c4c-be17-84a160ea7e69'; -- 1 eel in pass 3
select * from france.dbeel_batch_ope where ba_ob_id = '001b158a-94da-4c4c-be17-84a160ea7e69'; -- 1 eel in pass 3
select * from france.galicia_fish where cod_ope = 'INVGEN_0893' -- 1 eel in pass 2, 1 eel in pass 3

--	Nb total
begin;
with sum_eels as 	(
			select count(ba_id), cod_ope from france.galicia_fish where species = 'Anguila' group by cod_ope order by cod_ope -- 3699 rows
			),
 eels_tot as 		(
			select * from france.galicia_ope join sum_eels on galicia_ope.cod_ope = sum_eels.cod_ope where 
				count > (coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0))
			)
--select * from eels_tot  -- 78 rows
update france.dbeel_batch_ope set ba_quantity = count from eels_tot where dbeel_batch_ope.ba_ob_id = eels_tot.galicia_ob_id and ba_no_biological_characteristic_type = 47; -- 78 rows
commit;

--	Run2
begin;
with sum_eels as 	(
			select count(ba_id), cod_ope, op_pass from france.galicia_fish where species = 'Anguila' group by (cod_ope, op_pass) order by cod_ope -- 3346 rows
			),
 eels_p2 as 		(
			select * from france.galicia_ope join sum_eels on galicia_ope.cod_ope = sum_eels.cod_ope where count > coalesce(run2_ang, 0) and op_pass = 2 -- 78 rows
			)
--select * from eels_p2 -- 78 rows
update france.dbeel_batch_ope set ba_quantity = count from eels_p2 where dbeel_batch_ope.ba_ob_id = eels_p2.galicia_ob_id and ba_no_biological_characteristic_type = 232; -- 78 rows
commit;

-- Gipuzkoa
select * from france.guipuz_ope where guipuz_ob_id = '00aec661-2f9c-4759-9e2e-811d086e79f8' -- 500 eels in total
select * from france.dbeel_batch_ope where ba_ob_id = '00aec661-2f9c-4759-9e2e-811d086e79f8' -- 431 eels in total
select * from france.guipuz_fish where sampling = 'PA2005034' -- 69 eels in pass 3

ALTER TABLE france.guipuz_ope ADD COLUMN run3_ang integer;
ALTER TABLE france.guipuz_ope ADD COLUMN run3_oth integer;

-- 	Add pass 3 in guipuz_ope table
with run3_anguila as (
select
sampling as sampling,
sum("N") as run3_anguila
from france.guipuz_fish
where species='Anguilla anguilla' and pass = 3 group by sampling), -- 12 rows

run3_other as (
select
sampling as sampling5,
sum("N") as run3_other
from france.guipuz_fish
where species!='Anguilla anguilla' and pass = 3 group by sampling),

electro as (select coalesce(sampling, sampling5) as sampling, run3_anguila, run3_other from run3_anguila 
	FULL OUTER JOIN run3_other on sampling = sampling5
)
--select * from electro; -- 12 rows
update france.guipuz_ope
set (run3_ang, run3_oth) = (run3_anguila, run3_other) from electro where guipuz_ope.sampling = electro.sampling; -- 12 rows

--	Update nb of pass in electrofishing
update france.dbeel_electrofishing set ef_nbpas = 3 from france.guipuz_ope where dbeel_electrofishing.ob_id = guipuz_ope.guipuz_ob_id; -- 1302 rows

-- 	Update total number of catches in dbeel_batch_ope
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang, run3_ang
from france.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from france.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)
--select * from electrofishing_temp where guipuz_ob_id != '655cab5c-aa9d-475e-99a3-8f3a0605fc02' order by sampling ; -- 1316 rows
update france.dbeel_batch_ope set ba_quantity = electrofishing_temp.run1+electrofishing_temp.run2+electrofishing_temp.run3 from electrofishing_temp 
	where dbeel_batch_ope.ba_ob_id = electrofishing_temp.guipuz_ob_id and ba_no_biological_characteristic_type = 47; -- 1302 rows
commit;

-- 	Update op_p2 of catches in dbeel_batch_ope
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang, run3_ang
from france.guipuz_ope where is_sibic_duplicate = FALSE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from france.guipuz_ope),

electrofishing as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling),

electrofishing_temp as (
select electrofishing.* from electrofishing join france.dbeel_electrofishing on guipuz_ob_id = ob_id
)
--select * from electrofishing_temp
update france.dbeel_batch_ope set ba_quantity = electrofishing_temp.run2 from electrofishing_temp 
	where dbeel_batch_ope.ba_ob_id = electrofishing_temp.guipuz_ob_id and ba_no_biological_characteristic_type = 232; -- 1302 rows
commit;

-- 	op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang, run3_ang
from france.guipuz_ope where is_sibic_duplicate = FALSE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from france.guipuz_ope),

electrofishing as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling),

electrofishing_temp as (
select electrofishing.* from electrofishing join france.dbeel_electrofishing on guipuz_ob_id = ob_id
)
--select * from electrofishing_temp; -- 1302 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
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
	; -- 1302 rows
commit;

--	Particular cases:
select * from france.guipuz_ope where guipuz_ob_id = '655cab5c-aa9d-475e-99a3-8f3a0605fc02' -- 6 eels in total (5 in pass 1 and 1 in pass 2)
select * from france.guipuz_fish where sampling = 'PA2009009' and species = 'Anguilla anguilla' -- 1 eel in pass 2
select * from france.dbeel_batch_ope where ba_ob_id = 'afa62a60-48d1-4d13-90fd-f9a3ab0081ca'
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'afa62a60-48d1-4d13-90fd-f9a3ab0081ca' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 5 where dbeel_batch_ope.ba_ob_id = 'afa62a60-48d1-4d13-90fd-f9a3ab0081ca' and ba_no_biological_characteristic_type = 231;
update france.dbeel_batch_ope set ba_quantity = 6 where dbeel_batch_ope.ba_ob_id = 'afa62a60-48d1-4d13-90fd-f9a3ab0081ca' and ba_no_biological_characteristic_type = 47;

select * from france.guipuz_ope where guipuz_ob_id = 'ab5507dc-8fa6-4704-b0e1-58a4fe47bce2';
select * from france.guipuz_fish where sampling = 'PB2001018' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = 'ab5507dc-8fa6-4704-b0e1-58a4fe47bce2';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'ab5507dc-8fa6-4704-b0e1-58a4fe47bce2' and ba_no_biological_characteristic_type = 232;

select * from france.guipuz_ope where guipuz_ob_id = 'a25aed01-34db-4de4-b095-8ee8e5f02972';
select * from france.guipuz_fish where sampling = 'PB1996020' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = 'a25aed01-34db-4de4-b095-8ee8e5f02972';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'a25aed01-34db-4de4-b095-8ee8e5f02972' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'a25aed01-34db-4de4-b095-8ee8e5f02972' and ba_no_biological_characteristic_type = 47;

select * from france.guipuz_ope where guipuz_ob_id = '7a4516ce-4ca2-4dcf-b041-2685de73fc2d';
select * from france.guipuz_fish where sampling = 'PB2003005' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '7a4516ce-4ca2-4dcf-b041-2685de73fc2d';
update france.dbeel_batch_ope set ba_quantity = 2 where dbeel_batch_ope.ba_ob_id = '7a4516ce-4ca2-4dcf-b041-2685de73fc2d' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 2 where dbeel_batch_ope.ba_ob_id = '7a4516ce-4ca2-4dcf-b041-2685de73fc2d' and ba_no_biological_characteristic_type = 47;

select * from france.guipuz_ope where guipuz_ob_id = '6823ab79-5e48-4c61-8c0a-9f9b900cb81d';
select * from france.guipuz_fish where sampling = 'PA2017021' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '6823ab79-5e48-4c61-8c0a-9f9b900cb81d';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '6823ab79-5e48-4c61-8c0a-9f9b900cb81d' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '6823ab79-5e48-4c61-8c0a-9f9b900cb81d' and ba_no_biological_characteristic_type = 47;

select * from france.guipuz_ope where guipuz_ob_id = '5be8940c-c829-4bd1-98ac-687be315895e';
select * from france.guipuz_fish where sampling = 'PB2007002' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '5be8940c-c829-4bd1-98ac-687be315895e';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '5be8940c-c829-4bd1-98ac-687be315895e' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '5be8940c-c829-4bd1-98ac-687be315895e' and ba_no_biological_characteristic_type = 47; 

select * from france.guipuz_ope where guipuz_ob_id = '46be4e1c-871d-41b4-bd0c-ad739389d1cc';
select * from france.guipuz_fish where sampling = 'PB1996012' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '46be4e1c-871d-41b4-bd0c-ad739389d1cc';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '46be4e1c-871d-41b4-bd0c-ad739389d1cc' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '46be4e1c-871d-41b4-bd0c-ad739389d1cc' and ba_no_biological_characteristic_type = 47; 

select * from france.guipuz_ope where guipuz_ob_id = '2e8163bf-7a78-484b-873c-c04fdd187719';
select * from france.guipuz_fish where sampling = 'PB2004024' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '2e8163bf-7a78-484b-873c-c04fdd187719';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '2e8163bf-7a78-484b-873c-c04fdd187719' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '2e8163bf-7a78-484b-873c-c04fdd187719' and ba_no_biological_characteristic_type = 47; 

select * from france.guipuz_ope where guipuz_ob_id = '271192bd-0587-48a3-a629-501f3cb051c7';
select * from france.guipuz_fish where sampling = 'PB2001007' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '271192bd-0587-48a3-a629-501f3cb051c7';
update france.dbeel_batch_ope set ba_quantity = 2 where dbeel_batch_ope.ba_ob_id = '271192bd-0587-48a3-a629-501f3cb051c7' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 2 where dbeel_batch_ope.ba_ob_id = '271192bd-0587-48a3-a629-501f3cb051c7' and ba_no_biological_characteristic_type = 47; 

select * from france.guipuz_ope where guipuz_ob_id = '24e64f2c-7da6-4a7d-b7b3-1eebff0dbe4f';
select * from france.guipuz_fish where sampling = 'PA2007012' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '24e64f2c-7da6-4a7d-b7b3-1eebff0dbe4f';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '24e64f2c-7da6-4a7d-b7b3-1eebff0dbe4f' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '24e64f2c-7da6-4a7d-b7b3-1eebff0dbe4f' and ba_no_biological_characteristic_type = 47; 

select * from france.guipuz_ope where guipuz_ob_id = '199c3205-0325-4271-bd73-300575ed890f';
select * from france.guipuz_fish where sampling = 'PB2008007' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '199c3205-0325-4271-bd73-300575ed890f';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '199c3205-0325-4271-bd73-300575ed890f' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '199c3205-0325-4271-bd73-300575ed890f' and ba_no_biological_characteristic_type = 47; 

select * from france.guipuz_ope where guipuz_ob_id = '1874032c-ab26-4594-b1dd-eb11c7cb7b4b';
select * from france.guipuz_fish where sampling = 'PB1999017' and species = 'Anguilla anguilla';
select * from france.dbeel_batch_ope where ba_ob_id = '1874032c-ab26-4594-b1dd-eb11c7cb7b4b';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '1874032c-ab26-4594-b1dd-eb11c7cb7b4b' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '1874032c-ab26-4594-b1dd-eb11c7cb7b4b' and ba_no_biological_characteristic_type = 47; 

-- GT6
select * from france.gt6_ope where gt6_ob_id = '08d0e4a3-c58e-49c4-9685-c972f7e10a7f'; -- 15 eels in pass 1
select * from france.gt6_fish where op_cod = 'ter_30001'; -- 282 eel in pass 1
select * from france.dbeel_batch_ope where ba_ob_id = '08d0e4a3-c58e-49c4-9685-c972f7e10a7f'; -- 15 eels in pass 1
update france.dbeel_batch_ope set ba_quantity = 282 where dbeel_batch_ope.ba_ob_id = '08d0e4a3-c58e-49c4-9685-c972f7e10a7f' and ba_no_biological_characteristic_type = 231;
update france.dbeel_batch_ope set ba_quantity = 282 where dbeel_batch_ope.ba_ob_id = '08d0e4a3-c58e-49c4-9685-c972f7e10a7f' and ba_no_biological_characteristic_type = 47; 

-- Asturias
select * from france.asturias_ope where asturias_ob_id = '000ba411-c04a-4332-bc03-b498e4a89355'; -- 25 eels in total: error in op_nbeel (12 in op1, 10 in op2, 3 in op3)
select * from france.asturias_fish where ang_op_id = 28; -- 25 eels
select * from france.dbeel_batch_ope where ba_ob_id = '000ba411-c04a-4332-bc03-b498e4a89355'; -- 25 eels in total: error in op_nbeel (12 in op1, 10 in op2, 3 in op3)
update france.dbeel_batch_ope set ba_quantity = 25 where dbeel_batch_ope.ba_ob_id = '000ba411-c04a-4332-bc03-b498e4a89355' and ba_no_biological_characteristic_type = 47; 

select * from france.asturias_ope where asturias_ob_id = '25dfbeb0-b0f1-459b-a9fb-7acb58320e92'; -- 21 eels (12 in op1, 5 in op2, 4 in op3)
select * from france.asturias_fish where ang_op_id = 115 and ang_pas = 1; -- 22 eels (13 in pass 1; 5 in pass 2; 4 in pass 3): 1 is missing in pass 1
select * from france.dbeel_batch_ope where ba_ob_id = '25dfbeb0-b0f1-459b-a9fb-7acb58320e92';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '25dfbeb0-b0f1-459b-a9fb-7acb58320e92' and ba_no_biological_characteristic_type = 48; 
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '25dfbeb0-b0f1-459b-a9fb-7acb58320e92' and ba_no_biological_characteristic_type = 47; 

select * from france.asturias_ope where asturias_ob_id = '34ab44f2-5104-4439-a444-bb7d6c914e2a'; -- 1 eels (2 in op1, 1 in op2)
select count(*), ang_pas from france.asturias_fish where ang_op_id = 27 group by ang_pas; -- 3 eels (2 in pass 1; 1 in pass 2)
select * from france.dbeel_batch_ope where ba_ob_id = '34ab44f2-5104-4439-a444-bb7d6c914e2a';
update france.dbeel_batch_ope set ba_quantity = 3 where dbeel_batch_ope.ba_ob_id = '34ab44f2-5104-4439-a444-bb7d6c914e2a' and ba_no_biological_characteristic_type = 47; 

select * from france.asturias_ope where asturias_ob_id = '40681c34-ef0a-41f4-9457-1f1ec2bfff41'; -- 26 eels (17 in op1, 5 in op2, 4 in op3)
select count(*), ang_pas from france.asturias_fish where ang_op_id = 117 group by ang_pas; -- 3 eels (17 in pass 1; 15 in pass 2; 4 in pass 3)
select * from france.dbeel_batch_ope where ba_ob_id = '40681c34-ef0a-41f4-9457-1f1ec2bfff41';
update france.dbeel_batch_ope set ba_quantity = 36 where dbeel_batch_ope.ba_ob_id = '40681c34-ef0a-41f4-9457-1f1ec2bfff41' and ba_no_biological_characteristic_type = 47; 
update france.dbeel_batch_ope set ba_quantity = 15 where dbeel_batch_ope.ba_ob_id = '40681c34-ef0a-41f4-9457-1f1ec2bfff41' and ba_no_biological_characteristic_type = 232; 

select * from france.asturias_ope where asturias_ob_id = 'c3d77468-b42f-4d86-a4a2-b55fdab63b3e'; -- 0 eels (0 in op1)
select count(*), ang_pas from france.asturias_fish where ang_op_id = 20 group by ang_pas; -- 1 eels (1 in pass 2)
select * from france.dbeel_batch_ope where ba_ob_id = 'c3d77468-b42f-4d86-a4a2-b55fdab63b3e';
update france.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'c3d77468-b42f-4d86-a4a2-b55fdab63b3e' and ba_no_biological_characteristic_type = 47; 
begin;
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	'c3d77468-b42f-4d86-a4a2-b55fdab63b3e' as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	france.asturias_ope,
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
	and asturias_ob_id = 'c3d77468-b42f-4d86-a4a2-b55fdab63b3e'
	; -- 1 row
commit;

select * from france.asturias_ope where asturias_ob_id = 'ffcff086-9223-43d3-b2dd-f3e67de98b9d'; -- 57 eels (31 in op1, 19 in op2, 57 in op3)
select count(*), ang_pas from france.asturias_fish where ang_op_id = 9 group by ang_pas; -- 57 eels (31 in pass 1; 19 in pass 2; 7 in pass 3)
select * from france.dbeel_batch_ope where ba_ob_id = 'ffcff086-9223-43d3-b2dd-f3e67de98b9d';
update france.dbeel_batch_ope set ba_quantity = 7 where dbeel_batch_ope.ba_ob_id = 'ffcff086-9223-43d3-b2dd-f3e67de98b9d' and ba_no_biological_characteristic_type = 233; 

-- SIBIC
select * from france.levante_ope where ob_id = '08138b68-c5df-4da5-a3c4-8f0b444b5dca'; -- 10 eels 
select * from france.levante_fish where "PMSPCOD" = 'JU08210015' and "SISTCOD" = 'ANGANG'; -- 30 eels but only 11 eels with ba_id
select * from france.dbeel_batch_ope where ba_ob_id = '08138b68-c5df-4da5-a3c4-8f0b444b5dca';
update france.dbeel_batch_ope set ba_quantity = 11 where dbeel_batch_ope.ba_ob_id = '08138b68-c5df-4da5-a3c4-8f0b444b5dca' and ba_no_biological_characteristic_type = 231; 
update france.dbeel_batch_ope set ba_quantity = 11 where dbeel_batch_ope.ba_ob_id = '08138b68-c5df-4da5-a3c4-8f0b444b5dca' and ba_no_biological_characteristic_type = 47; 

select * from france.guipuz_ope where guipuz_ob_id = '4d5f6f1d-70eb-4900-8676-dbe5d5252c0c' -- 57 in pass, 14 in pass 2, 6 in pass 3
select * from france.guipuz_fish where sampling = 'PA2006013' and species = 'Anguilla anguilla' -- 77 eels
select * from france.dbeel_batch_ope where ba_ob_id = '4d5f6f1d-70eb-4900-8676-dbe5d5252c0c';
update france.dbeel_batch_ope set ba_quantity = 14 where dbeel_batch_ope.ba_ob_id = '4d5f6f1d-70eb-4900-8676-dbe5d5252c0c' and ba_no_biological_characteristic_type = 232;
update france.dbeel_batch_ope set ba_quantity = 3 where dbeel_batch_ope.ba_ob_id = '4d5f6f1d-70eb-4900-8676-dbe5d5252c0c' and ba_no_biological_characteristic_type = 233;

select * from france.temp_pesca_electrica where ob_id = 'ec9a463b-e865-47c9-b825-b52cca352c44' and codspecies = 'aang'; -- 10 eels 
select * from france.dbeel_batch_ope where ba_ob_id = 'ec9a463b-e865-47c9-b825-b52cca352c44';
update france.dbeel_batch_ope set ba_quantity = 17 where dbeel_batch_ope.ba_ob_id = 'ec9a463b-e865-47c9-b825-b52cca352c44' and ba_no_biological_characteristic_type = 47; 

--------------------------------------------------------------------------------------------
-- In bc_ope table
-- the density is corrected (divided by 100)
--------------------------------------------------------------------------------------------
select * from france.bc_ope limit 10;
select * from france.dbeel_batch_ope where ba_ob_id in (select bc_ob_id from france.bc_ope) and ba_no_biological_characteristic_type = 48; -- 885 rows
update france.dbeel_batch_ope set ba_quantity = round(op_dens::NUMERIC/100, 3) from france.bc_ope where dbeel_batch_ope.ba_ob_id = bc_ope.bc_ob_id and ba_no_biological_characteristic_type = 48;
SELECT * FROM france.dbeel_electrofishing de WHERE ob_id='32761281-9BC3-4F5B-B8FC-D06BE9FA6263'
BEGIN;
UPDATE france.dbeel_electrofishing de SET ob_starting_date='2017-10-26' WHERE ob_id='32761281-9BC3-4F5B-B8FC-D06BE9FA6263' -- instead of 2017-10-26
COMMIT;




--------------------
--  MISSING DATA BC_bis
--------------------
--323 france.bc_ope_bis 

/*
 * 
 * SOME stations sta_id were not in the bc_station_bis table... So we have to join with bc_station_to integate them
 * 
 */

----------------------------------------------------------------------------------------------
-- INSERT MISSING DATA 
---------------------------------------------------------------------------------------------
SELECT * from france.dbeel_electrofishing limit 10;
select * from france.bc_ope_bis limit 10;
-- the op_id column is bc_ob_id, dropping empty column

/*
SELECT count(*) FROM france.bc_ope_bis; -- 323
SELECT count(*) FROM france.bc_ope_bis pp JOIN france.dbeel_electrofishing ee on pp.bc_ob_id=ee.ob_id; -- 251
select count(*) from france.bc_ope_bis where is_duplicate = 'TRUE'; -- 1 row

BEGIN;
WITH friend as (
SELECT * FROM france.bc_ope_bis pp JOIN france.dbeel_electrofishing ee on pp.bc_ob_id=ee.ob_id -- 251
)
UPDATE france.bc_ope_bis set dbeel_ob_id=friend.bc_ob_id from friend where friend.bc_ob_id=bc_ope_bis.bc_ob_id; -- 251
COMMIT;

BEGIN;
with duplicates as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from france.bc_station_bis 
	join 
	france.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id -- 252 rows
	),-- joining the two tables on the portugal side

op_duplicates as (
	select ob_id, bc_ob_id from duplicates 
	JOIN 
	france.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates; -- 252 
UPDATE france.bc_ope_bis set dbeel_ob_id=ob_id FROM op_duplicates 
where op_duplicates.bc_ob_id=bc_ope_bis.bc_ob_id
AND is_duplicate; -- 1 row
COMMIT;

-- Checking already inserted batch_ope
WITH toto as (
	SELECT distinct ON (ba_ob_id) * FROM france.dbeel_batch_ope JOIN france.bc_ope_bis ON ba_ob_id=dbeel_ob_id
	)
select count (*) from toto; -- 252 OK

SELECT * from france.bc_fish_bis where ba_id is NULL; -- 625

SELECT * from france.bc_ope_bis 
	JOIN  
	france.bc_fish_bis on ang_op_id=bc_ope_bis.op_id; 	-- 3758

SELECT dbeel_dbeel_batch_fish_aspe.* FROM france.dbeel_dbeel_batch_fish_aspe JOIN 
	france.bc_ope_bis ON dbeel_ob_id= ba_ob_id; 		-- 3235
-- not more datat
SELECT dbeel_dbeel_batch_fish_aspe.* FROM france.dbeel_dbeel_batch_fish_aspe JOIN 
	france.bc_ope_bis ON dbeel_ob_id= ba_ob_id
	UNION
	SELECT dbeel_dbeel_batch_fish_aspe.* FROM france.dbeel_dbeel_batch_fish_aspe JOIN 
	france.bc_ope ON dbeel_ob_id= ba_ob_id;		-- 3235
		
-- which are the fish already in the database for which we have the size and for which we have new rows in dbeel_dbeel_batch_fish_aspe: we want to delete them
SELECT * FROM france.dbeel_dbeel_batch_fish_aspe 
	JOIN 
	france.bc_ope_bis ON dbeel_ob_id= ba_ob_id 
	where is_duplicate; -- 70

SELECT * FROM france.dbeel_dbeel_batch_fish_aspe limit 10;

SELECT * FROM france.dbeel_mensurationindiv_biol_charac 
	JOIN
	france.dbeel_dbeel_batch_fish_aspe on bc_ba_id=ba_id
	JOIN 
	france.bc_ope_bis ON dbeel_ob_id= ba_ob_id where is_duplicate; -- 70 

-- france.dbeel_mensurationindiv_biol_charac has delete cascade on ba_id,
-- so we delete one line per fish in dbeel_dbeel_batch_fish_aspe and all lines corresponding to length (there was only this) in dbeel_mensurationindiv_biol_charac

select * from france.bc_ope_bis 
except select * from france.bc_ope_bis 
where op_sta_id in (select sta_id from france.bc_station_bis); -- 71 rows


SELECT * FROM
		france.bc_station_bis 
	join
		france.bc_ope_bis on bc_ope_bis.op_sta_id = bc_station_bis.sta_id; --252 integrated
		
SELECT op_sta_id FROM france.bc_ope_bis
	WHERE op_sta_id NOT IN (SELECT sta_id FROM france.bc_station_bis )
	AND NOT is_duplicate ; --71		
	
SELECT DISTINCT(op_sta_id) FROM
france.bc_ope_bis 
WHERE op_sta_id NOT IN (SELECT sta_id FROM france.bc_station_bis ); --41 
*/

BEGIN;
INSERT INTO france.dbeel_electrofishing (
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
	bc_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	op_surface_m2 AS ef_wetted_area, 
	null AS ef_fished_length,
	null AS ef_fished_width,
	nb_pass AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.bc_station on dbeel_op_id = op_id
	join
		france.bc_ope_bis on bc_ope_bis.op_sta_id = bc_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='ALberto Aguirre'
	and is_duplicate = FALSE
	AND sta_id NOT IN (select sta_id from france.bc_station_bis )
	; -- 67


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2, run3 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)



BEGIN;
WITH uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM france.bc_station 
	JOIN france.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from france.bc_station_bis )
	) -- 67 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
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
	and is_duplicate = FALSE
	; -- 67
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
-- 			Density is calculated with different methods: estimation_method (Relative abundance, Seber Lecren, Carle Strab)
BEGIN;
with uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM france.bc_station 
	JOIN france.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from france.bc_station_bis )	) -- 252 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	round(coalesce(uniques.op_dens_nha::NUMERIC/10000,0),3) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	uniques, 
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
	and is_duplicate = FALSE
	; -- 67 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM france.bc_station 
	JOIN france.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from france.bc_station_bis )
	) -- 67 rows
INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	uniques.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	uniques, 
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
	and is_duplicate = FALSE
	; -- 67 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM france.bc_station 
	JOIN france.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from france.bc_station_bis )
	AND nb_pass >= 2
	) --54 rows

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
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
	and is_duplicate = FALSE
	; -- 54 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
-- nothing 


---- STEP 3: INSERT into dbeel_dbeel_batch_fish_aspe: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"


---- 		Check duplicates: Joining bc_fish and dbeel_dbeel_batch_fish_aspe by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select count(*) from france.bc_fish_bis; -- 3790 rows
select sum(op_nb_eels) from france.bc_ope_bis; -- 3771 rows

select * from france.bc_fish_bis a join france.bc_ope_bis o on ang_op_id = op_id -- 3758 rows
	join france.dbeel_electrofishing l on l.ob_id = o.bc_ob_id
	join france.dbeel_dbeel_batch_fish_aspe b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;
with uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM france.bc_station 
	JOIN france.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from france.bc_station_bis )
	) 
	
INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	bc_fish_bis.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	france.bc_fish_bis
	join uniques
	on ang_op_id = op_id	

	WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel'  
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 437 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 

WITH missing AS (	
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM france.bc_station 
	JOIN france.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from france.bc_station_bis)
	),	
	
    fish_from_bc as
	(	
	select * from missing 
	join france.dbeel_electrofishing on ob_id = bc_ob_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	) --437
UPDATE france.bc_fish_bis b
SET ba_id = fish_from_bc.ba_id
FROM fish_from_bc
WHERE fish_from_bc.fish_id = b.fish_id; -- 437 rows


-- select * from france.bc_fish_bis where ba_id is null; -- 188 rows

/* There are 9 rows that are more than one individual: nag_nb_indiv > 1 (with length and weigth as a mean): Remove them!
delete from france.dbeel_dbeel_batch_fish_aspe where ba_id in (select ba_id from france.bc_fish_bis where ang_nb_indiv > 1); -- 9 rows
update france.bc_fish_bis set ba_id = NULL where ang_nb_indiv > 1;  -- 9 rows
*/
---- 		Insert LENGTH
BEGIN;
WITH bc_fish_extract as (
	SELECT bc_fish_bis.* 
	FROM france.bc_station 
	JOIN france.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	JOIN france.bc_fish_bis ON ang_op_id=op_id
	WHERE sta_id NOT IN (select sta_id from france.bc_station_bis)
	)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_length_cm AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_length_cm > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3165 rows
COMMIT; 


---- 		Insert WEIGHT
begin;
WITH bc_fish_extract as (
	SELECT bc_fish_bis.* 
	FROM france.bc_station 
	JOIN france.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	JOIN france.bc_fish_bis ON ang_op_id=op_id
	WHERE sta_id NOT IN (select sta_id from france.bc_station_bis)
	)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds_g AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds_g > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 437 rows
commit;
*/



DELETE FROM france.dbeel_electrofishing de WHERE ob_starting_date >'2021-01-01'; --24



----------------------------------------------------------------------------------------------
-- CORRECTING DATA 
---------------------------------------------------------------------------------------------

/*
Regarding silvering data, length values from Alberto Aguirre were in centimeters, not mm
These data were corrected, testing a model in R to select these data and correct here
*/

begin;
with data_alberto as (
			select view_silvering.* from france.view_silvering join france.dbeel_electrofishing on view_silvering.ob_id = dbeel_electrofishing.ob_id where ob_dp_id = 23 -- 9574 rows
		     ),
--select * from data_alberto limit 10;
data_problem as (
	select (ln(weight) - 2.74 * ln(length) +11) > 4 as test, weight, length, ba_id, ob_starting_date from data_alberto 
	),
correction as (
		select * from data_problem join france.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id where test = TRUE and bc_no_characteristic_type = 39 -- 437 rows
		)
update france.dbeel_mensurationindiv_biol_charac set bc_numvalue = 10*correction.bc_numvalue from correction where correction.bc_id = dbeel_mensurationindiv_biol_charac.bc_id;  -- 437 rows
commit;

SELECT * FROM dbeel.establishment WHERE et_establishment_name ='miteco';
UPDATE dbeel.establishment SET et_establishment_name ='MITECO' WHERE et_establishment_name ='miteco';

UPDATE dbeel.establishment SET et_establishment_name ='Agencia vasca del agua (URA)' WHERE et_establishment_name ='ANBIOTEK';
UPDATE dbeel.establishment SET et_establishment_name ='URA (ANBIOTEK)' WHERE et_establishment_name ='Agencia vasca del agua (URA)';

UPDATE dbeel.establishment SET et_establishment_name ='france Pilot Basins (GT6)' WHERE et_establishment_name ='GT6';

UPDATE dbeel.establishment SET et_establishment_name ='Spanish Ministry (MITECO)' WHERE et_establishment_name ='MITECO';

UPDATE dbeel.establishment SET et_establishment_name ='Basque water agency (URA)  & ANBIOTEK' WHERE et_establishment_name ='URA (ANBIOTEK)';

UPDATE dbeel.establishment SET et_establishment_name ='University of Porto (UP)' WHERE et_establishment_name ='UP';

UPDATE dbeel.establishment SET et_establishment_name ='Spanish Fish Chart (SIBIC)' WHERE et_establishment_name ='SIBIC';

UPDATE dbeel.establishment SET et_establishment_name ='Spanish Ministry (MITECO)' WHERE et_establishment_name ='min esp';

UPDATE dbeel.establishment SET et_establishment_name ='Valencia Council (VAERSA)' WHERE et_establishment_name ='VAERSA';

UPDATE dbeel.establishment SET et_establishment_name ='University of Lisbon (FCUL) & APA, EDP, MARE' WHERE et_establishment_name ='FCUL (APA, EDP, MARE)';

UPDATE dbeel.establishment SET et_establishment_name ='Gipuzkoa Council & EKOLUR' WHERE et_establishment_name ='Diputaci�n de Gipuzkoa';

UPDATE dbeel.establishment SET et_establishment_name ='Navarra Council (GAN-NIK)' WHERE et_establishment_name ='The Navarra Environmental Management';

UPDATE dbeel.establishment SET et_establishment_name ='Galicia Council (Xunta de Galicia)' WHERE et_establishment_name ='The Xunta of Galicia';

UPDATE dbeel.establishment SET et_establishment_name ='University of C�rdoba (UCO)' WHERE et_establishment_name ='UCO';

UPDATE dbeel.establishment SET et_establishment_name ='Catalonia Council (ACA)' WHERE et_establishment_name ='ACA';

UPDATE dbeel.establishment SET et_establishment_name ='Asturias Council (DGPM Asturias)' WHERE et_establishment_name ='DGPM Asturias';



---------------------------------------------------------------------------------------------
-- CHECKING FISH DATA
---------------------------------------------------------------------------------------------

/*
Regarding fish tables (source), there are fishes in source tables without ba_id, so, they are not inserted in the dbeel
So, we have to check:
	- The station is not inserted because it is not reproyected in the river
	- The operation is duplicated and the fish are already inserted
First, join fish table with operation table and then, join with dbeel_electrofishing table
*/

-- PORTUGAL

SELECT count(*) from france.portugal_fish where ba_id is NULL; -- 113 rows (total: 4202 rows)
SELECT count(*) FROM france.portugal_ope; -- 868 rows (11 rows missing in dbeel_electrofishing)
SELECT count(*) FROM france.portugal_ope pp JOIN france.dbeel_electrofishing ee on pp.portugal_ob_id=ee.ob_id; -- 857 rows
select * from france.portugal_ope pl where problem_duplicates is TRUE; -- 11 rows (op_cod = 'A3' and 'A1')

-- 		Updating dbeel_op_id from portugal_ob_id in portugal_ope
BEGIN;
WITH friend as (
SELECT * FROM france.portugal_ope pp JOIN france.dbeel_electrofishing ee on pp.portugal_ob_id=ee.ob_id
) -- 857
UPDATE france.portugal_ope set dbeel_ob_id=friend.portugal_ob_id from friend where friend.portugal_ob_id=portugal_ope.portugal_ob_id; --44
COMMIT;


with portugal_join as (
	select * from france.portugal_fish fi join france.portugal_ope op on (fi.ang_op_id, fi.dat) = (op.op_sta_id, op.op_dat) -- 4186 rows (16 rows)
	),
portugal_check as (
	select * from portugal_join join france.dbeel_electrofishing on portugal_ob_id = ob_id
	)
select * from portugal_check; -- 4089 rows = 113 rows fish without ba_id

SELECT * from france.portugal_fish where ba_id is NULL; -- 113 rows (total: 4202 rows)
-- Thses fish comes form ang_id = 'A1', 'A3' and 'Estorãos'
select * from france.portugal_ope po where op_sta_id = 'A1' or op_sta_id = 'A3' or op_sta_id = 'Estorãos'; -- 11 rows
select * from france.portugal_ope where op_sta_id = 'Estorãos'; -- 0 rows
select * from france.portugal_location where "Code" = 'Estorãos'; -- 0 rows

/* Line  3440: TODO for Isabel, problem with stations A1 and A3.
Moreover, in portugal_fish table there is ang_op_id = 'Estorãos' that is not in operation nor station tables.
So, 113 fish not inserted!
*/


-- GIPUZKOA

select count(*) from guipuz_fish where species = 'Anguilla anguilla'; -- 4 rows ("sampling") (total = 31 976)
SELECT count(*) FROM france.guipuz_ope; -- 1317 rows
SELECT count(*) FROM france.guipuz_ope pp JOIN france.dbeel_electrofishing ee on pp.guipuz_ob_id=ee.ob_id; -- 1302 rows
select * from france.guipuz_ope pl where is_sibic_duplicate is TRUE; -- 222 rows

-- 		Updating dbeel_op_id from guipuz_ob_id in guipuz_ope
BEGIN;
WITH friend as (
SELECT * FROM france.guipuz_ope pp JOIN france.dbeel_electrofishing ee on pp.guipuz_ob_id = ee.ob_id
) -- 1302
UPDATE france.guipuz_ope set dbeel_ob_id=friend.guipuz_ob_id from friend where friend.guipuz_ob_id=guipuz_ope.guipuz_ob_id; -- 1302 rows
COMMIT;

-- 		There are 4 fish not inserted in the dbeel because the operation code (sampling) doesn't exist:
select * from france.guipuz_fish fi left join france.guipuz_ope op on fi.sampling = op.sampling where species = 'Anguilla anguilla' and pass is null; -- 4 rows
select * from france.guipuz_ope go2 where sampling = 'PB2012009';

--		How many fish appear in the dbeel of Guipuzkoa's operations, which don't have dbeel_ob_id?
select * from france.guipuz_fish fi 
	join france.guipuz_ope op on fi.sampling = op.sampling -- 31972 rows (4 rows are missing)
	join france.dbeel_electrofishing on guipuz_ob_id = ob_id where species = 'Anguilla anguilla'; -- 31156 rows (= 820 rows missing)

--		Why 816 fishes have been imported into the dbeel if there are not dbeel_ob_id?
select * from france.guipuz_fish fi 
	join france.guipuz_ope op on fi.sampling = op.sampling -- 31972 rows (4 rows are missing)
	join france.guipuz_station on station = "Station"
--	join france.dbeel_electrofishing on guipuz_ob_id = ob_id -- 0 rows These operations are missing in the dbeel_electrofishing
	where species = 'Anguilla anguilla' and dbeel_ob_id is null; -- 816 rows missing

	

	
	
-- no op_id removed unknowingly
	
	SELECT dbeel_op_id FROM france.guipuz_station
	EXCEPT
	SELECT op_id FROM france.dbeel_station_aspe; --0
	
	
	
-- these stations exist

SELECT * FROM france.guipuz_ope op	
JOIN france.guipuz_station on station = "Station"
WHERE is_sibic_duplicate=FALSE AND dbeel_ob_id IS NULL
	
-- OK so we have 15 lines of operation which are not there and we have no cue why....
-- we will insert them again

BEGIN;
ALTER TABLE france.guipuz_ope ADD COLUMN detected_missing BOOLEAN DEFAULT FALSE;

UPDATE france.guipuz_ope SET detected_missing= TRUE 
WHERE is_sibic_duplicate=FALSE AND dbeel_ob_id IS NULL;

INSERT INTO france.dbeel_electrofishing (
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
	guipuz_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	date AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	sampling_surface AS ef_wetted_area, 
	sampling_length AS ef_fished_length,
	sampling_width AS ef_fished_width,
	2 AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		france.dbeel_station_aspe as op
	join 
		france.guipuz_station on dbeel_op_id=op_id
	join
		france.guipuz_ope ope on ope.station=guipuz_station."Station"
		
	WHERE observation_origin.no_name='Raw data' 
	AND detected_missing =TRUE  -- THESE HAVE NOT BEEN INSERTED !
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Iker Azpiroz'
	; 	--15
	
BEGIN;
WITH friend as (
SELECT * FROM france.guipuz_ope pp JOIN france.dbeel_electrofishing ee on pp.guipuz_ob_id = ee.ob_id
) -- 1302
UPDATE france.guipuz_ope set dbeel_ob_id=friend.guipuz_ob_id from friend where friend.guipuz_ob_id=guipuz_ope.guipuz_ob_id; -- 1302 rows
COMMIT;

-- TOTAL NUMBER

with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from france.guipuz_ope
WHERE detected_missing =TRUE
),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from france.guipuz_ope
WHERE detected_missing =TRUE),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

-- select * from electrofishing_temp order by sampling;

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run1+electrofishing_temp.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
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
	; -- 15  rows

-- OP_P1	
	

with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from france.guipuz_ope
WHERE detected_missing =TRUE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from france.guipuz_ope
WHERE detected_missing =TRUE),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
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
	; -- 15


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from france.guipuz_ope
WHERE detected_missing =TRUE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from france.guipuz_ope
WHERE detected_missing =TRUE),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling
)

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
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
	; -- 15 rows


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)

with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from france.guipuz_ope
WHERE detected_missing =TRUE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from france.guipuz_ope
WHERE detected_missing =TRUE),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO france.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	electrofishing_temp, 
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
	; -- 15 rows

----		Insert individuals that were measured into the dbeel_dbeel_batch_fish_aspe


with anguila as (
select
fish_id,
a.sampling,
guipuz_ob_id as ba_ob_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from france.guipuz_fish a 
	join france.guipuz_ope o on a.sampling = o.sampling
	where species = 'Anguilla anguilla'
	AND detected_missing =TRUE)
--SELECT * FROM anguila; -- 816

INSERT INTO france.dbeel_dbeel_batch_fish_aspe
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN typeang='Amarilla' THEN 226 --'Yellow eel' 
	     WHEN typeang='Plateada' THEN 227 -- 'Silver eel'
	     WHEN typeang='Indefinida' THEN 224 -- unknown
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ba_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
--	anguila.sampling 		-- DOESN'T WORK because "locationid" is an integer and "sampling" is text
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; 



---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in guipuz_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 

ALTER TABLE france.guipuz_fish ADD COLUMN detected_missing BOOLEAN DEFAULT FALSE;


with fish_from_iker as
	(select * from france.dbeel_station_aspe 
	join france.dbeel_electrofishing on op_id = ob_op_id
	join france.dbeel_dbeel_batch_fish_aspe on ba_ob_id = ob_id
	JOIN france.guipuz_ope ON guipuz_ope.guipuz_ob_id = ba_ob_id
	where ob_dp_id = 14
	AND detected_missing =TRUE) -- 816 rows	
--select * from fish_from_iker join france.guipuz_fish on fish_from_iker.fish_id = guipuz_fish.fish_id limit 10;

UPDATE france.guipuz_fish b
SET (ba_id, detected_missing) = (fish_from_iker.ba_id, TRUE)
FROM fish_from_iker
WHERE fish_from_iker.fish_id = b.fish_id; -- 816 rows
--select * from france.guipuz_fish where ba_id is not null limit 10;


---- 		Insert LENGTH
-- with levante_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from france.levante_fish order by locationid),


-- THERE WAS AN ERROR THERE (WEIGHT INSTEAD OF LENGTH) IT IS CORRECTED JUST BELOW

with guipuz_fish_extract as (
select * from france.guipuz_fish 
WHERE detected_missing =TRUE
), -- the missing values

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 816

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,  
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 816 rows 


-- HERE IS THE CORRECTION

with guipuz_fish_extract as (
select * from france.guipuz_fish 
WHERE detected_missing =TRUE
), -- the missing values

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract),

--SELECT * FROM anguila
dbeel_mensurationindiv_biol_charac_temp AS (
SELECT * FROM france.dbeel_mensurationindiv_biol_charac JOIN 
anguila ON bc_ba_id = ba_id 
WHERE bc_no_characteristic_type = 39)

DELETE FROM france.dbeel_mensurationindiv_biol_charac  WHERE bc_id IN (
SELECT bc_id FROM dbeel_mensurationindiv_biol_charac_temp); --815


-- NOW INSERT AGAIN

with guipuz_fish_extract as (
select * from france.guipuz_fish 
WHERE detected_missing =TRUE
), -- the missing values

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 816

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length AS bc_numvalue,  
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 815 rows 





---- 		Insert WEIGHT

with guipuz_fish_extract as (
select * from france.guipuz_fish  
WHERE detected_missing =TRUE), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 815


---- 		Insert VERTICAL EYE DIAMETER

with guipuz_fish_extract as (
select * from france.guipuz_fish  
WHERE detected_missing =TRUE), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	eye_diam_vert AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE eye_diam_vert >0
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data';--17

---- 		Insert HORIZONTAL EYE DIAMETER

with guipuz_fish_extract as (
select * from france.guipuz_fish  
WHERE detected_missing =TRUE), 

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)

INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE eye_diam_horiz >0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; --17


---- 		Insert LENGTH OF THE PECTORAL FIN

with guipuz_fish_extract as (
select * from france.guipuz_fish  
WHERE detected_missing =TRUE), 
anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
INSERT INTO france.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length_pect AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length_pect >0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17

COMMIT ; --4720






-- GALICIA
select * from france.galicia_fish gf where ba_id is null and species = 'Anguila'; -- 294 rows (total = 44 191)
SELECT count(*) FROM france.galicia_ope; -- 5267 rows
SELECT count(*) FROM france.galicia_ope pp JOIN france.dbeel_electrofishing ee on pp.galicia_ob_id=ee.ob_id; -- 5267 rows
select * from france.galicia_ope pl where is_duplicate is TRUE; -- 4 rows

-- 		Updating dbeel_op_id from galicia_ob_id in galicia_ope
BEGIN;
WITH friend as (
SELECT * FROM france.galicia_ope pp JOIN france.dbeel_electrofishing ee on pp.galicia_ob_id = ee.ob_id
) -- 5267
UPDATE france.galicia_ope set dbeel_ob_id=friend.galicia_ob_id from friend where friend.galicia_ob_id=galicia_ope.galicia_ob_id; -- 5267 rows
COMMIT;

-- 		Checking the operations of the fishes missing
--			There are 294 fishes not inserted because the operations aren't in galicia_ope table
select count(*) from france.galicia_fish gf join france.galicia_ope gop on gf.cod_ope = gop.cod_ope; -- 43 897 (total = 44 191) -> 294 fishes missing

select * from france.galicia_fish where cod_ope not in (select cod_ope from france.galicia_ope); -- 294 rows (ex. INV91_0095)
select * from france.galicia_ope where cod_ope like '%INV91_009%';


-- BASQUE COUNTRY (first table)
SELECT count(*) from france.bc_fish where ba_id is NULL; -- 9 rows (total: 5 981 rows)
SELECT count(*) FROM france.bc_ope; -- 885 rows (0 rows missing in dbeel_electrofishing)
SELECT count(*) FROM france.bc_ope pp JOIN france.dbeel_electrofishing ee on pp.bc_ob_id = ee.ob_id; -- 885 rows
select * from france.bc_ope pl where is_duplicate is TRUE; -- 0 rows

-- 		Updating dbeel_op_id from bc_ob_id in bc_ope
BEGIN;
WITH friend as (
SELECT * FROM france.bc_ope pp JOIN france.dbeel_electrofishing ee on pp.bc_ob_id = ee.ob_id
) -- 885 rows
UPDATE france.bc_ope set dbeel_ob_id=friend.bc_ob_id from friend where friend.bc_ob_id=bc_ope.bc_ob_id; -- 885 rows
COMMIT;

-- select ang_op_id, ang_pass, count(*) from france.bc_fish group by ang_op_id, ang_pass order by ang_op_id ;

select * from france.bc_fish fi join france.bc_ope op on fi.ang_op_id = op.op_id 
	join france.dbeel_electrofishing on op.dbeel_ob_id = ob_id; -- 5972 rows = 9 rows fish without ba_id
	
select * from france.bc_ope bo where op_id in (select distinct ang_op_id as op_id from france.bc_fish fi where ba_id is null);
-- op_id = 22964 is in bc_fish but not in bc_ope, so we lost 9 eels measured because there is no the operation 

select * from france.bc_ope bo where op_sta_id in (select distinct ang_sta_id as op_sta_id from france.bc_fish fi where ba_id is null);
-- neither the station


-- NAVARRA
SELECT count(*) from france.navarra_fish where ba_id is NULL; -- 346 rows (total: 3 973 rows)
SELECT count(*) FROM france.navarra_ope; -- 66 rows (0 rows missing in dbeel_electrofishing)
SELECT count(*) FROM france.navarra_ope pp JOIN france.dbeel_electrofishing ee on pp.navarra_ob_id = ee.ob_id; -- 66 rows
select * from france.navarra_ope pl where is_duplicate is TRUE; -- 9 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM france.navarra_ope pp JOIN france.dbeel_electrofishing ee on pp.navarra_ob_id = ee.ob_id
) -- 66 rows
UPDATE france.navarra_ope set dbeel_ob_id=friend.navarra_ob_id from friend where friend.navarra_ob_id=navarra_ope.navarra_ob_id; -- 66 rows
COMMIT;

select * from france.navarra_fish fi join france.navarra_ope op on fi.ang_op_id = op.op_id 
	join france.dbeel_electrofishing on op.dbeel_ob_id = ob_id where is_duplicate = TRUE; -- 346 rows	
-- 346 eels are not inserted because they come from operations that were duplicates! Must we include them? 


-- ANDALUCIA
SELECT count(*) from france.andalucia_fish where ba_id is NULL; -- 2 rows (total: 31 rows)
SELECT count(*) FROM france.andalucia_ope; -- 92 rows (1 rows missing in dbeel_electrofishing -- where andalucia_ob_id is null)
SELECT count(*) FROM france.andalucia_ope pp JOIN france.dbeel_electrofishing ee on pp.andalucia_ob_id = ee.ob_id; -- 91 rows

-- There is one duplicate:
select * from france.andalucia_ope pl where is_duplicate is TRUE; -- 1 rows
SELECT * FROM france.andalucia_ope pp where andalucia_ob_id not in (select ob_id as andalucia_ob_id from france.dbeel_electrofishing);

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM france.andalucia_ope pp JOIN france.dbeel_electrofishing ee on pp.andalucia_ob_id = ee.ob_id
) -- 91 rows
UPDATE france.andalucia_ope set dbeel_ob_id=friend.andalucia_ob_id from friend where friend.andalucia_ob_id=andalucia_ope.andalucia_ob_id; -- 91 rows
COMMIT;

select * from france.andalucia_fish fi join france.andalucia_ope op on (fi.fish_sta_id, fi.fish_op_dat) = (op.sta_id, op.op_dat) 
	join france.dbeel_electrofishing on op.dbeel_ob_id = ob_id; -- 29 rows	


select * from france.andalucia_ope bo where (sta_id, op_dat) in (select fish_sta_id, fish_op_dat from france.andalucia_fish fi where ba_id is null); -- 0 rows
select * from france.andalucia_fish fi where ba_id is null;
-- fish_sta_id: 1.40.6, 1.40.3 there aren't in the operation table -> impossible to link these eels, so don't imported!

	
-- SPAIN
SELECT count(*) from france.spain_fish where ba_id is NULL; -- 1125 rows (total: 3488 rows)
SELECT count(*) FROM france.spain_ope; -- 1075 rows (0 rows missing in dbeel_electrofishing -- where spain_ob_id is null)
SELECT count(*) FROM france.spain_ope pp JOIN france.dbeel_electrofishing ee on pp.spain_ob_id = ee.ob_id; -- 948 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM france.spain_ope pp JOIN france.dbeel_electrofishing ee on pp.spain_ob_id = ee.ob_id
) -- 948 rows
UPDATE france.spain_ope set dbeel_ob_id=friend.spain_ob_id from friend where friend.spain_ob_id=spain_ope.spain_ob_id; -- 948 rows
COMMIT;


-- In dbeel_electrofishing: 972 rows (1075 operations - 99 duplicates - 4 with the same sta_cod) were inserted. 
-- But now, we found only 948 rows!
select * from france.spain_ope pl where is_duplicate is TRUE; -- 99 rows
SELECT * FROM france.spain_ope pp where spain_ob_id not in (select ob_id as spain_ob_id from france.dbeel_electrofishing) and is_duplicate = FALSE; -- 28 rows (from 127 total rows, 99 duplicates)
-- 24 rows with op_id and op_cod NULL
-- 4 rows with op_id and op_cod: '0500050-11/07/2008', 'CRAAI-022-06/07/2008', 'CRL-040-04/07/2008', 'CROKGO-032-03/07/2008' that are the same as:
select * from france.spain_ope bo where op_id in (select ang_op_id from france.spain_fish fi where ba_id is null) and is_duplicate = FALSE order by op_id; -- 4 rows

select * from france.spain_fish fi join france.spain_ope op on fi.ang_op_id = op.op_id 	-- 2828 rows
	join france.dbeel_electrofishing on op.dbeel_ob_id = ob_id ; 	-- 2363 rows that are imported into dbeel (where is_duplicate = TRUE: 0 rows)

select distinct op_cod from france.spain_fish fi join france.spain_ope op on fi.ang_op_id = op.op_id 
where spain_ob_id not in (select ob_id as spain_ob_id from france.dbeel_electrofishing) and is_duplicate = false;
-- '0500050-11/07/2008', 'CRAAI-022-06/07/2008', 'CRL-040-04/07/2008', 'CROKGO-032-03/07/2008'


SELECT * from france.spain_fish where ba_id is null and ang_op_id in (select op_id from france.spain_ope); -- 465 rows (from 1125 total of ba_id null)
select * from france.spain_fish fi left join france.spain_ope op on fi.ang_op_id = op.op_id where op_id is null; -- 660 rows (from 1125 total of ba_id null)

SELECT * from france.spain_fish where ba_id is null and ang_op_id in (select op_id from france.spain_ope where is_duplicate = TRUE); -- 448 rows (+ 17 rows is_duplicate = FALSE)

SELECT * from france.spain_fish where ba_id is null and ang_op_id in (select op_id from france.spain_ope so where is_duplicate = false); -- 17 rows
select * from france.spain_ope where op_id in (SELECT ang_op_id from france.spain_fish where ba_id is null) and is_duplicate = FALSE; -- 4 rows
-- '0500050-11/07/2008', 'CRAAI-022-06/07/2008', 'CRL-040-04/07/2008', 'CROKGO-032-03/07/2008'
-- Of the 1125 non-imported eels, 660 come from operations not listed in the operation table, 448 come from duplicates and 17 from four operations that have not been imported into the dbeel!


-- VALENCIA
SELECT count(*) from france.valencia_fish where ba_id is NULL; -- 1127 rows (total: 3435 rows)
SELECT count(*) FROM france.valencia_sta_ope; -- 193 rows (0 rows missing in dbeel_electrofishing -- where spain_ob_id is null)
SELECT count(*) FROM france.valencia_sta_ope pp JOIN france.dbeel_electrofishing ee on pp.val_ob_id = ee.ob_id; -- 193 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM france.valencia_sta_ope pp JOIN france.dbeel_electrofishing ee on pp.val_ob_id = ee.ob_id
) -- 193 rows
UPDATE france.valencia_sta_ope set dbeel_ob_id=friend.val_ob_id from friend where friend.val_ob_id=valencia_sta_ope.val_ob_id; -- 193 rows
COMMIT;

select * from france.valencia_fish mf where ba_id is null; -- 1227 rows
SELECT * from france.valencia_fish where ba_id is null and ang_sta_id in (select op_sta_id from france.valencia_sta_ope); -- 0 rows (from 1227 total of ba_id null)
select distinct ang_sta_id from france.valencia_fish fi left join france.valencia_sta_ope op on fi.ang_sta_id = op.op_sta_id where op_sta_id is null; -- 1227 rows from 84 ang_sta_id that don't matck in ope table
-- The 1227 eels not imported correspond to operations that do not appear in the table operation!


-- GT6 
SELECT count(*) from france.gt6_fish where ba_id is NULL; -- 3 rows (total: 4466 rows)
SELECT count(*) FROM france.gt6_ope; -- 94 rows (0 rows missing in dbeel_electrofishing -- where spain_ob_id is null)
SELECT count(*) FROM france.gt6_ope pp JOIN france.dbeel_electrofishing ee on pp.gt6_ob_id = ee.ob_id; -- 94 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM france.gt6_ope pp JOIN france.dbeel_electrofishing ee on pp.gt6_ob_id = ee.ob_id
) -- 94 rows
UPDATE france.gt6_ope set dbeel_ob_id=friend.gt6_ob_id from friend where friend.gt6_ob_id=gt6_ope.gt6_ob_id; -- 94 rows
COMMIT;

select * from france.gt6_fish mf where ba_id is null; -- 3 rows 
-- This ang_op_id = '130.002' doesn't have the op_cod associated (check table) -> looking in SIBIC.R that is TER!


-- MINHO
SELECT count(*) from france.minho_fish where ba_id is NULL; -- 150 rows (total: 2010 rows)
SELECT count(*) FROM france.minho_ope; -- 78 rows (0 rows missing in dbeel_electrofishing -- where spain_ob_id is null)
SELECT count(*) FROM france.minho_ope pp JOIN france.dbeel_electrofishing ee on pp.minho_ob_id = ee.ob_id; -- 78 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM france.minho_ope pp JOIN france.dbeel_electrofishing ee on pp.minho_ob_id = ee.ob_id
) -- 78 rows
UPDATE france.minho_ope set dbeel_ob_id=friend.minho_ob_id from friend where friend.minho_ob_id=minho_ope.minho_ob_id; -- 78 rows
COMMIT;

select * from france.minho_fish mf where ba_id is null; -- 150 rows
SELECT * from france.minho_fish where ba_id is null and ang_op_id in (select op_id from france.minho_ope); -- 0 rows (from 150 total of ba_id null)
select * from france.minho_fish fi left join france.minho_ope op on fi.ang_op_id = op.op_id where op_id is null; -- 150 rows from 8 ang_op_id that don't matck in ope table
-- The 150 eels not imported correspond to operations that do not appear in the table operation!
