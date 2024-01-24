/*
 * 
 * dbeel_physical_obstruction_pass_species & dbeel_physical_obstruction_score_species
 * 
 * correspond à 
 * -- #18 Summary of expertise data in ICE and Bdoe at the scale of dam and species
* ouv_id,
* species,
* fishway working for the species ? (TRUE/FALSE)
* ICE score of passability by dam and species
* Bdoe score of passability by dam and species
* Global score calculated thanks to all the previous information collected
*/



 
/*
 * ------------------------------------------
 * TABLE PASSES 
 * ------------------------------------------
 *
 * Traitement des données de passe à poissons. 
 * On récupère les fonctionnalités de passe par espèce
 * et on va les joindre à la table physical_obstruction en utilisant la date de construction de la passe
 * une passe s'appliquera à toutes les périodes dont la date de fin est supérieure à la date de construction de passe.
 * attention a la même période (même ob_id) il peut y avoir plusieurs passes pour une espèce
 * si une passe est franchissable (true pour l'espèce) et une ne l'est pas, il faudra choisir celle qui est franchissable.
 * DISTINCT FROM .... order by po_presence_pass::numeric desc est appliqué dans le code de la vue
 * Pour toutes les passes pour lesquelles on a pas de date, on applique la jointure à toute les périodes 
 * ca veut dire qu'on pourra avoir des observations avec une passe alors qu'en fait la passe n'était pas construite.
 * On fait un union entre la table qui fait la jointure avec les dates de construction de passe et les observations
 * et la table qui fait la même jointure mais pour laquelle la date de construction est NULL
 */

DROP TABLE IF EXISTS montepomi.dbeel_physical_obstruction_pass_species CASCADE;
CREATE TABLE montepomi.dbeel_physical_obstruction_pass_species AS (
-- table espece c'est juste une combinaison toutes les espèces à la main avec le gre_id correspondant
WITH table_espece AS (
  SELECT
    'alose' AS species,
    3 AS gre_id
UNION ALL
  SELECT
    'lamproie' AS species,
    5 AS gre_id
UNION ALL
  SELECT
    'saumon' AS species,
    1 AS gre_id
UNION ALL
  SELECT
    'anguille' AS species,
    19 AS gre_id
UNION ALL 
  SELECT
    'civelle' AS species,
    20 AS gre_id
),
dbeel_especes AS (
SELECT
  DISTINCT dbeel_obstruction_place.op_id, id_original,
  table_espece.species, table_espece.gre_id 
FROM montepomi.dbeel_obstruction_place,
    table_espece),
    
-- tableau des passes fonctionnelles ou non (po_presence_pass) true ou false pour 
-- chaque espèce en fonction du type de passe en provenance du ROE
     
roe_type_pap AS (
SELECT fpi_ref_id AS ouv_id,
	  'civelle' AS species,
      fpi_id,
      CASE WHEN fpi_fty_id IS NULL THEN FALSE 
      else fpi_fty_id IN (4,8) AND COALESCE (ouv_lineaire_aval, 9999) < 50
      END AS po_presence_pass,
       -- On garde le type passe à anguilles et rivière de contournement à moins de 50km
      COALESCE(dfp_date_mes,(hfpi_date_metier||'-12-31')::date) AS date_passe
FROM roe.franchissement_piscicole
LEFT JOIN bdoe.ouvrage ON fpi_ref_id=ouv_id
LEFT JOIN roe.historique_franch_piscicole ON hfpi_fpi_id=fpi_id
LEFT JOIN bdoe.franchissement_piscicole_bdoe ON dfp_fpi_id=fpi_id


UNION ALL 

SELECT fpi_ref_id AS ouv_id,
	  'anguille' AS species,
      fpi_id,
      CASE WHEN fpi_fty_id IS NULL THEN FALSE 
      else fpi_fty_id IN (1,4,8,7,2,6) 
      END AS po_presence_pass,
      COALESCE(dfp_date_mes,(hfpi_date_metier||'-12-31')::date) AS date_passe
FROM roe.franchissement_piscicole 
LEFT JOIN roe.historique_franch_piscicole ON hfpi_fpi_id=fpi_id
LEFT JOIN bdoe.franchissement_piscicole_bdoe ON dfp_fpi_id=fpi_id 

UNION ALL 

SELECT fpi_ref_id AS ouv_id,
	  'alose' AS species,
      fpi_id,
      CASE WHEN fpi_fty_id IS NULL THEN FALSE 
      else fpi_fty_id IN (1,8,5,0,7,2,6) 
      END AS po_presence_pass,
      COALESCE(dfp_date_mes,(hfpi_date_metier||'-12-31')::date) AS date_passe
FROM roe.franchissement_piscicole 
LEFT JOIN roe.historique_franch_piscicole ON hfpi_fpi_id=fpi_id
LEFT JOIN bdoe.franchissement_piscicole_bdoe ON dfp_fpi_id=fpi_id

UNION ALL 

SELECT fpi_ref_id AS ouv_id,
	  'lamproie' AS species,
      fpi_id,
      CASE WHEN fpi_fty_id IS NULL THEN FALSE 
      else fpi_fty_id IN (1,8,5,0,7,2,6) 
      END AS po_presence_pass,     
      COALESCE(dfp_date_mes,(hfpi_date_metier||'-12-31')::date) AS date_passe
FROM roe.franchissement_piscicole 
LEFT JOIN roe.historique_franch_piscicole ON hfpi_fpi_id=fpi_id
LEFT JOIN bdoe.franchissement_piscicole_bdoe ON dfp_fpi_id=fpi_id

UNION ALL 

SELECT fpi_ref_id AS ouv_id,
	  'saumon' AS species,
      fpi_id,
      CASE WHEN fpi_fty_id IS NULL THEN FALSE 
      else fpi_fty_id IN (1,8,5,0,7,2,6) 
      END AS po_presence_pass,   
      COALESCE(dfp_date_mes,(hfpi_date_metier||'-12-31')::date) AS date_passe
FROM roe.franchissement_piscicole 
LEFT JOIN roe.historique_franch_piscicole ON hfpi_fpi_id=fpi_id
LEFT JOIN bdoe.franchissement_piscicole_bdoe ON dfp_fpi_id=fpi_id
),

-- NOTE on utilise pas ICE type_pass (voir fin du script pour chunk enlevé pour lisibilité du code)

-- JOINTURE DE LA TABLE PRECEDENTE AVEC LES ESPECES pour récupérer gre_id (en vrai sert à rien parce qu'on fait plus ICE...)
dbeel_type_pap AS (
SELECT DISTINCT dbeel_especes.*,  fpi_id, po_presence_pass, date_passe
FROM dbeel_especes
LEFT JOIN roe_type_pap ON 'ROE' || ouv_id = id_original 
AND dbeel_especes.species = roe_type_pap.species
WHERE fpi_id IS NOT NULL 
), --456 068 --> 15541 (not null)

--SELECT * FROM dbeel_type_pap --15541
-- JOINTURE AVEC physical obstruction en fonction du code ouvrage et de la date_passe 
join_with_physical_obstruction_date AS(
SELECT ob_id,dbeel_type_pap.* FROM dbeel_type_pap JOIN 
montepomi.dbeel_physical_obstruction ON
dbeel_physical_obstruction.ob_op_id = dbeel_type_pap.op_id AND
date_passe < ob_ending_date
), -- 2703

join_with_physical_obstruction_null AS(
SELECT ob_id,dbeel_type_pap.* FROM dbeel_type_pap JOIN 
montepomi.dbeel_physical_obstruction ON
dbeel_physical_obstruction.ob_op_id = dbeel_type_pap.op_id 
WHERE date_passe IS NULL)

SELECT * FROM join_with_physical_obstruction_date 
   UNION 
SELECT * FROM join_with_physical_obstruction_null
); -- END CREATE TABLE 279610

--SELECT * FROM join_with_physical_obstruction where id_original='ROE37672'
--SELECT id_original, count(*) FROM join_with_physical_obstruction GROUP BY 1 ORDER BY 2 DESC  
--SELECT * FROM montepomi.dbeel_physical_obstruction_pass_species WHERE op_id='3ebf4db1-3a67-4191-ae6d-4185259c967d'
--SELECT * FROM montepomi.dbeel_view_pass WHERE op_id='3ebf4db1-3a67-4191-ae6d-4185259c967d'

-- A la même période il peut y avoir plusieurs passes, 
-- si une passe est franchissable et l'autre non, on choisi la franchissable

/*
 * ------------------------------------------
 * VUE POUR LES PASSES 
 * ------------------------------------------
 * (On choisit qu'il y ait une passe si il y a deux passes, 
 * l'une qui fonctionne, l'autre pas, à la même période)
 */

DROP VIEW IF EXISTS  montepomi.dbeel_view_pass CASCADE;
CREATE VIEW montepomi.dbeel_view_pass AS (

WITH 

ordered AS (SELECT dbeel_physical_obstruction_pass_species.*
FROM montepomi.dbeel_physical_obstruction_pass_species
ORDER BY ob_id, species, po_presence_pass DESC) --15 019

SELECT DISTINCT ON (ob_id, species, po_presence_pass) * FROM ordered --14 350
);


-- SELECT * FROM montepomi.dbeel_view_pass where op_id='3ebf4db1-3a67-4191-ae6d-4185259c967d'
-- SELECT * FROM montepomi.dbeel_physical_obstruction_pass_species WHERE id_original ='ROE105'

/*
 * ------------------------------------------
 * TABLE SCORES 
 * ------------------------------------------
 * ci dessous on créee deux tableaux, l'un provenant de ICE un de BDOE avec les 
 * mêmes colonnes id_original, species, score, date_releve, libelle_score, et source_score (soit ice soit bdoe)
 * Pour les expertises dont la date est nulle dans BDOE, on va joindre avec toutes les observations 
 * de dbeel_obstruction_places quelle que soit la date
 * Pour un ob_id (une période donnée) OBJECT n va avoir plusieurs notes d'expertise, par espèces,
 * Mais aussi correspondant potentiellement à différentes dates et différentes sources (soit bdoe soit ice)
 * il va falloir choisir, on va prendre ICE puis bdoe et on prend pour toute la période l'expertise la plus récente
 */


DROP TABLE IF EXISTS montepomi.dbeel_physical_obstruction_score_species CASCADE;
CREATE TABLE montepomi.dbeel_physical_obstruction_score_species AS (
WITH 		
-- pour le ICE on ne garde qu'un seul enregistrement PAD our toutes les parties d'obstacle
ice_mesure AS (
SELECT DISTINCT ON(ooi_ref_id,opi_date_releve,cipo_gre_id)
'ROE'||ooi_ref_id AS id_original,
CASE WHEN cipo_gre_id = 1 THEN 'saumon'
WHEN cipo_gre_id = 3 THEN 'alose'
WHEN cipo_gre_id = 5 THEN 'lamproie'
WHEN cipo_gre_id = 19 THEN 'anguille'
WHEN cipo_gre_id = 20 THEN 'civelle'
END AS species,
cipo_cli_id AS score, 
opi_date_releve AS date_releve, 
--cipo_pao_id,
cli_libelle AS libelle_score,
'ice' AS source_note
FROM ice.classe_ice_partie_obstacle
JOIN ice.classe_ice ON cipo_cli_id = cli_id
LEFT JOIN ice.partie_obstacle ON pao_id = cipo_pao_id 
LEFT JOIN ice.operation_ice ON pao_opi_id = opi_id
LEFT JOIN ice.obstacle_operation_ice ON opi_ooi_id = ooi_id
LEFT JOIN ice.structure_obstacle ON sto_pao_id=pao_id
WHERE cipo_cli_id IS NOT NULL AND cipo_gre_id IN (1,3,5,19,20)
ORDER BY ooi_ref_id,opi_date_releve,cipo_gre_id,
				    CASE WHEN sto_tso_id=5 THEN 2 -- ouvrage à marée
	               WHEN sto_tso_id=1 THEN 3 -- seuil
	               WHEN sto_tso_id=3 THEN 4 -- vannage
	               WHEN sto_tso_id=2 THEN 5	-- seuil en enrochement	
	               WHEN sto_tso_id=7 THEN 6 -- prise d'eau 
	               WHEN sto_tso_id=4 THEN 7 -- ouvrage routier
	               WHEN sto_tso_id=6 THEN 1	-- dispositif de franchissement piscicole             
	               WHEN sto_tso_id=8 THEN 8 -- voie sur berge
	               END 
),
--SELECT * FROM ice_mesure --27614

bdoe_expertise AS (
SELECT 'ROE'||exm_ouv_id AS id_original, 
CASE WHEN exm_esp_id = '3' THEN 'alose'
WHEN exm_esp_id = '5' THEN 'anguille'
WHEN exm_esp_id = '34' THEN 'lamproie'
WHEN exm_esp_id = '45' THEN 'saumon' END AS species,
exm_not_id AS score, 
exm_date AS date_releve,
not_libelle AS libelle_score,
'bdoe' AS source_note
FROM bdoe.expertise_montaison
LEFT JOIN bdoe.note ON not_id = exm_not_id
WHERE exm_esp_id in ('3','5','45','34')), --10 564

bdoe_ice_mesure AS (
SELECT * FROM bdoe_expertise
UNION ALL
SELECT * FROM ice_mesure), -- 38178


join_with_physical_obstruction_date AS(
SELECT 
ob_id,
bdoe_ice_mesure.*
FROM bdoe_ice_mesure 
JOIN montepomi.dbeel_obstruction_place ON dbeel_obstruction_place.id_original = bdoe_ice_mesure.id_original 
JOIN montepomi.dbeel_physical_obstruction ON 
  dbeel_physical_obstruction.ob_op_id= op_id AND
  date_releve between ob_starting_date AND ob_ending_date -1 
) ,
--SELECT * FROM join_with_physical_obstruction_date --2275 valeurs avec date non nulle.

join_with_physical_obstruction_null AS(
SELECT 
ob_id,
bdoe_ice_mesure.*
FROM bdoe_ice_mesure 
JOIN montepomi.dbeel_obstruction_place ON dbeel_obstruction_place.id_original = bdoe_ice_mesure.id_original 
JOIN montepomi.dbeel_physical_obstruction ON 
  dbeel_physical_obstruction.ob_op_id= op_id 
WHERE date_releve IS NULL),
--SELECT * FROM join_with_physical_obstruction_null; --9137 lignes dans bdoe ou la date n'est pas renseignée

expertise_ouv_esp AS (
SELECT * FROM
join_with_physical_obstruction_date 
UNION 
SELECT * FROM
join_with_physical_obstruction_null
)
SELECT * FROM expertise_ouv_esp 
); -- END CREATE TABLE --11399 

ALTER TABLE montepomi.dbeel_physical_obstruction_score_species ADD COLUMN score_homogene integer;
--DROP score_homogene FROM montepomi.dbeel_physical_obstruction_score_species
update montepomi.dbeel_physical_obstruction_score_species
set score_homogene =
	CASE when source_note = 'bdoe' THEN 
	case 
	when score = 0 then 4
	when score = 1 THEN 4
	WHEN score = 2 then 3
	WHEN score = 3 THEN 2
	WHEN score = 4 THEN 2
	WHEN score = 5 THEN 1
	end
	else score 
end;

ALTER TABLE montepomi.dbeel_physical_obstruction_score_species ADD COLUMN libelle_homogene varchar;
update montepomi.dbeel_physical_obstruction_score_species
set libelle_homogene =
	CASE 
	when score_homogene = 1 THEN 'Barrière totale'
	WHEN score_homogene = 2 then 'Barrière partielle à impact majeur'
	WHEN score_homogene = 3 THEN 'Barrière partielle à impact significatif'
	WHEN score_homogene = 4 THEN 'Barrière franchissable à impact limité'
end;

/*
 *  ------------------------------------------
 * VUE POUR LES SCORES 
  * ------------------------------------------ 
 * On choisit d'abord ICE puis BDOE
 * 
 */

DROP VIEW IF EXISTS montepomi.dbeel_view_score CASCADE;
CREATE VIEW montepomi.dbeel_view_score AS (
with
ordered as( 
SELECT * FROM montepomi.dbeel_physical_obstruction_score_species
order by ob_id, species, source_note desc -- we take ICE then bdoe
)
select distinct on (ob_id, species) * from ordered
); --11341


-- #17 summary of expertise data in ICE and Bdoe at the scale of fishway
-- On va chercher les expertises ICE par passes a poissons et espèces
-- A ce stade on ne sait pas comment joindre les deux tableaux car l'id des dispositifs de 
-- franchissement ice et roe ne sont pas les mêmes
 
--WITH note_ice_pap AS (
--SELECT dfp_id, cipo_gre_id,cipo_cli_id, cli_code, cli_libelle, gre_libelle
--FROM ice.dispositif_franchissement_piscicole
--LEFT JOIN ice.structure_obstacle ON structure_obstacle.sto_id=dispositif_franchissement_piscicole.dfp_id
--LEFT JOIN ice.partie_obstacle ON pao_id=sto_pao_id
--LEFT JOIN ice.classe_ice_partie_obstacle ON cipo_pao_id=pao_id
--LEFT JOIN ice.classe_ice ci ON cli_id=cipo_cli_id
--LEFT JOIN ice.groupe_espece ON gre_id=cipo_gre_id
--WHERE cipo_gre_id IN (1,3,5,19,20))--115
--
--
--SELECT DISTINCT dbeel_obstruction_place.op_id,
--franchissement_piscicole.fpi_ref_id AS ouv_id, 
--franchissement_piscicole.fpi_id AS pap_id,
--franchissement_piscicole_type.fty_code::numeric AS cdtypedisp, 
--franchissement_piscicole_type.fty_nom,
--dfp_date_mes AS date_creation_pap
--FROM montepomi.dbeel_obstruction_place
--LEFT JOIN roe.franchissement_piscicole ON 'ROE'||franchissement_piscicole.fpi_ref_id=id_original  
--LEFT JOIN roe.franchissement_piscicole_type on fpi_fty_id=fty_id
--LEFT JOIN bdoe.franchissement_piscicole_bdoe ON dfp_ouv_id=fpi_ref_id
--LEFT JOIN note_ice_pap ON dfp_id = ;--92146
          



-- Ci dessous non gardé, la récupération des scores depuis ICE (à integrer dans   montepomi.dbeel_physical_obstruction_pass_species pour voir)
/*    
ice_type_pap AS (

SELECT DISTINCT obstacle_operation_ice.ooi_ref_id, 'alose' AS species,
      TRUE::boolean AS po_presence_pass,
          max(operation_ice.opi_date_releve)  -- On fait le max car juste l'ouvrage 113393 a 2 dates avec les même types de passes 
    FROM dbeel_especes
    LEFT JOIN ice.obstacle_operation_ice ON id_original = 'ROE' || ooi_ref_id 
    LEFT JOIN ice.operation_ice ON opi_ooi_id = ooi_id
    LEFT JOIN ice.partie_obstacle ON pao_opi_id = opi_id
    LEFT JOIN ice.structure_obstacle ON sto_pao_id = pao_id
    LEFT JOIN ice.dispositif_franchissement_piscicole ON
      sto_id = dfp_id
      WHERE dfp_tdfp_id IN (1, 2, 3, 4, 5, 6, 7) 
      GROUP BY obstacle_operation_ice.ooi_ref_id
      
UNION ALL 

SELECT DISTINCT obstacle_operation_ice.ooi_ref_id, 'saumon' AS species,
      TRUE::boolean AS po_presence_pass,
          max(operation_ice.opi_date_releve)
    FROM dbeel_especes
    LEFT JOIN ice.obstacle_operation_ice ON id_original = 'ROE' || ooi_ref_id 
    LEFT JOIN ice.operation_ice ON opi_ooi_id = ooi_id
    LEFT JOIN ice.partie_obstacle ON pao_opi_id = opi_id
    LEFT JOIN ice.structure_obstacle ON sto_pao_id = pao_id
    LEFT JOIN ice.dispositif_franchissement_piscicole ON
      sto_id = dfp_id
      WHERE dfp_tdfp_id IN (1, 2, 3, 4, 5, 6, 7)
      GROUP BY obstacle_operation_ice.ooi_ref_id
UNION ALL

SELECT DISTINCT obstacle_operation_ice.ooi_ref_id, 'lamproie' AS species,
      TRUE::boolean AS po_presence_pass,
          max(operation_ice.opi_date_releve)
    FROM dbeel_especes
    LEFT JOIN ice.obstacle_operation_ice ON id_original = 'ROE' || ooi_ref_id 
    LEFT JOIN ice.operation_ice ON opi_ooi_id = ooi_id
    LEFT JOIN ice.partie_obstacle ON pao_opi_id = opi_id
    LEFT JOIN ice.structure_obstacle ON sto_pao_id = pao_id
    LEFT JOIN ice.dispositif_franchissement_piscicole ON
      sto_id = dfp_id
      WHERE dfp_tdfp_id IN (1, 2, 3, 4, 5, 6, 7)  
      GROUP BY obstacle_operation_ice.ooi_ref_id
      
UNION ALL 

SELECT DISTINCT obstacle_operation_ice.ooi_ref_id, 'anguille' AS species,
      TRUE::boolean AS po_presence_pass,
          max(operation_ice.opi_date_releve)
    FROM dbeel_especes
    LEFT JOIN ice.obstacle_operation_ice ON id_original = 'ROE' || ooi_ref_id 
    LEFT JOIN ice.operation_ice ON opi_ooi_id = ooi_id
    LEFT JOIN ice.partie_obstacle ON pao_opi_id = opi_id
    LEFT JOIN ice.structure_obstacle ON sto_pao_id = pao_id
    LEFT JOIN ice.dispositif_franchissement_piscicole ON
      sto_id = dfp_id
      WHERE dfp_tdfp_id IN (1, 2, 5, 6, 7, 8)
      GROUP BY obstacle_operation_ice.ooi_ref_id),
*/ 

