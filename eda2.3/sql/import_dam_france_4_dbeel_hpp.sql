/*-----------------------------------------------------
* PRISE D'EAU
----------------------------------------------------------*/
---- Hydropower plants:
-- TODO ajouter conformite devalaison et atg
--ATTENTION à vérifier les contraintes de clé étrangères pour que ça référence dans le bon schéma (montepomi au lieu de dbeel)
DROP TABLE IF EXISTS montepomi.dbeel_hpp ;
CREATE TABLE montepomi.dbeel_hpp (
        CONSTRAINT c_pk_hpp_id PRIMARY KEY (hpp_id),
        CONSTRAINT c_fk_hpp_orient_flow_no_id FOREIGN KEY (hpp_orient_flow_no_id) REFERENCES dbeel_nomenclature.orient_flow (no_id) ON UPDATE CASCADE ON DELETE CASCADE,
        CONSTRAINT c_fk_hpp_ob_id FOREIGN KEY (hpp_ob_id) REFERENCES montepomi.dbeel_physical_obstruction (ob_id) ON UPDATE CASCADE ON DELETE CASCADE
) INHERITS (dbeel.hpp);


---- Bypass:
DROP TABLE IF EXISTS montepomi.dbeel_bypass;
CREATE TABLE montepomi.dbeel_bypass (
        CONSTRAINT c_pk_bypass_id PRIMARY KEY (bypass_id),
  CONSTRAINT c_fk_bypass_hpp_id FOREIGN KEY (bypass_hpp_id) REFERENCES montepomi.dbeel_hpp (hpp_id) ON UPDATE CASCADE ON DELETE CASCADE
) INHERITS (dbeel.bypass); 


---- Turbine:
DROP TABLE IF EXISTS montepomi.dbeel_turbine;
CREATE TABLE montepomi.dbeel_turbine (
        CONSTRAINT c_pk_turb_id PRIMARY KEY (turb_id),
  CONSTRAINT c_fk_turb_hpp_id FOREIGN KEY (turb_hpp_id) REFERENCES montepomi.dbeel_hpp (hpp_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT c_fk_turb_turbine_type_no_id FOREIGN KEY (turb_turbine_type_no_id) REFERENCES dbeel_nomenclature.turbine_type (no_id) ON UPDATE CASCADE ON DELETE CASCADE
) INHERITS (dbeel.turbine); 


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
TODO ajouter ATG et conformite devalaison
*/


DELETE FROM montepomi.dbeel_hpp; --7176

--create table montepomi.titi (like montepomi.dbeel_hpp);
WITH roe_usage_hydro AS(
SELECT DISTINCT 'ROE'||usa_obs_id AS ouv_id
        FROM  roe.usage  
        WHERE usa_uty_id=5
        EXCEPT
        SELECT DISTINCT 'ROE'||usa_obs_id AS ouv_id
        FROM  roe.usage  
        WHERE usa_uty_id=12 --obsolete
        ), --5406 -->5582 (16/06)
        
bdoe_usage_hydro AS (
	SELECT bdoe.ouvrage.* FROM bdoe.ouvrage 
	JOIN  roe_usage_hydro on roe_usage_hydro.ouv_id='ROE'||ouvrage.ouv_id
	),
--SELECT * FROM bdoe_usage_hydro --5326 5508  -->5508(16/06)

--Il faut joindre ice.operation_ice et ice.obstacle_operation_ice car pour un même ouvrage on peut avoir plusieurs
--date de création/relève et on n'en veut qu'une. On prend la date min
join_operation_ice_obstacle as(
	select ooi_ref_id,coalesce(min(opi_date_releve) ,min(opi_date_creation)) AS opi_date
	FROM ice.obstacle_operation_ice 
	join ice.operation_ice on opi_ooi_id=ooi_id
	group by ooi_ref_id
),
join2 as(
	select *
	from ice.operation_ice opi
	join ice.obstacle_operation_ice ooi on ooi.ooi_id=opi.opi_ooi_id
),

prise_eau_ice AS (
SELECT j2.*,
		partie_obstacle.*,
		structure_obstacle.*,
		prise_eau.*,
		j.opi_date
FROM join_operation_ice_obstacle j
	join join2 j2 on j2.ooi_ref_id=j.ooi_ref_id and (j2.opi_date_releve=j.opi_date or j2.opi_date_creation=j.opi_date)
	JOIN ice.partie_obstacle ON pao_opi_id=j2.opi_id 
	JOIN ice.structure_obstacle on sto_pao_id=pao_id
    JOIN ice.prise_eau  on sto_id= pre_id
    ORDER BY j.opi_date DESC
        ),
        
prise_eau_ice_unique AS (
SELECT distinct ON (ooi_id) * FROM prise_eau_ice
),
--select * from prise_eau_ice_unique where ooi_ref_id=10787 --ooi_id=4518 ou 4656
        
--SELECT * FROM prise_eau_ice_unique --925
-- when joining with roesudo nrow = 925 similar to prise_eau_ice
-- later on joining to obstruction place drop to 891 probably because some dams are identified as 'grille de pisciculture'
-- joining without using the date create more line (all period for the same dam are joinded) --994
-- when using the latest date only for the prise d'eau we have -- 970
-- we have decided not to use date as the date is when the dam was expertised not the date when a HPP was present
-- SO we remove lines
  --AND opi_date >= ob_starting_date
  --AND opi_date < ob_ending_date
-- 

bdoe_ice_montepomi AS (  
	SELECT * 
	FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id
	JOIN montepomi.dbeel_physical_obstruction On ob_op_id=op_id
	JOIN prise_eau_ice_unique on ref_id_national='ROE'||ooi_ref_id
    LEFT JOIN bdoe_usage_hydro on 'ROE'||bdoe_usage_hydro.ouv_id=ref_id_national 
         ), --970
-- SELECT count(*) FROM bdoe_ice_montepomi WHERE (pre_id is not NULL OR usa_uty_id=5); --4727
-- SELECT count(*) FROM bdoe_ice_montepomi WHERE (pre_id is not NULL ); --505 (après jointure montepomi)
-- SELECT count(*) FROM bdoe_ice_montepomi WHERE usa_uty_id=5;--4462 (source roe après jointure montepomi) 
--SELECT * FROM bdoe_ice_montepomi; --970 (16/06)

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
 
--SELECT * FROM roe_presence_bypass-- 261 --> 78 (16/06)

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
 
  INSERT INTO montepomi.dbeel_hpp(
  --INSERT INTO montepomi.titi(
  hpp_id ,
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
  hpp_source) SELECT * FROM final_insert;
  --711 2020 (528 last run) (after correcting for missing geom bd_carthage)
-- 859 -->970(16/06) --> 915 after correction from Marion (remove duplicated values 29/06)


--SELECT count (*)  FROM montepomi.dbeel_hpp; --1502 -->970(16/06)
--SELECT count (*)  FROM montepomi.dbeel_hpp WHERE hpp_source ='ICE'; --859 -->970(16/06) 915 after correction from Marion (remove duplicated values 29/06)


/*
  with doublon as(
  SELECT hpp_ob_id ,count(*) as compte
FROM montepomi.titi
GROUP BY 1
ORDER BY 2 desc
)
select * from montepomi.titi where hpp_ob_id in( select hpp_ob_id from doublon where compte>1) 
*/


/*
 * CETTE TABLE CORRESPOND AUX OUVRAGES AYANT UN USAGE HYDROELECTRIQUE
 * QUI NE SONT PAS OBSOLETE DANS L'USAGE
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
        WHERE usa_uty_id=12 --obsolete --5582(16/06)
        ),
--SELECT count(*) FROM roe_usage_hydro --5393
roe_montepomi AS (  
	SELECT * 
	FROM montepomi.dbeel_obstruction_place --91188
	Join roe.roesudo on dbeel_op_id = op_id --91188
	JOIn montepomi.dbeel_physical_obstruction On ob_op_id=op_id --93962
	JOIN roe_usage_hydro on ref_id_national=roe_usage_hydro.ouv_id --5547
         )

SELECT id_original AS ouv_id, geom_reproj AS geom FROM roe_montepomi  ) ; --4723  --> 4900 --> 5547(16/06) : on en perd un peu sans doute car dans dbeel_obstruction_place on a écarté des type (grille pisci)

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
        ), --5406 -->5582(16/06)
 -- filter using an except cause       
 roe_filtered AS (
   SELECT ouv_id,
   st_transform(ref_position, 3035) AS geom
   FROM roe_usage_hydro 
   JOIN roe.obstacle_referentiel on ouv_id=ref_id_national),
 -- SELECT * FROM roe_filtered --5582(16/06)
  missing_dams AS (
  SELECT ouv_id FROM roe_filtered 
  EXCEPT
  SELECT ouv_id FROM france.ouvrages_inseres_hpp)
  --SELECT * FROm missing_dams
  --696 -->628 (16/06)

  SELECT * FROM roe_filtered WHERE ouv_id IN (SELECT ouv_id FROM missing_dams)
  ); --711 --> 682 -->628(16/06)
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
	  --970 (16/06) 915 (29/06)
--SELECT count(*) FROM montepomi.view_dbeel_hpp;

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
    SELECT 
    o.op_id,o.op_op_id, 
    l.profondeur+1,
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
-- SELECT * FROM dams_already_integrated --730 (16/06)
dams_with_ancestor AS (
	SELECT ouv_id FROM dams_already_integrated 
	JOIN linkeddams  ON ouv_id=ANY(chemin)
),
--SELECT * FROM dams_with_ancestor), --115 (16/06)
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
/*
bdoe_montepomi AS (  
	SELECT * 
	FROM montepomi.dbeel_obstruction_place 
	JOIN roe.roesudo on dbeel_op_id = op_id
	JOIN montepomi.dbeel_physical_obstruction On ob_op_id=op_id
	LEFT JOIN bdoe.ouvrage ON 'ROE'||ouvrage.ouv_id=ref_id_national 
         ),
*/
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
  ouvrage.ouv_ecartement_grille AS hpp_bar_rack_space ,
  NULL AS  hpp_surface_bar_rack,
  NULL AS  hpp_inclination_bar_rack,
  NULL AS  hpp_orientation_bar_rack, 
  NULL AS  hpp_presence_bypass_trAShrack,
  NULL AS  hpp_nb_trAShrack_bypass,
  ouvrage.ouv_debit_maximal AS hpp_turb_max_flow,
  ouvrage.ouv_debit_reserve AS hpp_reserved_flow, -- oui c'est pas une erreur voir explication plus bas
  ouvrage.ouv_debit_devalaison AS hpp_flow_trAShrack_bypass,
  NULL AS hpp_max_power,
  ouv_id_to_insert.ouv_id AS hpp_id_original,
  'ROE' AS hpp_source
  FROM ouv_id_to_insert
  JOIN montepomi.dbeel_obstruction_place o ON ouv_id_to_insert.ouv_id=id_original
  JOIN montepomi.dbeel_physical_obstruction p ON ob_op_id=op_id
  JOIN roe.roesudo r ON ref_id_national=ouv_id_to_insert.ouv_id
  LEFT JOIN bdoe.ouvrage ON 'ROE'||ouvrage.ouv_id=ouv_id_to_insert.ouv_id -- si on fait un join on passe à 3714 donc il y a moins d'ouvrages dans bdoe ???
  LEFT JOIN roe_presence_bypass rp ON 'ROE'||rp.ouv_id=ouv_id_to_insert.ouv_id; --4329 --> 4471 -->6241(16/06) --> 5053

  
/*
-- 29/06 recherche de doublons....
select * from montepomi.dbeel_hpp where hpp_ob_id='40fd7012-1a0f-4050-95a9-725372d8bcb0'
-- avant il y avait des doublons maintenant il n'y en a plus

WITH doublon AS(
SELECT hpp_ob_id ,count(*) AS compte
FROM montepomi.dbeel_hpp
GROUP BY 1
ORDER BY 2 desc
)
select * from montepomi.dbeel_hpp where hpp_ob_id in( select hpp_ob_id from doublon where compte>1) --2182
-- Il me reste 4 lignes qui n'ont pas le même ouv_id ?
ROE1030
ROE1026
ROE6704
ROE6707
*/
/*
THIS VIEW MUST BE RELAUNCHED NOW WE HAVE INTEGRATED NEW DATA
*/
DROP MATERIALIZED VIEW if EXISTS montepomi.view_dbeel_hpp;
CREATE MATERIALIZED VIEW montepomi.view_dbeel_hpp AS (
SELECT row_number() OVER (PARTITION BY true) AS id, * FROM montepomi.dbeel_obstruction_place
	JOIN montepomi.dbeel_physical_obstruction on op_id=ob_op_id 
    JOIN montepomi.dbeel_hpp on hpp_ob_id=ob_id
   --WHERE hpp_source='ICE' 
   ); --5973 -->7211(27/06) --> 5968(29/06) apres dedoublonnage

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
 * INTEGRATION DE LA TABLE TURBINE
 *
 */ 
/*
 * BEGIN;
 * DELETE FROM montepomi.dbeel_turbine;
 * COMMIT;
 */

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
  FROM final_insert; --343 ->647 (2020) -- 670 -->835(16/06) 707(29/06)

/*  
 SELECT * FROM montepomi.dbeel_turbine;
 SELECT * FROM montepomi.dbeel_hpp;
 With uniques as (SELECT distinct on (turb_hpp_id) turb_hpp_id FROM montepomi.dbeel_turbine)
 SELECT  count(*) from uniques
-/






      
