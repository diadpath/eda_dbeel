---------------------------------------
-- SCRIPT D'EXPORT DES DONNEES POUR Allan Dufouil, stagiaire fish pass travaillant 
-- dans le cotentin
-- EDA 2.2.1 12/07/2019
------------------------------------------------
/*
Tout d’abord merci pour l’aiguillage vers le site du PONAPOMI. J’ai donc bien réussi à télécharger les couches EDA, notamment la couche dcdf (densité anguilles jaunes) et cumul_aval (densité anguilles argentées). J’ai extrait les données qui m’intéressaient et j’ai quelques questions :
-    Pour certains cours d’eau situés sur la zone d’étude, on observe des densités moyennes en anguilles argentées nettement supérieures aux densités d’anguilles jaunes. A titre d’exemple, la Grande Crique présente une densité de 106 ind. AG /100 m² contre 16 ind. J / 100 m². La densité d’anguilles argentées se base bien sur celle des anguilles jaunes (utilisation du modèle d’argenture) ?
-    On aimerait également avoir des biomasses produites sur ces mêmes axes. Les données ne semblent pas apparaitre sur les couches dcdf et cumul_aval. On a bien les données de densité en individus pour chacun des tronçons. Auriez-vous une couche présentant les largeurs et longueurs de ces tronçons afin de pouvoir évaluer une biomasse en kg/ha.
*/


ALTER TABLE public."Secteur d'étude" SET SCHEMA temp;
DROP TABLE IF EXISTS temp.result_cotentin2;
CREATE TABLE temp.result_cotentin2 AS (
SELECT vv.*, rr.the_geom FROM rht.rhtvarmod vv 
JOIN rht.rhtvs2 rr ON vv.id_drain=rr.id_drain
JOIN temp."Secteur d'étude" tt ON st_intersects(st_transform(tt.geom,3035),rr.the_geom))

/*
cd C:\temp\stage_allan_dufouil_fish_pass
pgsql2shp -u postgres -f "result_cotentin2" -u postgres eda2.2 temp.result_cotentin2