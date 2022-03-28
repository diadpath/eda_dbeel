
DROP VIEW IF EXISTS sudoang.view_electrofishing_size_weight CASCADE;
CREATE OR REPLACE VIEW  sudoang.view_electrofishing_size_weight AS (
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
                   
size AS
	(
	SELECT dp_name, ob_id, 
	bc_id,
	bc_ba_id,
	bc_numvalue AS size,
	dbeel_mensurationindiv_biol_charac.fish_id
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
	
weight AS
	(
	SELECT dp_name, ob_id, 
	bc_id,
	bc_ba_id,
	bc_numvalue AS weight,
	dbeel_mensurationindiv_biol_charac.fish_id
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
		AND biological_characteristic_type.no_name = 'Weight'
		AND value_type.no_name = 'Raw data or Individual data'
	)
	
SELECT size.*, weight FROM size JOIN weight ON (size.bc_ba_id=weight.bc_ba_id)
)
;

--SELECT * FROM sudoang.view_electrofishing_size_weight;
