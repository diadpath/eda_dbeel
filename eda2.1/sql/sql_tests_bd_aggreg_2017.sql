-- Script adapte a bd_agglo
SET search_path TO base_mai, base_agglo, public;

-- les annees
select annee, count(*) from
(select extract(year from date_operation) as annee from operation) sub
group by annee
order by annee;

CREATE OR REPLACE VIEW base_mai.vue_operation_anguille AS (
  
SELECT id_libelle_wama_objectif as op_cd_objectifpeche, -- Il s'agit du premier objectif de pêche voir ci dessous
case 	when operation.id_wama_methode_prospection = 114 then 847 -- ambiance
	when operation.id_wama_methode_prospection = 116 then 851 -- autre
	when operation.id_wama_methode_prospection = 124 then 843 -- complète
	when operation.id_wama_methode_prospection = 119 then 848 -- stratifiée par EPA / EPA
	when operation.id_wama_methode_prospection = 120 then 846 -- statifiée par faciès/ faciès
	when operation.id_wama_methode_prospection = 121 then 845 -- Partielle sur berge 
	when operation.id_wama_methode_prospection = 122 then 844 -- Partielle sur toute la largeur
	when operation.id_wama_methode_prospection = 115 then 850 -- Partielle sur toute la largeur
	when operation.id_wama_methode_prospection = 118 then 1611 -- Stratifiée par point (grand milieu)
	when operation.id_wama_methode_prospection = 117 then 849 -- traits / stratifiée par traits
end as op_cd_methodeprospection, 
case    when operation.id_wama_moyen_prospection = 126 then 852 -- non renseigné
	when operation.id_wama_moyen_prospection = 127 then 853 --  a pied 
	when operation.id_wama_moyen_prospection = 128 then 854 -- en bateau
	when operation.id_wama_moyen_prospection = 125 then 855 -- mixte (à cheval!)
end as op_cd_moyenprospection,
operation.code_operation AS op_numero,   -- ATTENTION CETTE COLONNE EST EN PLUS PAR RAPPORT A LA VUE EDA2.0
extract(year from date_operation) as annee,
date_operation as op_datedebut,
NULL as op_listeespecescible, -- !! PAS TROUVE
case when longueur_pechee=999 then NULL else longueur_pechee end as op_longueur,
sub_nbrpassage.op_nbrpassage as op_nbrpassage, 
(coalesce(operation.nb_points_representatifs,0)+coalesce(nb_points_complementaires,0)) as op_nbrsondage, --(verifier ?) ATTENTION CETTE 
case when largeur_lame_d_eau=999 then NULL else largeur_lame_d_eau end as op_cs_largeurlameeau,
surface_calculee as op_surfaceechantillon,
 NULL as st_id, -- REM je suppose que celui là c'était un code bd_map.
 station.code_sandre_station as st_codecsp,   -- De toutes façons c'est celui là que j'utilise        
nom_wama_point as st_lieudit,-- REM station.nom pas cohérent avec le lieu dit de bd_map, c'est plus le nom de la station ici   
 -- pour les coordonnées je prends d'abord wama, puis sandre (si wama est null ou -9 mais quand sandre !=0), puis bd_carthage    
 case  when x_l93_wama is not null 
		and x_l93_wama!=(-9)::double precision 
		then x_l93_wama
       when (x_l93_wama is null or x_l93_wama=(-9)::double precision) and 
		x_l93_sandre	is not null and
	        x_l93_sandre!=0 
	        then x_l93_sandre
       when (x_l93_wama is null or x_l93_wama=(-9)::double precision) and 
	       (x_l93_sandre is null or x_l93_sandre=0) 
	       then x_l93_bd_carthage
 end as st_abcisse,  
 case  when y_l93_wama is not null 
		and y_l93_wama!=(-9)::double precision 
		then y_l93_wama
       when (y_l93_wama is null or y_l93_wama=(-9)::double precision) and 
		y_l93_sandre	is not null and
	        y_l93_sandre!=0 
	        then y_l93_sandre
       when (y_l93_wama is null or y_l93_wama=(-9)::double precision) and 
	       (y_l93_sandre is null or y_l93_sandre=0) 
	       then y_l93_bd_carthage
 end as st_ordonnee
 FROM base_mai.station 
 JOIN base_mai.point_prelevement_metier on point_prelevement_metier.code_sandre_station=station.code_sandre_station
 JOIN base_mai.operation ON point_prelevement_metier.id_point_metier = operation.id_point_metier     
     -----------------------------------------------------
     -- Premier objectif de pêche
     -- ci dessous il peut y avoir des doublons, cette reguete ne renvoit que le premier code de la liste
     -- voir TRAVAIL SUR LES OBJECTIFS OPERATION pour comprendre
     ------------------------------------------------------------
  LEFT JOIN 
	     (
	     SELECT distinct on (id_national_operation) *  from 
		(SELECT * from 
		 base_mai.objectifs_operation
		 ORDER BY id_national_operation,objectifs_operation
		 ) AS sub_objectifs_ordonnes
	     ) AS sub_objectifs_distincts     
     ON operation.id_national_operation=sub_objectifs_distincts.id_national_operation
     ---------------------------------------------------------------
     -- Nombre de passage
     -- calcul du nombre de passage, on fait l'hypothèse qu'il n'y a pas eu de passage sans poissons dans la base
     -- les nb de passages de wama ne sont pas reportés dans la base temporaire.
     -----------------------------------------------------------------
   LEFT JOIN 
	     (
		SELECT max(num_passage) as op_nbrpassage, id_national_operation 
		FROM base_mai.lots_poissons 
		GROUP BY id_national_operation 
	     ) AS sub_nbrpassage	
     ON sub_nbrpassage.id_national_operation=sub_objectifs_distincts.id_national_operation
      );--12285

  select * from base_mai.vue_operation_anguille          
          
-----------------------------------------------
/*
TRAVAIL SUR LES OBJECTIFS OPERATION
*/
-----------------------------------------------
     select count(*) from base_mai.objectifs_operation; -- 16437
     select count(*) from
     (select distinct on (id_national_operation) id_national_operation from base_mai.objectifs_operation) sub;-- 14419


create extension tablefunc; -- install crosstab
select * from base_mai.objectif order by id_libelle_wama_objectif

/* 
tableau des différents objectifs par operation
ne pas oublier le order by dans la première clause
*/
select * from (
select * from crosstab(
		'select  id_national_operation,id_libelle_wama_objectif,1 as count from base_mai.objectifs_operation order by id_national_operation',
		'select distinct id_libelle_wama_objectif from base_mai.objectifs_operation order by id_libelle_wama_objectif'
	)
	AS (id_national_operation integer,
		"381" numeric,
		"382" numeric,
		"385" numeric,
		"387" numeric,
		"388" numeric,
		"389" numeric,
		"390" numeric,
		"391" numeric,
		"392" numeric,
		"393" numeric,
		"394" numeric,
		"395" numeric,
		"396" numeric,
		"397" numeric,
		"804" numeric)
)subcrosstab
order by subcrosstab.id_national_operation;--14419

/* 
tableau des operations ayant plus qu'un seul objectif
*/

create view base_mai.tableau_objectifs as (
select subcrosstab.*,
subcount.count
 from (

	select count(*),id_national_operation 
	from base_mai.objectifs_operation 
	group by (id_national_operation)) subcount

join (
	select * from crosstab(
		'select  id_national_operation,id_libelle_wama_objectif,1 as count from base_mai.objectifs_operation order by id_national_operation',
		'select distinct id_libelle_wama_objectif from base_mai.objectifs_operation order by id_libelle_wama_objectif'
	)
	AS (id_national_operation integer,
		"381" numeric,
		"382" numeric,
		"385" numeric,
		"387" numeric,
		"388" numeric,
		"389" numeric,
		"390" numeric,
		"391" numeric,
		"392" numeric,
		"393" numeric,
		"394" numeric,
		"395" numeric,
		"396" numeric,
		"397" numeric,
		"804" numeric)
) subcrosstab
on subcrosstab.id_national_operation=subcount.id_national_operation
order by subcrosstab.id_national_operation);--1889

select * from base_mai.tableau_objectifs where count>=2;
select * from base_mai.tableau_objectifs where count>2 and "390"=1


-- suppression de la ligne à problème
begin;
delete from base_mai.objectifs_operation where id_national_operation=2506 and id_libelle_wama_objectif=390;
commit;



-- nombre de passage

select distinct num_passage, count(*) from base_mai.lots_poissons group by num_passage;


select max(num_passage), id_national_operation 
from base_mai.lots_poissons 
group by id_national_operation 
order by id_national_operation;


-- effectif d'anguilles par passage
CREATE VIEW vue_passage_anguille as (
SELECT sub_effectif.id_national_operation,nbp1,nbp2,nbp3, ot_effectif FROM (
	-- tous les passages	
		select sum(effectif_lot) as ot_effectif, id_national_operation
		from base_mai.lots_poissons 
		where code_sandre_taxon='2038'
		group by id_national_operation 
	) AS sub_effectif
	FULL OUTER JOIN (
	-- passage 1
		select sum(effectif_lot) as nbp1, id_national_operation
		from base_mai.lots_poissons 
		where code_sandre_taxon='2038'
		and num_passage=1
		group by id_national_operation
	) AS sub_nbp1
	ON sub_effectif.id_national_operation=sub_nbp1.id_national_operation
	FULL OUTER JOIN (
	-- passage 2
		select sum(effectif_lot) as nbp2, id_national_operation
		from base_mai.lots_poissons 
		where code_sandre_taxon='2038'
		and num_passage=2
		group by id_national_operation 
	) AS sub_nbp2
	ON sub_effectif.id_national_operation=sub_nbp2.id_national_operation
	FULL OUTER JOIN (
	--passage 3
	select sum(effectif_lot) as nbp3, id_national_operation
		from base_mai.lots_poissons 
		where code_sandre_taxon='2038'
		and num_passage=3
		group by id_national_operation 
	) AS sub_nbp3
	ON sub_effectif.id_national_operation=sub_nbp3.id_national_operation
	); --5626 lignes
	
-- Vérification
select distinct on (id_national_operation) id_national_operation
from base_mai.lots_poissons 
where code_sandre_taxon='2038'
--5626 lignes
----------------------------
-- Données de taille
---------------------------
select * from  base_mai.lots_poissons
(

-----------------------------
/*
Recalcul de la structure en taille 
*/
-------------------------------

 ot_effectif            
 ot_effectifestim         
 ot_efficacite          
 ot_estestime            
 pa_effectif              
 "150"                      
 "150_300"                  
 "300_450"                  
 "450_600"                 
 "600_750" 
 ">750"                 
 nbtotalclasstail         
 moyenprospection         
 methodeprospection       
 effort                  

select distinct type_lot from base_mai.lots_poissons where code_sandre_taxon='2038';
    
select id_national_operation, 
longueur_min,
longueur_max,
code_type_longueur,
 poids_lot,
 effectif_lot,
 type_prelevement_elementaire
 from base_mai.lots_poissons where code_sandre_taxon='2038' and type_lot='N+';--7000


-- ceux là sont faciles
-- lots N avec poids individuels
-- voir script R (import_donnee_wama.R)pour les autres tables equivalentes 


 select 
 id_national_operation, 
 lots_poissons.id_lot_poissons,
 taille_poisson,
 poids_poisson,
 mesure_reelle,
 effectif_lot
 from base_mai.lots_poissons 
 join base_mai.mesure_individuelle on mesure_individuelle.id_lot_poissons=lots_poissons.id_lot_poissons 
 where code_sandre_taxon='2038' 
 and type_lot='N+'
 ;
 
base_mai.lots_poissons
select * from base_mai.mesure_individuelle limit 10
 select * from base_mai.lots_poissons limit 10