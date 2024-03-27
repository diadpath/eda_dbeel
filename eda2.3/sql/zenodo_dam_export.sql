
COPY (
SELECT 
op_id,
CASE WHEN op_gis_layername= 'FCUL/MARE' THEN 'FCUL, APA, EDP, MARE'
     WHEN op_gis_layername= 'FCUL (APA, EDP, MARE)' THEN 'FCUL, APA, EDP, MARE'
     ELSE op_gis_layername END AS op_gis_layername,
--op_gislocation,
op_placename,
op_op_id,
id_original,
country,
--ob_id,
CASE WHEN dp_name ilike '%Isabel%' THEN 'Isabel Domingos and Ana Telhado'  
     WHEN dp_name ilike '%Belen%' THEN 'Belén Muñoz' 
     WHEN dp_name ilike '%Rosa%' THEN 'Rosa Olivo del Amo'
     ELSE dp_name
END AS dp_name,

obstruction_type_code,
obstruction_type_name,
--obstruction_impact_code,
--obstruction_impact_name,
po_obstruction_height,
--po_downs_pb,
--po_downs_water_depth,
po_presence_eel_pass,
--po_method_perm_ev,
po_date_presence_eel_pass,
fishway_type_code,
fishway_type_name,
--downstream_mitigation_measure_name,
googlemapscoods,
st_x(st_transform(the_geom, 4326)) AS x_espg_4326,
st_y(st_transform(the_geom, 4326)) AS y_espg_4326
FROM sudoang.view_obstruction)

 TO '/temp/obstacles.csv' WITH (FORMAT CSV, HEADER TRUE, DELIMITER ';', ENCODING 'UTF8'); --106406