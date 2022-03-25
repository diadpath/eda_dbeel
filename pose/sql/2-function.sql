
---************************************--
-- 	functions (including triggers)
---************************************--

-------------------------------------------
-- 	PRIMARY KEY
-------------------------------------------
----
-------------------------------
--- nomenclature table
-------------------------------
-- ensures that they will not have any tuples in no_id due to inheritance
DROP FUNCTION if exists"dbeel_nomenclature".nomenclature_id_insert() CASCADE;
CREATE or REPLACE FUNCTION "dbeel_nomenclature".nomenclature_id_insert() RETURNS TRIGGER AS
'
BEGIN
  PERFORM no_id FROM "dbeel_nomenclature".nomenclature WHERE no_id = NEW.no_id;
  IF FOUND THEN
	RAISE EXCEPTION ''1- Invalid no_id (%)'', NEW.no_id;
  ELSE
	RETURN NEW;
  END IF;
END
'
LANGUAGE 'plpgsql';

DROP FUNCTION if exists "dbeel_nomenclature".nomenclature_id_update() CASCADE;
CREATE or REPLACE FUNCTION "dbeel_nomenclature".nomenclature_id_update() RETURNS TRIGGER AS
'
BEGIN
  PERFORM no_id FROM "dbeel_nomenclature".nomenclature WHERE no_id = NEW.no_id;
  IF FOUND THEN
	RETURN NEW;
  ELSE
	RAISE EXCEPTION ''1- Invalid no_id (%)'', NEW.no_id;
  END IF;
END
'
LANGUAGE 'plpgsql';
------------------------------
-- observation_place table
------------------------------
-- ensures that they will not have any tuples in observation_place_id due to inheritance
DROP FUNCTION if exists "dbeel".id_observation_place_insert() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".observation_id_place_insert() RETURNS TRIGGER AS
'
BEGIN
  PERFORM os_id FROM "dbeel".observation_places WHERE op_id = NEW.op_id;
  IF FOUND THEN
	RAISE EXCEPTION ''2- Invalid op_id (%)'', NEW.op_id;
  ELSE
	RETURN NEW;
  END IF;
END
'
LANGUAGE 'plpgsql';

-- ensures that observation_place_id can not be updated
DROP FUNCTION if exists "dbeel".id_observation_place_update() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".observation_id_place_update() RETURNS TRIGGER AS
'
BEGIN
  IF NEW.op_id = OLD.op_id THEN
	RETURN NEW;
  ELSE
	RAISE EXCEPTION ''Do not update op_id (%)'', OLD.op_id;
  END IF;
END
'
LANGUAGE 'plpgsql';
--------------------------
--- observations table
--------------------------
-- ensures that they will not have any tuples in observations_id due to inheritance
DROP FUNCTION if exists dbeel.id_observations_insert() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".observations_id_insert() RETURNS TRIGGER AS
'
BEGIN
  PERFORM observations_id FROM "dbeel".observations WHERE ob_id = NEW.ob_id;
  IF FOUND THEN
	RAISE EXCEPTION ''3- Invalid ob_id (%)'', NEW.ob_id;
  ELSE
	RETURN NEW;
  END IF;
END
'
LANGUAGE 'plpgsql';

-- ensures that observation_place_id can not be updated
DROP FUNCTION if exists "dbeel".id_observations_update() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".observations_id_update() RETURNS TRIGGER AS
'
BEGIN
  IF NEW.observations_id = OLD.ob_id THEN
	RETURN NEW;
  ELSE
	RAISE EXCEPTION ''Do not update ob_id (%)'', OLD.ob_id;
  END IF;
END
'
LANGUAGE 'plpgsql';


-------------------------------------------
-- 	FOREIGN KEY (insert or update)
-------------------------------------------

-- ensures that ec_op_id exists
DROP FUNCTION IF EXISTS "dbeel".fk_id_environmental_characteristic_insert() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".fk_id_environmental_characteristic_insert() RETURNS TRIGGER AS
'
BEGIN
  PERFORM op_id FROM "dbeel".observation_places WHERE op_id = NEW.ec_op_id;
  IF FOUND THEN
	RETURN NEW;
  ELSE
	RAISE EXCEPTION ''5- Invalid ec_op_id (%)'', NEW.ec_op_id;
  END IF;
END
'
LANGUAGE 'plpgsql';


-- ensures that ob_op_id exists
DROP FUNCTION IF EXISTS "dbeel".fk_id_observations_insert() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".fk_id_observations_insert() RETURNS TRIGGER AS
'
BEGIN
  PERFORM op_id FROM "dbeel".observation_places WHERE op_id = NEW.ob_op_id;
  IF FOUND THEN
	RETURN NEW;
  ELSE
	RAISE EXCEPTION ''5- Invalid ob_op_id (%)'', NEW.ob_op_id;
  END IF;
END
'
LANGUAGE 'plpgsql';



-- ensures that observations_id exists;
DROP FUNCTION IF EXISTS "dbeel".fk_id_batch_insert() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".fk_id_batch_insert() RETURNS TRIGGER AS
'
BEGIN
  PERFORM ob_id FROM "dbeel".observations WHERE ob_id = NEW.ba_ob_id;
  IF FOUND THEN
	RETURN NEW;
  ELSE
	RAISE EXCEPTION ''6- Invalid ba_ob_id (%)'', NEW.ba_ob_id;
  END IF;
END
'
LANGUAGE 'plpgsql';

-------------------------------------------
-- 	FOREIGN KEY (delete)
-------------------------------------------
-- ensures that if observation_places is deleted no records refers to it
DROP FUNCTION if exists "dbeel".integrity_observation_places_verify() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".integrity_observation_places_verify() RETURNS TRIGGER AS
'
BEGIN
  PERFORM ob_op_id FROM "dbeel".observations WHERE ob_op_id = OLD.op_id;
  IF FOUND THEN
	RAISE EXCEPTION ''6- You try to delete an observation places record while there is some records in observations refering to it. op_id: (%)'', OLD.op_id;
  ELSE
	PERFORM ec_op_id FROM "dbeel".environmental_characteristic WHERE ec_op_id = OLD.op_id;
	IF FOUND THEN
		RAISE EXCEPTION ''6- You try to delete an observation places record while there is some records in environmental_characteristic refering to it. op_id: (%)'', OLD.op_id;
		ELSE
			RETURN OLD;
		END IF;
  END IF;
END
'
LANGUAGE 'plpgsql';

-- ensures that if observations is deleted no records refers to it;
DROP FUNCTION if exists "dbeel".integrity_observations_verify() CASCADE;
CREATE or REPLACE FUNCTION "dbeel".integrity_observations_verify() RETURNS TRIGGER AS
'
BEGIN
  PERFORM ba_ob_id FROM "dbeel".batch WHERE ba_ob_id = OLD.ob_id;
  IF FOUND THEN
	RAISE EXCEPTION ''6- You try to delete an observation record while there is some records in batch refering to it. ob_id: (%)'', OLD.ob_id;
  ELSE
	RETURN OLD;
  END IF;
END
'
LANGUAGE 'plpgsql';