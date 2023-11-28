
--ASPE
select oa.ope_id,
dea.ob_id, 
oa.op_typ,
dea.ef_no_fishingmethod,
som.no_name,
oa.nb_point,
ope_surface_calculee,
odp_longueur,
odp_largeur_lame_eau,
dea.ef_wetted_area, 
  CASE WHEN dea.ef_no_fishingmethod = 301 THEN oa.nb_point *12.5 --Deep habitat (partielle par points, ambiances)
        WHEN dea.ef_no_fishingmethod = 302 THEN odp_longueur * odp_largeur_lame_eau -- whole eel
        WHEN dea.ef_no_fishingmethod = 303 THEN oa.nb_point *12.5 --iaa
        WHEN dea.ef_no_fishingmethod = 62 THEN odp_longueur * odp_largeur_lame_eau --whole
        WHEN dea.ef_no_fishingmethod = 63 THEN odp_longueur * 4 --berge
        ELSE NULL -- Unknown 
        END AS actual_area
from operation_aspe oa 
join france.dbeel_electrofishing_aspe dea on dea.ope_id = oa.ope_id 
join dbeel_nomenclature.scientific_observation_method som on som.no_id  = dea.ef_no_fishingmethod 


--ASPE
select dea.ef_no_fishingmethod,som.no_name, 
count(dea.ob_id) as nb_ope,
sum(case when dea.ef_wetted_area is null then 1 else 0 end) as nb_without_area,
sum(case when dea.ef_wetted_area > 0 then 1 else 0 end) as nb_area_sup0,
sum(case when oa.nb_point is null then 1 else 0 end) as nb_without_nb_pts,
sum(case when oa.nb_point > 0 then 1 else 0 end) as nb_nb_pts_sup0,
sum(case when (dea.ef_fished_length is null or dea.ef_fished_length=0) then 1 else 0 end) as nb_without_length,
sum(case when (dea.ef_fished_width is null or dea.ef_fished_width=0) is null then 1 else 0 end) as nb_without_width
from france.dbeel_electrofishing_aspe dea 
join france.operation_aspe oa on oa.ope_id = dea.ope_id 
join dbeel_nomenclature.scientific_observation_method som on som.no_id = dea.ef_no_fishingmethod 
group by dea.ef_no_fishingmethod,som.no_name 
order by dea.ef_no_fishingmethod


--RSA
--inventaire à n passages
SELECT 
ope.op_id ,
ope.op_zone, 
dea.ob_id, 
ope.op_typ, 
dea.ef_no_fishingmethod,
som.no_name,
null as nb_points,--nb_points
null as surf_calc,--surface_calculée
opi.inv_long as ope_long,
opi.inv_larg as ope_larg,
dea.ef_wetted_area, 
opi.inv_long * opi.inv_larg AS actual_area --whole
from rsa.operation ope 
  JOIN rsa.op_inv  opi ON (opi.inv_op_id, opi.inv_zone)= (ope.op_id, ope.op_zone)
  join france.dbeel_electrofishing_rsa dea on (dea.op_id,dea.op_zone  ) = (ope.op_id, ope.op_zone)
join dbeel_nomenclature.scientific_observation_method som on som.no_id  = dea.ef_no_fishingmethod 
union all 
--iaa à pieds
SELECT 
ope.op_id ,
ope.op_zone, 
dea.ob_id, 
ope.op_typ, 
dea.ef_no_fishingmethod,
som.no_name,
opiaa.iaa_npnt as nb_points,--nb_points
null as surf_calc,--surface_calculée
null as ope_long,
null as ope_larg,
dea.ef_wetted_area, 
opiaa.iaa_npnt * 12.5 AS actual_area--iaa
from rsa.operation ope 
  JOIN rsa.op_iaa  opiaa ON (opiaa.iaa_op_id, opiaa.iaa_zone)= (ope.op_id, ope.op_zone)
  join france.dbeel_electrofishing_rsa dea on (dea.op_id,dea.op_zone  ) = (ope.op_id, ope.op_zone)
join dbeel_nomenclature.scientific_observation_method som on som.no_id  = dea.ef_no_fishingmethod 
union all 
--echantillonage pontctuel d'abondance, pêche par points (en bateau ?)
SELECT 
ope.op_id ,
ope.op_zone, 
dea.ob_id, 
ope.op_typ, 
dea.ef_no_fishingmethod,
som.no_name,
opb.epab_npnt  as nb_points,--nb_points
null as surf_calc,--surface_calculée
null as ope_long,
null as ope_larg,
dea.ef_wetted_area, 
opb.epab_npnt  * 12.5 AS actual_area--deep habitat
from rsa.operation ope 
  JOIN rsa.op_epab  opb ON (opb.epab_op_id  , opb.epab_zone)= (ope.op_id, ope.op_zone)
  join france.dbeel_electrofishing_rsa dea on (dea.op_id,dea.op_zone  ) = (ope.op_id, ope.op_zone)
join dbeel_nomenclature.scientific_observation_method som on som.no_id  = dea.ef_no_fishingmethod 
union all 
-- Pêche en continue des berge (en bateau ?)
SELECT 
ope.op_id ,
ope.op_zone, 
dea.ob_id, 
ope.op_typ, 
dea.ef_no_fishingmethod,--302 en base, devrait être 63 (comme dans ASPE) ou 64.
som.no_name,
null  as nb_points,--nb_points
null as surf_calc,--surface_calculée
opbgb.pcbgb_long  as ope_long,
opbgb.pcbgb_larg  as ope_larg,
dea.ef_wetted_area, 
opbgb.pcbgb_long * 4 AS actual_area--car pêche berge, mais enregsitré comme 302 dans dbeel --> KO ! devrait être 64. car 302 est considéré comme pêche complète.
from rsa.operation ope 
  JOIN rsa.op_pcbgb opbgb ON (opbgb.pcbgb_op_id  , opbgb.pcbgb_zone)= (ope.op_id, ope.op_zone)
  join france.dbeel_electrofishing_rsa dea on (dea.op_id,dea.op_zone  ) = (ope.op_id, ope.op_zone)
join dbeel_nomenclature.scientific_observation_method som on som.no_id  = dea.ef_no_fishingmethod 
union all
-- Pêche en continue des berge (à pied)
SELECT 
ope.op_id ,
ope.op_zone, 
dea.ob_id, 
ope.op_typ, 
dea.ef_no_fishingmethod,--302 en base, devrait être 63 (comme dans ASPE) ou 64.
som.no_name,
null  as nb_points,--nb_points
null as surf_calc,--surface_calculée
opbgp.pcbgp_long  as ope_long,
opbgp.pcbgp_larg  as ope_larg,
dea.ef_wetted_area, 
opbgp.pcbgp_long * 4 AS actual_area--car pêche berge, mais enregsitré comme 302 dans dbeel --> KO ! devrait être 64. car 302 est considéré comme pêche complète.
from rsa.operation ope 
  JOIN rsa.op_pcbgp opbgp ON (opbgp.pcbgp_op_id  , opbgp.pcbgp_zone)= (ope.op_id, ope.op_zone)
  join france.dbeel_electrofishing_rsa dea on (dea.op_id,dea.op_zone  ) =  (ope.op_id, ope.op_zone)
join dbeel_nomenclature.scientific_observation_method som on som.no_id  = dea.ef_no_fishingmethod 
union all 
-- echantillonage pontctuel d'abondance, pêche par points (à pied ?)
SELECT 
ope.op_id ,
ope.op_zone, 
dea.ob_id, 
ope.op_typ, 
dea.ef_no_fishingmethod,--306 en base
som.no_name,
epap.epap_npnt  as nb_points,--nb_points
null as surf_calc,--surface_calculée
null  as ope_long,
null  as ope_larg,
dea.ef_wetted_area, 
epap.epap_npnt * 12.5 AS actual_area--car pêche EPA
from rsa.operation ope 
  JOIN rsa.op_epap epap ON (epap.epap_op_id , epap.epap_zone)= (ope.op_id, ope.op_zone)
  join france.dbeel_electrofishing_rsa dea on (dea.op_id,dea.op_zone  ) =  (ope.op_id, ope.op_zone)
join dbeel_nomenclature.scientific_observation_method som on som.no_id  = dea.ef_no_fishingmethod  
