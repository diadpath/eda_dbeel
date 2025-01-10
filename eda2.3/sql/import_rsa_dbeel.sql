
/*
dbeel.establishment
dbeel.data_provider
*/


---------------------------------------------
-- SCRIPT INTEGRATION RSA => DBEEL
---------------------------------------------


--TODO Pour l'instant les diamètres occulaires ne sont pas là !


-- **************************************
-- UPDATES :
-- 
-- Correction clarisse

/* update rsa.anguille_ang set ang_pas=1 
where ang_op_id in (361,362,367,498,507,511,512,513,514,515,523)
and ang_zone='ap';
update rsa.anguille_ang set ang_poids=NULL where ang_poids=0; --9113
-- correction de Clarisse
update rsa.op_inv set inv_p3=NULL where inv_npas=2 and inv_p3 is not NULL;
 */
-- Julien RAITIF, 29/08/23 : add comments in file to give detailed information for users, and clean code
-- **************************************

-- *************************************************
-- *************************************************
-- *************************************************
-- TABLE OF CONTENTS
-- 1) ONLY IF NECESSARY : Create establishement and provider of RSA DATA
-- 2) Station
-- 3) Electrofishing details
-- 4) Batch informations 
-- 5) Batch informations (fish level)
-- *************************************************
-- *************************************************
-- *************************************************



-- *************************************************
-- *************************************************
-- *************************************************
-- 1) ONLY IF NECESSARY : Create establishement and provider of RSA DATA
-- *************************************************
-- *************************************************
-- *************************************************
/*
-- select * from dbeel.establishment;

--select * from dbeel.data_provider
--select max(dp_id) from dbeel.data_provider; -- 25


-- Creation de data providers à partir des noms de la table RSA

INSERT INTO  dbeel.data_provider ( dp_name, dp_et_id) 
SELECT prod_libelle, 27 FROM rsa.producteurs_prod; --17
ALTER SEQUENCE dbeel.data_provider_dp_id_seq RESTART WITH 38;






-- *************************************************
-- *************************************************
-- *************************************************
-- 2) Station
-- *************************************************
-- *************************************************
-- *************************************************

--SELECT * FROM rsa.station s ;

--SELECT DISTINCT(st_srid(geom)) FROM rsa.station; -- il y a des NULLS
-- Mise à jours de champs geom manquants (travail en cours de Clarisse)
UPDATE rsa.station SET geom = ST_GeomFromText('POINT(' ||sta_x93 || ' ' || sta_y93 || ')', 2154)
WHERE geom IS NULL; --20


SELECT * FROM dbeel.observation_places;

*/


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
	--1767 au 24/10,17/01/21
--retour des identifiants dans la TABLE mère

	/* UPDATE rsa.station SET sta_dbeel_op_id =NULL; --1757 */
	ALTER TABLE rsa.station ADD COLUMN sta_dbeel_op_id UUID;
	UPDATE rsa.station SET sta_dbeel_op_id = op_id FROM
 france.dbeel_station_rsa WHERE dbeel_station_rsa.sta_code=dbeel_station_rsa.sta_code; --1767

	





-- *************************************************
-- *************************************************
-- *************************************************
-- 3) Electrofishing details
-- *************************************************
-- *************************************************
-- *************************************************

/* Cette insertion des opérations de pêches électriques va se dérouler en plusieurs étapes.
Il existe 6 types d'opérations dont les détails sont stockés dans différentes tables.

SELECT DISTINCT op_typ FROM rsa.operation;

|op_typ|
|------|
|inv   | inventaire à pied  à n passages
|epap  | echantillonage pontctuel d'abondance, pêche par points (à pied ?)
|pcbgb | Pêche en continu des berge (en bateau ?) 
|pcbgp | Pêche en continu des berge (à pied ?) 
|epab  | echantillonage pontctuel d'abondance, pêche par points (en bateau ?)
|iaa   | Indice d'abondance à pied

*/

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


/* electrofishing mean
70    Electrofishing mean Unknown 
71    Electrofishing mean By foot 
72    Electrofishing mean By boat 
73    Electrofishing mean Mix 

--> CASE WHEN op_typ IN ('inv','iaa','epap', 'pcbgp')  THEN 71  -- a pied
	     WHEN op_typ IN ('pcbgb', 'epab') THEN 72	  -- en bateau  
	     ELSE 70 -- unknown
	END AS ef_no_electrofishing_mean,
	
	
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

--> CASE WHEN op_typ = 'inv' THEN 62
	     WHEN op_typ IN ('pcbgb', 'pcbgp') THEN 302 -- pêche CONTINUE des berges
	     WHEN op_typ LIKE '%epa%' THEN 306
	     WHEN op_typ LIKE '%iaa%' THEN 303 
       WHEN op_typ ILIKE '%anguille%' THEN 303	
	END AS ef_no_fishingmethod,
 */


--------------------------------------
-- Inventaire à pied à n passages
--------------------------------------
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
	62  AS ef_no_fishingmethod, 
	71 AS ef_no_electrofishing_mean,
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
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)  
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
	--J. RAITIF, 29/08 : 1008
	--J. RAITIF, 24/10,17/01/24 : 1090
	



--------------------------------------
-- Indice d'abondance à pied
--------------------------------------
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
  303 AS ef_no_fishingmethod,
  71 AS ef_no_electrofishing_mean, 
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
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone) 
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
  	--J. RAITIF, 29/08 : 2775
	--J.RAITIF, 24/10, 17/01/24 : 2770

--------------------------------------
-- echantillonage pontctuel d'abondance, pêche par points (en bateau ?)
--------------------------------------
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
  306 AS ef_no_fishingmethod,
  72 AS ef_no_electrofishing_mean, 
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
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)
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
  	--J. RAITIF, 29/08 et 24/10 : 162
  
--------------------------------------
-- Pêche en continue des berge (en bateau ?) 
--------------------------------------
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
  302 AS ef_no_fishingmethod,
  72 AS ef_no_electrofishing_mean, 
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
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone) 
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
  	--J. RAITIF, 29/08 et 02/10, 17/01/24 : 186
  
--------------------------------------
-- Pêche en continu des berge (à pied ?) 
--------------------------------------
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
  302 AS ef_no_fishingmethod,
  71 AS ef_no_electrofishing_mean, 
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
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone)
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
  	--J. RAITIF, 29/08 : 17  
	--J. RAITIF, 24/10, 17/01/24 : 19
  
  
  
--------------------------------------
-- echantillonage pontctuel d'abondance, pêche par points (à pied ?)
--------------------------------------
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
  306 AS ef_no_fishingmethod,
  71 AS ef_no_electrofishing_mean, 
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
  JOIN rsa.operation ope ON (sta.sta_id, sta.sta_zone) = (op_sta_id, op_zone) 
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
  	--J. RAITIF, 29/08 et 24/10, 17/01/24 : 145  
   
ALTER TABLE rsa.operation ADD COLUMN ope_dbeel_ob_id UUID;
UPDATE rsa.operation SET ope_dbeel_ob_id= NULL; --4540
WITH the_join AS (
SELECT ob_id, rsa.operation.* FROM 
 france.dbeel_electrofishing_rsa 
 JOIN rsa.operation ON  (operation.op_id, operation.op_zone) = 
 (dbeel_electrofishing_rsa.op_id, dbeel_electrofishing_rsa.op_zone)
 )
UPDATE rsa.operation SET ope_dbeel_ob_id = ob_id FROM the_join
WHERE (operation.op_id, operation.op_zone) =  (the_join.op_id, the_join.op_zone)
AND  operation.ope_dbeel_ob_id IS NULL; --3632+17
--J. RAITIF, 29/08 : 4293  
--J. RAITIF, 24/10 : 4372

	
-- contrôle d'intégrité
SELECT * FROM rsa.operation ope where ope.ope_dbeel_ob_id IS NULL
-- JRT, 29/08 : 22 lignes, 
--op_typ, op_zone : 	epab-ap, 21 lignes
--					iaa-lcvllogrami, 1 ligne

/* Test d'intégrité pour les opération de type iaa

with first_sel as (
SELECT * FROM rsa.operation ope where ope.ope_dbeel_ob_id IS null and ope.op_typ='iaa')
select opi.*,first_sel.* from op_iaa opi join first_sel on ((opi.iaa_op_id,opi.iaa_zone)  = (first_sel.op_id,first_sel.op_zone))

Pas de sta_id sur l'opération
 */
 
 /* Test d'intégrité pour les opération de type epab

with first_sel as (
SELECT * FROM rsa.operation ope where ope.ope_dbeel_ob_id IS null and ope.op_typ='epab')
select opi.*,first_sel.* from op_epab opi join first_sel on ((opi.epab_op_id,opi.epab_zone)  = (first_sel.op_id,first_sel.op_zone))

Les op_id de la table operation (avec op_type = 'epab') ne sont pas connus dans la table rsa.op_epab
 */
 
	





-- *************************************************
-- *************************************************
-- *************************************************
-- 4) Batch informations 
-- *************************************************
-- *************************************************
-- *************************************************

/* Cette insertion des réultats des opérations de pêches électriques va se dérouler en plusieurs étapes.
Il existe 6 types d'opérations dont les détails sont stockés dans différentes tables.

|op_typ|
|------|
|inv   | inventaire à pied  à n passages
|epap  | echantillonage pontctuel d'abondance, pêche par points (à pied ?)
|pcbgb | Pêche en continu des berge (en bateau ?) 
|pcbgp | Pêche en continu des berge (à pied ?) 
|epab  | echantillonage pontctuel d'abondance, pêche par points (en bateau ?)
|iaa   | Indice d'abondance à pied

On stocke le total dans un premier temps puis le nombre de poissons pêchés lors du premier passage (valable pour tous les types de pêches).
Pour les types de pêches inv, pcbgb et pcbgp on stocke ensuite les résultats de pêches pour les passages 2 et 3.

*/

-- select count(*) from france.dbeel_batch_ope_rsa -- 10229 (before 2023), 
-- JRT 30/08/23 : 9857 (pourquoi moins ?)

 --------------------------------------------	
-- NUMBER PER PASS... AND TOTAL NUMBER
-- BATCH INTEGRATION
-- WE DON'T NEED DENSITY, WILL BE RECALCULATED LATER
--------------------------------------------
 
DROP TABLE france.dbeel_batch_ope_rsa  CASCADE;
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

-- inventaire à pied  à n passages, totaux
-- JRT : 30/08/23 :
--  select distinct inv_p1 from rsa.op_inv oi,  no inventory value = -9 for inv_p1, inv_P2 or inv_p3
-- --> no need keep th following code : 
--	CASE WHEN inv_p1 =-9 THEN NULL::numeric END AS inv_p1,
-- 	CASE WHEN inv_p2 =-9 THEN NULL::numeric END AS inv_p2,
--  CASE WHEN inv_p3 =-9 THEN NULL::numeric END AS inv_p3,
INSERT INTO france.dbeel_batch_ope_rsa
  SELECT uuid_generate_v4() AS ba_id,
  species.no_id AS ba_no_species,
  stage.no_id AS ba_no_stage,
  value_type.no_id AS ba_no_value_type,
  biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
  COALESCE(inv_p1,0)+ 
  COALESCE(inv_p2,0) + 
  COALESCE(inv_p3,0) AS   ba_quantity,
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
  AND value_type.no_name='Raw data or Individual data';
  --950
  -- JRT, 30/08/23 : 1008
  -- JRT, 24/10, 17/01/24 : 1090

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
  
-- Indice d'abondance à pied, totaux  
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
  -- JRT, 30/08 : 2775
  -- JRT, 24/10, 17/01/24 : 2770
  
------------
-- Pêche en continu des berge (à pied ?), totaux  
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
  -- JRT, 30/08 : 17
  -- JRT, 02/10, 17/01/24 : 19

------------
-- Pêche en continu des berge (en bateau ?), totaux
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
  -- JRT, 30/08 et 24/10, 17/01/24 : 186
  
-----------------
-- echantillonage pontctuel d'abondance, pêche par points (en bateau ?), totaux  
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
  -- JRT, 30/08 et 24/10, 17/01/24 : 162


-----------------
-- echantillonage pontctuel d'abondance, pêche par points (à pied ?), totaux
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
  ope.op_zone-- JRT, 31/08 : correctif, il manquait la zone pour ce type de pêche. Ce problème est présent en prod également
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
-- JRT? 30/08 et 24/10, 17/01/24 : 145  
  
  


  
  
---------------------------------------------- 
-- Effectif des premiers passages

---
-- inventaire à pied  à n passages, 1er passage
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
  -- JRT? 30/08 : 1008
  -- JRT, 24/10, 17/01/24 : 1090
  
--------
-- Indice d'abondance à pied, premier passage
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
  -- JRT, 30/08 : 2775
  -- JRT, 24/10, 17/01/24 : 2770
  
------------
-- Pêche en continu des berge (à pied ?), 1er passage 
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
  -- JRT, 30/08 : 17
  -- JRT, 02/10 : 19
  
------------
-- Pêche en continu des berge (en bateau ?), 1er passage 
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
  -- JRT, 30/08 : 186
  -- JRT, 02/10 : 186
  
-----------------
-- echantillonage pontctuel d'abondance, pêche par points (en bateau ?), 1er passage    
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
  -- JRT, 30/08 : 162
  -- JRT, 02/10, 17/01/24 : 162

-----------------
-- echantillonage pontctuel d'abondance, pêche par points (à pied ?), 1er passage  
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
  -- JRT, 30/08 : 145
  -- JRT, 02/10, 17/01/24 : 145
  
  
  
---------------------------------------------- 
-- Effectif du second passage

---
-- inventaire à pied  à n passages, 2nd passage
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
  and op_inv.inv_npas > 1 -- ce filtre est nécessaire sinon on insère des lignes de résultats d'opérations avec une quantité NULL (alors qu'il n'y avait qu'un seul passage)
  ; --950 
  -- JRT, 30/08 : 1008
  -- JRT, 24/10, 17/01/24 : 1039 (après correction)
  
------------
-- Pêche en continu des berge (à pied ?), 2eme passage
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
  AND op_pcbgp.pcbgp_npas > 1
  ; --17
  -- JRT, 30/08 : 17
  -- jRT, 24/10, 17/01/24 : 19
  
------------
-- Pêche en continu des berge (en bateau ?), 2ème passage 
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
  AND op_pcbgb.pcbgb_npas>1
  ; --177
  -- JRT, 30/08 : 186
  -- JRT, 24/10, 17/01/24 : 186
  
---------------------------------------------- 
-- Effectif du troisième passage

---
-- inventaire à pied  à n passages, 3eme passage 
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
  -- JRT, 30/08 : 60
  -- JRT, 24/10, 17/01/24 : 60
  
------------
-- Pêche en continu des berge (à pied ?), 3eme passage 
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
  -- JRT, 30/08 et 24/10, 17/01/24 : 0
  
------------
-- Pêche en continu des berge (en bateau ?), 3ème passage 
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
  -- JRT, 30/08 et 24/10, 17/01/24 : 0
  
  
  
  
  
  
  
  
  
-- *************************************************
-- *************************************************
-- *************************************************
-- 5) Batch informations (fish level)
-- *************************************************
-- *************************************************
-- ************************************************* 
 
 -- A cette étape on insère une ligne par poisson (référencé dans rsa.anguille)
 -- il sont insérés dans france.dbeel_batch_fish_rsa
 -- en procédant par numéro de passage (1,2 puis 3)
 -- JRT 30/08 : Question : pourquoi faire passage par passage alors qu'on ne conserve pas le numéro de passage ?
 -- POur moi il y  a un problème dans les select pour l'insertion
 -- On devrait (tout comme ASPE) faire un filtre sur "AND biological_characteristic_type.no_name='Number P1' (ou P2, P3) et non pas
 --  AND biological_characteristic_type.no_name='Number'  (A REVOIR avec Cedric et Laurent)
 -- Il y a également je pense un pb dans l'insertion des mesures. On ne peut pas avoir + de 600000 lignes de poids alors qu'il y a environ 155000 anguilles capturées
 -- le pb vient du fait je pense que dans la jointure entre dbeel_batch_fish_rsaet ras.anguille_ang on utilie ang_id mais pas ang_zone. Alors que l'ang_id n''est pas unique.
 -- il y a un souci dans la table dbeel_mensurationindiv_biol_charac_rsa, le ang_id comme seul champs pour faire la jointure avec france.dbeel_batch_fish_rsa n'est pas suffisant, 
 -- il faut aussi ang_zone. Il en résulte qu'il y a des duplicats en prod dans la table dbeel_mensurationindiv_biol_charac_rsa, en plus d'avoir des lignes avec une mesure de poids ou taille à NULL.
 -- De plus pourquoi ne fait on pas comme pour ASPE et on calcule un poids moyen redistribué pour les anguilles mesurées par lot
 
 
 -- select count(*) from france.dbeel_batch_fish_rsa dbfr
 -- 147102 (avant 2023)
 -- JRT 30/08/23 : 
  
 -- select count(*) from rsa.anguille_ang aa 
 -- berfor 2023 : 139731
 -- JRT 30/08/23 : 155760

-- 	select count(*), aa.ang_pas from rsa.anguille_ang aa group by aa.ang_pas order by aa.ang_pas 
--	137650	1 (before 2023 : 123175)
--	17618	2
--	492		3

/* select bor.ba_no_biological_characteristic_type, count(*) 
  from france.dbeel_batch_ope_rsa bor 
  group by bor.ba_no_biological_characteristic_type
  order by bor.ba_no_biological_characteristic_type
  
47	4293
231	4293 (1er passage)
232	1211 (2eme passge)
233	60   (3eme passage) */
---------------------------------------------------------------------
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
          


-- Fish caught during 1st pass
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
	AND biological_characteristic_type.no_name='Number p1'
	--AND biological_characteristic_type.no_name='Number' -- should refer to Number p1 instead ?
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 121040 poissons mesurés au premier passage 1m56
	-- JRT, 30/08/23 : 137650
	-- JRT, 24/10 : 136704
	-- JRT, 17/01/24 : 136676


-- Fish caught during 2nd pass
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
	AND biological_characteristic_type.no_name='Number p2'
	--AND biological_characteristic_type.no_name='Number' -- should refer to Number p2 instead ?
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  ; 	--16089
  -- JRT 30/08/23 : 17618
  -- JRT, 24/10, 17/01/24 : 17775

-- Fish caught during 3rd pass
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
	AND biological_characteristic_type.no_name='Number p3'
	--AND biological_characteristic_type.no_name='Number' -- should refer to Number p3 instead ?
  AND individual_status.no_name='Alive' 
  AND value_type.no_name='Raw data or Individual data'
  ;   --467
  -- JRT, 30/08/23 : 492
  -- JRT, 24/10, 17/01/24 : 492


----------------
--Measures of fish caught (weight and length)

-- To integrate length and weight of fish, we need the "ba_id" 
-- that corresponds to the batch (each line must be different) 
DROP TABLE if exists france.dbeel_mensurationindiv_biol_charac_rsa CASCADE;
CREATE TABLE france.dbeel_mensurationindiv_biol_charac_rsa  (
	ang_id integer,
	ang_zone text,
	CONSTRAINT rsa_pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT rsa_fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT rsa_fk_mensindivbiocho_bc_value_type FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT rsa_fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES france.dbeel_batch_fish_rsa (ba_id) ON DELETE CASCADE ON UPDATE CASCADE

)INHERITS (dbeel.biological_characteristic);

/*
--select * from france.batch_fish_rsa limit 10;



SELECT count(*) FROM   france.dbeel_batch_fish_rsa dbaf JOIN
  rsa.anguille_ang baf ON baf.ang_id=dbaf.ang_id;-- 627221

SELECT count(*), ang_lot FROM rsa.anguille_ang  GROUP BY ang_lot;
*/ 
-- Lots N
-- Insert WEIGHT (gr)
   
INSERT INTO france.dbeel_mensurationindiv_biol_charac_rsa(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  ang_id,
  ang_zone)
	SELECT
	uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type,	
  55 AS bc_no_value_type, --'Raw data or Individual data'       
	ang_poids AS bc_numvalue,	
  baf.ang_id  ,
  baf.ang_zone-- 07/09 : corrected, was missing (as ang_id is not unique between every zone)
	FROM 
	france.dbeel_batch_fish_rsa dbaf JOIN
    rsa.anguille_ang baf ON (baf.ang_id,baf.ang_zone)=(dbaf.ang_id,dbaf.ang_zone), -- 07/09 : corrected as ang_id is not unique in ras.anguille_ang, duplicate for each zone
	dbeel_nomenclature.biological_characteristic_type 
	WHERE biological_characteristic_type.no_name = 'Weight'
	AND baf.ang_lot='N'
	AND baf.ang_poids is not null; --to prevent from inserting NULL weight values
	-- 677871 (with duplicate pb)
	-- 07/09 : 72376
	-- 24/10 : 69258
	--, 17/01/24 : 69259
	
	
-- Insert Length 
INSERT INTO france.dbeel_mensurationindiv_biol_charac_rsa(
  bc_id,
  bc_ba_id,
  bc_no_characteristic_type,
  bc_no_value_type,
  bc_numvalue,
  ang_id,
  ang_zone)
  SELECT 
  uuid_generate_v4() AS bc_id, 
  ba_id AS bc_ba_id, 
  biological_characteristic_type.no_id AS bc_no_characteristic_type,  
  55 AS bc_no_value_type, --'Raw data or Individual data'       
  ang_taille AS bc_numvalue, --07/09 : corrected, ang_poids was inserted instead of ang_taille
  baf.ang_id,
  baf.ang_zone -- 07/09 : corrected, was missing (as ang_id is not unique between every zone)
  FROM 
  france.dbeel_batch_fish_rsa dbaf JOIN
  rsa.anguille_ang baf ON (baf.ang_id,baf.ang_zone)=(dbaf.ang_id,dbaf.ang_zone), -- 07/09 : corrected as ang_id is not unique in ras.anguille_ang, duplicate for each zone 
  dbeel_nomenclature.biological_characteristic_type 
  WHERE biological_characteristic_type.no_name = 'Length'
  AND baf.ang_lot='N'
	AND baf.ang_taille is not null; --to prevent from inserting NULL length values
	-- 677871 (with duplicate pb)
	-- 07/09 : 145619
	-- 24/10 : 144165
	--, 17/01/24: 144137

