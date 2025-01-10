--secteur transport, à rajouter dans france.transport

--basin adour : supprime depuis 96 jusqu'à 2020+12
-- bcp d'empoissonements (civelles ?) entre 1996 et 2005 sur tout le secteur
-- présence de <150mm encore en 2020
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR117027'))
--basin adour bis (les segments plus en aval ne renvoient aucun segments amont via méthode upstream_segments)
-- empoissenement entre 1999 et 2004, bcp de <150mm
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR119731'))

--Garonne
--FR120584, La Garonne de sa source au confluent de l'Ariège, transport probable sur station RHP, depuis 1997
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR120584'))

--sur ce secteur (cf rapport Golfech), il y a des remontées de <150mm attestée jusqu'à 100km de la limite de marée dynamique.
--Donc pas de pb, ne pas supprimer les secteurs ci-dessous.
--FR113910, repeuplement en amont, effectif de <150mm important, doit on remonter plus en amont ? si oui on supprime bcp de pêches.
--proposition d'ajouter les secteurs suivants (avec +/- 15km) :
-- FR113888, 2018 ? car <150mm
-- FR112363, 2022 ? car <150mm
-- FR112618, 2013 et 2021 ? car <150mm
-- FR113836, 2018 ? car <150mm et mauvais résidus
-- FR113910 (déjà fait), 2010 à 2021, car <150mm
-- FR116557, 2019, car <150mm
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR113910'))

--Dordogne
--empoissenement référencé en 2000 ? pas de certitudes que ce soit des civelles toutefois
--mauvais résidus entre 1998 et 2015
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR106813'))

--en amont du barrage de Tuilières, présence de <150mm attestée dans rapport Tuilières
--Ne pas exclure
--effectif de <150mm important en 2020 (14) et 2022 (6), 152km de la mer
--présence de <150mm dès 2011 (4)
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR107583'))

--Bassin LOIRE
--Cher
--FR222976, Cher, station RHP transport ?, beaucoup d'ouvrages en aval, depuis 1992
--alvinage de civelles connus en 1998, 1999, 2000 avec bcp de <150mm
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR222465'))
--Beuvron (affluent loire)
--FR213324, beaucoup d'ouvrages aval, repeuplement en 1997, beaucoup de <150mm à partir de 1997 et juqu'en 2000 (mauvais résidus)
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR213324'))

--Lys
--CONSERVER ce secteur (sauf transport PONAPOMI)
--FR400577, Lys, nord pas de calais, coule vers la Belgique, avec upstream_segments (prendre tout le bassin), depuis 1988
--présence de <150mm en 2001, 2018
--résidus mauvais entre 94 et 2022
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR400577'))

--Rhin
--UNIQUEMENT de 1994 à 2006 (épisode SANDOZ), on conserve les autres années
-- à + de 600km de la mer, présence de <150mm, 
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR503710')) 


--opérations du Rhin qui seraient supprimées : 1193 (867 entre [1989-2010])
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR503710')))

--opérations beuvron qui seraient supprimées : 52
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR213324')))

--opérations cher qui seraient supprimées : 69
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR222465')))

--opérations lys qui seraient supprimées : 136
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR400577')))

--opérations Dordogne2 qui seraient supprimées : 8
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR107583')))

--opérations Dordogne qui seraient supprimées : 574
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR106813')))

--opérations Adourbis qui seraient supprimées : 43
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR119731')))

--opérations Adour qui seraient supprimées : 380
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR117027')))

--opérations Garonne qui seraient supprimées : 36
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR120584')))

--opérations Garonne2 qui seraient supprimées : 38
select * from france.ers_full ef 
where ef.idsegment in (SELECT idsegment FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR113910')))