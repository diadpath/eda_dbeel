SELECT * FROM(
SELECT extract(year FROM op_datedebut) AS annee,
      op_numero,
      tc_taillemin,
      tc_taillemax,
      ct_taille,
      ct_effectif 
 FROM   operation 
INNER JOIN  tableauclassetaille ON tc_op_id=op_id
INNER JOIN  classe_taille_taxon ON ct_tc_id=tc_id
INNER JOIN  taxon ON ta_id=tc_ta_id
