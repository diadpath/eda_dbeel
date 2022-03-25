-----------------------------------
-- Create Observation place table
-----------------------------------
DROP TABLE if exists "dbeel".observation_places CASCADE;
CREATE TABLE "dbeel".observation_places (
	op_id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
	op_gis_systemname varchar(20),
	op_gis_layername varchar(30),
	op_gislocation varchar(15),
	op_placename varchar(250),
	op_no_observationplacetype integer,
	op_op_id uuid);
-- Create foreign key
ALTER TABLE "dbeel".observation_places ADD CONSTRAINT fk_op_no_observationplacetype
	FOREIGN KEY (op_no_observationplacetype)
	REFERENCES "dbeel_nomenclature".observation_place_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_observation_places_Insert ON "dbeel".observation_places;
CREATE TRIGGER TR_observation_places_Insert BEFORE INSERT ON "dbeel".observation_places
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observation_id_place_insert();
--DROP TRIGGER TR_observation_places_Update ON "dbeel".observation_places;
CREATE TRIGGER TR_observation_places_Update BEFORE UPDATE ON "dbeel".observation_places
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observation_id_place_update();
--DROP TRIGGER TR_observation_places_Delete ON "dbeel".observation_places;
CREATE TRIGGER TR_observation_places_Delete BEFORE DELETE ON "dbeel".observation_places
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observation_places_verify();
-----------------------------------
-- Create within  table
-----------------------------------
DROP TABLE if exists "dbeel".within CASCADE;
CREATE TABLE "dbeel".within (
	wi_id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
	wi_op_id_parent uuid, -- place that include the child
	wi_op_id_child uuid); -- place be included in the parent
-- Create foreign key
ALTER TABLE "dbeel".within ADD CONSTRAINT fk_wi_op_idparent
	FOREIGN KEY (wi_op_id_parent)
	REFERENCES "dbeel".observation_places (op_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".within ADD CONSTRAINT fk_wi_op_idchild
	FOREIGN KEY (wi_op_id_child)
	REFERENCES "dbeel".observation_places (op_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger

-----------------------------------
-- Create upstream  table
-----------------------------------
DROP TABLE if exists "dbeel".upstream CASCADE;
CREATE TABLE "dbeel".upstream (
	up_id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
	up_op_id_parent uuid, -- place that is dowstream of the child
	up_op_id_child uuid); -- place that is upstream of the parent
-- Create foreign key
ALTER TABLE "dbeel".upstream ADD CONSTRAINT fk_up_op_idparent
	FOREIGN KEY (up_op_id_parent)
	REFERENCES "dbeel".observation_places (op_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".upstream ADD CONSTRAINT fk_up_op_idchild
	FOREIGN KEY (up_op_id_child)
	REFERENCES "dbeel".observation_places (op_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger

------------------------------------------------
-- Create Environmental characteristic table
------------------------------------------------
DROP TABLE if exists "dbeel".environmental_characteristic CASCADE;
CREATE TABLE "dbeel".environmental_characteristic (
	ec_id serial NOT NULL PRIMARY KEY,
	ec_temperature real,
	ec_slope real,
	ec_distance_sea real,
	ec_wettered_area real,
	ec_no_ecologicalproduct integer,
	ec_noncalcareous_precent real,
	ec_op_id uuid);
-- Create foreign key
ALTER TABLE "dbeel".environmental_characteristic ADD CONSTRAINT fk_ec_no_ecologicalproduct
	FOREIGN KEY (ec_no_ecologicalproduct)
	REFERENCES "dbeel_nomenclature".ecological_productivity (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_environmental_characteristic_op_id_Insert ON "dbeel".environmental_characteristic;
CREATE TRIGGER TR_environmental_characteristic_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".environmental_characteristic
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_environmental_characteristic_insert();

   
--------------------------------
-- Table establishment 
--------------------------------
DROP TABLE if exists "dbeel".establishment CASCADE;
CREATE TABLE "dbeel".establishment (
	et_id serial NOT NULL PRIMARY KEY,
	et_establishment_name varchar(100) );	
-------------------------------
-- Table Data provider 
-------------------------------
DROP TABLE if exists "dbeel".data_provider CASCADE;
CREATE TABLE "dbeel".data_provider (
	dp_id serial NOT NULL PRIMARY KEY,
	dp_name varchar(60) ,
	dp_et_id integer);	
-- foreign keys
ALTER TABLE "dbeel".data_provider ADD CONSTRAINT fk_et_id
	FOREIGN KEY (dp_et_id)
	REFERENCES "dbeel".establishment (et_id) ON DELETE RESTRICT ON UPDATE CASCADE;
	
--------------------------------
-- Create Observation table
--------------------------------
DROP TABLE if exists "dbeel".observations CASCADE;
CREATE TABLE "dbeel".observations (
	ob_id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
	ob_no_origin integer,  	-- Observation origin 
	ob_no_type integer,		-- observation type
	ob_no_period integer,	-- Period type
	ob_starting_date date,	 
	ob_ending_date date,
	ob_op_id uuid NOT NULL,
	ob_dp_id integer NOT NULL);
-- Create foreign key
ALTER TABLE "dbeel".observations ADD CONSTRAINT fk_ob_origin
	FOREIGN KEY (ob_no_origin)
	REFERENCES "dbeel_nomenclature".observation_origin (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".observations ADD CONSTRAINT fk_ob_type
	FOREIGN KEY (ob_no_type)
	REFERENCES "dbeel_nomenclature".observation_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".observations ADD CONSTRAINT fk_ob_period
	FOREIGN KEY (ob_no_period)
	REFERENCES "dbeel_nomenclature".period_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".observations ADD CONSTRAINT fk_dp
	FOREIGN KEY (ob_dp_id)
	REFERENCES "dbeel".data_provider (dp_id) ON DELETE RESTRICT ON UPDATE CASCADE;
-- Create Trigger
--DROP TRIGGER TR_observations_Insert ON "dbeel".observations;
CREATE TRIGGER TR_observations_Insert BEFORE INSERT ON "dbeel".observations
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_insert();
--DROP TRIGGER TR_observations_Update ON "dbeel".observations;
CREATE TRIGGER TR_observations_Update BEFORE UPDATE ON "dbeel".observations
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".observations_id_update();
--DROP TRIGGER TR_observations_op_id_Insert ON "dbeel".observations;
CREATE TRIGGER TR_observations_op_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".observations
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_observations_insert();
--DROP TRIGGER TR_observations_Delete ON "dbeel".observations;
CREATE TRIGGER TR_observations_Delete BEFORE DELETE ON "dbeel".observations
   FOR EACH ROW EXECUTE PROCEDURE "dbeel".integrity_observations_verify();
------------------------------------------
-- Create batch table
------------------------------------------
DROP TABLE if exists "dbeel".batch CASCADE;
CREATE TABLE "dbeel".batch (
	ba_id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
	ba_no_species integer,
	ba_no_stage integer,
	ba_no_value_type integer,
	ba_no_biological_characteristic_type integer,
	ba_quantity real,
	ba_no_individual_status integer,
	ba_batch_level integer,
	ba_ob_id uuid NOT NULL,
	ba_ba_id uuid);
-- Create foreign key
ALTER TABLE "dbeel".batch ADD CONSTRAINT fk_ba_species
	FOREIGN KEY (ba_no_species)
	REFERENCES "dbeel_nomenclature".species (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".batch ADD CONSTRAINT fk_ba_stage
	FOREIGN KEY (ba_no_stage)
	REFERENCES "dbeel_nomenclature".stage (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".batch ADD CONSTRAINT fk_ba_value_type
	FOREIGN KEY (ba_no_value_type)
	REFERENCES "dbeel_nomenclature".value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".batch ADD CONSTRAINT fk_ba_biological_characteristic_type
	FOREIGN KEY (ba_no_biological_characteristic_type)
	REFERENCES "dbeel_nomenclature".biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;	
ALTER TABLE "dbeel".batch ADD CONSTRAINT fk_ba_individual_status
	FOREIGN KEY (ba_no_individual_status)
	REFERENCES "dbeel_nomenclature".individual_status (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
--DROP TRIGGER TR_batch_ob_id_Insert ON "dbeel".batch;
CREATE TRIGGER TR_batch_ob_id_Insert BEFORE INSERT OR UPDATE ON "dbeel".batch
	FOR EACH ROW EXECUTE PROCEDURE "dbeel".fk_id_batch_insert();
-----------------------------------------
-- Table biological characteristics
-----------------------------------------
DROP TABLE if exists "dbeel".biological_characteristic CASCADE;
CREATE TABLE "dbeel".biological_characteristic (
	bc_id uuid DEFAULT uuid_generate_v4() NOT NULL PRIMARY KEY,
	bc_ba_id uuid NOT NULL,
	bc_no_characteristic_type integer NOT NULL,
	bc_no_value_type integer NOT NULL,
	bc_numvalue real);	
-- foreign keys
ALTER TABLE "dbeel".biological_characteristic ADD CONSTRAINT fk_bc_characteristic_type
	FOREIGN KEY (bc_no_characteristic_type)
	REFERENCES "dbeel_nomenclature".biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".biological_characteristic ADD CONSTRAINT fk_bc_value_type
	FOREIGN KEY (bc_no_value_type)
	REFERENCES "dbeel_nomenclature".value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "dbeel".biological_characteristic ADD CONSTRAINT fk_bc_ba_id
	FOREIGN KEY (bc_ba_id)
	REFERENCES "dbeel".batch (ba_id) ON DELETE RESTRICT ON UPDATE CASCADE;

