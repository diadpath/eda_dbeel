select addgeometrycolumn('rht','ers_full','geom',3035,'POINT',2)
update rht.ers_full set geom=the_geom
				from bdmap2012.stationsp2 where stationsp2.st_codecsp=ers_full.st_id
update rht.ers_full set geom=
				ST_GeomFromText('POINT('||st_abcisse||' '||st_ordonnee||')',3035) 
				where source='rsa'; -- 1598
-- pour les plus récentes
update rht.ers_full set geom=
				ST_GeomFromText('POINT('||st_abcisse||' '||st_ordonnee||')',3035) 
				where geom is null;								

alter table station set schema bd_agglo_2017;
select addgeometrycolumn('bd_agglo_2017','station','geom',3035,'POINT',2)


---------------------------
-- creation de la table station et base agglo dans la base
----------------------------

select count (*) from bd_agglo_2017.station; -- 3172
select * from bd_agglo_2017.station limit 10;
select * from bdmap2012.stationsp2 limit 10;
select * from rht.ers_full limit 10;
update bd_agglo_2017.station set geom= ST_Transform(ST_SetSRID(ST_MakePoint(x_l93_station, y_l93_station), 2154),3035);


-- projection geographique pas utilisée
/*
create or replace view bd_agglo_2017.new_station as
(
select s.* from bd_agglo_2017.station s
except 
(select s.* from bd_agglo_2017.station s join
bdmap2012.stationsp2 sp2 ON 
 st_dwithin(geom,the_geom,500))
 )
*/


 select * from rht.ers_full where annee>2012; --225

select code_sandre_station from bd_agglo_2017.new_station;
select st_id from rht.ers_full;

-- Jointure sur le code station
 create or replace view bd_agglo_2017.new_station as
(
select s.* from bd_agglo_2017.station s
except 
(select s.* from bd_agglo_2017.station s join
bdmap2012.stationsp2 sp2 ON 
 st_codecsp=code_sandre_station
 ));


/* 
petites requêtes préparatoires
*/

select st_codecsp from bdmap2012.stationsp2 union 
select code_sandre_station as st_codecsp from bd_agglo_2017.new_station -- 16214=13059 + 3155

select geom from  bd_agglo_2017.new_station where geom is null; --0 OK

-- La table bd_agglo_2017.bdmap_rht a pour geom le point de la station
-- Ici je fais la jointure de l'ancienne table avec les nouvelles stations qui ne sont pas dans l'ancien fichier (a partir de la vue newstation)
-- les colonnes du fichier stationsp2 et new.station(qui est indenitique à bd_agglo_2017.station) sont différentes, mais elles ont en commun le st_codecsp
-- qui a été renommé en code_sandre_station et je n'utilise que cette colonne dans la requète

DROP TABLE IF EXISTS bd_agglo_2017.bdmap_rht;
CREATE TABLE bd_agglo_2017.bdmap_rht as (
        SELECT distinct on (st_codecsp) st_codecsp, id_drain, min(distance) as distance, geom FROM (
               SELECT st_codecsp, id_drain ,CAST(distance(r.the_geom, s.geom) as  decimal(15,1)) as distance,s.geom 
               FROM (
               select st_codecsp,the_geom as geom from bdmap2012.stationsp2 union 
		select code_sandre_station as st_codecsp, geom from bd_agglo_2017.new_station) As s
               INNER JOIN  rht.rhtvs2 r ON ST_DWithin(r.the_geom, s.geom,300)
               WHERE s.geom IS NOT NULL
               ORDER BY st_codecsp) AS sub 
        GROUP BY st_codecsp, distance,id_drain, geom
);--15057
alter table bd_agglo_2017.bdmap_rht add column id serial;
-- mise Ã  jour de la table geometry_columns
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'bd_agglo_2017', 'bdmap_rht', 'geom', ST_CoordDim(geom), ST_SRID(geom), GeometryType(geom)
FROM bd_agglo_2017.bdmap_rht LIMIT 1;

-- creation d'index, clÃ© primaire, et constraintes qui vont bien
alter table bd_agglo_2017.bdmap_rht add CONSTRAINT enforce_dims_geom CHECK (ndims(geom) = 2);
alter table bd_agglo_2017.bdmap_rht add  CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = 'POINT'::text OR geom IS NULL);
alter table bd_agglo_2017.bdmap_rht add  CONSTRAINT enforce_srid_geom CHECK (srid(geom) = 3035);
alter table bd_agglo_2017.bdmap_rht ADD CONSTRAINT pk_id PRIMARY KEY(id);
CREATE INDEX indexbdmap_rht ON  bd_agglo_2017.bdmap_rht 
  USING GIST (geom GIST_GEOMETRY_OPS );

alter table bd_agglo_2017.bdmap_rht add column a_conserver boolean default TRUE;