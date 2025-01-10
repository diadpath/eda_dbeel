--la table temp_alvinage_shp contient l'ensemble du détail des données d'alvinage
--construite à partir de couches Qgis fournies par Guirec le 07/12

-- france.temp_alvinage_shp definition

-- Drop table

-- DROP TABLE france.temp_alvinage_shp;

/* CREATE TABLE france.temp_alvinage_shp (
	gid serial4 NOT NULL,
	id float8 NULL,
	id_projet float8 NULL,
	projet varchar(254) NULL,
	id_sousprj float8 NULL,
	sousprojet varchar(254) NULL,
	annee float8 NULL,
	qdev_kg varchar(254) NULL,
	nb_civelle float8 NULL,
	point_uniq varchar(254) NULL,
	"x_(wgs84)" numeric NULL,
	"y_(wgs84)" numeric NULL,
	geom public.geometry(point, 3035) NULL,
	idsegment text NULL,
	CONSTRAINT temp_alvinage_shp_pkey PRIMARY KEY (gid),
	CONSTRAINT c_fk_idsegment FOREIGN KEY (idsegment) REFERENCES france.rn(idsegment) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX temp_alvinage_shp_geom_idx ON france.temp_alvinage_shp USING gist (geom);

-- Permissions

ALTER TABLE france.temp_alvinage_shp OWNER TO postgres;
GRANT ALL ON TABLE france.temp_alvinage_shp TO postgres;
 */

--ces couches Qgis sont ensuites transformées en table SQL via script temp_alvinage.sql
--attention : les points sont sur un système de coordonnées wgs84 (4326) alors que l'on travaille en 3035
--il faut bien vérifier que dans la table temp_alvinage_shp, le champs geom est en 3035


--ajout colonne pour recevoir l'idsgement du point d'alvinage
alter table france.temp_alvinage_shp 
add column idsegment text;
alter table france.temp_alvinage_shp
add constraint c_fk_idsegment foreign key (idsegment) references france.rn(idsegment) on update cascade on delete cascade;

--choix du segment le plus proche de l'alvinage (on va rechercher jusqu'à 3km (pour les cas d'alvinage près des Lacs qui ne font pas partie du rht)
with project as (
SELECT tas.gid, rn.idsegment, st_distance(tas.geom,rn.geom) as distance FROM france.temp_alvinage_shp tas 
join france.rn rn on st_dwithin(tas.geom,rn.geom,3000)
order by tas.gid, distance
),
distinct_project as(
select distinct on (gid) * 
from project --projection sur plus proche (grâce à distinct sur order by)
)
update france.temp_alvinage_shp 
set idsegment = distinct_project.idsegment
from distinct_project where distinct_project.gid = temp_alvinage_shp.gid;

--ecrire temp_alvinage_transport_seg_year
--remontée et descente le long des segments choisis
--liste des segments avals, rattachés aux projets et à l'année
drop table if exists france.temp_alvinage_transport_seg_year;
create table france.temp_alvinage_transport_seg_year 
as 
with sub_query as (
select tas.*, rna.distanceseam, 
france.downstream_segments_rn(tas.idsegment) as down_segments
from france.temp_alvinage_shp tas
join france.rna rna on rna.idsegment = tas.idsegment),
sub_query2 as (
select sq.*, 
rna2.distanceseam as dist_down_seg,
(sq.distanceseam - rna2.distanceseam) as dist_aval
from sub_query sq
join france.rna rna2 on rna2.idsegment = sq.down_segments
where ((sq.distanceseam - rna2.distanceseam)<10000 and point_uniq = 'Non') or 
	((sq.distanceseam - rna2.distanceseam)<15000 and point_uniq = 'Oui')
),
--liste des segments amonts, rattachés aux projets et à l'année
sub_query3 as (
select tas.*, rna.distanceseam, 
france.upstream_segments_rn(tas.idsegment) as up_segments
from france.temp_alvinage_shp tas
join france.rna rna on rna.idsegment = tas.idsegment),
sub_query4 as (
select sq.*, 
rna2.distanceseam as dist_up_seg,
(sq.distanceseam - rna2.distanceseam) as dist_amont
from sub_query3 sq
join france.rna rna2 on rna2.idsegment = sq.up_segments
where ((rna2.distanceseam-sq.distanceseam)<10000 and point_uniq = 'Non') or 
	((rna2.distanceseam-sq.distanceseam)<15000 and point_uniq = 'Oui')
),
sub_query_final as (
select distinct down_segments as idsegment,
projet as sector,
annee as "year", r.geom 
from sub_query2--aval
join dbeel_rivers.rn r on r.idsegment = sub_query2.down_segments
union all
select distinct up_segments as idsegment,
projet as sector,
annee as "year", r.geom 
from sub_query4--amont
join dbeel_rivers.rn r on r.idsegment = sub_query4.up_segments--amont
--liste des segments d'alvinage (centraux), rattachés aux projets et à l'année
union all
select distinct tas2.idsegment,
tas2.projet as sector,
tas2.annee as "year", 
r.geom 
from france.temp_alvinage_shp tas2--centre
join dbeel_rivers.rn r on r.idsegment = tas2.idsegment
)
select distinct * from sub_query_final --pour s'assurer qu'au final il n'y a aucun doublon sur idsegement/year/projet


--maintenant sur la table temp_alvinage_transport_seg_year, on va, pour chaque trio segment/année/sector(=projet)
--ajouter des lignes sur les 12 années suivantes (impact estimé des alvinages)
alter table temp_alvinage_transport_seg_year
add column to_loop boolean default true;

--on ajoute des lignes de secteurs sélectionnés manuellement via analyses des résidus et qté anguilles <150mm
INSERT INTO france.temp_alvinage_transport_seg_year (idsegment,sector,year,geom,to_loop) 
--Adour (1996 --> 2020+12), 2 secteurs principaux
SELECT idsegment,
'Adour manuel 2023' as sector,
1996 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR117027'))
union all
SELECT idsegment,
'Adour manuel 2023' as sector,
2008 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR117027'))
union all
SELECT idsegment,
'Adour manuel 2023' as sector,
2020 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR117027'))
union all
SELECT idsegment,
'Adour manuel 2023' as sector,
1996 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR119731'))
union all
SELECT idsegment,
'Adour manuel 2023' as sector,
2008 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR119731'))
union all
SELECT idsegment,
'Adour manuel 2023' as sector,
2020 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR119731'))
--Garonne, dpeuis 1997 (hors rapport Golfech)
union all
SELECT idsegment,
'Garonne manuel 2023' as sector,
1997 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR120584'))
--Dordogne, entre 1998 et 2015 (hors amont du barrage de Tuilières)
union all
SELECT idsegment,
'Dordogne manuel 2023' as sector,
1998 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR106813'))
union all
SELECT idsegment,
'Dordogne manuel 2023' as sector,
2015 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR106813'))
--Loire : Cher, entre 1992 et 2000+12
union all
SELECT idsegment,
'Cher manuel 2023' as sector,
1992 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR222465'))
union all
SELECT idsegment,
'Cher manuel 2023' as sector,
2000 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR222465'))
--Loire : Beuvron, entre 1997 et 2000+12
union all
SELECT idsegment,
'Beuvron manuel 2023' as sector,
1997 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR213324'))
union all
SELECT idsegment,
'Beuvron manuel 2023' as sector,
2000 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR213324'))
--Rhin, cf alvinage Sandoz, 1994 +12 (à 2006)
union all
SELECT idsegment,
'Rhin Sandoz manuel 2023' as sector,
1994 as year, 
geom, 
True as to_loop 
FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR503710'))
--on boucle sur chaque ligne de segment (avec top to-loop = T)
--puis on ajoute 12 années supplémentaires (avec to_loop = F pour ne pas boucler dessus ensuite)
DO $$
DECLARE temprow RECORD;
begin FOR temprow IN
        SELECT * FROM france.temp_alvinage_transport_seg_year tsy
        where tsy.to_loop = true
        order by tsy.sector, tsy.idsegment, tsy.year
    loop
	    for i in 1..12 by 1 loop
			INSERT INTO france.temp_alvinage_transport_seg_year (idsegment,sector,year,geom,to_loop) 
			VALUES (temprow.idsegment,
					temprow.sector,
					temprow.year+i,
					temprow.geom,
					false);
		 end loop;
    END LOOP;
END; $$

--partie du script réservé aux secteurs de transport historique (Sudoang) pour lesquels on va également
--ajouter +12 ans
--on fait tourner la même fonction que ci-dessus, même cette fois ci en se basant sur dbeel_rivers.transport
DO $$
DECLARE temprow RECORD;
begin FOR temprow IN
        SELECT * FROM dbeel_rivers.transport t 
        where t.year is not null
        order by t.sector, t.idsegment, t.year
    loop
	    for i in 1..12 by 1 loop
			INSERT INTO france.temp_alvinage_transport_seg_year (idsegment,sector,year,geom,to_loop) 
			VALUES (temprow.idsegment,
					temprow.sector,
					temprow.year+i,
					temprow.geom,
					false);
		 end loop;
    END LOOP;
END; $$

--ensuite on va supprimer les duplicats dans la table france.temp_alvinage_transport_seg_year
--en priorisant ceux qui ont été topés à to_loop = T (car ce sont les lignes des projets d'alvinage)
--puis on priorise les lignes des projets plus récents 
--(car un alvinage en 2020 a plus de chance d'influencé un secteur les années suivantes, qu'un alvinage au même endroit mais en 2018 par exemple)
with sub_query_row as (
select idsegment, sector, year,
row_number() OVER( PARTITION BY idsegment, year 
ORDER BY  to_loop desc, year desc, sector desc) as nums
FROM france.temp_alvinage_transport_seg_year)
delete from france.temp_alvinage_transport_seg_year 
where (idsegment, sector, year) in (select idsegment, sector, year from sub_query_row where sub_query_row.nums > 1)


--enfin on ajoute toutes les lignes de la table temporaire dans la table dbeel_rivers.transport 
insert into dbeel_rivers.transport(idsegment,sector,year,geom)
select tsy.idsegment , tsy.sector, tsy."year" , tsy.geom 
from france.temp_alvinage_transport_seg_year tsy
--et on supprime les éventuels doublons
with sub_query_row as (
select idsegment, sector, year,
row_number() OVER( PARTITION BY idsegment, year 
ORDER BY  year desc, sector desc) as nums
FROM dbeel_rivers.transport)
delete from dbeel_rivers.transport 
where (idsegment, sector, year) in (select idsegment, sector, year from sub_query_row where sub_query_row.nums > 1)