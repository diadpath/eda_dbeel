SELECT * FROM sudoang.species_location AS sl 
SELECT count(*) FROM sudoang.dbeel_station ; --16669

COPY (

WITH species_location_uk AS (
SELECT DISTINCT ON (locationid) * FROM sudoang.species_location s 
JOIN sudoang."references" AS r  ON r.idref = s.idref
),
--SELECT count(*) FROM species_location_uk --10678
station AS (
SELECT op_id, -- identifier OF OBservation_place
op_gis_layername, -- DATA provider IN sudoang
--institution, -- institution IF DATA come FROM the sibic
--articletitle, -- article title IF DATA come FROM the sibic
op_placename, -- Name OF the place
st_x(st_transform(geom_reproj , 4326)), --x(EPSG 4326)
st_y(st_transform(geom_reproj,4326)), --y (EPSG 4326)
country -- country
FROM sudoang.dbeel_station s 
LEFT JOIN species_location_uk l
ON l.locationid = s.locationid 
WHERE geom_reproj IS NOT NULL
)
--SELECT count(*) FROM station --13793
SELECT * FROM station
)
--WHERE op_gis_layername ='SIBIC'
 TO '/temp/station.csv' WITH (FORMAT CSV, HEADER);
 
 
 
 -- operations 
--ICNF- (this data is not obtained by ICNF and is restricted for use) 
-- Electricity Supply Board (not public money and there is no permission)- provided exclusively for developing the model.
-- The data provided by ICNF has a 5 year lag time. 

COPY (
 WITH operation AS (
SELECT 
ve.id,
ve.op_id,
ve.op_gis_layername,
CASE WHEN et_establishment_name = 'Valencia Council (VAERSA)' THEN 'Servicio de Caza y Pesca de la Generalitat Valenciana'
     WHEN et_establishment_name = 'ANBIOTEK' THEN 'Basque Water Agency (URA)'
ELSE et_establishment_name END AS "data_provider",
ve.op_placename,
ve.ob_id,
ve.ob_starting_date,
ve.ef_wetted_area,
ve.ef_nbpas,
ve.ef_fished_length,
ve.ef_fished_width,
ve.ob_origin,
ve.ob_type,
ve.ob_period,
ve.ef_fishingmethod,
ve.ef_electrofishing_mean,
density,
totalnumber,
nbp1,
nbp2,
nbp3,
nb_size_measured
FROM sudoang.dbeel_electrofishing 
JOIN sudoang.view_electrofishing ve ON ve.ob_id = dbeel_electrofishing.ob_id
JOIN dbeel_nomenclature.observation_type ON observation_type.no_id=ob_no_type
JOIN dbeel.data_provider ON ob_dp_id = dp_id
JOIN dbeel.establishment ON dp_et_id = et_id
JOIN dbeel_nomenclature.scientific_observation_method ON scientific_observation_method.no_id=ef_no_fishingmethod
JOIN dbeel_nomenclature.electrofishing_mean ON electrofishing_mean.no_id = ef_no_electrofishing_mean 
) 
--SELECT count(*) FROM operation --16443
SELECT * FROM operation
)
TO '/temp/operation.csv' WITH (FORMAT CSV, HEADER);

-- individual size and weight, modifying view to left join
COPY (
 WITH ba_number AS (
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
        ), size AS (
         SELECT data_provider.dp_name,
            dbeel_electrofishing.ob_id,
            dbeel_mensurationindiv_biol_charac.bc_id,
            dbeel_mensurationindiv_biol_charac.bc_ba_id,
            dbeel_mensurationindiv_biol_charac.bc_numvalue AS size,
            dbeel_mensurationindiv_biol_charac.fish_id
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
        ), weight AS (
         SELECT data_provider.dp_name,
            dbeel_electrofishing.ob_id,
            dbeel_mensurationindiv_biol_charac.bc_id,
            dbeel_mensurationindiv_biol_charac.bc_ba_id,
            dbeel_mensurationindiv_biol_charac.bc_numvalue AS weight,
            dbeel_mensurationindiv_biol_charac.fish_id
           FROM sudoang.dbeel_mensurationindiv_biol_charac
             JOIN sudoang.dbeel_batch_fish ON dbeel_mensurationindiv_biol_charac.bc_ba_id = dbeel_batch_fish.ba_id
             JOIN sudoang.dbeel_electrofishing ON dbeel_batch_fish.ba_ob_id = dbeel_electrofishing.ob_id
             JOIN ba_number ON ba_number.ba_ob_id = dbeel_electrofishing.ob_id
             JOIN sudoang.dbeel_station ON dbeel_electrofishing.ob_op_id = dbeel_station.op_id
             JOIN dbeel.data_provider ON dbeel_electrofishing.ob_dp_id = data_provider.dp_id
             JOIN dbeel_nomenclature.biological_characteristic_type ON dbeel_mensurationindiv_biol_charac.bc_no_characteristic_type = biological_characteristic_type.no_id
             JOIN dbeel_nomenclature.species ON dbeel_batch_fish.ba_no_species = species.no_id
             JOIN dbeel_nomenclature.value_type ON dbeel_batch_fish.ba_no_value_type = value_type.no_id
          WHERE species.no_name::text = 'Anguilla anguilla'::text AND biological_characteristic_type.no_name::text = 'Weight'::text AND value_type.no_name::text = 'Raw data or Individual data'::text
        )
 SELECT size.dp_name,
    size.ob_id,
    size.bc_id,
    size.bc_ba_id,
    size.size,
    size.fish_id,
    weight.weight
   FROM size
   LEFT  JOIN weight ON size.bc_ba_id = weight.bc_ba_id
 ) 
TO '/temp/individual.csv' WITH (FORMAT CSV, HEADER); --137885
 
COPY (
SELECT * FROM sudoang.view_silvering)
TO '/temp/silver.csv' WITH (FORMAT CSV, HEADER); 