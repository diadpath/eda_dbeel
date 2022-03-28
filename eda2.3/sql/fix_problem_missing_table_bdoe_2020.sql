-- Premier problème : la table existe. Avant c'était une vue.... Bon comme c'est vide elle nous sert à rien
DROP TABLE bdoe.export_general;

-- Ci dessous le scrit de création de la vue que j'ai récupéré de l'ancienne base. J'ai du modifier car la table franchissement_piscicole
-- a changé un peu et ne contient plus la colonne "position" je pense qu'ils ont créé une autre table

CREATE VIEW bdoe.export_general
 AS
 SELECT ouv.ouv_id AS cdobstecou,
    obr.ref_nom AS nomprincip,
    st_x(obr.ref_position_l93) AS ouv_coord_x,
    st_y(obr.ref_position_l93) AS ouv_coord_y,
    typ.typ_nom AS ouv_type_nom,
    usa.ouv_usage_energie_hydro,
    usa.ouv_usages,
    eta.eta_nom AS ouv_etat,
        CASE
            WHEN lie.liens_ref_id = obr.ref_id THEN 'Principal'::text
            WHEN lie2.liens_ref_id_fils = obr.ref_id THEN 'Secondaire'::text
            ELSE ''::text
        END AS ouv_liaison,
    array_to_string(array_agg(lie.liens_ref_id_fils), ', '::text) AS ouv_ouvrage_lie,
    hco.array_hco_hauteur[1] AS ouv_hauteur_chute_1,
    hco.array_hco_date_mesure[1] AS ouv_date_hauteur_chute_1,
    hco.array_ope_libelle[1] AS ouv_operateur_hauteur_chute_1,
    hco.array_hco_ope_precision[1] AS ouv_precision_hauteur_chute_1,
    hco.array_hco_hauteur[2] AS ouv_hauteur_chute_2,
    hco.array_hco_date_mesure[2] AS ouv_date_hauteur_chute_2,
    hco.array_ope_libelle[2] AS ouv_operateur_hauteur_chute_2,
    hco.array_hco_ope_precision[2] AS ouv_precision_hauteur_chute_2,
    hco.array_hco_hauteur[3] AS ouv_hauteur_chute_3,
    hco.array_hco_date_mesure[3] AS ouv_date_hauteur_chute_3,
    hco.array_ope_libelle[3] AS ouv_operateur_hauteur_chute_3,
    hco.array_hco_ope_precision[3] AS ouv_precision_hauteur_chute_3,
    hco.array_hco_hauteur[4] AS ouv_hauteur_chute_4,
    hco.array_hco_date_mesure[4] AS ouv_date_hauteur_chute_4,
    hco.array_ope_libelle[4] AS ouv_operateur_hauteur_chute_4,
    hco.array_hco_ope_precision[4] AS ouv_precision_hauteur_chute_4,
    hco.array_hco_hauteur[5] AS ouv_hauteur_chute_5,
    hco.array_hco_date_mesure[5] AS ouv_date_hauteur_chute_5,
    hco.array_ope_libelle[5] AS ouv_operateur_hauteur_chute_5,
    hco.array_hco_ope_precision[5] AS ouv_precision_hauteur_chute_5,
    ouv.ouv_arasement,
    ouv.ouv_arasement_date AS ouv_date_arasement,
    ouv.ouv_derasement,
    ouv.ouv_derasement_date AS ouv_date_derasement,
    fpd.array_fty_nom[1] AS dispo_franch_piscicole_1,
    fpd.array_date_mes[1] AS date_mes_dispo_franch_piscicole_1,
    fpd.array_fty_nom[2] AS dispo_franch_piscicole_2,
    fpd.array_date_mes[2] AS date_mes_dispo_franch_piscicole_2,
    fpd.array_fty_nom[3] AS dispo_franch_piscicole_3,
    fpd.array_date_mes[3] AS date_mes_dispo_franch_piscicole_3,
    fpd.array_fty_nom[4] AS dispo_franch_piscicole_4,
    fpd.array_date_mes[4] AS date_mes_dispo_franch_piscicole_4,
    fpd.array_fty_nom[5] AS dispo_franch_piscicole_5,
    fpd.array_date_mes[5] AS date_mes_dispo_franch_piscicole_5,
        CASE
            WHEN mou.array_moo_mcm_id[1] = 1 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS mesure_corrective_montaison_gestion,
        CASE
            WHEN mou.array_moo_mcm_id[2] = 2 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS mesure_corrective_montaison_equipement,
        CASE
            WHEN dou.array_doe_mcd_id[1] = 1 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS mesure_corrective_devalaison_gestion,
        CASE
            WHEN dou.array_doe_mcd_id[2] = 2 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS mesure_corrective_devalaison_equipement,
        CASE
            WHEN dou.array_doe_mcd_id[3] = 3 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS mesure_corrective_devalaison_turbine,
        CASE
            WHEN cso.array_cso_mcc_id[1] = 1 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS mesure_corrective_continuite_gestion,
        CASE
            WHEN cso.array_cso_mcc_id[2] = 2 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS mesure_corrective_continuite_equipement,
        CASE
            WHEN cso.array_cso_mcc_id[3] = 3 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS mesure_corrective_continuite_recharge,
    ouv.ouv_commentaire_mesures AS mesure_corrective_commentaire,
    ouv.ouv_debut_activite AS date_debut_activite,
    ouv.ouv_fin_activite AS date_fin_activite,
    vde.vdr_libelle AS "variabilité_debit_reserve",
    ouv.ouv_debit_reserve AS debit_reserve,
    ouv.ouv_debit_montaison AS debit_minimal_montaison,
    ouv.ouv_debit_devalaison AS debit_minimal_devalaison,
    ouv.ouv_debit_maximal AS "debit_maximal_autorisé",
    ouv.ouv_debit_commentaire AS commentaire_debit,
    ouv.ouv_longueur_troncon AS longueur_troncon_cc,
    ouv.ouv_ecartement_grille AS ecartement_grille,
    ouv.ouv_cote_basse AS cote_retenue_basse,
    ouv.ouv_cote_haute AS cote_retenue_haute,
        CASE
            WHEN ouv.ouv_liste1 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS classement_liste_1,
        CASE
            WHEN ouv.ouv_liste2 THEN 'Oui'::text
            ELSE 'Non'::text
        END AS classement_liste_2,
    ouv.ouv_date_liste AS date_arrete_classement,
    array_to_string(eci.array_esp_nom_vernaculaire, ', '::text) AS especes_cibles,
    oss.array_sts_libelle[1] AS statut_sdage_1,
    oss.array_sts_libelle[2] AS statut_sdage_2,
    oss.array_sts_libelle[3] AS statut_sdage_3,
    array_to_string(ost.array_sto_libelle, ', '::text) AS statut_administratif,
    ouv.ouv_date_fin_acte AS date_fin_acte,
        CASE
            WHEN ouv.ouv_reglement_eau THEN 'Oui'::text
            ELSE 'Non'::text
        END AS existence_reglement_eau,
    ouv.ouv_surface_bv AS surface_bv_amont,
    ouv.ouv_source_surface AS source_surface_bv,
    ouv.ouv_module AS module_cours_d_eau,
    ouv.ouv_source_module AS source_module,
    ouv.ouv_surface_bv_irstea AS surface_bv_amont_irstea,
    ouv.ouv_module_irstea AS module_cours_d_eau_irstea,
    ouv.ouv_robustesse_irstea AS robustesse_irstea,
    obr.ref_z AS altitude,
    ouv.ouv_lineaire_aval AS lineaire_aval,
    ouv.ouv_surface_retenue AS surface_retenue,
    ouv.ouv_surface_source AS source_surface_retenue,
    ouv.ouv_volume_retenue AS volume_retenue,
    ouv.ouv_volume_source AS source_volume_retenue,
    ouv.ouv_longueur_remous AS longueur_remous,
    ouv.ouv_longueur_source AS source_longueur_remous,
    ouv.ouv_chute_amont AS chute_naturelle_amont,
    ouv.ouv_chute_aval AS chute_naturelle_aval,
    ouv.ouv_commentaire_chute AS commentaire_chutes_naturelles,
    ouv.ouv_commentaires AS autres_commentaires,
    obr.ref_nom_topo AS nom_cours_d_eau_topo,
    obr.ref_libelle_commune AS commune,
    obr.ref_code_insee_dept AS departement,
    obr.ref_code_hydro AS code_cours_eau,
    obr.ref_zone_hydro AS code_zone_hydro,
    substr(obr.ref_zone_hydro, 1, 2) AS code_secteur_hydro,
    obr.ref_bassin AS nom_bassin_hydro
   FROM bdoe.ouvrage ouv
     JOIN roe.obstacle_referentiel obr ON ouv.ouv_id = obr.ref_id
     LEFT JOIN bdoe.variabilite_debit vde ON vde.vdr_id = ouv.ouv_vdr_id
     LEFT JOIN roe.type typ ON typ.typ_id = obr.ref_typ_id
     LEFT JOIN ( SELECT usage.usa_obs_id,
                CASE
                    WHEN array_to_string(array_agg(usage_type.uty_id), ', '::text) ~~ '%5%'::text THEN 'Oui'::text
                    ELSE 'Non'::text
                END AS ouv_usage_energie_hydro,
            replace(replace(array_to_string(array_agg(usage_type.uty_nom), ', '::text), 'Energie et hydroélectricité'::text, ''::text), ', Energie et hydroélectricité'::text, ''::text) AS ouv_usages
           FROM roe.usage
             LEFT JOIN roe.usage_type ON usage_type.uty_id = usage.usa_uty_id
          GROUP BY usage.usa_obs_id) usa ON usa.usa_obs_id = obr.ref_id
     LEFT JOIN roe.etat eta ON eta.eta_id = obr.ref_eta_id
     LEFT JOIN roe.liens lie ON lie.liens_ref_id = obr.ref_id
     LEFT JOIN roe.liens lie2 ON lie2.liens_ref_id_fils = obr.ref_id
     LEFT JOIN ( SELECT hauteur_chute.hco_ouv_id,
            array_agg(hauteur_chute.hco_hauteur ORDER BY hauteur_chute.hco_date_mesure DESC NULLS LAST) AS array_hco_hauteur,
            array_agg(hauteur_chute.hco_date_mesure ORDER BY hauteur_chute.hco_date_mesure DESC NULLS LAST) AS array_hco_date_mesure,
            array_agg(hauteur_chute.hco_ope_precision ORDER BY hauteur_chute.hco_date_mesure DESC NULLS LAST) AS array_hco_ope_precision,
            array_agg(ope.ope_libelle ORDER BY hauteur_chute.hco_date_mesure DESC NULLS LAST) AS array_ope_libelle
           FROM bdoe.hauteur_chute
             LEFT JOIN bdoe.operateur ope ON ope.ope_id = hauteur_chute.hco_ope_id
          GROUP BY hauteur_chute.hco_ouv_id) hco ON hco.hco_ouv_id = ouv.ouv_id
     LEFT JOIN ( SELECT fpiorder.fpi_ref_id,
            array_agg(fpiorder.fty_nom) AS array_fty_nom,
            array_agg(fpiorder.dfp_date_mes) AS array_date_mes
           FROM ( SELECT fpi.fpi_ref_id,
                    fpt.fty_nom,
                    fpd_1.dfp_date_mes
                   FROM ( SELECT franchissement_piscicole.fpi_id,
                            franchissement_piscicole.fpi_ref_id,
                            franchissement_piscicole.fpi_fty_id,
                            franchissement_piscicole.fpi_fst_id,
                            franchissement_piscicole.fpi_fpp_id
                           FROM roe.franchissement_piscicole) fpi
                     LEFT JOIN bdoe.franchissement_piscicole_bdoe fpd_1 ON fpi.fpi_id = fpd_1.dfp_fpi_id
                     LEFT JOIN roe.franchissement_piscicole_type fpt ON fpt.fty_id = fpi.fpi_fty_id
				      LEFT JOIN roe.franchissement_piscicole_position fpp ON fpp.fpp_id = fpi.fpi_fpp_id
                  ORDER BY fpi.fpi_id DESC) fpiorder
          GROUP BY fpiorder.fpi_ref_id) fpd ON fpd.fpi_ref_id = obr.ref_id
     LEFT JOIN ( SELECT mou1.moo_ouv_id,
            array_agg(mou1.moo_mcm_id) AS array_moo_mcm_id
           FROM ( SELECT montaison_ouvrage.moo_mcm_id,
                    montaison_ouvrage.moo_ouv_id
                   FROM bdoe.montaison_ouvrage
                  ORDER BY montaison_ouvrage.moo_mcm_id) mou1
          GROUP BY mou1.moo_ouv_id) mou ON mou.moo_ouv_id = ouv.ouv_id
     LEFT JOIN ( SELECT dou1.doe_ouv_id,
            array_agg(dou1.doe_mcd_id) AS array_doe_mcd_id
           FROM ( SELECT devalaison_ouvrage.doe_mcd_id,
                    devalaison_ouvrage.doe_ouv_id
                   FROM bdoe.devalaison_ouvrage
                  ORDER BY devalaison_ouvrage.doe_mcd_id) dou1
          GROUP BY dou1.doe_ouv_id) dou ON dou.doe_ouv_id = ouv.ouv_id
     LEFT JOIN ( SELECT cso1.cso_ouv_id,
            array_agg(cso1.cso_mcc_id) AS array_cso_mcc_id
           FROM ( SELECT continuite_ouvrage.cso_mcc_id,
                    continuite_ouvrage.cso_ouv_id
                   FROM bdoe.continuite_ouvrage
                  ORDER BY continuite_ouvrage.cso_mcc_id) cso1
          GROUP BY cso1.cso_ouv_id) cso ON cso.cso_ouv_id = ouv.ouv_id
     LEFT JOIN ( SELECT eci_1.ecc_ouv_id,
            array_agg(ebd.esp_nom_vernaculaire) AS array_esp_nom_vernaculaire
           FROM bdoe.espece_cible eci_1
             LEFT JOIN bdoe.espece_bdoe ebd ON ebd.esp_id = eci_1.ecc_esp_id
          GROUP BY eci_1.ecc_ouv_id) eci ON eci.ecc_ouv_id = ouv.ouv_id
     LEFT JOIN ( SELECT oss_1.oss_ouv_id,
            array_agg(ssd.sts_libelle) AS array_sts_libelle
           FROM bdoe.ouvrage_statut_sdage oss_1
             LEFT JOIN bdoe.statut_sdage ssd ON ssd.sts_id = oss_1.oss_sts_id
          GROUP BY oss_1.oss_ouv_id) oss ON oss.oss_ouv_id = ouv.ouv_id
     LEFT JOIN ( SELECT ost_1.oso_ouv_id,
            array_agg(sou.sto_libelle) AS array_sto_libelle
           FROM bdoe.ouvrage_statut ost_1
             LEFT JOIN bdoe.statut_ouvrage sou ON sou.sto_id = ost_1.oso_sto_id
          GROUP BY ost_1.oso_ouv_id) ost ON ost.oso_ouv_id = ouv.ouv_id
  WHERE ouv.ouv_gelee IS NULL OR ouv.ouv_gelee = false
  GROUP BY ouv.ouv_id, obr.ref_nom, (st_x(obr.ref_position_l93)), (st_y(obr.ref_position_l93)), typ.typ_nom, eta.eta_nom, lie.liens_ref_id, lie2.liens_ref_id_fils, obr.ref_id, usa.ouv_usage_energie_hydro, usa.ouv_usages, hco.array_hco_hauteur, hco.array_hco_date_mesure, hco.array_ope_libelle, hco.array_hco_ope_precision, fpd.array_fty_nom, fpd.array_date_mes, vde.vdr_libelle, (array_to_string(eci.array_esp_nom_vernaculaire, ', '::text)), oss.array_sts_libelle, (array_to_string(ost.array_sto_libelle, ', '::text)), mou.array_moo_mcm_id, dou.array_doe_mcd_id, cso.array_cso_mcc_id;

ALTER TABLE bdoe.export_general
    OWNER TO geobs_p;

