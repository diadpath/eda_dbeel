/*
op_cd_objectifpeche	
op_cd_methodeprospection	
op_cd_moyenprospection
op_numero 
annee	*
op_datedebut *
op_listeespecescibles
op_longueur *
op_longprospdroit
op_longprospgauche
op_longsdt 
op_largprospdroit
op_largprospgauche
op_cs_largeurlitmineur
op_nbrpassage *
op_nbrsondage *
op_nbrzones
op_tempspeche
op_cd_typinventaire
op_cd_typzone
op_cs_profmoyen
op_cs_largeurlameeau *
op_largsdt
op_surfaceechantillon
st_id
st_penteign
st_sbv
st_distancemer
st_altitude
st_codecsp
st_distancesource
st_lieudit
st_abcisse
st_ordonnee
ta_code
ot_effectif
ot_effectifestim
ot_efficacite
ot_estestime
pa_effectif
150
150_300
300_450
450_600
600_750
750_900
900
nbtotalclasstail
test_oteff_ct
test_lotG
cd_libl.x	moyenprospection	cd_libl.y	methodeprospection	cd_libl.x.1	moyenprospection.1	cd_libl.y.1	methodeprospection.1	cd_libl	effort
*/
drop view if exists rsa.view_electrofishing;
create view rsa.view_electrofishing as(
with subope as (
select inv_op_id as op_id,
  inv_zone as op_zone,
  inv_long as op_longueur, 
  inv_larg as op_cs_largeurlameeau, 
  inv_npas as op_nbrpassage, 
  inv_p1 as nbp1, -- je reprends les libelles de EDA_CCM dbeel pour adapter le script
  inv_p2 as nbp2, 
  inv_p3 as nbp3,
  coalesce(inv_p1,0)+coalesce(inv_p2,0)+coalesce(inv_p3,0) as totalnumber,
  cast(NULL as integer) as vue,
  cast(NULL as integer) as op_nbrsondage
  from rsa.op_inv
UNION  
select epab_op_id as op_id,
  epab_zone as op_zone,
  NULL as op_longueur,
  NULL as op_cs_largeurlameeau, 
  NULL as op_nbrpassage, 
  NULL as nbp1,
  NULL as nbp2, 
  NULL as nbp3,
  epab_ang as totalnumber,  
  epab_vue as vue,
  epab_npnt as op_nbrsondage
  from rsa.op_epab
UNION  
select epap_op_id as op_id,
  epap_zone as op_zone,
  NULL as op_longueur,
  NULL as op_cs_largeurlameeau, 
  NULL as op_nbrpassage, 
  NULL as nbp1,
  NULL as nbp2, 
  NULL as nbp3,
  epap_ang as totalnumber,  
  epap_vue as vue,
  epap_npnt as op_nbrsondage
  from rsa.op_epap 
UNION 
select pcbgb_op_id as op_id,
  pcbgb_zone as op_zone,
  pcbgb_long as op_longueur, 
  pcbgb_larg as op_cs_largeurlameeau, 
  pcbgb_npas as op_nbrpassage, 
  pcbgb_p1 as nbp1, 
  pcbgb_p2 as nbp2, 
  pcbgb_p3 as nbp3,
  coalesce(pcbgb_p1,0)+coalesce(pcbgb_p2,0)+coalesce(pcbgb_p3,0) as totalnumber,
  NULL as vue,
  NULL as op_nbrsondage
  from rsa.op_pcbgb
UNION 
select pcbgp_op_id as op_id,
  pcbgp_zone as op_zone,
  pcbgp_long as op_longueur, 
  pcbgp_larg as op_cs_largeurlameeau, 
  pcbgp_npas as op_nbrpassage, 
  pcbgp_p1 as nbp1, 
  pcbgp_p2 as nbp2, 
  pcbgp_p3 as nbp3,
  coalesce(pcbgp_p1,0)+coalesce(pcbgp_p2,0)+coalesce(pcbgp_p3,0) as totalnumber,
  NULL as vue,
  NULL as op_nbrsondage
  from rsa.op_pcbgp
UNION 
select iaa_op_id as op_id,
  iaa_zone as op_zone,
  NULL as op_longueur, 
  NULL as op_cs_largeurlameeau, 
  1 as op_nbrpassage, 
  iaa_ang as nbp1, 
  NULL as nbp2, 
  NULL as nbp3,
  iaa_ang as totalnumber,
  iaa_vue as vue,
  iaa_npnt as op_nbrsondage
  from rsa.op_iaa) 
select station.sta_id,
station.sta_lib,
station.sta_zone,
st_x(st_transform(station.geom,3035))as sta_x,
st_y(st_transform(station.geom,3035)) as sta_y,
extract(year from op_date) as annee,
op_date as ope_datedebut,
case when op_typ= 'epap' then 'EPA' --848
	when op_typ='epab' then 'EPA' --848
	when op_typ='iaa' then 'indice abondance anguille'
	when op_typ='inv' then 'complète' --843
	when op_typ='pcbgb' then 'partielle sur berges' --845
	when op_typ='pcbgp' then 'partielle sur berges' -- 845 
	else NULL end as methodeprospection,
case when op_typ= 'epap' then 'A pied' 
	when op_typ='epab' then 'En bateau'  
	when op_typ='iaa' then 'A pied'
	when op_typ='inv' then 'A pied' 
	when op_typ='pcbgb' then 'En bateau' 
	when op_typ='pcbgp' then 'A pied'  
	else NULL end as moyenprospection,
op_cod as op_numero,
subope.op_longueur,
subope.op_cs_largeurlameeau, 
subope.op_nbrpassage, 
subope.nbp1,
subope.nbp2, 
subope.nbp3,
subope.totalnumber,  
subope.vue,
subope.op_nbrsondage
 from rsa.station 
	join rsa.operation on (op_sta_id,op_zone)=(sta_id,sta_zone)
	join subope ON (subope.op_id,subope.op_zone)=(operation.op_id,operation.op_zone))