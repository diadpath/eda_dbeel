-- script correcting bc_data_type
update dbeel_nomenclature.biological_characteristic_type set bc_data_type='Integer' where no_name='Number';
insert into dbeel_nomenclature.biological_characteristic_type (no_type,no_name,bc_label,  bc_unit ,  bc_data_type) values
('Biological characteristic type','Number p1','Number in the first pass','Dimensionless','Integer');
insert into dbeel_nomenclature.biological_characteristic_type (no_type,no_name,bc_label,  bc_unit ,  bc_data_type) values
('Biological characteristic type','Number p2','Number in the second pass','Dimensionless','Integer');
insert into dbeel_nomenclature.biological_characteristic_type (no_type,no_name,bc_label,  bc_unit ,  bc_data_type) values
('Biological characteristic type','Number p3','Number in the 3rd pass','Dimensionless','Integer');
insert into dbeel_nomenclature.biological_characteristic_type (no_type,no_name,bc_label,  bc_unit ,  bc_data_type) values
('Biological characteristic type','Number p4','Number in the 4th pass','Dimensionless','Integer');
insert into dbeel_nomenclature.biological_characteristic_type (no_type,no_name,bc_label,  bc_unit ,  bc_data_type) values
('Biological characteristic type','Number p5','Number in the 5th pass','Dimensionless','Integer');

select * from dbeel_nomenclature.nomenclature order by no_type,no_id;