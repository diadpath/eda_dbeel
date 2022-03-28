-------------------------------------------------
-- SCRIPT INTEGRATION OBSTACLES & HPP => DBEEL
-------------------------------------------------

--------------------------
-- inital modification
--------------------------

-- correction dbeel
ALTER TABLE dbeel.physical_obstruction 
ADD CONSTRAINT fk_ot_phys_obstruction_type FOREIGN KEY (ot_no_obstruction_type) REFERENCES dbeel_nomenclature.obstruction_type(no_id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE dbeel.physical_obstruction 
ADD CONSTRAINT fk_ot_mortality_type FOREIGN KEY (ot_no_mortality_type) REFERENCES dbeel_nomenclature.biological_characteristic_type(no_id) ON UPDATE CASCADE ON DELETE RESTRICT;

-- dump of rivers to dbeel pg_dump -U postgres --table spain.rivers -f "spain.rivers.sql" eda2.0
-- psql -U postgres  -c "create extension ltree" dbeel
-- psql -U postgres -f "spain.rivers.sql" dbeel

-- select st_srid(geom) from spain.rivers
ALTER TABLE spain.rivers
 ALTER COLUMN geom TYPE geometry(MultiLineString,3035) 
  USING ST_Transform(geom,3035);

REINDEX TABLE spain.rivers;

--------------------------
-- dbeel creation
--------------------------

---- Create the obs_place for obstacles
-- SELECT * FROM sudoang.dbeel_obstruction_place
-- alter table sudoang.dbeel_obstruction_place add column country character varying(2);
DROP TABLE if exists sudoang.dbeel_obstruction_place CASCADE;
CREATE TABLE sudoang.dbeel_obstruction_place (
		id_original character varying(10),
		country character varying(2),
        CONSTRAINT pk_obs_op_id PRIMARY KEY (op_id),
        CONSTRAINT c_uk_id_roe UNIQUE (id_original),
        CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
                REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
                MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places); 

-- Creation index spatial
CREATE INDEX 
  ON sudoang.dbeel_obstruction_place
  USING gist
  (the_geom);


---- Create physical obstruction
select * from sudoang.dbeel_physical_obstruction
DROP TABLE if exists sudoang.dbeel_physical_obstruction CASCADE;
CREATE TABLE sudoang.dbeel_physical_obstruction (
  fishway_type text,
  CONSTRAINT physical_obstruction_id PRIMARY KEY (ob_id),
  CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id),
  CONSTRAINT fk_ob_origin FOREIGN KEY (ob_no_origin)REFERENCES dbeel_nomenclature.observation_origin (no_id) ,
  CONSTRAINT fk_ob_period FOREIGN KEY (ob_no_period) REFERENCES dbeel_nomenclature.period_type (no_id) ,
  CONSTRAINT fk_ob_type FOREIGN KEY (ob_no_type) REFERENCES dbeel_nomenclature.observation_type (no_id) ,
  CONSTRAINT fk_po_obstruction_passability FOREIGN KEY (po_no_obstruction_passability)REFERENCES dbeel_nomenclature.obstruction_impact (no_id),
  CONSTRAINT fk_ot_obstruction_type FOREIGN KEY (ot_no_obstruction_type) REFERENCES dbeel_nomenclature.obstruction_type(no_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ot_mortality_type FOREIGN KEY (ot_no_mortality_type) REFERENCES dbeel_nomenclature.biological_characteristic_type(no_id) ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS(dbeel.physical_obstruction);


/* TODO MARIA / LAURENT (María done)
ALTER TABLE sudoang.dbeel_physical_obstruction ADD CONSTRAINT c_fk_ob_op_id FOREIGN KEY (ob_op_id) references sudoang.dbeel_obstruction_place(op_id) on update cascade on delete cascade;
*/


---------------------------------------------------
-- First data incorporated = spain_obstruction
---------------------------------------------------

-- Improve spain_obstruction_in_spain table
-- with index
CREATE INDEX 
  ON sudoang.spain_obstruction_in_spain
  USING gist
  (geom);

--------------------------------------------------------------------------------------------
-- with reprojection on the river
-- these are only those that are in spain, a lot of points were outside from the country
--------------------------------------------------------------------------------------------

select addgeometrycolumn('sudoang','spain_obstruction_in_spain','geom_reproj',3035,'POINT',2);
-- select * from sudoang.spain_obstruction_in_spain --3120
update sudoang.spain_obstruction_in_spain set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj,distance from(
select
id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj ,
ST_distance(r.geom,s.geom) as distance
from sudoang.spain_obstruction_in_spain s join
spain.rivers r on st_dwithin(r.geom,s.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= spain_obstruction_in_spain.id;

CREATE INDEX 
  ON sudoang.spain_obstruction_in_spain
  USING gist
  (geom_reproj);
  
-- to store the link for dbeel
ALTER TABLE sudoang.spain_obstruction_in_spain ADD COLUMN dbeel_op_id uuid;  
  
-- !!! some duplicate inside the spain_obstruction_in_spain table
-- eg SO_288 and SO_874 which have different ALT_CAU !!!
-- internal duplicate here
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.spain_obstruction_in_spain AS sp1, sudoang.spain_obstruction_in_spain AS sp2
	WHERE substring(sp1.id from 4) < substring(sp2.id from 4) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 4)::integer
;

INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id, 
	'SUDOANG' AS op_gis_systemname, 
	'spain_obstruction_in_spain' AS op_gis_layername, NULL AS op_gislocation, 
	NULL AS op_placename, 11 AS op_no_observationplacetype, 
	NULL op_op_id, geom_reproj AS the_geom, 
	NULL AS id_original, 
	'SP' AS country
	FROM (SELECT DISTINCT geom_reproj FROM sudoang.spain_obstruction_in_spain WHERE geom_reproj IS NOT NULL) unique_obs; --2414 / only the one projected on rivers
-- select * from sudoang.dbeel_obstruction_place
-- record back the link with dbeel
-- UPDATE sudoang.spain_obstruction_in_spain SET dbeel_op_id = NULL; -- to reset the column
-- select * from sudoang.spain_obstruction_in_spain limit 10;
UPDATE sudoang.spain_obstruction_in_spain SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE ST_DWithin(geom_reproj, the_geom, 0.1) AND op_gis_layername='spain_obstruction_in_spain';	-- 2487
	
-- choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'SO_' || max(substring(id from 4)::integer) AS id FROM sudoang.spain_obstruction_in_spain WHERE dbeel_op_id IS NOT NULL  GROUP BY dbeel_op_id)
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id FROM id_obs WHERE op_id = dbeel_op_id;--2414

/* TODO MARIA / LAURENT
update sudoang.dbeel_obstruction_place set op_placename = sub.placename from
( select INITCAP("NOMBRE") as placename, op_id from sudoang.dbeel_obstruction_place 
join sudoang.spain_obstruction_in_spain on spain_obstruction_in_spain.dbeel_op_id=dbeel_obstruction_place.op_id) sub
where dbeel_obstruction_place.op_id=sub.op_id ; -- 2414

-- remove dams in project form dbeel

with proyecto as (
select * from sudoang.dbeel_obstruction_place
join sudoang.spain_obstruction_in_spain 
on spain_obstruction_in_spain.dbeel_op_id=dbeel_obstruction_place.op_id
where "SITUACION" like '%Proyecto%'
or  "SITUACION" like 'Demolida'
or  "SITUACION" like 'Abandonada')
delete from sudoang.dbeel_obstruction_place where op_id in (select dbeel_op_id from proyecto); --485
*/

---- Load spain data
-- add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('min esp'); --TODO: TO BE MODIFIED spanish minstry
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Belen', et_id FROM dbeel.establishment WHERE et_establishment_name = 'min esp';

-- Insert into dbeel_physical_obstruction
INSERT INTO sudoang.dbeel_physical_obstruction
	WITH spain_obs AS
	(
		SELECT *, case when "ALT_CAU" is not NULL AND "ALT_CAU">0.0  then "ALT_CAU"
	else REPLACE("ALT_CIM", ',', '.')::numeric end AS height
		FROM sudoang.spain_obstruction_in_spain
		WHERE dbeel_op_id IS NOT NULL
	), spain_obs_max_height AS
	(
		SELECT dbeel_op_id, max(height) AS height FROM spain_obs GROUP BY dbeel_op_id --max is choosen, if mean the process should be different
	)
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type,-- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  height AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM spain_obs_max_height JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider WHERE dp_name = 'Belen' --TODO: TO BE MODIFIED
; -- 2414

select * from sudoang.dbeel_physical_obstruction

-- Update the type of obstacles
select * from sudoang.spain_obstruction_in_spain where dbeel_op_id is not null; -- 2487 rows (total 3120 rows (dams of the Spanish Inventory of Dams))
select distinct "TIPOPRESA" from sudoang.spain_obstruction_in_spain; -- numbers...What is its meaning?

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.spain_obstruction_in_spain WHERE dbeel_op_id = ob_op_id; -- 1929 rows


------ HPP DATA IMPORT from Spain

------		1. spain_obstrution_hpp (central.shp of Aprovechamiento_hidroelectrico folder (sent by Belen Muñoz, Spanish Government)) 
------			(row 77 of dbeel_sudoang_obstruction.sql script) NOT updated (2002)!
------		NOT IMPORTED because the data are obsolete until 2002

------		2. spain_obstrution_hpp_bis (Tiposdeturbinas Endesa Anguila table (sent by Cristina Rivero Fernández, AELEC)) (row 86 of GT2_obstacles.R script)

-- Move the table to sudoang schema from public
ALTER TABLE spain_obstruction_hpp_bis SET SCHEMA sudoang;

ALTER TABLE sudoang.spain_obstruction_hpp_bis RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.spain_obstruction_hpp_bis
  USING gist
  (geom);

select * from sudoang.spain_obstruction_hpp_bis; -- 26 rows

---- Reproject on the rivers
select st_srid(geom) from sudoang.spain_obstruction_hpp_bis -- 3035

SELECT addgeometrycolumn('sudoang','spain_obstruction_hpp_bis','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

begin;
update sudoang.spain_obstruction_hpp_bis set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.spain_obstruction_hpp_bis a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id = spain_obstruction_hpp_bis.id; -- 56 rows
commit;

CREATE INDEX 
  ON sudoang.spain_obstruction_hpp_bis
  USING gist
  (geom_reproj);
  
---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.spain_obstruction_hpp_bis AS sp1, sudoang.spain_obstruction_hpp_bis AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

---- Link Spain hpp TO dbeel
ALTER TABLE sudoang.spain_obstruction_hpp_bis add COLUMN dam_id character varying (10);
ALTER TABLE sudoang.spain_obstruction_hpp_bis add column dam_dbeel boolean default FALSE


---- FIND the nearest DAM to associate the HPP
begin;
WITH duplicate AS 
(
	SELECT DISTINCT geom_reproj, id, id_original, op_placename, central, st_distance(the_geom, geom_reproj) as distance, op_gis_layername
	FROM sudoang.spain_obstruction_hpp_bis, sudoang.dbeel_obstruction_place
	WHERE geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by distance -- 20 rows
), 
uq_duplicates as (
	select distinct on (id) * from duplicate
)
--select * from uq_duplicates -- 17 rows (from miteco (spain_obstruction_in_spain), but also UCO and AMBER)
UPDATE sudoang.spain_obstruction_hpp_bis SET (dam_id, dam_dbeel) = (id_original, TRUE)
FROM uq_duplicates
WHERE spain_obstruction_hpp_bis.id = uq_duplicates.id
; -- 17 rows
commit;

-- Check duplicates
with spain_dams as (
	select * from sudoang.dbeel_obstruction_place d 
	join 
	sudoang.spain_obstruction_hpp_bis h on d.id_original = h.dam_id
	)
select * from sudoang.view_dbeel_hpp join spain_dams on spain_dams.op_id = sudoang.view_dbeel_hpp.op_id; -- 12 rows

alter table sudoang.spain_obstruction_hpp_bis add column hpp_duplicate boolean default false;
alter table sudoang.spain_obstruction_hpp_bis add column dbeel_hpp_id uuid;

-- Update the hpp_id of duplicates 
with spain_dams as (
	select * from sudoang.dbeel_obstruction_place d 
	join 
	sudoang.spain_obstruction_hpp_bis h on d.id_original = h.dam_id
	),
spain_hpp as (
	select spain_dams.*, hpp.op_id, hpp.op_gis_layername, hpp.op_placename, hpp.id_original, hpp.ob_id, hpp.ob_dp_id, hpp.po_obstruction_height, hpp.comment_update, hpp.hpp_id, hpp.hpp_name, hpp.hpp_nb_turbines, hpp.hpp_id_original 
	from sudoang.view_dbeel_hpp hpp join spain_dams on spain_dams.op_id = hpp.op_id -- 12 rows
	)
--select * from spain_hpp; -- 12 rows
update sudoang.spain_obstruction_hpp_bis SET (hpp_duplicate, dbeel_hpp_id) = (TRUE, hpp_id)
from spain_hpp
where spain_obstruction_hpp_bis.id = spain_hpp.id; -- 12 rows

select * from sudoang.spain_obstruction_hpp_bis
-- Import hpp data
begin;
with closest_dam as (
	select d.op_id, po.ob_op_id, po.ob_id, o.* from sudoang.dbeel_obstruction_place d join sudoang.spain_obstruction_hpp_bis o on o.dam_id = d.id_original 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	where hpp_duplicate = FALSE
	)
--select * from closest_dam; -- 5 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_name, hpp_nb_turbines, hpp_id_original)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		central as hpp_name, 
		nb_groups as hpp_nb_turbines, 
		id as hpp_id_original
	FROM closest_dam
; -- 5 rows
COMMIT;

---- Record back the link with dbeel: hpp_id of hpp (inserted into the dbeel) are inserted into the source table (spain_obstruction_hpp_bis)
UPDATE sudoang.spain_obstruction_hpp_bis SET dbeel_hpp_id = hpp_id 
FROM sudoang.dbeel_hpp 
WHERE id = hpp_id_original AND central = hpp_name and hpp_duplicate = FALSE; -- 5 rows

-- TODO:  7 HPP with geom not inserted as dbeel_obstruction_place

-- Create table of TURBINES with the rows duplicated in case more than one turbine exist
CREATE TABLE sudoang.spain_obstruction_turbine AS
  SELECT * FROM sudoang.spain_obstruction_hpp_bis where dam_dbeel = TRUE; -- 17 rows

INSERT INTO sudoang.spain_obstruction_turbine SELECT * FROM sudoang.spain_obstruction_turbine WHERE nb_groups > 1; -- 10 rows
INSERT INTO sudoang.spain_obstruction_turbine SELECT * FROM sudoang.spain_obstruction_turbine WHERE nb_groups > 3; -- 4 rows
INSERT INTO sudoang.spain_obstruction_turbine SELECT distinct on (central) * FROM sudoang.spain_obstruction_turbine WHERE central = 'Pintado'; -- 1 rows
INSERT INTO sudoang.spain_obstruction_turbine SELECT distinct on (central) * FROM sudoang.spain_obstruction_turbine WHERE central = 'El Corchado'; -- 1 rows
select * from sudoang.spain_obstruction_turbine order by central; -- 31 rows

-- Check the duplicates of turbine
select distinct on (central) * from sudoang.spain_obstruction_turbine join sudoang.dbeel_turbine on dbeel_hpp_id = turb_hpp_id; -- 12 rows

update sudoang.spain_obstruction_turbine set turb_type_code = 251 where turb_type = 'Francis' and position = 'Horizontal'; -- 1 row
update sudoang.spain_obstruction_turbine set turb_type_code = 245 where turb_type = 'Francis' and position = 'Vertical'; -- 14 row


-- Import turbine data ONLY when hpp_duplicate = FALSE
begin;
INSERT INTO sudoang.dbeel_turbine(
	turb_id, turb_hpp_id, turb_turbine_type_no_id)
	SELECT
		uuid_generate_v4() AS turb_id,
		dbeel_hpp_id AS turb_hpp_id,
		turb_type_code as turb_turbine_type_no_id
	FROM sudoang.spain_obstruction_turbine where hpp_duplicate = FALSE
; -- 10 rows
COMMIT;


------		3. spain_obstrution_hpp_edp (edp_plantilla_obstaculos_SUDOANG.1 table (sent by Cristina Rivero Fernández, AELEC)) (row  of GT2_obstacles.R script)


---------------------------------------------------
-- Second data incorporated = AMBER
---------------------------------------------------

-- Add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('AMBER Project'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Rosa', et_id FROM dbeel.establishment WHERE et_establishment_name = 'AMBER Project'; --TODO: TO BE MODIFIED

-- Creation index spatial
CREATE INDEX 
  ON sudoang.amber
  USING gist
  (geom);

-- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','amber','geom_reproj',3035,'POINT',2);
update sudoang.amber set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj,distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj ,
ST_distance(r.geom,a.geom) as distance
from sudoang.amber a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= amber.id; -- 16809

CREATE INDEX 
  ON sudoang.amber
  USING gist
  (geom_reproj);

-- Link amber TO dbeel
ALTER TABLE sudoang.amber ADD COLUMN dbeel_op_id uuid;
-- update sudoang.amber set dbeel_op_id = NULL
-- check for internal duplicate
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.amber AS sp1, sudoang.amber AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer;

-- Duplicate with data already in dbeel
-- UPDATE sudoang.amber SET dbeel_op_id = NULL; -- to reset the column
-- the query is called duplicates but it is in fact to avoid duplicated
WITH duplicate_amber AS 
(
	SELECT DISTINCT geom_reproj, op_id
	FROM sudoang.amber, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'ASP%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) -- to be tuned
) 
UPDATE sudoang.amber SET dbeel_op_id = op_id
FROM duplicate_amber 
WHERE id LIKE 'ASP%' AND amber.geom_reproj IS NOT NULL AND amber.geom_reproj = duplicate_amber.geom_reproj
; --1190

-- Update height for these dams
WITH amber_obs AS
(
	SELECT *, REPLACE(REPLACE(height, ',', '.'), ' ', '') AS height2
	FROM sudoang.amber
	WHERE dbeel_op_id IS NOT NULL
), amber_obs_max_height AS
(
	SELECT dbeel_op_id, max(height2) AS height FROM amber_obs GROUP BY dbeel_op_id --max is choosen, if mean the process should be different
)	
UPDATE sudoang.dbeel_physical_obstruction SET po_obstruction_height = height::real FROM amber_obs_max_height
WHERE dbeel_op_id = ob_op_id AND po_obstruction_height < height::real; --147

-- Insert new dams
--select * from sudoang.dbeel_obstruction_place
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.amber WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
	 'SUDOANG' AS op_gis_systemname,
	  'amber' AS op_gis_layername, 
	  NULL AS op_gislocation, 
	  NULL AS op_placename, 11 AS op_no_observationplacetype, 
	  NULL op_op_id, 
	  geom_reproj AS the_geom,
	   NULL AS id_original,
	   'SP' AS country
	FROM unique_obs; --15571

-- Record back the link with dbeel
-- UPDATE sudoang.amber SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.amber SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='amber';	-- 15619
	
-- Choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'ASP_' || max(substring(id from 5)::integer) AS id FROM sudoang.amber WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id)
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='amber'; --15571

-- Insert new data
INSERT INTO sudoang.dbeel_physical_obstruction
	WITH amber_obs AS
	(
		SELECT *, REPLACE(REPLACE(height, ',', '.'), ' ', '')::real AS height2
		FROM sudoang.amber
		WHERE dbeel_op_id IS NOT NULL
		AND NOT (height LIKE '%-%' OR height LIKE '%>%' OR height LIKE '%a%')
	), amber_obs_max_height AS
	(
		SELECT dbeel_op_id, max(height2)::real AS height FROM amber_obs GROUP BY dbeel_op_id --max is choosen, if mean the process should be different
	)
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type,-- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  height::real AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM amber_obs_max_height JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Rosa' --TODO: TO BE MODIFIED
	AND op_gis_layername='amber'
; -- 12766

INSERT INTO sudoang.dbeel_physical_obstruction
	WITH amber_obs AS
	(
		SELECT *
		FROM sudoang.amber
		WHERE dbeel_op_id IS NOT NULL
		AND height is null
	), amber_obs_max_height AS
	(
		SELECT dbeel_op_id, max(height)::real AS height FROM amber_obs GROUP BY dbeel_op_id --max is choosen, if mean the process should be different
	)
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type,-- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  height AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM amber_obs_max_height JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Rosa' --TODO: TO BE MODIFIED
	AND op_gis_layername='amber'; --2808

select count(*) from 	sudoang.dbeel_physical_obstruction ; 14695
select * from sudoang.dbeel_physical_obstruction where ob_op_id = 'd596a65c-c681-412c-a417-5b65a12ff203'
select * from sudoand.dbeel_observation_places 
select * from sudoang.amber limit 1000;

/*
pg_dump -U postgres --table spain.rivers -f "spain_rivers_dbeel.sql" dbeel
pg_dump -U postgres --table sudoang.spain_obstruction --table sudoang.catalonia_obstruction --table sudoang.catalonia_obstruction_dams --table sudoang.catalonia_obstruction_hpp --table sudoang.minho_obstruction --table sudoang.amber  --table sudoang.fcul_obstruction --table sudoang.galicia_obstruction  --table sudoang.catalonia_obstruction_join_dams_hpp  --table sudoang.spain_obstruction_in_spain  --table sudoang.spain_obstruction_not_in_spain -f "all_obstacle_tables_except_dbeel.sql" dbeel
dbeel.physical_obstruction --table dbeel.physical_obstruction --table sudoang.dbeel_obstruction_place --table
*/

/*
Find duplicated values within the actual layer
*/
create view sudoang.view_physical_obstruction as select * from sudoang.dbeel_obstruction_place join sudoang.dbeel_physical_obstruction on ob_op_id=op_id;

WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2, sp1.sbruto_m FROM 
	sudoang.spain_obstruction_in_spain AS sp1 JOIN
	sudoang.spain_obstruction_in_spain AS sp2 ON
	ST_dwithin(sp1.geom, sp2.geom,10)
	where sp1.id != sp2.id 
	and substring(sp1.id from 4) < substring(sp2.id from 4)
	order by substring(sp1.id from 4)::numeric,
	substring(sp2.id from 4)::numeric
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 4)::integer,sbruto_m, rank;

select * from sudoang.spain_obstruction_in_spain where id in ('SO_969','SO_971')

/*
geom;dmer;n_silver_pred_upstream;id_hpp;potencia_t;corriente;sbruto_m;no_eel_above;riverwidth;id;dbeel_op_id;geom_reproj
0101000020DB0B0000CBE4AA1D36FF4A416A0247DF2B204041;211165.990574708;13.780044252366054804528391143231817756980813847140000;994.00000;0.00000;Canal de Baix de Piñana;5.30000;f;6.66843581766864776206;SO_969;;
0101000020DB0B0000CBE4AA1D36FF4A416A0247DF2B204041;211165.990574708;13.780044252366054804528391143231817756980813847140000;995.00000;0.00000;Canal de Baix de Piñana;11.00000;f;6.66843581766864776206;SO_971;;
*/

/*
Dans la récurisve ci dessous la premire partie cree un tableau avec (id1 id2 s_bruto)
Ou les id1 sont à moins de xx m de distance de id2
Plusieurs ouvrages peuvent être à distance proche...

Dans la deuxième partie, récursive, (search_path est la vraie récursive mais il faut mettre récursive en tête)
on fait une jointure entre id2 et id1 qui s'arrête quand il n'y a plus de lien. Cet arrêt est dans la colonne cycle.
Un petit truc que j'ai mis du temps à trouver c'est le ::text, sinon j'avais des incompatible type character varying 10
et charcater varying, et si j'essayais de caster en character varying je perdais array, et si j'assayais character varying[] ça
marchait pas...

Ci dessous il y a plusieurs niveaux d'agréggation, par exemple chain5_et_ses_petits correspond à 
id1;id2;sbruto_m;depth;path
SO_180;SO_181;;5;{SO_188,SO_187,SO_183,SO_181,SO_180}
SO_180;SO_181;;4;{SO_187,SO_183,SO_181,SO_180}
SO_181;SO_183;;4;{SO_188,SO_187,SO_183,SO_181}
SO_180;SO_183;;4;{SO_188,SO_187,SO_183,SO_180}
SO_180;SO_181;;4;{SO_187,SO_183,SO_181,SO_180}
SO_180;SO_181;;4;{SO_188,SO_183,SO_181,SO_180}
SO_180;SO_181;;4;{SO_188,SO_187,SO_181,SO_180}
SO_180;SO_183;;3;{SO_187,SO_183,SO_180}
SO_180;SO_181;;3;{SO_187,SO_181,SO_180}
SO_183;SO_187;;3;{SO_188,SO_187,SO_183}
SO_181;SO_187;;3;{SO_188,SO_187,SO_181}
SO_180;SO_187;;3;{SO_188,SO_187,SO_180}
SO_181;SO_183;;3;{SO_188,SO_183,SO_181}
SO_180;SO_183;;3;{SO_188,SO_183,SO_180}
SO_180;SO_181;;3;{SO_188,SO_181,SO_180}
SO_180;SO_181;;3;{SO_183,SO_181,SO_180}
SO_180;SO_181;;3;{SO_183,SO_181,SO_180}
SO_180;SO_181;;3;{SO_183,SO_181,SO_180}
SO_181;SO_183;;3;{SO_187,SO_183,SO_181}
SO_180;SO_183;;3;{SO_187,SO_183,SO_180}
....
Donc j'enlève ensuite toutes les lignes contenant un élement de SO_180;SO_181;;5;{SO_188,SO_187,SO_183,SO_181,SO_180}
Puis je continue à l'étape 4 ...
*/

WITH grouped_array as(
WITH RECURSIVE graph as (SELECT sp1.id AS id1, sp2.id AS id2 FROM 
	sudoang.spain_obstruction_in_spain AS sp1 JOIN
	sudoang.spain_obstruction_in_spain AS sp2 ON
	ST_dwithin(sp1.geom, sp2.geom,10)
	where sp1.id != sp2.id 
	and substring(sp1.id from 4) < substring(sp2.id from 4)
	order by substring(sp1.id from 4)::numeric,
	substring(sp2.id from 4)::numeric),
	
 search_graph(id1, id2, depth, path, cycle) AS (
        SELECT g.id1, g.id2,  1,
          ARRAY[g.id1::text],
          false
        from graph g
      UNION ALL
        SELECT g.id1, g.id2, sg.depth + 1,
          path || ARRAY[g.id1::text],
          sg.id2 in (select g.id1 from graph)
        FROM graph g, search_graph sg
        WHERE g.id2 = sg.id1 
        AND NOT cycle
)
SELECT  id1, id2, path, depth -- (cycle) j'ai plus besoin de cycle qui servait dans la partie récursive 
FROM search_graph order by depth desc 
),--grouped_array,
chain5 as (select * from grouped_array where depth =5),
chain4 as (select * from grouped_array where depth =4),
chain3 as (select * from grouped_array where depth =3),
chain2 as (select * from grouped_array where depth =2),

chain5_et_ses_petits as (
select grouped_array.* from chain5 JOIN grouped_array on chain5.path && grouped_array.path),

chain4_et_ses_petits as (
select grouped_array.* from chain4 JOIN grouped_array on chain4.path && grouped_array.path
where chain4.path not in (select path from chain5_et_ses_petits)),

chain3_et_ses_petits as (
select grouped_array.* from chain3 JOIN grouped_array on chain3.path && grouped_array.path
where chain3.path not in (select path from chain4_et_ses_petits)
and chain3.path not in (select path from chain5_et_ses_petits)),

chain2_et_ses_petits as (
select grouped_array.* from chain2 JOIN grouped_array on chain2.path && grouped_array.path
where chain2.path not in (select path from chain3_et_ses_petits)
and chain2.path not in (select path from chain4_et_ses_petits)
and chain2.path not in (select path from chain5_et_ses_petits)),

chain1 as (
select * from grouped_array where depth=1
and grouped_array.path not in (select path from chain2_et_ses_petits)
and grouped_array.path not in (select path from chain3_et_ses_petits)
and grouped_array.path not in (select path from chain4_et_ses_petits)
and grouped_array.path not in (select path from chain5_et_ses_petits)),

bigunion as (
select * from chain5_et_ses_petits where depth=5
UNION
select * from chain4_et_ses_petits where depth=4
UNION
select * from chain3_et_ses_petits where depth=3
UNION
select * from chain2_et_ses_petits where depth=2
UNION
select * from chain1)

select * from bigunion order by depth desc, id1

/*
id1;id2;path;depth
SO_180;SO_181;{SO_188,SO_187,SO_183,SO_181,SO_180};5
SO_2158;SO_2161;{SO_2164,SO_2162,SO_2161,SO_2158};4
SO_14;SO_15;{SO_16,SO_15,SO_14};3
SO_2195;SO_2196;{SO_2197,SO_2196,SO_2195};3
SO_2697;SO_2698;{SO_2700,SO_2698,SO_2697};3
SO_3049;SO_3050;{SO_3051,SO_3050,SO_3049};3
SO_1472;SO_1945;{SO_1945,SO_1472};2
SO_2641;SO_2642;{SO_2642,SO_2641};2
SO_2682;SO_2683;{SO_2683,SO_2682};2
SO_3084;SO_3086;{SO_3086,SO_3084};2
SO_1046;SO_1252;{SO_1046};1
SO_1047;SO_120;{SO_1047};1
SO_1167;SO_3021;{SO_1167};1
SO_118;SO_119;{SO_118};1
SO_1217;SO_1398;{SO_1217};1
SO_1234;SO_1235;{SO_1234};1
SO_1243;SO_3102;{SO_1243};1
SO_1282;SO_1283;{SO_1282};1
SO_1299;SO_1300;{SO_1299};1
SO_1302;SO_1303;{SO_1302};1
SO_1309;SO_2232;{SO_1309};1
SO_1312;SO_3276;{SO_1312};1
SO_1504;SO_3308;{SO_1504};1
SO_1518;SO_1519;{SO_1518};1
SO_1567;SO_1568;{SO_1567};1
SO_1635;SO_1637;{SO_1635};1
SO_1852;SO_3344;{SO_1852};1
SO_1868;SO_1869;{SO_1868};1
SO_1902;SO_1903;{SO_1902};1
SO_198;SO_491;{SO_198};1
SO_2059;SO_2060;{SO_2059};1
SO_2064;SO_3377;{SO_2064};1
SO_2075;SO_2076;{SO_2075};1
SO_2129;SO_2134;{SO_2129};1
SO_2141;SO_3384;{SO_2141};1
SO_2186;SO_2187;{SO_2186};1
SO_2200;SO_2202;{SO_2200};1
SO_229;SO_230;{SO_229};1
SO_2299;SO_3412;{SO_2299};1
SO_2303;SO_3413;{SO_2303};1
SO_2320;SO_2321;{SO_2320};1
SO_2323;SO_2324;{SO_2323};1
SO_2340;SO_2341;{SO_2340};1
SO_2366;SO_2367;{SO_2366};1
SO_2393;SO_2395;{SO_2393};1
SO_2396;SO_2397;{SO_2396};1
SO_2450;SO_2451;{SO_2450};1
SO_2507;SO_2594;{SO_2507};1
SO_2567;SO_2569;{SO_2567};1
SO_2585;SO_2586;{SO_2585};1
SO_2770;SO_2771;{SO_2770};1
SO_2812;SO_2822;{SO_2812};1
SO_2842;SO_2843;{SO_2842};1
SO_2847;SO_2848;{SO_2847};1
SO_288;SO_874;{SO_288};1
SO_2915;SO_2923;{SO_2915};1
SO_2916;SO_2924;{SO_2916};1
SO_292;SO_79;{SO_292};1
SO_2979;SO_2980;{SO_2979};1
SO_2981;SO_2983;{SO_2981};1
SO_3026;SO_3027;{SO_3026};1
SO_3081;SO_962;{SO_3081};1
SO_313;SO_315;{SO_313};1
SO_3150;SO_3153;{SO_3150};1
SO_3170;SO_3171;{SO_3170};1
SO_3185;SO_3614;{SO_3185};1
SO_3329;SO_3330;{SO_3329};1
SO_3386;SO_3387;{SO_3386};1
SO_339;SO_340;{SO_339};1
SO_3460;SO_3461;{SO_3460};1
SO_3532;SO_3533;{SO_3532};1
SO_3619;SO_3620;{SO_3619};1
SO_374;SO_382;{SO_374};1
SO_42;SO_44;{SO_42};1
SO_456;SO_457;{SO_456};1
SO_969;SO_971;{SO_969};1
*/

select * from sudoang.dbeel_obstruction_place where id_original in  ('SO_188','SO_183','SO_181','SO_180');
select * from sudoang.dbeel_obstruction_place where id_original in  ('SO_2164','SO_2162','SO_2161','SO_2158')
-- Ces entités n'ont pas de géométrie

WITH grouped_array as(
WITH RECURSIVE graph as (SELECT sp1.id AS id1, sp2.id AS id2 FROM 
	sudoang.spain_obstruction_in_spain AS sp1 JOIN
	sudoang.spain_obstruction_in_spain AS sp2 ON
	ST_dwithin(sp1.geom, sp2.geom,10)
	where sp1.id != sp2.id 
	and substring(sp1.id from 4) < substring(sp2.id from 4)
	order by substring(sp1.id from 4)::numeric,
	substring(sp2.id from 4)::numeric),
	
 search_graph(id1, id2, depth, path, cycle) AS (
        SELECT g.id1, g.id2,  1,
          ARRAY[g.id1::text],
          false
        from graph g
      UNION ALL
        SELECT g.id1, g.id2, sg.depth + 1,
          path || ARRAY[g.id1::text],
          sg.id2 in (select g.id1 from graph)
        FROM graph g, search_graph sg
        WHERE g.id2 = sg.id1 
        AND NOT cycle
)
SELECT  id1, id2, path, depth -- (cycle) j'ai plus besoin de cycle qui servait dans la partie récursive 
FROM search_graph order by depth desc 
),--grouped_array,
chain5 as (select * from grouped_array where depth =5),
chain4 as (select * from grouped_array where depth =4),
chain3 as (select * from grouped_array where depth =3),
chain2 as (select * from grouped_array where depth =2),

chain5_et_ses_petits as (
select grouped_array.* from chain5 JOIN grouped_array on chain5.path && grouped_array.path),

chain4_et_ses_petits as (
select grouped_array.* from chain4 JOIN grouped_array on chain4.path && grouped_array.path
where chain4.path not in (select path from chain5_et_ses_petits)),

chain3_et_ses_petits as (
select grouped_array.* from chain3 JOIN grouped_array on chain3.path && grouped_array.path
where chain3.path not in (select path from chain4_et_ses_petits)
and chain3.path not in (select path from chain5_et_ses_petits)),

chain2_et_ses_petits as (
select grouped_array.* from chain2 JOIN grouped_array on chain2.path && grouped_array.path
where chain2.path not in (select path from chain3_et_ses_petits)
and chain2.path not in (select path from chain4_et_ses_petits)
and chain2.path not in (select path from chain5_et_ses_petits)),

chain1 as (
select * from grouped_array where depth=1
and grouped_array.path not in (select path from chain2_et_ses_petits)
and grouped_array.path not in (select path from chain3_et_ses_petits)
and grouped_array.path not in (select path from chain4_et_ses_petits)
and grouped_array.path not in (select path from chain5_et_ses_petits)),

bigunion as (
select * from chain5_et_ses_petits where depth=5
UNION
select * from chain4_et_ses_petits where depth=4
UNION
select * from chain3_et_ses_petits where depth=3
UNION
select * from chain2_et_ses_petits where depth=2
UNION
select * from chain1)
select * from sudoang.dbeel_obstruction_place where id_original in (
select unnest(path) from bigunion)

-- un seul SO_1047
select * from sudoang.dbeel_obstruction_place
join sudoang.spain_obstruction_in_spain 
on spain_obstruction_in_spain.dbeel_op_id=dbeel_obstruction_place.op_id
where id_original = 'SO_1047'

-- Le deuxième c'est le canal, il est pas dans la table, mais le lien a été copié ... Pas très grave,
-- dans spain_obstruction_in_spain on a deux lignes avec le même op_id, une pour SO_1047 et une pour SO_120

---- Presence of an eel pass:
SELECT distinct fishpasstypelabel FROM sudoang.amber where id is not null; 

update sudoang.dbeel_physical_obstruction SET (po_presence_eel_pass, fishway_type) = (true, '270')
	from sudoang.amber WHERE dbeel_op_id = ob_op_id and "fishpasstypelabel" = 'Vertical cutout'; -- 1 rows

update sudoang.dbeel_physical_obstruction SET (po_presence_eel_pass, fishway_type) = (true, '271')
	from sudoang.amber WHERE dbeel_op_id = ob_op_id and "fishpasstypelabel" = 'Successive ponds'; -- 64 rows

with denil_pass as (
	select * from sudoang.amber where  ("fishpasstypelabel" = 'Decelerators' OR "fishpasstypelabel" = 'Retarders') and dbeel_op_id is not null)
update sudoang.dbeel_physical_obstruction SET (po_presence_eel_pass, fishway_type) = (FALSE, '273')
	from denil_pass WHERE dbeel_op_id = ob_op_id; -- 41 rows

with undefined as (
	select * from sudoang.amber where ("fishpasstypelabel" = 'YES' or "fishpasstypelabel" = 'UNDEFINED' or "fishpasstypelabel" = 'A small pass'
	 or "fishpasstypelabel" = 'Ramps' or "fishpasstypelabel" = 'Yes' or "fishpasstypelabel" = 'Others') and dbeel_op_id is not null)
update sudoang.dbeel_physical_obstruction SET (po_presence_eel_pass, fishway_type) = (FALSE, '279')
	from undefined WHERE dbeel_op_id = ob_op_id; -- 1480 rows

with no_pass as (
	select * from sudoang.amber where  ("fishpasstypelabel" = 'NONE' or "fishpasstypelabel" = 'No' or "fishpasstypelabel" = 'no' or "fishpasstypelabel" = 'Without fishway') 
	and dbeel_op_id is not null)
update sudoang.dbeel_physical_obstruction SET po_presence_eel_pass = FALSE
	from no_pass WHERE dbeel_op_id = ob_op_id; -- 2346 rows

---- Type of obstacles
select distinct labelatlas, labelsource from sudoang.amber where dbeel_op_id is not null;
/*
|labelatlas	|labelsource				|
|Dam		|					|
|Dam		|Ground with screen			|
|Dam		|Loose materials with curved pl		|
|Unknown	|Ground					|
|Weir		|Weir - Mobile gates			|
|Unknown	|Buttresses				| -- DAM
|Unknown	|Mixed: concrete in mass and gr		|
|Dam		|GRAVITY CIRCULAR PLANT			|
|Weir		|Weir - Loose materials			|
|Weir		|Weir - Riprap with concrete sc		|
|Dam		|Major dam - 				|
|Dam		|Major dam - Gravity			|
|Dam		|Small dam - Riprap screen film		|
|Dam		|Gravity - Buttresses			|
|Dam		|Small dam - Riprap with core		|
|Unknown	| - Undefined				|
|Unknown	|Spillway				| -- CULVERT
|Unknown	|Channeling				| ??
|Dam		|Major dam - Other			|
|Dam		|GRAVITY AND MATERIALS			|
|Dam		|Small dam - 				|
|Dam		|Gravity - ground			|
|Dam		|Riprap with concrete screen		|
|Weir		|Inflatable weir			|
|Dam		|Major dam - Riprap with asphal		|
|Dam		|Major dam - Dome vault			|
|Unknown	|Hydroelectric deviations		|
|Culvert	|Culvert				|
|Unknown	|Gauging Station. Out of WB		| -- WEIR
|Dam		|Major dam - Landfill weir		|
|Unknown	|Gauging station			| -- WEIR 
|Dam		|Major dam - Gravity - Arch		|
|Weir		|Weir - Riprap - Ground			|
|Dam		|Vault dome				|
|Unknown	| - Gravity				|
|Dam		|Major dam - Vertical Wall		|
|Weir		| - Landfill weir			|
|Dam		|Major dam - Riprap with core		|
|Unknown	| - 					|
|Dam		|GROUNDS				|
|Weir		|GRAVITY - THICK VAULT			|
|Unknown	|HCR					|
|Dam		|LOOSE MATERIALS			|
|Unknown	|Riprap with waterproof central		|
|Dam		|GRAVITY  MIX PLANTA			|
|Weir		|Weir - Gravity				|
|Unknown	|Undefined				|
|Dam		|Major dam - Gravity - Dome vau		|
|Dam		|Gravity - Thick vault			|
|Dam		|Compacted concrete			|
|Dam		|Dam. Out of WB				|
|Weir		|Weir - Other				|
|Weir		|Undefined				|
|Unknown	|Loose materials			|
|Weir		|Weir - Undefined			|
|Unknown	|Undefined - Other			|
|Weir		|Weir - Masonry				|
|Dam		|DOME VAULT/GRAVITY			|
|Dam		|Dam					|
|Dam		|Riprap with asphalt screen		|
|Weir		|Seuil en riviÃ¨re			|
|Dam		|Major dam - Loose materials		|
|Dam		|Small dam - Landfill weir		|
|Unknown	|Weir or dam				|
|Unknown	|Gauging station in natural bed		|
|Dam		|Major dam - Buttress			|
|Dam		|Gravity- Vault dome			|
|Unknown	|Undefined - 				|
|Unknown	|Undefined - Gravity			|
|Dam		|Small dam - Loose materials		|
|Dam		|Small dam - Gravity - Arch		|
|Unknown	|Direct pumping				|
|Unknown	|Loose materials with clay core		|
|Dam		|Arc - Gravity				|
|Dam		|Undefined				|
|Unknown	|Compacted concrete			|
|Unknown	|Riprap with asphalt core		|
|Dam		|Gravity				|
|Unknown	|Sleeper				|
|Unknown	|Canalization				|
|Weir		|Weir					|
|Weir		|Weir - Landfill weir			|
|Unknown	|Mobile gates				|
|Unknown	|Gauging Station			|
|Unknown	|Transfer				|
|Dam		|MIX: With right stirrup of loo		|
|Dam		|Gravity - riprap asphalt scree		|
|Dam		|Ground					|
|Dam		|Major dam - Ground			|
|Weir		|					|
|Unknown	|					|
|Dam		|Dome vault				|
|Weir		|Seuil en riviÃ¨re dÃ©versoir		|
|Unknown	|Riprap with core			|
|Culvert	|Buse					|
|Dam		|GRAVITY CURVE PLANT			|
|Dam		|GRAVITY				|
|Unknown	|Riprap with screen			|
|Dam		|GRAVITY STRAIGHT PLANT			|
|Weir		|Weir - Ground				|
|Unknown	|Bridge					| -- BRIDGE
|Weir		|Seuil en riviÃ¨re enrochements		|
|Ford		|Ford					|
|Unknown	|Bridge. Out of WB			| -- BRIDGE
|Unknown	|Riprap with concrete screen		|
|Dam		|ARCH GRAVITY				|
|Weir		|Weir - Compressed Concrete		|
|Dam		|Small dam - Gravity			|
|Unknown	|Canalisation				|
|Weir		|Weir - 				|
|Unknown	|Undefined - Undefined			|
|Weir		|Weir - Gravity - Straight plan		|
*/

select distinct labelatlas from sudoang.amber where dbeel_op_id is not null;

-- 32 obstacles must be updated with the information on fishways
select * from sudoang.amber where labelatlas = 'Weir' and dbeel_op_id is not null; -- 9580 rows
select * from sudoang.amber where labelatlas = 'Dam' and dbeel_op_id is not null; -- 607 rows
select * from sudoang.amber where labelatlas = 'Culvert' and dbeel_op_id is not null; -- 2 rows
select * from sudoang.amber where labelatlas = 'Ford' and dbeel_op_id is not null; -- 41 rows
select * from sudoang.amber where labelatlas = 'Unknown' and dbeel_op_id is not null; -- 6509 rows

begin;
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.amber WHERE dbeel_op_id = ob_op_id and labelatlas = 'Weir'; -- 9422 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.amber WHERE dbeel_op_id = ob_op_id and labelatlas = 'Dam'; -- 649 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '294'
	from sudoang.amber WHERE dbeel_op_id = ob_op_id and labelatlas = 'Culvert'; -- 2 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '295'
	from sudoang.amber WHERE dbeel_op_id = ob_op_id and labelatlas = 'Ford'; -- 41 rows
commit;

-- Specific labelsource
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '296'
	from sudoang.amber WHERE dbeel_op_id = ob_op_id and (labelsource = 'Bridge. Out of WB' or labelsource = 'Bridge'); -- 2719 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.amber WHERE dbeel_op_id = ob_op_id and (labelsource = 'Gauging Station. Out of WB' or labelsource = 'Gauging station'); -- 8 rows


---------------------------------------------------
-- Third data incorporated = AMBER PORTUGAL
---------------------------------------------------
SELECT * FROM sudoang.amber_portugal limit 10;

/* A resolved problem regarding the number of rows, everything was duplicated:
SELECT "name", count("name") FROM sudoang.amber_portugal group by "name"; -- 624 rows duplicated (some names are duplicated X4)
SELECT geom, count(geom) FROM sudoang.amber_portugal group by geom; -- 658 rows duplicated X2
SELECT distinct geom FROM sudoang.amber_portugal; -- 658 rows duplicated X2

create table sudoang.amber_potugal2 as SELECT DISTINCT ON (geom) * from sudoang.amber_portugal;
drop table sudoang.amber_portugal;
alter table sudoang.amber_potugal2 rename to amber_portugal;
*/

---- Adding a geometry column ("X" and "Y" in UTM system, change in QGis for a good projection EPSG 25830 - Coordinates Reference System PT-TM06/Datum ETRS89)
select addgeometrycolumn('sudoang','amber_portugal','geom', 25830, 'point',2);
update sudoang.amber_portugal set geom= ST_TRANSFORM(st_setsrid(ST_MakePoint("coordinates_m", "coordinates_p"), 3763),25830); -- 659 rows, 169 msec

---- Creation spatial index
CREATE INDEX 
  ON sudoang.amber_portugal
  USING gist
  (geom);

---- Change the srid of the geometry to 3035 (as portugal.rn): Doesn't work because it changes the SRID but the points aren't well projected
-- SELECT UpdateGeometrySRID('sudoang','amber_portugal','geom',25830);
-- Second trial to change the srid of amber.portugal:
ALTER TABLE sudoang.amber_portugal
 ALTER COLUMN geom TYPE geometry(POINT, 3035) USING ST_Transform(ST_SetSRID(geom,25830),3035);

SELECT Find_SRID('sudoang', 'amber_portugal', 'geom'); -- 3035

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','amber_portugal','geom_reproj',3035,'POINT',2);

-- Go to OBSTRUCTION AGGREGATION script (line 94) to add the id (character to define the table origin and a key)
-- alter table sudoang.amber_portugal add column id serial;
update sudoang.amber_portugal set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.amber_portugal a join
portugal.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= amber_portugal.id; -- 589 rows

CREATE INDEX 
  ON sudoang.amber_portugal
  USING gist
  (geom_reproj);
  
---- Link amber TO dbeel
ALTER TABLE sudoang.amber_portugal ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.amber_portugal ADD COLUMN initial_duplicate boolean default FALSE;
-- update sudoang.amber_portugal set id = NULL;

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.amber_portugal AS sp1, sudoang.amber_portugal AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- There is only one (APT 2255 - APT 256)

select * from sudoang.dbeel_obstruction_place where country = 'PT';
---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.amber SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
WITH duplicate_amber AS 
(
	SELECT DISTINCT geom_reproj, op_id
	FROM sudoang.amber_portugal, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'APT%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) -- 620 to be tuned
) 
UPDATE sudoang.amber_portugal SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM duplicate_amber 
WHERE id LIKE 'APT%' AND amber_portugal.geom_reproj IS NOT NULL AND amber_portugal.geom_reproj = duplicate_amber.geom_reproj
; -- 7 rows that correspond with 7 obstacles on the border, also presented in Spain (check in QGis)

---- Create a column of height with all the data combined in two columns ("height_alturabardata_m" and "height_altura_m")
alter table sudoang.amber_portugal add column height integer;
update sudoang.amber_portugal
	set height = coalesce(height_alturabardata_m, height_altura_m); -- 658 rows
--(select case when height_alturabardata_m is not null then height_alturabardata_m else height_altura_m end from sudoang.amber_portugal)

---- Update height for these dams
/* 	Problem solved with null data that weren't insert into the dbeel
	Line 355 in "dbeel_sudoang_obstruction_creation" script: 2808 rows are added
	Example for an op_id which its height his null in amber, but it's a duplicate for amber_portugal (and it contains the height)
select * from sudoang.amber where dbeel_op_id = 'd596a65c-c681-412c-a417-5b65a12ff203'
select * from sudoang.dbeel_physical_obstruction where ob_op_id = 'd596a65c-c681-412c-a417-5b65a12ff203'
select * from sudoang.dbeel_physical_obstruction where po_obstruction_height is null -- 2814 rows
*/
UPDATE sudoang.dbeel_physical_obstruction SET po_obstruction_height = height FROM sudoang.amber_portugal
WHERE dbeel_op_id = ob_op_id AND po_obstruction_height is null; -- 3 rows

-- A view of dbeel_physical obstruction is created to check in QGis the data
create or replace view sudoang.view_physical_obstruction as select * from sudoang.dbeel_obstruction_place 
	left join sudoang.dbeel_physical_obstruction on ob_op_id=op_id; -- DOESN'T WORK

---- NEW dams inserted into dbeel_obstruction_place
-- select * from sudoang.dbeel_obstruction_place
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.amber_portugal WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
	 'SUDOANG' AS op_gis_systemname,
	  'amber' AS op_gis_layername, 
	  NULL AS op_gislocation, 
	  NULL AS op_placename, 11 AS op_no_observationplacetype, 
	  NULL op_op_id, 
	  geom_reproj AS the_geom,
	  NULL AS id_original,
	  'PT' AS country
	FROM unique_obs; -- 581 rows (total rows: 659 - 7 are duplicated and 71 are lost because of reprojection, more than 500m from a river)

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (amber_portugal)
-- UPDATE sudoang.amber SET dbeel_op_id = NULL; -- to reset the column
begin;
UPDATE sudoang.amber_portugal SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='amber';	-- 582 rows
COMMIT;

---- The id of the source table (amber_portugal) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'APT_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.amber_portugal WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id)
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='amber'; -- 588 rows
	
---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type,-- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  height AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM sudoang.amber_portugal JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Rosa' --TODO: TO BE MODIFIED
	AND op_gis_layername='amber'
	AND NOT initial_duplicate
; -- 590 rows

---- Presence of an eel pass: Eels can pass if there is an eel pass, type "Bacias sucessivas"
SELECT distinct type_fish_passage FROM sudoang.amber_portugal where id is not null;	-- 'Eclusas', 'Bacias sucessivas', 'Ascensor'

SELECT distinct fish_passage FROM sudoang.amber_portugal where id is not null; 		-- Yes, No, Null
-- "fish_passage" from amber_portugal is text, it must be converted into boolean:
begin;
alter table sudoang.amber_portugal
alter column "fish_passage"
set data type boolean
using case
    when "fish_passage" = 'Yes' then true
    when "fish_passage" = 'No' then false
    else null
end;
commit;

-- 32 obstacles must be updated with the information on fishways
select * from sudoang.amber_portugal where "fish_passage" = 'Yes' and "type_fish_passage" = 'Bacias sucessivas'; -- 23 rows
select * from sudoang.amber_portugal where "fish_passage" = 'Yes' and "type_fish_passage" = 'Ascensor'; -- 1 rows
select * from sudoang.amber_portugal where "fish_passage" = 'Yes' and "type_fish_passage" = 'Eclusas'; -- 8 rows
-- select * from sudoang.dbeel_physical_obstruction where fishway_type is not null

update sudoang.dbeel_physical_obstruction SET (po_presence_eel_pass, fishway_type) = (true, '271')
	from sudoang.amber_portugal WHERE dbeel_op_id = ob_op_id and "fish_passage" = true and "type_fish_passage" = 'Bacias sucessivas'; -- 23 rows

update sudoang.dbeel_physical_obstruction SET (po_presence_eel_pass, fishway_type) = (FALSE, '274')
	from sudoang.amber_portugal WHERE dbeel_op_id = ob_op_id and "fish_passage" = true and "type_fish_passage" = 'Ascensor'; -- 1 rows

update sudoang.dbeel_physical_obstruction SET (po_presence_eel_pass, fishway_type) = (TRUE, '280')
	from sudoang.amber_portugal WHERE dbeel_op_id = ob_op_id and "fish_passage" = true and "type_fish_passage" = 'Eclusas'; -- 8 rows

/* dbeel_nomenclature.obstruction_type = 209 --"Unobtrusive and/or no barrier" when "fish_passage" = 'Yes' and "type_fish_passage" = 'Bacias sucessivas' ???
dbeel_nomenclature.obstruction_type:
	208: "Unknown"
	209: "Unobtrusive and/or no barrier"
	210: "Passable without apparent difficulty"
	211: "Passable with some risk of delay"
	212: "Difficult to pass"
	213: "Very difficult to pass"
	214: "Impassable"
*/

select * from sudoang.dbeel_physical_obstruction where po_presence_eel_pass = FALSE and fishway_type is not null;

---- Type of obstacles
select distinct type_barrier from sudoang.amber_portugal;
/*
|type_barrier  	|
|---------------|
|Weir		|
|		|
|Other		|
|Big dam	|
|		|
|Mini-hídraulic	|
*/

-- 32 obstacles must be updated with the information on fishways
select * from sudoang.amber_portugal where type_barrier = 'Weir'; -- 33 rows
select * from sudoang.amber_portugal where type_barrier = 'Other' or type_barrier = '' or type_barrier = ' '; -- 404 rows
select * from sudoang.amber_portugal where type_barrier = 'Big dam'; -- 153 rows
select * from sudoang.amber_portugal where type_barrier = 'Mini-hídraulic'; -- 68 rows
-- select * from sudoang.amber_portugal where type_barrier is not null and dbeel_op_id is not null -- 582 rows (total: 658 rows)

-- select distinct ot_no_obstruction_type from sudoang.dbeel_physical_obstruction
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.amber_portugal WHERE dbeel_op_id = ob_op_id and type_barrier = 'Weir'; -- 33 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '219'
	from sudoang.amber_portugal WHERE dbeel_op_id = ob_op_id and (type_barrier = 'Other' or type_barrier = '' or type_barrier = ' '); -- 338 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.amber_portugal WHERE dbeel_op_id = ob_op_id and type_barrier = 'Big dam'; -- 142 rows

-- HPP as dam
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.amber_portugal WHERE dbeel_op_id = ob_op_id and type_barrier = 'Mini-hídraulic'; -- 68 rows


---------------------------------------------------
-- Fourth data incorporated = CATALONIA
---------------------------------------------------
/* Differents data sent by Lluis Zamora:
	1. SUDOANG_dams_powerplants_UdG.xlsx:
		A. catalonia_obstruction_dams 		-- 983 rows
TO DO		B. catalonia_obstruction_hpp 		-- 590 rows
TO DO		C. catalonia_obstruction_join_dams_hpp	-- 365 rows
		-- Cédric has already worked on these tables: see from line 235 in "obstruction_aggregation.sql" script
		-- 	He created the third table (catalonia_obstruction_join_dams_hpp)
	2. Inventari estructures.accdb (from catalan water agency ACA): NOT NECESSARY TO BE IMPORTED (raw table of SUDOANG_dams_powerplants_UdG.xlsx)
TO DO	3. Llistat de centrals.xlsx
*/

------ 1.A DAMS DATA IMPORT (catalonia_obstruction_dams table)
SELECT * FROM sudoang.catalonia_obstruction_dams limit 10;
select * from sudoang.view_obstruction join sudoang.catalonia_obstruction_dams on op_id = dbeel_op_id;

---- Add establishment
-- select * from dbeel.establishment
-- 'ACA' is the Catalan water agency that provides data but it zas sent by Lluis Zamora (from the University of Gerona)
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('ACA'); -- TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Lluis Zamora', et_id FROM dbeel.establishment WHERE et_establishment_name = 'ACA'
; --TODO: TO BE MODIFIED

---- The reprojection was done (line 217 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'catalonia_obstruction_dams', 'geom'); -- 3035

---- Creation spatial index
CREATE INDEX 
  ON sudoang.catalonia_obstruction_dams
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','catalonia_obstruction_dams','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- Go to OBSTRUCTION_AGGREGATION script (line 49) to add the id (character to define the table origin and a key)
begin;
update sudoang.catalonia_obstruction_dams set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.catalonia_obstruction_dams a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= catalonia_obstruction_dams.id; -- 981 rows
commit;

CREATE INDEX 
  ON sudoang.catalonia_obstruction_dams
  USING gist
  (geom_reproj);
  
---- Link Catalonia dams TO dbeel
ALTER TABLE sudoang.catalonia_obstruction_dams ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.catalonia_obstruction_dams ADD COLUMN initial_duplicate boolean default FALSE;
-- update sudoang.catalonia_obstruction_dams set initial_duplicate = FALSE

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.catalonia_obstruction_dams AS sp1, sudoang.catalonia_obstruction_dams AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- There are only two (COD 352 - COD 353 and COD 962 - COD 963)

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.catalonia_obstruction_dams SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
-- At the end fo the query (line 1052: "and not op_gis_layername = 'ACA'" is add to recordback the dbeel_op_id)
begin;
WITH duplicate_aca AS 
(
	SELECT geom_reproj, op_id, id, st_distance(the_geom, geom_reproj) as distance, op_gis_layername
	FROM sudoang.catalonia_obstruction_dams, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'COD%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by id, distance -- 185 rows. To be tuned
), 
uq_duplicates_aca as (
	select distinct on (id) * from duplicate_aca
)
UPDATE sudoang.catalonia_obstruction_dams SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM uq_duplicates_aca 
WHERE catalonia_obstruction_dams.id = uq_duplicates_aca.id and not op_gis_layername = 'ACA'
;  -- 834 rows

---- Update height for these dams
/*
select * from sudoang.catalonia_obstruction_dams where dbeel_op_id = 'fadbcd0f-d5ce-425a-b5d1-f4fdec81fedb'
select * from sudoang.dbeel_physical_obstruction where ob_op_id = 'fadbcd0f-d5ce-425a-b5d1-f4fdec81fedb'
*/
begin;
UPDATE sudoang.dbeel_physical_obstruction SET po_obstruction_height = "obs_height(m)" FROM sudoang.catalonia_obstruction_dams
WHERE dbeel_op_id = ob_op_id AND po_obstruction_height is null; -- 191 rows
commit;

---- NEW dams inserted into dbeel_obstruction_place
-- select * from sudoang.dbeel_obstruction_place limit 10;
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.catalonia_obstruction_dams WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL -- 144 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'ACA' AS op_gis_layername, 
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs; -- 144 rows
commit;

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (catalonia_obstruction_dams)
-- UPDATE sudoang.catalonia_obstruction_dams SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.catalonia_obstruction_dams SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='ACA';	-- 145 rows

/*
begin;
UPDATE sudoang.catalonia_obstruction_dams SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom;	-- 582 rows
COMMIT;
*/

---- The id of the source table (catalonia_obstruction_dams) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'COD_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.catalonia_obstruction_dams WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id)
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='ACA'; -- 144 rows
	
---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  "obs_height(m)" AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM sudoang.catalonia_obstruction_dams JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Lluis Zamora' --TODO: TO BE MODIFIED
	AND op_gis_layername='ACA'
; -- 145 rows
commit;

---- Presence of a eel pass:
SELECT obs_presence_eel_pass, count(obs_presence_eel_pass) FROM sudoang.catalonia_obstruction_dams group by obs_presence_eel_pass; -- 894 f, 89 t
select * from sudoang.catalonia_obstruction_dams where dbeel_op_id is not null;


-- Update dbeel_physical_obstruction with the information from catalonia_obstruction_dams:
begin;
update sudoang.dbeel_physical_obstruction SET po_presence_eel_pass = obs_presence_eel_pass
from sudoang.catalonia_obstruction_dams WHERE dbeel_op_id = ob_op_id; -- 952 rows
commit;

-- 'po_no_obstruction_passability' since 'obs_impact', 'obs_downs_pb' is provided: not possible!
-- select * from sudoang.catalonia_obstruction_dams where obs_id = 'RES790' -- There is a probleme donwstream, a eel pass and no impact?

-- Type of obstacle
select distinct obs_type from sudoang.catalonia_obstruction_dams;
/*
|obs_type    				|
|---------------------------------------|
|Weir					|
|EA					|
|CaptaciÃ³ directa. Fora de MA		|
|Dam					|
|Travessa				|
|CaptaciÃ³ directa			|
|Gual					|
*/

select * from sudoang.catalonia_obstruction_dams where obs_type = 'Weir'; -- 918 rows
select * from sudoang.catalonia_obstruction_dams where obs_type = 'Dam'; -- 55 rows
select * from sudoang.catalonia_obstruction_dams where obs_type = 'EA'; -- 1 rows
select * from sudoang.catalonia_obstruction_dams where obs_type = 'CaptaciÃ³ directa. Fora de MA'; -- 4 rows
select * from sudoang.catalonia_obstruction_dams where obs_type = 'Travessa'; -- 2 rows
select * from sudoang.catalonia_obstruction_dams where obs_type = 'CaptaciÃ³ directa'; -- 1 rows
select * from sudoang.catalonia_obstruction_dams where obs_type = 'Gual'; -- 2 rows
-- select * from sudoang.catalonia_obstruction_dams where obs_type is not null and dbeel_op_id is not null; -- 979 rows (total: 983 rows)
begin;
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.catalonia_obstruction_dams WHERE dbeel_op_id = ob_op_id and obs_type = 'Weir'; -- 894 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.catalonia_obstruction_dams WHERE dbeel_op_id = ob_op_id and obs_type = 'Dam'; -- 53 rows
commit;
-- 'EA', 'CaptaciÃ³ directa. Fora de MA', 'Travessa', 'CaptaciÃ³ directa', 'Gual' as UNKNOWN


---- UPDATE previous information of dbeel with data from ACA
-- dbeel_obstruction_place: update the data provider and the name of obstacle (we don't change the id_original because otherwise we'll be lost)
BEGIN;
WITH joined as (	

 SELECT * FROM  sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.catalonia_obstruction_dams on dbeel_op_id=op_id
		where initial_duplicate and op_gis_layername = 'amber' -- 798 rows
EXCEPT
SELECT * FROM   sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.catalonia_obstruction_dams on dbeel_op_id=op_id
		where initial_duplicate and op_gis_layername = 'amber'
		AND comment_update LIKE '%ministry%'		
		),
filter_unique AS (
SELECT op_id, id, count(*) over (partition by op_id) as ct FROM joined
),
final as (
	SELECT 
	coalesce(obs_name, op_placename) as oname,
	coalesce("obs_height(m)", po_obstruction_height) as oheight,  -- replace when not null
	joined.id,
	ob_id,
	joined.op_id,
	CASE WHEN po_obstruction_height::NUMERIC!="obs_height(m)"::NUMERIC THEN coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to ACA data, changed data provider, height changed from '||po_obstruction_height||' to '||"obs_height(m)" 
	ELSE coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to ACA data, changed data provider'
	end as comment_update
	FROM filter_unique 
	join joined ON (joined.op_id, joined.id)=(filter_unique.op_id, filter_unique.id)
	WHERE (coalesce("obs_height(m)",0)-coalesce(po_obstruction_height,0))>-2 -- we only replace the height when the difference is height is -2 (OK if new dam 3m old one 4 m as is it -1 m)
	AND ct = 1 -- count of duplicated values at 500 m in the initial join
	AND op_gis_layername='amber'
	)
--select * from final; -- 739 rows
UPDATE sudoang.dbeel_obstruction_place set (op_gis_layername, op_placename) = ('ACA', oname) FROM final where dbeel_obstruction_place.op_id = final.op_id
; -- 739 rows
COMMIT;

-- dbeel_physical_obstruction: update the height and the update comment (about the data provider and the height)
BEGIN;
WITH joined as (	

 SELECT * FROM  sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.catalonia_obstruction_dams on dbeel_op_id=op_id
		where initial_duplicate 
		and ob_dp_id = 10
EXCEPT
SELECT * FROM   sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.catalonia_obstruction_dams on dbeel_op_id=op_id
		where initial_duplicate
		AND comment_update LIKE '%ministry%'
		and ob_dp_id = 10
		),
filter_unique AS (
SELECT op_id, id, count(*) over (partition by op_id) as ct FROM joined
),
final as (
	SELECT 
	coalesce(obs_name, op_placename) as oname,
	coalesce("obs_height(m)", po_obstruction_height) as oheight,  -- replace when not null
	joined.id,
	ob_id,
	joined.op_id,
	CASE WHEN po_obstruction_height::NUMERIC!="obs_height(m)"::NUMERIC THEN coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to ACA data, changed data provider, height changed from '||po_obstruction_height||' to '||"obs_height(m)" 
	ELSE coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to ACA data, changed data provider'
	end as ocomment_update
	FROM filter_unique 
	join joined ON (joined.op_id, joined.id)=(filter_unique.op_id, filter_unique.id)
	WHERE (coalesce("obs_height(m)",0)-coalesce(po_obstruction_height,0))>-2 -- we only replace the height when the difference is height is -2 (OK if new dam 3m old one 4 m as is it -1 m)
	AND ct = 1 -- count of duplicated values at 500 m in the initial join
	)
--select * from final; -- 739 rows
UPDATE sudoang.dbeel_physical_obstruction set (po_obstruction_height, date_last_update, author_last_update, comment_update) = (oheight, '2020-03-10', 'María and Cédric', ocomment_update) 
FROM final where dbeel_physical_obstruction.ob_id=final.ob_id; -- 739 rows
COMMIT;


------ 1.B HPP DATA IMPORT (catalonia_obstruction_hpp table)

---- Update number of turbines for these dams
/* There are many duplicates in dams and hpp tables of Catalonia: Why? (this problem appears also in line 176 from OBSTRUCTION_AGGREGATION script) 
SELECT * from sudoang.catalonia_obstruction_dams where powerplant_id like '%CHS1104' -- 6 rows
SELECT * from sudoang.catalonia_obstruction_hpp where dam_id like '%CHS1104' -- 6 rows

SELECT * from sudoang.catalonia_obstruction_hpp where dam_id like '%CHS1126' -- 6 rows
SELECT * from sudoang.catalonia_obstruction_join_dams_hpp where powerplant_id like '%CHS1104' -- 7 rows
*/
select * from sudoang.catalonia_obstruction_hpp order by hpp_id; -- 591 rows
begin;
UPDATE sudoang.dbeel_physical_obstruction SET po_turbine_number = dm_nb_turbines FROM sudoang.catalonia_obstruction_hpp
WHERE dbeel_op_id = ob_op_id AND po_turbine_number is null; --  rows
commit;


-- The table has been changed to homogenized the information. This table contains information about hpp and also turbines, for that the hpp are repeated.
--	hpp_name has been created to make the difference between hpp and turbines
/* colnames dbeel_hpp
	|hpp_id				|uuid		|		
	|hpp_ob_id 			|uuid 		|	
	|hpp_name			|integer	|hpp_name
	|hpp_main_grid_or_production 	|integer	|main_grid_production
	|hpp_presence_bypass 		|boolean	|dam_presence_bypass
	|hpp_total_flow_bypass 		|numeric	|
	|hpp_orient_flow_no_id 		|integer	|
	|hpp_presence_of_bar_rack 	|boolean	|
        |hpp_bar_rack_space 		|numeric	|	
	|hpp_surface_bar_rack 		|numeric	|
	|hpp_inclination_bar_rack 	|numeric	|
	|hpp_presence_bypass_trashrack 	|boolean	|
	|hpp_nb_trashrack_bypass 	|integer	|
	|hpp_turb_max_flow 		|numeric	|dam_turb_max_flow
	|hpp_reserved_flow 		|numeric	|
	|hpp_flow_trashrack_bypass 	|numeric	|
	|hpp_max_power 			|numeric	|dam_max_power
	|hpp_nb_turbines 		|integer	|dam_nb_turbines
	|hpp_orientation_bar_rack 	|numeric	|
	|hpp_id_original 		|text		|hpp_id
	|hpp_source 			|text		|	
*/
select jj.obs_id as did, jj.geom_reproj, h.* from sudoang.catalonia_obstruction_hpp h join sudoang.catalonia_obstruction_dams jj on jj.obs_id = h.obs_id where hpp_name is not null; -- 309 rows
select count(*) from sudoang.catalonia_obstruction_hpp where hpp_name is not null; -- 448 rows (139 rows not associated with dams, we will lose them)
select * from sudoang.catalonia_obstruction_hpp where obs_id is null; -- 147 turbines: we don't lose a lot of information, a lot of empty lines

-- Check duplicates
select * from sudoang.dbeel_hpp limit 10; -- hpp_ob_id (from dbeel_physical_obstruction)
select * from sudoang.catalonia_obstruction_hpp limit 10; -- dbeel_op_id (from dbeel_obstruction_place)

with catalonia_dams as (
	select * from sudoang.dbeel_obstruction_place d 
	join 
	sudoang.catalonia_obstruction_dams o on o.dbeel_op_id = d.op_id
	join
	sudoang.catalonia_obstruction_hpp h on o.obs_id = h.obs_id
	where hpp_name is not null
	)
select * from sudoang.view_dbeel_hpp join catalonia_dams on catalonia_dams.op_id = sudoang.view_dbeel_hpp.op_id; -- 0 rows, no duplicates

-- Import hpp data
SELECT hpp_id, count(*) FROM sudoang.catalonia_obstruction_hpp GROUP BY hpp_id HAVING count(*) > 1; -- 111 rows
SELECT sum(dam_nb_turbines) FROM sudoang.catalonia_obstruction_hpp GROUP BY hpp_id; -- 447 rows

begin;
with joined_dam as (
select d.op_id, 
	o.dbeel_op_id, 
	o.geom_reproj, 
	po.ob_op_id, 
	po.ob_id,
	h.*,
	row_number() over (partition by h.hpp_id order by h.order) as row_number
	from sudoang.dbeel_obstruction_place d join sudoang.catalonia_obstruction_dams o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.catalonia_obstruction_hpp h on o.obs_id = h.obs_id --where hpp_name is not null
	), -- 434 rows BUT there are duplicates because of turbines
only_hpp as (
	select * from joined_dam where row_number = 1
	)
--select * from only_hpp --where hpp_id = 'CHS1124'; -- 307 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_name, hpp_main_grid_or_production, hpp_presence_bypass, hpp_turb_max_flow, hpp_max_power, hpp_id_original)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		hpp_name as hpp_name, 
		main_grid_production as hpp_main_grid_or_production,
		dam_presence_bypass as hpp_presence_bypass,
		dam_turb_max_flow as hpp_turb_max_flow, 
		dam_max_power as hpp_max_power, 
		--sum(dam_nb_turbines) as hpp_nb_turbines, -- to do in a second query
		id as hpp_id_original
	FROM only_hpp 
; -- 307 rows
COMMIT;

begin;
with nb_turb as (
		select d.op_id, 
		o.dbeel_op_id, 
		o.geom_reproj, 
		po.ob_op_id, 
		po.ob_id,
		h.id,
		sum(h.dam_nb_turbines) as dam_nb_turbines
		from sudoang.dbeel_obstruction_place d join sudoang.catalonia_obstruction_dams o on o.dbeel_op_id = d.op_id 
		join 
		sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
		JOIN
		sudoang.catalonia_obstruction_hpp h on o.obs_id = h.obs_id group by h.id, d.op_id, o.dbeel_op_id, o.geom_reproj, po.ob_op_id, po.ob_id order by h.id
		)
update sudoang.dbeel_hpp set hpp_nb_turbines = dam_nb_turbines from nb_turb where nb_turb.id = dbeel_hpp.hpp_id_original; -- 307 rows
commit;

---- Record back the link with dbeel: hpp_id of hpp (inserted into the dbeel) are inserted into the source table (andalucia_obstruction_hpp)
ALTER TABLE sudoang.catalonia_obstruction_hpp ADD COLUMN dbeel_hpp_id uuid;
--UPDATE sudoang.catalonia_obstruction_hpp SET dbeel_hpp_id = null;

UPDATE sudoang.catalonia_obstruction_hpp SET dbeel_hpp_id = dbeel_hpp.hpp_id 
FROM sudoang.dbeel_hpp 
WHERE id = hpp_id_original; -- 434

select * from sudoang.catalonia_obstruction_hpp where hpp_name is not null and obs_id is not null; -- 309 rows with two rows without dbeel_hpp_id but an obs_id (id of dam) associated
select * from sudoang.catalonia_obstruction_hpp where id = 'COH_364' or id = 'COH_213'; -- 0 not inserted
select * from sudoang.dbeel_hpp where hpp_id_original = 'COH_364' and hpp_id_original = 'COH_213'; -- 0 not inserted

select jj.obs_id as did, jj.*, h.* from sudoang.catalonia_obstruction_hpp h join sudoang.catalonia_obstruction_dams jj on jj.obs_id = h.obs_id where h.id = 'COH_364'; -- no dbeel_op_id

/* TODO: One dam (obs_id =  'COD_592') is in sudoang.dbeel_obstruction_place, but not in sudoang.dbeel_physical_obstruction because it was a duplicate of amber
select jj.obs_id as did, jj.*, h.* from sudoang.catalonia_obstruction_hpp h join sudoang.catalonia_obstruction_dams jj on jj.obs_id = h.obs_id where h.id = 'COH_213'; -- dbeel_op_id = '912e4b2c-64dc-40a7-b047-b6891fd38910'
select * from sudoang.dbeel_obstruction_place where op_id = '912e4b2c-64dc-40a7-b047-b6891fd38910'; -- op_gislocation = COD_592
select * from sudoang.dbeel_physical_obstruction where ob_op_id = '912e4b2c-64dc-40a7-b047-b6891fd38910'; -- 0 rows

begin;
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  '912e4b2c-64dc-40a7-b047-b6891fd38910' as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  "obs_height(m)" AS po_obstruction_height,
	  2 AS po_turbine_number
	FROM sudoang.catalonia_obstruction_dams, 
	dbeel.data_provider 
	WHERE dp_name = 'Lluis Zamora' --TODO: TO BE MODIFIED
	and dbeel_op_id = '912e4b2c-64dc-40a7-b047-b6891fd38910'
; -- 1 rows
commit;
*/


------ 2.C TURBINE DATA IMPORT (andalucia_obstruction_turbine table)
select * from sudoang.catalonia_obstruction_hpp; -- 591 rows with hpp not associated to dams and without geometry -> not inserted because information is missing
select * from sudoang.catalonia_obstruction_dams; -- 983 rows

-- Correct the typt_id
select distinct turb_type from sudoang.catalonia_obstruction_hpp group by turb_type order by turb_type;

update sudoang.catalonia_obstruction_hpp	
	set typt_id = (case
				when turb_type = 'Bulb' then 242
				when turb_type = 'Francis' then 245
				when turb_type = 'Francis double rotor turbine' then 244
				when turb_type = 'Francis spiral chamber, horizontal axis' then 255
				when turb_type = 'Kaplan' then 247
				when turb_type = 'Kaplan horitzontal axis' then 242
				when turb_type = 'Kaplan vertical axis' then 253
				when turb_type = 'Pelton' then 248
				when turb_type = 'Turbine' then 252
				when turb_type = 'unknown' then 252
				when turb_type = 'Francis closed chumber turbine' THEN 255
				when turb_type = 'Francis horizontal axis' THEN 251
				when turb_type = 'Francis open chumber turbine' THEN  254
				when turb_type = 'Francis vertical axis' THEN 245
				when turb_type = 'Kösler' THEN 252 -- fabriquant tout types => unknown
				when turb_type = 'Neyrpic' then	252 -- fabriquant tout types => unknown
				when turb_type = 'Semikaplan' THEN 250 -- turbine S horizontale
				when turb_type = 'Sincron' THEN 252 -- Synkron c'est le générateur
				when turb_type = 'SKAT-T12' THEN  256
				when turb_type = 'Skoda' THEN 252 -- generateur
				when turb_type = 'Voith' THEN 252 -- fabriquant tout types
				else null
	end);

/* colnames dbeel_hpp
	|turb_id 			|uuid		|
	|turb_hpp_id 			|uuid		|dbeel_hpp_id
	|turb_turbine_type_no_id 	|integer	|typt_id -- MUST BE MODIFIED!
	|turb_in_service 		|boolean	|turb_in_service
	|turb_max_power 		|numeric	|turb_max_power_kw
	|turb_min_working_flow 		|numeric	|turb_min_working_flow
	|turb_hpp_height 		|numeric	|turb_dam_height
	|turb_diameter 			|numeric	|
	|turb_rotation_speed 		|numeric	|turb_rotation_speed
	|turb_nb_blades 		|integer	|turb_nb_blades
	|turb_max_turbine_flow 		|numeric	|??turb_min_working_flow
	|turb_description 		|text		|
*/

begin;
with joined_hpp as (
			select * from sudoang.catalonia_obstruction_hpp where dbeel_hpp_id is not null -- 434 rows
		   )
INSERT INTO sudoang.dbeel_turbine(
	turb_id, turb_hpp_id, turb_turbine_type_no_id, turb_in_service, turb_max_power, turb_min_working_flow, turb_hpp_height, turb_rotation_speed, turb_nb_blades)
	SELECT
		uuid_generate_v4() AS turb_id,
		dbeel_hpp_id AS turb_hpp_id,
		typt_id as turb_turbine_type_no_id, 
		case 	when turb_in_service = 'TRUE' then true
			when turb_in_service = 'FALSE' then FALSE
			when turb_in_service = 'UNKNOWN' then null
			else null 
			end as turb_in_service, 
		turb_max_power_kw as turb_max_power,
		turb_min_working_flow as turb_min_working_flow,
		turb_dam_height as turb_hpp_height, 
		turb_rotation_speed as turb_rotation_speed,
		turb_nb_blades as turb_nb_blades
		--id as turbine_id_original
	FROM joined_hpp
; -- 434 rows
COMMIT;

-- TODO
-- In this table there is 'turb_min_working_flow': what can we do with that? It doesn't correspond with turb_max_turbine_flow from dbeel_turbine table

---------------------------------------------------
-- Fifth data incorporated = GALICIA
---------------------------------------------------
/* Information given by Francisco Hervella:
	-- "artificial" = "NO": Natural waterfalls, they can have an impact or not, depending on its height (10m - 50m)
	select * from sudoang.galicia_obstruction where artificial = 'NO'; -- 361 rows, 248 altura = 0m, 7 altura > 10m
	-- "tipologia": type of obstacle:
	--		= "Presas sumergidas": Weirs
	--		= "Presa M.H." or "Gran Presa": HPP (with turbines, sometimes "Gran Presa" can be dams supplying)
	-- "uso": If they are in service or not
*/

---- Add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('The Xunta of Galicia'); -- TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Francisco Hervella', et_id FROM dbeel.establishment WHERE et_establishment_name = 'The Xunta of Galicia'
; --TODO: TO BE MODIFIED

---- The reprojection was done (line 241 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'galicia_obstruction', 'geom'); -- 3035

---- Creation spatial index: It has been done before
-- CREATE INDEX 
--   ON sudoang.galicia_obstruction
--   USING gist
--   (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','galicia_obstruction','geom_reproj',3035,'POINT',2);

-- Go to OBSTRUCTION_AGGREGATION script (line 115) to add the id (character to define the table origin and a key)
begin;
update sudoang.galicia_obstruction set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.galicia_obstruction a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= galicia_obstruction.id; -- 3363 rows
commit;

CREATE INDEX 
  ON sudoang.galicia_obstruction
  USING gist
  (geom_reproj);

VACUUM ANALYSE sudoang.galicia_obstruction;

---- Link Galicia TO dbeel
ALTER TABLE sudoang.galicia_obstruction ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.galicia_obstruction ADD COLUMN initial_duplicate boolean default FALSE;
-- update sudoang.galicia_obstruction set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.galicia_obstruction AS sp1, sudoang.galicia_obstruction AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 14 rows

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.galicia_obstruction SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
-- At the end fo the query (line 1052: "and not op_gis_layername = 'The Xunta of Galicia'" is add to recordback the dbeel_op_id)
begin;
WITH duplicate_galicia AS 
(
	SELECT DISTINCT geom_reproj, op_id, id, st_distance(the_geom, geom_reproj) as distance, op_gis_layername
	FROM sudoang.galicia_obstruction, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'GO%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by id, distance -- 2548 rows (total rows: 3468). To be tuned
), 
uq_duplicates_go as (
	select distinct on (id) * from duplicate_galicia
)
UPDATE sudoang.galicia_obstruction SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM uq_duplicates_go 
WHERE galicia_obstruction.id = uq_duplicates_go.id and not op_gis_layername = 'The Xunta of Galicia'
;  -- 1044 rows

---- Update height for these dams
/*
select * from sudoang.galicia_obstruction where altura ='0'; -- 1885 rows
select * from sudoang.galicia_obstruction where dbeel_op_id = '05df75ee-b292-411a-bf94-79cffba2bd1d' -- 3 rows
select * from sudoang.dbeel_physical_obstruction where ob_op_id = '05df75ee-b292-411a-bf94-79cffba2bd1d' -- 1 row
*/
UPDATE sudoang.dbeel_physical_obstruction SET po_obstruction_height = altura FROM sudoang.galicia_obstruction
WHERE dbeel_op_id = ob_op_id AND po_obstruction_height is null; -- 27 rows

---- NEW dams inserted into dbeel_obstruction_place
----	ONLY ARTIFICIAL OBSTACLES ARE IMPORTED
-- select * from sudoang.dbeel_obstruction_place limit 10;
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.galicia_obstruction WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL -- 2258 rows
		AND artificial = 'SI' -- 1983 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'The Xunta of Galicia' AS op_gis_layername, 
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs; -- 1983 rows
commit;

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (galicia_obstruction)
-- UPDATE sudoang.galicia_obstruction SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.galicia_obstruction SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='The Xunta of Galicia';	-- 1990 rows

---- The id of the source table (galicia_obstruction) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'GO_' || max(substring(id from 4)::integer) AS id -- from digit 4 to the end of the code
	FROM sudoang.galicia_obstruction WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 2620 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='The Xunta of Galicia'; -- 1983 rows
	
---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  altura AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM sudoang.galicia_obstruction JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Francisco Hervella' --TODO: TO BE MODIFIED
	AND op_gis_layername='The Xunta of Galicia'
; -- 1990 rows
commit;

-- TYPE DE DISPOSITIF = FISHWAY ???
select tipo_disp, count(tipo_disp) from sudoang.galicia_obstruction group by tipo_disp;
select * from sudoang.galicia_obstruction where tipo_disp = 'Escala de ralentizadores' or tipo_disp = 'Escala de Ralentizadores' or 
	tipo_disp = 'Escala artesas' or tipo_disp = 'Escala de artesas' or tipo_disp = 'Escala de Artesas'; -- 15 rows
/*
"Escala de ralentizadores", "Escala de Ralentizadores" 		= 'Denil pass' (273, FALSE: presence eel pass)
"Escala artesas", "Escala de artesas", "Escala de Artesas" 	= 'Pool type fishway' (271, TRUE: presence eel pass)
"Escala de aberturas verticales" 				= 'Vertical slot fishway' (270, TRUE: presence eel pass)
"ORIFICIO", "ABERTURAS"
"Hueco"
"Escala"
"Relleno"
"NO"
*/
-- Primary key of dbeel_phisical_obstruction is ob_id, so a subquery is needed to search the required lines from galicia_obtruction:
begin;
with pass as (
	select 
	(CASE WHEN tipo_disp = 'Escala de ralentizadores' or tipo_disp = 'Escala de Ralentizadores' THEN FALSE
	      WHEN tipo_disp = 'Escala artesas' or tipo_disp = 'Escala de artesas' or tipo_disp = 'Escala de Artesas' THEN true
	      WHEN tipo_disp = 'Escala de aberturas verticales' THEN true 
	      else false
	      end) as po_presence_eel_pass,
	(CASE WHEN tipo_disp = 'Escala de ralentizadores' or tipo_disp = 'Escala de Ralentizadores' THEN '273'
	      WHEN tipo_disp = 'Escala artesas' or tipo_disp = 'Escala de artesas' or tipo_disp = 'Escala de Artesas' THEN '271'
	      WHEN tipo_disp = 'Escala de aberturas verticales' THEN '270'
	      else null
	      end) AS fishway_type,
	dbeel_op_id
	from sudoang.galicia_obstruction 
        where tipo_disp = 'Escala de ralentizadores' or tipo_disp = 'Escala de Ralentizadores' 
	or tipo_disp = 'Escala artesas' or tipo_disp = 'Escala de artesas' or tipo_disp = 'Escala de Artesas' or tipo_disp = 'Escala de aberturas verticales'
	),
joining_pass as (
	select ob_id, p.po_presence_eel_pass, p.fishway_type from pass join sudoang.dbeel_physical_obstruction p ON p.ob_op_id = dbeel_op_id
	)
--select count(*), ob_id from joining_pass group by ob_id; 
UPDATE sudoang.dbeel_physical_obstruction as dpo
SET (po_presence_eel_pass, fishway_type) = (joining_pass.po_presence_eel_pass, joining_pass.fishway_type)
FROM joining_pass 
WHERE joining_pass.ob_id = dpo.ob_id
; 
commit;

-- TODO
-- There are also information about upstream (remonte) and downstream migration (descenso)?
select remonte, count(remonte) from sudoang.galicia_obstruction group by remonte; 		-- Impossible, Difficult, Easy, Variable in different formats!
select descenso, count(descenso) from sudoang.galicia_obstruction group by descenso; 		-- Impossible, Difficult, Easy, Variable in different formats!
-- 	and the passability (disp_franq)
select disp_franq, count(disp_franq) from sudoang.galicia_obstruction group by disp_franq;	-- Yes, no

-- Type of obstacles
select distinct tipologia, artificial from sudoang.galicia_obstruction;
/*
|tipologia     				|artificial	|
|---------------------------------------|---------------|
|Presa Sumergida			|SI		|
|Piedras				|NO		|
|Presa					|SI		|
|Compuerta				|SI		|
|Zapata puente				|SI		|
|Gran Presa				|SI		|
|AluviÃ³n/arena				|NO		|
|Presa M.H.				|SI		|
|Piedras				| 		|
|Pasos					|SI		|
|Empalizada/Barrera			|SI		|
|Plancha hormigÃ³n			|SI		|
|AluviÃ³n/arena				|		|
|Escombros				|SI		|
|Pesqueira				|SI		|
|Presa M.H.				|		|
|Gran Presa				| 		|
|Presa					| 		|
|Tabla aforos				|SI		|
|Cascada				|NO		|
|TÃºnel/CanalizaciÃ³n			|SI		|
|Pasos					| 		|
|Cascada				| 		|
|Piedras				|SI		|
*/
select * from sudoang.galicia_obstruction where tipologia = 'Presa Sumergida' or tipologia = 'Presa' or tipologia = 'Gran Presa' 
	or tipologia = 'Presa M.H.' and dbeel_op_id is not null; -- 2907 rows
-- select * from sudoang.galicia_obstruction where dbeel_op_id is not null; -- 3034 rows
begin;
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.galicia_obstruction WHERE dbeel_op_id = ob_op_id and (tipologia = 'Presa Sumergida' or tipologia = 'Presa' 
	or tipologia = 'Gran Presa' or tipologia = 'Presa M.H.'); -- 25387 rows
commit;


---- UPDATE previous information of dbeel with data from 'The Xunta of Galicia'
-- dbeel_obstruction_place: update the data provider and the name of obstacle (we don't change the id_original because otherwise we'll be lost)
BEGIN;
WITH joined as (	

 SELECT * FROM  sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.galicia_obstruction on dbeel_op_id=op_id
		where initial_duplicate and op_gis_layername = 'amber'
EXCEPT
SELECT * FROM   sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.galicia_obstruction on dbeel_op_id=op_id
		where initial_duplicate and op_gis_layername = 'amber'
		AND comment_update LIKE '%ministry%'		
		),
filter_unique AS (
SELECT op_id, id, count(*) over (partition by op_id) as ct FROM joined
),
final as (
	SELECT 
	coalesce(nome, op_placename) as oname,
	coalesce(altura, po_obstruction_height) as oheight,  -- replace when not null
	joined.id,
	ob_id,
	joined.op_id,
	CASE WHEN po_obstruction_height::NUMERIC!=altura::NUMERIC THEN coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to The Xunta of Galicia data, changed data provider, height changed from '||po_obstruction_height||' to '||altura 
	ELSE coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to The Xunta of Galicia data, changed data provider'
	end as comment_update
	FROM filter_unique 
	join joined ON (joined.op_id, joined.id)=(filter_unique.op_id, filter_unique.id)
	WHERE (coalesce(altura,0)-coalesce(po_obstruction_height,0))>-2 -- we only replace the height when the difference is height is -2 (OK if new dam 3m old one 4 m as is it -1 m)
	AND ct = 1 -- count of duplicated values at 500 m in the initial join
	AND op_gis_layername='amber'
	)
-- select * from final order by ob_id; -- 263 rows
UPDATE sudoang.dbeel_obstruction_place set (op_gis_layername, op_placename) = ('The Xunta of Galica', oname) FROM final 
	where dbeel_obstruction_place.op_id = final.op_id; -- 263 rows
COMMIT;

-- dbeel_physical_obstruction: update the height and the update comment (about the data provider and the height)
BEGIN;
WITH joined as (	

 SELECT * FROM  sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.galicia_obstruction on dbeel_op_id=op_id
		where initial_duplicate 
		and ob_dp_id = 10
EXCEPT
SELECT * FROM   sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.galicia_obstruction on dbeel_op_id=op_id
		where initial_duplicate
		AND comment_update LIKE '%ministry%'
		and ob_dp_id = 10
		),
filter_unique AS (
SELECT op_id, id, count(*) over (partition by op_id) as ct FROM joined
),
final as (
	SELECT 
	coalesce(nome, op_placename) as oname,
	coalesce(altura, po_obstruction_height) as oheight,  -- replace when not null
	joined.id,
	ob_id,
	joined.op_id,
	CASE WHEN po_obstruction_height::NUMERIC!=altura::NUMERIC THEN coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to The Xunta of Galicia data, changed data provider, height changed from '||po_obstruction_height||' to '||altura 
	ELSE coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to The Xunta of Galicia data, changed data provider'
	end as ocomment_update
	FROM filter_unique 
	join joined ON (joined.op_id, joined.id)=(filter_unique.op_id, filter_unique.id)
	WHERE (coalesce(altura,0)-coalesce(po_obstruction_height,0))>-2 -- we only replace the height when the difference is height is -2 (OK if new dam 3m old one 4 m as is it -1 m)
	AND ct = 1 -- count of duplicated values at 500 m in the initial join
	)
-- select * from final; -- 263 rows
UPDATE sudoang.dbeel_physical_obstruction set (po_obstruction_height, date_last_update, author_last_update, comment_update) = (oheight, '2020-02-25', 'María and Cédric', ocomment_update) 
FROM final where dbeel_physical_obstruction.ob_id=final.ob_id; -- 263 rows
COMMIT;


---- GALICIA HPP (ANGUILA_TURBINAS.csv)
-- Move the table to sudoang schema from public
ALTER TABLE galicia_obstruction_hpp SET SCHEMA sudoang;

ALTER TABLE sudoang.galicia_obstruction_hpp RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.galicia_obstruction_hpp
  USING gist
  (geom);
  
---- Reproject on the rivers
select st_srid(geom) from sudoang.galicia_obstruction_hpp -- 3035

SELECT addgeometrycolumn('sudoang','galicia_obstruction_hpp','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

begin;
update sudoang.galicia_obstruction_hpp set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.galicia_obstruction_hpp a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id = galicia_obstruction_hpp.id; -- 56 rows
commit;

CREATE INDEX 
  ON sudoang.galicia_obstruction_hpp
  USING gist
  (geom_reproj);
  
---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.galicia_obstruction_hpp AS sp1, sudoang.galicia_obstruction_hpp AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

---- Link Galicia hpp TO dbeel
ALTER TABLE sudoang.galicia_obstruction_hpp add COLUMN dam_id character varying (10);
ALTER TABLE sudoang.galicia_obstruction_hpp add column dam_dbeel boolean default FALSE

---- FIND the nearest DAM to associate the HPP
begin;
WITH duplicate AS 
(
	SELECT DISTINCT geom_reproj, id, id_original, st_distance(the_geom, geom_reproj) as distance, op_gis_layername
	FROM sudoang.galicia_obstruction_hpp, sudoang.dbeel_obstruction_place
	WHERE geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by distance -- 54 rows. To be tuned
), 
uq_duplicates as (
	select distinct on (id) * from duplicate
)
--select * from uq_duplicates -- 54 rows (from The Xunta of Galicia, but also miteco and AMBER)
UPDATE sudoang.galicia_obstruction_hpp SET (dam_id, dam_dbeel) = (id_original, TRUE)
FROM uq_duplicates
WHERE galicia_obstruction_hpp.id = uq_duplicates.id
; -- 54 rows
commit;

-- Check duplicates
with galicia_dams as (
	select * from sudoang.dbeel_obstruction_place d 
	join 
	sudoang.galicia_obstruction_hpp h on d.id_original = h.dam_id
	)
select * from sudoang.view_dbeel_hpp join galicia_dams on galicia_dams.op_id = sudoang.view_dbeel_hpp.op_id; -- 0 rows, no duplicates

-- Import hpp data
begin;
with joined_dam as (
	select d.op_id, po.ob_op_id, po.ob_id, o.* from sudoang.dbeel_obstruction_place d join sudoang.galicia_obstruction_hpp o on o.dam_id = d.id_original 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	),

closest_dam as (
select distinct on (op_id) * from joined_dam)
-- select * from closest_dam; -- 54 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_name, hpp_nb_turbines, hpp_id_original)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		name as hpp_name, 
		-- concession_flow_m3s as hpp_turb_max_flow, 
		turbine_number as hpp_nb_turbines, 
		id as hpp_id_original
	FROM closest_dam
; -- 54 rows
COMMIT;

---- Record back the link with dbeel: hpp_id of hpp (inserted into the dbeel) are inserted into the source table (andalucia_obstruction_hpp)
ALTER TABLE sudoang.galicia_obstruction_hpp ADD COLUMN dbeel_hpp_id uuid;

UPDATE sudoang.galicia_obstruction_hpp SET dbeel_hpp_id = hpp_id 
FROM sudoang.dbeel_hpp 
WHERE id = hpp_id_original AND name = hpp_name; -- 54 rows

-- TODO: Two HPP with geom not inserted as dbeel_obstruction_place

-- Create table of TURBINES with the rows duplicated in case more than one turbine exist
CREATE TABLE sudoang.galicia_obstruction_turbine AS
  SELECT * FROM sudoang.galicia_obstruction_hpp where dam_dbeel = TRUE; -- 54 rows

INSERT INTO sudoang.galicia_obstruction_turbine SELECT * FROM sudoang.galicia_obstruction_turbine WHERE turbine_number > 1; -- 19 row
INSERT INTO sudoang.galicia_obstruction_turbine SELECT * FROM sudoang.galicia_obstruction_turbine WHERE id = 'GHP_56';


-- Import turbine data
begin;
INSERT INTO sudoang.dbeel_turbine(
	turb_id, turb_hpp_id, turb_turbine_type_no_id, turb_hpp_height, turb_max_turbine_flow)
	SELECT
		uuid_generate_v4() AS turb_id,
		dbeel_hpp_id AS turb_hpp_id,
		turbine_type::NUMERIC as turb_turbine_type_no_id,
		height_m as turb_hpp_height,
		concession_flow_m3s as turb_max_turbine_flow
	FROM sudoang.galicia_obstruction_turbine
; -- 75 rows
COMMIT;


------------------------------------------------------------------
-- Sixth data incorporated = MIÑO BASIN (BARRAGENS_BACIA.xlsx)
------------------------------------------------------------------
/* Between the 40 parameters:
	-- "TIPO_USO" = hydroeelctric, suplying or irrigation
	-- "H_EN__M" = height
	-- "CAP_D_M3_S" = turbines flow?
	-- "POTEN_MW" = power
	-- "PSAXS_PEIX" = fish pass
*/

select * from sudoang.minho_obstruction; -- 45 rows
---- Add establishment
-- select * from dbeel.establishment
-- 'UP' is the Cthe University of Porto, but we don't know the origin of data (ask to Carlos Antunes)
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('UP'); -- TODO: TO BE MODIFIED

-- TO DO: ERROR IS NOT ACA, 'UP'
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Carlos Antunes', et_id FROM dbeel.establishment WHERE et_establishment_name = 'ACA'
; --TODO: TO BE MODIFIED
select * from sudoang.minho_obstruction;

---- The reprojection was done (line 225 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'minho_obstruction', 'geom');

---- Creation spatial index
CREATE INDEX 
  ON sudoang.minho_obstruction
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','minho_obstruction','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- Go to OBSTRUCTION_AGGREGATION script (line 70) to add the id (character to define the table origin and a key)
begin;
update sudoang.minho_obstruction set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.minho_obstruction a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= minho_obstruction.id; -- 44 rows
commit;

CREATE INDEX 
  ON sudoang.minho_obstruction
  USING gist
  (geom_reproj);
  
---- Link Minho dams TO dbeel
ALTER TABLE sudoang.minho_obstruction ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.minho_obstruction add column initial_duplicate boolean default FALSE
-- update sudoang.minho_obstruction set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.minho_obstruction AS sp1, sudoang.minho_obstruction AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.minho_obstruction SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
begin;
WITH duplicate_minho AS 
(
	SELECT DISTINCT geom_reproj, op_id, id, st_distance(the_geom, geom_reproj) as distance, op_gis_layername
	FROM sudoang.minho_obstruction, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'MIO%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by id, distance -- 46 rows. To be tuned
), 
uq_duplicates_mi as (
	select distinct on (id) * from duplicate_minho
)
UPDATE sudoang.minho_obstruction SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM uq_duplicates_mi
WHERE minho_obstruction.id = uq_duplicates_mi.id and not op_gis_layername = 'UP'
--WHERE id LIKE 'MIO%' AND minho_obstruction.geom_reproj IS NOT NULL AND minho_obstruction.geom_reproj = duplicate_minho.geom_reproj
; -- 36 rows
commit;

---- Update HEIGHT for these dams
/*
select * from sudoang.minho_obstruction where dbeel_op_id = '76b1884d-f662-4dc8-8e7b-efd4d57fc2fc'
select * from sudoang.dbeel_physical_obstruction where ob_op_id = '76b1884d-f662-4dc8-8e7b-efd4d57fc2fc'
*/
begin;
UPDATE sudoang.dbeel_physical_obstruction SET (po_obstruction_height,comment_update) = (
"H_EN__M", 
coalesce(comment_update,'')||'Height values updated from sudoang.minho_obstruction '||po_obstruction_height ||'>' || "H_EN__M") FROM sudoang.minho_obstruction
WHERE dbeel_op_id = ob_op_id; 
commit; -- 44 rows

SELECT "H_EN__M", coalesce(comment_update,'')||'Height values updated from sudoang.minho_obstruction '||po_obstruction_height ||'>' || "H_EN__M" as comment_udpate  FROM sudoang.dbeel_physical_obstruction JOIN sudoang.minho_obstruction
ON dbeel_op_id = ob_op_id ;

---- Update NAMES for these dams
BEGIN
with namesdams as (
SELECT op_id, op_placename,"NOME" as newname FROM 
sudoang.dbeel_obstruction_place JOIN
sudoang.dbeel_physical_obstruction On op_id=ob_op_id
JOIN sudoang.minho_obstruction
ON dbeel_op_id = ob_op_id 
)
UPDATE sudoang.dbeel_obstruction_place set op_placename=newname from namesdams where namesdams.op_id=dbeel_obstruction_place.op_id;--44
COMMIT;

---- NEW dams inserted into dbeel_obstruction_place
-- select * from sudoang.dbeel_obstruction_place limit 10;
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.minho_obstruction WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL -- 8 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'UP' AS op_gis_layername, 
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs; -- 8 rows
commit;

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (minho_obstruction)
-- UPDATE sudoang.minho_obstruction SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.minho_obstruction SET (dbeel_op_id, initial_duplicate) = (op_id, FALSE)
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='UP'; -- 8 rows
	
---- The id of the source table (minho_obstruction) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'MIO_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.minho_obstruction WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id)
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='UP'; -- 8 rows

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  "H_EN__M" AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM sudoang.minho_obstruction JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Carlos Antunes' --TODO: TO BE MODIFIED
	AND op_gis_layername='UP'
; -- 8 rows
commit;

-- Update the type of obstacles: All data are DAMS (45 dams = 'Barragem de')
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.minho_obstruction WHERE dbeel_op_id = ob_op_id; -- 44 rows

---- TO DO:
---- 	"CAP_D_M3_S" = turbines flow?
---- 	"POTEN_MW" = power
---- 	"PSAXS_PEIX" = fish pass
----	Insert line in HPP where  TIPO_USO LIKE '%Hidroelectrico%' 

select "PSAXS_PEIX", count("PSAXS_PEIX") from sudoang.minho_obstruction group by "PSAXS_PEIX"; -- NO fish pass


------------------------------------------------------------------
-- Seventh data incorporated = MIÑO BASIN (Obs_UTF8.shp)
------------------------------------------------------------------
/* Attributes:
	-- id_0 integer
	-- geom geometry(Point,3763)
	-- id 
	-- linha_de_ = River
	-- afluente = Tributary
	-- categoria = Type of obstruction
	-- origem = Artificial or Natural obstruction
	-- concelho
	-- freguesia
	-- altura = Height
	-- compriment character varying(254),
	-- largura 
	-- uso
	-- material
	-- estado_de
	-- actualiza date
	-- ...
*/

select * from sudoang."Obs_UTF8"; -- 297 rows
-- Change the name of the table
ALTER TABLE IF EXISTS sudoang."Obs_UTF8" RENAME TO minho_obstruction_bis;

-- select * from dbeel.establishment -- 'UP' (et_id = 15)
-- select * from dbeel.data_provider -- 'Carlos Antunes' (dp_et_id = 13) It must be dp_et_id = 15 ('UP')
BEGIN;
update dbeel.data_provider set dp_et_id = 15 where dp_name = 'Carlos Antunes'
commit;

---- The reprojection was done (line 322 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'minho_obstruction_bis', 'geom'); -- 3035

---- Creation spatial index
CREATE INDEX 
  ON sudoang.minho_obstruction_bis
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','minho_obstruction_bis','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- Go to OBSTRUCTION_AGGREGATION script (line 70) to add the id (character to define the table origin and a key)
begin;
update sudoang.minho_obstruction_bis set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.minho_obstruction_bis a join
portugal.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= minho_obstruction_bis.id; -- 294 rows
commit;

CREATE INDEX 
  ON sudoang.minho_obstruction_bis
  USING gist
  (geom_reproj);
  
---- Link Minho dams TO dbeel
ALTER TABLE sudoang.minho_obstruction_bis ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.minho_obstruction_bis add column initial_duplicate boolean default FALSE
-- update sudoang.minho_obstruction set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.minho_obstruction_bis AS sp1, sudoang.minho_obstruction_bis AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01) and sp1.origem = 'Artificial'
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer 
; -- 4 rows (There are more internal duplicates that are at the same time natural and artificial)
/*
select * from sudoang.minho_obstruction_bis where ID = 'MIO_216' or ID = 'MIO_217';
select * from sudoang.minho_obstruction_bis where ID = 'MIO_218' or ID = 'MIO_219';
select * from sudoang.minho_obstruction_bis where ID = 'MIO_221' or ID = 'MIO_222'; 
select * from sudoang.minho_obstruction_bis where ID = 'MIO_277' or ID = 'MIO_278';

delete from sudoang.minho_obstruction_bis where ID = 'MIO_216'; -- id_original = 'POR0901SLouObs4' (uso ND and estado_de ND)
delete from sudoang.minho_obstruction_bis where ID = 'MIO_219'; -- id_original = 'POR0901SLouObs7' (Queda de água, origem = Natural, uso ND and estado_de ND)
delete from sudoang.minho_obstruction_bis where ID = 'MIO_222'; -- id_original = 'POR0901SLouObs10' (Queda de água, origem = Natural, uso ND and estado_de ND)
delete from sudoang.minho_obstruction_bis where ID = 'MIO_227'; -- id_original = 'COD091002AguaObs8' (Represa, higher than MIO_278)
*/

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.minho_obstruction_bis SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
begin;
WITH duplicate_minho AS 
(
	SELECT DISTINCT geom_reproj, op_id, id, st_distance(the_geom, geom_reproj) as distance, op_gis_layername
	FROM sudoang.minho_obstruction_bis, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'MIO%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by id, distance -- 6 rows. To be tuned
), 
uq_duplicates_mi as (
	select distinct on (id) * from duplicate_minho
)
UPDATE sudoang.minho_obstruction_bis SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM uq_duplicates_mi
WHERE minho_obstruction_bis.id = uq_duplicates_mi.id and not op_gis_layername = 'UP'
--WHERE id LIKE 'MIO%' AND minho_obstruction_bis.geom_reproj IS NOT NULL AND minho_obstruction_bis.geom_reproj = duplicate_minho.geom_reproj
; -- 3 rows
commit;

---- Update height for these dams
-- 	altura column is in character with comma: conversion to dot and numeric format
begin;
UPDATE sudoang.minho_obstruction_bis set altura = replace(minho_obstruction_bis.altura, ',', '.');
ALTER TABLE sudoang.minho_obstruction_bis ALTER COLUMN altura type numeric USING cast(altura as NUMERIC)
commit;

/*
select * from sudoang.minho_obstruction_bis where dbeel_op_id = 'b18422e2-6f7e-4572-9af0-7ecdcc4297d6'
select * from sudoang.dbeel_physical_obstruction where ob_op_id = 'b18422e2-6f7e-4572-9af0-7ecdcc4297d6'
*/
begin;
UPDATE sudoang.dbeel_physical_obstruction SET (po_obstruction_height,comment_update) = (altura, coalesce(comment_update,'')||'Height values updated from sudoang.sudoang.minho_obstruction_bis ')FROM sudoang.minho_obstruction_bis
WHERE dbeel_op_id = ob_op_id -- 3 rows
commit;


-- TO DO
---- NEW dams inserted into dbeel_obstruction_place: Only Artificial!
-- select * from sudoang.dbeel_obstruction_place limit 10;

/*
Script MARIA
*/
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.minho_obstruction_bis WHERE dbeel_op_id IS NULL  AND geom_reproj IS NOT NULL and origem = 'Artificial' -- 210 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'UP' AS op_gis_layername, 
		NULL AS op_gislocation, 
		NULL AS op_placename,
		281 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'PT' AS country
		FROM unique_obs; -- 210 rows
commit;

/* Script CEDRIC (after change in table and dump of only this table from Maria)
begin;
WITH unique_obs AS
(
	SELECT DISTINCT on (geom_reproj) geom_reproj, id FROM sudoang.minho_obstruction_bis WHERE initial_duplicate=FALSE AND geom_reproj IS NOT NULL and origem = 'Artificial' -- 210 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'UP' AS op_gis_layername, 
		id AS op_gislocation, 
		NULL AS op_placename,
		281 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		id AS id_original,
		'PT' AS country
		FROM unique_obs; -- 210 rows
commit;
*/

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (minho_obstruction_bis)
-- UPDATE sudoang.minho_obstruction_bis SET dbeel_op_id = NULL; -- to reset the column don't do that you get rid of initial duplicates
UPDATE sudoang.minho_obstruction_bis SET (dbeel_op_id, initial_duplicate) = (op_id, FALSE)
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername = 'UP'; -- 214 rows
	
---- The id of the source table (minho_obstruction_bis) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
/* There is a problem with the id = MIO_ between countries, some are repeated!
select distinct id from sudoang.minho_obstruction_bis
update sudoang.minho_obstruction_bis set id = 'MIO_336' where id = 'MIO_40';
update sudoang.minho_obstruction_bis set id = 'MIO_337' where id = 'MIO_44';
*/
WITH id_obs AS
	(SELECT dbeel_op_id, 'MIO_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.minho_obstruction_bis WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id)
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id; -- 210 rows

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
select distinct categoria from sudoang.minho_obstruction_bis where origem = 'Artificial';
/*
select * from sudoang.minho_obstruction_bis where categoria = 'Detritos' and origem = 'Artificial';
select * from sudoang.minho_obstruction_bis where categoria = 'Desnível' and origem = 'Artificial';
"Açude" = Weir, 292
"Canal" = Weir, 292
"Represa" = Dam, 291
"Queda de água" = Dam, 291
"Desnível" = Weir, 292
"Ponte" = Bridge, 296
"Outro" = Other, 297
"Detritos" = Weir, 292
"Mini-Hidrica" = Dam, 291
"ND" = Physical obstruction (unknown), 219
*/

-- TODO
begin;
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  altura AS po_obstruction_height,
	  NULL AS po_turbine_number,
	  CASE WHEN categoria = 'Açude' THEN 292 --'Weir' 
	     WHEN categoria = 'Canal' THEN 292 -- 'Weir'
	     WHEN categoria = 'Represa' THEN 291 -- 'Dam'
	     WHEN categoria = 'Queda de água' THEN 291 -- 'Dam'
	     WHEN categoria = 'Desnível' THEN 292 -- 'Weir'
	     WHEN categoria = 'Outro' THEN 293 -- 'Other'
	     WHEN categoria = 'Ponte' THEN 296 -- 'Bridge'
	     WHEN categoria = 'Mini-Hidrica' THEN 291 -- 'Dam'
	     WHEN categoria = 'ND' THEN 219 -- 'Physical obstruction (unknown)'
	     WHEN categoria = 'Detritos' THEN 292 -- 'Weir'
	     END AS ot_no_obstruction_type
	FROM sudoang.minho_obstruction_bis JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Carlos Antunes' --TODO: TO BE MODIFIED
	AND op_gis_layername = 'UP'
; -- 214 rows
commit;


-------------------------------------------------------------------------------------------------------------------------------
-- Eighth data incorporated = CANTABRICO BASIN (CHCantabr_ObsTrans, CHCantabr_ObstransGenerales, CHCantabr_ObstransTecnicos)
-------------------------------------------------------------------------------------------------------------------------------
/* 3 tables as geodatabase:
	-- CHCantabr_ObsTrans
	-- CHCantabr_ObstransGenerales
	-- CHCantabr_ObstransTecnicos
*/

---- First change the name of tables to avoid capital letters
alter table sudoang."CHCantabr_ObsTrans" rename to chcoc_obstruction;
alter table sudoang."CHCantabr_transGenerales" rename to chcoc_obstruction_gen;
alter table sudoang."CHCantabr_transTecnicos" rename to chcoc_obstruction_tec;

alter table sudoang.chcoc_obstruction rename column id to id0; -- Change the name of id because we also use id (=COC_) (line 125 in OBSTRUCTION_AGGREGATION script)
select * from sudoang.chcoc_obstruction limit 10;

---- Add establishment
-- select * from dbeel.establishment
-- 'MITECO' is the Cthe University of Porto, but we don't know the origin of data (ask to Carlos Antunes)
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('miteco'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Belén Muñoz', et_id FROM dbeel.establishment WHERE et_establishment_name = 'miteco' -- The other data set sent by Belen: 'min esp' and 'Belen'
; --TODO: TO BE MODIFIED
select * from sudoang.chcoc_obstruction;

---- The reprojection was done (line 257 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'chcoc_obstruction', 'geom'); -- 25830 to 3035

---- Creation spatial index
CREATE INDEX 
  ON sudoang.chcoc_obstruction
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','chcoc_obstruction','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- line 125 in OBSTRUCTION_AGGREGATION script: the id (character to define the table origin and a key)
--select * from sudoang.chcoc_obstruction limit 10
begin;
update sudoang.chcoc_obstruction set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.chcoc_obstruction a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= chcoc_obstruction.id; -- 1980 rows
commit;

CREATE INDEX 
  ON sudoang.chcoc_obstruction
  USING gist
  (geom_reproj);

---- Link Cantabrico dams TO dbeel
ALTER TABLE sudoang.chcoc_obstruction ADD COLUMN dbeel_op_id uuid;
-- update sudoang.chcoc_obstruction set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.chcoc_obstruction AS sp1, sudoang.chcoc_obstruction AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.chcoc_obstruction SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES

ALTER TABLE sudoang.chcoc_obstruction ADD COLUMN dist_to_dbeel numeric;
update sudoang.chcoc_obstruction set (dbeel_op_id, dist_to_dbeel) = (null, null); --1980

begin;
WITH duplicate_chcoc AS 
(
	SELECT DISTINCT geom_reproj, op_id, st_distance(the_geom, geom_reproj) as dist_to_dbeel 
	FROM sudoang.chcoc_obstruction, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'COC%' 
	AND geom_reproj IS NOT NULL 
	AND ST_DWithin(the_geom, geom_reproj, 500)
	AND "TIPO_INFR" in ('SV', 'PP', 'OM') -- 1565 rows. All except pipes and road crossing
	) 
UPDATE sudoang.chcoc_obstruction SET (dbeel_op_id, dist_to_dbeel) = (op_id, duplicate_chcoc.dist_to_dbeel)
FROM duplicate_chcoc 
WHERE id LIKE 'COC%' AND chcoc_obstruction.geom_reproj IS NOT NULL AND chcoc_obstruction.geom_reproj = duplicate_chcoc.geom_reproj
; -- 808 rows (total 1980)
commit;

--select * from sudoang.chcoc_obstruction_tec where "IF" != 0; -- passability
--select count(*), "ACC_DP_DS" from sudoang.chcoc_obstruction_tec group by "ACC_DP_DS";

---- Update height for these dams

-- select * from sudoang.chcoc_obstruction_gen where "autoUID" = '46ec2641-26b4-4b11-9db9-bcaf2d7c71b3';
-- select * from sudoang.chcoc_obstruction
-- select * from sudoang.chcoc_obstruction_tec


--------------------- dbeel_physical_obstruction update --------------------------------------------------------------------------------------------------------
-- Rationale: we have used the metadata in word to insert as best as possible in our tables
-- When the data are considered as poor and the state of the dam is correct ESTADO not in ('PR' (project),'CO',(construction), 'AR' abandonned and ruined, 'DM'
-- When the height are not 0 (in the database all NULL values are currently set to zero)
-- When the projet miteco says the data are sure => "CIERTO" = 'SI'
-- Then we update our database with new data on height and other stuff
-- We have tested on maps, two dams from miteco may be at less than 500 m from an obstacle from the dbeel
-- In that case both dams will refer to the same dam in the dbeel. 
-- If there is a duplicate we will only update the closest dam hence the use of the joined dam and closest dam queries
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
alter table sudoang.dbeel_physical_obstruction add column date_last_update date;
alter table sudoang.dbeel_physical_obstruction add column author_last_update text;
alter table sudoang.dbeel_physical_obstruction add column comment_update text;

begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chcoc_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.chcoc_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	AND ot."CIERTO" = 'SI' -- Maria in fact, I have added the two maybe it's not the best...
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
select * from closest_dam; -- 25 rows

UPDATE sudoang.dbeel_physical_obstruction 
	SET 
	(po_obstruction_height, po_downs_pb, po_downs_water_depth, po_presence_eel_pass, fishway_type, date_last_update, author_last_update, comment_update) = 
	(r.po_obstruction_height, r.po_downs_pb, r.po_downs_water_depth, r.po_presence_eel_pass, r.fishway_type,
	'2019-04-09',
	'María and Cédric',
	'Values of height, downs_pb, po_downs_water_depth, presence_eel_pass modified from data provided by the ministry (miteco) and labelled as CIERTO') 
	FROM (SELECT
	dbeel_op_id,
	CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height, 
	CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb, 
	CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal 
	"TIPO_PASO" AS fishway_type
	FROM closest_dam) r
	WHERE dbeel_op_id = ob_op_id
	--AND po_obstruction_height is null)  -- Here we choose to use the data from miteco as reference and we will overwrite any exisiting value in the database
	; -- 25 rows
commit;


-----------------HPP table -----------------------------------------------------------------------------------------------------------------------------
-- Same but we update the dbeel_hpp table
-- The rationale is that if a downstream passage is accessible (SI) then we consider that it is OK even if other criteria (velocity...) are not met...
-- Those passages are so few (5) see following query
-- select count(*), "ACC_DP_DS" from sudoang.chcoc_obstruction_tec group by "ACC_DP_DS";
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- "ACC_DP_DS" from chcoc_obstruction_tec is text, it must be converted into boolean:
alter table sudoang.chcoc_obstruction_tec
alter column "ACC_DP_DS"
set data type boolean
using case
    when "ACC_DP_DS" = 'SI' then true
    when "ACC_DP_DS" = 'NO' then false
    else null
end; -- 7 rows

-- A problem is found with the foreign key and the constraint for this ob_id:
select * from sudoang.dbeel_physical_obstruction where ob_id = '2b26ca82-b459-409a-85a1-54ccfa10e84c';
alter table sudoang.dbeel_hpp drop constraint c_fk_hpp_ob_id;
alter table sudoang.dbeel_hpp  ADD CONSTRAINT c_fk_hpp_ob_id FOREIGN KEY (hpp_ob_id)
      REFERENCES sudoang.dbeel_physical_obstruction (ob_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE

begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chcoc_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.chcoc_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 25 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM closest_dam
; -- 25 rows
COMMIT;


/*--------------------------------------------------------------
---- NEW dams inserted into dbeel_obstruction_place

above we have insterted op_id for duplicates and for some dams 
where 	"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
we have updated the information in the database
Now we will insert new data, but again with the following
"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
----------------------------------------------------------------*/
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.chcoc_obstruction o join sudoang.chcoc_obstruction_tec t on o."autoUID" = t."autoUID"
	WHERE o.dbeel_op_id IS NULL 
	AND o.geom_reproj IS NOT NULL
	AND o."CIERTO" = 'SI'
	and t."H_TOTAL" + t."H_SALTO" > 0
	AND t."ESTADO" not IN ('PR','CO','AR','DM') -- 78 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id, -- "autoUID" AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'miteco' AS op_gis_layername,  -- spain_obstruction_in_spain is the op_gis_layername from the ministry
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs
; -- 78 rows
commit;

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (chcoc_obstruction)
-- UPDATE sudoang.chcoc_obstruction SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.chcoc_obstruction SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 78 rows
	
---- The id of the source table (chcoc_obstruction) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
begin;
WITH id_obs AS
	(SELECT dbeel_op_id, 'COC_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.chcoc_obstruction WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 644 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='miteco'; -- 78 rows
commit;

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
WITH join_chcoc AS
(
	SELECT * FROM sudoang.chcoc_obstruction o join sudoang.chcoc_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_op_id is not null -- 886 rows
) 
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height,
	  CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb,
	  CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	  CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal
	  NULL AS po_method_perm_ev,
	  NULL AS po_date_presence_eel_pass,
	  "TIPO_PASO" AS fishway_type,
	  NULL AS date_last_update,
	  NULL AS author_last_update,
	  NULL AS comment_update
	FROM join_chcoc JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Belén Muñoz' --TODO: TO BE MODIFIED
	AND op_gis_layername='miteco'
; -- 78 rows
commit;

---- Add the ob_id from dbeel_physical obstruction in chcoc_obstruction
alter table sudoang.chcoc_obstruction add column dbeel_ob_id uuid;
UPDATE sudoang.chcoc_obstruction SET dbeel_ob_id = ob_id 
FROM (
	select * from sudoang.dbeel_obstruction_place join sudoang.dbeel_physical_obstruction ON ob_op_id = op_id) sub
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 78 rows

---- Insert into the dbeel_hpp table, all the characteristics of the new hpp
begin;
WITH join_chcoc AS
(
	SELECT * FROM sudoang.chcoc_obstruction o join sudoang.chcoc_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_ob_id is not null -- 78 rows
) 
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		dbeel_ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM join_chcoc
; -- 78 rows
COMMIT;

-- Update the type of obstacles
select distinct "TIPO_INFR" from sudoang.chcoc_obstruction;
/* The same for the tables: chcoc, chebro, chguad, chmin, chseg
|			|TIPO_INFR	|
|-----------------------|---------------|
|Salto vertical		|SV		| (dam)
|Paso entubado		|PE		| (culvert)
|Paso sobre paramento	|PP		| (weir)
|Obstáculo mixto	|OM		| (weir)
|Cruce con vial		|CV		| (bridge)
*/
select * from sudoang.chcoc_obstruction where "TIPO_INFR" = 'SV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 94 rows (total 861 rows)
select * from sudoang.chcoc_obstruction where "TIPO_INFR" = 'PE' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 0 rows
select * from sudoang.chcoc_obstruction where "TIPO_INFR" = 'PP' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 14 rows (total 23 rows)
select * from sudoang.chcoc_obstruction where "TIPO_INFR" = 'OM' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 0 rows (total 1 row)
select * from sudoang.chcoc_obstruction where "TIPO_INFR" = 'CV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 1 row

--select * from sudoang.chcoc_obstruction where dbeel_op_id is not null; -- 886 rows
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '219'
	from sudoang.chcoc_obstruction WHERE dbeel_op_id = ob_op_id; -- 644 rows

begin;
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.chcoc_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'SV' and "CIERTO" = 'SI'; -- 92 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chcoc_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'PP' and "CIERTO" = 'SI'; -- 14 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chcoc_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'OM' and "CIERTO" = 'SI'; -- 0 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '296'
	from sudoang.chcoc_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'CV' and "CIERTO" = 'SI'; -- 1 rows
commit;


-------------------------------------------------------------------------------------------------------------------------------
-- Ninth data incorporated = EBRO BASIN (CHEbro_ObsTrans, CHEbro_ObstransGenerales, CHEbro_ObstransTecnicos as geodatabase)
-------------------------------------------------------------------------------------------------------------------------------

---- First change the name of tables to avoid capital letters
alter table sudoang."CHEbro_ObsTrans" rename to chebro_obstruction;
alter table sudoang."CHEbro_transGenerales" rename to chebro_obstruction_gen;
alter table sudoang."CHEbro_transTecnicos" rename to chebro_obstruction_tec;

alter table sudoang.chebro_obstruction rename column id to id0; -- Change the name of id because we also use id (=CEB_) (line 134 in OBSTRUCTION_AGGREGATION script)

select * from sudoang.chebro_obstruction;

---- The reprojection was done (line 302 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'chebro_obstruction', 'geom'); -- 3035

---- Creation spatial index
CREATE INDEX 
  ON sudoang.chebro_obstruction
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','chebro_obstruction','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- line 135 in OBSTRUCTION_AGGREGATION script: the id (character to define the table origin and a key)
--select * from sudoang.chebro_obstruction limit 10
begin;
update sudoang.chebro_obstruction set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.chebro_obstruction a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= chebro_obstruction.id; -- 3470 rows (3 rows are missing)
commit;

CREATE INDEX 
  ON sudoang.chebro_obstruction
  USING gist
  (geom_reproj);

---- Link Cantabrico dams TO dbeel
ALTER TABLE sudoang.chebro_obstruction ADD COLUMN dbeel_op_id uuid;
-- update sudoang.chcoc_obstruction set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.chebro_obstruction AS sp1, sudoang.chebro_obstruction AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 2 rows (CEB 2524 with CEB 2525, CEB 2678 with CEB 2679)

/* Delete in all tables, one of the duplicates because they are the same
select * from sudoang.chebro_obstruction_tec where "autoUID" = 'b93566b2-049a-4586-9f3e-ae71a8343c11' or "autoUID" = '5e550ee2-6c90-4108-b2f4-1b70407ecac7'; -- drop CEB_2424: "autoUID" = '5e550ee2-6c90-4108-b2f4-1b70407ecac7'
select * from sudoang.chebro_obstruction_tec where "autoUID" = 'ae61d148-a7f2-4383-a0c5-7d16106ddeb7' or "autoUID" = '01d7a305-b6f7-4ce3-b322-0bf629a15b3c'; -- drop CEB 2679: "autoUID" = '01d7a305-b6f7-4ce3-b322-0bf629a15b3c'
delete from sudoang.chebro_obstruction where "autoUID" = '5e550ee2-6c90-4108-b2f4-1b70407ecac7';
delete from sudoang.chebro_obstruction_gen where "autoUID" = '5e550ee2-6c90-4108-b2f4-1b70407ecac7';
delete from sudoang.chebro_obstruction_tec where "autoUID" = '5e550ee2-6c90-4108-b2f4-1b70407ecac7';
delete from sudoang.chebro_obstruction where "autoUID" = '01d7a305-b6f7-4ce3-b322-0bf629a15b3c';
delete from sudoang.chebro_obstruction_gen where "autoUID" = '01d7a305-b6f7-4ce3-b322-0bf629a15b3c';
delete from sudoang.chebro_obstruction_tec where "autoUID" = '01d7a305-b6f7-4ce3-b322-0bf629a15b3c';
*/

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.chebro_obstruction SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES

ALTER TABLE sudoang.chebro_obstruction ADD COLUMN dist_to_dbeel numeric;
--update sudoang.chebro_obstruction set (dbeel_op_id, dist_to_dbeel) = (null, null);

begin;
WITH duplicate_chebro AS 
(
	SELECT DISTINCT geom_reproj, op_id, st_distance(the_geom, geom_reproj) as dist_to_dbeel 
	FROM sudoang.chebro_obstruction, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'CEB%' 
	AND geom_reproj IS NOT NULL 
	AND ST_DWithin(the_geom, geom_reproj, 500)
	AND "TIPO_INFR" in ('SV', 'PP', 'OM') -- 3489 rows. All except pipes and road crossing
	) 
UPDATE sudoang.chebro_obstruction SET (dbeel_op_id, dist_to_dbeel) = (op_id, duplicate_chebro.dist_to_dbeel)
FROM duplicate_chebro 
WHERE id LIKE 'CEB%' AND chebro_obstruction.geom_reproj IS NOT NULL AND chebro_obstruction.geom_reproj = duplicate_chebro.geom_reproj
; -- 2165 rows (total 3473)
commit;

--select * from sudoang.chebro_obstruction_tec where "IF" != 0; -- 0 passability
--select count(*), "ACC_DP_DS" from sudoang.chebro_obstruction_tec group by "ACC_DP_DS"; -- 1 NO, 31 NA, 1 CA


--------------------- dbeel_physical_obstruction update --------------------------------------------------------------------------------------------------------
-- Rationale: we have used the metadata in word to insert as best as possible in our tables
-- When the data are considered as poor and the state of the dam is correct ESTADO not in ('PR' (project),'CO',(construction), 'AR' abandonned and ruined, 'DM'
-- When the height are not 0 (in the database all NULL values are currently set to zero)
-- When the projet miteco says the data are sure => "CIERTO" = 'SI'
-- Then we update our database with new data on height and other stuff
-- We have tested on maps, two dams from miteco may be at less than 500 m from an obstacle from the dbeel
-- In that case both dams will refer to the same dam in the dbeel. 
-- If there is a duplicate we will only update the closest dam hence the use of the joined dam and closest dam queries
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chebro_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.chebro_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
-- select * from closest_dam; -- 250 rows
UPDATE sudoang.dbeel_physical_obstruction 
	SET 
	(po_obstruction_height, po_downs_pb, po_downs_water_depth, po_presence_eel_pass, fishway_type, date_last_update, author_last_update, comment_update) = 
	(r.po_obstruction_height, r.po_downs_pb, r.po_downs_water_depth, r.po_presence_eel_pass, r.fishway_type,
	'2019-04-16',
	'María and Cédric',
	'Values of height, downs_pb, po_downs_water_depth, presence_eel_pass modified from data provided by the ministry (miteco) and labelled as CIERTO') 
	FROM (SELECT
	dbeel_op_id,
	CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height, 
	CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb, 
	CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal 
	"TIPO_PASO" AS fishway_type
	FROM closest_dam) r
	WHERE dbeel_op_id = ob_op_id
	--AND po_obstruction_height is null)  -- Here we choose to use the data from miteco as reference and we will overwrite any exisiting value in the database
	; -- 251 rows
commit; 


-----------------HPP table -----------------------------------------------------------------------------------------------------------------------------
-- Same but we update the dbeel_hpp table
-- The rationale is that if a downstream passage is accessible (SI) then we consider that it is OK even if other criteria (velocity...) are not met...
-- Those passages are so few (5) see following query
-- select count(*), "ACC_DP_DS" from sudoang.chebro_obstruction_tec group by "ACC_DP_DS";
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- "ACC_DP_DS" from chebro_obstruction_tec is text, it must be converted into boolean:
alter table sudoang.chebro_obstruction_tec
alter column "ACC_DP_DS"
set data type boolean
using case
    when "ACC_DP_DS" = 'SI' then true
    when "ACC_DP_DS" = 'NO' then false
    else null
end; -- 0 rows

begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chebro_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.chebro_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
-- select * from closest_dam; -- 250 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM closest_dam
; -- 250 rows
COMMIT;


/*--------------------------------------------------------------
---- NEW dams inserted into dbeel_obstruction_place

Above we have inserted op_id for duplicates and for some dams 
where 	"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
We have updated the information in the database
Now we will insert new data, but again with the following
"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
----------------------------------------------------------------*/
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.chebro_obstruction o join sudoang.chebro_obstruction_tec t on o."autoUID" = t."autoUID"
	WHERE o.dbeel_op_id IS NULL 
	AND o.geom_reproj IS NOT NULL
	AND o."CIERTO" = 'SI'
	and t."H_TOTAL" + t."H_SALTO" > 0
	AND t."ESTADO" not IN ('PR','CO','AR','DM') -- 76 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id, -- "autoUID" AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'miteco' AS op_gis_layername,  -- spain_obstruction_in_spain is the op_gis_layername from the ministry
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs
; -- 76 rows
commit;

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (chebro_obstruction)
-- UPDATE sudoang.chebro_obstruction SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.chebro_obstruction SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 76 rows
	
---- The id of the source table (chebro_obstruction) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
begin;
WITH id_obs AS
	(SELECT dbeel_op_id, 'CEB_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.chebro_obstruction WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 1681 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='miteco'; -- 76 rows
commit;

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
WITH join_chebro AS
(
	SELECT * FROM sudoang.chebro_obstruction o join sudoang.chebro_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_op_id is not null -- 886 rows
) 
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height,
	  CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb,
	  CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	  CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal
	  NULL AS po_method_perm_ev,
	  NULL AS po_date_presence_eel_pass,
	  "TIPO_PASO" AS fishway_type,
	  NULL AS date_last_update,
	  NULL AS author_last_update,
	  NULL AS comment_update
	FROM join_chebro JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Belén Muñoz' --TODO: TO BE MODIFIED
	AND op_gis_layername='miteco'
; -- 76 rows
commit;

---- Add the ob_id from dbeel_physical obstruction in chebro_obstruction
alter table sudoang.chebro_obstruction add column dbeel_ob_id uuid;
UPDATE sudoang.chebro_obstruction SET dbeel_ob_id = ob_id 
FROM (
	select * from sudoang.dbeel_obstruction_place join sudoang.dbeel_physical_obstruction ON ob_op_id = op_id) sub
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 76 rows

---- Insert into the dbeel_hpp table, all the characteristics of the new hpp
begin;
WITH join_chebro AS
(
	SELECT * FROM sudoang.chebro_obstruction o join sudoang.chebro_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_ob_id is not null -- 76 rows
) 
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		dbeel_ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM join_chebro
; -- 76 rows
COMMIT;

-- Update the type of obstacles
select distinct "TIPO_INFR" from sudoang.chebro_obstruction;
/* The same for the tables: chcoc, chebro, chguad, chmin, chseg
|			|TIPO_INFR	|
|-----------------------|---------------|
|Salto vertical		|SV		| (dam)
|Paso entubado		|PE		| (culvert)
|Paso sobre paramento	|PP		| (weir)
|Obstáculo mixto	|OM		| (weir)
|Cruce con vial		|CV		| (bridge)
*/
select * from sudoang.chebro_obstruction where "TIPO_INFR" = 'SV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 596 rows (total 1813 rows)
select * from sudoang.chebro_obstruction where "TIPO_INFR" = 'PE' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 9 rows (total 21 rows)
select * from sudoang.chebro_obstruction where "TIPO_INFR" = 'PP' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 184 rows (total 332 rows)
select * from sudoang.chebro_obstruction where "TIPO_INFR" = 'OM' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 35 rows (total 85 rows)
select * from sudoang.chebro_obstruction where "TIPO_INFR" = 'CV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 0 row

--select * from sudoang.chebro_obstruction where dbeel_op_id is not null; -- 2239 rows
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '219'
	from sudoang.chebro_obstruction WHERE dbeel_op_id = ob_op_id; -- 1681 rows (total 1785 rows)

begin;
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.chebro_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'SV' and "CIERTO" = 'SI'; -- 450 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '294'
	from sudoang.chebro_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'PE' and "CIERTO" = 'SI'; -- 9 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chebro_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'PP' and "CIERTO" = 'SI'; -- 178 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chebro_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'OM' and "CIERTO" = 'SI'; -- 30 rows
commit;


-------------------------------------------------------------------------------------------------------------------------------
-- Tenth data incorporated = GUADIANA BASIN (CHGuadiana_ObsTrans, CHGuadiana_ObstransGenerales, CHGuadiana_ObstransTecnicos as geodatabase)
-------------------------------------------------------------------------------------------------------------------------------
---- First change the name of tables to avoid capital letters
alter table sudoang."CHGuadiana_ObsTrans" rename to chguad_obstruction;
alter table sudoang."CHGuadiana_transGenerales" rename to chguad_obstruction_gen;
alter table sudoang."CHGuadiana_transTecnicos" rename to chguad_obstruction_tec;

alter table sudoang.chguad_obstruction rename column id to id0; -- Change the name of id because we also use id (=CEB_) (line 134 in OBSTRUCTION_AGGREGATION script)

---- The reprojection was done (line 306 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'chguad_obstruction', 'geom'); -- 3035

---- Creation spatial index
CREATE INDEX 
  ON sudoang.chguad_obstruction
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','chguad_obstruction','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- line 145 in OBSTRUCTION_AGGREGATION script: the id (character to define the table origin and a key)
--select * from sudoang.chebro_obstruction limit 10
begin;
update sudoang.chguad_obstruction set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.chguad_obstruction a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= chguad_obstruction.id; -- 1192 rows (4 rows are missing)
commit;

CREATE INDEX 
  ON sudoang.chguad_obstruction
  USING gist
  (geom_reproj);

---- Link Cantabrico dams TO dbeel
ALTER TABLE sudoang.chguad_obstruction ADD COLUMN dbeel_op_id uuid;
-- update sudoang.chcoc_obstruction set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.chguad_obstruction AS sp1, sudoang.chguad_obstruction AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer; -- 0 rows

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.chguad_obstruction SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES

ALTER TABLE sudoang.chguad_obstruction ADD COLUMN dist_to_dbeel numeric;
--update sudoang.chguad_obstruction set (dbeel_op_id, dist_to_dbeel) = (null, null);

begin;
WITH duplicate_chguad AS 
(
	SELECT DISTINCT geom_reproj, op_id, st_distance(the_geom, geom_reproj) as dist_to_dbeel 
	FROM sudoang.chguad_obstruction, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'CGU%' 
	AND geom_reproj IS NOT NULL 
	AND ST_DWithin(the_geom, geom_reproj, 500)
	AND "TIPO_INFR" in ('SV', 'PP', 'OM') -- 108 rows. All except pipes and road crossing
	) 
UPDATE sudoang.chguad_obstruction SET (dbeel_op_id, dist_to_dbeel) = (op_id, duplicate_chguad.dist_to_dbeel)
FROM duplicate_chguad 
WHERE id LIKE 'CGU%' AND chguad_obstruction.geom_reproj IS NOT NULL AND chguad_obstruction.geom_reproj = duplicate_chguad.geom_reproj
; -- 103 rows (total 1196)
commit;

--select * from sudoang.chguad_obstruction_tec where "IF" != 0; -- 0 passability
--select count(*), "ACC_DP_DS" from sudoang.chguad_obstruction_tec group by "ACC_DP_DS"; -- 0


--------------------- dbeel_physical_obstruction update --------------------------------------------------------------------------------------------------------
-- Rationale: we have used the metadata in word to insert as best as possible in our tables
-- When the data are considered as poor and the state of the dam is correct ESTADO not in ('PR' (project),'CO',(construction), 'AR' abandonned and ruined, 'DM'
-- When the height are not 0 (in the database all NULL values are currently set to zero)
-- When the projet miteco says the data are sure => "CIERTO" = 'SI'
-- Then we update our database with new data on height and other stuff
-- We have tested on maps, two dams from miteco may be at less than 500 m from an obstacle from the dbeel
-- In that case both dams will refer to the same dam in the dbeel. 
-- If there is a duplicate we will only update the closest dam hence the use of the joined dam and closest dam queries
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chguad_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.chguad_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 49 rows
UPDATE sudoang.dbeel_physical_obstruction 
	SET 
	(po_obstruction_height, po_downs_pb, po_downs_water_depth, po_presence_eel_pass, fishway_type, date_last_update, author_last_update, comment_update) = 
	(r.po_obstruction_height, r.po_downs_pb, r.po_downs_water_depth, r.po_presence_eel_pass, r.fishway_type,
	'2019-04-16',
	'María and Cédric',
	'Values of height, downs_pb, po_downs_water_depth, presence_eel_pass modified from data provided by the ministry (miteco) and labelled as CIERTO') 
	FROM (SELECT
	dbeel_op_id,
	CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height, 
	CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb, 
	CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal 
	"TIPO_PASO" AS fishway_type
	FROM closest_dam) r
	WHERE dbeel_op_id = ob_op_id
	--AND po_obstruction_height is null)  -- Here we choose to use the data from miteco as reference and we will overwrite any exisiting value in the database
	; -- 49 rows
commit; 


-----------------HPP table -----------------------------------------------------------------------------------------------------------------------------
-- Same but we update the dbeel_hpp table
-- The rationale is that if a downstream passage is accessible (SI) then we consider that it is OK even if other criteria (velocity...) are not met...
-- Those passages are so few (5) see following query
-- select count(*), "ACC_DP_DS" from sudoang.chcoc_obstruction_tec group by "ACC_DP_DS";
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- "ACC_DP_DS" from chcoc_obstruction_tec is text, it must be converted into boolean:
alter table sudoang.chguad_obstruction_tec
alter column "ACC_DP_DS"
set data type boolean
using case
    when "ACC_DP_DS" = 'SI' then true
    when "ACC_DP_DS" = 'NO' then false
    else null
end; -- 0 rows

begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chguad_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.chguad_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 49 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM closest_dam
; -- 49 rows
COMMIT;


/*--------------------------------------------------------------
---- NEW dams inserted into dbeel_obstruction_place

above we have insterted op_id for duplicates and for some dams 
where 	"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
we have updated the information in the database
Now we will insert new data, but again with the following
"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
----------------------------------------------------------------*/
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.chguad_obstruction o join sudoang.chguad_obstruction_tec t on o."autoUID" = t."autoUID"
	WHERE o.dbeel_op_id IS NULL 
	AND o.geom_reproj IS NOT NULL
	AND o."CIERTO" = 'SI'
	and t."H_TOTAL" + t."H_SALTO" > 0
	AND t."ESTADO" not IN ('PR','CO','AR','DM') -- 5 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id, -- "autoUID" AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'miteco' AS op_gis_layername,  -- spain_obstruction_in_spain is the op_gis_layername from the ministry
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs
; -- 5 rows
commit;

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (chguad_obstruction)
-- UPDATE sudoang.chguad_obstruction SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.chguad_obstruction SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 5 rows
	
---- The id of the source table (chguad_obstruction) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
begin;
WITH id_obs AS
	(SELECT dbeel_op_id, 'CGU_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.chguad_obstruction WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 644 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='miteco'; -- 5 rows
commit;

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
WITH join_chguad AS
(
	SELECT * FROM sudoang.chguad_obstruction o join sudoang.chguad_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_op_id is not null -- 108 rows
) 
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height,
	  CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb,
	  CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	  CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal
	  NULL AS po_method_perm_ev,
	  NULL AS po_date_presence_eel_pass,
	  "TIPO_PASO" AS fishway_type,
	  NULL AS date_last_update,
	  NULL AS author_last_update,
	  NULL AS comment_update
	FROM join_chguad JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Belén Muñoz' --TODO: TO BE MODIFIED
	AND op_gis_layername='miteco'
; -- 5 rows
commit;

---- Add the ob_id from dbeel_physical obstruction in chguad_obstruction
alter table sudoang.chguad_obstruction add column dbeel_ob_id uuid;
UPDATE sudoang.chguad_obstruction SET dbeel_ob_id = ob_id 
FROM (
	select * from sudoang.dbeel_obstruction_place join sudoang.dbeel_physical_obstruction ON ob_op_id = op_id) sub
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 5 rows

---- Insert into the dbeel_hpp table, all the characteristics of the new hpp
begin;
WITH join_chguad AS
(
	SELECT * FROM sudoang.chguad_obstruction o join sudoang.chguad_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_ob_id is not null -- 5 rows
) 
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		dbeel_ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM join_chguad
; -- 5 rows
COMMIT;

-- Update the type of obstacles
select distinct "TIPO_INFR" from sudoang.chguad_obstruction;
/* The same for the tables: chcoc, chebro, chguad, chmin, chseg
|			|TIPO_INFR	|
|-----------------------|---------------|
|Salto vertical		|SV		| (dam)
|Paso entubado		|PE		| (culvert)
|Paso sobre paramento	|PP		| (weir)
|Obstáculo mixto	|OM		| (weir)
|Cruce con vial		|CV		| (bridge)
*/
select * from sudoang.chguad_obstruction where "TIPO_INFR" = 'SV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 54 rows (total 84 rows)
select * from sudoang.chguad_obstruction where "TIPO_INFR" = 'PE' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 0 rows
select * from sudoang.chguad_obstruction where "TIPO_INFR" = 'PP' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 11 rows (total 20 rows)
select * from sudoang.chguad_obstruction where "TIPO_INFR" = 'OM' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 0 rows
select * from sudoang.chguad_obstruction where "TIPO_INFR" = 'CV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 4 rows

--select * from sudoang.chguad_obstruction where dbeel_op_id is not null; -- 108 rows
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '219'
	from sudoang.chguad_obstruction WHERE dbeel_op_id = ob_op_id; -- 101 rows (total 103 rows)

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.chguad_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'SV' and "CIERTO" = 'SI'; -- 53 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chguad_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'PP' and "CIERTO" = 'SI'; -- 10 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '296'
	from sudoang.chguad_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'CV' and "CIERTO" = 'SI'; -- 4 rows


-----------------------------------------------------------------------------------------------------------------------------------------
-- Eleventh data incorporated = SEGURA BASIN (CHSegura_ObsTrans, CHSegura_ObstransGenerales, CHSegura_ObstransTecnicos as geodatabase)
-----------------------------------------------------------------------------------------------------------------------------------------
---- First change the name of tables to avoid capital letters
alter table sudoang."CHSegura_ObsTrans" rename to chseg_obstruction;
alter table sudoang."CHSegura_transGenerales" rename to chseg_obstruction_gen;
alter table sudoang."CHSegura_transTecnicos" rename to chseg_obstruction_tec;

alter table sudoang.chseg_obstruction rename column id to id0; -- Change the name of id because we also use id (=CEB_) (line 134 in OBSTRUCTION_AGGREGATION script)

---- The reprojection was done (line 310 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'chseg_obstruction', 'geom'); -- 3035

---- Creation spatial index
CREATE INDEX 
  ON sudoang.chseg_obstruction
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','chseg_obstruction','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- line 155 in OBSTRUCTION_AGGREGATION script: the id (character to define the table origin and a key)
--select * from sudoang.chseg_obstruction limit 10
update sudoang.chseg_obstruction set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.chseg_obstruction a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= chseg_obstruction.id; -- 776 rows (3 rows are missing)

CREATE INDEX 
  ON sudoang.chseg_obstruction
  USING gist
  (geom_reproj);

---- Link Cantabrico dams TO dbeel
ALTER TABLE sudoang.chseg_obstruction ADD COLUMN dbeel_op_id uuid;
-- update sudoang.chcoc_obstruction set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.chseg_obstruction AS sp1, sudoang.chseg_obstruction AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.chseg_obstruction SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES

ALTER TABLE sudoang.chseg_obstruction ADD COLUMN dist_to_dbeel numeric;
--update sudoang.chseg_obstruction set (dbeel_op_id, dist_to_dbeel) = (null, null);

begin;
WITH duplicate_chseg AS 
(
	SELECT DISTINCT geom_reproj, op_id, st_distance(the_geom, geom_reproj) as dist_to_dbeel 
	FROM sudoang.chseg_obstruction, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'CSE%' 
	AND geom_reproj IS NOT NULL 
	AND ST_DWithin(the_geom, geom_reproj, 500)
	AND "TIPO_INFR" in ('SV', 'PP', 'OM') -- 221 rows. All except pipes and road crossing
	) 
UPDATE sudoang.chseg_obstruction SET (dbeel_op_id, dist_to_dbeel) = (op_id, duplicate_chseg.dist_to_dbeel)
FROM duplicate_chseg 
WHERE id LIKE 'CSE%' AND chseg_obstruction.geom_reproj IS NOT NULL AND chseg_obstruction.geom_reproj = duplicate_chseg.geom_reproj
; -- 167 rows (total 779)
commit;

--select * from sudoang.chseg_obstruction_tec where "IF" != 0; -- 0 passability
--select count(*), "ACC_DP_DS" from sudoang.chseg_obstruction_tec group by "ACC_DP_DS"; -- 0


--------------------- dbeel_physical_obstruction update --------------------------------------------------------------------------------------------------------
-- Rationale: we have used the metadata in word to insert as best as possible in our tables
-- When the data are considered as poor and the state of the dam is correct ESTADO not in ('PR' (project),'CO',(construction), 'AR' abandonned and ruined, 'DM'
-- When the height are not 0 (in the database all NULL values are currently set to zero)
-- When the projet miteco says the data are sure => "CIERTO" = 'SI'
-- Then we update our database with new data on height and other stuff
-- We have tested on maps, two dams from miteco may be at less than 500 m from an obstacle from the dbeel
-- In that case both dams will refer to the same dam in the dbeel. 
-- If there is a duplicate we will only update the closest dam hence the use of the joined dam and closest dam queries
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chseg_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.chseg_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 108 rows
UPDATE sudoang.dbeel_physical_obstruction 
	SET 
	(po_obstruction_height, po_downs_pb, po_downs_water_depth, po_presence_eel_pass, fishway_type, date_last_update, author_last_update, comment_update) = 
	(r.po_obstruction_height, r.po_downs_pb, r.po_downs_water_depth, r.po_presence_eel_pass, r.fishway_type,
	'2019-04-16',
	'María and Cédric',
	'Values of height, downs_pb, po_downs_water_depth, presence_eel_pass modified from data provided by the ministry (miteco) and labelled as CIERTO') 
	FROM (SELECT
	dbeel_op_id,
	CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height, 
	CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb, 
	CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal 
	"TIPO_PASO" AS fishway_type
	FROM closest_dam) r
	WHERE dbeel_op_id = ob_op_id
	--AND po_obstruction_height is null)  -- Here we choose to use the data from miteco as reference and we will overwrite any exisiting value in the database
	; -- 108 rows
commit; 


-----------------HPP table -----------------------------------------------------------------------------------------------------------------------------
-- Same but we update the dbeel_hpp table
-- The rationale is that if a downstream passage is accessible (SI) then we consider that it is OK even if other criteria (velocity...) are not met...
-- Those passages are so few (5) see following query
-- select count(*), "ACC_DP_DS" from sudoang.chcoc_obstruction_tec group by "ACC_DP_DS";
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- "ACC_DP_DS" from chseg_obstruction_tec is text, it must be converted into boolean:
alter table sudoang.chseg_obstruction_tec
alter column "ACC_DP_DS"
set data type boolean
using case
    when "ACC_DP_DS" = 'SI' then true
    when "ACC_DP_DS" = 'NO' then false
    else null
end; -- 0 rows

begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chseg_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.chseg_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 108 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM closest_dam
; -- 108 rows
COMMIT;


/*--------------------------------------------------------------
---- NEW dams inserted into dbeel_obstruction_place

above we have insterted op_id for duplicates and for some dams 
where 	"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
we have updated the information in the database
Now we will insert new data, but again with the following
"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
----------------------------------------------------------------*/
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.chseg_obstruction o join sudoang.chseg_obstruction_tec t on o."autoUID" = t."autoUID"
	WHERE o.dbeel_op_id IS NULL 
	AND o.geom_reproj IS NOT NULL
	AND o."CIERTO" = 'SI'
	and t."H_TOTAL" + t."H_SALTO" > 0
	AND t."ESTADO" not IN ('PR','CO','AR','DM') -- 39 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id, -- "autoUID" AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'miteco' AS op_gis_layername,  -- spain_obstruction_in_spain is the op_gis_layername from the ministry
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs
; -- 39 rows
commit;

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (chcoc_obstruction)
-- UPDATE sudoang.chseg_obstruction SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.chseg_obstruction SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 39 rows
	
---- The id of the source table (chseg_obstruction) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
begin;
WITH id_obs AS
	(SELECT dbeel_op_id, 'CSE_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.chseg_obstruction WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 644 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='miteco'; -- 39 rows
commit;

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
WITH join_chseg AS
(
	SELECT * FROM sudoang.chseg_obstruction o join sudoang.chseg_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_op_id is not null -- 206 rows
) 
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height,
	  CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb,
	  CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	  CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal
	  NULL AS po_method_perm_ev,
	  NULL AS po_date_presence_eel_pass,
	  "TIPO_PASO" AS fishway_type,
	  NULL AS date_last_update,
	  NULL AS author_last_update,
	  NULL AS comment_update
	FROM join_chseg JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Belén Muñoz' --TODO: TO BE MODIFIED
	AND op_gis_layername='miteco'
; -- 39 rows
commit;

---- Add the ob_id from dbeel_physical obstruction in chseg_obstruction
alter table sudoang.chseg_obstruction add column dbeel_ob_id uuid;
UPDATE sudoang.chseg_obstruction SET dbeel_ob_id = ob_id 
FROM (
	select * from sudoang.dbeel_obstruction_place join sudoang.dbeel_physical_obstruction ON ob_op_id = op_id) sub
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 39 rows

---- Insert into the dbeel_hpp table, all the characteristics of the new hpp
begin;
WITH join_chseg AS
(
	SELECT * FROM sudoang.chseg_obstruction o join sudoang.chseg_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_ob_id is not null -- 39 rows
) 
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		dbeel_ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM join_chseg
; -- 39 rows
COMMIT;

-- Update the type of obstacles
select distinct "TIPO_INFR" from sudoang.chseg_obstruction;
/* The same for the tables: chcoc, chebro, chguad, chmin, chseg
|			|TIPO_INFR	|
|-----------------------|---------------|
|Salto vertical		|SV		| (dam)
|Paso entubado		|PE		| (culvert)
|Paso sobre paramento	|PP		| (weir)
|Obstáculo mixto	|OM		| (weir)
|Cruce con vial		|CV		| (bridge)
*/
select * from sudoang.chseg_obstruction where "TIPO_INFR" = 'SV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 76 rows (total 90 rows)
select * from sudoang.chseg_obstruction where "TIPO_INFR" = 'PE' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 9 rows
select * from sudoang.chseg_obstruction where "TIPO_INFR" = 'PP' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 84 rows (total 94 rows)
select * from sudoang.chseg_obstruction where "TIPO_INFR" = 'OM' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 11 row
select * from sudoang.chseg_obstruction where "TIPO_INFR" = 'CV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 2 row

--select * from sudoang.chseg_obstruction where dbeel_op_id is not null; -- 206 rows
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '219'
	from sudoang.chseg_obstruction WHERE dbeel_op_id = ob_op_id; -- 173 rows (total 183 rows)

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.chseg_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'SV' and "CIERTO" = 'SI'; -- 66 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '294'
	from sudoang.chseg_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'PE' and "CIERTO" = 'SI'; -- 9 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chseg_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'PP' and "CIERTO" = 'SI'; -- 75 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chseg_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'OM' and "CIERTO" = 'SI'; -- 11 rows
		
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '296'
	from sudoang.chseg_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'CV' and "CIERTO" = 'SI'; -- 2 rows


-----------------------------------------------------------------------------------------------------------------------------------------
-- Twelfth data incorporated = MINHO BASIN (CHMinho_ObsTrans, CHSMinho_ObstransGenerales, CHMinho_ObstransTecnicos as geodatabase)
-----------------------------------------------------------------------------------------------------------------------------------------
---- First change the name of tables to avoid capital letters
alter table sudoang."CHMinho_ObsTrans" rename to chmin_obstruction;
alter table sudoang."CHMinho_transGenerales" rename to chmin_obstruction_gen;
alter table sudoang."CHMinho_transTecnicos" rename to chmin_obstruction_tec;

alter table sudoang.chmin_obstruction rename column id to id0; -- Change the name of id because we also use id (=CEB_) (line 134 in OBSTRUCTION_AGGREGATION script)

---- The reprojection was done (line 314 in OBSTRUCTION_AGGREGATION script). Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'chmin_obstruction', 'geom'); -- 3035

---- Creation spatial index
CREATE INDEX 
  ON sudoang.chmin_obstruction
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','chmin_obstruction','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- line 165 in OBSTRUCTION_AGGREGATION script: the id (character to define the table origin and a key)
--select * from sudoang.chmin_obstruction limit 10
update sudoang.chmin_obstruction set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.chmin_obstruction a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= chmin_obstruction.id; -- 3067 rows

CREATE INDEX 
  ON sudoang.chmin_obstruction
  USING gist
  (geom_reproj);

---- Link Cantabrico dams TO dbeel
ALTER TABLE sudoang.chmin_obstruction ADD COLUMN dbeel_op_id uuid;
-- update sudoang.chcoc_obstruction set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.chmin_obstruction AS sp1, sudoang.chmin_obstruction AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.chmin_obstruction SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES

ALTER TABLE sudoang.chmin_obstruction ADD COLUMN dist_to_dbeel numeric;
--update sudoang.chmin_obstruction set (dbeel_op_id, dist_to_dbeel) = (null, null);

begin;
WITH duplicate_chmin AS 
(
	SELECT DISTINCT geom_reproj, op_id, st_distance(the_geom, geom_reproj) as dist_to_dbeel 
	FROM sudoang.chmin_obstruction, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'CMI%' 
	AND geom_reproj IS NOT NULL 
	AND ST_DWithin(the_geom, geom_reproj, 500)
	AND "TIPO_INFR" in ('SV', 'PP', 'OM') -- 6676 rows. All except pipes and road crossing
	) 
UPDATE sudoang.chmin_obstruction SET (dbeel_op_id, dist_to_dbeel) = (op_id, duplicate_chmin.dist_to_dbeel)
FROM duplicate_chmin 
WHERE id LIKE 'CMI%' AND chmin_obstruction.geom_reproj IS NOT NULL AND chmin_obstruction.geom_reproj = duplicate_chmin.geom_reproj
; -- 2407 rows (total 3067)
commit;

--select * from sudoang.chmin_obstruction_tec where "IF" != 0; -- 0 passability
--select count(*), "ACC_DP_DS" from sudoang.chmin_obstruction_tec group by "ACC_DP_DS"; -- 0


--------------------- dbeel_physical_obstruction update --------------------------------------------------------------------------------------------------------
-- Rationale: we have used the metadata in word to insert as best as possible in our tables
-- When the data are considered as poor and the state of the dam is correct ESTADO not in ('PR' (project),'CO',(construction), 'AR' abandonned and ruined, 'DM'
-- When the height are not 0 (in the database all NULL values are currently set to zero)
-- When the projet miteco says the data are sure => "CIERTO" = 'SI'
-- Then we update our database with new data on height and other stuff
-- We have tested on maps, two dams from miteco may be at less than 500 m from an obstacle from the dbeel
-- In that case both dams will refer to the same dam in the dbeel. 
-- If there is a duplicate we will only update the closest dam hence the use of the joined dam and closest dam queries
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chmin_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.chmin_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 332 rows
UPDATE sudoang.dbeel_physical_obstruction 
	SET 
	(po_obstruction_height, po_downs_pb, po_downs_water_depth, po_presence_eel_pass, fishway_type, date_last_update, author_last_update, comment_update) = 
	(r.po_obstruction_height, r.po_downs_pb, r.po_downs_water_depth, r.po_presence_eel_pass, r.fishway_type,
	'2019-04-16',
	'María and Cédric',
	'Values of height, downs_pb, po_downs_water_depth, presence_eel_pass modified from data provided by the ministry (miteco) and labelled as CIERTO') 
	FROM (SELECT
	dbeel_op_id,
	CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height, 
	CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb, 
	CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal 
	"TIPO_PASO" AS fishway_type
	FROM closest_dam) r
	WHERE dbeel_op_id = ob_op_id
	--AND po_obstruction_height is null)  -- Here we choose to use the data from miteco as reference and we will overwrite any exisiting value in the database
	; -- 332 rows
commit; 


-----------------HPP table -----------------------------------------------------------------------------------------------------------------------------
-- Same but we update the dbeel_hpp table
-- The rationale is that if a downstream passage is accessible (SI) then we consider that it is OK even if other criteria (velocity...) are not met...
-- Those passages are so few (5) see following query
-- select count(*), "ACC_DP_DS" from sudoang.chmin_obstruction_tec group by "ACC_DP_DS";
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- "ACC_DP_DS" from chmin_obstruction_tec is text, it must be converted into boolean:
alter table sudoang.chmin_obstruction_tec
alter column "ACC_DP_DS"
set data type boolean
using case
    when "ACC_DP_DS" = 'SI' then true
    when "ACC_DP_DS" = 'NO' then false
    else null
end; -- 0 rows

begin;
with joined_dam as (
select * from sudoang.dbeel_obstruction_place d join sudoang.chmin_obstruction o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.chmin_obstruction_tec ot on o."autoUID" = ot."autoUID"
	where o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM') 
	order by op_id, dist_to_dbeel),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 331 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM closest_dam
; -- 331 rows
COMMIT;


/*--------------------------------------------------------------
---- NEW dams inserted into dbeel_obstruction_place

above we have insterted op_id for duplicates and for some dams 
where 	"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
we have updated the information in the database
Now we will insert new data, but again with the following
"CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND ESTADO not IN ('PR','CO','AR','DM') 
----------------------------------------------------------------*/
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.chmin_obstruction o join sudoang.chmin_obstruction_tec t on o."autoUID" = t."autoUID"
	WHERE o.dbeel_op_id IS NULL 
	AND o.geom_reproj IS NOT NULL
	AND o."CIERTO" = 'SI'
	and t."H_TOTAL" + t."H_SALTO" > 0
	AND t."ESTADO" not IN ('PR','CO','AR','DM') -- 45 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id, -- "autoUID" AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'miteco' AS op_gis_layername,  -- spain_obstruction_in_spain is the op_gis_layername from the ministry
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs
; -- 45 rows
commit;

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (chmin_obstruction)
-- UPDATE sudoang.chmin_obstruction SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.chmin_obstruction SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 45 rows
	
---- The id of the source table (chmin_obstruction) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
begin;
WITH id_obs AS
	(SELECT dbeel_op_id, 'CMI_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.chmin_obstruction WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 1480 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='miteco'; -- 45 rows
commit;

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
WITH join_chmin AS
(
	SELECT * FROM sudoang.chmin_obstruction o join sudoang.chmin_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_op_id is not null -- 2452 rows
) 
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  CASE WHEN "H_SALTO" != 0 THEN "H_SALTO" ELSE "H_TOTAL" END AS po_obstruction_height,
	  CASE WHEN "TURB_MOL" IN ('SI','CAUDAL') THEN TRUE ELSE NULL END AS po_downs_pb,
	  CASE WHEN "PROF_POZA" >0 THEN "PROF_POZA" ELSE NULL END AS po_downs_water_depth, 
	  CASE WHEN "TIPO_PASO" IN ('ES','RP','CL') THEN TRUE ELSE NULL END AS po_presence_eel_pass,  -- 'ES' = Pool type fishway, 'RP' = rock ramp, 'CL' = lateral canal
	  NULL AS po_method_perm_ev,
	  NULL AS po_date_presence_eel_pass,
	  "TIPO_PASO" AS fishway_type,
	  NULL AS date_last_update,
	  NULL AS author_last_update,
	  NULL AS comment_update
	FROM join_chmin JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Belén Muñoz' --TODO: TO BE MODIFIED
	AND op_gis_layername='miteco'
; -- 45 rows
commit;

---- Add the ob_id from dbeel_physical obstruction in chmin_obstruction
alter table sudoang.chmin_obstruction add column dbeel_ob_id uuid;
UPDATE sudoang.chmin_obstruction SET dbeel_ob_id = ob_id 
FROM (
	select * from sudoang.dbeel_obstruction_place join sudoang.dbeel_physical_obstruction ON ob_op_id = op_id) sub
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='miteco'; -- 45 rows

---- Insert into the dbeel_hpp table, all the characteristics of the new hpp
begin;
WITH join_chmin AS
(
	SELECT * FROM sudoang.chmin_obstruction o join sudoang.chmin_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_ob_id is not null -- 78 rows
) 
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_presence_of_bar_rack, hpp_presence_bypass)
	SELECT
		uuid_generate_v4() as hpp_id,
		dbeel_ob_id AS hpp_ob_id,
		CASE WHEN "EXIS_REJA" = 'SI' THEN TRUE ELSE NULL END AS hpp_presence_of_bar_rack, 
		"ACC_DP_DS" AS hpp_presence_bypass
	FROM join_chmin
; -- 45 rows
COMMIT;

-- Update the type of obstacles
select distinct "TIPO_INFR" from sudoang.chmin_obstruction;
/* The same for the tables: chcoc, chebro, chguad, chmin, chseg
|			|TIPO_INFR	|
|-----------------------|---------------|
|Salto vertical		|SV		| (dam)
|Paso entubado		|PE		| (culvert)
|Paso sobre paramento	|PP		| (weir)
|Obstáculo mixto	|OM		| (weir)
|Cruce con vial		|CV		| (bridge)
*/
select * from sudoang.chmin_obstruction where "TIPO_INFR" = 'SV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 679 rows (total 2320 rows)
select * from sudoang.chmin_obstruction where "TIPO_INFR" = 'PE' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 3 rows
select * from sudoang.chmin_obstruction where "TIPO_INFR" = 'PP' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 106 rows (total 117 rows)
select * from sudoang.chmin_obstruction where "TIPO_INFR" = 'OM' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 2 row
select * from sudoang.chmin_obstruction where "TIPO_INFR" = 'CV' and dbeel_op_id is not null and "CIERTO" = 'SI'; -- 10 row

--select * from sudoang.chmin_obstruction where dbeel_op_id is not null; -- 2452 rows
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '219'
	from sudoang.chmin_obstruction WHERE dbeel_op_id = ob_op_id; -- 1480 rows (total 1504 rows)

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.chmin_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'SV' and "CIERTO" = 'SI'; -- 512 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '294'
	from sudoang.chmin_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'PE' and "CIERTO" = 'SI'; -- 3 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chmin_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'PP' and "CIERTO" = 'SI'; -- 100 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.chmin_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'OM' and "CIERTO" = 'SI'; -- 2 rows
		
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '296'
	from sudoang.chmin_obstruction WHERE dbeel_op_id = ob_op_id and "TIPO_INFR" = 'CV' and "CIERTO" = 'SI'; -- 10 rows


---------------------------------------------------------------
-- CORRECT THE FISHWAY INFORMATION FOR ALL TABLES FROM MITECO
---------------------------------------------------------------
select * from sudoang.dbeel_physical_obstruction where fishway_type = 'ES' or fishway_type = 'RP' or fishway_type = 'CL'; -- 34 rows
select * from sudoang.dbeel_physical_obstruction where po_presence_eel_pass = true; -- 34 rows

/* First, update sudoang.physical_obstruction when there are 'ES' (271 Pool type fishway TRUE), 'RP' (275 Rock ramp) and 'CL' (277 Lateral canal)
Then, for each table of miteco, update op_id with this information:
	'RZ' = 'Denil pass'	-- 273 FALSE  presence eel pass 
	'DE' = 'Unknown' 	-- 279 FALSE presence eel pass  
*/
begin;
with join_chcoc AS
(
	SELECT * FROM sudoang.chcoc_obstruction o join sudoang.chcoc_obstruction_tec t on o."autoUID" = t."autoUID" where dbeel_op_id is not null
	and o."CIERTO" = 'SI'
	and "H_TOTAL" + "H_SALTO" > 0
	AND "ESTADO" not IN ('PR','CO','AR','DM')  -- chseg: 171 rows; chmin: 450 rows; chguad: 54 rows; chebro: 351 rows; chcoc: 105 rows
),
pass as (
	select 
	(CASE WHEN "TIPO_PASO" = 'ES' THEN TRUE
	      WHEN "TIPO_PASO" = 'RP' THEN true
	      WHEN "TIPO_PASO" = 'CL' THEN true 
	      WHEN "TIPO_PASO" = 'RZ' THEN false
	      WHEN "TIPO_PASO" = 'DE' THEN false
	      else false
	      end) as po_presence_eel_pass,
	(CASE WHEN "TIPO_PASO" = 'ES' THEN '271'
	      WHEN "TIPO_PASO" = 'RP' THEN '275'
	      WHEN "TIPO_PASO" = 'CL' THEN '277'
	      WHEN "TIPO_PASO" = 'RZ' THEN '273'
	      WHEN "TIPO_PASO" = 'DE' THEN '279'
	      else null
	      end) AS fishway_type,
	dbeel_op_id
	from join_chcoc
        where "TIPO_PASO" = 'ES' or "TIPO_PASO" = 'RP' or "TIPO_PASO" = 'CL' or "TIPO_PASO" = 'RZ' or "TIPO_PASO" = 'DE'
	),
joining_pass as (
	select ob_id, p.ob_op_id, p.po_presence_eel_pass, p.fishway_type from pass join sudoang.dbeel_physical_obstruction p ON p.ob_op_id = dbeel_op_id
	)
--select count(*), ob_op_id from joining_pass group by ob_op_id; -- chseg: 11 rows; chmin: 4 rows; chguad: 2 rows; chebro: 64 rows; chcoc: 11 rows
UPDATE sudoang.dbeel_physical_obstruction as dpo
SET (po_presence_eel_pass, fishway_type) = (joining_pass.po_presence_eel_pass, joining_pass.fishway_type)
FROM joining_pass 
WHERE joining_pass.ob_id = dpo.ob_id
; -- chseg: 11 rows; chmin: 4 rows; chguad: 2 rows; chebro: 64 rows; chcoc: 11 rows
commit;


---------------------------------------------
-- Thirteenth data incorporated = ANDALUCIA
---------------------------------------------
/* Differents data sent by Carlos Fernandez:
	1. 100 presas Andalucia.xlsx.xlsx that are the same than:
	2. tabla_obstaculos_SUDOANG_E.2.1-15-04-19_ANDALUCIA.xlsx
		A. DAM_data sheet as "andalucia_obstruction_dams" 	-- 186 rows
TO DO		B. POWER_PLANT_data as "andalucia_obstruction_hpp"	-- 50 rows -> from excel, 22 rows are deleted because they are empty
		c. andalucia_obstruction_turbine created with the power plant sheet
*/

------ 2.A DAMS DATA IMPORT (andalucia_obstruction_dams table)
SELECT * FROM sudoang.andalucia_obstruction_dams limit 10;

---- Add establishment
-- select * from dbeel.establishment
-- 'UCO' is the University of Cordoba who compiles the data, but we don't know the source of the data
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('UCO'); -- TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Carlos Fernandez', et_id FROM dbeel.establishment WHERE et_establishment_name = 'UCO'
; --TODO: TO BE MODIFIED

---- Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'andalucia_obstruction_dams', 'geom');

---- Creation spatial index
CREATE INDEX 
  ON sudoang.andalucia_obstruction_dams
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','andalucia_obstruction_dams','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- Go to OBSTRUCTION_AGGREGATION script (line 176) to add the id (character to define the table origin and a key)
begin;
update sudoang.andalucia_obstruction_dams set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.andalucia_obstruction_dams a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= andalucia_obstruction_dams.id; -- 176 rows
commit;

CREATE INDEX 
  ON sudoang.andalucia_obstruction_dams
  USING gist
  (geom_reproj);
    
---- Link Andalucia dams TO dbeel
ALTER TABLE sudoang.andalucia_obstruction_dams ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.andalucia_obstruction_dams ADD COLUMN initial_duplicate boolean default FALSE;
-- update sudoang.andalucia_obstruction_dams set dbeel_op_id = NULL

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.andalucia_obstruction_dams AS sp1, sudoang.andalucia_obstruction_dams AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

---- DUPLICATES with data already in DBEEL
-- UPDATE sudoang.andalucia_obstruction_dams SET dbeel_op_id = NULL; -- to reset the column
-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
-- At the end fo the query (line 1052: "and not op_gis_layername = 'UCO'" is add to recordback the dbeel_op_id)
begin;
WITH duplicate_andalucia AS 
(
	SELECT DISTINCT geom_reproj, op_id, st_distance(the_geom, geom_reproj) as distance, op_gis_layername
	FROM sudoang.andalucia_obstruction_dams, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'AOD%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by distance -- 154 rows. To be tuned
) 
UPDATE sudoang.andalucia_obstruction_dams SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM duplicate_andalucia 
WHERE andalucia_obstruction_dams.geom_reproj IS NOT NULL and not op_gis_layername = 'UCO' AND andalucia_obstruction_dams.geom_reproj = duplicate_andalucia.geom_reproj
; -- 143 rows
commit;

---- Update height for these dams
/*
select * from sudoang.andalucia_obstruction_dams where dbeel_op_id = ''
select * from sudoang.dbeel_physical_obstruction where ob_op_id = ''
*/
begin;
UPDATE sudoang.dbeel_physical_obstruction SET po_obstruction_height = obs_height FROM sudoang.andalucia_obstruction_dams
WHERE dbeel_op_id = ob_op_id AND po_obstruction_height is null; -- 0 rows
commit;

---- NEW dams inserted into dbeel_obstruction_place
-- select * from sudoang.dbeel_obstruction_place limit 10;
begin;
WITH unique_obs AS
(
	SELECT DISTINCT geom_reproj FROM sudoang.andalucia_obstruction_dams WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL -- 32 rows
) 
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'UCO' AS op_gis_layername, 
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		NULL AS id_original,
		'SP' AS country
		FROM unique_obs; -- 32 rows
commit;

-- Bug fixed: "op_gis_layername" was entered with a wrong code (line 3059)
update sudoang.dbeel_obstruction_place set op_gis_layername = 'UCO' where op_id in (
	select op_id from sudoang.andalucia_obstruction_dams JOIN sudoang.dbeel_obstruction_place on geom_reproj = the_geom 
	WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL); -- 32 rows

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (andalucia_obstruction_dams)
-- UPDATE sudoang.andalucia_obstruction_dams SET dbeel_op_id = NULL; -- to reset the column
UPDATE sudoang.andalucia_obstruction_dams SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='UCO';	-- 32 rows
	
---- The id of the source table (andalucia_obstruction_dams) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'AOD_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.andalucia_obstruction_dams WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 32 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='UCO'; -- 0 rows
	
---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  obs_height AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM sudoang.andalucia_obstruction_dams JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id = op_id), 
	dbeel.data_provider 
	WHERE dp_name = 'Carlos Fernandez' --TODO: TO BE MODIFIED
	AND op_gis_layername='UCO'
	AND NOT initial_duplicate
; -- 32 rows
commit;

---- Presence of a eel pass:
SELECT distinct obs_presence_eel_pass FROM sudoang.andalucia_obstruction_dams where id is not null; -- f

-- Update the type of obstacles
select distinct obs_name from sudoang.andalucia_obstruction_dams; -- 'PRESA' (dam) or 'CENTRAL' (hpp)

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.andalucia_obstruction_dams WHERE dbeel_op_id = ob_op_id; -- 170 rows


------ 2.B POWER PLANT DATA IMPORT (andalucia_obstruction_hpp table)
select * from sudoang.andalucia_obstruction_hpp; -- 50 rows
select * from sudoang.andalucia_obstruction_dams; -- 186 rows

/* colnames dbeel_hpp
	|hpp_id				|uuid		|		
	|hpp_ob_id 			|uuid 		|	
	|hpp_name			|integer	|dam_name
	|hpp_main_grid_or_production 	|integer	|"main-grid or production"
	|hpp_presence_bypass 		|boolean	|
	|hpp_total_flow_bypass 		|numeric	|
	|hpp_orient_flow_no_id 		|integer	|
	|hpp_presence_of_bar_rack 	|boolean	|
        |hpp_bar_rack_space 		|numeric	|	
	|hpp_surface_bar_rack 		|numeric	|
	|hpp_inclination_bar_rack 	|numeric	|
	|hpp_presence_bypass_trashrack 	|boolean	|
	|hpp_nb_trashrack_bypass 	|integer	|
	|hpp_turb_max_flow 		|numeric	|dam_turb_max_flow
	|hpp_reserved_flow 		|numeric	|
	|hpp_flow_trashrack_bypass 	|numeric	|
	|hpp_max_power 			|numeric	|dam_max_power
	|hpp_nb_turbines 		|integer	|dam_nb_turbines
	|hpp_orientation_bar_rack 	|numeric	|
	|hpp_id_original 		|text		|dam_id
	|hpp_source 			|text		|	
*/
select jj.dam_id as did, jj.geom_reproj, h.*  from sudoang.andalucia_obstruction_hpp h join sudoang.andalucia_obstruction_dams jj on jj.dam_id = h.dam_id; -- 50 rows

-- Check duplicates
select * from sudoang.dbeel_hpp limit 10; -- hpp_ob_id (from dbeel_physical_obstruction)
select * from sudoang.andalucia_obstruction_hpp limit 10; -- dbeel_op_id (from dbeel_obstruction_place)

with andalucia_dams as (
	select * from sudoang.dbeel_obstruction_place d 
	join 
	sudoang.andalucia_obstruction_dams o on o.dbeel_op_id = d.op_id
	join
	sudoang.andalucia_obstruction_hpp h on o.dam_id = h.dam_id
	)
select * from sudoang.view_dbeel_hpp join andalucia_dams on andalucia_dams.op_id = sudoang.view_dbeel_hpp.op_id; -- 0 rows, no duplicates

-- Import hpp data
begin;
with joined_dam as (
select d.op_id, o.dbeel_op_id, po.ob_op_id, po.ob_id, h.* from sudoang.dbeel_obstruction_place d join sudoang.andalucia_obstruction_dams o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.andalucia_obstruction_hpp h on o.dam_id = h.dam_id),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 47 rows: 3 are missing because the dams associated don't have the geom_reproj!
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_name, hpp_main_grid_or_production, hpp_turb_max_flow, hpp_max_power, hpp_nb_turbines, hpp_id_original)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		initcap(dam_name) as hpp_name, 
		"main-grid or production" as hpp_main_grid_or_production, 
		dam_turb_max_flow as hpp_turb_max_flow, 
		dam_max_power as hpp_max_power, 
		dam_nb_turbines as hpp_nb_turbines, 
		id as hpp_id_original
	FROM closest_dam
; -- 47 rows
COMMIT;

---- Record back the link with dbeel: hpp_id of hpp (inserted into the dbeel) are inserted into the source table (andalucia_obstruction_hpp)
ALTER TABLE sudoang.andalucia_obstruction_hpp ADD COLUMN dbeel_hpp_id uuid;

UPDATE sudoang.andalucia_obstruction_hpp SET dbeel_hpp_id = hpp_id 
FROM sudoang.dbeel_hpp 
WHERE id = hpp_id_original AND initcap(dam_name) = hpp_name; -- 47 rows


------ 2.C TURBINE DATA IMPORT (andalucia_obstruction_turbine table)
/* colnames dbeel_hpp
	|turb_id 			|uuid		|
	|turb_hpp_id 			|uuid		|
	|turb_turbine_type_no_id 	|integer	|typt_id
	|turb_in_service 		|boolean	|turb_in_service
	|turb_max_power 		|numeric	|turb_max_power
	|turb_min_working_flow 		|numeric	|
	|turb_hpp_height 		|numeric	|turb_dam_height
	|turb_diameter 			|numeric	|
	|turb_rotation_speed 		|numeric	|turb_rotation_speed
	|turb_nb_blades 		|integer	|
	|turb_max_turbine_flow 		|numeric	|turb_max_turbine_flow
	|turb_description 		|text		|
*/
select * from sudoang.andalucia_obstruction_turbine; -- 94 rows
select * from sudoang.andalucia_obstruction_dams; -- 186 rows

begin;
with joined_hpp as (
			select h.id, h.dbeel_hpp_id, t.*  from sudoang.andalucia_obstruction_hpp h join sudoang.andalucia_obstruction_turbine t on h.id = t.hpp_id 
		   )
--select * from joined_hpp; -- 94 rows
INSERT INTO sudoang.dbeel_turbine(
	turb_id, turb_hpp_id, turb_turbine_type_no_id, turb_in_service, turb_max_power, turb_hpp_height, turb_rotation_speed, turb_max_turbine_flow)
	SELECT
		uuid_generate_v4() AS turb_id,
		dbeel_hpp_id AS turb_hpp_id,
		typt_id as turb_turbine_type_no_id, 
		turb_in_service as turb_in_service, 
		turb_max_power as turb_max_power, 
		turb_dam_height as turb_hpp_height, 
		turb_rotation_speed as turb_rotation_speed,
		turb_max_turbine_flow as turb_max_turbine_flow
		--id as turbine_id_original
	FROM joined_hpp
; -- 94 rows
COMMIT;

--------------------------------------------------
-- Fourteenth data incorporated = BASQUE COUNTRY
--------------------------------------------------
/* Differents data set sent by Fran (from URA). It's the same information:
	1. 2019_INVENTARIO_OBSTACULOS_Y_DEMOLIDOS__CAPV: standardized format with all types of obstacles (it is necessary to remove the demolished ones)
	2. BD_INVENTARIO OBSTACULOS CAPV_2018.xlsx: each sheet corresponds to a type of obstacle.
TO DO		A. POWER_PLANT_data as "4. APROVECHAMIENTOS"	-- Only 40 rows with the number of turbines
		* "1. OBSTACULOS" sheet corresponds to "2019_INVENTARIO_OBSTACULOS_Y_DEMOLIDOS__CAPV" (CODIGO could be used to join data)
*/

------ 1. DAMS DATA IMPORT (2019_INVENTARIO_OBSTACULOS_Y_DEMOLIDOS__CAPV table)
--alter table sudoang."2019_INVENTARIO_OBSTACULOS_Y_DEMOLIDOS__CAPV" rename to bc_obstruction_dams;
SELECT * FROM sudoang.bc_obstruction_dams limit 10;

---- Add establishment
-- select * from dbeel.establishment
-- 'URA' is the Basque Water Agency
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('URA'); -- TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Fran Silván Beraza', et_id FROM dbeel.establishment WHERE et_establishment_name = 'URA'; --TODO: TO BE MODIFIED

---- Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'bc_obstruction_dams', 'geom'); -- 3035: It has been changed (line 351 from OBSTRUCTION_AGGREGATION script)

---- Creation spatial index
CREATE INDEX 
  ON sudoang.bc_obstruction_dams
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','bc_obstruction_dams','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- Go to OBSTRUCTION_AGGREGATION script (line 198) to add the id (character to define the table origin and a key)
begin;
update sudoang.bc_obstruction_dams set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.bc_obstruction_dams a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= bc_obstruction_dams.id; -- 2069 rows
commit;

CREATE INDEX 
  ON sudoang.bc_obstruction_dams
  USING gist
  (geom_reproj);
  
---- Link Basque Country dams TO dbeel
ALTER TABLE sudoang.bc_obstruction_dams ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.bc_obstruction_dams ADD COLUMN initial_duplicate boolean default FALSE;
-- update sudoang.bc_obstruction_dams set dbeel_op_id = FALSE

---- Dam removal = update the height to zero
-- First, remove those without coordinates:
SELECT * FROM sudoang.bc_obstruction_dams WHERE utm_x = '0' or utm_y = '0'; -- 4 rows
delete from sudoang.bc_obstruction_dams where utm_x = '0' or utm_y = '0'; -- 4 rows

-- SELECT * FROM sudoang.bc_obstruction_dams WHERE "solucion_t" = 'DEMOLICION'; -- 80 rows
update sudoang.bc_obstruction_dams set coaltura = '0' where "solucion_t" = 'DEMOLICION'; -- 80 rows

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.bc_obstruction_dams AS sp1, sudoang.bc_obstruction_dams AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 4 rows
/* id1; id2; rank:
"BCD_798"; "BCD_948"; 1		-- SELECT * FROM sudoang.bc_obstruction_dams WHERE id = 'BCD_798' OR id = 'BCD_948'; 	-- codigo = A0827, A0977 -- SAME COORDINATES (same op_op_id) INITIAL DUPLICATE
"BCD_1869"; "BCD_1870"; 1	-- SELECT * FROM sudoang.bc_obstruction_dams WHERE id = 'BCD_1869' OR id = 'BCD_1870';  -- codigo = A8333, A8334 -- EXACTLY THE SAME
"BCD_2001"; "BCD_2010"; 1	-- SELECT * FROM sudoang.bc_obstruction_dams WHERE id = 'BCD_2001' OR id = 'BCD_2010';  -- codigo = A8551, A8590 -- SAME COORDINATES (same op_op_id)
"BCD_2009"; "BCD_2012"; 1	-- SELECT * FROM sudoang.bc_obstruction_dams WHERE id = 'BCD_2009' OR id = 'BCD_2012';  -- codigo = A8589, A8592 -- SAME COORDINATES (same op_op_id)

SELECT * FROM sudoang.bc_obstruction_dams WHERE id = 'BCD_1869' OR id = 'BCD_1870';
select * from sudoang.dbeel_obstruction_place where op_id = '32bb6fbe-b37c-43e7-a185-540e0c3ce0d1'; -- 1 row (id_original = 'BCD_1870')
select * from sudoang.dbeel_physical_obstruction where ob_op_id = '32bb6fbe-b37c-43e7-a185-540e0c3ce0d1'; -- 2 row with different ob_id

SELECT * FROM sudoang.bc_obstruction_dams WHERE id = 'BCD_2001' OR id = 'BCD_2010';  
select * from sudoang.dbeel_obstruction_place where op_id = 'b7afaaa9-37a5-48b7-91ba-c810780dce3c'; -- 1 row (id_original = 'BCD_2010')
select * from sudoang.dbeel_physical_obstruction where ob_op_id = 'b7afaaa9-37a5-48b7-91ba-c810780dce3c'; -- 2 row with different ob_id

SELECT * FROM sudoang.bc_obstruction_dams WHERE id = 'BCD_2009' OR id = 'BCD_2012';
select * from sudoang.dbeel_obstruction_place where op_id = '0cba50e6-cda5-4313-84d5-63ba65927de0'; -- 1 row (id_original = 'BCD_2012')
select * from sudoang.dbeel_physical_obstruction where ob_op_id = '0cba50e6-cda5-4313-84d5-63ba65927de0'; -- 2 row with different ob_id
*/

---- DUPLICATES with data already in DBEEL
/* Correction
begin;
UPDATE sudoang.bc_obstruction_dams SET dbeel_op_id = NULL where initial_duplicate = TRUE; -- 1383 rows
commit;
*/

-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
begin;
WITH duplicate_bc AS 
(
	SELECT geom_reproj, op_id, id, st_distance(the_geom, geom_reproj) as distance
	FROM sudoang.bc_obstruction_dams, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'BCD%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by id, distance -- 4370 rows. To be tuned
), 
uq_duplicates_bc as (
	select distinct on (id) * from duplicate_bc
)
UPDATE sudoang.bc_obstruction_dams SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM uq_duplicates_bc 
WHERE bc_obstruction_dams.id = uq_duplicates_bc.id
; -- 1383 rows
commit;

---- Update height for these dams
begin;
with multiple_join as (
	select * from sudoang.bc_obstruction_dams join sudoang.dbeel_physical_obstruction on dbeel_op_id = ob_op_id order by ob_op_id, coaltura
	),
lowest_height as (
	select distinct on (id) * from multiple_join
	)
-- select * from lowest_height; -- 1383 rows
UPDATE sudoang.dbeel_physical_obstruction SET po_obstruction_height = coaltura FROM lowest_height
	WHERE dbeel_physical_obstruction.ob_op_id = lowest_height.ob_op_id AND dbeel_physical_obstruction.po_obstruction_height is null
; -- 35 rows
commit;

/* Total rows = 2122. Duplicates in dbeel = 1383. News dams = 682
select * from sudoang.bc_obstruction_dams where geom_reproj is null; -- 53 rows
4 rows are missing, which are the internal duplicates */

---- NEW dams inserted into dbeel_obstruction_place
-- select * from sudoang.dbeel_obstruction_place where op_gis_layername = 'URA'; -- 682 rows (total: 21187)
-- select * from sudoang.dbeel_physical_obstruction limit 10; -- (total: 21166)

-- Reimport the data because the internal duplicates of bc_obstruction_dams were imported incorrectly in the dbeel 
-- Before to delete these data in dbeel_obstruction_place, we need to delete in dbeel_physical_obstruction using ob_op_id = op_id
/*
BEGIN;
DELETE FROM sudoang.dbeel_physical_obstruction
USING sudoang.dbeel_obstruction_place
WHERE dbeel_physical_obstruction.ob_op_id = dbeel_obstruction_place.op_id and op_gis_layername = 'URA'; -- 686 rows

DELETE FROM sudoang.dbeel_obstruction_place WHERE op_gis_layername = 'URA'; -- 682 rows

UPDATE sudoang.bc_obstruction_dams SET dbeel_op_id = NULL; -- 2122 rows
UPDATE sudoang.bc_obstruction_dams SET initial_duplicate = FALSE; -- 2122 rows
COMMIT;
*/

-- We selected the dam with the lowest height when internals duplicates
begin;
WITH ordered as
(
	SELECT geom_reproj, id FROM sudoang.bc_obstruction_dams WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL order by coaltura
),

unique_obs AS
(
	SELECT DISTINCT on (geom_reproj) * FROM ordered
)

INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'URA' AS op_gis_layername, 
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		id AS id_original,
		'SP' AS country
		FROM unique_obs; -- 682 rows
commit;

---- Record back the link with dbeel: 
---- For the new dams without duplicates, insert back the id from dbeel table (op_id inserted into the dbeel) into the source table (bc_obstruction_dams)
-- UPDATE sudoang.bc_obstruction_dams SET dbeel_op_id = NULL; -- to reset the column
begin;
UPDATE sudoang.bc_obstruction_dams SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place
WHERE id = id_original and initial_duplicate = false AND op_gis_layername='URA'; -- 682 rows
commit;

---- The id of the source table (bc_obstruction_dams) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'BCD_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.bc_obstruction_dams WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 1378 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='URA'; -- 682 rows

/*
select initial_duplicate from sudoang.bc_obstruction_dams;
update sudoang.bc_obstruction_dams set initial_duplicate = false where initial_duplicate is null; -- 739 rows
select * from sudoang.dbeel_obstruction_place where op_gis_layername='URA';
*/

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  coaltura AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM sudoang.bc_obstruction_dams JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id, id) = (op_id, id_original), 
	dbeel.data_provider 
	WHERE dp_name = 'Fran Silván Beraza' --TODO: TO BE MODIFIED
	AND op_gis_layername = 'URA'
	AND NOT initial_duplicate
; -- 682 rows
commit;

---- EEL PASSABILITY = poangui parameter
-- select * from sudoang.dbeel_physical_obstruction where po_no_obstruction_passability is not null; -- 0 rows
SELECT distinct * FROM sudoang.bc_obstruction_dams where poangui is not null; -- BUENO; MALO; REGULAR; -- 245 rows

-- Update the passability with poangui:
-- There might be duplicates when joining bc_tables with the original dbeel, several bc_dams corresponding to one dbeel_dam
-- In that case, we choose the lowest passability score (using the order by, group by queries)
BEGIN;
with multiple_joins as (
		SELECT ob_id, initial_duplicate, id,
		CASE 
			when poangui = 'BUENO' then 267
			when poangui = 'MALO' then 269
			when poangui = 'REGULAR' then 268
			else null
			end AS passability
		from sudoang.bc_obstruction_dams join sudoang.dbeel_obstruction_place on dbeel_op_id = op_id 
		join sudoang.dbeel_physical_obstruction on ob_op_id = op_id
		where poangui is not null
		order by ob_id, case
			when poangui = 'BUENO' then 1
			when poangui = 'MALO' then 3
			when poangui = 'REGULAR' then 2
			END
		),
closest_dams as (
		select distinct on (id) * from multiple_joins
		)
		
update sudoang.dbeel_physical_obstruction set po_no_obstruction_passability = passability from closest_dams
		where closest_dams.ob_id = dbeel_physical_obstruction.ob_id; -- 171 rows
commit;

/* Trial to understand the problem with duplicates
select distinct ob_id from sudoang.dbeel_obstruction_place join sudoang.dbeel_physical_obstruction on op_id = ob_op_id where op_gis_layername='URA' order by ob_id; -- 682 rows
select distinct on (op_id) * from sudoang.bc_obstruction_dams join sudoang.dbeel_obstruction_place on dbeel_op_id = op_id; -- 1378
select count(*), op_id from sudoang.bc_obstruction_dams join sudoang.dbeel_obstruction_place on dbeel_op_id = op_id group by op_id; -- 1378
select * from sudoang.bc_obstruction_dams where dbeel_op_id = '2368f34f-1644-4975-af33-f2cd6c31ecac';
*/

-- Update the type of obstacles
select distinct tipo from sudoang.bc_obstruction_dams;
/*
|tipo	|			|
|-------|-----------------------|
|*	|			|
|A	|Azud			|
|C	|Cruce			| (bridge)
|E	|Estación de aforo	| (seuil)
|P	|Presa			| (dam)
|X	|Otros			| (unkown)
*/
select * from sudoang.bc_obstruction_dams where tipo = 'A' and dbeel_op_id is not null; -- 1427 rows
select * from sudoang.bc_obstruction_dams where tipo = 'C' and dbeel_op_id is not null; -- 121 rows
select * from sudoang.bc_obstruction_dams where tipo = 'E' and dbeel_op_id is not null; -- 50 rows (total 117 rows)
select * from sudoang.bc_obstruction_dams where tipo = 'P' and dbeel_op_id is not null; -- 33 row
select * from sudoang.bc_obstruction_dams where (tipo = 'X' or tipo = '*') and dbeel_op_id is not null; -- 438 row

--select * from sudoang.bc_obstruction_dams where dbeel_op_id is not null; -- 2069 rows
begin;
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.bc_obstruction_dams WHERE dbeel_op_id = ob_op_id and tipo = 'A'; -- 1179 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '296'
	from sudoang.bc_obstruction_dams WHERE dbeel_op_id = ob_op_id and tipo = 'C'; -- 95 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '292'
	from sudoang.bc_obstruction_dams WHERE dbeel_op_id = ob_op_id and tipo = 'E'; -- 50 rows

update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.bc_obstruction_dams WHERE dbeel_op_id = ob_op_id and tipo = 'P'; -- 33 rows
commit;

---- UPDATE previous information of dbeel with data from URA
-- dbeel_obstruction_place: update the data provider and the name of obstacle (we don't change the id_original because otherwise we'll be lost)
BEGIN;
WITH joined as (	

 SELECT * FROM  sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.bc_obstruction_dams on dbeel_op_id=op_id
		where initial_duplicate and op_gis_layername = 'amber'
EXCEPT
SELECT * FROM   sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.bc_obstruction_dams on dbeel_op_id=op_id
		where initial_duplicate and op_gis_layername = 'amber'
		AND comment_update LIKE '%ministry%'		
		),
filter_unique AS (
SELECT op_id, id, count(*) over (partition by op_id) as ct FROM joined
),
final as (
	SELECT 
	coalesce(nombre, op_placename) as oname,
	coalesce(coaltura, po_obstruction_height) as oheight,  -- replace when not null
	joined.id,
	ob_id,
	joined.op_id,
	CASE WHEN po_obstruction_height::NUMERIC!=coaltura::NUMERIC THEN coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to URA data, changed data provider, height changed from '||po_obstruction_height||' to '||coaltura 
	ELSE coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to URA data, changed data provider'
	end as comment_update
	FROM filter_unique 
	join joined ON (joined.op_id, joined.id)=(filter_unique.op_id, filter_unique.id)
	WHERE (coalesce(coaltura,0)-coalesce(po_obstruction_height,0))>-2 -- we only replace the height when the difference is height is -2 (OK if new dam 3m old one 4 m as is it -1 m)
	AND ct = 1 -- count of duplicated values at 500 m in the initial join
	AND op_gis_layername='amber'
	)
-- select * from final;
UPDATE sudoang.dbeel_obstruction_place set (op_gis_layername, op_placename) = ('URA', oname) FROM final where dbeel_obstruction_place.op_id = final.op_id
; -- 593 rows
COMMIT;

-- dbeel_physical_obstruction: update the height and the update comment (about the data provider and the height)
BEGIN;
WITH joined as (	

 SELECT * FROM  sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.bc_obstruction_dams on dbeel_op_id=op_id
		where initial_duplicate 
		and ob_dp_id = 10
EXCEPT
SELECT * FROM   sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.bc_obstruction_dams on dbeel_op_id=op_id
		where initial_duplicate
		AND comment_update LIKE '%ministry%'
		and ob_dp_id = 10
		),
filter_unique AS (
SELECT op_id, id, count(*) over (partition by op_id) as ct FROM joined
),
final as (
	SELECT 
	coalesce(nombre, op_placename) as oname,
	coalesce(coaltura, po_obstruction_height) as oheight,  -- replace when not null
	joined.id,
	ob_id,
	joined.op_id,
	CASE WHEN po_obstruction_height::NUMERIC!=coaltura::NUMERIC THEN coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to URA data, changed data provider, height changed from '||po_obstruction_height||' to '||coaltura 
	ELSE coalesce(comment_update||', ', '')||'UPDATE FROM '||op_gis_layername|| 
	' to URA data, changed data provider'
	end as ocomment_update
	FROM filter_unique 
	join joined ON (joined.op_id, joined.id)=(filter_unique.op_id, filter_unique.id)
	WHERE (coalesce(coaltura,0)-coalesce(po_obstruction_height,0))>-2 -- we only replace the height when the difference is height is -2 (OK if new dam 3m old one 4 m as is it -1 m)
	AND ct = 1 -- count of duplicated values at 500 m in the initial join
	)
--select * from final; -- 593 rows
UPDATE sudoang.dbeel_physical_obstruction set (po_obstruction_height, date_last_update, author_last_update, comment_update) = (oheight, '2020-02-18', 'María and Cédric', ocomment_update) 
FROM final where dbeel_physical_obstruction.ob_id=final.ob_id; -- 593 rows
COMMIT;


------ 2.A. POWER_PLANT_data as "4. APROVECHAMIENTOS"	-- Only 40 rows with the number of turbines (bc_obstruction_hpp table)
-- 	aprvobser column: information about the use of the hpp, the type of turbine and the presence of bar rack
-- 	enuso column: if the hpp is in use
-- 	Different columns are created to add these information:
alter table sudoang.bc_obstruction_hpp add column hpp_presence_of_bar_rack boolean;
update sudoang.bc_obstruction_hpp set hpp_presence_of_bar_rack = TRUE where id in ('BCH_8', 'BCH_9', 'BCH_29', 'BCH_39', 'BCH_40'); -- 5 rows

alter table sudoang.bc_obstruction_hpp add column hpp_bar_rack_space numeric;
update sudoang.bc_obstruction_hpp set hpp_bar_rack_space = 3 where id = 'BCH_29'; -- 1 rows
update sudoang.bc_obstruction_hpp set hpp_bar_rack_space = 2 where id in ('BCH_39', 'BCH_40'); -- 2 rows

-- There are 31 hpp that are in use, but only 20 hpp with dams associated
select * from sudoang.bc_obstruction_hpp where enuso = 1 order by sta_id; -- 31 rows
select * from sudoang.bc_obstruction_hpp h join sudoang.bc_obstruction_dams d on h.codigo = d.codigo where enuso = 1 order by h.sta_id; -- 20 rows (11 rows without dam associated)

-- Check duplicates
with bc_dams as (
	select * from sudoang.dbeel_obstruction_place d 
	join 
	sudoang.bc_obstruction_dams o on o.dbeel_op_id = d.op_id
	join
	sudoang.bc_obstruction_hpp h on o.codigo = h.codigo
	)
select * from sudoang.view_dbeel_hpp join bc_dams on bc_dams.op_id = sudoang.view_dbeel_hpp.op_id; -- 0 rows, no duplicates

-- Import hpp data
begin;
with joined_dam as (
select d.op_id, o.dbeel_op_id, po.ob_op_id, po.ob_id, h.* from sudoang.dbeel_obstruction_place d join sudoang.bc_obstruction_dams o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.bc_obstruction_hpp h on o.codigo = h.codigo),

closest_dam as (
select distinct on (op_id) * from joined_dam where enuso = 1)
--select * from closest_dam; -- 19 rows
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_name, hpp_presence_of_bar_rack, hpp_bar_rack_space, hpp_nb_turbines, hpp_id_original)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		initcap(nombre) as hpp_name, 
		hpp_presence_of_bar_rack as hpp_presence_of_bar_rack, 
		hpp_bar_rack_space as hpp_bar_rack_space, 
		aprvdato as hpp_nb_turbines, 
		id as hpp_id_original
	FROM closest_dam
; -- 19 rows
COMMIT;

---- Record back the link with dbeel: hpp_id of hpp (inserted into the dbeel) are inserted into the source table (bc_obstruction_hpp)
ALTER TABLE sudoang.bc_obstruction_hpp ADD COLUMN dbeel_hpp_id uuid;

UPDATE sudoang.bc_obstruction_hpp SET dbeel_hpp_id = hpp_id 
FROM sudoang.dbeel_hpp 
WHERE id = hpp_id_original; -- 19 rows

-- Not imported: 11 rows without dam associated because they haven't code in the original table
select * from sudoang.bc_obstruction_hpp where enuso = 1 and id not in (
	select h.id from sudoang.bc_obstruction_dams d join sudoang.bc_obstruction_hpp h on h.codigo = d.codigo where enuso = 1 order by h.sta_id);

select * from sudoang.bc_obstruction_dams limit 10;
select * from sudoang.bc_obstruction_hpp where enuso = 1

------ 2.B. There are data on turbines
/* In the comments (aprvobser column) there is the following information:
id	type_turbine	turb_max_power (Kw)	turb_max_turbine_flow concession (l/s) -> m3/s
BCH_4	Francis (2)				825 -> 0.825
BCH_5			2345			907 -> 0.907
BCH_9	Kaplan (1)	547
BCH_11	Kaplan (1)	404			500 -> 0.5
BCH_19	Pelton (1)	586			295 -> 0.295
BCH_20			577
BCH_22			955
BCH_24			60
BCH_26	Voith 1910
BCH_32	Wilcox
BCH_34	Charmilles nb1026
*/

CREATE TABLE sudoang.bc_obstruction_turbine AS
  SELECT * FROM sudoang.bc_obstruction_hpp WHERE id in ('BCH_4', 'BCH_5', 'BCH_9', 'BCH_11', 'BCH_19', 'BCH_20', 'BCH_22', 'BCH_24'); -- 8rows

alter table sudoang.bc_obstruction_turbine add column turb_max_power numeric;
update sudoang.bc_obstruction_turbine	
	set turb_max_power = (case
				when id = 'BCH_5' then 2345
				when id = 'BCH_9' then 547
				when id = 'BCH_11' then 404
				when id = 'BCH_19' then 586
				when id = 'BCH_20' then 577
				when id = 'BCH_22' then 955
				when id = 'BCH_24' then 60
				else null
	end); -- 8rows

alter table sudoang.bc_obstruction_turbine add column turb_max_turbine_flow numeric;
update sudoang.bc_obstruction_turbine	
	set turb_max_turbine_flow = (case
				when id = 'BCH_4' then 0.825
				when id = 'BCH_5' then 0.907
				when id = 'BCH_11' then 0.5
				when id = 'BCH_19' then 0.295
				else null
	end); -- 8 rows

alter table sudoang.bc_obstruction_turbine add column turb_turbine_type_no_id numeric;
update sudoang.bc_obstruction_turbine	
	set turb_turbine_type_no_id = (case
				when id = 'BCH_4' then 245
				when id = 'BCH_9' then 247
				when id = 'BCH_11' then 247
				when id = 'BCH_19' then 248
				else null
	end); -- 8 rows

-- There are two turbines
INSERT INTO sudoang.bc_obstruction_turbine SELECT * FROM sudoang.bc_obstruction_turbine WHERE id = 'BCH_4'; -- 1 row

-- Import turbine data
begin;
with imported_hpp as (
select * from sudoang.bc_obstruction_turbine where codigo is not null) -- 7 rows
INSERT INTO sudoang.dbeel_turbine(
	turb_id, turb_hpp_id, turb_turbine_type_no_id, turb_max_power, turb_max_turbine_flow)
	SELECT
		uuid_generate_v4() AS turb_id,
		dbeel_hpp_id AS turb_hpp_id,
		turb_turbine_type_no_id as turb_turbine_type_no_id,
		turb_max_power as turb_max_power,
		turb_max_turbine_flow as turb_max_turbine_flow
	FROM imported_hpp
; -- 7 rows
COMMIT;

--------------------------------------------------
-- Fifteenth data incorporated = PORTUGAL
--------------------------------------------------
/* Two datasets sent by Isabel (from FCUL):
	1. Obstaclesturbines_datacollectionFCUL_Portugal.xlsx: 70 large dams without length (only the coordinates). NOT IMPORTED (in "GT"_obstacles.R" there is the code to import the data, see lines 111)
	2. obstaculos_portugal_datacollectionFCULMARE_04_2019.xlsx: dam and hpp data are in the same sheet that we separate in two datasets ("GT"_obstacles.R", line 307)
		A. DAMS data = fcul_obstruction_dams table
TO DO		B. HPP data = fcul_obstruction_hpp table with the id of dams (dams_id)
*/

------ 2.A. DAMS DATA IMPORT
SELECT * FROM sudoang.fcul_obstruction_dams limit 100;
--obs_name
--obs_presence_eel_pass
--id

---- Add establishment
-- select * from dbeel.establishment
-- 'APA' is the Agência Portuguesa do Ambiente, but Isabel Dominigos comes from 'FCUL/MARE'

ALTER SEQUENCE dbeel.establishment_et_id_seq restart with 20;
ALTER SEQUENCE dbeel.data_provider_dp_id_seq RESTART WITH 18;
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('FCUL/MARE'); 
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Isabel Domingos', et_id FROM dbeel.establishment WHERE et_establishment_name = 'FCUL/MARE'; 

---- Checking the srid of the geometry:
SELECT Find_SRID('sudoang', 'fcul_obstruction_dams', 'geom'); -- 3035: It has been changed (line 359 from OBSTRUCTION_AGGREGATION script)

---- Creation spatial index
CREATE INDEX 
  ON sudoang.fcul_obstruction_dams
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','fcul_obstruction_dams','geom_reproj',3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

-- Go to GT"_obstacles.R script (lines 325-326) to add the id (character to define the table origin and a key)
begin;
update sudoang.fcul_obstruction_dams set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.fcul_obstruction_dams a join
portugal.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= fcul_obstruction_dams.id; -- 268 rows (10 without geom_reproj)
commit;

CREATE INDEX 
  ON sudoang.fcul_obstruction_dams
  USING gist
  (geom_reproj);
  
---- Link Portuguese dams TO dbeel
ALTER TABLE sudoang.fcul_obstruction_dams ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.fcul_obstruction_dams ADD COLUMN initial_duplicate boolean default FALSE;
-- update sudoang.fcul_obstruction_dams set dbeel_op_id = FALSE

---- There are 36 dams without the height of dams
SELECT * FROM sudoang.fcul_obstruction_dams WHERE obs_height is null; -- 36 rows

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.fcul_obstruction_dams AS sp1, sudoang.fcul_obstruction_dams AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

---- DUPLICATES with data already in DBEEL
/* Correction
begin;
UPDATE sudoang.fcul_obstruction_dams SET dbeel_op_id = NULL where initial_duplicate = TRUE; -- rows
commit;
*/

-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
begin;
WITH duplicate_fcul AS 
(
	SELECT geom_reproj, op_id, id, st_distance(the_geom, geom_reproj) as distance
	FROM sudoang.fcul_obstruction_dams, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'POD%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by id, distance -- 185 rows. To be tuned
), 
uq_duplicates_fcul as (
	select distinct on (id) * from duplicate_fcul
)
UPDATE sudoang.fcul_obstruction_dams SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM uq_duplicates_fcul 
WHERE fcul_obstruction_dams.id = uq_duplicates_fcul.id
; -- 182 rows
commit;

---- Update height for these dams
begin;
with multiple_join as (
	select * from sudoang.fcul_obstruction_dams join sudoang.dbeel_physical_obstruction on dbeel_op_id = ob_op_id order by ob_op_id, obs_height
	),
lowest_height as (
	select distinct on (id) * from multiple_join
	)
--select * from lowest_height; -- 182 rows
UPDATE sudoang.dbeel_physical_obstruction SET po_obstruction_height = obs_height FROM lowest_height
	WHERE dbeel_physical_obstruction.ob_op_id = lowest_height.ob_op_id AND dbeel_physical_obstruction.po_obstruction_height is null
; -- 42 rows
commit;

---- UPDATE HEIGHT NAMES PRESENCE OF EEL PASS IN A SECOND TIME AFTER DISCUSSION WITH ISABEL AND TERESA
SELECT * 
       FROM 	
	        sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.fcul_obstruction_dams on dbeel_op_id=ob_op_id
		where initial_duplicate limit 10;

---- WE UPDATE THE OBSTRUCTION PLACE WITH THE NAME OF FCUL TO REPLACE SOURCE FROM AMBER TO MODFIED DATA SOURCE BY FCUL
BEGIN;		
With updatetable as(
SELECT 
       obs_name,
       CASE WHEN obs_presence_eel_pass= 'FALSO' then FALSE
            WHEN obs_presence_eel_pass='VERDADERO' THEN TRUE
            WHEN obs_presence_eel_pass IS NULL then po_presence_eel_pass
            END as po_presence_eel_pass,
       coalesce(obs_height,po_obstruction_height),  -- replace when not null
       id,
       ob_id,
       op_id,
       CASE WHEN po_obstruction_height!=obs_height THEN 'UPDATE FROM fcul data, height changed from '||po_obstruction_height||' to '||obs_height 
       ELSE NULL end as comment_update
       FROM 	
	        sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.fcul_obstruction_dams on dbeel_op_id=ob_op_id
		where initial_duplicate)
-- We let op_gislocation with the orginal id from amber
UPDATE sudoang.dbeel_obstruction_place set (op_gis_layername,id_original,op_placename) = ('FCUL/MARE',id, obs_name) FROM updatetable where dbeel_obstruction_place.op_id=updatetable.op_id; --180
COMMIT;

BEGIN;		
With updatetable as(
SELECT 
       obs_name,
       CASE WHEN obs_presence_eel_pass= 'FALSO' then FALSE
            WHEN obs_presence_eel_pass='VERDADERO' THEN TRUE
            WHEN obs_presence_eel_pass IS NULL then po_presence_eel_pass
            END as po_presence_eel_pass,
       coalesce(obs_height,po_obstruction_height) as po_obstruction_height,  -- replace when not null
       id,
       ob_id,
       op_id,
       CASE WHEN po_obstruction_height!=obs_height THEN 'UPDATE FROM fcul data, height changed from '||po_obstruction_height||' to '||obs_height 
       ELSE NULL end as comment_update
       FROM 	
	        sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.fcul_obstruction_dams on dbeel_op_id=ob_op_id
		where initial_duplicate)
UPDATE sudoang.dbeel_physical_obstruction set (po_presence_eel_pass, po_obstruction_height, ob_dp_id, comment_update, date_last_update, author_last_update) =
(updatetable.po_presence_eel_pass, updatetable.po_obstruction_height, 19, updatetable.comment_update, '2020-01-30', 'Cédric and Maria') 
FROM updatetable where dbeel_physical_obstruction.ob_id=updatetable.ob_id; -- 180
COMMIT;

/* Total rows = 277. Duplicates in dbeel = 182. News dams = 85
select * from sudoang.fcul_obstruction_dams where geom_reproj is null; -- 10 rows
*/

---- NEW dams inserted into dbeel_obstruction_place
-- select * from sudoang.dbeel_obstruction_place where op_gis_layername = 'FCUL/MARE'; -- rows (total: )
-- select * from sudoang.dbeel_physical_obstruction limit 10; -- (total: 21166)

-- We selected the dam with the lowest height when internals duplicates
begin;
WITH ordered as
(
	SELECT geom_reproj, id FROM sudoang.fcul_obstruction_dams WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL order by obs_height -- 85 rows
),

unique_obs AS
(
	SELECT DISTINCT on (geom_reproj) * FROM ordered
)

INSERT INTO sudoang.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'FCUL/MARE' AS op_gis_layername, 
		NULL AS op_gislocation, 
		NULL AS op_placename,
		11 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		id AS id_original,
		'PT' AS country
		FROM unique_obs; -- 85 rows
commit;

---- Record back the link with dbeel: 
---- For the new dams without duplicates, insert back the id from dbeel table (op_id inserted into the dbeel) into the source table (fcul_obstruction_dams)
-- UPDATE sudoang.fcul_obstruction_dams SET dbeel_op_id = NULL; -- to reset the column
begin;
UPDATE sudoang.fcul_obstruction_dams SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place
WHERE id = id_original and initial_duplicate = false AND op_gis_layername='FCUL/MARE'; -- 85 rows
commit;

---- The id of the source table (fcul_obstruction_dams) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'POD_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.fcul_obstruction_dams WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id) -- 265 rows
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='FCUL/MARE'; -- 85 rows

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
INSERT INTO sudoang.dbeel_physical_obstruction
	SELECT
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  219 as ot_no_obstruction_type, -- physical
	  1 as ot_obstruction_number,
	  NULL AS ot_no_mortality_type,
	  NULL AS ot_no_mortality,
	  NULL as po_no_obstruction_passability,
	  obs_height AS po_obstruction_height,
	  NULL AS po_turbine_number
	FROM sudoang.fcul_obstruction_dams JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id, id) = (op_id, id_original), 
	dbeel.data_provider 
	WHERE dp_name = 'Isabel Domingos' --TODO: TO BE MODIFIED
	AND op_gis_layername = 'FCUL/MARE'
	AND NOT initial_duplicate
; -- 85 rows
commit;

/* Checking that the new dams are in the dbeel:
with joining as (
	select * from sudoang.dbeel_physical_obstruction left join sudoang.dbeel_obstruction_place on ob_op_id = op_id
	)
select * from joining where op_gis_layername = 'FCUL/MARE' -- 85
*/

-- Presence of eel pass: the type of pass is not registered
select obs_presence_eel_pass, count(obs_presence_eel_pass) from sudoang.fcul_obstruction_dams group by obs_presence_eel_pass; -- TRUE and VERDADERO = 11 rows

begin;
with pass as (
	select 
	(CASE WHEN obs_presence_eel_pass = 'TRUE' THEN TRUE
	      WHEN obs_presence_eel_pass = 'VERDADERO' THEN true
	      WHEN obs_presence_eel_pass = 'FALSO' THEN FALSE 
	      else false
	      end) as po_presence_eel_pass,
	dbeel_op_id
	from sudoang.fcul_obstruction_dams
        where obs_presence_eel_pass = 'TRUE' or obs_presence_eel_pass = 'VERDADERO' or obs_presence_eel_pass = 'FALSO' -- 135 rows
	),
joining_pass as (
	select ob_id, p.ob_op_id, p.po_presence_eel_pass from pass join sudoang.dbeel_physical_obstruction p ON p.ob_op_id = dbeel_op_id
	)
--select count(*), ob_op_id from joining_pass group by ob_op_id; -- 131 rows
UPDATE sudoang.dbeel_physical_obstruction as dpo
SET po_presence_eel_pass = joining_pass.po_presence_eel_pass
FROM joining_pass 
WHERE joining_pass.ob_id = dpo.ob_id
; -- 131 rows
commit;

-- Update the type of obstacles: all data are dams
update sudoang.dbeel_physical_obstruction SET ot_no_obstruction_type = '291'
	from sudoang.fcul_obstruction_dams WHERE dbeel_op_id = ob_op_id; -- 265 rows

-- Change data provider
update dbeel.establishment set et_establishment_name = 'FCUL (APA, EDP, MARE)' where et_id = 21; -- 1 row


------ 2.B. HPP DATA IMPORT
select * from sudoang.fcul_obstruction_hpp;
/* colnames dbeel_hpp
	|hpp_id				|uuid		|		
	|hpp_ob_id 			|uuid 		|	
	|hpp_name			|integer	|obs_name
	|hpp_main_grid_or_production 	|integer	|main_grid_production
	|hpp_presence_bypass 		|boolean	|dam_presence_bypass
	|hpp_total_flow_bypass 		|numeric	|dam_total_flow_bypass
	|hpp_orient_flow_no_id 		|integer	|dam_orient_flow
	|hpp_presence_of_bar_rack 	|boolean	|dam_presence_of_bar_rack
        |hpp_bar_rack_space 		|numeric	|turb_rack_bar_space	
	|hpp_surface_bar_rack 		|numeric	|
	|hpp_inclination_bar_rack 	|numeric	|
	|hpp_presence_bypass_trashrack 	|boolean	|
	|hpp_nb_trashrack_bypass 	|integer	|
	|hpp_turb_max_flow 		|numeric	|dam_turb_max_flow
	|hpp_reserved_flow 		|numeric	|dam_reserved_flow
	|hpp_flow_trashrack_bypass 	|numeric	|
	|hpp_max_power 			|numeric	|dam_max_power
	|hpp_nb_turbines 		|integer	|dam_nb_turbines
	|hpp_orientation_bar_rack 	|numeric	|
	|hpp_id_original 		|text		|dams_id
	|hpp_source 			|text		|	

*/

---- Change the format of these columns:
--	dam_presence_bypass text -> boolean
alter table sudoang.fcul_obstruction_hpp
alter column dam_presence_bypass
set data type boolean
using case
    when dam_presence_bypass = 'VERDADERO' then true
    when dam_presence_bypass = 'FALSO' then false
    else null
end;

--	dam_orient_flow integer -> no_id
begin;
update sudoang.fcul_obstruction_hpp 	
	set dam_orient_flow = (case
				when dam_orient_flow = 1 then 238 -- "[70-90°]"
				when dam_orient_flow = 2 then 239 -- "[50-70°["
				when dam_orient_flow = 3 then 240 -- "[30-50°["
				when dam_orient_flow = 4 then 241 -- "<30°"
				else null
	end);
commit;

--	dam_presence_of_bar_rack text -> boolean
alter table sudoang.fcul_obstruction_hpp
alter column dam_presence_of_bar_rack
set data type boolean
using case
    when dam_presence_of_bar_rack = 'VERDADERO' then true
    when dam_presence_of_bar_rack = 'FALSO' then false
    when dam_presence_of_bar_rack = 'no' then false
    else null
end;

--	dam_max_power text -> numeric
UPDATE sudoang.fcul_obstruction_hpp SET dam_max_power = replace(dam_max_power, '-', ''); -- 277 rows

begin;
alter table sudoang.fcul_obstruction_hpp
alter column dam_max_power
set data type NUMERIC
using case
	when dam_max_power = '' then null
	else dam_max_power::NUMERIC
end;
commit;

-- Delete empty rows
begin;
delete from sudoang.fcul_obstruction_hpp where main_grid_production is null and dam_presence_bypass is null and dam_total_flow_bypass is null and dam_orient_flow is null and dam_presence_of_bar_rack is null 
					and turb_rack_bar_space is null and dam_turb_max_flow is null and dam_reserved_flow is null and dam_max_power is null and dam_nb_turbines is null; --52 rows
commit;

-- Check duplicates
select * from sudoang.dbeel_hpp limit 10; -- hpp_ob_id (from dbeel_physical_obstruction)
select * from sudoang.fcul_obstruction_dams limit 10; -- dbeel_op_id (from dbeel_obstruction_place)

with fcul_dams as (
	select * from sudoang.dbeel_obstruction_place d 
	join 
	sudoang.fcul_obstruction_dams o on o.dbeel_op_id = d.op_id
	join
	sudoang.fcul_obstruction_hpp h on o.id = h.dams_id
	)
select * from sudoang.view_dbeel_hpp join fcul_dams on fcul_dams.op_id = sudoang.view_dbeel_hpp.op_id; -- 0 rows, no duplicates


-- Import hpp data
begin;
with joined_dam as (
select d.op_id, o.dbeel_op_id, po.ob_op_id, po.ob_id, h.* from sudoang.dbeel_obstruction_place d join sudoang.fcul_obstruction_dams o on o.dbeel_op_id = d.op_id 
	join 
	sudoang.dbeel_physical_obstruction po on po.ob_op_id=d.op_id
	JOIN
	sudoang.fcul_obstruction_hpp h on o.id = h.dams_id),

closest_dam as (
select distinct on (op_id) * from joined_dam)
--select * from closest_dam; -- 218 rows: 7 are missing
INSERT INTO sudoang.dbeel_hpp(
	hpp_id, hpp_ob_id, hpp_name, hpp_main_grid_or_production, hpp_presence_bypass, hpp_total_flow_bypass, hpp_orient_flow_no_id, hpp_presence_of_bar_rack, hpp_bar_rack_space, hpp_turb_max_flow, hpp_reserved_flow, hpp_max_power,
	hpp_nb_turbines, hpp_id_original)
	SELECT
		uuid_generate_v4() as hpp_id,
		ob_id AS hpp_ob_id,
		obs_name as hpp_name, 
		main_grid_production as hpp_main_grid_or_production, 
		dam_presence_bypass as hpp_presence_bypass, 
		dam_total_flow_bypass as hpp_total_flow_bypass, 
		dam_orient_flow as hpp_orient_flow_no_id, 
		dam_presence_of_bar_rack as hpp_presence_of_bar_rack, 
		turb_rack_bar_space as hpp_bar_rack_space, 
		dam_turb_max_flow as hpp_turb_max_flow, 
		dam_reserved_flow as hpp_reserved_flow, 
		dam_max_power as hpp_max_power,
		dam_nb_turbines as hpp_nb_turbines, 
		dams_id as hpp_id_original
	FROM closest_dam
; -- 218 rows
COMMIT;

---- Record back the link with dbeel: hpp_id of hpp (inserted into the dbeel) are inserted into the source table (andalucia_obstruction_hpp)
ALTER TABLE sudoang.fcul_obstruction_hpp ADD COLUMN dbeel_hpp_id uuid;

UPDATE sudoang.fcul_obstruction_hpp SET dbeel_hpp_id = hpp_id 
FROM sudoang.dbeel_hpp 
WHERE dams_id = hpp_id_original; -- 218 rows

------ 2.C TURBINE DATA IMPORT (andalucia_obstruction_turbine table)
/* colnames dbeel_hpp
	|turb_id 			|uuid		|
	|turb_hpp_id 			|uuid		|
	|turb_turbine_type_no_id 	|integer	|typt_id
	|turb_in_service 		|boolean	|turb_in_service
	|turb_max_power 		|numeric	|turb_max_power
	|turb_min_working_flow 		|numeric	|turb_min_working_flow
	|turb_hpp_height 		|numeric	|turb_dam_height
	|turb_diameter 			|numeric	|turb_diameter
	|turb_rotation_speed 		|numeric	|turb_rotation_speed
	|turb_nb_blades 		|integer	|turb_nb_blades
	|turb_max_turbine_flow 		|numeric	|turb_max_turbine_flow
	|turb_description 		|text		|turb_description
*/
select * from sudoang.fcul_obstruction_turbine;

-- Change the data type of these columns:
--	typt_id -> no_id
update sudoang.fcul_obstruction_turbine 	
	set typt_id = (case
				when typt_id = 1 then 242 -- "Horizontal axis Kaplan (bulb)"
				when typt_id = 4 then 245 -- "Francis unspecified"
				when typt_id = 6 then 247 -- "Kaplan not specified"
				when typt_id = 7 then 248 -- "Pelton"
				when typt_id = 11 then 252 -- "Unknown"
				when typt_id = 12 then 253 -- "Vertical axis Kaplan"
				else null
	end); -- 322 rows

--	turb_in_service text -> boolean
select distinct turb_in_service from sudoang.fcul_obstruction_turbine order by turb_in_service; -- NULL, VERDADERO
alter table sudoang.fcul_obstruction_turbine
alter column turb_in_service
set data type boolean
using case
    when turb_in_service = 'VERDADERO' then true
    else null
end;

-- Delete empty rows
begin;
delete from sudoang.fcul_obstruction_turbine where typt_id is null and turb_in_service is null and turb_max_power is null and turb_min_working_flow is null and turb_dam_height is null 
					and turb_diameter is null and turb_rotation_speed is null and turb_nb_blades is null and turb_max_turbine_flow is null; -- 205 rows
commit;

select * from sudoang.fcul_obstruction_turbine; -- 117 rows
select * from sudoang.fcul_obstruction_hpp; -- 225 rows


-- Import turbine data
begin;
with joined_hpp as (
			select h.id, h.dbeel_hpp_id, t.*  from sudoang.fcul_obstruction_hpp h join sudoang.fcul_obstruction_turbine t on h.id = t.hpp_id 
		   )
--select * from joined_hpp; -- 116 rows
INSERT INTO sudoang.dbeel_turbine(
	turb_id, turb_hpp_id, turb_turbine_type_no_id, turb_in_service, turb_max_power, turb_min_working_flow, turb_hpp_height, turb_diameter, turb_rotation_speed, turb_nb_blades, turb_max_turbine_flow, turb_description)
	SELECT
		uuid_generate_v4() AS turb_id,
		dbeel_hpp_id AS turb_hpp_id,
		typt_id as turb_turbine_type_no_id,
		turb_in_service as turb_in_service,
		turb_max_power as turb_max_power,
		turb_min_working_flow as turb_min_working_flow,
		turb_dam_height as turb_hpp_height,
		turb_diameter as turb_diameter,
		turb_rotation_speed as turb_rotation_speed,
		turb_nb_blades as turb_nb_blades,
		turb_max_turbine_flow as turb_max_turbine_flow,
		turb_description as turb_description
		--id as turbine_id_original
	FROM joined_hpp
; -- 116 rows
COMMIT;

/* NOT TODO
 bypass_width double precision
 bypass_position text
 */

/* 
30/04/2019 we have found some duplicates, understood why, see portugal script above to see how to fix the problem
*/
Begin;
delete from sudoang.dbeel_physical_obstruction where ob_id='ee8927f7-af34-4555-acc2-e0d8f9234c37';
delete from sudoang.dbeel_physical_obstruction where ob_id='591e6218-e744-49bd-8a69-2a90e43322b2';
delete from sudoang.dbeel_physical_obstruction where ob_id='f2e5be16-9e97-4d20-ab13-fba8f5d783b8';
delete from sudoang.dbeel_physical_obstruction where ob_id='9d78a117-2658-4646-803e-a65dedce50d4';
delete from sudoang.dbeel_physical_obstruction where ob_id='5bcbb723-e553-425d-86d9-81c4f636f39c';
delete from sudoang.dbeel_physical_obstruction where ob_id='93ebb0fb-676c-46fc-8906-3b425f9e400f';
delete from sudoang.dbeel_physical_obstruction where ob_id='e197d805-eabf-4ff8-b6af-44d698ed11ed';
delete from sudoang.dbeel_physical_obstruction where ob_id='f56b6b96-47aa-4c5a-b078-bcd1a773228f';
delete from sudoang.dbeel_physical_obstruction where ob_id='e08b4bbe-cdbf-4363-a37a-d2daed9eaac9';
delete from sudoang.dbeel_physical_obstruction where ob_id='1e9ae7fe-3280-4bcb-bca4-2b8341b79c18';
delete from sudoang.dbeel_physical_obstruction where ob_id='47e05706-c186-48f3-914c-366e880d30d0';
delete from sudoang.dbeel_physical_obstruction where ob_id='2ab58ae1-3e73-44e1-a83e-b41ce05b0383';
delete from sudoang.dbeel_physical_obstruction where ob_id='987c3439-ef26-4fe1-907e-c81cef0783e2';
delete from sudoang.dbeel_physical_obstruction where ob_id='a961f79e-771f-4275-8e82-baf2b88559eb';
delete from sudoang.dbeel_physical_obstruction where ob_id='d0a9f57d-8259-4810-92c4-b00c45157bd7';
delete from sudoang.dbeel_physical_obstruction where ob_id='18bd2784-cf83-4c54-9d58-3e1d794519fb';
delete from sudoang.dbeel_physical_obstruction where ob_id='46187e7d-becc-4550-819c-ebab1759a2e1';
delete from sudoang.dbeel_physical_obstruction where ob_id='e3525676-e1ea-4bd9-8736-784f5fff25dc';
delete from sudoang.dbeel_physical_obstruction where ob_id='957a5e2d-3e1c-43cb-8310-96925f566cfd';
delete from sudoang.dbeel_physical_obstruction where ob_id='f698365b-22c2-4eef-b7c3-427eef2eedbb';
delete from sudoang.dbeel_physical_obstruction where ob_id='b70d0499-825b-4fd7-9a47-3df0380941df';
delete from sudoang.dbeel_physical_obstruction where ob_id='5303b647-d893-4be8-8f63-8126d304e0d8';
delete from sudoang.dbeel_physical_obstruction where ob_id='1497a247-bef7-4e94-8a19-fada27da89dc';
COMMIT;


-- select distinct fishway_type from sudoang.dbeel_physical_obstruction
/* Fishway_type
274
ES
CL
275
276
271
273
279
NA
280
270

RP
DE
278
272
*/
BEGIN;
UPDATE sudoang.dbeel_physical_obstruction SET fishway_type=NULL where fishway_type='NA'; --443
UPDATE sudoang.dbeel_physical_obstruction SET fishway_type='271' where fishway_type='ES'; --pool type 28
UPDATE sudoang.dbeel_physical_obstruction SET fishway_type='275' where fishway_type='RP'; --rock ramp 3
UPDATE sudoang.dbeel_physical_obstruction SET fishway_type='277' where fishway_type='CL'; -- lateral canal 3
UPDATE sudoang.dbeel_physical_obstruction SET fishway_type='273' where fishway_type='RZ'; -- DENIL 0
UPDATE sudoang.dbeel_physical_obstruction SET fishway_type='279' where fishway_type='DE'; --'Unknown'  49
UPDATE sudoang.dbeel_physical_obstruction SET fishway_type=NULL where fishway_type='';--439
UPDATE sudoang.dbeel_physical_obstruction SET fishway_type=NULL where fishway_type=' '; --13
COMMIT;

---- Caster le type de physical_obstruction fishway_type en integer
-- SELECT fishway_type from dbeel.physical_obstruction; not inherited
DROP MATERIALIZED VIEW IF EXISTS sudoang.view_dbeel_hpp;
DROP MATERIALIZED VIEW IF EXISTS sudoang.view_obstruction CASCADE;
BEGiN;
ALTER TABLE sudoang.dbeel_physical_obstruction ALTER COLUMN fishway_type  type integer USING fishway_type::integer;
COMMIT;

---- Mettre une contrainte de clé étrangère sur la table
ALTER TABLE sudoang.dbeel_physical_obstruction add constraint c_fk_fishway_type FOREIGN KEY (fishway_type) REFERENCES dbeel_nomenclature.fishway_type(no_id) ON UPDATE CASCADE ON
DELETE RESTRICT;

 ALTER TABLE sudoang.dbeel_physical_obstruction ADD CONSTRAINT c_fk_mitigation_measure_no_id FOREIGN KEY (mitigation_measure_no_id)
      REFERENCES dbeel_nomenclature.downstream_mitigation_measure (no_id) MATCH SIMPLE ON UPDATE CASCADE ON
	DELETE RESTRICT;


--------------------------------------------------
-- DATA CORRECTION
--------------------------------------------------

-- PENSTOCK PIPE 
update sudoang.dbeel_physical_obstruction set ot_no_obstruction_type = 300 where 
	ob_op_id in ('201aeb02-ce62-44a0-9d70-6226a96e1193','7fd1175d-633c-43b9-875e-d502c899f587','3fa241ce-6f23-43fb-8b1a-6be6e5aafdb4',
	'18fa1efc-4e1f-409a-91c7-73b363fd120d','cf81fe1a-16d7-4914-849a-3802e51a30ec','98ecc950-930a-4f12-8448-ec4ff9d9cbf9','24212856-af6d-4527-8197-933bc982c4c6',
	'7cd3dd53-f0bf-4995-9be6-beb25c0696b6','c4bc3cc2-b94b-4fc7-8ea5-cd8b808f55c8','3e0edf36-b3a3-4720-8e1c-095b9e6b6283','5d3667d8-8f38-4c03-a3d3-ed9735383ee2',
	'44743bf9-7098-48f4-890d-136044c5ceba','97c37195-a41a-4da7-ab4e-15d61238a318','52e54dc1-465f-494f-93d3-ad3e7f3837aa','8bbc4610-d8da-4160-ace6-fbac6e3ca2c0',
	'81cc0962-19e8-4dbc-be10-6068f7df6c96','e3c2c7a0-36bd-42fa-be60-bd2e792eed69','3dd6b5bd-bb57-46d4-b004-eaa059a2c04a','29a6e540-85d4-4f25-8806-a8632c56b7e9',
	'e4367ce4-ff80-4063-9673-d64fc74429bf','5a9e3492-eacd-4759-87fe-0cf59cb06e54','d696d253-4647-4d49-b730-8f0ab9bb852e','66bef3e3-65ee-46b4-96ab-788bb40337c1',
	'ebf3290f-13ee-443e-a985-22ae9fbf46bb','4b136fab-ab1a-488a-b0da-65bb380cb2bf','53e54958-9c59-4a4e-83a9-694d06827def','028c14a4-f273-44f8-8cc8-ec4eb0c2cfc6',
	'b44ac6f7-2fa6-45b4-b134-45d452617d0f','a5a2ac9e-f9df-4215-8df4-bf3f29041c77'
	); -- 29 rows

-- HEIGHT = 0
update sudoang.dbeel_physical_obstruction set po_obstruction_height = 0 where
	ob_op_id in ('17df2639-af36-4df5-85e5-87efcd3afce2','3ec6f823-93a5-48e8-af1c-6bdb91c4440e','883dece6-96eb-4364-bb1e-ea16b91b8211','5560fae3-ac96-48fc-9327-0c6b7659db87',
	'a82f9be4-3e6a-4ad5-b543-462eb1a792b5','d94c301a-84bf-4156-9728-44a873a13b80','54243000-1d47-4d9c-8465-50bf807975ae','3fcd953e-e5c1-4073-97fb-587b1ff59282'
	); -- 8 rows

-- PARTICULAR CASES
update sudoang.dbeel_physical_obstruction set po_obstruction_height = 11.5 where ob_op_id = '080d5c7c-1a93-40af-870b-c27c618925f3';
update sudoang.dbeel_physical_obstruction set po_obstruction_height = 21 where ob_op_id = 'f3a17509-c063-4cf7-b377-539077bdb120';
update sudoang.dbeel_physical_obstruction set po_obstruction_height = 89 where ob_op_id = '1032b512-5426-41ab-b841-00d001434bac';

-- 2nd round of data correction
update sudoang.dbeel_physical_obstruction set po_obstruction_height = 0 where
	ob_op_id in ('303284fc-7285-47aa-ba60-c8e2242b4858','d50487fe-0839-4c10-ab51-62f57b9f2060','462ba779-8f25-4a7a-b58c-20c73559e5d4','3186a6e0-9326-4a10-aa9b-3282cbc75988',
	'4e920409-bd7a-4e04-a2ff-7cc33c675bb5','e3b2acc0-d6d5-434e-8f4c-ae2795b7611e','225eeb74-ee8c-4b10-9c9f-bba60a2c5949','ddb4bc0f-de92-477d-b148-d3cf98912fd8',
	'3fc47dca-d30e-4d09-8d1a-e95ad9383a1c','b14b4b09-ac6a-40e0-a435-1a2da03538a9','608b3d48-6440-4f8c-9fd7-811c1453eef8','90aae4de-5354-4caa-8125-d79d14ab2aa3',
	'2bf9d162-7d55-4dcf-a9bf-23ead4f2aef4', '0037ff0c-cb5c-4fca-9ee3-ba4f2f9402e2','d8a98185-cee4-44ee-8d5e-17dd98b90367','b52fe1b8-ce76-4c93-a2c5-3ffac21f0196',
	'065f5483-f177-425e-a1cf-549e69a7f8db','dd33b7a1-cf73-40d6-b6a8-5bb87d4a2179','7ec6c945-d13f-4a1d-b923-788589ef1c20','fc39781a-7ab3-403b-b4df-2906a5805199',
	'b3773737-3066-42a9-94c1-a9c1f0d461f5','9b7b25d9-97e7-499a-a43c-73230525232c','a0742056-413c-4af3-88bc-9e4d9cc7bd7b'
	); -- 23 rows

update sudoang.dbeel_physical_obstruction set ot_no_obstruction_type = 300 where 
	ob_op_id in ('5b25b810-c32b-493d-8ee6-d65797377041','c42baa7f-10f6-469c-a8c4-751c100b092e','4a705d83-2923-46ec-bd37-76cacf4e9dfc','76a383ca-fbae-4c18-8a16-9f1de9c932c8',
	'658df730-0d66-4325-954c-5a4f9b64c793','f406e872-acd2-40bb-87bf-e0969bab3109','f7525960-3cd9-492b-92cd-b5c03412ecad','a512f118-d802-485d-8b27-3e449ae1c97b',
	'1fe532a3-21f0-4704-a166-dcda9bd2eac8','8225a5b0-c00e-4c39-8c47-d45b5759e1c1','a57972ee-9af0-4042-ab22-0d602a0f942d','a41e9335-2b69-4ddd-bec2-de3ea2c41e9e',
	'd9f3e88b-6cd5-4a19-98d2-4a585d1c8f1f','b7c41374-f948-4d23-aef9-a81d6e55f368','a18a94a4-a40e-495b-9f9d-af985ef88a0d','cd821821-2249-4abf-b3fe-2d5022f3a898',
	'd78aba8b-e8f3-4cd7-b73a-7a4e3e51666e','99feddf6-66fe-47f4-aa51-3ae641a0643f','a5f1424f-a93b-49e8-8166-f672d85dded2','3a66cbc1-dc9e-4d9b-af22-d2aa7a7bd3b3',
	'b293ad12-a985-46b1-adf2-4e5ff4cc38c9','1c8d4d6f-90b6-488b-ba7d-3e65f23a9f92','a81fe10b-b189-4412-84d4-e84cb236baa2','3cfb495e-b49e-444f-8d71-aa47034bc01a',
	'0b16f757-103e-4a47-96b8-aae7b45483ba','cb584c8e-3a2f-4ad7-a4ef-c69ec9984bed','ece0e08d-427f-49f6-bd78-52045f280305','c9a06464-e4dd-4836-bfbb-5eae26d5b46b',
	'd83eb45d-90c7-4b0d-b740-de24e21210f0','012d9247-724f-4d8f-94ff-467af32480ca','3369f7ef-e8b0-4e5d-936e-630d22d7bb15','d27bf81d-971b-449b-9e6a-684d8f381ce0',
	'17eeaac3-4137-4eca-b220-7dc79693fc05','30b14571-321a-4c70-8a1c-aa44e1f0a164','e32f0a1d-3a9b-4774-be25-e976d50a57fa','7bab11bb-be9d-442e-ab38-295a802d216c'
	); -- 36 rows

-- Delete duplicates


	
DELETE FROM sudoang.dbeel_obstruction_place WHERE op_id in ('d4ec91d1-67fc-4e21-8b81-a806c29679a5','3b458aaf-b2c7-4e11-b8f6-92f2547f7aa8',
	'0037ff0c-cb5c-4fca-9ee3-ba4f2f9402e2','5964526a-8987-4337-921f-c4495605c69f','edf74633-4e31-4021-9963-287e768d8ee8',
	'6d415969-d910-4bc4-b96f-89d0214dcaf2','365a971f-57c4-48e3-80d3-53771c410575'
);

DELETE FROM sudoang.dbeel_physical_obstruction WHERE ob_op_id in ('d4ec91d1-67fc-4e21-8b81-a806c29679a5', '3b458aaf-b2c7-4e11-b8f6-92f2547f7aa8',
	'0037ff0c-cb5c-4fca-9ee3-ba4f2f9402e2','5964526a-8987-4337-921f-c4495605c69f','edf74633-4e31-4021-9963-287e768d8ee8','6d415969-d910-4bc4-b96f-89d0214dcaf2',
	'365a971f-57c4-48e3-80d3-53771c410575'
);

--TODO-------Integration of link between two dams
-- two linked dams of 93 m Ricobayo
UPDATE sudoang.dbeel_obstruction_place SET op_op_id= 'b4c03654-81d0-4c7b-bad4-0f3c979d29dd' WHERE op_id='6c865ca5-339f-4dd7-b0f7-f477a188b975';
-- Villalcampo46
UPDATE sudoang.dbeel_obstruction_place SET op_op_id= '9543030b-4476-4575-b898-6d1c966b5e54' WHERE op_id='3b159728-d44f-4ce5-a5ca-8cb240d37732';
--Castro collado
UPDATE sudoang.dbeel_obstruction_place SET op_op_id= '806d8f61-892c-4b0b-b23c-2cafdcd8182a' WHERE op_id='36894cdb-fc43-44c5-9a8f-d12e936b724d';
UPDATE sudoang.dbeel_obstruction_place SET op_op_id= '806d8f61-892c-4b0b-b23c-2cafdcd8182a' WHERE op_id='8f6e2e2a-be23-4144-b50c-edfd1a9fb8ab';
--Almendra
UPDATE sudoang.dbeel_obstruction_place SET op_op_id='a57972ee-9af0-4042-ab22-0d602a0f942d'   WHERE op_id IN ('1549f2f5-49ad-4242-854a-b0dd8a265b63',
'9069b49b-cf2d-4ffb-8363-d4aff574fb21','80a4f00e-0c33-4f5e-a76a-3dc553f3815b');
-- Castrovido
UPDATE sudoang.dbeel_obstruction_place SET op_op_id='56061eee-d843-43d0-ad46-049b366b1504'   WHERE op_id='82fe2edb-e5eb-4b02-9839-39c4a21514fd';
-- Rio guadalaviar the dam from Belen is badly placed, amber is all right, move belen's dam and remove amber
UPDATE sudoang.dbeel_obstruction_place SET the_geom = sub.the_geom
FROM (SELECT * FROM sudoang.dbeel_obstruction_place WHERE id_original='ASP_126905')sub
WHERE dbeel_obstruction_place.op_id='8640a4a1-f518-4ea2-a6c0-a60ca74f617b';
DELETE FROM sudoang.dbeel_physical_obstruction WHERE ob_op_id in ('52e03364-90ec-4777-a5ff-d0846be46932');
DELETE FROM sudoang.dbeel_obstruction_place WHERE op_id in ('52e03364-90ec-4777-a5ff-d0846be46932');


DELETE FROM sudoang.dbeel_physical_obstruction WHERE ob_op_id in ('fb1bd586-feb6-403f-a29f-d3b9a3374257');
DELETE FROM sudoang.dbeel_obstruction_place WHERE op_id in ('fb1bd586-feb6-403f-a29f-d3b9a3374257');

/*
UPDATE sudoang.dbeel_physical_obstruction set po_obstruction_height = 0 
	ob_op_id in ('303284fc-7285-47aa-ba60-c8e2242b4858'),
*/

-- stupid bridge
DELETE FROM sudoang.dbeel_physical_obstruction WHERE ob_op_id in ('ab7690b1-60f7-4f3e-86d6-3078f05db3ef');
DELETE FROM sudoang.dbeel_obstruction_place WHERE op_id in ('ab7690b1-60f7-4f3e-86d6-3078f05db3ef');


-- Corrections Ramon uco_es_atlantica

DELETE FROM sudoang.dbeel_physical_obstruction WHERE ob_op_id IN (
SELECT op_id FROM  sudoang.dbeel_obstruction_place WHERE id_original IN (
'SO_3266',
'SO_1173',
'SO_1779',
'SO_2171',
'SO_1587',
'SO_1748',
'SO_1747',
'SO_2834',
'SO_2047',
'SO_2334',
'SO_2066',
'SO_3427',
'SO_1784',
'AOD_161',
'SO_2537',
'SO_1118',
'SO_1778')); --17

DELETE FROM sudoang.dbeel_obstruction_place WHERE op_id in (
SELECT op_id FROM  sudoang.dbeel_obstruction_place WHERE id_original IN (
'SO_3266',
'SO_1173',
'SO_1779',
'SO_2171',
'SO_1587',
'SO_1748',
'SO_1747',
'SO_2834',
'SO_2047',
'SO_2334',
'SO_2066',
'SO_3427',
'SO_1784',
'AOD_161',
'SO_2537',
'SO_1118',
'SO_1778'));

UPDATE sudoang.dbeel_physical_obstruction po SET 
(po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
(26, current_date, 'Ramón J. De Miguel Rubio',COALESCE( po.comment_update||', ','')||'HEIGHT 26') 
FROM (
   SELECT * FROM sudoang.dbeel_obstruction_place
   JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
   WHERE id_original='SO_1637')sub 
WHERE  po.ob_id=sub.ob_id;

-- A lancer pour Maria

UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (34, current_date, 'Ramón J. De Miguel Rubio',COALESCE( po.comment_update||', ','')||'HEIGHT 34, DISMISS THE TWO POINTS LOCATED JUST DOWNSTREAM BECAUSE THEY ARE DEFECTIVE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1235')sub 
   WHERE  po.ob_id=sub.ob_id;
  
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (45, current_date, 'Ramón J. De Miguel Rubio',COALESCE( po.comment_update||', ','')||'HEIGHT 45') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1439')sub 
   WHERE  po.ob_id=sub.ob_id;
  
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (54, current_date, 'Ramón J. De Miguel Rubio',COALESCE( po.comment_update||', ','')||'HEIGHT 54') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3118')sub 
   WHERE  po.ob_id=sub.ob_id;
  
  
  DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3266');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_3266');
 
 
 -- changes Guadalquivir
 
 DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_126092');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_126092';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1574');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1574';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124557');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_124557';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2539');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2539';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3191');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_3191';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_126131');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_126131';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3221');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_3221';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125752');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_125752';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3242');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_3242';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_612');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_612';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2454');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2454';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3269');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_3269';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1449');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1449';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2153');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2153';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1144');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1144';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2361');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2361';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1968');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1968';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1969');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1969';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1701');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1701';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1893');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1893';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2673');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2673';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2533');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2533';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1502');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1502';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3002');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_3002';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1287');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1287';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2001');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2001';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2097');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2097';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2099');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2099';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2098');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2098';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1919');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1919';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2367');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2367';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2757');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2757';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125818');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_125818';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1242');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1242';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1280');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1280';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2489');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2489'; --72 rows
 
 
 -- Update on height
 
 UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (15, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  < 20 M, IT IS A SMALL DAM IN THE TAIL OF THE RESERVOIR') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124415')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (101, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  101') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3585')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (106, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  106') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3447')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (12, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  12') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2207')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (14, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  14') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3035')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (24, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  24, NAME: CENTRAL HIDROELECTRICA DE DONNA ALDONZA') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3098')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (25, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  25, NAME: CENTRAL HIDROELECTRICA DE PEDRO MARIN') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124661')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (29, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  29') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3455')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (29, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  29') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3498')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (37, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  37') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3454')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (41, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  41') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3320')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (45.3, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  45.3') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3397')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (46, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  46') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3444')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (49.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  49.5') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1266')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (58, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  58') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3515')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (60, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  60') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2635')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (60, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  60') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2517')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (65, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  65') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3596')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (69, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  69') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3376')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (75, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  75') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2478')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (78, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  78') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3349')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (85, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT  85') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3580')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT < 10 M, IT IS THE MOUTH OF A PIPE FROM AN UPPER RESERVOIR, ONLY MODERATE WEIRS IN ITS FACILITIES') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_941')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (109, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 109, NAME:  BRENNA II, LA') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3300')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (21, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 21, NAME:  GUADANUNNO') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1971')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (26, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 26, NAME:  SIERRA BOYERA, TYPE: DAM') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125891')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (53, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 53, NAME:  SAN RAFAEL DE NAVALLANA, TYPE: DAM') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124955')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (60, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 60, NAME:  EMBALSE DE LA PUEBLA DE CAZALLA, TYPE: DAM') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125738')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (84, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 84, NAME:  PRESA DEL TRANCO DE BEAS') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125856')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'IT IS A COMMON WEIR VERY LIKELY LESS THAN 20 M HEIGHT, BUT NO FIELD CONTRASTING') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125214')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (13, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT  IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1983')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (18.25, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1704')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (12, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'NAME:  CENTRAL HIDROELÃ‰CTRICA DE RACIONEROS') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124919')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (14, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'NAME:  CERRADA DEL UTRERO') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124861')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (35.4, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'NAME: DANNADOR') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1771')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (20, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'NAME: EMBALSE DEL  GUADIATO') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125910')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (61.55, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'NAME: LA MINILLA II') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_126508')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (14, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'NAME: PUENTE DE LA CERRADA') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124946')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (15, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'NAME: SAN PEDRO') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125919')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (19.1, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3082')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (19.7, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2419')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (15.67, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2978')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (20.75, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1575')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (19.88, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3130')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (45.7, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1123')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (13, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1585')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (62.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3357')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (31, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1981')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (53.05, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3401')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (64, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3030')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (25.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3314')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (52.95, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3306')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (14.2, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2789')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (23.9, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1833')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (16, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124670')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (21, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3159')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (86.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3437')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (73, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3117')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (20.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1246')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (34.38, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3292')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (99, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3056')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (17, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2199')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (25.1, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3305')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (17, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2538')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (24.2, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1808')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (14, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1972')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (61, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3579')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (77.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1292')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (55.07, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2174')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (86.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3531')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (13.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2794')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (33, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3544')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (87.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3586')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (17, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3024')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (33, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3319')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (101, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1855')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (19, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2237')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (56, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3578')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (85.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3107')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (20, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2344')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (55, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3481')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (91.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2668')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (12, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_125679')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (48, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3298')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (17, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124478')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (41.6, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124529')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (19, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_124721')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (62, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3325')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (62, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3295')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (45.25, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3331')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_126525')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (14, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1112')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (20, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2565')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (14.2, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2619')sub 
   WHERE  po.ob_id=sub.ob_id; --94
   
-- update name
CREATE UNIQUE INDEX idx_dbee_obstruction_place_id_original ON sudoang.dbeel_obstruction_place(id_original);
   
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP('DonA Aldonza')
   WHERE id_original='SO_3098';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'CENTRAL HIDROELECTRICA DE PEDRO MARIN')
   WHERE id_original='ASP_124661';
  UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'BRENNA II, LA')
   WHERE id_original='SO_3300';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'GUADANUNNO')
   WHERE id_original='SO_1971';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'SIERRA BOYERA')
   WHERE id_original='ASP_125891';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'SAN RAFAEL DE NAVALLANA')
   WHERE id_original='ASP_124955';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'EMBALSE DE LA PUEBLA DE CAZALLA')
   WHERE id_original='ASP_125738';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'PRESA DEL TRANCO DE BEAS')
   WHERE id_original='ASP_125856';
  UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'CENTRAL HIDROELECTRICA DE RACIONEROS')
   WHERE id_original='ASP_124919';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'CERRADA DEL UTRERO')
   WHERE id_original='ASP_124861';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'DANNADOR')
   WHERE id_original='SO_1771';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'EMBALSE DEL GUADIATO')
   WHERE id_original='ASP_125910';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'LA MINILLA II')
   WHERE id_original='ASP_126508';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'PUENTE DE LA CERRADA')
   WHERE id_original='ASP_124946';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'SAN PEDRO')
   WHERE id_original='ASP_125919';
UPDATE sudoang.dbeel_obstruction_place  SET 
   op_placename=   INITCAP( 'PRESA DEL RÃO ALHAMA')
   WHERE id_original='SO_1419';  --16
   
   
-- UCO ES MEDITERRANEA

  --deletes
  
   DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2760');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2760';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1765');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1765';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2782');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2782';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2783');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2783';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2781');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2781';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3206');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_3206';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1110');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1110';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='AOD_104');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='AOD_104';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2733');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2733';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1638');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_1638';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2268');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='SO_2268';
 --22 lines
 
 -- height
 
 UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (2, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 2') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='AOD_102')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (4, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 4') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='AOD_111')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'HEIGHT 5') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1460')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN,  IT  IS SET IN A MOSTLY DRY WATERCOURSE. WRONG HEIGHT.') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1376')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (13, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT  IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1953')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (27, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT  IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1402')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (34, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT  IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1403')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (31, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT  IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1401')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (15, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT  IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1466')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (8, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT  IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1249')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (31, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'MINOR CONCERN, IT  IS SET IN A MOSTLY DRY WATERCOURSE') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2327')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (4, current_date, 'rjmiguel@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='CGU_494')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (4, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='CGU_494')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (23, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2256')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (22, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1667')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (66, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3323')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (17, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1780')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (67, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3366')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (25, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3485')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (18, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2769')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (26, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1965')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (10.86, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1531')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (10.15, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2192')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (14, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3011')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (23.5, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1960')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (17.85, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2973')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (17.28, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_2336')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (70, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3327')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='AOD_108')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='AOD_106')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (76, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3381')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (46, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_1135')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (68, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3312')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='AOD_105')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (31, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3625')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='AOD_110')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='AOD_115')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (93, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3464')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (82, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3294')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (99, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'OK') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3337')sub 
   WHERE  po.ob_id=sub.ob_id; 
   
   UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'WRONG HEIGHT') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3054')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'WRONG HEIGHT') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3209')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height,  date_last_update, author_last_update,  comment_update )=
   (NULL, current_date, 'a92mirur@uco.es',COALESCE( po.comment_update||', ','')||'WRONG HEIGHT.') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='SO_3080')sub 
   WHERE  po.ob_id=sub.ob_id;
   
 
--43 updates 
   
  
 -- SEGURA
 
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_132925');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_132925';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_132673');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_132673';  
  
-- 4  

/*
  DATA IMPORT from Andalucia: new_a92mirur@uco.csv 
	* The csv has been imported from QGis 
	* In the csv the IDs for type of obstacle, fishway and the ID (of the table fucl_obstruction_dams) have been added
*/

------ 2.A. DAMS DATA IMPORT
SELECT * FROM sudoang.andalucia_obstruction_dams_shiny; -- 4 rows

-- et_id = dp_et_id = 18: 'UCO'
-- dp_id = 'Carlos Fernandez'

---- Checking the srid of the geometry:
-- SELECT Find_SRID('sudoang', 'andalucia_obstruction_dams_shiny', 'geom'); -- 4326 Changed in the script obstruction_aggregation.sql (306 - 310 rows)
SELECT Find_SRID('sudoang', 'andalucia_obstruction_dams_shiny', 'geom'); -- 3035 

---- Creation spatial index
CREATE INDEX 
  ON sudoang.andalucia_obstruction_dams_shiny
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','andalucia_obstruction_dams_shiny','geom_reproj', 3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

begin;
update sudoang.andalucia_obstruction_dams_shiny set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.andalucia_obstruction_dams_shiny a join
spain.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= andalucia_obstruction_dams_shiny.id; -- 4 rows
commit;

CREATE INDEX 
  ON sudoang.andalucia_obstruction_dams_shiny
  USING gist
  (geom_reproj);
  
---- Link Andalucia dams TO dbeel
ALTER TABLE sudoang.andalucia_obstruction_dams_shiny ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.andalucia_obstruction_dams_shiny ADD COLUMN initial_duplicate boolean default FALSE;

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.andalucia_obstruction_dams_shiny AS sp1, sudoang.andalucia_obstruction_dams_shiny AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows

-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
WITH duplicate_fcul AS 
(
	SELECT geom_reproj, op_id, id, st_distance(the_geom, geom_reproj) as distance
	FROM sudoang.andalucia_obstruction_dams_shiny, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'AOD%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by id, distance -- 4 rows. To be tuned
), 
uq_duplicates_uco as (
	select distinct on (id) * from duplicate_fcul
)
select * from uq_duplicates_uco; -- 0 rows
--UPDATE sudoang.andalucia_obstruction_dams_shiny SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
--FROM uq_duplicates_fcul 
--WHERE andalucia_obstruction_dams_shiny.id = uq_duplicates_fcul.id;

/* NOT duplicates
---- Check for these duplicates:
SELECT 	dop.op_id, dop.op_gis_layername, dop.op_gislocation, dop.op_placename, dop.id_original,
	dpo.po_obstruction_height, dpo.comment_update, ap.id, ap.obs_name, ap.obs_height, ap.ot_type, ap.fishway_type_name
FROM sudoang.dbeel_obstruction_place dop
     JOIN sudoang.dbeel_physical_obstruction dpo ON ob_op_id = op_id
     JOIN sudoang.andalucia_obstruction_dams_shiny ap on op_id = dbeel_op_id;
*/


---- NEW dams inserted into dbeel_obstruction_place
begin;
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT 	uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'UCO' AS op_gis_layername, 
		id AS op_gislocation, 
		obs_name AS op_placename,
		281 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		id AS id_original,
		'SP' AS country
		FROM sudoang.andalucia_obstruction_dams_shiny; -- 4 rows
commit;

---- Record back the link with dbeel: 
---- For the new dams without duplicates, insert back the id from dbeel table (op_id inserted into the dbeel) into the source table (andalucia_obstruction_dams_shiny)
-- UPDATE sudoang.andalucia_obstruction_dams_shiny SET dbeel_op_id = NULL; -- to reset the column
begin;
UPDATE sudoang.andalucia_obstruction_dams_shiny SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place
WHERE id = id_original and initial_duplicate = false AND op_gis_layername='UCO'; -- 4 rows
commit;

-- "obs_eel_pass" from fcul_obstruction_dams_shiny is text, it must be converted into boolean:
begin;
alter table sudoang.andalucia_obstruction_dams_shiny
alter column obs_eel_pass
set data type boolean
using case
    when obs_eel_pass = 'FALSE' then FALSE
    else NULL
end;
commit;

select * from sudoang.andalucia_obstruction_dams_shiny;
---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
INSERT INTO sudoang.dbeel_physical_obstruction (ob_id, ob_no_origin, ob_no_type, ob_no_period, ob_starting_date, ob_ending_date, ob_op_id, ob_dp_id, ot_no_obstruction_type, ot_obstruction_number, po_obstruction_height,
	po_presence_eel_pass, fishway_type, date_last_update, author_last_update, comment_update)
	SELECT 
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  no_id_obstacle as ot_no_obstruction_type,
	  1 as ot_obstruction_number,
	  obs_height AS po_obstruction_height,
	  obs_eel_pass as po_presence_eel_pass,
	  no_id_fishway as fishway_type,
	  '2020-03-26' as date_last_update,
	  'a92mirur@uco.es' as author_last_update,
	  'Obstacles integrated by Ramon during the data validation in Shiny' as comment_update
	FROM sudoang.andalucia_obstruction_dams_shiny JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id, id) = (op_id, id_original), 
	dbeel.data_provider 
	WHERE dp_name = 'Carlos Fernandez'
	AND op_gis_layername = 'UCO'
	AND not initial_duplicate
; -- 4 rows
commit;


/* Checking that the new dams are in the dbeel:
with joining as (
	select * from sudoang.dbeel_physical_obstruction left join sudoang.dbeel_obstruction_place on ob_op_id = op_id
	)
select * from joining where op_gis_layername = 'UCO' -- 34 rows
*/


------------------------------
-- Portugal
------------------------------
--------------------
/* 
 PROBLEME DE CORRESPONDANCE ENTRE LES TABLES amber_portugal et la dbeel, l'id_original ne correspond pas :

 Au lieu de refaire le lien vers la table amber en utilisant le op_id qu'on avait remis dessus, 
 on ajoute un "id" de la table, mais cet id est juste un entier et il disparait après en devenant
  un APT_XXXX :

---- Record back the link with dbeel: op_id of new dams (inserted into the dbeel) are inserted into the source table (amber_portugal)
-- UPDATE sudoang.amber SET dbeel_op_id = NULL; -- to reset the column
begin;
UPDATE sudoang.amber_portugal SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place 
WHERE geom_reproj = the_geom AND geom_reproj && the_geom AND op_gis_layername='amber';	-- 582 rows
COMMIT;

---- The id of the source table (amber_portugal) is retrieved in the dbeel_obstruction_place: choose an id (last) to record in dbeel
WITH id_obs AS
	(SELECT dbeel_op_id, 'APT_' || max(substring(id from 5)::integer) AS id 
	FROM sudoang.amber_portugal WHERE dbeel_op_id IS NOT NULL GROUP BY dbeel_op_id)
UPDATE sudoang.dbeel_obstruction_place SET id_original = id, op_gislocation = id 
	FROM id_obs WHERE op_id = dbeel_op_id AND op_gis_layername='amber'; -- 588 rows

En Effet l'id original a été modifié comme :
alter sequence seq restart with 1;
alter table amber_portugal add column id character varying(10);
update amber_portugal set id = 'APT_'||nextval('seq');  -- 658 rows
alter table amber_portugal add constraint c_apt_uk_id unique (id);

La bonne nouvelles c'est que le lien par le dbeel_ob_id fonctionne lui
en effet : 

 SELECT 	dop.op_id, dop.op_gis_layername, dop.op_gislocation, dop.op_placename, dop.id_original,
	ap.id, ap.name, ap.type_barrier_height, ap.height, ap.height_altura_m, ap.initial_duplicate, 
	dpo.po_obstruction_height, dpo.comment_update, ap.dbeel_op_id
FROM sudoang.dbeel_obstruction_place dop
     JOIN sudoang.dbeel_physical_obstruction dpo ON ob_op_id = op_id
     JOIN sudoang.amber_portugal ap on geom_reproj = the_geom
     WHERE dbeel_op_id!=op_id;
     
renvoit zéro lignes donc là ou tu as utilisé le geom_reproj 
on peut utiliser dbeel_ob_id 
 
 
-- requete pour aller chercher les ob_id....    
SELECT *
FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
	RIGHT JOIN sudoang.amber_portugal 
	ON dbeel_op_id=op_id
WHERE op_gislocation IN ('APT_108','APT_110','APT_125','APT_127','APT_130','APT_131','APT_134','APT_139','APT_140','APT_144','APT_151','APT_185','APT_220','APT_221','APT_239','APT_265','APT_266','APT_267','APT_268','APT_275','APT_279','APT_289','APT_292','APT_301','APT_304','APT_310','APT_317','APT_515','APT_534','APT_537','APT_574','APT_604','APT_76','APT_77','APT_78','MIO_135',
'POD_10','POD_113','POD_122','POD_134','POD_177','POD_203','POD_218','POD_232','POD_42','POD_91')
ORDER BY op_gislocation;

/*
  * In the script below I'm updating the values in amber table as they were wrong.
  * I can only update those that have been inserted in the dbeel, so I need to change the code
  * from previous values where there was no insert otherwise we will have duplicated values.
  * One last problem was where a dam had exactly the same location, it appeared as two lines,
  * I have updated one line with a new code to avoid duplication 
  * 
*/
 
ALTER TABLE sudoang.amber_portugal DROP CONSTRAINT c_apt_uk_id ;
-- remove names for those without projection
create temporary sequence seq;
alter sequence seq restart with 1000;
UPDATE  sudoang.amber_portugal SET id='APT_'||nextval('seq') WHERE dbeel_op_id IS NULL;--69

 WITH good_join AS (
SELECT *
FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
	RIGHT JOIN sudoang.amber_portugal ON dbeel_op_id=op_id
	ORDER BY op_gislocation)
UPDATE sudoang.amber_portugal SET id = op_gislocation
FROM good_join WHERE amber_portugal.dbeel_op_id=good_join.op_id
;--582
SELECT * FROM     sudoang.amber_portugal ORDER BY id;
-- this is a duplicate left :: two points at exactly the same location....
UPDATE  sudoang.amber_portugal SET id='APT_'||nextval('seq') WHERE name='Mingazes 1';--1
ALTER TABLE sudoang.amber_portugal ADD CONSTRAINT c_apt_uk_id UNIQUE (id); -- OK



-- UPDATES FROM EXCEL

DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='MIO_131');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='MIO_131';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_260');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_260';
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (25, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'coordinates corrected') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_261')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (3.5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'coordinates updated and height added') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_211')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (7, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'height updated') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_240')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (7.5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'Height updated') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_80')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (148, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'Height updated') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_164')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (10.5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'height updated from 15 to 10.5') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_196')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (7, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'height updated from 87 to 7') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_224')sub 
   WHERE  po.ob_id=sub.ob_id;
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_296');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_296';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_530');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_530';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_629');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_629';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_635');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_635';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_636');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_636';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_637');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_637';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_120147');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_120147';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_126882');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_126882';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_130454');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_130454';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_131933');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_131933';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_253');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_253';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_269');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_269';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_320');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_320';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_323');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_323';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_335');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_335';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_401');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_401';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_402');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_402';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_420');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_420';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_513');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_513';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_573');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_573';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_616');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_616';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='ASP_126807');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='ASP_126807';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_33');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='POD_33';
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (10, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'It is not working properly. The fishway does not work.') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_82')sub 
   WHERE  po.ob_id=sub.ob_id;
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_40');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='POD_40';
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (110, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_83')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (87, NULL, FALSE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_123')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (100, NULL, FALSE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_128')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (80, NULL, FALSE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_133')sub 
   WHERE  po.ob_id=sub.ob_id;
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_117');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_117';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_149');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_149';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_165');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_165';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_177');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_177';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_256');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_256';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_258');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_258';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_259');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_259';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_263');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_263';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_264');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_264';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_342');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_342';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_359');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_359';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_368');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_368';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_369');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_369';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_454');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_454';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_520');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_520';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_105');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='POD_105';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_151');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='POD_151';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_30');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='POD_30';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_93');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='POD_93';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_510');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_510';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_556');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_556';
DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_557');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='APT_557';
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (20, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_108')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (6, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_110')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (104, NULL, FALSE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_125')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (33.5, NULL, FALSE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_127')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (57, 274, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_130')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (25.5, 274, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_131')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (41, 274, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_134')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (49, 274, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_139')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (48, 274, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_140')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (2, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_144')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (NULL, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_151')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (NULL, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_185')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (NULL, 275, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_220')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (4, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_221')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (18.5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_239')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (NULL, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_265')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (3.6, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_266')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (10.4, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_267')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (9, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_268')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (3.5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_275')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (3.5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_279')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (2, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_289')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (6.5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_292')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (6.2, 270, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_301')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (36, 274, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_304')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (48.5, NULL, FALSE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_310')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (33.5, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_317')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (NULL, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_515')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (45, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_534')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (26, NULL, FALSE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_537')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (43, 274, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_574')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (36, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_604')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_76')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (42.5, 274, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_77')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (12, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='APT_78')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (0.1, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='MIO_135')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (35, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_10')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (26, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_113')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (28, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_122')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (NULL, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_134')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (5.5, 271, TRUE, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_177')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (205, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_203')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (35, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_218')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (16, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_232')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (27, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_42')sub 
   WHERE  po.ob_id=sub.ob_id;
UPDATE sudoang.dbeel_physical_obstruction po SET 
   (po_obstruction_height, fishway_type,  po_presence_eel_pass, date_last_update, author_last_update,  comment_update )=
   (56, NULL, NULL, current_date, 'tmportela@fc.ul.pt',COALESCE( po.comment_update||', ','')||'No comment given, height, fishway type and expertise pass updated but we don''t know if there was any change') 
     FROM (
     SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_91')sub 
   WHERE  po.ob_id=sub.ob_id; --105


/*
  DATA IMPORT from Portugal: databasenew_tmportela@fc.ul.pt.csv 
	* The csv has been imported from QGis 
	* In the csv the IDs for type of obstacle, fishway and the ID (of the table fucl_obstruction_dams) have been added
*/

------ 2.A. DAMS DATA IMPORT
SELECT * FROM sudoang.fcul_obstruction_dams_shiny;

-- et_id = dp_et_id = 21: FCUL (APA, EDP, MARE)
-- dp_id = Isabel domingos

---- Checking the srid of the geometry:
-- SELECT Find_SRID('sudoang', 'fcul_obstruction_dams_shiny', 'geom'); -- 4326 Changed in the script obstruction_aggregation.sql (301 - 304 rows)
SELECT Find_SRID('sudoang', 'fcul_obstruction_dams_shiny', 'geom'); -- 3035 

---- Creation spatial index
CREATE INDEX 
  ON sudoang.fcul_obstruction_dams_shiny
  USING gist
  (geom);

---- Reproject on the rivers
SELECT addgeometrycolumn('sudoang','fcul_obstruction_dams_shiny','geom_reproj', 3035,'POINT',2);
-- It correspond to the same "geom" because the srid is the same, done for don't change the script below

begin;
update sudoang.fcul_obstruction_dams_shiny set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id, 
ST_ClosestPoint(r.geom,a.geom) as geom_reproj,
ST_distance(r.geom,a.geom) as distance
from sudoang.fcul_obstruction_dams_shiny a join
portugal.rn r on st_dwithin(r.geom,a.geom,300) 
order by id, distance
)sub )sub2
where sub2.id= fcul_obstruction_dams_shiny.id; -- 17 rows (1 without geom_reproj)
commit;

CREATE INDEX 
  ON sudoang.fcul_obstruction_dams_shiny
  USING gist
  (geom_reproj);
  
---- Link Portuguese dams TO dbeel
ALTER TABLE sudoang.fcul_obstruction_dams_shiny ADD COLUMN dbeel_op_id uuid;
ALTER TABLE sudoang.fcul_obstruction_dams_shiny ADD COLUMN initial_duplicate boolean default FALSE;
-- update sudoang.fcul_obstruction_dams set dbeel_op_id = FALSE

---- There are 36 dams without the height of dams
SELECT * FROM sudoang.fcul_obstruction_dams_shiny WHERE obs_height is null; -- 3 rows

---- Check for INTERNAL DUPLICATES in the same table (geographically, in meters)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.fcul_obstruction_dams_shiny AS sp1, sudoang.fcul_obstruction_dams_shiny AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 rows


-- The query is called duplicates but it is in fact TO AVOID DUPLICATES
begin;
WITH duplicate_fcul AS 
(
	SELECT geom_reproj, op_id, id, st_distance(the_geom, geom_reproj) as distance
	FROM sudoang.fcul_obstruction_dams_shiny, sudoang.dbeel_obstruction_place
	WHERE id LIKE 'POD%' AND geom_reproj IS NOT NULL AND ST_DWithin(the_geom, geom_reproj, 500) order by id, distance -- 4 rows. To be tuned
), 
uq_duplicates_fcul as (
	select distinct on (id) * from duplicate_fcul
)
--select * from uq_duplicates_fcul; -- 4 rows
UPDATE sudoang.fcul_obstruction_dams_shiny SET (dbeel_op_id, initial_duplicate) = (op_id, TRUE)
FROM uq_duplicates_fcul 
WHERE fcul_obstruction_dams_shiny.id = uq_duplicates_fcul.id
; -- 4 rows
commit;

---- Check for these duplicates:
SELECT 	dop.op_id, dop.op_gis_layername, dop.op_gislocation, dop.op_placename, dop.id_original,
	dpo.po_obstruction_height, dpo.comment_update, ap.id, ap.obs_name, ap.obs_height, ap.ot_type, ap.fishway_type_name
FROM sudoang.dbeel_obstruction_place dop
     JOIN sudoang.dbeel_physical_obstruction dpo ON ob_op_id = op_id
     JOIN sudoang.fcul_obstruction_dams_shiny ap on op_id = dbeel_op_id;

---- Update the obstruction_place with the name of FCUL to replace source from AMBER to modified data source by FCUL
BEGIN;		
With updatetable as(
SELECT 
       obs_name,
       CASE WHEN obs_eel_pass = 'yes' then TRUE
            WHEN obs_eel_pass = 'NA' then NULL 
            END as obs_eel_pass,
       coalesce(obs_height, po_obstruction_height) as po_obstruction_height,  -- replace when not null
       id,
       ob_id,
       op_id,
       CASE WHEN po_obstruction_height!=obs_height THEN 'UPDATE FROM fcul data, height changed from '||po_obstruction_height||' to '||obs_height 
       ELSE NULL end as comment_update,
       no_id_fishway as fishway_type,
       no_id_obstacle as ot_no_obstruction_type
       FROM 	
	        sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.fcul_obstruction_dams_shiny on dbeel_op_id=ob_op_id
		where initial_duplicate)
-- We let op_gislocation with the orginal id from amber
UPDATE sudoang.dbeel_obstruction_place set (op_gis_layername,id_original,op_placename) = ('FCUL/MARE', id, obs_name) FROM updatetable where dbeel_obstruction_place.op_id = updatetable.op_id; --180
COMMIT; -- 4 rows

BEGIN;		
With updatetable as(
SELECT 
       obs_name,
       CASE WHEN obs_eel_pass = 'yes' then TRUE
            WHEN obs_eel_pass = 'NA' then NULL 
            END as po_presence_eel_pass,
       coalesce(obs_height, po_obstruction_height) as po_obstruction_height,  -- replace when not null
       id,
       ob_id,
       op_id,
       CASE WHEN po_obstruction_height!=obs_height THEN 'UPDATE FROM fcul data, height changed from '||po_obstruction_height||' to '||obs_height 
       ELSE NULL end as comment_update,
       no_id_fishway as fishway_type,
       no_id_obstacle as ot_no_obstruction_type
       FROM 	
	        sudoang.dbeel_obstruction_place 
	        JOIN sudoang.dbeel_physical_obstruction ON op_id=ob_op_id
		JOIN sudoang.fcul_obstruction_dams_shiny on dbeel_op_id=ob_op_id
		where initial_duplicate)
UPDATE sudoang.dbeel_physical_obstruction set (po_presence_eel_pass, ot_no_obstruction_type, po_obstruction_height, ob_dp_id, fishway_type, comment_update, date_last_update, author_last_update) =
(updatetable.po_presence_eel_pass, updatetable.ot_no_obstruction_type, updatetable.po_obstruction_height, 19, updatetable.fishway_type, updatetable.comment_update, '2020-03-25', 'Cédric and Maria') 
FROM updatetable where dbeel_physical_obstruction.ob_id = updatetable.ob_id; -- 4 rows
COMMIT;


---- NEW dams inserted into dbeel_obstruction_place
begin;
WITH unique_obs as (
			SELECT * FROM sudoang.fcul_obstruction_dams_shiny WHERE dbeel_op_id IS NULL AND geom_reproj IS NOT NULL -- 13 rows
			)
INSERT INTO sudoang.dbeel_obstruction_place
	SELECT 	uuid_generate_v4() AS op_id,
		'SUDOANG' AS op_gis_systemname,
		'FCUL/MARE' AS op_gis_layername, 
		id AS op_gislocation, 
		obs_name AS op_placename,
		281 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom,
		id AS id_original,
		'PT' AS country
		FROM unique_obs; -- 13 rows
commit;

---- Record back the link with dbeel: 
---- For the new dams without duplicates, insert back the id from dbeel table (op_id inserted into the dbeel) into the source table (fcul_obstruction_dams_shiny)
-- UPDATE sudoang.fcul_obstruction_dams SET dbeel_op_id = NULL; -- to reset the column
begin;
UPDATE sudoang.fcul_obstruction_dams_shiny SET dbeel_op_id = op_id 
FROM sudoang.dbeel_obstruction_place
WHERE id = id_original and initial_duplicate = false AND op_gis_layername='FCUL/MARE'; -- 13 rows
commit;

-- "obs_eel_pass" from fcul_obstruction_dams_shiny is text, it must be converted into boolean:
begin;
alter table sudoang.fcul_obstruction_dams_shiny
alter column obs_eel_pass
set data type boolean
using case
    when obs_eel_pass = 'Yes' then true -- error: Y
    when obs_eel_pass = 'NA' then NULL
end;
commit; -- DE LA PUREEEEEE obs_eel_pass is null
select * from sudoang.fcul_obstruction_dams_shiny where obs_eel_pass is not null; -- 0 rows

update sudoang.fcul_obstruction_dams_shiny set obs_eel_pass = TRUE; -- 18 rows
update sudoang.fcul_obstruction_dams_shiny set obs_eel_pass = NULL where id = 'POD_281' OR id = 'POD_282' or id = 'POD_283'; -- 3 rows 

---- Correct the op_gislayername from dbeel_obstruction_place
begin;
with port_shiny as (
			select * from sudoang.fcul_obstruction_dams_shiny 
			join  
			sudoang.dbeel_obstruction_place
			on dbeel_op_id = op_id -- 17 rows
		    )
update sudoang.dbeel_obstruction_place set op_gis_layername = 'FCUL (APA, EDP, MARE)' where op_id in (select op_id from port_shiny); -- 17 rows
commit;

---- Insert into the dbeel_physical_obstruction table, all the characteristics of the new dams
begin;
INSERT INTO sudoang.dbeel_physical_obstruction (ob_id, ob_no_origin, ob_no_type, ob_no_period, ob_starting_date, ob_ending_date, ob_op_id, ob_dp_id, ot_no_obstruction_type, ot_obstruction_number, po_obstruction_height,
	po_presence_eel_pass, fishway_type, date_last_update, author_last_update, comment_update)
	SELECT 
	  uuid_generate_v4() as ob_id,
	  11 AS ob_no_origin, -- raw data
	  16 AS ob_no_type, -- obstruction
	  74 AS ob_no_period, -- Unknown
	  NULL AS ob_starting_date,
	  NULL AS ob_ending_date,
	  dbeel_obstruction_place.op_id as ob_op_id,
	  dp_id AS ob_dp_id,
	  no_id_obstacle as ot_no_obstruction_type,
	  1 as ot_obstruction_number,
	  obs_height AS po_obstruction_height,
	  obs_eel_pass as po_presence_eel_pass,
	  no_id_fishway as fishway_type,
	  '2020-03-25' as date_last_update,
	  'tmportela@fc.ul.pt' as author_last_update,
	  'Obstacles integrated by Teresa Portela during the data validation in Shiny' as comment_update
	FROM sudoang.fcul_obstruction_dams_shiny JOIN sudoang.dbeel_obstruction_place ON (dbeel_op_id, id) = (op_id, id_original), 
	dbeel.data_provider 
	WHERE dp_id = 19 -- 'Isabel Domingos'
	AND op_gis_layername = 'FCUL (APA, EDP, MARE)'
	AND not initial_duplicate
; -- 13 rows
commit;


/* Checking that the new dams are in the dbeel:
with joining as (
	select * from sudoang.dbeel_physical_obstruction left join sudoang.dbeel_obstruction_place on ob_op_id = op_id
	)
select * from joining where op_gis_layername = 'FCUL (APA, EDP, MARE)' -- 17 rows

with joining as (
	select * from sudoang.dbeel_physical_obstruction left join sudoang.dbeel_obstruction_place on ob_op_id = op_id
	)
select * from joining where op_gis_layername = 'FCUL/MARE' -- 258 rows
*/

/*
 * 28/03 checking for eels above dams, there is no dam of 200 m there
 */

DELETE FROM sudoang.dbeel_physical_obstruction  WHERE ob_id = 
     (SELECT ob_id 
     FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
     WHERE id_original='POD_203');
  DELETE FROM sudoang.dbeel_obstruction_place WHERE  id_original='POD_203';
 
 /*
  * 28/03 A recent power plant
  */
 
 SELECT * FROM sudoang.dbeel_hpp dh 
 JOIN sudoang.dbeel_physical_obstruction po ON dh.hpp_ob_id = po.ob_id 
 WHERE ob_id='f8900b68-b554-4c94-bc61-7aed21ba265f';

-- the height is not 186 m
 UPDATE sudoang.dbeel_physical_obstruction SET (ob_starting_date,po_obstruction_height)=
('2018-01-01',77.5) WHERE ob_id='f8900b68-b554-4c94-bc61-7aed21ba265f';

-- 118 MW 200 m3/s
UPDATE sudoang.dbeel_hpp SET (hpp_max_power, hpp_turb_max_flow ) = (118,200)
WHERE hpp_ob_id='f8900b68-b554-4c94-bc61-7aed21ba265f';


-- It is clear from the plan that there are two Francis turbines
--https://tpf.eu/es/projects/daivoes-hydropower-scheme/

INSERT INTO sudoang.dbeel_turbine (
turb_id,
turb_hpp_id,
turb_turbine_type_no_id,
turb_in_service,
turb_max_power,
turb_hpp_height,
turb_max_turbine_flow) VALUES 
( uuid_generate_v4(),
'8bd3e6b7-d3fe-48a2-94ea-3a415e008e84',
255, -- Francis
TRUE,
59,
77.5,
110
);
-- we need to insert it twice (so this is not a duplication)
INSERT INTO sudoang.dbeel_turbine (
turb_id,
turb_hpp_id,
turb_turbine_type_no_id,
turb_in_service,
turb_max_power,
turb_hpp_height,
turb_max_turbine_flow) VALUES 
( uuid_generate_v4(),
'8bd3e6b7-d3fe-48a2-94ea-3a415e008e84',
255, -- Francis
TRUE,
59,
77.5,
110
);
 --89

-- On the EBRO this is a bridge

UPDATE sudoang.dbeel_physical_obstruction po SET  (po_obstruction_height,  ot_no_obstruction_type, date_last_update, author_last_update,  comment_update)=
(0,296, current_date, 'Cédric and Maria', COALESCE(po.comment_update||', ','')||'This is a bridge') 
FROM (SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
      where id_original= 'ASP_119203') sub
      where sub.ob_id=po.ob_id;


UPDATE sudoang.dbeel_physical_obstruction po set ot_no_obstruction_type = 300 
FROM (SELECT * FROM sudoang.dbeel_obstruction_place
     JOIN sudoang.dbeel_physical_obstruction ON ob_op_id=op_id
      where id_original= 'SO1433') sub
      where sub.ob_id=po.ob_id;


-- duplicate

	
		
DELETE FROM sudoang.dbeel_obstruction_place WHERE op_id in ('854575af-a2b9-4625-b3d6-65b8e57b78f1');

DELETE FROM sudoang.dbeel_physical_obstruction WHERE ob_op_id in ('854575af-a2b9-4625-b3d6-65b8e57b78f1');

	
-- duplicated Minho Friera

DELETE FROM sudoang.dbeel_obstruction_place WHERE op_id in ('799ee893-0f76-40bd-817c-c0c66175cdb0');
DELETE FROM sudoang.dbeel_physical_obstruction WHERE ob_op_id in ('799ee893-0f76-40bd-817c-c0c66175cdb0');

DELETE FROM sudoang.dbeel_obstruction_place WHERE op_id in ('d9e6f1af-1cb6-43dd-a527-5d81cfbe8b0a');
DELETE FROM sudoang.dbeel_physical_obstruction WHERE ob_op_id in ('d9e6f1af-1cb6-43dd-a527-5d81cfbe8b0a');



