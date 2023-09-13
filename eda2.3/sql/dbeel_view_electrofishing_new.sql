--Cette vue a pour objectif de remonter l'ensemble des opérations de pêches réalisées sur des anguilles
--Elle est utilisée par le modèle EDA
--Elle présente le détail des résultats, pour chaque passage, par opérations de pêches
--le détail par poisson n'est pas présenté (il est réalisé dans une autre vue)
--il faut donc un filtre pour ne remonter que les données totaux (en travaillant sur ba_batch_level ou ba_no_biological_characteristic_type)
--durée sur postgres_local : environ 18s (avec 200 lignes remontées)

DROP VIEW IF EXISTS dbeel.view_electrofishing_new CASCADE;
CREATE OR REPLACE VIEW dbeel.view_electrofishing_new AS 
 -- first a sided select to calculate the number of eels measured for each electrofishing
with count_length as (
SELECT el.ob_id,
            count(*) AS nb_meas
           FROM dbeel.electrofishing el
           	 join dbeel.observation_places opl on opl.op_id = el.ob_op_id  
             JOIN dbeel.batch ba ON el.ob_id = ba.ba_ob_id
             JOIN dbeel.biological_characteristic bchar ON bchar.bc_ba_id = ba.ba_id
          WHERE bchar.bc_no_characteristic_type = 39
          and opl.op_gis_layername in ('ASPE','RSA')--to limit the number of electrofishing in the select		
          GROUP BY el.ob_id)
--then the main query
SELECT row_number() OVER() AS "id",
    op.op_id,								--station id
    op.op_gis_layername,					--station source (ex : ASPE, RSA, ...)
    op.op_placename,						--station label	
    e.ob_id,								--operation id
    e.ob_starting_date,						--operation date
    e.ef_wetted_area,						--electrofished area (length * width)
    e.ef_nbpas,								--number of passes
    e.ef_fished_length,						--electrofished length
    e.ef_fished_width,						--electrofished width
    dp.dp_name AS ob_dp_name,				--data provider name
    n1.no_name AS ob_origin,				--origin of data (label from dbeel_nomenclature.nomenclature)
    n2.no_name AS ob_type,					--type of operation (label from dbeel_nomenclature.nomenclature)
    n3.no_name AS ob_period,				--periodicity of operation (label from dbeel_nomenclature.nomenclature)
    n4.no_name AS ef_fishingmethod,			--method of electrofishing (label from dbeel_nomenclature.nomenclature)
    n5.no_name AS ef_electrofishing_mean,	--mean of electrofishing (label from dbeel_nomenclature.nomenclature)
	ba1.ba_quantity AS density,				--estimated density of eels
    ba2.ba_quantity AS totalnumber,			--captured eels (for all passes)
    ba3.ba_quantity AS nbp1,				--captured eels, 1st pass
    ba4.ba_quantity AS nbp2,				--captured eels, 2nd pass
    ba5.ba_quantity AS nbp3,				--captured eels, 3rd pass
    cl.nb_meas AS nb_size_measured, 		--count of eels measured (size)
    op.the_geom								--station coordinates (geometry)
from dbeel.observation_places op 
join dbeel.electrofishing e on e.ob_op_id = op.op_id 
--data provider
join dbeel.data_provider dp on dp.dp_id = e.ob_dp_id 								
--detailing electrofishing means, method, etc...
left join dbeel_nomenclature.nomenclature n1 on n1.no_id = e.ob_no_origin 				-- to get origin label
left join dbeel_nomenclature.nomenclature n2 on n2.no_id = e.ob_no_type  				-- to get type label
left join dbeel_nomenclature.nomenclature n3 on n3.no_id = e.ob_no_period  				-- to get period label
left join dbeel_nomenclature.nomenclature n4 on n4.no_id = e.ef_no_fishingmethod 		-- to get method label
left join dbeel_nomenclature.nomenclature n5 on n5.no_id = e.ef_no_electrofishing_mean 	-- to get means label
-- getting operations results	
left join dbeel.batch ba1 on ba1.ba_ob_id = e.ob_id and ba1.ba_no_biological_characteristic_type = 48 and ba1.ba_batch_level = 1	-- for density estimate, left join because some operations didn't have a density measure
left join dbeel.batch ba2 on ba2.ba_ob_id = e.ob_id and ba2.ba_no_biological_characteristic_type = 47 and ba2.ba_batch_level = 1 	-- for total catches, is left join necessary ? every op should have a total number
left join dbeel.batch ba3 on ba3.ba_ob_id = e.ob_id and ba3.ba_no_biological_characteristic_type = 231 and ba3.ba_batch_level = 1 	-- for 1st pass catches, is left join necessary ? every of should have a 1st pass1
left join dbeel.batch ba4 on ba4.ba_ob_id = e.ob_id and ba4.ba_no_biological_characteristic_type = 232 and ba4.ba_batch_level = 1 	-- for 2nd pass catches, left join necessary
left join dbeel.batch ba5 on ba5.ba_ob_id = e.ob_id and ba5.ba_no_biological_characteristic_type = 234 and ba5.ba_batch_level = 1	-- for 3rd pass catches, left join necessary 
-- getting count of length measured
left join count_length cl on cl.ob_id = e.ob_id 
--to be replaced when France data would be stored in dbeel_france scheme
where op.op_gis_layername in ('ASPE','RSA');											

ALTER TABLE dbeel.view_electrofishing_new
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
 
 
 

