 select distinct on (annee) annee from (select extract(year from op_datedebut) as annee from station
 inner join operation on op_st_id=st_id inner join optaxon on ot_op_id=op_id
  inner join taxon on ot_ta_id=ta_id ) AS Subquery 
--where BDMAP.taxon.ta_code='ANG')

