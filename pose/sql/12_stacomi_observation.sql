-- Observations	 

DROP TABLE if exists stacomi.observations_ob;
CREATE TABLE stacomi.observations_ob (
	LIKE iav.t_operation_ope,
	CONSTRAINT observations_pkey PRIMARY KEY (ob_id),
	CONSTRAINT fk_ob_obsplaces FOREIGN KEY (ob_op_id)
		REFERENCES dbeel.observation_places (op_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_ob_origin FOREIGN KEY (ob_no_origin)
		REFERENCES dbeel_nomenclature.observation_origin (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_ob_period FOREIGN KEY (ob_no_period)
		REFERENCES dbeel_nomenclature.period_type (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_ob_type FOREIGN KEY (ob_no_type)
		REFERENCES dbeel_nomenclature.observation_type (no_id) MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.observations);

INSERT INTO dbeel.establishment(et_establishment_name,et_id) values ('iav',2)
INSERT INTO dbeel.data_provider (dp_name,dp_et_id) VALUES ('Cédric Briand',2);

-- creer une vue qui fait des sommes par mois avec choix du DC
-- et remplacer t_operation_ope ci dessous....
-- cette vue va devoir aussi aller chercher les lots et les caractéristiques de lot ?
-- pas si simple de recréer les liens après coup...
CREATE OR REPLACE VIEW stacomi.vue_lot_ope_car AS 
 SELECT t_operation_ope.ope_identifiant, t_lot_lot.lot_identifiant, t_operation_ope.ope_dic_identifiant, t_lot_lot.lot_lot_identifiant AS lot_pere, t_operation_ope.ope_date_debut, t_operation_ope.ope_date_fin, t_lot_lot.lot_effectif, t_lot_lot.lot_quantite, t_lot_lot.lot_tax_code, t_lot_lot.lot_std_code, tr_taxon_tax.tax_nom_latin, tr_stadedeveloppement_std.std_libelle, tr_devenirlot_dev.dev_code, tr_devenirlot_dev.dev_libelle, tg_parametre_par.par_nom, tj_caracteristiquelot_car.car_par_code, tj_caracteristiquelot_car.car_methode_obtention, tj_caracteristiquelot_car.car_val_identifiant, tj_caracteristiquelot_car.car_valeur_quantitatif, tr_valeurparametrequalitatif_val.val_libelle
   FROM iav.t_operation_ope
   JOIN iav.t_lot_lot ON t_lot_lot.lot_ope_identifiant = t_operation_ope.ope_identifiant
   LEFT JOIN ref.tr_typequantitelot_qte ON tr_typequantitelot_qte.qte_code::text = t_lot_lot.lot_qte_code::text
   LEFT JOIN ref.tr_devenirlot_dev ON tr_devenirlot_dev.dev_code::text = t_lot_lot.lot_dev_code::text
   JOIN ref.tr_taxon_tax ON tr_taxon_tax.tax_code::text = t_lot_lot.lot_tax_code::text
   JOIN ref.tr_stadedeveloppement_std ON tr_stadedeveloppement_std.std_code::text = t_lot_lot.lot_std_code::text
   JOIN iav.tj_caracteristiquelot_car ON tj_caracteristiquelot_car.car_lot_identifiant = t_lot_lot.lot_identifiant
   LEFT JOIN ref.tg_parametre_par ON tj_caracteristiquelot_car.car_par_code::text = tg_parametre_par.par_code::text
   LEFT JOIN ref.tr_parametrequalitatif_qal ON tr_parametrequalitatif_qal.qal_par_code::text = tg_parametre_par.par_code::text
   LEFT JOIN ref.tr_valeurparametrequalitatif_val ON tj_caracteristiquelot_car.car_val_identifiant = tr_valeurparametrequalitatif_val.val_identifiant
  ORDER BY t_operation_ope.ope_date_debut;

INSERT INTO stacomi.observations_ob
	SELECT uuid_generate_v4() as ob_id,
	11 AS ob_no_origin, --raw data
        23 AS ob_no_type, --migration monitorin (scientific)
        84 As ob_no_period, -- yearly
	CAST(ope_date_debut AS date) as ob_starting_date , 
	CAST(ope_date_fin AS date) as ob_ending_date,
	(select op_id from stacomi.stacomi_observation_places_op where sta_code='M4560001') as ob_op_id, -- a rafiner surtout la requete
	 *	
	 FROM iav.t_operation_ope;

