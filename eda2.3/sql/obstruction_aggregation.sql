-------------------------------------------------------------------------------------------
-- OBSTACLES database
--	1. IDs foe each table (in some cases it has been done in GT2_obstacles.R script)
--	2. REPROJECTION:
--		WE HAVE DECIDED TO USE JUST ONE PROJECTION 3035
-- 		BEWARE MARIA YOU HAVE FIRST TO UPDATE THE PROJECTION
--	3. JOINING catalonia_obstruction_hpp and catalonia_obstruction_dam
--	4. CORRECT coordinates of spain_obstruction table
--------------------------------------------------------------------------------------------

/*-----------------------------------------------------------------------------------------------------
dump de WISE pour mettre dans dbeel pour Laurent (pour identifier extension géographique de l'espagne)

pg_dump -U postgres -f "wise_rbd_f1v3.sql" --table spain.wise_rbd_f1v3 eda2.0
psql -U postgres -c "create schema spain" dbeel
psql -U postgres -f "wise_rbd_f1v3.sql" dbeel
-----------------------------------------------------------------------------------------------------*/

-- RUN one only Correction of wrong projections
SELECT UpdateGeometrySRID('sudoang','catalonia_obstruction','geom', 25831);
SELECT UpdateGeometrySRID('sudoang','spain_obstruction_hpp','geom', 4326);
SELECT UpdateGeometrySRID('sudoang','minho_obstruction','geom', 25829);
SELECT UpdateGeometrySRID('sudoang','catalonia_obstruction_dams','geom', 25831);

-- CORRECT
update portugal.rn set isfrontier = FALSE where idsegment in (select idsegment from portugal.rn_rna 
 where basin='Guadiana' and nextdownidsegment like '%PT%' and isfrontier=TRUE);--45
 
-- CREATE SEQUENCE of unique names in tables
set search_path to sudoang, public;

create temporary sequence seq;
alter sequence seq restart with 1;

--select 'SO_'||nextval('seq') 


---------------------------------------------------
-- 1. CREATION OF UNIQUE ID IN EACH OF THE TABLES
---------------------------------------------------

/*-------------------
spain_obstruction SO
---------------------*/
alter table spain_obstruction add column id character varying(10);
update spain_obstruction set id = 'SO_'||nextval('seq');  --3642 rows
-- select * from spain_obstruction order by id limit 10
alter table spain_obstruction add constraint c_uk_id unique (id);

/*---------------
amber AFR ou ASP
-----------------*/
-- select * from amber limit 10
-- select distinct dbname_ from amber
alter sequence seq restart with 1;
alter table amber add column id character varying(10);
update amber set id = 'A'||
case when dbname_ like '%FRANCE%' THEN 'FR_'
when dbname_ like '%SPAIN%' THEN 'SP_'
END ||nextval('seq');  --261364 rows
alter table amber add constraint c_amb_uk_id unique (id);

/*--------
AMBER APT
----------*/
-- select * from amber_portugal limit 10

alter sequence seq restart with 1;
alter table amber_portugal add column id character varying(10);
update amber_portugal set id = 'APT_'||nextval('seq');  -- 658 rows
alter table amber_portugal add constraint c_apt_uk_id unique (id);

/*-----------------------------------------------------
catalonia_obstruction CO  THIS IS THE DEPRECATED TABLE
-------------------------------------------------------*/
-- select * from catalonia_obstruction limit 10
alter sequence seq restart with 1;
alter table catalonia_obstruction add column id character varying(10);
update catalonia_obstruction set id = 'CO_'||nextval('seq');  --3642 rows
alter table catalonia_obstruction add constraint c_co_uk_id unique (id);

alter table sudoang.catalonia_obstruction rename to catalonia_obstruction_deprecated;

/*-----------------------------
catalonia_obstruction_dams COD
-------------------------------*/
-- select * from catalonia_obstruction_dams limit 10
alter sequence seq restart with 1;
alter table catalonia_obstruction_dams add column id character varying(10);
update catalonia_obstruction_dams set id = 'COD_'||nextval('seq');  --984 rows
alter table catalonia_obstruction_dams add constraint c_cod_uk_id unique (id);

/*----------------------------
catalonia_obstruction_hpp COH
-----------------------------*/
-- select * from catalonia_obstruction_hpp limit 10
alter sequence seq restart with 1;
alter table catalonia_obstruction_hpp add column id character varying(10);

update sudoang.catalonia_obstruction_hpp set id = 'COH_'||nextval('seq') where hpp_name is not null;  -- 448 rows

with hpp_ok as (
	select * from sudoang.catalonia_obstruction_hpp where hpp_name is not null
	)
update sudoang.catalonia_obstruction_hpp set id = hpp_ok.id from hpp_ok where catalonia_obstruction_hpp.hpp_id = hpp_ok.hpp_id;

select * from sudoang.catalonia_obstruction_hpp order by id;
-- The id of catalonia_obstruction_hpp is repeated because in the same table there are the turbines. We can't create constraint for this id
--alter table catalonia_obstruction_hpp add constraint c_coh_uk_id unique (id);

select * from catalonia_obstruction_hpp h  join 
catalonia_obstruction_dams d on d.obs_id=h.obs_id limit 10; -- 444 rows

/*--------------------
galicia_obstruction GO
----------------------*/
-- select * from sudoang.galicia_obstruction limit 10

alter sequence seq restart with 1;
alter table galicia_obstruction add column id character varying(10);
update galicia_obstruction set id = 'GO_'||nextval('seq');  --3468 rows
alter table galicia_obstruction add constraint c_go_uk_id unique (id);

/*--------------------
minho_obstruction MIO
----------------------*/
-- select * from sudoang.minho_obstruction limit 10
alter sequence seq restart with 1;
alter table minho_obstruction add column id character varying(10);
update minho_obstruction set id = 'MIO_'||nextval('seq');  --3642 rows
alter table minho_obstruction add constraint c_mio_uk_id unique (id);

/*--------------------
minho_obstruction_bis MIO
----------------------*/
-- select * from sudoang.minho_obstruction_bis
alter sequence seq restart with 39;
alter table sudoang.minho_obstruction_bis rename column id TO id_original;
alter table sudoang.minho_obstruction_bis add column id character varying(10);
update sudoang.minho_obstruction_bis set id = 'MIO_'||nextval('seq');  -- 297 rows
alter table sudoang.minho_obstruction_bis add constraint c_mio_bis_uk_id unique (id);

/*---------------------
CHCantabr_ObsTrans COC
-----------------------*/
-- select * from sudoang.chcoc_obstruction limit 10

alter sequence seq restart with 1;
alter table chcoc_obstruction add column id character varying(10); -- the column id is already created
update chcoc_obstruction set id = 'COC_'||nextval('seq');  --1980 rows
alter table chcoc_obstruction add constraint c_coc_uk_id unique (id);

/*------------------
CHEbro_ObsTrans CEB
--------------------*/
-- select * from sudoang.chebro_obstruction limit 10

alter sequence seq restart with 1;
alter table chebro_obstruction add column id character varying(10); -- the column id is already created
update chebro_obstruction set id = 'CEB_'||nextval('seq');
alter table chebro_obstruction add constraint c_ceb_uk_id unique (id);

/*----------------------
CHGuadiana_ObsTrans CGU
------------------------*/
-- select * from sudoang.chguad_obstruction limit 10

alter sequence seq restart with 1;
alter table chguad_obstruction add column id character varying(10); -- the column id is already created
update chguad_obstruction set id = 'CGU_'||nextval('seq');
alter table chguad_obstruction add constraint c_cgu_uk_id unique (id);

/*--------------------
CHSegura_ObsTrans CSE
----------------------*/
-- select * from sudoang.chseg_obstruction limit 10

alter sequence seq restart with 1;
alter table chseg_obstruction add column id character varying(10); -- the column id is already created
update chseg_obstruction set id = 'CSE_'||nextval('seq');  --779 rows
alter table chseg_obstruction add constraint c_cse_uk_id unique (id);

/*-------------------
CHMinho_ObsTrans CSE
---------------------*/
-- select * from sudoang.chmin_obstruction limit 10

alter sequence seq restart with 1;
alter table chmin_obstruction add column id character varying(10); -- the column id is already created
update chmin_obstruction set id = 'CMI_'||nextval('seq');  --3067 rows
alter table chmin_obstruction add constraint c_cmi_uk_id unique (id);

/*-----------------------------
andalucia_obstruction_dams AOD
------------------------------*/
-- select * from andalucia_obstruction_dams limit 10;
-- ALTER TABLE andalucia_obstruction_dams RENAME COLUMN "ï»¿obs_id" TO obs_id;
alter sequence seq restart with 1;
alter table andalucia_obstruction_dams add column id character varying(10);
update andalucia_obstruction_dams set id = 'AOD_'||nextval('seq');  -- 186 rows
alter table andalucia_obstruction_dams add constraint c_aod_uk_id unique (id);

/*----------------------------
andalucia_obstruction_hpp AOH
-----------------------------*/
-- select * from andalucia_obstruction_hpp limit 10;
-- ALTER TABLE andalucia_obstruction_dams RENAME COLUMN "ï»¿obs_id" TO dam_id;
alter sequence seq restart with 1;
alter table andalucia_obstruction_hpp add column id character varying(10);
update andalucia_obstruction_hpp set id = 'AOH_'||nextval('seq');  -- 71 rows
alter table andalucia_obstruction_hpp add constraint c_aoh_uk_id unique (id);

select * from andalucia_obstruction_hpp h  join 
andalucia_obstruction_dams d on d.obs_id=h.dam_id; -- 71 rows

/*-------------------------
bc_obstruction_dams BCD
--------------------------*/
-- select * from bc_obstruction_dams limit 10;
-- ALTER TABLE bc_obstruction_dams RENAME COLUMN "id" TO obs_id;
alter sequence seq restart with 1;
alter table bc_obstruction_dams add column id character varying(10);
update bc_obstruction_dams set id = 'BCD_'||nextval('seq');  -- 2126 rows
alter table bc_obstruction_dams add constraint c_bcd_uk_id unique (id);

/*------------------
fcul_obstruction FC
--------------------*/
-- select * from fcul_obstruction limit 10

alter sequence seq restart with 1;
alter table fcul_obstruction add column id character varying(10);
update fcul_obstruction set id = 'FC_'||nextval('seq');  --70 rows
alter table fcul_obstruction add constraint c_fcu_uk_id unique (id);


----------------------------
-- 2. REPROJECTION
----------------------------

ALTER TABLE sudoang.spain_obstruction_hpp
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);
  
ALTER TABLE sudoang.amber
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);
  
ALTER TABLE sudoang.amber_portugal
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);
  
ALTER TABLE sudoang.catalonia_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);
  
ALTER TABLE sudoang.catalonia_obstruction_dams
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.galicia_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035); --02:36

ALTER TABLE sudoang.minho_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.minho_obstruction_bis
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.chcoc_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.chebro_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.chguad_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.chseg_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.chmin_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.bc_obstruction_dams
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);
   
ALTER TABLE sudoang.fcul_obstruction_dams
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);

ALTER TABLE sudoang.fcul_obstruction_dams_shiny
  ALTER COLUMN geom 
  TYPE Geometry(Point, 3035) 
  USING ST_Transform(geom, 3035);

ALTER TABLE sudoang.andalucia_obstruction_dams_shiny
  ALTER COLUMN geom 
  TYPE Geometry(Point, 3035) 
  USING ST_Transform(geom, 3035);

/* This table was deleted because the information was missing (height of dams)
ALTER TABLE sudoang.fcul_obstruction
 ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035);
*/


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. JOINING catalonia_obstruction_hpp and catalonia_obstruction_dam
--	pas évident, la colonne de jointure est dans la table mère au lieu de la table fille, avec le nom de tous les filles séparé par des , ou des ;
--------------------------------------------------------------------------------------------------------------------------------------------------------

--column powerplant_id correspond to column dam_id dans catalonia_obstruction_hpp 
-- the problem is that values are semicolumn separated

-- select * from sudoang.catalonia_obstruction_hpp limit 10
/*
dam_id;dam_name;main-grid or production;dam_presence_bypass;dam_total_flow_bypass;dam_orient_flow;dam_presence_of_bar_rack;turb_rack_bar_space;dam_surface_bar_rack;dam_inclination_bar_rack;dam_presence_bypass_trashrack;dam_nb_trashrack_bypass;bypass_water_depth;bypass_width;bypass_position;dam_turb_max_flow;dam_reserved_flow;dam_flow_trashrack;dam_max_power;dam_nb_turbines;turb_type;typt_id;turb_in_service;turb_max_power (kw);turb_min_working_flow;turb_dam_height;turb_diameter;turb_rotation_speed;turb_nb_blades;turb_max_turbine_flow;turb_description;id
CHS1147;ColÃ²nia Pernau;2;t;;;;;;;;;;;;2,000;;;188;2;Francis;4;TRUE;;840;12,00;;;;;;COH_115
CHS1001;Puig i Font;2;t;;;;;;;;;;;;13,200;;;977;1;Francis open chumber turbine ;4;TRUE;no data;396;9,43;;;;;;COH_1
CHS1001;Puig i Font;2;t;;;;;;;;;;;;13,200;;;977;1;Kaplan ;6;TRUE;no data;396;9,43;;;;;;COH_2
*/
--select * from catalonia_obstruction_hpp where dam_id='CHS1613'
-- select powerplant_id from catalonia_obstruction_dams limit 10
-- select * from catalonia_obstruction_dams limit 10
/*
obs_id;obs_type;obs_name;powerplant_id;X;Y;SRID;obs_height(m);In service;obs_downs_pb;obs_downs_water_depth;obs_presence_eel_pass;obs_impact;obs_method_perm_ev;geom;id
RES139;Weir;Resclosa Fontsanta;;440866;4657123;4326;;Si;no data;;f;no data;;0101000020DB0B00009DE6216153164C41148B73D389524041;COD_185
RES314;Weir;Can Boix-7;;463487;4635031;4326;1;No;TRUE;;f;TRUE;;0101000020DB0B0000F828FF0DBD3E4C41EC0D5C1282234041;COD_359
RES364;EA;EA A0035 MontornÃ©s;;437289;4599663;4326;;Si;FALSE;;f;FALSE;;0101000020DB0B000018E956A9AD054C41E08838045EC73F41;COD_409
RES499;Weir;Resclosa CH Cabrianes;CHS1017;408833.215;4629759.09;4326;;Si;TRUE;;f;TRUE;;0101000020DB0B0000C275A64139D34B416F13106657234041;COD_541
RES833;Weir;resclosa;;345142;4701267;4326;;no data;no data;;f;no data;;0101000020DB0B0000EA44663C30634B4116D8FDCF07BA4041;COD_884
*/
update catalonia_obstruction_dams set powerplant_id= replace(replace(powerplant_id,
			',',';'), -- some data are separated with ',' some with ';'
			' ','');  -- remove spaces --984 rows

-- there is one empty line, remove it.... 
delete from catalonia_obstruction_dams where obs_id is null; --1

begin;
DROP TABLE IF EXISTS catalonia_obstruction_join_dams_hpp;
create table catalonia_obstruction_join_dams_hpp as (
select  id, regexp_split_to_table(powerplant_id,';') as powerplant_id from catalonia_obstruction_dams order by id);--365
commit;
/*
select * from catalonia_obstruction_join_dams_hpp
id;powerplant_id
COD_102;CHS1613
COD_103;CHS2004
COD_106;CHS1428
COD_108;CHS1614
COD_109;CHS1616
*/

-- ADDING A FOREIGN KEY TO THE NEW JOINING TABLE
-- The id of catalonia_obstruction_hpp is repeated because in the same table there are the turbines. We can't create constraint for this id
 --ALTER TABLE catalonia_obstruction_hpp add CONSTRAINT c_fk_id FOREIGN KEY (id) 
 --REFERENCES catalonia_obstruction_dams(id) ON DELETE CASCADE ON UPDATE CASCADE ;

-- il y a pas mal de duplicats
-- dam_id relie vers l'identifiant du barrage hydroélectrique. Mais dans catalonia_obstruction_dams on point vers plusieurs lignes de barrages hydroélectriques aussi.
-- Je pourrais faire une table des ouvrages hydroélectriques mais je vais essayer de joindre directement vers le dam_id
with howmanyduplicates as (
SELECT count(*),hpp_id from sudoang.catalonia_obstruction_hpp group by hpp_id
)
select * from howmanyduplicates 
order by count desc;

alter table catalonia_obstruction_hpp add column obs_id text;
update catalonia_obstruction_hpp set obs_id = sub.obs_id from
(select jj.id as did, h.id,d.obs_id  from catalonia_obstruction_hpp h 
join catalonia_obstruction_join_dams_hpp jj on jj.powerplant_id=h.hpp_id
join catalonia_obstruction_dams d on jj.id=d.id)sub
where catalonia_obstruction_hpp.id=sub.id; -- 444

/*
select * from catalonia_obstruction_dams limit 10
select *  from catalonia_obstruction_hpp limit 10
select * from catalonia_obstruction_hpp where dam_id='CHS1002'
dam_id;dam_name;main-grid or production;dam_presence_bypass;dam_total_flow_bypass;dam_orient_flow;dam_presence_of_bar_rack;turb_rack_bar_space;dam_surface_bar_rack;dam_inclination_bar_rack;dam_presence_bypass_trashrack;dam_nb_trashrack_bypass;bypass_water_depth;bypass_width;bypass_position;dam_turb_max_flow;dam_reserved_flow;dam_flow_trashrack;dam_max_power;dam_nb_turbines;turb_type;typt_id;turb_in_service;turb_max_power (kw);turb_min_working_flow;turb_dam_height;turb_diameter;turb_rotation_speed;turb_nb_blades;turb_max_turbine_flow;turb_description;id;obs_id
CHS1018;MolÃ­ GÃ¼ell, La Collada, Can Costa, CH Gossol;2;t;;;;;;;;;;;;1,200;;;;1;Francis;4;FALSE;600;no data;no  data;;;;;;COH_23;RES554
CHS1018;MolÃ­ GÃ¼ell - 2ona captaciÃ³, font de la Barraques, font d'espuÃ±a, torrent de Monistrol;2;t;;;;;;;;;;;;1,200;;;1.063;1;Francis;4;FALSE;600;140;118,47;;;;;;COH_24;RES554
CHS1019;Els Torrents, Els Casals;2;t;;;;;;;;;;;;4,000;;;188;1;Francis;4;TRUE;no data;1400;6,00;;;;;;COH_25;RES620
*/

-- SELECT * from catalonia_obstruction_dams where  powerplant_id like '%CHS1456%'
-- ALTER TABLE catalonia_obstruction_join_dams_hpp add CONSTRAINT c_pk_powerplant_id primary key (powerplant_id); --marche pas


-----------------------------------------------------------------------------------------
-- 4. CORRECT coordinates of spain_obstruction
--	spain_obstruction failed: latitude or longitude exceeded limits
-- 	LAURENT LAUNCH LINES 15-22 so that the id is created from the mother table !!!!
-- 	then re_launch the following lines
-----------------------------------------------------------------------------------------

-- Separate table in two good/wrong_coordinate
DROP TABLE IF EXISTS sudoang.spain_obstruction_in_spain;
CREATE TABLE sudoang.spain_obstruction_in_spain AS
(WITH spain AS
(
	SELECT st_union(the_geom) AS the_geom FROM spain.wise_rbd_f1v3
)
SELECT spain_obstruction.* FROM spain, sudoang.spain_obstruction
WHERE ST_Contains(the_geom, geom));--3120

DROP TABLE IF EXISTS sudoang.spain_obstruction_not_in_spain;
CREATE TABLE sudoang.spain_obstruction_not_in_spain AS
(WITH spain AS
(
	SELECT st_union(the_geom) AS the_geom FROM spain.wise_rbd_f1v3
)
SELECT spain_obstruction.* FROM spain, sudoang.spain_obstruction
WHERE NOT(ST_Contains(the_geom, geom)));--522

ALTER TABLE sudoang.spain_obstruction_in_spain
ALTER COLUMN geom TYPE geometry(Point,3035) 
  USING ST_Transform(geom,3035); 