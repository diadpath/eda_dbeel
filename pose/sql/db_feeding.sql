
---************************************--
-- 	database feeding
---************************************--
-- Table RBD
INSERT INTO "BDEel"."RBD" (gis_name, gis_layer_name, fk_observation_place_syb_type_id, location_id, place_name, the_geom)
	SELECT 'WISE' as gis_name, 'RBD_F1v3' as gis_layer_name, 4 as fk_observation_place_syb_type_id, gid as location_id, name_engl as place_name, the_geom FROM "GIS"."RBD_F1v3";

-- Table Country
INSERT INTO "BDEel".region (gis_name, gis_layer_name, fk_observation_place_syb_type_id, location_id, place_name, country, the_geom)
	SELECT 'UNEP' as gis_name, 'admin98' as gis_layer_name, 3 as fk_observation_place_syb_type_id, gid as location_id, "ADMIN_NAME" as place_name, "CNTRY_NAME" as country, the_geom FROM "GIS"."admin98";

-- Parent table observations
INSERT INTO "BDEel".observations (fk_observation_origin_id, fk_observation_type_id, fk_observation_place_id) 	
	SELECT * FROM (SELECT trunc(random() * 2 + 10) FROM generate_series(1,3)) as a, (SELECT trunc(random() * 10 + 12)  FROM generate_series(1,3)) as b , (SELECT observation_place_id FROM "BDEel".observation_places ORDER BY random() LIMIT 30) as c;

-- Table scientific_observation
INSERT INTO "BDEel".scientific_observation (fk_observation_origin_id, fk_observation_type_id, fk_observation_place_id) 	
	SELECT * FROM (SELECT trunc(random() * 2 + 10) FROM generate_series(1,3)) as a, (SELECT trunc(random() * 10 + 12)  FROM generate_series(1,3)) as b , (SELECT observation_place_id FROM "BDEel".observation_places ORDER BY random() LIMIT 30) as c;

-- Table batch
INSERT INTO "BDEel".batch (species, stage, fk_observation_id)
	SELECT 36, b.*, c.* FROM (SELECT trunc(random() * 7 + 37) FROM generate_series(1,3)) as b,(SELECT observations_id FROM "BDEel".observations ORDER BY random() LIMIT 10) as c
;
