/* Un doublon = 
- opération de pêche : même date, même lieu, même quantité pêchée 
- poisson même date, même lieu, même poids, même taille
Attention : il peut y avoir parfois des opérations de pêches qui ont donné lieu a 1 saisie dans RSA puis dans ASPE mais sur des données différentes
Théoriquement dans ASPE, il n'y a que de l'OFB et dans RSA ce sont d'autres partenaires
*/

-- Etape 1 : Peut on trouver des stations communes entre RSA et ASPE ? (A faire sous R)
-- Faire une table qui fait le lien entre les stations de RSA et ASPE qui se trouvent à moins de 200m (distance à adapter selon les besoins)---
-- cf fichier check_dup_stations_ASPE_RSA.R
-- résultats dans france.stations_dup_aspe_rsa

-- Etape 2 : Chercher l'ensemble des opérations de pêches réalisées 
-- conjointement sur des couples de stations de l'étape 1 à 2/3j 
-- d'intervalle (au cas où la date de l 'opération ne soit pas très précise)

--on remonte les opérations ASPE dont la station est connu dans le fichier des duplicats ASPE/RSA
with select_ope_aspe as(
select dea.ob_id,tsdar.aspe_sta_id,dea.ob_starting_date from dbeel_electrofishing_aspe dea 
join temp_stations_dup_aspe_rsa tsdar on tsdar.aspe_sta_id = dea.sta_id ),
--on remonte les opérations RSA dont la station est connu dans le fichier des duplicats ASPE/RSA
select_ope_rsa as(
select der.ob_id,tsdar.rsa_sta_id,tsdar.rsa_sta_zone,der.ob_starting_date  from dbeel_electrofishing_rsa der  
join temp_stations_dup_aspe_rsa tsdar on (tsdar.rsa_sta_id,tsdar.rsa_sta_zone) = (der.op_sta_id,der.op_zone))
select tsd.*,soa.*,sor.* from temp_stations_dup_aspe_rsa tsd
--puis on fait une jointure avec la table des duplicats sur les deux champs stations
join select_ope_aspe soa on soa.aspe_sta_id = tsd.aspe_sta_id 
join select_ope_rsa sor on sor.rsa_sta_id = tsd.rsa_sta_id 
--avec en plus la contrainte de date
where soa.ob_starting_date = sor.ob_starting_date
--25/10/23 : 1039 opérations communes trouvées


-- opérations de pêches réalisées sur ces stations ASPE
select dea.ob_starting_date, dea.ope_id ,dboa.ba_quantity  from dbeel_electrofishing_aspe dea 
join temp_stations_dup_aspe_rsa sdar on sdar.aspe_sta_id = dea.sta_id 
join dbeel_batch_ope_aspe dboa on dboa.ope_id = dea.ope_id
order by dea.ob_starting_date, dea.ope_id 

-- Etape 3 : Comparer les quantités de poissons pêchées et les méthodes utilisées
-- Remonter la liste des couples d'opérations de pêches de l'étape 2
-- dont les quantités pêchées sont égales

-- on refait la même requête qu'en étape 2 mais cette fois-ci on ajoute la jointure avec dbeel_batch_ope_aspe
-- et dbeel_batch_ope_rsa pour obtenir la quantité de poissons pêchés
with select_ope_aspe as(
select dea.ob_id,tsdar.aspe_sta_id,dea.ob_starting_date, dea.ope_id  from dbeel_electrofishing_aspe dea 
join temp_stations_dup_aspe_rsa tsdar on tsdar.aspe_sta_id = dea.sta_id ),
select_ope_rsa as(
select der.ob_id,tsdar.rsa_sta_id,tsdar.rsa_sta_zone,der.ob_starting_date, der.op_id from dbeel_electrofishing_rsa der  
join temp_stations_dup_aspe_rsa tsdar on (tsdar.rsa_sta_id,tsdar.rsa_sta_zone) = (der.op_sta_id,der.op_zone))
select distinct(tsd.aspe_sta_id, tsd.rsa_sta_id, tsd.rsa_sta_zone, soa.ob_id, sor.ob_id) as id,
tsd.aspe_sta_id as aspe_sta_id,
tsd.rsa_sta_id as rsa_sta_id, 
tsd.rsa_sta_zone as rsa_sta_zone,
tsd.dist as sta_dist, 
soa.ob_starting_date as ope_date_debut, 
soa.ob_id as aspe_ob_id,
soa.ope_id as aspe_ope_id,
sor.ob_id as rsa_ob_id,
sor.op_id as rsa_ope_id,
dboa.ba_quantity as aspe_qty,
dbor.ba_quantity as rsa_qty
from temp_stations_dup_aspe_rsa tsd
join select_ope_aspe soa on soa.aspe_sta_id = tsd.aspe_sta_id 
join select_ope_rsa sor on (sor.rsa_sta_id,sor.rsa_sta_zone) = (tsd.rsa_sta_id ,tsd.rsa_sta_zone)
join dbeel_batch_ope_aspe dboa ON dboa.ope_id = soa.ope_id
join dbeel_batch_ope_rsa dbor on (dbor.op_id,dbor.op_zone) = (sor.rsa_sta_id,sor.rsa_sta_zone) 
where soa.ob_starting_date = sor.ob_starting_date and
dboa.ba_no_biological_characteristic_type = 47 and 
dbor.ba_no_biological_characteristic_type = 47 and 
dboa.ba_quantity = dbor.ba_quantity
order by dboa.ba_quantity 
--25/10/23 : 87 opérations communes trouvées avec la même quantité de poissons

--on insère ces résultats dans une table temporaire pour pouvoir les étudier par la suite

drop table if exists france.temp_ope_dup_aspe_rsa;
CREATE TABLE france.temp_ope_dup_aspe_rsa(
id TEXT,
aspe_sta_id INTEGER,
rsa_sta_id INTEGER,
rsa_sta_zone TEXT,
sta_dist  INTEGER,
ope_date_debut DATE,
aspe_ob_id TEXT,
aspe_ope_id INTEGER,
rsa_ob_id TEXT,
rsa_ope_id INTEGER,
aspe_qty INTEGER,
rsa_qty INTEGER);

insert into france.temp_ope_dup_aspe_rsa(
id,
aspe_sta_id,
rsa_sta_id,
rsa_sta_zone,
sta_dist,
ope_date_debut,
aspe_ob_id,
aspe_ope_id,
rsa_ob_id,
rsa_ope_id,
aspe_qty,
rsa_qty)
with select_ope_aspe as(
select dea.ob_id,tsdar.aspe_sta_id,dea.ob_starting_date, dea.ope_id  from dbeel_electrofishing_aspe dea 
join temp_stations_dup_aspe_rsa tsdar on tsdar.aspe_sta_id = dea.sta_id ),
select_ope_rsa as(
select der.ob_id,tsdar.rsa_sta_id,tsdar.rsa_sta_zone,der.ob_starting_date, der.op_id from dbeel_electrofishing_rsa der  
join temp_stations_dup_aspe_rsa tsdar on (tsdar.rsa_sta_id,tsdar.rsa_sta_zone) = (der.op_sta_id,der.op_zone))
select distinct(tsd.aspe_sta_id, tsd.rsa_sta_id, tsd.rsa_sta_zone, soa.ob_id, sor.ob_id) as id,
tsd.aspe_sta_id as aspe_sta_id,
tsd.rsa_sta_id as rsa_sta_id, 
tsd.rsa_sta_zone as rsa_sta_zone,
tsd.dist as sta_dist, 
soa.ob_starting_date as ope_date_debut, 
soa.ob_id as aspe_ob_id,
soa.ope_id as aspe_ope_id,
sor.ob_id as rsa_ob_id,
sor.op_id as rsa_ope_id,
dboa.ba_quantity as aspe_qty,
dbor.ba_quantity as rsa_qty
from temp_stations_dup_aspe_rsa tsd
join select_ope_aspe soa on soa.aspe_sta_id = tsd.aspe_sta_id 
join select_ope_rsa sor on (sor.rsa_sta_id,sor.rsa_sta_zone) = (tsd.rsa_sta_id ,tsd.rsa_sta_zone)
join dbeel_batch_ope_aspe dboa ON dboa.ope_id = soa.ope_id
join dbeel_batch_ope_rsa dbor on (dbor.op_id,dbor.op_zone) = (sor.rsa_sta_id,sor.rsa_sta_zone) 
where soa.ob_starting_date = sor.ob_starting_date and
dboa.ba_no_biological_characteristic_type = 47 and 
dbor.ba_no_biological_characteristic_type = 47 and 
dboa.ba_quantity = dbor.ba_quantity
order by dboa.ba_quantity 


-- Etape 4 : Chercher l'ensemble des poissons de même tailles et/ou poids
-- issus d'une pêche le même jour et dans un couple de station existant à l'étape 1

--on vérifie dans un premier temps que les effectifs de dbeel_batch_fish et temp_ope_dup_aspe_rsa sont équivalents à la fois pour ASPE et RSA
select dbfa.ba_ob_id as aspe_ob_id, 
dbfa.ba_no_biological_characteristic_type as num_p, 
sum(dbfa.ba_quantity) as quantity,
todar.rsa_ob_id as rsa_ob_id from france.dbeel_batch_fish_aspe dbfa 
join france.temp_ope_dup_aspe_rsa todar on todar.aspe_ob_id = cast(dbfa.ba_ob_id as text)
group by dbfa.ba_ob_id, todar.rsa_ob_id, dbfa.ba_no_biological_characteristic_type 
order by dbfa.ba_ob_id, dbfa.ba_no_biological_characteristic_type


select dbfr.ba_ob_id as rsa_ob_id, 
dbfr.ba_no_biological_characteristic_type  as num_p, 
sum(dbfr.ba_quantity) as quantity,
todar.aspe_ob_id as aspe_ob_id,
todar.rsa_qty from france.dbeel_batch_fish_rsa dbfr 
join france.temp_ope_dup_aspe_rsa todar on todar.rsa_ob_id = cast(dbfr.ba_ob_id as text)
group by dbfr.ba_ob_id, todar.aspe_ob_id, dbfr.ba_no_biological_characteristic_type ,todar.rsa_qty 
order by dbfr.ba_ob_id, dbfr.ba_no_biological_characteristic_type


-- au 02/10 : OK
-- (attention ces requêtes remontent les effectifs par passage isssus de dbeel_batch_fish alors que la colonne rsa_qty (ou ASPE)
-- remonte l'effectif total (tous passages confondus). 

--on remonte maintenant la moyenne des longueurs pour ces couples d'opérations
-- 4673 couples ob_id/numéro de passage dans ASPE ayant des mesures de longueurs
-- 63 coupls quand on rajoute la jointure avec temp_ope_dup_aspe_rsa (qui concerne 98 couples d'opérations)
drop table if exists france.temp_ope_dup_aspe_rsa_fish_level;

create table france.temp_ope_dup_aspe_rsa_fish_level
as
with aspe_listing as (
select dbfa.ba_ob_id as aspe_ob_id, 
dbfa.ba_no_biological_characteristic_type as num_p, 
sum(dbfa.ba_quantity) as quantity,
todar.rsa_ob_id as rsa_ob_id,
ROUND(cast(avg(dmbca.bc_numvalue) as numeric),2) as mean_length
from france.dbeel_batch_fish_aspe dbfa 
join france.temp_ope_dup_aspe_rsa todar on todar.aspe_ob_id = cast(dbfa.ba_ob_id as text)
join france.dbeel_mensurationindiv_biol_charac_aspe dmbca on dmbca.mei_id = dbfa.mei_id
where dmbca.bc_no_characteristic_type = 39 -- length
group by dbfa.ba_ob_id, todar.rsa_ob_id, dbfa.ba_no_biological_characteristic_type ),
rsa_listing as (select dbfr.ba_ob_id as rsa_ob_id, 
dbfr.ba_no_biological_characteristic_type  as num_p, 
sum(dbfr.ba_quantity) as quantity,
todar.aspe_ob_id as aspe_ob_id,
ROUND(cast(avg(dmbcr.bc_numvalue) as numeric),2) as mean_length
from france.dbeel_batch_fish_rsa dbfr
join france.temp_ope_dup_aspe_rsa todar on todar.rsa_ob_id = cast(dbfr.ba_ob_id as text)
join france.dbeel_mensurationindiv_biol_charac_rsa dmbcr on (dmbcr.ang_id,dmbcr.ang_zone)=(dbfr.ang_id,dbfr.ang_zone) 
where dmbcr.bc_no_characteristic_type = 39 -- length
group by dbfr.ba_ob_id, todar.aspe_ob_id, dbfr.ba_no_biological_characteristic_type)
select al.aspe_ob_id,
al.rsa_ob_id,
al.quantity as aspe_quantity,
rl.quantity as rsa_quantity,
al.mean_length as aspe_mean_length,
rl.mean_length as rsa_mean_length,
(al.mean_length-rl.mean_length) as aspe_rsa_diff
from aspe_listing al
join rsa_listing rl on (cast(rl.rsa_ob_id as text),rl.num_p) = (cast(al.rsa_ob_id as text),al.num_p)
--where (al.mean_length-rl.mean_length) <> 0

-- même chose pour les poids 
-- cette requête ne renvoie aucune résultat car (voir ci-dessous)
--3157 lignes d'ob_id/numero passage dans RSA avec mesure de poids
--quand on rajoute la jointure avec temp_ope_dup_aspe_rsa, il ne reste plus que 2 couples ob_id/numero passage 
-- ob_id (dans RSA): 31b8edf8-031f-43ca-b03d-43c6d915f9fb, ob_id dans ASPE :  '44d02070-26a1-442a-b11e-f1e267ebf13f'
--on vérifie que pour l'opération ASPE '44d02070-26a1-442a-b11e-f1e267ebf13f', il n'y a aucune mesure de poids dans dbeel_mensurationindiv_biol_charac_aspe
/*select dmbca.* from dbeel_batch_fish_aspe dbfa 
join dbeel_mensurationindiv_biol_charac_aspe dmbca on dmbca.mei_id = dbfa.mei_id 
where dbfa.ba_ob_id = '44d02070-26a1-442a-b11e-f1e267ebf13f'*/


with aspe_listing as(
select dbfa.ba_ob_id as aspe_ob_id, 
dbfa.ba_no_biological_characteristic_type as num_p, 
sum(dbfa.ba_quantity) as quantity,
todar.rsa_ob_id as rsa_ob_id,
ROUND(cast(avg(dmbca.bc_numvalue) as numeric),2) as mean_weight
from france.dbeel_batch_fish_aspe dbfa 
join france.temp_ope_dup_aspe_rsa todar on todar.aspe_ob_id = cast(dbfa.ba_ob_id as text)
join france.dbeel_mensurationindiv_biol_charac_aspe dmbca on dmbca.mei_id = dbfa.mei_id
where dmbca.bc_no_characteristic_type = 42 -- weight
group by dbfa.ba_ob_id, todar.rsa_ob_id, dbfa.ba_no_biological_characteristic_type ),
rsa_listing as (select dbfr.ba_ob_id as rsa_ob_id, 
dbfr.ba_no_biological_characteristic_type  as num_p, 
sum(dbfr.ba_quantity) as quantity,
todar.aspe_ob_id as aspe_ob_id,
ROUND(cast(avg(dmbcr.bc_numvalue) as numeric),2) as mean_weight
from france.dbeel_batch_fish_rsa dbfr
join france.temp_ope_dup_aspe_rsa todar on todar.rsa_ob_id = cast(dbfr.ba_ob_id as text)
join france.dbeel_mensurationindiv_biol_charac_rsa dmbcr on (dmbcr.ang_id,dmbcr.ang_zone)=(dbfr.ang_id,dbfr.ang_zone) 
where dmbcr.bc_no_characteristic_type = 42 -- weight
group by dbfr.ba_ob_id, todar.aspe_ob_id, dbfr.ba_no_biological_characteristic_type)
select al.aspe_ob_id,
al.rsa_ob_id,
al.quantity as aspe_quantity,
rl.quantity as rsa_quantity,
al.mean_weight as aspe_mean_weight,
rl.mean_weight as rsa_mean_weight,
(al.mean_weight-rl.mean_weight) as aspe_rsa_diff
from aspe_listing al
join rsa_listing rl on (cast(rl.rsa_ob_id as text),rl.num_p) = (cast(al.rsa_ob_id as text),al.num_p)
where (al.mean_weight-rl.mean_weight) <> 0;


--on conserve donc les opérations saisies dans ASPE.
--on va updater (avec l'option cascade) les tables 
--france.dbeel_mensurationindiv_biol_charac_rsa, --mesure sur les poissons pêchés 
delete from france.dbeel_mensurationindiv_biol_charac_rsa bcr2
	where bcr2.bc_id in (select bcr.bc_id from france.dbeel_mensurationindiv_biol_charac_rsa bcr
	join france.dbeel_batch_fish_rsa dbfr on bcr.bc_ba_id = dbfr.ba_id and dbfr.ba_ob_id::text in 
	(select rfl.rsa_ob_id from france.temp_ope_dup_aspe_rsa_fish_level rfl))
--france.dbeel_batch_fish_rsa, --liste des poissons 
delete from france.dbeel_batch_fish_rsa bfr2
	where bfr2.ba_ob_id::text in (select rfl.rsa_ob_id from france.temp_ope_dup_aspe_rsa_fish_level rfl)
--france.dbeel_batch_ope_rsa, --liste des résultats d'opérations de pêches
delete from france.dbeel_batch_ope_rsa bor
	where bor.ba_ob_id::text in (select rfl.rsa_ob_id from france.temp_ope_dup_aspe_rsa_fish_level rfl)
--france.dbeel_electrofishing_rsa, liste des opérations de pêches  
delete from france.dbeel_electrofishing_rsa er
	where er.ob_id::text in (select rfl.rsa_ob_id from france.temp_ope_dup_aspe_rsa_fish_level rfl)

--enfin on supprime les tables temporaires
drop table if exists france.temp_ope_dup_aspe_rsa;
drop table if exists france.temp_stations_dup_aspe_rsa;
drop table if exists france.temp_ope_dup_aspe_rsa_fish_level;
drop table if exists france.stations_dup_aspe_rsa;

-- Etape 5 : Autre méthode de recherche de doublons; Cette fois-ci on regarde directement dans la table dbeel.batch des résutlats de pêches identiques, le même jour et au même lieu de pêche 
-- (on utilise le nom du lieu de pêche)
-- l'hypohtèse est qu'ici, lors des alimentations de la dbeel, de ASPE ou de RSA : il y a parfois des dump puis des recréations de tables mais ceux-ci peuvent avoir été exécuté de façon imparfaite
-- cette fois ci ce sont donc des doublons potentiels "intra" source de données (ASPE vs ASPE ou RSA vs RSA)


-- check dans electrofishing
-- des doublons d'opérations de pêches avec les m^mes caractéristiques ?
-- pourraient être issus de DELETE qui se sont mal passés...
select count(*),--nobre de fois ou apparaît ce résultat de pêche dans la table dbeel.batch
e.ob_no_origin,e.ob_no_type, e.ob_no_period,
e.ob_starting_date,e.ef_no_fishingmethod,
e.ef_no_electrofishing_mean,e.ef_wetted_area,e.ef_fished_length,
e.ef_fished_width,e.ef_duration,e.ef_nbpas, op.op_placename, op_gis_layername
from dbeel.electrofishing e 
join dbeel.observation_places op on op.op_id = e.ob_op_id 
join dbeel.batch b on b.ba_ob_id = e.ob_id 
where op.op_gis_layername in ('ASPE','RSA')
and b.ba_batch_level = 1
and b.ba_no_biological_characteristic_type = 47 -- uniquement les totaux
group by (e.ob_no_origin,e.ob_no_type, e.ob_no_period,
e.ob_starting_date,e.ef_no_fishingmethod,
e.ef_no_electrofishing_mean,e.ef_wetted_area,e.ef_fished_length,
e.ef_fished_width,e.ef_duration,e.ef_nbpas,op.op_placename,op.op_gis_layername,b.ba_quantity)--pêche le même jour au même endroit avec le même résultat de pêche totale
having count(*) > 1

-- 38 opérations de pêches qui sont présentent en double en PROD le 29/09/2023
-- depuis RSA il y a des opérations de pêches réalisées le même jour sur le même site (type iaa par exemple, est-ce normal; exemple : op_zone = 'lcvlogrami' et op_id = 90 à 94)
-- depuis ASPE il semble y avoir de vrais doublons (exemple ob_id : 'da46be9a-b9a6-4a48-86c3-46ff71edaaf9','8ea9154e-a868-4522-97ad-0d86aa72b281'
--													ou :'bb04054a-48c0-415a-8efb-e638092aab14','2154f5f0-ed13-4c4d-9a77-e829480ef984' ) dans les deux cas il semble qu'il y ait effectivement des doublons dans ASPE

--autre façon de faire
--1)on crée d'abord une table temporaire pour récupérer toutes les caractéristiques d'oprations de pêches qui apparaissent plusieurs fois dans la base
--ayant été exécutée le même jour au même endroit avec le même nombre de passage et le même résultat de pêche.
--on stocke le résultat de cette requête pour plus de simplicité
--on va créer un champs "id-unique" qui sera simplement la concaténation des champs


drop table if exists france.temp_duplicates_intra_source;


create table france.temp_duplicates_intra_source
as --une requête ici qui construit un id à partir de champs issus de electrofishing et batch
select ROW_NUMBER() OVER (ORDER BY 1) as id,concat_ws('_',e.ob_no_origin,
e.ob_no_type, 
e.ob_no_period,
e.ob_starting_date,
e.ef_no_fishingmethod,
e.ef_no_electrofishing_mean,
e.ef_wetted_area,
e.ef_fished_length,
e.ef_fished_width,
e.ef_duration,
e.ef_nbpas, 
op.op_placename,
op.op_gis_layername,
b.ba_quantity) as id_concat
from dbeel.electrofishing e 
join dbeel.observation_places op on op.op_id = e.ob_op_id 
join dbeel.batch b on b.ba_ob_id = e.ob_id 
where op.op_gis_layername in ('ASPE','RSA')
and b.ba_batch_level = 1
and b.ba_no_biological_characteristic_type = 47
group by concat_ws('_',e.ob_no_origin,
e.ob_no_type, 
e.ob_no_period,
e.ob_starting_date,
e.ef_no_fishingmethod,
e.ef_no_electrofishing_mean,
e.ef_wetted_area,
e.ef_fished_length,
e.ef_fished_width,
e.ef_duration,
e.ef_nbpas, 
op.op_placename,
op.op_gis_layername,
b.ba_quantity)
having count(concat_ws('_',e.ob_no_origin,
e.ob_no_type, 
e.ob_no_period,
e.ob_starting_date,
e.ef_no_fishingmethod,
e.ef_no_electrofishing_mean,
e.ef_wetted_area,
e.ef_fished_length,
e.ef_fished_width,
e.ef_duration,
e.ef_nbpas, 
op.op_placename,
op.op_gis_layername,
b.ba_quantity))>1;



-- 2) on récupère maintent la liste des ob_id concernés 
-- + le champs id (de la table temp) pour les regrouper.
-- on remonte également l'ensemble des lignes issues de dbeel.batch pour avoir une vision exhaustive
-- des lignes enregistrées en base (opération + poissons)
drop table if exists france.temp_duplicates_intra_source_2; 

create table france.temp_duplicates_intra_source_2
as 
select tdis.id,e.ob_id
from dbeel.electrofishing e
join dbeel.batch b on b.ba_ob_id = e.ob_id 
join dbeel.observation_places op on op.op_id = e.ob_op_id 
join france.temp_duplicates_intra_source tdis on tdis.id_concat = concat_ws('_',e.ob_no_origin,
e.ob_no_type, 
e.ob_no_period,
e.ob_starting_date,
e.ef_no_fishingmethod,
e.ef_no_electrofishing_mean,
e.ef_wetted_area,
e.ef_fished_length,
e.ef_fished_width,
e.ef_duration,
e.ef_nbpas, 
op.op_placename,
op.op_gis_layername,
b.ba_quantity)
where b.ba_batch_level = 1
and b.ba_no_biological_characteristic_type = 47
order by tdis.id, e.ob_id, b.ba_ba_id;

drop table if exists france.temp_duplicates_intra_source; 

--3) et on remonte maintenant le détail des résultats de pêches 
-- on va vérifier qu'il y a bien le même nombre de poissons sauvegardés et que leur taille moyenne est équivalente
drop table if exists france.temp_duplicates_intra_source; 

create table france.temp_duplicates_intra_source
as
select tdis.id, b.ba_ob_id, b.ba_batch_level,
count(*)--count of fishes or pass
from dbeel.batch b 
join france.temp_duplicates_intra_source_2 tdis on tdis.ob_id = b.ba_ob_id 
group by (tdis.id, b.ba_ob_id, b.ba_batch_level)--groupés par duplicat + numéro d'opérations de pêches
order by tdis.id, b.ba_batch_level,b.ba_ob_id ;

drop table if exists france.temp_duplicates_intra_source_2; 

alter table france.temp_duplicates_intra_source
add mean_length float4;

with pre_query as (
  -- Any generic query which returns rowid and corresponding calculated values
  select tds.id, b.ba_ob_id, avg(bc.bc_numvalue) as mean_lgt
  from dbeel.batch b 
  join france.temp_duplicates_intra_source tds on tds.ba_ob_id = b.ba_ob_id 
  join dbeel.biological_characteristic bc on bc.bc_ba_id = b.ba_id 
  where b.ba_batch_level = 2 --only fishes
  and bc.bc_no_characteristic_type = 39 --longueur
  group by  (tds.id,b.ba_ob_id )
)
update france.temp_duplicates_intra_source tdis
set mean_length = pre_query.mean_lgt
from pre_query
where tdis.id = pre_query.id
and tdis.ba_ob_id = pre_query.ba_ob_id
and tdis.ba_batch_level = 2;

--Check OPE RSA
--select tdis.*,dsr.sta_zone  from france.temp_duplicates_intra_source tdis 
--join dbeel.electrofishing e on e.ob_id = tdis.ba_ob_id
--join dbeel.observation_places op on op.op_id = e.ob_op_id 
--join france.dbeel_station_rsa dsr on dsr.op_id = op.op_id 
--where op.op_gis_layername = 'RSA'
--order by tdis.id, tdis.ba_batch_level 
--pour la liste des op RSA, il ne reste plus que des opérations en Ndie qui ne sont pas des doublons (cf action de G. André le 05/10).

--Check OPE ASPE
select tdis.*,dboa.ope_id,oa.sta_code_sandre  from france.temp_duplicates_intra_source tdis 
join dbeel.electrofishing e on e.ob_id = tdis.ba_ob_id
join dbeel.observation_places op on op.op_id = e.ob_op_id 
join france.dbeel_batch_ope_aspe dboa on dboa.ba_ob_id = e.ob_id 
join france.operation_aspe oa on oa.ope_id = dboa.ope_id 
where op.op_gis_layername = 'ASPE'
order by tdis.id, tdis.ba_batch_level 
--pour la liste des op ASPE, cf action de Eddy COSSON au 13/10, les opérations ASPE à supprimer sont les ope_id (issus de ASPE):
--2668,4413,9753,10527,83135,89356


--on va updater la table des doublons
--on ajoute un champs ope_id (issu de ASPE) pour plus de comidités
alter table france.temp_duplicates_intra_source 
add column ope_id int4;
--on va ensuite chercher l'id ASPE
with pre_query as (
select distinct ba_ob_id,ope_id from 
france.dbeel_batch_ope_aspe dboa 
where dboa.ope_id in (2668,4413,9753,10527,83135,89356)
)
update france.temp_duplicates_intra_source tdis
set ope_id = pre_query.ope_id 
from pre_query
where tdis.ba_ob_id = pre_query.ba_ob_id

--france.dbeel_mensurationindiv_biol_charac_aspe, --mesure sur les poissons pêchés 
delete from france.dbeel_mensurationindiv_biol_charac_aspe bcr2
	where bcr2.bc_id in (select bcr.bc_id from france.dbeel_mensurationindiv_biol_charac_aspe bcr
	join france.dbeel_batch_fish_aspe dbfr on bcr.bc_ba_id = dbfr.ba_id and dbfr.ba_ob_id::text in 
		(select tdis.ba_ob_id::text from france.temp_duplicates_intra_source tdis where tdis.ope_id in (2668,4413,9753,10527,83135,89356)))
--france.dbeel_batch_fish_aspe, --liste des poissons 
delete from france.dbeel_batch_fish_aspe bfr2
	where bfr2.ba_ob_id::text in (select tdis.ba_ob_id::text from france.temp_duplicates_intra_source tdis where tdis.ope_id in (2668,4413,9753,10527,83135,89356))
--france.dbeel_batch_ope_rsa, --liste des résultats d'opérations de pêches
delete from france.dbeel_batch_ope_aspe bor
	where bor.ba_ob_id::text in (select tdis.ba_ob_id::text from france.temp_duplicates_intra_source tdis where tdis.ope_id in (2668,4413,9753,10527,83135,89356))
--france.dbeel_electrofishing_rsa, liste des opérations de pêches  
delete from france.dbeel_electrofishing_aspe er
	where er.ob_id::text in (select tdis.ba_ob_id::text from france.temp_duplicates_intra_source tdis where tdis.ope_id in (2668,4413,9753,10527,83135,89356))
	
drop table if exists france.temp_duplicates_intra_source;