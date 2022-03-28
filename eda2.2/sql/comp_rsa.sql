 /*
COMPARAISON AUX DONNEES DU RSA ET AUTRE
*/
drop
	table
		rht.devalaison;

create
	table
		rht.devalaison(
			site text,
			id_drain integer,
			annee integer,
			estim numeric,
			estim_eda numeric
		);

-- petite verif
 alter table
	rht.devalaison add column surface_reelle_ha numeric;

alter table
	rht.devalaison add column surface_rht_ha numeric;

alter table
	rht.devalaison add column nb_eda_corr numeric;

-- nombres corrigés avec les surfaces en eau
 alter table
	rht.devalaison add column size_str_eda numeric ARRAY[4];

select
	sum( total )/ 10 ^6
from
	rht.silver;

-- 7.84 =>1.82 OK	
 select
	*
from
	rht.silver limit 10 
	
 /*
FONCTION rht.eda_prediction
Cette fonction eda_prediction(site, annee) calcule le produit vectoriel du vecteur de proportion annuelle par rapport à 2017 et 
de la somme des effectifs par taille à l'amont d'un id_drain donné (y compris l'id_drain lui même).
Elle écrit le résultat par update dans la table (les valeurs doivent être présentes) et donne un output
*/
create
	or replace function rht.eda_prediction(
		_site text,
		_annee integer
	) returns integer 
 LANGUAGE plpgsql
AS $function$

$BODY$ 

declare _nb integer;
declare _id_drain integer;

BEGIN; 
-- 1. Récupération de l'id_drain
select
	distinct(id_drain)
from
	rht.devalaison
where
	site = _site into
		_id_drain;
-- 2. Calcul de la somme par classe de taille  * coefficient année
select
	round( s300*t_300_450 + s450*t_450_600 + s600*t_600_750 + s750*t_750 )
from
	(
		select
			sum( "300_450" ) s300,
			sum( "450_600" ) s450,
			sum( "600_750" ) s600,
			sum( "750" ) s750
		from
			rht.silver2017
		where
			id_drain in(
				select
					rht.upstream_segments(_id_drain)
			)
			or id_drain = _id_drain
	) sub1,
	(
		select
			*
		from
			rht.densityyear2017
		where
			annee = _annee::text
	) sub2 into
		_nb;
-- 3. requete en update
update
	rht.devalaison
set
	estim_eda = _nb
where
	site = _site
	and annee = _annee;

RAISE NOTICE 'Table mise à jour pour le site % annee %',
_site,
_annee;

return _nb;
end;

$BODY$ LANGUAGE plpgsql VOLATILE COST 100;

alter function rht.eda_prediction(
	text,
	integer
) OWNER to postgres;	
---------------------			
 --Vilaine (Briand et al, 2014)
 --------------------
 select
		AddGeometryColumn(
			'rht',
			'devalaison',
			'geom',
			2154,
			'POINT',
			2
		);

insert
	into
		rht.devalaison(
			site,
			annee,
			estim
		)
	values(
		'Vilaine',
		2012,
		130000
	);

update
	rht.devalaison
set
	estim = 130000
where
	site = 'Vilaine';

-- récupération des latitudes longitudes sous google, attention inverser	
 update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' ||- 2.382867 || ' ' || 47.499193 || ')',
			4326
		),
		2154
	)
where
	site = 'Vilaine';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Vilaine'
	) limit 5;

--212340
 update
	rht.devalaison
set
	id_drain = 212340
where
	site = 'Vilaine';

update
	rht.devalaison
set
	estim_eda =(
		select
			round( sum( total ))
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(212340)
			)
			or id_drain = 212340
	)
where
	site = 'Vilaine';

update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver2017
		where
			id_drain in(
				select
					rht.upstream_segments(212340)
			)
			or id_drain = 212340
	)
where
	site = 'Vilaine';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(212340)
			)
			or id_drain = 212340
	)
where
	site = 'Vilaine';

select
	*
from
	rht.devalaison;

--------------------
 -- mise à jour 2017
 --------------------
 /*
Je vais chercher le rapport des valeurs à la référence de 2015 (dans la table silver2017) et je corrige par le pourcentage
relatif de l'année donné dans la table densityyear2017. Attention pour les autres sites, ces requêtes ont été transformées en fonction
rht.eda_prediction
*/
select
	t_300_450,
	t_450_600,
	t_600_750,
	t_750
from
	rht.densityyear2017
where
	annee = '2014';

-- Vilaine 2014
 update
	rht.devalaison
set
	estim_eda =(
		select
			round( s300*t_300_450 + s450*t_450_600 + s600*t_600_750 + s750*t_750 )
		from
			(
				select
					sum( "300_450" ) s300,
					sum( "450_600" ) s450,
					sum( "600_750" ) s600,
					sum( "750" ) s750
				from
					rht.silver2017
				where
					id_drain in(
						select
							rht.upstream_segments(212340)
					)
					or id_drain = 212340
			) sub1,
			(
				select
					*
				from
					rht.densityyear2017
				where
					annee = '2014'
			) sub2
	)
where
	site = 'Vilaine'
	and annee = 2014;

-- Vilaine 2013
 update
	rht.devalaison
set
	estim_eda =(
		select
			round( s300*t_300_450 + s450*t_450_600 + s600*t_600_750 + s750*t_750 )
		from
			(
				select
					sum( "300_450" ) s300,
					sum( "450_600" ) s450,
					sum( "600_750" ) s600,
					sum( "750" ) s750
				from
					rht.silver2017
				where
					id_drain in(
						select
							rht.upstream_segments(212340)
					)
					or id_drain = 212340
			) sub1,
			(
				select
					*
				from
					rht.densityyear2017
				where
					annee = '2013'
			) sub2
	)
where
	site = 'Vilaine'
	and annee = 2013;

-- Vilaine 2012 (sur la précédente version 49622 sur la nouvelle 46180
 update
	rht.devalaison
set
	estim_eda =(
		select
			round( s300*t_300_450 + s450*t_450_600 + s600*t_600_750 + s750*t_750 )
		from
			(
				select
					sum( "300_450" ) s300,
					sum( "450_600" ) s450,
					sum( "600_750" ) s600,
					sum( "750" ) s750
				from
					rht.silver2017
				where
					id_drain in(
						select
							rht.upstream_segments(212340)
					)
					or id_drain = 212340
			) sub1,
			(
				select
					*
				from
					rht.densityyear2017
				where
					annee = '2012'
			) sub2
	)
where
	site = 'Vilaine'
	and annee = 2012;

-- Vilaine 2015 (Pas besoin de tout ce traffic mais je garde le script
 update
	rht.devalaison
set
	estim_eda =(
		select
			round( s300*t_300_450 + s450*t_450_600 + s600*t_600_750 + s750*t_750 )
		from
			(
				select
					sum( "300_450" ) s300,
					sum( "450_600" ) s450,
					sum( "600_750" ) s600,
					sum( "750" ) s750
				from
					rht.silver2017
				where
					id_drain in(
						select
							rht.upstream_segments(212340)
					)
					or id_drain = 212340
			) sub1,
			(
				select
					*
				from
					rht.densityyear2017
				where
					annee = '2015'
			) sub2
	)
where
	site = 'Vilaine'
	and annee = 2015;

---------------------			
 --Loire (Acou et al., 2010)
 --------------------
 --LAURENT :
 -- Loire à Ancenis 
 -- 214245 ==> 135 049
 -- aval Havre
 -- 214484 ==> 140 947
 -- aval Divate
 -- 214874 ==> 156 179 // 40800 ha
 -- ste Luce 
 -- 215413 ==> 159 953 // 40900 ha
 -- Anthony ==> Il faut se baser sur la station de Yannick Perraud à Varrades
 ---0.960420288999956,47.379037109000080 213929
 insert
	into
		rht.devalaison(
			site,
			annee,
			estim
		)
	values(
		'Loire',
		2009,
		150000
	);

insert
	into
		rht.devalaison(
			site,
			annee,
			estim
		)
	values(
		'Loire',
		2012,
		137000
	);

-- 137000 +-10000 antho
 update
	rht.devalaison
set
	estim = 150000
where
	site = 'Loire'
	and annee = 2009;

update
	rht.devalaison
set
	estim = 137000
where
	site = 'Loire'
	and annee = 2012;

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' ||- 0.9604202 || ' ' || 47.379037109 || ')',
			4326
		),
		2154
	)
where
	site = 'Loire';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Loire'
	) limit 5;

update
	rht.devalaison
set
	estim_eda =(
		select
			round( sum( total ))*(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2009
			)
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(213929)
			)
			or id_drain = 213929
	)
where
	site = 'Loire'
	and annee = 2009;

update
	rht.devalaison
set
	estim_eda =(
		select
			round( sum( total ))*(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			)
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(213929)
			)
			or id_drain = 213929
	)
where
	site = 'Loire'
	and annee = 2012;

update
	rht.devalaison
set
	id_drain = 213929
where
	site = 'Loire';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(213929)
			)
			or id_drain = 213929
	)
where
	site = 'Loire';

update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(213929)
			)
			or id_drain = 213929
	)
where
	site = 'Loire';

select rht.eda_prediction('Loire',2009);--196 458
select rht.eda_prediction('Loire',2012);--159 434
---------------------			
 --Frémur 
 --------------------
 
update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' ||- 2.103526 || ' ' || 48.577691 || ')',
			4326
		),
		2154
	)
where
	site = 'Frémur';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Frémur' limit 1
	) limit 5;

/*
update rht.devalaison set estim_eda = 
(select round(sum(total)) from rht.silver where id_drain in (select rht.upstream_segments(200870)) or id_drain= 200870)
where site='Frémur' and annee=2012;
--select * from rht.modelyear -- pas bon il s'agit de valeurs relatives par classe de taille
*/
-- en gros c'est ça
 update
	rht.devalaison
set
	estim_eda = ttt*sub1.estim
from
	(
		select
			i as ttt,
			i.annee
		from
			rht.indiceannuel i join rht.devalaison d on
			i.annee = d.annee
		where
			site = 'Frémur'
	) sub,
	(
		select
			sum( total ) as estim
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(200870)
			)
			or id_drain = 200870
	) sub1
where
	site = 'Frémur'
	and devalaison.annee = sub.annee;

update
	rht.devalaison
set
	surface_reelle_ha = 59.5
where
	site = 'Frémur';

--\citep[p74]{Acou_these_2006}
 update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(200870)
			)
			or id_drain = 200870
	)
where
	site = 'Frémur';





------
 -- Frémur 2017
 -----


-- insertions en base pour le Frémur 1996-2015
 select
	rht.eda_prediction(
		'Frémur',
		1996
	);
 select
	rht.eda_prediction(
		'Frémur',
		1997
	);
 select
	rht.eda_prediction(
		'Frémur',
		1998
	);
 select
	rht.eda_prediction(
		'Frémur',
		1999
	);
 select
	rht.eda_prediction(
		'Frémur',
		2000
	);
 select
	rht.eda_prediction(
		'Frémur',
		2001
	);
 select
	rht.eda_prediction(
		'Frémur',
		2002
	) ;
select
	rht.eda_prediction(
		'Frémur',
		2003
	);
 select
	rht.eda_prediction(
		'Frémur',
		2004
	);
 select
	rht.eda_prediction(
		'Frémur',
		2005
	);
 select
	rht.eda_prediction(
		'Frémur',
		2006
	);
	 select
	rht.eda_prediction(
		'Frémur',
		2007
	);
 select
	rht.eda_prediction(
		'Frémur',
		2008
	);
 select
	rht.eda_prediction(
		'Frémur',
		2009
	);
 select
	rht.eda_prediction(
		'Frémur',
		2010
	);
 select
	rht.eda_prediction(
		'Frémur',
		2011
	);
 select
	rht.eda_prediction(
		'Frémur',
		2012
	);
 select
	rht.eda_prediction(
		'Frémur',
		2013
	);
 select
	rht.eda_prediction(
		'Frémur',
		2014
	);
	 select
	rht.eda_prediction(
		'Frémur',
		2015
	);
	
------------------------------
-- Mise à jour des nb corrigés
-------------------------------
	
update
	rht.devalaison
set
	nb_eda_corr = sub.nb_corrige
from
	(
		select
			estim_eda*surface_reelle_ha / surface_rht_ha as nb_corrige,
			annee
		from
			rht.devalaison
		where
			site = 'Frémur'
	) sub
where
	site = 'Frémur'
	and devalaison.annee = sub.annee;


-- Vilaine 2012 (sur la précédente version 49622 sur la nouvelle 46180
 update
	rht.devalaison
set
	estim_eda =(
		select
			round( s300*t_300_450 + s450*t_450_600 + s600*t_600_750 + s750*t_750 )
		from
			(
				select
					sum( "300_450" ) s300,
					sum( "450_600" ) s450,
					sum( "600_750" ) s600,
					sum( "750" ) s750
				from
					rht.silver2017
				where
					id_drain in(
						select
							rht.upstream_segments(212340)
					)
					or id_drain = 212340
			) sub1,
			(
				select
					*
				from
					rht.densityyear2017
				where
					annee = '2012'
			) sub2
	) ;
	
---------------------			
 --Sommme -- Cléry sur Somme  (ref ?)
 --------------------
 update
		rht.devalaison
	set
		geom = st_transform(
			geomfromtext(
				'POINT(' || 2.788961 || ' ' || 49.940364 || ')',
				4326
			),
			2154
		)
	where
		site = 'Somme';

delete
from
	rht.devalaison
where
	site = 'Somme';

----------------------
-- DEPRECATED TOTAL ANGUILLES EDA
------------------------

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(403191)
					)
					or id_drain = 403191
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Somme';
	
----------------------
-- DEPRECATED SURFACE RHT EDA
------------------------
update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(403191)
			)
			or id_drain = 403191
	)
where
	site = 'Somme';
----------------------
-- GEOM POINT CENTROID SOMME
------------------------
update
	rht.devalaison
set
	geom =(
		select
			st_transform(
				st_centroid(the_geom),
				2154
			)
		from
			rht.rhtvs2
		where
			id_drain = 403191
	)
where
	site = 'Somme';

select
	*
from
	rht.devalaison;
----------------------
-- STRUCTURE EN TAILLE SOMME
------------------------
update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(403191)
			)
			or id_drain = 403191
	)
where
	site = 'Somme';
-------------
-- MISE A JOUR 2017 SOMME (2013 2014 2015)
------------
select rht.eda_prediction(
		'Somme',
		2013
	); --533
select rht.eda_prediction(
		'Somme',
		2014
	);--462
select rht.eda_prediction(
		'Somme',
		2015
	);	--459
	
	
 --------------------
 -- soustons
 ------------------------
 /*
43.761018, -1.371695
6449 --2011-2012 6805 effectif capturable 8700
55% femelles
d=13.9 ind/ha ~ 8700 => S=N/d=625
--2011-2011 13,9 individus par ha de Surface en Eau
--2012-2013 67,1 ind./km² de BV ou 24,4 ind./ha de SE
-- source Dartau mis à jour par PM / mise à jour manuelle
*/
 update
	rht.devalaison
set
	estim = 8700
where
	site = 'Soustons';

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' ||- 1.371695 || ' ' || 43.761018 || ')',
			4326
		),
		2154
	)
where
	site = 'Soustons';
--------------------------
-- SELECTION DES ID_DRAINS DE SOUSTONS
--------------------------
select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Soustons'
	) limit 5;
--------------------------
-- ESIMTATION EDA 2015
--------------------------
update
	rht.devalaison
set
	id_drain = 116871
where
	site = 'Soustons';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(116871)
					)
					or id_drain = 116871
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Soustons';
--------------------------
-- SURFACE EN EAU EDA
--------------------------
update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(116871)
			)
			or id_drain = 116871
	)
where
	site = 'Soustons';
--------------------------
-- SURFACE REELLE SOUSTONS
--------------------------
update
	rht.devalaison
set
	surface_reelle_ha = 625
where
	site = 'Soustons';
--------------------------
-- NB CORRIGES DEVALAISON
--------------------------
update
	rht.devalaison
set
	nb_eda_corr = sub.nb_corrige
from
	(
		select
			estim_eda*surface_reelle_ha / surface_rht_ha as nb_corrige,
			estim,
			annee
		from
			rht.devalaison
		where
			site = 'Soustons'
	) sub
where
	site = 'Soustons'
	and devalaison.annee = sub.annee;
--------------------------
-- DENSITE CORRIGEE
--------------------------
select
	estim_eda / surface_rht_ha
from
	rht.devalaison
where
	site = 'Soustons';

--38 ind /ha
--------------------------
-- NB CORRIGES DEVALAISON
--------------------------
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(116871)
			)
			or id_drain = 116871
	)
where
	site = 'Soustons';
----------------
-- SOUSTONS MAJ 2012 2015
---------------------
select rht.eda_prediction('Soustons',2012);
select rht.eda_prediction('Soustons',2013);
select rht.eda_prediction('Soustons',2014);
select rht.eda_prediction('Soustons',2015);
----------------------------	
 -- Dronne
 ----------------------
 select
	100 * 1 /(
		38 + 131 + 31
	)::numeric -- 0.5 % mâles
 --N =143 246
 -------------------
 -- Monfourat
 -----------------
 insert
		into
			rht.devalaison(
				site,
				id_drain,
				annee,
				estim
			)
		values(
			'Dronne Monfourat',
			null,
			2012,
			null
		);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' ||- 0.067428 || ' ' || 45.084709 || ')',
			4326
		),
		2154
	)
where
	site = 'Dronne Monfourat';

update
	rht.devalaison
set
	estim = 56
where
	site = 'Dronne Monfourat' --221 en 2012-2013 avec les jaunes p 37 Verdeyroux 2014
 select
		*
	from
		rht.rhtvs2
	order by
		the_geom <->(
			select
				st_transform(
					geom,
					3035
				)
			from
				rht.devalaison
			where
				site = 'Dronne Monfourat'
		) limit 5;

update
	rht.devalaison
set
	id_drain = 105441
where
	site = 'Dronne Monfourat';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(105441)
					)
					or id_drain = 105441
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Dronne Monfourat';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(105441)
			)
			or id_drain = 105441
	)
where
	site = 'Dronne Monfourat';

update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(105441)
			)
			or id_drain = 105441
	)
where
	site = 'Dronne Monfourat';
select rht.eda_prediction('Dronne Monfourat',2012);--2711=>2065
select rht.eda_prediction('Dronne Monfourat',2013);--2378
select rht.eda_prediction('Dronne Monfourat',2014);--1972
------------------------------------
 -- poltrot 45.280044, 0.211495
 --------------------------------------
 insert
	into
		rht.devalaison(
			site,
			id_drain,
			annee,
			estim
		)
	values(
		'Dronne Poltrot',
		null,
		2012,
		null
	);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' || 0.211495 || ' ' || 45.280044 || ')',
			4326
		),
		2154
	)
where
	site = 'Dronne Poltrot';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Dronne Poltrot'
	) limit 5;

update
	rht.devalaison
set
	id_drain = 104137
where
	site = 'Dronne Poltrot';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(104137)
					)
					or id_drain = 104137
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Dronne Poltrot';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(104137)
			)
			or id_drain = 104137
	)
where
	site = 'Dronne Poltrot';

update
	rht.devalaison
set
	estim = 168
where
	site = 'Dronne Poltrot';

--221 en 2012-2013 avec les jaunes p 37 Verdeyroux 2014
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(104137)
			)
			or id_drain = 104137
	)
where
	site = 'Dronne Poltrot';
select rht.eda_prediction('Dronne Poltrot',2011);--502
select rht.eda_prediction('Dronne Poltrot',2012);--444=>428
select rht.eda_prediction('Dronne Poltrot',2013);--473
select rht.eda_prediction('Dronne Poltrot',2014);--432
--------------------------------
 -- renamon 45.287032, 0.528548
 --------------------------------
 insert
	into
		rht.devalaison(
			site,
			id_drain,
			annee,
			estim
		)
	values(
		'Dronne Renamon',
		null,
		2012,
		null
	);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' || 0.528548 || ' ' || 45.287032 || ')',
			4326
		),
		2154
	)
where
	site = 'Dronne Renamon';

update
	rht.devalaison
set
	estim = 56
where
	site = 'Dronne Renamon';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Dronne Renamon'
	) limit 5;

update
	rht.devalaison
set
	id_drain = 104069
where
	site = 'Dronne Renamon';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(104069)
					)
					or id_drain = 104069
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Dronne Renamon';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(104069)
			)
			or id_drain = 104069
	)
where
	site = 'Dronne Renamon';

update
	rht.devalaison
set
	estim = 9
where
	site = 'Dronne Renamon';

-- 2012-2103=124
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(104069)
			)
			or id_drain = 104069
	)
where
	site = 'Dronne Renamon';
select rht.eda_prediction('Dronne Renamon',2011);--52
select rht.eda_prediction('Dronne Renamon',2012);--48
select rht.eda_prediction('Dronne Renamon',2013);--46
select rht.eda_prediction('Dronne Renamon',2014);--55
--------------------------------
 -- Marais poitevin 45.287032, 0.528548
 -- Sèvre niortaise
 --------------------------------
 46.348960,
- 0.463470 insert
	into
		rht.devalaison(
			site,
			id_drain,
			annee,
			estim
		)
	values(
		'Sèvre Niortaise',
		null,
		2012,
		null
	);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' ||- 0.463470 || ' ' || 46.348960 || ')',
			4326
		),
		2154
	)
where
	site = 'Sèvre Niortaise';

update
	rht.devalaison
set
	annee = 2013
where
	site = 'Sèvre Niortaise';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Sèvre Niortaise'
	) limit 5;

update
	rht.devalaison
set
	id_drain = 226241
where
	site = 'Sèvre Niortaise';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(226241)
					)
					or id_drain = 226241
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Sèvre Niortaise';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(226241)
			)
			or id_drain = 226241
	)
where
	site = 'Sèvre Niortaise';

update
	rht.devalaison
set
	estim = 1411
where
	site = 'Sèvre Niortaise';

update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(226241)
			)
			or id_drain = 226241
	)
where
	site = 'Sèvre Niortaise';
	

select rht.eda_prediction('Sèvre Niortaise',2013);--1259
select rht.eda_prediction('Sèvre Niortaise',2014);--1046
select rht.eda_prediction('Sèvre Niortaise',2015);--1056	
---------------------------------------------------------------------------------------------------------

 /*
•        Sur le tronçon situé au niveau de Lisle sur Tarn
•        A l’amont de l’ouvrage de Sapiac (chaîne de 3 ouvrages, de l’amont vers l’aval -> Sapiac – Albarèdes – Lagarde)
•        A l’amont de Golfech
•        A l’aval de la confluence Lot – Garonne (extrême aval de la Garonne, pas loin de Marmande)
Lisle sur Tarn : 43.852383, 1.812800
Amont sapiac : 44.003757, 1.342390
Amont Golfech : 44.083315, 0.985264
Aval confluence Lot/Garonne : 44.333234, 0.313466

*/
	insert
		into
			rht.devalaison(
				site,
				id_drain,
				annee,
				estim
			)
		values(
			'Lisle Tarn',
			null,
			2012,
			null
		);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' || 1.812800 || ' ' || 43.852383 || ')',
			4326
		),
		2154
	)
where
	site = 'Lisle Tarn';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Lisle Tarn'
	) limit 5;

-- 5 drains 116705 le plus aval et pas sur affluent
 update
	rht.devalaison
set
	id_drain = 116705
where
	site = 'Lisle Tarn';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(116705)
					)
					or id_drain = 116705
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Lisle Tarn';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(116705)
			)
			or id_drain = 116705
	)
where
	site = 'Lisle Tarn';

-- si données à cet endroit
 -- update rht.devalaison set estim=where site='Lisle Tarn' ; 
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(116705)
			)
			or id_drain = 116705
	)
where
	site = 'Lisle Tarn';

--#####################################################
 --A l’amont de l’ouvrage de Sapiac (chaîne de 3 ouvrages, de l’amont vers l’aval -> Sapiac – Albarèdes – Lagarde)
 --#####################################################
 insert
	into
		rht.devalaison(
			site,
			id_drain,
			annee,
			estim
		)
	values(
		'Sapiac Tarn',
		null,
		2012,
		null
	);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' || 1.342390 || ' ' || 44.083315,
			|| ')',
			4326
		),
		2154
	)
where
	site = 'Sapiac Tarn';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Sapiac Tarn'
	) limit 5;

-- 5 drains 115247 26 barrages le tronçon à l'aval en à 23... on doit être là
 update
	rht.devalaison
set
	id_drain = 115247
where
	site = 'Sapiac Tarn';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(115247)
					)
					or id_drain = 115247
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Sapiac Tarn';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(115247)
			)
			or id_drain = 115247
	)
where
	site = 'Sapiac Tarn';

-- si données à cet endroit
 -- update rht.devalaison set estim=where site='Sapiac Tarn' ; 
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(115247)
			)
			or id_drain = 115247
	)
where
	site = 'Sapiac Tarn';

--#####################################################
 --A l’amont de Golfech
 --#####################################################
 insert
	into
		rht.devalaison(
			site,
			id_drain,
			annee,
			estim
		)
	values(
		'Golfech Garonne',
		null,
		2012,
		null
	);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' || 0.985264 || ' ' || 44.083315 || ')',
			4326
		),
		2154
	)
where
	site = 'Golfech Garonne';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Golfech Garonne'
	) limit 5;

-- 114443
 update
	rht.devalaison
set
	id_drain = 114443
where
	site = 'Golfech Garonne';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(114443)
					)
					or id_drain = 114443
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Golfech Garonne';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(114443)
			)
			or id_drain = 114443
	)
where
	site = 'Golfech Garonne';

-- si données à cet endroit
 -- update rht.devalaison set estim=where site='Golfech Garonne' ; 
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(114443)
			)
			or id_drain = 114443
	)
where
	site = 'Golfech Garonne';

--#####################################################
 --Aval confluence Lot/Garonne : 44.333234, 0.313466
 --#####################################################
 insert
	into
		rht.devalaison(
			site,
			id_drain,
			annee,
			estim
		)
	values(
		'Aval confluence Lot Garonne',
		null,
		2012,
		null
	);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' || 0.313466 || ' ' || 44.333234 || ')',
			4326
		),
		2154
	)
where
	site = 'Aval confluence Lot Garonne';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Aval confluence Lot Garonne'
	) limit 5;

-- 114443
 update
	rht.devalaison
set
	id_drain = 111955
where
	site = 'Aval confluence Lot Garonne';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(111955)
					)
					or id_drain = 111955
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Aval confluence Lot Garonne';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(111955)
			)
			or id_drain = 111955
	)
where
	site = 'Aval confluence Lot Garonne';

-- si données à cet endroit
 -- update rht.devalaison set estim=where site='Aval confluence Lot Garonne' ; 
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(111955)
			)
			or id_drain = 111955
	)
where
	site = 'Aval confluence Lot Garonne';

select
	site,
	id_drain,
	annee,
	estim,
	estim_eda,
	surface_reelle_ha,
	surface_rht_ha,
	size_str_eda
from
	rht.devalaison
where
	site in(
		'Aval confluence Lot Garonne',
		'Golfech Garonne',
		'Sapiac Tarn',
		'Lisle Tarn'
	) -- demande de stéphane 2
 /*
•   faire un calcul de Biomasse (par classes de taille et totale comme l’autre fois)
d’anguilles en amont de ce point (l’ouvrage du Bazacle sur la Garonne dans Toulouse) : 
43.602791, 1.432529 (coordonnées lat/long sur GoogleMaps) 



*/
	insert
		into
			rht.devalaison(
				site,
				id_drain,
				annee,
				estim
			)
		values(
			'Bazacle Garonne',
			null,
			2012,
			null
		);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' || 1.432529 || ' ' || 43.602791 || ')',
			4326
		),
		2154
	)
where
	site = 'Bazacle Garonne';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'Bazacle Garonne'
	) limit 5;

-- 2 drains sur cours 118599 et 118603 (en amont) , je garde 118603
 /*Note the magic <-> operator in the ORDER BY clause. This is where the magic occurs. 
The <-> is a “distance” operator, but it only makes use of the index when it appears in the ORDER BY clause. 
Between putting the operator in the ORDER BY and using a LIMIT to truncate the result set, we can very very quickly 
(less than 10ms on a 2M record table, in this case) get the 10 nearest points to our test point.

“It can’t possibly be this easy!!” You’re right. It can’t. Because it is traversing the index, 
which is made of bounding boxes, the distance operator only works with bounding boxes. 
For point data, the bounding boxes are equivalent to the points, so the answers are exact. 
But for any other geometry types (lines, polygons, etc) the results are approximate.

There are actually two different approximations available for you to chose from.

Using the <-> operator, you get the nearest neighbour using the centers of the bounding boxes to calculate the inter-object distances.
Using the <#> operator, you get the nearest neighbour using the bounding boxes themselves to calculate the inter-object distances.
*/
update
	rht.devalaison
set
	id_drain = 118603
where
	site = 'Bazacle Garonne';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(118603)
					)
					or id_drain = 118603
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'Bazacle Garonne';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(118603)
			)
			or id_drain = 118603
	)
where
	site = 'Bazacle Garonne';

-- si données à cet endroit
 -- update rht.devalaison set estim=where site='Lisle Tarn' ; 
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(118603)
			)
			or id_drain = 118603
	)
where
	site = 'Bazacle Garonne';

select
	site,
	id_drain,
	annee,
	estim,
	estim_eda,
	surface_reelle_ha,
	surface_rht_ha,
	size_str_eda
from
	rht.devalaison
where
	site in(
		'Aval confluence Lot Garonne',
		'Golfech Garonne',
		'Sapiac Tarn',
		'Lisle Tarn',
		'Bazacle Garonne'
	) -- demande de Frank Pressiat----------------------------------------
 /*
Site d’implantation de la PCH de Vallabrègues :
30300 Vallabrègues
Coordonnées :  X :43.848603,  Y : 4.619004
*/
	--------------------------------------------------------------------------
 insert
		into
			rht.devalaison(
				site,
				id_drain,
				annee,
				estim
			)
		values(
			'PCH Vallabrègue Rhône',
			null,
			2012,
			null
		);

update
	rht.devalaison
set
	geom = st_transform(
		geomfromtext(
			'POINT(' || 4.62 || ' ' || 43.84 || ')',
			4326
		),
		2154
	)
where
	site = 'PCH Vallabrègue Rhône';

select
	*
from
	rht.rhtvs2
order by
	the_geom <->(
		select
			st_transform(
				geom,
				3035
			)
		from
			rht.devalaison
		where
			site = 'PCH Vallabrègue Rhône'
	) limit 10;

-- pas les bons, le bon (aval confluence gardon) 18691
 update
	rht.devalaison
set
	id_drain = 18691
where
	site = 'PCH Vallabrègue Rhône';

update
	rht.devalaison
set
	estim_eda =(
		select
			i* sumeel
		from
			(
				select
					round( sum( total )) as sumeel
				from
					rht.silver
				where
					id_drain in(
						select
							rht.upstream_segments(18691)
					)
					or id_drain = 18691
			) sub1,
			(
				select
					i
				from
					rht.indiceannuel
				where
					annee = 2012
			) sub
	)
where
	site = 'PCH Vallabrègue Rhône';

update
	rht.devalaison
set
	surface_rht_ha =(
		select
			100 * sum( surface )
		from
			rht.crosstab_rhtvs2
		where
			id_drain in(
				select
					rht.upstream_segments(18691)
			)
			or id_drain = 18691
	)
where
	site = 'PCH Vallabrègue Rhône';

-- si données à cet endroit
 -- update rht.devalaison set estim=where site='Lisle Tarn' ; 
 update
	rht.devalaison
set
	size_str_eda =(
		select
			ARRAY[ sum( "300_450" )/ sum( total ),
			sum( "450_600" )/ sum( total ),
			sum( "600_750" )/ sum( total ),
			sum( "750" )/ sum( total ) ]
		from
			rht.silver
		where
			id_drain in(
				select
					rht.upstream_segments(18691)
			)
			or id_drain = 18691
	)
where
	site = 'PCH Vallabrègue Rhône';

select
	site,
	id_drain,
	annee,
	estim,
	estim_eda,
	surface_reelle_ha,
	surface_rht_ha,
	size_str_eda
from
	rht.devalaison
where
	site in('PCH Vallabrègue Rhône')


-------------------------
-- Traitement des données de seinormig
--------------------------

-- récupération des données Seinormig
--F:\IAV\eda\traitements_eda>shp2pgsql -I -W latin1 -s 2154 BDD_STATIONS_IAA temp.seinormig>BDD_STATIONS_IAA.sql
--psql -U postgres -f "BDD_STATIONS_IAA.sql" eda2.2

--Récupération des données d'argenture
-- F:\IAV\eda\traitements_eda>pg_dump -U postgres -f "argenture.sql" --table rht.argenture -h w3.eptb-vilaine.fr eda2.1
select find_SRID('rht', 'rhtvs2', 'the_geom'); --3035

select ST_ClosestPoint(road_network, poi)
select * from temp.seinormig;
SELECT * from rht.silver2017 limit 10 
alter table temp.seinormig add column p_300_450 numeric;
alter table temp.seinormig add column p_450_600 numeric;
alter table temp.seinormig add column p_600_750 numeric;
alter table temp.seinormig add column p_750 numeric;

vacuum full verbose analyze rht.argenture;
ALTER TABLE temp.seinormig
  ALTER COLUMN geom
    TYPE geometry(Point, 3035)
    USING ST_SetSRID(st_transform(geom, 3035), 3035);
ALTER TABLE 

with projection as(
select  
	s.gid,
	r.id_drain,
	p300_450,
	p450_600,
	p600_750,
	p750,
	st_distance(s.geom, r.the_geom) as dist
	 from rht.rhtvs2 r 
	join rht.argenture a on a.id_drain=r.id_drain
	JOIN temp.seinormig s on st_dwithin (s.geom, r.the_geom,1000)
	order by id_drain,dist
	),
     p as (	
	SELECT distinct on (gid) * from projection 
	)
Update temp.seinormig set (p_300_450,p_450_600,p_600_750,p_750) = (p.p300_450,p.p450_600,p.p600_750,p.p750)
FROM p where p.gid=temp.seinormig.gid;

ALTER TABLE temp.seinormig
  ALTER COLUMN geom
    TYPE geometry(Point, 2154)
    USING ST_SetSRID(st_transform(geom, 2154), 2154);
	
select * from temp.seinormig;

pgsql2shp -u postgres -f "BDD_STATIONS_IAA.shp" eda2.2 temp.seinormig 