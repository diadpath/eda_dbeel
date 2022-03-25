-- Chargement des noeuds mer qui sont en espagne mais n'ont pas été calculés pour la France
select wso_id from europe.wso where area='Spain'
except (select  wso_id  from europe.wso where area='France') --2339
-- chargement des noeuds de la Façade Atlantque
select wso_id from ccm21.seaoutlets where area_cd='A1'; --6361
-- intersection
(select wso_id from europe.wso where area='Spain'
except (select  wso_id  from europe.wso where area='France')) --2339
intersect (select wso_id from ccm21.seaoutlets where area_cd='A1'); --348
-- Une table pour les vues dans Qgis
create table ccm21.riversegments_spain as (
        select * from ccm21.riversegments where wso_id in ((select wso_id from europe.wso where area='Spain'
except (select  wso_id  from europe.wso where area='France')) --2339
intersect (select wso_id from ccm21.seaoutlets where area_cd='A1'))); --348);

-- insertion de nouveaux bassins
insert into europe.wso(wso_id) 
(select wso_id from europe.wso where area='Spain'
except (select  wso_id  from europe.wso where area='France')) 
intersect (select wso_id from ccm21.seaoutlets where area_cd='A1'); 
UPDATE europe.wso set area='Spain_Atl' where area IS NULL;

/* 
creation des tables des stations 
*/
-- Schema: "oria"

-- DROP SCHEMA oria;

--CREATE SCHEMA oria  AUTHORIZATION postgres;

drop table if exists oria.estaciones_st;
create table oria.estaciones_st (  
        st_id character varying(10),
        st_ecoregion character varying(10),
        st_river character varying(40),
        st_name text,
        st_x numeric,
        st_y numeric,
        st_z numeric,
        st_pk_des numeric,
        st_date date,
        st_21fpcomun_num integer,
        st_nha numeric);
alter table oria.estaciones_st add constraint  pk_st_id primary key (st_id);
set client_encoding to 'latin1';
copy oria.estaciones_st  from 'c:/base/estaciones.csv' with csv delimiter as ';' header; 

drop table if exists oria.operation_op;
create table oria.operation_op (
        op_date date,
        op_st_id character varying(10),
        op_id character varying(10) primary key,
        st_x numeric,
        st_y numeric,
        st_z numeric,
        st_pk_des numeric,
        op_surf numeric,
        op_methodest character varying(30),
        op_fishingobj character varying(30),
        op_nbpas integer,
        op_effort numeric,
        op_densite numeric,
        op_nbtot numeric,
        op_nbp1 numeric,
        op_nbp2 numeric,
        op_nbp3 numeric,
        op_nb150 numeric,
        op_nb150_300 numeric,
        op_nb300_450 numeric,
        op_nb_450_600 numeric,
        op_nb_600 numeric,
        op_glass_eel_transport boolean);
alter table oria.operation_op add constraint  fk_op_st_id foreign key (op_st_id) references oria.estaciones_st(st_id);
copy oria.operation_op  from 'c:/base/operation.csv' with csv delimiter as ';' header; 
alter table oria.operation_op drop column  st_x;
alter table oria.operation_op drop column         st_y ;
alter table oria.operation_op drop column         st_z ;
alter table oria.operation_op drop column         st_pk_des ;
-- projection sur le SRID 3035
SELECT AddGeometryColumn('oria', 'estaciones_st','the_geom', 3035,'POINT',2); 
UPDATE oria.estaciones_st   SET the_geom=ST_Transform(PointFromText('POINT(' || st_x || ' ' || st_y || ')',23030),3035);
ALTER TABLE oria.estaciones_st SET WITH OIDS;

CREATE INDEX indexestaciones_st ON oria.estaciones_st
  USING GIST ( the_geom GIST_GEOMETRY_OPS );

-- capture des stations de pêche
DROP TABLE IF EXISTS oria.oria_ccm_500;
CREATE TABLE oria.oria_ccm_500 as (
        SELECT distinct on (st_id ) st_id , gid, wso1_id, min(distance) as distance, the_geom FROM (
               SELECT st_id, gid , wso1_id, CAST(distance(r.the_geom, s.the_geom) as  decimal(15,1)) as distance,s.the_geom 
               FROM oria.estaciones_st As s
               INNER JOIN  ccm21.riversegments r ON ST_DWithin(r.the_geom, s.the_geom,500)
               WHERE s.the_geom IS NOT NULL
               ORDER BY st_id) AS sub 
        GROUP BY st_id, gid, wso1_id,  distance,the_geom
);
alter table oria.oria_ccm_500 add column id serial;
-- mise à jour de la table geometry_columns
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'oria', 'oria_ccm_500', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM oria.oria_ccm_500 LIMIT 1;

-- creation d'index, clé primaire, et constraintes qui vont bien
alter table oria.oria_ccm_500 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table oria.oria_ccm_500 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table oria.oria_ccm_500 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
alter table oria.oria_ccm_500 ADD CONSTRAINT pk_id PRIMARY KEY(id);
CREATE INDEX indexoria_ccm_500 ON oria.oria_ccm_500
  USING GIST ( the_geom GIST_GEOMETRY_OPS );

drop table if exists oria.operation_station;
create table oria.operation_station as (
	select * from oria.estaciones_st join oria.operation_op on op_st_id=st_id
	where st_id in (select st_id from oria.oria_ccm_500));
alter table oria.operation_station add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table oria.operation_station add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table oria.operation_station add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
/*
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'oria', 'operation_station', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM oria.oria_ccm_500 LIMIT 1;
*/
--------------------------------------------
---------------------------------------------
-- Corinne Landcover
---------------------------------------------
---------------------------------------------
--------------------------------------
--------------------------------------
--SURFACE CUT
--------------------------------------
--------------------------------------
DROP TABLE IF EXISTS clc.clipped_spain;
CREATE TABLE clc.clipped_spain AS
SELECT intersected.clcgid, intersected.gid, code_00,the_geom
FROM (SELECT clc.gid as clcgid, c.gid,code_00, ST_Multi(ST_Intersection(clc.the_geom, c.the_geom)) the_geom
        FROM  clc.clc00_v2_europe clc INNER JOIN 
        (select * from ccm21.catchments c WHERE c.wso_id IN (SELECT wso_id FROM europe.wso WHERE area='Spain_Atl')) as c
        ON  ST_Intersects (c.the_geom,clc.the_geom)
        
       -- AND substring(code_00 from 1 for 1)='1'
       )  AS intersected; --1h12 min
ALTER TABLE clc.clipped_spain ADD column id serial PRIMARY KEY;
alter table clc.clipped_spain add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table clc.clipped_spain add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL);
alter table clc.clipped_spain add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
CREATE INDEX indexclc00clipped_spain ON clc.clipped_spain
  USING GIST ( the_geom GIST_GEOMETRY_OPS ); 
--------------------------------------
--------------------------------------
--MERGING
--------------------------------------
--------------------------------------
DROP TABLE IF EXISTS clc.clipped_spain1;
CREATE TABLE clc.clipped_spain1 AS (
SELECT gid,code_00,
           ST_Multi(ST_Collect(f.the_geom)) as the_geom
         FROM (SELECT gid, code_00,(ST_Dump(the_geom)).geom As the_geom
                                FROM
                                 clc.clipped_spain
                                ) As f
GROUP BY gid,code_00); -- 5s
ALTER TABLE clc.clipped_spain1 add column id serial PRIMARY KEY;
alter table clc.clipped_spain1 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table clc.clipped_spain1 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL);
alter table clc.clipped_spain1 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
CREATE INDEX indexclc00clipped_spain1 ON clc.clipped_spain1
  USING GIST ( the_geom GIST_GEOMETRY_OPS );
ALTER TABLE clc.clipped_spain1 add constraint c_ck_uk  UNIQUE(gid,code_00); -- contrainte d'unicité
--------------------------------------
--------------------------------------
--AREA
--------------------------------------
--------------------------------------
ALTER TABLE clc.clipped_spain1 add column area numeric;
UPDATE clc.clipped_spain1 set area=ST_Area(the_geom); -- 9s
--------------------------------------
--------------------------------------
--AREA PER COLUMN FOR CLC TYPE (agregation)
--------------------------------------
--------------------------------------
SELECT gid,code_00, id,round(area) as area FROM clc.clipped_spain1 order by gid, code_00 limit 10;
DROP TABLE IF EXISTS clc.surf_area;
CREATE TABLE clc.surf_area AS (
SELECT DISTINCT ON (init.gid) init.gid,
        artificial_surfaces_11_13,
        artificial_vegetated_14,
         arable_land_21,
         permanent_crops_22,
         pastures_23,
         heterogeneous_agricultural_24,
         forest_31,
         natural_32_33,
         wetlands_4,
         inland_waterbodies_51 ,
         marine_water_52
        -- SELECT * 
         FROM (
        SELECT  gid from clc.clipped_spain1    ) as init        
        FULL OUTER JOIN (SELECT gid,sum(area) AS artificial_surfaces_11_13 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='11' 
                        OR  substring(code_00 from 1 for 2)='12'
                        OR substring(code_00 from 1 for 2)='13' 
                        GROUP BY gid) AS artificial_surfaces
                       on (init.gid) =(artificial_surfaces.gid)         
        FULL OUTER JOIN (SELECT gid,sum(area) AS artificial_vegetated_14 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='14'
                        GROUP BY gid) AS artificial_vegetated
                        on artificial_vegetated.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS arable_land_21 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='21'
                        GROUP BY gid) AS arable_land
                        on arable_land.gid =init.gid
        FULL OUTER JOIN (SELECT gid, sum(area) AS permanent_crops_22 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='22'
                        GROUP BY gid) AS permanent_crops
                        on permanent_crops.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS pastures_23 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='23'
                        GROUP BY gid) AS pastures
                        on pastures.gid =init.gid
        FULL OUTER JOIN (SELECT gid, sum(area) AS heterogeneous_agricultural_24 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='24'
                        GROUP BY gid) AS heterogeneous_agricultural
                        on heterogeneous_agricultural.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS forest_31 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='31'
                        GROUP BY gid) AS forest
                        ON forest.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS natural_32_33 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='32'
                        OR  substring(code_00 from 1 for 2)='33'
                        GROUP BY gid) AS nature
                        ON nature.gid =init.gid
        FULL OUTER JOIN (SELECT gid, sum(area) AS wetlands_4  FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 1)='4'
                        GROUP BY gid) AS wetlands
                        on wetlands.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS inland_waterbodies_51 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='51'
                        GROUP BY gid) AS waterbodies
                        on waterbodies.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS marine_water_52 FROM clc.clipped_spain1 WHERE 
                        substring(code_00 from 1 for 2)='52'
                        GROUP BY gid) AS marine_water
                        on marine_water.gid =init.gid); --375 ms
ALTER TABLE clc.surf_area ADD CONSTRAINT c_pk_gid_surf_area PRIMARY KEY (gid);
SELECT * FROM clc.surf_area;
--------------------------------------
--------------------------------------
--REMOVING ZEROS AND JOINING RIVERSEGMENTS AND CATCHMENTS TABLES
--------------------------------------
--------------------------------------
DROP TABLE IF EXISTS clc.surf_area1;
CREATE TABLE clc.surf_area1 AS( 
SELECT 
        r.gid,
        area/1e6 as catchment_area,
        CASE WHEN artificial_surfaces_11_13 IS NOT NULL THEN artificial_surfaces_11_13/1e6
        ELSE 0
        END AS artificial_surfaces_11_13,
        CASE WHEN artificial_vegetated_14 IS NOT NULL THEN artificial_vegetated_14/1e6 
        ELSE 0
        END AS artificial_vegetated_14,
        CASE WHEN arable_land_21 IS NOT NULL THEN arable_land_21/1e6 
        ELSE 0
        END AS arable_land_21,
        CASE WHEN permanent_crops_22 IS NOT NULL THEN permanent_crops_22/1e6 
        ELSE 0
        END AS permanent_crops_22,
        CASE WHEN pastures_23 IS NOT NULL THEN pastures_23/1e6 
        ELSE 0
        END AS pastures_23,
        CASE WHEN heterogeneous_agricultural_24 IS NOT NULL THEN heterogeneous_agricultural_24/1e6
        ELSE 0
        END AS heterogeneous_agricultural_24,
        CASE WHEN forest_31 IS NOT NULL THEN forest_31/1e6 
        ELSE 0
        END AS forest_31,
        CASE WHEN natural_32_33 IS NOT NULL THEN natural_32_33/1e6 
        ELSE 0
        END AS natural_32_33,
        CASE WHEN wetlands_4 IS NOT NULL THEN wetlands_4/1e6 
        ELSE 0
        END AS wetlands_4,
        CASE WHEN inland_waterbodies_51 IS NOT NULL THEN inland_waterbodies_51 /1e6 
        ELSE 0
        END AS inland_waterbodies_51,
        CASE WHEN  marine_water_52 IS NOT NULL THEN marine_water_52/1e6 
        ELSE 0
        END AS marine_water_52,
        c.wso1_id,
        c.the_geom      
FROM clc.surf_area p
JOIN ccm21.catchments c ON c.gid=p.gid
JOIN ccm21.riversegments r on r.wso1_id=c.wso1_id
);
--------------------------------------
--------------------------------------
--COMPARISON OF SURFACES FROM THE CCM AND CLC
--------------------------------------
--------------------------------------
DROP TABLE IF EXISTS clc.surf_area_analyse;
CREATE TABLE clc.surf_area_analyse AS( 
SELECT 
        gid,
        wso1_id,
        catchment_area,
        artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52 as sum_clc_area ,
        (artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52)/catchment_area AS pourc_clc,
         the_geom
         FROM clc.surf_area1);
ALTER TABLE clc.surf_area_analyse add CONSTRAINT c_pk_gid_area_analyse PRIMARY KEY (gid);
alter table clc.surf_area_analyse add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table clc.surf_area_analyse add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL);
alter table clc.surf_area_analyse add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
CREATE INDEX indexclc00area_analyse ON clc.surf_area_analyse
  USING GIST ( the_geom GIST_GEOMETRY_OPS );




SELECT rn.idsegment FROM dbeel_rivers.rn 
JOIN dbeel_rivers.rna AS ra ON rn.idsegment=ra.idsegment;



