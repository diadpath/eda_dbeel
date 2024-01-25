
----------------------------------------------------------------

---ICI

--------------------------------------------------------------------

WITH 
-- Pour la bdoe il peut y avoir plusieurs hauteurs de chutes différentes le meme jour.
-- Dans ce cas on prends la moyenne sinon on aura des problèmes.
hauteur_chute_bdoe AS ( 
  SELECT round(avg(hco_hauteur),2) as h_chute_bdoe,
  hco_ouv_id::integer as ouv_id, 
  hco_date_mesure AS bdoe_date_mesure  
  FROM bdoe.hauteur_chute 
  WHERE hco_date_mesure IS NOT NULL
  GROUP BY hco_date_mesure, hco_ouv_id
  ),
  -- SELECT * FROM hauteur_chute_bdoe WHERE ouv_id = 13697 (show duplicated value)

hauteur_chute_sto AS (
  SELECT   ooi_ref_id AS ouv_id, *
  FROM ice.obstacle_operation_ice JOIN
  ice.operation_ice on opi_ooi_id=ooi_id JOIN
  ice.partie_obstacle ON pao_opi_id=opi_id LEFT JOIN
  ice.structure_obstacle on sto_pao_id=pao_id --LEFT JOIN
  --hauteur_chute_pre on pre_id=sto_id
  ),
-- TODO voir si on garde voie sur berge, si ça à une quelconque conséquence sur la hauteur de chute
hauteur_chute_reordonne AS (
  SELECT opi_date_releve AS ice_date_mesure, *, -- contient opi_date_releve
   CASE WHEN sto_tso_id=5 THEN 2 -- ouvrage à marée
                 WHEN sto_tso_id=1 THEN 3 -- seuil
                 WHEN sto_tso_id=3 THEN 4 -- vannage
                 WHEN sto_tso_id=2 THEN 5 -- seuil en enrochement 
                 WHEN sto_tso_id=7 THEN 6 -- prise d'eau 
                 WHEN sto_tso_id=4 THEN 7 -- ouvrage routier
                 WHEN sto_tso_id=6 THEN 8   -- dispositif de franchissement piscicole             
                 WHEN sto_tso_id=8 THEN 9 --voie sur berge
                 END AS order_sto_tso_id 
   FROM hauteur_chute_sto     
   WHERE pao_eco_id in (1,3) -- oui, ou discontinu
   ORDER BY order_sto_tso_id),
   
   
-- Au sein d'une opération on prend la première chute parmis l'ordre précédent   
hauteur_chute_ice_sto AS (
  SELECT distinct on (ouv_id,opi_id) *
   FROM hauteur_chute_reordonne                                
  ),
--SELECT * FROM hauteur_chute_ice_sto limit 50

-- si on deux chutes lors d'opérations successives, on prend la plus petite
hauteur_chute_ice_par_ouvrage AS
(SELECT 
  ouv_id, 
  ice_date_mesure,
  min(sto_hauteur_chute) AS hauteur_chute_ice,
  max(opi_hauteur_chute) AS hauteur_chute_ice_plus_limitante  
  FROM hauteur_chute_ice_sto
  GROUP BY ouv_id, ice_date_mesure),
-- Nos hauteurs sont en général égales, parfois plus faibles, mais pas systématiquement ???. 
-- Dans certains cas on a une hauteur_chute venant de opi alors que pour nous rien ... 
-- peut être parce que dans ICE ils traitent mieux les nulls
-- SELECT * FROM hauteur_chute_ice_par_ouvrage WHERE hauteur_chute_ice_plus_limitante < hauteur_chute_ice
hauteur_chute_ice AS
(SELECT ouv_id, ice_date_mesure,
  coalesce(hauteur_chute_ice,hauteur_chute_ice_plus_limitante) AS h_chute_ice
  FROM hauteur_chute_ice_par_ouvrage
  WHERE coalesce(hauteur_chute_ice,hauteur_chute_ice_plus_limitante) IS NOT NULL ),
  
selectionne_roe AS (  
  SELECT regexp_replace(ref_id_national, 'ROE', '')::integer AS ouv_id,
  CASE WHEN ref_typ_id = 0 THEN 291 -- barrage
       WHEN ref_typ_id = 1 AND (ref_sty_id=10 OR ref_sty_id=11) THEN 292 --seuil
       WHEN ref_typ_id = 1 AND (ref_sty_id IS NULL) THEN 292 --seuil
       WHEN ref_typ_id = 1 AND ref_sty_id=12 THEN 293 -- enrochement
       WHEN ref_typ_id = 2 THEN 298 -- digue (en vrai va virer car non inclus)
       WHEN ref_typ_id = 3 AND (ref_sty_id=17 OR ref_sty_id=21) THEN 296 -- pont
       WHEN ref_typ_id = 3 AND (ref_sty_id IS NULL) THEN 296 -- pont
       WHEN ref_typ_id = 3 AND ref_sty_id = 20 THEN 295 -- passage à gué
       WHEN ref_typ_id = 3 AND ref_sty_id = 18 THEN 294 -- culvert
       WHEN ref_sty_id = 9 OR  ref_sty_id = 19 OR ref_sty_id=13 THEN 297 -- other
       WHEN ref_typ_id = 5 THEN 299 -- grille de pisciculture (en vrai va virer car non inclus)
       ELSE 219 -- Physical unknown
       END AS obstruction_type_no_id,
  roe.roesudo.*,
  chce_nom AS ref_hauteur_chute_etiage_classe --change 2020 la classe de hauteur de chute est stockée dans un référentiel
  FROM roe.roesudo
  LEFT JOIN roe.classe_hauteur_chute_etiage ON classe_hauteur_chute_etiage.chce_id = ref_chce_id -- CHANGE 2020 adapt code to new roe
  WHERE  geom_reproj IS NOT NULL AND
  ref_sta_id in(0,4) 
   ),
--SELECT * FROM selectionne_roe
--SELECT count(*)  FROM selectionne_roe --88743 --> 92253 (2023-04-11)
-- change 2020 add ref_chce_id
hauteur_chute_roe AS (
    SELECT ouv_id, 
    dbeel_op_id, 
    obstruction_type_no_id,
   CASE WHEN ref_chce_id=1 THEN NULL -- indéterminé
     WHEN ref_chce_id=2 THEN 0.25 --valeurs unique classe <0.5
     WHEN ref_chce_id=3 THEN 0.75 --De 0.5m à inférieure à 1m
     WHEN ref_chce_id=4 THEN 1.25 --De 1m à inférieure à 1.5m
     WHEN ref_chce_id=5 THEN 1.75 -- De 1.5m à inférieure à 2m
     WHEN ref_chce_id=6 THEN 2.5  --'DE 2m A INFERIEURE A 3m'     
     WHEN  ref_chce_id=7 THEN 4 --'DE 3m A INFERIEURE A 5m'
     WHEN ref_chce_id=8 THEN 7.5 --'DE 5m A INFERIEURE A 10m'
     WHEN ref_chce_id=9 THEN 20 --'SUPERIEURE OU EGALE A 10m'
     ELSE NULL  
   END AS h_chute_roe_classe,  
     COALESCE(ref_hauteur_chute_etiage,ref_hauteur_terrain) AS h_chute_roe
    FROM selectionne_roe
    WHERE dbeel_op_id IS NOT NULL -- ON vire les ouvrages pas utilisés à l'étape précédente (table observation place)
    ),
-- SELECT * FROM hauteur_chute_roe; --91188
 
hauteur_chute_tous AS (
 SELECT
   ouv_id,
   bdoe_date_mesure AS date_mesure,
   h_chute_bdoe AS h_chute,
   'bdoe' AS source_hchute
  FROM   hauteur_chute_bdoe
 UNION 
  SELECT 
    ouv_id,
    ice_date_mesure AS date_mesure,
    h_chute_ice AS h_chute,    
    'ice' AS source_hchute   
  FROM  hauteur_chute_ice
UNION 
  SELECT 
     ouv_id,
     NULL AS date_mesure,
     h_chute_roe AS h_chute,
     'roe' AS source_hchute      
  FROM hauteur_chute_roe
  WHERE h_chute_roe IS NOT NULL
     ),
-- SELECT * FROM hauteur_chute_tous WHERE source_hchute <>'roe' AND date_mesure IS NULL --70


-- Il peut y avoir differents types d'évennements qui changent un ouvrage
-- insallation d'une passe, dérasement, arasement, mise en activité ...
-- ci dessous on groupe tous les evennements dans un meme tableau puis
-- on utilise une fonction window (over partition by) pour calculer les périodes. 
     
date_evenement_all AS (
 
  SELECT ouv_id, 
  ouv_debut_activite AS date_evt,
  'début activité usage' AS type_evt
  FROM bdoe.ouvrage 
  WHERE ouv_debut_activite IS NOT NULL 
  UNION ALL 
  SELECT  ouv_id, 
  ouv_fin_activite AS date_evt,
  'fin activité usage' AS type_evt
  FROM bdoe.ouvrage 
  WHERE ouv_fin_activite IS NOT NULL 
  AND ouv_fin_activite < CURRENT_DATE
  UNION ALL 
  SELECT ouv_id,
  ouv_arasement_date AS date_evt,
  'arasement' AS type_evt
  FROM bdoe.ouvrage
  WHERE ouv_arasement_date IS NOT NULL
  AND ouv_arasement_date  < CURRENT_DATE
  UNION ALL 
  SELECT ouv_id,
  ouv_derasement_date AS date_evt,
  'derasement' AS type_evt
  FROM bdoe.ouvrage
  WHERE ouv_derasement_date IS NOT NULL
  AND ouv_derasement_date < CURRENT_DATE
  UNION ALL 
  SELECT DISTINCT dfp_ouv_id AS ouv_id,
  dfp_date_mes AS date_evt,
  'dispositif de franchissement' AS type_evt
  --dfp_libelle AS type_passe
  FROM bdoe.franchissement_piscicole_bdoe
  WHERE dfp_date_mes IS NOT NULL
  AND dfp_date_mes < CURRENT_DATE
    UNION ALL 
  SELECT DISTINCT 
  fpi_ref_id AS ouv_id,
  (hfpi_date_metier||'-12-31')::date AS date_evt,
  'dispositif de franchissement' AS type_evt
  FROM roe.historique_franch_piscicole
  LEFT JOIN roe.franchissement_piscicole ON fpi_id = hfpi_fpi_id
  LEFT JOIN bdoe.franchissement_piscicole_bdoe ON dfp_fpi_id = fpi_id
  WHERE hfpi_date_metier IS NOT NULL
  AND (hfpi_date_metier||'-12-31')::date < current_date
  AND (dfp_date_mes IS NULL OR EXTRACT(YEAR FROM dfp_date_mes)<>hfpi_date_metier) -- 2024 On prend le ROE que si on a pas de passe dans BDOE la même année 362 => 430
  UNION all
  SELECT DISTINCT ref_id AS ouv_id,
  ref_date_construction_ouvrage AS date_evt,
  'date construction ouvrage' AS type_evt
  --dfp_libelle AS type_passe  
  FROM roe.roesudo
  WHERE ref_date_construction_ouvrage IS NOT NULL
      -- ***********************************************
  UNION ALL
 SELECT ref_id AS ouv_id, 
'1800-01-01'::date AS date_evt, 
'date debut (defaut)' AS type_evt
 FROM roe.roesudo
  WHERE ref_date_construction_ouvrage IS NULL
  ),
--SELECT * FROM date_evenement_all WHERE   ouv_id = 7783    
  
-- La premiere va de NULL a min, les suivantes vont de
-- date à date+1 dans le partition by. 
-- pour la première partie on veut tous les ouvrage avec
-- une date de début par défaut sauf ceux qui ont une date de construction d'ouvrage 
 
ordre_periode AS (
SELECT ouv_id, 
type_evt, 
date_evt AS datedebut,
-- LEAD OVER PARTITION BY VA CHERCHER LES VALEURS PAR DATE_EVT et par defaut sur la dernière ligne met 2023
LEAD(date_evt, 1, '2035-01-01') -- ATTENTION SI MODIF 2035 ADAPT SCRIPT baseedariosriversegmetdam.R cumulated_dam_impact2 fntrans()
OVER (PARTITION BY ouv_id ORDER BY date_evt) AS datefin 
FROM date_evenement_all 
ORDER BY ouv_id, datedebut),

--SELECT * FROM ordre_periode WHERE   ouv_id = 7783

  
-- 2024 : les dates_atg ne se joignent qu'à certaines périodes (dans periode_atg)
-- on récupère les autres (celles qui n'ont pas d'avis technique) dans periode_nonatg
-- et on fait l'union des deux dans unique_periode_atg

  date_atg AS (
  SELECT ouv_id, ouv_atg_id, ouv_date_avis 
  FROM bdoe.ouvrage
  WHERE ouv_date_avis IS NOT NULL AND ouv_date_avis < current_date
  ),
  
  periode_atg AS (

  SELECT 
  date_atg.ouv_id, ouv_atg_id, ouv_date_avis, datedebut, datefin
  FROM ordre_periode   
  LEFT JOIN date_atg  ON ordre_periode.ouv_id = date_atg.ouv_id  
  AND ouv_date_avis >= datedebut and ouv_date_avis < datefin
  ),
  
periode_nonatg AS (

  SELECT 
  ordre_periode.ouv_id, NULL AS ouv_atg_id, NULL AS ouv_date_avis, ordre_periode.datedebut, ordre_periode.datefin
  FROM ordre_periode   
 
  EXCEPT
  
  SELECT 
  ordre_periode.ouv_id, NULL::INTEGER AS ouv_atg_id, NULL::date AS ouv_date_avis, ordre_periode.datedebut, ordre_periode.datefin
  FROM ordre_periode   INNER JOIN 
  periode_atg ON (periode_atg.ouv_id, periode_atg.datedebut,  periode_atg.datefin)= 
 (ordre_periode.ouv_id, ordre_periode.datedebut,  ordre_periode.datefin)
 ),
  
  
unique_periode_atg as (
    SELECT * FROM   periode_atg
    UNION 
    SELECT * FROM   periode_nonatg
    ),



--SELECT * FROM unique_periode_atg WHERE  ouv_id = 7783

-- Attention à date_metier qui correspondrait a des modifications sur la franchissabilité de l'ouvrage mais pas forcément lié à un dispositif de franchissement
--SELECT * FROM ordre_periode WHERE ouv_id=217 

-- On joint les hauteur_tous (qui éventuellement contiennent des dates)
-- avec ordre periode

hauteur_chute_par_periode AS (
-- premier cas la chute est datee
 SELECT
 hauteur_chute_tous.ouv_id,
 date_mesure,
 h_chute,
 source_hchute,
 type_evt,
 datedebut,
 datefin
 FROM
 hauteur_chute_tous JOIN ordre_periode ON (
 ordre_periode.ouv_id=hauteur_chute_tous.ouv_id
 AND date_mesure < datefin
 AND date_mesure >= datedebut
)

  
  
 UNION
 -- par defaut on ajoute les lignes avec le ROE (qui n'ont pas de dates) et tous les ouvrages
 -- y compris ceux sur lesquels on a pas pu déterminer de période
 -- ces ligne s'appliquent alors à toutes les périodes avant et après l'arasement d'un ouvrage 
 -- certains ouvrages ont des petites hauteurs de chute dans le roe donc ils ont été mis à jour.
 
 SELECT
 hauteur_chute_tous.ouv_id,
 NULL AS date_mesure,
 h_chute, 
 source_hchute,
 type_evt,
 datedebut,
 datefin
 FROM 
 hauteur_chute_tous JOIN ordre_periode ON 
 ordre_periode.ouv_id=hauteur_chute_tous.ouv_id
 WHERE date_mesure IS NULL 
),
--SELECT * FROM hauteur_chute_par_periode WHERE   ouv_id = 87230

--where datedebut is not null;--8082

-- choisir en priorié ICE > BDOE > ROE (pas de date)
-- on refait une jointure avec selectionne_roe ci dessus pour récupérer
-- tous les ouvrages ROE selectionnés (92253)  et
-- obstruction_type_no_id qui correspond au code de l'ouvrage dans la dbeel
-- il n'y a pas d'autres données dispo ce qui veut dire que la grande majorité des hauteurs de chute est nulle.
ordered_hauteur_chute_par_periode AS (
SELECT 
hauteur_chute_roe.ouv_id,
obstruction_type_no_id,
date_mesure,
CASE WHEN h_chute IS NULL AND h_chute_roe IS NULL THEN h_chute_roe_classe
     WHEN h_chute IS NULL AND h_chute_roe IS NOT NULL THEN h_chute_roe
     WHEN h_chute IS NOT NULL THEN h_chute END AS h_chute,
CASE WHEN h_chute IS NULL AND h_chute_roe IS NULL AND h_chute_roe_classe IS NULL THEN 'pas de hauteur de chute'
     WHEN h_chute IS NULL AND h_chute_roe IS NULL AND h_chute_roe_classe IS NOT NULL THEN 'roe classe'
     WHEN h_chute IS NULL AND h_chute_roe IS NOT NULL THEN 'roe'
     WHEN h_chute IS NOT NULL THEN source_hchute END  AS commentaire_h_chute,
type_evt,
datedebut::date,
datefin::date  
FROM hauteur_chute_roe
LEFT JOIN hauteur_chute_par_periode
 ON hauteur_chute_roe.ouv_id = hauteur_chute_par_periode.ouv_id
ORDER BY 
ouv_id,
datedebut, 
CASE WHEN source_hchute = 'ice' THEN 1
    WHEN source_hchute = 'bdoe' THEN 2
    WHEN source_hchute = 'roe'  THEN 3
 END,
 date_mesure desc),
--SELECT * FROM  hauteur_chute_roe                                
--SELECT * FROM  ordered_hauteur_chute_par_periode --99922 (   92253 pour ouvrages distincts)
--where datedebut is not null;  --8002 avec une date  ( on en perd 80 par rapport au tableau hauteur chute par periode ==> restreint sur les ouvrages ROE selectionnés  
--SELECT count(*) FROM   ordered_hauteur_chute_par_periode WHERE datedebut IS NULL;    --88777  ouvrages sans info             

-- ci dessous on a pour un meme ouvrage plusieurs lignes
-- les lignes roe ont une date nulle elles vont se joindre à toutes les lignes dans la clause between utilisée dans hauteur_chute_par_periode
-- Il peut aussi y avoir des lignes de source ICE et BDOE (voir arasement ci dessous)
-- comme on a ré-ordonné on prend l'abord ice puis bdoe puis roe
-- Dans l'immense majorité des cas il n'y a pas de valeur pour la hauteur de chute                               
/*      
261 292 2010-12-31  2.615 bdoe    date debut (defaut) 1800-01-01  2010-12-31
261 292 2010-12-31  0.59  roe    date debut (defaut)  1800-01-01  2010-12-31 => SUPPRIMEE
261 292 2011-05-11  0.59  ice    arasement            2010-12-31  2035-01-01                   
261 292 2010-12-31  0.59  bdoe    arasement           2010-12-31  2035-01-01 => SUPPRIMEE   
261 292 2010-12-31  0.59  roe    arasement            2010-12-31  2035-01-01 => SUPPRIMEE
*/   
height AS (
    SELECT  DISTINCT ON (ouv_id,datedebut)  * FROM ordered_hauteur_chute_par_periode),


reception_devalaison_tous AS (
  SELECT ooi_ref_id AS ouv_id, 
  TRUE AS po_downs_pb
  FROM ice.obstacle_operation_ice 
  JOIN ice.operation_ice on opi_ooi_id=ooi_id 
  JOIN ice.probleme_reception_devalaison_operation_ice ON  prdoi_opi_id=opi_id
  JOIN hauteur_chute_roe hh on hh.ouv_id=ooi_ref_id -- pour virer les codes gelés et autres
  ORDER BY ouv_id, coalesce(opi_date_releve,'1900-01-01') desc
  ),
  
reception_devalaison AS (SELECT DISTINCT on (ouv_id) * FROM reception_devalaison_tous),
  
--SELECT * FROM reception_devalaison --583 -->543

--SELECT * FROM presence_eel_pass--58754
--SELECT DISTINCT on (ouv_id) * FROM presence_eel_pass

-- THE DISTINCT CLAUSE MUST BE IN THE SAME TABLE AS ORDER BY OTHERWISE WON'T WORK       
       
expertise_devalaison_tous AS (
SELECT DISTINCT ON (doe_ouv_id) * FROM bdoe.devalaison_ouvrage dou
--JOIN  hauteur_chute_roe hh on hh.ouv_id=dou.doe_ouv_id
ORDER BY doe_ouv_id, CASE WHEN doe_mcd_id=3 THEN 1
    WHEN doe_mcd_id=2 THEN 2
    WHEN doe_mcd_id=1 THEN 3
    END
    ), --126
expertise_devalaison AS (
SELECT doe_ouv_id AS ouv_id, 
  CASE WHEN doe_mcd_id =3 THEN 283  -- turbine ichtyocompatible
  WHEN doe_mcd_id=2 THEN 282 -- equipement de prise d'eau
  WHEN doe_mcd_id=1 THEN 284  -- Gestion (fish adapted management)
  END AS mitigationmeasureid
FROM expertise_devalaison_tous  
),  
  
obstruction AS (
SELECT replace(id_original,'ROE','')::integer AS ouv_id, 
op_id, 
--dbeel_op_id,
   op_no_observationplacetype
FROM montepomi.dbeel_obstruction_place WHERE id_original like 'ROE%' ),--91188
--select * from obstruction

bdoe_ouvrage AS (
SELECT ouv_id, ouv_atg_id, ouv_date_avis, atg_libelle
FROM bdoe.ouvrage
LEFT JOIN bdoe.avis_technique_global ON atg_id = ouv_atg_id), --114?314

add_column_bdoe as (
  select ouv_atg_id AS ouv_avis_tech_global_id,
      ouv_conformite_montaison,
      ouv_conformite_devalaison,
    ouv_commentaire_chute AS ouv_commentaire_chute_bdoe,
    ouv_commentaire_avis AS ouv_commentaire_avis_bdoe,
    ouv_commentaires AS ouv_commentaires_bdoe,
    ouv_commentaire_mesures AS ouv_commentaire_mesures_bdoe,
    ouv_derasement_date,
    ouv_arasement_date,
    ouv_debut_activite,
    ouv_fin_activite,
    ouv_id
  from bdoe.ouvrage
  --trouver comment joindre avec l'uuid
),
add_column_roe as (
  select ref_commentaire_sous_type as ref_commentaire_sous_type_roe ,
  ref_id as ouv_id
  from roe.obstacle_referentiel
  ) 
SELECT 
  count(*) FROM (
  SELECT * 
FROM 
  obstruction
  LEFT JOIN unique_periode_atg upa ON upa.ouv_id = obstruction.ouv_id) fdgddfgg

   LEFT JOIN height on (height.ouv_id, height.datedebut,height.datefin)=(upa.ouv_id, upa.datedebut, upa.datefin) -- contient hauteur chute, voir ce qu'on fait de la colonne commentaire_hauteur_chute  qui qualifie la hauteur OK pAS de doublons
  LEFT JOIN reception_devalaison on reception_devalaison.ouv_id=obstruction.ouv_id  --po_downs_pb (boolean) OK pAS de doublons
    LEFT JOIN expertise_devalaison on expertise_devalaison.ouv_id=obstruction.ouv_id 
  LEFT JOIN add_column_bdoe ON add_column_bdoe.ouv_id = obstruction.ouv_id
    LEFT JOIN add_column_roe ON add_column_roe.ouv_id = obstruction.ouv_id )fdgddfgg
  WHERE obstruction.ouv_id = 7783;
    
/*
   

select dbeel_view_pass.*,
dbeel_obstruction_place.the_geom 
from montepomi.dbeel_view_pass 
left join montepomi.dbeel_obstruction_place 
on dbeel_obstruction_place.op_id=dbeel_view_pass.op_id
WHERE dbeel_obstruction_place.id_original = 'ROE7783'


SELECT dbeel_physical_obstruction_pass_species.*
FROM montepomi.dbeel_physical_obstruction_pass_species
where op_id = '3ebf4db1-3a67-4191-ae6d-4185259c967d'
ORDER BY ob_id, species, po_presence_pass DESC


SELECT * FROM montepomi.dbeel_physical_obstruction AS dpo  
WHERE ob_op_id = '22228ca1-fb5a-43df-b34b-68e431212495';

*/

