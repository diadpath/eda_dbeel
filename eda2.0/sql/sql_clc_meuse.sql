select * from european_wise2008.rbd_f1v3 where name_engl like 'Meuse'


-- selection of the meuse basin
select * from european_wise2008.rbd_f1v3 where name_engl like 'Meuse'
-- 5 lines


select * from europe.wso limit 10;-- id, wso_id, area
-- I just need the two second columns, below a request spatial joining riversegments and the wise layer
select distinct on (wso_id)  wso_id, name_engl as area from ccm21.riversegments r
    join (SELECT the_geom, name_engl FROM european_wise2008.rbd_f1v3 As f where name_engl like 'Meuse' ) as sub
    ON ST_Intersects(sub.the_geom,r.the_geom) limit 10;

    

select * from ccm21.riversegments where wso1_id in 
(291110,
291112,
291115,
291130,
291133,
292843,
292848,
298657,
324473,
324479)
--324473
--324479
--291130 --Meuse
select *  from ccm21.riversegments where wso_id in 
(291110,--rhin
291112,-- Rhone
291115,-- Seine
291130,-- Meuse
291133,--Scheldt
292843,-- Meuse du bas
292848,-- micro pipi près de l'esuaire
298657)-- petit pipi près de l'esuaire


-- i'll insert this in europe.wso

insert into europe.wso(wso_id,area) VALUES (291130,'Meuse');-- Meuse
insert into europe.wso(wso_id,area) VALUES (292848,'Meuse');-- micro pipi près de l'esuaire
insert into europe.wso(wso_id,area) VALUES  (298657,'Meuse');-- petit pipi près de l'esuaire
insert into europe.wso(wso_id,area) VALUES  (292843,'Meuse');--- Meuse du bas


drop table if exists clc.meusebelge;
create table clc.meusebelge as (
	select distinct on (gid) cl.* from clc.clc00_v2_europe cl
	join
	(select the_geom from ccm21.catchments c join europe.wso e on e.wso_id=c.wso_id where e.area='Meuse' 
	except
	select the_geom from ccm21.catchments c join europe.wso1 e on e.wso1_id=c.wso1_id where e.area='France') as ccm
	on st_intersects(cl.the_geom,ccm.the_geom)
	
);
 alter table clc.meusebelge ADD CONSTRAINT meusebelge_pkey PRIMARY KEY (gid);
  alter table clc.meusebelge ADD  CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
  alter table clc.meusebelge ADD  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL);
  alter table clc.meusebelge ADD  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
  
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'clc', 'meusebelge', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM clc.meusebelge  LIMIT 1;

--CLIP 1
--------------------------------------------
---------------------------------------------
-- Corinne Landcover
---------------------------------------------
---------------------------------------------

--------
--SURFACE CUT

--------------------------------------
--------------------------------------
-- Below i'm using a BEGIN COMMIT statement so that if the program drops at some point it will not loose everything
BEGIN;
DROP TABLE IF EXISTS clc.clipped;
CREATE TABLE clc.clipped AS
SELECT intersected.clcgid, intersected.gid, code_00,the_geom
FROM (SELECT clc.gid as clcgid,code_00, ST_Multi(ST_Intersection(clc.the_geom, sub1.the_geom)) the_geom
        FROM  clc.clc00_v2_europe clc 
        INNER JOIN (
                SELECT gid, wso1_id,c.the_geom FROM ccm21.catchments c WHERE c.wso_id IN (SELECT wso_id FROM europe.wso WHERE area='Meuse')                         
        )AS sub1
        ON  ST_Intersects (sub1.the_geom,clc.the_geom)
       )  AS intersected;     
COMMIT;

select count(*) from clc.clipped; --40552

BEGIN;

ALTER TABLE clc.clipped ADD column id serial PRIMARY KEY;
alter table clc.clipped add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table clc.clipped add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL);
alter table clc.clipped add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);

CREATE INDEX indexclc00clipped ON clc.clipped
  USING GIST ( the_geom GIST_GEOMETRY_OPS ); 
COMMIT;

CREATE INDEX indexclipped
  ON clc.clipped
  USING btree
  (gid);





--------------------------------------
--------------------------------------
--MERGING
--------------------------------------
--------------------------------------
-- at this stage I would like to see the result in Qgis, are there holes ?
-- from now on I'm using the name "meuse" to indicate that everything is Ok
DROP TABLE IF EXISTS clc.clipped_meuse1;
CREATE TABLE clc.clipped_meuse1 AS (
SELECT gid,code_00,
           ST_Multi(ST_Collect(f.the_geom)) as the_geom
         FROM (SELECT gid, code_00,wso1_id,(ST_Dump(the_geom)).geom As the_geom
                                FROM
                                 clc.clipped
                                ) As f 
GROUP BY gid,code_00);--done - 7th march EdeE. looks ok - desnt seem to be any holes



ALTER TABLE clc.clipped_meuse1 add column id serial PRIMARY KEY;
alter table clc.clipped_meuse1 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table clc.clipped_meuse1 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL);
alter table clc.clipped_meuse1 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
CREATE INDEX indexclc00clipped_meuse1 ON clc.clipped_meuse1
  USING GIST ( the_geom GIST_GEOMETRY_OPS );
ALTER TABLE clc.clipped_meuse1 add constraint c_ck_uk_meuse  UNIQUE(gid,code_00); -- contrainte d'unicité

INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'clc', 'clipped_meuse1', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM clc.clipped_meuse1  LIMIT 1;


-- il faut virer la France

delete from clc.clipped_meuse1 where gid in (select gid from ccm21.catchments where wso1_id in (select wso1_id from europe.wso1 where area='France'));--5124
--------------------------------------
--------------------------------------
--AREA
--------------------------------------
--------------------------------------

ALTER TABLE clc.clipped_meuse1 add column area numeric;
UPDATE clc.clipped_meuse1 set area=ST_Area(the_geom); 

--------------------------------------
--AREA PER COLUMN FOR CLC TYPE (agregation)
--------------------------------------
--------------------------------------
SELECT gid,code_00, round(area) as area FROM clc.clipped_meuse1 order by gid, code_00 limit 10;
DROP TABLE IF EXISTS clc.surf_area_meuse;

CREATE TABLE clc.surf_area_meuse AS (
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
        SELECT  gid from clc.clipped_meuse1    ) as init        
        FULL OUTER JOIN (SELECT gid,sum(area) AS artificial_surfaces_11_13 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='11' 
                        OR  substring(code_00 from 1 for 2)='12'
                        OR substring(code_00 from 1 for 2)='13' 
                        GROUP BY gid) AS artificial_surfaces
                       on (init.gid) =(artificial_surfaces.gid)         
        FULL OUTER JOIN (SELECT gid,sum(area) AS artificial_vegetated_14 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='14'
                        GROUP BY gid) AS artificial_vegetated
                        on artificial_vegetated.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS arable_land_21 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='21'
                        GROUP BY gid) AS arable_land
                        on arable_land.gid =init.gid
        FULL OUTER JOIN (SELECT gid, sum(area) AS permanent_crops_22 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='22'
                        GROUP BY gid) AS permanent_crops
                        on permanent_crops.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS pastures_23 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='23'
                        GROUP BY gid) AS pastures
                        on pastures.gid =init.gid
        FULL OUTER JOIN (SELECT gid, sum(area) AS heterogeneous_agricultural_24 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='24'
                        GROUP BY gid) AS heterogeneous_agricultural
                        on heterogeneous_agricultural.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS forest_31 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='31'
                        GROUP BY gid) AS forest
                        ON forest.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS natural_32_33 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='32'
                        OR  substring(code_00 from 1 for 2)='33'
                        GROUP BY gid) AS nature
                        ON nature.gid =init.gid
        FULL OUTER JOIN (SELECT gid, sum(area) AS wetlands_4  FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 1)='4'
                        GROUP BY gid) AS wetlands
                        on wetlands.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS inland_waterbodies_51 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='51'
                        GROUP BY gid) AS waterbodies
                        on waterbodies.gid =init.gid
        FULL OUTER JOIN (SELECT gid,sum(area) AS marine_water_52 FROM clc.clipped_meuse1 WHERE 
                        substring(code_00 from 1 for 2)='52'
                        GROUP BY gid) AS marine_water
                        on marine_water.gid =init.gid); 

ALTER TABLE clc.surf_area_meuse ADD CONSTRAINT c_pk_gid_surf_area_meuse PRIMARY KEY (gid);
SELECT * FROM clc.surf_area_meuse;
--------------------------------------
--------------------------------------
--REMOVING ZEROS AND JOINING RIVERSEGMENTS AND CATCHMENTS TABLES
--------------------------------------
--------------------------------------
-- this table drops the previous one but final calculations are stored in surf_area_final

DROP TABLE IF EXISTS clc.surf_area_meuse_final;
CREATE TABLE clc.surf_area_meuse_final AS( 
SELECT 
        c.gid,
        C.area/1e6 as catchment_area,
        CASE WHEN p.artificial_surfaces_11_13 IS NOT NULL THEN p.artificial_surfaces_11_13/1e6
        ELSE 0
        END AS artificial_surfaces_11_13,
        CASE WHEN p.artificial_vegetated_14 IS NOT NULL THEN p.artificial_vegetated_14/1e6 
        ELSE 0
        END AS artificial_vegetated_14,
        CASE WHEN p.arable_land_21 IS NOT NULL THEN p.arable_land_21/1e6 
        ELSE 0
        END AS arable_land_21,
        CASE WHEN p.permanent_crops_22 IS NOT NULL THEN p.permanent_crops_22/1e6 
        ELSE 0
        END AS permanent_crops_22,
        CASE WHEN p.pastures_23 IS NOT NULL THEN p.pastures_23/1e6 
        ELSE 0
        END AS pastures_23,
        CASE WHEN p.heterogeneous_agricultural_24 IS NOT NULL THEN p.heterogeneous_agricultural_24/1e6
        ELSE 0
        END AS heterogeneous_agricultural_24,
        CASE WHEN p.forest_31 IS NOT NULL THEN p.forest_31/1e6 
        ELSE 0
        END AS forest_31,
        CASE WHEN p.natural_32_33 IS NOT NULL THEN p.natural_32_33/1e6 
        ELSE 0
        END AS natural_32_33,
        CASE WHEN p.wetlands_4 IS NOT NULL THEN p.wetlands_4/1e6 
        ELSE 0
        END AS wetlands_4,
        CASE WHEN p.inland_waterbodies_51 IS NOT NULL THEN p.inland_waterbodies_51 /1e6 
        ELSE 0
        END AS inland_waterbodies_51,
        CASE WHEN  p.marine_water_52 IS NOT NULL THEN p.marine_water_52/1e6 
        ELSE 0
        END AS marine_water_52,
        c.wso1_id,
        c.the_geom      
FROM clc.surf_area_meuse p
JOIN ccm21.catchments c ON c.gid=p.gid
JOIN ccm21.riversegments r on r.wso1_id=c.wso1_id
);
-- recopie les données depuis la France (données manquantes)

select count(*) from clc.surf_area_final where wso1_id in (select wso1_id from europe.wso1 where area='Meuse');--2975
select count(*) from europe.wso1 where area='Meuse';--3022
select count(*) from clc.surf_area_meuse;--2011

insert into clc.surf_area_meuse_final 
select * from clc.surf_area_final where wso1_id in (
select wso1_id from  clc.surf_area_final where wso1_id in (select wso1_id from europe.wso1 where area='Meuse')
and wso1_id not in (select wso1_id from clc.surf_area_meuse_final));--1011


--this bit of code sums up all the clc areas and comapres them to the ccm surface areas
DROP TABLE IF EXISTS clc.surf_area_analyse;
CREATE TABLE clc.surf_area_analyse AS( 
SELECT 
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
         FROM clc.surf_area_meuse_final);



--this bit of code divides each categrpry by the sum of all clc categories to get percent land cover. does the clc categorgy wetlands mean bog? i think so

DROP TABLE IF EXISTS clc.percent;
CREATE TABLE clc.percent AS( 
SELECT 
        wso1_id,
        catchment_area,

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
         marine_water_52) AS sum_of_CLC_areas,
        
     artificial_surfaces_11_13/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_artifical_surfaces,
         
     artificial_vegetated_14/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_artificial_vegetated,
         
     arable_land_21/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_arable_land,
         
     permanent_crops_22/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_permanent_crops,

         pastures_23/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_pastures,

         heterogeneous_agricultural_24/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_heterogeneous_agricultural,

         forest_31/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_forest,

         natural_32_33/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_natural,

         wetlands_4/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_wetlands,

         inland_waterbodies_51/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_inland_waterbodies,

         marine_water_52/(artificial_surfaces_11_13+
         artificial_vegetated_14+
         arable_land_21+
         permanent_crops_22+
         pastures_23+
         heterogeneous_agricultural_24+
         forest_31+
         natural_32_33+
         wetlands_4+
         inland_waterbodies_51 +
         marine_water_52) AS pourc_marine_water,
         
         the_geom
         FROM clc.surf_area_meuse_final);

