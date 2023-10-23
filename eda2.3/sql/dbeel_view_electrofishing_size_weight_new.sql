DROP VIEW IF EXISTS dbeel.view_electrofishing_size_weight_new CASCADE;
CREATE OR REPLACE VIEW  dbeel.view_electrofishing_size_weight_new AS (
--505339 records on  16/10
--505288 records on 16/10 with ]50,1400[ filter
select 
dp.dp_name,																										--provider name
e.ob_id,																										--operation id
bc.bc_id,																										--biological characteristic id (for length only)
bc.bc_ba_id,																									--eel id from dbeel.batch
null as fish_id,																								--no fish_id in ASPE/RSA, bc_ba_id sufficient ?
bc.bc_numvalue as length,																						--length
bc2.bc_numvalue as weight																						--weight
from dbeel.observation_places op 
join dbeel.electrofishing e on e.ob_op_id = op.op_id 
join dbeel.batch b on b.ba_ob_id = e.ob_id and b.ba_batch_level = 2												--to retrieve only fish-level data
join dbeel.data_provider dp on dp.dp_id = e.ob_dp_id 
--this query retrieve only eels with at least length measurement (inner join)
--weight measurement is not mandatory (left join)
join dbeel.biological_characteristic bc on bc.bc_ba_id = b.ba_id and bc.bc_no_characteristic_type = 39			--length measurement			
left join dbeel.biological_characteristic bc2 on bc2.bc_ba_id = b.ba_id and bc2.bc_no_characteristic_type = 42	--weight measurement
where op.op_gis_layername in ('ASPE','RSA')																		--to retrieve only ASPE and RSA data, to be deleted when new dbeel_france scheme 
-- filter on eel size ]50,1400[
-- nb : this filter is not applied in dbeel.view_electrofishing_size_new
and bc.bc_numvalue>50 
AND bc.bc_numvalue<1400 
)
;

ALTER TABLE dbeel.view_electrofishing_size_weight_new OWNER TO postgres;
GRANT ALL ON TABLE dbeel.view_electrofishing_size_weight_new TO postgres;
GRANT SELECT ON TABLE dbeel.view_electrofishing_size_weight_new TO dbeel;    
