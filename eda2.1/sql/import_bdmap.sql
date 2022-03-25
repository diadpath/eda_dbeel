--SET client_encoding ='LATIN1';

DELETE FROM taxon;
COPY taxon FROM 'C:/Users/admin-mig/Desktop/BdMap/Taxon.txt' CSV HEADER DELIMITER '|' ;
UPDATE version SET date_maj=current_date WHERE "table"='taxon';
/*
DELETE FROM codier;
COPY codier FROM 'C:/Users/admin-mig/Desktop/BdMap/codier.txt' CSV HEADER DELIMITER '|' ;
UPDATE version SET date_maj=current_date WHERE "table"='codier';
*/
ALTER TABLE station alter column st_limites type text;
ALTER TABLE station alter column st_lieudit type text;
DELETE FROM station;
COPY station FROM 'C:/Users/admin-mig/Desktop/BdMap/station.txt' CSV HEADER DELIMITER '|'  ;--13059, suppréssion de tous les " + retours chariots
UPDATE version SET date_maj=current_date WHERE "table"='station';

DELETE FROM operation;
COPY operation FROM 'C:/Users/admin-mig/Desktop/BdMap/operation.txt' CSV HEADER DELIMITER '|' ; --29207 lignes retours chariots 6356 18521 23169 24151 26347 27327 28198 28357
UPDATE version SET date_maj=current_date WHERE "table"='operation';
select count(*) from operation

DELETE FROM optaxon;--224185
COPY optaxon FROM 'C:/Users/admin-mig/Desktop/BdMap/optaxon.txt' CSV HEADER DELIMITER '|' ; --235565
UPDATE version SET date_maj=current_date WHERE "table"='optaxon';

DELETE FROM tableauclassetaille;--226361
COPY tableauclassetaille FROM 'C:/Users/admin-mig/Desktop/BdMap/tableauclassetaille.txt' CSV HEADER DELIMITER '|' ;--237748
UPDATE version SET date_maj=current_date WHERE "table"='tableauclassetaille';

DELETE FROM pathopoisson;--4 320 841 lignes modifiées
COPY pathopoisson FROM 'C:/Users/admin-mig/Desktop/BdMap/pathopoisson.txt' CSV HEADER DELIMITER '|' ;--4 485 736
UPDATE version SET date_maj=current_date WHERE "table"='pathopoisson';

DELETE FROM passtaxon;--285388
COPY passtaxon FROM 'C:/Users/admin-mig/Desktop/BdMap/passtaxon.txt' CSV HEADER DELIMITER '|' ;--298108
UPDATE version SET date_maj=current_date WHERE "table"='passtaxon';

DELETE FROM mensurationindiv;--1710324 lignes 
COPY mensurationindiv FROM 'C:/Users/admin-mig/Desktop/BdMap/mensurationindiv.txt' CSV HEADER DELIMITER '|' ;--1863626 lignes
UPDATE version SET date_maj=current_date WHERE "table"='mensurationindiv';

DELETE FROM zonepeche;--43640 lignes modifiées
COPY zonepeche FROM 'C:/Users/admin-mig/Desktop/BdMap/zonepeche.txt' CSV HEADER DELIMITER '|' ;--44308 lignes modifiées
UPDATE version SET date_maj=current_date WHERE "table"='zonepeche';

DELETE FROM lotpeche;--3362499 lignes modifiées
COPY lotpeche FROM 'C:/Users/admin-mig/Desktop/roe/lotpeche.csv' CSV HEADER DELIMITER ';' QUOTE '"'; --3743578
UPDATE version SET date_maj=current_date WHERE "table"='lotpeche';

DELETE FROM classe_taille_taxon;--2625412 lignes modifiées
COPY classe_taille_taxon FROM 'C:/Users/admin-mig/Desktop/BdMap/classetailletaxon.txt' CSV HEADER DELIMITER '|' ;--2751856 lignes modifiées
UPDATE version SET date_maj=current_date WHERE "table"='classe_taille_taxon';

DELETE FROM patho;--47
COPY patho FROM 'C:/Users/admin-mig/Desktop/BdMap/patho.txt' CSV HEADER DELIMITER '|' ;--46
UPDATE version SET date_maj=current_date WHERE "table"='patho';

SET client_encoding ='UTF-8';
drop table codier;
create table codier(
cd_id integer,	
cd_fc_id integer,
cd_code character varying(20),
cd_libc text ,
cd_libl text,
cd_chaine1 text,
cd_chaine2 text,
cd_num1 integer,	
cd_num2 integer,
cd_date1 text,
cd_date2 text,
cd_dt_cre text,
cd_dt_maj text,
cd_qi_maj text);
COPY codier FROM 'C:/Users/admin-mig/Desktop/roe/codier.txt' CSV HEADER DELIMITER E'\t'  ;----1702
/* 
Modification de la table pour creer des géométries spatiales
*/

/*
H:
cd base
pg_dump -h 1.100.1.6 -U postgres --table station -f "station2014.sql" bd_map
psql -U postgres -h 1.100.1.6 -f "station.sql" eda2.1
*/
create schema bdmap2012;
alter table station set schema bdmap2012;
set search_path to bdmap2012,public;
create table stationsp2 as select * from station;--13059
SELECT AddGeometryColumn('bdmap2012', 'stationsp2','the_geom', 3035,'POINT',2); 
UPDATE bdmap2012.stationsp2 SET the_geom=st_transform(PointFromText('POINT(' || st_abcisse || ' ' || st_ordonnee || ')',27572),3035);--13059
ALTER TABLE bdmap2012.stationsp2 SET WITH OIDS;
CREATE INDEX indexStations ON bdmap2012.stationsp2
  USING GIST ( the_geom GIST_GEOMETRY_OPS ); 

update bdmap2012.stationsp2 set the_geom=sub.the_geom
from bdmap2009.stationsp2 sub
where sub.st_codecsp=bdmap2012.stationsp2.st_codecsp
and st_id in (1265,1668)


-- quels sont les stations qui ont une géométrie dans l'ancienne et pas dans la nouvelle
select st_id from bdmap2012.stationsp2 new join
bdmap2009.stationsp2 old on old.st_codecsp=new.st_codecsp
where
new.the_geom is null
and old.the_geom is not null; --8580,1182,8642 trois stations
-- mise à jour des trois stations
update bdmap2012.stationsp2 set the_geom=sub.the_geom
from bdmap2009.stationsp2 sub
where sub.st_codecsp=bdmap2012.stationsp2.st_codecsp
and st_id in (select st_id from bdmap2012.stationsp2 new join
bdmap2009.stationsp2 old on old.st_codecsp=new.st_codecsp
where
new.the_geom is null
and old.the_geom is not null);--3
-- une station avec les coordonnées en L93
update bdmap2012.stationsp2 set the_geom=st_transform(PointFromText('POINT(' || st_abcisse_l93 || ' ' || st_ordonnee_l93 || ')',2154),3035)
where the_geom is null and st_abcisse_l93>0;--1

select count(*) from bdmap2012.stationsp2 where the_geom is not null; --12950 (on en avait 11371)
select count(*) from bdmap2012.stationsp2;--13059
select count(*) from bdmap2012.stationsp2 where the_geom is null; -- 109 stations ou il manque la geométrie

COMMENT ON TABLE bdmap2012.stationsp2 is 'Données BDMAP avec l''année 2011 transmises par Erick Baglinière au format txt'


DROP TABLE IF EXISTS bdmap2012.bdmap_rht;
CREATE TABLE bdmap2012.bdmap_rht as (
        SELECT distinct on (st_codecsp) st_codecsp, id_drain, min(distance) as distance, the_geom FROM (
               SELECT st_codecsp, id_drain ,CAST(distance(r.the_geom, s.the_geom) as  decimal(15,1)) as distance,s.the_geom 
               FROM bdmap2012.stationsp2 As s
               INNER JOIN  rht.rht r ON ST_DWithin(r.the_geom, s.the_geom,300)
               WHERE s.the_geom IS NOT NULL
               ORDER BY st_codecsp) AS sub 
        GROUP BY st_codecsp, distance,id_drain, the_geom
);--12381
alter table bdmap2012.bdmap_rht add column id serial;
-- mise à jour de la table geometry_columns
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'bdmap2012', 'bdmap_rht', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM bdmap2012.bdmap_rht LIMIT 1;

-- creation d'index, clé primaire, et constraintes qui vont bien
alter table bdmap2012.bdmap_rht add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table bdmap2012.bdmap_rht add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table bdmap2012.bdmap_rht add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
alter table bdmap2012.bdmap_rht ADD CONSTRAINT pk_id PRIMARY KEY(id);
CREATE INDEX indexbdmap_rht ON bdmap2012.bdmap_rht
  USING GIST ( the_geom GIST_GEOMETRY_OPS );

alter table bdmap2012.bdmap_rht add column a_conserver boolean default TRUE;