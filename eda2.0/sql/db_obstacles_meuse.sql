

-- Insertion des ouvrages de la Meuse Belge dans la dbeel

set search_path to belge,public;
select * from obstacles limit 100;
alter table obstacles add column obs_id serial primary key;
select st_srid(the_geom) from obstacles;--31300
update belge.obstacles set the_geom=st_setsrid(the_geom,31370);
update belge.obstacles set the_geom=ST_PointFromText('POINT('||x_lb72||' '||y_lb72||')',31370);--8188
update belge.obstacles set the_geom=st_transform(the_geom,3035);--2484
alter table belge.obstacles ADD CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2);
alter table belge.obstacles ADD CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text);
alter table belge.obstacles ADD CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 3035);
alter table belge.obstacles ADD CONSTRAINT geometry_valid_check CHECK (isvalid(the_geom));

/*
retour des données dans la dbeel
H:
cd base
pg_dump -U postgres -h 192.168.1.104 -f "belge.obstacles.sql" --table belge.obstacles --verbose eda2
psql -U postgres -h 1.100.1.6 -f "belge.obstacles.sql"  dbeel
*/
-- Script integration des obstacles dans dbeel

-- select * from obstacles
-- Il ya plusieurs lignes par sites correspondants aux différents aménagements. Mais les informations que l'on veut ne sont pas répétés sur toutes les lignes.
-- select site_num,obst_num,type_obst,role_obst, com_obst,revetement,hauteur, lame_eau,dif_niveau,import_bio 
-- from belge.obstacles where dif_niveau=0 -- Là où il y a le plus d'information c'est pour le numéro 0 de l'obstacle par site (obst_num)*

-- Récupération des symbolisation (pour la franchissabilité)
update belge.obstacles set symbolisat=sub.symbolisat
from (select symbolisat, site_num from belge.obstacles where obst_num=0 ) sub
where obstacles.site_num=sub.site_num; 
-- Récupération des echelles à poissons:
select site_num, obst_num, echelle from belge.obstacles where obst_num!=0 -- P/A d'echelle partout sauf pour obst_num=0
update belge.obstacles set echelle=sub.echelle
from (select echelle, site_num from belge.obstacles where obst_num!=0 ) sub
where obstacles.site_num=sub.site_num; 
-- select * from belge.obstacles

update belge.obstacles set dif_niveau= NULL where dif_niveau=0

-- Ajout d'une colonne diff niveau où on ajoute le niveau le plus bas par site, on le duplique pour toutes les lignes du site
alter table belge.obstacles add column dif_niveau_ouvrage numeric;
update belge.obstacles set dif_niveau_ouvrage =sub.min from
(select min(dif_niveau),site_num from belge.obstacles 
where dif_niveau>0
group by site_num) sub
where obstacles.site_num=sub.site_num --7737
-- select * from belge.obstacles order by site_num

-- Vérification qu'il y a bien des zéros partout
select * from belge.obstacles where obst_num=0 --3106
select site_num from belge.obstacles group by site_num order by site_num -- 3106

-- Création d'une table avec une ligne par site et les symbolisat, hauteurs (diff_niveau) et echelles associées
CREATE TABLE belge.obstacles_sites as
        select * from belge.obstacles where obst_num=0
-- select * from belge.obstacles_sites
ALTER TABLE belge.obstacles rename to obstacles_sites_detailles
ALTER TABLE belge.obstacles_sites rename to obstacles
-- select * from belge.obstacles -- 3016 lignes

set search_path to belge,public,dbeel;

-- il faut d'abord rentrer un lieu
DROP TABLE if exists belge.ouvragedbeel CASCADE;
CREATE TABLE belge.ouvragedbeel (
        obs_id integer,
        CONSTRAINT pk_obs_op_id PRIMARY KEY (op_id),
        CONSTRAINT c_uk_obs_id UNIQUE (obs_id),
        CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
                REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
                MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);
-- select * from belge.ouvragedbeel;

INSERT INTO belge.ouvragedbeel
        SELECT  uuid_generate_v4() AS op_id,
        'SPW' AS op_gis_systemname ,
        'OBSTACLES' AS op_gis_layername, 
        site_num AS op_gislocation,
        noma AS op_placename,
        11 AS op_no_observationplacetype, -- Obstacle location
        NULL AS  op_op_id,
        the_geom,
        obs_id -- on a rajouté qu'une seule colonne, seulement l'identifiant de l'ouvrage....
         FROM belge.obstacles  ; -- 3106 lines

select * from belge.ouvragedbeel

-- selection des colonnes qui nous interesses dans les donnees obstacles pour la dbeel
DROP TABLE if exists belge.obstaclescourt CASCADE;
CREATE TABLE belge.obstaclescourt as 
  select  site_num, obst_num, code_ori, sousbassin, basin_inf, categorie, noma, province, symbolisat, dat_m_jour, type_obst, revetement, longueur, larg_diam, 
  hauteur, prof_amont, prof_aval, lame_eau, dif_niveau_ouvrage, import_bio, echelle, obs_id, role_obst FROM belge.obstacles;


DROP TABLE if exists belge.physical_obstruction CASCADE;
CREATE TABLE belge.physical_obstruction(
  LIKE belge.obstaclescourt,
  CONSTRAINT physical_obstruction_id PRIMARY KEY (ob_id),
  CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id),
  CONSTRAINT fk_ob_origin FOREIGN KEY (ob_no_origin)REFERENCES dbeel_nomenclature.observation_origin (no_id) ,
  CONSTRAINT fk_ob_period FOREIGN KEY (ob_no_period) REFERENCES dbeel_nomenclature.period_type (no_id) ,
  CONSTRAINT fk_ob_type FOREIGN KEY (ob_no_type) REFERENCES dbeel_nomenclature.observation_type (no_id) ,
  CONSTRAINT fk_po_obstruction_passability FOREIGN KEY (po_no_obstruction_passability)REFERENCES dbeel_nomenclature.obstruction_impact (no_id) 
) INHERITS (dbeel.physical_obstruction);

-- select * from belge.physical_obstruction

INSERT INTO belge.physical_obstruction (ob_id,ob_no_origin,ob_no_type,ob_no_period,ob_starting_date, ob_ending_date,ob_op_id,ob_dp_id,ot_no_obstruction_type,
  ot_obstruction_number,ot_no_mortality_type, ot_no_mortality , po_no_obstruction_passability, po_obstruction_height, po_turbine_number, site_num, obst_num, code_ori, sousbassin, basin_inf, categorie, noma, province, symbolisat, dat_m_jour, type_obst, revetement, longueur, larg_diam, 
  hauteur, prof_amont, prof_aval, lame_eau, dif_niveau_ouvrage, import_bio, echelle, obs_id, role_obst
  )
  SELECT 
  uuid_generate_v4() as ob_id,
  11 AS ob_no_origin, -- raw data
  16 AS ob_no_type, -- obstruction
  74 AS ob_no_period, -- Unknown
  NULL AS ob_starting_date,
  NULL AS ob_ending_date,
  d.op_id as ob_op_id,
  7 AS ob_dp_id,
  219 as ot_no_obstruction_type,
  1 as ot_obstruction_number,
  NULL AS ot_no_mortality_type,
  NULL AS ot_no_mortality,
  case when o.symbolisat='AMENAGE' then 209 
  when o.symbolisat='CHANTOIR' then 209
  when o.symbolisat='EMBACLE' then 209
  when o.symbolisat='IMPORTANT' then 212
  when o.symbolisat='INDETERMINE' then 208
  when o.symbolisat='INFRANCHISSABLE' then 214
  when o.symbolisat='MAJEUR' then 213
  when o.symbolisat='MINEUR' then 210
  when o.symbolisat='NEANT' then 209
  when o.symbolisat='TERMINUS' then 208
  when o.symbolisat='N''EXISTE PLUS' then 208
  when o.symbolisat is null then 208
  end as po_no_obstruction_passability,
  o.dif_niveau_ouvrage as po_obstruction_height,
  NULL AS po_turbine_number,o.*
  FROM                  
  belge.obstaclescourt o JOIN  belge.ouvragedbeel d ON o.obs_id=d.obs_id;