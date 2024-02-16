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
--CREATE SCHEMA montepomi;
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
-- DELETE FROM montepomi.dbeel_obstruction_place CASCADE; --86563

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
UPDATE roe.roesudo set ref_position_carthage= ST_Transform(ST_SetSRID(ref_position_carthage,4326),3035);
REINDEX TABLE roe.roesudo;
-- SELECT * FROM roe.roesudo WHERE ref_position_carthage is NULL;
--SELECT count(*) FROM roe.roesudo WHERE ref_position_carthage IS NULL; 

-- projection des données ROE ICE sur le réseau RHT (couche france.rn), nécessite de trouver le point sur le tronçon RHT qui est le plus proche de notre ouvrage
SELECT addgeometrycolumn('roe','roesudo','geom_reproj',3035,'POINT',2);

-- SELECT count (*) FROM roe.roesudo WHERE ref_position_carthage is not null;
UPDATE roe.roesudo set	geom_reproj = sub2.geom_reproj from(
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
UPDATE roe.roesudo set geom_reproj = sub2.geom_reproj FROM (
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
	
WITH data_import as (
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

--BEGIN;
--select count(*) from montepomi.dbeel_obstruction_place; --91188

-- Benjamin: faut il supp le seuil du Moulin de Coulonge et la Prise d'eau EDF Cordemais pour montepomi
-- pour l'instant pas executé
/*
select *
from montepomi.dbeel_obstruction_place
WHERE id_original in ('ROE106058','ROE88566')
*/
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
	WHERE eta_nom In ('En construction','En projet')); --3545 -- ceux qui ne sont pAS physiquement présent -->4189 
	-->120 (Marion, Laetitia, Benjamin 31/03/23 il y en avait bcp en détruit entièrement donc)

-- on supprime plus les dérasés
/*
	DELETE FROM montepomi.dbeel_obstruction_place 
	WHERE op_id in (
	SELECT op_id FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id 
	JOIN bdoe.ouvrage on 'ROE'||ouv_id=ref_id_national
	WHERE ouv_derasement); --198 -->554
*/
	
-- SELECT count(*) FROM montepomi.dbeel_obstruction_place WHERE country ='FR'; --110 013 (SP+PT+FR) 
--85035 (après suppression) -->86563 -->91188 (Marion, Laetitia, Benjamin 31/03/23)

--COMMIT;
--ROLLBACK;
 
/*
 * On repasse dessus pour supprimer les liens qui n'existent plus (meme requete que precedement)
 */
UPDATE roe.roesudo set dbeel_op_id = NULL;--113415 -->117340



UPDATE roe.roesudo SET dbeel_op_id = op_id 
FROM montepomi.dbeel_obstruction_place 
WHERE dbeel_obstruction_place.id_original=roesudo.ref_id_national;	--85035 rows affected, 8.6 secs execution time. 
-->86563 -->91188 (Marion, Laetitia, Benjamin 31/03/23)



-- Copied from dbeel view obstruction to be able to launch everything at once.

DROP TABLE IF EXISTS montepomi.join_obstruction_rn;
CREATE TABLE montepomi.join_obstruction_rn as(
  
   with projection as ( 
        SELECT r.idsegment, 
          op_id,                          
      geom,
      st_distance(r.geom,d.the_geom) as distance,
      1-ST_LineLocatePoint(ST_GeometryN(r.geom,1),ST_ClosestPoint(r.geom,d. the_geom)) AS position_ouvrage_segment
    FROM france.rn r
    JOIN montepomi.dbeel_obstruction_place  d
    ON st_dwithin(r.geom, d.the_geom,0.01)
    order by idsegment, distance desc)
SELECT distinct on (op_id) op_id, idsegment, position_ouvrage_segment from projection
);
create index idx_montepomi_join_obstruction_rn_idsegment ON montepomi.join_obstruction_rn using btree(idsegment); --183msec

-- Il y a des ouvrages qui sont mal projetés sur le RHT.
-- on charge la bd_topage dans la base eda2.3/bdtopo_hydrographie/courseau_topage2023
-- on fait une jointure spatiale entre le ROE et la bd_topage sur le champ 
-- roe.obstacle_referentiel.ref_position_bdtopo=bdtopo_hydrographie.courseau_topage2023.geom
-- 1449 ouvrages ROE en Loire-Bretagne avec ref_position_bdtopo=NULL / 7708 sur france entière
-- SELECT count(*) as france, COUNT(CASE WHEN ref_bassin  = 'LOIRE-BRETAGNE' THEN 1 END) as loire_bretagne FROM roe.obstacle_referentiel WHERE ref_position_bdtopo IS null; --7708 en France
-- on créée un index sur la bd_topage pour la colonne geom et sur roe.ref_position_bdtopo
-- CREATE INDEX idx_courseau_topage2023_geom ON bdtopo_hydrographie.courseau_topage2023 USING GIST(geom);
-- CREATE INDEX idx_courseau_topage2023_geom4326 ON bdtopo_hydrographie.courseau_topage2023 USING GIST(st_transform(geom,4326));
-- CREATE INDEX idx_roe_ref_position_topage ON roe.obstacle_referentiel USING GIST(ref_position_bdtopo);
-- CREATE INDEX idx_roe_ref_position_topage_2154 ON roe.obstacle_referentiel USING GIST(st_transform(ref_position_bdtopo,2154));
-- select count(*) from roe.obstacle_referentiel where ref_position is null; --124

--on créée france.link_roe_topage pour stocker la jointure spatiale entre les obstacles du ROE et la bd_topage
--on est content d'avoir fait l'index spatial sur le st_transform pour avoir les 2 geom dans la même projection
drop table france.link_roe_topage;
create table france.link_roe_topage as (
with dist_roe_topo AS (
    SELECT
        o.ref_id_national,
        c.cdoh,
        c.topooh,
        --ST_Distance(o.ref_position_bdtopo, st_transform(c.geom,4326)) AS distance,
        ROW_NUMBER() OVER (PARTITION BY ref_id_national ORDER BY ST_Distance(st_transform(o.ref_position_bdtopo,2154), c.geom)) AS rn,
        o.ref_position_bdtopo,
        c.geom as geom
    from roe.obstacle_referentiel o
    JOIN bdtopo_hydrographie.courseau_topage2023 c
   		 ON ST_DWithin(st_transform(o.ref_position_bdtopo,2154),c.geom, 100)
	where ref_position_bdtopo IS NOT null  
)
SELECT
    ref_id_national,
    cdoh,
    topooh,
    true as direct_link_topo,
    geom,
    ref_position_bdtopo
FROM dist_roe_topo
WHERE rn = 1
); --102361


-- on s'occupe des ouvrages qui n'ont pas de ref_position_bdtopo et on les ajoute dans france.link_roe_topage
-- au lieu de pointer sur le point projeté sur la bd topo on prend le point par défaut dans le ROE (ref_position)
WITH dist_roe_topo AS (
    SELECT
        o.ref_id_national,
        c.cdoh,
        c.topooh,
        ROW_NUMBER() OVER (PARTITION BY ref_id_national ORDER BY ST_Distance(st_transform(o.ref_position,2154), c.geom)) AS rn,
        o.ref_position,
        c.geom as geom
    from roe.obstacle_referentiel o
    JOIN bdtopo_hydrographie.courseau_topage2023 c
   		 ON ST_DWithin(st_transform(o.ref_position,2154), c.geom, 1000)
   	where ref_position_bdtopo IS null and ref_position is not null
), tab as(
SELECT
    ref_id_national,
    cdoh,
    topooh,
    false as direct_link_topo,
    geom,
    ref_position
FROM dist_roe_topo
WHERE rn = 1
)
insert into france.link_roe_topage
select *
from tab
;--5873

--On fait la jointure entre link_roe_topage et montepomi.join_obstruction_rn pour avoir à la fois les anciens idsegment et les nouveaux
--suite à la jointure spatiale. Attention bd_topo=segment très long (tout le cours d'eau) qui se joignent à plein d'idsegment rht
-- ici ça marche car on fait la jointure entre bd_topo et idsegment
with good as(
--on récupère les idsegment avec même code topage et même idsegment
	SELECT l.*,rn.idsegment id_old
	FROM france.link_roe_topage l
	JOIN montepomi.dbeel_obstruction_place d  ON d.id_original=l.ref_id_national
	JOIN montepomi.join_obstruction_rn rn ON rn.op_id= d.op_id 
	JOIN france.rht_courseau_bdtopage c ON c.cdoh=l.cdoh and c.idsegment=rn.idsegment --75631
),
bad as (
--on récupère les autres lignes = celles où on a des soucis
select *
from france.link_roe_topage l
where ref_id_national not in (select ref_id_national from good)
),
tab as (
--on a besoin d'une double jointure code topage et une projection des idsegments proche des points ROE (on refait une jointure spatiale)
select bad.*,
		rn.idsegment as idsegment_new,
		ROW_NUMBER() OVER (PARTITION BY ref_id_national ORDER BY ST_Distance(st_transform(ref_position_bdtopo,3035), rn.geom)) AS rownumber
from bad 
join france.rn on st_dwithin(rn.geom,st_transform(ref_position_bdtopo,3035),100)
),tab_final as (
--on récupère que les lignes où idsgment_old différent de idsegment_new
select tab.*,jrn.idsegment as idsegment_old,jrn.op_id
from tab
JOIN montepomi.dbeel_obstruction_place d  ON d.id_original=tab.ref_id_national
left join montepomi.join_obstruction_rn jrn on jrn.op_id= d.op_id 
where rownumber=1 and jrn.idsegment<>tab.idsegment_new
)
--on met à jour join_obstruction_rn avec les nouveaux code idsegment et on a vérifié qu'on récupéré bien l'ouvrage à Redon sur le Canal de Nantes
--à Brest plutôt que sur la Vilaine, Cédric est tout content !
update montepomi.join_obstruction_rn set idsegment=idsegment_new from tab_final where tab_final.op_id=join_obstruction_rn.op_id; --252 (249)



--calcul distance entre position_bd_topo et chaque idsegment

DROP TABLE IF EXISTS montepomi.join_obstruction_rn_downstream;
CREATE TABLE montepomi.join_obstruction_rn_downstream as(
WITH downstreamjoin AS (  
  select unnest(regexp_split_to_array(ltree2text(path),E'\\.+')) as vecteurchemin,
  rn.idsegment AS idsegmentsource  
  from france.rn 
)
 SELECT j.op_id, 
 j.position_ouvrage_segment, 
 downstreamjoin.* FROm downstreamjoin 
 JOIN montepomi.join_obstruction_rn j ON j.idsegment=downstreamjoin.vecteurchemin
);

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


