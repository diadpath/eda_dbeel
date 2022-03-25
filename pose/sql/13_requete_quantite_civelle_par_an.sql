-- requete faisant les somme des effectifs de civelles par an
-- attention cette requête suppose que les coefficients de conversion sont entrés journalièrement
select extract( year from date) as year,
	sum(effectif_total) as effectif_total
	FROM (
-- sous requête pour joindre les deux tables effectif total et poids sur
-- la base de leur colonne commune date
select case when ope_date_eff is not null then ope_date_eff
		else ope_date 
		end as date,
	case when effectif IS NOT null and effectif_from_poids is not null
			then effectif+poids
		when  effectif is null 
			then  poids
		else  effectif 
		end  as effectif_total,
	effectif,
	poids,
	effectif_from_poids,
	coe_valeur_coefficient
 from (
-- sous requete qui permet de récupérer les effectifs par jour
 SELECT cast(t_operation_ope.ope_date_debut as date) AS ope_date_eff,  
 sum(t_lot_lot.lot_effectif) as effectif
   FROM iav.t_operation_ope
   JOIN iav.t_lot_lot ON t_lot_lot.lot_ope_identifiant = t_operation_ope.ope_identifiant
      where ope_dic_identifiant in (6,5,12)
       and lot_tax_code='2038'
       and lot_std_code='CIV'
       and lot_effectif>0
    group by ope_date_eff
    order by ope_date_eff) As effectif_seulement
full outer join (
-- sous requete pour extraire les qte de lots par jour 
-- elle suppose que les valeurs de quantités de lots sont par jour
SELECT ope_date, round(poids*coe_valeur_coefficient) as effectif_from_poids, poids, coe_valeur_coefficient FROM (
 SELECT cast(t_operation_ope.ope_date_debut as date) AS ope_date,  
 sum(t_lot_lot.lot_quantite) as poids
   FROM iav.t_operation_ope
   JOIN iav.t_lot_lot ON t_lot_lot.lot_ope_identifiant = t_operation_ope.ope_identifiant
      where ope_dic_identifiant in (6,5,12)
       and lot_tax_code='2038'
       and lot_std_code='CIV'
    group by ope_date
  ORDER BY ope_date) AS qte
  left join (
	select   coe_date_debut, coe_valeur_coefficient from  iav.tj_coefficientconversion_coe
	where coe_qte_code='1'
	and coe_tax_code='2038'
	and coe_std_code='CIV') as coe
on coe_date_debut=ope_date
where poids is not null) as poids_seulement
on poids_seulement.ope_date=effectif_seulement.ope_date_eff) AS effectif_journaliers
group by year;



-- calcul des poids de civelles données journalières

 SELECT cast(t_operation_ope.ope_date_debut as date) AS ope_date_eff,  
 sum(t_lot_lot.lot_effectif) as effectif
   FROM iav.t_operation_ope
   JOIN iav.t_lot_lot ON t_lot_lot.lot_ope_identifiant = t_operation_ope.ope_identifiant
      where ope_dic_identifiant in (6,5,12)
       and lot_tax_code='2038'
       and lot_std_code='CIV'
       and lot_effectif>0
    group by ope_date_eff
    order by ope_date_eff) As effectif_seulement
full outer join (
-- sous requete pour extraire les qte de lots par jour 
-- elle suppose que les valeurs de quantités de lots sont par jour
SELECT ope_date, round(poids*coe_valeur_coefficient) as effectif_from_poids, poids, coe_valeur_coefficient FROM (
 SELECT cast(t_operation_ope.ope_date_debut as date) AS ope_date,  
 sum(t_lot_lot.lot_quantite) as poids
   FROM iav.t_operation_ope
   JOIN iav.t_lot_lot ON t_lot_lot.lot_ope_identifiant = t_operation_ope.ope_identifiant
      where ope_dic_identifiant in (6,5,12)
       and lot_tax_code='2038'
       and lot_std_code='CIV'
    group by ope_date
  ORDER BY ope_date) AS qte
  left join (
	select   coe_date_debut, coe_valeur_coefficient from  iav.tj_coefficientconversion_coe
	where coe_qte_code='1'
	and coe_tax_code='2038'
	and coe_std_code='CIV') as coe
on coe_date_debut=ope_date
where poids is not null

-- calcul des effectifs de civelles données journalières

SELECT cast(t_operation_ope.ope_date_debut as date) AS ope_date_eff,  
 sum(t_lot_lot.lot_effectif) as effectif
   FROM iav.t_operation_ope
   JOIN iav.t_lot_lot ON t_lot_lot.lot_ope_identifiant = t_operation_ope.ope_identifiant
      where ope_dic_identifiant in (6,5,12)
       and lot_tax_code='2038'
       and lot_std_code='CIV'
       and lot_effectif>0
    group by ope_date_eff
    order by ope_date_eff
	
	
-- calcul des sommes annuelles des anguilles jaunes

SELECT cast(t_operation_ope.ope_date_debut as date) AS ope_date_eff,  
 sum(t_lot_lot.lot_effectif) as effectif
   FROM iav.t_operation_ope
   JOIN iav.t_lot_lot ON t_lot_lot.lot_ope_identifiant = t_operation_ope.ope_identifiant
      where ope_dic_identifiant in (6,5,12)
       and lot_tax_code='2038'
       and lot_std_code='AGJ'
       and lot_effectif>0
    group by ope_date_eff
    order by ope_date_eff
	
-- recupération des lots	