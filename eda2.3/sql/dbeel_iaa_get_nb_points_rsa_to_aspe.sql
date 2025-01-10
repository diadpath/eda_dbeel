--Ce script a pour objectif de remonter le nombres de points réalisés lors des opérations de pêches IAA
--ce nombre dep oitns est manquant dasn ASPE mais existe dans RSA

--important :
-- 1) 	ce script doit être exécuté après avoir remonté le doublons mais avant de les avoir traités (suppression éventuelle) 
-- 		car beaucoup d'opérations de pêche IAA sont saisies à la fois dans ASPE et RSA
-- 		et à ce stade on ne sait pas si on conserve l'opération ASPE ou RSA
-- 2)	toujours en lien avec les doublons potentiels, le nombre de points doit être stockés sur l'opération ASPE ET sur l'éopration RSA (dans la dbeel)
-- 3)	le préambule à ce traitement est d'avoir créé une table temporaire france.temp_iaa_rsa_to_aspe_npoints qui permet de relier un code d'opé ASPE à un nombre de points.
-- 		cette table teporaire est alimenté via un fichier csv qui aura été fourni externe (au 12/12/2023, par G. André)
/* 
CREATE TABLE france.temp_iaa_rsa_to_aspe_npoints (
	ope_id int4 NULL,
	sta_code_sandre int4 NULL,
	op_placename varchar(50) NULL,
	ob_starting_date varchar(50) NULL,
	ef_fished_length int4 NULL,
	ba_quantity int4 NULL,
	nb_points int4 NULL
);

-- Permissions

ALTER TABLE france.temp_iaa_rsa_to_aspe_npoints OWNER TO postgres;
GRANT ALL ON TABLE france.temp_iaa_rsa_to_aspe_npoints TO postgres; */

--ASPE (bilan des opé IAA avec le nb de points)
select count(*),dea.odp_nombre_points_anguilles, dea.nb_point, dea.ef_wetted_area  
from france.dbeel_electrofishing_aspe dea where dea.ef_no_fishingmethod = '303' 
group by (dea.odp_nombre_points_anguilles, dea.nb_point, dea.ef_wetted_area)

--RSA (bilan des opé IAA avec le nb de points)
select count(*), der.ef_wetted_area , oi.iaa_npnt
from france.dbeel_electrofishing_rsa der 
join rsa.op_iaa oi on (oi.iaa_op_id, oi.iaa_zone) = (der.op_id, der.op_zone)
where der.ef_no_fishingmethod = '303' 
group by (der.ef_wetted_area, oi.iaa_npnt)


--pour vérifier que les données entre ASPE, RSA et le fichier manuel sont cohérentes
--ASPE, jointure avec table temp pour nombre de points + jointure avec table des doublons pour éventuellement remonter l'id RSA correspondant et le nb de points RSA connus
select dea.ob_id as aspe_ob_id, 
dea.ope_id as aspe_id,
der.ob_id as rsa_obe_id,
der.op_id as rsa_id,
der.op_zone as rsa_zone,
dea.odp_nombre_points_anguilles as aspe_odb_points, 
dea.nb_point as aspe_dbeel_pts, 
tirtan.nb_points as nb_points_man, 
oi.iaa_npnt as rsa_nb_points,
dea.ef_wetted_area as aspe_dbeel_area 
from france.dbeel_electrofishing_aspe dea 
left join france.temp_iaa_rsa_to_aspe_npoints tirtan on tirtan.ope_id = dea.ope_id 
left join france.temp_ope_dup_aspe_rsa todar on todar.aspe_ob_id = dea.ob_id
left join france.dbeel_electrofishing_rsa der on der.ob_id = todar.rsa_ob_id 
left join rsa.op_iaa oi on (oi.iaa_op_id, oi.iaa_zone) = (der.op_id, der.op_zone)
where dea.ef_no_fishingmethod = '303' 

--il existe donc 3 sources possibles pour le nombre de points : ASPE, RSA ou fichier manuel de Guirec.
--Dans l'ordre de préférence, on va prioriser :
--données Guirec, si absente donnée ASPE (champs odp_nombre_points_anguilles), si absente donnée RSA (iaa_npnt)
--le champs a mettre à jour est dans france.dbeel_electrofishing_aspe/rsa

--MAJ côté ASPE
with sub_query as (
select dea.ob_id as aspe_ob_id, 
coalesce(
nullif(tirtan.nb_points,0),
nullif(dea.odp_nombre_points_anguilles,0),
nullif(oi.iaa_npnt,0)) as best_nb_point 
from france.dbeel_electrofishing_aspe dea 
left join france.temp_iaa_rsa_to_aspe_npoints tirtan on tirtan.ope_id = dea.ope_id 
left join france.temp_ope_dup_aspe_rsa todar on todar.aspe_ob_id = dea.ob_id
left join france.dbeel_electrofishing_rsa der on der.ob_id = todar.rsa_ob_id 
left join rsa.op_iaa oi on (oi.iaa_op_id, oi.iaa_zone) = (der.op_id, der.op_zone)
where dea.ef_no_fishingmethod = '303' 
)
update france.dbeel_electrofishing_aspe dea 
set nb_point = sq.best_nb_point,
ef_wetted_area = sq.best_nb_point*12.5
from sub_query sq where sq.aspe_ob_id = dea.ob_id 
--17/01/24 : 1245 lignes maj

--MAJ côté RSA (via table doublons)
with sub_query as (
select dea.ob_id as aspe_ob_id, 
todar.rsa_ob_id  as rsa_ob_id, 
coalesce(
nullif(tirtan.nb_points,0),
nullif(dea.odp_nombre_points_anguilles,0),
nullif(oi.iaa_npnt,0)) as best_nb_point 
from france.dbeel_electrofishing_aspe dea 
left join france.temp_iaa_rsa_to_aspe_npoints tirtan on tirtan.ope_id = dea.ope_id 
left join france.temp_ope_dup_aspe_rsa todar on todar.aspe_ob_id = dea.ob_id
left join france.dbeel_electrofishing_rsa der on der.ob_id = todar.rsa_ob_id 
left join rsa.op_iaa oi on (oi.iaa_op_id, oi.iaa_zone) = (der.op_id, der.op_zone)
where dea.ef_no_fishingmethod = '303' 
)
update france.dbeel_electrofishing_rsa der 
set ef_wetted_area = sq2.best_nb_point*12.5
from sub_query sq2 where sq2.rsa_ob_id = der.ob_id 
--17/01/24 : 764 lignes maj

