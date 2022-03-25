ag_roe_temp2014_05_19.txt
ap_roe_temp2014_05_19.txt
lb_roe_temp2014_05_19.txt
nr_roe_temp2014_05_19.txt
rmc_roe_temp2014_05_19.txt
rm_roe_temp2014_05_19.txt
sn_roe_temp2014_05_19.txt
SET client_encoding ='LATIN1';
alter table roe alter column "pre_ice_date_creation_ouvrage" type text;
alter table roe alter column "pre_ice_note_fr_Alose" type text;
alter table roe alter column "pre_ice_note_fr_Alose_feinte" type text;
alter table roe alter column "pre_ice_note_fr_Anguille" type text;
alter table roe alter column "pre_ice_note_fr_Apron" type text;
alter table roe alter column "pre_ice_note_fr_Brochet" type text;
alter table roe alter column "pre_ice_note_fr_CypEC" type text;
alter table roe alter column "pre_ice_note_fr_CypEV" type text;
alter table roe alter column "pre_ice_note_fr_Grale" type text;
alter table roe alter column "pre_ice_note_fr_LamproieM" type text;
alter table roe alter column "pre_ice_note_fr_OmbreComm" type text;
alter table roe alter column "pre_ice_note_fr_PEBenth" type text;
alter table roe alter column "pre_ice_note_fr_Salmonides" type text;
alter table roe alter column "pre_ice_note_fr_Saumon" type text;
alter table roe alter column "pre_ice_note_fr_TruiteMer" type text;
alter table roe alter column  roe_commentaire_validation  type text;
alter table roe alter column "deptCd" type text;
alter table roe alter column "commCd" type text;
delete from roe where bassin_hydrographique='Artois-Picardie'
alter table roe add primary key("Id_ROE")
COPY roe FROM 'C:/Users/admin-mig/Desktop/roe/ap_roe_temp2014_05_19.txt' CSV HEADER DELIMITER ';' NULL as '';--2324
-- line 538 P; KOLO => P. KOLO
COPY roe FROM 'C:/Users/admin-mig/Desktop/roe/lb_roe_temp2014_05_19.txt' CSV HEADER DELIMITER ';' NULL as '';--24191 lignes modifiées
COPY roe FROM 'C:/Users/admin-mig/Desktop/roe/nr_roe_temp2014_05_19.txt' CSV HEADER DELIMITER ';' NULL as '';--73
COPY roe FROM 'C:/Users/admin-mig/Desktop/roe/rmc_roe_temp2014_05_19.txt' CSV HEADER DELIMITER ';' NULL as '';--20406
--A FAIRE CI DESSOUS
COPY roe FROM 'C:/Users/admin-mig/Desktop/roe/rm_roe_temp2014_05_19.txt' CSV HEADER DELIMITER ';' NULL as '';--8752
COPY roe FROM 'C:/Users/admin-mig/Desktop/roe/sn_roe_temp2014_05_19.txt' CSV HEADER DELIMITER ';' NULL as '';--12378 lignes modifiées



-- mise à jour de la table geometry_columns
select Probe_Geometry_Columns(); 
-- ajout de la coordonnées géographique
select  * from roe limit 100
select AddGeometryColumn('public', 'roe', 'geom', 3035, 'POINT', 2);
update roe set geom=ST_transform(ST_PointFromText('POINT('||"XCartL93"||' '||"YCartL93"||')',2154),3035);--80262

set search_path to belge,public;
/*
retour des données dans la dbeel er dans eda2.1
H:
cd base
pg_dump -U postgres -h 1.100.1.6 -f "belge.roe.sql" --table roe --verbose roe
psql -U postgres -h 1.100.1.6 -f "belge.roe.sql"  dbeel
pg_dump -U postgres -h 1.100.1.6 --table roe --verbose roe|psql -U postgres -h 1.100.1.6 eda2.1


*/
-- Script integration des obstacles dans dbeel

-- select * from obstacles

set search_path to belge,onema,public,dbeel;
select * from roe limit 10;
alter table roe set schema onema;

-- il faut d'abord rentrer un lieu
create table onema.roecourt as (select "Id_ROE",
	"roe_Nom",
	"bassin_hydrographique",
	"bassin_administratif",
	"deptCd",
	"deptNom",
	"commCd",
	"commNom",
	"ObjFusion_id",
	"IdTopo",
	"nomTopo",
	"IdTrCart",
	"nomCart",
	"etatNom",
	"roe_typeCd",
	"roe_typeNom",
	"roe_stypeCd",
	"roe_stypeNom",
	"roe_stypEmCd1",
	"roe_stypEmNom1",
	"roe_stypEmCd2",
	"roe_stypEmNom2",
	"roe_stypEmCd3",
	"roe_stypEmNom3",
	"roe_fnt1_code",
	"roe_fnt1_nom",
	"roe_fnt2_code",
	"roe_fnt2_nom",
	"roe_fnt3_code",
	"roe_fnt3_nom",
	"roe_staCd",
	"roe_staNom",
	"roe_etatCd",
	"roe_dateModif",
	"roe_source",
	"pre_ice_hauteur_terrain",
	"pre_ice_hauteur_chute",
	"pre_ice_nom_2",
	"pre_ice_date_creation_ouvrage",
	"pre_ice_usage1",
	"pre_ice_usage2",
	"pre_ice_usage3",
	"pre_ice_usage4",
	"pre_ice_fpi1",
	"pre_ice_fpi2",
	"pre_ice_fpi3",
	"pre_ice_fpi4",
	"pre_ice_fpi5",
	"pre_ice_note_fr_Anguille",
	"roe_commentaire_validation",
	"roe_commentaire_suppression"
	FROM onema.roe)


DROP TABLE if exists onema.roedbeel CASCADE;
CREATE TABLE onema.roedbeel (
        "Id_ROE" character varying,
        CONSTRAINT pk_obs_op_id PRIMARY KEY (op_id),
        CONSTRAINT c_uk_id_roe UNIQUE ("Id_ROE"),
        CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
                REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
                MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);
-- select * from belge.ouvragedbeel;

INSERT INTO onema.roedbeel
        SELECT  uuid_generate_v4() AS op_id,
        '3035' AS op_gis_systemname ,
        'roe' AS op_gis_layername, 
        "Id_ROE" AS op_gislocation,
        "roe_Nom" AS op_placename,
        11 AS op_no_observationplacetype, -- Obstacle location
        NULL AS  op_op_id,
        geom as the_geom,
        "Id_ROE" -- on a rajouté qu'une seule colonne, seulement l'identifiant de l'ouvrage....
         FROM onema.roe 
         where "roe_staCd"=1 ; -- 80262 lines

--select * from onema.roedbeel

  
DROP TABLE if exists onema.physical_obstruction CASCADE;
CREATE TABLE onema.physical_obstruction(
  LIKE onema.roecourt,
  CONSTRAINT physical_obstruction_id PRIMARY KEY (ob_id),
  CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id),
  CONSTRAINT fk_ob_origin FOREIGN KEY (ob_no_origin)REFERENCES dbeel_nomenclature.observation_origin (no_id) ,
  CONSTRAINT fk_ob_period FOREIGN KEY (ob_no_period) REFERENCES dbeel_nomenclature.period_type (no_id) ,
  CONSTRAINT fk_ob_type FOREIGN KEY (ob_no_type) REFERENCES dbeel_nomenclature.observation_type (no_id) ,
  CONSTRAINT fk_po_obstruction_passability FOREIGN KEY (po_no_obstruction_passability)REFERENCES dbeel_nomenclature.obstruction_impact (no_id) 
) INHERITS (dbeel.physical_obstruction);

-- select * from belge.physical_obstruction
--select "pre_ice_note_fr_Anguille",count(*) from onema.roe group by "pre_ice_note_fr_Anguille"
INSERT INTO onema.physical_obstruction 
  SELECT 
  uuid_generate_v4() as ob_id,
  11 AS ob_no_origin, -- raw data
  16 AS ob_no_type, -- obstruction
  74 AS ob_no_period, -- Unknown
  NULL AS ob_starting_date,
  NULL AS ob_ending_date,
  d.op_id as ob_op_id,
  7 AS ob_dp_id,--Laura
  219 as ot_no_obstruction_type,-- physical
  1 as ot_obstruction_number,
  NULL AS ot_no_mortality_type,
  NULL AS ot_no_mortality,
  NULL as po_no_obstruction_passability,
  case when  (pre_ice_hauteur_chute=-999 and pre_ice_hauteur_terrain != -999) then pre_ice_hauteur_terrain
  when pre_ice_hauteur_chute=-999 then NULL
  else pre_ice_hauteur_chute end as po_obstruction_height,
  NULL AS po_turbine_number,
	 d."Id_ROE",
	"roe_Nom",
	"bassin_hydrographique",
	"bassin_administratif",
	"deptCd",
	"deptNom",
	"commCd",
	"commNom",
	"ObjFusion_id",
	"IdTopo",
	"nomTopo",
	"IdTrCart",
	"nomCart",
	"etatNom",
	"roe_typeCd",
	"roe_typeNom",
	"roe_stypeCd",
	"roe_stypeNom",
	"roe_stypEmCd1",
	"roe_stypEmNom1",
	"roe_stypEmCd2",
	"roe_stypEmNom2",
	"roe_stypEmCd3",
	"roe_stypEmNom3",
	"roe_fnt1_code",
	"roe_fnt1_nom",
	"roe_fnt2_code",
	"roe_fnt2_nom",
	"roe_fnt3_code",
	"roe_fnt3_nom",
	"roe_staCd",
	"roe_staNom",
	"roe_etatCd",
	"roe_dateModif",
	"roe_source",
	"pre_ice_hauteur_terrain",
	"pre_ice_hauteur_chute",
	"pre_ice_nom_2",
	"pre_ice_date_creation_ouvrage",
	"pre_ice_usage1",
	"pre_ice_usage2",
	"pre_ice_usage3",
	"pre_ice_usage4",
	"pre_ice_fpi1",
	"pre_ice_fpi2",
	"pre_ice_fpi3",
	"pre_ice_fpi4",
	"pre_ice_fpi5",
	"pre_ice_note_fr_Anguille",
	"roe_commentaire_validation",
	"roe_commentaire_suppression"
  FROM                  
  onema.roecourt r JOIN  onema.roedbeel d ON r."Id_ROE"=d."Id_ROE"
  where "roe_staCd"=1;--73332


--====================================================================
-- projection roe ccm
-- creation d'une table à partir de la dbeel
--====================================================================



CREATE INDEX indexgeobs ON dbeel.observation_places  USING GIST (the_geom GIST_GEOMETRY_OPS);
/*
pg_dump -U postgres -h 1.100.1.6 -f "dbeel_nomenclature.sql" --schema dbeel_nomenclature --verbose dbeel
pg_dump -U postgres -h 1.100.1.6 -f "dbeelschema.sql" --schema dbeel --verbose dbeel
pg_dump -U postgres -h 1.100.1.6 -f "onmeaschemadbeel.sql" --schema onema --verbose dbeel
pg_dump -U postgres -h 1.100.1.6 -f "belgeschemadbeel.sql" --schema belge --verbose dbeel
psql -U postgres -h 192.168.1.104 -f "dbeel_nomenclature.sql" eda2
psql -U postgres -h 192.168.1.104  -f "dbeelschema.sql" eda2
psql  -U postgres -h 192.168.1.104  -f "onmeaschemadbeel.sql" eda2
psql  -U postgres -h 192.168.1.104  -f "belgeschemadbeel.sql" eda2

*/
create table belge.observation_places_ccm_300 as
select ob.* from dbeel.observation_places op join 
dbeel.observations ob on ob_op_id=op_id
where ob_dp_id=7

DROP TABLE IF EXISTS dbeelproj.observation_places_ccm_300;
CREATE TABLE dbeelproj.observation_places_ccm_300 as (
        SELECT distinct on (ref_id) ref_id, gid, min(distance) as distance, height, score,nbdams,ref_position_etrs89 as the_geom FROM (
               SELECT ref_id, gid ,CAST(distance(r.the_geom, b.ref_position_etrs89) as  decimal(15,1)) as distance ,b.ref_position_etrs89,
               CASE WHEN  ref_hauteur_chute>0 then ref_hauteur_chute
                    WHEN   ref_hauteur_chute=0 then ref_hauteur_chute
                    ELSE  ref_hauteur_terrain
                    END  AS height,
                0 As score,
                1 AS nbdams -- pour jointure ultérieure
               FROM geobs2010.obstacle_referentiel As b
               INNER JOIN  ccm21.riversegments r ON ST_DWithin(r.the_geom, b.ref_position_etrs89,300)
--             WHERE b.goodproj IS TRUE
               ORDER BY ref_id) AS sub 
        GROUP BY ref_id, distance, gid,height,score,nbdams ,the_geom
); 





-- si la commande ci dessus ne marche pas ...
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'geobs2010', 'roe_ccm_300', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM geobs2010.roe_ccm_300 LIMIT 1;

-- creation d'index, clé primaire, et constraintes qui vont bien
alter table geobs2010.roe_ccm_300 add column id serial PRIMARY KEY;
alter table geobs2010.roe_ccm_300 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table geobs2010.roe_ccm_300 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table geobs2010.roe_ccm_300 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);

CREATE INDEX indexgeobsroe_ccm_300 ON geobs2010.roe_ccm_300
  USING GIST ( the_geom GIST_GEOMETRY_OPS );

/*
SCRIPT POUR EDA2_RHT
*/

alter table roe rename to roe_v3;
alter table roe_v3 set schema roe_v3;
select * from roe_v3.roe_v3 limit 10
-- Je recrée la même table que précédemment
-- table de projection

DROP TABLE IF EXISTS rht.rht_roev3;
CREATE TABLE rht.rht_roev3 as (
        SELECT distinct on (id_roe) id_roe, id_drain, min(distance) as distance, geom FROM (
               SELECT "Id_ROE" as id_roe, id_drain ,CAST(distance(r.the_geom, s.geom) as  decimal(15,1)) as distance, s.geom 
               FROM roe_v3.roe_v3 s
               INNER JOIN  rht.rht r ON ST_DWithin(r.the_geom, s.geom,300)
               WHERE s.geom IS NOT NULL
               ORDER BY "Id_ROE") AS sub 
        GROUP BY id_roe, distance,id_drain, geom  ---68697 lines
); 
alter table rht.rht_roev3 add column id serial;
-- mise à jour de la table geometry_columns
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'rht', 'rht_roev3', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM rht.rht_roev3 LIMIT 1;

-- creation d'index, clé primaire, et constraintes qui vont bien
alter table rht.rht_roev3 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table rht.rht_roev3 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table rht.rht_roev3 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
alter table rht.rht_roev3 ADD CONSTRAINT pk_idroe PRIMARY KEY(id);
alter table rht.rht_roev3 drop CONSTRAINT pk_idroe;
CREATE INDEX indexroev3_rht ON rht.rht_roev3
  USING GIST ( the_geom GIST_GEOMETRY_OPS );

--verification

select "pre_ice_note_fr_Anguille" from roe_v3.roe_v3 where "pre_ice_note_fr_Anguille" is not NULL;-- 7417
select distinct "pre_ice_note_fr_Anguille" from roe_v3.roe_v3 where "pre_ice_note_fr_Anguille" is not NULL;
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"='2' where "pre_ice_note_fr_Anguille"='2+';
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"='1' where "pre_ice_note_fr_Anguille"=' 1';
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"='3.5' where "pre_ice_note_fr_Anguille"='34';--1
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"='2.5' where "pre_ice_note_fr_Anguille"='23';--1
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"=NULL where "pre_ice_note_fr_Anguille"='Inc';--6
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"=NULL where "pre_ice_note_fr_Anguille"='?';--32
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"=2.3 where "pre_ice_note_fr_Anguille"='2.3 avant passe usine';--4
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"=0 where "pre_ice_note_fr_Anguille"='0 sur Cantache';--1
select replace("pre_ice_note_fr_Anguille",',','.') from roe_v3.roe_v3 where "pre_ice_note_fr_Anguille" like '%,%';
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"=replace("pre_ice_note_fr_Anguille",',','.') where "pre_ice_note_fr_Anguille" like '%,%';
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"=replace("pre_ice_note_fr_Anguille",'+','') where "pre_ice_note_fr_Anguille" like '%+%';--1
update roe_v3.roe_v3 set "pre_ice_note_fr_Anguille"=replace("pre_ice_note_fr_Anguille",'-','') where "pre_ice_note_fr_Anguille" like '%-%';--5
select count(*) from roe_v3.roe_v3 where "roe_staCd"=1 -- 73332
select count(*) from roe_v3.roe_v3 where "roe_staCd"=1 and pre_ice_hauteur_chute>0; -- 32146/73332=43%

alter table roe_v3.roe_v3 add column pre_ice_note_fr_anguille numeric;
update  roe_v3.roe_v3 set pre_ice_note_fr_anguille=cast("pre_ice_note_fr_Anguille" as numeric);--80262

select count(*) from roe_v3.roe_v3; --80262
-- fonction modifiée fin 2014 pour aller chercher les scores et les hauteurs de chutes
-- lancement 10/12/2014 
-- verif voir chunk analyseROE dans eda
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- modif ajout dans cette table de heightp les hauteurs réelles ou prédites quand NA LANCER LE SCRIPT R APRES CETTE COMMANDE , chunk analyseROE eda.rnw
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- il en manque encore quelques unes à l'étranger et pour quelques types (je n'ai pas vérifié) qui n'étaient pas dans le jeu de données de départ
DROP TABLE IF EXISTS rht.rhtvs2_roev3;
CREATE TABLE rht.rhtvs2_roev3 as (
        SELECT distinct on (id_roe) id_roe, id_drain, min(distance) as distance, geom,nbdams,height,score FROM (
               SELECT "Id_ROE" as id_roe, id_drain ,CAST(distance(r.the_geom, s.geom) as  decimal(15,1)) as distance, s.geom,
                1 AS nbdams, -- pour jointure ultérieure 
               CASE WHEN  pre_ice_hauteur_chute>=0 then pre_ice_hauteur_chute
                    WHEN pre_ice_hauteur_terrain>=0 then pre_ice_hauteur_terrain
                    ELSE null
                    END  AS height,
                 pre_ice_note_fr_Anguille as score   
               FROM roe_v3.roe_v3 As s
               INNER JOIN  rht.rhtvs2 r ON ST_DWithin(r.the_geom, s.geom,300)
               WHERE s.geom IS NOT NULL
               AND "roe_staCd"=1 -- validé point par point
               AND (ouv_fils =FALSE or ouv_fils is null)
               ORDER BY id_roe) AS sub 
        GROUP BY id_roe, distance,id_drain,height,score,nbdams, geom  ---49269 lines =>62913 en enlevant les ouvrages fils voire ci-après
); 
alter table rht.rhtvs2_roev3 add column id serial;
-- mise à jour de la table geometry_columns
/*
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'rht', 'rhtvs2_roev3', 'geom', ST_CoordDim(geom), ST_SRID(geom), GeometryType(geom)
FROM rht.rhtvs2_roev3 LIMIT 1;
*/
-- creation d'index, clé primaire, et constraintes qui vont bien
alter table rht.rhtvs2_roev3 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(geom) = 2);
alter table rht.rhtvs2_roev3 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(geom) = 'POINT'::text OR geom IS NULL);
alter table rht.rhtvs2_roev3 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(geom) = 3035);
alter table rht.rhtvs2_roev3 ADD CONSTRAINT pk_idroe PRIMARY KEY(id);
alter table rht.rhtvs2_roev3 drop CONSTRAINT pk_idroe;
CREATE INDEX indexroev3_rhtvs2 ON rht.rhtvs2_roev3
  USING GIST ( geom GIST_GEOMETRY_OPS );
-- select count(*) from rht.rhtvs2_roev3

  /* 
  petits tests
  ci dessous pas évident de comparer sur idbcarthage que la projection est juste
  */

alter table roe_v3.roe_v3 add column c_ss_sect character varying(3);
update roe_v3.roe_v3 set c_ss_sect=sub.c_ss_sect from(
select
"Id_ROE",
ss.c_ss_sect
from roe_v3.roe_v3 rr join
 bd_carthage2011.sous_secteur ss on st_intersects(ss.the_geom,rr.geom)) sub
 where sub."Id_ROE"=roe_v3."Id_ROE";

/*
POUR RECUPERER DANS R
*/
select c_ss_sect,st_astext(the_geom) from bd_carthage2011.sous_secteur
-- voir chunk analyseROE dans eda.rnw, au final ne marche pas=> n'a pas la mémoire pour afficher
/*
petits test
Pourcentage de NA par sous zone hydro
*/
select * from rht.rhtvs2_roev3 limit 1000

/*
petits test
Ouvratge liés
Ajout d'une colonne ouv_fils
*/
alter table roe_v3.roe_v3 add column ouv_fils boolean;

--- Je commence par indenfier les ouvrages fils
update roe_v3.roe_v3 set ouv_fils=true where "Id_ROE" in
(
select ouv_fils from (
with level1 as
(select "Id_ROE" as ouv_pere,unnest(regexp_split_to_array(pre_ice_ouv_lies,' - ')) as ouv_fils from roe_v3.roe_v3 where  pre_ice_ouv_lies is not NULL) 
select level1.ouv_pere,level1.ouv_fils, level2.ouv_fils as ouv_petitfils from level1 join level1 as level2 on level1.ouv_fils=level2.ouv_pere
)sub);--82
-- Je vire les ouvrages qui bouclent de cette liste
update roe_v3.roe_v3 set ouv_fils=FALSE where "Id_ROE" in
(
select ouv_petitfils from (
with level1 as
(select "Id_ROE" as ouv_pere,unnest(regexp_split_to_array(pre_ice_ouv_lies,' - ')) as ouv_fils from roe_v3.roe_v3 where  pre_ice_ouv_lies is not NULL) 
select level1.ouv_pere,level1.ouv_fils, level2.ouv_fils as ouv_petitfils from level1 join level1 as level2 on level1.ouv_fils=level2.ouv_pere
)sub where ouv_pere=ouv_petitfils);--60

select count(*) from roe_v3.roe_v3 where  ouv_fils;

drop table if exists rht.rht_bdcarthage_roev3;
create table rht.rht_bdcarthage_roev3 as
select v.*, bdc.*
from roe_v3.roe_v3 v
join rht.rht_bdcarthage bdc on bdc.id_bdcarth=cast(v."IdTrCart" as integer); ---68697 lines
CREATE INDEX indexrhtbdcroe
ON rht.rht_bdcarthage_roev3
USING btree (id_roe);
alter table rht.rht_bdcarthage_roev3 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table rht.rht_bdcarthage_roev3 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table rht.rht_bdcarthage_roev3 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
alter table rht.rht_bdcarthage_roev3 ADD CONSTRAINT pk_idroe PRIMARY KEY(id_roe);
CREATE INDEX indexrht_bdc_roev3_geom
  ON rht.rht_bdcarthage_roev3
  USING gist (the_geom GIST_GEOMETRY_OPS);

Comment on table rht.rht_bdcarthage_roev3 IS 'Jointure entre id_drain et id_roe à partir de id_bdcarthage - Table à utiliser pour récupérer les barrages du ROE';





/*
pg_dump -U postgres -h 1.100.1.6 -f "roe_v3.sql" --table roe_v3.roe_v3 --verbose eda2.1
pg_dump -U postgres -h 1.100.1.6 -f "rht.rht_bdcarthage_roev3.sql" --table rht.rht_bdcarthage_roev3 --verbose eda2.1
pg_dump -U postgres -h 1.100.1.6 -f "rht.rht_roev3.sql" --table rht.rht_roev3 --verbose eda2.1
*/

/*
Travail RHT fin 2014 Cédric
la table rhtv2_roe correspond au deuxième script sur rht modifié par Céline
http://trac.eptb-vilaine.fr:8066/trac/wiki/Noeud%20-%20parcours%20RHT
Je commence par renommer rht.rht_roev3 en rhtvs2_roev3
*/




drop table if exists rht.rhtvs2_roev3_nbdams;
create table rht.rhtvs2_roev3_nbdams as
select id_drain, count(nbdams) as nbdams, sum(coalesce(height,0)) as c_height,sum(coalesce(heightp,0))as c_heightp,
sum(coalesce(score,0)) as c_score  from rht.rhtvs2_roev3 as r group by id_drain;--25814

---100 lines
-- J'ai besoin d'aller chercher les barrages de la frontière à partir des tronçons bd_carthage.
--Comment aller chercher les infos sur le nombre de barrages et la distance mer, les données sont dans la ccm ?
/*
installation de dblink (je suis aller chercher le code sql dans contrib), dblink s'installe dans une base de données PostgreSQL: pgsql/contrib/dblink/dblink.sql

 cross database query
-- je crée une table contenant la ccm.riversegments pour la France avec les colonnes qui m'intéressent.

---Cedric
select dblink_connect('connectionccm','hostaddr=93.20.247.238 port=5432 dbname=eda2 user=postgres password=petromyzon***');

-- table crée dans le schéma en 2012
create schema ccm;
drop table if exists ccm.riversegments_france;
create table ccm.riversegments_france as (
SELECT * FROM dblink('connectionccm','SELECT wso1_id,cs_nbdams,cum_len_sea,the_geom  FROM ccm21.riversegments r join europe.wso w on r.wso_id=w.wso_id where area=''France''')
 AS  t(wso1_id int, cs_nbdams integer, cum_len_sea numeric,the_geom geometry)
);

-- je vais chercher dans la ccm les informations sur les distances mer et les cumuls de barrages

select distinct on (zonegeo) zonegeo from rht.noeudmervs2;

alter table rht.noeudmervs2 add column cumnbbar integer;
alter table rht.noeudmervs2 add column dmer numeric;
alter table rht.noeudmervs2 add column wso1_id integer;
alter table rht.noeudmervs2 add column c_height numeric;

update rht.noeudmervs2 set (cumnbbar,dmer,wso1_id)= (jointure.cs_nbdams,jointure.cum_len_sea,jointure.wso1_id) from
        -- resultat final de la jointure spatiale entre ccm et noeudfrontiere
        (select distinct on (id_drain) id_drain, min(distance) as distance, wso1_id,cs_nbdams, cum_len_sea from (
                -- requete intermédiaire dont on prend le min (sub)
                select id_drain, ST_distance(noeudfrontiere.the_geom,ccmrs.the_geom) as distance,ccmrs.*
                FROM ccm.riversegments_france ccmrs join
                (select id_drain, the_geom from rht.noeudmervs2 where noeudmer and zonegeo in ('Est','pyrénées')) as noeudfrontiere
                on ST_DWithin(noeudfrontiere.the_geom,ccmrs.the_geom, 500)) as sub
        group by id_drain, distance, wso1_id,cs_nbdams, cum_len_sea) as jointure
where noeudmervs2.id_drain=jointure.id_drain; --100 lines modifiées

*/
select * from rht.rhtvs2_roev3_nbdams
/*
Meuse
http://www.cipm-icbm.be/tempFiles/210558864_7.73257E-03/Rapport_Masterplan_octobre2011_f.pdf p18
rhin
http://www.iksr.org/fileadmin/user_upload/Dokumente_fr/Rapport/Rapport_179f.pdf
Moselle
http://www.iksr.org/fileadmin/user_upload/Dokumente_fr/Rapport/Rapport_n__162-f.pdf p46 11 barrages
Behrmann-Godel, J., and Eckmann, R. 2003. A preliminary telemetry study of the migration of silver European eel (Anguilla anguilla L.)
in the River Mosel, Germany. Ecology of Freshwater Fish 12: 196–202. 14 barrages (je suppose une hauteur de 1.5 m)
*/
select * from rht.noeudmervs2 where id_drain=500002
update rht.noeudmervs2 set( cumnbbar,c_height)=(29,25.7) where id_drain=500002; -- meuse
update rht.noeudmervs2 set( cumnbbar,c_height)=(4,17.6) where id_drain=503204;-- Rhin amont
update rht.noeudmervs2 set( cumnbbar,c_height)=(3,6) where id_drain=502548;-- Rhin
update rht.noeudmervs2 set( cumnbbar,c_height)=(3,6) where id_drain=502131;-- Rhin
update rht.noeudmervs2 set( cumnbbar,c_height)=(7,6) where id_drain=501864; -- lauter affluent rhin (le calcul de cumul ne sera pas effectué...)
update rht.noeudmervs2 set( cumnbbar,c_height)=(4,25.7) where id_drain=501822;-- lauter affluent rhin
update rht.noeudmervs2 set( cumnbbar,c_height)=(14,31) where id_drain=501822;-- moselle affluent rhin

-- mise à jour des distances mer (pas testé reprise et adaptation de l'ancien script)
update rht.rhtvs2 set dmer=sub.dmer from (select dmer from rht.noeudmervs2 where dmer is not null) sub
where sub.id_drain=rhtvs2.id_drain;  -- 100 lines

-- mise à jour des nombres de barrages aux noeuds frontière
update rht.rhtvs2_roev3_nbdams set (nbdams,c_height,c_heightp)=(sub.cumnbbar,sub.c_height,sub.c_height)
from (select id_drain,dmer,cumnbbar,c_height from rht.noeudmervs2 where dmer is not null) sub
where sub.id_drain=rhtvs2_roev3_nbdams.id_drain;  ---32 lines

create table rht.cs_heightpb as(
select c.id_drain, c.the_geom from rht.crosstab_rhtvs2 c join rht.attributs_rht_fev_2011_vs2 r on c.id_drain=r.id_drain
where cs_height>cast(altitude as numeric)); --2431

create table rht.cs_heightppb as(
select c.id_drain, c.the_geom from rht.crosstab_rhtvs2 c join rht.attributs_rht_fev_2011_vs2 r on c.id_drain=r.id_drain
where cs_heightp>cast(altitude as numeric)); --2431

alter table 
s