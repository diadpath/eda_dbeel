-- how many electrofishing stations with null data in the fish table while the station has a positive number of eel 427
select * from dbeel.view_electrofishing e 
join wrbd.stationdbeel st on e.op_id=st.op_id
where nb_size_measured is null and totalnumber>0; --77 after corr


select * from wrbd.stationdbeel where st_source = 'MI electrofishing survey'; --138

select * from dbeel.view_electrofishing e 
join wrbd.stationdbeel st on e.op_id=st.op_id
where st_source = 'MI electrofishing survey'; --966



-- c'est bien la relation entre operation et poissons qui merde.

select 'update wrbd.fish_fi set fi_op_id= ' ||cast(op_id as text)||' where fi_id='||cast(fi_id as text)||';'
from (
	select * from wrbd.fish_fi  fi
	join (select * from wrbd.operation_op where op_nbtotal>0 and op_folio_no is not null )as ope
	on (fi_date,fi_st_id)=(ope.op_date,ope.op_st_id)
	order by fi_id 
	) as aqmkdfhaeofiyhaeofhaiofoarhgaeihfgoaghoaeighoaeghaoerifgorgho; 
-- il y avait peut être un problème de guillemets.. Il faut maintenant réintégrer dans la dbeel




-- TODO
-- il y a apparemment deux problèmes certaines stations de 2002 et certaines de 2009
select totalnumber,nb_size_measured,e.ob_starting_date,op_year,el.* from dbeel.view_electrofishing e 
join wrbd.stationdbeel st on e.op_id=st.op_id
join wrbd.electrofishing el on e.ob_id=el.ob_id
where st_source = 'MI electrofishing survey'
and nb_size_measured !=totalnumber; --17 stations --2007-10-01 -- after correction 2 stations one 17 /16 one 7 /4c

select * from wrbd.batch_fish where ba_ob_id= '024d1ac2-1d67-4f5e-b32d-fcd895b0c05f';
-- c'est tout du MI
-- la première mi0145 8 17
-- on retrouve 2002 et 2007
-- il y a bien dix poissons 
-- jointure avec la table 
select * from wrbd.batch_fish where ba_ob_id='24468221-8aaf-42db-be12-72e4a9f46c85'

-- after correction
select * from wrbd.batch_fish where ba_ob_id= '4b74dc4d-56a7-430f-b1ba-4da6813f6d33'; -- les poissons sont tous à la bonne date
select * from wrbd.batch_fish where ba_ob_id= 'c04b3228-baae-4916-97b4-af631e2d571b';
-- les éléments de la vue
SELECT electrofishing.ob_id, count(*) AS count
   FROM dbeel.electrofishing
   JOIN dbeel.batch ON electrofishing.ob_id = batch.ba_ob_id
   JOIN dbeel.biological_characteristic ON biological_characteristic.bc_ba_id = batch.ba_id
  WHERE biological_characteristic.bc_no_characteristic_type = 39
  and fi_st_id='MI0145' and fi_year=2007
  GROUP BY electrofishing.ob_id
  

select totalnumber,nb_size_measured,e.ob_starting_date,op_year,el.* from dbeel.view_electrofishing e 
join wrbd.stationdbeel st on e.op_id=st.op_id
join wrbd.electrofishing el on e.ob_id=el.ob_id
where st_source = 'MI electrofishing survey'
and nb_size_measured is null
and totalnumber>0; --91 stations

-- il reste des problèmes pour 2002-09-19 c'est un problème de date

select * from wrbd.fish_fi where extract(year from fi_date)!=fi_year;
select extract(month from fi_date) from wrbd.fish_fi;
select extract(day from fi_date) from wrbd.fish_fi;
select extract(month from fi_date)||' '||extract(day from fi_date)||' '||fi_year from wrbd.fish_fi;
-- 69 enregistrements dont il faut que je repère le op_id avant de les corriger
select to_date(extract(month from fi_date)||' '||extract(day from fi_date)||' '||fi_year, 'M D YYYY') from wrbd.fish_fi where extract(year from fi_date)!=fi_year;

-- a faire trouver comment changer le fi_op_id de seulement les lignes qui ne vont pas dans wrbd.fish_fi et dans wrbd.batch_fi et 
-- dans mensurindivbiolchar => pour les 2002
-- a faire comprendre ce qui se passe pour les dates récentes.

select 'update wrbd.fish_fi set fi_op_id= ' ||cast(op_id as text)||' where fi_id='||cast(fi_id as text)||';'
from (
	select * from (
		select *, to_date(extract(month from fi_date)||' '||extract(day from fi_date)||' '||fi_year, 'MM DD YYYY') as corrected_date 
		from wrbd.fish_fi  fi 
		where extract(year from fi_date)!=fi_year) as fipb
	join (select * from wrbd.operation_op )as ope
	on (fipb.corrected_date,fipb.fi_st_id)=(ope.op_date,ope.op_st_id)
	order by fi_id 
	) as totogogo; 
select 'update wrbd.fish_fi set fi_date= ' ||corrected_date||' where fi_id='||cast(fi_id as text)||';'
from (
	select * from (
		select *, to_date(extract(month from fi_date)||' '||extract(day from fi_date)||' '||fi_year, 'MM DD YYYY') as corrected_date 
		from wrbd.fish_fi  fi 
		where extract(year from fi_date)!=fi_year) as fipb
	join (select * from wrbd.operation_op )as ope
	on (fipb.corrected_date,fipb.fi_st_id)=(ope.op_date,ope.op_st_id)
	order by fi_id 
	) as toto2; 
-- les deux sont sauvegardés dans C:\eda\ireland\POSE_Data_for_Modellers\update_pb_fi_date

-- ci dessous le fichier
-- correction des problemes d'opération
update wrbd.fish_fi set fi_op_id= 551 where fi_id=558;
update wrbd.fish_fi set fi_op_id= 551 where fi_id=559;
update wrbd.fish_fi set fi_op_id= 551 where fi_id=560;
update wrbd.fish_fi set fi_op_id= 562 where fi_id=571;
update wrbd.fish_fi set fi_op_id= 562 where fi_id=572;
update wrbd.fish_fi set fi_op_id= 573 where fi_id=584;
update wrbd.fish_fi set fi_op_id= 573 where fi_id=585;
update wrbd.fish_fi set fi_op_id= 573 where fi_id=586;
update wrbd.fish_fi set fi_op_id= 594 where fi_id=606;
update wrbd.fish_fi set fi_op_id= 594 where fi_id=607;
update wrbd.fish_fi set fi_op_id= 602 where fi_id=626;
update wrbd.fish_fi set fi_op_id= 602 where fi_id=627;
update wrbd.fish_fi set fi_op_id= 611 where fi_id=653;
update wrbd.fish_fi set fi_op_id= 611 where fi_id=654;
update wrbd.fish_fi set fi_op_id= 636 where fi_id=797;
update wrbd.fish_fi set fi_op_id= 636 where fi_id=798;
update wrbd.fish_fi set fi_op_id= 723 where fi_id=1022;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1057;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1058;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1059;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1060;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1061;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1062;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1063;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1064;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1065;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1066;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1067;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1068;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1069;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1070;
update wrbd.fish_fi set fi_op_id= 732 where fi_id=1071;
update wrbd.fish_fi set fi_op_id= 741 where fi_id=1142;
update wrbd.fish_fi set fi_op_id= 750 where fi_id=1151;
update wrbd.fish_fi set fi_op_id= 750 where fi_id=1152;
update wrbd.fish_fi set fi_op_id= 750 where fi_id=1153;
update wrbd.fish_fi set fi_op_id= 750 where fi_id=1154;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1181;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1182;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1183;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1184;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1185;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1186;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1187;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1188;
update wrbd.fish_fi set fi_op_id= 761 where fi_id=1189;
update wrbd.fish_fi set fi_op_id= 771 where fi_id=1229;
update wrbd.fish_fi set fi_op_id= 771 where fi_id=1230;
update wrbd.fish_fi set fi_op_id= 771 where fi_id=1231;
update wrbd.fish_fi set fi_op_id= 780 where fi_id=1256;
update wrbd.fish_fi set fi_op_id= 780 where fi_id=1257;
update wrbd.fish_fi set fi_op_id= 780 where fi_id=1258;
update wrbd.fish_fi set fi_op_id= 780 where fi_id=1259;
update wrbd.fish_fi set fi_op_id= 780 where fi_id=1260;
update wrbd.fish_fi set fi_op_id= 780 where fi_id=1261;
update wrbd.fish_fi set fi_op_id= 780 where fi_id=1262;
update wrbd.fish_fi set fi_op_id= 780 where fi_id=1263;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1307;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1308;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1309;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1310;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1311;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1312;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1313;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1314;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1315;
update wrbd.fish_fi set fi_op_id= 789 where fi_id=1316;
--correction des dates dans un deuxième temps pour les enregistrements correspondants
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=558;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=559;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=560;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=571;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=572;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=584;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=585;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=586;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=606;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=607;
update wrbd.fish_fi set fi_date= '2002-10-14' where fi_id=626;
update wrbd.fish_fi set fi_date= '2002-10-14' where fi_id=627;
update wrbd.fish_fi set fi_date= '2002-10-14' where fi_id=653;
update wrbd.fish_fi set fi_date= '2002-10-14' where fi_id=654;
update wrbd.fish_fi set fi_date= '2002-10-14' where fi_id=797;
update wrbd.fish_fi set fi_date= '2002-10-14' where fi_id=798;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1022;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1057;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1058;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1059;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1060;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1061;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1062;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1063;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1064;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1065;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1066;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1067;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1068;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1069;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1070;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1071;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1142;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1151;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1152;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1153;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1154;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1181;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1182;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1183;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1184;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1185;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1186;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1187;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1188;
update wrbd.fish_fi set fi_date= '2002-09-23' where fi_id=1189;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=1229;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=1230;
update wrbd.fish_fi set fi_date= '2002-09-19' where fi_id=1231;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1256;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1257;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1258;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1259;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1260;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1261;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1262;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1263;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1307;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1308;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1309;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1310;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1311;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1312;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1313;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1314;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1315;
update wrbd.fish_fi set fi_date= '2002-09-20' where fi_id=1316;