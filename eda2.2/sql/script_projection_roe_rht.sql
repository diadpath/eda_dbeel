Projection spatiale des obstacles (points) sur le RHT (lignes) avec un buffer de 300 m 
DROP TABLE IF EXISTS rht.rhtvs2_roev2;
CREATE TABLE rht.rhtvs2_roev2 as (
        SELECT distinct on (id_roe) id_roe, id_drain, min(distance) as distance, the_geom FROM (
               SELECT id_roe, id_drain ,CAST(distance(r.the_geom, s.the_geom) as  decimal(15,1)) as distance, s.the_geom 
               FROM roe_v2.roe_v2 As s
               INNER JOIN  rht.rhtvs2 r ON ST_DWithin(r.the_geom, s.the_geom,300)
               WHERE s.the_geom IS NOT NULL
               ORDER BY id_roe) AS sub 
        GROUP BY id_roe, distance,id_drain, the_geom  ---49269 lines
); 
alter table rht.rhtvs2_roev2 add column id serial;
-- mise à jour de la table geometry_columns
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'rht', 'rhtvs2_roev2', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
FROM rht.rhtvs2_roev2 LIMIT 1;

-- creation d'index, clé primaire, et constraintes qui vont bien
alter table rht.rhtvs2_roev2 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table rht.rhtvs2_roev2 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table rht.rhtvs2_roev2 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);
alter table rht.rhtvs2_roev2 ADD CONSTRAINT pk_idroe PRIMARY KEY(id);
alter table rht.rhtvs2_roev2 drop CONSTRAINT pk_idroe;
CREATE INDEX indexroev2_rhtvs2 ON rht.rhtvs2_roev2
  USING GIST ( the_geom GIST_GEOMETRY_OPS );
  


  
