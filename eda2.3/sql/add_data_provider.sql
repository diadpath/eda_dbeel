INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('min esp'); --TODO: TO BE MODIFIED spanish minstry
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Belen', et_id FROM dbeel.establishment WHERE et_establishment_name = 'min esp'
; --TODO: TO BE MODIFIED


INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('AMBER Project'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Rosa', et_id FROM dbeel.establishment WHERE et_establishment_name = 'AMBER Project'
; --TODO: TO BE MODIFIED