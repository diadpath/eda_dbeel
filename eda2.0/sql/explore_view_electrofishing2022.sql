-- select specific examples from view_electrofishing
select 
	op_gis_layername,
	op_placename,
	ob_starting_date,
	ob_id,
	ef_nbpas,
	ef_fishingmethod,
	ob_dp_name,
	totalnumber,
	nbp1,
	nbp2,
	nbp3
	from dbeel.view_electrofishing
	where ef_fishingmethod = 'Whole' and (op_placename = 'Fane|Fane River|EPA16' or op_placename = 'Dunneill|Dunneill River|Donaghintraine Br._A' or
	(op_placename = 'Burrishoole|Goulaun|Goul' and ob_starting_date = '2013-08-12'));
	

  
  
  

/*
 * |op_gis_layername|op_placename                                |
|----------------|--------------------------------------------|
|MI              |Burrishoole|Goulaun|Goul                    |
|WFD             |Dunneill|Dunneill River|Donaghintraine Br._A|
|IFI             |Fane|Fane River|EPA16                       |

|nbp1|nbp2|nbp3|
|----|----|----|
|3   |7   |0   |
|30  |17  |64  |
|12  |5   |5   |
*/
SELECT * FROM dbeel.view_electrofishing WHERE op_gis_layername IN ('MI', 'WFD', 'IFI')

	
-- select from survey files
select * from ireland.eel_ifi_survey as ifi
	where "Site" = 'EPA16' and "Date" = '2013-07-09';
	
	/*
|Fishing1|Fishing2|Fishing3|Fishing4|Fishing5|Totaleel|
|--------|--------|--------|--------|--------|--------|
|12      |5       |5       |        |        |22      |
OK
*/
	 */

select * from ireland.eel_wfd_survey as wfd
	where "Site" = 'Donaghintraine Br._A';
	
/*
|Fishing1|Fishing2|Fishing3|Fishing4|Fishing5|Totaleel|
|--------|--------|--------|--------|--------|--------|
|        |        |        |        |        |64      |
This one has no values, how comes we have some in the table where do they come from ?
*/
	
SELECT *  FROM 
  ireland.eel_wfd_survey JOIN
  ireland.wfd_count ON  "Samplingcode"= samplingcode	
  where "Site" = 'Donaghintraine Br._A';
/*	
|pass_number|n  |
|-----------|---|
|1          |30 |
|2          |17 |
|3          |17 |
*/
-- So eel_wfd_survey does not contain the information on the number per pass only wfd_count



	-- samplingcode WFD12R_35D060200A_a
	


select * from ireland.eel_mi_survey as mi
	where ("SiteCode" ilike 'Goul%' and "Date" = '2013-08-12' and ob_id = '71357cd8-6687-4bb5-9b28-fe18392240a6');
	
/*
 * |Fishing1|Fishing2|Fishing3|Fishing4|Fishing5|Totaleel|
|--------|--------|--------|--------|--------|--------|
|3       |7       |0       |        |        |10      |

*/
	
	
/* 
 * 
 * I don't know if you have the same problem as me, it is only WFD data am I right or do you have something different ?
 * Trying to puzzle out what the problem is :
 * 
 */

	
select * from ireland.eel_wfd_survey as wfd
  where "Site" ilike '%donaghintraine Br%'; -- ILIKE takes upper OR lowercase => just one line 2012-07-16

  
  
select *  
  from dbeel.view_electrofishing
  where  op_placename ILIKE '%donaghintraine%'; -- it's the same so there IS NO confusion OF operation
  

 SELECT * FROM ireland.batch_ope bo WHERE ba_ob_id='783332ad-95de-4430-80af-49cd6d21d28b';
 
 /*
 |ba_id                               |ba_no_species|ba_no_stage|ba_no_value_type|ba_no_biological_characteristic_type|ba_quantity|ba_no_individual_status|ba_batch_level|ba_ob_id                            |ba_ba_id|op_locationcode|op_surveyid|op_nb|pa_numero|samplingcode       |datasource|
|------------------------------------|-------------|-----------|----------------|------------------------------------|-----------|-----------------------|--------------|------------------------------------|--------|---------------|-----------|-----|---------|-------------------|----------|
|ceb0147b-f648-478a-9196-b7901a42f85a|30           |226        |55              |233                                 |64         |49                     |3             |783332ad-95de-4430-80af-49cd6d21d28b|        |35D060200A     |1 091      |17   |         |WFD12R_35D060200A_a|WFD       |
|da9ec628-015d-4f5e-8bd7-fbb0055b6f01|30           |226        |55              |47                                  |64         |49                     |0             |783332ad-95de-4430-80af-49cd6d21d28b|        |35D060200A     |1 091      |64   |         |WFD12R_35D060200A_a|WFD       |
|55bf3c1f-7e6d-4105-8756-7a12c0502d5a|30           |226        |55              |232                                 |17         |49                     |2             |783332ad-95de-4430-80af-49cd6d21d28b|        |35D060200A     |1 091      |17   |         |WFD12R_35D060200A_a|WFD       |
|8995ae7f-693d-4c7c-a350-9616be3835a8|30           |226        |55              |231                                 |30         |49                     |1             |783332ad-95de-4430-80af-49cd6d21d28b|        |35D060200A     |1 091      |30   |         |WFD12R_35D060200A_a|WFD       |
*/
 
 
 -- OK this is strange, where do 30 17 64 come from ?
 
 -- op_p1 comes from there 
SELECT batch_ope.*, e.* FROM ireland.batch_ope
JOIN ireland.electrofishing AS e ON e.ob_id=batch_ope.ba_ob_id
JOIN dbeel_nomenclature.biological_characteristic_type bct ON bct.no_id=ba_no_biological_characteristic_type
WHERE bct.no_name='Number p1'
AND op_nb != ba_quantity; -- No differrence


SELECT batch_ope.*, e.* FROM ireland.batch_ope
JOIN ireland.electrofishing AS e ON e.ob_id=batch_ope.ba_ob_id
JOIN dbeel_nomenclature.biological_characteristic_type bct ON bct.no_id=ba_no_biological_characteristic_type
WHERE bct.no_name='Number p2'
AND op_nb != ba_quantity; -- NO difference

SELECT batch_ope.* FROM ireland.batch_ope
JOIN dbeel_nomenclature.biological_characteristic_type bct ON bct.no_id=ba_no_biological_characteristic_type
WHERE bct.no_name='Number p3'
AND op_nb != ba_quantity;--171 lines
-- wrong for WFD 

-- I've identified the errors in the script

 