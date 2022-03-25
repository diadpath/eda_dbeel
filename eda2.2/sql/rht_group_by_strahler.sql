

/*
Première fonction, une récursive avec jointure sur strahler, et nextdownid et id_drain.
Les étapes sont les suivantes : creation d'une table parcours (id_drain_aval, id_drain, nextdownid, strahler, geom)
Puis jointure de cette table parcours avec le rht de manière récursive
*/



DROP function if exists rht.recursive_strahler(INTEGER);
CREATE FUNCTION rht.recursive_strahler(INTEGER)

RETURNS TABLE(id_drain_aval INTEGER,  strahler integer, geom geometry) AS
$$
BEGIN
RETURN QUERY
-- une récursive doit d'abord définir une récursive qui correspond à la première étape et qui sera appelée d'abord dans la récursive 
-- en première étape puis va ajouter des lignes tant que la deuxième partie de la récursive ramène des lignes (il y a des tronçons à l'amont du même rang de strahler)
	WITH RECURSIVE parcours AS(
		SELECT
			r0.id_drain as id_drain_aval,
			r0.id_drain,
			r0.nextdownid,
			r0.strahler,
			r0.the_geom
		FROM
			(SELECT rh1.*, rh2.strahler from rht.rhtvs2  rh1
			join rht.attributs_rht_fev_2011_vs2 rh2 on rh1.id_drain=rh2.id_drain) r0 -- sous table de jointure car les champs sont dans deux tables
		WHERE
			r0.id_drain in ($1)
	       -- ci dessous le tableau a la meme structure, UNION ALL est nécessaire sinon plante (UNION récursif pas implémenté)
	       UNION ALL SELECT
			parcours.id_drain_aval, -- j'aurais besoin plus tard de faire un group by id_drain_aval quand j'aurais plusieurs tronçons de meme rang partant d'endroits différent
		       r1.id_drain,
		       r1.nextdownid,
		       r1.strahler,
		       r1.the_geom
		FROM
			parcours -- partie récursive, on rappelle la première table
		JOIN 	(SELECT rh3.*, rh4.strahler from rht.rhtvs2  rh3
			join rht.attributs_rht_fev_2011_vs2 rh4 on rh3.id_drain=rh4.id_drain) r1 -- sous table de jointure car les champs sont dans deux tables
		ON  (parcours.id_drain,parcours.strahler) = (r1.nextdownid,r1.strahler)
		)
          SELECT parcours.id_drain_aval, parcours.strahler, st_union(geom) FROM parcours group by parcours.id_drain_aval,parcours.strahler;
END
$$
  LANGUAGE plpgsql VOLATILE;

-- pour tester la fonction 

SELECT * from   rht.recursive_strahler(214925); -- retourne toutes les lignes de la Loire avec strahler 8

-- Celle là m'a demandé du temps car rht.recursive_strahler(id_drain) renvoit un record, il faut utiliser (la_fonction) .*
-- La différence avec la précédente est que je l’appelle sur le résultat d’une requète, par exemple tous les strahler de rang 5 (avec limit 3 pour aller plus vite)
-- renvoit bien trois lignes aggrégées une par id_drain aval

with myiddrain as (select id_drain from rht.attributs_rht_fev_2011_vs2 where strahler=5 limit 3) 
 SELECT (rht.recursive_strahler(id_drain)).*   FROM myiddrain

--TODO creer une fonction prenant comme paramètre un id_drain mer, la fonction s'initialise avec un strahler correspondant au strahler max
-- sur le bassin ,et redescend jusqu'au 2 (je suppose que tu vas joindre les 2 et 1 en fin donc il faut adapter avec un if ou un case when
-- A chaque étape la fonction lancer la fonction récursive et va écrire des lignes dans une table créée au préalable



