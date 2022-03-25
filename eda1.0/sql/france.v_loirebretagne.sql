-- france.v_loirebretagne.sql
--requète pour joindre la table de Laurent acec la notre soit de manière directe 
-- soit de manière indirecte



DROP VIEW IF EXISTS france.v_loirebretagne_score2 CASCADE;
CREATE OR REPLACE VIEW france.v_loirebretagne_score2 AS 

--SET client_encoding = 'WIN1252';
-- score2
SELECT * FROM(

-- Vue directe des relations (ceux de notre base qui ont été retenus dans la projection

SELECT 	ouv.ouv_id,
	den.den_denivele,bar."Id_BDCARTHAGE",
	bar."ID_final",
	bar."Id_trhyd",
	bar."Pt_LII_X" as xproj,
	bar."Pt_LII_Y" as yproj,
	CAST(fran.fba_valeurnote AS real) 
FROM (

SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
"Auteur"='PM Chapon') AS bar
JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
JOIN t_denivele_den den ON bar."ID_base_new" =den.den_ouv_id

LEFT JOIN (SELECT 	fba.fba_ouv_id,
			fba.fba_tyn_typenote,
			CAST(fba.fba_valeurnote AS real),
			fba.fba_tax_code 
		FROM t_franchisbar_fba fba 
		WHERE fba.fba_tyn_typenote = 'SCORE2' 
		AND CAST(fba.fba_valeurnote AS real) >0 
		AND fba.fba_tax_code='2038')AS fran ON bar."ID_base_new" =fran.fba_ouv_id
		--order by ouv_id
		
UNION

-- vue indirecte
SELECT 	ouv_id,
	den.den_denivele,	
	buq."Id_BDCARTHAGE",
	buq."ID_final",
	buq."Id_trhyd",
	loosers."Pt_LII_X" as xproj,  -- valeur projettée de notre barrage mê si au final c'est l'autre qui est projetté
	loosers."Pt_LII_Y" as yproj,
	CAST(fran.fba_valeurnote as real)
-- 01 
--SELECT * 
FROM (
  -- 00 jointure de l'id ouvrage de notre base ouv_id avec ID_final qui est dans latable totale france compilation
  SELECT ouv_id, "ID_final" AS idfinalsanscorres,"Pt_LII_X","Pt_LII_Y" FROM (
    --liste des id sanscorrespondance
    SELECT ouv_id FROM t_ouvrage_ouv ouv
     EXCEPT 
     (
     SELECT ouv_id  FROM (
     SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
     "Auteur"='PM Chapon') AS bar
     JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
     )
     --finlistedesidsanscorrespondance
   ) AS ouvsanscorres
  JOIN (
    -- Liste totale de tous y compris les doublons (table dre Laurent)
    SELECT * FROM france.compilation
    WHERE "Auteur" = 'Pierre Steinbach' OR "Auteur"='PM Chapon'
    order by "ID_base_new"
     -- fin liste totale de tous y compris les doublons 4629 lignes
        ) AS comp
  ON ouvsanscorres.ouv_id=comp."ID_base_new"
  --fin00
) AS loosers
JOIN france.correspondance cor ON loosers.idfinalsanscorres = "ID_final_doublon"
--01
JOIN france.t_barunique_buq buq ON "ID_final_unique"=buq."ID_final"
--01
JOIN t_denivele_den den ON ouv_id =den.den_ouv_id
LEFT JOIN (
SELECT fba.fba_ouv_id,fba.fba_tyn_typenote,CAST(fba.fba_valeurnote AS real),fba.fba_tax_code 
FROM t_franchisbar_fba fba 
WHERE fba.fba_tyn_typenote = 'SCORE2' 
AND fba.fba_tax_code='2038')AS fran ON ouv_id =fran.fba_ouv_id
ORDER BY ouv_id
-- fin vue indirecte
) AS joint;


-- score
DROP VIEW IF EXISTS france.v_loirebretagne_score CASCADE;
CREATE OR REPLACE VIEW france.v_loirebretagne_score AS 


SELECT * FROM(

SELECT 	ouv.ouv_id,
	den.den_denivele,bar."Id_BDCARTHAGE",
	bar."ID_final",
	bar."Id_trhyd",
	bar."Pt_LII_X" as xproj,
	bar."Pt_LII_Y" as yproj,
	CAST(fran.fba_valeurnote AS real) 
FROM (

SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
"Auteur"='PM Chapon') AS bar
JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
JOIN t_denivele_den den ON bar."ID_base_new" =den.den_ouv_id

LEFT JOIN (SELECT 	fba.fba_ouv_id,
			fba.fba_tyn_typenote,
			CAST(fba.fba_valeurnote AS real),
			fba.fba_tax_code 
		FROM t_franchisbar_fba fba 
		WHERE fba.fba_tyn_typenote = 'SCORE' 
		AND CAST(fba.fba_valeurnote AS real) >0 
		AND fba.fba_tax_code='2038')AS fran ON bar."ID_base_new" =fran.fba_ouv_id
UNION

SELECT ouv_id,
	den.den_denivele,
	buq."Id_BDCARTHAGE",
	buq."ID_final",
	buq."Id_trhyd",
	loosers."Pt_LII_X" as xproj,  -- valeur projettée de notre barrage mê si au final c'est l'autre qui est projetté
	loosers."Pt_LII_Y" as yproj,
	CAST(fran.fba_valeurnote as real) 
FROM (
  SELECT ouv_id, "ID_final" AS idfinalsanscorres, "Pt_LII_X","Pt_LII_Y" FROM (
    SELECT ouv_id FROM t_ouvrage_ouv ouv
     EXCEPT 
     (
     SELECT ouv_id  FROM (
     SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
     "Auteur"='PM Chapon') AS bar
     JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
     )
   ) AS ouvsanscorres
  JOIN (
    SELECT * FROM france.compilation
    WHERE "Auteur" = 'Pierre Steinbach' OR "Auteur"='PM Chapon'
        ) AS comp
  ON ouvsanscorres.ouv_id=comp."ID_base_new"
) AS loosers
JOIN france.correspondance cor ON loosers.idfinalsanscorres = "ID_final_doublon"
JOIN france.t_barunique_buq buq ON "ID_final_unique"=buq."ID_final"

JOIN t_denivele_den den ON ouv_id =den.den_ouv_id

LEFT JOIN (
SELECT fba.fba_ouv_id,fba.fba_tyn_typenote,CAST(fba.fba_valeurnote AS real),fba.fba_tax_code 
FROM t_franchisbar_fba fba 
WHERE fba.fba_tyn_typenote = 'SCORE' 
AND fba.fba_tax_code='2038')AS fran ON ouv_id  =fran.fba_ouv_id) AS joint;

-- expertise
DROP VIEW IF EXISTS france.v_loirebretagne_expertise CASCADE;
CREATE OR REPLACE VIEW france.v_loirebretagne_expertise AS 


SELECT * FROM(

SELECT 	ouv.ouv_id,
	den.den_denivele,bar."Id_BDCARTHAGE",
	bar."ID_final",
	bar."Id_trhyd",
	bar."Pt_LII_X" as xproj,
	bar."Pt_LII_Y" as yproj,
	CAST(fran.fba_valeurnote AS real) 
FROM (

SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
"Auteur"='PM Chapon') AS bar
JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
JOIN t_denivele_den den ON bar."ID_base_new" =den.den_ouv_id

LEFT JOIN (SELECT 	fba.fba_ouv_id,
			fba.fba_tyn_typenote,
			CAST(fba.fba_valeurnote AS real),
			fba.fba_tax_code 
		FROM t_franchisbar_fba fba 
		WHERE fba.fba_tyn_typenote = 'EXPERTISE' 
		AND CAST(fba.fba_valeurnote AS real) >0 
		AND fba.fba_tax_code='2038')AS fran ON bar."ID_base_new" =fran.fba_ouv_id
UNION

SELECT ouv_id,
	den.den_denivele,
	buq."Id_BDCARTHAGE",
	buq."ID_final",
	buq."Id_trhyd",
	loosers."Pt_LII_X" as xproj,  -- valeur projettée de notre barrage mê si au final c'est l'autre qui est projetté
	loosers."Pt_LII_Y" as yproj,
	CAST(fran.fba_valeurnote as real) 
FROM (
  SELECT 	ouv_id, 
		"ID_final" AS idfinalsanscorres,
		 "Pt_LII_X",
		 "Pt_LII_Y" 
   FROM (
    SELECT ouv_id FROM t_ouvrage_ouv ouv
     EXCEPT 
     (
     SELECT ouv_id  FROM (
     SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
     "Auteur"='PM Chapon') AS bar
     JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
     )
   ) AS ouvsanscorres
  JOIN (
    SELECT * FROM france.compilation
    WHERE "Auteur" = 'Pierre Steinbach' OR "Auteur"='PM Chapon'
        ) AS comp
  ON ouvsanscorres.ouv_id=comp."ID_base_new"
) AS loosers
JOIN france.correspondance cor ON loosers.idfinalsanscorres = "ID_final_doublon"
JOIN france.t_barunique_buq buq ON "ID_final_unique"=buq."ID_final"

JOIN t_denivele_den den ON ouv_id  =den.den_ouv_id

LEFT JOIN (
SELECT fba.fba_ouv_id,fba.fba_tyn_typenote,CAST(fba.fba_valeurnote AS real),fba.fba_tax_code 
FROM t_franchisbar_fba fba 
WHERE fba.fba_tyn_typenote = 'EXPERTISE' 
AND CAST(fba.fba_valeurnote AS real) >0
AND fba.fba_tax_code='2038')AS fran ON ouv_id  =fran.fba_ouv_id) AS joint;

-- Jointure des différentes vues dans une seule 
DROP VIEW IF EXISTS france.v_loirebretagne_total CASCADE;
CREATE OR REPLACE VIEW france.v_loirebretagne_total AS 
SELECT  ouv_id,
	den_denivele, 
	"Id_BDCARTHAGE",
	"ID_final",
	"Id_trhyd",
	"score2",
	"score",
	"expertise"

	FROM(
 SELECT v.ouv_id,
	v.den_denivele, 
	v."Id_BDCARTHAGE",
	v."ID_final",
	v."Id_trhyd",
	v.fba_valeurnote AS "score2"	
     FROM   france.v_loirebretagne_score2 v) AS SCORE2
     
FULL JOIN 

       (SELECT v.ouv_id AS ouv,	
	v.fba_valeurnote AS "score"	
	FROM   france.v_loirebretagne_score v) AS SCORE
	ON SCORE2.ouv_id=SCORE.ouv
	
FULL JOIN 

	(SELECT v.ouv_id AS ouv,	
	v.fba_valeurnote AS "expertise"
	FROM   france.v_loirebretagne_expertise v) AS EXPERTISE
	ON SCORE2.ouv_id=EXPERTISE.ouv

ORDER BY ouv_id;





