
-- capture des obstacles
DROP TABLE IF EXISTS dbeel.obstacles_ccm_500;
CREATE TABLE dbeel.obstacles_ccm_500 as (
        SELECT distinct on (ob_id ) ob_id , gid, wso1_id, min(distance) as distance, height,score,nbdams, the_geom FROM (
               SELECT ob_id, gid , wso1_id, distance,the_geom, 
                s.po_obstruction_height as height,
                case when s.po_no_obstruction_passability =208 then NULL
                when s.po_no_obstruction_passability =209 Then 0
                when s.po_no_obstruction_passability =210 Then 1
                when s.po_no_obstruction_passability =211 Then 2
                when s.po_no_obstruction_passability =212 Then 3
                when s.po_no_obstruction_passability =213 Then 4
                when s.po_no_obstruction_passability =214 Then 5 end as score,
                1 AS nbdams -- pour jointure ultérieure
                FROM dbeel.observation_places_ccm_500
                join dbeel.physical_obstruction s ON op_id=s.ob_op_id
                WHERE the_geom IS NOT NULL
                ORDER BY ob_id) AS sub 
                GROUP BY ob_id, gid, wso1_id, distance,the_geom, height, score, nbdams
);

alter table dbeel.obstacles_ccm_500 add column id serial;
-- creation d'index, clé primaire, et constraintes qui vont bien
alter table dbeel.obstacles_ccm_500 add CONSTRAINT enforce_dims_the_geom CHECK (ndims(the_geom) = 2);
alter table dbeel.obstacles_ccm_500 add  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL);
alter table dbeel.obstacles_ccm_500 add  CONSTRAINT enforce_srid_the_geom CHECK (srid(the_geom) = 3035);

-- select * from dbeel.obstacles_ccm_500 order by score

select avg(height),score from dbeel.obstacles_ccm_500 group by score order by score ;
CREATE OR REPLACE FUNCTION _final_median(numeric[])
   RETURNS numeric AS
$$
   SELECT AVG(val)
   FROM (
     SELECT val
     FROM unnest($1) val
     ORDER BY 1
     LIMIT  2 - MOD(array_upper($1, 1), 2)
     OFFSET CEIL(array_upper($1, 1) / 2.0) - 1
   ) sub;
$$
LANGUAGE 'sql' IMMUTABLE;
 
CREATE AGGREGATE median(numeric) (
  SFUNC=array_append,
  STYPE=numeric[],
  FINALFUNC=_final_median,
  INITCOND='{}'
);

select avg(height),score from dbeel.obstacles_ccm_500 group by score order by score ;

-- 0.737643314383117; 0;0.7
-- 0.485636008615421; 1;0.44
-- 0.582429379743933; 3;0.5
-- 0.791119402330091; 4;0.65
-- 1.63602666750054;  5;1
select height,score from dbeel.obstacles_ccm_500 where score is not null and height is null 
select * from dbeel.obstacles_ccm_500 where score is null -

UPDATE dbeel.obstacles_ccm_500 SET height=0.74 where score=1 and height is null; 
UPDATE dbeel.obstacles_ccm_500 SET height=0.49 where score=2 and height is null;
UPDATE dbeel.obstacles_ccm_500 SET height=0.58 where score=3 and height is null;
UPDATE dbeel.obstacles_ccm_500 SET height=0.79 where score=4 and height is null; 
UPDATE dbeel.obstacles_ccm_500 SET height=1.63 where score=5 and height is null; 







