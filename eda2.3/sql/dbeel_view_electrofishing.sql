DROP VIEW IF EXISTS dbeel.view_electrofishing CASCADE;
CREATE OR REPLACE VIEW dbeel.view_electrofishing AS 
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
    ba1.ba_quantity AS density,
    ba2.ba_quantity AS totalnumber,
    ba3.ba_quantity AS nbp1,
    ba4.ba_quantity AS nbp2,
    ba5.ba_quantity AS nbp3,
    bc.count AS nb_size_measured,
    the_geom
    -- select * 
   FROM ( SELECT observation_places.op_id,
            observation_places.op_gis_systemname,
            observation_places.op_gis_layername,
            observation_places.op_gislocation,
            observation_places.op_placename,
            observation_places.op_no_observationplacetype,
            observation_places.op_op_id,
            observation_places.the_geom,            
            electrofishing.ob_id,
            electrofishing.ob_no_origin,
            electrofishing.ob_no_type,
            electrofishing.ob_no_period,
            electrofishing.ob_starting_date,
            electrofishing.ob_ending_date,
            electrofishing.ob_op_id,
            electrofishing.ob_dp_id,
            electrofishing.ef_no_fishingmethod,
            electrofishing.ef_no_electrofishing_mean,
            electrofishing.ef_wetted_area,
            electrofishing.ef_fished_length,
            electrofishing.ef_fished_width,
            electrofishing.ef_duration,
            electrofishing.ef_nbpas,
            data_provider.dp_id,
            data_provider.dp_name,
            data_provider.dp_et_id
           FROM dbeel.observation_places
             JOIN dbeel.electrofishing ON observation_places.op_id = electrofishing.ob_op_id
             JOIN dbeel.data_provider ON data_provider.dp_id = electrofishing.ob_dp_id) ob
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
           FROM ( SELECT batch.ba_ob_id,
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
                     JOIN dbeel_nomenclature.nomenclature b5 ON batch.ba_no_individual_status = b5.no_id) ba
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
           FROM ( SELECT batch.ba_ob_id,
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
                     JOIN dbeel_nomenclature.nomenclature b5 ON batch.ba_no_individual_status = b5.no_id) ba
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
           FROM ( SELECT batch.ba_ob_id,
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
                     JOIN dbeel_nomenclature.nomenclature b5 ON batch.ba_no_individual_status = b5.no_id) ba
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
           FROM ( SELECT batch.ba_ob_id,
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
                     JOIN dbeel_nomenclature.nomenclature b5 ON batch.ba_no_individual_status = b5.no_id) ba
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
           FROM ( SELECT batch.ba_ob_id,
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
                     JOIN dbeel_nomenclature.nomenclature b5 ON batch.ba_no_individual_status = b5.no_id) ba
          WHERE ba.ba_species::text = 'Anguilla anguilla'::text 
          AND (ba.ba_stage::text = 'Yellow eel'::text OR ba.ba_stage::text = 'Yellow & silver eel mixed'::text OR ba.ba_stage::text = 'G, Y & S eel mixed'::text) 
          AND ba.ba_biological_characteristic_type::text = 'Number p3'::text) ba5 ON ba5.ba_ob_id = ob.ob_id
     LEFT JOIN ( SELECT electrofishing.ob_id,
            count(*) AS count
           FROM dbeel.electrofishing
             JOIN dbeel.batch ON electrofishing.ob_id = batch.ba_ob_id
             JOIN dbeel.biological_characteristic ON biological_characteristic.bc_ba_id = batch.ba_id
          WHERE biological_characteristic.bc_no_characteristic_type = 39
          GROUP BY electrofishing.ob_id) bc 
          ON bc.ob_id = ob.ob_id;

ALTER TABLE dbeel.view_electrofishing
  OWNER TO postgres;



/*
create a temp view
*/
/*
 
DROP MATERIALIZED VIEW  dbeel.view_electrofishing_frozen;
create materialized VIEW dbeel.view_electrofishing_frozen as select * from dbeel.view_electrofishing; --8013


Create index view_electrofishing_frozenidxid on dbeel.view_electrofishing_frozen 
  USING btree
  (id);

-- Index: spain.rn_geom_ix

-- DROP INDEX spain.rn_geom_ix;

CREATE INDEX view_electrofishing_frozen_ixthegeom
  ON dbeel.view_electrofishing_frozen 
  USING gist
  (the_geom);

*/
 
 
 

