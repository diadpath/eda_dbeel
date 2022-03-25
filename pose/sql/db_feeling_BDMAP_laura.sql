
-- dump de bd_map sch public vers EDA2 public:
pg_dump -h 1.100.1.6 -U postgres bd_map| psql -h 1.100.1.6 -U postgres eda2
-- transfers de public à ONEMA. Les tables existent déjà.
ALTER TABLE zonepeche SET SCHEMA onema;
ALTER TABLE version SET SCHEMA onema;
ALTER TABLE taxon SET SCHEMA onema;
ALTER TABLE tableauclassetaille SET SCHEMA onema;
ALTER TABLE station SET SCHEMA onema;
ALTER TABLE patho SET SCHEMA onema;
ALTER TABLE passtaxon SET SCHEMA onema;
ALTER TABLE optaxon SET SCHEMA onema;
ALTER TABLE operation SET SCHEMA onema;
ALTER TABLE mensurationindiv SET SCHEMA onema;
ALTER TABLE codier SET SCHEMA onema;
ALTER TABLE classe_taille_taxon SET SCHEMA onema;
ALTER TABLE lotpeche SET SCHEMA onema;

INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('ONEMA');
INSERT INTO dbeel.data_provider(dp_name, dp_et_id) VALUES ('Laurent Beaulaton',1);


-- Bon il est pas content ca il n y a pas de colonnes the_geom
select st_abcisse, st_ordonnee from onema.station;
ALTER TABLE onema.station ADD COLUMN the_geom geometry;
UPDATE onema.station SET the_geom = ST_GeometryFromText ('POINT(' || st_abcisse|| ' ' ||  st_ordonnee || ')',
27572)
select * from onema.station
-- il faut trouver quelle colonne il prend pour the_geom


DROP TABLE if exists onema.station_onema CASCADE;
CREATE TABLE onema.station_onema (
	LIKE onema.station,
	CONSTRAINT pk_so_op_id PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);
-- select * from onema.station_onema, the_geom c'ets la 8ième colonne
-- select * from onema.station --> il faut placer the_geom au même niveau

INSERT INTO onema.station_onema
	SELECT  uuid_generate_v4() AS op_id,
	'onema' AS op_gis_systemname ,
	'BDMAP' AS op_gis_layername, 
	s.st_id AS op_gislocation,
	s.st_localisation AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	st_transform(s.the_geom,3035) AS the_geom,	
  s.st_id,
  s.st_altitude,
  s.st_abcisse,
  s.st_codecsp,
  s.st_codesie,
  s.st_datearret,
  s.st_datecreation,
  s.st_distancesource,
  s.st_distancemer,
  s.st_finalite,
  s.st_imageign,
  s.st_imagedept,
  s.st_lieudit,
  s.st_limites,
  s.st_localisation,
  s.st_longueur,
  s.st_moduleia,
  s.st_cd_naturecourseau,
  s.st_ordonnee,
  s.st_penteign,
  s.st_pkaval,
  s.st_raisremp,
  s.st_sbv,
  s.st_t_janvier,
  s.st_t_juillet,
  s.st_cd_typecourseau,
  s.st_cd_tet,
  s.st_st_id,
  s.st_cm_id,
  s.st_cx_id,
  s.st_th_id,
  s.st_eh_id,
  s.st_uh_id,
  s.st_dt_cre,
  s.st_dt_maj,
  s.st_qi_maj,
  s.st_masseeau,
  s.st_abcisse_l93,
  s.st_ordonnee_l93 FROM onema.station s ;

DROP TABLE if exists onema.operation_onema CASCADE;
CREATE TABLE onema.operation_onema (
	LIKE onema.operation,
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
) INHERITS (dbeel.electrofishing);--13059

-- select * from onema.operation_onema limi





--select distinct  op_cd_methodeprospection from onema.operation
--select distinct  op_cd_moyenprospection from onema.operation
/*
> methodeprospection
                                cd_libl op_cd_methodeprospection no_id
1                             ambiances                      847    65
2                                autres                      851	61
3                              complète                      843	62
4                                   EPA                      848	66
5                                faciès                      846	66
6                  partielle sur berges                      845	63
7        partielle sur toute la largeur                      844	66
8                             placettes                      850	65
9  Stratifiée par Points (grand milieu)                     1611	66
10                               traits                      849	67


        cd_libl op_cd_moyenprospection no_id
1        A pied                    853 71
2     En bateau                    854 72
3         Mixte                    855 73
4 Non renseigné                    852 70


*/

select count(*) from onema.operation_onema
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
	case when op_cd_methodeprospection in (848,844,846,1611) then 66 --  Partial prop pour EPA(848) faciès(846) partille sur toute la largeur(844),Stratifiée par point (1611)
	when op_cd_methodeprospection in (847,850) then 65 --65 = partialrandom ambiance (847) placettes (850)
	when op_cd_methodeprospection =851  then 61 	 -- inconnu(61) unknown 851=autre
	when op_cd_methodeprospection=843 then 62 -- 843 pêche complete whole
	when op_cd_methodeprospection=845 then 63  -- 63 partial one balk, partille sur berge
	when op_cd_methodeprospection=849 then 67 -- 67 other 849 =trait ?
	else NULL end as ob_no_fishingmethod,
	case when op_cd_moyenprospection =853 then 71 
	when op_cd_moyenprospection= 854 then 72
	when op_cd_moyenprospection=855 then 73
	when op_cd_moyenprospection=852 then 70 
	else NULL end AS ef_no_electrofishing_mean,	
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
		--dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		onema.station_onema AS station join onema.operation AS operation on station.st_id = operation.op_st_id
		--dbeel_nomenclature.electrofishing_mean
	WHERE observation_origin.no_name='Raw data' 
	--AND scientific_observation_method.no_id=61
	AND observation_type.no_name='Electro-fishing' 
	--AND electrofishing_mean.no_name='Unknown' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Laurent Beaulaton';

-- select * from onema.station_onema limit 50;

---------------------------------------------------------------------------------------
-- optaxon
-- nb_total -- here pa_numero is null ;
DROP TABLE if exists onema.optaxon_onema CASCADE;
CREATE TABLE onema.optaxon_onema (
	LIKE onema.optaxon,
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
-- total number
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
	onema.optaxon
	WHERE species.no_name='Anguilla anguilla'
	 AND stage.no_name='Yellow & silver eel mixed'
	 AND biological_characteristic_type.no_name='Number'
	 AND value_type.no_name='Raw data or Individual data'
	 AND individual_status.no_name='Alive'
	 AND operation_onema.op_id = optaxon.ot_op_id
	 AND optaxon.ot_ta_id=2; --23872 lines

UPDATE onema.optaxon_onema SET ba_quantity = 0 WHERE ba_quantity IS NULL; 
-- select * from onema.optaxon_onema
select count(*) from onema.passtaxon_onema
DROP TABLE if exists onema.passtaxon_onema CASCADE;
CREATE TABLE onema.passtaxon_onema (
	LIKE onema.passtaxon,
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
		ON DELETE RESTRICT ON UPDATE CASCADE
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
	case when pa_numero=1 then 231 --'Number p1'
	 when pa_numero=2 then 232 --'Number p2'
	 when pa_numero=3 then 233 --'Number p3'
	 when pa_numero=4 then 234 --'Number p4'
	 when pa_numero=5 then 235 --'Number p5'
	 when pa_numero=6 then 236 --'Number p6'
	 else NULL end as ba_no_biological_characteristic_type,
	passtaxon.pa_effectif AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	operation_onema.ob_id AS ba_ob_id,
	NULL AS ba_ba_id,
	passtaxon.* 
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	--dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	onema.operation_onema AS operation_onema, 
	onema.passtaxon
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow & silver eel mixed' 
	--AND biological_characteristic_type.no_name='Number' 
	AND value_type.no_name='Raw data or Individual data'
	AND individual_status.no_name='Alive' 
	AND operation_onema.op_id = passtaxon.pa_op_id
	AND pa_ta_id=2;--30792
	
-- select * from onema.optaxon_onema
-- select * from onema.passtaxon_onema limit 10
-- UPDATE onema.passtaxon_onema SET quantity = 0 WHERE quantity ISNULL;

UPDATE onema.passtaxon_onema pao SET ba_ba_id=opo.ba_id FROM onema.optaxon_onema opo WHERE opo.ba_ob_id = pao.ba_ob_id;
-- select * from onema.passtaxon_onema limit 100;
--DELETE FROM onema.passtaxon_onema where pa_ta_id!=2; 
-- select * from onema.passtaxon_onema order by pa_dt_maj --15396 rows, il y a 2011, 2012, 2013

/*--------------------------------------------------------------------------------------
		lotpeche
--------------------------------------------------------------------------------------*/
DROP TABLE if exists onema.lotpeche_onema CASCADE;
CREATE TABLE onema.lotpeche_onema (
	LIKE onema.lotpeche,
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
		ON DELETE RESTRICT ON UPDATE CASCADE
--	CONSTRAINT fk_lopeo_ba_ba_id FOREIGN KEY (ba_ba_id)
--		REFERENCES dbeel.batch(ba_id) -- Il ne peut pas y avoir de contraintes de clé étrangères dans la table
--		ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (dbeel.batch);

-- TODO: insert trigger
-- this is way too long, I'm only inserting the eels
SELECT * FROM 	onema.operation_onema  join onema.lotpeche on operation_onema.op_id = lotpeche.lo_op_id limit 10;

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
	onema.operation_onema  join onema.lotpeche on operation_onema.op_id = lotpeche.lo_op_id 
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

-- select * from onema.lotpeche_onema limit 100;


---------------------------------------------------------------------------------------
-- Biological characteristic for lotpeche
---------------------------------------------------------------------------------------

-- Ici les résultats biologiques sont par lot du coup pour chacun d'eux on a Lt min, taille minimum, Lt max, le poid du lot, poid moyen individuel
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
		AND value_type.no_name = 'Raw data or Individual data' -- 77189
; 

-- select * from onema.lotpeche_biol_charac_onema --280018 rows

---------------------------------------------------------------------------------------
-- mensurationindiv
------------------------------------------------------------------------------------
DROP TABLE if exists onema.mensurationindiv_onema CASCADE;
CREATE TABLE onema.mensurationindiv_onema (
	LIKE onema.mensurationindiv,
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


(select * from 	onema.operation_onema 
	join onema.lotpeche_onema  on ob_id=ba_ob_id 
	join onema.mensurationindiv on mi_lo_id=lotpeche_onema.lo_id limit 10) as sub


INSERT INTO onema.mensurationindiv_onema
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	joineel. * --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id,ba_id AS ba_ba_id, mensurationindiv.* from onema.operation_onema 
	join onema.lotpeche_onema  on ob_id=ba_ob_id 
	join onema.mensurationindiv on mi_lo_id=lotpeche_onema.lo_id 
	where lo_ta_id=2) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow & silver eel mixed' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--42253 lines

-- select * from onema.mensurationindiv_onema 

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
; --42252 (contre 40721 avant)

-- select * from onema.operation_onema  order by  ob_starting_date
-- select * from dbeel.electrofishing where extract(year from ob_starting_date) >2010 order by ob_starting_date -- c'est ok elles sont dans la dbeel

--select * from dbeel.observation_places where op_gis_layername='BDMAP' -- 13059
--select * from dbeel.observation_places where op_gis_layername='BDMAP' and the_geom is NULL -- 113 (c'est toujours les mêmes répétées par ans.
select st_srid(the_geom) from dbeel.observation_places group by st_srid(the_geom); -- y a 3035 et lambert 93
update dbeel.observation_places set the_geom=st_transform(the_geom,3035);

---------------------------------------------------------------------------------------------------------------
---------------- Table observation_ccm_500----------------
---------------------------------------------------------------------------------------------------------------

-- On refais la table observation_ccm_500 du coup:

DROP TABLE IF EXISTS dbeel.observation_places_ccm_500;
CREATE TABLE dbeel.observation_places_ccm_500 as (
        SELECT distinct on (op_id) op_id, gid, wso1_id, min(distance) as distance,op_gis_layername, the_geom FROM (
               SELECT op_id, gid , wso1_id,op_gis_layername, CAST(distance(r.the_geom, s.the_geom) as  decimal(15,1)) as distance,s.the_geom 
               FROM dbeel.observation_places As s
               INNER JOIN  ccm21.riversegments r ON ST_DWithin(r.the_geom, s.the_geom,500)  --69931 observations sur 87204 lignes
               WHERE s.the_geom IS NOT NULL
               ) AS sub 
        GROUP BY op_id,distance, gid, wso1_id,  the_geom,op_gis_layername
);

alter table dbeel.observation_places_ccm_500 add column id serial;


-- mise à jour de la table geometry_columns
-- INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
-- SELECT '', 'dbeel', 'observation_places_ccm_500', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
-- FROM dbeel.observation_places_ccm_500 LIMIT 1;
-- creation d'index, clé primaire, et constraintes qui vont bien
alter table dbeel.observation_places_ccm_500 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table dbeel.observation_places_ccm_500 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table dbeel.observation_places_ccm_500 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
alter table dbeel.observation_places_ccm_500 ADD CONSTRAINT pk_id PRIMARY KEY(id);
CREATE INDEX indexstation_ccm_500 ON dbeel.observation_places_ccm_500
  USING GIST ( the_geom GIST_GEOMETRY_OPS );

---------------------------------------------------------------------------------------------------------------
---------------- Table station_CCM_500 france_belge_Meuse----------------
---------------------------------------------------------------------------------------------------------------

ALTER TABLE onema.station_onema RENAME COLUMN st_id TO site;
ALTER TABLE belge.stationdbeel ALTER COLUMN site TYPE bigint;
ALTER TABLE onema.station_onema ALTER COLUMN site TYPE character varying;

DROP TABLE IF EXISTS dbeel.meuse_stations_ccm_500;
CREATE TABLE dbeel.meuse_stations_ccm_500 as (
         SELECT n.site, n.gid, n.wso1_id, min(n.distance) as distance, n.the_geom FROM 
		(  
		SELECT site, gid, wso1_id, distance, s.the_geom 
		FROM dbeel.observation_places_CCM_500 s
		join belge.stationdbeel o ON o.op_id=s.op_id --516 lignes
		union ALL
			SELECT p.site, gid, m.wso1_id, m.distance, p.the_geom FROM (
				select o.gid, o.wso1_id, o.op_id,  o.distance from dbeel.observation_places_CCM_500 o
				JOIN europe.wso1 e ON o.wso1_id=e.wso1_id where area='Meuse') m
		join onema.station_onema p ON p.op_id=m.op_id ) n --901 lignes
		
         WHERE n.the_geom IS NOT NULL  
         GROUP BY n.site, n.gid, n.wso1_id, distance, n.the_geom -- 901
         order by n.wso1_id, n.site 
);
select * from dbeel.meuse_stations_ccm_500
       
alter table dbeel.meuse_stations_ccm_500 add column id serial;
-- mise à jour de la table geometry_columns
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'dbeel', 'meuse_stations_ccm_500', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM dbeel.meuse_stations_ccm_500 LIMIT 1;

-- creation d'index, clé primaire, et constraintes qui vont bien
alter table dbeel.meuse_stations_ccm_500 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table dbeel.meuse_stations_ccm_500 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table dbeel.meuse_stations_ccm_500 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
alter table dbeel.meuse_stations_ccm_500 ADD CONSTRAINT pk_id PRIMARY KEY(id);
CREATE INDEX indexmeuse_FB_ccm_500 ON dbeel.meuse_stations_ccm_500
  USING GIST ( the_geom GIST_GEOMETRY_OPS );

alter table dbeel.meuse_stations_ccm_500 set schema belge
