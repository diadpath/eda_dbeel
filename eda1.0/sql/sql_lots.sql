select op_numero,
      lo_effectif,
      lo_taillemin,
      lo_taillemax, 
      cd_libl
from station 
inner join operation on op_st_id=st_id
inner join lotpeche on lo_op_id=op_id
inner join taxon on ta_id=lo_ta_id
inner join csp.codier on cd_id=lo_cd_type 
where ta_code='ANG'
and cd_libl='G'