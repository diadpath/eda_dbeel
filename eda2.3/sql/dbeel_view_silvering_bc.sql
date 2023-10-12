-- dbeel.view_silvering_bc source

CREATE OR REPLACE VIEW dbeel.view_silvering_bc
AS 
--this select is the result of a crosstab() function defined thereafter.
--505340 lines
SELECT crosstab.ba_id,--id of fish measured
    crosstab.length,
    crosstab.weight,
    crosstab.sex,
    crosstab.stage,
    crosstab.eye_diam_vert,
    crosstab.eye_diam_horiz,
    crosstab.length_pect,
    crosstab.presence_neuromast,
    crosstab.contrast
   FROM crosstab(
   --first we define the "source" select returning the list of records to be "crosstabed"
   --the element defining the crosstab are :
   --key : ba_id = the fish measured
   --categories : biological_characteristic_type.no_name = the type of measurement (weight, length, sex, etc...)
   --values : bc_numvalue
   --748650 measures, on 2023/10/16
	'SELECT b.ba_id, bct.no_name, bc.bc_numvalue 
					FROM dbeel.batch b
					join dbeel.electrofishing e on e.ob_id = b.ba_ob_id
					join dbeel.observation_places op on op.op_id = e.ob_op_id and op.op_gis_layername in (''ASPE'', ''RSA'')
					JOIN dbeel.biological_characteristic bc ON bc_ba_id=b.ba_id
					-- nomenclature table
					JOIN dbeel_nomenclature.biological_characteristic_type bct ON bc.bc_no_characteristic_type = bct.no_id
					where b.ba_batch_level=2 --only fishes
					and bct.no_name in (''Length'',
							''Weight'',
							''Sex'',
							''Stage'',
							''eye_diam_vert'',
							''eye_diam_horiz'',
							''length_pect'',
							''presence_neuromast'',
							''contrast'')
					ORDER by 1,2'::text, 
	--the we defined the "category" select 
	--these are the type of measurements value listed in dbeel_nomenclature.biological_characteristic_type
					'SELECT * FROM (VALUES 
							(''Length''),
							(''Weight''),
							(''Sex''),
							(''Stage''),
							(''eye_diam_vert''),
							(''eye_diam_horiz''),
							(''length_pect''),
							(''presence_neuromast''),
							(''contrast'')
							)  AS t (no_name)'::text
				) 
	--finally we define the column names of the crosstab and their datatypes
	as crosstab(
		ba_id uuid, 
		length numeric, 
		weight numeric, 
		sex numeric, 
		stage numeric, 
		eye_diam_vert numeric, 
		eye_diam_horiz numeric, 
		length_pect numeric, 
		presence_neuromast numeric, 
		contrast numeric);
	
	
-- Permissions

ALTER TABLE dbeel.view_silvering_bc OWNER TO postgres;
GRANT ALL ON TABLE dbeel.view_silvering_bc TO postgres;
GRANT SELECT ON TABLE dbeel.view_silvering_bc TO dbeel;