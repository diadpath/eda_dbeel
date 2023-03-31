-----------------------------------------------------
-- script d'import des données BDOE, ICE, ROE
-- import_dam_france.sql
--  Cédric et Mathilde
-- @deprecated UTILISATION DU FICHIER SANDRE voir script R import_bdoe.R pour mise à jour des données BDOE et roe
-- 11/07/2019
-- Utilisation du dump Nettoyage des tables
-- 14/08/2020 test sur nouvelle version envoyée par Karl
-- 29/09/2022  Import nouvelle version geobs du 03/07/2022 voir script script/script_restore_geobs.sh
-- NOTE j'ai eu un pb de commit les nb affichés ne sont pas les bons !!!
/*
suppression des infos propriétaires

ALTER TABLE ice.obstacle_operation_ice DROP CONSTRAINT fk_obstacle_operation_ice_proprietaire;
DROP TABLE ice.proprietaire;
ALTER TABLE ice.obstacle_operation_ice DROP CONSTRAINT fk_obstacle_operation_ice_exploitant;
DROP TABLE ice.exploitant;
ALTER TABLE roe.obstacle_partenaire DROP COLUMN par_auteur_modification;
ALTER TABLE roe.obstacle_referentiel DROP COLUMN ref_auteur_confirmation;
ALTER TABLE roe.obstacle_referentiel DROP COLUMN ref_auteur_validation;
ALTER TABLE roe.obstacle_referentiel DROP COLUMN ref_auteur_creation;
ALTER TABLE roe.obstacle_referentiel DROP COLUMN ref_auteur_modification CASCADE;
ALTER TABLE ice.operation_ice DROP COLUMN opi_uti_auteur_creation;
ALTER TABLE ice.operation_ice DROP COLUMN opi_uti_auteur_modification;
ALTER TABLE ice.obstacle_operation_ice DROP COLUMN ooi_ooige_precision CASCADE;

DROP VIEW IF EXISTS bdoe.export_ouvrage;
CREATE OR REPLACE VIEW bdoe.export_ouvrage AS 
 SELECT ouv.ouv_id,
    ouv.ouv_arasement,
    ouv.ouv_arasement_date,
    ouv.ouv_derasement,
    ouv.ouv_derasement_date,
    ouv.ouv_commentaires,
    ouv.ouv_commentaire_mesures,
    ouv.ouv_atg_id,
    atg.atg_libelle,
    ouv.ouv_date_avis,
    ouv.ouv_avis_ope_id,
    ope.ope_libelle,
    ouv.ouv_avis_ope_precision,
    ouv.ouv_commentaire_avis,
    ouv.ouv_fichier_avis,
    ouv.ouv_debut_activite,
    ouv.ouv_fin_activite,
    ouv.ouv_vdr_id,
    vad.vdr_libelle,
    ouv.ouv_debit_reserve,
    ouv.ouv_debit_montaison,
    ouv.ouv_debit_devalaison,
    ouv.ouv_debit_maximal,
    ouv.ouv_debit_commentaire,
    ouv.ouv_longueur_troncon,
    ouv.ouv_ecartement_grille,
    ouv.ouv_cote_basse,
    ouv.ouv_cote_haute,
    ouv.ouv_liste1,
    ouv.ouv_liste2,
    ouv.ouv_date_liste,
    ouv.ouv_date_fin_acte,
    ouv.ouv_reglement_eau,
    ouv.ouv_fichier_reglement,
    ouv.ouv_surface_bv,
    ouv.ouv_source_surface,
    ouv.ouv_module,
    ouv.ouv_source_module,
    ouv.ouv_surface_bv_irstea,
    ouv.ouv_module_irstea,
    ouv.ouv_robustesse_irstea,
    ref.ref_z AS altitude,
    ouv.ouv_lineaire_aval,
    ouv.ouv_surface_retenue,
    ouv.ouv_surface_source,
    ouv.ouv_volume_retenue,
    ouv.ouv_volume_source,
    ouv.ouv_longueur_remous,
    ouv.ouv_longueur_source,
    ouv.ouv_chute_amont,
    ouv.ouv_chute_aval,
    ouv.ouv_commentaire_chute,
    --ouv.ouv_auteur_creation,
    ouv.ouv_structure_creation,
    strc.str_libelle AS structure_libelle_creation,
    ouv.ouv_date_creation,
    --ouv.ouv_auteur_modification,
    ouv.ouv_structure_modification,
    strm.str_libelle AS structure_libelle_modification,
    ouv.ouv_date_modification,
    ouv.ouv_gelee
   FROM bdoe.ouvrage ouv
     LEFT JOIN roe.obstacle_referentiel ref ON ref.ref_id = ouv.ouv_id
     LEFT JOIN bdoe.operateur ope ON ope.ope_id = ouv.ouv_avis_ope_id
     LEFT JOIN bdoe.variabilite_debit vad ON vad.vdr_id = ouv.ouv_vdr_id
     LEFT JOIN bdoe.avis_technique_global atg ON atg.atg_id = ouv.ouv_atg_id
     LEFT JOIN geobs.structure strc ON strc.str_id = ouv.ouv_structure_creation
     LEFT JOIN geobs.structure strm ON strm.str_id = ouv.ouv_structure_modification
  WHERE ouv.ouv_gelee <> true OR ouv.ouv_gelee IS NULL
  ORDER BY ouv.ouv_id;


DROP VIEW bdoe.ouvrage_bdoe;

CREATE OR REPLACE VIEW bdoe.ouvrage_bdoe AS 
 SELECT entrybdoe.ouv_id,
    entrybdoe.ouv_arasement,
    entrybdoe.ouv_arasement_date,
    entrybdoe.ouv_derasement,
    entrybdoe.ouv_derasement_date,
    entrybdoe.ouv_commentaires,
    entrybdoe.ouv_commentaire_mesures,
    entrybdoe.ouv_atg_id,
    entrybdoe.ouv_date_avis,
    entrybdoe.ouv_avis_ope_id,
    entrybdoe.ouv_avis_ope_precision,
    entrybdoe.ouv_commentaire_avis,
    entrybdoe.ouv_fichier_avis,
    entrybdoe.ouv_debut_activite,
    entrybdoe.ouv_fin_activite,
    entrybdoe.ouv_vdr_id,
    entrybdoe.ouv_debit_reserve,
    entrybdoe.ouv_debit_montaison,
    entrybdoe.ouv_debit_devalaison,
    entrybdoe.ouv_debit_maximal,
    entrybdoe.ouv_debit_commentaire,
    entrybdoe.ouv_longueur_troncon,
    entrybdoe.ouv_ecartement_grille,
    entrybdoe.ouv_cote_basse,
    entrybdoe.ouv_cote_haute,
    entrybdoe.ouv_liste1,
    entrybdoe.ouv_liste2,
    entrybdoe.ouv_date_liste,
    entrybdoe.ouv_date_fin_acte,
    entrybdoe.ouv_reglement_eau,
    entrybdoe.ouv_fichier_reglement,
    entrybdoe.ouv_surface_bv,
    entrybdoe.ouv_source_surface,
    entrybdoe.ouv_module,
    entrybdoe.ouv_source_module,
    entrybdoe.ouv_surface_bv_irstea,
    entrybdoe.ouv_module_irstea,
    entrybdoe.ouv_robustesse_irstea,
    entrybdoe.ouv_lineaire_aval,
    entrybdoe.ouv_surface_retenue,
    entrybdoe.ouv_surface_source,
    entrybdoe.ouv_volume_retenue,
    entrybdoe.ouv_volume_source,
    entrybdoe.ouv_longueur_remous,
    entrybdoe.ouv_longueur_source,
    entrybdoe.ouv_chute_amont,
    entrybdoe.ouv_chute_aval,
    entrybdoe.ouv_commentaire_chute,
    --entrybdoe.ouv_auteur_creation,
    entrybdoe.ouv_structure_creation,
    entrybdoe.ouv_date_creation,
    --entrybdoe.ouv_auteur_modification,
    entrybdoe.ouv_structure_modification,
    entrybdoe.ouv_date_modification,
    entrybdoe.ouv_gelee,
    ( SELECT
                CASE
                    WHEN entrybdoe.ouv_gelee IS NOT TRUE THEN 1
                    ELSE 0
                END AS ouvrage_non_gele) AS ouvrage_non_gele,
    ( SELECT
                CASE
                    WHEN (EXISTS ( SELECT 1
                       FROM ice.operation_ice opi
                         LEFT JOIN ice.obstacle_operation_ice ooi ON opi.opi_ooi_id = ooi.ooi_id
                      WHERE ooi.ooi_ref_id = entrybdoe.ouv_id AND opi.opi_gelee IS NOT TRUE)) THEN 1
                    ELSE 0
                END AS presence_bdoe_et_ice) AS presence_bdoe_et_ice,
    ( SELECT
                CASE
                    WHEN (EXISTS ( SELECT 1
                       FROM bdoe.hauteur_chute hc
                      WHERE hc.hco_ouv_id = entrybdoe.ouv_id)) THEN 1
                    ELSE 0
                END AS hauteur_chute_renseignee) AS hauteur_chute_renseignee,
    ( SELECT
                CASE
                    WHEN (EXISTS ( SELECT 1
                       FROM bdoe.montaison_ouvrage moo
                      WHERE moo.moo_ouv_id = entrybdoe.ouv_id AND moo.moo_mcm_id = 2)) OR (EXISTS ( SELECT 1
                       FROM bdoe.devalaison_ouvrage doe
                      WHERE doe.doe_ouv_id = entrybdoe.ouv_id AND (doe.doe_mcd_id = 2 OR doe.doe_mcd_id = 3))) OR (EXISTS ( SELECT 1
                       FROM bdoe.continuite_ouvrage cso
                      WHERE cso.cso_ouv_id = entrybdoe.ouv_id AND cso.cso_mcc_id = 2)) THEN 1
                    ELSE 0
                END AS mesure_corrective_equipement) AS mesure_corrective_equipement
   FROM bdoe.ouvrage entrybdoe;






ALTER TABLE bdoe.ouvrage DROP COLUMN ouv_auteur_creation;
ALTER TABLE bdoe.ouvrage DROP COLUMN ouv_auteur_modification;


*/
----------------------------------------------------
STOP ERREUR DE COMPILATION DU SCRIPT SI LANCE PAR MEGARDE

--------------------------------------
CREATE SCHEMA montepomi;
DROP TABLE if exists montepomi.dbeel_obstruction_place CASCADE;
CREATE TABLE montepomi.dbeel_obstruction_place (
    id_original character varying(10),
    country character varying(2),
        CONSTRAINT pk_obs_op_id PRIMARY KEY (op_id),
        CONSTRAINT c_uk_id_roe UNIQUE (id_original),
        CONSTRAINT fk_so_observation_place_type_id FOREIGN KEY (op_no_observationplacetype) 
                REFERENCES dbeel_nomenclature.observation_place_type (no_id) 
                MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observation_places);


-- Creation index spatial
CREATE INDEX 
  ON montepomi.dbeel_obstruction_place
  USING gist
  (the_geom);





-- Le choix est fait d'utiliser les TABLEs de SUDOANG


-- SELECT * FROM montepomi.dbeel_obstruction_place WHERE country='FR';
-- SELECT count(*) FROM roe.roesudo
DROP TABLE IF EXISTS roe.roesudo;
CREATE TABLE roe.roesudo AS SELECT * FROM roe.obstacle_referentiel;--112934 => 113415 =>117340

--Change le référentiel géographique (srid) de la colonne ref_position_carthage
SELECT UpdateGeometrySRID('roe','roesudo','ref_position_carthage',3035);
update roe.roesudo set ref_position_carthage= ST_Transform(ST_SetSRID(ref_position_carthage,4326),3035);
reindex TABLE roe.roesudo;
-- SELECT * FROM roe.roesudo WHERE ref_position_carthage is NULL;
--SELECT count(*) FROM roe.roesudo WHERE ref_position_carthage IS NULL; 

-- projection des données ROE ICE sur le réseau RHT (couche france.rn), nécessite de trouver le point sur le tronçon RHT qui est le plus proche de notre ouvrage
SELECT addgeometrycolumn('roe','roesudo','geom_reproj',3035,'POINT',2);

-- SELECT count (*) FROM roe.roesudo WHERE ref_position_carthage is not null;
update roe.roesudo set	geom_reproj = sub2.geom_reproj from(
	select
		distinct on
		(ref_id) ref_id,
		geom_reproj,
		distance
	from(
		select
			roe.ref_id,
			ST_ClosestPoint(r.geom,roe.ref_position_carthage) as geom_reproj ,
			ST_distance(r.geom,roe.ref_position_carthage) as distance
		from roe.roesudo roe
		join france.rn r on st_dwithin(r.geom,roe.ref_position_carthage,300)
		order by ref_id,distance
		)sub )sub2
where sub2.ref_id = roesudo.ref_id;--94288

/* For those missing adding the geom from ref_position not ref_position_carthage
 * RHT basé sur bd_carthage mais dans ROE lien avec d'autres référentiels cours d'eau, on peut donc essayer avec d'autres géométries pour voir si on récupère d'autres ouvrages
*/
update roe.roesudo set geom_reproj = sub2.geom_reproj FROM (
SELECT DISTINCT on (ref_id) ref_id, geom_reproj, distance FROM(
SELECT roe.ref_id, 
ST_ClosestPoint(r.geom,st_transform(roe.ref_position,3035)) AS geom_reproj ,
ST_distance(r.geom,st_transform(roe.ref_position,3035)) AS distance
FROM roe.roesudo roe  join
france.rn r on st_dwithin(r.geom,st_transform(roe.ref_position,3035),300) 
WHERE ref_position_carthage is NULL  -- là ou le ref_postition_carthage est null
ORDER BY ref_id, distance
)sub )sub2
WHERE sub2.ref_id= roesudo.ref_id; --5360


--SELECT count(*) FROM roe.roesudo --117340 
-- TODO quand usage hydroelectricité corriger usage plan de grille

/*SELECT * FROM roe.roesudo 
JOIN roe.type ON ref_typ_id=typ_id
WHERE ref_id_national = 'ROE43938';
-- LACAZE
SELECT * FROM roe.roesudo 
JOIN roe.type ON ref_typ_id=typ_id
WHERE ref_id_national = 'ROE43929';
-- NAvarre - Grille de pisciculture
SELECT * FROM roe.roesudo 
JOIN roe.type ON ref_typ_id=typ_id
WHERE ref_id_national = 'ROE43922';

SELECT * FROM roe.roesudo 
JOIN roe.type ON ref_typ_id=typ_id
WHERE ref_id_national = 'ROE40569';

SELECT * FROM roe.roesudo 
JOIN roe.type ON ref_typ_id=typ_id
WHERE ref_id_national = 'ROE40562';
-- vignes
SELECT * FROM roe.roesudo 
JOIN roe.type ON ref_typ_id=typ_id
WHERE ref_id_national = 'ROE40562';
-- SRA
SELECT * FROM roe.roesudo 
JOIN roe.type ON ref_typ_id=typ_id
WHERE ref_id_national = 'ROE40573';

SELECT * FROM montepomi.dbeel_obstruction_place WHERE id_original = 'ROE43938'
*/
CREATE INDEX 
  ON roe.roesudo
  USING gist
  (geom_reproj);


---------------
-- TODO pb de projection
---------------
/*
les informations de reprojection sur la bd_carthage sont présentes sur le ROE (colonne cd_Entite_hy et semble correspondre au code cd_hyd_cdo
Voir si il est possible de récupérer le rang de strahler de la bd_carthage ou attacher l'information concernant la jointure entre tronçons rht et bd_carthage.
http://www.sandre.eaufrance.fr/ftp/documents/fr/scn/obsgeo/1/sandre_sc_geo_obs_1.pdf
http://id.eaufrance.fr/ddd/ETH/2002-1/IdTronconHydrograElt
*/
 
 
--Marion : vois pas trop pourquoi on voudrait faire ça...la table montepomi.dbeel_obstruction_place est vide de toute façon à ce stade...
--DELETE  FROM montepomi.dbeel_obstruction_place WHERE country='FR';  

--ref_sta_id = statut des ouvrages. On veut garder Validé par échantillonnage (4) et Validé point par point (0)
 --Marion : vieille écriture de sous-requête. Pour Léa, Jules et Benjamin, revient au même que d'utiliser un WITH()
/*
INSERT INTO montepomi.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id, 
	'AFB' AS op_gis_systemname, 
	'roe' AS op_gis_layername, 
	3035 AS op_gislocation, 
	ref_nom AS op_placename, 
	281 AS op_no_observationplacetype, 
	NULL op_op_id, 
	geom_reproj AS the_geom, 
	ref_id_national AS id_original, 
	'FR' AS country
	FROM (SELECT * FROM roe.roesudo WHERE geom_reproj IS NOT NULL and ref_sta_id in (0,4)) unique_obs
	; --  including pb geom 89717 -->92253 (82s)
*/
	
with data_import as (
	SELECT * 
	FROM roe.roesudo 
	WHERE geom_reproj IS NOT NULL and ref_sta_id in (0,4)
	)
INSERT INTO montepomi.dbeel_obstruction_place
	SELECT uuid_generate_v4() AS op_id, 
		'AFB' AS op_gis_systemname, 
		'roe' AS op_gis_layername, 
		3035 AS op_gislocation, 
		ref_nom AS op_placename, 
		281 AS op_no_observationplacetype, 
		NULL op_op_id, 
		geom_reproj AS the_geom, 
		ref_id_national AS id_original, 
		'FR' AS country
	from data_import; --92253
	
--VACUUM FULL ANALYSE montepomi.dbeel_obstruction_place;--7s
--REINDEX TABLE montepomi.dbeel_obstruction_place; -- 5s
	--2414 / only the one projected on rivers
-- SELECT * FROM montepomi.dbeel_obstruction_place
-- record back the link with dbeel



-----------------------------------------------
--  Dans le dictionnaire du sandre il y a un type 6 installation industrielle, ce type n'est pas intégré dans le ROE pourquoi ?
-------------------------------------------------



--SELECT * FROM roe.roesudo WHERE ref_id_national like '%90128%'
--SELECT * FROM roe.roesudo WHERE ref_position_carthage is NULL and ref_position_bdtopo is not NULL
-----------------------------------------------
--  Ouvrages liés
-------------------------------------------------
-- Dans ROE quand la colonne ouvrageLie est remplie on récupére cette information pour l'introduire dans devalpomi
-- premiere requete récuperatio du lien fils
WITH recupere_moi_le_code_op_id_pere AS (
SELECT op_id AS op_id_pere, liens_ref_id,liens_ref_id_fils FROM montepomi.dbeel_obstruction_place join
     roe.liens  on 'ROE'||liens.liens_ref_id=id_original),
     recupere_moi_le_code_op_id_fils AS (
   SELECT op_id_pere, op_id AS op_id_fils, liens_ref_id,liens_ref_id_fils FROM recupere_moi_le_code_op_id_pere join
     montepomi.dbeel_obstruction_place  on 'ROE'||liens_ref_id_fils=id_original)
-- on référence le code du père dans la ligne de l'ouvrage fils
update montepomi.dbeel_obstruction_place set op_op_id=recupere_moi_le_code_op_id_fils.op_id_pere FROM recupere_moi_le_code_op_id_fils
WHERE recupere_moi_le_code_op_id_fils.op_id_fils=dbeel_obstruction_place.op_id; 
--6055 2.2 s --> 6494 (Marion, Laetitia, Benjamin 31/03/23)



-- on rajoute une colonne dbeel_op_id dans la TABLE source pour faire le lien
--ALTER TABLE roe.roesudo ADD COLUMN dbeel_op_id uuid; 
UPDATE roe.roesudo set dbeel_op_id = NULL;--117340

UPDATE roe.roesudo SET dbeel_op_id = op_id 
FROM montepomi.dbeel_obstruction_place 
WHERE dbeel_obstruction_place.id_original=roesudo.ref_id_national;	--89717 rows affected, 8.6 secs execution time. 
-->92253 (Marion, Laetitia, Benjamin 31/03/23)




/*
Adaptation du script de Soizic pour le choix des ouvrages, merci Soizic !!!
*/

BEGIN;
select count(*) from montepomi.dbeel_obstruction_place; --92253

-- Benjamin: faut il supp le seuil du Moulin de Coulonge et la Prise d'eau EDF Cordemais pour montepomi
-- pour l'instant pas executé
select *
from montepomi.dbeel_obstruction_place
WHERE id_original in ('ROE106058','ROE88566')
DELETE FROM montepomi.dbeel_obstruction_place WHERE id_original in ('ROE106058','ROE88566'); --2 supression d'ouvrages dont on sait qu'ils ne sont pAS des ouvrages hydroélectriques
-- On vire les digues

-- Si on veut travailler avec les dates de mise en place/suppression des ouvrages, il faudra sans doute revenir sur ce script pour le modifier
DELETE FROM montepomi.dbeel_obstruction_place 
	WHERE op_id in (
	SELECT op_id FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id 
	JOIN roe.type ON ref_typ_id=typ_id
	WHERE typ_nom = 'Digue' );--290 -->294
	
DELETE FROM montepomi.dbeel_obstruction_place 
	WHERE op_id in (
	SELECT op_id FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id 
	JOIN roe.type ON ref_typ_id=typ_id
	WHERE typ_nom In ('Epis en rivière','Grille de pisciculture')); --647 -->651

-- modif 2023 'Détruit entièrement' gardé
DELETE FROM montepomi.dbeel_obstruction_place 
	WHERE op_id in (
	SELECT op_id FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id 
	JOIN roe.etat ON ref_eta_id=eta_id
	WHERE eta_nom In ('En construction','En projet')); --3545 -- ceux qui ne sont pAS physiquement présent -->4189 -->120 (Marion, Laetitia, Benjamin 31/03/23 il y en avait bcp en détruit entièrement donc)

-- on supprime plus les dérasés
/*
	DELETE FROM montepomi.dbeel_obstruction_place 
	WHERE op_id in (
	SELECT op_id FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id 
	JOIN bdoe.ouvrage on 'ROE'||ouv_id=ref_id_national
	WHERE ouv_derasement); --198 -->554
*/
	
SELECT count(*) FROM montepomi.dbeel_obstruction_place WHERE country ='FR'; --110 013 (SP+PT+FR) 
--85035 (après suppression) -->86563 -->91188 (Marion, Laetitia, Benjamin 31/03/23)

COMMIT;
--ROLLBACK;
 
/*
 * On repasse dessus pour supprimer les liens qui n'existent plus (meme requete que precedement)
 */
UPDATE roe.roesudo set dbeel_op_id = NULL;--113415 -->117340



UPDATE roe.roesudo SET dbeel_op_id = op_id 
FROM montepomi.dbeel_obstruction_place 
WHERE dbeel_obstruction_place.id_original=roesudo.ref_id_national;	--85035 rows affected, 8.6 secs execution time. 
-->86563 -->91188 (Marion, Laetitia, Benjamin 31/03/23)





--SELECT count(*) FROM montepomi.dbeel_obstruction_place join roe.roesudo on dbeel_op_id = op_id  -- 85035
	
---------------------------------------------------------------
--Insertion des données de la TABLE dbeel_physical_obstructions
-----------------------------------------------------------------

-- SELECT * FROM roe.roesudo WHERE "CdObstEcou"='ROE79716'

-- SELECT * FROM dbeel.establishment -- 8 AFB
/* RUNONCE
insert into dbeel.data_provider(dp_name,dp_et_id)  values ('Pierre Sagnes',8);--1 dp_id 23
-- SELECT * FROM dbeel.data_provider;
*/



/*

|tso_id     |tso_libelle                                                                                         |tso_libelle_long                                                                                    |
|-----------|----------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
|1          |Seuil                                                                                               |Seuil (inclin├®, vertical), ├®l├®ment mobile par surverse ou ├®coulement libre                      |
|2          |Seuil en enrochements                                                                               |Seuil en enrochements                                                                               |
|3          |Ecoulement sous vannes et orifices (├®l├®ments mobiles)                                             |Ecoulement sous vannes et orifices (├®l├®ments mobiles)                                             |
|4          |Ouvrage routier ou ferroviaire                                                                      |Ouvrage routier ou ferroviaire                                                                      |
|5          |Ouvrage de mar├®e                                                                                   |Ouvrage de mar├®e                                                                                   |
|6          |Dispositif de franchissement piscicole                                                              |Dispositif de franchissement piscicole                                                              |
|7          |Prise d'eau                                                                                         |Prise d'eau                                                                                         |
|8          |Voie de reptation en berge                                                                          |Voie de reptation en berge                                                                          |


SELECT DISTINCT doe_mcd_id, mcd_libelle FROM bdoe.devalaison_ouvrage
|doe_mcd_id               |mcd_libelle                                                                                         |
|-------------------------|----------------------------------------------------------------------------------------------------|
|1                        |Gestion                                                                                             |
|2                        |Equipement de prise d'eau                                                                           |
|3                        |Turbine ichtyocompatible                                                                            |

REFLEXION INITIALE
A la montée d'abord ICE puis BDOE , ensuite hauteur terrain du ROE.

TODO changer pour mettre BDOE en premier ?

CE QU'ON A FAIT AU FINAL (PRESQUE PAREIL SAUF QU'ON IGNORE LES CLASSES ROE)
(1)Pour hauteur chute ICE, on va chercher la valeur de chute min de toutes les turbines => stockée dans tuh_hauteur_chute
                        on a aussi une valeur de chute par partie d'ouvrage, on choisit de mettre un ordre de priorité et
                         d'aller chercher les chutes dans l'ordre suivant :
                      
			1 ouvrage à marée (tso_id=5)
			2 seuil     (1)
			3 vannes     (3)
			4 seuil en enrochement (2)
			5 prise eau (7)
			6 ouvrage routier (4)
			7 passe (6)
			8 voie reptation (8)
(2)Pour hauteur chute ROE on a soit un LbHautChut qui correpond à un CdHautChut, soit une valeur HautChutEt
(3) Pour la BDOE on a une valeur qui peut correspondre à ROE, qui peut aussi avoir été rentrée à la main. Dans ce dernier cAS,
il peut y avoir plusieurs mesures pour le même ouvrage, sans indication de quelle hauteur de chute serait la meilleure à prendre en 
compte dans le cAS de l'anguille. Au final prendre la moyenne semble un bon choix
TODO :
Une alternative serait de prendre la hauteur de chute avec la date la plus récente (permet de prendre en compte des modifications de hauteur de seuil qui seraient intervenues)

 Dès qu'on a une seule valeur sur les trois (BDOE,ICE,ROE) on la prend,
 Si on a rien de rien on vire la ligne,
 Si on a pAS de valeur et quelque chose dans la classe du ROE on prend la classe (10883 lignes)
 CASE WHEN "CdHautChut"=1 THEN 0.25 --<0.5
	   "CdHautChut"=2 THEN 0.75
	   "CdHautChut"=4 THEN 1.25
	   "CdHautChut"=5 THEN 1.75	   
	   "CdHautChut"=6 THEN 4
	   "CdHautChut"=7 THEN 7
	   "CdHautChut"=8 THEN 20	   	   	   
 Normalement, la bdoe correspond à la valeur à l'étiage,  si la valeur est supérieure aux autres 
 et différente de la valeur du ROE (car elle peut venir du ROE) on prend bdoe 
 Sinon on prend ICE
 Sinon on prend la chute au niveau de la turbine

 Le LEFT JOIN A LA FIN EST NECESSAIRE CAR CERTAINS OUVRAGES SONT ENCORE RENSEIGNES DANS BDOE ET ICE ALORS QU'ILS SONT GELES



|no_id      |no_code|no_type                                                     |no_name                                                                         |
|-----------|-------|------------------------------------------------------------|--------------------------------------------------------------------------------|
|270        |       |Fishway type                                                |Vertical slot fishway                                                           |
|271        |       |Fishway type                                                |Pool type fishway                                                               |
|272        |       |Fishway type                                                |Fish lock                                                                       |
|273        |       |Fishway type                                                |Denil pass                                                                      |
|274        |       |Fishway type                                                |Fish lift                                                                       |
|275        |       |Fishway type                                                |Rock ramp                                                                       |
|276        |       |Fishway type                                                |Eel ramp                                                                        |
|277        |       |Fishway type                                                |Lateral canal                                                                   |
|278        |       |Fishway type                                                |Artificial river                                                                |
|279        |       |Fishway type                                                |Unknown                                                                         |
|280        |       |Fishway type                                                |Sluice                                                                          |


Les types de dispositifs de l'ICE

tdfp_id;tdfp_libelle
1;passe à bASsins successifs Oui	(4)
2;Rivière de contournement Oui        (1)
3;Ascenseur Non                        (7)
4;passe à ralentisseurs Non            (8)
5;Rampe en enrochements Oui            (2)
6;Ecluse oui				(6)
7;Prébarrages Oui		       (5)
8;passe à anguilles Oui               (3)
9;Autre Non                           (9)
(1,2,5,6,7,8)

LES TYPES DE DISPOSTIF DU ROE
-- SELECT count(*), "CdTypeDi_1"::integer, "LbTypeDi_1" FROM roe.roesudo GROUP BY "CdTypeDi_1"::integer, "LbTypeDi_1" ORDER BY "CdTypeDi_1"::integer


0;Absence de passe   non
1;passe à ralentisseurs non
2;passe à  bassins successifs oui
3;Ecluse à  poisson oui
4;Exutoire de dévalaison non
5;passe à Anguille oui
6;Ascenseur à poissons
7;Pré-barrage oui
8;Rampe oui
9;Rivière de contournement oui
10;Autre type de passe non
11;Type de dispositif (piscicole) inconnu non     (dernier)

(2,3,5,7,8,9)

On dit qu'il y a une passe "compatible anguille" si un seul des deux référentiels présente une passe compatible anguille

--SELECT count(*), fishway_type, po_presence_eel_pass FROM roe_presence_eel_pass WHERE fishway_type is not null GROUP BY fishway_type,po_presence_eel_pass ; --3843 (en ajoutant tous les types de disp, 
/*
count;fishway_type;po_presence_eel_pass
426;279;f
509;273;f
459;275;t
233;276;t
11;274;f
14;272;t
478;278;t
1713;271;t
*/
*/

/*
 * 
 * PHYSICAL OBSTRUCTION INSERTION
 * 
 */


-- MONTEPOMI > eda_dbeel > ISSUE #14 : collect dam impact score for ALA/SAT/LPM
-- copié collé de la requête précente pour l'anguille en ajoutant les notes ICE de franchissabilité des autres espèces

--ALTER TABLE montepomi.dbeel_physical_obstruction
--ALTER COLUMN fishway_type TYPE INTEGER USING fishway_type::INTEGER;


DROP TABLE if exists montepomi.dbeel_physical_obstruction CASCADE;
CREATE TABLE montepomi.dbeel_physical_obstruction (
  fishway_type INTEGER,
  date_last_update date,
  author_last_update text,
  comment_update text,
  esp_id integer, 
  ouv_avis_tech_global_id integer,
  ouv_commentaire_chute_bdoe text,
  ouv_commentaire_avis_bdoe text,
  ouv_commentaires_bdoe text,
  ouv_commentaire_mesures_bdoe text,
  ref_commentaire_sous_type_roe text,
  ouv_derasement_date date,
  ouv_arasement_date date,
  ouv_debut_activite date,
  ouv_fin_activite date,
  haut_chut_avant_abaissement numeric(10,2),
  haut_chut_apres_abaissement numeric(10,2),
  CONSTRAINT physical_obstruction_id PRIMARY KEY (ob_id),
  CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id),
  CONSTRAINT fk_ob_origin FOREIGN KEY (ob_no_origin)REFERENCES dbeel_nomenclature.observation_origin (no_id) ,
  CONSTRAINT fk_ob_period FOREIGN KEY (ob_no_period) REFERENCES dbeel_nomenclature.period_type (no_id) ,
  CONSTRAINT fk_ob_type FOREIGN KEY (ob_no_type) REFERENCES dbeel_nomenclature.observation_type (no_id) ,
  CONSTRAINT fk_po_obstruction_passability FOREIGN KEY (po_no_obstruction_passability)REFERENCES dbeel_nomenclature.obstruction_impact (no_id),
  CONSTRAINT fk_ot_obstruction_type FOREIGN KEY (ot_no_obstruction_type) REFERENCES dbeel_nomenclature.obstruction_type(no_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ot_mortality_type FOREIGN KEY (ot_no_mortality_type) REFERENCES dbeel_nomenclature.biological_characteristic_type(no_id) ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS(dbeel.physical_obstruction);


  WITH 
hauteur_chute_bdoe_nlignes AS (
	
	SELECT hco_hauteur AS h_chute_bdoe, hco_ouv_id::integer AS ouv_id FROM  bdoe.hauteur_chute 
	),--58380 -->61978
hauteur_chute_bdoe AS (	
	SELECT avg(h_chute_bdoe) h_chute_bdoe,ouv_id FROM  hauteur_chute_bdoe_nlignes GROUP BY ouv_id
	),

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
	SELECT *,
	 CASE WHEN sto_tso_id=5 THEN 2 -- ouvrage à marée
	               WHEN sto_tso_id=1 THEN 3 -- seuil
	               WHEN sto_tso_id=3 THEN 4 -- vannage
	               WHEN sto_tso_id=2 THEN 5	-- seuil en enrochement	
	               WHEN sto_tso_id=7 THEN 6 -- prise d'eau 
	               WHEN sto_tso_id=4 THEN 7 -- ouvrage routier
	               WHEN sto_tso_id=6 THEN 8	  -- dispositif de franchissement piscicole             
	               WHEN sto_tso_id=8 THEN 1 --voie sur berge
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
(SELECT ouv_id, 
	min(sto_hauteur_chute) AS hauteur_chute_ice,
	max(opi_hauteur_chute) AS hauteur_chute_ice_plus_limitante	
	FROM hauteur_chute_ice_sto
	GROUP BY ouv_id),
-- Nos hauteurs sont en général égales, parfois plus faibles, mais pas systématiquement ???. 
-- Dans certains cas on a une hauteur_chute venant de opi alors que pour nous rien ... 
-- peut être parce que dans ICE ils traitent mieux les nulls
-- SELECT * FROM hauteur_chute_ice_par_ouvrage WHERE hauteur_chute_ice_plus_limitante < hauteur_chute_ice
hauteur_chute_ice AS
(SELECT ouv_id, 
	coalesce(hauteur_chute_ice,hauteur_chute_ice_plus_limitante) AS h_chute_ice
	FROM hauteur_chute_ice_par_ouvrage),
	
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
 	WHERE  geom_reproj IS NOT NULL and
 	ref_sta_id in(0,4) 
 	 ),
--SELECT *  FROM selectionne_roe	--88743 --> 92253
-- change 2020 add ref_chce_id
hauteur_chute_roe AS (
 	  SELECT ouv_id, dbeel_op_id, ref_hauteur_chute_etiage_classe,  ref_hauteur_chute_etiage AS h_chute_roe, ref_chce_id, obstruction_type_no_id  
 	  FROM selectionne_roe
 	  ),
--SELECT * FROM hauteur_chute_roe
-- TODO changer les priorités BDOE / ICES
height AS (
 	  SELECT  
 	 coalesce(hauteur_chute_bdoe.ouv_id,hauteur_chute_ice.ouv_id,hauteur_chute_roe.ouv_id) AS ouv_id,
 	 dbeel_op_id,
 	 obstruction_type_no_id,
 	 round(
 	 CASE 
   WHEN h_chute_ice is NOT NULL THEN h_chute_ice --ice d'abord
 	 WHEN h_chute_ice IS NULL and h_chute_bdoe is NOT NULL  THEN h_chute_bdoe --bdoe ensuite
 	 WHEN h_chute_bdoe is NULL and h_chute_ice is NULL AND h_chute_roe IS NOT NULL THEN h_chute_roe::numeric -- ROE ensuite
  	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=1 THEN NULL -- indéterminé
  	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=2 THEN 0.25 --valeurs unique classe <0.5
  	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=3 THEN 0.75 --De 0.5m à inférieure à 1m
  	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=4 THEN 1.25 --De 1m à inférieure à 1.5m
	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=5 THEN 1.75 -- De 1.5m à inférieure à 2m
	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=6 THEN 2.5  --'DE 2m A INFERIEURE A 3m'	   
	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=7 THEN 4 --'DE 3m A INFERIEURE A 5m'
	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=8 THEN 7.5 --'DE 5m A INFERIEURE A 10m'
	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id=9 THEN 20 --'SUPERIEURE OU EGALE A 10m'
	 ELSE NULL	
	 END,2) AS hauteur_chute,	 
	 CASE 
	 WHEN h_chute_ice is NOT NULL THEN 'Choix ice (1)' --ice d'abord (parce que sinon on en a aucun)
 	 WHEN h_chute_ice IS NULL and h_chute_bdoe is NOT NULL  THEN  'Choix bdoe (2)' --bdoe ensuite
 	 WHEN h_chute_bdoe is NULL and h_chute_ice is NULL AND h_chute_roe IS NOT NULL THEN 'Choix roe (3)' -- très rare
  	 WHEN h_chute_bdoe IS NULL AND h_chute_roe IS NULL and h_chute_ice is NULL AND ref_chce_id IS NOT NULL 
  	 AND ref_chce_id!=1 THEN 'Choix classe (4)' --jamais, merci de vous êtres fait c... => les classes de hauteur de chute doivent venir des autres tables
 	 ELSE 'Pas de hauteur'	
	 END  AS commentaire_hauteur_chute  
 	 FROM hauteur_chute_roe 
 	 LEFT JOIN  hauteur_chute_ice on hauteur_chute_roe.ouv_id=hauteur_chute_ice.ouv_id 
 	 LEFT JOIN hauteur_chute_bdoe On hauteur_chute_bdoe.ouv_id= hauteur_chute_roe.ouv_id
        -- WHERE coalesce(h_chute_roe, h_chute_ice, h_chute_bdoe) IS NOT NULL AND ref_hauteur_chute_etiage_classe IS NOT NULL 
        ),
--SELECT count(*) FROM  height    --88743 -> 92253
	 
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

-- si presence d'une passe correspondant à la liste et ouvrage noté infranchissable à une date existante (correspond aux avis récents)
-- Avis technique global Avis technique à la montaison

-- TODO adapter pour Lamproie, Saumon, Alose
ice_presence_eel_pass AS(
-- On récupère la première des passes 
SELECT  distinct on (ouv_id) 
	ouv_id,
	CASE WHEN dfp_tdfp_id in (1,2,5,6,7,8) THEN TRUE ELSE FALSE END AS po_presence_eel_pass,
	-- On peut avoir plusieurs passes dans ce cAS on les prend dans l'ordre suivant :
	CASE WHEN dfp_tdfp_id = 2 THEN 278
		WHEN dfp_tdfp_id = 5 THEN 275
		WHEN dfp_tdfp_id = 8 THEN 276
		WHEN dfp_tdfp_id = 1 THEN 271
		WHEN dfp_tdfp_id = 7 THEN 271 -- pre barrage est identique à pool type fishway
		WHEN dfp_tdfp_id = 6 THEN 272
		WHEN dfp_tdfp_id = 3 THEN 274		
		WHEN dfp_tdfp_id = 4 THEN 273
		WHEN dfp_tdfp_id = 9 THEN 279 -- de toutes façons on récupère mais on mettra non
		ELSE NULL END AS fishway_type	
	FROM ice.obstacle_operation_ice 
	JOIN ice.operation_ice on opi_ooi_id=ooi_id 
	JOIN ice.partie_obstacle ON pao_opi_id=opi_id 
	JOIN ice.structure_obstacle on sto_pao_id=pao_id
        JOIN ice.dispositif_franchissement_piscicole  on sto_id= dfp_id 
         JOIN hauteur_chute_roe hh on hh.ouv_id=ooi_ref_id -- pour virer les codes gelés et autres
        ),
 --SELECT * FROM ice_presence_eel_pass --125

union_roe_pass AS (
          SELECT fty_code::numeric AS cdtypedisp, 
          fpi_ref_id AS ouv_id
          FROM roe.franchissement_piscicole 
          join roe.franchissement_piscicole_type on fpi_fty_id=fty_id
          
 	  ),
roe_presence_eel_pass AS (
	SELECT DISTINCT on (ouv_id)
	ouv_id,
	CASE WHEN cdtypedisp in (2,3,5,7,8,9) THEN TRUE ELSE FALSE END AS po_presence_eel_pass,
	-- On peut avoir plusieurs passes dans ce cAS on les prend dans l'ordre suivant :
	CASE WHEN cdtypedisp = 9 THEN 278
		WHEN cdtypedisp = 8 THEN 275
		WHEN cdtypedisp = 5 THEN 276
		WHEN cdtypedisp = 2 THEN 271
		WHEN cdtypedisp = 7 THEN 271 -- pre barrage est identique à pool type fishway
		WHEN cdtypedisp = 3 THEN 272
		WHEN cdtypedisp = 6 THEN 274		
		WHEN cdtypedisp = 1 THEN 273
		WHEN cdtypedisp in (10,11) THEN 279 -- de toutes façons on récupère mais on mettra non
		ELSE NULL -- correpond au type 0 absence de passe
		END AS fishway_type	
	FROM union_roe_pass 	
),

presence_eel_pass AS (

	SELECT coalesce(ice.ouv_id,roe.ouv_id) AS ouv_id,
	CASE WHEN ice.fishway_type is not NULL THEN ice.fishway_type else roe.fishway_type END AS fishway_type,
	CASE WHEN ice.po_presence_eel_pass is not NULL THEN ice.po_presence_eel_pass else roe.po_presence_eel_pass END AS po_presence_eel_pass  
       FROM roe_presence_eel_pass roe FULL OUTER JOIN ice_presence_eel_pass ice on roe.ouv_id=ice.ouv_id),


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
  
-- TODO note expertise devalaison

notes_expertise AS (
SELECT calcul_ice.*,
ooi_ref_id,
CASE WHEN opi_date_releve is NULL THEN opi_date_creation::date 
else opi_date_releve END AS opi_date_releve,
 cli_code, 
 cli_libelle,
 coalesce(ouv_lineaire_aval,9999) AS ouv_lineaire_aval -- si pAS de valeur on calcule pAS 
FROM ice.obstacle_operation_ice JOIN ice.operation_ice on opi_ooi_id=ooi_id 
JOIN ice.partie_obstacle ON pao_opi_id=opi_id 
JOIN ice.structure_obstacle on sto_pao_id=pao_id 
JOIN ice.calcul_ice ON sto_id=cai_sto_id
join ice.classe_ice on calcul_ice.cai_cli_id=classe_ice.cli_id 
LEFT JOIN bdoe.ouvrage on ouvrage.ouv_id=ooi_ref_id
WHERE cai_gre_id in (1,3,5,19,20) and cli_code NOT IN ('DNA','NC','DA')
ORDER BY ooi_ref_id,cai_gre_id,opi_date_releve),
--Select count(ooi_ref_id) OVER( PARTITION BY ooi_ref_id), * FROM notes_expertise ORDER BY count desc, cai_gre_id, cli_code desc) --11221
ice_all_species AS (
SELECT DISTINCT on (ooi_ref_id) *,5 as species FROM notes_expertise WHERE cai_gre_id = 20 and ouv_lineaire_aval <50  -- SELECTing notes for glASs eel only WHEN < 50 km
UNION
SELECT DISTINCT on (ooi_ref_id) *,5 as species FROM notes_expertise WHERE cai_gre_id = 19
union 
SELECT DISTINCT on (ooi_ref_id) *, 45 as species FROM notes_expertise WHERE cai_gre_id = 1 
union 
SELECT DISTINCT on (ooi_ref_id) *, 3 as species FROM notes_expertise WHERE cai_gre_id = 3
union 
SELECT DISTINCT on (ooi_ref_id) *, 34 as species FROM notes_expertise WHERE cai_gre_id = 5
ORDER BY ooi_ref_id, species,  cli_code desc),
-- Si une des deux notes est  franchissable on considère que c'est franchissable

ice_unique AS (
SELECT DISTINCT on (ooi_ref_id, species) * FROM ice_all_species), --on prend la moins pénalisante

--  FRANCHISSABILITES DANS ROE
---PAS de données	

--  FRANCHISSABILITES DANS BDOE	
-- selection finale, je prends comme pour ICE la note la moins pénalisante (et tant pis pour la date il n'y avait que 15 doublons)
-- On choisira de rendre franchissable les ouvrages ayant zero et 1
orderedbdoe AS (
SELECT exm_ouv_id, exm_not_id, exm_esp_id, 
coalesce (exm_date, '1900-01-01') AS exm_date
FROM bdoe.expertise_montaison WHERE exm_esp_id in (3,5,34,45) ORDER BY exm_ouv_id, exm_esp_id, exm_not_id asc),
distinctbdoe AS (
SELECT distinct on (exm_ouv_id, exm_esp_id) * FROM orderedbdoe),--7645 --montepomi : 10482

decision_note AS (
	SELECT
	exm_ouv_id,
	exm_date, exm_esp_id, species,
-- En fonction de la date, on prend le plus récent 
-- quand on a a la fois un ice et un bdoe, et que la date de ice est plus récente que celle de bdoe (ou alors dboe est null et alors on a mis 1900)
 CASE WHEN exm_ouv_id is not null and ooi_ref_id is NOT NULL AND exm_date < opi_date_releve THEN NULL
            ELSE exm_not_id END AS exm_not_id,
       CASE WHEN exm_ouv_id is not null and ooi_ref_id is NOT NULL AND  opi_date_releve< exm_date THEN NULL
            ELSE cli_code END AS cli_code,            
            ooi_ref_id,
            opi_date_releve
-- alors on efface la note bdoe
-- A partir de maintenant on a soit l'une soit l'autre dans deux colonnes séparées , donc dans le CASE WHEN qui suit on prendra
-- toujours soit BDOE soit ICE
 FROM distinctbdoe FULL OUTER JOIN ice_unique on exm_ouv_id=ooi_ref_id and species = exm_esp_id), --10918
 
 --SELECT * FROM decision_note WHERE exm_ouv_id is not null and ooi_ref_id is NOT NULL 
final_franch AS( 
SELECT  COALESCE(exm_ouv_id,ooi_ref_id) AS ouv_id, 
COALESCE(exm_esp_id,species) AS esp_id,
CASE	 WHEN exm_not_id=0 THEN 209
		WHEN exm_not_id=1 THEN 210
		WHEN exm_not_id=2 THEN 211	
		WHEN exm_not_id=3 THEN 212		
		WHEN exm_not_id=4 THEN 213		
		WHEN exm_not_id=5 THEN 214
		WHEN cli_code='1' THEN 287
		WHEN cli_code='0.66' THEN 288
		WHEN cli_code='0.33' THEN 289
		WHEN cli_code='0' THEN 290
		END AS	po_no_obstruction_passability,
	CASE WHEN coalesce(exm_date,opi_date_releve)  = '1900-01-01' THEN NULL ELSE COALESCE(exm_date,opi_date_releve) END AS exm_date
FROM decision_note),--10879 -- montepomi : 31 482

/*countme AS (SELECT count (*)  over (partition by ouv_id), * FROM final_franch )
SELECT * FROM countme WHERE count>1*/
obstruction AS (
SELECT replace(id_original,'ROE','')::integer AS ouv_id, op_id 
FROM montepomi.dbeel_obstruction_place WHERE id_original like 'ROE%' ),--80324

--TODO : aller chercher les infos suivantes dans les différentes tables
add_column_bdoe as (
	select ouv_avis_tech_global_id,
		ouv_commentaire_chute_bdoe,
		ouv_commentaire_avis_bdoe,
		ouv_commentaires_bdoe,
		ouv_commentaire_mesures_bdoe,
		ouv_derasement_date,
		ouv_arasement_date,
		ouv_debut_activite,
		ouv_fin_activite
	from bdoe.ouvrage
	--trouver comment joindre avec l'uuid
),
add_column_roe as (
	select ref_commentaire_sous_type
	from roe.obstacle_referentiel
	--trouver comment joindre avec l'uuid (il faudra faire pareil que pour add_column_bdoe vu que code ROE dans les 2 cas)
),
hauteur_chute_date as (
	--ouv_debut_activité | NULL
	--à   > aller chercher les hauteurs de chutes dans cette période
	--ouv_arasement ou derasement

	--ouv_arasement derasement
	--à   > pour dérasement systématiquement 0 pour arasement chercher la hauteur de chute
	--NULL
)


-- ajouter ouv_atg_id de bdoe, ouv_commentaires_bdoe, ouv_commentaires_mesurebdoe, ouv_commentaire_roe
-- récupérer les différentes dates
-- ouv_debut_activite
-- la fin d'un ouvrage est une combinaison de :
-- ouv_fin_activite
-- ouv_derasement_date
-- ouv_arasement_date

/*
ouv_debut_activité | NULL
à   > aller chercher les hauteurs de chutes dans cette période
ouv_arasement ou derasement

ouv_arasement derasement
à   > pour dérasement systématiquement 0 pour arasement chercher la hauteur de chute
NULL
*/

-- pour les ouvrages arasés
 -- modifier pour aller chercher la hauteur de chute entre le début et la fin de l'activité de l'ouvrage



INSERT INTO montepomi.dbeel_physical_obstruction(
ob_id,
ob_no_origin,
ob_no_type,
ob_no_period,
ob_starting_date,
ob_ending_date,
ob_op_id,
ob_dp_id,
ot_no_obstruction_type,
ot_obstruction_number,
ot_no_mortality_type,
ot_no_mortality,
po_no_obstruction_passability,
po_obstruction_height,
po_downs_pb,
po_downs_water_depth,
po_presence_eel_pass,
po_method_perm_ev,
po_date_presence_eel_pass,
fishway_type,
date_last_update,
author_last_update,
comment_update,
mitigation_measure_no_id,
esp_id,
--Champs insérés
ouv_avis_tech_global_id,
ouv_commentaire_chute_bdoe,
ouv_commentaire_avis_bdoe,
ouv_commentaires_bdoe,
ouv_commentaire_mesures_bdoe,
ref_commentaire_sous_type_roe,
ouv_derasement_date,
ouv_arasement_date,
ouv_debut_activite,
ouv_fin_activite,
haut_chut_avant_abaissement,
haut_chut_apres_abaissement
)

SELECT 
  uuid_generate_v4() AS ob_id,
  11 AS ob_no_origin, -- raw data
  16 AS ob_no_type, -- obstruction
  74 AS ob_no_period, -- Unknown
  NULL AS ob_starting_date,
  NULL AS ob_ending_date,
  obstruction.op_id AS ob_op_id,
  dp_id AS ob_dp_id,
  obstruction_type_no_id AS ot_no_obstruction_type,-- physical
   1 AS ot_obstruction_number,
   NULL AS ot_no_mortality_type, 
   NULL AS ot_no_mortality,
   po_no_obstruction_passability, 
  hauteur_chute AS po_obstruction_height, 
  po_downs_pb, 
  NULL AS po_downs_water_depth, 
  po_presence_eel_pass, 
  CASE WHEN po_no_obstruction_passability in (209,210,211,212,213,214) THEN 'ROE expertise 5 class'
       WHEN po_no_obstruction_passability in (287,288,289,290) THEN 'ICE'
       ELSE NULL END AS po_method_perm_ev, 
  NULL AS po_date_presence_eel_pass, -- bullshit
  fishway_type, 
  current_date AS date_last_update, 
  'Cédric and Mathilde' AS author_last_update, 
  'initial insertion Height:' || coalesce(commentaire_hauteur_chute,'No height') AS comment_update, 
  mitigationmeasureid AS mitigation_measure_no_id,
  esp_id
FROM 
  obstruction
  LEFT JOIN final_franch ON final_franch.ouv_id=obstruction.ouv_id 	-- this view calculates passability (po_no_obstruction_passability) OK pAS de doublons
  LEFT JOIN height on height.ouv_id=obstruction.ouv_id -- contient hauteur chute, voir ce qu'on fait de la colonne commentaire_hauteur_chute  qui qualifie la hauteur OK pAS de doublons
  LEFT JOIN reception_devalaison on reception_devalaison.ouv_id=obstruction.ouv_id  --po_downs_pb (boolean) OK pAS de doublons
  LEFT JOIN presence_eel_pass  on presence_eel_pass.ouv_id=obstruction.ouv_id -- fishway_type and po_presence_eel_pass
  LEFT JOIN expertise_devalaison on expertise_devalaison.ouv_id=obstruction.ouv_id ,
  dbeel.data_provider WHERE dp_name = 'Pierre Sagnes'
  AND  obstruction_type_no_id IS NOT null

  ; --103309 1 m 54 serveur --> 109972 (Marion, Laetitia, Benjamin 31/03/23)




--select * from montepomi.dbeel_physical_obstruction  where author_last_update = 'Cédric and Mathilde' limit 10;
/*
with counts as (
select count(*) as "N", comment_update from montepomi.dbeel_physical_obstruction group by comment_update),
counts_france AS (
select "N", substring(comment_update from position('Height' in comment_update) for 50) as type_height from counts where comment_update like '%initial%' order by "N" desc),
--select * from counts_france)
total AS (
SELECT sum("N") as "N", 'Height:Total'::text as type_height from counts_france)
SELECT type_height, "N" from counts_france UNION SELECT type_height, "N" FROM total
*/
/*countme AS (SELECT count (*)  over (partition by op_id), * FROM final )
SELECT * FROM countme WHERE count>1*/
-- traiter les ouvrages liés


/*
with find_duplicates AS (
SELECT  count (*)  over (partition by op_id),* FROM montepomi.dbeel_physical_obstruction 
Join  montepomi.dbeel_obstruction_place on ob_op_id=op_id
join roe.roesudo on dbeel_op_id = op_id )
SELECT * FROM find_duplicates WHERE count>1
*/
/*
SELECT * FROm montepomi.dbeel_physical_obstruction WHERE author_lASt_update = 'Cédric and Mathilde' and date_lASt_update='2019-10-14';
BEGIn;
DELETE FROM montepomi.dbeel_physical_obstruction WHERE author_lASt_update = 'Cédric and Mathilde' and date_lASt_update='2019-10-14';
COMMIT;--80363

SELECT DISTINCT on (ob_op_id) * FROM montepomi.dbeel_physical_obstruction 
Join  montepomi.dbeel_obstruction_place on ob_op_id=op_id
join roe.roesudo on dbeel_op_id = op_id ) 

SELECT count(*) FROM uniqueCASE -- 80324
*/

/*-----------------------------------------------------
* PRISE D'EAU
----------------------------------------------------------*/
/*
 * RUNONCE CHANGES IN THE DBEEL
 */
 /*
BEGIN;
ALTER TABLE dbeel.hpp add COLUMN hpp_orientation_bar_rack numeric;
COMMENT ON COLUMN dbeel.hpp.hpp_orientation_bar_rack is 'Orientation of the bar rack, angle in degree between the bank and the bar rack';
COMMENT ON COLUMN dbeel.hpp.hpp_inclination_bar_rack IS 'Inclination of the bar rack, angle in degree between the bottom and the bar rack';
ALTER TABLE dbeel.hpp RENAME COLUMN hpp_flow_trAShrack TO hpp_flow_trashrack_bypass;
ALTER TABLE dbeel.hpp ADD COLUMN hpp_id_original text;
ALTER TABLE dbeel.hpp ADD COLUMN hpp_source text;
COMMIT;
*/

/*
DELETE DATA INTEGRATED IN HPP USING A JOIN FROM ROE, THIS IS ONLY NECESSARY IF WE NEED TO START AGAIN
FROM THIS STEP (i.e. physical obstruction is finished)
*/
  /*
BEGIN;
With hpp_inserted_FROM_france AS(
SELECT hpp_id 
	FROM montepomi.dbeel_obstruction_place 
	Join roe.roesudo on dbeel_op_id = op_id
	JOIn montepomi.dbeel_physical_obstruction On ob_op_id=op_id
	JOIN montepomi.dbeel_hpp on hpp_ob_id=ob_id)
DELETE FROM montepomi.dbeel_hpp WHERE hpp_id in (SELECT hpp_id FROM hpp_inserted_FROM_france);--4253
COMMIT;
*/


/*
INSERTION SCRIPT
*/

WITH roe_usage_hydro AS(
SELECT DISTINCT 'ROE'||usa_obs_id AS ouv_id
        FROM  roe.usage  
        WHERE usa_uty_id=5
        EXCEPT
        SELECT DISTINCT 'ROE'||usa_obs_id AS ouv_id
        FROM  roe.usage  
        WHERE usa_uty_id=12 --obsolete
        ), --5406
        
bdoe_usage_hydro AS (
	SELECT bdoe.ouvrage.* FROM bdoe.ouvrage 
	JOIN  roe_usage_hydro on roe_usage_hydro.ouv_id='ROE'||ouvrage.ouv_id
	),
	
--SELECT * FROM bdoe_usage_hydro --5326 
prise_eau_ice AS (
SELECT * FROM ice.obstacle_operation_ice 
	JOIN ice.operation_ice on opi_ooi_id=ooi_id 
	JOIN ice.partie_obstacle ON pao_opi_id=opi_id 
	JOIN ice.structure_obstacle on sto_pao_id=pao_id
        JOIN ice.prise_eau  on sto_id= pre_id
        ORDER BY opi_date_releve DESC
        ),
prise_eau_ice_unique AS (
	SELECT distinct ON (ooi_id) * FROM  prise_eau_ice
	),
	
--SELECT * FROM prise_eau_ice_unique --562

bdoe_ice_montepomi AS (  
	SELECT * 
	FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id
	JOIN montepomi.dbeel_physical_obstruction On ob_op_id=op_id
	JOIN prise_eau_ice_unique on ref_id_national='ROE'||ooi_ref_id
    LEFT JOIN bdoe_usage_hydro on 'ROE'||bdoe_usage_hydro.ouv_id=ref_id_national 
         ),
-- SELECT count(*) FROM bdoe_ice_montepomi WHERE (pre_id is not NULL OR usa_uty_id=5); --4727
-- SELECT count(*) FROM bdoe_ice_montepomi WHERE (pre_id is not NULL ); --505 (après jointure montepomi)
-- SELECT count(*) FROM bdoe_ice_montepomi WHERE usa_uty_id=5;--4462 (source roe après jointure montepomi) 
--SELECT * FROM bdoe_ice_montepomi limit 10;
union_roe_pass AS (
          SELECT fty_code::numeric AS cdtypedisp, 
          fpi_ref_id AS ouv_id
          FROM roe.franchissement_piscicole 
          join roe.franchissement_piscicole_type on fpi_fty_id=fty_id
          WHERE fty_code='4'--365
          and 'ROE'||fpi_ref_id in (SELECT ref_id_national FROM bdoe_ice_montepomi)          
 	  ),
 	  
roe_presence_bypass AS (
	SELECT DISTINCT on (ouv_id)
	ouv_id,
	TRUE AS hpp_presence_bypass
	FROM union_roe_pass 	
),  
 
--SELECT * FROM roe_presence_bypass-- 261 

angle_between_0_and_90 AS (
SELECT CASE WHEN pre_seuil_barrage_angle >90 THEN pre_seuil_barrage_angle - 90 
else pre_seuil_barrage_angle  end AS pre_seuil_barrage_angle_recode ,
*
FROM bdoe_ice_montepomi),

recode_angle AS (
SELECT 
CASE WHEN pre_seuil_barrage_angle_recode <30 THEN 241 --<30°
     WHEN pre_seuil_barrage_angle_recode >=30 AND pre_seuil_barrage_angle_recode <50 THEN 240 --[30-50°[
     WHEN pre_seuil_barrage_angle_recode >=50 AND pre_seuil_barrage_angle_recode <70 THEN 239 --[50-70°[
     WHEN pre_seuil_barrage_angle_recode >=70 AND pre_seuil_barrage_angle_recode <=90 THEN 238 --[70-90°] 
     END AS hpp_orient_flow_no_id,
     *
FROM angle_between_0_and_90),
-- On prend d'abord ICE puis bdoe
/*
Dans le Tableau ice il y a une partie ouvrage en dérivation, elle est appelée pre_derivation_debit mais c'est bien le débit réservé qui passe
dans l'ouvrage en dérivation, même si la representation de l'ouvrage principal comme un ouvrage en dérivation
ne correspond pas à la réalité terrain (pour les migrations).
*/
choix_bdoe_ice AS (
SELECT CASE WHEN pre_sppe_entrefer is NOT NULL THEN pre_sppe_entrefer
ELSE ouv_ecartement_grille -- celui là vient de bdoe
END AS pre_sppe_entrefer_final,
CASE WHEN pre_debit_maximum is NOT NULL THEN pre_debit_maximum
ELSE ouv_debit_maximal --  bdoe
END AS pre_debit_maximum_final,
CASE WHEN pre_derivation_debit is NOT NULL THEN  pre_derivation_debit
ELSE ouv_debit_reserve --  bdoe
END AS pre_derivation_debit_final,
CASE WHEN pre_debit_devalaison is NOT NULL THEN pre_debit_devalaison
ELSE ouv_debit_devalaison --  bdoe
END AS pre_debit_devalaison_final,
*
FROM
recode_angle),
--SELECT * FROM choix_bdoe_ice limit 10
final_insert AS (
SELECT 
  uuid_generate_v4() AS hpp_id,
  choix_bdoe_ice.ob_id AS hpp_ob_id,
  ref_nom AS hpp_name,
  NULL::integer hpp_main_grid_or_production , 
  roe_presence_bypass.hpp_presence_bypass AS hpp_presence_bypass, 
  NULL::numeric AS hpp_total_flow_bypass, 
  hpp_orient_flow_no_id,
  pre_existe_systeme_protection AS hpp_presence_of_bar_rack,
  choix_bdoe_ice.pre_sppe_entrefer_final AS hpp_bar_rack_space ,
  pre_lpg*pre_ltg AS hpp_surface_bar_rack,
  pre_b AS hpp_inclination_bar_rack,
  pre_a AS hpp_orientation_bar_rack, 
  pre_existence_exutoire AS hpp_presence_bypass_trashrack,
  pre_nombre_exutoire AS hpp_nb_trashrack_bypass,
  choix_bdoe_ice.pre_debit_maximum_final AS hpp_turb_max_flow,
  choix_bdoe_ice.pre_derivation_debit_final AS hpp_reserved_flow, -- oui c'est pAS une erreur voir explication plus bAS
  choix_bdoe_ice.pre_debit_devalaison_final AS hpp_flow_trashrack_bypass,
  choix_bdoe_ice.pre_puissance_amenagement AS hpp_max_power,
  'ROE'||pre_id AS hpp_id_original,
  'ICE' AS hpp_source
  FROM choix_bdoe_ice 
  FULL OUTER JOIN roe_presence_bypass on 'ROE'||roe_presence_bypass.ouv_id=id_original)
  SELECT * FROM final_insert;
  
INSERT INTO montepomi.dbeel_hpp
  (hpp_id ,
  hpp_ob_id ,
  hpp_name ,
  hpp_main_grid_or_production ,
  hpp_presence_bypass,
  hpp_total_flow_bypass , 
  hpp_orient_flow_no_id,
  hpp_presence_of_bar_rack,
  hpp_bar_rack_space,
  hpp_surface_bar_rack,
  hpp_inclination_bar_rack,
  hpp_orientation_bar_rack,
  hpp_presence_bypass_trAShrack,
  hpp_nb_trAShrack_bypass,
  hpp_turb_max_flow,
  hpp_reserved_flow,
  hpp_flow_trAShrack_bypass,
  hpp_max_power, 
  hpp_id_original,
  hpp_source) SELECT * FROM final_insert; --711 2020 (528 last run) (after correcting for missing geom bd_carthage)
-- 859 

SELECT count (*)  FROM montepomi.dbeel_hpp; --1502
SELECT count (*)  FROM montepomi.dbeel_hpp WHERE hpp_source ='ICE'; --859
-- SELECT * FROM  montepomi.dbeel_hpp ;


  
  
/*
 * CETTE TABLE CORRESPOND AUX OUVRAGES AYANT UN USAGE HYDROELECTRIQUE
 * QUI NE SONT PAS AUSSI OBSOLETE DANS L'USAGE
 * ET QUI SONT INSERES DANS LA TABLE DES OUVRAGES (dbeel_physical_obstruction)
 * 
 */
DROP TABLE IF EXISTS france.ouvrages_inseres_hpp;
CREATE TABLE france.ouvrages_inseres_hpp AS (
WITH roe_usage_hydro AS(
	SELECT DISTINCT 'ROE'||usa_obs_id AS ouv_id
        FROM  roe.usage  
        WHERE usa_uty_id=5
        EXCEPT
        SELECT DISTINCT 'ROE'||usa_obs_id AS ouv_id
        FROM  roe.usage  
        WHERE usa_uty_id=12 --obsolete
        ),
--SELECT count(*) FROM roe_usage_hydro --5393
roe_montepomi AS (  
	SELECT * 
	FROM montepomi.dbeel_obstruction_place 
	Join roe.roesudo on dbeel_op_id = op_id
	JOIn montepomi.dbeel_physical_obstruction On ob_op_id=op_id
	JOIN roe_usage_hydro on ref_id_national=roe_usage_hydro.ouv_id
         )

SELECT id_original AS ouv_id, geom_reproj AS geom FROM roe_montepomi  ) ; --4723  --> 4900

/*
 * CETTE TABLE FAIT LA LISTE DES OUVRAGES QUI ONT UN USAGE HYDROELECTRICITE
 * MAIS QUI N'ONT PAS ETE INSERES DANS LA TABLE OUVRAGE DE LA DBEEL, SOIT PARCE
 * QU'ILS SONT OBSOLETES OU DETRUITS OU DU MAUVAIS TYPE
 */

DROP TABLE IF EXISTS france.ouvrages_missing_hpp;
CREATE TABLE france.ouvrages_missing_hpp AS (
 WITH roe_usage_hydro AS(
	SELECT DISTINCT 'ROE'||usa_obs_id AS ouv_id
        FROM  roe.usage  
        WHERE usa_uty_id=5
        EXCEPT
        SELECT DISTINCT 'ROE'||usa_obs_id AS ouv_id
        FROM  roe.usage  
        WHERE usa_uty_id=12 --ouvrage obsolete
        ), --5406
 -- filter using an except cause       
 roe_filtered AS (
   SELECT ouv_id,
   st_transform(ref_position, 3035) AS geom
   FROM roe_usage_hydro JOIN roe.obstacle_referentiel on ouv_id=ref_id_national),
  --SELECT * FROM roe_filtered
  missing_dams AS (
  SELECT ouv_id FROM roe_filtered 
  EXCEPT
  SELECT ouv_id FROM france.ouvrages_inseres_hpp)
  --SELECT * FROm missing_dams
  --696

  SELECT * FROM roe_filtered WHERE ouv_id IN (SELECT ouv_id FROM missing_dams)
  ); --711 --> 682
 /*
  * 
  * VUE DES OUVRAGES INSERES A PARTIR D'ICE (et qui ont une description de la prise d'eau
  * et des turbines)
  */
DROP MATERIALIZED VIEW if EXISTS montepomi.view_dbeel_hpp;
CREATE MATERIALIZED VIEW montepomi.view_dbeel_hpp AS (
SELECT row_number() OVER (PARTITION BY true) AS id, * FROM montepomi.dbeel_obstruction_place
	JOIN montepomi.dbeel_physical_obstruction on op_id=ob_op_id 
    JOIN montepomi.dbeel_hpp on hpp_ob_id=ob_id
   --WHERE hpp_source='ICE' 
   ); --1532 => 5901 (AFTER SPAIN INSERTION)  ??? 2358 2020 (first run) 6687 don't forget to run this after the next chunk below

SELECT count(*) FROM montepomi.view_dbeel_hpp;

/*
* 
* INSERTION DES OUVRAGES MANQUANTS
* il faut qu'ils aient un usage hydroélectriques, qui soient entrés dans la TABLE physical_obstruction
* et qu'ils ne soient pas déjà insérés
* et qu'il n'existe pas dans les déjà insérés d'ouvrages liés.
* 
*/

-- linked dam renvoit une récursive avec tous les liens 
-- union ALL n'enlève pAS les enregitrements répétés comme UNION
-- mais le problème reste car le chemin ne sera jamais le meme
-- d'arrête dès qu'un gid est déjà dans chemin (id_original=ANY(chemin) =TRUE pour boucle)
WITH RECURSIVE linkeddams(op_id,op_op_id,profondeur,chemin,boucle) AS (
    SELECT op_id, op_op_id,1, 
    ARRAY[id_original::TEXT] AS chemin,
    FALSE AS boucle
    FROM montepomi.dbeel_obstruction_place 
    WHERE op_op_id IS NOT NULL
  UNION ALL
    SELECT * FROM (
    SELECT o.op_id,o.op_op_id, l.profondeur+1,
    array_append(chemin,id_original::TEXT) AS chemin,
    id_original::TEXT = ANY(chemin) AS boucle
    FROM linkeddams l JOIN
    montepomi.dbeel_obstruction_place o ON l.op_id=o.op_op_id) sub
    WHERE NOT sub.boucle
),
--SELECT * FROM linkeddams WHERE profondeur>1
dams_already_integrated AS (
	SELECT ouv_id FROM france.ouvrages_inseres_hpp JOIN
	montepomi.view_dbeel_hpp ON id_original=ouv_id
),
-- SELECT * FROM dams_already_integrated
dams_with_ancestor AS (
	SELECT ouv_id FROM dams_already_integrated 
	JOIN linkeddams  ON ouv_id=ANY(chemin)
),
--SELECT * FROM dams_with_ancestor),
-- SELECT * FROM dams_with_ancestor
-- Finally we insert dams that are not linked in anyway with other hpp dam either 
-- if they have been already inserted or they are linked (even degree 3) to a 
-- dam that wAS already inserted
ouv_id_to_insert AS (
	SELECT ouv_id FROM france.ouvrages_inseres_hpp
	EXCEPT (
	SELECT ouv_id FROM dams_with_ancestor
	UNION
	SELECT ouv_id FROM dams_already_integrated
)),
--SELECT count(*) FROM ouv_id_to_insert --3725  --(On enlève depuis 5393 des ouvrages déjà insérés ayant un usage Hydroélectrique)
bdoe_montepomi AS (  
	SELECT * 
	FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id
	JOIN montepomi.dbeel_physical_obstruction On ob_op_id=op_id
	LEFT JOIN bdoe.ouvrage ON 'ROE'||ouvrage.ouv_id=ref_id_national 
         ),
union_roe_pass AS (
  SELECT fty_code::numeric AS cdtypedisp, 
  fpi_ref_id AS ouv_id
  FROM roe.franchissement_piscicole 
  join roe.franchissement_piscicole_type on fpi_fty_id=fty_id
  WHERE fty_code='4'), 	  
roe_presence_bypass AS (
	SELECT DISTINCT on (ouv_id)
	ouv_id,
	TRUE AS hpp_presence_bypass
	FROM union_roe_pass 	
)


INSERT INTO montepomi.dbeel_hpp
  (hpp_id ,
  hpp_ob_id ,
  hpp_name,
  hpp_main_grid_or_production ,
  hpp_presence_bypass,
  hpp_total_flow_bypass , 
  hpp_orient_flow_no_id,
  hpp_presence_of_bar_rack,
  hpp_bar_rack_space,
  hpp_surface_bar_rack,
  hpp_inclination_bar_rack,
  hpp_orientation_bar_rack,
  hpp_presence_bypass_trAShrack,
  hpp_nb_trAShrack_bypass,
  hpp_turb_max_flow,
  hpp_reserved_flow,
  hpp_flow_trAShrack_bypass,
  hpp_max_power, 
  hpp_id_original,
   hpp_source) 


SELECT 
  uuid_generate_v4() AS hpp_id,
  p.ob_id AS hpp_ob_id,
  r.ref_nom AS hpp_name,
  NULL hpp_main_grid_or_production , 
  rp.hpp_presence_bypass AS hpp_presence_bypass, 
  NULL AS hpp_total_flow_bypass, 
  NULL AS hpp_orient_flow_no_id,
  NULL AS hpp_presence_of_bar_rack,
  bdoe_montepomi.ouv_ecartement_grille AS hpp_bar_rack_space ,
  NULL AS  hpp_surface_bar_rack,
  NULL AS  hpp_inclination_bar_rack,
  NULL AS  hpp_orientation_bar_rack, 
  NULL AS  hpp_presence_bypass_trAShrack,
  NULL AS  hpp_nb_trAShrack_bypass,
  bdoe_montepomi.ouv_debit_maximal AS hpp_turb_max_flow,
  bdoe_montepomi.ouv_debit_reserve AS hpp_reserved_flow, -- oui c'est pas une erreur voir explication plus bas
  bdoe_montepomi.ouv_debit_devalaison AS hpp_flow_trAShrack_bypass,
  NULL AS hpp_max_power,
  ouv_id_to_insert.ouv_id AS hpp_id_original,
  'ROE' AS hpp_source
  FROM ouv_id_to_insert
  JOIN montepomi.dbeel_obstruction_place o ON ouv_id_to_insert.ouv_id=id_original
  JOIN montepomi.dbeel_physical_obstruction p ON ob_op_id=op_id
  JOIN roe.roesudo r ON ref_id_national=ouv_id_to_insert.ouv_id
  LEFT JOIN bdoe_montepomi ON 'ROE'||bdoe_montepomi.ouv_id=ouv_id_to_insert.ouv_id -- si on fait un join on passe à 3714 donc il y a moins d'ouvrages dans bdoe ???
  LEFT JOIN roe_presence_bypass rp ON 'ROE'||rp.ouv_id=ouv_id_to_insert.ouv_id; --4329 --> 4471

/*
THIS VIEW MUST BE RELAUNCHED NOW WE HAVE INTEGRATED NEW DATA
*/
DROP MATERIALIZED VIEW if EXISTS montepomi.view_dbeel_hpp;
CREATE MATERIALIZED VIEW montepomi.view_dbeel_hpp AS (
SELECT row_number() OVER (PARTITION BY true) AS id, * FROM montepomi.dbeel_obstruction_place
	JOIN montepomi.dbeel_physical_obstruction on op_id=ob_op_id 
    JOIN montepomi.dbeel_hpp on hpp_ob_id=ob_id
   --WHERE hpp_source='ICE' 
   ); --5973

SELECT * FROM montepomi.view_dbeel_hpp  WHERE hpp_id='9988fd61-2e87-4397-a6dc-8c1b08b4c092'
--SELECT country,count(*) FROM montepomi.view_dbeel_hpp group by country

-- TDOO INSERER DES PRISES D'EAU AVEC RIEN SI USAGE HYDROELECTRIQUE

/*
no_id;no_code;no_type;no_name
238;1;orient_flow;[70-90°]
239;2;orient_flow;[50-70°[
240;3;orient_flow;[30-50°[
241;4;orient_flow;<30°
*/



---------------------------
-- présence possible de duplicats
------------------------------
/*
With count_ice AS (
SELECT count (*) OVER (partition by ooi_ref_id) AS count, * 
	FROM montepomi.dbeel_obstruction_place 
	join roe.roesudo on dbeel_op_id = op_id
	JOIn montepomi.dbeel_physical_obstruction On ob_op_id=op_id
	JOIN ice.obstacle_operation_ice on ref_id_national='ROE'||ooi_ref_id
	JOIN ice.operation_ice on opi_ooi_id=ooi_id 
	JOIN ice.partie_obstacle ON pao_opi_id=opi_id 
	JOIN ice.structure_obstacle on sto_pao_id=pao_id
        JOIN ice.prise_eau  on sto_id= pre_id )
  SELECT * FROM count_ice WHERE count>1
*/



/*
tur_id;tur_libelle
1;Pelton    --248
2;Francis   --245
3;Kaplan    --247
4;Autre     --243

no_id;no_code;no_type;no_name
242;;Turbine type;Horizontal axis Kaplan (bulb)
243;;Turbine type;Other (please specify)
244;;Turbine type;Double Francis (spiral case)
245;;Turbine type;Francis unspecified
246;;Turbine type;Turbine with fixed blade propeller and vertical axis
247;;Turbine type;Kaplan not specified
248;;Turbine type;Pelton
249;;Turbine type;Reversible
250;;Turbine type;Kaplan (model of S-turbine)
251;;Turbine type;Turbine with fixed blade propeller and horizontal axis
252;;Turbine type;Unknown
253;;Turbine type;Vertical axis Kaplan
254;;Turbine type;Francis without volute
255;;Turbine type;Francis (spiral case)
256;;Turbine type;Banki-Michell (cross-flow)
257;;Turbine type;VLH
258;;Turbine type;Archimedean screw turbine
259;;Turbine type;Water wheel turbine (aqualienne)
260;;Turbine type;Water wheel turbine (others)
261;;Turbine type;Propeller unspecified
*/
/*
BEGIN;
ALTER TABLE montepomi.dbeel_turbine DROP  CONSTRAINT c_fk_turb_hpp_id;
ALTER TABLE montepomi.dbeel_turbine ADD  CONSTRAINT c_fk_turb_hpp_id
FOREIGN KEY (turb_hpp_id)
      REFERENCES montepomi.dbeel_hpp (hpp_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;
COMMIT;

SELECT * FROM ice.turbine_usine_hydrolelectrique; --378
*/
 
/*
 * BEGIN;
 * DELETE FROM montepomi.dbeel_turbine;
 * COMMIT;
 */
--SELECT * FROM montepomi.dbeel_turbine;
--SELECT * FROM montepomi.dbeel_hpp
WITH hpp_full AS(
SELECT * 
	FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id
	JOIN montepomi.dbeel_physical_obstruction On ob_op_id=op_id
	JOIN montepomi.dbeel_hpp on hpp_ob_id=ob_id),
ice_pre_turbine AS(
SELECT pre_id, turbine_usine_hydrolelectrique.* FROM ice.prise_eau 	
JOIN ice.turbine_usine_hydrolelectrique on tuh_pre_id=pre_id),
--SELECT * FROM hpp_full
final_insert AS (
 SELECT op_id, op_placename, hpp_id,  ice_pre_turbine.* 
 FROM hpp_full JOIN ice_pre_turbine on hpp_id_original='ROE'||pre_id) --290
--SELECT * FROM final_insert

INSERT INTO montepomi.dbeel_turbine
SELECT
  uuid_generate_v4() AS turb_id ,
  hpp_id AS turb_hpp_id,
  CASE WHEN tuh_tur_id=1 THEN 248 
       WHEN tuh_tur_id=2 THEN 245 
       WHEN tuh_tur_id=3 THEN 247 
       WHEN tuh_tur_id=4 THEN 243 END AS turb_turbine_type_no_id,
  NULL::boolean AS turb_in_service,
  NULL::NUMERIC AS turb_max_power,
  tuh_debit_armement AS turb_min_working_flow ,
  tuh_hauteur_chute AS turb_hpp_height, -- TODO LATER USE OTHER HEIGHT WHEN AVAILABLE
  tuh_diametre_roue AS turb_diameter ,
  tuh_vitesse_rotation AS turb_rotation_speed,
  tuh_nombre_pale AS turb_nb_blades,
  tuh_debit_max AS turb_max_turbine_flow,
  NULL AS turb_description
  FROM final_insert; --343 ->647 (2020) -- 670

With uniques as (SELECT distinct on (turb_hpp_id) turb_hpp_id FROM montepomi.dbeel_turbine)
SELECT  count(*) from uniques


-- TODO collecter les données vers R à l'aide d'un script, et prévoir les updates de la bASe.


-- Notes pour souffrir plus tard

----------- 
-- Aller chercher touts les usines hydroelctriques qui sont ouvrage filles, et les rajouter, mais pour les cumuls à la montée ne prendre que les ouvrages pères
-- si il y a une centrale sur l'ouvrage pere il faut que les cacluls de proportions de débit passant au niveau des deux centrales soient calculées comme si c'était un seul ouvrage.
-----------


-- TODO dbeel_bypass



/*******************
 * TEMPORARY CORRECTIONS THESE HAVE BEEN CORRECTED AT THE SOURCE REMOVE AT NEXT RUN
 **********************/
--Three obstacles still wrong 
UPDATE montepomi.dbeel_physical_obstruction  SET(author_last_update, po_obstruction_height) = 
('Cédric correction temporaire BDOE', 1.05) FROM (
SELECT * 
FROM montepomi.dbeel_obstruction_place 
JOIN montepomi.dbeel_physical_obstruction ON ob_op_id = op_id 
WHERE id_original='ROE45141') sub 
WHERE dbeel_physical_obstruction.ob_id=sub.ob_id; --still 53 m Moulin de l'esperance

UPDATE montepomi.dbeel_physical_obstruction  SET(author_last_update, po_obstruction_height) = 
('Cédric correction temporaire BDOE', 0.55) FROM (
SELECT * 
FROM montepomi.dbeel_obstruction_place 
JOIN montepomi.dbeel_physical_obstruction ON ob_op_id = op_id 
WHERE id_original='ROE89249') sub 
WHERE dbeel_physical_obstruction.ob_id=sub.ob_id;  --seuil répartiteur 27.78m

UPDATE montepomi.dbeel_physical_obstruction  SET(author_last_update, po_obstruction_height) = 
('Cédric correction temporaire BDOE', 0.95) FROM (
SELECT * 
FROM montepomi.dbeel_obstruction_place 
JOIN montepomi.dbeel_physical_obstruction ON ob_op_id = op_id 
WHERE id_original='ROE45139') sub 
WHERE dbeel_physical_obstruction.ob_id=sub.ob_id; --47.97 m seuil répartiteur quartier du Grès

UPDATE montepomi.dbeel_physical_obstruction  SET(author_last_update, po_obstruction_height) = 
('Cédric correction temporaire BDOE',2.60) FROM (
SELECT * 
FROM montepomi.dbeel_obstruction_place 
JOIN montepomi.dbeel_physical_obstruction ON ob_op_id = op_id 
WHERE id_original='ROE44738') sub 
WHERE dbeel_physical_obstruction.ob_id=sub.ob_id; -- vannage Croze et Peyron 131 m

UPDATE montepomi.dbeel_physical_obstruction  SET(author_last_update, po_obstruction_height) = 
('Cédric correction temporaire BDOE',2.10) FROM (
SELECT * 
FROM montepomi.dbeel_obstruction_place 
JOIN montepomi.dbeel_physical_obstruction ON ob_op_id = op_id 
WHERE id_original='ROE45144') sub 
WHERE dbeel_physical_obstruction.ob_id=sub.ob_id;




-- Iffezheim (corrected now)
/* UPDATE montepomi.dbeel_physical_obstruction po SET  (po_obstruction_height,  date_last_update, author_last_update,  comment_update)=
(11.8, current_date, 'Cédric and Maria', COALESCE(po.comment_update||', ','')||'Height NULL in bdoe, correction asked to Pierre') 
FROM (SELECT * FROM montepomi.dbeel_obstruction_place
     JOIN montepomi.dbeel_physical_obstruction ON ob_op_id=op_id
      where id_original= 'ROE44609') sub
      where sub.ob_id=po.ob_id;
      */
--Barrage d'Arzal (corrected now)
 /*UPDATE montepomi.dbeel_physical_obstruction po SET  (po_obstruction_height,  date_last_update, author_last_update,  comment_update)=
(2.10, current_date, 'Cédric and Maria', COALESCE(po.comment_update||', ','')||'Height NULL in bdoe, correction asked to Pierre') 
FROM (SELECT * FROM montepomi.dbeel_obstruction_place
     JOIN montepomi.dbeel_physical_obstruction ON ob_op_id=op_id
      where id_original= 'ROE58432') sub
      where sub.ob_id=po.ob_id;
*/

      
