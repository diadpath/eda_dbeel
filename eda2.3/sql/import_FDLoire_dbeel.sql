--------------------------------------------------------------------------------------------
--  Stations
--------------------------------------------------------------------------------------------


ALTER TABLE france.station_fdloire RENAME COLUMN geometry TO geom;


CREATE INDEX 
  ON france.station_fdloire
  USING gist
  (geom);
  

-- to store the link for dbeel
ALTER TABLE sudoang.gt6_station ADD COLUMN dbeel_op_id uuid;
  


-- add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name)
SELECT DISTINCT sf.sta_source from station_fdloire sf ;

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

DELETE FROM france.dbeel_batch_ope_aspe; --75666
DELETE FROM france.dbeel_electrofishing_aspe; --33300
DELETE FROM france.dbeel_station_fdloire; 


-- Insert data into the dbeel table
INSERT INTO france.dbeel_station_fdloire 
	SELECT  uuid_generate_v4() AS op_id, -- UNIQUE identifier
	'3035' AS op_gis_systemname ,
	'fdloire' AS op_gis_layername, 
	NULL AS op_gislocation, 
	sta_lib AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, -- already 3035
   sta_id,
   'FR' AS country 
	FROM france.station_fdloire ;  --32720 17s => 31734 après filtre contour france

------------------------------
--Add uuid to original table
--------------------------------
	
	
	ALTER TABLE france.station_fdloire  ADD COLUMN sta_dbeel_op_id UUID;
	UPDATE france.station_fdloire SET sta_dbeel_op_id = op_id FROM
 france.dbeel_station_fdloire WHERE dbeel_station_fdloire.sta_id=station_fdloire.sta_id; --2550
 
 
 
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
ef_wetted_area,
ef_fished_length,
ef_fished_width,
ef_duration,
nb_point,
op_typ,
ope_id,
sta_id)
SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat::date AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	CASE WHEN sta_source LIKE 'FD72' THEN 32
		 WHEN sta_source LIKE 'FD49' THEN 31
		 WHEN sta_source LIKE 'EPLoire' THEN 33
		 WHEN sta_source LIKE 'FD44' THEN 34
		 WHEN sta_source LIKE 'FD86' THEN 35
		 WHEN sta_source LIKE 'FD43' THEN 36
		 WHEN sta_source LIKE 'FD45' THEN 37
	END AS ob_dp_id, 
	CASE WHEN (op_typ ILIKE '%compl%') AND objectif ILIKE '%anguilles%' THEN 302
	     WHEN op_typ ILIKE '%artielle sur berge%' THEN 302
	     WHEN (op_typ ILIKE '%compl%' OR op_type ILIKE 'Sauvetage' OR op_type ILIKE '%passage%') THEN 62
	     WHEN (op_typ ILIKE '%partielle%' OR op_typ ILIKE 'Par points' OR op_typ ILIKE 'Echantillonnage ponctuel d''abondance') THEN 301
	     WHEN op_typ ILIKE '%mbiance%' THEN 301 -- ambiance IS a sort OF deep habitat electrofishing WITH point FOR LARGE streams
	     WHEN op_typ ILIKE '%partielle sur berge%' THEN 63
       WHEN (op_typ ILIKE '%anguille%' OR op_typ ILIKE '%IAA%') THEN 303	
       ELSE 61 -- si y a des des 61 se m�fier
	END AS ef_no_fishingmethod,
	

peche_pied_barrage -> code à créer (on aura des données nouvelles sur le Loire cette année)


 

Sondage presence-absence -> a virer?
Complête -> 62
EPA ANG -> 303
EPA -> 301
Complete -> 62
Stratifiée par Trait - > 301
Complète -> 62
	
	
	
	
	
	
	
	
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
