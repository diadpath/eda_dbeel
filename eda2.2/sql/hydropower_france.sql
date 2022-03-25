select * from roe_v4.roe where stobstecou ='Validé' and nomprincip like '%Guerlédan%';


drop table if exists rht.most_impacting_dams;
create table rht.most_impacting_dams as (
select 
 distinct on (roe_code)
 row_number() over (order by roe_code) as gid,
 * from (
 
	select cdobstecou as roe_code, 
	st_x(st_transform(roe.geom, 4326)) as X,
	st_y(st_transform(roe.geom, 4326)) as Y,
	nomprincip as "main_name", 
	nomseconda as "secondary_name",
	lbtypeouvr as "dam_type",
	lbtypedisp as "pass type",
	lbtypedi_1 as "secondary pass type",
	hautchutet as "dam_height",
	nomentiteh as river_name,
	cdcommune as postal_code,
	lbcommune as town_name,
	altipointc as altitude,
	nomlimiteh as basin,
	"300_450" as number_eel_300_450,
	"450_600" as number_eel_450_600,
	"600_750" as number_eel_600_750,
	"750"  as number_eel_750,
	total as number_eel_total,
	dmer as dmer,
	cumnbbar as "cumulated_number_dams_downstream",
	st_distance(roe.geom, silver_production.geom) as distance_riverdrain_dam,
	rhtvs2.id_drain,
	module,
	roe.geom
	 from roe_v4.roe 
	join rht.silver_production  on st_dwithin(roe.geom, silver_production.geom,1000)
	join rht.rhtvs2 on rhtvs2.id_drain=silver_production.id_drain
	join rht.attributs_rht_fev_2011_vs2 on rhtvs2.id_drain=attributs_rht_fev_2011_vs2.id_drain
	where stobstecou ='Validé' and lbusageobs = 'Energie et hydroélectricité' 
	--and altipointc < 100 -- altitude < 100 m
	--and dmer < 250000 -- distance to the sea < 100 km
	--and total > 100	
	and cdobstecou not in ('ROE106058','ROE88566')
	order by roe_code, distance_riverdrain_dam asc
) as sub
) ;--4725

drop table if exists rht.most_impacting_dams2;
create table rht.most_impacting_dams2 as (
select 
 distinct on (roe_code)
 row_number() over (order by roe_code) as gid,
 * from (
 
	select cdobstecou as roe_code, 
	st_x(st_transform(roe.geom, 4326)) as X,
	st_y(st_transform(roe.geom, 4326)) as Y,
	nomprincip as "main_name", 
	nomseconda as "secondary_name",
	lbtypeouvr as "dam_type",
	lbtypedisp as "pass type",
	lbtypedi_1 as "secondary pass type",
	hautchutet as "dam_height",
	nomentiteh as river_name,
	cdcommune as postal_code,
	lbcommune as town_name,
	altipointc as altitude,
	nomlimiteh as basin,
	"300_450" as number_eel_300_450,
	"450_600" as number_eel_450_600,
	"600_750" as number_eel_600_750,
	"750"  as number_eel_750,
	total as number_eel_total,
	dmer as dmer,
	cumnbbar as "cumulated_number_dams_downstream",
	st_distance(roe.geom, silver_production.geom) as distance_riverdrain_dam,
	rhtvs2.id_drain,
	module,
	lbusageobs,
	roe.geom
	 from roe_v4.roe 
	join rht.silver_production  on st_dwithin(roe.geom, silver_production.geom,1000)
	join rht.rhtvs2 on rhtvs2.id_drain=silver_production.id_drain
	join rht.attributs_rht_fev_2011_vs2 on rhtvs2.id_drain=attributs_rht_fev_2011_vs2.id_drain
	where stobstecou ='Validé' 
	--and altipointc < 100 -- altitude < 100 m
	--and dmer < 250000 -- distance to the sea < 100 km
	--and total > 100	
	and cdobstecou not in ('ROE106058','ROE88566')
	order by roe_code, distance_riverdrain_dam asc
) as sub
) ;--4725


select * from rht.most_impacting_dams
where roe_code='ROE52354'

with  dam_type_sub as (
select CASE WHEN dmer<250000 then '<250'
            WHEN dmer>=250000 then '>250'
       end as dmer_group,
       * 
       FROM
       rht.most_impacting_dams)
       select count(*) as number,
       round(sum(number_eel_total)) as nb_eel,
       dmer_group from dam_type_sub 
group by dmer_group






select * ,
st_distance(most_impacting_dams.geom, rhtvs2.the_geom) as distance_riverdrain_dam 
from rht.most_impacting_dams
	join rht.rhtvs2 ON
	st_dwithin(most_impacting_dams.geom, rhtvs2.the_geom,1000)


/*

select st_distance(roe.geom, silver_production.geom),total, *  from roe_v4.roe 
	join (select * from rht.silver_production where  total >10) as silver_production 
	on st_dwithin(roe.geom, silver_production.geom,1000) 
		join rht.rhtvs2 on rhtvs2.id_drain=silver_production.id_drain


select 
 distinct on (roe_code)
 row_number() over (order by roe_code) as gid,
 * from (
 
	select cdobstecou as roe_code, 
	st_x(st_transform(roe.geom, 4326)) as X,
	st_y(st_transform(roe.geom, 4326)) as Y,
	nomprincip as "main_name", 
	nomseconda as "secondary_name",
	lbtypeouvr as "dam_type",
	lbtypedisp as "pass type",
	lbtypedi_1 as "secondary pass type",
	hautchutet as "dam_height",
	nomentiteh as river_name,
	cdcommune as postal_code,
	lbcommune as town_name,
	altipointc as altitude,
	nomlimiteh as basin,
	"300_450" as number_eel_300_450,
	"450_600" as number_eel_450_600,
	"600_750" as number_eel_600_750,
	"750"  as number_eel_750,
	total as number_eel_total,
	dmer as distance_sea,
	cumnbbar as "cumulated_number_dams_downstream",
	st_distance(roe.geom, silver_production.geom) as distance_riverdrain_dam,
	roe.geom
	 from roe_v4.roe 
	join (select * from rht.silver_production where  total >10) as silver_production on st_dwithin(roe.geom, silver_production.geom,1000)
	join rht.rhtvs2 on rhtvs2.id_drain=silver_production.id_drain
	where stobstecou ='Validé'  
	and lbusageobs = 'Energie et hydroélectricité' 
	and cdobstecou='ROE52354'
	order by roe_code, distance_riverdrain_dam desc	) as sub	
*/

drop table if exists rht.join_roe_rht;
create table rht.join_roe_rht as (
select 
 distinct on (roe_code)
 row_number() over (order by roe_code) as gid,
 * from (
 
	select cdobstecou as cdobstecou, 
	st_x(st_transform(roe.geom, 4326)) as X,
	st_y(st_transform(roe.geom, 4326)) as Y,
	nomprincip, 
	nomseconda,
	lbtypeouvr,
	cdtypedisp,
	lbtypedisp,
	cdtypedisp1,
	lbtypedi_1,
	cdtypedisp1,
	lbtypedi_2,
	cdtypedisp2,	
	lbtypedi_3,
	cdtypedisp3,	
	lbtypedi_4,
        cdtypedisp4,
	hautchutet,
	nomentiteh,
	cdcommune,
	lbcommune,
	altipointc,
	nomlimiteh,
	"300_450" as number_eel_300_450,
	"450_600" as number_eel_450_600,
	"600_750" as number_eel_600_750,
	"750"  as number_eel_750,
	total as number_eel_total,
	dmer as dmer,
	cumnbbar as "cumulated_number_dams_downstream",
	st_distance(roe.geom, silver_production.geom) as distance_riverdrain_dam,
	rhtvs2.id_drain,
	module,
	roe.geom
	 from roe_v4.roe 
	join rht.silver_production  on st_dwithin(roe.geom, silver_production.geom,1000)
	join rht.rhtvs2 on rhtvs2.id_drain=silver_production.id_drain
	join rht.attributs_rht_fev_2011_vs2 on rhtvs2.id_drain=attributs_rht_fev_2011_vs2.id_drain

	--and altipointc < 100 -- altitude < 100 m
	--and dmer < 250000 -- distance to the sea < 100 km
	--and total > 100	
	and cdobstecou not in ('ROE106058','ROE88566')
	order by roe_code, distance_riverdrain_dam asc
) as sub
) ;--4725
select * from roe_v4.roe  limit 10