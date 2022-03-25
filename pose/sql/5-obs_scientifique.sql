-----------------------------------
-- Create electrofishing table
-----------------------------------
-- TODO add a table of size classes by 150 mm + p1 p2 p3 + totalnumbereel
DROP TABLE if exists "dbeel".electrofishing CASCADE;
CREATE TABLE "dbeel".electrofishing (
	ef_no_fishingmethod integer,
	ef_no_electrofishing_mean integer,
	ef_wetted_area real,
	ef_fished_length real,
	ef_fished_width real,
	ef_duration float, -- cedric changed from integer to float
	ef_nbpas integer, -- change cedric
	CONSTRAINT electrofishing_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Create foreign key
ALTER TABLE "dbeel".electrofishing ADD CONSTRAINT fk_ef_electrofishing_mean
	FOREIGN KEY (ef_no_electrofishing_mean)
	REFERENCES "dbeel_nomenclature".electrofishing_mean (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".electrofishing ADD CONSTRAINT fk_ef_electrofishing_method
	FOREIGN KEY (ef_no_fishingmethod)
	REFERENCES "dbeel_nomenclature".scientific_observation_method (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".electrofishing ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".electrofishing ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".electrofishing ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".electrofishing ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_electrofishing_Insert ON "dbeel".electrofishing;
CREATE TRIGGER TR_electrofishing_Insert BEFORE INSERT ON "dbeel".electrofishing
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_electrofishing_Update ON "dbeel".electrofishing;
CREATE TRIGGER TR_electrofishing_Update BEFORE UPDATE ON "dbeel".electrofishing
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".electrofishing;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".electrofishing
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".electrofishing;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".electrofishing
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
--------------------------------------------
-- Create Scientific gear fishing table
--------------------------------------------
DROP TABLE if exists "dbeel".gear_fishing CASCADE;
CREATE TABLE "dbeel".gear_fishing (
	gf_no_gear_type integer,
	gf_gear_number integer,
	gf_no_effort_type integer,
	gf_effort_value real,
	gf_no_name integer,
	CONSTRAINT gear_fishing_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Foreign key
ALTER TABLE "dbeel".gear_fishing ADD CONSTRAINT fk_gf_geartype
	FOREIGN KEY (gf_no_gear_type)
	REFERENCES "dbeel_nomenclature".gear_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".gear_fishing ADD CONSTRAINT fk_gf_effort_type
	FOREIGN KEY (gf_no_effort_type)
	REFERENCES "dbeel_nomenclature".effort_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".gear_fishing ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".gear_fishing ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".gear_fishing ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".gear_fishing ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_gearfishing_Insert ON "dbeel".gear_fishing;
CREATE TRIGGER TR_gearfishing_Insert BEFORE INSERT ON "dbeel".gear_fishing
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_gearfishing_Update ON "dbeel".gear_fishing;
CREATE TRIGGER TR_gearfishing_Update BEFORE UPDATE ON "dbeel".gear_fishing
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".gear_fishing;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".gear_fishing
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".gear_fishing;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".gear_fishing
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
-----------------------------------
-- Create migration monitoring table
-----------------------------------
DROP TABLE if exists "dbeel".migration_monitoring CASCADE;
CREATE TABLE "dbeel".migration_monitoring (
	mm_no_monitoring_type integer,
	mm_no_monitoring_direction integer,
	mm_escapment_rate real, 
	mm_no_name integer,
	CONSTRAINT migration_monitoring_id PRIMARY KEY (ob_id)
) INHERITS ("dbeel".observations);
-- Foreign key
ALTER TABLE "dbeel".migration_monitoring ADD CONSTRAINT fk_mm_monitoring_type
	FOREIGN KEY (mm_no_monitoring_type)
	REFERENCES "dbeel_nomenclature".control_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".migration_monitoring ADD CONSTRAINT fk_mm_monitoring_direction
	FOREIGN KEY (mm_no_monitoring_direction)
	REFERENCES "dbeel_nomenclature".migration_direction (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".migration_monitoring ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".migration_monitoring ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".migration_monitoring ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".migration_monitoring ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_migration_monitoring_Insert ON "dbeel".migration_monitoring;
CREATE TRIGGER TR_migration_monitoring_Insert BEFORE INSERT ON "dbeel".migration_monitoring
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_migration_monitoring_Update ON "dbeel".migration_monitoring;
CREATE TRIGGER TR_migration_monitoring_Update BEFORE UPDATE ON "dbeel".migration_monitoring
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
  --DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".migration_monitoring;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".migration_monitoring
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".migration_monitoring;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".migration_monitoring
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();