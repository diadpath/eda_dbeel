select * from(
select extract(YEAR FROM op_datedebut) as annee,
      op_numero,
      op_datedebut,
      op_cd_methodeprospection,
      op_cd_objectifpeche,
      op_listeespecescibles,
      op_cs_profmoyen,
      op_cs_largeurlameeau,
      op_largsdt,
      op_surfaceechantillon,
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
      eh_codegenerique,
      ta_code,
      ot_effectif,
      ot_effectifestim,
      ot_efficacite,
      ot_estestime,
      lo_effectif,
      lo_taillemin,
      lo_taillemax,
      cd_libl,
      tc_taillemin,
      tc_taillemax,
      ct_taille,
      ct_effectif
from entitehydro inner join station on st_eh_id=eh_id
inner join operation on op_st_id=st_id
inner join lotpeche on lo_op_id=op_id
left join (select * from optaxon
inner join taxon on ta_id=ot_ta_id
where ta_code='ANG') on ot_op_id=op_id
inner join csp.codier on cd_id=lo_cd_type
left join tableauclassetaille on tc_op_id=op_id
left join classetailletaxon on ct_tc_id=tc_id
