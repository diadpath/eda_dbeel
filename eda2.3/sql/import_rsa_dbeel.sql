
/*
dbeel.establishment
dbeel.data_provider
*/


---------------------------------------------
-- SCRIPT INTEGRATION RSA => DBEEL me 08/07/2022 Clarisse/ Denis / Cédric
--TODO Pour l'instant les diamètres occulaires ne sont pas là !
---------------------------------------------


-- Correction clarisse

update rsa.anguille_ang set ang_pas=1 
where ang_op_id in (361,362,367,498,507,511,512,513,514,515,523)
and ang_zone='ap';
update rsa.anguille_ang set ang_poids=NULL where ang_poids=0; --9113
-- correction de Clarisse
update rsa.op_inv set inv_p3=NULL where inv_npas=2 and inv_p3 is not NULL;

-- select * from dbeel.establishment;

--select * from dbeel.data_provider
--select max(dp_id) from dbeel.data_provider; -- 25


-- Creation de data providers à partir des noms de la table RSA

INSERT INTO  dbeel.data_provider ( dp_name, dp_et_id) 
SELECT prod_libelle, 27 FROM rsa.producteurs_prod; --17
ALTER SEQUENCE dbeel.data_provider_dp_id_seq RESTART WITH 38;


-- TABLES FOR IMPORT will be created IN France AND IN loire schema (for electrofishing from f�d�rations de p�che)
-- script for creating station is in eda_dbeel/eda2.3/R/rsa_import.R






--SELECT * FROM rsa.station s ;

--SELECT DISTINCT(st_srid(geom)) FROM rsa.station; -- il y a des NULLS
-- Mise à jours de champs geom manquants (travail en cours de Clarisse)
UPDATE rsa.station SET geom = ST_GeomFromText('POINT(' ||sta_x93 || ' ' || sta_y93 || ')', 2154)
WHERE geom IS NULL; --20


SELECT * FROM dbeel.observation_places;
-- Create the stationdbeel table from dbeel



DROP TABLE if exists france.dbeel_station_rsa CASCADE;
CREATE TABLE france.dbeel_station_rsa (
  sta_id INTEGER,
	sta_cod TEXT, 
	sta_code TEXT,
	sta_zone TEXT,
	fleuve_lib TEXT,
	sta_reseau  TEXT,
  country character varying(2),
	CONSTRAINT pk_rsa_op_id PRIMARY KEY (op_id),
	CONSTRAINT c_uk_rsa_sta_id_sta_cod UNIQUE (sta_id,sta_zone),
	CONSTRAINT fk_rsa_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);

COMMENT ON  COLUMN france.dbeel_station_rsa.sta_cod IS 'Code opérateur original avec dièses de wama remplacés par des underscore';
COMMENT ON  COLUMN  france.dbeel_station_rsa.sta_code IS 'Code opérateur original';

--select * from france.dbeel_station_rsa limit 10;

/*
DELETE FROM  france.dbeel_station_rsa; 
DELETE FROM france.dbeel_electrofishing_rsa; 
*/

-- SELECT * FROM france.station_rsa;
-- Insert data into the dbeel table
INSERT INTO france.dbeel_station_rsa 
	SELECT  uuid_generate_v4() AS op_id, -- UNIQUE identifier
	'3035' AS op_gis_systemname ,
	'RSA' AS op_gis_layername, 
	NULL AS op_gislocation, 
	sta_lib AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	st_transform(geom,3035)  as the_geom,
	sta_id,
	sta_cod, 
  sta_code,
  sta_zone,
  fleuve_lib,
  sta_reseau,
  'FR' AS country 
	FROM rsa.station LEFT JOIN rsa.bassin_bas ON station.sta_bas_id=bassin_bas.bas_id
	;  --1793

------------------------------
--retour des identifiants dans la TABLE mère
--------------------------------
	
	--UPDATE rsa.station SET sta_dbeel_op_id =NULL; --1757
	-- ALTER TABLE rsa.station ADD COLUMN sta_dbeel_op_id UUID;
	UPDATE rsa.station SET sta_dbeel_op_id = op_id FROM
 france.dbeel_station_rsa WHERE dbeel_station_rsa.sta_code=dbeel_station_rsa.sta_code; --1793

	

/*--------------------------------------------------
-- rsa.electrofishing	
-------------------------------------------------*/
	
-- SELECT * FROM rsa.operation oa ;


--SELECT * from dbeel.electrofishing limit 10;


DROP TABLE if exists france.dbeel_electrofishing_rsa CASCADE;

CREATE TABLE france.dbeel_electrofishing_rsa(
 op_id INTEGER,
 op_zone TEXT,
 op_typ TEXT,
 op_sta_id INTEGER,
	CONSTRAINT pk_rsa_ob_id PRIMARY KEY (ob_id),
	CONSTRAINT fk_rsa_op_id FOREIGN KEY (ob_op_id)	
		REFERENCES france.dbeel_station_rsa (op_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_rsa_dp_id FOREIGN KEY (ob_dp_id)	
		REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_rsa_electrofishing_mean FOREIGN KEY (ef_no_electrofishing_mean)
		REFERENCES dbeel_nomenclature.electrofishing_mean (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_rsa_electrofishing_method FOREIGN KEY (ef_no_fishingmethod)
		REFERENCES dbeel_nomenclature.scientific_observation_method (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_rsa_ob_no_origin FOREIGN KEY (ob_no_origin)
		REFERENCES dbeel_nomenclature.observation_origin (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_rsa_ob_no_period FOREIGN KEY (ob_no_period)
		REFERENCES dbeel_nomenclature.period_type (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_rsa_ob_no_type FOREIGN KEY (ob_no_type)
		REFERENCES dbeel_nomenclature.observation_type (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.electrofishing);

-----------------------------
-- I electrofishing 
----------------------------
/*
ALTER TABLE rsa.station ADD CONSTRAINT c_fk_sta_prod_id FOREIGN KEY (sta_prod_id)
REFERENCES rsa.producteurs_prod(prod_id) 
ON UPDATE CASCADE ON DELETE RESTRICT;


COMMENT ON table rsa.op_iaa IS 'Pêche continue des deux berges en bateau';
COMMENT ON table rsa.op_iaa IS 'Pêche continue des deux berges à pied';
*/

/*
For the moment we set the type of electrofishing to unknown (61), later for some fishing we with use whole (62)
*/
/*select * from france.dbeel_station_rsa limit 10;
select * from rsa.operation limit 10; --43695
SELECT * FROM  france.dbeel_station_rsa sta
   JOIN rsa.operation ope ON (sta.id, sat.sta_zone) = (ope.sta_id, op_zone)
*/
-- The import is done in two times as some operations do not have sta_id, it must be loaded from point_prelevement_rsa

--DELETE FROM france.dbeel_electrofishing_rsa;
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
306 EP  Scientific_observation_type EPA Electro-fishing Partial point sampling with density current, protocol Feunteun, Rigaud
**/

--SELECT DISTINCT op_typ FROM rsa.operation;
/*
|op_typ|
|------|
|inv   |
|epap  |
|pcbgb |
|pcbgp |
|epab  |
|iaa   |

*/

-- TODO inserer le ope_prod_id dans la table rsa.operation + le lien vers les ob_id

/*
SELECT * FROM rsa.producteurs_prod AS pp JOIN 
dbeel.data_provider ON dp_name= prod_libelle
-- 1 insersion de inv
DELETE FROM france.dbeel_electrofishing_rsa; -- très long
*/
INSERT INTO france.dbeel_electrofishing_rsa (
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
	op_id ,
 op_zone,
 op_typ ,
  op_sta_id
	)
SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	ope.op_date::date AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	CASE WHEN op_typ = 'inv' THEN 62
	     WHEN op_typ IN ('pcbgb', 'pcbgp') THEN 302 -- pêche CONTINUE des berges
	     WHEN op_typ LIKE '%epa%' THEN 306
	     WHEN op_typ LIKE '%iaa%' THEN 303 
       WHEN op_typ ILIKE '%anguille%' THEN 303	
	END AS ef_no_fishingmethod,
	CASE WHEN op_typ IN ('inv','iaa','epap', 'pcbgp')  THEN 71  -- a pied
	     WHEN op_typ IN ('pcbgb', 'epab') THEN 72	    
	     ELSE 70 -- unknown
	END AS ef_no_electrofishing_mean,	
	op_inv.inv_long * op_inv.inv_larg AS ef_wetted_area, 
	op_inv.inv_long AS ef_fished_length,
	op_inv.inv_larg AS ef_fished_width,
	NULL AS ef_duration,
	op_inv.inv_npas AS ef_nbpas,	     
	sta.op_id as ob_op_id,
	ope.op_id,
  ope.op_zone,
  ope.op_typ, 
  ope.op_sta_id 
	FROM 	
  france.dbeel_station_rsa sta
  JOIN rsa.station  starsa ON (starsa.sta_id, starsa.sta_zone) = (sta.sta_id, sta.sta_zone)   
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)  -- JOIN donc les operations sans sta_id sont gardées
  JOIN rsa.producteurs_prod ON prod_id=starsa.sta_prod_id
  JOIN rsa.op_inv  ON (op_inv.inv_op_id, op_inv.inv_zone)= (ope.op_id, ope.op_zone)
  LEFT JOIN dbeel.data_provider ON dp_name= prod_libelle,
	 dbeel_nomenclature.observation_origin,
	dbeel_nomenclature.observation_type,
	 dbeel_nomenclature.period_type 			
	WHERE observation_origin.no_name='Raw data' 
	AND observation_type.no_name='Electro-fishing' 
	AND period_type.no_name='Daily' 
	; --950 ROWS 28s
	



 -- 2 insersion de iaa
INSERT INTO france.dbeel_electrofishing_rsa (
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
  op_id ,
 op_zone,
 op_typ ,
  op_sta_id
  )
SELECT 
  uuid_generate_v4() AS ob_id ,
  observation_origin.no_id AS ob_no_origin,
  observation_type.no_id AS ob_no_type, 
  period_type.no_id AS ob_no_period,
  ope.op_date::date AS ob_starting_date,
  CAST(NULL AS date) as ob_ending_date,
  data_provider.dp_id AS ob_dp_id, 
  CASE WHEN op_typ = 'inv' THEN 62
       WHEN op_typ IN ('pcbgb', 'pcbgp') THEN 302 -- pêche CONTINUE des berges
       WHEN op_typ LIKE '%epa%' THEN 306
       WHEN op_typ LIKE '%iaa%' THEN 303 
       WHEN op_typ ILIKE '%anguille%' THEN 303  
  END AS ef_no_fishingmethod,
  CASE WHEN op_typ IN ('inv','iaa','epap', 'pcbgp')  THEN 71  -- a pied
       WHEN op_typ IN ('pcbgb', 'epab') THEN 72     
       ELSE 70 -- unknown
  END AS ef_no_electrofishing_mean, 
  op_iaa.iaa_npnt * 12.5 AS ef_wetted_area, 
  NULL AS ef_fished_length,
  NULL AS ef_fished_width,
  NULL AS ef_duration,
  1 AS ef_nbpas,       
  sta.op_id as ob_op_id,
  ope.op_id,
  ope.op_zone,
  ope.op_typ, 
  ope.op_sta_id 
  FROM  
  france.dbeel_station_rsa sta
  JOIN rsa.station  starsa ON (starsa.sta_id, starsa.sta_zone) = (sta.sta_id, sta.sta_zone)   
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)  -- JOIN donc les operations sans sta_id sont gardées
  JOIN rsa.producteurs_prod ON prod_id=starsa.sta_prod_id
  JOIN rsa.op_iaa  ON (op_iaa.iaa_op_id, op_iaa.iaa_zone)= (ope.op_id, ope.op_zone)
  LEFT JOIN dbeel.data_provider ON dp_name= prod_libelle,
   dbeel_nomenclature.observation_origin,
  dbeel_nomenclature.observation_type,
   dbeel_nomenclature.period_type       
  WHERE observation_origin.no_name='Raw data' 
  AND observation_type.no_name='Electro-fishing' 
  AND period_type.no_name='Daily' 
  ; --2221 ROWS 28s (2499 avant)
  

 --3 insersion de epab
INSERT INTO france.dbeel_electrofishing_rsa (
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
  op_id ,
 op_zone,
 op_typ ,
  op_sta_id
  )
SELECT 
  uuid_generate_v4() AS ob_id ,
  observation_origin.no_id AS ob_no_origin,
  observation_type.no_id AS ob_no_type, 
  period_type.no_id AS ob_no_period,
  ope.op_date::date AS ob_starting_date,
  CAST(NULL AS date) as ob_ending_date,
  data_provider.dp_id AS ob_dp_id, 
  CASE WHEN op_typ = 'inv' THEN 62
       WHEN op_typ IN ('pcbgb', 'pcbgp') THEN 302 -- pêche CONTINUE des berges
       WHEN op_typ LIKE '%epa%' THEN 306
       WHEN op_typ LIKE '%iaa%' THEN 303 
       WHEN op_typ ILIKE '%anguille%' THEN 303  
  END AS ef_no_fishingmethod,
  CASE WHEN op_typ IN ('inv','iaa','epap', 'pcbgp')  THEN 71  -- a pied
       WHEN op_typ IN ('pcbgb', 'epab') THEN 72     
       ELSE 70 -- unknown
  END AS ef_no_electrofishing_mean, 
  op_epab.epab_npnt * 12.5 AS ef_wetted_area, 
  NULL AS ef_fished_length,
  NULL AS ef_fished_width,
  NULL AS ef_duration,
  1 AS ef_nbpas,       
  sta.op_id as ob_op_id,
  ope.op_id,
  ope.op_zone,
  ope.op_typ, 
  ope.op_sta_id 
  FROM  
  france.dbeel_station_rsa sta
  JOIN rsa.station  starsa ON (starsa.sta_id, starsa.sta_zone) = (sta.sta_id, sta.sta_zone)   
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)  -- JOIN donc les operations sans sta_id sont gardées
  JOIN rsa.producteurs_prod ON prod_id=starsa.sta_prod_id
  JOIN rsa.op_epab  ON (op_epab.epab_op_id, op_epab.epab_zone)= (ope.op_id, ope.op_zone)
  LEFT JOIN dbeel.data_provider ON dp_name= prod_libelle,
   dbeel_nomenclature.observation_origin,
  dbeel_nomenclature.observation_type,
   dbeel_nomenclature.period_type       
  WHERE observation_origin.no_name='Raw data' 
  AND observation_type.no_name='Electro-fishing' 
  AND period_type.no_name='Daily' 
  ; --152 ROWS 28s
  
 -- 4 insetion de pcbgb

INSERT INTO france.dbeel_electrofishing_rsa (
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
  op_id ,
 op_zone,
 op_typ ,
  op_sta_id
  )
SELECT 
  uuid_generate_v4() AS ob_id ,
  observation_origin.no_id AS ob_no_origin,
  observation_type.no_id AS ob_no_type, 
  period_type.no_id AS ob_no_period,
  ope.op_date::date AS ob_starting_date,
  CAST(NULL AS date) as ob_ending_date,
  data_provider.dp_id AS ob_dp_id, 
  CASE WHEN op_typ = 'inv' THEN 62
       WHEN op_typ IN ('pcbgb', 'pcbgp') THEN 302 -- pêche CONTINUE des berges
       WHEN op_typ LIKE '%epa%' THEN 306
       WHEN op_typ LIKE '%iaa%' THEN 303 
       WHEN op_typ ILIKE '%anguille%' THEN 303   
  END AS ef_no_fishingmethod,
  CASE WHEN op_typ IN ('inv','iaa','epap', 'pcbgp')  THEN 71  -- a pied
       WHEN op_typ IN ('pcbgb', 'epab') THEN 72    
       ELSE 70 -- unknown
  END AS ef_no_electrofishing_mean, 
  op_pcbgb.pcbgb_long * 4 AS ef_wetted_area, -- two banks * 2 = 2*2
  pcbgb_long AS ef_fished_length,
  pcbgb_larg AS ef_fished_width,
  NULL AS ef_duration,
  pcbgb_npas AS ef_nbpas,       
  sta.op_id as ob_op_id,
  ope.op_id,
  ope.op_zone,
  ope.op_typ, 
  ope.op_sta_id 
  FROM  
  france.dbeel_station_rsa sta
  JOIN rsa.station  starsa ON (starsa.sta_id, starsa.sta_zone) = (sta.sta_id, sta.sta_zone)   
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)  -- JOIN donc les operations sans sta_id sont gardées
  JOIN rsa.producteurs_prod ON prod_id=starsa.sta_prod_id
  JOIN rsa.op_pcbgb  ON (op_pcbgb.pcbgb_op_id, op_pcbgb.pcbgb_zone)= (ope.op_id, ope.op_zone)
  LEFT JOIN dbeel.data_provider ON dp_name= prod_libelle,
   dbeel_nomenclature.observation_origin,
  dbeel_nomenclature.observation_type,
   dbeel_nomenclature.period_type       
  WHERE observation_origin.no_name='Raw data' 
  AND observation_type.no_name='Electro-fishing' 
  AND period_type.no_name='Daily' 
  ; --177 ROWS 28s 
  
-- 4 insetion de pcbgp

INSERT INTO france.dbeel_electrofishing_rsa (
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
  op_id ,
 op_zone,
 op_typ ,
  op_sta_id
  )
SELECT 
  uuid_generate_v4() AS ob_id ,
  observation_origin.no_id AS ob_no_origin,
  observation_type.no_id AS ob_no_type, 
  period_type.no_id AS ob_no_period,
  ope.op_date::date AS ob_starting_date,
  CAST(NULL AS date) as ob_ending_date,
  data_provider.dp_id AS ob_dp_id, 
  CASE WHEN op_typ = 'inv' THEN 62
       WHEN op_typ IN ('pcbgb', 'pcbgp') THEN 302 -- pêche CONTINUE des berges
       WHEN op_typ LIKE '%epa%' THEN 306
       WHEN op_typ LIKE '%iaa%' THEN 303 
       WHEN op_typ ILIKE '%anguille%' THEN 303   
  END AS ef_no_fishingmethod,
  CASE WHEN op_typ IN ('inv','iaa','epap', 'pcbgp')  THEN 71  -- a pied
       WHEN op_typ IN ('pcbgb', 'epab') THEN 72    
       ELSE 70 -- unknown
  END AS ef_no_electrofishing_mean, 
  op_pcbgp.pcbgp_long * 4 AS ef_wetted_area, -- two banks * 2 = 2*2
  pcbgp_long AS ef_fished_length,
  pcbgp_larg AS ef_fished_width,
  NULL AS ef_duration,
  pcbgp_npas AS ef_nbpas,       
  sta.op_id as ob_op_id,
  ope.op_id,
  ope.op_zone,
  ope.op_typ, 
  ope.op_sta_id 
  FROM  
  france.dbeel_station_rsa sta
  JOIN rsa.station  starsa ON (starsa.sta_id, starsa.sta_zone) = (sta.sta_id, sta.sta_zone)   
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)  -- JOIN donc les operations sans sta_id sont gardées
  JOIN rsa.producteurs_prod ON prod_id=starsa.sta_prod_id
  JOIN rsa.op_pcbgp  ON (op_pcbgp.pcbgp_op_id, op_pcbgp.pcbgp_zone)= (ope.op_id, ope.op_zone)
  LEFT JOIN dbeel.data_provider ON dp_name= prod_libelle,
   dbeel_nomenclature.observation_origin,
  dbeel_nomenclature.observation_type,
   dbeel_nomenclature.period_type       
  WHERE observation_origin.no_name='Raw data' 
  AND observation_type.no_name='Electro-fishing' 
  AND period_type.no_name='Daily' 
  ; --17 ROWS 28s   
  
  
  
--7 insersion de epap
INSERT INTO france.dbeel_electrofishing_rsa (
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
  op_id ,
 op_zone,
 op_typ ,
  op_sta_id
  )
SELECT 
  uuid_generate_v4() AS ob_id ,
  observation_origin.no_id AS ob_no_origin,
  observation_type.no_id AS ob_no_type, 
  period_type.no_id AS ob_no_period,
  ope.op_date::date AS ob_starting_date,
  CAST(NULL AS date) as ob_ending_date,
  data_provider.dp_id AS ob_dp_id, 
  CASE WHEN op_typ = 'inv' THEN 62
       WHEN op_typ IN ('pcbgb', 'pcbgp') THEN 302 -- pêche CONTINUE des berges
       WHEN op_typ LIKE '%epa%' THEN 306
       WHEN op_typ LIKE '%iaa%' THEN 303 
       WHEN op_typ ILIKE '%anguille%' THEN 303  
  END AS ef_no_fishingmethod,
  CASE WHEN op_typ IN ('inv','iaa','epap', 'pcbgp')  THEN 71  -- a pied
       WHEN op_typ IN ('pcbgb', 'epab') THEN 72      
       ELSE 70 -- unknown
  END AS ef_no_electrofishing_mean, 
  op_epap.epap_npnt * 12.5 AS ef_wetted_area, 
  NULL AS ef_fished_length,
  NULL AS ef_fished_width,
  NULL AS ef_duration,
  1 AS ef_nbpas,       
  sta.op_id as ob_op_id,
  ope.op_id,
  ope.op_zone,
  ope.op_typ, 
  ope.op_sta_id 
  FROM  
  france.dbeel_station_rsa sta
  JOIN rsa.station  starsa ON (starsa.sta_id, starsa.sta_zone) = (sta.sta_id, sta.sta_zone)   
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)  -- JOIN donc les operations sans sta_id sont gardées
  JOIN rsa.producteurs_prod ON prod_id=starsa.sta_prod_id
  JOIN rsa.op_epap  ON (op_epap.epap_op_id, op_epap.epap_zone)= (ope.op_id, ope.op_zone)
  LEFT JOIN dbeel.data_provider ON dp_name= prod_libelle,
   dbeel_nomenclature.observation_origin,
  dbeel_nomenclature.observation_type,
   dbeel_nomenclature.period_type       
  WHERE observation_origin.no_name='Raw data' 
  AND observation_type.no_name='Electro-fishing' 
  AND period_type.no_name='Daily' 
  ; --132 ROWS 28s
   
--ALTER TABLE rsa.operation ADD COLUMN ope_dbeel_ob_id UUID;
UPDATE rsa.operation SET ope_dbeel_ob_id= NULL; --3928

SELECT count(*) FROM france.dbeel_electrofishing_rsa;--3649

WITH the_join AS (
SELECT ob_id, rsa.operation.* FROM 
 france.dbeel_electrofishing_rsa 
 JOIN rsa.operation ON  (operation.op_id, operation.op_zone) = 
 (dbeel_electrofishing_rsa.op_id, dbeel_electrofishing_rsa.op_zone)
 )
UPDATE rsa.operation SET ope_dbeel_ob_id = ob_id FROM the_join
WHERE (operation.op_id, operation.op_zone) =  (the_join.op_id, the_join.op_zone)
AND  operation.ope_dbeel_ob_id IS NULL; --3649

	



	
/*	
SELECT * FROM france.dbeel_electrofishing_rsa LIMIT 10;

*/
	


--------------------------------------------	
-- NUMBER PER PASS... AND TOTAL NUMBER
-- BATCH INTEGRATION
-- WE DON'T NEED DENSITY, WILL BE RECALCULATED LATER
--------------------------------------------

-- Drop table

-- SELECT  * FROM france.batch_rsa 

 
DROP TABLE france.dbeel_batch_ope_rsa;
CREATE TABLE france.dbeel_batch_ope_rsa (
  op_id int4 NULL,
  op_zone TEXT,
  CONSTRAINT pk_batch_rsa_ba_id PRIMARY KEY (ba_id),
  CONSTRAINT c_fk_rsa_ba_ob_id FOREIGN KEY (ba_ob_id) REFERENCES france.dbeel_electrofishing_rsa(ob_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_rsa_ba_no_biological_characteristic_type FOREIGN KEY (ba_no_biological_characteristic_type) REFERENCES dbeel_nomenclature.biological_characteristic_type(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_rsa_ba_no_individual_status FOREIGN KEY (ba_no_individual_status) REFERENCES dbeel_nomenclature.individual_status(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_rsa_ba_no_species_id FOREIGN KEY (ba_no_species) REFERENCES dbeel_nomenclature.species(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_rsa_ba_no_stage_id FOREIGN KEY (ba_no_stage) REFERENCES dbeel_nomenclature.stage(no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_batch_ope_rsa_ba_value_type FOREIGN KEY (ba_no_value_type) REFERENCES dbeel_nomenclature.value_type(no_id) ON DELETE RESTRICT ON UPDATE CASCADE
)
INHERITS (dbeel.batch);

-- nbeel inv
--DELETE FROM france.dbeel_batch_ope_rsa;

INSERT INTO france.dbeel_batch_ope_rsa
WITH correct_moins_9 AS (
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  CASE WHEN inv_p1 =-9 THEN NULL::numeric END AS inv_p1,
  CASE WHEN inv_p2 =-9 THEN NULL::numeric END AS inv_p2,
  CASE WHEN inv_p3 =-9 THEN NULL::numeric END AS inv_p3,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_inv  ON (op_inv.inv_op_id, op_inv.inv_zone)= (ope.op_id, ope.op_zone),
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
  )
  
SELECT 
 ba_id,
  ba_no_species,
  ba_no_stage,
  ba_no_value_type,
  ba_no_biological_characteristic_type,
  COALESCE(inv_p1,0)+ 
  COALESCE(inv_p2,0) + 
  COALESCE(inv_p3,0) AS   ba_quantity,  
  ba_no_individual_status,
  ba_batch_level,
  ba_ob_id, 
  ba_ba_id,
  op_id,
  op_zone
  FROM correct_moins_9; --950

  /*--------------------
   SELECT * FROM rsa.op_iaa
   EXCEPT
  SELECT op_iaa.*
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_iaa  ON (op_iaa.iaa_op_id, op_iaa.iaa_zone)= (ope.op_id, ope.op_zone)

|iaa_id|iaa_op_id|iaa_npnt|iaa_ang|iaa_vue|iaa_zone  |
|------|---------|--------|-------|-------|----------|
|123   |123      |30      |0      |0      |lcvlogrami|

123 n'a pas de station c'est de là que le pb vient
Et la station a été écartée à cause de coordonnées fausses
   */
  
-- nbeel iaa  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  iaa_ang AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_iaa  ON (op_iaa.iaa_op_id, op_iaa.iaa_zone)= (ope.op_id, ope.op_zone),
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
  ; --2221
  
-- nbeel pcbgp  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  COALESCE(pcbgp_p1,0)+ 
  COALESCE(pcbgp_p2,0) + 
  COALESCE(pcbgp_p3,0) AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_pcbgp  ON (op_pcbgp.pcbgp_op_id, op_pcbgp.pcbgp_zone)= (ope.op_id, ope.op_zone),
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
  ; --17
  
-- nbeel pcbgb  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
   COALESCE(pcbgb_p1,0)+ 
  COALESCE(pcbgb_p2,0) + 
  COALESCE(pcbgb_p3,0) AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_pcbgb  ON (op_pcbgb.pcbgb_op_id, op_pcbgb.pcbgb_zone)= (ope.op_id, ope.op_zone),
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
  ; --177
  
 -- nbeel epab  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  epab_ang AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_epab  ON (op_epab.epab_op_id, op_epab.epab_zone)= (ope.op_id, ope.op_zone),
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
  ; --152   

   -- nbeel epap  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  epap_ang AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_epap  ON (op_epap.epap_op_id, op_epap.epap_zone)= (ope.op_id, ope.op_zone),
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
  ; --132   
  
  


  
  
  
-- number p1
  
-- number p1 inv

INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  inv_p1 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_inv  ON (op_inv.inv_op_id, op_inv.inv_zone)= (ope.op_id, ope.op_zone),
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
  ; --950
  
  
-- number p1 iaa  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  iaa_ang AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_iaa  ON (op_iaa.iaa_op_id, op_iaa.iaa_zone)= (ope.op_id, ope.op_zone),
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
  ; --2221
  
-- number p1 pcbgp  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  pcbgp_p1  AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_pcbgp  ON (op_pcbgp.pcbgp_op_id, op_pcbgp.pcbgp_zone)= (ope.op_id, ope.op_zone),
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
  ; --17
  
-- number p1 op_pcbgb  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  pcbgb_p1 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_pcbgb  ON (op_pcbgb.pcbgb_op_id, op_pcbgb.pcbgb_zone)= (ope.op_id, ope.op_zone),
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
  ; --177
  
 -- number p1 epab  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  epab_ang AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_epab  ON (op_epab.epab_op_id, op_epab.epab_zone)= (ope.op_id, ope.op_zone),
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
  ; --152   

   -- number p1 epap  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  epap_ang AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_epap  ON (op_epap.epap_op_id, op_epap.epap_zone)= (ope.op_id, ope.op_zone),
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
  ; --132    
  
  
  
-- number p2
	
--	SELECT * FROM france.dbeel_electrofishing_rsa
  
  
  -- number p2 inv

INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  inv_p2 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_inv  ON (op_inv.inv_op_id, op_inv.inv_zone)= (ope.op_id, ope.op_zone),
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
  ; --950
  
  -- number p2 pcbgp  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  pcbgp_p2  AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_pcbgp  ON (op_pcbgp.pcbgp_op_id, op_pcbgp.pcbgp_zone)= (ope.op_id, ope.op_zone),
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
  ; --17
  
-- number p2 op_pcbgb  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  pcbgb_p2 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_pcbgb  ON (op_pcbgb.pcbgb_op_id, op_pcbgb.pcbgb_zone)= (ope.op_id, ope.op_zone),
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
  ; --177
  
-- number p3



-- inv p3  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  inv_p3 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_inv  ON (op_inv.inv_op_id, op_inv.inv_zone)= (ope.op_id, ope.op_zone),
  dbeel_nomenclature.species, 
  dbeel_nomenclature.stage, 
  dbeel_nomenclature.biological_characteristic_type,
  dbeel_nomenclature.value_type,
  dbeel_nomenclature.individual_status 
  WHERE species.no_name='Anguilla anguilla'
  AND stage.no_name='Yellow eel' -- we actually don't know that...
  AND biological_characteristic_type.no_name='Number p3' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  AND inv_npas=3
  ; --59
  
  -- number p3 pcbgp  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  pcbgp_p3  AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_pcbgp  ON (op_pcbgp.pcbgp_op_id, op_pcbgp.pcbgp_zone)= (ope.op_id, ope.op_zone),
  dbeel_nomenclature.species, 
  dbeel_nomenclature.stage, 
  dbeel_nomenclature.biological_characteristic_type,
  dbeel_nomenclature.value_type,
  dbeel_nomenclature.individual_status 
  WHERE species.no_name='Anguilla anguilla'
  AND stage.no_name='Yellow eel' -- we actually don't know that...
  AND biological_characteristic_type.no_name='Number p3' 
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  AND pcbgp_npas=3
  ; --0
  
-- number p3 op_pcbgb  
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  pcbgb_p3 AS ba_quantity,
  individual_status.no_id AS ba_no_individual_status,
  1 AS ba_batch_level,
  ee.ob_id as ba_ob_id, 
  cast(NULL as uuid) as ba_ba_id,
  ope.op_id,
  ope.op_zone
  FROM 
  france.dbeel_electrofishing_rsa ee 
    JOIN rsa.operation ope ON ob_id = ope_dbeel_ob_id 
    JOIN rsa.op_pcbgb  ON (op_pcbgb.pcbgb_op_id, op_pcbgb.pcbgb_zone)= (ope.op_id, ope.op_zone),
  dbeel_nomenclature.species, 
  dbeel_nomenclature.stage, 
  dbeel_nomenclature.biological_characteristic_type,
  dbeel_nomenclature.value_type,
  dbeel_nomenclature.individual_status 
  WHERE species.no_name='Anguilla anguilla'
  AND stage.no_name='Yellow eel' -- we actually don't know that...
  AND biological_characteristic_type.no_name='Number p3'
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
   AND pcbgb_npas=3
  ; --0  
  
--SELECT * FROM france.dbeel_batch_ope_rsa WHERE ba_no_biological_characteristic_type=233; --59  
  
  
----------------------------------------------------------------------
-- Batch integration, the second level will reference the fish table
----------------------------------------------------------------------
/*
 
N  Lot individuel : mesures individuelles
I Lot I : Longueur mesurée individuellement et poids global du lot
L Lot L : Nombre total d'individus et poids total du lot
S & L Lot S : Sous échantillon de 30 individus mesurés individuellement

 */










DROP TABLE if exists france.dbeel_batch_fish_rsa CASCADE;
CREATE TABLE france.dbeel_batch_fish_rsa (
  ang_id INTEGER,
  ang_op_id INTEGER,
  ang_lot TEXT,
  ang_nlot INTEGER, 
  ang_zone TEXT,
  ang_cod TEXT,
	CONSTRAINT pk_rsa_fish_fi_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_rsa_fish_fi_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_rsa_fish_fi_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_fish_rsa_fi_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_fish_rsa_fi_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,			
	CONSTRAINT fk_fish_rsa_fi_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT c_fk_rsa_fi_ob_id FOREIGN KEY (ba_ob_id) 
		REFERENCES france.dbeel_electrofishing_rsa (ob_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
		) INHERITS (dbeel.batch);


/*
 WITH bap1 AS (
    SELECT * FROM france.dbeel_batch_ope_rsa boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p1'  
  ),

  bafp1 AS (SELECT * FROM rsa.anguille_ang
          WHERE ang_pas = 1) -- AS we entered ALL fish AS p1 even IF they ARE point sample
  SELECT count(*) FROM bafp1
  JOIN bap1 ON (bap1.op_id, bap1.op_zone) =(bafp1.ang_op_id, bafp1.ang_zone)   --123174
  
  
  SELECT count(*) FROM rsa.anguille_ang ; -- 139731
   SELECT count(*) FROM rsa.anguille_ang where ang_pas=1; -- 123175
  SELECT count(*) FROM  france.dbeel_batch_ope_rsa WHERE ba_no_biological_characteristic_type=231 --3927
  SELECT count(*) FROM rsa.operation ; --3928
  
  -- rien
  SELECT * FROM rsa.operation  EXCEPT
  SELECT ope.* FROM rsa.operation ope JOIN france.dbeel_batch_ope_rsa bor ON bor.op_id=ope.op_id  
  */
  
--DELETE FROM  france.dbeel_batch_fish_rsa;

-- SELECT count (*), ang_pas FROM rsa.anguille_ang group by ang_pas
          



INSERT INTO france.dbeel_batch_fish_rsa


   WITH bap1 AS (
    SELECT * FROM france.dbeel_batch_ope_rsa boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p1'  
  ),

  bafp1 AS (SELECT * FROM rsa.anguille_ang
          WHERE ang_pas = 1) -- AS we entered ALL fish AS p1 even IF they ARE point sample
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
  ang_id,
  ang_op_id,
  ang_lot,
  ang_nlot, 
  ang_zone ,
  ang_cod 
	FROM bafp1
  JOIN bap1 ON (bap1.op_id, bap1.op_zone) =(bafp1.ang_op_id, bafp1.ang_zone),
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
	; -- 121040 poissons mesurés au premier passage 1m56

INSERT INTO france.dbeel_batch_fish_rsa


   WITH bap2 AS (
    SELECT * FROM france.dbeel_batch_ope_rsa boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p2'  
  ),

  bafp2 AS (SELECT * FROM rsa.anguille_ang
          WHERE ang_pas = 2) -- AS we entered ALL fish AS p1 even IF they ARE point sample
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
  ang_id,
  ang_op_id,
  ang_lot,
  ang_nlot, 
  ang_zone ,
  ang_cod 
  FROM bafp2
  JOIN bap2 ON (bap2.op_id, bap2.op_zone) =(bafp2.ang_op_id, bafp2.ang_zone),
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
  ; 	--16089
	
INSERT INTO france.dbeel_batch_fish_rsa
   WITH bap3 AS (
    SELECT * FROM france.dbeel_batch_ope_rsa boa 
    JOIN dbeel_nomenclature.biological_characteristic_type bc ON bc.no_id=boa.ba_no_biological_characteristic_type
    WHERE bc.no_name='Number p3'  
  ),

  bafp3 AS (SELECT * FROM rsa.anguille_ang
          WHERE ang_pas = 3) -- AS we entered ALL fish AS p1 even IF they ARE point sample
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
  ang_id,
  ang_op_id,
  ang_lot,
  ang_nlot, 
  ang_zone ,
  ang_cod 
  FROM bafp3
  JOIN bap3 ON (bap3.op_id, bap3.op_zone) =(bafp3.ang_op_id, bafp3.ang_zone),
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
  ;   --467

-- To integrate length and weight of fish, we need the "ba_id" 
-- that corresponds to the batch (each line must be different) 


DROP TABLE if exists france.dbeel_mensurationindiv_biol_charac_rsa CASCADE;
CREATE TABLE france.dbeel_mensurationindiv_biol_charac_rsa  (
	ang_id integer,
	CONSTRAINT rsa_pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT rsa_fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT rsa_fk_mensindivbiocho_bc_value_type FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT rsa_fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES france.dbeel_batch_fish_rsa (ba_id) ON DELETE CASCADE ON UPDATE CASCADE

)INHERITS (dbeel.biological_characteristic); --0
/*
select * from france.batch_fish_rsa limit 10;
*/

/*
SELECT count(*) FROM   france.dbeel_batch_fish_rsa dbaf JOIN
  rsa.anguille_ang baf ON baf.ang_id=dbaf.ang_id;-- 627221

SELECT count(*), ang_lot FROM rsa.anguille_ang  GROUP BY ang_lot;
*/  
-- Lots N
-- Insert WEIGHT (gr)
  
--DELETE FROM france.dbeel_mensurationindiv_biol_charac_rsa;  
INSERT INTO france.dbeel_mensurationindiv_biol_charac_rsa(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  ang_id)
	SELECT
	uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type,	
  55 AS bc_no_value_type, --'Raw data or Individual data'       
	ang_poids AS bc_numvalue,	
  baf.ang_id   
	FROM 
	france.dbeel_batch_fish_rsa dbaf JOIN
  rsa.anguille_ang baf ON baf.ang_id=dbaf.ang_id, 
	dbeel_nomenclature.biological_characteristic_type 
	WHERE biological_characteristic_type.no_name = 'Weight'
	AND baf.ang_lot='N'; -- 677871 9m
	
	--TODO STOP HERE the 08/07/2022 See ticket https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/issues/4
	-- Lots N
-- Insert WEIGHT (gr)
INSERT INTO france.dbeel_mensurationindiv_biol_charac_rsa(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  ang_id)
  SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type,  
  55 AS bc_no_value_type, --'Raw data or Individual data'       
  ang_poids AS bc_numvalue, 
  baf.ang_id
  FROM 
  france.dbeel_batch_fish_rsa dbaf JOIN
  rsa.anguille_ang baf ON baf.ang_id=dbaf.ang_id, 
  dbeel_nomenclature.biological_characteristic_type 
  WHERE biological_characteristic_type.no_name = 'Length'
  AND baf.ang_lot='N'; -- 627221

