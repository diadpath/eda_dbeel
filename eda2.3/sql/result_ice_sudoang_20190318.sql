-- FOURNIR UNE TABLE ROE SPATIALISEE DANS LE SCHEMA ICE
DROP TABLE IF EXISTS ice.projection_obstacle CASCADE ;
CREATE TABLE ice.projection_obstacle AS 

SELECT 
ref_id, 
ref_id_national,
ref_position_l93 AS "Position",
st_x(ref_position_l93) AS "Coordonnée X",
st_y(ref_position_l93) AS "Coordonnée Y",
'Lambert93'::text AS "Projection"
  
FROM 
  roe.obstacle_referentiel ;

-- FOURNIR UNE 2NDE VUE ICE AVEC TOUS LES RESULTATS DE DIAGNOSTICS
CREATE OR REPLACE VIEW ice.resultats AS 

SELECT 
	operationIce.opi_id AS "Identifiant ICE",
	to_char(operationIce.opi_date_releve, 'DD/MM/YYYY') AS "Date du relevé",
	obstacleReferentiel.ref_id_national AS "Code ROE",
	obstacleReferentiel.ref_nom AS "Nom ROE",
	--st_x(obstacleReferentiel.ref_position_l93) AS "Coordonnée X",
	-- st_y(obstacleReferentiel.ref_position_l93) AS "Coordonnée Y",
	-- 'Lambert93' AS "Projection",
    obstacleReferentiel.ref_departement AS "Departement",
    structure.str_libelle AS "Organisme",
    controleDonnee.cod_libelle AS "Contrôle de données",
    qualificationDonnee.qud_libelle AS "Niveau de qualification",
    hydrologie.hyd_libelle AS "Hydrologie",
    operationIce.opi_hydrologie_debit AS "Débit",
    operationIce.opi_hydrologie_echelle_limni AS "Présence d'une échelle limnimétrique",
    operationIce.opi_hydrologie_val_echelle_limni AS "Valeur de l'échelle limnimétrique",
    operationIce.opi_hauteur_chute AS "Hauteur de chute globale",
    operationIce.opi_cote_point_reference AS "Cote du point de référence",
    operationIce.opi_description_point_reference AS "Description du point de référence",
    groupeEspece.gre_code AS "Code groupe d'espèces cibles",
    groupeEspece.gre_libelle AS "Groupe d'espèces cibles",
    partieObstacle.pao_ordre + 1 AS "Numéro partie obstacle",
    classeIcePartie.cli_code AS "Code classe",
    classeIcePartie.cli_code ||' - '|| classeIcePartie.cli_libelle AS "Classe ICE partie obstacle",
    structureObstacle.sto_ordre + 1 AS "Numéro structure obstacle",
    typeStructureObstacle.tso_libelle AS "Type structure obstacle",
    typeSeuil.tys_libelle AS "Inclinaison si seuil",
    typeDispositifFranchissementPiscicole.tdfp_libelle AS "Type de dispositif de franchissement piscicole",
    modeDeplacement.mod_libelle AS "Mode déplacement",
    classeIceCalcul.cli_code ||' - '|| classeIceCalcul.cli_libelle AS "Classe ICE / Pré-diagnostic de la structure",
  	etapeCalculIce.eci_libelle AS "Etape",
  	regleCalculIce.rci_libelle AS "Règle",
  	regleCalculIce.rci_valeur_testee AS "Valeur testée",
  	regleCalculIce.rci_operateur AS "Opérateur",
  	regleCalculIce.rci_valeur_seuil AS "Valeur seuil",
  	regleCalculIce.rci_borne_inferieure AS "Borne inférieure",
  	regleCalculIce.rci_borne_superieure AS "Borne supérieure",
  	regleCalculIce.rci_unite AS "Unité",
  	classeIceEtape.cli_code ||' - '|| classeIceEtape.cli_libelle AS "Classe ICE / Pré-diagnostic de l'étape"
  	
FROM ice.operation_ice AS operationIce
LEFT JOIN ice.hydrologie ON operationIce.opi_hyd_id = hydrologie.hyd_id
LEFT JOIN geobs.structure ON operationIce.opi_str_id_auteur_creation = structure.str_id
LEFT JOIN ice.controle_donnee AS controleDonnee ON operationIce.opi_cod_id = controleDonnee.cod_id
LEFT JOIN ice.qualification_donnee AS qualificationDonnee ON operationIce.opi_qud_id = qualificationDonnee.qud_id

INNER JOIN ice.obstacle_operation_ice AS obstacleOperationIce ON obstacleOperationIce.ooi_id = operationIce.opi_ooi_id
INNER JOIN roe.obstacle_referentiel AS obstaclereferentiel ON obstacleReferentiel.ref_id = obstacleOperationIce.ooi_ref_id

LEFT JOIN ice.partie_obstacle AS partieObstacle ON partieObstacle.pao_opi_id = operationIce.opi_id 

LEFT JOIN ice.structure_obstacle AS structureObstacle ON structureObstacle.sto_pao_id = partieObstacle.pao_id
LEFT JOIN ice.type_structure_obstacle AS typeStructureObstacle ON structureObstacle.sto_tso_id= typeStructureObstacle.tso_id
LEFT JOIN ice.seuil AS structureSeuil ON structureObstacle.sto_id= structureSeuil.seu_id
LEFT JOIN ice.type_seuil AS typeSeuil ON structureSeuil.seu_tys_id= typeSeuil.tys_id
LEFT JOIN ice.dispositif_franchissement_piscicole AS dispositifFranchissementPiscicole ON structureObstacle.sto_id= dispositifFranchissementPiscicole.dfp_id
LEFT JOIN ice.type_dispositif_franchissement_piscicole AS typeDispositifFranchissementPiscicole ON dispositifFranchissementPiscicole.dfp_tdfp_id= typeDispositifFranchissementPiscicole.tdfp_id

LEFT JOIN ice.calcul_ice AS calculIce ON calculIce.cai_sto_id = structureObstacle.sto_id
LEFT JOIN ice.groupe_espece AS groupeEspece ON calculIce.cai_gre_id = groupeEspece.gre_id
LEFT JOIN ice.mode_deplacement AS modeDeplacement ON calculIce.cai_mod_id= modeDeplacement.mod_id
LEFT JOIN ice.classe_ice AS classeIceCalcul ON classeIceCalcul.cli_id= calculIce.cai_cli_id

LEFT JOIN ice.classe_ice_partie_obstacle AS classeIcePartieObstacle ON partieObstacle.pao_id = classeIcePartieObstacle.cipo_pao_id AND calculIce.cai_gre_id = classeIcePartieObstacle.cipo_gre_id
LEFT JOIN ice.classe_ice AS classeIcePartie ON classeIcePartie.cli_id= classeIcePartieObstacle.cipo_cli_id


LEFT JOIN ice.etape_calcul_ice AS etapeCalculIce ON etapeCalculIce.eci_cai_id = calculIce.cai_id
LEFT JOIN ice.classe_ice AS classeIceEtape ON classeIceEtape.cli_id= etapeCalculIce.eci_cli_id

LEFT JOIN ice.regle_calcul_ice AS regleCalculIce ON regleCalculIce.rci_eci_id = etapeCalculIce.eci_id


ORDER BY operationIce.opi_id ASC, partieObstacle.pao_ordre ASC, structureObstacle.sto_ordre ASC, calculIce.cai_id ASC, etapeCalculIce.eci_ordre ASC, regleCalculIce.rci_ordre ASC ;

-- FOURNIR UNE 3EME VUE SPATIALISEE AVEC l'INTEGRALITE DES RESULTATS (LES INDENTATIONS PERMETTENT DE DESCENDRE PLUS FINEMENT DANS LE RESULTAT, JUSQU'A LA STRUCTURE VOIRE JUSQU'A L'ETAPE : PARTIE D'OBSTACLE > STRUCTURES > STRUCTURE > ETAPES D'EVALUATION DE LA STRUCTURE > ETAPE DE L'ARBRE DECISIONNEL CORRESPONDANT)

CREATE OR REPLACE VIEW ice.resultats_complets AS

SELECT 
  resultats."Identifiant ICE", 
  resultats."Date du relevé", 
  resultats."Code ROE", 
  resultats."Nom ROE", 
  projection_obstacle."Coordonnée X",
  projection_obstacle."Coordonnée Y",
  projection_obstacle."Projection",
  projection_obstacle."Position",
  resultats."Departement",
  resultats."Description du point de référence", 
  resultats."Cote du point de référence", 
  resultats."Hauteur de chute globale", 
  resultats."Valeur de l'échelle limnimétrique", 
  resultats."Présence d'une échelle limnimétrique", 
  resultats."Débit", 
  resultats."Hydrologie", 
  resultats."Niveau de qualification", 
  resultats."Contrôle de données", 
  resultats."Organisme",
  resultats."Code groupe d'espèces cibles", 
  resultats."Groupe d'espèces cibles", 
  resultats."Mode déplacement",
  resultats."Numéro partie obstacle",
--   resultats."Numéro structure obstacle",
--   resultats."Inclinaison si seuil", 
--   resultats."Type structure obstacle",
--   resultats."Type de dispositif de franchissement piscicole", 
--   resultats."Classe ICE / Pré-diagnostic de l'étape",
--   resultats."Etape",
--   resultats."Règle",  
--   resultats."Valeur testée",
--   resultats."Opérateur",
--   resultats."Valeur seuil",
--   resultats."Borne supérieure", 
--   resultats."Borne inférieure",
--   resultats."Unité", 
--   resultats."Classe ICE / Pré-diagnostic de la structure",
  resultats."Code classe",
  resultats."Classe ICE partie obstacle" 
    
FROM 
  ice.resultats, 
  ice.projection_obstacle
WHERE 
  projection_obstacle.ref_id_national = resultats."Code ROE"

 GROUP BY 
  resultats."Identifiant ICE", 
  resultats."Date du relevé", 
  resultats."Code ROE", 
  resultats."Nom ROE", 
  projection_obstacle."Coordonnée X",
  projection_obstacle."Coordonnée Y",
  projection_obstacle."Projection",
  projection_obstacle."Position",
  resultats."Departement",
  resultats."Description du point de référence", 
  resultats."Cote du point de référence", 
  resultats."Hauteur de chute globale", 
  resultats."Valeur de l'échelle limnimétrique", 
  resultats."Présence d'une échelle limnimétrique", 
  resultats."Débit", 
  resultats."Hydrologie", 
  resultats."Niveau de qualification", 
  resultats."Contrôle de données", 
  resultats."Organisme",
  resultats."Code groupe d'espèces cibles", 
  resultats."Groupe d'espèces cibles", 
  resultats."Mode déplacement",
  resultats."Numéro partie obstacle",
  resultats."Numéro structure obstacle",
  resultats."Inclinaison si seuil", 
  resultats."Type structure obstacle",
  resultats."Type de dispositif de franchissement piscicole", 
--   resultats."Classe ICE / Pré-diagnostic de l'étape",
--   resultats."Etape",
--   resultats."Règle",  
--   resultats."Valeur testée",
--   resultats."Opérateur",
--   resultats."Valeur seuil",
--   resultats."Borne supérieure", 
--   resultats."Borne inférieure",
--   resultats."Unité", 
--   resultats."Classe ICE / Pré-diagnostic de la structure",
  resultats."Code classe",
  resultats."Classe ICE partie obstacle" ;

-- EXEMPLE D'EXTRACTIONS CIBLEES
-- 1er Test : j'extrais pour le groupe 1 la classe ICE la plus pénalisante à l'ouvrage
CREATE OR REPLACE VIEW ice.export_resultats_gr1_min AS SELECT 

  "Identifiant ICE", 
  "Date du relevé", 
  "Code ROE", 
  "Nom ROE", 
  "Coordonnée X",
  "Coordonnée Y",
  "Projection",
  "Position",
  "Departement",
  "Description du point de référence", 
  "Cote du point de référence", 
  "Hauteur de chute globale", 
  "Valeur de l'échelle limnimétrique", 
  "Présence d'une échelle limnimétrique", 
  "Débit", 
  "Hydrologie", 
  "Niveau de qualification", 
  "Contrôle de données", 
  "Organisme",
  "Code groupe d'espèces cibles", 
  "Groupe d'espèces cibles", 
  "Mode déplacement",
--   "Numéro partie obstacle",
--   "Numéro structure obstacle",
--   "Inclinaison si seuil", 
--   "Type structure obstacle",
--   "Type de dispositif de franchissement piscicole", 
--   "Classe ICE / Pré-diagnostic de l'étape",
--   "Etape",
--   "Règle",  
--   "Valeur testée",
--   "Opérateur",
--   "Valeur seuil",
--   "Borne supérieure", 
--   "Borne inférieure",
--   "Unité", 
--   "Classe ICE / Pré-diagnostic de la structure",
   min("Code classe") AS "Code classe",
  "Classe ICE partie obstacle"

 FROM ice.resultats_complets WHERE "Code groupe d'espèces cibles" LIKE '1' AND "Code classe" IS NOT NULL

 GROUP BY 

   "Identifiant ICE", 
  "Date du relevé", 
  "Code ROE", 
  "Nom ROE", 
  "Coordonnée X",
  "Coordonnée Y",
  "Projection",
  "Position",
  "Departement",
  "Description du point de référence", 
  "Cote du point de référence", 
  "Hauteur de chute globale", 
  "Valeur de l'échelle limnimétrique", 
  "Présence d'une échelle limnimétrique", 
  "Débit", 
  "Hydrologie", 
  "Niveau de qualification", 
  "Contrôle de données", 
  "Organisme",
  "Code groupe d'espèces cibles", 
  "Groupe d'espèces cibles", 
  "Mode déplacement",
--   "Numéro partie obstacle",
--   "Numéro structure obstacle",
--   "Inclinaison si seuil", 
--   "Type structure obstacle",
--   "Type de dispositif de franchissement piscicole", 
--   "Classe ICE / Pré-diagnostic de l'étape",
--   "Etape",
--   "Règle",  
--   "Valeur testée",
--   "Opérateur",
--   "Valeur seuil",
--   "Borne supérieure", 
--   "Borne inférieure",
--   "Unité", 
--   "Classe ICE / Pré-diagnostic de la structure",
  "Code classe",
  "Classe ICE partie obstacle" ;


 -- 2nd Test : j'extrais pour le groupe 1 la classe ICE la moins pénalisante à l'ouvrage
CREATE OR REPLACE VIEW ice.export_resultats_gr1_max AS SELECT 

  "Identifiant ICE", 
  "Date du relevé", 
  "Code ROE", 
  "Nom ROE", 
  "Coordonnée X",
  "Coordonnée Y",
  "Projection",
  "Position",
  "Departement",
  "Description du point de référence", 
  "Cote du point de référence", 
  "Hauteur de chute globale", 
  "Valeur de l'échelle limnimétrique", 
  "Présence d'une échelle limnimétrique", 
  "Débit", 
  "Hydrologie", 
  "Niveau de qualification", 
  "Contrôle de données", 
  "Organisme",
  "Code groupe d'espèces cibles", 
  "Groupe d'espèces cibles", 
  "Mode déplacement",
--   "Numéro partie obstacle",
--   "Numéro structure obstacle",
--   "Inclinaison si seuil", 
--   "Type structure obstacle",
--   "Type de dispositif de franchissement piscicole", 
--   "Classe ICE / Pré-diagnostic de l'étape",
--   "Etape",
--   "Règle",  
--   "Valeur testée",
--   "Opérateur",
--   "Valeur seuil",
--   "Borne supérieure", 
--   "Borne inférieure",
--   "Unité", 
--   "Classe ICE / Pré-diagnostic de la structure",
   max("Code classe") AS "Code classe",
  "Classe ICE partie obstacle"

 FROM ice.resultats_complets WHERE "Code groupe d'espèces cibles" LIKE '1' AND "Code classe" IS NOT NULL

 GROUP BY 

   "Identifiant ICE", 
  "Date du relevé", 
  "Code ROE", 
  "Nom ROE", 
  "Coordonnée X",
  "Coordonnée Y",
  "Projection",
  "Position",
  "Departement",
  "Description du point de référence", 
  "Cote du point de référence", 
  "Hauteur de chute globale", 
  "Valeur de l'échelle limnimétrique", 
  "Présence d'une échelle limnimétrique", 
  "Débit", 
  "Hydrologie", 
  "Niveau de qualification", 
  "Contrôle de données", 
  "Organisme",
  "Code groupe d'espèces cibles", 
  "Groupe d'espèces cibles", 
  "Mode déplacement",
--   "Numéro partie obstacle",
--   "Numéro structure obstacle",
--   "Inclinaison si seuil", 
--   "Type structure obstacle",
--   "Type de dispositif de franchissement piscicole", 
--   "Classe ICE / Pré-diagnostic de l'étape",
--   "Etape",
--   "Règle",  
--   "Valeur testée",
--   "Opérateur",
--   "Valeur seuil",
--   "Borne supérieure", 
--   "Borne inférieure",
--   "Unité", 
--   "Classe ICE / Pré-diagnostic de la structure",
  "Code classe",
  "Classe ICE partie obstacle" ;

 