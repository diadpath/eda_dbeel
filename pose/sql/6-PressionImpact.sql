-----------------------------------
-- Create ecological_status table
-----------------------------------
DROP TABLE if exists "dbeel".ecological_status CASCADE;
CREATE TABLE "dbeel".ecological_status (
	es_no_statusclass integer,
	CONSTRAINT ecological_status_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
ALTER TABLE "dbeel".ecological_status ADD CONSTRAINT fk_es_statusclass
	FOREIGN KEY (es_no_statusclass)
	REFERENCES "dbeel_nomenclature".ecological_status_class (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".ecological_status ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".ecological_status ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".ecological_status ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".ecological_status ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_ecological_status_Insert ON "dbeel".ecological_status;
CREATE TRIGGER TR_ecological_status_Insert BEFORE INSERT ON "dbeel".ecological_status
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_ecological_status_Update ON "dbeel".ecological_status;
CREATE TRIGGER TR_ecological_status_Update BEFORE UPDATE ON "dbeel".ecological_status
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".ecological_status;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".ecological_status
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".ecological_status;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".ecological_status
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Habitat loss table
------------------------------------------------
DROP TABLE if exists "dbeel".habitat_loss CASCADE;
CREATE TABLE "dbeel".habitat_loss (
	el_no_hahitat_losstype integer,
	el_no_unity_type integer,
	el_value real,
	CONSTRAINT habitat_loss_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Create foreign key
ALTER TABLE "dbeel".habitat_loss ADD CONSTRAINT fk_el_habitat_losstype
	FOREIGN KEY (el_no_hahitat_losstype)
	REFERENCES "dbeel_nomenclature".habitat_loss_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".habitat_loss ADD CONSTRAINT fk_el_unity_type
	FOREIGN KEY (el_no_unity_type)
	REFERENCES "dbeel_nomenclature".type_of_unit (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".habitat_loss ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".habitat_loss ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".habitat_loss ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".habitat_loss ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_habitat_loss_Insert ON "dbeel".habitat_loss;
CREATE TRIGGER TR_habitat_loss_Insert BEFORE INSERT ON "dbeel".habitat_loss
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_habitat_loss_Update ON "dbeel".habitat_loss;
CREATE TRIGGER TR_habitat_loss_Update BEFORE UPDATE ON "dbeel".habitat_loss
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".habitat_loss;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".habitat_loss
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".habitat_loss;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".habitat_loss
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
----------------------------------
-- Create Stocking table
-----------------------------------
DROP TABLE if exists "dbeel".stocking CASCADE;
CREATE TABLE "dbeel".stocking (
	st_mortality_rate real,
	st_population_origin varchar(60),
	CONSTRAINT stocking_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
ALTER TABLE "dbeel".stocking ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".stocking ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".stocking ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".stocking ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_stocking_Insert ON "dbeel".stocking;
CREATE TRIGGER TR_stocking_Insert BEFORE INSERT ON "dbeel".stocking
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_stocking_Update ON "dbeel".stocking;
CREATE TRIGGER TR_stocking_Update BEFORE UPDATE ON "dbeel".stocking
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".stocking;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".stocking
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".stocking;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".stocking
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Predation table
------------------------------------------------
DROP TABLE if exists "dbeel".predation CASCADE;
CREATE TABLE "dbeel".predation (
	pr_no_predation_type integer,		
	pr_predator_number integer,
	pr_no_effort_unit integer,
	pr_effort_value real,
	pr_maxumin_length real,
	pr_minimum_length real,
--	pr_selectivity_param1 real,
--	pr_selectivity_param2 real
	CONSTRAINT predation_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Create foreign key
ALTER TABLE "dbeel".predation ADD CONSTRAINT fk_pr_effort_unit
	FOREIGN KEY (pr_no_effort_unit)
	REFERENCES "dbeel_nomenclature".effort_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".predation ADD CONSTRAINT fk_pr_predation_type
	FOREIGN KEY (pr_no_predation_type)
	REFERENCES "dbeel_nomenclature".predation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".predation ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".predation ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".predation ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".predation ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_predation_Insert ON "dbeel".predation;
CREATE TRIGGER TR_predation_Insert BEFORE INSERT ON "dbeel".predation
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_predation_Update ON "dbeel".predation;
CREATE TRIGGER TR_predation_Update BEFORE UPDATE ON "dbeel".predation
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".predation;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".predation
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".predation;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".predation
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create fishery table
------------------------------------------------
DROP TABLE if exists "dbeel".fishery CASCADE;
CREATE TABLE "dbeel".fishery (		
	fi_no_fisher_type integer,
	fi_no_geartype integer,
	CONSTRAINT fishery_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".predation);
-- Create foreign key
ALTER TABLE "dbeel".fishery ADD CONSTRAINT fk_fi_fisher_type
	FOREIGN KEY (fi_no_fisher_type)
	REFERENCES "dbeel_nomenclature".fisher_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;	
ALTER TABLE "dbeel".fishery ADD CONSTRAINT fk_fi_geartype
	FOREIGN KEY (fi_no_geartype)
	REFERENCES "dbeel_nomenclature".gear_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".fishery ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".fishery ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".fishery ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".fishery ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_fishery_Insert ON "dbeel".fishery;
CREATE TRIGGER TR_fishery_Insert BEFORE INSERT ON "dbeel".fishery
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_fishery_Update ON "dbeel".fishery;
CREATE TRIGGER TR_fishery_Update BEFORE UPDATE ON "dbeel".fishery
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".fishery;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".fishery
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".fishery;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".fishery
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Wildlife table
------------------------------------------------
DROP TABLE if exists "dbeel".wildlife CASCADE;
CREATE TABLE "dbeel".wildlife (		
	wi_no_species integer,
	CONSTRAINT wildlife_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".predation);
-- Create foreign key
ALTER TABLE "dbeel".wildlife ADD CONSTRAINT fk_wi_species
	FOREIGN KEY (wi_no_species)
	REFERENCES "dbeel_nomenclature".species  (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".wildlife ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".wildlife ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".wildlife ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".wildlife ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_wildlife_Insert ON "dbeel".wildlife;
CREATE TRIGGER TR_wildlife_Insert BEFORE INSERT ON "dbeel".wildlife
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_wildlife_Update ON "dbeel".wildlife;
CREATE TRIGGER TR_wildlife_Update BEFORE UPDATE ON "dbeel".wildlife
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".wildlife;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".wildlife
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".wildlife;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".wildlife
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Obstruction table
------------------------------------------------
DROP TABLE if exists "dbeel".obstruction CASCADE;
CREATE TABLE "dbeel".obstruction (
	ot_no_obstruction_type integer,		
	ot_obstruction_number integer,
	ot_no_mortality_type integer,
	ot_no_mortality real,
	CONSTRAINT obstruction_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Create foreign key
ALTER TABLE "dbeel".obstruction ADD CONSTRAINT fk_ot_mortality_type
	FOREIGN KEY (ot_no_mortality_type)
	REFERENCES "dbeel_nomenclature".biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".obstruction ADD CONSTRAINT fk_ot_obstruction_type
	FOREIGN KEY (ot_no_obstruction_type)
	REFERENCES "dbeel_nomenclature".obstruction_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".obstruction ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".obstruction ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".obstruction ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".obstruction ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_obstruction_Insert ON "dbeel".obstruction;
CREATE TRIGGER TR_obstruction_Insert BEFORE INSERT ON "dbeel".obstruction
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_obstruction_Update ON "dbeel".obstruction;
CREATE TRIGGER TR_obstruction_Update BEFORE UPDATE ON "dbeel".obstruction
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".obstruction;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".obstruction
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".obstruction;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".obstruction
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Physical Obstruction table
------------------------------------------------
DROP TABLE if exists "dbeel".physical_obstruction CASCADE;
CREATE TABLE "dbeel".physical_obstruction (
	po_no_obstruction_passability integer,
	po_obstruction_height real,
	po_turbine_number integer,
	CONSTRAINT physical_obstruction_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".obstruction);
-- Create foreign key
ALTER TABLE "dbeel".physical_obstruction ADD CONSTRAINT fk_po_obstruction_passability
	FOREIGN KEY (po_no_obstruction_passability)
	REFERENCES "dbeel_nomenclature".obstruction_impact (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".physical_obstruction ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".physical_obstruction ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".physical_obstruction ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".physical_obstruction ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_physical_obstruction_Insert ON "dbeel".physical_obstruction;
CREATE TRIGGER TR_physical_obstruction_Insert BEFORE INSERT ON "dbeel".physical_obstruction
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_physical_obstruction_Update ON "dbeel".physical_obstruction;
CREATE TRIGGER TR_physical_obstruction_Update BEFORE UPDATE ON "dbeel".physical_obstruction
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".physical_obstruction;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".physical_obstruction
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".physical_obstruction;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".physical_obstruction
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Chemical Obstruction table
------------------------------------------------
DROP TABLE if exists "dbeel".chemical_obstruction CASCADE;
CREATE TABLE "dbeel".chemical_obstruction (
	co_chemical_type varchar(30),
	co_pollution varchar(30),
	co_distribution_type varchar(30),
	co_distribution integer,
	CONSTRAINT chemical_obstruction_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".obstruction);
ALTER TABLE "dbeel".chemical_obstruction ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".chemical_obstruction ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".chemical_obstruction ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".chemical_obstruction ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_chemical_obstruction_Insert ON "dbeel".chemical_obstruction;
CREATE TRIGGER TR_chemical_obstruction_Insert BEFORE INSERT ON "dbeel".chemical_obstruction
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_chemical_obstruction_Update ON "dbeel".chemical_obstruction;
CREATE TRIGGER TR_chemical_obstruction_Update BEFORE UPDATE ON "dbeel".chemical_obstruction
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".chemical_obstruction;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".chemical_obstruction
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".chemical_obstruction;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".chemical_obstruction
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();