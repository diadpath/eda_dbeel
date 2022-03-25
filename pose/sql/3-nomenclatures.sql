
---************************************--
-- 	nomenclature
---************************************--
-----------------------------------------
-- Parent table nomenclature
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".nomenclature CASCADE;
CREATE TABLE "dbeel_nomenclature".nomenclature (
	no_id serial PRIMARY KEY,
	no_code varchar(2),  -- give the code of then name
	no_type varchar(60), -- give the purpose of the nomeclature
	no_name varchar(80)
);
--DROP TRIGGER TR_nomenclature_id_Insert ON "dbeel_nomenclature".nomenclature;
CREATE TRIGGER TR_nomenclature_id_Insert BEFORE INSERT ON "dbeel_nomenclature".nomenclature 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_nomenclature_id_Update ON "dbeel_nomenclature".nomenclature;
CREATE TRIGGER TR_nomenclature_id_Update BEFORE UPDATE ON "dbeel_nomenclature".nomenclature 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();
-----------------------------------------
-- Create observation_place_type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".observation_place_type CASCADE;
CREATE TABLE "dbeel_nomenclature".observation_place_type (
	obs_subtype_name varchar(30),
	CONSTRAINT obs_subtype_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_obs_subtype_Insert ON "dbeel_nomenclature".observation_place_type;
CREATE TRIGGER TR_obs_subtype_Insert BEFORE INSERT ON "dbeel_nomenclature".observation_place_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER R_obs_subtype_Update ON "dbeel_nomenclature".observation_place_type;
CREATE TRIGGER TR_obs_subtype_Update BEFORE UPDATE ON "dbeel_nomenclature".observation_place_type 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();
   
INSERT INTO "dbeel_nomenclature".observation_place_type
	(obs_subtype_name, no_type, no_name) 
	VALUES
	('Unknown', 'Observation place', 'Unknown'),
	('Administrative', 'Observation place', 'Country'),
	('Administrative', 'Observation place', 'Region'),
	('Administrative', 'Observation place', 'River Basin District'),
	('Administrative', 'Observation place', 'EMU'),
	('Geographic', 'Observation place', 'Waterbody'),
	('Geographic', 'Observation place', 'River Basin'),
	('Geographic', 'Observation place', 'River'),
	('Geographic', 'Observation place', 'River stretch'),
	('Geographic', 'Observation place', 'Sampling station')
;
-----------------------------------------
-- Create observation origin (ob_origin) table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".ob_origin CASCADE;
CREATE TABLE "dbeel_nomenclature".observation_origin (
	CONSTRAINT obs_origin_id PRIMARY KEY (no_id)) 
INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_obs_origin_Insert ON "dbeel_nomenclature".observation_origin;
CREATE TRIGGER TR_obs_origin_Insert BEFORE INSERT ON "dbeel_nomenclature".observation_origin 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_obs_origin_Update ON "dbeel_nomenclature".observation_origin;
CREATE TRIGGER TR_obs_origin_Update BEFORE UPDATE ON "dbeel_nomenclature".observation_origin  
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();
   
INSERT INTO "dbeel_nomenclature".observation_origin 
	(no_type, no_name) 
	VALUES 
	('Observation origin','Raw data'), 
	('Observation origin','Modelling result')
;
-----------------------------------------
-- Create observation_type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".observation_type CASCADE;
CREATE TABLE "dbeel_nomenclature".observation_type (
	obs_type_class_name varchar(30),
	CONSTRAINT obs_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_obs_type_Insert ON "dbeel_nomenclature".observation_type;
CREATE TRIGGER TR_obs_type_Insert BEFORE INSERT ON "dbeel_nomenclature".observation_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_obs_type_Update ON "dbeel_nomenclature".observation_type;
CREATE TRIGGER TR_obs_type_Update BEFORE UPDATE ON "dbeel_nomenclature".observation_type
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".observation_type 
	(obs_type_class_name, no_name, no_type) 
	VALUES
	('Unknown', 'Unknown', 'Observation Type'),
	('Pression - Impact', 'Pression - Impact', 'Observation Type'),
	('Pression - Impact', 'Habitat loss', 'Observation Type'),
	('Pression - Impact', 'Obstruction', 'Observation Type'),
	('Pression - Impact', 'Stocking', 'Observation Type'),
	('Pression - Impact', 'Predation', 'Observation Type'),
	('Pression - Impact', 'Ecological status', 'Observation Type'),
	('Scientific Observation','Scientific Observation', 'Observation Type'),
	('Scientific Observation','Gear fishing', 'Observation Type'),
	('Scientific Observation','Electro-fishing', 'Observation Type'),
	('Scientific Observation','Migration monitoring', 'Observation Type'),
	('Biological process','Biological process', 'Observation Type'),
	('Biological process','Migration', 'Observation Type'),
	('Biological process','Maturation', 'Observation Type'),
	('Biological process','Growth', 'Observation Type'),
	('Biological process','Mortality', 'Observation Type'),
	('Biological process','Differentiation', 'Observation Type')
;
-----------------------------------------
-- Create species table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".species CASCADE;
CREATE TABLE "dbeel_nomenclature".species (
	sp_vernacular_name varchar(30),
	CONSTRAINT sp_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_species_Insert ON "dbeel_nomenclature".observation_type;
CREATE TRIGGER TR_species_Insert BEFORE INSERT ON "dbeel_nomenclature".species 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_species_Update ON "dbeel_nomenclature".observation_type;
CREATE TRIGGER TR_species_Update BEFORE UPDATE ON "dbeel_nomenclature".species  
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".species 
	(sp_vernacular_name, no_name, no_type) 
	VALUES
	('Eel', 'Anguilla anguilla', 'Species')
;
-----------------------------------------
-- Create stage table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".stage CASCADE;
CREATE TABLE "dbeel_nomenclature".stage (
	CONSTRAINT st_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_stage_Insert ON "dbeel_nomenclature".stage;
CREATE TRIGGER TR_stage_Insert BEFORE INSERT ON "dbeel_nomenclature".stage 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_stage_Update ON "dbeel_nomenclature".stage;
CREATE TRIGGER TR_stage_Update BEFORE UPDATE ON "dbeel_nomenclature".stage
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".stage 
	(no_name, no_type) 
	VALUES
	('Unknown', 'Stage'),
	('Glass eel', 'Stage'),
	('Yellow eel', 'Stage'),
	('Silver eel', 'Stage'),
	('Glass & yellow eel mixed', 'Stage'),
	('Yellow & silver eel mixed', 'Stage'),
	('G, Y & S eel mixed', 'Stage')
;
-----------------------------------------
-- Create biological_characteristic_type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".biological_characteristic_type CASCADE;
CREATE TABLE "dbeel_nomenclature".biological_characteristic_type (
	bc_label varchar(100),
	bc_unit varchar(25),
	bc_data_type varchar(25),
	CONSTRAINT bc_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_bio_characteristic_Insert ON "dbeel_nomenclature".biological_characteristic_type;
CREATE TRIGGER TR_bio_characteristic_Insert BEFORE INSERT ON "dbeel_nomenclature".biological_characteristic_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_bio_characteristic_Update ON "dbeel_nomenclature".biological_characteristic_type;
CREATE TRIGGER TR_bio_characteristic_Update BEFORE UPDATE ON "dbeel_nomenclature".biological_characteristic_type  
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".biological_characteristic_type 
	(no_type, no_name, bc_label, bc_unit, bc_data_type) 
	VALUES
	('Biological characteristic type', 'Unknown', 'Unknown', 'Unknown', 'Unknown'),
	('Biological characteristic type', 'Length', 'Total length', 'mm', 'real'),
	('Biological characteristic type', 'Lower length', 'Total length - lower bound', 'mm', 'real'),
	('Biological characteristic type', 'Upper length', 'Total length - upper bound', 'mm', 'real'),
	('Biological characteristic type', 'Weight', 'Weight', 'g', 'real'),
	('Biological characteristic type', 'Age', 'Age', 'year', 'integer'),
	('Biological characteristic type', 'Sex', 'Sex', 'Dimensionless', 'nomenclature'),
	('Biological characteristic type', 'Stage', 'stage', 'Dimensionless', 'nomenclature'),
	('Biological characteristic type', 'Rate', 'rate', '%', 'real'),
	('Biological characteristic type', 'Number', 'Number', 'Dimensionless', 'nomenclature'),
	('Biological characteristic type', 'Density', 'Density', 'nb/m²', 'real')
;
-----------------------------------------
-- Create individual_status table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".individual_status CASCADE;
CREATE TABLE "dbeel_nomenclature".individual_status (
	CONSTRAINT indiv_status_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_Indiv_status_Insert ON "dbeel_nomenclature".individual_status;
CREATE TRIGGER TR_Indiv_status_Insert BEFORE INSERT ON "dbeel_nomenclature".individual_status 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_Indiv_status_Update ON "dbeel_nomenclature".individual_status;
CREATE TRIGGER TR_Indiv_status_Update BEFORE UPDATE ON "dbeel_nomenclature".individual_status
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".individual_status 
	(no_type, no_name) 
	VALUES
	('Individual status','Alive'),
	('Individual status','Dead'),
	('Individual status','extracted from the aqu. env.'),
	('Individual status','added to the aquatic env.'),
	('Individual status','Other')
;
-----------------------------------------
-- Create value_type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".value_type CASCADE;
CREATE TABLE "dbeel_nomenclature".value_type (
	CONSTRAINT vl_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_value_type_Insert ON "dbeel_nomenclature".value_type;
CREATE TRIGGER TR_value_type_Insert BEFORE INSERT ON "dbeel_nomenclature".value_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_value_type_Update ON "dbeel_nomenclature".value_type;
CREATE TRIGGER TR_value_type_Update BEFORE UPDATE ON "dbeel_nomenclature".value_type
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".value_type 
	(no_type, no_name) 
	VALUES
	('Value type','Unknown'),
	('Value type','Raw data or Individual data'),
	('Value type','Mean value'),
	('Value type','Class value'),
	('Value type','Elaborated data'),
	('Value type','Cumulated data')
;

-----------------------------------------
-- Create scientific_observation_type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".scientific_observation_method CASCADE;
CREATE TABLE "dbeel_nomenclature".scientific_observation_method (
	sc_observation_category varchar(30),
	sc_definition varchar(500),
	CONSTRAINT sc_observ_method_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_scientific_obs_method_Insert ON "dbeel_nomenclature".scientific_observation_method;
CREATE TRIGGER TR_scientific_obs_method_Insert BEFORE INSERT ON "dbeel_nomenclature".scientific_observation_method 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_scientific_obs_method_Update ON "dbeel_nomenclature".scientific_observation_method;
CREATE TRIGGER TR_scientific_obs_method_Update BEFORE UPDATE ON "dbeel_nomenclature".scientific_observation_method  
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".scientific_observation_method 
	(no_type, sc_observation_category, no_name) 
	VALUES
	('Scientific observation type', 'Unknown', 'Unknown'),
	('Scientific observation type', 'Electro-fishing', 'Unknown'),
	('Scientific observation type', 'Electro-fishing', 'Whole'),
	('Scientific observation type', 'Electro-fishing', 'Partial1bank'),
	('Scientific observation type', 'Electro-fishing', 'Partial2banks'),
	('Scientific observation type', 'Electro-fishing', 'Partialrandom'),
	('Scientific observation type', 'Electro-fishing', 'Partialprop'),
	('Scientific observation type', 'Electro-fishing', 'Other'),
	('Scientific observation type', 'Gear fishing', 'Unknown'),
	('Scientific observation type', 'Migration monitoring', 'Unknown')
;
-----------------------------------------
-- Create electrofishing_mean table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".electrofishing_mean CASCADE;
CREATE TABLE "dbeel_nomenclature".electrofishing_mean (
	ef_definition varchar(500),
	CONSTRAINT ef_mean_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_electrofishing_mean_Insert ON "dbeel_nomenclature".electrofishing_mean;
CREATE TRIGGER TR_electrofishing_mean_Insert BEFORE INSERT ON "dbeel_nomenclature".electrofishing_mean 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_electrofishing_mean_Update ON "dbeel_nomenclature".electrofishing_mean;
CREATE TRIGGER TR_electrofishing_mean_Update BEFORE UPDATE ON "dbeel_nomenclature".electrofishing_mean  
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".electrofishing_mean 
	(no_type, no_name) 
	VALUES
	('Electrofishing mean', 'Unknown'),
	('Electrofishing mean', 'By foot'),
	('Electrofishing mean', 'By boat'),
	('Electrofishing mean', 'Mix')
;
-----------------------------------------
-- Create period_type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".period_type CASCADE;
CREATE TABLE "dbeel_nomenclature".period_type (
	CONSTRAINT period_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_period_type_Insert ON "dbeel_nomenclature".period_type;
CREATE TRIGGER TR_period_type_Insert BEFORE INSERT ON "dbeel_nomenclature".period_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_period_type_Update ON "dbeel_nomenclature".period_type;
CREATE TRIGGER TR_period_type_Update  BEFORE UPDATE ON "dbeel_nomenclature".period_type
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".period_type 
	(no_type, no_name) 
	VALUES
	('Period type', 'Unknown'),
	('Period type', 'Daily'),
	('Period type', 'Weekly'),
	('Period type', 'Semimonthly'),
	('Period type', 'Monthly'),
	('Period type', 'Bimonthly'),
	('Period type', 'Quaterly'),
	('Period type', 'Half-yearly'),
	('Period type', 'Yearly'),
	('Period type', 'Other')
;
-----------------------------------------
-- Create Control_type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".Control_type CASCADE;
CREATE TABLE "dbeel_nomenclature".control_type (
	CONSTRAINT control_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_control_type_Insert ON "dbeel_nomenclature".control_type;
CREATE TRIGGER R_control_type_Insert BEFORE INSERT ON "dbeel_nomenclature".control_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_control_type_Update ON "dbeel_nomenclature".control_type;
CREATE TRIGGER TR_control_type_Update  BEFORE UPDATE ON "dbeel_nomenclature".control_type  
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".control_type 
	(no_type, no_name) 
	VALUES
	('Control type', 'Unknown'),
	('Control type', 'Trapping'),
	('Control type','Resistivity fish counter'),
	('Control type','Visual image analysis'),
	('Control type','Acoustic counter'),
	('Control type','Optoelectronics')
;
-----------------------------------------
-- Create Ecological_status_class  table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".ecological_status_class  CASCADE;
CREATE TABLE "dbeel_nomenclature".ecological_status_class (
	CONSTRAINT ecolo_class_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_ecolo_status_Insert ON "dbeel_nomenclature".ecological_status_class;
CREATE TRIGGER TR_ecolo_status_Insert BEFORE INSERT ON "dbeel_nomenclature".ecological_status_class
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_ecolo_status_Update ON "dbeel_nomenclature".ecological_status_class;
CREATE TRIGGER TR_ecolo_status_Update  BEFORE UPDATE ON "dbeel_nomenclature".ecological_status_class 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".ecological_status_class
	(no_type, no_name) 
	VALUES
	('Ecological status class', 'High'),
	('Ecological status class', 'Good'),
	('Ecological status class', 'Moderate'),
	('Ecological status class', 'Poor'),
	('Ecological status class', 'Unclassified')
;

-----------------------------------------
-- Create Predator type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".fisher_type CASCADE;
CREATE TABLE "dbeel_nomenclature".fisher_type (
	CONSTRAINT fisher_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_Predator_Type_Insert ON "dbeel_nomenclature".fisher_type;
CREATE TRIGGER TR_fisher_type_Insert BEFORE INSERT ON "dbeel_nomenclature".fisher_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_fisher_type_Update ON "dbeel_nomenclature".fisher_type;
CREATE TRIGGER TR_fisher_type_Update  BEFORE UPDATE ON "dbeel_nomenclature".fisher_type 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".fisher_type
	(no_type, no_name) 
	VALUES
	('Fisher type', 'Unknown'),
	('Fisher type','Professional fishing'),
	('Fisher type','Amateur fishing'),
	('Fisher type','Other')
;
-----------------------------------------
-- Create Fishing effort type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".effort_type CASCADE;
CREATE TABLE "dbeel_nomenclature".effort_type (
	CONSTRAINT effort_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_effort_Insert ON "dbeel_nomenclature".effort_type;
CREATE TRIGGER TR_effort_Insert BEFORE INSERT ON "dbeel_nomenclature".effort_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_effort_Update ON "dbeel_nomenclature".effort_type;
CREATE TRIGGER TR_effort_Update  BEFORE UPDATE ON "dbeel_nomenclature".effort_type  
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".effort_type 
	(no_type, no_name) 
	VALUES
	('Effort type', 'Unknown'),
	('Effort type', 'Number of gear'),
	('Effort type','Duration days'),
	('Effort type','Area in square meters'),
	('Effort type','Volume in cubic meters'),
	('Effort type','Number gear par days'),
	('Effort type','Number gear per month')
; 
-----------------------------------------
-- Create Gear type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".gear_type CASCADE;
CREATE TABLE "dbeel_nomenclature".gear_type (
	isscfg_code varchar(6),
	main_gear varchar(60),
	eel_specific_gear varchar(60),
	CONSTRAINT gear_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_gear_type_Insert ON "dbeel_nomenclature".gear_type;
CREATE TRIGGER TR_gear_type_Insert BEFORE INSERT ON "dbeel_nomenclature".gear_type 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_gear_type_Update ON "dbeel_nomenclature".gear_type;
CREATE TRIGGER TR_gear_type_Update BEFORE UPDATE ON "dbeel_nomenclature".gear_type
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".gear_type
	(isscfg_code,main_gear, no_type, no_name, eel_specific_gear) 
	VALUES
	('01.0.0', 'SURROUNDING NETS', 'Gear type', 'Unknown',NULL),
	('01.1.0', 'SURROUNDING NETS', 'Gear type', 'Surrounding Nets with Purse Lines (Purse Seines)',NULL),
	('01.1.1', 'SURROUNDING NETS', 'Gear type', 'Surrounding Nets with Purse Lines - one boat',NULL),
	('01.1.2', 'SURROUNDING NETS', 'Gear type', 'Surrounding Nets with Purse Lines - two boats ',NULL),
	('01.2.0', 'SURROUNDING NETS', 'Gear type', 'Surrounding Nets without Purse Lines',NULL),
	('02.0.0', 'SEINE NETS', 'Gear type', 'Unknown',NULL),
	('02.1.0', 'SEINE NETS', 'Gear type', 'Beach Seines',NULL),
	('02.2.0', 'SEINE NETS', 'Gear type', 'Boat Seines',NULL),
	('02.2.1', 'SEINE NETS', 'Gear type', 'Boat Seines',NULL),
	('02.2.2', 'SEINE NETS', 'Gear type', 'Boat Seines',NULL),
	('02.2.3', 'SEINE NETS', 'Gear type', 'Boat Seines',NULL),
	('02.9.0', 'SEINE NETS', 'Gear type', 'Boat Seines',NULL),
	('03.0.0','TRAWLS', 'Gear type', 'Unknown',NULL),
	('03.1.0','TRAWLS', 'Gear type', 'Unknown',NULL),
	('03.1.1','TRAWL NETS', 'Gear type', 'Beam trawls',NULL),
	('03.1.2','TRAWL NETS', 'Gear type', 'Bottom otter trawls',NULL),
	('03.1.3','TRAWL NETS', 'Gear type', 'Bottom pair trawls',NULL),
	('03.1.4','TRAWLS', 'Gear type', 'Unknown',NULL),
	('03.1.5','TRAWLS', 'Gear type', 'Unknown',NULL),
	('03.1.9','TRAWLS', 'Gear type', 'Unknown',NULL),
	('03.2.0','TRAWLS', 'Gear type', 'Unknown',NULL),
	('03.2.1','TRAWL NETS', 'Gear type', 'Midwater otter trawls',NULL),
	('03.2.2','TRAWL NETS', 'Gear type', 'Midwater pair trawls',NULL),
	('03.2.3','TRAWLS', 'Gear type', 'Unknown',NULL),
	('03.2.9','TRAWLS', 'Gear type', 'Unknown',NULL),
	('03.3.0','TRAWL NETS', 'Gear type', '0tter Twin Trawls',NULL),
	('03.4.9','TRAWL NETS', 'Gear type', '0tter Twin Trawls',NULL),
	('03.5.9','TRAWL NETS', 'Gear type', '0tter Twin Trawls',NULL),
	('03.9.0','TRAWL NETS', 'Gear type', '0tter Twin Trawls',NULL),
	('04.0.0','DREDGES', 'Gear type', 'Boat Dredges',NULL),
	('04.1.0','DREDGES', 'Gear type', 'Boat Dredges',NULL),
	('04.2.0','DREDGES', 'Gear type', 'Hand Dredges',NULL),
	('05.0.0','LIFT NETS', 'Gear type', 'Portable Lift Nets',NULL),
	('05.1.0','LIFT NETS', 'Gear type', 'Portable Lift Nets',NULL),
	('05.2.0','LIFT NETS', 'Gear type', 'Boat Operated Lift Nets',NULL),
	('05.3.0','LIFT NETS', 'Gear type', 'Shore Operated Lift Nets',NULL),
	('05.9.0','LIFT NETS', 'Gear type', 'Shore Operated Lift Nets',NULL),
	('06.0.0','FALLING GEAR', 'Gear type', 'Cast Nets',NULL),
	('06.1.0','FALLING GEAR', 'Gear type', 'Cast Nets',NULL),
	('06.9.0','FALLING GEAR', 'Gear type', 'Falling Gear (Not Specified)',NULL),
	('07.0.0','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Set Gillnets (Anchored)',NULL),
	('07.1.0','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Set Gillnets (Anchored)',NULL),
	('07.2.0','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Drifting Gillnets (Driftnets)',NULL),
	('07.3.0','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Encircling gillnets',NULL),
	('07.4.0','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Fixed Gillnets (on Stakes)',NULL),
	('07.5.0','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Trammel Nets',NULL),
	('07.6.0','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Trammel Nets',NULL),
	('07.9.0','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Trammel Nets',NULL),
	('07.9.1','GILLNETS AND ENTANGLING NETS', 'Gear type', 'Trammel Nets',NULL),
	('08.0.0','TRAPS', 'Gear type', 'Unknown',NULL),
	('08.1.0','TRAPS', 'Gear type', 'Stationary Uncovered Pound Nets',NULL),
	('08.2.0','TRAPS', 'Gear type', 'Pots','Eel pots'),
	('08.3.0','TRAPS', 'Gear type', 'Fyke Nets','Eel fyke nets'),
	('08.4.0','TRAPS', 'Gear type', 'Stow Nets','Dideau'),
	('08.5.0','TRAPS', 'Gear type', 'Barriers, Fences, Weirs, Corrals, etc.',NULL),
	('08.6.0','TRAPS', 'Gear type', 'Aerial Traps',NULL),
	('08.9.0','TRAPS', 'Gear type', 'Aerial Traps',NULL),
	('09.0.0','HOOKS AND LINES', 'Gear type', 'Handlines and Pole-Lines (Hand Operated)',NULL),
	('09.1.0','HOOKS AND LINES', 'Gear type', 'Handlines and Pole-Lines (Hand Operated)',NULL),
	('09.2.0','HOOKS AND LINES', 'Gear type', 'Handlines and Pole-Lines (Mechanized)',NULL),
	('09.3.0','HOOKS AND LINES', 'Gear type', 'Set Longlines',NULL),
	('09.4.0','HOOKS AND LINES', 'Gear type', 'Drifting Longlines',NULL),
	('09.5.0','HOOKS AND LINES', 'Gear type', 'Longlines (Not Specified)',NULL),
	('09.6.0','HOOKS AND LINES', 'Gear type', 'Trolling Lines',NULL),
	('09.9.0','HOOKS AND LINES', 'Gear type', 'Trolling Lines',NULL),
	('10.0.0','GRAPPLING AND WOUNDING', 'Gear type', 'Unknown',NULL),
	('10.1.0','GRAPPLING AND WOUNDING', 'Gear type', 'Harpoons',NULL),
	('11.0.0','HARVESTING GEAR', 'Gear type', 'Pumps',NULL),
	('11.1.0','HARVESTING GEAR', 'Gear type', 'Pumps',NULL),
	('11.2.0','HARVESTING GEAR', 'Gear type', 'Mechanized Dredges',NULL),
	('11.9.0','HARVESTING GEAR', 'Gear type', 'Pumps',NULL),
	('20.0.0','MISCELLANEOUS', 'Gear type', 'Miscellaneous','Glass eel scoop net and push net'),
	('25.0.0','RECREATIVE FISHING GEAR', 'Gear type', 'Recreational fishing gear',NULL),
	('99.0.0','UNKNOWN', 'Gear type', 'Unknown',NULL)
;
-----------------------------------------
-- Create sex table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".sex CASCADE;
CREATE TABLE "dbeel_nomenclature".sex (
	CONSTRAINT sex_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_sex_Insert ON "dbeel_nomenclature".sex;
CREATE TRIGGER TR_sex_Insert BEFORE INSERT ON "dbeel_nomenclature".sex 
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_sex_Update ON "dbeel_nomenclature".sex;
CREATE TRIGGER TR_sex_Update BEFORE UPDATE ON "dbeel_nomenclature".sex 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".sex 
	(no_type, no_name) 
	VALUES
	('Sex', 'Unknown'),
	('Sex', 'male'),
	('Sex', 'female'),
	('Sex', 'Unidentifed')
;
-----------------------------------------
-- Create Mortality type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".mortality_type CASCADE;
CREATE TABLE "dbeel_nomenclature".mortality_type (
	CONSTRAINT mortality_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_mortality_type_Insert ON "dbeel_nomenclature".mortality_type;
CREATE TRIGGER TR_mortality_type_Insert BEFORE INSERT ON "dbeel_nomenclature".mortality_type
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_mortality_type_Update ON "dbeel_nomenclature".mortality_type;
CREATE TRIGGER TR_mortality_type_Update BEFORE UPDATE ON "dbeel_nomenclature".mortality_type 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".mortality_type
	(no_type, no_name) 
	VALUES
	('Mortality type', 'Unknown'),
	('Mortality type', 'Natural'),
	('Mortality type', 'Total anthropogenic mortality'),
	('Mortality type', 'Total mortality'),
	('Mortality type', 'Fishing Mortality'),
	('Mortality type', 'Anthropogenic mortality other than fishing')
;
-----------------------------------------
-- Create Habitat loss type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".habitat_loss_type CASCADE;
CREATE TABLE "dbeel_nomenclature".habitat_loss_type (
	CONSTRAINT habitat_loss_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_habitat_loss_Insert ON "dbeel_nomenclature".habitat_loss_type;
CREATE TRIGGER TR_habitat_loss_Insert BEFORE INSERT ON "dbeel_nomenclature".habitat_loss_type
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_habitat_loss_Update ON "dbeel_nomenclature".habitat_loss_type;
CREATE TRIGGER TR_habitat_loss_Update BEFORE UPDATE ON "dbeel_nomenclature".habitat_loss_type
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".habitat_loss_type
	(no_type, no_name) 
	VALUES
	('Habitat loss type', 'Unknown'),
	('Habitat loss type', 'Marshland'),
	('Habitat loss type', 'Lake'),
	('Habitat loss type', 'Sea'),
	('Habitat loss type', 'Estuary'),
	('Habitat loss type', 'River')
;
-----------------------------------------
-- Create Type of unit table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".type_of_unit CASCADE;
CREATE TABLE "dbeel_nomenclature".type_of_unit (
	tu_unit varchar(10),
	CONSTRAINT type_of_unit_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_type_of_unit_Insert ON "dbeel_nomenclature".type_of_unit;
CREATE TRIGGER TR_type_of_unit_Insert BEFORE INSERT ON "dbeel_nomenclature".type_of_unit
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_type_of_unit_Update ON "dbeel_nomenclature".type_of_unit;
CREATE TRIGGER TR_type_of_unit_Update BEFORE UPDATE ON "dbeel_nomenclature".type_of_unit 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".type_of_unit
	(no_type, no_name, tu_unit) 
	VALUES
	('Type of unit', 'Unknown','Unknown'),
	('Type of unit', 'Area', 'm2'),
	('Type of unit', 'Linear', 'm'),
	('Type of unit', 'Percent', '%')
;
-----------------------------------------
-- Create Gear characteristic type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".gear_characteristic_type CASCADE;
CREATE TABLE "dbeel_nomenclature".gear_characteristic_type (
	CONSTRAINT gear_characteristic_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_gear_characteristic_type_Insert ON "dbeel_nomenclature".gear_characteristic_type;
CREATE TRIGGER TR_gear_characteristic_type_Insert BEFORE INSERT ON "dbeel_nomenclature".gear_characteristic_type
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_gear_characteristic_type_Update ON "dbeel_nomenclature".gear_characteristic_type;
CREATE TRIGGER TR_gear_characteristic_type_Update BEFORE UPDATE ON "dbeel_nomenclature".gear_characteristic_type 
   FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".gear_characteristic_type
	(no_type, no_name) 
	VALUES
	('Gear characteristic type', 'Unknown'),
	('Gear characteristic type', 'Stretched mesh size by the trap net'),
	('Gear characteristic type', 'Sieve area by net'),
	('Gear characteristic type', 'Net length')
;
-----------------------------------------
-- Create Migration direction table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".migration_direction CASCADE;
CREATE TABLE "dbeel_nomenclature".migration_direction (
	CONSTRAINT migration_direction_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_migration_direction_Insert ON "dbeel_nomenclature".migration_direction;
CREATE TRIGGER TR_migration_direction_Insert BEFORE INSERT ON "dbeel_nomenclature".migration_direction
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_migration_direction_Update ON "dbeel_nomenclature".migration_direction;
CREATE TRIGGER TR_migration_direction_Update BEFORE UPDATE ON "dbeel_nomenclature".migration_direction
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".migration_direction
	(no_type, no_name) 
	VALUES
	('Migration direction', 'Unknown'),
	('Migration direction', 'Upstream migration'),
	('Migration direction', 'Downstream migration')
;
-----------------------------------------
-- create Predator sub-type table
-----------------------------------------
DROP TABLE if exists "dbeel_nomenclature".Predator_subtype CASCADE;
CREATE TABLE "dbeel_nomenclature".Predator_subtype (
	CONSTRAINT Predator_subtype_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_Predator_subtype_Insert ON "dbeel_nomenclature".Predator_subtype;
CREATE TRIGGER TR_Predator_subtype_Insert BEFORE INSERT ON "dbeel_nomenclature".Predator_subtype
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_Predator_subtype_Update ON "dbeel_nomenclature".Predator_subtype;
CREATE TRIGGER TR_Predator_subtype_Check BEFORE UPDATE ON "dbeel_nomenclature".Predator_subtype
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".Predator_subtype
	(no_type, no_name) 
	VALUES
	('Predator_subtype', 'Cormorant')
;
-------------------------------------------
-- Create Obstruction impact table
-------------------------------------------
DROP TABLE if exists "dbeel_nomenclature".obstruction_impact CASCADE;
CREATE TABLE "dbeel_nomenclature".obstruction_impact (
	CONSTRAINT obstruction_impact_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_obstruction_impact_Insert ON "dbeel_nomenclature".obstruction_impact;
CREATE TRIGGER TR_obstruction_impact_Insert BEFORE INSERT ON "dbeel_nomenclature".obstruction_impact
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_obstruction_impact_Update ON "dbeel_nomenclature".obstruction_impact;
CREATE TRIGGER TR_obstruction_impact_Update BEFORE UPDATE ON "dbeel_nomenclature".obstruction_impact
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_update();

INSERT INTO "dbeel_nomenclature".obstruction_impact
	(no_type, no_name) 
	VALUES
	('Obstruction impact', 'Unknown'),
	('Obstruction impact', 'Unobtrusive and/or no barrier'),
	('Obstruction impact', 'Passable without apparent difficulty'),
	('Obstruction impact', 'Passable with some risk of delay'),
	('Obstruction impact', 'Difficult to pass'),
	('Obstruction impact', 'Very difficult to pass'),
	('Obstruction impact', 'Impassable')
;
-----------------------------------------------
-- Create Ecological productivity table
-----------------------------------------------
DROP TABLE if exists "dbeel_nomenclature".ecological_productivity CASCADE;
CREATE TABLE "dbeel_nomenclature".ecological_productivity (
	CONSTRAINT ecological_productivity_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_ecological_prod_Insert ON "dbeel_nomenclature".ecological_productivity;
CREATE TRIGGER TR_ecological_prod_Insert BEFORE INSERT ON "dbeel_nomenclature".ecological_productivity
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_ecological_prod_Update ON "dbeel_nomenclature".ecological_productivity;
CREATE TRIGGER TR_ecological_prod_Update BEFORE UPDATE ON "dbeel_nomenclature".ecological_productivity
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();

INSERT INTO "dbeel_nomenclature".ecological_productivity
	(no_type, no_name) 
	VALUES
	('Ecological productivity', 'Unknown'),
	('Ecological productivity', 'Good productivity'),
	('Ecological productivity', 'Bad productivity')
;
------------------------------------------
--  Create Obstruction type table
------------------------------------------
DROP TABLE if exists "dbeel_nomenclature".obstruction_type CASCADE;
CREATE TABLE "dbeel_nomenclature".obstruction_type (
	CONSTRAINT obstruction_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_obstruction_type_Insert ON "dbeel_nomenclature".obstruction_type;
CREATE TRIGGER TR_obstruction_type_Insert BEFORE INSERT ON "dbeel_nomenclature".obstruction_type
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_obstruction_type_Update ON "dbeel_nomenclature".obstruction_type;
CREATE TRIGGER TR_obstruction_type_Update BEFORE UPDATE ON "dbeel_nomenclature".obstruction_type
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();

INSERT INTO "dbeel_nomenclature".obstruction_type
	(no_type, no_name) 
	VALUES
	('Obstruction type', 'Unknown'),
	('Obstruction type', 'Physical obstruction'),
	('Obstruction type', 'Chemical obstruction')
;
------------------------------------------------
-- Create Predation type Table 
------------------------------------------------
DROP TABLE if exists "dbeel_nomenclature".predation_type CASCADE;
CREATE TABLE "dbeel_nomenclature".predation_type (
	CONSTRAINT predation_type_id PRIMARY KEY (no_id)
) INHERITS ("dbeel_nomenclature".nomenclature);
--DROP TRIGGER TR_predation_type_Insert ON "dbeel_nomenclature".predation_type;
CREATE TRIGGER TR_predation_type_Insert BEFORE INSERT ON "dbeel_nomenclature".predation_type
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();
--DROP TRIGGER TR_predation_type_Update ON "dbeel_nomenclature".predation_type;
CREATE TRIGGER TR_predation_type_Update BEFORE UPDATE ON "dbeel_nomenclature".predation_type
	FOR EACH ROW EXECUTE PROCEDURE "dbeel_nomenclature".nomenclature_id_insert();

INSERT INTO "dbeel_nomenclature".predation_type
	(no_type, no_name) 
	VALUES
	('Predation type', 'Unknown'),
	('Predation type', 'fishery'),
	('Predation type', 'wildlife')
;