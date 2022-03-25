select addgeometrycolumn('','rht','ersw','geom',3035,'POINT',2);

update rht.ersw set geom=st.geom from rsa.rsa_rht st where st_id=sta_code;--2303
update rht.ersw set geom=st.the_geom from bdmap2012.stationsp2 st where st.st_codecsp=ersw.st_id;
update rht.ersw set geom=bda.geom from bd_agglo_2017.bdmap_rht bda where bda.st_codecsp=ersw.st_id;
select * from rht.ersw where geom is null; --3455

update rht.ersw set geom=St_transform(ST_SetSRID(St_Makepoint(ersw.st_abcisse,ersw.st_ordonnee),2154),3035) where geom is null;
alter table rht.ersw add column id serial



CREATE INDEX ersw_index
ON rht.ersw
USING btree
(id);

CREATE INDEX ersw_gistindex
ON rht.ersw
USING gist
(geom);

select * from rht.ersw limit 10;
select * from rht.erst2017 limit 10;
update rht.erst2017 set geom= ersw.geom from rht.ersw where erst2017.st_id =ersw.st_id
	


