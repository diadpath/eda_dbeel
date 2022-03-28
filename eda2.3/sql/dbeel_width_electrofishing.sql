select * from dbeel_rivers.rna limit 10;
select * from dbeel_rivers.rn limit 10;

select * from dbeel.observation_places limit 10;
select * from sudoang.dbeel_station limit 10;
select * from dbeel.view_electrofishing limit 10;
select st_srid(the_geom) from dbeel.view_electrofishing limit 10; -- 3035 (SELECT Find_SRID doesn't work)

select count(*) from sudoang.dbeel_electrofishing where dbeel_electrofishing.ef_fished_width !=10 and dbeel_electrofishing.ef_fished_width !=20 and dbeel_electrofishing.ef_fished_width !=30
and dbeel_electrofishing.ef_fished_width !=40 and dbeel_electrofishing.ef_fished_width !=50; -- 11224 rows


with electro_surface as (
	select 
		dbeel_station.op_id,
		dbeel_station.op_placename,
		dbeel_station.op_gis_layername,
		dbeel_station.the_geom,
		dbeel_station.geom_reproj,
		dbeel_station.x,
		dbeel_station.y,
		dbeel_electrofishing.ob_id,
		dbeel_electrofishing.ob_starting_date,
		dbeel_electrofishing.ob_op_id,
		dbeel_electrofishing.ef_wetted_area,
		dbeel_electrofishing.ef_fished_length,
		dbeel_electrofishing.ef_fished_width
	FROM sudoang.dbeel_station
             JOIN sudoang.dbeel_electrofishing ON dbeel_station.op_id = dbeel_electrofishing.ob_op_id
             where dbeel_electrofishing.ef_fished_width !=10 and dbeel_electrofishing.ef_fished_width !=20 and dbeel_electrofishing.ef_fished_width !=30
             and dbeel_electrofishing.ef_fished_width !=40 and dbeel_electrofishing.ef_fished_width !=50
	),
--select count(*) from electro_surface; -- 11224 rows

joining_all as(
select 
	electro_surface.*,
	rn.gid,
	rn.idsegment,
	rn.geom,
	rn.country,
	rna.distanceseam, 
	rna.surfacebvm2, 
	rna.name, 
	rna.basin, 
	rna.riverwidthm, 
	rna.emu,
	st_distance(electro_surface.geom_reproj,rn.geom) as distance
from electro_surface
	join dbeel_rivers.rn on st_dwithin(electro_surface.geom_reproj,rn.geom,0.1) -- Rounding problem: if we use 0.1 m it is not exactly the same measure
		join dbeel_rivers.rna on rn.idsegment = rna.idsegment order by distance asc, surfacebvm2 desc  -- If there is ever a point at a confluence, we choose the largest watercourse
)
--select * from joining_all; -- 11078 rows
select distinct on (ob_id) * from joining_all;  -- 11 028 rows

select count(op_id) from sudoang.dbeel_station; -- 15 959 stations

