-- sudoang.view_electrofishing_size source

CREATE OR REPLACE VIEW sudoang.view_electrofishing_size
AS WITH ba_number AS (
         SELECT ba.ba_ob_id,
            ba.ba_quantity AS totalnumber,
            ba.ba_batch_level,
            ba.ba_species,
            ba.ba_stage,
            ba.ba_value_type,
            ba.ba_biological_characteristic_type,
            ba.ba_individual_status
           FROM ( SELECT dbeel_batch_ope.ba_ob_id,
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
                     JOIN dbeel_nomenclature.nomenclature b5 ON dbeel_batch_ope.ba_no_individual_status = b5.no_id) ba
          WHERE ba.ba_species::text = 'Anguilla anguilla'::text AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text) AND ba.ba_biological_characteristic_type::text = 'Number'::text AND ba.ba_batch_level = 1
        ), taille AS (
         SELECT data_provider.dp_name,
            dbeel_electrofishing.ob_id,
            dbeel_mensurationindiv_biol_charac.bc_id,
            dbeel_mensurationindiv_biol_charac.bc_ba_id,
            dbeel_mensurationindiv_biol_charac.bc_no_characteristic_type,
            dbeel_mensurationindiv_biol_charac.bc_no_value_type,
            dbeel_mensurationindiv_biol_charac.bc_numvalue,
            dbeel_mensurationindiv_biol_charac.fish_id,
            dbeel_mensurationindiv_biol_charac.locationid,
            dbeel_mensurationindiv_biol_charac.place_classification,
            ba_number.totalnumber
           FROM sudoang.dbeel_mensurationindiv_biol_charac
             JOIN sudoang.dbeel_batch_fish ON dbeel_mensurationindiv_biol_charac.bc_ba_id = dbeel_batch_fish.ba_id
             JOIN sudoang.dbeel_electrofishing ON dbeel_batch_fish.ba_ob_id = dbeel_electrofishing.ob_id
             JOIN ba_number ON ba_number.ba_ob_id = dbeel_electrofishing.ob_id
             JOIN sudoang.dbeel_station ON dbeel_electrofishing.ob_op_id = dbeel_station.op_id
             JOIN dbeel.data_provider ON dbeel_electrofishing.ob_dp_id = data_provider.dp_id
             JOIN dbeel_nomenclature.biological_characteristic_type ON dbeel_mensurationindiv_biol_charac.bc_no_characteristic_type = biological_characteristic_type.no_id
             JOIN dbeel_nomenclature.species ON dbeel_batch_fish.ba_no_species = species.no_id
             JOIN dbeel_nomenclature.value_type ON dbeel_batch_fish.ba_no_value_type = value_type.no_id
          WHERE species.no_name::text = 'Anguilla anguilla'::text AND biological_characteristic_type.no_name::text = 'Length'::text AND value_type.no_name::text = 'Raw data or Individual data'::text AND dbeel_mensurationindiv_biol_charac.bc_numvalue > 50::double precision AND dbeel_mensurationindiv_biol_charac.bc_numvalue < 1400::double precision
        ), test AS (
         SELECT taille.dp_name,
            taille.ob_id,
            min(taille.bc_numvalue) AS min,
            max(taille.bc_numvalue) AS max,
            count(*) AS count,
            taille.totalnumber
           FROM taille
          GROUP BY taille.ob_id, taille.dp_name, taille.totalnumber
        ), diag AS (
         SELECT test.ob_id,
                CASE
                    WHEN test.totalnumber < 10::double precision AND test.count::double precision = test.totalnumber THEN 'ok1'::text
                    WHEN test.totalnumber >= 10::double precision AND test.count::double precision >= (0.80::double precision * test.totalnumber) THEN 'ok2'::text
                    WHEN test.totalnumber >= 50::double precision AND test.count >= 30 THEN 'ok3'::text
                    ELSE 'no'::text
                END AS diagnostic
           FROM test
          ORDER BY test.dp_name
        ), selected_length AS (
         SELECT taille.ob_id,
            taille.dp_name,
            taille.bc_id,
            taille.bc_ba_id,
            taille.bc_no_characteristic_type,
            taille.bc_no_value_type,
            taille.bc_numvalue,
            taille.fish_id,
            taille.locationid,
            taille.place_classification,
            taille.totalnumber,
            diag.diagnostic
           FROM taille
             JOIN diag USING (ob_id)
          WHERE diag.diagnostic <> 'no'::text
        ), length_class AS (
         SELECT selected_length.ob_id,
            selected_length.dp_name,
            selected_length.bc_id,
            selected_length.bc_ba_id,
            selected_length.bc_no_characteristic_type,
            selected_length.bc_no_value_type,
            selected_length.bc_numvalue,
            selected_length.fish_id,
            selected_length.locationid,
            selected_length.place_classification,
            selected_length.totalnumber,
            selected_length.diagnostic,
                CASE
                    WHEN selected_length.bc_numvalue < 50::double precision THEN '0 - error'::text
                    WHEN selected_length.bc_numvalue >= 50::double precision AND selected_length.bc_numvalue < 150::double precision THEN '1 - <150'::text
                    WHEN selected_length.bc_numvalue >= 150::double precision AND selected_length.bc_numvalue < 300::double precision THEN '2 - [150-300['::text
                    WHEN selected_length.bc_numvalue >= 300::double precision AND selected_length.bc_numvalue < 450::double precision THEN '3 - [300-450['::text
                    WHEN selected_length.bc_numvalue >= 450::double precision AND selected_length.bc_numvalue < 600::double precision THEN '4 - [450-600['::text
                    WHEN selected_length.bc_numvalue >= 600::double precision AND selected_length.bc_numvalue < 750::double precision THEN '5 - [600-750['::text
                    WHEN selected_length.bc_numvalue >= 750::double precision THEN '6 - >=750'::text
                    ELSE NULL::text
                END AS length_class
           FROM selected_length
        ), count_class AS (
         SELECT length_class.ob_id,
            length_class.dp_name,
            length_class.length_class,
            count(*) AS nb_class
           FROM length_class
          GROUP BY length_class.ob_id, length_class.dp_name, length_class.length_class
          ORDER BY length_class.ob_id, length_class.dp_name, length_class.length_class
        ), combinaison_total AS (
         SELECT ob.ob_id,
            ob.dp_name,
            classe.length_class
           FROM ( SELECT DISTINCT length_class.ob_id,
                    length_class.dp_name
                   FROM length_class) ob,
            ( SELECT DISTINCT length_class.length_class
                   FROM length_class) classe
        )
 SELECT combinaison_total.ob_id,
    combinaison_total.dp_name,
    combinaison_total.length_class,
    COALESCE(count_class.nb_class, 0::bigint) AS number
   FROM combinaison_total
     LEFT JOIN count_class USING (ob_id, length_class, dp_name)
  ORDER BY combinaison_total.ob_id, combinaison_total.dp_name, combinaison_total.length_class;

-- Permissions

ALTER TABLE sudoang.view_electrofishing_size OWNER TO postgres;
GRANT ALL ON TABLE sudoang.view_electrofishing_size TO postgres;
GRANT SELECT ON TABLE sudoang.view_electrofishing_size TO dbeel;