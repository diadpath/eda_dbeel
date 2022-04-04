-- updated TABLES 04/04 => Maria

/*
dbeel.establishment
dbeel.data_provider
*/


---------------------------------------------
-- SCRIPT INTEGRATION SIBIC => DBEEL
---------------------------------------------


-- select * from dbeel.establishment;
INSERT INTO  dbeel.establishment (et_establishment_name) VALUES ('OFB');
--select * from dbeel.data_provider
--select max(dp_id) from dbeel.data_provider; -- 25
INSERT INTO  dbeel.data_provider (dp_id, dp_name, dp_et_id) VALUES (30, 'Pascal Irz',27);
ALTER SEQUENCE dbeel.data_provider_dp_id_seq RESTART WITH 31;


-- TABLES FOR IMPORT will be created IN France AND IN loire schema (for electrofishing from f�d�rations de p�che)
-- script for creating station is in eda_dbeel/eda2.3/R/aspe_import.R


select * from dbeel.observation_places limit 10;




--select * from sudoang.dbeel_station;

-- Create the stationdbeel table from dbeel
DROP TABLE if exists sudoang.stationdbeel CASCADE;
CREATE TABLE sudoang.stationdbeel (
	locationid integer,
        country character varying(2),
	place_classification text,
	codhb text,
	observations text,
	hydrographic_basin_pt text,
	hydrographic_basin_es text,
	s_guid text,
	x double precision,
	y double precision,		
	CONSTRAINT pk_so_op_id PRIMARY KEY (op_id),
	CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
		REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
		MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);

--select * from sudoang.stationdbeel limit 10;


-- Insert data from location table (SIBIC) into the stationdbeel table
INSERT INTO sudoang.stationdbeel
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'25830' AS op_gis_systemname ,
	'SIBIC' AS op_gis_layername, 
	NULL AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	stretch_place as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	st_transform(geom ,3035) as the_geom, 
	locationid as locationid,
	NULL as country,
	place_classification as place_classification, -- That correspond to the station's code of the original data provided to the SIBIC
	codhb as codhb,	
	"Observaciones" as observations,
	"HydrographicBasin_PT" as hydrographic_basin_pt,
	"HydrographicBasin_ES" as hydrographic_basin_es,
	"s_GUID" as s_guid,
	"X" as x,
	"Y" as y
	FROM sudoang.location; -- 10839 rows, 8.6 secs

/*
RUNONCE INSTALL DBLINK
*/
--CREATE EXTENSION dblink;

/*
The column PT or ES is based on the apparatenance to basins, it is wrong, here we recode properly with a spatial query.
For that, we use dnlink, a module which supports connections to other PostgreSQL databases from within a database session.
We created a view taking the basins layers (from Spain and Portugal) and making a spatial query between these layers and the stations.
   (st_intersect: takes 2geometries and returns TRUE if any part of those geometries is shared between the 2).
*/

CREATE VIEW sudoang.portugal_union_basin AS
  SELECT *
    FROM dblink('dbname=eda2.0 host=localhost user=postgres password=postgres',
                'SELECT st_transform(st_union(geom),3035) from portugal.atagua_bacias_bacias_snirh_pc')
    AS t1(geom geometry);
  
--DROP VIEW sudoang.spain_union_basin;
CREATE VIEW sudoang.spain_union_basin AS
  SELECT *
    FROM dblink('dbname=eda2.0 host=localhost user=postgres password=postgres',
                'SELECT st_transform(st_union(the_geom),3035) from spain.wise_rbd_f1v3')
    AS t1(geom geometry);   

UPDATE sudoang.stationdbeel set country=NULL; -- 10839 rows, 245 msec
UPDATE sudoang.stationdbeel set country='PT' FROM sudoang.portugal_union_basin WHERE st_intersects(the_geom,geom); -- 1907 rows, 14.4 secs
UPDATE sudoang.stationdbeel set country='ES' FROM sudoang.spain_union_basin WHERE st_intersects(the_geom,geom); -- 8415, 4.1 secs

-- It does not work for Maria ()
update sudoang.stationdbeel set

with howmany as (
select count(*), locationid from sudoang.location group by locationid)-- Check if the locationid is duplicated
select * from howmany where count>1


---------------------------------------------------
-- sudoang.electrofishing
---------------------------------------------------
--select * from sudoang.species_location limit 100
select distinct methods from sudoang.species_location -- There are 140 methods of fishing (and empty option)

-- Standardize the format of some parameters 
update sudoang.species_location set "Area"=regexp_replace("Area", ',', '.'); -- 65132 rows, 868 msec
update sudoang.species_location set "ind/ha"=regexp_replace("ind/ha", ',', '.'); -- 65132 rows, 471 msec
update sudoang.species_location set "ind/hour"=regexp_replace("ind/hour", ',', '.'); -- 65132 rows, 553 msec

update sudoang.species_location set "capture_date"=regexp_replace("capture_date", '  ', ' '); -- 65132 rows, 656 msec


------------------------------------------------------------------
-- extract month from textual information
------------------------------------------------------------------
alter table sudoang.species_location add column capture_month character varying(2);

select * from sudoang.species_location where lower(capture_date) like '%octubre%'; -- 3907 rows
update sudoang.species_location set capture_month='10' where lower(capture_date) like '%octubre%'; -- 3907 rows, 127 msec
update sudoang.species_location set capture_month='05' where lower(capture_date) like '%mayo%'; -- 2157 rows, 94 msec
update sudoang.species_location set capture_month='06' where lower(capture_date) like '%junio%'; -- 2596 rows, 85 msec
update sudoang.species_location set capture_month='07' where lower(capture_date) like '%julio%'; -- 3985 rows, 103 msec
update sudoang.species_location set capture_month='08' where lower(capture_date) like '%agosto%'; -- 4721 rows, 109 msec
update sudoang.species_location set capture_month='09' where lower(capture_date) like '%septiembre%'; -- 6820 rows, 104 msec
update sudoang.species_location set capture_month='11' where lower(capture_date) like '%noviembre%'; -- 1255 rows, 108 msec
update sudoang.species_location set capture_month='12' where lower(capture_date) like '%diciembre%'; -- 422 rows, 72 msec
update sudoang.species_location set capture_month='01' where lower(capture_date) like '%enero%'; -- 506 rows, 103 msec
update sudoang.species_location set capture_month='02' where lower(capture_date) like '%febrero%'; -- 347 rows, 88 msec
update sudoang.species_location set capture_month='03' where lower(capture_date) like '%marzo%'; -- 908 rows, 83 msec
update sudoang.species_location set capture_month='04' where lower(capture_date) like '%abril%'; -- 4561 rows, 124 msec
update sudoang.species_location set capture_month='05' where lower(capture_date) like '%primavera%'; -- 2046 rows, 123 msec
update sudoang.species_location set capture_month='10' where lower(capture_date) like '%otoño%'; -- 1236 rows, 92 msec
update sudoang.species_location set capture_month='06' where lower(capture_date) like '%junho%'; -- 2279 rows, 95 msec
update sudoang.species_location set capture_month='05' where lower(capture_date) like '%maio%'; -- 1950 rows, 96 msec
update sudoang.species_location set capture_month='09' where lower(capture_date) like '%setembro%'; -- 1802 rows, 92 msec
update sudoang.species_location set capture_month='03' where lower(capture_date) like '%março%'; -- 1840 rows, 85 msec
update sudoang.species_location set capture_month='08' where lower(capture_date) like '%verão%'; -- summer: 837 rows, 93 msec
update sudoang.species_location set capture_month='11' where lower(capture_date) like '%novembro%'; -- 2356 rows, 111 msec
update sudoang.species_location set capture_month='10' where lower(capture_date) like '%outubro%'; -- 2560 rows, 114 msec
update sudoang.species_location set capture_month='07' where lower(capture_date) like '%julho%'; -- 2752 rows, 102 msec
update sudoang.species_location set capture_month='12' where lower(capture_date) like '%dezembro%'; -- 1686 rows, 98 msec
update sudoang.species_location set capture_month='02' where lower(capture_date) like '%fevereiro%'; -- 1893 rows, 95 msec
update sudoang.species_location set capture_month='01' where lower(capture_date) like '%janeiro%'; -- 1368 rows, 92 msec
update sudoang.species_location set capture_month='08' where lower(capture_date) like '%verano%'; -- 300 rows, 82 msec
update sudoang.species_location set capture_month='10' where lower(capture_date) like '%outono%'; -- 161 rows, 92 msec
update sudoang.species_location set capture_month='09' where lower(capture_date) like '%septiem%'; -- 6822 rows, 107 msec
update sudoang.species_location set capture_month='09' where lower(capture_date) like '%spetiem%'; -- 1 row, 72 msec
update sudoang.species_location set capture_month='04' where lower(capture_date) like '%abr%'; -- 4595 rows, 112 msec
update sudoang.species_location set capture_month='10' where lower(capture_date) like '%ocutbre%'; -- 1 row, 82 msec
update sudoang.species_location set capture_month='09' where lower(capture_date) like '%setiem%'; -- 5 rows, 81 msec
update sudoang.species_location set capture_month='08' where lower(capture_date) like '%ago%'; -- 4734 rows, 106 msec
update sudoang.species_location set capture_month='01' where lower(capture_date) like '%inverno%'; -- 104 rows, 102 msec
update sudoang.species_location set capture_month='01' where lower(capture_date) like '%invierno%'; -- 94 rows, 81 msec
update sudoang.species_location set capture_month='07' where lower(capture_date) like '%jullho%'; -- 4 rows, 82 msec
update sudoang.species_location set capture_month='10' where lower(capture_date) like '%oct%'; -- 3916 rows, 132 msec
update sudoang.species_location set capture_month='05' where lower(capture_date) like '%prinavera%'; -- 3 rows, 104 msec
update sudoang.species_location set capture_month='02' where lower(capture_date) like '%feveiro%'; -- 2 rows, 99 msec

update sudoang.species_location set capture_month=month from 
(select 
       locationid,		
       case when char_length(dd::text)=1 then '0'||dd::text 
       else                        dd::text
       end as month from (
select locationid,extract(MONTH from capture_date::date)dd 
from sudoang.species_location 
where capture_date like '%/%' 
and char_length(capture_date)=10)sub)sub1
where sub1.locationid=species_location.locationid; -- 6055 rows, 579 msec


-- extract month from format 01/08/2003
update sudoang.species_location set capture_month=month from 
(select 
       locationid,		
       case when char_length(dd::text)=1 then '0'||dd::text 
       else                        dd::text
       end as month from (
select locationid,extract(MONTH from capture_date::date)dd 
from sudoang.species_location 
where capture_date like '%/%' 
and char_length(capture_date)=10)sub)sub1
where sub1.locationid=species_location.locationid; -- 6055 rows, 545 msec

-- extract month from format 08/2003
update sudoang.species_location set capture_month=month from 
(select 
       locationid,		
       case when char_length(dd::text)=1 then '0'||dd::text 
       else                        dd::text
       end as month from (
select locationid, capture_date, extract(MONTH from ('01/'||capture_date)::date)dd 
from sudoang.species_location 
where capture_date like '%/%' 
and char_length(capture_date)=7
)sub)sub1
where sub1.locationid=species_location.locationid; -- 89 rows, 63 msec

select locationid,capture_date from sudoang.species_location where capture_month IS NOT NULL order by capture_date;

-- select * from sudoang.species_location where capture_date='01/08/2010'

alter table sudoang.species_location add column capture_date_corrected date;

update sudoang.species_location set  capture_date_corrected=('01/'||capture_date)::date
where capture_date like '%/%' and char_length(capture_date)=7 -- 89 rows, 38 msec

update sudoang.species_location set  capture_date_corrected=capture_date::date
where capture_date like '%/%' and char_length(capture_date)=10; -- 5888 rows (Cedric) and 5883 rows (Maria)

update sudoang.species_location set  capture_date_corrected=('01/'||capture_month||'/'||capture_year)::date
 where capture_month is not null and capture_year is not null and capture_date_corrected is null; -- 50425 rows (Cedric) and 50424 rows (Maria)

select * from  sudoang.species_location where "ind/ha" is not null and capture_date_corrected is null; -- only pmar
/*
Maria found three locationid of eels where capture_date_corrected is null:
193974326
144945177
147293138
*/

/*
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' enero ', '/01/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Febrero ', '/02/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' febrero ', '/02/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Marzo ', '/03/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' marzo ', '/03/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Abril ', '/04/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' abril ', '/04/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Mayo ', '/05/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' mayo ', '/05/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Junio ', '/06/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' junio ', '/06/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Julio ', '/07/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' julio ', '/07/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Agosto ', '/08/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' agosto ', '/08/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' septiembre ', '/09/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Septiembre ', '/09/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' octubre ', '/10/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Octubre ', '/10/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' noviembre ', '/11/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Noviembre ', '/11/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' diciembre ', '/12/');
update sudoang.species_location set "capture_date"=regexp_replace("capture_date", ' Diciembre ', '/12/');
*/

-- View of Portuguese abundance level of eels
drop view if exists sudoang.portugal_abundance_level;
create view sudoang.portugal_abundance_level as (
select row_number() OVER (PARTITION BY true), stationdbeel.locationid,abundance_order, the_geom from sudoang.species_location 
JOIN sudoang.stationdbeel on stationdbeel.locationid=species_location.locationid
where country='PT' and codspecies='aang');


update sudoang.species_location set "capture_date"='01/08/'||capture_year 
where not (codspecies='pmar' and capture_date is null) and "capture_date" is NULL and capture_year is not null and capture_year !=0; -- 5 rows, 42 msec


/*
Pb converting ind/ha to numeric (it has already been stardardized in line 107)
*/

select * from sudoang.species_location where "ind/ha" like '% %'; -- 3 rows
update sudoang.species_location set "ind/ha" =regexp_replace("ind/ha", 'a', ''); -- 65132 rows affected, 834 msec
update sudoang.species_location set "ind/ha" =regexp_replace("ind/ha", ' ', ''); -- 65132 rows affected, 748 msec
select "ind/ha"::numeric from sudoang.species_location; --OK


/*
We need all operations including where no eels.
We created temp_pesca_electrica taking into account 19 methods from location (methods do not exist for Portugal data).
*/

create index idx_location_id on sudoang.species_location(locationid);
create index idx_locationid on sudoang.location(locationid);

-- select * from sudoang.location limit 10

drop table if exists sudoang.temp_pesca_electrica;
create table sudoang.temp_pesca_electrica as
select 
species_location.locationid,
capture_date,
capture_date_corrected,
capture_year,
capture_month,
codspecies,
"Time1" as time1,
"Time2" as time2,
"Time3" as time3,
"Run1" as run1,
"Run2" as run2,
"Run3" as run3,
length,
width,
"Area"::numeric as area,
"ind/ha"::numeric as indha,
hydrographic_basin_es,
methods
 from sudoang.species_location 
join sudoang.stationdbeel on stationdbeel.locationid=species_location.locationid
 where methods in 
(
	'electrofishing', 
	'Pesca eléctrico'
	'Pesc eléctrica',
	'Trasmallo y pesca eléctrica',
	'pesca eléctrica',
	'Pesca eléctrica, visual',
	'Pesca eléctrica y trasmallos.',
	'Pesca elétrica',
	'Pesca eléctrica, trasmallos.'
	'Pesca eléctrica.',
	'Pesca eléctrica y trasmallos',
	'Pesca con trasmallos y pesca eléctrica',
	'Pesca con trasmallos y pesca eléctrica.',
	'Trasmallos y pesca eléctrica.',
	'Pesca eléctrica, acotado',
	'Trasmallos y pesca eléctrica',
	'Trasmallos y pesca eléctrica',
	'Pesca eléctrica, trasmallos',
	'Pesca eléctrica'

	) and (
"Area" is not NULL OR "ind/ha" is not null) 
and not (codspecies='pmar' and capture_date is null); -- 14569 rows, 102 msec

select * from sudoang.species_location limit 10
-- Looking for the efficiency to calculate eel density by bassin
select round(run1::numeric/area/indha,2) as capturabilidad, capture_year, hydrographic_basin_es from sudoang.temp_pesca_electrica 
where indha is not null 
and area is not null 
and run1 is not null
and codspecies='aang'
order by hydrographic_basin_es;

select * from sudoang.temp_pesca_electrica limit 10;
select count(*), locationid from sudoang.temp_pesca_electrica group by locationid -- 4425 Ids
select count(*), codspecies from sudoang.temp_pesca_electrica group by codspecies -- 81 species


select * from sudoang.temp_pesca_electrica where run2 is not null;  -- 13 rows (no eel)
select * from sudoang.temp_pesca_electrica limit 200;


DROP TABLE if exists sudoang.electrofishing CASCADE;
SELECT * from dbeel.electrofishing limit 10;


/*-----------------------------------------------
FIRST CREATE AN EMPTY TABLE
-----------------------------------------------------*/
/*
ob_id UUID
ob_no_origin --11 electrofishing observation_origin => row data
ob_no_type  (period_type.no_id)   --22 
-----------------------------------------------------
no_id;no_code;no_type;no_name;obs_type_class_name
22;;Observation Type;Electro-fishing;Scientific Observation
----------------------------------------------------------
ob_no_period  --75 (daily) dans period_type
ob_starting_date date
ob_ending_date date
ob_op_id UUID observation place
ob_dp_id; -- dataprovider
ef_no_fishingmethod;            scientific_observation_method.no_id AS ef_no_fishingmethod,
ef_no_electrofishing_mean; 	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
ef_wetted_area;
ef_fished_length;
ef_fished_width;
ef_duration;
ef_nbpas
*/
/*
runonce
ALTER TABLE sudoang.electrofishing add constraint fk_oo_op_id FOREIGN KEY (ob_op_id)	
		REFERENCES sudoang.stationdbeel (op_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE
*/


CREATE TABLE sudoang.electrofishing (
	locationid integer,
	capture_date text,	
	--LIKE ireland.survey INCLUDING DEFAULTS INCLUDING CONSTRAINTS,
	CONSTRAINT pk_oo_ob_id PRIMARY KEY (ob_id),
	CONSTRAINT fk_oo_op_id FOREIGN KEY (ob_op_id)	
		REFERENCES sudoang.stationdbeel (op_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_oo_dp_id FOREIGN KEY (ob_dp_id)	
		REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_electrofishing_mean FOREIGN KEY (ef_no_electrofishing_mean)
		REFERENCES dbeel_nomenclature.electrofishing_mean (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_electrofishing_method FOREIGN KEY (ef_no_fishingmethod)
		REFERENCES dbeel_nomenclature.scientific_observation_method (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_ob_no_origin FOREIGN KEY (ob_no_origin)
		REFERENCES dbeel_nomenclature.observation_origin (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_ob_no_period FOREIGN KEY (ob_no_period)
		REFERENCES dbeel_nomenclature.period_type (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_oo_ob_no_type FOREIGN KEY (ob_no_type)
		REFERENCES dbeel_nomenclature.observation_type (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.electrofishing);

-----------------------------
-- I electrofishing 
----------------------------

/*
For the moment we set the type of electrofishing to unknown (61), later for some fishing we with use whole (62)
*/
select * from sudoang.dbeel_station limit 10;
select * from sudoang.stationdbeel limit 10;

DELETE FROM sudoang.electrofishing;
INSERT INTO sudoang.electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_duration,
	ef_nbpas,
	ob_op_id,
	locationid,
	capture_date
	)
	SELECT 
	distinct on (locationid,capture_date_corrected)
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	capture_date_corrected AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	area AS ef_wetted_area, 
	length AS ef_fished_length,
	width AS ef_fished_width,
	time1+coalesce(time2,0) AS ef_duration,
	case when run3 is not null then 3
	     when run2 is not null then 2 
	     when run1 is not null then 1 
	     else null 
	     end AS ef_nbpas,	     
	op.op_id as ob_op_id,
	op.locationid as locationid, -- locationid coming from sudoang.stationdbeel
	capture_date as capture_date -- date as text (original format)
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.stationdbeel as op
	join
		sudoang.temp_pesca_electrica on temp_pesca_electrica.locationid=op.locationid
		
			
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Rafael Miranda Ferreiro'
	AND capture_date_corrected is not null
	; -- 5734 rows, 8.6 secs

select count(*) from sudoang.electrofishing where ob_starting_date is null; --7

/*
Tableau pour voir les sites avec et sans anguilles
*/
create table sudoang.locationid_sibic_eels as
(select distinct e.locationid, x, y, the_geom from sudoang.dbeel_station d join sudoang.dbeel_electrofishing e on ob_op_id=op_id 
where e.locationid in (
select locationid 
from  sudoang.temp_pesca_electrica 
where codspecies='aang')); -- 1075 locationid with eels

create table sudoang.locationid_sibic_no_eels as
(select distinct e.locationid, x, y, the_geom from sudoang.dbeel_station d join sudoang.dbeel_electrofishing e on ob_op_id=op_id 
where e.locationid not in (
select locationid 
from  sudoang.temp_pesca_electrica 
where codspecies='aang')); -- 3350 locationid without eels


	
-- NUMBER PER PASS... AND TOTAL NUMBER
-- BATCH INTEGRATION

/*
select * from sudoang.electrofishing limit 10;
select * from sudoang.temp_pesca_electrica limit 100;
*/

/*
Adding identifiers from the dbeel into source table
*/
alter table sudoang.temp_pesca_electrica add column id serial primary key;
alter table sudoang.temp_pesca_electrica add column op_id uuid;
alter table sudoang.temp_pesca_electrica add column ob_id uuid;

update sudoang.temp_pesca_electrica set(op_id, ob_id)=(sub.ob_op_id, sub.ob_id) from (
	select id,ee.ob_op_id, ee.ob_id from sudoang.temp_pesca_electrica pe 
	join sudoang.electrofishing ee 
	on (pe.locationid,pe.capture_date_corrected) = (ee.locationid,ee.ob_starting_date)) sub
where temp_pesca_electrica.id=sub.id;

/* runonce
ALTER TABLE sudoang.temp_pesca_electrica add constraint fk_ob_id FOREIGN KEY (ob_id) 
		REFERENCES sudoang.electrofishing (ob_id) 
		ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE sudoang.temp_pesca_electrica add constraint fk_op_id FOREIGN KEY (op_id) 
		REFERENCES sudoang.stationdbeel (op_id) 
		ON DELETE CASCADE ON UPDATE CASCADE;	
*/

/* 
Some of the lines have no op_id or ob_id, it is because they were not integrated in electrofishing table,
We are happy with that.
*/


-- select * from dbeel.batch limit 10 
/* runonce
ALTER TABLE sudoang.batch_ope add constraint fk_batch_ope_ba_ob_id FOREIGN KEY (ba_ob_id) 
		REFERENCES sudoang.electrofishing (ob_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
*/


DROP TABLE if exists sudoang.batch_ope CASCADE;
CREATE TABLE sudoang.batch_ope (
		locationid integer,
	CONSTRAINT pk_batch_ba_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_batch_ope_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_batch_ope_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_batch_ope_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_batch_ope_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,			
	CONSTRAINT fk_batch_ope_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT c_fk_ba_ob_id FOREIGN KEY (ba_ob_id) 
		REFERENCES sudoang.electrofishing (ob_id) 
		ON DELETE CASCADE ON UPDATE CASCADE;
		-- here I'm not putting any restriction concerning parent table within sudoang
		-- Perhaps we will need them later but currently the information is not well structured anyways
		) INHERITS (dbeel.batch);

-- select * from sudoang.batch_ope;
-- select coalesce(run1,0)+coalesce(run2,0)+coalesce(run3,0) from sudoang.temp_pesca_electrica where locationid=-2102599566

/*
alter table sudoang.batch_ope add constraint c_fk_ba_ob_id FOREIGN KEY (ba_ob_id) 
		REFERENCES sudoang.electrofishing (ob_id) 
		ON DELETE CASCADE ON UPDATE CASCADE;
*/
/*-----------------------------------------------
Two cases, first the operation contains an eel then we select it
	   second there are no eels, 
           this means that "and locationid not in (select locationid from anguila)"
           we are not in the first case
           We also select places where ob_id is null because some operations code could not be 
           generated in the table temp_pesca_electrica as there were missing dates
---------------------------------------------------------------------------------------------------*/


with anguila as (
select ob_id,
locationid,
coalesce(run1,0),
coalesce(run2,0),
coalesce(run3,0),
round(coalesce(indha/10000,0),3) AS density
from sudoang.temp_pesca_electrica 
where codspecies='aang' and ob_id is not null),
other as (
select distinct on (ob_id)
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.temp_pesca_electrica 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null)
select * from anguila 
union
select * from other 
order by locationid; -- 5579 rows

-- select * from sudoang.electrofishing e join sudoang.survey s on e.surveyid=s.surveyid


-- number per pass and total number are  
-- referenced by biological_characteristic_type.no_name='Number' (see biological_characteristic_type.no_id=47)


with anguila as (
select ob_id,
locationid,
coalesce(run1,0) as run1,
coalesce(run2,0) as run2,
coalesce(run3,0) as run3,
round(coalesce(indha/10000,0),3) AS density
from sudoang.temp_pesca_electrica 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.temp_pesca_electrica 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO sudoang.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.run1+electrofishing.run2+electrofishing.run3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM 
        electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status        
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 5579 rows

-- op_p1 (this batch is of level 2, 1 is total number, the pass is identified by the number in pa_numero)
-- I kept this as in the first version of the dbeel there was not number_p1 the new version corrects this
-- also referenced by biological_characteristic_type.no_name='Number p1' (i.e. biological_characteristic_type.no_id=231)
with anguila as (
select ob_id,
locationid,
coalesce(run1,0) as run1,
coalesce(run2,0) as run2,
coalesce(run3,0) as run3,
round(coalesce(indha/10000,0),3) AS density
from sudoang.temp_pesca_electrica 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.temp_pesca_electrica 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO sudoang.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM 
	electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 5579 rows

-- op_p2
with anguila as (
select ob_id,
locationid,
coalesce(run1,0) as run1,
coalesce(run2,0) as run2,
coalesce(run3,0) as run3,
round(coalesce(indha/10000,0),3) AS density
from sudoang.temp_pesca_electrica 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.temp_pesca_electrica 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO sudoang.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	3 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM 
	electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 5579 rows


/*  Example of one locationid
select * from sudoang.batch_ope where locationid=-382286476;
select * from sudoang.temp_pesca_electrica where locationid=-382286476;	-- There are 3 pass but only run1 has data
select count(*) from sudoang.temp_pesca_electrica where codspecies='aang'; --1273

select * from ireland.batch_ope where op_locationcode=1936 and op_surveyid=1892; -- Looking how works in Ireland
*/

-- op_p3
with anguila as (
select ob_id,
locationid,
coalesce(run1,0) as run1,
coalesce(run2,0) as run2,
coalesce(run3,0) as run3,
round(coalesce(indha/10000,0),3) AS density
from sudoang.temp_pesca_electrica 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.temp_pesca_electrica 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO sudoang.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.run3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM 
	electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 5579 rows

-- In SIBIC table there aren't op_p4 and op_p5
	
-- Densities as below are also calculated later but still I integrate them here
-- referenced by biological_characteristic_type.no_name='density' and the corresponding biological_characteristic_type.no_id
with anguila as (
select ob_id,
locationid,
coalesce(run1,0) as run1,
coalesce(run2,0) as run2,
coalesce(run3,0) as run3,
round(coalesce(indha/10000,0),3) AS density
from sudoang.temp_pesca_electrica 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.temp_pesca_electrica 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO sudoang.batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM
	electrofishing, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 5579 rows


/*----------------------------------------------------
INTEGRATING MISSING DATA OF SIBIC (mostly about size)

1. EBRO (from Ebro Datos IBI.xls):
	"place_classification" corresponds to the operation, not station, but only 3 rows are duplicated:
		SELECT count(*) FROM sudoang.ebro_location; -- 369 rows
		SELECT count(distinct geom) FROM sudoang.ebro_location; -- 366 rows

	We have to include missing information about:
	-- ebro_location:	"Longitud..m." = mean length of station (as "ef_fished_length") 
				"Anchura.media..m." = mean width of station (as "ef_fished_width")
		SELECT * FROM sudoang.ebro_location where place_classification='(IBI011)'; -- 54 m length and 6.3 m width but NOT "locationid"
		SELECT * FROM sudoang.stationdbeel where place_classification='(IBI033)';  -- locationid = 258166863
		SELECT * FROM sudoang.dbeel_electrofishing where locationid = '258166863'; -- no length no width
	But "Area (m2)" = Surface is included in the SIBIC db!

SELECT * FROM sudoang.stationdbeel where place_classification like '(JU08210015-RB161)' -- locationid = 2114742390
SELECT * FROM sudoang.electrofishing where locationid = '2114742390'; -- no length no width

	-- ebro_ope: nothing to import, only infomrative
			"num_inv_totales" as "run1" in SIBIC (there is no nb of pass)
			"num_ind_medidos" = nb of sampled fishes (not included but we don't need?)
			"Densidad..ind.ha." = density as "ind/ha" in SIBIC
		SELECT * FROM sudoang.ebro_ope where place_classification='(IBI011)'; 		-- "Especie" but not codspecies
		SELECT * FROM sudoang.temp_pesca_electrica where locationid = '258166863'; 	-- "codspecies" but not the name of species
		SELECT * FROM sudoang.species_location where locationid = '258166863';		-- "codspecies" but not the name of species
		SELECT * FROM sudoang.dbeel_batch_ope where locationid = '-777537002';		-- "codspecies" but not the name of species

		
	-- ebro_fish:	"LF..mm." = fork length (mm)
			"Peso..gr." = weight (gr)
		SELECT * FROM sudoang.ebro_fish where place_classification='(IBI033)';
		SELECT * FROM sudoang.temp_pesca_electrica where locationid = '258166863';
-----------------------------------------------------------------------------------------------------------------------------------------------*/	

-- We need a previous step (before insert length and width of stations) since ebro_location has "place_classification" and 
-- electrofishing has "locationid". Using stationdbeel, we update ebro_location with the corresponding "locationid"
alter table sudoang.ebro_location add column locationid integer;

UPDATE sudoang.ebro_location b
SET locationid = a.locationid
FROM sudoang.stationdbeel a
WHERE a.place_classification = b.place_classification; -- 350 rows, 24 msec (There are 16 codes missing)

update sudoang.electrofishing
set (ef_fished_length,ef_fished_width) = ("Longitud (m)","Anchura media (m)") from 
	sudoang.ebro_location WHERE ebro_location.locationid = electrofishing.locationid; -- 302 rows


-- Before insert length and width of fish, we need: 
--	"fish_id"
--	"locationid"
--	"place_classification"
--	"codspecies" (ebro_fish has the name of species but not the code)
-- 	"ob_id"
-- In different queries since there aren't tables with all parameters together

alter table sudoang.ebro_fish add column fish_id serial;

alter table sudoang.ebro_fish add column locationid integer;
UPDATE sudoang.ebro_fish b
SET locationid = a.locationid
FROM sudoang.stationdbeel a
WHERE a.place_classification = b.place_classification; -- 21484 rows (total rows: 21504)

alter table sudoang.ebro_fish add column codspecies text;
UPDATE sudoang.ebro_fish set codspecies = 'aang' where "Especie" = 'Anguilla anguilla'; -- 170 rows
UPDATE sudoang.ebro_fish set codspecies = 'oth' where "Especie" != 'Anguilla anguilla'; -- 21334 rows

alter table sudoang.ebro_fish add column ob_id uuid;
UPDATE sudoang.ebro_fish b
SET ob_id = a.ob_id
FROM sudoang.electrofishing a
WHERE a.locationid = b.locationid; -- 21298 rows (total rows: 21504)


-- Batch integration, the second level will reference the fish table

DROP TABLE if exists sudoang.batch_fish CASCADE;
CREATE TABLE sudoang.batch_fish (
	fish_id integer,
	locationid integer, 
	place_classification text,
	CONSTRAINT pk_fish_fi_id PRIMARY KEY (ba_id),
	CONSTRAINT fk_fish_fi_ba_no_species_id FOREIGN KEY (ba_no_species) 
		REFERENCES dbeel_nomenclature.species (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_fish_fi_ba_no_stage_id FOREIGN KEY (ba_no_stage) 
		REFERENCES dbeel_nomenclature.stage (no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_fish_fi_ba_value_type FOREIGN KEY (ba_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,	
	CONSTRAINT fk_fish_fi_ba_no_biological_characteristic_type 	FOREIGN KEY (ba_no_biological_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id)
		ON DELETE RESTRICT ON UPDATE CASCADE,			
	CONSTRAINT fk_fish_fi_ba_no_individual_status FOREIGN KEY (ba_no_individual_status)
		REFERENCES dbeel_nomenclature.individual_status(no_id) 
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT c_fk_fi_ob_id FOREIGN KEY (ba_ob_id) 
		REFERENCES sudoang.electrofishing (ob_id) 
		ON DELETE CASCADE ON UPDATE CASCADE
		) INHERITS (dbeel.batch);


with anguila as (
select fish_id,
locationid,
place_classification,
ob_id,
coalesce("LF..mm.",0) as length,
coalesce("Peso..gr.",0) as weight
from sudoang.ebro_fish 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
fish_id,
locationid,
place_classification,
ob_id,
0 as length,
0 as weight
from sudoang.ebro_fish 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

sample as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO sudoang.batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	sample.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	sample.fish_id,        
	sample.locationid,
	sample.place_classification
	FROM 
	sample,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; -- 454 rows


-- To integrate length and weight of fish, we need the "ba_id" that corresponds to the batch (each line must be different) 
alter table sudoang.ebro_fish add column ba_id uuid;

UPDATE sudoang.ebro_fish b
SET ba_id = a.ba_id
FROM sudoang.batch_fish a
WHERE a.fish_id = b.fish_id; -- 21298 rows (total rows: 21504)

DROP TABLE if exists sudoang.mensurationindiv_biol_charac CASCADE;
CREATE TABLE sudoang.mensurationindiv_biol_charac  (
	fish_id integer,
	locationid integer, 
	place_classification text,
	CONSTRAINT pk_mensindivbiocho_id PRIMARY KEY (bc_id),
	CONSTRAINT fk_mensindivbiocho_bc_characteristic_type FOREIGN KEY (bc_no_characteristic_type)
		REFERENCES dbeel_nomenclature.biological_characteristic_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_value_type FOREIGN KEY (bc_no_value_type)
		REFERENCES dbeel_nomenclature.value_type (no_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_mensindivbiocho_bc_ba_id FOREIGN KEY (bc_ba_id)
		REFERENCES sudoang.dbeel_batch_fish (ba_id) ON DELETE CASCADE ON UPDATE CASCADE

)INHERITS (dbeel.biological_characteristic);

select * from dbeel.biological_characteristic limit 10;

-- Insert WEIGHT (gr)
INSERT INTO sudoang.mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	"Peso..gr." AS bc_numvalue,
	fish_id,
	locationid, 
	place_classification
	FROM sudoang.ebro_fish, 
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE "Peso..gr.">0 
	AND codspecies='aang' 
	AND ob_id is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 170 rows

-- Insert LENGTH (mm)
INSERT INTO sudoang.mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	"LF..mm." AS bc_numvalue,
	fish_id,
	locationid, 
	place_classification
	FROM sudoang.ebro_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE "LF..mm.">0
	AND codspecies='aang' 
	AND ob_id is not null
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 170 rows

-- Insert SEX: for this table, the sex is missing!
select count(*) from sudoang.ebro_fish where codspecies='aang' and "Sexo" = ''; -- 170 rows

INSERT INTO sudoang.mensurationindiv_biol_charac
	SELECT 	uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	CASE when ebro_fish."Sexo" = 'not recorded' then 180
	when ebro_fish."Sexo" ='M' then 181
	when ebro_fish."Sexo" ='F' then 182
	when ebro_fish."Sexo" ='unknown' then 183 -- unidentified
	ELSE null
	END  as bc_numvalue
	FROM sudoang.ebro_fish,
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE "Sexo" IS NOT NULL 
	AND codspecies='aang'
	AND "Sexo" !=''
	AND biological_characteristic_type.no_name = 'Sex' 
	AND value_type.no_name = 'Raw data or Individual data'; -- 0 lines


/*----------------------------------------------------
INTEGRATING MISSING DATA OF SIBIC (mostly about size)

2. North of Spain (from NSp_EFIplus.mdb):
-----------------------------------------------------------
	"place_classification" corresponds to the station:
		SELECT * FROM sudoang.nsp_efiplus_location where locationid = -2061689289;
		SELECT count(*) FROM sudoang.nsp_efiplus_location; -- 1848 rows
		SELECT count(distinct geom) FROM sudoang.nsp_efiplus_location; -- 1848 rows
		SELECT count(distinct place_classification) FROM sudoang.nsp_efiplus_location; -- 1848 rows

	We have to include missing information about:
	-- nsp_efiplus_location:	"locality_length" = length of station (as "ef_fished_length") 
					"locality_width" = width of station (as "ef_fished_width")
		SELECT * FROM sudoang.nsp_efiplus_location where place_classification='(ES_35_0008)'; 	-- 53m length and 13.8m width but NOT "locationid"
		SELECT * FROM sudoang.dbeel_station where place_classification='(ES_35_0008)';  	-- locationid = -1823349679
		SELECT * FROM sudoang.dbeel_electrofishing where locationid = '1952416621'; 		-- no length no width
	But "fished_area" = Surface is included in the SIBIC db!

	-- nsp_efiplus_ope:	"Catch_id"
				"run_1" as "run1" in SIBIC
				"run_2"
				"run_3"
				"run_4"
				"total_nb" = total nb of fishes (do we need to include?)
				"total_abundance" = as "ind/ha" in SIBIC (but is it the real density? I don't know how they estimate it)
				"estimated_efficiency" (do we need to include?)
		SELECT * FROM sudoang.nsp_efiplus_ope limit 10;
		SELECT * FROM sudoang.nsp_efiplus_ope where place_classification='(ES_35_0440)';	-- "Species" but not codspecies
		SELECT * FROM sudoang.dbeel_electrofishing where locationid = '1952416621'; 		-- "codspecies" but not the name of species
		SELECT * FROM sudoang.temp_pesca_electrica where locationid = '1952416621';
		SELECT * FROM sudoang.dbeel_batch_ope where locationid = '-2061689289';
		SELECT count(distinct "Catch_id") FROM sudoang.nsp_efiplus_ope; 			-- 4210 rows that corresponds to "Batch ID" (dbeel) and 1837 rows for locationid
		
	-- nsp_efiplus_fish:	"lenth_id" = id of individual
				"total_length" = length
				"run" = nb pass when fish was caught (do we need to include?)
		SELECT * FROM sudoang.nsp_efiplus_fish limit 10;
		SELECT * FROM sudoang.nsp_efiplus_fish where place_classification='(ES_35_0008)';
		SELECT * FROM sudoang.temp_pesca_electrica where locationid = '1952416621';
-----------------------------------------------------------------------------------------------------------------------------------------------*/	
-- We need a previous step (before insert length and width of stations) since nsp_efiplus_location has "place_classification" and 
-- dbeel_electrofishing has "locationid". Using dbeel_station, we update nsp_efiplus_location with the corresponding "locationid"
alter table sudoang.nsp_efiplus_location add column locationid integer;

UPDATE sudoang.nsp_efiplus_location b
SET locationid = a.locationid
FROM sudoang.dbeel_station a
WHERE a.place_classification = b.place_classification; -- 1848 rows, 67 msec

update sudoang.dbeel_electrofishing
set (ef_fished_length,ef_fished_width) = (locality_length,locality_width) from 
	sudoang.nsp_efiplus_location WHERE nsp_efiplus_location.locationid = dbeel_electrofishing.locationid; -- 1836 rows (12 rows missing?)

-- Before insert length of fish, we need: 
--	"locationid"
--	"codspecies" (nsp_efiplus_ope has the name of species but not the code)
-- 	"ob_id"
-- In different queries since there aren't tables with all parameters together

alter table sudoang.nsp_efiplus_ope add column locationid integer;
UPDATE sudoang.nsp_efiplus_ope b
SET locationid = a.locationid
FROM sudoang.dbeel_station a
WHERE a.place_classification = b.place_classification; -- 4210 rows

alter table sudoang.nsp_efiplus_ope add column codspecies text;
UPDATE sudoang.nsp_efiplus_ope set codspecies = 'aang' where "Species" = 'Anguilla anguilla'; -- 681 rows
UPDATE sudoang.nsp_efiplus_ope set codspecies = 'oth' where "Species" != 'Anguilla anguilla'; -- 3529 rows

alter table sudoang.nsp_efiplus_ope add column ob_id uuid;
UPDATE sudoang.nsp_efiplus_ope b
SET ob_id = a.ob_id
FROM sudoang.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 4208 rows (total rows: 4210)
 

-- op_p1
begin;
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

join_electro as (select ba_id, electro.* from electro join sudoang.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 231) 

update sudoang.dbeel_batch_ope 
set ba_quantity = run1 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 1839 rows
commit;


-- op_p2
begin;
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

-- select * from electro order by locationid --1836 rows
join_electro as (select ba_id, electro.* from electro join sudoang.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 232) 

update sudoang.dbeel_batch_ope 
set ba_quantity = run2 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 1839 rows
commit;

-- select count(*) from sudoang.dbeel_batch_ope where locationid in (select distinct locationid from sudoang.nsp_efiplus_ope); --9180
-- select * from electro where locationid = '1952416621';
-- select * from sudoang.dbeel_batch_ope where dbeel_batch_ope.locationid = '1952416621' and ba_no_biological_characteristic_type = 232;


-- op_p3
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

join_electro as (select ba_id, electro.* from electro join sudoang.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 233) 

update sudoang.dbeel_batch_ope 
set ba_quantity = run3 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 1839 rows


-- op_p4
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

join_electro as (select ba_id, electro.* from electro join sudoang.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 234) 

update sudoang.dbeel_batch_ope 
set ba_quantity = run4 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 0 rows


-- total_number
begin;
with anguila as (
select 
ob_id,
locationid,
place_classification,
case when run_1 = -999 then 0 
	else coalesce(run_1,0) end as run1,
case when run_2 = -999 then 0 
	else coalesce(run_2,0) end as run2,
case when run_3 = -999 then 0 
	else coalesce(run_3,0) end as run3,
case when run_4 = -999 then 0 
	else coalesce(run_4,0) end as run4,
case when total_nb = -999 then 0 
	else coalesce(total_nb,0) end as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on (ob_id)
ob_id,
locationid,
place_classification,
0 as run1,
0 as run2,
0 as run3,
0 as run4,
0 as total_nb
from sudoang.nsp_efiplus_ope 
where codspecies='oth'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electro as (select * from anguila 
union
select * from other 
order by locationid),

join_electro as (select ba_id, electro.* from electro join sudoang.dbeel_batch_ope on dbeel_batch_ope.locationid = electro.locationid
where ba_no_biological_characteristic_type = 47) 

update sudoang.dbeel_batch_ope 
set ba_quantity = total_nb 
	from join_electro where dbeel_batch_ope.ba_id = join_electro.ba_id;
-- 1839 rows
commit;


-- Density
-- Before calculate the density, "fished_area" should be included in the nsp_efiplus_batch_ope table:
alter table sudoang.nsp_efiplus_ope add column fished_area integer;
UPDATE sudoang.nsp_efiplus_ope b
SET fished_area = a.fished_area
FROM sudoang.nsp_efiplus_location a
WHERE a.locationid = b.locationid; -- 4210 rows

-- Calculate eel density by bassin
begin;
with anguila as (
select ob_id,
locationid,
place_classification,
round(coalesce(total_nb::numeric/fished_area,0),3) as density -- TO DO: should it be "10000*total_nb::numeric/fished_area" ha?
from sudoang.nsp_efiplus_ope 
where codspecies='aang' and ob_id is not null and total_nb is not null and fished_area is not null),

-- select distinct locationid from sudoang.nsp_efiplus_ope 
--	where codspecies='oth' and locationid not in (select locationid from sudoang.nsp_efiplus_ope where codspecies='aang'); -- 1156 rows

join_anguila as (select ba_id, anguila.* from anguila join sudoang.dbeel_batch_ope on dbeel_batch_ope.locationid = anguila.locationid
where ba_no_biological_characteristic_type = 48) 

update sudoang.dbeel_batch_ope 
set ba_quantity = density 
	from join_anguila where dbeel_batch_ope.ba_id = join_anguila.ba_id;
-- 680 rows
commit;


-- Before insert length of fish, we need: 
--	"locationid"
--	"codspecies" (ebro_fish has the name of species but not the code)
-- 	"ob_id"
-- In different queries since there aren't tables with all parameters together

-- Rename the id of fish
alter table sudoang.nsp_efiplus_fish rename column lenth_id to fish_id;

alter table sudoang.nsp_efiplus_fish add column locationid integer;
UPDATE sudoang.nsp_efiplus_fish b
SET locationid = a.locationid
FROM sudoang.dbeel_station a
WHERE a.place_classification = b.place_classification; -- 163010 rows

alter table sudoang.nsp_efiplus_fish add column codspecies text;
UPDATE sudoang.nsp_efiplus_fish set codspecies = 'aang' where species = 'Anguilla anguilla'; -- 9029 rows
UPDATE sudoang.nsp_efiplus_fish set codspecies = 'oth' where species != 'Anguilla anguilla'; -- 153981 rows

alter table sudoang.nsp_efiplus_fish add column ob_id uuid;
UPDATE sudoang.nsp_efiplus_fish b
SET ob_id = a.ob_id
FROM sudoang.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 162971 rows (39 rows are missing)

-- Insert into dbeel_batch_fish the individuals which were caught
-- select count(*) from sudoang.nsp_efiplus_fish where codspecies='aang' and ob_id is not null -- 9028
-- select sum(total_nb) from sudoang.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null -- 9028 rows
with count_fish as
(select count(*) as count_fish, ob_id as ob_id_fish from sudoang.nsp_efiplus_fish where codspecies='aang' and ob_id is not null group by ob_id), -- 468 rows
count_ope as 
(select sum(total_nb) as count_ope, ob_id as ob_id_ope from sudoang.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null
	 group by ob_id), -- 680 rows
differents as 
(select * from count_fish full outer join count_ope on count_fish.ob_id_fish = count_ope.ob_id_ope
	where (count_fish != count_ope or count_ope is null or count_fish is null))
select * from differents;--sudoang.nsp_efiplus_fish where ob_id in (select ob_id from differents) and codspecies='aang';

-- There are three cases to correct:
-- 	1. In nsp_efiplus_ope "Fishlength" = 'No' when ob_id is null in nsp_efiplus_fish (77 ob_id not found in count_fish (= 1046 eels counted but not measured))
begin;
with anguila as
(select ob_id as ob_id_ang, locationid from sudoang.nsp_efiplus_fish where codspecies='aang' and ob_id is not null), -- 9028 rows
ope as 
(select ob_id as ob_id_ope, locationid from sudoang.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null), -- 464 rows
differents as 
(select * from anguila full outer join ope on anguila.ob_id_ang = ope.ob_id_ope where 
	(anguila != ope or ope is null or anguila is null))
--select * from differents; -- 78 rows
update sudoang.nsp_efiplus_ope set "Fishlength" = 'No' 
	from differents where nsp_efiplus_ope.ob_id = differents.ob_id_ope; -- 255 rows
commit;

-- 	2. (UPDATE) In nsp_efiplus_ope add nb of fish that are measured but not counted (10 ob_id = 381 eels measured but not counted)
-- select * from sudoang.nsp_efiplus_ope where ob_id = 'b0c62cd0-a5c5-4bd8-b6f6-641645f66a4a' and codspecies = 'aang';  -- 35 eel counted
-- select * from sudoang.nsp_efiplus_fish where ob_id = 'b0c62cd0-a5c5-4bd8-b6f6-641645f66a4a' and codspecies = 'aang'; -- 68 eels measured
begin;
with count_fish as
(select count(*) as count_fish, ob_id as ob_id_fish 
	from sudoang.nsp_efiplus_fish where codspecies='aang' and ob_id is not null group by ob_id), -- 468 rows
count_fish_run1 as 
(select count(*) as run1, ob_id as ob_id_fish 
	from sudoang.nsp_efiplus_fish where run = '1' and codspecies='aang' and ob_id is not null group by ob_id),
count_fish_run2 as 
(select count(*) as run2, ob_id as ob_id_fish 
	from sudoang.nsp_efiplus_fish where run = '2' and codspecies='aang' and ob_id is not null group by ob_id),
count_fish_run3 as 
(select count(*) as run3, ob_id as ob_id_fish 
	from sudoang.nsp_efiplus_fish where run = '3' and codspecies='aang' and ob_id is not null group by ob_id),
count_ope as 
(select sum(total_nb) as count_ope, ob_id as ob_id_ope from sudoang.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null
	 group by ob_id), -- 680 rows
differents as 
(select count_fish, count_ope, run1, run2, run3, ob_id_ope from count_fish full outer join count_ope on count_fish.ob_id_fish = count_ope.ob_id_ope
	left join count_fish_run1 on count_fish_run1.ob_id_fish = count_ope.ob_id_ope 
	left join count_fish_run2 on count_fish_run2.ob_id_fish = count_ope.ob_id_ope
	left join count_fish_run3 on count_fish_run3.ob_id_fish = count_ope.ob_id_ope
	where (count_fish != count_ope or count_ope is null or count_fish is null))
--select * from differents; -- 8 rows
update sudoang.nsp_efiplus_ope set (total_nb, run_1, run_2, run_3) = (count_fish, run1, run2, run3) 
	from differents where differents.ob_id_ope = nsp_efiplus_ope.ob_id; -- 48 rows
commit;

-- 	3. (INSERT INTO) In nsp_efiplus_ope add 4 ob_id (= 56 eels) that don't exist
-- select * from sudoang.nsp_efiplus_ope where ob_id = '7aa31e13-d193-41a6-b9ee-52f3ac7afd2e' and codspecies = 'aang';  -- 0 eel counted
-- select * from sudoang.nsp_efiplus_fish where ob_id = '7aa31e13-d193-41a6-b9ee-52f3ac7afd2e' and codspecies = 'aang'; -- 3 eels measured
with count_fish as
(select count(*) as count_fish, ob_id as ob_id_fish, site_code, "Date", species, place_classification, locationid, codspecies
	from sudoang.nsp_efiplus_fish where codspecies='aang' and ob_id is not null 
	group by ob_id, site_code, "Date", species, place_classification, locationid, codspecies), -- 468 rows
count_fish_run1 as 
(select count(*) as run1, ob_id as ob_id_fish, site_code, "Date", species, place_classification, locationid, codspecies 
	from sudoang.nsp_efiplus_fish where run = '1' and codspecies='aang' and ob_id is not null 
	group by ob_id, site_code, "Date", species, place_classification, locationid, codspecies),
count_fish_run2 as 
(select count(*) as run2, ob_id as ob_id_fish, site_code, "Date", species, place_classification, locationid, codspecies 
	from sudoang.nsp_efiplus_fish where run = '2' and codspecies='aang' and ob_id is not null 
	group by ob_id, site_code, "Date", species, place_classification, locationid, codspecies),
count_fish_run3 as 
(select count(*) as run3, ob_id as ob_id_fish 
	from sudoang.nsp_efiplus_fish where run = '3' and codspecies='aang' and ob_id is not null group by ob_id),
count_ope as 
(select sum(total_nb) as count_ope, ob_id as ob_id_ope 
	from sudoang.nsp_efiplus_ope where codspecies='aang' and "Fishlength" = 'Yes' and ob_id is not null group by ob_id),
anguila as 
--(select * from count_fish_run1 full outer join count_ope on count_fish_run1.ob_id_fish = count_ope.ob_id_ope where count_ope is null)
(select count_fish.*, run1, run2, run3 from count_fish
	left join count_fish_run1 on count_fish_run1.ob_id_fish = count_fish.ob_id_fish 
	left join count_fish_run2 on count_fish_run2.ob_id_fish = count_fish.ob_id_fish
	left join count_fish_run3 on count_fish_run3.ob_id_fish = count_fish.ob_id_fish
	where count_fish_run1.ob_id_fish not in (select ob_id_ope from count_ope))
--select * from anguila; -- 4 rows
INSERT INTO sudoang.nsp_efiplus_ope(
	site_code, "Date", "Species", run_1, run_2, run_3, total_nb, "Fishlength", place_classification, locationid, codspecies, ob_id)
	SELECT anguila.site_code,
	anguila."Date",
	anguila.species as "Species",
	anguila.run1 AS run_1,
	anguila.run2 AS run_2,
	anguila.run3 AS run_3,
	anguila.count_fish AS total_nb,
	'Yes' as "Fishlength",
	anguila.place_classification,
	anguila.locationid,
	anguila.codspecies,
	anguila.ob_id_fish as ob_id
	FROM anguila; -- 4 rows


-- Insert individuals that were measured into the dbeel_batch_fish
begin;
with anguila as (
select fish_id,
locationid,
place_classification,
ob_id,
coalesce(total_length,0) as length
from sudoang.nsp_efiplus_fish 
where codspecies='aang' and ob_id is not null)

INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id,		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	anguila.locationid,
	anguila.place_classification
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; -- 9028 rows
commit;

-- To integrate length and weight of fish, "ba_id" must be included before 
alter table sudoang.nsp_efiplus_fish add column ba_id uuid;
begin;
UPDATE sudoang.nsp_efiplus_fish b
SET ba_id = a.ba_id
FROM sudoang.dbeel_batch_fish a
WHERE (a.fish_id, a.locationid) = (b.fish_id, b.locationid); -- 9028 rows
commit;



ALTER TABLE sudoang.mensurationindiv_biol_charac RENAME TO dbeel_mensurationindiv_biol_charac;
-- Insert LENGTH (mm)
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	total_length AS bc_numvalue,
	fish_id,
	locationid, 
	place_classification
	FROM sudoang.nsp_efiplus_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE total_length >0
	AND codspecies='aang' 
	AND ob_id is not null
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 9028 rows
commit;

/*----------------------------------------------------
INTEGRATING MISSING DATA OF SIBIC (mostly about size)

2. Levante PECES_2011:
	There aren't the coordinates of the stations in levante_location, but there are included in the sibic database!
	We have to include missing information about:
	-- levante_location:	"LONG_TRAMO" = length of station (as "ef_fished_length") 
				"ANCH_TRAMO" = width of station (as "ef_fished_width")
				"SUP_MUESTREADA" = surface of station (as "ef_wetted_area")
	But "fished_area" = Surface is included in the SIBIC db!

	-- levante_ope:		"NINDIVIDUOS" = run1 and total number
				"SUP_MUESTREADA" = surface of station (it must be included in levante_ope)
		
	-- levante_fish:
-----------------------------------------------------------------------------------------------------------------------------------------------*/	
-- Location in levante_location: don't necessary because there is place_classification
alter table sudoang.levante_location add column locationid integer;

UPDATE sudoang.levante_location b
SET locationid = a.locationid
FROM sudoang.dbeel_station a
WHERE a.place_classification = b.place_classification; -- 567 rows

-- In dbeel_station there are the stations of Levante, but NOT in dbeel_electrofishing and temp_pesca_electrica
with dbeel_electrofishing1 as
(select dbeel_station.locationid, place_classification, dbeel_electrofishing.* 
	from sudoang.dbeel_station join sudoang.dbeel_electrofishing on op_id = ob_op_id)

select * from dbeel_electrofishing1 de full outer join sudoang.levante_location ll on de.place_classification = ll.place_classification -- 6334 rows

-- 	1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (locationid,"ANSPFMUES")) from sudoang.levante_location; -- 104 rows
begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id,
	locationid,
	capture_date
	)
	SELECT 
	distinct on (locationid,"ANSPFMUES")
	uuid_generate_v4() AS ob_id ,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	"ANSPFMUES" AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	"SUP_MUESTREADA" AS ef_wetted_area, 
	"LONG_TRAMO" AS ef_fished_length,
	"ANCH_TRAMO" AS ef_fished_width,
	1 AS ef_nbpas,	     
	op.op_id as ob_op_id,
	op.locationid as locationid, -- locationid coming from sudoang.dbeel_station
	"ANSPFMUES" as capture_date -- the date is ok
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join
		sudoang.levante_location on levante_location.locationid=op.locationid
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Rafael Miranda Ferreiro'
	; -- 98 rows (6 station are missing because the locationid is missing)
commit;


-- 	2. INSERT into dbeel_batch_ope: total number, run1 and density
---- 		Before insert number of fish, we need: "locationid", "codspecies", "ob_id"
alter table sudoang.levante_ope add column "SUP_MUESTREADA" integer;
UPDATE sudoang.levante_ope b
SET "SUP_MUESTREADA" = a.ef_wetted_area
FROM sudoang.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 720 rows

alter table sudoang.levante_ope add column codspecies text;
UPDATE sudoang.levante_ope set codspecies = 'aang' where "NOMBRE_TAXON" = 'Anguilla anguilla'; -- 69 rows
UPDATE sudoang.levante_ope set codspecies = 'oth' where "NOMBRE_TAXON" != 'Anguilla anguilla'; -- 651 rows

alter table sudoang.levante_ope add column ob_id uuid;
UPDATE sudoang.levante_ope b
SET ob_id = a.ob_id
FROM sudoang.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 720 rows

----- DOESN'T WORK		Verify "ob_id" from levante_ope table
select sudoang.levante_ope.* from sudoang.levante_ope join sudoang.dbeel_electrofishing on ob_id = ob_id
	except (select * from sudoang.levante_ope);

select * from sudoang.dbeel_batch_ope where locationid = '-115938694' -- 3 rows for number, run1 and density OK!

-- 		TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
--			There is only one pass, so we have to insert total number, run1 and density
begin;
with anguila as (
select distinct on ("ANSPFMUES",ob_id) 
ob_id,
locationid,
coalesce("NINDIVIDUOS",0) as run1, -- It is also total number!
0 as run2,
0 as run3,
round(coalesce("NINDIVIDUOS"::numeric/"SUP_MUESTREADA",0),3) as density -- TO DO: should it be "10000*total_nb::numeric/fished_area" ha?
from sudoang.levante_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on ("ANSPFMUES",ob_id) 
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.levante_ope 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)
-- select * from electrofishing order by locationid;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.run1+electrofishing.run2+electrofishing.run3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM 
        electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status        
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 91 rows
commit;

-- op_p1
begin;
with anguila as (
select distinct on ("ANSPFMUES",ob_id) 
ob_id,
locationid,
coalesce("NINDIVIDUOS",0) as run1, -- It is also the total number!
0 as run2,
0 as run3,
round(coalesce("NINDIVIDUOS"::numeric/"SUP_MUESTREADA",0),3) as density -- TO DO: should it be "10000*total_nb::numeric/fished_area" ha?
from sudoang.levante_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on ("ANSPFMUES",ob_id) 
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.levante_ope 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	2 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM 
	electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND ob_id is not null
	; -- 91 rows
commit;

-- op_density
begin;
with anguila as (
select distinct on ("ANSPFMUES",ob_id)
ob_id, 
locationid,
coalesce("NINDIVIDUOS",0) as run1,
0 as run2,
0 as run3,
round(coalesce("NINDIVIDUOS"::numeric/"SUP_MUESTREADA",0),3) as density -- TO DO: should it be "10000*total_nb::numeric/fished_area" ha?
from sudoang.levante_ope 
where codspecies='aang' and ob_id is not null),

other as (
select distinct on ("ANSPFMUES",ob_id)
ob_id,
locationid,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.levante_ope 
where codspecies!='aang'
and locationid not in (select locationid from anguila)
and ob_id is not null),

electrofishing as (select * from anguila 
union
select * from other 
order by locationid)

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
        electrofishing.locationid
	FROM
	electrofishing, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	AND ob_id is not null -- in the table some lines are not joined to the electrofishing table, in those lines the value is NULL and we don't want to use those lines
	; -- 91 rows
commit;


-- 	3. INSERT into dbeel_batch_fish: fish that were measured
---- Before insert length of fish, we need: "fish_id", "locationid", "codspecies", "ob_id"

alter table sudoang.levante_fish add column fish_id serial;

alter table sudoang.levante_fish add column locationid integer;
UPDATE sudoang.levante_fish b
SET locationid = a.locationid
FROM sudoang.dbeel_station a
WHERE a.place_classification = b.place_classification; -- 13170 rows

alter table sudoang.levante_fish add column codspecies text;
UPDATE sudoang.levante_fish set codspecies = 'aang' where "NOMBRE_TAXON" = 'Anguilla anguilla'; -- 864 rows
UPDATE sudoang.levante_fish set codspecies = 'oth' where "NOMBRE_TAXON" != 'Anguilla anguilla'; -- 12306 rows

alter table sudoang.levante_fish add column ob_id uuid;
UPDATE sudoang.levante_fish b
SET ob_id = a.ob_id
FROM sudoang.dbeel_electrofishing a
WHERE a.locationid = b.locationid; -- 13170 rows

--		Insert individuals that were measured
---- Example to see that are three eels with the same length and weight.
---- the only difference is the effort code ("COD_ESFUERZO") and the description ("DESCRIPCION")
select * from sudoang.levante_fish where locationid = '-2064312883' and codspecies = 'aang';
select * from sudoang.levante_ope where locationid = '-2064312883' and codspecies = 'aang';

---- For a same "locationid" some individuals can be fished but they are repeated:
select * from sudoang.levante_fish where locationid = '618122735' and codspecies = 'aang' order by "CPEZLTOTAL"; -- 81 eels
select * from sudoang.levante_ope where locationid = '618122735' and codspecies = 'aang'; -- 27 eels
---- There isn't a code with which we can filter the duplicates. So, we used:
---- 	Row_number function that assigns a sequencial integer to each row in a result set.
---- 	Window function (OVER (PARTITION BY ... ORDER BY ... DESC)) that performs a calculation across a set of table rows 
----		which are somehow related to the current row, retaining its separate identity.
begin;
with levante_fish_extract as (
select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from sudoang.levante_fish order by locationid),

anguila as (
select
locationid,
place_classification,
fish_id,
ob_id,
coalesce("CPEZLTOTAL",0) as length,
coalesce("CPEZPESO",0) as weight
from levante_fish_extract
where codspecies='aang' and modulo = 0)

--select * from anguila; -- 289 rows
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id,		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	anguila.locationid,
	anguila.place_classification
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; -- 289 rows
commit;



-- 	4. INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		Before insert length of fish, we need: "ba_id" (we had some problems to obtain it, but they are solved)
alter table sudoang.levante_fish add column ba_id uuid;

---- Joining levante_fish and dbeel_batch_fish by "fish_id" and "locationid"
select * from sudoang.levante_fish a full outer join sudoang.dbeel_batch_fish b on (a.fish_id, a.locationid) = (b.fish_id, b.locationid)
	where b.locationid in (select locationid from sudoang.levante_ope); -- 289 rows
-- delete from sudoang.dbeel_batch_fish where ba_id in (select ba_id from sudoang.levante_fish);
-- update sudoang.levante_fish set ba_id = null;

with l as
	(select a.fish_id, b.ba_id from sudoang.levante_fish a join sudoang.dbeel_batch_fish b on (a.fish_id, a.locationid) = (b.fish_id, b.locationid)
	where b.locationid in (select locationid from sudoang.levante_ope))
-- select * from l
UPDATE sudoang.levante_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; -- 289 rows

---- Insert LENGTH
begin;
-- with levante_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from sudoang.levante_fish order by locationid),

with levante_fish_extract as (
select * from sudoang.levante_fish where ba_id is not null),

anguila as (
select
fish_id,
locationid,
place_classification,
ob_id,
codspecies,
ba_id,
coalesce("CPEZLTOTAL",0) as length,
coalesce("CPEZPESO",0) as weight
from levante_fish_extract
where codspecies='aang') --  and modulo = 0
-- select * from anguila; -- 290 rows
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length AS bc_numvalue,
	fish_id,
	locationid, 
	place_classification
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length >0
	AND codspecies='aang' 
	AND ob_id is not null
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 289 rows
commit;

---- Insert WEIGHT
begin;
with levante_fish_extract as (
select * from sudoang.levante_fish where ba_id is not null),

anguila as (
select
fish_id,
locationid,
place_classification,
ob_id,
codspecies,
ba_id,
coalesce("CPEZLTOTAL",0) as length,
coalesce("CPEZPESO",0) as weight
from levante_fish_extract
where codspecies='aang')
-- select * from anguila; -- 290 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id,
	locationid, 
	place_classification
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight >0
	AND codspecies='aang' 
	AND ob_id is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 289 rows
commit;


/*----------------------------------------------------
INTEGRATING MISSING DATA OF SIBIC

3. Doadrio.mdb (individuals fished during the second pass are missing in the Sibic database)
-- Data on size is missing
--Example of one station that doesn't exists in the dbeel database but you can find in the source table (doadrio.mdb):
select * from sudoang.dbeel_station where place_classification='AT3978';

-- Other examples with species fished in the first pass, but not in the second:
select * from sudoang.dbeel_station where place_classification = 'AT3995'; -- locationid = '476583617'
select * from sudoang.temp_pesca_electrica where locationid = '476583617' -- run1 OK, but run2 26 individuals fished not counted (oth species)
select * from sudoang.dbeel_electrofishing where locationid = '476583617'

select * from sudoang.dbeel_station where place_classification = 'AT4233';  -- It doesn't appear but in doadrio db there are 20 eels!
select * from sudoang.dbeel_station where place_classification = 'AT4318'; -- lcoationid = '854720744'
select * from sudoang.temp_pesca_electrica where locationid = '854720744' 

select * from sudoang.dbeel_station where place_classification = 'AT4258';  -- locationid = '-282329194'
select * from sudoang.temp_pesca_electrica where locationid = '-2055656564' 

*/-----------------------------------------------------


/*----------------------------------
INTEGRATION NEW DATA 
*/------------------------------------

---------------------------------
 -- Reprojection of dbeel on the river network
 ------------------------------------

--------------------------------------------------------------------------------------------
-- with reprojection on the river
-- these are only those that are in spain, a lot of points were outside from the country
--------------------------------------------------------------------------------------------

select addgeometrycolumn('sudoang','dbeel_station','geom_reproj',3035,'POINT',2);
-- select * from sudoang.dbeel_station limit 10 --3120
-- select st_srid(geom) from spain.rn
update sudoang.dbeel_station set geom_reproj = sub2.geom_reproj from (
select distinct on (op_id) op_id, geom_reproj,distance from(
select
op_id, 
ST_ClosestPoint(r.geom,s.the_geom) as geom_reproj,
ST_distance(r.geom,s.the_geom) as distance
from sudoang.dbeel_station s join
spain.rn r on st_dwithin(r.geom,s.the_geom,300) 
order by op_id, distance
)sub )sub2
where sub2.op_id= dbeel_station.op_id;

CREATE INDEX 
  ON sudoang.dbeel_station
  USING gist
  (geom_reproj);


--------------------------------------------------------------------------------------------
--  GIPUZKOA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Reprojection

select st_srid(geom) from sudoang.guipuz_station; -- 25830

ALTER TABLE sudoang.guipuz_station
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035);


select addgeometrycolumn('sudoang','guipuz_station','geom_reproj',3035,'POINT',2);
-- select * from sudoang.guipuz_station limit 10 --3120
update sudoang.guipuz_station set geom_reproj = sub2.geom_reproj from (
select distinct on ("Station") "Station", geom_reproj,distance from(
select
"Station", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.guipuz_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by "Station", distance
)sub )sub2
where sub2."Station"= guipuz_station."Station"; -- 397 rows (427 total)

CREATE INDEX 
  ON sudoang.guipuz_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.guipuz_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (GIP_) from ligne 188 script "dbeel_sudoang_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.guipuz_station AS sp1, sudoang.guipuz_station AS sp2
	WHERE substring(sp1.id from 4) < substring(sp2.id from 4) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 4)::integer
; -- 0 no internal duplicates

select * from sudoang.dbeel_station limit 10;
-- add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('Diputación de Gipuzkoa'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Iker Azpiroz', et_id FROM dbeel.establishment WHERE et_establishment_name = 'Diputación de Gipuzkoa'
; --TODO: TO BE MODIFIED


-- duplicate with data already in dbeel, there is one internal duplicate in dbeel that we ignore
-- we choose the closest station to join with

--update sudoang.guipuz_station set dbeel_op_id IS NULL;
WITH 
projection_gipuzkoa AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.guipuz_station g
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_gipuzkoa AS (
SELECT distinct on (id) * from projection_gipuzkoa
)
--SELECT * from closest_gipuzkoa
UPDATE sudoang.guipuz_station SET dbeel_op_id = op_id
	FROM closest_gipuzkoa c
	WHERE c.id=guipuz_station.id; -- 34 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)

--SELECT Find_SRID('sudoang', 'dbeel_station', 'the_geom'); --3035
update sudoang.dbeel_station set op_gis_systemname ='3035'; --10839
-- SELECT * from sudoang.dbeel_station limit 10;
-- select * from sudoang.guipuz_station limit 10
delete from sudoang.guipuz_station  where id in ('GIP_1','GIP_2','GIP_3'); -- 3 lines of rubbish
--393

DELETE FROM sudoang.dbeel_station where op_gis_layername='Diputación de Gipuzkoa';
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname ,
	'Diputación de Gipuzkoa' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	'Estación' as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, 	
	NULL as locationid,
	NULL as country,
	"Station" as place_classification,
	NULL as codhb,	
	'Localización' as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(st_transform(geom,25830)) as x,
	st_y(st_transform(geom,25830)) as y,
	geom_reproj as geom_reproj
	from sudoang.guipuz_station 
	where dbeel_op_id is null -- as those lines are not reprojected
	 ; --390 lines

-- We put back the op_id into the source table
With jointure as (
SELECT * from sudoang.dbeel_station JOIN
sudoang.guipuz_station ON op_gislocation=id)
update sudoang.guipuz_station set dbeel_op_id=op_id from jointure where jointure.id = guipuz_station.id; --390

-----------------------------------
-- INSERTING GIPUZKOA OPERATIONS
-----------------------------------

-- select * from sudoang.guipuz_ope limit 10 -- 1575 rows
delete from sudoang.guipuz_ope where sampling in ('PA2009024','PA2010007','PB2015024'); -- 3 lines of rubbish, 1572 rows
delete from sudoang.guipuz_ope where station in ('0'); -- 1 lines of rubbish, 1571 rows

---- Add dbeel_ob_id in guipuz_operation table
ALTER TABLE sudoang.guipuz_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year

-- Checking the duplicates of the stations (we know, line , that there are 34 stations as duplicates)
with g_station_operation as(
select guipuz_station.dbeel_op_id, guipuz_station.id, guipuz_ope.* from sudoang.guipuz_station 
	join sudoang.guipuz_ope on guipuz_station."Station" = guipuz_ope.station -- 1571 rows
)-- joining the two tables on the guipuz side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 89 rows (but the date it is not the same)


-- Checking the duplicates for year
with g_station_operation as(
select guipuz_station.dbeel_op_id, guipuz_station.id, guipuz_ope.* from sudoang.guipuz_station 
	join sudoang.guipuz_ope on guipuz_station."Station" = guipuz_ope.station -- 1571 rows
)-- joining the two tables on the guipuz side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (date, dbeel_op_id) -- 0 rows: NO DUPLICATES IN OPE

-- for those lines where there is a join, add ob_id in gipuzkoa tables
-- add also a boolean indicating if it's a duplicate.... is_SIBIC_duplicate
ALTER TABLE sudoang.guipuz_ope ADD COLUMN is_sibic_duplicate boolean;

begin;
with sibic_duplicates as(
select guipuz_station.dbeel_op_id, guipuz_station."Station", dbeel_station.* from sudoang.guipuz_station 
	join sudoang.dbeel_station on guipuz_station.dbeel_op_id = dbeel_station.op_id where op_gis_layername = 'SIBIC'-- 34 rows
)
update sudoang.guipuz_ope
set is_sibic_duplicate = TRUE from sibic_duplicates where guipuz_ope.station = sibic_duplicates."Station"; -- 261 rows

UPDATE sudoang.guipuz_ope set is_sibic_duplicate = FALSE WHERE is_sibic_duplicate IS NULL; -- 1310 rows
-- select count(*), station from sudoang.guipuz_ope where is_sibic_duplicate = TRUE group by station; -- 23 rows
select count(sampling), station from sudoang.guipuz_ope where is_sibic_duplicate = TRUE group by station; -- 26 stations: 5 STATIONS ARE MISSING
commit;


---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)

---- STEP 2: integrate new data operations and then fish.... using where is_SIBIC_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (station,date)) from sudoang.guipuz_ope; -- 1570 operations (1316)
select * from sudoang.dbeel_station where op_gis_layername = 'Diputación de Gipuzkoa'; -- 390 stations

-- 		The id of sudoang.guipuz_ope is 'sampling', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'guipu_ob_is' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table sudoang.guipuz_ope add column guipuz_ob_id uuid default uuid_generate_v4 ();


begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	guipuz_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	date AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	sampling_surface AS ef_wetted_area, 
	sampling_length AS ef_fished_length,
	sampling_width AS ef_fished_width,
	2 AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.guipuz_station on dbeel_op_id=op_id
	join
		sudoang.guipuz_ope on guipuz_ope.station=guipuz_station."Station"
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Iker Azpiroz'
	; -- 1317 rows
commit;
SELECT * FROM sudoang.dbeel_station LIMIT 10;
SELECT * FROM sudoang.guipuz_station LIMIT 10;
SELECT * FROM sudoang.guipuz_ope LIMIT 10
SELECT * from sudoang.dbeel_batch_fish;
SELECT * from sudoang.dbeel_batch_ope;

-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.guipuz_ope there is no information about species, only the number of species captured ('nb_species').
--			So, it is not possible to know the number of individuals captured by species.
--			One option could be estimate the number of individuals using sudoang.guipuz_fish: we add the individuals by operation and species.
--			The problem is that the number of individuals measured ('N' by 'sampling' and 'species') doesn't always correspond with 
--			the number of infividuals captured by operation ('nb_tot'). See these examples for two stations:

select nb_tot from sudoang.guipuz_ope where sampling = 'PA1996004'; -- 221 individuals
select sum("N"), species from sudoang.guipuz_fish where sampling = 'PA1996004' group by species;  -- 139 individuals

select nb_tot from sudoang.guipuz_ope where sampling = 'PB2009005'; -- 374 individuals
select sum("N"), species from sudoang.guipuz_fish where sampling = 'PB2009005' group by species;  -- 374 individuals (Maria did a mistake using count("N")


ALTER TABLE sudoang.guipuz_ope ADD COLUMN run1_ang integer;
ALTER TABLE sudoang.guipuz_ope ADD COLUMN run2_ang integer;
ALTER TABLE sudoang.guipuz_ope ADD COLUMN run1_oth integer;
ALTER TABLE sudoang.guipuz_ope ADD COLUMN run2_oth integer;

with run1_anguila as (
select
sampling as sampling,
sum("N") as run1_anguila
from sudoang.guipuz_fish
where species='Anguilla anguilla' and pass = 1 group by sampling),

run2_anguila as (
select
sampling as sampling2,
sum("N") as run2_anguila
from sudoang.guipuz_fish
where species='Anguilla anguilla' and pass = 2 group by sampling),

run1_other as (
select
sampling as sampling3,
sum("N") as run1_other
from sudoang.guipuz_fish
where species!='Anguilla anguilla' and pass = 1 group by sampling),

run2_other as (
select
sampling as sampling4,
sum("N") as run2_other
from sudoang.guipuz_fish
where species!='Anguilla anguilla' and pass = 2 group by sampling),

electro as (select coalesce(sampling, sampling2, sampling3, sampling4) as sampling, run1_anguila, run2_anguila, run1_other, run2_other from run1_anguila 
	FULL OUTER JOIN run2_anguila on sampling = sampling2
	FULL OUTER JOIN run1_other on sampling = sampling3
	FULL OUTER JOIN run2_other on sampling = sampling4
)
-- select * from electro; -- 1464 rows (compared to 1571 in guipuz_ope table)
update sudoang.guipuz_ope
set (run1_ang, run2_ang, run1_oth, run2_oth) = (run1_anguila, run2_anguila, run1_other, run2_other) from electro where guipuz_ope.sampling = electro.sampling; -- 1231 rows

--			Delete rows where we didn't count fish in the operation
delete from sudoang.guipuz_ope where run1_ang is null and run2_ang is null and run1_oth is null and run2_oth is null and nb_species > 0
; -- 340 rows: 32 rows that indicating there are no fish! DO WE CONSERV THESE OPE AS 0? (254 rows)

begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from sudoang.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from sudoang.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)
--select * from electrofishing_temp order by sampling;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run1+electrofishing_temp.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	--AND ob_id is not null
	; -- 1317 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from sudoang.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from sudoang.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 1317 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from sudoang.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from sudoang.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 1317 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from sudoang.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from sudoang.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	electrofishing_temp, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 1317 rows
commit;

---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.guipuz_fish add column fish_id serial;
alter table sudoang.guipuz_fish add column ba_id uuid; -- We can't generate hte ba_id for the whole table because there are more than 200 000 rows!

---- 		Check duplicates: Joining levante_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.guipuz_fish a join sudoang.guipuz_ope o on a.sampling = o.sampling
	join sudoang.dbeel_electrofishing l on l.ob_id = o.guipuz_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows
	
-- delete from sudoang.dbeel_batch_fish where ba_id in (select ba_id from sudoang.guipuz_fish);
-- update sudoang.guipuz_fish set ba_id = null;

/*   There aren't fishes in dbeel_batch_fish from guipuz_fish, so this query is not necessary
with l as
	(select * from sudoang.guipuz_fish a join sudoang.guipuz_ope o on a.sampling = o.sampling
	join sudoang.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id)) -- 0 rows
UPDATE sudoang.levante_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; -- 0 rows
*/

----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
select * from sudoang.guipuz_fish where lap_mm = '2.024,00';
update sudoang.guipuz_fish set lap_mm = '2024,00' where lap_mm = '2.024,00';

begin;	
with anguila as (
select
fish_id,
a.sampling,
guipuz_ob_id as ba_ob_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from sudoang.guipuz_fish a 
	join sudoang.guipuz_ope o on a.sampling = o.sampling
	where species = 'Anguilla anguilla')
--SELECT * FROM anguila; -- 31 972 rows

INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN typeang='Amarilla' THEN 226 --'Yellow eel' 
	     WHEN typeang='Plateada' THEN 227 -- 'Silver eel'
	     WHEN typeang='Indefinida' THEN 224 -- unknown
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ba_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
--	anguila.sampling 		-- DOESN'T WORK because "locationid" is an integer and "sampling" is text
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; -- 31 972 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in guipuz_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from sudoang.dbeel_station;

with fish_from_iker as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 14) -- 31 972 rows	
--select * from fish_from_iker join sudoang.guipuz_fish on fish_from_iker.fish_id = guipuz_fish.fish_id limit 10;

UPDATE sudoang.guipuz_fish b
SET ba_id = fish_from_iker.ba_id
FROM fish_from_iker
WHERE fish_from_iker.fish_id = b.fish_id; -- 31 972 rows
--select * from sudoang.guipuz_fish where ba_id is not null limit 10;


---- 		Insert LENGTH
-- with levante_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from sudoang.levante_fish order by locationid),
begin;
with guipuz_fish_extract as (
select * from sudoang.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 31 972 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,  -- ERROR
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 31925 rows (47 rows with length NULL)
commit; 

-- Update LENGTH
select * from sudoang.dbeel_electrofishing join sudoang.dbeel_batch_fish on ob_id = ba_ob_id
join sudoang.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id where ob_dp_id = 14 and bc_no_characteristic_type = 39 -- 31110 rows

begin;
with guipuz_fish_extract as (
select * from sudoang.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select fish_id, ba_id, length_mm, typeang
from guipuz_fish_extract),

batch as (
select bc_id, anguila.* from sudoang.dbeel_mensurationindiv_biol_charac m 
join anguila on (anguila.ba_id, anguila.fish_id) = (m.bc_ba_id, m.fish_id) where bc_no_characteristic_type = 39
)
--select * from batch order by fish_id -- 31110 rows
update sudoang.dbeel_mensurationindiv_biol_charac m set bc_numvalue = length_mm from batch where m.bc_id = batch.bc_id -- 31110 rows
commit;

---- 		Insert WEIGHT
begin;
with guipuz_fish_extract as (
select * from sudoang.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 31 972 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 31664 rows (308 rows with weight NULL)
commit;

---- 		Insert VERTICAL EYE DIAMETER
begin;
with guipuz_fish_extract as (
select * from sudoang.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 2346 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	eye_diam_vert AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE eye_diam_vert >0
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2346 rows
commit;
--select * from dbeel_nomenclature.biological_characteristic_type where biological_characteristic_type.no_name = 'eye_diam_vert'

---- 		Insert HORIZONTAL EYE DIAMETER
begin;
with guipuz_fish_extract as (
select * from sudoang.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 2346 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE eye_diam_horiz >0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2334 rows
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN
begin;
with guipuz_fish_extract as (
select * from sudoang.guipuz_fish where ba_id is not null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 2346 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length_pect AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length_pect >0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2196 rows
commit;



/*
Corrections for the view
there were a lot more lines than operation
the first was due to counts from batch_fish integrated in the batch file, solved by setting batch level to 4 in batch_fish as the view only takes 1 as batch_level
The second was duplicated values, every second rows was removed from 5 operations
*/


begin;
update sudoang.dbeel_batch_fish set ba_batch_level=4 --41743
--select count(*) from dbeel.view_electrofishing; --7311
COMMIT;

/*
  select  op_gis_layername, count(*) from dbeel.view_electrofishing group by op_gis_layername;
  select count(*) from dbeel.view_electrofishing;
  --7156

select * from dbeel.view_electrofishing limit 10
select * from dbeel.batch where ba_ob_id='0006cd83-93a7-45cc-8b46-96372def8b29'
SELECT * from  dbeel_nomenclature.nomenclature where no_id in (47,48,231,232)

select * from sudoang.dbeel_batch_ope where ba_ob_id='0006cd83-93a7-45cc-8b46-96372def8b29'

select * from sudoang.dbeel_batch_fish where ba_ob_id='0006cd83-93a7-45cc-8b46-96372def8b29'

select  ob_id, count(*) from dbeel.view_electrofishing group by ob_id ;
select * from dbeel.view_electrofishing where ob_id='2d56351d-596a-4379-8d02-0d7e4b87fd29';
select * from sudoang.dbeel_batch_ope where ba_ob_id='2d56351d-596a-4379-8d02-0d7e4b87fd29';
SELECT * from sudoang.dbeel_electrofishing where ob_id='2d56351d-596a-4379-8d02-0d7e4b87fd29';
*/
BEGIN;
with the_culprit as (select  ob_id, count(*) from dbeel.view_electrofishing group by ob_id),

 counts as (
select 
    ba_id, 
    ROW_NUMBER() OVER(
    PARTITION BY ba_ob_id, ba_no_biological_characteristic_type
    ORDER BY ba_ob_id, ba_no_biological_characteristic_type)
    from sudoang.dbeel_batch_ope 
where ba_ob_id in (select ob_id from the_culprit where count>1))

DELETE FROM sudoang.dbeel_batch_ope where ba_id in (
 SELECT ba_id from counts where row_number=2
); --25

-- select  ob_id, count(*) from dbeel.view_electrofishing group by ob_id order by count desc; -- yeahhh
COMMIT;



--------------------------------------------------------------------------------------------
-- PORTUGAL: reprojection and stations
--------------------------------------------------------------------------------------------

select * from sudoang.portugal_location limit 10; -- 745 rows
select count("Code") from sudoang.portugal_location; -- 745 rows

---- Reprojection
SELECT Find_SRID('sudoang', 'portugal_location', 'geom'); -- 3035

ALTER TABLE sudoang.portugal_location
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035);

CREATE INDEX 
  ON sudoang.portugal_location
  USING gist
  (geom);
  
-- Add geom_reproj
select addgeometrycolumn('sudoang','portugal_location','geom_reproj',3035,'POINT',2);

update sudoang.portugal_location set geom_reproj = sub2.geom_reproj from (
select distinct on ("Code") "Code", geom_reproj,distance from(
select
"Code", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.portugal_location s join
portugal.rn r on st_dwithin(r.geom,s.geom,300) 
order by "Code", distance
)sub )sub2
where sub2."Code"= portugal_location."Code"; -- 739 rows

CREATE INDEX 
  ON sudoang.portugal_location
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.portugal_location ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (POR_) from ligne 163 script "dbeel_sudoang_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.portugal_location AS sp1, sudoang.portugal_location AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 1 no internal duplicates: POR_741 and POR_742

/* TO DO: ask to Isabel the exact location of these two stations
select * from sudoang.portugal_location where id in ('POR_741', 'POR_742');
select * from sudoang.portugal_ope where op_sta_id in ('MI_008', 'MI_009');
*/

/* Establishment and provider
select * from dbeel.establishment	-- FCUL/MARE et_id = 21
select * from dbeel.data_provider	-- Isabel Domingos dp_id = 19
*/


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.portugal_location set dbeel_op_id IS NULL;
WITH 
projection_portugal AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.portugal_location g
	-- join sudoang.portugal_ope on op_sta_id = "Code"
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_portugal AS (
SELECT distinct on (id) * from projection_portugal
)
--SELECT * from closest_portugal -- 0 row
UPDATE sudoang.portugal_location SET dbeel_op_id = op_id
	FROM closest_portugal c
	WHERE c.id = portugal_location.id; -- 0 duplicates

/* The only duplicate in the dbeel is not in the electrofishing table:
select * from sudoang.portugal_location where id = 'POR_736'
select * from sudoang.dbeel_station where locationid = '1947';
select* from sudoang.dbeel_electrofishing where locationid = '1947';
*/

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='FCUL/MARE'; -- 0 rows
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'FCUL/MARE' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	'Label' as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, 	
	NULL as locationid,
	'PT' as country,
	'Code' as place_classification,
	NULL as codhb,	
	NULL as observations,
	'Basin' as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.portugal_location
	where dbeel_op_id is null -- as those lines are not reprojected
	 ; -- 745 lines
commit;

-- We put back the op_id into the source table
begin;
update sudoang.portugal_location set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 745 rows
commit;


-----------------------------------
-- INSERTING PORTUGUESE OPERATIONS
-----------------------------------

-- select * from sudoang.portugal_ope limit 10; -- 868 rows
-- ALTER TABLE sudoang.portugal_ope RENAME COLUMN "ï»¿op_id" TO op_id;

---- Add dbeel_ob_id in portugal_ope table
ALTER TABLE sudoang.portugal_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year

-- Checking the duplicates of the stations (we know, line , that there are 2 stations as duplicates)
with p_station_operation as(
select portugal_location.dbeel_op_id, portugal_location.id, portugal_ope.* from sudoang.portugal_location 
	join sudoang.portugal_ope on portugal_location."Code" = portugal_ope.op_sta_id -- 879 rows
)-- joining the two tables on the portugal side
select * from p_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 0 rows


-- Checking the duplicates for year
with p_station_operation as(
select portugal_location.dbeel_op_id, portugal_location.id, portugal_ope.* from sudoang.portugal_location 
	join sudoang.portugal_ope on portugal_location."Code" = portugal_ope.op_sta_id -- 879 rows
)-- joining the two tables on the portugal side
select * from p_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id); -- 0 rows: NO DUPLICATES IN OPE

-- for those lines where there is a join, add ob_id in portugal tables
-- add also a boolean indicating if it's a duplicate.... is_SIBIC_duplicate
ALTER TABLE sudoang.portugal_ope ADD COLUMN is_sibic_duplicate boolean default false;

/* No duplicates in Portugal
begin;
with sibic_duplicates as(
select portugal_location.dbeel_op_id, guipuz_station."Station", dbeel_station.* from sudoang.guipuz_station 
	join sudoang.dbeel_station on guipuz_station.dbeel_op_id = dbeel_station.op_id where op_gis_layername = 'SIBIC'-- 34 rows
)
update sudoang.guipuz_ope
set is_sibic_duplicate = TRUE from sibic_duplicates where guipuz_ope.station = sibic_duplicates."Station"; -- 261 rows

UPDATE sudoang.guipuz_ope set is_sibic_duplicate = FALSE WHERE is_sibic_duplicate IS NULL; -- 1310 rows
-- select count(*), station from sudoang.guipuz_ope where is_sibic_duplicate = TRUE group by station; -- 23 rows
select count(sampling), station from sudoang.guipuz_ope where is_sibic_duplicate = TRUE group by station; -- 26 stations: 5 STATIONS ARE MISSING
commit;
*/

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)

---- STEP 2: integrate new data operations and then fish.... using where is_SIBIC_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from sudoang.portugal_ope; -- 868 rows
select count(distinct (op_sta_id,op_dat)) from sudoang.portugal_ope; -- 868 operations
select * from sudoang.dbeel_station where op_gis_layername = 'FCUL/MARE'; -- 745 stations

alter table sudoang.portugal_ope add column portugal_ob_id uuid default uuid_generate_v4 ();
alter table sudoang.portugal_ope add column problem_duplicates boolean default false;

begin;
with duplicates as (
			select portugal_ob_id, count(*) from sudoang.portugal_location 
			join
			sudoang.portugal_ope on portugal_ope.op_sta_id=portugal_location."Code" group by portugal_ob_id order by count desc
		    ),
burnt as (select portugal_ob_id from duplicates where count > 1)
update sudoang.portugal_ope set problem_duplicates = TRUE where portugal_ob_id in (select portugal_ob_id from burnt); -- 11 rows
commit;


begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	portugal_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.portugal_location on dbeel_op_id=op_id
	join
		sudoang.portugal_ope on portugal_ope.op_sta_id=portugal_location."Code"
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Isabel Domingos'
	and problem_duplicates = FALSE
	; -- 857 rows
commit;

-- SOLVED PROBLEM WITH DATA FORMAT: update date of dbeel_electrofishing using the ob_id key (from portugal_ope with portugal_ob_id key)
begin;
update sudoang.dbeel_electrofishing as de set ob_starting_date = po.op_dat from sudoang.portugal_ope as po where po.portugal_ob_id = de.ob_id;

select * from sudoang.dbeel_electrofishing where ob_id in (select portugal_ob_id from sudoang.portugal_ope); 
COMMIT;


/* TO DO Isabel: check duplicates - 11 rows - 
select distinct op_sta_id from sudoang.portugal_ope where problem_duplicates = TRUE; 			-- A3 and A1
SELECT * FROM sudoang.portugal_ope where portugal_ob_id = 'bbb8c153-de70-4940-8fa0-7834c992f7d5';
SELECT * FROM sudoang.portugal_location where "Code" = 'A1' or "Code" = 'A3'; 				-- More than one operation
*/


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.portugal_ope there is only information about eels ('op_nbeel').

select * from sudoang.portugal_ope where op_length is null or op_width is null; -- 676 rows
select * from sudoang.portugal_ope where (op_length is null or op_width is null) and op_dens > 0; -- 150 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.portugal_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	--AND ob_id is not null
	; -- 857 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	portugal_ope.op_dens AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.portugal_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	; -- 857 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	portugal_ope.op_nbeel AS ba_quantity, -- We think that there is only one passage
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.portugal_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	; -- 857 rows
commit;

---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.portugal_fish add column fish_id serial;
alter table sudoang.portugal_fish add column ba_id uuid;

select sum(op_nbeel) as quantity from sudoang.portugal_ope; -- 4 202 rows
select count(*) from sudoang.portugal_fish; -- 4 202 rows

---- 		Check duplicates: Joining portugal_fish and dbeel_batch_fish by "op_sta_id" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.portugal_fish a join sudoang.portugal_ope o on a.ang_op_id = o.op_sta_id
	join sudoang.dbeel_electrofishing l on ob_id = o.portugal_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = ba_ob_id; -- 0 rows

/*   There aren't fishes in dbeel_batch_fish from _fish, so this query is not necessary
with l as
	(select * from sudoang.portugal_fish a join sudoang.portugal_ope o on a.ang_op_id = o.op_sta_id
	join sudoang.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id)) --  rows
UPDATE sudoang.portugal_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; --  rows
*/


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy
select distinct on (fish_id) * from sudoang.portugal_fish; -- 4202 rows
-- todo
begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope.portugal_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	portugal_fish.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 	 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.portugal_fish
	join sudoang.portugal_ope
	on (ang_op_id, portugal_ope.op_dat) = (op_sta_id,dat)	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	AND stage.no_name='Yellow eel'  
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = 'FALSE'
	; -- 4089 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length
---- 		To integrate length and weight of fish, "ba_id" must be included before in portugal_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in portugal_fish table! 

with fish_from_portugal as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 19) -- Verify that ob_dp_id = 19: 4089 rows
--select * from fish_from_portugal join sudoang.portugal_fish on fish_from_portugal.fish_id = portugal_fish.fish_id; -- 4089 rows
UPDATE sudoang.portugal_fish b
SET ba_id = fish_from_portugal.ba_id
FROM fish_from_portugal
WHERE fish_from_portugal.fish_id = b.fish_id; -- 4089 rows
-- select ang_op_id from sudoang.portugal_fish where ba_id is null; -- 113 rows: ang_op_id are TRUE in problem_duplicates (they haven't been inserted)


---- 		Insert LENGTH (no_id = 39)
begin;
with portugal_fish_extract as (
select * from sudoang.portugal_fish where ba_id is not null) -- 4089 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 4089 rows
commit; 



--------------------------------------------------------------------------------------------
-- PORTUGAL BIS: reprojection and stations
--------------------------------------------------------------------------------------------

select * from sudoang.portugal_location_bis; -- 53 rows

---- Reprojection
SELECT Find_SRID('sudoang', 'portugal_location_bis', 'geom'); -- 3035

CREATE INDEX 
  ON sudoang.portugal_location_bis
  USING gist
  (geom);
  
-- Add geom_reproj
select addgeometrycolumn('sudoang','portugal_location_bis','geom_reproj',3035,'POINT',2);

update sudoang.portugal_location_bis set geom_reproj = sub2.geom_reproj from (
select distinct on ("sta_id") "sta_id", geom_reproj,distance from(
select
"sta_id", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.portugal_location_bis s join
portugal.rn r on st_dwithin(r.geom,s.geom,300) 
order by "sta_id", distance
)sub )sub2
where sub2."sta_id"= portugal_location_bis."sta_id"; -- 53 rows

CREATE INDEX 
  ON sudoang.portugal_location_bis
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.portugal_location_bis ADD COLUMN dbeel_op_id uuid;

-- internal duplicate here (added id (POR_) from ligne 163 script "dbeel_sudoang_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.portugal_location_bis AS sp1, sudoang.portugal_location_bis AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 1 no internal duplicates: POR_778 and POR_788

/* TO DO: ask to Isabel the exact location of these two stations
select * from sudoang.portugal_location_bis where id in ('POR_778', 'POR_788');
select * from sudoang.portugal_ope_bis where op_sta_id in ('MJ10', 'MARE10');
select * from sudoang.portugal_ope_bis where op_sta_id = 'MJ10'; -- 0 rows: Delete this station from portugal_location_bis
delete from sudoang.portugal_location_bis where id = 'POR_778'; -- 1 row
*/

/* Establishment and provider
select * from dbeel.establishment	-- FCUL/MARE et_id = 21
select * from dbeel.data_provider	-- Isabel Domingos dp_id = 19
*/


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.portugal_location_bis set dbeel_op_id IS NULL;
WITH 
projection_portugal AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.portugal_location_bis g
	-- join sudoang.portugal_ope_bis on op_sta_id = "Code"
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_portugal AS (
SELECT distinct on (id) * from projection_portugal
)
--SELECT * from closest_portugal -- 50 rows
UPDATE sudoang.portugal_location_bis SET dbeel_op_id = op_id
	FROM closest_portugal c
	WHERE c.id = portugal_location_bis.id; -- 50 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='FCUL/MARE'; -- 745 rows
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'FCUL/MARE' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	NULL as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom, 	
	NULL as locationid,
	'PT' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.portugal_location_bis
	where dbeel_op_id is null -- as those lines are not reprojected
	; -- 2 lines
commit;

-- We put back the op_id into the source table
update sudoang.portugal_location_bis set dbeel_op_id = op_id from sudoang.dbeel_station where id = op_gislocation; -- 2 rows


----------------------------------------
-- INSERTING PORTUGUESE OPERATIONS BIS
----------------------------------------
-- select * from sudoang.portugal_ope_bis; -- 100 rows

---- Add dbeel_ob_id in portugal_ope_bis table
ALTER TABLE sudoang.portugal_ope_bis ADD COLUMN dbeel_ob_id uuid;

---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with p_station_operation as(
select portugal_location_bis.dbeel_op_id, portugal_location_bis.id, portugal_ope_bis.* from sudoang.portugal_location_bis 
	join sudoang.portugal_ope_bis on portugal_location_bis.sta_id = portugal_ope_bis.op_sta_id -- 100 rows
)-- joining the two tables on the portugal side
select * from p_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 286 rows

-- Checking the duplicates for year: real duplicates
with p_station_operation as(
select portugal_location_bis.dbeel_op_id, portugal_location_bis.id, portugal_ope_bis.* from sudoang.portugal_location_bis 
	join sudoang.portugal_ope_bis on portugal_location_bis.sta_id = portugal_ope_bis.op_sta_id -- 100 rows
)-- joining the two tables on the portugal side
select * from p_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id); -- 56 rows

-- for those lines where there is a join, add ob_id in portugal tables
ALTER TABLE sudoang.portugal_ope_bis ADD COLUMN is_duplicate boolean;
-- update sudoang.portugal_ope_bis set is_duplicate = FALSE;  -- 100 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select portugal_location_bis.dbeel_op_id, portugal_location_bis.id, portugal_location_bis.sta_id, portugal_ope_bis.* from sudoang.portugal_location_bis 
	join sudoang.portugal_ope_bis on portugal_location_bis.sta_id = portugal_ope_bis.op_sta_id -- 100 rows
	),-- joining the two tables on the portugal side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates; -- 56 rows
update sudoang.portugal_ope_bis set is_duplicate = TRUE where op_id in (select op_id from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 56 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from sudoang.portugal_ope_bis; -- 100 rows
select count(distinct (op_sta_id,op_dat)) from sudoang.portugal_ope_bis; -- 868 operations
select * from sudoang.dbeel_station where op_gis_layername = 'FCUL/MARE'; -- 747 stations

alter table sudoang.portugal_ope_bis add column portugal_ob_id uuid default uuid_generate_v4 ();

begin;
with operation as (
	select * from sudoang.portugal_ope_bis where is_duplicate = FALSE -- 44 rows
	)
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	portugal_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.portugal_location_bis on dbeel_op_id = op_id
	join
		operation on operation.op_sta_id = portugal_location_bis.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_id = 19 -- There is an error in data provider: Isabel Domingos is repeated!!
	; -- 44 rows
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.portugal_ope there is only information about eels ('op_nbeel').

select * from sudoang.portugal_ope_bis where op_length is null or op_width is null; -- 0 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.portugal_ope_bis,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 44 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	round(cast(portugal_ope_bis.op_nbeel / (portugal_ope_bis.op_length * portugal_ope_bis.op_width) as numeric), 3) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.portugal_ope_bis, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 44 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	portugal_ope_bis.op_p1 AS ba_quantity, -- There is only one passage
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.portugal_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.portugal_ope_bis, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 44 rows
commit;

---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.portugal_fish_bis add column fish_id serial;
alter table sudoang.portugal_fish_bis add column ba_id uuid;

select sum(op_nbeel) as quantity from sudoang.portugal_ope_bis; -- 1 496 rows
select sum(op_nbeel) as quantity from sudoang.portugal_ope_bis where is_duplicate = FALSE; -- 861 rows
select count(*) from sudoang.portugal_fish_bis; -- 1 496 rows
select count(*) from sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis
	on ang_op_id = op_id			-- 1035 rows
	where is_duplicate = FALSE; 		-- 400 rows

---- 		Check duplicates: Joining portugal_fish and dbeel_batch_fish by "op_sta_id" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.portugal_fish_bis a join sudoang.portugal_ope_bis o on a.ang_op_id = o.op_sta_id
	join sudoang.dbeel_electrofishing l on ob_id = o.portugal_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = ba_ob_id; -- 0 rows

/*   There aren't fishes in dbeel_batch_fish from _fish, so this query is not necessary
with l as
	(select * from sudoang.portugal_fish_bis a join sudoang.portugal_ope_bis o on a.ang_op_id = o.op_sta_id
	join sudoang.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id)) --  rows
UPDATE sudoang.portugal_fish_bis b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; --  rows
*/


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy
begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.portugal_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	portugal_fish_bis.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 	 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis
	on ang_op_id = op_id	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	AND stage.no_name='Yellow eel'  
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = 'FALSE'
	; -- 400 rows
commit;

-- SOLVED PROBLEM WITH STAGE: update stage of dbeel_batch_fish using the ba_id key (from portugal_fish_bis with ba_id key)
begin;
update sudoang.dbeel_batch_fish as fi set ba_no_stage = CASE WHEN ang_silver = 'FALSE' THEN 226 -- 'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 	-- 'Silver eel'
	     when ang_silver is null then 226   -- 'Yellow eel' 
	     END
from sudoang.portugal_fish_bis as po where po.ba_id = fi.ba_id; -- 400 rows
COMMIT;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length, weight, etc
---- 		To integrate length and weight of fish, "ba_id" must be included before in portugal_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in portugal_fish table! 
select * from sudoang.dbeel_electrofishing where ob_dp_id = 19
with fish_from_portugal as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 19
	and ob_starting_date in (select op_dat from sudoang.portugal_ope_bis where is_duplicate = FALSE) -- ba_id is repeated because fish_id is the same in portugal_fish table and portugal_fish_bis
	) -- 809 rows
UPDATE sudoang.portugal_fish_bis b
SET ba_id = fish_from_portugal.ba_id
FROM fish_from_portugal
WHERE fish_from_portugal.fish_id = b.fish_id; -- 400 rows
-- select ang_op_id from sudoang.portugal_fish_bis where ba_id is null; -- 1096 rows

---- 		Insert LENGTH (no_id = 39)
begin;
with portugal_fish_extract as (
select * from sudoang.portugal_fish_bis where ba_id is not null) -- 400 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 400 rows
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with portugal_fish_extract as (
select * from sudoang.portugal_fish_bis where ba_id is not null)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	round(cast(ang_pds as NUMERIC), 3) AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds::NUMERIC > 0
	and ang_pds is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 399 rows
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
with portugal_fish_extract as (
select * from sudoang.portugal_fish_bis where ba_id is not null)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
with portugal_fish_extract as (
select * from sudoang.portugal_fish_bis where ba_id is not null)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
with portugal_fish_extract as (
select * from sudoang.portugal_fish_bis where ba_id is not null)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" is text
begin;
with portugal_fish_extract as (
select * from sudoang.portugal_fish_bis where ba_id is not null)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast is null THEN 0
	     WHEN ang_neuromast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" is text
begin;
with portugal_fish_extract as (
select * from sudoang.portugal_fish_bis where ba_id is not null)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_constrast is null THEN 0
	     WHEN ang_constrast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_constrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 8 rows
commit;

----------------------------------------------------------------------------------------------
-- INSERT MISSING DATA 
---------------------------------------------------------------------------------------------
SELECT * from sudoang.dbeel_electrofishing;
select * from sudoang.portugal_ope_bis limit 10;
-- the op_id column is portugal_ob_id, dropping empty column

SELECT count(*) FROM sudoang.portugal_ope_bis; --100
SELECT count(*) FROM sudoang.portugal_ope_bis pp JOIN sudoang.dbeel_electrofishing ee on pp.portugal_ob_id=ee.ob_id; --44


BEGIN;
WITH friend as (
SELECT * FROM sudoang.portugal_ope_bis pp JOIN sudoang.dbeel_electrofishing ee on pp.portugal_ob_id=ee.ob_id
) --44
UPDATE sudoang.portugal_ope_bis set dbeel_ob_id=friend.portugal_ob_id from friend where friend.portugal_ob_id=portugal_ope_bis.portugal_ob_id; --44
COMMIT;

BEGIN;
with duplicates as (
	Select portugal_location_bis.dbeel_op_id, portugal_location_bis.id, portugal_location_bis.sta_id, portugal_ope_bis.* from sudoang.portugal_location_bis 
	join sudoang.portugal_ope_bis on portugal_location_bis.sta_id = portugal_ope_bis.op_sta_id -- 100 rows
	),-- joining the two tables on the portugal side

op_duplicates as (
	select  ob_id, portugal_ob_id  from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
UPDATE sudoang.portugal_ope_bis set dbeel_ob_id=ob_id FROM op_duplicates 
where op_duplicates.portugal_ob_id=portugal_ope_bis.portugal_ob_id
AND is_duplicate;--56
COMMIT;

-- Checking already inserted batch_ope
WITH toto as (
SELECT distinct ON (ba_ob_id) * FROM sudoang.dbeel_batch_ope JOIN sudoang.portugal_ope_bis ON ba_ob_id=dbeel_ob_id )
select count (*) from toto; --100 OK

SELECT * from sudoang.portugal_fish_bis where ba_id is NULL; --1496


SELECT * from  	sudoang.portugal_ope_bis 
		JOIN  sudoang.portugal_fish_bis on ang_op_id=portugal_ope_bis.op_id

SELECT dbeel_batch_fish.* FROM sudoang.dbeel_batch_fish JOIN 
 sudoang.portugal_ope_bis ON dbeel_ob_id= ba_ob_id --1035
-- not more datat
SELECT dbeel_batch_fish.* FROM sudoang.dbeel_batch_fish JOIN 
 sudoang.portugal_ope_bis ON dbeel_ob_id= ba_ob_id
 UNION
SELECT dbeel_batch_fish.* FROM sudoang.dbeel_batch_fish JOIN 
 sudoang.portugal_ope ON dbeel_ob_id= ba_ob_id;	--1035
		

-- which are the fish already in the database for which we have the size and for which we have new rows in dbeel_batch_fish : we want to delete them
SELECT * FROM sudoang.dbeel_batch_fish JOIN 
 sudoang.portugal_ope_bis ON dbeel_ob_id= ba_ob_id 
 where is_duplicate; --635

SELECT * FROM sudoang.dbeel_batch_fish 


SELECT * FROM 
sudoang.dbeel_mensurationindiv_biol_charac 
JOIN
sudoang.dbeel_batch_fish on bc_ba_id=ba_id
JOIN 
 sudoang.portugal_ope_bis ON dbeel_ob_id= ba_ob_id 
 where is_duplicate; --635
 

-- sudoang.dbeel_mensurationindiv_biol_charac has delete cascade on ba_id,
-- so we delete one line per fish in dbeel_batch_fish and all lines corresponding to length (there was only this) in dbeel_mensurationindiv_biol_charac

BEGIN;
DELETE FROM sudoang.dbeel_batch_fish WHERE ba_id in (
SELECT ba_id FROM sudoang.dbeel_batch_fish JOIN 
 sudoang.portugal_ope_bis ON dbeel_ob_id= ba_ob_id 
 where is_duplicate);--635
COMMIT; 


SELECT portugal_ope_bis.* FROM sudoang.portugal_ope_bis
EXCEPT 
SELECT portugal_ope_bis.* FROM sudoang.dbeel_batch_ope 
JOIN 
sudoang.portugal_ope_bis ON ba_ob_id=dbeel_ob_id 




-- Now it's time to insert the fish that were marked 'as duplicate' in portugal_ope_bis 
begin;	

INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.dbeel_ob_id as ba_ob_id, 	-- this one is not longer portugal_ob_id
	cast(NULL as uuid) as ba_ba_id,
	portugal_fish_bis.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 	 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis
	on ang_op_id = op_id
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	AND stage.no_name='Yellow eel'  
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = 'TRUE'
	; -- 635 rows


with fishinserteddupl as
	(
	select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate
	),
      fish_from_portugal AS 
      (
SELECT fishinserteddupl.fish_id, dbeel_batch_fish.ba_id from fishinserteddupl 
	join sudoang.dbeel_batch_fish on (fishinserteddupl.fish_id,fishinserteddupl.dbeel_ob_id) = (dbeel_batch_fish.fish_id, dbeel_batch_fish.ba_ob_id)
	)

UPDATE sudoang.portugal_fish_bis b
SET ba_id = fish_from_portugal.ba_id
FROM fish_from_portugal
WHERE fish_from_portugal.fish_id = b.fish_id; -- 635 rows
COMMIT;

---- 		Insert LENGTH (no_id = 39)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate) 

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 635 rows
COMMIT;

---- 		Insert WEIGHT (no_id = 42)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	round(cast(ang_pds as NUMERIC), 3) AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds::NUMERIC > 0
	and ang_pds is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 635 rows
COMMIT;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
COMMIT;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
COMMIT;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
COMMIT;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" is text
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast is null THEN 0
	     WHEN ang_neuromast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
COMMIT;

---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" is text
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where is_duplicate)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_constrast is null THEN 0
	     WHEN ang_constrast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_constrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 10 rows
commit;


SELECT * FROM  sudoang.portugal_fish_bis where ba_id is NOT NULL;--1035

select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where dbeel_ob_id is NULL;--0

select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where ba_id is NULL;--0
	
-- DE LA PUREEEEEEEEE pas de ang_op_id MJ3 001 instead of MJ30001

ALTER TABLE sudoang.portugal_fish_bis ADD COLUMN isbigpuree boolean default FALSE;
UPDATE sudoang.portugal_fish_bis set isbigpuree=TRUE where fish_id in (
SELECT fish_id FROM (
SELECT * FROM sudoang.portugal_fish_bis EXCEPT
select portugal_fish_bis.* FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id)sub);-- 461
	
BEGIN;
UPDATE 	sudoang.portugal_fish_bis set ang_op_id=
regexp_replace(ang_op_id, '001', '0001')  WHERE isbigpuree; --461
COMMIT;

begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	portugal_ope_bis.dbeel_ob_id as ba_ob_id, 	-- this one is not longer portugal_ob_id
	cast(NULL as uuid) as ba_ba_id,
	portugal_fish_bis.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 	 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis
	on ang_op_id = op_id
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	AND stage.no_name='Yellow eel'  
	AND value_type.no_name='Raw data or Individual data'
	and isbigpuree
	; -- 461 rows
COMMIT;

BEGIN;
with fishinserteddupl as
	(
	select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree
	),
      fish_from_portugal AS 
      (
SELECT fishinserteddupl.fish_id, dbeel_batch_fish.ba_id from fishinserteddupl 
	join sudoang.dbeel_batch_fish on (fishinserteddupl.fish_id,fishinserteddupl.dbeel_ob_id) = (dbeel_batch_fish.fish_id, dbeel_batch_fish.ba_ob_id)
	)

UPDATE sudoang.portugal_fish_bis b
SET ba_id = fish_from_portugal.ba_id
FROM fish_from_portugal
WHERE fish_from_portugal.fish_id = b.fish_id; -- 461 rows
COMMIT;

---- 		Insert LENGTH (no_id = 39)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree) 

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 461 rows
COMMIT;

---- 		Insert WEIGHT (no_id = 42)
BEGIN;
UPDATE sudoang.portugal_fish_bis set ang_pds = NULL WHERE ang_pds = '-';
COMMIT;

BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	round(cast(ang_pds as NUMERIC), 3) AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds::NUMERIC > 0
	and ang_pds is not null
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 460 rows
COMMIT;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
COMMIT;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
COMMIT;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
COMMIT;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" is text
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast is null THEN 0
	     WHEN ang_neuromast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
COMMIT;

---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" is text
BEGIN;
with portugal_fish_extract as (
select * FROM sudoang.portugal_fish_bis
	join sudoang.portugal_ope_bis 	on ang_op_id = op_id
	where isbigpuree)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_constrast is null THEN 0
	     WHEN ang_constrast = 'TRUE' THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM portugal_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_constrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17 rows
commit;



--------------------------------------------------------------------------------------------
-- HARMONIZED SURFACE IN M2 IN dbeel_electrofishing TABLE:
--------------------------------------------------------------------------------------------
select * from sudoang.dbeel_electrofishing limit 10;
select round(coalesce(ef_fished_length::numeric*ef_fished_width::numeric/10000,0), 4) from sudoang.dbeel_electrofishing; -- Surface in ha
-- select * from sudoang.dbeel_electrofishing where ob_id = 'c111e9af-f813-4c8a-a1b5-1488e3e52ee8'; -- length but not width

begin;
with corrected as (
		  select 
		  ob_id,
		  ef_wetted_area,
		  ef_fished_length,
		  ef_fished_width,		    
		  (case when ef_fished_length is not null and ef_fished_width is not null
			then round(coalesce(ef_fished_length::numeric*ef_fished_width::numeric,0), 3)
			when ef_fished_length is null or ef_fished_width is null
			then ef_wetted_area::numeric * 10000
			when ef_fished_length is not null and ef_wetted_area > ef_fished_length
			then ef_wetted_area
			else ef_wetted_area
			END) AS surface_sm
		  from sudoang.dbeel_electrofishing
		  )
--select * from corrected;
update sudoang.dbeel_electrofishing set ef_wetted_area = surface_sm from corrected where corrected.ob_id = dbeel_electrofishing.ob_id; -- 8013 rows
commit;



--------------------------------------------------------------------------------------------
-- ASTURIAS: reprojection and stations
--------------------------------------------------------------------------------------------

select * from sudoang.asturias_location; -- 36 rows
--ALTER TABLE sudoang.asturias_location DROP COLUMN "X";
--ALTER TABLE sudoang.asturias_location DROP COLUMN "X.1";
select count(sta_id) from sudoang.asturias_location; -- 36 rows

---- Reprojection
SELECT Find_SRID('sudoang', 'asturias_location', 'geom'); -- 25830

ALTER TABLE sudoang.asturias_location
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035); -- 3035

CREATE INDEX 
  ON sudoang.asturias_location
  USING gist
  (geom);
  
-- Add geom_reproj
select addgeometrycolumn('sudoang','asturias_location','geom_reproj',3035,'POINT',2);

update sudoang.asturias_location set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.asturias_location s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= asturias_location.sta_id; -- 36 rows

CREATE INDEX 
  ON sudoang.asturias_location
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.asturias_location ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (AST_) from ligne 145 script "dbeel_sudoang_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.asturias_location AS sp1, sudoang.asturias_location AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment
-- select * from dbeel.data_provider

INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('DGPM Asturias'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Lucía García Florez', et_id FROM dbeel.establishment WHERE et_establishment_name = 'DGPM Asturias'
; --TODO: TO BE MODIFIED


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.asturias_location set dbeel_op_id = NULL;
WITH 
projection_asturias AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.asturias_location g
	-- join sudoang.asturias_location on op_sta_id = sta_id
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_asturias AS (
SELECT distinct on (id) * from projection_asturias
)
--SELECT * from closest_asturias; -- 1 row: id = AST_10; place_classification: (ES_35_1771)
UPDATE sudoang.asturias_location SET dbeel_op_id = op_id
	FROM closest_asturias c
	WHERE c.id = asturias_location.id; -- 1 duplicates

/* The only duplicate is ignored:
select * from sudoang.asturias_location where id = 'AST_10'
select * from sudoang.dbeel_station where place_classification = '(ES_35_1771)';
select* from sudoang.dbeel_electrofishing where locationid = '1249093214'; -- ob_starting_date = '2007-09-01'; ob_op_id = 'e78e83e5-07aa-46ae-b690-2f1317226552'
*/

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='FCUL/MARE'; -- 0 rows
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'DGPM Asturias' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.asturias_location
	where dbeel_op_id is null
	; -- 35 lines
commit;

-- We put back the op_id into the source table
begin;
update sudoang.asturias_location set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 36 rows
commit;


--------------------------------------
-- INSERTING OPERATIONS FROM ASTURIAS
--------------------------------------

-- select * from sudoang.asturias_ope limit 10; -- 210 rows

---- Add dbeel_ob_id in asturias_ope table
ALTER TABLE sudoang.asturias_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select asturias_location.dbeel_op_id, asturias_location.id, asturias_ope.* from sudoang.asturias_location 
	join sudoang.asturias_ope on asturias_location.sta_id = asturias_ope.op_sta_id -- 210 rows
)-- joining the two tables on the asturias side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 0 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select asturias_location.dbeel_op_id, asturias_location.id, asturias_ope.* from sudoang.asturias_location 
	join sudoang.asturias_ope on asturias_location.sta_id = asturias_ope.op_sta_id -- 210 rows
)-- joining the two tables on the asturias side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 0 rows

-- for those lines where there is a join, add ob_id in asturias tables
ALTER TABLE sudoang.asturias_ope ADD COLUMN is_duplicate boolean;
-- update sudoang.asturias_ope set is_duplicate = FALSE;  -- 210 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from sudoang.asturias_ope; -- 210 rows
select count(distinct (op_sta_id,op_dat)) from sudoang.asturias_ope; -- 210 operations
select * from sudoang.dbeel_station where op_gis_layername = 'DGPM Asturias'; -- 36 stations

alter table sudoang.asturias_ope add column asturias_ob_id uuid default uuid_generate_v4 ();
alter table sudoang.asturias_ope add column problem_duplicates boolean default false;

/* No duplicates
with duplicates as (
			select asturias_ob_id, count(*) from sudoang.asturias_location 
			join
			sudoang.asturias_ope on asturias_ope.op_sta_id=asturias_location.sta_id group by asturias_ob_id order by count desc
		    ),
burnt as (select asturias_ob_id from duplicates where count > 1)
update sudoang.asturias_ope set problem_duplicates = TRUE where asturias_ob_id in (select asturias_ob_id from burnt); -- 0 rows
*/

begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	asturias_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.asturias_location on dbeel_op_id=op_id
	join
		sudoang.asturias_ope on asturias_ope.op_sta_id = asturias_location.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Lucía García Florez'
	and problem_duplicates = FALSE
	; -- 210 rows
commit;

select * from sudoang.dbeel_electrofishing where ob_id in (select asturias_ob_id from sudoang.asturias_ope); -- 210 rows


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.asturias_ope there is only information about eels ('op_nbeel').

select * from sudoang.asturias_ope where op_length is null or op_width is null; -- 10 rows
select * from sudoang.asturias_ope where (op_length is null or op_width is null) and op_dens > 0; -- 0 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ope.asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.asturias_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	; -- 210 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	asturias_ope.op_dens AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ope.asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.asturias_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	and asturias_ope.op_dens is not null
	; -- 200 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	asturias_ope.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ope.asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.asturias_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	and op_p1 is not null
	; -- 209 rows
commit;


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.asturias_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	and op_p2 is not null -- this will be used for next time but we didn't use it during first integration
	; -- 191 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.asturias_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	and op_p3 is not null
	; -- 188 rows
commit;

-- 			op_p4 (biological_characteristic_type.no_name='Number p4') (see biological_characteristic_type.no_id=234)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p4 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	asturias_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.asturias_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p4' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and problem_duplicates = FALSE
	and op_p4 is not null
	; -- 12 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.asturias_fish add column fish_id serial;
alter table sudoang.asturias_fish add column ba_id uuid;

/* Some rows in fish table are empty, we remove them:
select * from sudoang.asturias_fish where ang_lng is null; -- 11 rows where everything IS NULL
DELETE FROM sudoang.asturias_fish WHERE ang_lng is null; -- 11 rows
*/


---- 		Check duplicates: Joining asturias_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.asturias_fish a join sudoang.asturias_ope o on a.ang_op_id = o.op_id
	join sudoang.dbeel_electrofishing l on l.ob_id = o.asturias_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows

/* Problem wiht silvering state: in most of the lines where the silvering fields are given, the column on the silvering state is false 
select * from sudoang.asturias_fish where ang_silver = FALSE and ang_pect is not null; -- 1120 rows
select * from sudoang.asturias_fish where ang_silver = TRUE and ang_pect is not null; -- 431 rows
*/

----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN ang_silver='FALSE' THEN 226 	--'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 	-- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	asturias_ope.asturias_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	asturias_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.asturias_fish
	join sudoang.asturias_ope
	on asturias_fish.ang_op_id = asturias_ope.op_id	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 12819 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from sudoang.dbeel_station;

with fish_from_asturias as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 21) -- 12819 rows
--select * from fish_from_asturias join sudoang.asturias_fish on fish_from_asturias.fish_id = asturias_fish.fish_id; -- 12819 rows
UPDATE sudoang.asturias_fish b
SET ba_id = fish_from_asturias.ba_id
FROM fish_from_asturias
WHERE fish_from_asturias.fish_id = b.fish_id; -- 12819 rows
-- select * from sudoang.asturias_fish where ba_id is null; -- 0 rows


---- 		Insert LENGTH
begin;
with asturias_fish_extract as (
select * from sudoang.asturias_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 12819 rows (0 rows with length NULL)
commit; 


---- 		Insert WEIGHT
begin;
with asturias_fish_extract as (
select * from sudoang.asturias_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 12819 rows (0 rows with weight NULL)
commit;


---- 		Insert VERTICAL EYE DIAMETER
begin;
with asturias_fish_extract as (
select * from sudoang.asturias_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert > 0
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1551 rows (11268 rows with ang_eye_diam_vert NULL)
commit;


---- 		Insert HORIZONTAL EYE DIAMETER
begin;
with asturias_fish_extract as (
select * from sudoang.asturias_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz > 0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1552 rows (total: 11267 rows)
commit;


---- 		Insert LENGTH OF THE PECTORAL FIN
begin;
with asturias_fish_extract as (
select * from sudoang.asturias_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM asturias_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect > 0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1152 rows (total: 11267 rows)
commit;



--------------------------------------------------------------------------------------------
-- CATALONIA: reprojection and stations
--------------------------------------------------------------------------------------------

select * from sudoang.catalonia_station; -- 300 rows
select count(id_stat) from sudoang.catalonia_station; -- 300 rows
select count(cod_stat) from sudoang.catalonia_station; -- 300 rows


---- Reprojection
SELECT Find_SRID('sudoang', 'catalonia_station', 'geom'); -- 32631

ALTER TABLE sudoang.catalonia_station
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035); -- 3035

CREATE INDEX 
  ON sudoang.catalonia_station
  USING gist
  (geom);
  
-- Add geom_reproj
select addgeometrycolumn('sudoang','catalonia_station','geom_reproj',3035,'POINT',2);

update sudoang.catalonia_station set geom_reproj = sub2.geom_reproj from (
select distinct on (id_stat) id_stat, geom_reproj, distance from(
select
id_stat, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.catalonia_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by id_stat, distance
)sub )sub2
where sub2.id_stat= catalonia_station.id_stat; -- 299 rows (of 300 stations)

CREATE INDEX 
  ON sudoang.catalonia_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.catalonia_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (CAT_) from ligne 134 script "dbeel_sudoang_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.catalonia_station AS sp1, sudoang.catalonia_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment (et_id = 13 = ACA)
-- select * from dbeel.data_provider (dp_id = 11 = Lluis Zamora)


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

-- update sudoang.catalonia_station set dbeel_op_id = NULL;
begin;
WITH 
projection_catalonia AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.catalonia_station g
	-- join sudoang.catalonia_station on op_sta_id = id_stat
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_catalonia AS (
SELECT distinct on (id) * from projection_catalonia
)
-- SELECT * from closest_catalonia; -- 26 rows (one station from GT6, others from SIBIC)
UPDATE sudoang.catalonia_station SET dbeel_op_id = op_id
	FROM closest_catalonia c
	WHERE c.id = catalonia_station.id; -- 26 duplicates
commit;

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='ACA'; -- 0 rows
-- select * from sudoang.dbeel_station limit 10;
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'ACA' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	name_stat as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	cod_stat as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.catalonia_station
	where dbeel_op_id is null
	; -- 274 lines
commit;

-- We put back the op_id into the source table
begin;
update sudoang.catalonia_station set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- rows
commit; -- 274 rows


-----------------------------------
-- INSERTING CATALONIA OPERATIONS
-----------------------------------

select * from sudoang.catalonia_ope limit 10 -- 443 rows

---- Add dbeel_ob_id in catalonia_operation table
ALTER TABLE sudoang.catalonia_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations (there are 26 stations duplicated)
with g_station_operation as(
select catalonia_station.dbeel_op_id, catalonia_station.id, catalonia_ope.* from sudoang.catalonia_station 
	join sudoang.catalonia_ope on catalonia_station.cod_stat = catalonia_ope.cod_stat -- 401 rows
)-- joining the two tables on the catalonia side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 49 rows


-- Checking the duplicates for year: real duplicates
with g_station_operation as(
select catalonia_station.dbeel_op_id, catalonia_station.id, catalonia_ope.* from sudoang.catalonia_station 
	join sudoang.catalonia_ope on catalonia_station.cod_stat = catalonia_ope.cod_stat -- 401 rows
)-- joining the two tables on the catalonia side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (date_ope, dbeel_op_id); -- 0 rows: NO DUPLICATES IN OPE


-- for those lines where there is a join, add ob_id in catalonia tables
ALTER TABLE sudoang.catalonia_ope ADD COLUMN is_duplicate boolean;


---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES
UPDATE sudoang.catalonia_ope SET is_duplicate is FALSE; -- 443 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (cod_stat, date_ope)) from sudoang.catalonia_ope; -- 155 operations
select count(cod_stat) from sudoang.catalonia_ope; -- 443 rows: species catched by row

select distinct id_ope from sudoang.catalonia_ope; -- 140 operations (15 nulls)
select count(id_stat) from sudoang.catalonia_ope; -- 401 rows
select * from sudoang.catalonia_ope where id_stat is null or fihsed_length is null; 
--		The rows without id_stat don't have information about fished surface. So, we remove them:
--delete from sudoang.catalonia_ope where id_stat is null; -- 42 rows

-- 		The id of sudoang.catalonia_ope is 'cod_stat', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'cat_ob_is' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table sudoang.catalonia_ope add column cat_ob_id uuid default uuid_generate_v4 ();
-- 		The cat_ob_id must be updated because it's unique for each row, but each row doesn't correspond with an operation
with test as (
	select  distinct on (id_ope, date_ope) * from sudoang.catalonia_ope order by id_ope, date_ope -- 140 rows
	)
update sudoang.catalonia_ope ope set cat_ob_id = test.cat_ob_id from test where ope.id_ope = test.id_ope -- 401 rows

-- delete from sudoang.dbeel_electrofishing where ob_id in (select cat_ob_id from sudoang.catalonia_ope); -- 401 rows
begin;
with operation as (
	select  distinct on (id_ope, date_ope) * from sudoang.catalonia_ope order by id_ope, date_ope -- 140 rows
	)

INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	cat_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	date_ope AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	fishing_surface AS ef_wetted_area, 
	fihsed_length AS ef_fished_length,
	fihsed_width AS ef_fished_width,
	1 AS ef_nbpas, -- The number of pass isn't indicated
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.catalonia_station on dbeel_op_id=op_id
	join
		operation on operation.cod_stat=catalonia_station.cod_stat
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Lluis Zamora'
	and is_duplicate = FALSE
	; -- 140 rows
commit;

select * from sudoang.dbeel_station where op_gis_layername = 'ACA'; -- 274 stations
-- 274 stations are inserted and only 155 operations!?!?


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
begin;
with anguila as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
nb_indiv,
round(cast(density as numeric)/10000,3) as density
from sudoang.catalonia_ope
where name_species='Anguilla anguilla'), -- 29 rows

other as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
0 as nb_indiv,
0 density
from sudoang.catalonia_ope 
where name_species!='Anguilla anguilla'
and cat_ob_id not in (select cat_ob_id from anguila)), -- 111 rows

electrofishing as (select * from anguila 
union
select * from other 
order by cod_stat)

--select * from electrofishing; -- 140 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_indiv AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.cat_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 140 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with anguila as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
nb_indiv,
round(cast(density as numeric)/10000,3) as density
from sudoang.catalonia_ope
where name_species='Anguilla anguilla'), -- 29 rows

other as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
0 as nb_indiv,
0 density
from sudoang.catalonia_ope 
where name_species!='Anguilla anguilla'
and cat_ob_id not in (select cat_ob_id from anguila)), -- 111 rows

electrofishing as (select * from anguila 
union
select * from other 
order by cod_stat)

--select * from electrofishing order by cod_stat; -- 140 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_indiv AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.cat_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 140 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with anguila as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
nb_indiv,
round(cast(density as numeric)/10000,3) as density
from sudoang.catalonia_ope
where name_species='Anguilla anguilla'), -- 29 rows

other as (
select distinct on (cat_ob_id)
id_ope,
cat_ob_id,
cod_stat,
0 as nb_indiv,
0 density
from sudoang.catalonia_ope 
where name_species!='Anguilla anguilla'
and cat_ob_id not in (select cat_ob_id from anguila)), -- 111 rows

electrofishing as (select * from anguila 
union
select * from other 
order by cod_stat)

--select * from electrofishing order by cod_stat; -- 140 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing.cat_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.catalonia_fish add column fish_id serial;
alter table sudoang.catalonia_fish add column ba_id uuid;

-- 		id_species = 8 corresponds to Anguilla anguilla: the rest of individuals are other species
select * from sudoang.catalonia_fish where id_species = 8; -- 220 rows

select sum(nb_indiv) from sudoang.catalonia_ope where name_species='Anguilla anguilla'; -- 193 rows
select * from sudoang.catalonia_fish where id_species = 8 and id_ope in (
	select distinct id_ope from sudoang.catalonia_ope where name_species='Anguilla anguilla'); -- 193 rows

--delete from sudoang.catalonia_fish where id_species = 8 and id_ope not in (
--	select distinct id_ope from sudoang.catalonia_ope where name_species='Anguilla anguilla'); -- 27 rows
select * from sudoang.catalonia_fish where id_species = 8; -- 193 rows


---- 		Check duplicates: Joining catalonia_fish and dbeel_batch_fish by "cod_stat" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.catalonia_fish a join sudoang.catalonia_ope o on cod_stat = o.cod_stat
	join sudoang.dbeel_electrofishing l on ob_id = o.cat_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = ba_ob_id; -- 0 rows
	
-- delete from sudoang.dbeel_batch_fish where ba_id in (select ba_id from sudoang.catalonia_fish);
-- update sudoang.catalonia_fish set ba_id = null;

/*   There aren't fishes in dbeel_batch_fish from _fish, so this query is not necessary
with l as
	(select * from sudoang.catalonia_fish a join sudoang.catalonia_ope o on a.cod_stat = o.cod_stat
	join sudoang.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id)) --  rows
UPDATE sudoang.catalonia_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; --  rows
*/

----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	begin;	
select distinct on (fish_id) * from sudoang.catalonia_fish where id_species = 8; -- 193 rows

begin;
with anguila as (
select distinct on (fish_id)
fish_id,
a.id_ope,
cat_ob_id as ba_ob_id,
ba_id,
length,
weight,
id_species
from sudoang.catalonia_fish a 
	join sudoang.catalonia_ope o on a.id_ope = o.id_ope
	where id_species = 8)
--SELECT * FROM anguila order by ba_ob_id; -- 193 rows
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ba_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND stage.no_name='Yellow eel' 
	AND value_type.no_name='Raw data or Individual data'; -- 193 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in catalonia_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 

with fish_from_catalonia as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 11) -- Verify that ob_dp_id = 11: 193 rows
--select * from fish_from_catalonia join sudoang.catalonia_fish on fish_from_catalonia.fish_id = catalonia_fish.fish_id; -- 193 rows
UPDATE sudoang.catalonia_fish b
SET ba_id = fish_from_catalonia.ba_id
FROM fish_from_catalonia
WHERE fish_from_catalonia.fish_id = b.fish_id; -- 193 rows
-- select * from sudoang.catalonia_fish where ba_id is null and id_species = 8; -- 0 rows


---- 		Insert LENGTH
begin;
with catalonia_fish_extract as (
select * from sudoang.catalonia_fish where ba_id is NOT null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length,
weight,
id_species
from catalonia_fish_extract)
--select * from anguila; -- 193 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 193 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT
begin;
with catalonia_fish_extract as (
select * from sudoang.catalonia_fish where ba_id is NOT null), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length,
weight,
id_species
from catalonia_fish_extract)
--select * from anguila; -- 193 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 193 rows ( rows with weight NULL)
commit;


--------------------------------------------------------------------------------------------
--  GALICIA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to sudoang schema from public
ALTER TABLE galicia_ope
    SET SCHEMA sudoang;

ALTER TABLE sudoang.galicia_ope RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.galicia_ope
  USING gist
  (geom);
  
-- Reprojection

select st_srid(geom) from sudoang.galicia_ope; -- 3035 (SELECT Find_SRID doesn't work)

select addgeometrycolumn('sudoang','galicia_ope','geom_reproj',3035,'POINT',2);
update sudoang.galicia_ope set geom_reproj = sub2.geom_reproj from (
select distinct on ("cod_stat") "cod_stat", geom_reproj,distance from(
select
"cod_stat", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.galicia_ope s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by "cod_stat", distance
)sub )sub2
where sub2."cod_stat"= galicia_ope."cod_stat"; -- 5032 rows

CREATE INDEX 
  ON sudoang.galicia_ope
  USING gist
  (geom_reproj);

select count(distinct geom_reproj) from sudoang.galicia_ope; -- 3795 rows (total: 5302 rows)

/* sudoang.galicia_ope has several problems:

-- 1. There isn't an ID to identify the stations:
select distinct on (cod_stat) * from sudoang.galicia_ope order by cod_stat; -- 5302 rows = OPERATIONS (NOT code of stations)
ALTER TABLE sudoang.galicia_ope RENAME COLUMN cod_stat TO cod_ope;
ALTER TABLE sudoang.galicia_fish RENAME COLUMN cod_stat TO cod_ope;

select distinct on (sta_id) * from sudoang.galicia_ope order by sta_id; -- 5302 rows = OPERATIONS (NOT code of stations)
ALTER TABLE sudoang.galicia_ope RENAME COLUMN sta_id TO ope_id;

select distinct on (station) * from sudoang.galicia_ope order by station; -- 2232 rows
ALTER TABLE sudoang.galicia_ope RENAME COLUMN station TO stat_ope;

select distinct on (geom) * from sudoang.galicia_ope; -- 3796 (total: 5302 rows)

-- 	Solution: create a table for stations
-- 	For that, the id's ('GAL_') created in the SIBIC.R script is deleted because it's corresponded to operations
	ALTER TABLE sudoang.galicia_ope DROP COLUMN id;
-- 	The table galicia_station is created taken into account the geometry of operations
	CREATE TABLE sudoang.galicia_station AS
		SELECT distinct on (geom) cod_ope, data_source, stat_ope, river, place, province, efi_code, "ZEC", geom, geom_reproj from sudoang.galicia_ope; -- 3796 rows
-- 	Adding the ID: dbeel_sudoang_electrofishing.sql script (175 line)
--	Insert the ID of the station in galicia_ope table:
	ALTER TABLE sudoang.galicia_ope ADD COLUMN id_station text;
	UPDATE sudoang.galicia_ope set id_station = id from sudoang.galicia_station where galicia_station.geom = galicia_ope.geom; -- 5302 rowws

	
-- 2. The number of fish catched in each operation isn't appeared, only the number of pass (nb_pass)
--	Solution: take galicia.fish table and add the number of eels per pass and operation
ALTER TABLE sudoang.galicia_ope ADD COLUMN run1_ang integer;
ALTER TABLE sudoang.galicia_ope ADD COLUMN run2_ang integer;
ALTER TABLE sudoang.galicia_ope ADD COLUMN run3_ang integer;
ALTER TABLE sudoang.galicia_ope ADD COLUMN run4_ang integer;
ALTER TABLE sudoang.galicia_ope ADD COLUMN run5_ang integer;

with run1_anguila as (
select
cod_ope as sampling,
sum(frequency) as run1_anguila
from sudoang.galicia_fish
where species='Anguila' and op_pass = 1 group by sampling), -- 3346 rows

run2_anguila as (
select
cod_ope as sampling2,
sum(frequency) as run2_anguila
from sudoang.galicia_fish
where species='Anguila' and op_pass = 2 group by sampling2), -- 2537 rows

run3_anguila as (
select
cod_ope as sampling3,
sum(frequency) as run3_anguila
from sudoang.galicia_fish
where species='Anguila' and op_pass = 3 group by sampling3), -- 1626 rows

run4_anguila as (
select
cod_ope as sampling4,
sum(frequency) as run4_anguila
from sudoang.galicia_fish
where species='Anguila' and op_pass = 4 group by sampling4), -- 17 rows

run5_anguila as (
select
cod_ope as sampling5,
sum(frequency) as run5_anguila
from sudoang.galicia_fish
where species='Anguila' and op_pass = 5 group by sampling5), -- 1 row

electro as (select coalesce(sampling, sampling2, sampling3, sampling4, sampling5) as sampling, run1_anguila, run2_anguila, run3_anguila, run4_anguila, run5_anguila from run1_anguila 
	FULL OUTER JOIN run2_anguila on sampling = sampling2
	FULL OUTER JOIN run3_anguila on sampling = sampling3
	FULL OUTER JOIN run4_anguila on sampling = sampling4
	FULL OUTER JOIN run5_anguila on sampling = sampling5
)
--select * from electro; -- 3778 rows (compared to 5302 in guipuz_ope table)
update sudoang.galicia_ope
set (run1_ang, run2_ang, run3_ang, run4_ang, run5_ang) = (run1_anguila, run2_anguila, run3_anguila, run4_anguila, run5_anguila) from electro where galicia_ope.cod_ope = electro.sampling; -- 3699 rows
*/


-- to store the link for dbeel
-- ALTER TABLE sudoang.galicia_ope DROP COLUMN dbeel_op_id;
ALTER TABLE sudoang.galicia_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (GAL_) from dbeel_sudoang_electrofishing.sql script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.galicia_station AS sp1, sudoang.galicia_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 internal duplicates


-- select * from dbeel.establishment; -- et_id = 14; 'The Xunta of Galicia'
-- select * from dbeel.data_provider; -- dp_id = 12 : 'Francisco Hervella' (Fernando Tilves Pazos has also participated)

-- duplicate with data already in dbeel
-- we choose the closest station to join with

WITH 
projection_galicia AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.galicia_station g
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_galicia AS (
SELECT distinct on (id) * from projection_galicia
)
--SELECT * from closest_galicia; -- 412 rows
UPDATE sudoang.galicia_station SET dbeel_op_id = op_id
	FROM closest_galicia c
	WHERE c.id=galicia_station.id; -- 412 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='The Xunta of Galicia'; -- 0 rows
-- select * from sudoang.dbeel_station limit 10;
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'The Xunta of Galicia' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	place as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	NULL as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.galicia_station
	where dbeel_op_id is null
	; -- 3384 lines
commit;

-- We put back the op_id into the source table
update sudoang.galicia_station set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 3384 rows


--------------------------------
-- INSERTING GALICIA OPERATIONS
--------------------------------
select * from sudoang.galicia_ope limit 10; -- 5302 rows
---- Add dbeel_ob_id in andalucia_ope table
ALTER TABLE sudoang.galicia_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select galicia_station.dbeel_op_id, galicia_station.id, galicia_ope.* from sudoang.galicia_station 
	join sudoang.galicia_ope on galicia_station.id = galicia_ope.id_station -- 5302 rows
)-- joining the two tables on the galicia side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 439 rows

-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select galicia_station.dbeel_op_id, galicia_station.id, galicia_ope.* from sudoang.galicia_station 
	join sudoang.galicia_ope on galicia_station.id = galicia_ope.id_station -- 5302 rows
)-- joining the two tables on the galicia side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 4 rows

-- for those lines where there is a join, add ob_id in galicia tables
ALTER TABLE sudoang.galicia_ope ADD COLUMN is_duplicate boolean;
-- update sudoang.galicia_ope set is_duplicate = FALSE;  -- 5302 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select galicia_station.dbeel_op_id, galicia_station.id, galicia_ope.* from sudoang.galicia_station 
	join sudoang.galicia_ope on galicia_station.id = galicia_ope.id_station -- 5302 rows
	),-- joining the two tables on the andalucia side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
update sudoang.galicia_ope set is_duplicate = TRUE where id_station in (select id_station from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 4 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from sudoang.galicia_ope; -- 5302 rows
select count(distinct (ope_id,op_dat)) from sudoang.galicia_ope; -- 5300 operations
select count(distinct (id_station,op_dat)) from sudoang.galicia_ope; -- 5300 operations

select * from sudoang.dbeel_station where op_gis_layername = 'The Xunta of Galicia'; -- 3384 stations

alter table sudoang.galicia_ope add column galicia_ob_id uuid default uuid_generate_v4 ();

--delete from sudoang.dbeel_electrofishing where ob_dp_id = 12; -- 5298 rows
--delete from sudoang.galicia_ope where fished_length is null or fished_width is null; -- 33 rows

begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	galicia_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(galicia_ope.fished_length * galicia_ope.fished_width) AS ef_wetted_area, 
	galicia_ope.fished_length AS ef_fished_length,
	fished_width AS ef_fished_width,
	nb_pass AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.galicia_station on dbeel_op_id=op_id
	join
		sudoang.galicia_ope on galicia_ope.id_station = galicia_station.id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Francisco Hervella'
	and is_duplicate = FALSE
	; -- 5263 rows
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2, run3, run4, run5 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.galicia_ope the information about the number of eels catched per pass is calculated: 4973 line

/* Errors with froeign key and the restriction of the unicity. It has been corrected by removing the electrofishing without information for the surface.	
--DELETE FROM sudoang.galicia_ope WHERE cod_ope = 'INVANG13_056';

ALTER TABLE sudoang.galicia_ope DROP COLUMN galicia_ob_id;
alter table sudoang.galicia_ope add column galicia_ob_id uuid default uuid_generate_v4 ();
*/

with duplicates as (
	Select galicia_station.dbeel_op_id, galicia_station.id, galicia_ope.* from sudoang.galicia_station 
	join sudoang.galicia_ope on galicia_station.id = galicia_ope.id_station -- 5302 rows
	),-- joining the two tables on the galicia side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id, ef_fished_length) = (op_dat, dbeel_op_id, fished_length)
	)
--select * from op_duplicates; -- 5267 rows
update sudoang.galicia_ope set galicia_ob_id = ob_id from op_duplicates od where galicia_ope.op_dat = od.op_dat and galicia_ope.cod_ope = od.cod_ope; -- 5267 rows
select galicia_ob_id, is_duplicate, count(*) from sudoang.galicia_ope group by galicia_ob_id, is_duplicate having count(*) > 1; -- 0 row

select * from sudoang.galicia_ope where galicia_ob_id not in (select ob_id from sudoang.dbeel_electrofishing where ob_dp_id = 12) -- 4 duplicates

begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from sudoang.galicia_ope),

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5
from surface)
--select * from anguila order by cod_ope; -- 5267 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run1 + anguila.run2 + anguila.run3 + anguila.run4 + anguila.run5 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 5263 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from sudoang.galicia_ope),

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 5267 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 5263 rows
commit;
-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from sudoang.galicia_ope where nb_pass >= 2), -- 4607 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 5267 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 4603 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from sudoang.galicia_ope where nb_pass >= 3), -- 3604 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 3604 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 3600 rows
commit;

-- 			op_p4 (biological_characteristic_type.no_name='Number p4') (see biological_characteristic_type.no_id=234)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from sudoang.galicia_ope where nb_pass >= 4), -- 44 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 44 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run4 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p4' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 44 rows
commit;

-- 			op_p5 (biological_characteristic_type.no_name='Number p5') (see biological_characteristic_type.no_id=235)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from sudoang.galicia_ope where nb_pass >= 5), -- 1 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila order by cod_ope; -- 1 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.run5 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p5' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 1 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with surface as(
SELECT *, coalesce((galicia_ope.fished_length * galicia_ope.fished_width), 0) as surface
from sudoang.galicia_ope), -- 5267 rows

anguila as (
select
galicia_ob_id,
cod_ope,
id_station,
is_duplicate,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(run4_ang,0) as run4,
coalesce(run5_ang,0) as run5,
case
	when
	coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0) = 0 then 0
	else
	round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0)) / surface as numeric), 3)
	end as density
from surface)
--select * from anguila where density > 0; -- 3658 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	anguila.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	anguila.galicia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	anguila, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and density > 0
	and is_duplicate = FALSE
	; -- 3658 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.galicia_fish add column fish_id serial;
alter table sudoang.galicia_fish add column ba_id uuid;

select sum((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0))) as quantity from sudoang.galicia_ope; -- 50 035 rows
select count(*) from sudoang.galicia_fish; -- 44 191 rows

---- 		Check duplicates: Joining galicia_fish and dbeel_batch_fish by "cod_ope" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.galicia_fish a join sudoang.galicia_ope o on a.cod_ope = o.cod_ope
	join sudoang.dbeel_electrofishing l on ob_id = o.galicia_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = ba_ob_id; -- 0 rows

/*   There aren't fishes in dbeel_batch_fish from _fish, so this query is not necessary
with l as
	(select * from sudoang.galicia_fish a join sudoang.galicia_ope o on a.cod_ope = o.cod_ope
	join sudoang.dbeel_electrofishing l on l.ob_id = o.dbeel_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id)) --  rows
UPDATE sudoang.galicia_fish b
SET ba_id = l.ba_id
FROM l
WHERE l.fish_id = b.fish_id; --  rows
*/


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	begin;	
select distinct on (fish_id) * from sudoang.galicia_fish; -- 44 191 rows

begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN stage='Amarilla' THEN 226 	--'Yellow eel' 
	     WHEN stage='Plateada' THEN 227 	-- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	galicia_ope.galicia_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	galicia_fish.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.galicia_fish
	join sudoang.galicia_ope
	on galicia_fish.cod_ope = galicia_ope.cod_ope	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 43 897 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in catalonia_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 

with fish_from_galicia as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 12) -- Verify that ob_dp_id = 12: 43 897 rows
--select * from fish_from_galicia join sudoang.galicia_fish on fish_from_galicia.fish_id = galicia_fish.fish_id; -- 43 897 rows
UPDATE sudoang.galicia_fish b
SET ba_id = fish_from_galicia.ba_id
FROM fish_from_galicia
WHERE fish_from_galicia.fish_id = b.fish_id; -- 43897 rows
-- select cod_ope from sudoang.galicia_fish where ba_id is null; -- 294 rows: the cod_ope doesn't appear in galicia_ope table!


---- 		Insert LENGTH (no_id = 39)
begin;
with galicia_fish_extract as (
select * from sudoang.galicia_fish where ba_id is not null) -- 43 897 rows

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length AS bc_numvalue,
	fish_id
	FROM galicia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 43337 rows (560 empty rows)
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with galicia_fish_extract as (
select * from sudoang.galicia_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM galicia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 43337 rows (560 empty rows)
commit;



--------------------------------------------------------------------------------------------
--  BASQUE COUNTRY: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to sudoang schema from public
ALTER TABLE bc_station
    SET SCHEMA sudoang;

ALTER TABLE sudoang.bc_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.bc_station
  USING gist
  (geom);


select * from sudoang.bc_station; -- 179 rows
select count(sta_id) from sudoang.bc_station; -- 179 rows

---- Reprojection
select st_srid(geom) from sudoang.bc_station; -- 3035

-- Add geom_reproj
select addgeometrycolumn('sudoang','bc_station','geom_reproj',3035,'POINT',2);

update sudoang.bc_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.bc_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= bc_station.sta_id; -- 179 rows

CREATE INDEX 
  ON sudoang.bc_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.bc_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (BAS_) from R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.bc_station AS sp1, sudoang.bc_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- "BAS_163"; "BAS_164" internal duplicates

-- add establishment
-- select * from dbeel.establishment
-- select * from dbeel.data_provider

INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('ANBIOTEK'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'ALberto Aguirre', et_id FROM dbeel.establishment WHERE et_establishment_name = 'ANBIOTEK'
; --TODO: TO BE MODIFIED


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.bc_station set dbeel_op_id = NULL;
WITH 
projection_bc AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.bc_station g
	-- join sudoang.bc_station on op_sta_id = sta_id
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_bc AS (
SELECT distinct on (id) * from projection_bc
)
--SELECT * from closest_bc; -- 19 rows
UPDATE sudoang.bc_station SET dbeel_op_id = op_id
	FROM closest_bc c
	WHERE c.id = bc_station.id; -- 19 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='FCUL/MARE'; -- 0 rows
select * from sudoang.bc_station;
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'ANBIOTEK' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.bc_station
	where dbeel_op_id is null
	; -- 160 lines
commit;

-- We put back the op_id into the source table
begin;
update sudoang.bc_station set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 160 rows
commit;


---------------------------------------
-- INSERTING BASQUE COUNTRY OPERATIONS
---------------------------------------

select * from sudoang.bc_ope limit 10;
select op_dat from sudoang.bc_ope order by op_dat

---- Add dbeel_ob_id in bc_ope table
ALTER TABLE sudoang.bc_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select bc_station.dbeel_op_id, bc_station.id, bc_ope.* from sudoang.bc_station 
	join sudoang.bc_ope on bc_station.sta_id = bc_ope.op_sta_id -- 885 rows
)-- joining the two tables on the basque country side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 734 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select bc_station.dbeel_op_id, bc_station.id, bc_ope.* from sudoang.bc_station 
	join sudoang.bc_ope on bc_station.sta_id = bc_ope.op_sta_id -- 885 rows
)-- joining the two tables on the asturias side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 0 rows

-- for those lines where there is a join, add ob_id in basque country tables
ALTER TABLE sudoang.bc_ope ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES
update sudoang.bc_ope set is_duplicate = FALSE;  -- 885 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from sudoang.bc_ope; -- 885 rows
select count(distinct (op_sta_id,op_dat)) from sudoang.bc_ope; -- 885 operations
select * from sudoang.dbeel_station where op_gis_layername = 'ANBIOTEK'; -- 160 stations

alter table sudoang.bc_ope add column bc_ob_id uuid default uuid_generate_v4 ();


begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	bc_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.bc_station on dbeel_op_id=op_id
	join
		sudoang.bc_ope on bc_ope.op_sta_id = bc_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='ALberto Aguirre'
	; -- 885 rows
commit;

select * from sudoang.dbeel_electrofishing where ob_id in (select bc_ob_id from sudoang.bc_ope); -- 885 rows


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.asturias_ope there is only information about eels ('op_nbeel').

select * from sudoang.bc_ope where op_length is null or op_width is null; -- 0 rows
select * from sudoang.bc_ope where (op_length is null or op_width is null) and op_dens > 0; -- 0 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ope.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.bc_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 885 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	bc_ope.op_dens AS ba_quantity, -- nbeel/surface * 100
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ope.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.bc_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and bc_ope.op_dens is not null
	; -- 885 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	bc_ope.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ope.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.bc_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and op_p1 is not null
	; -- 885 rows
commit;


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.bc_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and op_p2 is not null
	; -- 885 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.bc_fish add column fish_id serial;
alter table sudoang.bc_fish add column ba_id uuid;


---- 		Check duplicates: Joining bc_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.bc_fish a join sudoang.bc_ope o on a.ang_op_id = o.op_id
	join sudoang.dbeel_electrofishing l on l.ob_id = o.bc_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	bc_ope.bc_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	bc_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.bc_fish
	join sudoang.bc_ope
	on bc_fish.ang_op_id = bc_ope.op_id	

	WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel'  
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 5972 rows
commit;

-- Add silvering information in bc_fish table
begin;
update sudoang.bc_fish bc set (pectoral_fin_mm, horiz_diam_mm, vert_diam_mm, back_color, belly_color, lateral_line) = 
	(si.pectoral_fin_mm, si.horiz_diam_mm, si.vert_diam_mm, si.back_color, si.belly_color, si.lateral_line) 
	from sudoang.bc_silv si where bc.ang_op_id = si.ang_op_id::TEXT and bc.ang_lng_cm = si.ang_lng_cm and bc.ang_pds_estimated_g = si.ang_pds_estimated_g -- 219 rows
commit;

-- Update fish_id from dbeel into bc_fish table
begin;
WITH fish_ope AS	(
			select (ang_lng_cm*10) as bc_length, * from sudoang.bc_fish a join sudoang.bc_ope o on a.ang_op_id = o.op_id -- 5972 rows
			),

dbeel as		(
			SELECT ob_id, ba_id, bc_id, bc_numvalue as length, dbeel_mensurationindiv_biol_charac.fish_id FROM 
			sudoang.dbeel_electrofishing join sudoang.dbeel_batch_fish on ba_ob_id = ob_id join 
			sudoang.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id 
			join dbeel_nomenclature.biological_characteristic_type nn on no_id = bc_no_characteristic_type
			where no_name = 'Length' and ob_dp_id = 23 -- 9137 rows (bc_fish + bc_fish_bis)
			),
 
dbeel_fish as 		(
			select distinct on (dbeel.fish_id) ang_op_id, ang_lng_cm, op_id, ob_id, dbeel.ba_id, bc_id, dbeel.fish_id, pectoral_fin_mm from fish_ope 
			join dbeel on (fish_ope.bc_length, fish_ope.bc_ob_id) = (length, ob_id)
			)
--select * from dbeel_fish where pectoral_fin_mm is not null; -- 219 rows
UPDATE sudoang.bc_fish a
SET fish_id = b.fish_id
FROM dbeel_fish b
WHERE (a.ang_lng_cm, a.ang_op_id) = (b.ang_lng_cm, b.op_id); -- 5972 rows


-- Update ba_id from dbeel into bc_fish table
WITH fish_ope AS	(
			select (ang_lng_cm*10) as bc_length, * from sudoang.bc_fish a join sudoang.bc_ope o on a.ang_op_id = o.op_id -- 5972 rows
			),

dbeel as		(
			select dbeel_batch_fish.*, fish_ope.op_id, fish_ope.ang_lng_cm from sudoang.dbeel_batch_fish join fish_ope on (fish_ope.fish_id, bc_ob_id) = (dbeel_batch_fish.fish_id, ba_ob_id)
			)
--select * from dbeel; -- 5972 rows
UPDATE sudoang.bc_fish a
SET ba_id = b.ba_id
FROM dbeel b
WHERE (a.fish_id, a.ang_lng_cm, a.ang_op_id) = (b.fish_id, b.ang_lng_cm, b.op_id); -- 5972 rows

/* Test not working
WITH fish_ope AS	(
			select * from sudoang.bc_fish a join sudoang.bc_ope o on a.ang_op_id = o.op_id -- 5972 rows
			),		
fish_count_basque as 	(
			SELECT *, row_number() OVER(PARTITION BY bc_ob_id, ang_lng_cm, ang_pds_estimated_g ORDER BY ang_lng_cm desc) FROM fish_ope -- 5972 rows
			),
dbeel_l as 		(
			SELECT ob_id, ba_id, bc_id, bc_numvalue as length FROM 
			sudoang.dbeel_electrofishing join sudoang.dbeel_batch_fish on ba_ob_id = ob_id join 
			sudoang.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id 
			join dbeel_nomenclature.biological_characteristic_type nn on no_id = bc_no_characteristic_type
			where no_name = 'Length' and ob_dp_id = 23 -- 9137 rows (bc_fish + bc_fish_bis)
			),
dbeel_w as 		(
			SELECT ob_id, ba_id, bc_id, bc_numvalue as weight FROM 
			sudoang.dbeel_electrofishing join sudoang.dbeel_batch_fish on ba_ob_id = ob_id join 
			sudoang.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id 
			join dbeel_nomenclature.biological_characteristic_type nn on no_id = bc_no_characteristic_type
			where no_name = 'Weight' and ob_dp_id = 23 -- 9137 rows (bc_fish + bc_fish_bis)
			),
dbeel as 		(
			select l.*, weight from dbeel_l l join dbeel_w w on l.ba_id = w.ba_id
			),
fish_count_dbeel as 	(
			SELECT *, row_number() OVER(PARTITION BY ob_id, length, weight) FROM dbeel -- 9137 rows (bc_fish + bc_fish_bis)
			)
select db.ba_id,  length, weight, cb.* from fish_count_dbeel db join fish_count_basque cb on 
	(cb.row_number, cb.bc_ob_id,ang_lng_cm, ang_pds_estimated_g) = (db.row_number, db.ob_id, length, weight)
	where pectoral_fin_mm is not null or horiz_diam_mm is not null or vert_diam_mm is not Null or back_color is not null or belly_color is not null or lateral_line is not null
; -- 0 rows
*/

---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from sudoang.dbeel_station;

with fish_from_bc as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 23) -- 5972 rows
--select * from fish_from_bc join sudoang.bc_fish on fish_from_bc.fish_id = bc_fish.fish_id; -- 5972 rows
UPDATE sudoang.bc_fish b
SET ba_id = fish_from_bc.ba_id
FROM fish_from_bc
WHERE fish_from_bc.fish_id = b.fish_id; -- 5972 rows
-- select * from sudoang.bc_fish where ba_id is null; -- 9 rows


---- 		Insert LENGTH
begin;
with bc_fish_extract as (
select * from sudoang.bc_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng_cm AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng_cm >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 5972 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT
begin;
with bc_fish_extract as (
select * from sudoang.bc_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds_estimated_g AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds_estimated_g >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 5972 rows (0 rows with weight NULL)
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262) (mm)
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	vert_diam_mm AS bc_numvalue,
	fish_id
	FROM sudoang.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE vert_diam_mm IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263) (mm)
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	horiz_diam_mm AS bc_numvalue,
	fish_id
	FROM sudoang.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE horiz_diam_mm is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264) (mm)
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	pectoral_fin_mm AS bc_numvalue,
	fish_id
	FROM sudoang.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE pectoral_fin_mm is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;

---- 		Insert CONTRAST COLORS (no_id = 266)
alter table sudoang.bc_fish add column ang_contrast boolean;
update sudoang.bc_fish 
set ang_contrast = case
    when back_color = 'NG' or back_color = 'OS' and belly_color = 'BL' or belly_color = 'PL' then true
    when back_color = 'PR' or back_color = 'OR'or back_color = 'OS' and belly_color = 'BA' or belly_color = 'AM' or belly_color = 'BL'  then false
   else null
end;

begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_contrast = FALSE THEN 0
	     WHEN ang_contrast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM sudoang.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_contrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "lateral_line" from bc_fish is text, it must be converted into boolean:
alter table sudoang.bc_fish
alter column lateral_line
set data type boolean
using case
    when lateral_line = 1 or lateral_line = 2 then true
    when lateral_line = 0 then false
    else null
end;

begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN lateral_line = FALSE THEN 0
	     WHEN lateral_line = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM sudoang.bc_fish,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and lateral_line is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 219 rows
commit;



--------------------------------------------------------------------------------------------
--  BASQUE COUNTRY BIS: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to sudoang schema from public
ALTER TABLE bc_station_bis
    SET SCHEMA sudoang;

ALTER TABLE sudoang.bc_station_bis RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.bc_station_bis
  USING gist
  (geom);


select * from sudoang.bc_station_bis; -- 128 rows
select  distinct sta_id from sudoang.bc_station_bis; -- 116 rows
select  distinct (dbeel_op_id) dbeel_op_id from sudoang.bc_station_bis; -- 116 rows
---- Reprojection
select st_srid(geom) from sudoang.bc_station_bis; -- 3035

-- Add geom_reproj
select addgeometrycolumn('sudoang','bc_station_bis','geom_reproj',3035,'POINT',2);

update sudoang.bc_station_bis set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj, distance from(
select
sta_id, 
ST_ClosestPoint(r.geom, s.geom) as geom_reproj,
ST_distance(r.geom, s.geom) as distance
from sudoang.bc_station_bis s join
spain.rn r on st_dwithin(r.geom, s.geom, 300) 
order by sta_id, distance
) sub) sub2
where sub2.sta_id= bc_station_bis.sta_id; -- 128 rows

CREATE INDEX 
  ON sudoang.bc_station_bis
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.bc_station_bis ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (BAS_) from R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.bc_station_bis AS sp1, sudoang.bc_station_bis AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 14 internal duplicates

-- add establishment
-- select * from dbeel.establishment -- 24: ANBIOTEK
-- select * from dbeel.data_provider -- 23: Alberto Aguirre


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.bc_station_bis set dbeel_op_id = NULL;
WITH 
projection_bc AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.bc_station_bis g
	-- join sudoang.bc_station_bis on op_sta_id = sta_id
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_bc AS (
SELECT distinct on (id) * from projection_bc
)
--SELECT * from closest_bc; -- 70 rows
UPDATE sudoang.bc_station_bis SET dbeel_op_id = op_id
	FROM closest_bc c
	WHERE c.id = bc_station_bis.id; -- 70 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='ANBIOTEK'; -- 160 rows
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'ANBIOTEK' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	null as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	sta_basin as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.bc_station_bis
	where dbeel_op_id is null
	; -- 58 lines
commit;

-- We put back the op_id into the source table
update sudoang.bc_station_bis set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 58 rows


-------------------------------------------
-- INSERTING BASQUE COUNTRY OPERATIONS BIS
-------------------------------------------

select * from sudoang.bc_ope_bis; -- 324 rows
select op_dat from sudoang.bc_ope_bis order by op_dat; -- 2002/2009

---- Add dbeel_ob_id in bc_ope table
ALTER TABLE sudoang.bc_ope_bis ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id -- 275 rows
)-- joining the two tables on the basque country side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 273 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id -- 275 rows
)-- joining the two tables on the basque country side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 1 rows

-- for those lines where there is a join, add ob_id in basque country tables
ALTER TABLE sudoang.bc_ope_bis ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES
update sudoang.bc_ope_bis set is_duplicate = FALSE;  -- 324 rows

with duplicates as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id -- 275 rows
	),-- joining the two tables on the basque country side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates; -- 1 rows
update sudoang.bc_ope_bis set is_duplicate = TRUE where op_id in (select op_id from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 1 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)

select * from sudoang.bc_ope_bis; -- 324 rows
select count(distinct (op_sta_id,op_dat)) from sudoang.bc_ope_bis; -- 324 operations
select * from sudoang.dbeel_station where op_gis_layername = 'ANBIOTEK'; -- 218 stations

alter table sudoang.bc_ope_bis add column bc_ob_id uuid default uuid_generate_v4 ();

/* In bc_station_bis there are duplicated rows!
begin;
WITH uniques AS
    (SELECT DISTINCT ON (dbeel_op_id, geom_reproj) * FROM sudoang.bc_station_bis) -- 124 rows
DELETE FROM sudoang.bc_station_bis WHERE sudoang.bc_station_bis.id NOT IN (SELECT id FROM uniques); -- 4rows
commit;

begin;
WITH uniques AS
    (SELECT DISTINCT ON (sta_id) * FROM sudoang.bc_station_bis) -- 116 rows
DELETE FROM sudoang.bc_station_bis WHERE sudoang.bc_station_bis.id NOT IN (SELECT id FROM uniques); -- 8rows
commit;
*/
begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	bc_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	op_surface_m2 AS ef_wetted_area, 
	null AS ef_fished_length,
	null AS ef_fished_width,
	nb_pass AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.bc_station_bis on dbeel_op_id = op_id
	join
		sudoang.bc_ope_bis on bc_ope_bis.op_sta_id = bc_station_bis.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='ALberto Aguirre'
	and is_duplicate = FALSE
	; -- 252 rows
commit;

select * from sudoang.dbeel_electrofishing where ob_id in (select bc_ob_id from sudoang.bc_ope_bis); -- 252 rows





-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2, run3 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-
select * from sudoang.bc_ope_bis where op_surface_m2 is null; -- 0 rows
select * from sudoang.bc_ope_bis where op_surface_m2 is null and op_nb_eels > 0; -- 0 rows

-- There is one row with density but no number of eels, so remove it!
--DELETE FROM sudoang.bc_ope_bis WHERE op_nb_eels is null; -- 1rows

BEGIN;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id
	) -- 252 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 251 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
-- 			Density is calculated with different methods: estimation_method (Relative abundance, Seber Lecren, Carle Strab)
BEGIN;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id
	) -- 252 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	round(coalesce(uniques.op_dens_nha::NUMERIC/10000,0),3) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	uniques, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 251 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id
	) -- 252 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	uniques.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	uniques, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 251 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id where nb_pass >= 2
	) -- 224 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 223 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id where nb_pass >= 3
	) -- 11 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 11 rows
commit;




select * from sudoang.bc_ope_bis 
except select * from sudoang.bc_ope_bis 
where op_sta_id in (select sta_id from sudoang.bc_station_bis); -- 71 rows

select * from sudoang.bc_station_bis 
--except select * from sudoang.bc_ope_bis 
where sta_id in (select op_sta_id from sudoang.bc_ope_bis);




---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.bc_fish_bis add column fish_id serial;
alter table sudoang.bc_fish_bis add column ba_id uuid;

---- 		Check duplicates: Joining bc_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select count(*) from sudoang.bc_fish_bis; -- 3790 rows
select sum(op_nb_eels) from sudoang.bc_ope_bis; -- 3771 roxs

select * from sudoang.bc_fish_bis a join sudoang.bc_ope_bis o on ang_op_id = op_id -- 3758 rows
	join sudoang.dbeel_electrofishing l on l.ob_id = o.bc_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;
with uniques as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from sudoang.bc_station_bis 
	join sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id
	) -- 11 rows
	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	bc_fish_bis.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.bc_fish_bis
	join uniques
	on ang_op_id = op_id	

	WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel'  
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 3174 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
with fish_from_bc as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 23
	and ob_starting_date in (select op_dat from sudoang.bc_ope_bis where is_duplicate = FALSE) -- ba_id is repeated because fish_id is the same in bc_fish table and bc_fish_bis
) -- 3174 rows
--select * from fish_from_bc join sudoang.bc_fish_bis on fish_from_bc.fish_id = bc_fish_bis.fish_id; -- 3174 rows
UPDATE sudoang.bc_fish_bis b
SET ba_id = fish_from_bc.ba_id
FROM fish_from_bc
WHERE fish_from_bc.fish_id = b.fish_id; -- 3174 rows
-- select * from sudoang.bc_fish_bis where ba_id is null; -- 616 rows

/* There are 9 rows that are more than one individual: nag_nb_indiv > 1 (with length and weigth as a mean): Remove them!
delete from sudoang.dbeel_batch_fish where ba_id in (select ba_id from sudoang.bc_fish_bis where ang_nb_indiv > 1); -- 9 rows
update sudoang.bc_fish_bis set ba_id = NULL where ang_nb_indiv > 1;  -- 9 rows
*/
---- 		Insert LENGTH
begin;
with bc_fish_extract as (
select * from sudoang.bc_fish_bis where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_length_cm AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_length_cm > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3165 rows
commit; 


---- 		Insert WEIGHT
begin;
with bc_fish_extract as (
select * from sudoang.bc_fish_bis where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds_g AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds_g > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3165 rows
commit;




--------------------------------------------------------------------------------------------
--  NAVARRA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to sudoang schema from public
ALTER TABLE navarra_station
    SET SCHEMA sudoang;

ALTER TABLE sudoang.navarra_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.navarra_station
  USING gist
  (geom);


select * from sudoang.navarra_station; -- 12 rows
select count(sta_id) from sudoang.navarra_station; -- 12 rows

---- Reprojection
select st_srid(geom) from sudoang.navarra_station; -- 3035

  
-- Add geom_reproj
select addgeometrycolumn('sudoang','navarra_station','geom_reproj',3035,'POINT',2);

update sudoang.navarra_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.navarra_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= navarra_station.sta_id; -- 12 rows

CREATE INDEX 
  ON sudoang.navarra_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.navarra_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (NAV_) from R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.navarra_station AS sp1, sudoang.navarra_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment
-- select * from dbeel.data_provider

INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('The Navarra Environmental Management'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Josu Iñaki Elso Huarte', et_id FROM dbeel.establishment WHERE et_establishment_name = 'The Navarra Environmental Management'
; --TODO: TO BE MODIFIED


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.navarra_station set dbeel_op_id = NULL;
WITH 
projection_navarra AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.navarra_station g
	-- join sudoang.navarra_station on op_sta_id = sta_id
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_navarra AS (
SELECT distinct on (id) * from projection_navarra
)
--SELECT * from closest_navarra; -- 9 rows
UPDATE sudoang.navarra_station SET dbeel_op_id = op_id
	FROM closest_navarra c
	WHERE c.id = navarra_station.id; -- 9 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='The Navarra Environmental Management'; -- 0 rows
-- select * from sudoang.navarra_station;
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'The Navarra E. M.' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS op_op_id,
	geom as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_cod as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.navarra_station
	where dbeel_op_id is null
	; -- 3 lines
commit;

-- We put back the op_id into the source table
begin;
update sudoang.navarra_station set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 3 rows
commit;

------------------------------
-- INSERTING NAVARRA OPERATIONS
------------------------------
select * from sudoang.navarra_ope limit 10;
---- Add dbeel_ob_id in navarra_ope table
ALTER TABLE sudoang.navarra_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select navarra_station.dbeel_op_id, navarra_station.id, navarra_ope.* from sudoang.navarra_station 
	join sudoang.navarra_ope on navarra_station.sta_id = navarra_ope.op_sta_id -- 66 rows
)-- joining the two tables on the navarra side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 112 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select navarra_station.dbeel_op_id, navarra_station.id, navarra_ope.* from sudoang.navarra_station 
	join sudoang.navarra_ope on navarra_station.sta_id = navarra_ope.op_sta_id -- 210 rows
)-- joining the two tables on the navarra side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) order by is_duplicate -- 9 rows

-- for those lines where there is a join, add ob_id in navarra tables
ALTER TABLE sudoang.navarra_ope ADD COLUMN is_duplicate boolean;
-- update sudoang.navarra_ope set is_duplicate = FALSE;  -- 66 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select navarra_station.dbeel_op_id, navarra_station.id, navarra_ope.* from sudoang.navarra_station 
	join sudoang.navarra_ope on navarra_station.sta_id = navarra_ope.op_sta_id -- 66 rows
	),-- joining the two tables on the navarra side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)

select * from op_duplicates order by is_duplicate; -- 9 rows
update sudoang.navarra_ope set is_duplicate = TRUE where op_cod in (select op_cod from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 9 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from sudoang.navarra_ope; -- 66 rows
select count(distinct (op_sta_id,op_dat)) from sudoang.navarra_ope; -- 66 operations
select * from sudoang.dbeel_station where op_gis_layername = 'The Navarra E. M.'; -- 3 stations

alter table sudoang.navarra_ope add column navarra_ob_id uuid default uuid_generate_v4 ();


begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	navarra_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.navarra_station on dbeel_op_id=op_id
	join
		sudoang.navarra_ope on navarra_ope.op_sta_id = navarra_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Josu Iñaki Elso Huarte'
	and is_duplicate = FALSE
	; -- 57 rows
commit;

select * from sudoang.dbeel_electrofishing where ob_id in (select navarra_ob_id from sudoang.navarra_ope); -- 57 rows


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.asturias_ope there is only information about eels ('op_nbeel').

select * from sudoang.navarra_ope where op_length is null or op_width is null; -- 0 rows
select * from sudoang.navarra_ope where (op_length is null or op_width is null) and op_dens > 0; -- 0 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	navarra_ope.navarra_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.navarra_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 57 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	navarra_ope.op_dens AS ba_quantity, -- It is not nb/m2! (may be c&s?)
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	navarra_ope.navarra_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.navarra_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	and navarra_ope.op_dens is not null
	; -- 57 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	navarra_ope.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	navarra_ope.navarra_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.navarra_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	and op_p1 is not null
	; -- 57 rows
commit;


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	navarra_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.navarra_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	and op_p2 is not null
	; -- 11 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.navarra_fish add column fish_id serial;
alter table sudoang.navarra_fish add column ba_id uuid;


---- 		Check duplicates: Joining navarra_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.navarra_fish a join sudoang.navarra_ope o on a.ang_op_id = o.op_id
	join sudoang.dbeel_electrofishing l on l.ob_id = o.navarra_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows

/*  
select * from sudoang.navarra_fish where ang_silver = FALSE; -- 446 rows
select * from sudoang.navarra_fish where ang_silver = TRUE; -- 287 rows
*/

----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy

/* ERROR: insertion or update in the table  «dbeel_batch_fish» violates foreign key «c_fk_fi_ob_id»
   DETAIL:  The key (ba_ob_id)=(ead4d27d-b9cd-4532-b861-20681b23464f) is not present in the table «dbeel_electrofishing»

select * from sudoang.dbeel_electrofishing where ob_op_id = 'a3d7c74e-8bd8-4075-a130-b0a27ab18a8a';
select * from sudoang_navarra_ope where navarra_ob_id = 'ead4d27d-b9cd-4532-b861-20681b23464f';

The error was that navarra_ob_id from navarra_ope didn't correspond with the ob_id from dbeel_electrofishing for duplicates (is_duplicate = TRUE).
The error has been corrected (following lines)
*/
begin;
with duplicates as (
	Select navarra_station.dbeel_op_id, navarra_station.id, navarra_ope.* from sudoang.navarra_station 
	join sudoang.navarra_ope on navarra_station.sta_id = navarra_ope.op_sta_id -- 66 rows
	),-- joining the two tables on the navarra side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates order by is_duplicate; -- 
update sudoang.navarra_ope set navarra_ob_id = ob_id from op_duplicates od where navarra_ope.op_dat = od.op_dat and navarra_ope.op_cod = od.op_cod;
commit;

begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN ang_silver='FALSE' THEN 226 	--'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 	-- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	navarra_ope.navarra_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	navarra_fish.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.navarra_fish
	join sudoang.navarra_ope
	on navarra_fish.ang_op_id = navarra_ope.op_id	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 3973 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length, weight, silvering, pect_eye_diam_vert, ang_diam_horiz
---- 		To integrate length and weight of fish, "ba_id" must be included before in navarra_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in navarra_fish table! 

with fish_from_navarra as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 24) -- 3627 rows
-- select * from fish_from_navarra join sudoang.navarra_fish on fish_from_navarra.fish_id = navarra_fish.fish_id; -- 3627 rows
UPDATE sudoang.navarra_fish b
SET ba_id = fish_from_navarra.ba_id
FROM fish_from_navarra
WHERE fish_from_navarra.fish_id = b.fish_id; -- 3627 rows
-- select * from sudoang.navarra_fish where ba_id is null; -- 346 rows


---- 		Insert LENGTH (no_id = 39)
begin;
with navarra_fish_extract as (
select * from sudoang.navarra_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3627 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with navarra_fish_extract as (
select * from sudoang.navarra_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 662 rows (3239 rows with weight NULL)
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
with navarra_fish_extract as (
select * from sudoang.navarra_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 659 rows (3259 rows with ang_eye_diam_vert NULL)
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
with navarra_fish_extract as (
select * from sudoang.navarra_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz > 0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 660 rows (3258 rows with ang_eye_diam_horiz null)
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
with navarra_fish_extract as (
select * from sudoang.navarra_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM navarra_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect > 0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 661 rows (3242 rows with ang_pect NULL)
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
select * from sudoang.navarra_fish where ang_neuromast is not null; -- 0 rows

---- 		Insert CONTRAST COLORS (no_id = 266)
select * from sudoang.navarra_fish where ang_constrast is not null; -- 0 rows



--------------------------------------------------------------------------------------------
--  ANDALUCIA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to sudoang schema from public
--	Station:
ALTER TABLE andalucia_station
    SET SCHEMA sudoang;

ALTER TABLE sudoang.andalucia_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.andalucia_station
  USING gist
  (geom);

--	Operation:
ALTER TABLE andalucia_ope
    SET SCHEMA sudoang;

ALTER TABLE sudoang.andalucia_ope RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.andalucia_ope
  USING gist
  (geom);


select * from sudoang.andalucia_station; -- 62 (15 rows without surface)
--delete from sudoang.andalucia_station where surface_m2 is null; -- 15 rows

select count(distinct sta_id) from sudoang.andalucia_station; -- 47 rows

---- Reprojection
select st_srid(geom) from sudoang.andalucia_station; -- 3035

-- Add geom_reproj
select addgeometrycolumn('sudoang','andalucia_station','geom_reproj',3035,'POINT',2);

update sudoang.andalucia_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.andalucia_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= andalucia_station.sta_id; -- 47 rows

CREATE INDEX 
  ON sudoang.andalucia_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.andalucia_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (AST_) from ligne 145 script "dbeel_sudoang_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.andalucia_station AS sp1, sudoang.andalucia_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment (et_id = 18, UCO)
-- select * from dbeel.data_provider (dp_id = 16, Carlos Fernandez, dp_et_id = 18)


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.andalucia_station set dbeel_op_id = NULL;
WITH 
projection_andalucia AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 g.sta_id,
	 d.place_classification
	FROM sudoang.andalucia_station g
	-- join sudoang.andalucia_station on op_sta_id = sta_id
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_andalucia AS (
SELECT distinct on (id) * from projection_andalucia
)
--SELECT * from closest_andalucia; -- 31 rows
UPDATE sudoang.andalucia_station SET dbeel_op_id = op_id
	FROM closest_andalucia c
	WHERE c.id = andalucia_station.id; -- 31 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='UCO'; -- 0 rows
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'UCO' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	NULL as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.andalucia_station
	where dbeel_op_id is null
	; -- 16 lines
commit;

-- We put back the op_id into the source table
begin;
update sudoang.andalucia_station set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 16 rows
commit;



----------------------------------
-- INSERTING ANDALUCIA OPERATIONS
----------------------------------
select * from sudoang.andalucia_ope limit 10;
---- Add dbeel_ob_id in andalucia_ope table
ALTER TABLE sudoang.andalucia_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select andalucia_station.dbeel_op_id, andalucia_station.id, andalucia_ope.* from sudoang.andalucia_station 
	join sudoang.andalucia_ope on andalucia_station.sta_id = andalucia_ope.sta_id -- 93 rows
)-- joining the two tables on the andalucia side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 61 rows

-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select andalucia_station.dbeel_op_id, andalucia_station.id, andalucia_ope.* from sudoang.andalucia_station 
	join sudoang.andalucia_ope on andalucia_station.sta_id = andalucia_ope.sta_id -- 93 rows
)-- joining the two tables on the andalucia side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 1 rows

-- for those lines where there is a join, add ob_id in andalucia tables
ALTER TABLE sudoang.andalucia_ope ADD COLUMN is_duplicate boolean;
-- update sudoang.andalucia_ope set is_duplicate = FALSE;  -- 93 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select andalucia_station.dbeel_op_id, andalucia_station.id, andalucia_ope.* from sudoang.andalucia_station 
	join sudoang.andalucia_ope on andalucia_station.sta_id = andalucia_ope.sta_id -- 93 rows
	),-- joining the two tables on the andalucia side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
update sudoang.andalucia_ope set is_duplicate = TRUE where sta_id in (select sta_id from op_duplicates) and op_dat in (select op_dat from op_duplicates); -- 1 rows

DELETE FROM sudoang.andalucia_ope WHERE sta_id = '1.37.1' and op_dat = '2012-03-13'; -- This row is empty

---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from sudoang.andalucia_ope; -- 93 rows
select count(distinct (sta_id,op_dat)) from sudoang.andalucia_ope; -- 93 operations
select * from sudoang.dbeel_station where op_gis_layername = 'UCO'; -- 16 stations

alter table sudoang.andalucia_ope add column andalucia_ob_id uuid default uuid_generate_v4 ();


begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	andalucia_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	andalucia_ope.surface_m2 AS ef_wetted_area, 
	andalucia_ope.meter_fished::REAL AS ef_fished_length,
	NULL AS ef_fished_width,
	1 AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.andalucia_station on dbeel_op_id=op_id
	join
		sudoang.andalucia_ope on andalucia_ope.sta_id = andalucia_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Carlos Fernandez'
	and is_duplicate = FALSE
	; -- 91 rows
commit;

select * from sudoang.dbeel_electrofishing where ob_id in (select andalucia_ob_id from sudoang.andalucia_ope); -- 91 rows

-- The riverbed corresponds to the width of the river: it must be included!
begin;
with join_electro as (
	select * from sudoang.andalucia_ope JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_id) = (op_dat, andalucia_ob_id)
	)
--select * from join_electro; -- 91 rows
update sudoang.dbeel_electrofishing set ef_fished_width = riverbed from join_electro 
	where dbeel_electrofishing.ob_id = join_electro.ob_id and dbeel_electrofishing.ob_starting_date = join_electro.ob_starting_date; -- 91 rows
COMMIT;

-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.andalucia_ope there is only information about eels ('nb_eels').

select * from sudoang.andalucia_ope where meter_fished is null or riverbed is null; -- 0 rows
select * from sudoang.andalucia_ope where (meter_fished is null or riverbed is null) and nb_eels > 0; -- 0 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	andalucia_ope.andalucia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.andalucia_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 91 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	coalesce(andalucia_ope.nb_eels/andalucia_ope.surface_m2,0) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	andalucia_ope.andalucia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.andalucia_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 91 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	andalucia_ope.nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	andalucia_ope.andalucia_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.andalucia_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 91 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.andalucia_fish add column fish_id serial;
alter table sudoang.andalucia_fish add column ba_id uuid;


---- 		Check duplicates: Joining andalucia_fish and dbeel_batch_fish by "sta_id" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.andalucia_fish a join sudoang.andalucia_ope o on a.fish_sta_id = o.sta_id
	join sudoang.dbeel_electrofishing l on l.ob_id = o.andalucia_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows (NOT sure that it's right)


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT distinct on (andalucia_fish.fish_id)
	uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	andalucia_ope.andalucia_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	andalucia_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.andalucia_fish
	join sudoang.andalucia_ope
	on (andalucia_fish.fish_sta_id, andalucia_fish.fish_op_dat) = (andalucia_ope.sta_id, andalucia_ope.op_dat)	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 29 rows (2 rows are missing, I don't know why...)
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in andalucia_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in andalucia_fish table! 

with fish_from_andalucia as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 16) 
--select * from fish_from_andalucia join sudoang.andalucia_fish on fish_from_andalucia.fish_id = andalucia_fish.fish_id; -- 29 rows
UPDATE sudoang.andalucia_fish b
SET ba_id = fish_from_andalucia.ba_id
FROM fish_from_andalucia
WHERE fish_from_andalucia.fish_id = b.fish_id; -- 29 rows
-- select * from sudoang.andalucia_fish where ba_id is null; -- 2 rows


---- 		Insert LENGTH
begin;
with andalucia_fish_extract as (
select * from sudoang.andalucia_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length_mm AS bc_numvalue,
	fish_id
	FROM andalucia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length_mm >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 29 rows (0 rows with length NULL)
commit; 


---- 		Insert WEIGHT
begin;
with andalucia_fish_extract as (
select * from sudoang.andalucia_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weigth_g AS bc_numvalue,
	fish_id
	FROM andalucia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weigth_g >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 21 rows (8 rows with weight NULL)
commit;


--------------------------------------------------------------------------------------------
--  MINHO: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to sudoang schema from public
ALTER TABLE minho_station
    SET SCHEMA sudoang;

ALTER TABLE sudoang.minho_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.minho_station
  USING gist
  (geom);

select * from sudoang.minho_station; -- 29 rows
select count(sta_id) from sudoang.minho_station; -- 29 rows

---- Reprojection
SELECT Find_SRID('sudoang', 'minho_station', 'geom'); -- 25830
  
-- Add geom_reproj
select addgeometrycolumn('sudoang','minho_station','geom_reproj',3035,'POINT',2);

update sudoang.minho_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from(
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.minho_station s join
portugal.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= minho_station.sta_id; -- 27 rows

CREATE INDEX 
  ON sudoang.minho_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.minho_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (AST_) from ligne 145 script "dbeel_sudoang_electrofishing")
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.minho_station AS sp1, sudoang.minho_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment -- UP (et_id = 15)
-- select * from dbeel.data_provider -- Carlos Antunes (dp_id = 13)


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.minho_station set dbeel_op_id = NULL;
WITH 
projection_minho AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.minho_station g
	-- join sudoang.minho_station on op_sta_id = sta_id
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_minho AS (
SELECT distinct on (id) * from projection_minho
)
--SELECT * from closest_minho; -- 0 row
UPDATE sudoang.minho_station SET dbeel_op_id = op_id
	FROM closest_minho c
	WHERE c.id = minho_station.id; -- 0 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='FCUL/MARE'; -- 0 rows
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'UP' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'PT' as country,
	sta_id as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.minho_station
	where dbeel_op_id is null
	; -- 29 lines
commit;

-- We put back the op_id into the source table
begin;
update sudoang.minho_station set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 29 rows
commit;


------------------------------
-- INSERTING MINHO OPERATIONS
------------------------------
select * from sudoang.minho_ope limit 10; -- 89 rows
---- Add dbeel_ob_id in asturias_ope table
ALTER TABLE sudoang.minho_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with a_station_operation as(
select minho_station.dbeel_op_id, minho_station.id, minho_ope.* from sudoang.minho_station 
	join sudoang.minho_ope on minho_station.sta_id = minho_ope.op_sta_id -- 89 rows
)-- joining the two tables on the minho side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 19 rows


-- Checking the duplicates for year: real duplicates
with a_station_operation as(
select minho_station.dbeel_op_id, minho_station.id, minho_ope.* from sudoang.minho_station 
	join sudoang.minho_ope on minho_station.sta_id = minho_ope.op_sta_id -- 89 rows
)-- joining the two tables on the minho side
select * from a_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id); -- 0 rows

-- for those lines where there is a join, add ob_id in asturias tables
ALTER TABLE sudoang.minho_ope ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- NO DUPLICATES
-- update sudoang.minho_ope set is_duplicate = FALSE;  -- 89 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select * from sudoang.minho_ope; -- 89 rows
select count(distinct (op_sta_id,op_dat)) from sudoang.minho_ope; -- 89 operations
select * from sudoang.dbeel_station where op_gis_layername = 'UP'; -- 29 stations

alter table sudoang.minho_ope add column minho_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	minho_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length * op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass::integer AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.minho_station on dbeel_op_id=op_id
	join
		sudoang.minho_ope on minho_ope.op_sta_id = minho_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Carlos Antunes'
	and is_duplicate = FALSE
	; -- 89 rows ERROR: 11 rows without surface data!!!
commit;

select * from sudoang.dbeel_electrofishing where ob_id in (select minho_ob_id from sudoang.minho_ope); -- 89 rows


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.asturias_ope there is only information about eels ('op_nbeel').

-- Remove rows without surface data:
UPDATE sudoang.minho_ope SET op_area = op_length * op_width WHERE op_area is null; -- 42 rows
DELETE FROM sudoang.minho_ope WHERE op_area is null; -- 11 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ope.minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.minho_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 78 rows
commit;


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
--ALTER TABLE sudoang.minho_ope DROP COLUMN op_dens;
--ALTER TABLE sudoang.minho_ope ADD COLUMN op_dens double precision;
UPDATE sudoang.minho_ope SET op_dens = coalesce(op_nbeel/op_area,0) WHERE op_dens is null; -- 78 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	round(op_dens::NUMERIC,3) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ope.minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.minho_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	and minho_ope.op_dens is not null
	; -- 78 rows
commit;


-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	minho_ope.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ope.minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.minho_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	and op_p1 is not null
	; -- 78 rows
commit;


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.minho_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	and op_p2 is not null
	; -- 34 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	minho_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.minho_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	and op_p3 is not null
	; -- 2 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.minho_fish add column fish_id serial;
alter table sudoang.minho_fish add column ba_id uuid;


---- 		Check duplicates: Joining asturias_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.minho_fish a join sudoang.minho_ope o on a.ang_op_id = o.op_id
	join sudoang.dbeel_electrofishing l on l.ob_id = o.minho_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	minho_ope.minho_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	minho_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.minho_fish
	join sudoang.minho_ope
	on minho_fish.ang_op_id = minho_ope.op_id	

	WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel'
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 1896 rows (total: 2010)
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
with fish_from_minho as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 13) -- 1896 rows
--select * from fish_from_minho join sudoang.minho_fish on fish_from_minho.fish_id = minho_fish.fish_id; -- 1896 rows
UPDATE sudoang.minho_fish b
SET ba_id = fish_from_minho.ba_id
FROM fish_from_minho
WHERE fish_from_minho.fish_id = b.fish_id; -- 1860 rows
-- select * from sudoang.minho_fish where ba_id is null; -- 150 rows


---- 		Insert LENGTH
begin;
with minho_fish_extract as (
select * from sudoang.minho_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM minho_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1860 rows
commit; 


---- 		Insert WEIGHT
begin;
with minho_fish_extract as (
select * from sudoang.minho_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM minho_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1860 rows
commit;


--------------------------------------------------------------------------------------------
--  SPAIN (MITECO): reprojection and stations
--------------------------------------------------------------------------------------------

ALTER TABLE spain_station
    SET SCHEMA sudoang;

ALTER TABLE sudoang.spain_station RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.spain_station
  USING gist
  (geom);

select * from sudoang.spain_station; -- 717 rows
select count(sta_id) from sudoang.spain_station; -- 717 rows

---- Reprojection
select st_srid(geom) from sudoang.spain_station; -- 3035
  
-- Add geom_reproj
select addgeometrycolumn('sudoang','spain_station','geom_reproj',3035,'POINT',2);

update sudoang.spain_station set geom_reproj = sub2.geom_reproj from (
select distinct on (sta_id) sta_id, geom_reproj,distance from (
select
sta_id, 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.spain_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by sta_id, distance
)sub )sub2
where sub2.sta_id= spain_station.sta_id; -- 711 rows

CREATE INDEX 
  ON sudoang.spain_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.spain_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (SPA_) from R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.spain_station AS sp1, sudoang.spain_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_Distance(sp1.geom, sp2.geom)<0.01
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- no internal duplicates

-- add establishment
-- select * from dbeel.establishment -- miteco (et_id = 17)
-- select * from dbeel.data_provider -- Belén Muñoz (dp_id = 15)


---- Duplicate with data already in dbeel
-- We choose the closest station to join with

--update sudoang.spain_station set dbeel_op_id = NULL;
WITH 
projection_spain AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.spain_station g
	-- join sudoang.spain_station on op_sta_id = sta_id
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
        join sudoang.dbeel_electrofishing on ob_op_id = op_id -- Join with dbeel_eelctrofishing to avoid more stations than necessary (in dbeel_station, all data from SIBIC were included)
	WHERE g.geom_reproj IS NOT NULL -- and op_dat IS NOT NULL (it was a mistake)
	order by id, dist
),
closest_spain AS (
SELECT distinct on (id) * from projection_spain
)
--SELECT * from closest_spain; -- 224 row
UPDATE sudoang.spain_station SET dbeel_op_id = op_id
	FROM closest_spain c
	WHERE c.id = spain_station.id; -- 224 duplicates


-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='miteco'; -- 0 rows (and 'min esp')
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'miteco' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	sta_cod as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.spain_station
	where dbeel_op_id is null
	; -- 493 lines
commit;

-- We put back the op_id into the source table
begin;
update sudoang.spain_station set dbeel_op_id = op_id from sudoang.dbeel_station where id = op_gislocation; -- 493 rows
commit;

---------------------------------------
-- INSERTING SPAIN (MITECO) OPERATIONS
---------------------------------------
-- Duplicates with the same information:
SELECT op_sta_id, op_dat, count(*) FROM sudoang.spain_ope GROUP BY op_sta_id, op_dat HAVING count(*) > 1;
/*
WITH uniq AS
    (SELECT op_sta_id, op_dat, count(*) FROM sudoang.spain_ope GROUP BY op_sta_id, op_dat HAVING count(*) > 1)
DELETE FROM sudoang.spain_ope op WHERE op.op_sta_id IN (SELECT op_sta_id FROM uniq) and op.op_dat IN (SELECT op_dat FROM uniq); -- 32 rows 
*/
select count(*) from sudoang.spain_ope; -- 1184 rows

-- Update the surface when length and width data are available
update sudoang.spain_ope set op_surface = case
	when spain_ope.op_surface is null then round(cast(coalesce(spain_ope.op_length, 0) * coalesce(spain_ope.op_width, 0)/1000000 as numeric), 3)
	when spain_ope.op_surface is not null then round(cast(spain_ope.op_surface as numeric), 3)
	end; --1184

/* There are rows with eels but without information about surface: remove it!
delete from sudoang.spain_ope where op_surface = 0 and (op_length is null or op_width is null); -- 109 rows
*/

-- Update sta_cod: when it is null, the op_cod has been split to take the first part of the string
update sudoang.spain_ope set sta_cod = case
						when sta_cod is not null then sta_cod
						when sta_cod is null then (select split_part(op_cod, '-', 1))
					END; -- 1075 rows

---- Add dbeel_ob_id in spain_ope table
ALTER TABLE sudoang.spain_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with s_station_operation as(
select spain_station.dbeel_op_id, spain_station.id, spain_station.sta_cod, spain_ope.* from sudoang.spain_station 
	join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod -- 1071 rows
)-- joining the two tables on the spain side
select * from s_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 401 rows (but the date it is not the same)

-- Checking the duplicates for year: real duplicates
with s_station_operation as(
select spain_station.dbeel_op_id, spain_station.id, spain_station.sta_cod, spain_ope.* from sudoang.spain_station 
	join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod -- 1071 rows
)-- joining the two tables on the spain side
select * from s_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 99 rows

-- for those lines where there is a join, add ob_id in spain tables
ALTER TABLE sudoang.spain_ope ADD COLUMN is_duplicate boolean;
update sudoang.spain_ope set is_duplicate = FALSE; -- 1075 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from sudoang.spain_station 
	join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod -- 1071 rows
	),-- joining the two tables on the spain side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates; -- 99 rows
update sudoang.spain_ope set is_duplicate = TRUE where spain_ope.sta_cod in (select op_duplicates.sta_cod from op_duplicates) 
							and spain_ope.op_dat in (select op_duplicates.op_dat from op_duplicates); -- 99 rows


---- STEP 2: integrate new data operations and then fish.... using where is_duplicate = FALSE
-- select only lines where ob_id is null;

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with surface)
select * from sudoang.spain_ope; -- 1075 rows
select count(distinct (sta_cod,op_dat)) from sudoang.spain_ope; -- 1075 operations
select count(distinct (op_sta_id,op_dat)) from sudoang.spain_ope; -- 1075 operations

select * from sudoang.dbeel_station where op_gis_layername = 'miteco'; -- 493 stations

alter table sudoang.spain_ope add column spain_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	spain_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	spain_ope.op_surface AS ef_wetted_area, 
	spain_ope.op_length AS ef_fished_length,
	spain_ope.op_width AS ef_fished_width,
	spain_ope.op_nbpass AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.spain_station on dbeel_op_id=op_id
	join
		sudoang.spain_ope on spain_ope.sta_cod = spain_station.sta_cod
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Belén Muñoz'
	and is_duplicate = FALSE
	; -- 972 rows (1075 operations - 99 duplicates - 4 with the same sta_cod)
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2, run3 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.spain_ope there is only information about eels
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from sudoang.spain_station 
		join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ) -- joining the two tables on the spain side

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 972 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from sudoang.spain_station 
		join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ) -- joining the two tables on the spain side
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 972 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from sudoang.spain_station 
		join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ) -- joining the two tables on the spain side
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2::NUMERIC AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and op_p2 is not null
	; -- 50 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from sudoang.spain_station 
		join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ) -- joining the two tables on the spain side
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3::NUMERIC AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and op_p3 is not null
	; -- 2 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from sudoang.spain_station 
		join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     ),
ope_dens as (
		select *,
				case
				when op_nbeel = 0 then 0
				else round(cast(op_nbeel/op_surface as numeric), 3)
				end as density
		from ope
	     )
-- select * from ope_dens -- 972 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	density AS ba_quantity, -- I don't know the unit of the surface!
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	spain_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	ope_dens, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and density > 0
	; -- 143 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.spain_fish add column fish_id serial;
alter table sudoang.spain_fish add column ba_id uuid;

---- 		Check duplicates: Joining spain_fish and dbeel_batch_fish by "ang_op_id" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.spain_fish a join sudoang.spain_ope o on a.ang_op_id = o.op_id 	-- 2828 rows (where is_duplicate = FALSE : 2380 rows)
	join sudoang.dbeel_electrofishing l on l.ob_id = o.spain_ob_id			-- 2363 rows
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_batch_fish
select sum(op_nbeel) from sudoang.spain_ope; 	-- 5423 eels
select count(*) from sudoang.spain_fish; 	-- 3488 eels
-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	

begin;
with ope as (
		select spain_station.dbeel_op_id, spain_station.id, spain_ope.* from sudoang.spain_station 
		join sudoang.spain_ope on spain_station.sta_cod = spain_ope.sta_cod where is_duplicate = FALSE -- 972 rows
	     )
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	ope.spain_ob_id as ba_ob_id,
	cast(NULL as uuid) as ba_ba_id,
	spain_fish.fish_id 			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.spain_fish
	join ope
	on spain_fish.ang_op_id = ope.op_id	

	WHERE species.no_name='Anguilla anguilla'
	and stage.no_name='Yellow eel'
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and ope.is_duplicate = FALSE
	; -- 2363 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in gt6_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
with fish_from_spain as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 15) -- 2363 rows
--select * from fish_from_spain join sudoang.spain_fish on fish_from_spain.fish_id = spain_fish.fish_id; -- 2363 rows
UPDATE sudoang.spain_fish b
SET ba_id = fish_from_spain.ba_id
FROM fish_from_spain
WHERE fish_from_spain.fish_id = b.fish_id; -- 2363 rows
-- select * from sudoang.spain_fish where ba_id is null; -- 1125 rows


---- 		Insert LENGTH (no_id = 39)
begin;
with spain_fish_extract as (
select * from sudoang.spain_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM spain_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2363 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT (no_id = 42)
/* NOT INSERTED BECAUSE THE VALUE IS SOMETIMES STRANGE: EXAMPLE 1 !?!?
begin;
with spain_fish_extract as (
select * from sudoang.spain_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM spain_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1587 rows
commit;
*/



--------------------------------------------------------------------------------------------
--  VALENCIA: reprojection and stations
--------------------------------------------------------------------------------------------

-- Move the table to sudoang schema from public
ALTER TABLE valencia_sta_ope
    SET SCHEMA sudoang;

ALTER TABLE sudoang.valencia_sta_ope RENAME COLUMN geometry TO geom;

CREATE INDEX 
  ON sudoang.valencia_sta_ope
  USING gist
  (geom);
  
/* sudoang.valencia_sta_ope has several problems:

-- 1. There isn't an ID to identify the stations:
select distinct on (op_sta_id) * from sudoang.valencia_sta_ope order by op_sta_id; -- 197 rows = OPERATIONS (NOT code of stations)
ALTER TABLE sudoang.valencia_sta_ope RENAME COLUMN op_sta_id TO op_id;

select distinct on (geom) * from sudoang.valencia_sta_ope; -- 150 (total: 197 rows)

-- 	Solution: create a table for stations
-- 	For that, the id's ('VAL_') created in the SIBIC.R script is deleted because it's corresponded to operations
	ALTER TABLE sudoang.valencia_sta_ope DROP COLUMN id;
-- 	The table valencia_station is created taken into account the geometry of operations
	CREATE TABLE sudoang.valencia_station AS
		SELECT distinct on (geom) observer, place_name, water_body, basin, town, province, geom from sudoang.valencia_sta_ope; -- 112 rows
-- 	Adding the ID: dbeel_sudoang_electrofishing.sql script (241 line)
--	Insert the ID of the station in valencia_sta_ope table:
	ALTER TABLE sudoang.valencia_sta_ope ADD COLUMN id_station text;
	UPDATE sudoang.valencia_sta_ope set id_station = id from sudoang.valencia_station where valencia_station.geom = valencia_sta_ope.geom; -- 197 rowws
*/

-- Reprojection

select st_srid(geom) from sudoang.valencia_station; -- 3035 (SELECT Find_SRID doesn't work)

select addgeometrycolumn('sudoang','valencia_station','geom_reproj',3035,'POINT',2);
update sudoang.valencia_station set geom_reproj = sub2.geom_reproj from (
select distinct on (id) id, geom_reproj, distance from(
select
id,
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.valencia_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by s.geom, distance
)sub )sub2
where sub2.id= valencia_station.id; -- 140 rows

CREATE INDEX 
  ON sudoang.valencia_station
  USING gist
  (geom_reproj);

select count(distinct geom_reproj) from sudoang.valencia_station; -- 132 rows (total: 197 rows)

-- to store the link for dbeel
-- ALTER TABLE sudoang.valencia_station DROP COLUMN dbeel_op_id;
ALTER TABLE sudoang.valencia_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (VAL_) from dbeel_sudoang_electrofishing.sql script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.valencia_station AS sp1, sudoang.valencia_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 internal duplicates

INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('VAERSA'); --TODO: TO BE MODIFIED (et_id = 26)
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Nacho Ferrando Belloch', et_id FROM dbeel.establishment WHERE et_establishment_name = 'VAERSA'; --TODO: TO BE MODIFIED (dp_id = 25: 'Nacho Ferrando Belloch')

-- duplicate with data already in dbeel
-- we choose the closest station to join with

WITH 
projection_valencia AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.valencia_station g
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_valencia AS (
SELECT distinct on (id) * from projection_valencia
)
--SELECT * from closest_valencia; -- 5 rows
UPDATE sudoang.valencia_station SET dbeel_op_id = op_id
	FROM closest_valencia c
	WHERE c.id=valencia_station.id; -- 5 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)
-- select * FROM sudoang.dbeel_station where op_gis_layername='VAERSA'; -- 0 rows
-- select * from sudoang.dbeel_station limit 10;
begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'VAERSA' AS op_gis_layername, 
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	place_name as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS  op_op_id,
	geom  as the_geom,
	NULL as locationid,
	'ES' as country,
	NULL as place_classification,
	NULL as codhb,	
	NULL as observations,
	NULL as hydrographic_basin_pt,
	basin as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.valencia_station
	where dbeel_op_id is null
	; -- 145 lines
commit;

-- We put back the op_id into the source table
update sudoang.valencia_station set dbeel_op_id=op_id from sudoang.dbeel_station where id = op_gislocation; -- 145 rows


---------------------------------
-- INSERTING VALENCIA OPERATIONS
---------------------------------
-- select * from sudoang.valencia_sta_ope; -- 197 rows
-- select * from sudoang.valencia_station; -- 150 rows

---- Add dbeel_ob_id in valencia operation table
ALTER TABLE sudoang.valencia_sta_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with v_station_operation as(
select valencia_station.dbeel_op_id, valencia_station.id, valencia_sta_ope.* from sudoang.valencia_station 
	join sudoang.valencia_sta_ope on valencia_station.id = valencia_sta_ope.id_station -- 197 rows
)-- joining the two tables on the valencia side
select * from v_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 15 rows (but the date it is not the same)


-- Checking the duplicates for year: real duplicates
with v_station_operation as(
select valencia_station.dbeel_op_id, valencia_station.id, valencia_sta_ope.* from sudoang.valencia_station 
	join sudoang.valencia_sta_ope on valencia_station.id = valencia_sta_ope.id_station -- 197 rows
)-- joining the two tables on the valencia side
select * from v_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 0 rows from Valencia

-- for those lines where there is a join, add ob_id in valencia tables
ALTER TABLE sudoang.valencia_sta_ope ADD COLUMN is_duplicate boolean;
update sudoang.valencia_sta_ope set is_duplicate = NULL; -- 197 rows

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- No duplicates!

---- STEP 2: integrate all new data operations and then fish....there are no longer any duplicates

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length and width)
select count(distinct (op_sta_id, op_dat)) from sudoang.valencia_sta_ope; -- 197 operations

--		There are 3 operations that are repeated with different number of eels catched
select distinct (id_station,op_dat), count(*) from sudoang.valencia_sta_ope group by (id_station,op_dat) having count(*) > 1; -- 3 rows
/*
begin;
WITH uniques AS
    (SELECT DISTINCT ON (id_station,op_dat) * FROM sudoang.valencia_sta_ope) -- 193 rows
DELETE FROM sudoang.valencia_sta_ope WHERE sudoang.valencia_sta_ope.op_sta_id NOT IN (SELECT op_sta_id FROM uniques); -- 4rows
commit;
*/
-- 		The id of sudoang.valencia_sta_ope is 'op_sta_id', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'val_ob_id' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table sudoang.valencia_sta_ope add column val_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT
	val_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id,
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(length * mean_width_m) AS ef_wetted_area, 
	length AS ef_fished_length,
	mean_width_m AS ef_fished_width,
	1 AS ef_nbpas, -- Not info about that, by default: 1
	dbeel_op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.valencia_station
	join
		sudoang.valencia_sta_ope on valencia_sta_ope.id_station = valencia_station.id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Nacho Ferrando Belloch'
	ANd dp_et_id = 26
	; -- 193 rows
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.valencia_sta_ope there is only information about nb of eels (and total nb of species)
update sudoang.valencia_sta_ope set nb_eels = 0 where nb_eels is null; -- 67 rows

begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	val_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.valencia_sta_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 193 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	val_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.valencia_sta_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 193 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
with dens as (
	      select round(cast(nb_eels/(length*mean_width_m) as numeric),3) as density, * from sudoang.valencia_sta_ope where nb_eels > 0
	      )
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	density AS ba_quantity, -- ind/m2
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	val_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	dens, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 125 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.valencia_fish add column fish_id serial;
alter table sudoang.valencia_fish add column ba_id uuid; -- We can't generate hte ba_id for the whole table because there are more than 200 000 rows!

-- There are individuals without total length but furcal length appears (as a proxy, in comments it's indicated)
update sudoang.valencia_fish set tl = fl where tl is null -- 1257 rows
select count(*) from sudoang.valencia_fish where tl is null; -- 749
--DELETE FROM sudoang.valencia_fish where tl is null; -- 749 rows

---- 		Check duplicates: Joining valencia_fish and dbeel_batch_fish by "ang_sta" and "ob_id" (to join "ob_id" we need to go through different tables)
select count(*) from sudoang.valencia_fish a join sudoang.valencia_sta_ope o on a.ang_sta_id = o.op_sta_id -- 2208 rows (3435 TOTAL)

select * from sudoang.valencia_fish a join sudoang.valencia_sta_ope o on a.ang_sta_id = o.op_sta_id
	join sudoang.dbeel_electrofishing l on l.ob_id = o.val_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows

-- There are 1594 fish that miss because of the id of the operation, which doesn't match!
----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	valencia_sta_ope.val_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	valencia_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.valencia_fish
	join sudoang.valencia_sta_ope
	on valencia_fish.ang_sta_id = valencia_sta_ope.op_sta_id

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive'
	and stage.no_name='Yellow eel'
	AND value_type.no_name='Raw data or Individual data'
	; -- 2 208 rows
commit;

--TO DO
---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in valencia_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
with fish_from_valencia as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 25) -- 2208 rows
--select * from fish_from_valencia join sudoang.valencia_fish on fish_from_valencia.fish_id = valencia_fish.fish_id; -- 2208 rows
UPDATE sudoang.valencia_fish b
SET ba_id = fish_from_valencia.ba_id
FROM fish_from_valencia
WHERE fish_from_valencia.fish_id = b.fish_id; -- 2208 rows
-- select * from sudoang.valencia_fish where ba_id is null; -- 1227 rows


---- 		Insert LENGTH (no_id = 39)
begin;
with valencia_fish_extract as (
select * from sudoang.valencia_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	tl AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE tl > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 2208 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with valencia_fish_extract as (
select * from sudoang.valencia_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1475 rows
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
with valencia_fish_extract as (
select * from sudoang.valencia_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	diam_vert AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1018 rows
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
with valencia_fish_extract as (
select * from sudoang.valencia_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	diam_horiz AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE diam_horiz is not null
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1018 rows
commit;


---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
with valencia_fish_extract as (
select * from sudoang.valencia_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	pect_fin AS bc_numvalue,
	fish_id
	FROM valencia_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE pect_fin is not null
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1017 rows
commit;



--------------------------------------------------------------------------------------------
--  GT6: reprojection and stations in 2018/2019
--------------------------------------------------------------------------------------------

-- Move the teble to sudoang schema from public
ALTER TABLE gt6_station
    SET SCHEMA sudoang;

ALTER TABLE sudoang.gt6_station RENAME COLUMN geometry TO geom;

select * from sudoang.gt6_station; -- 99 rows

CREATE INDEX 
  ON sudoang.gt6_station
  USING gist
  (geom);
  
-- Reprojection

select st_srid(geom) from sudoang.gt6_station; -- 3035 (SELECT Find_SRID doesn't work)

select addgeometrycolumn('sudoang','gt6_station','geom_reproj',3035,'POINT',2);
update sudoang.gt6_station set geom_reproj = sub2.geom_reproj from (
select distinct on ("sta_cod") "sta_cod", geom_reproj,distance from(
select
"sta_cod", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.gt6_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by "sta_cod", distance
)sub )sub2
where sub2."sta_cod"= gt6_station."sta_cod"; -- 67 rows (98 total)

CREATE INDEX 
  ON sudoang.gt6_station
  USING gist
  (geom_reproj);



-- to store the link for dbeel
ALTER TABLE sudoang.gt6_station ADD COLUMN dbeel_op_id uuid;
  
-- internal duplicate here (added id (GT6_) from SIBIC.R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.gt6_station AS sp1, sudoang.gt6_station AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- GT6_92 and TG6_97 internal duplicates


-- add establishment
-- select * from dbeel.establishment
INSERT INTO dbeel.establishment(et_establishment_name) VALUES ('GT6'); --TODO: TO BE MODIFIED
-- add data provider
INSERT INTO dbeel.data_provider(dp_name, dp_et_id)
	SELECT 'Isabel Domingos', et_id FROM dbeel.establishment WHERE et_establishment_name = 'GT6'
; --TODO: TO BE MODIFIED


-- duplicate with data already in dbeel, there is one internal duplicate in dbeel that we ignore
-- we choose the closest station to join with

--update sudoang.gt6_station set dbeel_op_id IS NULL;
WITH 
projection_gt6 AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.gt6_station g
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_gt6 AS (
SELECT distinct on (id) * from projection_gt6
)
--SELECT * from closest_gt6; -- 16 rows
UPDATE sudoang.gt6_station SET dbeel_op_id = op_id
	FROM closest_gt6 c
	WHERE c.id=gt6_station.id; -- 16 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)

--SELECT Find_SRID('sudoang', 'dbeel_station', 'the_geom'); --3035
-- SELECT * from sudoang.dbeel_station limit 10;
-- select * from sudoang.gt6_station limit 10

begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT  uuid_generate_v4() AS op_id,  -- We are sad, the uuid in the SIBIC does not correspond to observation place but to data provider....
	'3035' AS op_gis_systemname,
	'GT6' AS op_gis_layername, -- GT6 or sta_source (not correspond with the information in dbeel.establishment)
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS op_op_id,
	geom as the_geom, 	
	NULL as locationid,
	case when sta_source in ('ecobiop', 'bages_sigean') then 'FR'
	WHEN sta_source in ('fcup_ciimar', 'fcul_mare') then 'PT' 
	WHEN sta_source in ('udg', 'AZTI', 'uco') then 'ES' END as country,
	sta_cod as place_classification,
	NULL as codhb,	
	null as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.gt6_station 
	where dbeel_op_id is null -- as those lines are not reprojected
	; -- 83 rows
COMMIT;

-- We put back the op_id into the source table
begin;
With jointure as (
SELECT * from sudoang.dbeel_station JOIN
sudoang.gt6_station ON op_gislocation=id)
update sudoang.gt6_station set dbeel_op_id=op_id from jointure where jointure.id = gt6_station.id; -- 83 rows
commit;


---------------------------------------
-- INSERTING GT6 OPERATIONS 2018/2019
---------------------------------------

-- select * from sudoang.gt6_ope; -- 98 rows
-- select * from sudoang.gt6_station;
delete from sudoang.gt6_ope where op_cod in ('gro_50001','gro_60001','gro_160001','gro_190001'); -- 4 empty lines, 94 rows

---- Add dbeel_ob_id in guipuz_operation table
ALTER TABLE sudoang.gt6_ope ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates of the stations
with g_station_operation as(
select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
)-- joining the two tables on the gt6 side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on ob_op_id = dbeel_op_id; -- 231 rows (but the date it is not the same)


-- Checking the duplicates for year: real duplicates
with g_station_operation as(
select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
)-- joining the two tables on the gt6 side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 15 rows from Gipuzkoa

-- for those lines where there is a join, add ob_id in gt6 tables
ALTER TABLE sudoang.gt6_ope ADD COLUMN is_duplicate boolean;

---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)

--select * from op_duplicates; -- 15 rows
update sudoang.gt6_ope set is_duplicate = TRUE where op_cod in (select op_cod from op_duplicates); -- 15rows

-- We search into the dbeel the duplicated operations. We will supress them as we have better information from GT6:
-- We have to do three times for different tables because we have on delete restrict clause in the table:
begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	),

fish_duplicates as (
	select * from sudoang.dbeel_batch_fish where ba_ob_id in (select ob_id from op_duplicates)
	)

--select * from sudoang.dbeel_mensurationindiv_biol_charac where bc_ba_id in (select ba_id from fish_duplicates);
delete from sudoang.dbeel_mensurationindiv_biol_charac where bc_ba_id in (select ba_id from fish_duplicates); -- 1681 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from sudoang.dbeel_batch_fish where ba_ob_id in (select ob_id from op_duplicates);
delete from sudoang.dbeel_batch_fish where ba_ob_id in (select ob_id from op_duplicates); -- 816 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from sudoang.dbeel_batch_ope where ba_ob_id in (select ob_id from op_duplicates); -- 60 rows
delete from sudoang.dbeel_batch_ope where ba_ob_id in (select ob_id from op_duplicates); -- 60 rows
commit;

begin;
with duplicates as (
	Select gt6_station.dbeel_op_id, gt6_station.id, gt6_ope.* from sudoang.gt6_station 
	join sudoang.gt6_ope on gt6_station.sta_cod = gt6_ope.op_sta_id -- 94 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from sudoang.dbeel_electrofishing where ob_id in (select ob_id from op_duplicates); -- 15 rows
delete from sudoang.dbeel_electrofishing where ob_id in (select ob_id from op_duplicates); -- 15 rows
commit;

---- STEP 2: integrate all new data operations and then fish....there are no longer any duplicates

-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (op_cod, op_dat)) from sudoang.gt6_ope; -- 94 operations
-- select * from sudoang.dbeel_station where op_gis_layername = ''; --  stations

-- 		The id of sudoang.gt6_ope is 'op_cod', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'gt6_ob_id' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table sudoang.gt6_ope add column gt6_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT
	gt6_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, -- Isabel Domingos or each pilot basin leader?
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length*op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass AS ef_nbpas, -- 1, 2 or 3
	dbeel_op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.gt6_station
	join
		sudoang.gt6_ope on gt6_ope.op_sta_id = gt6_station.sta_cod
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Isabel Domingos'  -- or each pilot basin leader?
	ANd dp_et_id = 22 -- two lines for Isabel Domingos (fcul and GT6)
	; -- 94 rows
commit;


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.gt6_ope there is only information about eels
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 94 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 94 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and op_p2 is not null -- this will be used for next time but we didn't use it during first integration
	; -- 94 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and op_p3 is not null
	; -- 4 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_dens AS ba_quantity, -- ind/m2
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.gt6_ope, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 94 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.gt6_fish add column fish_id serial;
alter table sudoang.gt6_fish add column ba_id uuid; -- We can't generate hte ba_id for the whole table because there are more than 200 000 rows!

---- 		Check duplicates: Joining gt6_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.gt6_fish a join sudoang.gt6_ope o on a.op_cod = o.op_cod
	join sudoang.dbeel_electrofishing l on l.ob_id = o.gt6_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	

begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN ang_silver='FALSE' THEN 226 --'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 -- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	gt6_ope.gt6_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	gt6_fish.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.gt6_fish
	join sudoang.gt6_ope
	on gt6_fish.op_cod = gt6_ope.op_cod	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 4 463 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in gt6_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from sudoang.dbeel_station;

with fish_from_gt6 as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 20) -- 4463 rows
--select * from fish_from_gt6 join sudoang.gt6_fish on fish_from_gt6.fish_id = gt6_fish.fish_id; -- 4463 rows
UPDATE sudoang.gt6_fish b
SET ba_id = fish_from_gt6.ba_id
FROM fish_from_gt6
WHERE fish_from_gt6.fish_id = b.fish_id; -- 4463 rows
-- select * from sudoang.gt6_fish where ba_id is null; -- 3 rows


---- 		Insert LENGTH (no_id = 39)
-- with gt6_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from sudoang.gt6e_fish order by locationid),
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 4463 rows (0 rows with length NULL)
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 4354 rows  (109 rows with weight NULL)
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 385 rows (4079 rows with ang_eye_diam_vert NULL)
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz > 0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 381 rows (total: 387 rows)
commit;


---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect > 0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 382 rows (total: 391 rows)
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" from amber_portugal is text, it must be converted into boolean:
alter table sudoang.gt6_fish
alter column ang_neuromast
set data type boolean
using case
    when ang_neuromast = 'TRUE' then true
    when ang_neuromast = 'FALSE' then false
    else null
end;

/* postgresql stops working when I run this query:
alter table sudoang.gt6_fish
alter column ang_neuromast
set data type integer
using case
    when ang_neuromast = 'TRUE' then 1
    when ang_neuromast = 'FALSE' then 0
    else null
end;
*/


/*	ERROR:  insertion or update in the table «dbeel_mensurationindiv_biol_charac» violates the foreign key «fk_mensindivbiocho_bc_value_type»
	DETAIL:  The key (bc_no_value_type)=(0) isn't present in the table «value_type».
	CORRECTED: error in value_type.no_name
*/

begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null and ang_neuromast is not null) -- 3832
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast = FALSE THEN 0 -- DOESN'T WORK (because of '')
	     WHEN ang_neuromast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3832 rows
commit;


---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" from gt6_fish is text, it must be converted into boolean:
alter table sudoang.gt6_fish
alter column ang_contrast
set data type boolean
using case
    when ang_contrast = 'TRUE' then true
    when ang_contrast = 'FALSE' then false
    else null
end;

begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish where ba_id is not null and ang_contrast is not null) -- 4037
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_contrast = FALSE THEN 0
	     WHEN ang_contrast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_contrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 4037 rows
commit;


--------------------------------------------------------------------------------------------
--  GT6 II: reprojection and stations in 2019/2020
--------------------------------------------------------------------------------------------

-- Move the teble to sudoang schema from public
ALTER TABLE gt6_station2
    SET SCHEMA sudoang;

ALTER TABLE sudoang.gt6_station2 RENAME COLUMN geometry TO geom;

select * from sudoang.gt6_station2; -- 13 rows

CREATE INDEX 
  ON sudoang.gt6_station2
  USING gist
  (geom);
  
-- Reprojection

select st_srid(geom) from sudoang.gt6_station2; -- 3035 (SELECT Find_SRID doesn't work)

select addgeometrycolumn('sudoang','gt6_station2','geom_reproj',3035,'POINT',2);
update sudoang.gt6_station2 set geom_reproj = sub2.geom_reproj from (
select distinct on ("sta_cod") "sta_cod", geom_reproj,distance from(
select
"sta_cod", 
ST_ClosestPoint(r.geom,s.geom) as geom_reproj,
ST_distance(r.geom,s.geom) as distance
from sudoang.gt6_station s join
spain.rn r on st_dwithin(r.geom,s.geom,300) 
order by "sta_cod", distance
)sub )sub2
where sub2."sta_cod"= gt6_station."sta_cod"; -- 67 rows (98 total)

CREATE INDEX 
  ON sudoang.gt6_station
  USING gist
  (geom_reproj);


-- to store the link for dbeel
ALTER TABLE sudoang.gt6_station2 ADD COLUMN dbeel_op_id uuid;
 
-- internal duplicate here (added id (GT6_) from SIBIC.R script)
WITH duplicate AS
(
	SELECT sp1.id AS id1, sp2.id AS id2 FROM sudoang.gt6_station2 AS sp1, sudoang.gt6_station2 AS sp2
	WHERE substring(sp1.id from 5) < substring(sp2.id from 5) AND ST_DWithin(sp1.geom, sp2.geom, 0.01)
) SELECT *, rank() OVER(PARTITION BY id1 ORDER BY id2) FROM duplicate ORDER BY substring(id1 from 5)::integer
; -- 0 internal duplicates


-- Establishment and data provider
-- select * from dbeel.establishment; -- et_id = 22
-- select * from dbeel.data_provider; -- dp_id = 20 (dp_et_id = 22)


--update sudoang.gt6_station set dbeel_op_id IS NULL;
WITH 
projection_gt6 AS (
	SELECT st_distance(g.geom_reproj,d.geom_reproj) as dist,
	 d.op_id, 
	 g.id,
	 d.place_classification
	FROM sudoang.gt6_station2 g
        JOIN  sudoang.dbeel_station d on ST_DWithin(d.geom_reproj, g.geom_reproj, 50)
	WHERE g.geom_reproj IS NOT NULL
	order by id, dist
),
closest_gt6 AS (
SELECT distinct on (id) * from projection_gt6
)
--SELECT * from closest_gt6; -- 1 rows
UPDATE sudoang.gt6_station2 SET dbeel_op_id = op_id
	FROM closest_gt6 c
	WHERE c.id=gt6_station2.id; -- 1 duplicates

-- Insertion of stations that are not duplicated (not already in the dbeel (farther than 50 m)

-- SELECT * from sudoang.dbeel_station limit 10;
-- select * from sudoang.gt6_station2; -- 13 rows

begin;
INSERT INTO sudoang.dbeel_station(
		op_id,
		op_gis_systemname,
		op_gis_layername,
		op_gislocation,
		op_placename,
		op_no_observationplacetype,
		op_op_id,
		the_geom,
		locationid,
		country,
		place_classification,
		codhb,
		observations,
		hydrographic_basin_pt,
		hydrographic_basin_es,
		s_guid,
		x,
		y,
		geom_reproj)		
	SELECT uuid_generate_v4() AS op_id,
	'3035' AS op_gis_systemname,
	'GT6' AS op_gis_layername, -- GT6 or sta_source (not correspond with the information in dbeel.establishment)
	id AS op_gislocation, -- some of those lines are empty, this field allows to join back to original data provided to the SIBIC
	sta_lib as op_placename,
	10 AS op_no_observationplacetype, -- Sampling station
	NULL AS op_op_id,
	geom as the_geom, 	
	NULL as locationid,
	case when sta_source in ('fcup_ciimar') then 'PT'
	WHEN sta_source in ('udg', 'AZTI') then 'ES' END as country,
	sta_cod as place_classification,
	NULL as codhb,	
	null as observations,
	NULL as hydrographic_basin_pt,
	NULL as hydrographic_basin_es,
	NULL as s_guid,
	st_x(geom) as x,
	st_y(geom) as y,
	geom_reproj as geom_reproj
	from sudoang.gt6_station2 
	where dbeel_op_id is null -- as those lines are not reprojected
	; -- 12 rows
COMMIT;

-- We put back the op_id into the source table
With jointure as (
SELECT * from sudoang.dbeel_station JOIN
sudoang.gt6_station2 ON op_gislocation=id)
update sudoang.gt6_station2 set dbeel_op_id=op_id from jointure where jointure.id = gt6_station2.id; -- 12 rows


-- In GT6_station2 there is only the NEW STATIONS added, but we need to have all the stations to insert the operations
select count(*) from sudoang.gt6_station; -- 99 rows

begin;
INSERT INTO sudoang.gt6_station2 (sta_id, sta_source, sta_layername, sta_cod, sta_lib, srid, id, geom, geom_reproj, dbeel_op_id)
SELECT cast(sta_id as text), sta_source, sta_layername, sta_cod, sta_lib, srid, id, geom, geom_reproj, dbeel_op_id FROM sudoang.gt6_station; -- 99 rows
commit;

-----------------------------------------
-- INSERTING GT6 II OPERATIONS 2019/2020
-----------------------------------------

-- select * from sudoang.gt6_ope2; -- 107 rows
-- select * from sudoang.gt6_station2; -- 13 rows

---- Add dbeel_ob_id in guipuz_operation table
ALTER TABLE sudoang.gt6_ope2 ADD COLUMN dbeel_ob_id uuid;


---- We have to verify that there is no duplicate for year
-- Checking the duplicates for year: real duplicates
with g_station_operation as(
select gt6_station2.dbeel_op_id, gt6_station2.id, gt6_ope2.* from sudoang.gt6_station2 
	join sudoang.gt6_ope2 on gt6_station2.sta_cod = gt6_ope2.op_sta_id -- 106 rows
)-- joining the two tables on the gt6 side
select * from g_station_operation JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id) -- 10 rows from Minho

-- Duplicates are deleted from the table because they are the operations from the previous year that are already included in the dbeel
-- Do the same in fish_table!!!
with duplicates as (
	select gt6_station2.dbeel_op_id, gt6_station2.id, gt6_ope2.* from sudoang.gt6_station2
	join sudoang.gt6_ope2 on gt6_station2.sta_cod = gt6_ope2.op_sta_id -- 106 rows
	),-- joining the two tables on the gt6 side

op_duplicates as (
	select * from duplicates JOIN sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)

--select * from op_duplicates; -- 10 rows
delete from sudoang.gt6_ope2 where op_cod in (select op_cod from op_duplicates); -- 10 rows


---- STEP 1 for duplicates, check if the same information about size is present in the database (eg silvering is probably not integrated)
-- It's the same information they sent us last year (Carlos Antunes)

---- STEP 2: integrate all new data operations and then fish....be careful with duplicates
select * from sudoang.gt6_ope2; -- 97 rows
-- 	STEP 2.1. INSERT into dbeel_electrofishing all the stations (with length, width and surface)
select count(distinct (op_cod, op_dat)) from sudoang.gt6_ope2; -- 97 operations
-- select * from sudoang.dbeel_station where op_gis_layername = ''; --  stations

-- 		The id of sudoang.gt6_ope2 is 'op_cod', but it is text, so it cannot be inserted into the column "locationid" from dbeel_electrofishing
--		since "locationid" is numeric. Remember that we use "locationid" to insert data from SIBIC ddbb.
--		As solution, 'gt6_ob_id' is first created in the source table, and we use after to insert data into dbeel_electrofishing table.
alter table sudoang.gt6_ope2 add column gt6_ob_id uuid default uuid_generate_v4 ();

begin;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT
	gt6_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id,
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	(op_length*op_width) AS ef_wetted_area, 
	op_length AS ef_fished_length,
	op_width AS ef_fished_width,
	op_nbpass AS ef_nbpas, -- 1, 2 or 3
	dbeel_op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.gt6_station2
	join
		sudoang.gt6_ope2 on gt6_ope2.op_sta_id = gt6_station2.sta_cod
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Isabel Domingos'
	AND dp_et_id = 22 -- two lines for Isabel Domingos (fcul and GT6)
	; -- 96 rows
commit;
rollback;

-- One ope is not inserted, because there is a mistake in the id station (from TER)
update sudoang.gt6_ope2 set op_sta_id = 'TER12' where gt6_ob_id = '74834426-ef98-4df6-9d29-f3bd1522ef8e';
-- This row is imported into dbeel_electrofishing!

-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)
-- 			In sudoang.gt6_ope2 there is only information about eels
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nbeel AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope2,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 97 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope2,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 97 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope2,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and op_p2 is not null
	; -- 93 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.gt6_ope2,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and op_p3 is not null
	; -- 11 rows
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_dens AS ba_quantity, -- ind/m2
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	gt6_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	sudoang.gt6_ope2, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 97 rows
commit;


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
/* Delete fish from the previous year (Minho)
with is_2020 as (select fi.* from sudoang.gt6_ope2 op join sudoang.gt6_fish2 fi on op.op_cod = fi.op_cod)
delete from sudoang.gt6_fish2 where op_cod not in (select op_cod from is_2020); -- 211 rows
*/

---- 		Before insert length of fish, we need: "ba_id" and "fish_id"
alter table sudoang.gt6_fish2 add column fish_id serial;
alter table sudoang.gt6_fish2 add column ba_id uuid;

---- 		Check duplicates: Joining gt6_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select * from sudoang.gt6_fish2 a join sudoang.gt6_ope2 o on a.op_cod = o.op_cod
	join sudoang.dbeel_electrofishing l on l.ob_id = o.gt6_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	

begin;	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN ang_silver='FALSE' THEN 226 --'Yellow eel' 
	     WHEN ang_silver='TRUE' THEN 227 -- 'Silver eel'
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	4 AS ba_batch_level,
	gt6_ope2.gt6_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	gt6_fish2.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.gt6_fish2
	join sudoang.gt6_ope2
	on gt6_fish2.op_cod = gt6_ope2.op_cod	

	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 3 848 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in gt6_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 
select distinct op_gislocation from sudoang.dbeel_station;

with fish_from_gt6 as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	where ob_dp_id = 20), -- 8311 rows
final_select as (
	select * from fish_from_gt6 join sudoang.gt6_ope2 on fish_from_gt6.ob_id = gt6_ope2.gt6_ob_id
	join sudoang.gt6_fish2 on fish_from_gt6.fish_id = gt6_fish2.fish_id
	) -- 3848 rows
UPDATE sudoang.gt6_fish2 b
SET ba_id = fish_from_gt6.ba_id
FROM fish_from_gt6
WHERE fish_from_gt6.fish_id = b.fish_id; -- 3848 rows


---- 		Insert LENGTH (no_id = 39)
-- with gt6_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from sudoang.gt6e_fish order by locationid),
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_lng AS bc_numvalue,
	fish_id
	FROM sudoang.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_lng >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3848 rows
commit; 

---- 		Insert WEIGHT (no_id = 42)
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds AS bc_numvalue,
	fish_id
	FROM sudoang.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3848 rows
commit;

---- 		Insert VERTICAL EYE DIAMETER (no_id = 262)
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_vert AS bc_numvalue,
	fish_id
	FROM sudoang.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_vert IS not null
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1902 rows
commit;

---- 		Insert HORIZONTAL EYE DIAMETER (no_id = 263)
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM sudoang.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_eye_diam_horiz > 0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 369 rows
commit;

---- 		Insert LENGTH OF THE PECTORAL FIN (no_id = 264)
begin;
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pect AS bc_numvalue,
	fish_id
	FROM sudoang.gt6_fish2,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pect > 0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 370 rows
commit;

---- 		Insert PRESENCE OF NEUROMAST (no_id = 265)
-- "ang_neuromast" from amber_portugal is text, it must be converted into boolean:
alter table sudoang.gt6_fish2
alter column ang_neuromast
set data type boolean
using case
    when ang_neuromast = 'TRUE' then true
    when ang_neuromast = 'FALSE' then false
    else null
end;

begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish2 where ba_id is not null and ang_neuromast is not null) -- 1382 rows
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_neuromast = FALSE THEN 0
	     WHEN ang_neuromast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'presence_neuromast'
	and ang_neuromast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 1382 rows
commit;


---- 		Insert CONTRAST COLORS (no_id = 266)
-- "ang_contrast" from gt6_fish is text, it must be converted into boolean:
alter table sudoang.gt6_fish2
alter column ang_contrast
set data type boolean
using case
    when ang_contrast = 'TRUE' then true
    when ang_contrast = 'FALSE' then false
    else null
end;

begin;
with gt6_fish_extract as (
select * from sudoang.gt6_fish2 where ba_id is not null and ang_contrast is not null) -- 3448
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id,
	biological_characteristic_type.no_id AS bc_no_characteristic_type,
	value_type.no_id AS bc_no_value_type, 
	CASE WHEN ang_contrast = FALSE THEN 0
	     WHEN ang_contrast = TRUE THEN 1
	     END AS bc_numvalue,
	fish_id
	FROM gt6_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type
	WHERE biological_characteristic_type.no_name = 'contrast'
	and ang_contrast is not null
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3448 rows
commit;



/*-------------------------------
	DATABASE CORRECTION
*/-------------------------------

--------------------------------------------------------------------------------------------
-- In pb_totalnumber.csv there are 112 ob_id with problem in the number of catchs:
-- missing catches are inserted and tables are corrected when necessary
--------------------------------------------------------------------------------------------

-- VAERSA Valencia
select * from sudoang.valencia_sta_ope where val_ob_id = '89d1166e-af61-41fd-90e9-f9b6e6a965f3'; -- 38 eels 
select * from sudoang.valencia_fish where ang_sta_id = 1998; -- 39 eels

begin;
with correct as		(
			select * from sudoang.dbeel_batch_ope where ba_ob_id = '89d1166e-af61-41fd-90e9-f9b6e6a965f3' and 
				(ba_no_biological_characteristic_type = 47 or ba_no_biological_characteristic_type = 231)
			)
update sudoang.dbeel_batch_ope set ba_quantity = 39 from correct where dbeel_batch_ope.ba_id = correct.ba_id
commit;

-- Galicia
select * from sudoang.galicia_ope where galicia_ob_id = '001b158a-94da-4c4c-be17-84a160ea7e69'; -- 1 eel in pass 3
select * from sudoang.dbeel_batch_ope where ba_ob_id = '001b158a-94da-4c4c-be17-84a160ea7e69'; -- 1 eel in pass 3
select * from sudoang.galicia_fish where cod_ope = 'INVGEN_0893' -- 1 eel in pass 2, 1 eel in pass 3

--	Nb total
begin;
with sum_eels as 	(
			select count(ba_id), cod_ope from sudoang.galicia_fish where species = 'Anguila' group by cod_ope order by cod_ope -- 3699 rows
			),
 eels_tot as 		(
			select * from sudoang.galicia_ope join sum_eels on galicia_ope.cod_ope = sum_eels.cod_ope where 
				count > (coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0) + coalesce(run4_ang, 0) + coalesce(run5_ang, 0))
			)
--select * from eels_tot  -- 78 rows
update sudoang.dbeel_batch_ope set ba_quantity = count from eels_tot where dbeel_batch_ope.ba_ob_id = eels_tot.galicia_ob_id and ba_no_biological_characteristic_type = 47; -- 78 rows
commit;

--	Run2
begin;
with sum_eels as 	(
			select count(ba_id), cod_ope, op_pass from sudoang.galicia_fish where species = 'Anguila' group by (cod_ope, op_pass) order by cod_ope -- 3346 rows
			),
 eels_p2 as 		(
			select * from sudoang.galicia_ope join sum_eels on galicia_ope.cod_ope = sum_eels.cod_ope where count > coalesce(run2_ang, 0) and op_pass = 2 -- 78 rows
			)
--select * from eels_p2 -- 78 rows
update sudoang.dbeel_batch_ope set ba_quantity = count from eels_p2 where dbeel_batch_ope.ba_ob_id = eels_p2.galicia_ob_id and ba_no_biological_characteristic_type = 232; -- 78 rows
commit;

-- Gipuzkoa
select * from sudoang.guipuz_ope where guipuz_ob_id = '00aec661-2f9c-4759-9e2e-811d086e79f8' -- 500 eels in total
select * from sudoang.dbeel_batch_ope where ba_ob_id = '00aec661-2f9c-4759-9e2e-811d086e79f8' -- 431 eels in total
select * from sudoang.guipuz_fish where sampling = 'PA2005034' -- 69 eels in pass 3

ALTER TABLE sudoang.guipuz_ope ADD COLUMN run3_ang integer;
ALTER TABLE sudoang.guipuz_ope ADD COLUMN run3_oth integer;

-- 	Add pass 3 in guipuz_ope table
with run3_anguila as (
select
sampling as sampling,
sum("N") as run3_anguila
from sudoang.guipuz_fish
where species='Anguilla anguilla' and pass = 3 group by sampling), -- 12 rows

run3_other as (
select
sampling as sampling5,
sum("N") as run3_other
from sudoang.guipuz_fish
where species!='Anguilla anguilla' and pass = 3 group by sampling),

electro as (select coalesce(sampling, sampling5) as sampling, run3_anguila, run3_other from run3_anguila 
	FULL OUTER JOIN run3_other on sampling = sampling5
)
--select * from electro; -- 12 rows
update sudoang.guipuz_ope
set (run3_ang, run3_oth) = (run3_anguila, run3_other) from electro where guipuz_ope.sampling = electro.sampling; -- 12 rows

--	Update nb of pass in electrofishing
update sudoang.dbeel_electrofishing set ef_nbpas = 3 from sudoang.guipuz_ope where dbeel_electrofishing.ob_id = guipuz_ope.guipuz_ob_id; -- 1302 rows

-- 	Update total number of catches in dbeel_batch_ope
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang, run3_ang
from sudoang.guipuz_ope),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.guipuz_ope),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)
--select * from electrofishing_temp where guipuz_ob_id != '655cab5c-aa9d-475e-99a3-8f3a0605fc02' order by sampling ; -- 1316 rows
update sudoang.dbeel_batch_ope set ba_quantity = electrofishing_temp.run1+electrofishing_temp.run2+electrofishing_temp.run3 from electrofishing_temp 
	where dbeel_batch_ope.ba_ob_id = electrofishing_temp.guipuz_ob_id and ba_no_biological_characteristic_type = 47; -- 1302 rows
commit;

-- 	Update op_p2 of catches in dbeel_batch_ope
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang, run3_ang
from sudoang.guipuz_ope where is_sibic_duplicate = FALSE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.guipuz_ope),

electrofishing as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling),

electrofishing_temp as (
select electrofishing.* from electrofishing join sudoang.dbeel_electrofishing on guipuz_ob_id = ob_id
)
--select * from electrofishing_temp
update sudoang.dbeel_batch_ope set ba_quantity = electrofishing_temp.run2 from electrofishing_temp 
	where dbeel_batch_ope.ba_ob_id = electrofishing_temp.guipuz_ob_id and ba_no_biological_characteristic_type = 232; -- 1302 rows
commit;

-- 	op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang, run3_ang
from sudoang.guipuz_ope where is_sibic_duplicate = FALSE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(run3_ang,0) as run3,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0) + coalesce(run3_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 as run3,
0 AS density
from sudoang.guipuz_ope),

electrofishing as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling),

electrofishing_temp as (
select electrofishing.* from electrofishing join sudoang.dbeel_electrofishing on guipuz_ob_id = ob_id
)
--select * from electrofishing_temp; -- 1302 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run3 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p3' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 1302 rows
commit;

--	Particular cases:
select * from sudoang.guipuz_ope where guipuz_ob_id = '655cab5c-aa9d-475e-99a3-8f3a0605fc02' -- 6 eels in total (5 in pass 1 and 1 in pass 2)
select * from sudoang.guipuz_fish where sampling = 'PA2009009' and species = 'Anguilla anguilla' -- 1 eel in pass 2
select * from sudoang.dbeel_batch_ope where ba_ob_id = 'afa62a60-48d1-4d13-90fd-f9a3ab0081ca'
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'afa62a60-48d1-4d13-90fd-f9a3ab0081ca' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 5 where dbeel_batch_ope.ba_ob_id = 'afa62a60-48d1-4d13-90fd-f9a3ab0081ca' and ba_no_biological_characteristic_type = 231;
update sudoang.dbeel_batch_ope set ba_quantity = 6 where dbeel_batch_ope.ba_ob_id = 'afa62a60-48d1-4d13-90fd-f9a3ab0081ca' and ba_no_biological_characteristic_type = 47;

select * from sudoang.guipuz_ope where guipuz_ob_id = 'ab5507dc-8fa6-4704-b0e1-58a4fe47bce2';
select * from sudoang.guipuz_fish where sampling = 'PB2001018' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = 'ab5507dc-8fa6-4704-b0e1-58a4fe47bce2';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'ab5507dc-8fa6-4704-b0e1-58a4fe47bce2' and ba_no_biological_characteristic_type = 232;

select * from sudoang.guipuz_ope where guipuz_ob_id = 'a25aed01-34db-4de4-b095-8ee8e5f02972';
select * from sudoang.guipuz_fish where sampling = 'PB1996020' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = 'a25aed01-34db-4de4-b095-8ee8e5f02972';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'a25aed01-34db-4de4-b095-8ee8e5f02972' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'a25aed01-34db-4de4-b095-8ee8e5f02972' and ba_no_biological_characteristic_type = 47;

select * from sudoang.guipuz_ope where guipuz_ob_id = '7a4516ce-4ca2-4dcf-b041-2685de73fc2d';
select * from sudoang.guipuz_fish where sampling = 'PB2003005' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '7a4516ce-4ca2-4dcf-b041-2685de73fc2d';
update sudoang.dbeel_batch_ope set ba_quantity = 2 where dbeel_batch_ope.ba_ob_id = '7a4516ce-4ca2-4dcf-b041-2685de73fc2d' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 2 where dbeel_batch_ope.ba_ob_id = '7a4516ce-4ca2-4dcf-b041-2685de73fc2d' and ba_no_biological_characteristic_type = 47;

select * from sudoang.guipuz_ope where guipuz_ob_id = '6823ab79-5e48-4c61-8c0a-9f9b900cb81d';
select * from sudoang.guipuz_fish where sampling = 'PA2017021' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '6823ab79-5e48-4c61-8c0a-9f9b900cb81d';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '6823ab79-5e48-4c61-8c0a-9f9b900cb81d' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '6823ab79-5e48-4c61-8c0a-9f9b900cb81d' and ba_no_biological_characteristic_type = 47;

select * from sudoang.guipuz_ope where guipuz_ob_id = '5be8940c-c829-4bd1-98ac-687be315895e';
select * from sudoang.guipuz_fish where sampling = 'PB2007002' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '5be8940c-c829-4bd1-98ac-687be315895e';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '5be8940c-c829-4bd1-98ac-687be315895e' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '5be8940c-c829-4bd1-98ac-687be315895e' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.guipuz_ope where guipuz_ob_id = '46be4e1c-871d-41b4-bd0c-ad739389d1cc';
select * from sudoang.guipuz_fish where sampling = 'PB1996012' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '46be4e1c-871d-41b4-bd0c-ad739389d1cc';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '46be4e1c-871d-41b4-bd0c-ad739389d1cc' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '46be4e1c-871d-41b4-bd0c-ad739389d1cc' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.guipuz_ope where guipuz_ob_id = '2e8163bf-7a78-484b-873c-c04fdd187719';
select * from sudoang.guipuz_fish where sampling = 'PB2004024' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '2e8163bf-7a78-484b-873c-c04fdd187719';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '2e8163bf-7a78-484b-873c-c04fdd187719' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '2e8163bf-7a78-484b-873c-c04fdd187719' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.guipuz_ope where guipuz_ob_id = '271192bd-0587-48a3-a629-501f3cb051c7';
select * from sudoang.guipuz_fish where sampling = 'PB2001007' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '271192bd-0587-48a3-a629-501f3cb051c7';
update sudoang.dbeel_batch_ope set ba_quantity = 2 where dbeel_batch_ope.ba_ob_id = '271192bd-0587-48a3-a629-501f3cb051c7' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 2 where dbeel_batch_ope.ba_ob_id = '271192bd-0587-48a3-a629-501f3cb051c7' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.guipuz_ope where guipuz_ob_id = '24e64f2c-7da6-4a7d-b7b3-1eebff0dbe4f';
select * from sudoang.guipuz_fish where sampling = 'PA2007012' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '24e64f2c-7da6-4a7d-b7b3-1eebff0dbe4f';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '24e64f2c-7da6-4a7d-b7b3-1eebff0dbe4f' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '24e64f2c-7da6-4a7d-b7b3-1eebff0dbe4f' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.guipuz_ope where guipuz_ob_id = '199c3205-0325-4271-bd73-300575ed890f';
select * from sudoang.guipuz_fish where sampling = 'PB2008007' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '199c3205-0325-4271-bd73-300575ed890f';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '199c3205-0325-4271-bd73-300575ed890f' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '199c3205-0325-4271-bd73-300575ed890f' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.guipuz_ope where guipuz_ob_id = '1874032c-ab26-4594-b1dd-eb11c7cb7b4b';
select * from sudoang.guipuz_fish where sampling = 'PB1999017' and species = 'Anguilla anguilla';
select * from sudoang.dbeel_batch_ope where ba_ob_id = '1874032c-ab26-4594-b1dd-eb11c7cb7b4b';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '1874032c-ab26-4594-b1dd-eb11c7cb7b4b' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '1874032c-ab26-4594-b1dd-eb11c7cb7b4b' and ba_no_biological_characteristic_type = 47; 

-- GT6
select * from sudoang.gt6_ope where gt6_ob_id = '08d0e4a3-c58e-49c4-9685-c972f7e10a7f'; -- 15 eels in pass 1
select * from sudoang.gt6_fish where op_cod = 'ter_30001'; -- 282 eel in pass 1
select * from sudoang.dbeel_batch_ope where ba_ob_id = '08d0e4a3-c58e-49c4-9685-c972f7e10a7f'; -- 15 eels in pass 1
update sudoang.dbeel_batch_ope set ba_quantity = 282 where dbeel_batch_ope.ba_ob_id = '08d0e4a3-c58e-49c4-9685-c972f7e10a7f' and ba_no_biological_characteristic_type = 231;
update sudoang.dbeel_batch_ope set ba_quantity = 282 where dbeel_batch_ope.ba_ob_id = '08d0e4a3-c58e-49c4-9685-c972f7e10a7f' and ba_no_biological_characteristic_type = 47; 

-- Asturias
select * from sudoang.asturias_ope where asturias_ob_id = '000ba411-c04a-4332-bc03-b498e4a89355'; -- 25 eels in total: error in op_nbeel (12 in op1, 10 in op2, 3 in op3)
select * from sudoang.asturias_fish where ang_op_id = 28; -- 25 eels
select * from sudoang.dbeel_batch_ope where ba_ob_id = '000ba411-c04a-4332-bc03-b498e4a89355'; -- 25 eels in total: error in op_nbeel (12 in op1, 10 in op2, 3 in op3)
update sudoang.dbeel_batch_ope set ba_quantity = 25 where dbeel_batch_ope.ba_ob_id = '000ba411-c04a-4332-bc03-b498e4a89355' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.asturias_ope where asturias_ob_id = '25dfbeb0-b0f1-459b-a9fb-7acb58320e92'; -- 21 eels (12 in op1, 5 in op2, 4 in op3)
select * from sudoang.asturias_fish where ang_op_id = 115 and ang_pas = 1; -- 22 eels (13 in pass 1; 5 in pass 2; 4 in pass 3): 1 is missing in pass 1
select * from sudoang.dbeel_batch_ope where ba_ob_id = '25dfbeb0-b0f1-459b-a9fb-7acb58320e92';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '25dfbeb0-b0f1-459b-a9fb-7acb58320e92' and ba_no_biological_characteristic_type = 48; 
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = '25dfbeb0-b0f1-459b-a9fb-7acb58320e92' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.asturias_ope where asturias_ob_id = '34ab44f2-5104-4439-a444-bb7d6c914e2a'; -- 1 eels (2 in op1, 1 in op2)
select count(*), ang_pas from sudoang.asturias_fish where ang_op_id = 27 group by ang_pas; -- 3 eels (2 in pass 1; 1 in pass 2)
select * from sudoang.dbeel_batch_ope where ba_ob_id = '34ab44f2-5104-4439-a444-bb7d6c914e2a';
update sudoang.dbeel_batch_ope set ba_quantity = 3 where dbeel_batch_ope.ba_ob_id = '34ab44f2-5104-4439-a444-bb7d6c914e2a' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.asturias_ope where asturias_ob_id = '40681c34-ef0a-41f4-9457-1f1ec2bfff41'; -- 26 eels (17 in op1, 5 in op2, 4 in op3)
select count(*), ang_pas from sudoang.asturias_fish where ang_op_id = 117 group by ang_pas; -- 3 eels (17 in pass 1; 15 in pass 2; 4 in pass 3)
select * from sudoang.dbeel_batch_ope where ba_ob_id = '40681c34-ef0a-41f4-9457-1f1ec2bfff41';
update sudoang.dbeel_batch_ope set ba_quantity = 36 where dbeel_batch_ope.ba_ob_id = '40681c34-ef0a-41f4-9457-1f1ec2bfff41' and ba_no_biological_characteristic_type = 47; 
update sudoang.dbeel_batch_ope set ba_quantity = 15 where dbeel_batch_ope.ba_ob_id = '40681c34-ef0a-41f4-9457-1f1ec2bfff41' and ba_no_biological_characteristic_type = 232; 

select * from sudoang.asturias_ope where asturias_ob_id = 'c3d77468-b42f-4d86-a4a2-b55fdab63b3e'; -- 0 eels (0 in op1)
select count(*), ang_pas from sudoang.asturias_fish where ang_op_id = 20 group by ang_pas; -- 1 eels (1 in pass 2)
select * from sudoang.dbeel_batch_ope where ba_ob_id = 'c3d77468-b42f-4d86-a4a2-b55fdab63b3e';
update sudoang.dbeel_batch_ope set ba_quantity = 1 where dbeel_batch_ope.ba_ob_id = 'c3d77468-b42f-4d86-a4a2-b55fdab63b3e' and ba_no_biological_characteristic_type = 47; 
begin;
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	'c3d77468-b42f-4d86-a4a2-b55fdab63b3e' as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	sudoang.asturias_ope,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and asturias_ob_id = 'c3d77468-b42f-4d86-a4a2-b55fdab63b3e'
	; -- 1 row
commit;

select * from sudoang.asturias_ope where asturias_ob_id = 'ffcff086-9223-43d3-b2dd-f3e67de98b9d'; -- 57 eels (31 in op1, 19 in op2, 57 in op3)
select count(*), ang_pas from sudoang.asturias_fish where ang_op_id = 9 group by ang_pas; -- 57 eels (31 in pass 1; 19 in pass 2; 7 in pass 3)
select * from sudoang.dbeel_batch_ope where ba_ob_id = 'ffcff086-9223-43d3-b2dd-f3e67de98b9d';
update sudoang.dbeel_batch_ope set ba_quantity = 7 where dbeel_batch_ope.ba_ob_id = 'ffcff086-9223-43d3-b2dd-f3e67de98b9d' and ba_no_biological_characteristic_type = 233; 

-- SIBIC
select * from sudoang.levante_ope where ob_id = '08138b68-c5df-4da5-a3c4-8f0b444b5dca'; -- 10 eels 
select * from sudoang.levante_fish where "PMSPCOD" = 'JU08210015' and "SISTCOD" = 'ANGANG'; -- 30 eels but only 11 eels with ba_id
select * from sudoang.dbeel_batch_ope where ba_ob_id = '08138b68-c5df-4da5-a3c4-8f0b444b5dca';
update sudoang.dbeel_batch_ope set ba_quantity = 11 where dbeel_batch_ope.ba_ob_id = '08138b68-c5df-4da5-a3c4-8f0b444b5dca' and ba_no_biological_characteristic_type = 231; 
update sudoang.dbeel_batch_ope set ba_quantity = 11 where dbeel_batch_ope.ba_ob_id = '08138b68-c5df-4da5-a3c4-8f0b444b5dca' and ba_no_biological_characteristic_type = 47; 

select * from sudoang.guipuz_ope where guipuz_ob_id = '4d5f6f1d-70eb-4900-8676-dbe5d5252c0c' -- 57 in pass, 14 in pass 2, 6 in pass 3
select * from sudoang.guipuz_fish where sampling = 'PA2006013' and species = 'Anguilla anguilla' -- 77 eels
select * from sudoang.dbeel_batch_ope where ba_ob_id = '4d5f6f1d-70eb-4900-8676-dbe5d5252c0c';
update sudoang.dbeel_batch_ope set ba_quantity = 14 where dbeel_batch_ope.ba_ob_id = '4d5f6f1d-70eb-4900-8676-dbe5d5252c0c' and ba_no_biological_characteristic_type = 232;
update sudoang.dbeel_batch_ope set ba_quantity = 3 where dbeel_batch_ope.ba_ob_id = '4d5f6f1d-70eb-4900-8676-dbe5d5252c0c' and ba_no_biological_characteristic_type = 233;

select * from sudoang.temp_pesca_electrica where ob_id = 'ec9a463b-e865-47c9-b825-b52cca352c44' and codspecies = 'aang'; -- 10 eels 
select * from sudoang.dbeel_batch_ope where ba_ob_id = 'ec9a463b-e865-47c9-b825-b52cca352c44';
update sudoang.dbeel_batch_ope set ba_quantity = 17 where dbeel_batch_ope.ba_ob_id = 'ec9a463b-e865-47c9-b825-b52cca352c44' and ba_no_biological_characteristic_type = 47; 

--------------------------------------------------------------------------------------------
-- In bc_ope table
-- the density is corrected (divided by 100)
--------------------------------------------------------------------------------------------
select * from sudoang.bc_ope limit 10;
select * from sudoang.dbeel_batch_ope where ba_ob_id in (select bc_ob_id from sudoang.bc_ope) and ba_no_biological_characteristic_type = 48; -- 885 rows
update sudoang.dbeel_batch_ope set ba_quantity = round(op_dens::NUMERIC/100, 3) from sudoang.bc_ope where dbeel_batch_ope.ba_ob_id = bc_ope.bc_ob_id and ba_no_biological_characteristic_type = 48;
SELECT * FROM sudoang.dbeel_electrofishing de WHERE ob_id='32761281-9BC3-4F5B-B8FC-D06BE9FA6263'
BEGIN;
UPDATE sudoang.dbeel_electrofishing de SET ob_starting_date='2017-10-26' WHERE ob_id='32761281-9BC3-4F5B-B8FC-D06BE9FA6263' -- instead of 2017-10-26
COMMIT;




--------------------
--  MISSING DATA BC_bis
--------------------
--323 sudoang.bc_ope_bis 

/*
 * 
 * SOME stations sta_id were not in the bc_station_bis table... So we have to join with bc_station_to integate them
 * 
 */

----------------------------------------------------------------------------------------------
-- INSERT MISSING DATA 
---------------------------------------------------------------------------------------------
SELECT * from sudoang.dbeel_electrofishing limit 10;
select * from sudoang.bc_ope_bis limit 10;
-- the op_id column is bc_ob_id, dropping empty column

/*
SELECT count(*) FROM sudoang.bc_ope_bis; -- 323
SELECT count(*) FROM sudoang.bc_ope_bis pp JOIN sudoang.dbeel_electrofishing ee on pp.bc_ob_id=ee.ob_id; -- 251
select count(*) from sudoang.bc_ope_bis where is_duplicate = 'TRUE'; -- 1 row

BEGIN;
WITH friend as (
SELECT * FROM sudoang.bc_ope_bis pp JOIN sudoang.dbeel_electrofishing ee on pp.bc_ob_id=ee.ob_id -- 251
)
UPDATE sudoang.bc_ope_bis set dbeel_ob_id=friend.bc_ob_id from friend where friend.bc_ob_id=bc_ope_bis.bc_ob_id; -- 251
COMMIT;

BEGIN;
with duplicates as (
	Select bc_station_bis.dbeel_op_id, bc_station_bis.id, bc_station_bis.sta_id, bc_ope_bis.* from sudoang.bc_station_bis 
	join 
	sudoang.bc_ope_bis on bc_station_bis.sta_id = bc_ope_bis.op_sta_id -- 252 rows
	),-- joining the two tables on the portugal side

op_duplicates as (
	select ob_id, bc_ob_id from duplicates 
	JOIN 
	sudoang.dbeel_electrofishing on(ob_starting_date, ob_op_id) = (op_dat, dbeel_op_id)
	)
--select * from op_duplicates; -- 252 
UPDATE sudoang.bc_ope_bis set dbeel_ob_id=ob_id FROM op_duplicates 
where op_duplicates.bc_ob_id=bc_ope_bis.bc_ob_id
AND is_duplicate; -- 1 row
COMMIT;

-- Checking already inserted batch_ope
WITH toto as (
	SELECT distinct ON (ba_ob_id) * FROM sudoang.dbeel_batch_ope JOIN sudoang.bc_ope_bis ON ba_ob_id=dbeel_ob_id
	)
select count (*) from toto; -- 252 OK

SELECT * from sudoang.bc_fish_bis where ba_id is NULL; -- 625

SELECT * from sudoang.bc_ope_bis 
	JOIN  
	sudoang.bc_fish_bis on ang_op_id=bc_ope_bis.op_id; 	-- 3758

SELECT dbeel_batch_fish.* FROM sudoang.dbeel_batch_fish JOIN 
	sudoang.bc_ope_bis ON dbeel_ob_id= ba_ob_id; 		-- 3235
-- not more datat
SELECT dbeel_batch_fish.* FROM sudoang.dbeel_batch_fish JOIN 
	sudoang.bc_ope_bis ON dbeel_ob_id= ba_ob_id
	UNION
	SELECT dbeel_batch_fish.* FROM sudoang.dbeel_batch_fish JOIN 
	sudoang.bc_ope ON dbeel_ob_id= ba_ob_id;		-- 3235
		
-- which are the fish already in the database for which we have the size and for which we have new rows in dbeel_batch_fish: we want to delete them
SELECT * FROM sudoang.dbeel_batch_fish 
	JOIN 
	sudoang.bc_ope_bis ON dbeel_ob_id= ba_ob_id 
	where is_duplicate; -- 70

SELECT * FROM sudoang.dbeel_batch_fish limit 10;

SELECT * FROM sudoang.dbeel_mensurationindiv_biol_charac 
	JOIN
	sudoang.dbeel_batch_fish on bc_ba_id=ba_id
	JOIN 
	sudoang.bc_ope_bis ON dbeel_ob_id= ba_ob_id where is_duplicate; -- 70 

-- sudoang.dbeel_mensurationindiv_biol_charac has delete cascade on ba_id,
-- so we delete one line per fish in dbeel_batch_fish and all lines corresponding to length (there was only this) in dbeel_mensurationindiv_biol_charac

select * from sudoang.bc_ope_bis 
except select * from sudoang.bc_ope_bis 
where op_sta_id in (select sta_id from sudoang.bc_station_bis); -- 71 rows


SELECT * FROM
		sudoang.bc_station_bis 
	join
		sudoang.bc_ope_bis on bc_ope_bis.op_sta_id = bc_station_bis.sta_id; --252 integrated
		
SELECT op_sta_id FROM sudoang.bc_ope_bis
	WHERE op_sta_id NOT IN (SELECT sta_id FROM sudoang.bc_station_bis )
	AND NOT is_duplicate ; --71		
	
SELECT DISTINCT(op_sta_id) FROM
sudoang.bc_ope_bis 
WHERE op_sta_id NOT IN (SELECT sta_id FROM sudoang.bc_station_bis ); --41 
*/

BEGIN;
INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
	SELECT 
	bc_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	op_dat AS ob_starting_date,
	CAST(NULL AS DATE) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	op_surface_m2 AS ef_wetted_area, 
	null AS ef_fished_length,
	null AS ef_fished_width,
	nb_pass AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.bc_station on dbeel_op_id = op_id
	join
		sudoang.bc_ope_bis on bc_ope_bis.op_sta_id = bc_station.sta_id
		
	WHERE observation_origin.no_name='Raw data' 
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='ALberto Aguirre'
	and is_duplicate = FALSE
	AND sta_id NOT IN (select sta_id from sudoang.bc_station_bis )
	; -- 67


-- 	STEP 2.2. INSERT into dbeel_batch_ope: total number, run1, run2, run3 and density
-- 			TOTAL NUMBER (biological_characteristic_type.no_name='Number') (see biological_characteristic_type.no_id=47)



BEGIN;
WITH uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM sudoang.bc_station 
	JOIN sudoang.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from sudoang.bc_station_bis )
	) -- 67 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_nb_eels AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 67
commit;

-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)
-- 			Density is calculated with different methods: estimation_method (Relative abundance, Seber Lecren, Carle Strab)
BEGIN;
with uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM sudoang.bc_station 
	JOIN sudoang.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from sudoang.bc_station_bis )	) -- 252 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	round(coalesce(uniques.op_dens_nha::NUMERIC/10000,0),3) AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	uniques, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 67 rows
commit;

-- 			op_p1 (biological_characteristic_type.no_name='Number p1') (see biological_characteristic_type.no_id=231)
begin;
with uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM sudoang.bc_station 
	JOIN sudoang.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from sudoang.bc_station_bis )
	) -- 67 rows
INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	uniques.op_p1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	uniques, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 67 rows
commit;

-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM sudoang.bc_station 
	JOIN sudoang.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from sudoang.bc_station_bis )
	AND nb_pass >= 2
	) --54 rows

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	op_p2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	bc_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	uniques,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 54 rows
commit;

-- 			op_p3 (biological_characteristic_type.no_name='Number p3') (see biological_characteristic_type.no_id=233)
-- nothing 


---- STEP 3: INSERT into dbeel_batch_fish: fish that were measured
---- 		Before insert length of fish, we need: "ba_id" and "fish_id"


---- 		Check duplicates: Joining bc_fish and dbeel_batch_fish by "sampling" and "ob_id" (to join "ob_id" we need to go through different tables)
select count(*) from sudoang.bc_fish_bis; -- 3790 rows
select sum(op_nb_eels) from sudoang.bc_ope_bis; -- 3771 rows

select * from sudoang.bc_fish_bis a join sudoang.bc_ope_bis o on ang_op_id = op_id -- 3758 rows
	join sudoang.dbeel_electrofishing l on l.ob_id = o.bc_ob_id
	join sudoang.dbeel_batch_fish b on l.ob_id = b.ba_ob_id; -- 0 rows


----		Insert individuals that were measured into the dbeel_batch_fish

-- There is a stage possible in biological characteristic, but this stage is entered in the dbeel batch fish table,
-- so we will not use it, because it comes from a table above in the hierarchy	
begin;
with uniques as (
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM sudoang.bc_station 
	JOIN sudoang.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from sudoang.bc_station_bis )
	) 
	
INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	uniques.bc_ob_id as ba_ob_id, 	-- ob_id batch_ope_fyke
	cast(NULL as uuid) as ba_ba_id,
	bc_fish_bis.fish_id		-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
	FROM 
	dbeel_nomenclature.species,
	dbeel_nomenclature.stage,
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status, 

	sudoang.bc_fish_bis
	join uniques
	on ang_op_id = op_id	

	WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel'  
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	and is_duplicate = FALSE
	; -- 437 rows
commit;


---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in asturias_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 

WITH missing AS (	
	Select bc_station.dbeel_op_id, bc_station.id, bc_station.sta_id, bc_ope_bis.* 
	FROM sudoang.bc_station 
	JOIN sudoang.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	WHERE sta_id NOT IN (select sta_id from sudoang.bc_station_bis)
	),	
	
    fish_from_bc as
	(	
	select * from missing 
	join sudoang.dbeel_electrofishing on ob_id = bc_ob_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	) --437
UPDATE sudoang.bc_fish_bis b
SET ba_id = fish_from_bc.ba_id
FROM fish_from_bc
WHERE fish_from_bc.fish_id = b.fish_id; -- 437 rows


-- select * from sudoang.bc_fish_bis where ba_id is null; -- 188 rows

/* There are 9 rows that are more than one individual: nag_nb_indiv > 1 (with length and weigth as a mean): Remove them!
delete from sudoang.dbeel_batch_fish where ba_id in (select ba_id from sudoang.bc_fish_bis where ang_nb_indiv > 1); -- 9 rows
update sudoang.bc_fish_bis set ba_id = NULL where ang_nb_indiv > 1;  -- 9 rows
*/
---- 		Insert LENGTH
BEGIN;
WITH bc_fish_extract as (
	SELECT bc_fish_bis.* 
	FROM sudoang.bc_station 
	JOIN sudoang.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	JOIN sudoang.bc_fish_bis ON ang_op_id=op_id
	WHERE sta_id NOT IN (select sta_id from sudoang.bc_station_bis)
	)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_length_cm AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_length_cm > 0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 3165 rows
COMMIT; 


---- 		Insert WEIGHT
begin;
WITH bc_fish_extract as (
	SELECT bc_fish_bis.* 
	FROM sudoang.bc_station 
	JOIN sudoang.bc_ope_bis on bc_station.sta_id = bc_ope_bis.op_sta_id
	JOIN sudoang.bc_fish_bis ON ang_op_id=op_id
	WHERE sta_id NOT IN (select sta_id from sudoang.bc_station_bis)
	)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	ang_pds_g AS bc_numvalue,
	fish_id
	FROM bc_fish_extract,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE ang_pds_g > 0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 437 rows
commit;
*/



DELETE FROM sudoang.dbeel_electrofishing de WHERE ob_starting_date >'2021-01-01'; --24



----------------------------------------------------------------------------------------------
-- CORRECTING DATA 
---------------------------------------------------------------------------------------------

/*
Regarding silvering data, length values from Alberto Aguirre were in centimeters, not mm
These data were corrected, testing a model in R to select these data and correct here
*/

begin;
with data_alberto as (
			select view_silvering.* from sudoang.view_silvering join sudoang.dbeel_electrofishing on view_silvering.ob_id = dbeel_electrofishing.ob_id where ob_dp_id = 23 -- 9574 rows
		     ),
--select * from data_alberto limit 10;
data_problem as (
	select (ln(weight) - 2.74 * ln(length) +11) > 4 as test, weight, length, ba_id, ob_starting_date from data_alberto 
	),
correction as (
		select * from data_problem join sudoang.dbeel_mensurationindiv_biol_charac on bc_ba_id = ba_id where test = TRUE and bc_no_characteristic_type = 39 -- 437 rows
		)
update sudoang.dbeel_mensurationindiv_biol_charac set bc_numvalue = 10*correction.bc_numvalue from correction where correction.bc_id = dbeel_mensurationindiv_biol_charac.bc_id;  -- 437 rows
commit;

SELECT * FROM dbeel.establishment WHERE et_establishment_name ='miteco';
UPDATE dbeel.establishment SET et_establishment_name ='MITECO' WHERE et_establishment_name ='miteco';

UPDATE dbeel.establishment SET et_establishment_name ='Agencia vasca del agua (URA)' WHERE et_establishment_name ='ANBIOTEK';
UPDATE dbeel.establishment SET et_establishment_name ='URA (ANBIOTEK)' WHERE et_establishment_name ='Agencia vasca del agua (URA)';

UPDATE dbeel.establishment SET et_establishment_name ='SUDOANG Pilot Basins (GT6)' WHERE et_establishment_name ='GT6';

UPDATE dbeel.establishment SET et_establishment_name ='Spanish Ministry (MITECO)' WHERE et_establishment_name ='MITECO';

UPDATE dbeel.establishment SET et_establishment_name ='Basque water agency (URA)  & ANBIOTEK' WHERE et_establishment_name ='URA (ANBIOTEK)';

UPDATE dbeel.establishment SET et_establishment_name ='University of Porto (UP)' WHERE et_establishment_name ='UP';

UPDATE dbeel.establishment SET et_establishment_name ='Spanish Fish Chart (SIBIC)' WHERE et_establishment_name ='SIBIC';

UPDATE dbeel.establishment SET et_establishment_name ='Spanish Ministry (MITECO)' WHERE et_establishment_name ='min esp';

UPDATE dbeel.establishment SET et_establishment_name ='Valencia Council (VAERSA)' WHERE et_establishment_name ='VAERSA';

UPDATE dbeel.establishment SET et_establishment_name ='University of Lisbon (FCUL) & APA, EDP, MARE' WHERE et_establishment_name ='FCUL (APA, EDP, MARE)';

UPDATE dbeel.establishment SET et_establishment_name ='Gipuzkoa Council & EKOLUR' WHERE et_establishment_name ='Diputaci�n de Gipuzkoa';

UPDATE dbeel.establishment SET et_establishment_name ='Navarra Council (GAN-NIK)' WHERE et_establishment_name ='The Navarra Environmental Management';

UPDATE dbeel.establishment SET et_establishment_name ='Galicia Council (Xunta de Galicia)' WHERE et_establishment_name ='The Xunta of Galicia';

UPDATE dbeel.establishment SET et_establishment_name ='University of C�rdoba (UCO)' WHERE et_establishment_name ='UCO';

UPDATE dbeel.establishment SET et_establishment_name ='Catalonia Council (ACA)' WHERE et_establishment_name ='ACA';

UPDATE dbeel.establishment SET et_establishment_name ='Asturias Council (DGPM Asturias)' WHERE et_establishment_name ='DGPM Asturias';



---------------------------------------------------------------------------------------------
-- CHECKING FISH DATA
---------------------------------------------------------------------------------------------

/*
Regarding fish tables (source), there are fishes in source tables without ba_id, so, they are not inserted in the dbeel
So, we have to check:
	- The station is not inserted because it is not reproyected in the river
	- The operation is duplicated and the fish are already inserted
First, join fish table with operation table and then, join with dbeel_electrofishing table
*/

-- PORTUGAL

SELECT count(*) from sudoang.portugal_fish where ba_id is NULL; -- 113 rows (total: 4202 rows)
SELECT count(*) FROM sudoang.portugal_ope; -- 868 rows (11 rows missing in dbeel_electrofishing)
SELECT count(*) FROM sudoang.portugal_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.portugal_ob_id=ee.ob_id; -- 857 rows
select * from sudoang.portugal_ope pl where problem_duplicates is TRUE; -- 11 rows (op_cod = 'A3' and 'A1')

-- 		Updating dbeel_op_id from portugal_ob_id in portugal_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.portugal_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.portugal_ob_id=ee.ob_id
) -- 857
UPDATE sudoang.portugal_ope set dbeel_ob_id=friend.portugal_ob_id from friend where friend.portugal_ob_id=portugal_ope.portugal_ob_id; --44
COMMIT;


with portugal_join as (
	select * from sudoang.portugal_fish fi join sudoang.portugal_ope op on (fi.ang_op_id, fi.dat) = (op.op_sta_id, op.op_dat) -- 4186 rows (16 rows)
	),
portugal_check as (
	select * from portugal_join join sudoang.dbeel_electrofishing on portugal_ob_id = ob_id
	)
select * from portugal_check; -- 4089 rows = 113 rows fish without ba_id

SELECT * from sudoang.portugal_fish where ba_id is NULL; -- 113 rows (total: 4202 rows)
-- Thses fish comes form ang_id = 'A1', 'A3' and 'Estorãos'
select * from sudoang.portugal_ope po where op_sta_id = 'A1' or op_sta_id = 'A3' or op_sta_id = 'Estorãos'; -- 11 rows
select * from sudoang.portugal_ope where op_sta_id = 'Estorãos'; -- 0 rows
select * from sudoang.portugal_location where "Code" = 'Estorãos'; -- 0 rows

/* Line  3440: TODO for Isabel, problem with stations A1 and A3.
Moreover, in portugal_fish table there is ang_op_id = 'Estorãos' that is not in operation nor station tables.
So, 113 fish not inserted!
*/


-- GIPUZKOA

select count(*) from guipuz_fish where species = 'Anguilla anguilla'; -- 4 rows ("sampling") (total = 31 976)
SELECT count(*) FROM sudoang.guipuz_ope; -- 1317 rows
SELECT count(*) FROM sudoang.guipuz_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.guipuz_ob_id=ee.ob_id; -- 1302 rows
select * from sudoang.guipuz_ope pl where is_sibic_duplicate is TRUE; -- 222 rows

-- 		Updating dbeel_op_id from guipuz_ob_id in guipuz_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.guipuz_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.guipuz_ob_id = ee.ob_id
) -- 1302
UPDATE sudoang.guipuz_ope set dbeel_ob_id=friend.guipuz_ob_id from friend where friend.guipuz_ob_id=guipuz_ope.guipuz_ob_id; -- 1302 rows
COMMIT;

-- 		There are 4 fish not inserted in the dbeel because the operation code (sampling) doesn't exist:
select * from sudoang.guipuz_fish fi left join sudoang.guipuz_ope op on fi.sampling = op.sampling where species = 'Anguilla anguilla' and pass is null; -- 4 rows
select * from sudoang.guipuz_ope go2 where sampling = 'PB2012009';

--		How many fish appear in the dbeel of Guipuzkoa's operations, which don't have dbeel_ob_id?
select * from sudoang.guipuz_fish fi 
	join sudoang.guipuz_ope op on fi.sampling = op.sampling -- 31972 rows (4 rows are missing)
	join sudoang.dbeel_electrofishing on guipuz_ob_id = ob_id where species = 'Anguilla anguilla'; -- 31156 rows (= 820 rows missing)

--		Why 816 fishes have been imported into the dbeel if there are not dbeel_ob_id?
select * from sudoang.guipuz_fish fi 
	join sudoang.guipuz_ope op on fi.sampling = op.sampling -- 31972 rows (4 rows are missing)
	join sudoang.guipuz_station on station = "Station"
--	join sudoang.dbeel_electrofishing on guipuz_ob_id = ob_id -- 0 rows These operations are missing in the dbeel_electrofishing
	where species = 'Anguilla anguilla' and dbeel_ob_id is null; -- 816 rows missing

	

	
	
-- no op_id removed unknowingly
	
	SELECT dbeel_op_id FROM sudoang.guipuz_station
	EXCEPT
	SELECT op_id FROM sudoang.dbeel_station; --0
	
	
	
-- these stations exist

SELECT * FROM sudoang.guipuz_ope op	
JOIN sudoang.guipuz_station on station = "Station"
WHERE is_sibic_duplicate=FALSE AND dbeel_ob_id IS NULL
	
-- OK so we have 15 lines of operation which are not there and we have no cue why....
-- we will insert them again

BEGIN;
ALTER TABLE sudoang.guipuz_ope ADD COLUMN detected_missing BOOLEAN DEFAULT FALSE;

UPDATE sudoang.guipuz_ope SET detected_missing= TRUE 
WHERE is_sibic_duplicate=FALSE AND dbeel_ob_id IS NULL;

INSERT INTO sudoang.dbeel_electrofishing (
	ob_id,
	ob_no_origin,
	ob_no_type,
	ob_no_period,
	ob_starting_date,
	ob_ending_date,
	ob_dp_id,
	ef_no_fishingmethod,
	ef_no_electrofishing_mean,
	ef_wetted_area,
	ef_fished_length,
	ef_fished_width,
	ef_nbpas,
	ob_op_id
	)
SELECT 
	guipuz_ob_id AS ob_id,
	observation_origin.no_id AS ob_no_origin,
	observation_type.no_id AS ob_no_type, 
	period_type.no_id AS ob_no_period,
	date AS ob_starting_date,
	CAST(NULL AS date) as ob_ending_date,
	data_provider.dp_id AS ob_dp_id, 
	scientific_observation_method.no_id AS ef_no_fishingmethod,
	electrofishing_mean.no_id AS ef_no_electrofishing_mean,	
	sampling_surface AS ef_wetted_area, 
	sampling_length AS ef_fished_length,
	sampling_width AS ef_fished_width,
	2 AS ef_nbpas,
	op.op_id as ob_op_id
	FROM 	dbeel_nomenclature.observation_origin,
		dbeel_nomenclature.scientific_observation_method,
		dbeel_nomenclature.observation_type,
		dbeel_nomenclature.period_type, 
		dbeel.data_provider,
		dbeel_nomenclature.electrofishing_mean,
		sudoang.dbeel_station as op
	join 
		sudoang.guipuz_station on dbeel_op_id=op_id
	join
		sudoang.guipuz_ope ope on ope.station=guipuz_station."Station"
		
	WHERE observation_origin.no_name='Raw data' 
	AND detected_missing =TRUE  -- THESE HAVE NOT BEEN INSERTED !
	AND scientific_observation_method.no_name='Unknown'
	AND scientific_observation_method.sc_observation_category='Electro-fishing'
	AND observation_type.no_name='Electro-fishing' 
	AND electrofishing_mean.no_name='By foot' 
	AND period_type.no_name='Daily' 
	AND data_provider.dp_name='Iker Azpiroz'
	; 	--15
	
BEGIN;
WITH friend as (
SELECT * FROM sudoang.guipuz_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.guipuz_ob_id = ee.ob_id
) -- 1302
UPDATE sudoang.guipuz_ope set dbeel_ob_id=friend.guipuz_ob_id from friend where friend.guipuz_ob_id=guipuz_ope.guipuz_ob_id; -- 1302 rows
COMMIT;

-- TOTAL NUMBER

with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from sudoang.guipuz_ope
WHERE detected_missing =TRUE
),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from sudoang.guipuz_ope
WHERE detected_missing =TRUE),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

-- select * from electrofishing_temp order by sampling;

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run1+electrofishing_temp.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
       WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 15  rows

-- OP_P1	
	

with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from sudoang.guipuz_ope
WHERE detected_missing =TRUE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from sudoang.guipuz_ope
WHERE detected_missing =TRUE),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p1' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 15


-- 			op_p2 (biological_characteristic_type.no_name='Number p2') (see biological_characteristic_type.no_id=232)
begin;
with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from sudoang.guipuz_ope
WHERE detected_missing =TRUE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from sudoang.guipuz_ope
WHERE detected_missing =TRUE),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling
)

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.run2 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM 
	electrofishing_temp,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
        WHERE species.no_name='Anguilla anguilla'
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Number p2' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 15 rows


-- 			Density (biological_characteristic_type.no_name='Density') (see biological_characteristic_type.no_id=48)

with surface_corrected as(
select case when sampling_surface = 0 then null else sampling_surface end as sampling_surface, guipuz_ob_id, sampling, run1_ang, run2_ang
from sudoang.guipuz_ope
WHERE detected_missing =TRUE),

anguila as (
select
guipuz_ob_id,
sampling,
coalesce(run1_ang,0) as run1,
coalesce(run2_ang,0) as run2,
coalesce(round(cast((coalesce(run1_ang, 0) + coalesce(run2_ang, 0))/sampling_surface as numeric), 3), 0) as density
from surface_corrected),

other as (
select
guipuz_ob_id, 
sampling,
0 as run1,
0 as run2,
0 AS density
from sudoang.guipuz_ope
WHERE detected_missing =TRUE),

electrofishing_temp as (select * from anguila 
union
select * from other where sampling not in (select sampling from anguila)
order by sampling)

INSERT INTO sudoang.dbeel_batch_ope
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	stage.no_id AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	electrofishing_temp.density AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,
	electrofishing_temp.guipuz_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id
	FROM
	electrofishing_temp, 
	dbeel_nomenclature.species, 
	dbeel_nomenclature.stage, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status
	WHERE species.no_name='Anguilla anguilla' 
	AND stage.no_name='Yellow eel' 
	AND biological_characteristic_type.no_name='Density' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'
	; -- 15 rows

----		Insert individuals that were measured into the dbeel_batch_fish


with anguila as (
select
fish_id,
a.sampling,
guipuz_ob_id as ba_ob_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from sudoang.guipuz_fish a 
	join sudoang.guipuz_ope o on a.sampling = o.sampling
	where species = 'Anguilla anguilla'
	AND detected_missing =TRUE)
--SELECT * FROM anguila; -- 816

INSERT INTO sudoang.dbeel_batch_fish
	SELECT uuid_generate_v4() AS ba_id,
	species.no_id AS ba_no_species,
	CASE WHEN typeang='Amarilla' THEN 226 --'Yellow eel' 
	     WHEN typeang='Plateada' THEN 227 -- 'Silver eel'
	     WHEN typeang='Indefinida' THEN 224 -- unknown
	     END AS ba_no_stage,
	value_type.no_id AS ba_no_value_type,
	biological_characteristic_type.no_id AS ba_no_biological_characteristic_type,
	1 AS ba_quantity,
	individual_status.no_id AS ba_no_individual_status,
	1 AS ba_batch_level,		-- This ba_batch_level must be changed to 1 (we didn't find subsamples)
	anguila.ba_ob_id as ba_ob_id, 
	cast(NULL as uuid) as ba_ba_id,
	anguila.fish_id			-- fish_id can be repeated because of different tables (ebro_fish, nsp_efiplus_fish...)
--	anguila.sampling 		-- DOESN'T WORK because "locationid" is an integer and "sampling" is text
	FROM 
	anguila,
	dbeel_nomenclature.species, 
	dbeel_nomenclature.biological_characteristic_type,
	dbeel_nomenclature.value_type,
	dbeel_nomenclature.individual_status 
	WHERE species.no_name='Anguilla anguilla' 
	AND biological_characteristic_type.no_name='Number' 
	AND individual_status.no_name='Alive' 
	AND value_type.no_name='Raw data or Individual data'; 



---- STEP 4: INSERT into dbeel_mensurationindiv_biol_charact: length and weight
---- 		To integrate length and weight of fish, "ba_id" must be included before in guipuz_fish table
---- 		We have the same problem as in operation because we can't join with "locationid" but in this case, we can't generate the uuid in guipuz_fish table! 

ALTER TABLE sudoang.guipuz_fish ADD COLUMN detected_missing BOOLEAN DEFAULT FALSE;


with fish_from_iker as
	(select * from sudoang.dbeel_station 
	join sudoang.dbeel_electrofishing on op_id = ob_op_id
	join sudoang.dbeel_batch_fish on ba_ob_id = ob_id
	JOIN sudoang.guipuz_ope ON guipuz_ope.guipuz_ob_id = ba_ob_id
	where ob_dp_id = 14
	AND detected_missing =TRUE) -- 816 rows	
--select * from fish_from_iker join sudoang.guipuz_fish on fish_from_iker.fish_id = guipuz_fish.fish_id limit 10;

UPDATE sudoang.guipuz_fish b
SET (ba_id, detected_missing) = (fish_from_iker.ba_id, TRUE)
FROM fish_from_iker
WHERE fish_from_iker.fish_id = b.fish_id; -- 816 rows
--select * from sudoang.guipuz_fish where ba_id is not null limit 10;


---- 		Insert LENGTH
-- with levante_fish_extract as (
-- select *, (row_number() OVER (PARTITION BY locationid ORDER BY "CPEZLTOTAL" DESC))%3 as modulo from sudoang.levante_fish order by locationid),


-- THERE WAS AN ERROR THERE (WEIGHT INSTEAD OF LENGTH) IT IS CORRECTED JUST BELOW

with guipuz_fish_extract as (
select * from sudoang.guipuz_fish 
WHERE detected_missing =TRUE
), -- the missing values

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 816

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,  
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 816 rows 


-- HERE IS THE CORRECTION

with guipuz_fish_extract as (
select * from sudoang.guipuz_fish 
WHERE detected_missing =TRUE
), -- the missing values

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract),

--SELECT * FROM anguila
dbeel_mensurationindiv_biol_charac_temp AS (
SELECT * FROM sudoang.dbeel_mensurationindiv_biol_charac JOIN 
anguila ON bc_ba_id = ba_id 
WHERE bc_no_characteristic_type = 39)

DELETE FROM sudoang.dbeel_mensurationindiv_biol_charac  WHERE bc_id IN (
SELECT bc_id FROM dbeel_mensurationindiv_biol_charac_temp); --815


-- NOW INSERT AGAIN

with guipuz_fish_extract as (
select * from sudoang.guipuz_fish 
WHERE detected_missing =TRUE
), -- the missing values

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
--select * from anguila; -- 816

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length AS bc_numvalue,  
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length >0
	AND biological_characteristic_type.no_name = 'Length' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 815 rows 





---- 		Insert WEIGHT

with guipuz_fish_extract as (
select * from sudoang.guipuz_fish  
WHERE detected_missing =TRUE), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	weight AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE weight >0
	AND biological_characteristic_type.no_name = 'Weight' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 815


---- 		Insert VERTICAL EYE DIAMETER

with guipuz_fish_extract as (
select * from sudoang.guipuz_fish  
WHERE detected_missing =TRUE), -- the rows with "ba_id" NULL must be other species!

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	eye_diam_vert AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE eye_diam_vert >0
	AND biological_characteristic_type.no_name = 'eye_diam_vert' 
	AND value_type.no_name = 'Raw data or Individual data';--17

---- 		Insert HORIZONTAL EYE DIAMETER

with guipuz_fish_extract as (
select * from sudoang.guipuz_fish  
WHERE detected_missing =TRUE), 

anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)

INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	eye_diam_horiz AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE eye_diam_horiz >0
	AND biological_characteristic_type.no_name = 'eye_diam_horiz' 
	AND value_type.no_name = 'Raw data or Individual data'
; --17


---- 		Insert LENGTH OF THE PECTORAL FIN

with guipuz_fish_extract as (
select * from sudoang.guipuz_fish  
WHERE detected_missing =TRUE), 
anguila as (
select
fish_id,
ba_id,
length_mm as length,
weight_g as weight,
case when dv_mm = 0 then NULL else dv_mm end as eye_diam_vert,
case when dh_mm = 0 then NULL else dh_mm end as eye_diam_horiz,
case when lap_mm = '0,00' then NULL else regexp_replace(lap_mm, ',', '.')::numeric end as length_pect,  -- It's text!!!
NULL::boolean AS presence_neuromast, -- useless here but will be used with the silvering data from pilot basins
NULL::boolean AS contrast,
typeang
from guipuz_fish_extract)
INSERT INTO sudoang.dbeel_mensurationindiv_biol_charac
	SELECT uuid_generate_v4() AS bc_id, 
	ba_id AS bc_ba_id, 
	biological_characteristic_type.no_id AS bc_no_characteristic_type, 
	value_type.no_id AS bc_no_value_type, 
	length_pect AS bc_numvalue,
	fish_id
	FROM anguila,  
	dbeel_nomenclature.biological_characteristic_type, 
	dbeel_nomenclature.value_type
	WHERE length_pect >0
	AND biological_characteristic_type.no_name = 'length_pect' 
	AND value_type.no_name = 'Raw data or Individual data'
; -- 17

COMMIT ; --4720






-- GALICIA
select * from sudoang.galicia_fish gf where ba_id is null and species = 'Anguila'; -- 294 rows (total = 44 191)
SELECT count(*) FROM sudoang.galicia_ope; -- 5267 rows
SELECT count(*) FROM sudoang.galicia_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.galicia_ob_id=ee.ob_id; -- 5267 rows
select * from sudoang.galicia_ope pl where is_duplicate is TRUE; -- 4 rows

-- 		Updating dbeel_op_id from galicia_ob_id in galicia_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.galicia_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.galicia_ob_id = ee.ob_id
) -- 5267
UPDATE sudoang.galicia_ope set dbeel_ob_id=friend.galicia_ob_id from friend where friend.galicia_ob_id=galicia_ope.galicia_ob_id; -- 5267 rows
COMMIT;

-- 		Checking the operations of the fishes missing
--			There are 294 fishes not inserted because the operations aren't in galicia_ope table
select count(*) from sudoang.galicia_fish gf join sudoang.galicia_ope gop on gf.cod_ope = gop.cod_ope; -- 43 897 (total = 44 191) -> 294 fishes missing

select * from sudoang.galicia_fish where cod_ope not in (select cod_ope from sudoang.galicia_ope); -- 294 rows (ex. INV91_0095)
select * from sudoang.galicia_ope where cod_ope like '%INV91_009%';


-- BASQUE COUNTRY (first table)
SELECT count(*) from sudoang.bc_fish where ba_id is NULL; -- 9 rows (total: 5 981 rows)
SELECT count(*) FROM sudoang.bc_ope; -- 885 rows (0 rows missing in dbeel_electrofishing)
SELECT count(*) FROM sudoang.bc_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.bc_ob_id = ee.ob_id; -- 885 rows
select * from sudoang.bc_ope pl where is_duplicate is TRUE; -- 0 rows

-- 		Updating dbeel_op_id from bc_ob_id in bc_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.bc_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.bc_ob_id = ee.ob_id
) -- 885 rows
UPDATE sudoang.bc_ope set dbeel_ob_id=friend.bc_ob_id from friend where friend.bc_ob_id=bc_ope.bc_ob_id; -- 885 rows
COMMIT;

-- select ang_op_id, ang_pass, count(*) from sudoang.bc_fish group by ang_op_id, ang_pass order by ang_op_id ;

select * from sudoang.bc_fish fi join sudoang.bc_ope op on fi.ang_op_id = op.op_id 
	join sudoang.dbeel_electrofishing on op.dbeel_ob_id = ob_id; -- 5972 rows = 9 rows fish without ba_id
	
select * from sudoang.bc_ope bo where op_id in (select distinct ang_op_id as op_id from sudoang.bc_fish fi where ba_id is null);
-- op_id = 22964 is in bc_fish but not in bc_ope, so we lost 9 eels measured because there is no the operation 

select * from sudoang.bc_ope bo where op_sta_id in (select distinct ang_sta_id as op_sta_id from sudoang.bc_fish fi where ba_id is null);
-- neither the station


-- NAVARRA
SELECT count(*) from sudoang.navarra_fish where ba_id is NULL; -- 346 rows (total: 3 973 rows)
SELECT count(*) FROM sudoang.navarra_ope; -- 66 rows (0 rows missing in dbeel_electrofishing)
SELECT count(*) FROM sudoang.navarra_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.navarra_ob_id = ee.ob_id; -- 66 rows
select * from sudoang.navarra_ope pl where is_duplicate is TRUE; -- 9 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.navarra_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.navarra_ob_id = ee.ob_id
) -- 66 rows
UPDATE sudoang.navarra_ope set dbeel_ob_id=friend.navarra_ob_id from friend where friend.navarra_ob_id=navarra_ope.navarra_ob_id; -- 66 rows
COMMIT;

select * from sudoang.navarra_fish fi join sudoang.navarra_ope op on fi.ang_op_id = op.op_id 
	join sudoang.dbeel_electrofishing on op.dbeel_ob_id = ob_id where is_duplicate = TRUE; -- 346 rows	
-- 346 eels are not inserted because they come from operations that were duplicates! Must we include them? 


-- ANDALUCIA
SELECT count(*) from sudoang.andalucia_fish where ba_id is NULL; -- 2 rows (total: 31 rows)
SELECT count(*) FROM sudoang.andalucia_ope; -- 92 rows (1 rows missing in dbeel_electrofishing -- where andalucia_ob_id is null)
SELECT count(*) FROM sudoang.andalucia_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.andalucia_ob_id = ee.ob_id; -- 91 rows

-- There is one duplicate:
select * from sudoang.andalucia_ope pl where is_duplicate is TRUE; -- 1 rows
SELECT * FROM sudoang.andalucia_ope pp where andalucia_ob_id not in (select ob_id as andalucia_ob_id from sudoang.dbeel_electrofishing);

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.andalucia_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.andalucia_ob_id = ee.ob_id
) -- 91 rows
UPDATE sudoang.andalucia_ope set dbeel_ob_id=friend.andalucia_ob_id from friend where friend.andalucia_ob_id=andalucia_ope.andalucia_ob_id; -- 91 rows
COMMIT;

select * from sudoang.andalucia_fish fi join sudoang.andalucia_ope op on (fi.fish_sta_id, fi.fish_op_dat) = (op.sta_id, op.op_dat) 
	join sudoang.dbeel_electrofishing on op.dbeel_ob_id = ob_id; -- 29 rows	


select * from sudoang.andalucia_ope bo where (sta_id, op_dat) in (select fish_sta_id, fish_op_dat from sudoang.andalucia_fish fi where ba_id is null); -- 0 rows
select * from sudoang.andalucia_fish fi where ba_id is null;
-- fish_sta_id: 1.40.6, 1.40.3 there aren't in the operation table -> impossible to link these eels, so don't imported!

	
-- SPAIN
SELECT count(*) from sudoang.spain_fish where ba_id is NULL; -- 1125 rows (total: 3488 rows)
SELECT count(*) FROM sudoang.spain_ope; -- 1075 rows (0 rows missing in dbeel_electrofishing -- where spain_ob_id is null)
SELECT count(*) FROM sudoang.spain_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.spain_ob_id = ee.ob_id; -- 948 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.spain_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.spain_ob_id = ee.ob_id
) -- 948 rows
UPDATE sudoang.spain_ope set dbeel_ob_id=friend.spain_ob_id from friend where friend.spain_ob_id=spain_ope.spain_ob_id; -- 948 rows
COMMIT;


-- In dbeel_electrofishing: 972 rows (1075 operations - 99 duplicates - 4 with the same sta_cod) were inserted. 
-- But now, we found only 948 rows!
select * from sudoang.spain_ope pl where is_duplicate is TRUE; -- 99 rows
SELECT * FROM sudoang.spain_ope pp where spain_ob_id not in (select ob_id as spain_ob_id from sudoang.dbeel_electrofishing) and is_duplicate = FALSE; -- 28 rows (from 127 total rows, 99 duplicates)
-- 24 rows with op_id and op_cod NULL
-- 4 rows with op_id and op_cod: '0500050-11/07/2008', 'CRAAI-022-06/07/2008', 'CRL-040-04/07/2008', 'CROKGO-032-03/07/2008' that are the same as:
select * from sudoang.spain_ope bo where op_id in (select ang_op_id from sudoang.spain_fish fi where ba_id is null) and is_duplicate = FALSE order by op_id; -- 4 rows

select * from sudoang.spain_fish fi join sudoang.spain_ope op on fi.ang_op_id = op.op_id 	-- 2828 rows
	join sudoang.dbeel_electrofishing on op.dbeel_ob_id = ob_id ; 	-- 2363 rows that are imported into dbeel (where is_duplicate = TRUE: 0 rows)

select distinct op_cod from sudoang.spain_fish fi join sudoang.spain_ope op on fi.ang_op_id = op.op_id 
where spain_ob_id not in (select ob_id as spain_ob_id from sudoang.dbeel_electrofishing) and is_duplicate = false;
-- '0500050-11/07/2008', 'CRAAI-022-06/07/2008', 'CRL-040-04/07/2008', 'CROKGO-032-03/07/2008'


SELECT * from sudoang.spain_fish where ba_id is null and ang_op_id in (select op_id from sudoang.spain_ope); -- 465 rows (from 1125 total of ba_id null)
select * from sudoang.spain_fish fi left join sudoang.spain_ope op on fi.ang_op_id = op.op_id where op_id is null; -- 660 rows (from 1125 total of ba_id null)

SELECT * from sudoang.spain_fish where ba_id is null and ang_op_id in (select op_id from sudoang.spain_ope where is_duplicate = TRUE); -- 448 rows (+ 17 rows is_duplicate = FALSE)

SELECT * from sudoang.spain_fish where ba_id is null and ang_op_id in (select op_id from sudoang.spain_ope so where is_duplicate = false); -- 17 rows
select * from sudoang.spain_ope where op_id in (SELECT ang_op_id from sudoang.spain_fish where ba_id is null) and is_duplicate = FALSE; -- 4 rows
-- '0500050-11/07/2008', 'CRAAI-022-06/07/2008', 'CRL-040-04/07/2008', 'CROKGO-032-03/07/2008'
-- Of the 1125 non-imported eels, 660 come from operations not listed in the operation table, 448 come from duplicates and 17 from four operations that have not been imported into the dbeel!


-- VALENCIA
SELECT count(*) from sudoang.valencia_fish where ba_id is NULL; -- 1127 rows (total: 3435 rows)
SELECT count(*) FROM sudoang.valencia_sta_ope; -- 193 rows (0 rows missing in dbeel_electrofishing -- where spain_ob_id is null)
SELECT count(*) FROM sudoang.valencia_sta_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.val_ob_id = ee.ob_id; -- 193 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.valencia_sta_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.val_ob_id = ee.ob_id
) -- 193 rows
UPDATE sudoang.valencia_sta_ope set dbeel_ob_id=friend.val_ob_id from friend where friend.val_ob_id=valencia_sta_ope.val_ob_id; -- 193 rows
COMMIT;

select * from sudoang.valencia_fish mf where ba_id is null; -- 1227 rows
SELECT * from sudoang.valencia_fish where ba_id is null and ang_sta_id in (select op_sta_id from sudoang.valencia_sta_ope); -- 0 rows (from 1227 total of ba_id null)
select distinct ang_sta_id from sudoang.valencia_fish fi left join sudoang.valencia_sta_ope op on fi.ang_sta_id = op.op_sta_id where op_sta_id is null; -- 1227 rows from 84 ang_sta_id that don't matck in ope table
-- The 1227 eels not imported correspond to operations that do not appear in the table operation!


-- GT6 
SELECT count(*) from sudoang.gt6_fish where ba_id is NULL; -- 3 rows (total: 4466 rows)
SELECT count(*) FROM sudoang.gt6_ope; -- 94 rows (0 rows missing in dbeel_electrofishing -- where spain_ob_id is null)
SELECT count(*) FROM sudoang.gt6_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.gt6_ob_id = ee.ob_id; -- 94 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.gt6_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.gt6_ob_id = ee.ob_id
) -- 94 rows
UPDATE sudoang.gt6_ope set dbeel_ob_id=friend.gt6_ob_id from friend where friend.gt6_ob_id=gt6_ope.gt6_ob_id; -- 94 rows
COMMIT;

select * from sudoang.gt6_fish mf where ba_id is null; -- 3 rows 
-- This ang_op_id = '130.002' doesn't have the op_cod associated (check table) -> looking in SIBIC.R that is TER!


-- MINHO
SELECT count(*) from sudoang.minho_fish where ba_id is NULL; -- 150 rows (total: 2010 rows)
SELECT count(*) FROM sudoang.minho_ope; -- 78 rows (0 rows missing in dbeel_electrofishing -- where spain_ob_id is null)
SELECT count(*) FROM sudoang.minho_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.minho_ob_id = ee.ob_id; -- 78 rows

-- 		Updating dbeel_op_id from navarra_ob_id in navarra_ope
BEGIN;
WITH friend as (
SELECT * FROM sudoang.minho_ope pp JOIN sudoang.dbeel_electrofishing ee on pp.minho_ob_id = ee.ob_id
) -- 78 rows
UPDATE sudoang.minho_ope set dbeel_ob_id=friend.minho_ob_id from friend where friend.minho_ob_id=minho_ope.minho_ob_id; -- 78 rows
COMMIT;

select * from sudoang.minho_fish mf where ba_id is null; -- 150 rows
SELECT * from sudoang.minho_fish where ba_id is null and ang_op_id in (select op_id from sudoang.minho_ope); -- 0 rows (from 150 total of ba_id null)
select * from sudoang.minho_fish fi left join sudoang.minho_ope op on fi.ang_op_id = op.op_id where op_id is null; -- 150 rows from 8 ang_op_id that don't matck in ope table
-- The 150 eels not imported correspond to operations that do not appear in the table operation!
