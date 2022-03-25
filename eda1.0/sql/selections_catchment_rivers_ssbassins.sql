-- Fabrication d'une couche lesse:
CREATE TABLE belge.sous_bassin as
select wso4_id, wso1_id from ccm21.catchments 
where ws01_id in (select wso1_id from europe.wso)

-- travail à la main sur les données

select distinct on (wso4_id) * from belge.sous_bassin
alter table belge.catchment_meuse add column ss_bassin character varying(50);

update belge.catchment_meuse set ss_bassin=b.ss_bassin from
(select distinct on (wso4_id) * from belge.sous_bassin)b
where b.wso4_id=catchment_meuse.wso4_id;--5997
-------------------------------------------------------
-- zones correspond à sous sous bassin pour la lesse
-------------------------------------------------------

-- Table couches segments (rempie à la main)
CREATE TABLE belge.riversegment_lesse as (
select * from ccm21.riversegments where wso1_id in 
(select wso1_id from belge.catchment_lesse)
)


INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'belge', 'riversegment_lesse', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM belge.riversegment_lesse LIMIT 1;


ALTER TABLE belge.riversegment_lesse ADD COLUMN ss_bassins character varying (50);
UPDATE belge.riversegment_lesse SET ss_bassins = 'Bassin Lomme' where wso1_id in (select wso1_id from belge.catchment_lesse where wso4_id = '291613')
UPDATE belge.riversegment_lesse SET ss_bassins = 'Aval confluence Lomme' where wso1_id in (select wso1_id from belge.catchment_lesse where wso4_id = '291605');
UPDATE belge.riversegment_lesse SET ss_bassins = 'Amont confluence Lomme' where wso1_id in (select wso1_id from belge.catchment_lesse where wso4_id = '291618');


alter table belge.catchment_meuse add column zones character varying(50);
update belge.catchment_meuse set zones=b.ss_bassins from
(select * from belge.riversegment_lesse)b
where b.wso1_id=catchment_meuse.wso1_id;--366


-- explotation des données
select * from belge.sous_bassin limit 10;
select ss_bassin from belge.sous_bassin group by 1;
select * from belge.sous_bassin where ss_bassin like 'Lesse';--183 rows 
select wso1_id from belge.sous_bassin where ss_bassin like 'Lesse' group by 1;
select * from belge.sous_bassin5 where ss_bassin like 'Lesse' ;
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'belge', 'catchment_meuse', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM belge.catchment_meuse LIMIT 1;

update belge.catchment_meuse set ss_bassin='Mid meuse' where ss_bassin='Mean Meuse';
select 

select geometrytype(the_geom) from belge.catchment_meuse

   

select count(wso1_id) from belge.catchment_meuse group by (wso1_id)

create table belge.catchment_meuse2 as select distinct on (wso1_id) * from belge.catchment_meuse;
drop table belge.catchment_meuse;
alter table belge.catchment_meuse2 rename to catchment_meuse;
select * from belge.catchement_meuse


drop table if exists  belge.catchment_meuse_union;
create table belge.catchment_meuse_union as
select wso4_id,ss_z,st_union(the_geom) as the_geom from (
select 
	 wso4_id,
	 case when zones is null then ss_bassin
	 else zones end as ss_z,
	 the_geom
	  from belge.catchment_meuse)sub
  group by wso4_id,ss_z;

INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'belge', 'catchment_meuse_union', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM belge.catchment_meuse_union LIMIT 1;


update belge.catchment_meuse_union set ss_z='Upstream Lesse' where ss_z='Upstream Lomme';
update belge.catchment_meuse_union set ss_z='Downstream Lesse' where ss_z='Downstream Lomme'; 
update belge.catchment_meuse set zones='Downstream Lesse' where zones='Downstream Lomme'; 
update belge.catchment_meuse set zones='Upstream Lesse' where zones='Upstream Lomme'; 