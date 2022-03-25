-- Ajout d'une colonne


alter table dbeel.observation_places add column the_geom geometry;
alter table dbeel.observation_places add  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2);
alter table dbeel.observation_places add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table dbeel.observation_places add   CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 3035);
alter table dbeel.observation_places add   CONSTRAINT geometry_valid_check CHECK (isvalid(the_geom));

select SRID(the_geom), * from dbeel.observation_places;
update dbeel.observation_places set the_geom=ST_Transform(the_geom,3035) where SRID(the_geom)=27572; --10075
