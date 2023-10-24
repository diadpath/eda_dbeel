drop table if exists france.join_france_2023_rn;
CREATE TABLE france.join_france_2023_rn AS ( 
--on prend toutes les rivières de france et on rattache les stations aux segments de rivières qui sont à moins de 500m
with projection as (
SELECT frn.idsegment, 
       op.op_id,                          
       op.the_geom,
       st_distance(frn.geom,op.the_geom) as distance 
       FROM france.rn frn
       join france.rna frna on frna.idsegment = frn.idsegment 
       JOIN  dbeel.observation_places op ON st_dwithin(frn.geom, op.the_geom, 500)
       where op.op_gis_layername in ('ASPE','RSA')      
       order by idsegment, distance desc)
select distinct on (op_id)
	   op_id,
	   idsegment,
	   the_geom,
       distance
       from projection
--34184 stations (on avait 35752 stations, on va perdre les opérations reliées à ces stations perdues) 
       );
       
ALTER TABLE france.join_france_2023_rn  OWNER TO postgres;
GRANT ALL ON TABLE france.join_france_2023_rn  TO postgres;
GRANT SELECT ON TABLE france.join_france_2023_rn  TO dbeel;