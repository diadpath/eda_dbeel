/* Un doublon = 
- opération de pêche : même date, même lieu, même quantité pêchée 
- poisson même date, même lieu, même poids, même taille
Attention : il peut y avoir parfois des opérations de pêches qui ont donné lieu a 1 saisie dans RSA puis dans ASPE mais sur des données différentes
Théoriquement dans ASPE, il n'y a que de l'OFB et dans RSA ce sont d'autres partenaires
*/

--#############################################################################################--
-- RECHERCHE DOUBLON SUR STATIONS PROCHES
--#############################################################################################--

-- Etape 1 : Peut on trouver des stations communes entre RSA et ASPE ? (A faire sous R)
-- Faire une table qui fait le lien entre les stations de RSA et ASPE qui se trouvent à moins de 200m (distance à adapter selon les besoins)---
-- cf fichier check_dup_stations_ASPE_RSA.R
-- résultats dans france.stations_dup_aspe_rsa

-- Etape 2/3 : Chercher l'ensemble des opérations de pêches réalisées 
-- conjointement sur des couples de stations de l'étape 1, le même jour 
-- d'intervalle (au cas où la date de l 'opération ne soit pas très précise)

--on remonte les opérations ASPE et RSA dont les stations sont connues dans le fichier de doublonsdrop table if exists france.temp_ope_dup_aspe_rsa;
drop table if exists france.temp_ope_dup_aspe_rsa;
CREATE TABLE france.temp_ope_dup_aspe_rsa
as
with select_ope_aspe as (
select dea.ob_id, dea.sta_id,dea.ob_starting_date,dboa.ba_quantity,tsdar.rsa_sta_id, tsdar.rsa_sta_zone, dea.ef_no_fishingmethod, op.the_geom , op.op_placename  
from france.dbeel_electrofishing_aspe dea 
join france.temp_stations_dup_aspe_rsa tsdar on tsdar.aspe_sta_id = dea.sta_id 
join france.dbeel_batch_ope_aspe dboa on dboa.ba_ob_id = dea.ob_id and dboa.ba_no_biological_characteristic_type =47 --quantité totale
join dbeel.observation_places op on op.op_id::text = dea.ob_op_id::text
),
select_ope_rsa as (
select der.ob_id as rsa_ob_id, 
der.op_sta_id as rsa_sta_id, 
der.op_zone as rsa_sta_zone, 
der.ob_starting_date as rsa_date,
dboa.ba_quantity as rsa_qty,
tsdar.aspe_sta_id as aspe_sta_id,
der.ef_no_fishingmethod as rsa_method,
op2.the_geom as rsa_thegeom,
op2.op_placename as rsa_name
from france.dbeel_electrofishing_rsa der 
join france.temp_stations_dup_aspe_rsa tsdar on (tsdar.rsa_sta_id, tsdar.rsa_sta_zone ) = (der.op_sta_id , der.op_zone )
join france.dbeel_batch_ope_rsa dboa on dboa.ba_ob_id = der.ob_id and dboa.ba_no_biological_characteristic_type =47
join dbeel.observation_places op2 on op2.op_id::text = der.ob_op_id::text 
)
select distinct soa.ob_id as aspe_ob_id,
soa.sta_id as aspe_sta_id,
soa.the_geom as aspe_geom, 
soa.op_placename as aspe_name,
soa.ob_starting_date as aspe_date,
soa.ef_no_fishingmethod as aspe_method,
soa.ba_quantity as aspe_qty,
sor.rsa_ob_id as rsa_ob_id,
sor.rsa_sta_id as rsa_sta_id,
sor.rsa_sta_zone as rsa_zone,
sor.rsa_thegeom as rsa_geom, 
sor.rsa_name as rsa_name,
sor.rsa_date as rsa_date,
sor.rsa_method as rsa_method,
sor.rsa_qty as rsa_qty
from select_ope_aspe soa
--join select_ope_rsa sor on (sor.aspe_sta_id, sor.rsa_date, sor.rsa_qty) = (soa.sta_id, soa.ob_starting_date, soa.ba_quantity)
join select_ope_rsa sor on (sor.aspe_sta_id, sor.rsa_date) = (soa.sta_id, soa.ob_starting_date)
--01/12/23 : 749 opérations de pêches réalisées le même jour au même endroit (quelque soit résultat).

--on remonte maintenant plusieurs champs différents pour comparer ces opérations
alter table france.temp_ope_dup_aspe_rsa
add column what_to_keep varchar(30) default '', --a field to store which data record (ASPE or RSA) should be kept
add column nb_dup_with_ASPE numeric default 1,
add column nb_dup_with_RSA numeric default 1,
add column nb_length_measured_aspe numeric default 0,
add column nb_length_measured_rsa numeric default 0,
add column mean_length_aspe numeric  DEFAULT 0,
add column mean_length_rsa numeric  DEFAULT 0;



update france.temp_ope_dup_aspe_rsa todar
set mean_length_aspe = sub_query.mean_length
from 
(select dbfa.ba_ob_id, ROUND(cast(avg(dmbca.bc_numvalue) as numeric),2) as mean_length
from france.dbeel_batch_fish_aspe dbfa 
join france.dbeel_mensurationindiv_biol_charac_aspe dmbca on dmbca.mei_id = dbfa.mei_id 
where dmbca.bc_no_characteristic_type = 39 -- length
group by (dbfa.ba_ob_id)) as sub_query
where todar.aspe_ob_id::text = sub_query.ba_ob_id::text;

update france.temp_ope_dup_aspe_rsa todar
set mean_length_rsa = sub_query.mean_length
from 
(select dbfr.ba_ob_id, ROUND(cast(avg(dmbcr.bc_numvalue) as numeric),2) as mean_length
from france.dbeel_batch_fish_rsa dbfr
join france.dbeel_mensurationindiv_biol_charac_rsa dmbcr on (dmbcr.ang_id, dmbcr.ang_zone) = (dbfr.ang_id, dbfr.ang_zone)
where dmbcr.bc_no_characteristic_type = 39 -- length
group by (dbfr.ba_ob_id)) as sub_query
where todar.rsa_ob_id::text = sub_query.ba_ob_id::text;


update france.temp_ope_dup_aspe_rsa todar
set nb_length_measured_aspe = sub_query.nb_length
from 
(select dbfa.ba_ob_id, count(dmbca.bc_id) as nb_length
from france.dbeel_batch_fish_aspe dbfa 
join france.dbeel_mensurationindiv_biol_charac_aspe dmbca on dmbca.mei_id = dbfa.mei_id 
where dmbca.bc_no_characteristic_type = 39 -- length
group by (dbfa.ba_ob_id)) as sub_query
where todar.aspe_ob_id::text = sub_query.ba_ob_id::text;

update france.temp_ope_dup_aspe_rsa todar
set nb_length_measured_rsa = sub_query.nb_length
from 
(select dbfr.ba_ob_id, count(dmbcr.bc_id) as nb_length
from france.dbeel_batch_fish_rsa dbfr
join france.dbeel_mensurationindiv_biol_charac_rsa dmbcr on (dmbcr.ang_id, dmbcr.ang_zone) = (dbfr.ang_id, dbfr.ang_zone)
where dmbcr.bc_no_characteristic_type = 39 -- length
group by (dbfr.ba_ob_id)) as sub_query
where todar.rsa_ob_id::text = sub_query.ba_ob_id::text;

--ASPE operations linked with several RSA operations
update france.temp_ope_dup_aspe_rsa todar
set nb_dup_with_ASPE = sub_query.nb_dup
from 
(select todar.aspe_ob_id,count(*) as nb_dup
from france.temp_ope_dup_aspe_rsa todar 
group by (todar.aspe_ob_id)) as sub_query
where todar.aspe_ob_id::text = sub_query.aspe_ob_id::text;

--RSA operations linked with several ASPE operations
update france.temp_ope_dup_aspe_rsa todar
set nb_dup_with_RSA = sub_query.nb_dup
from 
(select todar.rsa_ob_id,count(*) as nb_dup
from france.temp_ope_dup_aspe_rsa todar 
group by (todar.rsa_ob_id)) as sub_query
where todar.rsa_ob_id::text = sub_query.rsa_ob_id::text;

-- what to keep treatment
--1) we set to manual all lines with nb_dup_with_ASPE/RSA >1
update france.temp_ope_dup_aspe_rsa todar
set what_to_keep = 'manual'
where nb_dup_with_RSA > 1 or nb_dup_with_ASPE > 1

--2) when quantity, nb_length_measured and mean_length are equal --> keep ASPE
--		except when fishing method is not equal --> manual
update temp_ope_dup_aspe_rsa todar 
set what_to_keep = 'ASPE'
where nb_dup_with_RSA = 1 and nb_dup_with_ASPE = 1
and mean_length_aspe = mean_length_rsa 
and nb_length_measured_aspe = nb_length_measured_rsa 
and aspe_qty = rsa_qty 
and aspe_method = rsa_method 

update temp_ope_dup_aspe_rsa todar 
set what_to_keep = 'manual'
where nb_dup_with_RSA = 1 and nb_dup_with_ASPE = 1
and mean_length_aspe = mean_length_rsa 
and nb_length_measured_aspe = nb_length_measured_rsa 
and aspe_qty = rsa_qty 
and aspe_method <> rsa_method 

--3) quantité égale mais effectif mesuré différent 
		--> on conserve l'enregistrement dont l'effectif mesuré est le plus proche de la quantité capturée
update temp_ope_dup_aspe_rsa
set what_to_keep = 'ASPE'
where what_to_keep = '' --pour éviter de travailler sur des lignes préalablement traitées
and rsa_qty = aspe_qty 
and nb_length_measured_aspe > nb_length_measured_rsa 

update temp_ope_dup_aspe_rsa
set what_to_keep = 'RSA'
where what_to_keep = '' --pour éviter de travailler sur des lignes préalablement traitées
and rsa_qty = aspe_qty 
and nb_length_measured_aspe < nb_length_measured_rsa 

-- 4) quantité égale, effectif mesuré égal, longueur moyenne différente
	--> si diff <=10mm --> diff minime, on garde ASPE
	--> si diff >10mm --> à traiter manuellement
update temp_ope_dup_aspe_rsa
set what_to_keep = 'ASPE' 
where what_to_keep = '' --pour éviter de travailler sur des lignes préalablement traitées
and rsa_qty = aspe_qty 
and nb_length_measured_aspe = nb_length_measured_rsa 
and mean_length_aspe <> mean_length_rsa 
and abs(mean_length_aspe - mean_length_rsa) <= 10

update temp_ope_dup_aspe_rsa
set what_to_keep = 'manual' 
where what_to_keep = '' --pour éviter de travailler sur des lignes préalablement traitées
and rsa_qty = aspe_qty 
and nb_length_measured_aspe = nb_length_measured_rsa 
and mean_length_aspe <> mean_length_rsa 
and abs(mean_length_aspe - mean_length_rsa) > 10

--vérification : 0 résultat
select * from temp_ope_dup_aspe_rsa todar 
where what_to_keep = '' --pour éviter de travailler sur des lignes préalablement traitées
and rsa_qty = aspe_qty 

update temp_ope_dup_aspe_rsa todar 
set what_to_keep = 'keep_all'
where what_to_keep = '' --pour éviter de travailler sur des lignes préalablement traitées
and rsa_qty <> aspe_qty 

---------------------------------------------------------------------------------
--suppression automatiques des opérations de pêches, mesures, poissons en doublons
--1) cas ou what_to_keep = 'ASPE', on supprime côté RSA
	--suppression des mesures RSA
	delete from france.dbeel_mensurationindiv_biol_charac_rsa dmbcr2
	where dmbcr2.bc_id in (select dmbcr.bc_id from france.dbeel_mensurationindiv_biol_charac_rsa dmbcr 
	join france.dbeel_batch_fish_rsa dbfr on dbfr.ba_id = dmbcr.bc_ba_id 
	join france.dbeel_electrofishing_rsa der on der.ob_id = dbfr.ba_ob_id 
	where dbfr.ba_ob_id in (select todar.rsa_ob_id from france.temp_ope_dup_aspe_rsa todar 
	where what_to_keep = 'ASPE')
	and dmbcr.bc_no_characteristic_type  = 39);
	--suppression des poissons RSA
	delete from france.dbeel_batch_fish_rsa dbfr
	where dbfr.ba_ob_id  in (select todar.rsa_ob_id from france.temp_ope_dup_aspe_rsa todar 
	where what_to_keep = 'ASPE')
	and dbfr.ba_batch_level = 2; --only eels;
	--suppression des batch d'ope RSA
	delete from france.dbeel_batch_ope_rsa dbor
	where dbor.ba_ob_id  in (select todar.rsa_ob_id from france.temp_ope_dup_aspe_rsa todar 
	where what_to_keep = 'ASPE')
	and dbor.ba_batch_level = 1; --only ope;
	--suppression des opérations RSA
	delete from france.dbeel_electrofishing_rsa der
	where der.ob_id in (select todar.rsa_ob_id from france.temp_ope_dup_aspe_rsa todar 
	where what_to_keep = 'ASPE');
--2) cas ou what_to_keep = 'RSA', on supprime côté ASPE
	--suppression des mesures ASPE
	delete from france.dbeel_mensurationindiv_biol_charac_aspe dmbcr2
	where dmbcr2.bc_id in (select dmbcr.bc_id from france.dbeel_mensurationindiv_biol_charac_aspe dmbcr 
	join france.dbeel_batch_fish_aspe dbfr on dbfr.ba_id = dmbcr.bc_ba_id 
	join france.dbeel_electrofishing_aspe der on der.ob_id = dbfr.ba_ob_id 
	where dbfr.ba_ob_id in (select todar.aspe_ob_id from france.temp_ope_dup_aspe_rsa todar 
	where what_to_keep = 'RSA')
	and dmbcr.bc_no_characteristic_type  = 39);
	--suppression des poissons ASPE
	delete from france.dbeel_batch_fish_aspe dbfr
	where dbfr.ba_ob_id  in (select todar.aspe_ob_id from france.temp_ope_dup_aspe_rsa todar 
	where what_to_keep = 'RSA')
	and dbfr.ba_batch_level = 2; --only eels;
	--suppression des batch d'ope ASPE
	delete from france.dbeel_batch_ope_aspe dbor
	where dbor.ba_ob_id  in (select todar.aspe_ob_id from france.temp_ope_dup_aspe_rsa todar 
	where what_to_keep = 'RSA')
	and dbor.ba_batch_level = 1; --only ope;
	--suppression des opérations ASPE
	delete from france.dbeel_electrofishing_aspe der
	where der.ob_id in (select todar.aspe_ob_id from france.temp_ope_dup_aspe_rsa todar 
	where what_to_keep = 'RSA');


--enfin on supprime les tables temporaires
--drop table if exists france.temp_ope_dup_aspe_rsa;
--drop table if exists france.temp_stations_dup_aspe_rsa;
--drop table if exists france.temp_ope_dup_aspe_rsa_fish_level;
--drop table if exists france.stations_dup_aspe_rsa;


--#############################################################################################--
-- RECHERCHE DOUBLON INTRAsources (ASPE ou RSA)
--#############################################################################################--

-- Autre méthode de recherche de doublons; Cette fois-ci on regarde directement dans la table dbeel.batch des résutlats de pêches identiques, 
-- le même jour et au même lieu de pêche (on utilise le nom du lieu de pêche)
-- l'hypohtèse est qu'ici, lors des alimentations de la dbeel, de ASPE ou de RSA : il y a parfois des dump puis des recréations de tables 
-- mais ceux-ci peuvent avoir été exécuté de façon imparfaite cette fois ci ce sont donc des doublons potentiels "intra" source de données 
-- (ASPE vs ASPE ou RSA vs RSA)


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