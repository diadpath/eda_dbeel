with big as(
select observation_places.*,electrofishing.*,biological_characteristic.* from 
dbeel.observation_places
      JOIN dbeel.electrofishing ON observation_places.op_id = electrofishing.ob_op_id
      JOIN dbeel.batch  ba1 ON ba_ob_id=ob_id
      JOIN dbeel.biological_characteristic on bc_ba_id=ba_id
      where bc_no_characteristic_type =39)
      select distinct on (op_gis_systemname) op_gis_systemname from big;	-- Je ne trouve pas les données ONEMA... bizarre
-- Soit elles ont été intégrées dans l'ancienne dbeel et pas ici, il faudrait par exemple faire un dump des
-- schema anglian et basque, vérifier pour irlande...
-- soit le script n'a pas été relancé jusqu'à la fin

/*
Fonction pour calculer la médiane
*/

CREATE FUNCTION _final_median(anyarray) RETURNS float8 AS $$ 
  WITH q AS
  (
     SELECT val
     FROM unnest($1) val
     WHERE VAL IS NOT NULL
     ORDER BY 1
  ),
  cnt AS
  (
    SELECT COUNT(*) AS c FROM q
  )
  SELECT AVG(val)::float8
  FROM 
  (
    SELECT val FROM q
    LIMIT  2 - MOD((SELECT c FROM cnt), 2)
    OFFSET GREATEST(CEIL((SELECT c FROM cnt) / 2.0) - 1,0)  
  ) q2;
$$ LANGUAGE sql IMMUTABLE;
 
CREATE AGGREGATE median(anyelement) (
  SFUNC=array_append,
  STYPE=anyarray,
  FINALFUNC=_final_median,
  INITCOND='{}'
);
      
with big as(
select observation_places.*,electrofishing.*,biological_characteristic.* from 
dbeel.observation_places
      JOIN dbeel.electrofishing ON observation_places.op_id = electrofishing.ob_op_id
      JOIN dbeel.batch  ba1 ON ba_ob_id=ob_id
      JOIN dbeel.biological_characteristic on bc_ba_id=ba_id
      where bc_no_characteristic_type =39)
      select median(bc_numvalue) as median,op_gis_systemname from big	
      group by op_gis_systemname

--520 SPW pas de données pour ONEMA...


select * from onema.lotpeche_biol_charac_onema

select * from dbeel.batch where ba_id='b63e08b6-f1f0-4845-b856-5fa7d10de10d'
select * from dbeel.batch where ba_id='ae86b9b2-6dc4-4072-9a77-8f3c1512125c' rien ?????

-- Je pense qu'on a pas tout relancé jusqu'à la fin
-- du coup je peux pas faire les calculs pour la France
