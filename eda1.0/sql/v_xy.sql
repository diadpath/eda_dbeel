/*SET client_encoding = 'WIN1252';
SELECT * from france.t_barunique_buq LIMIT 25000;

--ALTER TABLE "compilation_definitiveprojeteeT" SET SCHEMA  france
ALTER TABLE "correspondance" SET SCHEMA  france
SELECT * FROM france.compilation LIMIT 100
SELECT * FROM france.correspondance LIMIT 100
-- les tables dans la jointure

SELECT * FROM (
SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
"Auteur"='PM Chapon') AS bar
JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id

-- selection des 351 ouvrages qui ne sont pas dans la jointure

SELECT * FROM (
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
*/
-- Pour Marion les X et Y projettés des barrages
-- DROP VIEW france.v_xy

CREATE OR REPLACE VIEW france.v_xy AS 

SELECT 	"ID_final" As id_final,
	ouv_id,
	"Pt_LII_X" as xproj,
	"Pt_LII_Y" as yproj
 FROM (
	SELECT * FROM france.t_barunique_buq buq WHERE "Auteur" = 'Pierre Steinbach' OR
	"Auteur"='PM Chapon'
) AS bar
JOIN t_ouvrage_ouv ouv ON bar."ID_base_new" =ouv.ouv_id

UNION

SELECT "ID_final" As id_final,
	ouv_id,
	"Pt_LII_X" as xproj,
	"Pt_LII_Y" as yproj
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

ORDER BY ouv_id;


