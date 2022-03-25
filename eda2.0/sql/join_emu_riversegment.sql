select ST_GeometryType(geom) from uga2010.t_emuagreg_ema
update uga2010.t_emuagreg_ema set geom=st_multi(geom) ;

DROP TABLE IF EXISTS uga2010.join_emu_wso1;
create table uga2010.join_emu_wso1 as
select wso1_id,emu_name_short,emu_coun_abrev,emu_cty_id from 
ccm21.riversegments
join uga2010.t_emuagreg_ema 
on st_intersects(geom,the_geom)
;



