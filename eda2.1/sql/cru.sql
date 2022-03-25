/*

Script lancé sur nouveau serveur

*/

SELECT PostGIS_full_version();
-- import des données CRU
CREATE TABLE cru
 (
	"gridx"			INTEGER, 
	"gridy"			INTEGER, 
	"long"			numeric, 
	"lat"			numeric, 
	"annee"			INTEGER, 
	"mois"			INTEGER, 
	"valeur"			INTEGER
);

-- moyenne des temp > 13 pour l'année 2000
DROP TABLE cru_2000 ;
CREATE TABLE cru_2000 AS
SELECT long, lat, ROUND(sum(CASE WHEN round(valeur::numeric/10,1)-13<0 THEN 0 ELSE round(valeur::numeric/10,1)-13 END), 1) as tempsup13, ST_SetSRID(ST_MakePoint(long, lat), 4326) AS geom 
FROM cru WHERE annee = 2000 GROUP BY long, lat;

--select min(long), max(long),((max(long) - min(long))/.5)::integer , min(lat), max(lat),((max(lat) - min(lat))/.5)::integer, count(*), min(tempsup13), max(tempsup13) from cru_2000 ;

-- création du raster
DROP TABLE IF EXISTS cru_raster;

CREATE TABLE cru_raster(rid serial primary key, rast raster);

INSERT INTO cru_raster(rast) 
SELECT ST_MakeEmptyRaster(((max(long) - min(long))/.5)::integer+1, ((max(lat) - min(lat))/.5)::integer+1, min(long)-0.25, max(lat)+0.25, 0.5) FROM cru_2000;
SELECT UpdateRasterSRID('cru_raster', 'rast', 4326);
update cru_raster set rast=st_setsrid(rast, 4326) ;
--SELECT ST_SRID(rast) AS srid FROM cru_raster;

-- création d'une bande vide
UPDATE cru_raster SET rast = ST_Addband(rast,'32BF'::text,-9) ;

-- import des données cru dans la bande
UPDATE cru_raster SET rast = St_SetValues(rast, 1,geomvalue) FROM (SELECT ARRAY_AGG(ROW(geom, tempsup13)::geomval) AS geomvalue FROM cru_2000) AS cru;

-- UTILISER ST_VALUE pour récupérer les valeurs de troncon (en prenant le point du milieu du troncon ou en faisant la moyenne de n points équidistants sur le troncon
/*
Déplacement vers nouvelle base compatible 2.1 pour calculs
create extension ltree
C:\Users\admin-mig\Desktop\data>psql -U postgres -f "rhtvs2.sql" -p 5433 CRU
C:\Users\admin-mig\Desktop\data>pg_dump -U postgres -f "rhtvs2.sql" --table rht.
rhtvs2 --verbose eda2.1
*/
--double precision ST_Value(raster rast, geometry pt, boolean exclude_nodata_value=true);
alter table rht.rhtvs2 add column temp_CRU_2000 numeric;
update rht.rhtvs2  set temp_CRU_2000 =temp from (
select id_drain,
st_value(rast,st_centroid(st_transform(the_geom,4326))) as temp from rht.rhtvs2, cru_raster ) as toto
where toto.id_drain=rht.rhtvs2.id_drain;
DROP TABLE cru_2000 ;
DROP table cru;