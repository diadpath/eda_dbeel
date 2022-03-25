--Observation places
create schema stacomi;
-- je supprimerais les schémas iav et ref à la fin de l'opérations

ALTER table dbeel.observations ALTER COLUMN ob_starting_date TYPE timestamp(0)without time zone;

DROP TABLE if exists stacomi.observation_places_op;
CREATE TABLE stacomi.stacomi_observation_places_op (
	LIKE iav.t_station_sta,
	CONSTRAINT sta_pk_id PRIMARY KEY (op_id),
	CONSTRAINT fk_op_no_observationplacetype FOREIGN KEY (op_no_observationplacetype)
        REFERENCES dbeel_nomenclature.observation_place_type (no_id) MATCH SIMPLE
        ON UPDATE CASCADE ON DELETE RESTRICT
) INHERITS (dbeel.migration_monitoring);


SELECT * FROM iav.t_bilanmigrationjournalier_bjo





SELECT sum(bjo_valeur),bjo_annee FROM iav.t_bilanmigrationjournalier_bjo 
where bjo_labelquantite='Effectif_total' 
and bjo_tax_code='2038' -- anguille
and bjo_std_code='AGJ'
and (bjo_dis_identifiant= 5 or bjo_dis_identifiant= 6 or bjo_dis_identifiant=12)
group by bjo_annee
ORDER BY bjo_annee


SELECT sum(bjo_valeur),bjo_annee FROM iav.t_bilanmigrationjournalier_bjo 
where bjo_labelquantite='Effectif_total' 
and bjo_tax_code='2038' -- anguille
and bjo_std_code='CIV'
and (bjo_dis_identifiant= 5 or bjo_dis_identifiant= 6 or bjo_dis_identifiant=12)
group by bjo_annee
ORDER BY bjo_annee

CREATE OR REPLACE VIEW iav.vue_effectif_year AS 
 SELECT t_operation_ope.ope_identifiant,
  t_lot_lot.lot_identifiant,
  t_operation_ope.ope_dic_identifiant,
  extract(year from t_operation_ope.ope_date_debut) as year,
  t_lot_lot.lot_effectif,
   t_lot_lot.lot_quantite,
   t_lot_lot.lot_tax_code, 
   t_lot_lot.lot_std_code,
   tr_taxon_tax.tax_nom_latin,
   tr_stadedeveloppement_std.std_libelle,
   tr_devenirlot_dev.dev_code,
   tr_devenirlot_dev.dev_libelle,
  tg_parametre_par.par_nom,
   tj_caracteristiquelot_car.car_par_code,
   tj_caracteristiquelot_car.car_methode_obtention,
  tj_caracteristiquelot_car.car_val_identifiant,
   tj_caracteristiquelot_car.car_valeur_quantitatif,
   tr_valeurparametrequalitatif_val.val_libelle
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
	WHERE ope_dic_identifiant=6
	AND (lot_std_code='CIV' OR lot_std_code='AGJ')
  group by year
  ORDER BY t_operation_ope.ope_date_debut;

CREATE OR REPLACE VIEW iav.vue_lot_ope_car AS 
 SELECT t_operation_ope.ope_identifiant,
  t_lot_lot.lot_identifiant,
  t_operation_ope.ope_dic_identifiant,
  extract(year from t_operation_ope.ope_date_debut) as year,
  t_lot_lot.lot_effectif, t_lot_lot.lot_quantite,
   t_lot_lot.lot_tax_code, t_lot_lot.lot_std_code,
   tr_taxon_tax.tax_nom_latin,
   tr_stadedeveloppement_std.std_libelle,
   tr_devenirlot_dev.dev_code,
   tr_devenirlot_dev.dev_libelle,
  tg_parametre_par.par_nom,
   tj_caracteristiquelot_car.car_par_code,
   tj_caracteristiquelot_car.car_methode_obtention,
  tj_caracteristiquelot_car.car_val_identifiant,
   tj_caracteristiquelot_car.car_valeur_quantitatif,
   tr_valeurparametrequalitatif_val.val_libelle
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
	WHERE ope_dic_identifiant=6
	AND (lot_std_code='CIV' OR lot_std_code='AGJ')
  group by year
  ORDER BY t_operation_ope.ope_date_debut;

ALTER TABLE iav.vue_lot_ope_car OWNER TO postgres;
GRANT ALL ON TABLE iav.vue_lot_ope_car TO postgres;
GRANT SELECT, UPDATE, INSERT ON TABLE iav.vue_lot_ope_car TO iav;
GRANT SELECT, UPDATE, INSERT ON TABLE iav.vue_lot_ope_car TO invite;
 
INSERT INTO stacomi.stacomi_observation_places_op
	SELECT uuid_generate_v4() as op_id , 
	'Lambert93' as op_gis_systemname , 
	'stacomi' as op_gis_layername,
	 'sta_coordonnee' as op_gislocation, -- pas sur que ce soit ça ici
	 substring(sta_nom from 1 for 20) as op_placename,	
	 10 AS op_no_observationplacetype, -- sampling station dans nomenclature
	mm_no_monitoring_type integer,
        mm_no_monitoring_direction integer,
        mm_escapment_rate real,
	CONSTRAINT migration_monitoring_id PRIMARY KEY (ob_id),
	CONSTRAINT fk_mm_monitoring_direction FOREIGN KEY (mm_no_monitoring_direction)
	REFERENCES dbeel_nomenclature.migration_direction (no_id) MATCH SIMPLE
	ON UPDATE CASCADE ON DELETE RESTRICT,
	CONSTRAINT fk_mm_monitoring_type FOREIGN KEY (mm_no_monitoring_type)
	REFERENCES dbeel_nomenclature.control_type (no_id) MATCH SIMPLE
	ON UPDATE CASCADE ON DELETE RESTRICT
	 *	
	 FROM iav.t_station_sta;



