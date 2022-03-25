
-- insertion donn�es Laura
create schema belge;
alter table stations set schema belge;
alter table mesures_ang set schema belge;
alter table obstacles set schema belge;
alter table anguilles set schema belge;


set search_path to belge,public,dbeel;
select * from belge.stations;
select st_srid(the_geom) from belge.stations;--103300
--103300 est le code ESRI mais ce n'est pas un ESPG qui est 31370
update belge.stations set the_geom=st_setsrid(the_geom,31370);
update belge.stations set the_geom=st_transform(the_geom,3035);--2484
alter table belge.stations  ADD CONSTRAINT station_pkey PRIMARY KEY (st_id ),
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 27572),
  CONSTRAINT geometry_valid_check CHECK (isvalid(the_geom));


--Meuse
INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('SPW');
INSERT INTO dbeel.data_provider(dp_name, dp_et_id) VALUES ('Laura',7);

alter table stations rename to operations;
create table stations as select distinct on (site) site, organisme, eau,commune, lambex,lambey, code_precxy, the_geom from operations 
where code_typpec= 'PECHEELECTRIQUE';
alter table stations add constraint c_pk_stations PRIMARY KEY (site);

DROP TABLE if exists belge.stationdbeel CASCADE;
CREATE TABLE belge.stationdbeel (
	LIKE belge.stations,
	CONSTRAINT pk_so_op_id PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);

INSERT INTO belge.stationdbeel
	SELECT  uuid_generate_v4() AS op_id,
	'SPW' AS op_gis_systemname ,
	'STATIONS' AS op_gis_layername, 
	st.site AS op_gislocation,
	site AS op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	the_geom,
	site, organisme, eau,commune, lambex,lambey, code_precxy FROM belge.stations st ; -- 563 lines

select * from stationdbeel order by site
-----
-- Pour intégrer les données de pêche il faut détailler le nombre d'anguilles par passage
-- Intégration dans la table opérations

select numpas from belge.mesures_ang group by numpas -- de 1 à 4 et 12? mail SEP
select nb_pas from belge.operations  group by nb_pas -- de 1 à 4 passages
select*from belge.mesures_ang order by id -- données en double idem pour anguilles
select*from belge.operations order by id -- données en double egalement
select*from belge.stations order by site,organisme,eau -- pas en double

	select  m.nbrind
	FROM belge.operations op JOIN belge.mesures_ang m ON (m.codsit=op.site  AND m.datvis=op.dates) where numpas=1
	(select m.nbrind
	FROM belge.operations op JOIN belge.mesures_ang m ON (m.codsit=op.site  AND m.datvis=op.dates) where numpas=2 
	(select m.nbrind as nbp3
	FROM belge.operations op JOIN belge.mesures_ang m ON (m.codsit=op.site  AND m.datvis=op.dates) where numpas=3 
	(select m.nbrind as nbp4
	FROM belge.operations op JOIN belge.mesures_ang m ON (m.codsit=op.site  AND m.datvis=op.dates) where numpas=4 

-- Rerentrer le tableau mesures_ang ou supprimer les lignes doubles
-- Créer 4 colonnes dans opérations 
----------------------------------------------------
-- belge.electrofishing
---------------------------------------------------

alter table operations add constraint c_pk_id PRIMARY KEY (ope_id);
drop table if exists operationspeche;
create table operationspeche as select ope_id,
		organisme,
		code_typpec,
		eau,
		site,
		dates,
		nb_pas,
		statut_validation,
		resultatsfish,
		code_repres_spec,
		surface_peche from operations where code_typpec = 'PECHEELECTRIQUE';--874
alter table operationspeche add constraint c_pk_id_operationspeche PRIMARY KEY (ope_id);
-- creation de la cle etrangere vers station
alter table operationspeche add constraint c_fk_site FOREIGN KEY (site) REFERENCES stations(site) ;
select count(*) from operationspeche; --874


DROP TABLE if exists belge.electrofishing CASCADE;
CREATE TABLE belge.electrofishing (
	LIKE belge.operationspeche INCLUDING DEFAULTS INCLUDING CONSTRAINTS,-- seulement pour les contraintes check
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
		ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.electrofishing);


INSERT INTO belge.electrofishing (ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date,ob_ending_date,ob_dp_id,
		ef_no_fishingmethod,ef_no_electrofishing_mean,ef_wetted_area,ef_fished_length,ef_fished_width,ef_duration,ef_nbpas,ob_op_id,
		ope_id,
		organisme,
		code_typpec,
		eau,
		site,
		dates,
		nb_pas,
		statut_validation,
		resultatsfish,
		code_repres_spec,
		surface_peche 
		)
	SELECT 
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	dates AS ob_starting_date,
	NULL AS ob_ending_date,
	data_provider.dp_id AS ob_dp_id, -- belge
	case when nb_pas is null then 61 -- Unknown
	when nb_pas>=2 then 62 --whole (peche complete)
	when nb_pas=1 then 61 else
	61 end AS ef_no_fishingmethod, --scientific_observation_method.no_id,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	surface_peche AS ef_wetted_area, 
	NULL AS ef_fished_length,
	NULL AS ef_fished_width,
	NULL AS ef_duration,
	nb_pas AS ef_nbpas, 
	op.*
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		(select st.op_id as op_ob_id, op.* from belge.operationspeche op  
		join belge.stationdbeel st on op.site=st.site 
		order by site
		) as op			
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.sc_observation_category='Unknown'
	--AND scientific_observation_method.sc_observation_category='Electro-fishing' (je le met pas plusieurs cas)
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='Unknown' --  a preciser plus tard
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Laura'; --874 lignes

select * from belge.electrofishing	

-------------------------------
-- Batch intégration
-------------------------------
-- 
select count (*) from mesures_ang;--1501
select * from mesures_ang;
/*
alter table mesures_ang add constraint c_pk_mea_id PRIMARY KEY (mea_id) ;
alter table mesures_ang add column mea_ope_id integer;
alter table mesures_ang add constraint c_fk_ope_id FOREIGN KEY (mea_ope_id) references operationspeche (ope_id);
*/
update mesures_ang set mea_ope_id=sub.ope_id
from (select ope_id, mea_id from mesures_ang mea join operationspeche o on (mea.codsit,mea.datvis)=(o.site,o.dates)) sub
where sub.mea_id=mesures_ang.mea_id;--1285

--select * from mesures_ang where mea_ope_id is not null;

update mesures_ang set numpas=1 where mea_ope_id=263;--11

select * from belge.electrofishing

drop view joineel;
create or replace view joineel as select ob_op_id,ob_id,mea_id,mea_ope_id,site as ope_st_id,numpas,lonmin,lonmax,nbrind from belge.electrofishing 
join mesures_ang on mea_ope_id=ope_id;
select * from joineel;



-- La première table fait référence aux opérations de pêches (electrofishing)

DROP TABLE if exists belge.batch_ope CASCADE;
CREATE TABLE belge.batch_ope (
		ope_id integer, 
		ope_st_id character varying(25),
		pa_numero integer,
		nb integer,
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
	CONSTRAINT c_fk_batch_ope_ope_st_id FOREIGN KEY (ope_st_id)
		REFERENCES belge.stations (site) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
		) INHERITS (dbeel.batch);

--select * from belge.batch_ope;
-- on peut mettre les ob_op_id dans le group by car structurellement ça rajoutera pas de lignes
/*
select sum(nbrind),ob_op_id,ob_id from joineel group by ob_op_id,ob_id
union 
select 0 as sum, ob_op_id,ob_id from belge.electrofishing  where ope_id not in (
select mea_ope_id from joineel);--874
*/

-- nb_total
INSERT INTO belge.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel2.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	joineel2.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id,cast(NULL as uuid) as ba_ba_id,mea_ope_id as ope_id,ope_st_id,0 as pa_numero,sum(nbrind) as nb from joineel group by ob_op_id,ob_id,mea_ope_id,ope_st_id
	union 
	select  ob_id,cast(NULL as uuid) as ba_ba_id,ope_id,site as ope_st_id, 0 as pa_numero, 0 as nb from belge.electrofishing  where ope_id not in (
	select mea_ope_id from joineel)
	)joineel2
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';    --874 lines

/*
select * from batch_ope
select * from joineel where numpas=12;
select * from joineel where mea_ope_id=263

select * from joineel;
select ob_op_id,ob_id,cast(NULL as uuid) as ba_ba_id,mea_ope_id as ope_id,1 as pa_numero,sum(nbrind) as nb from joineel 
where numpas=1 
group by ob_op_id,ob_id,mea_ope_id
*/

-- op_nbp1
INSERT INTO belge.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel2.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel2.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id,cast(NULL as uuid) as ba_ba_id,mea_ope_id as ope_id,ope_st_id,1 as pa_numero,sum(nbrind) as nb from joineel 
	where numpas=1 
	group by ob_op_id,ob_id,mea_ope_id,ope_st_id) as joineel2
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--200 lines

	-- op_nbp2
INSERT INTO belge.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel2.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel2.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id,cast(NULL as uuid) as ba_ba_id,mea_ope_id as ope_id,ope_st_id,2 as pa_numero,sum(nbrind) as nb from joineel 
	where numpas=2 
	group by ob_op_id,ob_id,mea_ope_id,ope_st_id) as joineel2
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--96 lines

	-- op_nbp3
INSERT INTO belge.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel2.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel2.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id,cast(NULL as uuid) as ba_ba_id,mea_ope_id as ope_id,ope_st_id,3 as pa_numero,sum(nbrind) as nb from joineel 
	where numpas=3 
	group by ob_op_id,ob_id,mea_ope_id,ope_st_id) as joineel2
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--2 lines

	-- op_nbp4
INSERT INTO belge.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	joineel2.nb AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	joineel2.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id,cast(NULL as uuid) as ba_ba_id,mea_ope_id as ope_id,ope_st_id,4 as pa_numero,sum(nbrind) as nb from joineel 
	where numpas=4 
	group by ob_op_id,ob_id,mea_ope_id,ope_st_id) as joineel2
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p4' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--1 line


-- pas de densités
/*
INSERT INTO belge.batch_ope
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
	(select ob_id as ba_ob_id, cast(NULL as uuid) as ba_ba_id,op_st_id,op_id,op_density as op_nb, cast(Null as integer) as pa_numero from belge.electrofishing) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';	
*/
	

-- Batch integration, the second level will reference the fish table
select * from joineel
select * from joineel join operationspeche on mea_ope_id=ope_id order by lonmax
-- les anguilles de belgique sont grosses mais pas plus que ça....
-- A 100 km  de la mer...
-- Mais il y a eu des transports...
update mesures_ang set lonmax=NULL where lonmax=9999;-- prétentieux
-- les petites anguilles correspondent elles à des opérations ou les anguilles sont nombreuses (sites de déversements ?)
select * from mesures_ang
where mea_ope_id in 
(select ope_id from batch_ope where ba_batch_level=1 and ba_quantity>10)
order by codsit,lonmax
--1275 1276 1277=> civelles a virer 
--100BUR
--1288 1290 => civelles
--BERW_40222 lâché de civelles (correspondant à 1288 1290)
--BERW_03260 189 182
--1338 site=BERW_04130
--18
select * from mesures_ang where codsit='100BUR'
select * from mesures_ang
where mea_ope_id not in (1275,1276,1277,1288,1290,1338,189,182)
order by lonmax;
select * from mesures_ang where lonmax<50 and datvis<'1998-01-01'
update mesures_ang set lonmax=10*lonmax where lonmax<50 and datvis<'1998-01-01';--3

-- données de taille
DROP TABLE if exists belge.batch_fish CASCADE;
CREATE TABLE belge.batch_fish (
	ba_ope_id integer,
	mea_id integer,
	--LIKE belge.fish_fi INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
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
		CONSTRAINT c_fk_fi_op_id FOREIGN KEY (ba_ope_id)
		REFERENCES belge.operationspeche (ope_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
		) INHERITS (dbeel.batch);

select * from belge.batch_fish

-- creation des lots avec 1 ind;
INSERT INTO belge.batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	3 AS ba_batch_level,
	joineel.* --contains ba_ob_id and ba_ba_id
	FROM dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 
	(select ob_id as ba_ob_id,
		cast(NULL as uuid) as ba_ba_id,
		mea_ope_id as ba_ope_id,
		mea_id		
		from joineel 
		where  lonmax is not null
		and nbrind=1
	) as joineel
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data';--1211

DROP TABLE if exists belge.mensurationindiv_biol_charac CASCADE;
CREATE TABLE belge.mensurationindiv_biol_charac  (
	CONSTRAINT pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_value_type 	FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES belge.batch_fish (ba_id) ON DELETE RESTRICT ON UPDATE CASCADE
)INHERITS (dbeel.biological_characteristic);
-- select * from belge.mensurationindiv_biol_charac


-- tailles
INSERT INTO belge.mensurationindiv_biol_charac
	SELECT 
		 uuid_generate_v4() AS bc_id, 
		 ba_id AS bc_ba_id, 
		 biological_characteristic_type.no_id AS bc_no_characteristic_type, 
		 value_type.no_id AS bc_no_value_type, 
		 lonmax AS bc_numvalue
	FROM 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type,
	belge.batch_fish,
	mesures_ang
	WHERE  mesures_ang.mea_id=batch_fish.mea_id		
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; --1211 lines

-- select * from mesures_ang


-----------------------------------------------------------------------------
-- Creation de la table stations_ccm_500 avec l'id station et l'id de la CCM
-----------------------------------------------------------------------------

-- Table pour les stations
-- Juste la Meuse belge car on doit attendre les données de pêches pour la hollande et la France
DROP TABLE IF EXISTS belge.stations_ccm_500;
CREATE TABLE belge.stations_ccm_500 as (
        SELECT distinct (locationcode) locationcode, gid, wso1_id, min(distance) as distance, the_geom FROM (  
               SELECT site as locationcode, gid, wso1_id, distance, s.the_geom 
               FROM dbeel.observation_places_CCM_500 s
               join belge.stationdbeel o ON o.op_id=s.op_id 
               WHERE s.the_geom IS NOT NULL
               ORDER BY site) AS sub 
               GROUP BY locationcode, gid, gid, wso1_id,  distance,the_geom -- 516 lignes pour Meuse
);

alter table belge.stations_ccm_500 add column id serial;
-- mise à jour de la table geometry_columns
/*
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'belge', 'stations_ccm_500', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM oria.oria_ccm_500 LIMIT 1;
*/

-- creation d'index, clé primaire, et constraintes qui vont bien
alter table belge.stations_ccm_500 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table belge.stations_ccm_500 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table belge.stations_ccm_500 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
alter table belge.stations_ccm_500 ADD CONSTRAINT pk_locationcode PRIMARY KEY(locationcode);
CREATE INDEX indexbelge_ccm_500 ON belge.stations_ccm_500
  USING GIST ( the_geom GIST_GEOMETRY_OPS );
  
-- select * from belge.stations_ccm_500


