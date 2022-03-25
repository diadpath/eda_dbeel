select extract(YEAR FROM op_datedebut) as annee,
      op_numero,
      op_datedebut,
      op_cd_methodeprospection,
      op_cd_objectifpeche,
      op_cs_profmoyen,
      op_cs_largeurlameeau,
      op_cs_largeurlitmineur,
      st_id,
      st_penteign,
      st_sbv,
      st_distancemer,
      st_altitude,
      st_codecsp,
      st_distancesource,
      st_lieudit,
      st_abcisse,
      st_ordonnee,
      ta_code,
      pa_effectif      
from station inner join operation on op_st_id=st_id
left join (select * from passtaxon
inner join taxon on ta_id=pa_ta_id
where ta_code='ANG'
and pa_numero=1)as subreqang on pa_op_id=op_id
