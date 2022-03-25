DROP VIEW IF EXISTS france.v_troncon_barrage CASCADE;
CREATE OR REPLACE VIEW france.v_troncon_barrage AS 

--SET client_encoding = 'WIN1252';


SELECT * FROM(

SELECT CAST(bar0."ID_base_new" AS Character varying(7))AS ouv_id, 
	NULL::Character varying(20) AS den_denivele,
	bar0."Id_BDCARTHAGE",
	bar0."ID_final",
	bar0."Id_trhyd" ,
	NULL::Real AS fba_valeurnote 
   
	FROM (
		SELECT * FROM france.t_barunique_buq buq 
		WHERE "Auteur" != 'Pierre Steinbach' AND "Auteur"!='PM Chapon') AS bar0
		

UNION

SELECT ouv.ouv_id,den.den_denivele,bar."Id_BDCARTHAGE",bar."ID_final",bar."Id_trhyd",CAST(fran.fba_valeurnote AS real) FROM (
SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
"Auteur"='PM Chapon') AS bar
JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id
JOIN t_denivele_den den ON bar."ID_base_new" =den.den_ouv_id
LEFT JOIN (SELECT fba.fba_ouv_id,fba.fba_tyn_typenote,CAST(fba.fba_valeurnote AS real),fba.fba_tax_code 
FROM t_franchisbar_fba fba 
WHERE fba.fba_tyn_typenote = 'SCORE2' 
AND CAST(fba.fba_valeurnote AS real) >0 
AND fba.fba_tax_code='2038')AS fran ON bar."ID_base_new" =fran.fba_ouv_id

UNION

SELECT ouv_id,den.den_denivele,buq."Id_BDCARTHAGE",buq."ID_final",buq."Id_trhyd",CAST(fran.fba_valeurnote as real) 
FROM (
  SELECT ouv_id, "ID_final" AS idfinalsanscorres FROM (
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

JOIN t_denivele_den den ON buq."ID_base_new" =den.den_ouv_id
LEFT JOIN (
SELECT fba.fba_ouv_id,fba.fba_tyn_typenote,CAST(fba.fba_valeurnote AS real),fba.fba_tax_code 
FROM t_franchisbar_fba fba 
WHERE fba.fba_tyn_typenote = 'SCORE2' 
AND CAST(fba.fba_valeurnote AS real) >0 
AND fba.fba_tax_code='2038')AS fran ON buq."ID_base_new" =fran.fba_ouv_id) AS joint;

-- Jointure table barrage et table troncon
DROP VIEW IF EXISTS france.jointure;
CREATE OR REPLACE VIEW france.jointure AS 
SELECT * from france.v_troncon_barrage v
JOIN france.troncon2 tron ON tron.id_bdcarthage = v."Id_BDCARTHAGE";

-- SELECT * FROM france.jointure limit 100