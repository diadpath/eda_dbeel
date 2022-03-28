DROP VIEW IF EXISTS sudoang.view_electrofishing CASCADE;
CREATE OR REPLACE VIEW sudoang.view_electrofishing AS 
 SELECT 
    row_number() OVER() AS "id",
    ob.op_id,
    ob.op_gis_layername,
    ob.op_placename,
    ob.ob_id,
    ob.ob_starting_date,
    ob.ef_wetted_area,
    ob.ef_nbpas,
    ob.ef_fished_length,
    ob.ef_fished_width,
    o1.no_name AS ob_origin,
    o2.no_name AS ob_type,
    o3.no_name AS ob_period,
    o4.no_name AS ef_fishingmethod,
    o5.no_name AS ef_electrofishing_mean,
    ob.dp_name AS ob_dp_name,  
    ob.et_establishment_name AS data_provider,
    ba1.ba_quantity AS density,
    ba2.ba_quantity AS totalnumber,
    ba3.ba_quantity AS nbp1,
    ba4.ba_quantity AS nbp2,
    ba5.ba_quantity AS nbp3,
    bc.count AS nb_size_measured,
    the_geom
    -- select * 
   FROM ( SELECT dbeel_station.op_id,
            dbeel_station.op_gis_systemname,
            dbeel_station.op_gis_layername,
            dbeel_station.op_gislocation,
            dbeel_station.op_placename,
            dbeel_station.op_no_observationplacetype,
            dbeel_station.op_op_id,
            dbeel_station.the_geom,            
            dbeel_electrofishing.ob_id,
            dbeel_electrofishing.ob_no_origin,
            dbeel_electrofishing.ob_no_type,
            dbeel_electrofishing.ob_no_period,
            dbeel_electrofishing.ob_starting_date,
            dbeel_electrofishing.ob_ending_date,
            dbeel_electrofishing.ob_op_id,
            dbeel_electrofishing.ob_dp_id,
            dbeel_electrofishing.ef_no_fishingmethod,
            dbeel_electrofishing.ef_no_electrofishing_mean,
            dbeel_electrofishing.ef_wetted_area,
            dbeel_electrofishing.ef_fished_length,
            dbeel_electrofishing.ef_fished_width,
            dbeel_electrofishing.ef_duration,
            dbeel_electrofishing.ef_nbpas,
            data_provider.dp_id,
            data_provider.dp_name,
            data_provider.dp_et_id,
            establishment.et_establishment_name
           FROM sudoang.dbeel_station
             JOIN sudoang.dbeel_electrofishing ON dbeel_station.op_id = dbeel_electrofishing.ob_op_id
             JOIN dbeel.data_provider ON data_provider.dp_id = dbeel_electrofishing.ob_dp_id
             JOIN dbeel.establishment on et_id = dp_et_id) ob
     JOIN dbeel_nomenclature.nomenclature o1 ON ob.ob_no_origin = o1.no_id
     JOIN dbeel_nomenclature.nomenclature o2 ON ob.ob_no_type = o2.no_id
     JOIN dbeel_nomenclature.nomenclature o3 ON ob.ob_no_period = o3.no_id
     JOIN dbeel_nomenclature.nomenclature o4 ON ob.ef_no_fishingmethod = o4.no_id
     JOIN dbeel_nomenclature.nomenclature o5 ON ob.ef_no_electrofishing_mean = o5.no_id
     LEFT JOIN ( SELECT ba.ba_ob_id,
            ba.ba_quantity,
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
          WHERE ba.ba_species::text = 'Anguilla anguilla'::text 
          AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text) 
          AND ba.ba_biological_characteristic_type::text = 'Density'::text) ba1 ON ba1.ba_ob_id = ob.ob_id
     LEFT JOIN ( SELECT ba.ba_ob_id,
            ba.ba_quantity,
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
          WHERE ba.ba_species::text = 'Anguilla anguilla'::text 
          AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text)
          AND ba.ba_biological_characteristic_type::text = 'Number'::text AND ba.ba_batch_level = 1) ba2 ON ba2.ba_ob_id = ob.ob_id
     LEFT JOIN ( SELECT ba.ba_ob_id,
            ba.ba_quantity,
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
          WHERE ba.ba_species::text = 'Anguilla anguilla'::text 
          AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text) 
          AND ba.ba_biological_characteristic_type::text = 'Number p1'::text) ba3 ON ba3.ba_ob_id = ob.ob_id
     LEFT JOIN ( SELECT ba.ba_ob_id,
            ba.ba_quantity,
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
          WHERE ba.ba_species::text = 'Anguilla anguilla'::text 
          AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text) 
          AND ba.ba_biological_characteristic_type::text = 'Number p2'::text) ba4 ON ba4.ba_ob_id = ob.ob_id
     LEFT JOIN ( SELECT ba.ba_ob_id,
            ba.ba_quantity,
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
          WHERE ba.ba_species::text = 'Anguilla anguilla'::text 
          AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text) 
          AND ba.ba_biological_characteristic_type::text = 'Number p3'::text) ba5 ON ba5.ba_ob_id = ob.ob_id
     LEFT JOIN ( SELECT dbeel_electrofishing.ob_id,
            count(*) AS count
           FROM sudoang.dbeel_electrofishing
             JOIN sudoang.dbeel_batch_fish ON dbeel_electrofishing.ob_id = dbeel_batch_fish.ba_ob_id
             JOIN sudoang.dbeel_mensurationindiv_biol_charac ON bc_ba_id=ba_id
          WHERE dbeel_mensurationindiv_biol_charac.bc_no_characteristic_type = 39
          GROUP BY dbeel_electrofishing.ob_id) bc 
          ON bc.ob_id = ob.ob_id;

ALTER TABLE sudoang.view_electrofishing
  OWNER TO postgres;

--SELECT * FROM sudoang.view_electrofishing limit 10;
/*
create a temp view
*/
DROP MATERIALIZED VIEW IF EXISTS sudoang.view_electrofishing_frozen;
create materialized VIEW sudoang.view_electrofishing_frozen as select * from sudoang.view_electrofishing; --8013



Create index view_electrofishing_frozenidxid on sudoang.view_electrofishing_frozen 
  USING btree
  (id);


CREATE INDEX view_electrofishing_frozen_ixthegeom
  ON sudoang.view_electrofishing_frozen 
  USING gist
  (the_geom);


-- select * FROM sudoang.view_electrofishing_frozen
-- select * from sudoang.view_electrofishing
