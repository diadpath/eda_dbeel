-- Script de creation de la table de buffer, et remplissage depuis le CSV.
-- @author : Marion Hoffmann

--On force l'encodage en mode 'Windows Western', pour éviter les problèmes de conversion depuis Excel
SET client_encoding = 'WIN1252';

-- On supprime la table buffer si ell existe
DROP TABLE IF EXISTS buffer;

-- Et on recrée la nouvelle, avec la derniere structure
CREATE TABLE buffer
(
  id_barrage integer NOT NULL,
  barrage_aval integer,
  modification character varying (10),
  ref_cpl character varying(9) NOT NULL,
  id_ouvrage character varying(9) NOT NULL,
  ref_bd character varying(40) NOT NULL,
  dep character varying(3) NOT NULL,
  cours_eau character varying(80) NOT NULL,
  nom_principal character varying(80) NOT NULL,
  autre_nom character varying(80) NOT NULL,
  commune_rd character(80) NOT NULL,
  commune_rg character varying(80) NOT NULL,
  coord_x character varying (30), --A changer en integer NOT NULL dès que pb . sera résolu
  coord_y character varying (30), --A changer en integer NOT NULL dès que pb . sera résolu
  z_cote real,
  z_ref character varying (50),
  pk real,
  pk_mer real,
  observateur character varying(80) NOT NULL,
  dt_derniere_viste character varying (15),
  chute_sig real,
  chute_etiage character varying (30),
  chute_module real,
  chute_exploitee real,
  lg_fixe character varying (20),
  lg_mobile character varying (20),
  surface_retenue real,
  volume_retenue character varying (20),
  surface_bv real,
  date_construction character varying (15),
  id_derivation integer,
  id_ancien_moulin integer,
  id_fondee_en_titre integer,
  id_usage_1 character varying (20),
  id_autre_usage_1 character varying (40),
  id_usage_2 character varying (40),
  id_autre_usage_2 character varying (30),
  id_hydro_e integer,
  id_turbine_activite character varying (20),
  date_arrete character varying (40),
  date_echeance character varying (15),
  puissance_equipement character varying (20),
  module real,
  q_reservee text,
  q_equipement real,
  q_equipement_module real,
  q_equipement_module_prct real,
  type_turbine character varying (20),
  intitule_carac_turbine character varying(200) NOT NULL,
  nb_turbines integer,
  espacement_grille character varying (50),
  diametre_roue real,
  nb_pales real,
  vitesse_rotation real,
  id_type_princ_1 integer,
  type1_autre character varying (50),
  id_type_compl_2 real,
  id_type_compl_3 integer,
  priorite integer,
  ang real,
  ala real,
  lpm real,
  sat real,
  trf real,
  ind_confiance integer,
  anc_pecherie_avalaison character varying (20),
  effacement character varying (20),
  mortalite_devalaison character varying (30),
  id_type_pap_1 character varying (20),
  annee_pap_1 character varying (20),
  id_type_pap_2 integer,
  annee_pap_2 integer,
  id_type_pap_3 integer,
  annee_pap_3 integer,
  q_reservee_dispo_franchissement character varying (30),
  observations character varying(400) NOT NULL,
  cout_total_franchissement character varying(255) NOT NULL,
  amenagement_projete character varying(255) NOT NULL,
  cout_previsionnel character varying(255) NOT NULL,
  maitre_ouvrage character varying(80) NOT NULL,
  _col_vide_ character varying(10),
  usage character varying(255) NOT NULL,
  type_ouvrage_princ character varying(300) NOT NULL,
  dispositif_franchissement character varying(255) NOT NULL
  
)
WITH (OIDS=FALSE);
ALTER TABLE buffer OWNER TO postgres;
COMMENT ON TABLE buffer IS 'table comprenant tout le document Excel de la Base de Pierre';

-- On rempli la table avec toutes les donnees du CSV
COPY buffer
FROM 'C:/temp/dump_bd_obstacle.csv'
USING DELIMITERS ';'
WITH CSV 
    HEADER
    FORCE NOT NULL ref_cpl, id_ouvrage, ref_bd, dep, cours_eau, nom_principal, autre_nom,
	commune_rd, commune_rg, coord_x, coord_y, observateur, intitule_carac_turbine,
	observations, cout_total_franchissement, amenagement_projete, cout_previsionnel,
	maitre_ouvrage, _col_vide_, usage, type_ouvrage_princ,dispositif_franchissement
;

