--check view_electrofishing

--ensemble des lignes dans view_electrofishing qui sont présentes en plusieurs exemplaires
select count(*),ve.op_id, ve.op_gis_layername, ve.ob_id, ve.totalnumber, ve.nb_size_measured  from dbeel.view_electrofishing ve 
group by ve.op_id, ve.op_gis_layername, ve.ob_id, ve.totalnumber, ve.nb_size_measured 
having count(*)>1 and ve.op_gis_layername in ('ASPE', 'RSA')
-- cette requête remonte 19194 lignes avec des duplicats (en local), et en 13955 lignes en prod.
