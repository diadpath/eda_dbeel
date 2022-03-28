-- identification of unit errors
/*
WITH test as
(SELECT ob_dp_name, ba_ob_id, min(bc_numvalue), max(bc_numvalue),  count(*)  FROM sudoang.dbeel_mensurationindiv_biol_charac
JOIN sudoang.dbeel_batch_fish ON bc_ba_id = ba_id
JOIN sudoang.view_electrofishing ON ba_ob_id = ob_id
-- nomenclature table
JOIN dbeel_nomenclature.biological_characteristic_type ON bc_no_characteristic_type = biological_characteristic_type.no_id
JOIN dbeel_nomenclature.species ON ba_no_species = species.no_id
JOIN dbeel_nomenclature.value_type ON ba_no_value_type = value_type.no_id
WHERE species.no_name = 'Anguilla anguilla'
	AND biological_characteristic_type.no_name = 'Length'
	AND value_type.no_name = 'Raw data or Individual data'
GROUP BY ba_ob_id, ob_dp_name),
diag AS
	(SELECT *, CASE 
	-- the 2 following lines have been sorted out with the following query
		WHEN  ob_dp_name IN ('ALberto Aguirre', 'Lucía García Florez', 'Nacho Ferrando Belloch') THEN 'cm'
		WHEN  ob_dp_name IN ('Belén Muñoz', 'Carlos Antunes', 'Carlos Fernandez', 'Francisco Hervella', 'Iker Azpiroz', 'Isabel Domingos', 'Josu Iñaki Elso Huarte', 'Lluis Zamora', 'Rafael Miranda Ferreiro') THEN 'mm'
	-- original case when to explore data
		WHEN min>=50 AND max<1500 THEN 'mm'
		WHEN min >=5 AND max<150 THEN 'cm'
		ELSE 'autre' END AS diagnostic FROM test 
	ORDER BY ob_dp_name, ba_ob_id)
SELECT ob_dp_name, count(*) FILTER(WHERE diagnostic = 'mm') AS mm, count(*) FILTER(WHERE diagnostic = 'cm') AS cm , count(*) FILTER(WHERE diagnostic = 'autre') AS autre FROM diag
GROUP BY ob_dp_name
ORDER BY ob_dp_name
;

-- check for data of a particular data provider
WITH test as
(SELECT ob_dp_name, ba_ob_id, min(bc_numvalue), max(bc_numvalue),  count(*)  FROM sudoang.dbeel_mensurationindiv_biol_charac
JOIN sudoang.dbeel_batch_fish ON bc_ba_id = ba_id
JOIN sudoang.view_electrofishing ON ba_ob_id = ob_id
-- nomenclature table
JOIN dbeel_nomenclature.biological_characteristic_type ON bc_no_characteristic_type = biological_characteristic_type.no_id
JOIN dbeel_nomenclature.species ON ba_no_species = species.no_id
JOIN dbeel_nomenclature.value_type ON ba_no_value_type = value_type.no_id
WHERE species.no_name = 'Anguilla anguilla'
	AND biological_characteristic_type.no_name = 'Length'
	AND value_type.no_name = 'Raw data or Individual data'
GROUP BY ba_ob_id, ob_dp_name),
diag AS
	(SELECT *, CASE WHEN min>=50 AND max<1500 THEN 'mm' WHEN min >=5 AND max<150 THEN 'cm' ELSE 'autre' END AS diagnostic FROM test 
	ORDER BY ob_dp_name, ba_ob_id)
SELECT * FROM diag
WHERE ob_dp_name = 'Rafael Miranda Ferreiro' 
AND diagnostic <> 'mm'
;

-- check biometry data from a particular operation
SELECT bc_ba_id, bc_id, biological_characteristic_type.no_name, bc_numvalue  FROM sudoang.dbeel_mensurationindiv_biol_charac
JOIN sudoang.dbeel_batch_fish ON bc_ba_id = ba_id
-- nomenclature table
JOIN dbeel_nomenclature.biological_characteristic_type ON bc_no_characteristic_type = biological_characteristic_type.no_id
JOIN dbeel_nomenclature.species ON ba_no_species = species.no_id
JOIN dbeel_nomenclature.value_type ON ba_no_value_type = value_type.no_id
WHERE species.no_name = 'Anguilla anguilla'
	--AND biological_characteristic_type.no_name = 'Length'
	AND value_type.no_name = 'Raw data or Individual data'
	AND ba_ob_id = '75b8bd1a-067c-4d07-8894-904aa30c333f'
--	AND bc_numvalue<50
ORDER BY bc_ba_id
;

-- update cm to mm
BEGIN;

UPDATE sudoang.dbeel_mensurationindiv_biol_charac SET bc_numvalue = bc_numvalue*10
FROM sudoang.dbeel_batch_fish, sudoang.view_electrofishing, dbeel_nomenclature.biological_characteristic_type, dbeel_nomenclature.species, dbeel_nomenclature.value_type
WHERE bc_ba_id = ba_id AND bc_no_characteristic_type = biological_characteristic_type.no_id AND ba_ob_id = ob_id AND ba_no_species = species.no_id AND  ba_no_value_type = value_type.no_id
	AND species.no_name = 'Anguilla anguilla'
	AND biological_characteristic_type.no_name = 'Length'
	AND value_type.no_name = 'Raw data or Individual data'
	AND ob_dp_name IN ('ALberto Aguirre', 'Lucía García Florez', 'Nacho Ferrando Belloch')
;

ROLLBACK;
--COMMIT;

--SELECT *, totalnumber<(COALESCE(nbp1,0)+COALESCE(nbp2,0)+COALESCE(nbp3,0)) FROM sudoang.view_electrofishing
--WHERE (totalnumber<(COALESCE(nbp1,0)+COALESCE(nbp2,0)+COALESCE(nbp3,0)) OR totalnumber<COALESCE(nb_size_measured, 0))
--;

*/
-------
DROP VIEW IF EXISTS sudoang.view_electrofishing_size CASCADE;
CREATE OR REPLACE VIEW  sudoang.view_electrofishing_size AS (
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
            SELECT dbeel_batch_ope.ba_ob_id,
                    dbeel_batch_ope.ba_quantity,
                    dbeel_batch_ope.ba_batch_level,
                    b1.no_name AS ba_species,
                    b2.no_name AS ba_stage,
                    b3.no_name AS ba_value_type,
                    b4.no_name AS ba_biological_characteristic_type,
                    b5.no_name AS ba_individual_status
                   FROM sudoang.dbeel_batch_ope
                     JOIN dbeel_nomenclature.nomenclature b1 ON dbeel_batch_ope.ba_no_species = b1.no_id
                     JOIN dbeel_nomenclature.nomenclature b2 ON dbeel_batch_ope.ba_no_stage = b2.no_id
                     JOIN dbeel_nomenclature.nomenclature b3 ON dbeel_batch_ope.ba_no_value_type = b3.no_id
                     JOIN dbeel_nomenclature.nomenclature b4 ON dbeel_batch_ope.ba_no_biological_characteristic_type = b4.no_id
                     JOIN dbeel_nomenclature.nomenclature b5 ON dbeel_batch_ope.ba_no_individual_status = b5.no_id
                  ) ba
                   WHERE ba.ba_species::text = 'Anguilla anguilla'::text 
                   AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text) 
                   AND ba.ba_biological_characteristic_type::text = 'Number'::text 
                   AND ba.ba_batch_level = 1),
taille AS
	(
	SELECT dp_name, ob_id, dbeel_mensurationindiv_biol_charac.*, totalnumber
	FROM sudoang.dbeel_mensurationindiv_biol_charac
	JOIN sudoang.dbeel_batch_fish ON bc_ba_id = dbeel_batch_fish.ba_id
	JOIN sudoang.dbeel_electrofishing ON ba_ob_id=ob_id
	JOIN ba_number ON ba_number.ba_ob_id=ob_id
	JOIN sudoang.dbeel_station ON ob_op_id=op_id
	JOIN dbeel.data_provider ON ob_dp_id=dp_id
	--JOIN sudoang.view_electrofishing ON ba_ob_id = ob_id
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

--SELECT * FROM sudoang.view_electrofishing_size;
