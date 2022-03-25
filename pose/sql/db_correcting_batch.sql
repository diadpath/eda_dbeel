/*
this script corrects the batch created to integrate the new nomenclature
*/
update wrbd.batch_ope 
	set ba_no_biological_characteristic_type=231 --Number p1
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=1;
update wrbd.batch_ope 
	set ba_no_biological_characteristic_type=232 --Number p2
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=2;	
update wrbd.batch_ope 
	set ba_no_biological_characteristic_type=233 --Number p3
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=3;--978
update wrbd.batch_ope 
	set ba_no_biological_characteristic_type=234 --Number p4
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=4;
update wrbd.batch_ope 
	set ba_no_biological_characteristic_type=235 --Number p5
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=5;

update oria.batch_ope 
	set ba_no_biological_characteristic_type=231 --Number p1
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=1;
update oria.batch_ope 
	set ba_no_biological_characteristic_type=232 --Number p2
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=2;	
update oria.batch_ope 
	set ba_no_biological_characteristic_type=233 --Number p3
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=3;


update onema.passtaxon_onema 
	set ba_no_biological_characteristic_type=231 --Number p1
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=1;--5960
update onema.passtaxon_onema 
	set ba_no_biological_characteristic_type=232 --Number p2
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=2;--3241	
update onema.passtaxon_onema
	set ba_no_biological_characteristic_type=233 --Number p3
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=3;--47
update onema.passtaxon_onema 
	set ba_no_biological_characteristic_type=234 --Number p4
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=4;--1
update onema.passtaxon_onema 
	set ba_no_biological_characteristic_type=235 --Number p5
	where ba_no_biological_characteristic_type=47 -- Number
	and ba_batch_level=2
	and pa_numero=5; --0


