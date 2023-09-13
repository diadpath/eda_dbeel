/* Un doublon = 
- opération de pêche : même date, même lieu, même quantité pêchée 
- poisson même date, même lieu, même poids, même taille*/
/* Attention : il peut y avoir parfois des opérations de pêches qui ont donné lieu a 1 saisie dans RSA puis dans ASPE mais sur des données différentes
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
--1053 opérations communes trouvées

=======
-- opérations de pêches réalisées sur ces stations ASPE
select dea.ob_starting_date, dea.ope_id ,dboa.ba_quantity  from dbeel_electrofishing_aspe dea 
join stations_dup_aspe_rsa sdar on sdar.aspe_sta_id = dea.sta_id 
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
--98 opérations communes trouvées avec la même quantité de poissons

--on insère ces résultats dans une table temporaire pour pouvoir les étudier par la suite
CREATE TABLE france.temp_ope_dup_aspe_rsa(
id TEXT
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
rsa_qty INTEGER)

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

-- au 12/09 : OK 
-- (attention ces requêtes remontent les effectifs par passage isssus de dbeel_batch_fish alors que la colonne rsa_qty (ou ASPE)
-- remonte l'effectif total (tous passages confondus).

--on remonte maintenant la moyenne des longueurs pour ces couples d'opérations
-- 4673 couples ob_id/numéro de passage dans ASPE ayant des mesures de longueurs
-- 63 coupls quand on rajoute la jointure avec temp_ope_dup_aspe_rsa (qui concerne 98 couples d'opérations)
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
where (al.mean_length-rl.mean_length) <> 0
-- au 12/09 : 10 oopérations ont une différence de moyenne <> 0
-- comment traiter ?

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
where (al.mean_weight-rl.mean_weight) <> 0