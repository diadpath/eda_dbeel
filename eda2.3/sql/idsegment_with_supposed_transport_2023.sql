--secteur transport, à rajouter dans france.transport

--exemple de requête pour alimenter la table france.transport
SELECT _idsegment AS idsegment, sector, "year"  FROM  france.upstream_segments_rn('SP231807')
CROSS JOIN (SELECT %nom_basin% AS sector,  %année% AS "year") sub30

--basin adour
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR117027'))
--basin adour bis (les segments plus en aval ne renvoient aucun segments amont via méthode upstream_segments)
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR119731'))

--Garonne
--FR120584, La Garonne de sa source au confluent de l'Ariège, transport probable sur station RHP, depuis 1997
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR120584'))
--FR113910, repeuplement en amont, effectif de <150mm important, doit on remonter plus en amont ? si oui on supprime bcp de pêches.
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR113910'))

--Dordogne
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR106813'))
--effectif de <150mm important en 2020 (14) et 2022 (6), 152km de la mer
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR107583'))

--Bassin LOIRE
--Cher
--FR222976, Cher, station RHP transport ?, beaucoup d'ouvrages en aval, depuis 1992
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR222465'))
--Beuvron (affluent loire)
--FR213324, beaucoup d'ouvrages aval, repeuplement en 1997
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR213324'))

--Lys
--FR400577, Lys, nord pas de calais, coule vers la Belgique, avec upstream_segments (prendre tout le bassin), depuis 1988
SELECT idsegment, geom FROM france.rn where idsegment in (select _idsegment from france.upstream_segments_rn('FR400577'))

--Rhin
-- à + de 600km de la mer, présence de <150mm, pourtant sans ensemencement déclaré.
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