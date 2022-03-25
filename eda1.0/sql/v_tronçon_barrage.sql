/* vue france.jointure
 et vue v_troncon_barrage
 dernièremodif 9 juillet 2008
 il y a une erreur, la première condition du premier select WHERE "Auteur" != 'Pierre Steinbach' AND "Auteur"!='PM Chapon'
 ne garantit pas que des barrages soient déja présents (ils sont les doublons de Pierre etPM Chapon)
 je rajoute une étape dans les vues

*/


--SET client_encoding = 'WIN1252';

DROP VIEW IF EXISTS france.v_troncon_barrage_direct CASCADE;
CREATE OR REPLACE VIEW france.v_troncon_barrage_direct AS 

SELECT ouv.ouv_id,den.den_denivele,bar."Id_BDCARTHAGE",bar."ID_final",bar."Id_trhyd",CAST(fran.fba_valeurnote AS real) FROM (
SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
"Auteur"='PM Chapon') AS bar
JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
JOIN t_denivele_den den ON bar."ID_base_new" =den.den_ouv_id
LEFT JOIN (SELECT fba.fba_ouv_id,fba.fba_tyn_typenote,CAST(fba.fba_valeurnote AS real),fba.fba_tax_code 
FROM t_franchisbar_fba fba 
-- WHERE fba.fba_tyn_typenote = 'SCORE2' modif 21/07/08
WHERE fba.fba_tyn_typenote = 'EXPERTISE' 
AND CAST(fba.fba_valeurnote AS real) >0 
AND fba.fba_tax_code='2038')AS fran ON bar."ID_base_new" =fran.fba_ouv_id;


DROP VIEW IF EXISTS france.v_troncon_barrage_indirect CASCADE;
CREATE OR REPLACE VIEW france.v_troncon_barrage_indirect AS 

-- jointure indirecte
SELECT 	ouv_id,
	den.den_denivele,
	buq."Id_BDCARTHAGE",
	buq."ID_final",  -- ici je choisis l'ID_final de celui qui a été projetté
	buq."Id_trhyd",
	CAST(fran.fba_valeurnote as real) 

FROM (
 --07 SELECT * FROM(
  --06
  SELECT ouv_id, "ID_final" AS idfinalsanscorres FROM (
  -- 05 SELECT * FROM(
	-- 04ouv_id sans coores
    SELECT ouv_id FROM t_ouvrage_ouv ouv
     EXCEPT 
     (
		
     SELECT ouv_id  FROM (
     --ouvrages avec correpondance directe 03 SELECT *  FROM (
     SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
     "Auteur"='PM Chapon') AS bar
     JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
     --03
     )
     --fin 04 ouv_id sans corresp
   ) AS ouvsanscorres
  JOIN (
    SELECT * FROM france.compilation
    WHERE "Auteur" = 'Pierre Steinbach' OR "Auteur"='PM Chapon'
        ) AS comp
  ON ouvsanscorres.ouv_id=comp."ID_base_new"
  --ORDER BY "ID_final"--05
  --06
) AS loosers
JOIN france.correspondance cor ON loosers.idfinalsanscorres = "ID_final_doublon"
JOIN france.t_barunique_buq buq ON "ID_final_unique"=buq."ID_final"

JOIN t_denivele_den den ON ouv_id =den.den_ouv_id
LEFT JOIN (
SELECT fba.fba_ouv_id,fba.fba_tyn_typenote,CAST(fba.fba_valeurnote AS real),fba.fba_tax_code 
FROM t_franchisbar_fba fba 
-- WHERE fba.fba_tyn_typenote = 'SCORE2' modif 21/07/08
WHERE fba.fba_tyn_typenote = 'EXPERTISE' 
AND CAST(fba.fba_valeurnote AS real) >0 
AND fba.fba_tax_code='2038')AS fran ON ouv_id =fran.fba_ouv_id
ORDER BY "ID_final"
--07

;
-- jointure des deux précédentes

DROP VIEW IF EXISTS france.v_troncon_barrage CASCADE;
CREATE OR REPLACE VIEW france.v_troncon_barrage AS 

select * FROM france.v_troncon_barrage_direct
UNION
select * FROM  france.v_troncon_barrage_indirect;


--- vue pour laquelle je rajoute ceux qui ne sont pas déjà récupérés de manière directe ou indirecte

DROP VIEW IF EXISTS france.v_troncon_barrage2 CASCADE;
CREATE OR REPLACE VIEW france.v_troncon_barrage2 AS 

SELECT CAST(bar0."ID_base_new" AS Character varying(7))AS ouv_id, 
	NULL::Character varying(20) AS den_denivele,
	bar0."Id_BDCARTHAGE",
	bar0."ID_final",
	bar0."Id_trhyd" ,
	NULL::Real AS fba_valeurnote 
   
	FROM (
		
		--01
		--00 selection des ID_final pas déja pris
		SELECT * FROM(
		SELECT "ID_final" AS id FROM france.t_barunique_buq
		EXCEPT (
		SELECT "ID_final" AS id from france.v_troncon_barrage) )AS lesdoubles
		-- fin 00
		JOIN france.t_barunique_buq buq 
		ON lesdoubles.id=buq."ID_final"
		--01 --31006
		) AS bar0
		
UNION

SELECT * FROM france.v_troncon_barrage;


-- Jointure table barrage et table troncon
DROP VIEW IF EXISTS france.jointure;
CREATE OR REPLACE VIEW france.jointure AS 
SELECT * from france.v_troncon_barrage2 v
JOIN france.troncon2 tron ON tron.id_bdcarthage = v."Id_BDCARTHAGE";




--SELECT COUNT (*) FROM france.t_barunique_buq =>35333
-- SELECT COUNT(*) FROM france.compilation => 47217
--SELECT COUNT(*) FROM france.correspondance => 48250
-- SELECT COUNT(*) FROM france.v_troncon_barrage2 --34684 (manque 649)
-- SELECT COUNT(*) FROM france.v_troncon_barrage --4419 --4131 direct + 288 indirects (manque 536)
-- SELECT COUNT(*) FROM t_ouvrage_ouv -- 4955 
-- SELECT * FROM france.jointure limit 100
-- SELECT COUNT(*) FROM france.jointure --34684

SELECT * FROM france.v_troncon_barrage ORDER BY "ID_final"
SELECT * FROM france.v_troncon_barrage where "ID_final"=41
SELECT * FROM france.v_troncon_barrage_direct where "ID_final"=41
SELECT * FROM france.v_troncon_barrage_indirect where "ID_final"=41
select * from france.compilation where "ID_final"=41
select * from france.t_barunique_buq where "ID_final"=41
select * from france.correspondance where "ID_final_doublon"=41
SELECT * FROM france.v_troncon_barrage2 limit 10