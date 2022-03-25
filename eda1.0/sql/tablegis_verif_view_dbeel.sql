drop table dbeel.temp_view_electrofishing;
create table dbeel.temp_view_electrofishing as(
select the_geom,v.* from dbeel.view_electrofishing v join dbeel.observation_places p on p.op_id=v.op_id );
create index  "dbeeltemp_view_electrofishing" on dbeel.temp_view_electrofishing using gist(the_geom);
INSERT INTO geometry_columns(f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, "type")
SELECT '', 'dbeel', 'temp_view_electrofishing', 'the_geom', ST_CoordDim(the_geom), ST_SRID(the_geom), GeometryType(the_geom)
 FROM dbeel.temp_view_electrofishing LIMIT 1;