----------------------------------
-- Create migration table
-----------------------------------
DROP TABLE if exists "dbeel".migration CASCADE;
CREATE TABLE "dbeel".migration (
	mi_proportion real,
	mi_speed_unity varchar(30),
	mi_speed real,
	mi_arrival_op_id uuid,
	CONSTRAINT migration_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
ALTER TABLE "dbeel".migration ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".migration ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".migration ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".migration ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_migration_Insert ON "dbeel".migration;
CREATE TRIGGER TR_migration_Insert BEFORE INSERT ON "dbeel".migration
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_migration_Update ON "dbeel".migration;
CREATE TRIGGER TR_migration_Update BEFORE UPDATE ON "dbeel".migration
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".migration;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".migration
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".migration;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".migration
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Maturation table
------------------------------------------------
DROP TABLE if exists "dbeel".maturation CASCADE;
CREATE TABLE "dbeel".maturation (
	ma_param1 real,
	ma_param2 real,
	ma_lenght integer,
	ma_no_sex integer,
	CONSTRAINT maturation_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Create foreign key
ALTER TABLE "dbeel".maturation ADD CONSTRAINT fk_ma_sex
	FOREIGN KEY (ma_no_sex)
	REFERENCES "dbeel_nomenclature".sex (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".maturation ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".maturation ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".maturation ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".maturation ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_maturation_Insert ON "dbeel".maturation;
CREATE TRIGGER TR_maturation_Insert BEFORE INSERT ON "dbeel".maturation
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_maturation_Update ON "dbeel".maturation;
CREATE TRIGGER TR_maturation_Update BEFORE UPDATE ON "dbeel".maturation
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".maturation;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".maturation
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".maturation;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".maturation
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Growth table
------------------------------------------------
DROP TABLE if exists "dbeel".growth CASCADE;
CREATE TABLE "dbeel".growth (
	gr_rate real,
	gr_assymptotique_length real,
	gr_constante real,
	CONSTRAINT growth_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
ALTER TABLE "dbeel".growth ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".growth ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".growth ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".growth ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_growth_Insert ON "dbeel".growth;
CREATE TRIGGER TR_growth_Insert BEFORE INSERT ON "dbeel".growth
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_growth_Update ON "dbeel".growth;
CREATE TRIGGER TR_growth_Update BEFORE UPDATE ON "dbeel".growth
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".growth;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".growth
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".growth;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".growth
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Mortality table
------------------------------------------------
DROP TABLE if exists "dbeel".mortality CASCADE;
CREATE TABLE "dbeel".mortality (
	mo_no_mortality_type integer,
	CONSTRAINT mortality_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Create foreign key
ALTER TABLE "dbeel".mortality ADD CONSTRAINT fk_mo_mortality
	FOREIGN KEY (mo_no_mortality_type)
	REFERENCES "dbeel_nomenclature".mortality_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".mortality ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".mortality ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".mortality ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".mortality ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_mortality_Insert ON "dbeel".mortality;
CREATE TRIGGER TR_mortality_Insert BEFORE INSERT ON "dbeel".mortality
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_mortality_Update ON "dbeel".mortality;
CREATE TRIGGER TR_mortality_Update BEFORE UPDATE ON "dbeel".mortality
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".mortality;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".mortality
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".mortality;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".mortality
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------------
-- Create Differentiation table
------------------------------------------------
DROP TABLE if exists "dbeel".differentiation CASCADE;
CREATE TABLE "dbeel".differentiation (
	di_rate real,
	di_no_sex integer,
	CONSTRAINT differentiation_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Create foreign key
ALTER TABLE "dbeel".differentiation ADD CONSTRAINT fk_di_sex
	FOREIGN KEY (di_no_sex)
	REFERENCES "dbeel_nomenclature".sex (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".differentiation ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".differentiation ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".differentiation ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".differentiation ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_differentiation_Insert ON "dbeel".differentiation;
CREATE TRIGGER TR_differentiation_Insert BEFORE INSERT ON "dbeel".differentiation
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_differentiation_Update ON "dbeel".differentiation;
CREATE TRIGGER TR_differentiation_Update BEFORE UPDATE ON "dbeel".differentiation
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".differentiation;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".differentiation
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".differentiation;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".differentiation
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();