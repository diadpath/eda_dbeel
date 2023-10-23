---------------------------------------------
-- SCRIPT INTEGRATION ASPE => DBEEL
---------------------------------------------
-- TABLES FOR IMPORT will be created IN France AND IN loire schema 
-- (for electrofishing from federations de peche)
-- script for creating is in eda_dbeel/eda2.3/R/aspe_import.R


-- **************************************
-- UPDATES :
-- updated TABLES 04/04 => Maria
	/*
	dbeel.establishment
	dbeel.data_provider
	*/
-- Julien RAITIF, 24/08/23 : add comments in file to give detailed information for users
-- **************************************



-- *************************************************
-- *************************************************
-- *************************************************
-- TABLE OF CONTENTS
-- 1) ONLY IF NECESSARY : Create establishement and provider of ASPE DATA
-- 2) Station
-- 3) Electrofishing details
-- 4) Batch informations 
-- 5) Batch informations (fish level)
-- 6) Silvering data (dbeel.view_electrofishing_size_weight_new needed)
-- *************************************************
-- *************************************************
-- *************************************************







-- *************************************************
-- *************************************************
-- *************************************************
-- 1) ONLY IF NECESSARY : Create establishement and provider of ASPE DATA
-- *************************************************
-- *************************************************
-- *************************************************
-- select * from dbeel.establishment;
INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('OFB');
--select * from dbeel.data_provider
--select max(dp_id) from dbeel.data_provider; -- 25
INSERT INTO  dbeel.data_provider (dp_id, dp_name, dp_et_id) VALUES (30, 'Pascal Irz',27);
ALTER SEQUENCE dbeel.data_provider_dp_id_seq RESTART WITH 31;






-- *************************************************
-- *************************************************
-- *************************************************
-- 2) Station
-- *************************************************
-- *************************************************
-- *************************************************
/* select * from dbeel.observation_places limit 10; */
-- select * from france.station_aspe limit 10;
/* SELECT DISTINCT  count(*), sta_statut FROM france.station_aspe GROUP BY sta_statut; -- 31734 true */

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

--DELETE FROM france.dbeel_batch_ope_aspe; --75666
--DELETE FROM france.dbeel_electrofishing_aspe; --33300
--DELETE FROM france.dbeel_station_aspe; -- 2 min 32720


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
	FROM france.station_aspe;  

--2020 : 31734 après filtre contour france
-- 24/08/2023 : 33985 stations après nouveau filtre contour France.


	
	
/* 	--retour des identifiants dans la TABLE mère

ALTER TABLE france.station_aspe ADD COLUMN sta_dbeel_op_id UUID;
	UPDATE france.station_aspe SET sta_dbeel_op_id = op_id FROM
 france.dbeel_station_aspe WHERE dbeel_station_aspe.sta_id=station_aspe.sta_id; --31734 */

	







-- *************************************************
-- *************************************************
-- *************************************************
-- 3) Electrofishing details
-- *************************************************
-- *************************************************
-- *************************************************

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

/*
For the moment we set the type of electrofishing to unknown (61), 
later for some fishing we will use whole (62)
*/
/* select * from france.dbeel_station_aspe limit 10;
select * from france.operation_aspe limit 10; --43695
SELECT * FROM  france.dbeel_station_aspe sta
   JOIN france.operation_aspe ope ON sta.sta_id=ope.sta_id */

-- The import is done in two times as some operations do not have sta_id, 
-- it must be loaded from point_prelevement_aspe

/* DELETE FROM france.dbeel_electrofishing_aspe; */
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
   JOIN france.operation_aspe ope ON sta.sta_id=ope.sta_id,  
   -- JRT, 24/08 : ça ne me semble pas correct
   -- si on veut toutes les opérations même celles qui n'ont pas de sta_id, 
   -- il faudrait un right join, mais voir fichier impart_aspe.R pour solution proposée
   -- 
   -- old comment : JOIN donc les operations sans sta_id sont gardées
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
	

/* ALTER TABLE france.operation_aspe ADD COLUMN ope_dbeel_ob_id UUID;
UPDATE france.operation_aspe SET ope_dbeel_ob_id = NULL; --43695

UPDATE france.operation_aspe SET ope_dbeel_ob_id = ob_id FROM
 france.dbeel_electrofishing_aspe WHERE dbeel_electrofishing_aspe.ope_id=operation_aspe.ope_id; --31919
 
 
 SELECT  * FROM france.dbeel_electrofishing_aspe WHERE dbeel_electrofishing_aspe.ope_id=operation_aspe.ope_id */
	
-- INSERT DES OPERATIONS MANQUANTES A PARTIR DES POINTS DE PRELEVEMENT
-- IL N'en reste que 24 après jointure.... on oublie....
/*	
	
SELECT count(*) FROM  france.operation_aspe ope WHERE ope.sta_id IS NULL; --10394
SELECT *  FROM france.point_prelevement_aspe pop
JOIN  france.operation_aspe ope ON ope.pop_id=pop.pop_id
WHERE ope.sta_id IS NULL; --10394 => 24

--> cf import_aspe.R pour proposition de solution en 
rattachant le point de prélèvement à la station la plus proche connue
*/

-- Some verifs
	
/*	

SELECT DISTINCT ef_no_fishingmethod FROM france.dbeel_electrofishing_aspe
303
63
301
62
302


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
Pêche partielle par points (grand milieu)	9428
Pêche par ambiances	2239
Pêche partielle sur berge	3023
Pêche complète à un ou plusieurs passages	19219
Indice Abondance Anguille	1245
*/
/* SELECT mom_libelle, count(*) FROM france.dbeel_electrofishing_aspe GROUP BY mom_libelle;
SELECT op_typ, count(*) FROM france.dbeel_electrofishing_aspe GROUP BY op_typ */
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

/* select count(*) from france.dbeel_electrofishing_aspe where ob_starting_date is null; --0


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
/* select * from france.dbeel_electrofishing_aspe  where ope_id=85705 */









-- *************************************************
-- *************************************************
-- *************************************************
-- 4) Batch informations
-- *************************************************
-- *************************************************
-- *************************************************

--------------------------------------------	
-- NUMBER PER PASS... AND TOTAL NUMBER
-- BATCH INTEGRATION
-- WE DON'T NEED DENSITY, WILL BE RECALCULATED LATER
--------------------------------------------

-- Drop table

-- SELECT  * FROM france.batch_aspe 

 
DROP TABLE france.dbeel_batch_ope_aspe CASCADE;
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

-- Total quantity of eels captured
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
  AND stage.no_name='Yellow eel' -- we actually don't know that...
  AND biological_characteristic_type.no_name='Number' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  ; -- 31919 rows

  
-- Quantity of eels captured at the 1st pass
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
	; -- 31919 ROWS

-- Quantity of eels captured at the 2nd pass (if exists)
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
  AND ef_nbpas > 1 
  ; -- 8745 ROWS
  
-- Quantity of eels captured at the 3rd pass (if exists)  
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
  AND ef_nbpas > 2
  ; -- 154 ROWS => 150 WITH nbpas = 3
  
 -- Quantity of eels captured at the 4th pass (if exists)
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
  AND ef_nbpas > 3
  ; -- 4 ROWS
    
  
  
  
  
  
  
  
  
  
-- *************************************************
-- *************************************************
-- *************************************************
-- 5) Batch informations, fish level
-- *************************************************
-- *************************************************
-- *************************************************
  
DROP TABLE if exists france.dbeel_batch_fish_aspe CASCADE;
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
/* SELECT * FROM france.batch_fish_aspe baf  */

-- test il manque des poissons on comprend pas pourquoi 12/04
/*
SELECT * FROM france.batch_fish_aspe;--403623
SELECT  pas_numero, count(*) as N FROM france.batch_fish_aspe group by pas_numero;
|pas_numero|n     |
|----------|------|
|1         |237081|
|2         |48587 |
|3         |434   |
|4         |4     |
|          |117517|
WITH dist AS(
SELECT  distinct on (pas_numero,ope_id) * FROM france.batch_fish_aspe
)
SELECT count(*) FROM dist
group by pas_numero;

|count|
|-----|
|10186|
|3575 |
|41   |
|1    |
|6409 |


SELECT * FROM  france.dbeel_batch_fish_aspe; --319535
SELECT * FROM france.batch_fish_aspe;--403623
WITH bap1 AS (
    SELECT * FROM france.dbeel_batch_ope_aspe boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p1'  
  ),

  bafp1 AS (SELECT * FROM france.batch_fish_aspe
          WHERE pas_numero = 1 OR pas_numero IS NULL) 

  SELECT * 
  FROM 
  bafp1
  JOIN bap1 ON (bap1.ope_id=bafp1.ope_id) ;--285 096
  
-- ceux qui ne sont pas entrés  
  
WITH bap1 AS (
    SELECT * FROM france.dbeel_batch_ope_aspe boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p1'  
  ),

  bafp1 AS (SELECT * FROM france.batch_fish_aspe
          WHERE pas_numero = 1 OR pas_numero IS NULL) 
          
  SELECT * FROM france.batch_fish_aspe
  EXCEPT
  SELECT bafp1.* 
  FROM 
  bafp1
  JOIN bap1 ON (bap1.ope_id=bafp1.ope_id) ;   --118527 non rentrés
  
  
  SELECT * FROM france.dbeel_batch_ope_aspe ba JOIN
       france.batch_fish_aspe baf ON (ba.ope_id=baf.ope_id) --754847 weight + size
  
  
  
  SELECT * FROM france.dbeel_batch_fish_aspe WHERE ope_id not in 
  (select distinct ope_id FROM france.dbeel_batch_ope_aspe);--0
  
  
  
  
SELECT distinct (ope_id) FROM france.dbeel_batch_fish_aspe;--13785
SELECT distinct (ope_id) FROM france.batch_fish_aspe; --16888
*/

-- Fish caught during 1st pass
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
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	;

/* 
select * from france.batch_fish_aspe limit 10;



SELECT * FROM   france.dbeel_batch_fish_aspe dbaf JOIN
  france.batch_fish_aspe baf ON baf.mei_id=dbaf.mei_id;-- 285096 -> 284812 */


-- Measures of fish caught during 1st pass
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
  WHERE biological_characteristic_type.no_name = 'Length'; 

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

-- Fish caught during 2nd pass
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
  AND biological_characteristic_type.no_name='Number p2' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  ;


-- Measures of fish caught during 2nd pass
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
    AND baf.pas_numero=2;

-- Fish caught during 3rd pass
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
  AND biological_characteristic_type.no_name='Number p3' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  ; 

-- Measures of fish caught during 3rd pass
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
    AND baf.pas_numero=3; 
    
    
-- Fish caught during 4th pass
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
  AND biological_characteristic_type.no_name='Number p4' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  ; 

-- Measures of fish caught during 4th pass
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


-- *************************************************
-- *************************************************
-- *************************************************
-- 6) Silvering data (dbeel.view_electrofishing_size_weight_new)
-- *************************************************
-- *************************************************
-- *************************************************

/*----------------------
 * Imported from Laurent's treatment and further explorted in eda2.3 chunk silvering_analysis 
 line 8409 in EDA_build.rnw
 * Currently not available in the database ASPE (only size and weight)
 * The import to db is done in aspe_import.R line 323
 * The table copied is  batch_silver_wama with column ope_dbeel_ob_id corresponding to current ob_id 
 * ----------------------- */


 
-- how many lines in batch_silver_wama
select count(*) from batch_silver_wama bsw 
--25/08 : 14575

--How many records in batch_silver_wama will be updated
select count(bsw.*) from batch_silver_wama bsw 
join dbeel_electrofishing_aspe dea  
on bsw.ope_code_wama = dea.ope_code_wama 
--25/08 : 14351 --> 224 silvering data lost

-- what are the missing ope_code_wama
select bsw2.ope_code_wama, count(*) from batch_silver_wama bsw2 where bsw2.ope_code_wama  not in 
	(select bsw.ope_code_wama from batch_silver_wama bsw 
	join dbeel_electrofishing_aspe dea on dea.ope_code_wama = bsw.ope_code_wama )
	group by bsw2.ope_code_wama
-- 25/08 : 18 missing codes for the 224 missing lines

-- all 18 ope_code_wama ref are associated with a non existent sta_id.
select cast(oa.ope_code_wama as text),oa.sta_id  from operation_aspe oa 
where cast(oa.ope_code_wama as text) in (select distinct bsw2.ope_code_wama from batch_silver_wama bsw2 
where bsw2.ope_code_wama  not in 
	(select bsw.ope_code_wama from batch_silver_wama bsw 
	join dbeel_electrofishing_aspe dea on dea.ope_code_wama = bsw.ope_code_wama ))
-- waiting for decision to the operation without sta_id (cf aspe_import.R)

--update of batch_silver_wama
UPDATE batch_silver_wama
SET ope_dbeel_ob_id = subquery.ob_id 
FROM (select ob_id,bsw.ope_code_wama  from batch_silver_wama bsw 
join dbeel_electrofishing_aspe dea  on bsw.ope_code_wama = dea.ope_code_wama 
) AS subquery
WHERE batch_silver_wama.ope_code_wama = subquery.ope_code_wama


--
--we then need to include silvering data into dbeel_mensurationindiv_biol_charac_aspe
--but to do so, we need each measure in batch_silver_wama to be associated with a unique fish id (ba_id in dbeel.batch for ba_batch_level = 2)
--for that purpose, we create a temporary table which would be created by linking batch_silver_wama data and the list of fish measurments already none in dbeel which are listed in dbeel.view_electrofishing_size_weight_new
--we also need to manage the case of eels with identical length/weight measured (but different silvering data) during a given electrofishing operation. We do so with a partition trick.
drop table if exists france.temp_batch_wama_with_id ;
CREATE TABLE france.temp_batch_wama_with_id
AS 
with 
part_wama as (
select 
tbw.*,
row_number () OVER(PARTITION BY (tbw.ope_dbeel_ob_id, tbw.length, tbw.weight) ORDER BY (tbw.ope_dbeel_ob_id, tbw.length, tbw.weight) asc) AS row_wama--,
from france.batch_silver_wama tbw),
--on fait la même chose côté dbeel pour les ob_id connus dans wama
part_dbeel as (
select ve.bc_id, ve.bc_ba_id ,ve.ob_id, ve.length, ve.weight,
row_number () OVER(PARTITION BY (ve.ob_id, ve.length, ve.weight) ORDER BY (ve.ob_id, ve.length, ve.weight) asc) AS row_dbeel--,
--concat(ve.ob_id, ve.length, ve.weight,
--row_number () OVER(PARTITION BY (ve.ob_id, ve.length, ve.weight) ORDER BY (ve.ob_id, ve.length, ve.weight) asc)) as concat_dbeel
from dbeel.view_electrofishing_size_weight_new ve 
where ve.ob_id::text in (select distinct tb.ope_dbeel_ob_id::text from france.batch_silver_wama tb))
--et au final on update la table wama, en prenant en compte le quator ob_id, length,weight,numéro de partition
--l'update n'est pas encore fait mais je vérifie ici que j'arrive bien à assigner un id de poisson (ve.bc_ba_id) à chaque mesure batch_wama
select pw.*, pd.row_dbeel, pd.bc_id, pd.bc_ba_id, pd.ob_id
from part_wama pw
join part_dbeel pd on (pd.ob_id::text,pd.length,pd.weight,pd.row_dbeel) = (pw.ope_dbeel_ob_id::text,pw.length,pw.weight,pw.row_wama);
--14264 sur 14351 initialement existantes dans WAMA
--87 lines lost due mainly to dpulicates in WAMA or other issues in ASPE.



--
--insert silvering data in dbeel_mensurationindiv_biol_charac_aspe
--

--insert Eyes, vertical diameter
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)  
  SELECT 
  uuid_generate_v4() AS bc_id, 	--generated id of measurment
  tbwwi.bc_ba_id, 				--fish id (from batch)
  bct.no_id,					--id of type of measurment (eye_diam_vert, eye_diam_horiz, length_pect, presence_neuromast, contrast) 
  dbfa.ba_no_value_type, 		--id of type of value (raw or elaborated)
  tbwwi.eye_diam_vert, 			--silvering measurment
  dbfa.mei_id,					-- id of measurment from ASPE database
  dbfa.ope_id 					-- id of operation from ASPE
  FROM 
  france.temp_batch_wama_with_id tbwwi 
  join france.dbeel_batch_fish_aspe dbfa ON dbfa.ba_id = tbwwi.bc_ba_id, 
  dbeel_nomenclature.biological_characteristic_type bct WHERE bct.no_name = 'eye_diam_vert'
  --19/10/23 : 14264 records

--insert Eyes, horizontal diameter
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)  
  SELECT 
  uuid_generate_v4() AS bc_id, 	--generated id of measurment
  tbwwi.bc_ba_id, 				--fish id (from batch)
  bct.no_id,					--id of type of measurment (eye_diam_vert, eye_diam_horiz, length_pect, presence_neuromast, contrast) 
  dbfa.ba_no_value_type, 		--id of type of value (raw or elaborated)
  tbwwi.eye_diam_horiz, 		--silvering measurment
  dbfa.mei_id,					-- id of measurment from ASPE database
  dbfa.ope_id 					-- id of operation from ASPE
  FROM 
  france.temp_batch_wama_with_id tbwwi 
  join france.dbeel_batch_fish_aspe dbfa ON dbfa.ba_id = tbwwi.bc_ba_id, 
  dbeel_nomenclature.biological_characteristic_type bct WHERE bct.no_name = 'eye_diam_horiz'
  --19/10/23 : 14264 records
  
--insert pectoral length
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)  
  SELECT 
  uuid_generate_v4() AS bc_id, 	--generated id of measurment
  tbwwi.bc_ba_id, 				--fish id (from batch)
  bct.no_id,					--id of type of measurment (eye_diam_vert, eye_diam_horiz, length_pect, presence_neuromast, contrast) 
  dbfa.ba_no_value_type, 		--id of type of value (raw or elaborated)
  tbwwi.length_pect, 			--silvering measurment
  dbfa.mei_id,					-- id of measurment from ASPE database
  dbfa.ope_id 					-- id of operation from ASPE
  FROM 
  france.temp_batch_wama_with_id tbwwi 
  join france.dbeel_batch_fish_aspe dbfa ON dbfa.ba_id = tbwwi.bc_ba_id, 
  dbeel_nomenclature.biological_characteristic_type bct WHERE bct.no_name = 'length_pect'
  --19/10/23 : 14264 records

--insert presence of neuromast
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)  
  SELECT 
  uuid_generate_v4() AS bc_id, 	--generated id of measurment
  tbwwi.bc_ba_id, 				--fish id (from batch)
  bct.no_id,					--id of type of measurment (eye_diam_vert, eye_diam_horiz, length_pect, presence_neuromast, contrast) 
  dbfa.ba_no_value_type, 		--id of type of value (raw or elaborated)
  tbwwi.presence_neuromast, 	--silvering measurment
  dbfa.mei_id,					-- id of measurment from ASPE database
  dbfa.ope_id 					-- id of operation from ASPE
  FROM 
  france.temp_batch_wama_with_id tbwwi 
  join france.dbeel_batch_fish_aspe dbfa ON dbfa.ba_id = tbwwi.bc_ba_id, 
  dbeel_nomenclature.biological_characteristic_type bct 
  WHERE bct.no_name = 'presence_neuromast'
  and tbwwi.presence_neuromast is not null and length(tbwwi.presence_neuromast::text)>0
  --19/10/23 : 0 record


--insert contrast observations
INSERT INTO france.dbeel_mensurationindiv_biol_charac_aspe(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  mei_id,
  ope_id)  
  SELECT 
  uuid_generate_v4() AS bc_id, 	--generated id of measurment
  tbwwi.bc_ba_id, 				--fish id (from batch)
  bct.no_id,					--id of type of measurment (eye_diam_vert, eye_diam_horiz, length_pect, presence_neuromast, contrast) 
  dbfa.ba_no_value_type, 		--id of type of value (raw or elaborated)
  tbwwi.contrast, 				--silvering measurment
  dbfa.mei_id,					-- id of measurment from ASPE database
  dbfa.ope_id 					-- id of operation from ASPE
  FROM 
  france.temp_batch_wama_with_id tbwwi 
  join france.dbeel_batch_fish_aspe dbfa ON dbfa.ba_id = tbwwi.bc_ba_id, 
  dbeel_nomenclature.biological_characteristic_type bct 
  WHERE bct.no_name = 'contrast'
  and tbwwi.contrast is not null and length(tbwwi.contrast::text)>0
  --19/10/23 : 0 record

drop table if exists france.temp_batch_wama_with_id ;

/*  WITH bc_size AS (
 SELECT bc_id, bc_ba_id, bc_numvalue AS size FROM france.dbeel_mensurationindiv_biol_charac_aspe  bb
 WHERE bc_no_characteristic_type =39
),
 bc_weight AS (
 SELECT bc_id, bc_ba_id, bc_numvalue AS weight FROM france.dbeel_mensurationindiv_biol_charac_aspe  bb
 WHERE bc_no_characteristic_type =42
),
bc AS (
SELECT bc_size.*, weight FROM bc_size LEFT JOIN bc_weight ON bc_size.bc_ba_id=bc_weight.bc_ba_id),

bcop AS (        
 SELECT ba_ob_id AS ob_id, bc.* FROM bc
JOIN france.dbeel_batch_fish_aspe dboa ON dboa.ba_id=bc.bc_ba_id) */
/*
SELECT * FROM bcop
FULL OUTER JOIN france.batch_silver_wama wam
 ON (bcop.ob_id::TEXT, bcop.size, bcop.weight)=(wam.ope_dbeel_ob_id,wam.length,wam.weight)
 */
 
/* SELECT DISTINCT bcop.ob_id FROM bcop
JOIN france.batch_silver_wama wam
 ON (bcop.ob_id::TEXT)=(wam.ope_dbeel_ob_id) 

 
-- PREMIERE OPERATION
 
SELECT * FROM france.batch_silver_wama  WHERE ope_dbeel_ob_id='c4991ed3-714c-4f74-9619-0d873efb8783'
c4991ed3-714c-4f74-9619-0d873efb8783 79990004133 448.0 3 - [300-450[ 121.0 OK
c4991ed3-714c-4f74-9619-0d873efb8783  79990004133 449.0 3 - [300-450[ 120.0 OK

 */
/* WITH bc_size AS (
 SELECT bc_id, bc_ba_id, bc_numvalue AS size FROM france.dbeel_mensurationindiv_biol_charac_aspe  bb
 WHERE bc_no_characteristic_type =39
),
 bc_weight AS (
 SELECT bc_id, bc_ba_id, bc_numvalue AS weight FROM france.dbeel_mensurationindiv_biol_charac_aspe  bb
 WHERE bc_no_characteristic_type =42
),
bc AS (
SELECT bc_size.*, weight FROM bc_size LEFT JOIN bc_weight ON bc_size.bc_ba_id=bc_weight.bc_ba_id),

bcop AS (        
 SELECT ba_ob_id AS ob_id, bc.* FROM bc
JOIN france.dbeel_batch_fish_aspe dboa ON dboa.ba_id=bc.bc_ba_id)
SELECT * FROM bcop  WHERE bcop.ob_id='c4991ed3-714c-4f74-9619-0d873efb8783'
 
c4991ed3-714c-4f74-9619-0d873efb8783  a73d83da-f339-4c61-af4b-8a18d9dbc262  d24efee6-8dbd-419f-8f8d-6214468e1372  448.0 
c4991ed3-714c-4f74-9619-0d873efb8783  8ab7cfd0-8f27-415c-a568-958ecf84bef2  eb13402e-cabc-4dfe-836b-ecd116622142  449.0 120.0

-- DEUXIEME OPERATION
SELECT * FROM france.batch_silver_wama  WHERE ope_dbeel_ob_id='bdf20f05-0434-4e61-a365-16a42200cb44'
bdf20f05-0434-4e61-a365-16a42200cb44  79990003903 609.0 5 - [600-750[ 357.0 OK
bdf20f05-0434-4e61-a365-16a42200cb44  79990003903 324.0 3 - [300-450[ 66.0 OK
bdf20f05-0434-4e61-a365-16a42200cb44  79990003903 331.0 3 - [300-450[ 67.0 OK
bdf20f05-0434-4e61-a365-16a42200cb44  79990003903 325.0 3 - [300-450[ 58.0 OK


WITH bc_size AS (
 SELECT bc_id, bc_ba_id, bc_numvalue AS size FROM france.dbeel_mensurationindiv_biol_charac_aspe  bb
 WHERE bc_no_characteristic_type =39
),
 bc_weight AS (
 SELECT bc_id, bc_ba_id, bc_numvalue AS weight FROM france.dbeel_mensurationindiv_biol_charac_aspe  bb
 WHERE bc_no_characteristic_type =42
),
bc AS (
SELECT bc_size.*, weight FROM bc_size LEFT JOIN bc_weight ON bc_size.bc_ba_id=bc_weight.bc_ba_id),

bcop AS (        
 SELECT ba_ob_id AS ob_id, bc.* FROM bc
JOIN france.dbeel_batch_fish_aspe dboa ON dboa.ba_id=bc.bc_ba_id)
SELECT * FROM bcop  WHERE bcop.ob_id='bdf20f05-0434-4e61-a365-16a42200cb44'

bdf20f05-0434-4e61-a365-16a42200cb44  0afe49b3-9009-40ba-96b3-a0f0157b490f  33e228d1-9d49-4ba7-b595-b1c5eccd755d  331.0 
bdf20f05-0434-4e61-a365-16a42200cb44  f24bb081-dd9c-451b-bafa-4d6679b80175  0fe54449-9268-49af-aacc-121f62c391d5  324.0 
bdf20f05-0434-4e61-a365-16a42200cb44  503cf751-63f6-4c30-9c73-d3410db8c279  0b1379f3-b02b-49e2-998f-dc334b6f1c7b  609.0 
bdf20f05-0434-4e61-a365-16a42200cb44  2d60ad19-ad06-4c87-b9cf-e4edc46cd17b  1660aa96-1178-488b-a4ab-8a65a018aee6  325.0 58.0 OK
bdf20f05-0434-4e61-a365-16a42200cb44  8675585e-b638-4302-b80f-6e4131ba519e  775e42d4-e7bd-4e84-a0ed-40dc0a0eae80  159.0 5.0 NO


-- TROISIEME OPERATION'26290e2d-ee52-42c7-9787-4573f795bd22'

SELECT * FROM france.batch_silver_wama  WHERE ope_dbeel_ob_id='26290e2d-ee52-42c7-9787-4573f795bd22'
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 357.0 3 - [300-450[ 83.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 283.0 2 - [150-300[ 37.0  OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 301.0 3 - [300-450[ 42.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 257.0 2 - [150-300[ 27.0  OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 303.0 3 - [300-450[ 47.0  OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 287.0 2 - [150-300[ 43.0  OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 422.0 3 - [300-450[ 130.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 392.0 3 - [300-450[ 101.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 281.0 2 - [150-300[ 40.0  OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 276.0 2 - [150-300[ 38.0  OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 397.0 3 - [300-450[ 121.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 292.0 2 - [150-300[ 48.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 412.0 3 - [300-450[ 153.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  19010002030 277.0 2 - [150-300[ 34.0 OK


WITH bc_size AS (
 SELECT bc_id, bc_ba_id, bc_numvalue AS size FROM france.dbeel_mensurationindiv_biol_charac_aspe  bb
 WHERE bc_no_characteristic_type =39
),
 bc_weight AS (
 SELECT bc_id, bc_ba_id, bc_numvalue AS weight FROM france.dbeel_mensurationindiv_biol_charac_aspe  bb
 WHERE bc_no_characteristic_type =42
),
bc AS (
SELECT bc_size.*, weight FROM bc_size LEFT JOIN bc_weight ON bc_size.bc_ba_id=bc_weight.bc_ba_id),

bcop AS (        
 SELECT ba_ob_id AS ob_id, bc.* FROM bc
JOIN france.dbeel_batch_fish_aspe dboa ON dboa.ba_id=bc.bc_ba_id)
SELECT * FROM bcop  WHERE bcop.ob_id='26290e2d-ee52-42c7-9787-4573f795bd22'

26290e2d-ee52-42c7-9787-4573f795bd22  3b966b5c-f8ba-4f1d-b038-774a39eb0e7a  b6799273-a6b6-4bd1-b909-2c37790a88d0  292.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  9bab933a-6cca-4ce4-a9af-32a82bad984b  41620e38-5e86-4304-b658-032537c10084  433.0 NO
26290e2d-ee52-42c7-9787-4573f795bd22  f38ce266-dcef-4162-8f7c-211d6707993a  06a08f91-29c6-4bee-adf4-94a0c134e161  287.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  37fd5e84-42d6-4d22-9750-513e19b7a523  9931d36f-a614-4d83-815b-edff22e0176c  170.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  ed035230-a9a7-4be3-9588-4229ea64a493  b2170b06-2ba5-4468-bf13-9832b051b3a3  418.0 NO
26290e2d-ee52-42c7-9787-4573f795bd22  14b61825-5dac-400f-b630-fd7b80bc85ff  0011c27c-297d-420b-b3c1-ac7c4b0f020f  413.0 NO
26290e2d-ee52-42c7-9787-4573f795bd22  7cf3fdd7-4143-44ef-91d1-902bec4a483c  ccbe810a-8cef-49f8-9282-55d601202e23  510.0 NO
26290e2d-ee52-42c7-9787-4573f795bd22  93ae3702-bf96-4efc-9d07-676fb15d75ab  e2c375cf-1f8e-48ff-8ffc-c06e0eeb3bed  203.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  3e35376b-5b37-4625-a72b-cee8c6f49410  cca08028-a783-4675-a399-0a4b238affd1  240.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  f8cd30d5-4be9-4e13-bdb5-feeb15d5ed7a  ef867f62-6000-41b0-a1e1-508f6e7987f1  265.0 NO
26290e2d-ee52-42c7-9787-4573f795bd22  dfb8817f-ee48-4de0-92e2-bbc86472ef44  77f2bd2a-fa52-4b39-a96a-4e07af619f3c  400.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  32f2380f-dd56-4d08-9c32-09af6f4fedc4  643204fb-e000-4cdf-9f2d-34f125b5b0b9  276.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  8d0afacc-2ddf-4225-9433-8599a78ef82f  29e89964-8295-44b3-a70b-ee9393c51f54  443.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  8592f6ce-8a60-40f2-957a-17489d261cf7  e0049585-19ae-416d-943c-2fc314425e6f  236.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  2a8daff7-9f11-4f96-9766-dd3b325b2186  827598f7-cfab-4176-91ee-d1989cd36b60  281.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  d0c59da4-0c71-4c81-92ef-c70fb57b4475  585d7480-a909-4d78-87d1-8d8182d15284  283.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  9b6532cc-1d61-48b6-b493-a4fc53631537  836d25bb-f193-481f-9966-0317ea4c808a  462.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  fc22da01-55bc-48c0-80b2-8c294e36c7f3  d9a2f1b2-be1a-472e-bb43-a6ee9a56e7aa  400.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  4fc4f0fa-b68e-4bd1-b9fa-bae2a5cb94e4  e68a4c71-b1e9-4a94-a967-1240cda8b845  202.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  bfc2c5e8-260d-43ab-8e5d-d8b91878a11d  70abbbef-6007-4359-ba6e-a6591b441b97  397.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  79db6127-6220-4bb9-8b9a-e4094f0709ec  465ac2b1-4c61-453b-b0e5-a13c1ec2ddd7  402.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  e72a94e1-23bc-45d0-aef0-709216ae43c0  391e4596-25de-460a-b87e-b934d005f345  257.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  266cf6d9-30c4-48a0-98b6-a104109ad4f3  05247632-f2f0-490f-a417-c483ca1ad3b2  503.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  c5e97e8f-e277-478e-8ff2-9c243af311f5  618cd7b4-fe28-4809-bb68-e6719f1cae4e  303.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  f1f0cce9-e14f-4771-97fe-eb470d312ba4  b3766d04-b868-4310-b6dc-84f193637c22  455.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  84d774fe-37cf-44b0-ae7f-1199de957e51  9a1393bb-c3a7-4c15-b2d0-f4377f1ed3e0  478.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  9658d8ff-c9f8-4c66-b315-880c3ba30eb3  424ac175-e4d5-4e34-acd6-1331ab7572ba  282.0 NO
26290e2d-ee52-42c7-9787-4573f795bd22  401e6639-d59b-42f9-b379-2ced71a82be9  ad68eb78-ca5d-44ed-b79a-c385fc630ee3  412.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  28284a49-0983-458e-a15c-a4a5149a50b6  6a366055-7842-410e-9639-ffe5f3c2c467  169.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  99f2f503-3de1-441f-a501-1e6692c6edc4  6eb95beb-de4e-411d-860a-d05da4852060  315.0  NO
26290e2d-ee52-42c7-9787-4573f795bd22  2c9cf43e-c8bd-45c9-b706-fe2ddb72973a  42d9be88-9435-41f5-b4c6-f79114cc4741  172.0 9.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  60911de9-41d3-485b-aa0e-46dae20bac3e  e9a46958-bd10-4db1-9d9e-0ef18a98d7b8  301.0 42.0 NO
26290e2d-ee52-42c7-9787-4573f795bd22  0e33a75d-1556-4ab2-b59f-ec8633da12bc  af6da92c-eb48-4c3b-b3b4-8d155648f6d4  392.0 101.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  cbdff159-bebc-486f-af67-63f7a7498339  b46d7624-8e76-4090-9211-e8e53c5253af  119.0 3.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  1dfcceff-b19e-4218-985b-0720e364c684  183b9562-6275-45cb-809c-92e5c785494e  277.0 34.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  71e197ad-f41a-49de-8997-8e56bf76a7ff  cf799985-fe51-4235-9901-629dc451b1fd  195.0 13.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  5fdd434d-76f1-490f-9538-b8eb24875a09  f12fab0f-ea2c-4bd0-910c-71589cbb4013  183.0 11.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  c9e78379-8558-4567-a0e5-d3ca935aa7c4  ce70f1a8-a83d-44f9-9e53-2b6cd423cb35  357.0 83.0 OK
26290e2d-ee52-42c7-9787-4573f795bd22  763aa482-4bad-48ac-ab01-4511bb9bcc88  059f63a3-5e11-4335-9773-b4a2fdbbd1fe  210.0 16.0 -
26290e2d-ee52-42c7-9787-4573f795bd22  cb32705c-6b97-4fab-bf95-1d7c2ac93531  c6788b0b-554a-4d93-b92d-bc3a914bb0fe  422.0 130.0 OK


SELECT *  FROM france.dbeel_batch_fish_aspe dboa WHERE ba_ob_id= '26290e2d-ee52-42c7-9787-4573f795bd22'; => ope_id==4609
 */
--TODO FINISH DATA INPUT