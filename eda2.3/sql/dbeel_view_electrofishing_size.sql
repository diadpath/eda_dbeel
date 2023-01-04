DROP VIEW IF EXISTS dbeel.view_electrofishing_size CASCADE;
CREATE OR REPLACE VIEW  dbeel.view_electrofishing_size AS (
WITH ba_number AS (
SELECT
      ba.ba_ob_id,
      ba.ba_quantity AS totalnumber,
            ba.ba_batch_level,
            ba.ba_species,
            ba.ba_stage,
            ba.ba_value_type,
            ba.ba_biological_characteristic_type,
            ba.ba_individual_status  
            FROM (
            SELECT batch.ba_ob_id,
                    batch.ba_quantity,
                    batch.ba_batch_level,
                    b1.no_name AS ba_species,
                    b2.no_name AS ba_stage,
                    b3.no_name AS ba_value_type,
                    b4.no_name AS ba_biological_characteristic_type,
                    b5.no_name AS ba_individual_status
                   FROM dbeel.batch
                     JOIN dbeel_nomenclature.nomenclature b1 ON batch.ba_no_species = b1.no_id
                     JOIN dbeel_nomenclature.nomenclature b2 ON batch.ba_no_stage = b2.no_id
                     JOIN dbeel_nomenclature.nomenclature b3 ON batch.ba_no_value_type = b3.no_id
                     JOIN dbeel_nomenclature.nomenclature b4 ON batch.ba_no_biological_characteristic_type = b4.no_id
                     JOIN dbeel_nomenclature.nomenclature b5 ON batch.ba_no_individual_status = b5.no_id
                  ) ba
                   WHERE ba.ba_species::text = 'Anguilla anguilla'::text 
                   AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text) 
                   AND ba.ba_biological_characteristic_type::text = 'Number'::text 
                   AND ba.ba_batch_level = 1),
taille AS
  (
  SELECT dp_name, ob_id, bc.*, totalnumber
  FROM dbeel.biological_characteristic AS bc 
  JOIN dbeel.batch ON bc_ba_id = batch.ba_id
  JOIN dbeel.electrofishing ON ba_ob_id=ob_id
  JOIN ba_number ON ba_number.ba_ob_id=ob_id
  JOIN dbeel.observation_places ON ob_op_id=op_id
  JOIN dbeel.data_provider ON ob_dp_id=dp_id
  --JOIN dbeel.view_electrofishing ON ba_ob_id = ob_id
  -- nomenclature table
  JOIN dbeel_nomenclature.biological_characteristic_type ON bc_no_characteristic_type = biological_characteristic_type.no_id
  JOIN dbeel_nomenclature.species ON ba_no_species = species.no_id
  JOIN dbeel_nomenclature.value_type ON ba_no_value_type = value_type.no_id
  WHERE species.no_name = 'Anguilla anguilla'
    AND biological_characteristic_type.no_name = 'Length'
    AND value_type.no_name = 'Raw data or Individual data'
    AND bc_numvalue>50 AND bc_numvalue<1400
  ),
--SELECT count(*) FROM taille
test AS
  (
  SELECT dp_name, ob_id, min(bc_numvalue), max(bc_numvalue), count(*), totalnumber
  FROM taille
  GROUP BY ob_id, dp_name, totalnumber
  ),
--SELECT * FROM test
diag AS
  (
  SELECT ob_id, CASE 
    WHEN totalnumber<10 AND count=totalnumber THEN  'ok1'
    WHEN totalnumber>=10 AND count>= 0.80 * totalnumber THEN 'ok2'
    WHEN totalnumber>=50 AND count>= 30 THEN 'ok3'
    ELSE 'no'
    END AS diagnostic
  FROM test
  ORDER BY dp_name
  ),
--SELECT count(*) FROM diag
selected_length AS
  (
  SELECT * FROM taille
  JOIN diag USING(ob_id)
  WHERE diagnostic <> 'no'
  ),
--SELECT * FROM selected_length
length_class AS
  (
  SELECT *, CASE 
    WHEN bc_numvalue<50 THEN '0 - error'
    WHEN bc_numvalue>=50 AND bc_numvalue<150 THEN '1 - <150'
    WHEN bc_numvalue>=150 AND bc_numvalue<300 THEN '2 - [150-300['
    WHEN bc_numvalue>=300 AND bc_numvalue<450 THEN '3 - [300-450['
    WHEN bc_numvalue>=450 AND bc_numvalue<600 THEN '4 - [450-600['
    WHEN bc_numvalue>=600 AND bc_numvalue<750 THEN '5 - [600-750['
    WHEN bc_numvalue>=750 THEN '6 - >=750'
    END AS length_class
  FROM selected_length
  ),
count_class AS
  (
  SELECT ob_id, dp_name, length_class, count(*) AS nb_class 
  FROM length_class
  GROUP BY ob_id, dp_name, length_class
  ORDER BY ob_id, dp_name, length_class
  ),
--SELECT * FROM count_class
--ci dessous c'est pour faire un coalesce et pas avoir de catégorie manquante
combinaison_total AS
  (
  SELECT * 
  FROM (SELECT DISTINCT ob_id, dp_name FROM length_class) AS ob, 
    (SELECT DISTINCT length_class FROM length_class) AS classe
  )
--SELECT * FROM combinaison_total
SELECT ob_id, dp_name, length_class, COALESCE(nb_class, 0) AS number 
FROM combinaison_total
  LEFT JOIN count_class USING (ob_id, length_class, dp_name)
ORDER BY ob_id, dp_name, length_class
)
;