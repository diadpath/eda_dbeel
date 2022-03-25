drop view if exists dbeel.view_electrofishing;
create view dbeel.view_electrofishing as(
select 
ob.op_id,
op_gis_layername,
op_placename,
ob.ob_id,
ob_starting_date,
ef_wetted_area,
ef_nbpas,
ef_fished_length,
ef_fished_width,
o1.no_name as ob_origin,
o2.no_name as ob_type,
o3.no_name as ob_period,
o4.no_name as ef_fishingmethod,
o5.no_name as ef_electrofishing_mean,
ob.dp_name as ob_dp_name,
ba1.ba_quantity as density,
ba2.ba_quantity as totalnumber,
ba3.ba_quantity as nbp1,
ba4.ba_quantity as nbp2,
ba5.ba_quantity as nbp3,
bc.count as nb_size_measured
from (select * from dbeel.observation_places join dbeel.electrofishing on op_id=ob_op_id
join dbeel.data_provider on dp_id=ob_dp_id
) as ob
join dbeel_nomenclature.nomenclature o1 on ob_no_origin=o1.no_id
join dbeel_nomenclature.nomenclature o2 on ob_no_type=o2.no_id
join dbeel_nomenclature.nomenclature o3 on ob_no_period=o3.no_id
join dbeel_nomenclature.nomenclature o4 on ef_no_fishingmethod=o4.no_id
join dbeel_nomenclature.nomenclature o5 on ef_no_electrofishing_mean=o5.no_id
left join (	select * from (
		select
		ba_ob_id,
		ba_quantity,
		ba_batch_level,
		b1.no_name as ba_species,
		b2.no_name as ba_stage,
		b3.no_name as ba_value_type,
		b4.no_name as ba_biological_characteristic_type,
		b5.no_name as ba_individual_status
		from dbeel.batch 
		join dbeel_nomenclature.nomenclature b1 on ba_no_species=b1.no_id
		join dbeel_nomenclature.nomenclature b2 on ba_no_stage=b2.no_id
		join dbeel_nomenclature.nomenclature b3 on ba_no_value_type=b3.no_id
		join dbeel_nomenclature.nomenclature b4 on ba_no_biological_characteristic_type=b4.no_id
		join dbeel_nomenclature.nomenclature b5 on ba_no_individual_status=b5.no_id) as ba
	where ba_species='Anguilla anguilla'
	and (ba_stage='Yellow eel' OR ba_stage='Yellow & silver eel mixed' OR ba_stage='G, Y & S eel mixed')
	and ba_biological_characteristic_type='Density' 
	) as ba1 on ba1.ba_ob_id=ob_id
left join (	select * from (
		select
		ba_ob_id,
		ba_quantity,
		ba_batch_level,
		b1.no_name as ba_species,
		b2.no_name as ba_stage,
		b3.no_name as ba_value_type,
		b4.no_name as ba_biological_characteristic_type,
		b5.no_name as ba_individual_status
		from dbeel.batch 
		join dbeel_nomenclature.nomenclature b1 on ba_no_species=b1.no_id
		join dbeel_nomenclature.nomenclature b2 on ba_no_stage=b2.no_id
		join dbeel_nomenclature.nomenclature b3 on ba_no_value_type=b3.no_id
		join dbeel_nomenclature.nomenclature b4 on ba_no_biological_characteristic_type=b4.no_id
		join dbeel_nomenclature.nomenclature b5 on ba_no_individual_status=b5.no_id) as ba
	where ba_species='Anguilla anguilla'
	and (ba_stage='Yellow eel' OR ba_stage='Yellow & silver eel mixed' OR ba_stage='G, Y & S eel mixed')
	and ba_biological_characteristic_type='Number'  
	and ba_batch_level=1
	) as ba2 on ba2.ba_ob_id=ob_id
left join (	select * from (
		select
		ba_ob_id,
		ba_quantity,
		ba_batch_level,
		b1.no_name as ba_species,
		b2.no_name as ba_stage,
		b3.no_name as ba_value_type,
		b4.no_name as ba_biological_characteristic_type,
		b5.no_name as ba_individual_status
		from dbeel.batch 
		join dbeel_nomenclature.nomenclature b1 on ba_no_species=b1.no_id
		join dbeel_nomenclature.nomenclature b2 on ba_no_stage=b2.no_id
		join dbeel_nomenclature.nomenclature b3 on ba_no_value_type=b3.no_id
		join dbeel_nomenclature.nomenclature b4 on ba_no_biological_characteristic_type=b4.no_id
		join dbeel_nomenclature.nomenclature b5 on ba_no_individual_status=b5.no_id) as ba
	where ba_species='Anguilla anguilla'
	and (ba_stage='Yellow eel' OR ba_stage='Yellow & silver eel mixed' OR ba_stage='G, Y & S eel mixed')
	and ba_biological_characteristic_type='Number p1' 
	) as ba3 on ba3.ba_ob_id=ob_id
left join (	select * from (
		select
		ba_ob_id,
		ba_quantity,
		ba_batch_level,
		b1.no_name as ba_species,
		b2.no_name as ba_stage,
		b3.no_name as ba_value_type,
		b4.no_name as ba_biological_characteristic_type,
		b5.no_name as ba_individual_status
		from dbeel.batch 
		join dbeel_nomenclature.nomenclature b1 on ba_no_species=b1.no_id
		join dbeel_nomenclature.nomenclature b2 on ba_no_stage=b2.no_id
		join dbeel_nomenclature.nomenclature b3 on ba_no_value_type=b3.no_id
		join dbeel_nomenclature.nomenclature b4 on ba_no_biological_characteristic_type=b4.no_id
		join dbeel_nomenclature.nomenclature b5 on ba_no_individual_status=b5.no_id) as ba
	where ba_species='Anguilla anguilla'
	and (ba_stage='Yellow eel' OR ba_stage='Yellow & silver eel mixed' OR ba_stage='G, Y & S eel mixed')
	and ba_biological_characteristic_type='Number p2'
	) as ba4 on ba4.ba_ob_id=ob_id
left join (	select * from (
		select
		ba_ob_id,
		ba_quantity,
		ba_batch_level,
		b1.no_name as ba_species,
		b2.no_name as ba_stage,
		b3.no_name as ba_value_type,
		b4.no_name as ba_biological_characteristic_type,
		b5.no_name as ba_individual_status
		from dbeel.batch 
		join dbeel_nomenclature.nomenclature b1 on ba_no_species=b1.no_id
		join dbeel_nomenclature.nomenclature b2 on ba_no_stage=b2.no_id
		join dbeel_nomenclature.nomenclature b3 on ba_no_value_type=b3.no_id
		join dbeel_nomenclature.nomenclature b4 on ba_no_biological_characteristic_type=b4.no_id
		join dbeel_nomenclature.nomenclature b5 on ba_no_individual_status=b5.no_id) as ba
	where ba_species='Anguilla anguilla'
	and (ba_stage='Yellow eel' OR ba_stage='Yellow & silver eel mixed' OR ba_stage='G, Y & S eel mixed')
	and ba_biological_characteristic_type='Number p3' 
	) as ba5 on ba5.ba_ob_id=ob_id
-- below counting number in biological characteristic
left join (select ob_id,count(*) from 
	dbeel.electrofishing join 
	dbeel.batch on ob_id=ba_ob_id join
	dbeel.biological_characteristic on bc_ba_id=ba_id
	where bc_no_characteristic_type=39 --length
	group by ob_id) as bc on bc.ob_id=ob.ob_id
where o1.no_name ='Raw data')


SELECT * FROM dbeel.view_electrofishing;
SELECT count(*) FROM ireland.electrofishing