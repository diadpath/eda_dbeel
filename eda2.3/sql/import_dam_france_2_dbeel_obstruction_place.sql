/*
 * 
 * PHYSICAL OBSTRUCTION INSERTION
 * 
 * 
 * The following table now makes full use of starting_date and ending_date
 * It will then be set from '1800-01-01'  to '2035-01-01' by default for any dams if no information on period is set 
 * but any event like pass construction, dam construction, arasement (the dam is completely removed),
 * derasement (the dam is partially destroyed), start of activity, end of activity will create a "period"
 * for the dam.
 * A height recorded at different times might be different but it will not create a "structural"
 * modification of the dam (check with OFB how an alteration of dam structure over time might later be integrated).
 */






DROP TABLE if exists montepomi.dbeel_physical_obstruction CASCADE;
CREATE TABLE montepomi.dbeel_physical_obstruction (
  --fishway_type INTEGER,
  --ouv_idnational TEXT,
  --2024 : ajout de ouv_id pour identifier plus facilement les ouvrages
  ouv_id integer,
  date_last_update date,
  author_last_update text,
  comment_update text,
  --esp_id integer, 
  ouv_avis_tech_global_id integer,
  ouv_date_avis date,
  ouv_conformite_montaison integer,
  ouv_conformite_devalaison integer,
  ouv_commentaire_chute_bdoe text,
  ouv_commentaire_avis_bdoe text,
  ouv_commentaires_bdoe text,
  ouv_commentaire_mesures_bdoe text,
  ref_commentaire_sous_type_roe text,
  h_chute_date_mesure date,
  source_h_chute varchar (30),
  ouv_type_evt varchar (30),
  commentaire_maj_h_chute TEXT,
  CONSTRAINT physical_obstruction_id PRIMARY KEY (ob_id),
  CONSTRAINT c_uk_ob_id_date UNIQUE(ob_id, ob_starting_date, ob_ending_date),
  CONSTRAINT c_nn_ob_starting_date CHECK (ob_starting_date IS NOT NULL),
  CONSTRAINT c_nn_ob_ending_date CHECK (ob_ending_date IS NOT NULL),
  CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id),
  CONSTRAINT fk_ob_origin FOREIGN KEY (ob_no_origin)REFERENCES dbeel_nomenclature.observation_origin (no_id) ,
  CONSTRAINT fk_ob_period FOREIGN KEY (ob_no_period) REFERENCES dbeel_nomenclature.period_type (no_id) ,
  CONSTRAINT fk_ob_type FOREIGN KEY (ob_no_type) REFERENCES dbeel_nomenclature.observation_type (no_id) ,
  --CONSTRAINT fk_po_obstruction_passability FOREIGN KEY (po_no_obstruction_passability)REFERENCES dbeel_nomenclature.obstruction_impact (no_id),
  CONSTRAINT fk_ot_obstruction_type FOREIGN KEY (ot_no_obstruction_type) REFERENCES dbeel_nomenclature.obstruction_type(no_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ot_mortality_type FOREIGN KEY (ot_no_mortality_type) REFERENCES dbeel_nomenclature.biological_characteristic_type(no_id) ON UPDATE CASCADE ON DELETE RESTRICT
  
) INHERITS(dbeel.physical_obstruction);


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
	               WHEN sto_tso_id=2 THEN 5	-- seuil en enrochement	
	               WHEN sto_tso_id=7 THEN 6 -- prise d'eau 
	               WHEN sto_tso_id=4 THEN 7 -- ouvrage routier
	               WHEN sto_tso_id=6 THEN 8	  -- dispositif de franchissement piscicole             
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
--SELECT count(*)  FROM selectionne_roe	--88743 --> 92253 (2023-04-11)
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
--SELECT * FROM hauteur_chute_tous  --59118
     

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
  -- AJOUT 2024 : les dates par défaut sont ajoutées aux evennements ouvrage
  -- avant on arrivait pas à avoir de hauteurs autres que ROE et les hauteurs
  -- ICE et bdoe étaient perdues
  UNION ALL
 SELECT ref_id AS ouv_id, 
'1800-01-01'::date AS date_evt, 
'date debut (defaut)' AS type_evt
 FROM roe.roesudo
  WHERE ref_date_construction_ouvrage IS NULL
  ORDER BY ouv_id, date_evt),
  
  
-- La premiere va de NULL a min, les suivantes vont de
-- date à date+1 dans le partition by. 
-- pour la première partie on veut tous les ouvrage avec
-- une date de début par défaut sauf ceux qui ont une date de construction d'ouvrage 
 -- LEAD OVER PARTITION BY VA CHERCHER LES VALEURS PAR DATE_EVT et par defaut sur la dernière ligne met 2023

ordre_periode AS (

SELECT ouv_id, 
type_evt, 
date_evt AS datedebut,
LEAD(date_evt, 1, '2035-01-01') -- ATTENTION SI MODIF 2035 ADAPT SCRIPT baseedariosriversegmetdam.R cumulated_dam_impact2 fntrans()
OVER (PARTITION BY ouv_id ORDER BY date_evt) AS datefin 
FROM date_evenement_all 
ORDER BY ouv_id, datedebut),

  
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
  date_atg.ouv_id, ouv_atg_id, ouv_date_avis, datedebut, datefin, type_evt
  FROM ordre_periode   
  LEFT JOIN date_atg  ON ordre_periode.ouv_id = date_atg.ouv_id  
  AND ouv_date_avis >= datedebut and ouv_date_avis < datefin
  ),
  
periode_nonatg AS (

  SELECT 
  ordre_periode.ouv_id, 
  NULL AS ouv_atg_id,
  NULL AS ouv_date_avis, 
  ordre_periode.datedebut, 
  ordre_periode.datefin,
  ordre_periode.type_evt
  FROM ordre_periode   
 
  EXCEPT
  
  SELECT 
  ordre_periode.ouv_id, 
  NULL::INTEGER AS ouv_atg_id, 
  NULL::date AS ouv_date_avis, 
  ordre_periode.datedebut, 
  ordre_periode.datefin,
  ordre_periode.type_evt
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
    
hauteur_chute_par_periode AS (

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
 AND date_mesure >= datedebut)
 
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
--SELECT * FROM hauteur_chute_par_periode
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
                                
--SELECT * FROM  ordered_hauteur_chute_par_periode --95632 (   92253 pour ouvrages distincts)
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
--SELECT * FROM height 
--where datedebut is not null;--6106
--SELECT count(*) FROM  height    -- 93736 lignes (2472 lignes d'ouvrage ajoutées avec des infos de période)
 
   
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
--JOIN	hauteur_chute_roe hh on hh.ouv_id=dou.doe_ouv_id
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
LEFT JOIN bdoe.avis_technique_global ON atg_id = ouv_atg_id), --114 314

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

INSERT INTO montepomi.dbeel_physical_obstruction(
ob_id,
--2024 : ajout ouv_id pour identifier plus facilement les ouvrages
ouv_id,
ob_no_origin,
ob_no_type,
ob_no_period,
ob_starting_date,
ob_ending_date,
ob_op_id,
ob_dp_id,
ot_no_obstruction_type,
ot_obstruction_number,
--ot_no_mortality_type,
--ot_no_mortality,
--po_no_obstruction_passability,
po_obstruction_height,
po_downs_pb,
--po_downs_water_depth,
--po_presence_eel_pass,
--po_method_perm_ev,
--po_date_presence_eel_pass,
--fishway_type,
--ouv_idnational,
date_last_update,
author_last_update,
comment_update,
mitigation_measure_no_id,
--esp_id,
--Champs insérés 2023
ouv_avis_tech_global_id,
ouv_date_avis,
ouv_conformite_montaison,
ouv_conformite_devalaison,
ouv_commentaire_chute_bdoe,
ouv_commentaire_avis_bdoe,
ouv_commentaires_bdoe,
ouv_commentaire_mesures_bdoe,
ref_commentaire_sous_type_roe,
h_chute_date_mesure,
source_h_chute,
ouv_type_evt,
commentaire_maj_h_chute
)

SELECT uuid_generate_v4() AS ob_id,
--2024 : ajout ouv_id pour identifier plus facilement les ouvrages
  o.ouv_id,
  11 AS ob_no_origin, -- raw data
  16 AS ob_no_type, -- obstruction
  74 AS ob_no_period, -- Unknown
  upa.datedebut AS ob_starting_date,
  upa.datefin AS ob_ending_date,
  -- NOTE In the building query when no event occurs for a dam, then both
  -- datedebut and datefin are NULL after joining and the coalesce fixes that case
  o.op_id AS ob_op_id,
  dp.dp_id AS ob_dp_id,
  h.obstruction_type_no_id AS ot_no_obstruction_type,-- physical
   1 AS ot_obstruction_number,
   --NULL AS ot_no_mortality_type, 
   --NULL AS ot_no_mortality,
   --po_no_obstruction_passability, 
  h.h_chute AS po_obstruction_height, 
  case when rd.po_downs_pb is null then false else rd.po_downs_pb end as po_downs_pb,
  --NULL AS po_downs_water_depth, 
  --po_presence_eel_pass, 
  --CASE WHEN po_no_obstruction_passability in (209,210,211,212,213,214) THEN 'ROE expertise 5 class'
  --     WHEN po_no_obstruction_passability in (287,288,289,290) THEN 'ICE'
  --     ELSE NULL END AS po_method_perm_ev, 
  --NULL AS po_date_presence_eel_pass, -- bullshit
  --fishway_type, 
  --ouv_idnational, 
  current_date AS date_last_update, 
  'Cédric, Marion & Laëtitia' AS author_last_update, 
  'montepomi jan 2024' AS comment_update, 
  ed.mitigationmeasureid AS mitigation_measure_no_id,
--esp_id,
--****** 2024 : Remplace case when sur ouv_avis_techçglobal_id par ouv_atg_id ******
--CASE WHEN ouv_avis_tech_global_id IS NULL THEN 2
--ELSE ouv_avis_tech_global_id END AS ouv_avis_tech_global_id,
upa.ouv_atg_id as ouv_avis_tech_global_id,
upa.ouv_date_avis,
acb.ouv_conformite_montaison,
acb.ouv_conformite_devalaison,
acb.ouv_commentaire_chute_bdoe,
acb.ouv_commentaire_avis_bdoe,
acb.ouv_commentaires_bdoe,
acb.ouv_commentaire_mesures_bdoe,
acr.ref_commentaire_sous_type_roe,
h.date_mesure as h_chute_date_mesure,
h.commentaire_h_chute as source_h_chute,
upa.type_evt as ouv_type_evt,
NULL::text AS commentaire_maj_h_chute
FROM 
  obstruction o
  LEFT JOIN unique_periode_atg upa ON upa.ouv_id = o.ouv_id
  LEFT JOIN height h on (h.ouv_id, h.datedebut,h.datefin)=(upa.ouv_id, upa.datedebut, upa.datefin) 
  LEFT JOIN reception_devalaison rd on rd.ouv_id=o.ouv_id  --po_downs_pb (boolean) OK pAS de doublons
  LEFT JOIN expertise_devalaison ed on ed.ouv_id=o.ouv_id 
  LEFT JOIN add_column_bdoe acb ON acb.ouv_id = o.ouv_id
  LEFT JOIN add_column_roe acr ON acr.ouv_id = o.ouv_id,
  dbeel.data_provider dp
  WHERE dp_name = 'Pierre Sagnes';
  --2024 : nous avons dégagé la clause AND qui empêche de récupérer toutes nos lignes
  -- et changé l'ordre de la requete car on perdait des périodes.
-- AND  obstruction_type_no_id IS NOT NULL;
 
--  select * from montepomi.dbeel_physical_obstruction where ouv_id=7783

  
 --SELECT count(*) FROM montepomi.dbeel_physical_obstruction  
--103309 1 m 54 serveur --> 109972 (Marion, Laetitia, Benjamin 31/03/23)
-- 93736 14/04/23
-- 93954 28/04/23
-- 93962 12/05/23
-- 93962 16/06/23
-- 93971 24/01/2024
-- 95384 25/01/2024 
-- 95386 26/01/2024 
  
-- correction des problèmes de hauteur mise par defaut (roe) pour les periodes sans hauteur datée  
-- si plusieurs périodes, et bdoe ou ice et pas arasement ou derasement on remplace roe par la valeur bdoe ou ice
--Si arasement ou derasement, et on a un bdoe ou un ice avant ou après, on applique cette valeur aux valeurs roe avant ou après


-- premier cas
-- si c'est derasement ou arasement et positif 
--et si valeur avant < à celle de dérasement ou nulle
-- et si c'est roe ou null mettre sur la période avant
-- on recherche les ouvrages ayant plusieurs periodes (dupl) 
-- parmis ceux là on selectionne les ouvrages dont un des évennements a été
-- dérasement ou arasement (dupl1, dupl2, dupl3), et pour lesquels la hauteur de chute 
-- était positive ou non nulle,
-- ensuite on selectionne les lignes qui ont arasement ou derasement et on le compare
-- aux lignes qui étaient avant en ordonnant sur datedebut datefin
-- et on met à jour les valeurs qui sont soit nulles soit inférieures


WITH dupl AS (
  select 
  count(*) OVER(PARTITION BY ob_op_id) AS n, *
  from montepomi.dbeel_physical_obstruction
),
dupl1 AS (
SELECT 
   CASE WHEN ouv_type_evt ='arasement' THEN 1
        WHEN ouv_type_evt ='derasement' THEN 1
        ELSE 0 END AS count_aradera,  
   CASE WHEN ouv_type_evt ='arasement' AND COALESCE(po_obstruction_height,0) >0  THEN 1
        WHEN ouv_type_evt ='derasement' AND COALESCE(po_obstruction_height,0) >0 THEN 1
        ELSE 0 END AS count_aradera_positif,  
   CASE WHEN source_h_chute ='bdoe' THEN 1
        WHEN source_h_chute ='ice' THEN 1
        ELSE 0 END AS count_bdoeice,             
* FROM dupl 
),
dupl2 AS (
SELECT sum(count_aradera) OVER(PARTITION BY ob_op_id) sumaradera,
       sum(count_aradera_positif) OVER(PARTITION BY ob_op_id) sumaradera_positif,
       sum(count_bdoeice) OVER(PARTITION BY ob_op_id) sumbdoeice,
*
FROM dupl1),
dupl3 AS (
SELECT 
ouv_id,
ob_id,
count_aradera,
ROW_NUMBER() OVER (PARTITION BY ouv_id ORDER BY ob_starting_date, ob_ending_date) ordre,
n,
ob_starting_date,
ob_ending_date,
h_chute_date_mesure,
po_obstruction_height,
source_h_chute,
ouv_type_evt
FROM dupl2
WHERE n >1 AND sumaradera_positif>=1 AND sumbdoeice>=1 
ORDER by ouv_id, ob_starting_date, ob_ending_date),
aradera AS (
SELECT ouv_id, po_obstruction_height AS height_aradera, ordre   FROM dupl3 WHERE count_aradera >0 ),
prev_aradera AS (
SELECT dupl3.*,height_aradera  FROM dupl3 JOIN aradera ON (
aradera.ouv_id = dupl3.ouv_id 
AND aradera.ordre > dupl3.ordre
AND aradera.height_aradera > coalesce(dupl3.po_obstruction_height,0) 
AND COALESCE(dupl3.source_h_chute, 'roe') = 'roe'
))
--SELECT count(ob_id) FROM prev_aradera GROUP BY ob_id
UPDATE montepomi.dbeel_physical_obstruction SET (po_obstruction_height, commentaire_maj_h_chute) =
(prev_aradera.height_aradera, 'There is positive value in arasement derasement occuring after this period, and the value in this period was lower than the value at arasement- derasement ('||coalesce(prev_aradera.po_obstruction_height::text, 'NULL')||') so it has been replaced' )
FROM prev_aradera
WHERE prev_aradera.ob_id = dbeel_physical_obstruction.ob_id; --164



-- todo si c'est derasement c'est zero

UPDATE montepomi.dbeel_physical_obstruction SET po_obstruction_height = 0
        WHERE ouv_type_evt ='derasement'; --1603


-- si il y a des null ou roe et que qu'il y a une ligne avant celle marquee arasement ou dérasement
--  qui est non nulle, on applique cette valeur aux lignes d'avant 
--  (on fera ça plus tard mais ici on est dans le cas arasement derasement)
-- On a regardé, pas vraiement de cas ou ça existe 
     
-- Dans le cas ou on a pas d'arasement ou derasement, et si il y a des valeurs NULLEs ou roe qui sont 
-- appliquées à des lignes, il faut récuperer les valeurs ICE ou bdoe et les utiliser        
        
        

WITH dupl AS (
  select 
  count(*) OVER(PARTITION BY ob_op_id) AS n, *
  from montepomi.dbeel_physical_obstruction
),
dupl1 AS (
SELECT 
   CASE WHEN ouv_type_evt ='arasement' THEN 1
        WHEN ouv_type_evt ='derasement' THEN 1
        ELSE 0 END AS count_aradera,  
   CASE WHEN source_h_chute ='bdoe' THEN 1
        WHEN source_h_chute ='ice' THEN 1
        ELSE 0 END AS count_bdoeice,             
* FROM dupl 
),
dupl2 AS (
SELECT sum(count_aradera) OVER(PARTITION BY ob_op_id) sumaradera,
       sum(count_bdoeice) OVER(PARTITION BY ob_op_id) sumbdoeice,
*
FROM dupl1),
dupl3 AS (
SELECT 
ouv_id,
ob_id,
ROW_NUMBER() OVER (PARTITION BY ouv_id ORDER BY ob_starting_date, ob_ending_date) ordre,
n,
ob_starting_date,
ob_ending_date,
h_chute_date_mesure,
po_obstruction_height,
source_h_chute,
ouv_type_evt
FROM dupl2
WHERE n >1 AND sumaradera =0 AND sumbdoeice>=1 
ORDER by ouv_id, ob_starting_date, ob_ending_date),
roe_bdoe AS (
  SELECT * FROM dupl3 WHERE source_h_chute IN ('bdoe','ice') ORDER BY
  ouv_id, CASE WHEN source_h_chute = 'ice' THEN 1
               WHEN source_h_chute = 'bdoe' THEN 2
               END
),
uq_roe_bdoe AS (
  SELECT DISTINCT ON (ouv_id) ouv_id, po_obstruction_height AS h_chute, source_h_chute AS source_h_chute_cor FROM roe_bdoe
),
correction AS (
 SELECT dupl3.*, h_chute,source_h_chute_cor  FROM uq_roe_bdoe INNER JOIN dupl3 ON dupl3.ouv_id = uq_roe_bdoe.ouv_id
 WHERE coalesce(source_h_chute, 'roe')='roe'
)
UPDATE montepomi.dbeel_physical_obstruction SET (po_obstruction_height, commentaire_maj_h_chute) =
(correction.h_chute, 'if there are null or roe values and there is a line before the one marked arasement or derasement which is non-null, this value is applied to the lines before it and we kept the source used for height replacement ('||source_h_chute_cor||')' )
FROM correction
WHERE correction.ob_id = dbeel_physical_obstruction.ob_id; --740 ouvrage sur lequels on met à jour la hauteur de chute
 
--select * from montepomi.dbeel_physical_obstruction dpo where commentaire_maj_h_chute~*'^if*.'
 

DROP MATERIALIZED VIEW IF EXISTS  montepomi.view_obstruction CASCADE;
CREATE MATERIALIZED VIEW montepomi.view_obstruction AS (
 SELECT dbeel_obstruction_place.op_id,
    dbeel_obstruction_place.op_gis_systemname,
    dbeel_obstruction_place.op_gis_layername,
    dbeel_obstruction_place.op_gislocation,
    dbeel_obstruction_place.op_placename,
    observation_place_type.no_name AS observation_place_type_name,
    dbeel_obstruction_place.op_op_id,
    dbeel_obstruction_place.the_geom,
    dbeel_obstruction_place.id_original,
    dbeel_obstruction_place.country,    
    dbeel_physical_obstruction.ob_id,
    dbeel_physical_obstruction.ob_no_origin,
    dbeel_physical_obstruction.ob_no_type,
    dbeel_physical_obstruction.ob_no_period,
    dbeel_physical_obstruction.ob_starting_date,
    dbeel_physical_obstruction.ob_ending_date,
    dbeel_physical_obstruction.ob_op_id,
    data_provider.dp_name,
    obstruction_type.no_code AS obstruction_type_code,
    obstruction_type.no_name AS obstruction_type_name,
    dbeel_physical_obstruction.ot_obstruction_number,
    --dbeel_physical_obstruction.ot_no_mortality_type,
    --dbeel_physical_obstruction.ot_no_mortality,
    --obstruction_impact.no_code AS obstruction_impact_code,
    --obstruction_impact.no_name AS obstruction_impact_name,
    dbeel_physical_obstruction.po_obstruction_height,
    dbeel_physical_obstruction.po_downs_pb,
    --dbeel_physical_obstruction.po_downs_water_depth,
    -- dbeel_physical_obstruction.po_presence_eel_pass,
    --dbeel_physical_obstruction.po_method_perm_ev,
    --dbeel_physical_obstruction.po_date_presence_eel_pass,
    --dbeel_physical_obstruction.po_turbine_number,
    --fishway_type.no_code AS fishway_type_code,
    --fishway_type.no_name AS fishway_type_name,
    downstream_mitigation_measure.no_name AS downstream_mitigation_measure_name,
    dbeel_physical_obstruction.ouv_avis_tech_global_id,
    dbeel_physical_obstruction.ouv_date_avis,
    dbeel_physical_obstruction.ouv_conformite_montaison,
    dbeel_physical_obstruction.ouv_conformite_devalaison,
  dbeel_physical_obstruction.ouv_commentaire_chute_bdoe,
  dbeel_physical_obstruction.ouv_commentaire_avis_bdoe,
  dbeel_physical_obstruction.ouv_commentaires_bdoe,
  dbeel_physical_obstruction.ouv_commentaire_mesures_bdoe,
  dbeel_physical_obstruction.ref_commentaire_sous_type_roe,
  dbeel_physical_obstruction.h_chute_date_mesure,
  dbeel_physical_obstruction.source_h_chute,
  dbeel_physical_obstruction.ouv_type_evt,
    'http://maps.google.fr/maps?q='||st_y(st_transform(the_geom,4326))||','||st_x(st_transform(the_geom,4326)) AS googlemapscoods
   FROM montepomi.dbeel_obstruction_place
   JOIN montepomi.dbeel_physical_obstruction ON dbeel_physical_obstruction.ob_op_id = dbeel_obstruction_place.op_id
   LEFT JOIN dbeel_nomenclature.observation_place_type ON op_no_observationplacetype=observation_place_type.no_id
   LEFT JOIN dbeel_nomenclature.obstruction_type ON obstruction_type.no_id=dbeel_physical_obstruction.ot_no_obstruction_type
   LEFT JOIN dbeel_nomenclature.obstruction_impact ON obstruction_impact.no_id= dbeel_physical_obstruction.po_no_obstruction_passability
  -- LEFT JOIN dbeel_nomenclature.fishway_type ON fishway_type.no_id= dbeel_physical_obstruction.fishway_type
   LEFT JOIN dbeel_nomenclature.downstream_mitigation_measure ON downstream_mitigation_measure.no_id= dbeel_physical_obstruction.mitigation_measure_no_id
   JOIN dbeel.data_provider ON ob_dp_id=dp_id)
; --  26/01/2024 : 95386 --103309 --montepomi : 93736= > 93962 => 95384




  
/*
 * requetes variées de comptage des duplicats
 * 


with counts as (
select count(*) as "N", comment_update from montepomi.dbeel_physical_obstruction group by comment_update),
counts_france AS (
select "N", substring(comment_update from position('Height' in comment_update) for 50) as type_height from counts where comment_update like '%initial%' order by "N" desc),
--select * from counts_france)
total AS (
SELECT sum("N") as "N", 'Height:Total'::text as type_height from counts_france)
SELECT type_height, "N" from counts_france UNION SELECT type_height, "N" FROM total


with find_duplicates AS (
SELECT  count (*)  over (partition by op_id),* FROM montepomi.dbeel_physical_obstruction 
Join  montepomi.dbeel_obstruction_place on ob_op_id=op_id
join roe.roesudo on dbeel_op_id = op_id )
SELECT * FROM find_duplicates WHERE count>1


SELECT DISTINCT on (ob_op_id) * FROM montepomi.dbeel_physical_obstruction 
Join  montepomi.dbeel_obstruction_place on ob_op_id=op_id
join roe.roesudo on dbeel_op_id = op_id ) 
*/

