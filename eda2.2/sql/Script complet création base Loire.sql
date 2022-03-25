-- Script de creation de la base Loire
-- @author : Marion Hoffmann

--On force l'encodage en mode 'Windows Western', pour éviter les problèmes de conversion depuis Excel
SET client_encoding = 'WIN1252';


--Etape 1 : on crée la table buffer qui correspond au csv total

	-- On supprime la table buffer si elle existe
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
  coord_x real,
  coord_y real,
  z_cote real,
  z_ref character varying (50),
  pk real,
  pk_mer real,
  observateur character varying(80) NOT NULL,
  dt_derniere_visite character varying (15),
  chute_sig real,
  chute_etiage character varying (30),
  chute_module real,
  chute_exploitee real,
  lg_fixe character varying (20),
  lg_mobile character varying (20),
  surface_retenue real,
  volume_retenue character varying (20),
  surface_bv real,
  surface_bv_AELB character varying (30),
  date_construction character varying (15),
  id_derivation integer,
  id_ancien_moulin integer,
  id_fondee_en_titre integer,
  id_usage_1 integer,
  id_autre_usage_1 character varying (40),
  id_usage_2 integer,
  id_autre_usage_2 character varying (30),
  id_hydro_e integer,
  id_turbine_activite character varying (20),
  date_arrete character varying (40),
  date_echeance character varying (15),
  puissance_equipement character varying (20),
  module real,
  q_reserve text,
  q_equipement real,
  q_equipement_module real,
  q_equipement_module_prct real,
  type_turbine integer,
  intitule_carac_turbine character varying(200) NOT NULL,
  nb_turbines integer,
  espacement_grille character varying (50),
  diametre_roue character varying (40),
  nb_pales character varying (40),
  vitesse_rotation character varying (40),
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
  anc_pecherie_avalaison integer,
  effacement integer,
  mortalite_devalaison_ANG character varying (30),
  mortalite_devalaison_SAT character varying (30),
  id_type_pap_1 integer,
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
  usage character varying(255) NOT NULL,
  type_ouvrage_princ character varying(300) NOT NULL,
  dispositif_franchissement character varying(255) NOT NULL
  
)
WITH (OIDS=FALSE);
ALTER TABLE buffer OWNER TO postgres;
COMMENT ON TABLE buffer IS 'table comprenant tout le document Excel de la Base de Pierre';

-- On remplit la table avec toutes les données du CSV
COPY buffer
FROM 'C:/temp/dump_bd_obstacle.csv'
USING DELIMITERS ';'
WITH CSV 
    HEADER
   FORCE NOT NULL ref_cpl, id_ouvrage, ref_bd, dep, cours_eau, nom_principal, autre_nom,
	commune_rd, commune_rg, coord_x, coord_y, observateur, intitule_carac_turbine,
	observations, cout_total_franchissement, amenagement_projete, cout_previsionnel,
	maitre_ouvrage, usage,type_ouvrage_princ,dispositif_franchissement
;

--Etape 2 : on supprime toutes les tables dans l'ordre inverse de leur création pour éviter qu'il râle avec les clés étrangères
	--Suppression de la vue v_ouv_passe
DROP VIEW IF EXISTS v_ouv_passe;

	--Suppression de la vue v_ouv_nao 
DROP VIEW IF EXISTS v_ouv_nao;

	--Suppression de la vue v_ouv_fba
DROP VIEW IF EXISTS v_ouv_fba;

	--Suppression de la vue v_ouv_den
DROP VIEW IF EXISTS v_ouv_den;

	--Suppressiont_turbine_turb
DROP TABLE IF EXISTS t_turbine_turb;

	--Suppression t_devalaison_deval
DROP TABLE IF EXISTS t_devalaison_deval;

	--Suppression t_franchisbar_fba
DROP TABLE IF EXISTS t_franchisbar_fba;

	--Suppression tj_espececible_esp
DROP TABLE IF EXISTS tj_espececible_esp;

	--Suppression t_denivele_den
DROP TABLE IF EXISTS t_denivele_den;

	--Suppression tj_ouvrageusage_ouu
DROP TABLE IF EXISTS tj_ouvrageusage_ouu;

	--Suppression tj_natureouvrage_nao
DROP TABLE IF EXISTS tj_natureouvrage_nao;

	--Suppression t_info_compl_inc
DROP TABLE IF EXISTS t_info_compl_inc;

	--Suppression t_passe_passe
DROP TABLE IF EXISTS t_passe_passe;

	--Suppression t_obstacle_ofr
DROP TABLE IF EXISTS t_obstaclefr_ofr;

	--Suppression tr_typeturbine_typt
DROP TABLE IF EXISTS tr_typeturbine_typt;

	--Suppression tr_typepasse_typ
DROP TABLE IF EXISTS tr_typepasse_typ;

	--Suppression tr_taxon_tax
DROP TABLE IF EXISTS tr_taxon_tax;
	
	--Suppression tr_typenote_tyn
DROP TABLE IF EXISTS tr_typenote_tyn;

	--Suppression tr_usage_us
DROP TABLE IF EXISTS tr_usage_us;

	--Suppression tr_nature_nov
DROP TABLE IF EXISTS tr_nature_nov;

	--Suppression t_bvsansbar_bv
DROP TABLE IF EXISTS t_bvsansbar_bv;

	--Suppression t_ouvrage_ou
DROP TABLE IF EXISTS t_ouvrage_ouv;


--Etape 3 : on crée toutes les vues qui vont nous permettre ensuite de rapatrier les données de la base Bretagne


/* Connection à une base distante

 http://www.postgresql.org/docs/current/static/dblink.html
 A lancer depuis 'BASE Pierre'
*/

-- création des fonctions db_link permettant un lien vers d'autres bases
CREATE OR REPLACE FUNCTION dblink_connect (text)
RETURNS text
AS '$libdir/dblink','dblink_connect'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION dblink_connect (text, text)
RETURNS text
AS '$libdir/dblink','dblink_connect'
LANGUAGE C STRICT;

--dblink_connect -- opens a persistent connection to a remote database

CREATE OR REPLACE FUNCTION dblink_disconnect (text)
RETURNS text
AS '$libdir/dblink','dblink_disconnect'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION dblink (text, text)
RETURNS setof record
AS '$libdir/dblink','dblink_record'
LANGUAGE C STRICT;

/*
dblink executes a query (usually a SELECT, but it can be any SQL statement that returns rows) in a remote database.
When two text arguments are given, the first one is first looked up as a persistent connection's name;
 if found, the command is executed on that connection. If not found, the first argument is treated as a connection info string 
as for dblink_connect, and the indicated connection is made just for the duration of this command. 
*/

-- essai de connexion 
SELECT * from dblink_connect('base=Migang','hostaddr=127.0.0.1 port=5432 dbname=Migang user=postgres password=postgres'); --lien vers la base Migang
SELECT * from dblink_connect('base=BASE Pierre','hostaddr=127.0.0.1 port=5432 dbname=''BASE Pierre'' user=postgres password=postgres'); --lien vers la base BASE Pierre

--Création de la vue t_ouvrage_ouv de la base Bretagne

drop view if exists Migang_t_ouvrage_view;

create or replace view Migang_t_ouvrage_view as

      select *
        from dblink('base=Migang', 'select * from t_ouvrage_ouv')
        as t1(ouv_id character(7),ouv_ouv_id character(7),ouv_baraval character(7),ouv_codegenerique character(8),ouv_distancesource real,ouv_distancemer real,ouv_distancemareedyn real,ouv_sbv real,ouv_bassin character(20),ouv_rinom character (150),ouv_abscisse real,ouv_ordonnee real,ouv_libelle character(100),ouv_commentaires text); -- la fonction doit retourner le nom et le type du champ
-- pour voir: select * from Migang_t_ouvrage_view ;
--Création de la vue t_bvsansbar_bv de la base Bretagne

drop view if exists Migang_t_bvsansbar_view;

create or replace view Migang_t_bvsansbar_view as

      select *
        from dblink('base=Migang', 'select * from t_bvsansbar_bv')
        as t1(bv_id character(10),bv_codegenerique character(8),bv_distancesource real,bv_distancemer real,bv_distancemareedyn real,bv_sbv real,bv_rinom character(150),bv_abscisse real,bv_ordonnee real,bv_commentaires text); -- la fonction doit retourner le nom et le type du champ

--Création de la vue t_denivele_den de la base Bretagne

drop view if exists Migang_t_denivele_view;

create or replace view Migang_t_denivele_view as

       select *
        from dblink('base=Migang', 'select * from t_denivele_den')
        as t1(den_id integer,den_ouv_id character(7),den_date date, den_denivele real,den_debit real); -- la fonction doit retourner le nom et le type du champ

--Création de la vue t_devalaison_deval de la base Loire

drop view if exists BPierre_t_devalaison_view;

create or replace view BPierre_t_devalaison_view as

        select *
        from dblink('base=BASE Pierre', 'select * from t_devalaison_deval')
        as t1(deval_code integer,deval_ouv_id character(7),deval_existdeval boolean,deval_hauteur integer,deval_grilles boolean,deval_ecartement integer,deval_vitesse integer); -- la fonction doit retourner le nom et le type du champ

--Création de la vue t_franchisbar_fba de la base Bretagne

drop view if exists Migang_t_franchisbar_view;

create or replace view Migang_t_franchisbar_view as

        select *
        from dblink('base=Migang', 'select * from t_franchisbar_fba')
        as t1(fba_id integer,fba_ouv_id character(7),fba_tax_code character(6),fba_valeurnote real,fba_tyn_typenote character(10),fba_datedebut date,fba_datefin date,fba_commentaires text);

--Création de la vue t_passe_passe de la base Bretagne

drop view if exists Migang_t_passe_view;

create or replace view Migang_t_passe_view as

      select *
        from dblink('base=Migang', 'select * from t_passe_passe')
        as t1(passe_code integer,passe_ouv_id character(7),passe_typ_code character(20),passe_datedebut date,passe_datefin date,passe_descr character(40));

--Création de la vue t_turbine_turb de la base Bretagne (pas de données dans la base-->à créer si nouvelle donnée)

--Création de la vue tj_espececible_esp de la base Bretagne (pas de données dans la base-->à créer si nouvelle donnée)

--Création de la vue tj_natureouvrage_nao de la base Bretagne

drop view if exists Migang_tj_natureouvrage_view;

create or replace view Migang_tj_natureouvrage_view as

      select *
        from dblink('base=Migang', 'select * from tj_natureouvrage_nao')
        as t1(nao_id integer,nao_nov_code integer,nao_ouv_id character(7),nao_datedebut date,nao_datefin date);

--Création de la vue tj_ouvrageusage_ouu de la base Bretagne

drop view if exists Migang_tj_ouvrageusage_view;

create or replace view Migang_tj_ouvrageusage_view as

      select *
        from dblink('base=Migang', 'select * from tj_ouvrageusage_ouu')
        as t1(ouu_us_code integer,ouu_ouv_id character(7),ouu_datedebut date,ouu_datefin date);


--Création de la vue tr_taxon_tax de la base Bretagne

drop view if exists Migang_tr_taxon_view;

create or replace view Migang_tr_taxon_view as

      select *
        from dblink('base=Migang', 'select * from tr_taxon_tax')
        as t1(tax_code character(6),tax_nom_latin character(30),tax_nom_commun character(30),tax_ntx_code character(4),tax_tax_code character(6),tax_rang integer);


--Etape 4 : on crée toutes les tables qui ne font pas référence à une autre table

	--Création de la table t_ouvrage_ouv

CREATE TABLE t_ouvrage_ouv
(
  ouv_id character varying (7) NOT NULL,
  ouv_codeAREA character varying (9),
  ouv_ouv_id character varying(40), -- reference l'ouvrage père
  ouv_baraval character varying(40),
  ouv_codegenerique character varying(40),
  ouv_distancesource real default 0,
  ouv_distancemer real,
  ouv_distancemareedyn real,
  ouv_sbv real,
  ouv_bassin character varying(20),
  ouv_rinom character varying(150),
  ouv_abscisse character varying (20),
  ouv_ordonnee character varying (20),
  ouv_libelle character varying(100),
  ouv_debit_reserve character varying (50),
  ouv_commentaires text,
  ouv_zone_geo character varying (30),
  CONSTRAINT c_pk_ouv_idouvrage PRIMARY KEY (ouv_id),
  CONSTRAINT c_fk_ouv_ouv_id FOREIGN KEY (ouv_ouv_id)
      REFERENCES t_ouvrage_ouv (ouv_id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION
) 
WITH (OIDS=FALSE);
ALTER TABLE t_ouvrage_ouv OWNER TO postgres;
COMMENT ON COLUMN t_ouvrage_ouv.ouv_id Is 'identifiant ouvrage';
COMMENT ON COLUMN t_ouvrage_ouv.ouv_codeAREA IS 'identifiant des barrages dans la base nationale';
COMMENT ON COLUMN t_ouvrage_ouv.ouv_ouv_id IS 'reference l''ouvrage pere';
COMMENT ON COLUMN t_ouvrage_ouv.ouv_baraval Is 'barrage aval';
COMMENT ON COLUMN t_ouvrage_ouv.ouv_codegenerique IS 'code entité hydro';
COMMENT ON COLUMN t_ouvrage_ouv.ouv_sbv IS 'surface bassin versant';
COMMENT ON COLUMN t_ouvrage_ouv.ouv_rinom IS 'nom rivière';
COMMENT ON COLUMN t_ouvrage_ouv.ouv_libelle IS 'nom barrage';

--Insertion des données de la base Loire
INSERT INTO t_ouvrage_ouv (ouv_id, ouv_codeAREA,ouv_distancemer,ouv_sbv,ouv_rinom,ouv_abscisse,ouv_ordonnee,ouv_libelle,ouv_debit_reserve,ouv_commentaires,ouv_zone_geo)
    SELECT id_barrage, id_ouvrage, pK_mer,surface_bv,cours_eau,coord_x,coord_y,nom_principal,q_reserve,observations,'BV Loire'
    FROM buffer;

	--Création de la table t_bvsansbar_bv

CREATE TABLE t_bvsansbar_bv
(
  bv_id character varying(10) NOT NULL,
  bv_codegenerique character varying(8) NOT NULL,
  bv_distancesource real NOT NULL,
  bv_distancemer real NOT NULL,
  bv_distancemareedyn real NOT NULL,
  bv_sbv real NOT NULL,
  bv_rinom character varying(150),
  bv_abscisse real NOT NULL,
  bv_ordonnee real NOT NULL,
  bv_commentaires text
)
WITH (OIDS=FALSE);
ALTER TABLE t_bvsansbar_bv OWNER TO postgres;
--Pas de données dans base Loire 


	--Création de la table tr_nature_nov

CREATE TABLE tr_nature_nov
(
  nov_code integer NOT NULL,
  nov_partieouvrage character varying(40) NOT NULL,
  nov_organe character varying(40) NOT NULL,
  nov_description text,
  CONSTRAINT c_pk_nov PRIMARY KEY (nov_code),
  CONSTRAINT c_uq_nov_nom UNIQUE (nov_partieouvrage, nov_organe)
)
WITH (OIDS=FALSE);
ALTER TABLE tr_nature_nov OWNER TO postgres;
--Insertion des données 
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (15, 'Ouvrage fixe', 'Demantele ou ruine', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (18, 'Ouvrage fixe', 'Barrage', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (19, 'Ouvrage fixe', 'Digue', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (6, 'Ouvrage fixe', 'Deversoir incline', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (5, 'Ouvrage fixe', 'Deversoir vertical', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (8, 'Ouvrage fixe', 'Radier a paroi inclinee', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (7, 'Ouvrage fixe', 'Radier a paroi verticale', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (10, 'Ouvrage fixe', 'Enrochement libre', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (20, 'Ouvrage fixe', 'Buse', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (21, 'Ouvrage fixe', 'Chute naturelle', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (22, 'Ouvrage fixe', 'Autre', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (23, 'Ouvrage mobile', 'Demantele ou ruine', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (24, 'Ouvrage mobile vannage', 'Clapet basculant', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (25, 'Ouvrage mobile vannage', 'Vanne(s) levante(s)', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (26, 'Ouvrage mobile vannage', 'Madriers  - Planches', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (9, 'Ouvrage mobile vannage', 'Systeme anti-refoulement', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (27, 'Ouvrage mobile vannage', 'Ecluse', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (28, 'Ouvrage mobile vannage', 'Autre', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (29, 'Ouvrage mobile rehausse', 'Clapet basculant', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (30, 'Ouvrage mobile rehausse', 'Vanne(s) levante(s)', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (31, 'Ouvrage mobile rehausse', 'Madriers  - Planches', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (2, 'Ouvrage mobile rehausse', 'Aiguilles', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (32, 'Ouvrage mobile rehausse', 'Autre', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (11, 'Ouvrage', 'Autre', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (1, 'Ouvrage', 'Clapet basculant', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (3, 'Ouvrage', 'Madriers - Planches', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (4, 'Ouvrage', 'Vanne(s) levante(s)', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (12, 'Ouvrage', 'Effacement volontaire', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (13, 'Ouvrage', 'Effacement naturel', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (14, 'Ouvrage', 'Eff nat partiel et abandon d''usage', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (17, 'Bâtit', 'Ancien Moulin', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (16, 'Dérivation', 'Existence d''un bras de dérivation', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (-98, '', 'A Préciser', NULL);
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (0, '', 'Pas d''ouvrage', NULL);	
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (-99, '', 'Sans object', NULL);	
INSERT INTO tr_nature_nov (nov_code, nov_partieouvrage, nov_organe, nov_description) VALUES (33, '', 'Priorité d''effacement', NULL);	
	
	--Création de la table tr_usage_us

CREATE TABLE tr_usage_us
(
  us_code integer,
  us_nom character varying(60) NOT NULL,
  us_commentaire text,
  CONSTRAINT c_pk_us_code PRIMARY KEY (us_code),
  CONSTRAINT c_uq_us_nom UNIQUE (us_nom)
)
WITH (OIDS=FALSE);
ALTER TABLE tr_usage_us OWNER TO postgres;
--Insertion des données 
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (13, 'Electricite vente', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (14, 'Electricite autoconsom.', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (3, 'Navigation', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (4, 'AEP', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (7, 'Irrigation', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (15, 'Industrie', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (5, 'Pisciculture', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (16, 'Securite inondation', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (17, 'Soutien d''etiage', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (10, 'Securite incendie', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (18, 'Regulation niveau d''eau', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (19, 'Loisir-Tourisme-Sport nautique', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (20, 'Abreuvement', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (21, 'Jaugeage', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (22, 'Anti-Erosion', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (23, 'Anti-Maree', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (24, 'Transport', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (25, 'Agrement', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (0, 'Sans usage', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (12, 'Autre', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (26, 'Electricité', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (27, 'Ancienne pêcherie d''avalaison', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (-99, 'Sans object', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (1, 'Production hydroélectrique', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (2, 'Energie Mécanique', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (6, 'Soutien nappe alluviale', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (8, 'Autre Usage agricole', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (9, 'Stabilité du profil en long', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (11, 'Agrément, aire de loisirs', NULL);
INSERT INTO tr_usage_us (us_code, us_nom, us_commentaire) VALUES (-98, 'A préciser', NULL);


	--Création de la table tr_typenote_tyn

CREATE TABLE tr_typenote_tyn
(
  tyn_typenote character varying(50) NOT NULL,
  tyn_description text,
  CONSTRAINT c_pk_tyn_typenote PRIMARY KEY (tyn_typenote)
)
WITH (OIDS=FALSE);
ALTER TABLE tr_typenote_tyn OWNER TO postgres;
--Insertion des données 
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('EXPERTISE', '"""kkk"""');
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('SCORE', '"""kkk"""');
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('HAUTEUR', '"""kkk"""');
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('PROFIL', '"""kkk"""');
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('RUGOSITE', '"""kkk"""');
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('BERGE', '"""kkk"""');
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('DIVERSITE', '"""kkk"""');
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('SCORE2', '"""kkk"""');
INSERT INTO tr_typenote_tyn (tyn_typenote, tyn_description) VALUES ('MORTALITE DEVALAISON', '"""kkk"""');
	
	--Création de la table tr_taxon_tax

CREATE TABLE tr_taxon_tax
(
  tax_code character varying(6) NOT NULL,
  tax_nom_latin character varying(30) NOT NULL,
  tax_nom_commun character varying(30),
  tax_ntx_code character varying(4) NOT NULL,
  tax_tax_code character varying(6),
  tax_rang integer NOT NULL DEFAULT 1,
  CONSTRAINT c_pk_tax PRIMARY KEY (tax_code),
  CONSTRAINT c_uq_tax_nom_latin UNIQUE (tax_nom_latin)
)
WITH (OIDS=TRUE);
ALTER TABLE tr_taxon_tax OWNER TO postgres;
COMMENT ON TABLE tr_taxon_tax IS 'Pour l''instant export de la table taxon existante, 
faudra t''il créer des catégories des taxon ?
la taxons identifes seraient salmonides, anguilles, lamproies, aloses et grands cyprinides deau vives et ombres, truites et brochets';
--Insertion des données Loire-Bretagne (rassemblée dans base Bretagne)
INSERT INTO tr_taxon_tax (tax_code,tax_nom_latin,tax_nom_commun,tax_ntx_code,tax_tax_code,tax_rang)
	SELECT tax_code,tax_nom_latin,tax_nom_commun,tax_ntx_code,tax_tax_code,tax_rang
	FROM Migang_tr_taxon_view;
	
	--Création de la table tr_typepasse_typ

CREATE TABLE tr_typepasse_typ
(
  typ_code integer,
  typ_libelle character varying(60),
  CONSTRAINT c_pk_typ_code PRIMARY KEY (typ_code)
)
WITH (OIDS=FALSE);
ALTER TABLE tr_typepasse_typ OWNER TO postgres;
--Insertion des données 
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (7, 'Ascenseur');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (1, 'Passe bassins sucessifs');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (2, 'Passe ralentisseur');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (3, 'Prebarrage');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (8, 'Echancrure');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (4, 'Riviere artificiel');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (9, 'Echarpe');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (10, 'Passe rustique');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (11, 'Ecluse');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (12, 'Passe piege');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (13, 'Passe orifice noye');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (14, 'Autre');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (15, 'Passe anguille Ascenseur');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (16, 'Tapis brosse');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (17, 'Substrat rugueux');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (18, 'Passe anguille piege');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (19, 'Passe anguille rustique');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (20, 'Autre');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (21, 'Indetermine');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (22, 'Canoe et passe poisson');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (23, 'Ouverture permanente vannage');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (24, 'Ouverture temporaire vannage');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (25, 'Eclusees');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (26, 'Suppression vannage Pertuis libre');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (27, 'Abandon ouvrage Breche Eboulement');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (28, 'Arasement ouvrage vannage');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (29, 'Autre');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (5, 'Rampe à Civelle');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (6, 'Dispositif de dévalaison');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (0, 'Absence');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (-99, 'Sans object');
INSERT INTO tr_typepasse_typ (typ_code, typ_libelle) VALUES (-98, 'A préciser');
	
	--Création de la table tr_typeturbine_typt

CREATE TABLE tr_typeturbine_typt
(
  typt_code integer NOT NULL,
  typt_libelle character varying(40),
  CONSTRAINT c_pk_typt_code PRIMARY KEY (typt_code)
)
WITH (OIDS=FALSE);
ALTER TABLE tr_typeturbine_typt OWNER TO postgres;
--Insertion des données 
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(-99 ,'Sans object');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(-98 ,'A préciser');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(1 ,'Kaplan horizontale et bulbe à pâles');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(10 ,'Autre (à préciser)');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(2 ,'Francis double');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(3 ,'Francis');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(4 ,'Hélice verticale');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(5 ,'Kaplan');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(6 ,'Pelton');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(7 ,'Réversible');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(8 ,'Groupe en S');
INSERT INTO tr_typeturbine_typt (typt_code,typt_libelle) VALUES(9 ,'Hélice horizontale');
	
	--Création de la table t_obstacle_ofr (base Paris)

CREATE TABLE t_obstaclefr_ofr 
(
  ID_final integer NOT NULL,
  ID_base_new integer NOT NULL,
  Code_ouvrage character varying(25),
  Bassin character varying(40),
  Auteur character varying(25),
  Nom_obstacle text,
  X_proj real NOT NULL,
  Y_proj real NOT NULL,
  Type_ text,
  Type_2 text,
  hauteur_chute real,
  cours_eau text,
  commentaire text,
  Id_BDCARTHAGE integer,
  Id_BDCARTHAGE_Noeud_Initial integer,
  Id_BDCARTHAGE_Noeud_Final integer,
  Code_Hydrographique character varying (20),
  Toponyme1 text,
  Code_Entite_Surfacique character varying(20),
  Code_Hydrographique_Cours_Eau  character varying(20),
  PkHg_Point real,
  Dist_Pt_Pro real,
  CONSTRAINT c_pk_ID_final PRIMARY KEY (ID_final)
      ) ;

COPY t_obstaclefr_ofr 
FROM 'C:/temp/t_obstaclefr_ofr.txt'
--FROM 'd:/PostgresDataStore/t_obstaclefr_ofr.txt'
USING DELIMITERS ';'
WITH NULL AS ''
;

delete from t_obstaclefr_ofr  where (t_obstaclefr_ofr.bassin!= 'Loire-Bretagne' and bassin!='Adour-Garonne');


--Etape 5: on crée toutes les autres tables
	
	--Création de t_passe_passe

CREATE TABLE t_passe_passe
(
  passe_code serial NOT NULL,
  passe_ouv_id character varying (7) NOT NULL,
  passe_typ_code integer,
  passe_princ boolean,
  passe_datedebut character varying (20),
  passe_debit_reserve character varying (30),
  passe_datefin date,
  passe_descr character varying(200),

  CONSTRAINT c_pk_passe_code PRIMARY KEY (passe_code),
  CONSTRAINT c_fk_passe_ouv_id FOREIGN KEY (passe_ouv_id)
      REFERENCES t_ouvrage_ouv (ouv_id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT c_fk_typ_code FOREIGN KEY (passe_typ_code)
      REFERENCES tr_typepasse_typ (typ_code) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION
  --CONSTRAINT c_ck_passe_datedebut CHECK (passe_datefin >= passe_datedebut AS date)
)
WITH (OIDS=FALSE);
ALTER TABLE t_passe_passe OWNER TO postgres;

--Insertion données Base Loire
INSERT INTO t_passe_passe (passe_ouv_id,passe_typ_code,passe_princ,passe_datedebut,passe_debit_reserve,passe_descr)
	SELECT id_barrage,id_type_pap_1,TRUE, 
	CASE WHEN annee_pap_1 ~'([0-9]{2})/([0-9]{2})/([0-9]{4})'
		THEN regexp_replace(annee_pap_1,'([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1')
	      WHEN (annee_pap_1 <> '-98' AND annee_pap_1 <> '' AND annee_pap_1 <> '0')
	        THEN annee_pap_1
	      ELSE '1900-01-01' --pour mettre au bon format (pas besoin de faire pareil avec annee_pap_2 ou 3 car pas de pb de format
	 END,
	 q_reservee_dispo_franchissement,dispositif_franchissement
	FROM buffer;

INSERT INTO t_passe_passe (passe_ouv_id,passe_typ_code,passe_princ,passe_datedebut,passe_debit_reserve,passe_descr)
	SELECT id_barrage,id_type_pap_2,FALSE,annee_pap_2,q_reservee_dispo_franchissement,dispositif_franchissement
	FROM buffer;

INSERT INTO t_passe_passe (passe_ouv_id,passe_typ_code,passe_princ,passe_datedebut,passe_debit_reserve,passe_descr)
	SELECT id_barrage,id_type_pap_3,FALSE,annee_pap_3,q_reservee_dispo_franchissement,dispositif_franchissement
	FROM buffer;
	
	--Création de t_info_compl_inc

CREATE TABLE t_info_compl_inc
(
  inc_ouv_id character varying (7),
  inc_ouv_libelle_autre character varying (100),
  inc_dep character varying(3),
  inc_commune_RD character varying (40),
  inc_commune_RG character varying (40),
  inc_z real,
  inc_z_ref character varying (40),
  inc_pK real,
  inc_surface_retenue real,
  inc_volume_retenue character varying(20),
  inc_fondee_titre text,
  inc_priorite text,
  inc_module real,
  inc_cout_total text,
  inc_amenagement_projete text,
  inc_cout_previsionnel text,
  inc_maitrise_ouvrage text,
  CONSTRAINT c_pk_inc_ouv_id PRIMARY KEY (inc_ouv_id),
  CONSTRAINT c_fk_inc_ouv_id_fk FOREIGN KEY (inc_ouv_id)
	REFERENCES t_ouvrage_ouv (ouv_id) MATCH FULL
        ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (OIDS=FALSE);
ALTER TABLE t_ouvrage_ouv OWNER TO postgres;
COMMENT ON TABLE t_info_compl_inc IS 'une table rassemblant toutes les informations complémentaires sur les ouvrages';
COMMENT ON COLUMN t_info_compl_inc.inc_commune_RD IS 'nom de la commune en rive droite';
COMMENT ON COLUMN t_info_compl_inc.inc_commune_RG IS 'nom de la commune en rive gauche';
COMMENT ON COLUMN t_info_compl_inc.inc_z IS 'altitude du seuil de crête';
COMMENT ON COLUMN t_info_compl_inc.inc_z_ref IS 'système dans lequel l''altitude du seuil z est rentrée';
COMMENT ON COLUMN t_info_compl_inc.inc_priorite IS 'repérage des obstacles majeurs pour la définition des priorités d''intervention';

--Insertion des données de la base Loire (pas de données Bretagne)
INSERT INTO t_info_compl_inc (inc_ouv_id,inc_ouv_libelle_autre,inc_dep,inc_commune_RD,inc_commune_RG,inc_z,inc_z_ref,inc_pK,inc_surface_retenue,inc_volume_retenue,inc_fondee_titre,inc_priorite,inc_module,inc_cout_total,inc_amenagement_projete,inc_cout_previsionnel,inc_maitrise_ouvrage)
	SELECT id_barrage,autre_nom,dep,commune_rd,commune_rg,z_cote,z_ref,pk,surface_retenue,volume_retenue,
	CASE WHEN id_fondee_en_titre = 0 THEN 'non'
	     WHEN id_fondee_en_titre =1 THEN 'oui'
	     ELSE ' '
	END,
	CASE WHEN priorite = 1 THEN 'Obstacle majeur présentant un impact significatif à l''échelle du bassin entier (COGEPOMI Loire)'
	     WHEN priorite = 2 THEN 'Obstacle majeur présentant un impact significatif à l''échelle d''un axe prioritaire'
	     ELSE ' '
	END,
	module,cout_total_franchissement,amenagement_projete,cout_previsionnel,maitre_ouvrage
	FROM buffer;

	--Création de tj_natureouvrage_nao
CREATE TABLE tj_natureouvrage_nao
(
  nao_id SERIAL NOT NULL,
  nao_nov_code integer,
  nao_ouv_id character varying (7) NOT NULL,
  nao_princ boolean,
  nao_commentaire text,
  nao_datedebut character varying (20) DEFAULT '1900-01-01',
  nao_datefin date,
  nao_longueur_fixe character varying (20),
  nao_longueur_mobile character varying (20),
  CONSTRAINT c_pk_nao_nao_id PRIMARY KEY (nao_id),
  CONSTRAINT c_fk_nao_nov_code FOREIGN KEY (nao_nov_code)
      REFERENCES tr_nature_nov (nov_code) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT c_fk_nao_ouv_id FOREIGN KEY (nao_ouv_id)
      REFERENCES t_ouvrage_ouv (ouv_id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION
  --CONSTRAINT c_ck_nao_datefin CHECK (nao_datefin > nao_datedebut)
)
WITH (OIDS=FALSE);
ALTER TABLE tj_natureouvrage_nao OWNER TO postgres;


--Insertion des données Loire
INSERT INTO tj_natureouvrage_nao (nao_nov_code,nao_ouv_id,nao_princ,nao_commentaire,nao_datedebut,nao_longueur_fixe,nao_longueur_mobile)
	SELECT id_type_princ_1,id_barrage,TRUE,type1_autre,date_construction,lg_fixe,lg_mobile
	FROM buffer;

INSERT INTO tj_natureouvrage_nao (nao_nov_code,nao_ouv_id,nao_princ,nao_commentaire,nao_datedebut,nao_longueur_fixe,nao_longueur_mobile)
	SELECT id_type_compl_2,id_barrage,FALSE,'',date_construction,lg_fixe,lg_mobile
	FROM buffer;

INSERT INTO tj_natureouvrage_nao (nao_nov_code,nao_ouv_id,nao_princ, nao_commentaire,nao_datedebut,nao_longueur_fixe,nao_longueur_mobile)
	SELECT id_type_compl_3,id_barrage,FALSE,'',date_construction,lg_fixe,lg_mobile
	FROM buffer;

INSERT INTO tj_natureouvrage_nao (nao_nov_code,nao_ouv_id,nao_princ,nao_commentaire,nao_datedebut,nao_longueur_fixe,nao_longueur_mobile)
	SELECT 
	CASE WHEN effacement=1 THEN 12
	     WHEN effacement=2 THEN 13
	     WHEN effacement=3 THEN 14
	     WHEN effacement=9 THEN 33
	END,
	id_barrage,FALSE,'',date_construction,lg_fixe,lg_mobile
	FROM buffer;

INSERT INTO tj_natureouvrage_nao (nao_nov_code,nao_ouv_id,nao_princ,nao_commentaire,nao_datedebut,nao_longueur_fixe,nao_longueur_mobile)
	SELECT 
	CASE WHEN id_derivation = 1 THEN 16
	END,
	id_barrage,FALSE,'',date_construction,lg_fixe,lg_mobile
	FROM buffer;

INSERT INTO tj_natureouvrage_nao (nao_nov_code,nao_ouv_id,nao_princ, nao_commentaire,nao_datedebut,nao_longueur_fixe,nao_longueur_mobile)
	SELECT 
	CASE WHEN id_ancien_moulin = 1 THEN 17
	END,	
	id_barrage,FALSE,'',date_construction,lg_fixe,lg_mobile
	FROM buffer;
	
	--Création de tj_ouvrageusage_ouu

CREATE TABLE tj_ouvrageusage_ouu
(
  ouu_code serial,
  ouu_ouv_id character varying(7) NOT NULL,
  ouu_us_code integer,
  ouu_us_code_desc text,
  ouu_us_autre integer,
  ouu_us_autre_desc text,
  ouu_datedebut date NOT NULL,
  ouu_datefin date,
  CONSTRAINT c_pk_ouu PRIMARY KEY (ouu_code),
  CONSTRAINT c_ck_ouu_datefin CHECK (ouu_datefin > ouu_datedebut)
)
WITH (OIDS=FALSE);
ALTER TABLE tj_ouvrageusage_ouu OWNER TO postgres;

--Insertion des données Loire
INSERT INTO tj_ouvrageusage_ouu (ouu_ouv_id,ouu_us_code,ouu_us_code_desc,ouu_us_autre,ouu_us_autre_desc,ouu_datedebut,ouu_datefin)
	SELECT  id_barrage,id_usage_1,id_autre_usage_1,id_usage_2,id_autre_usage_2,'1900-01-01',null
	FROM buffer;
	--Insertion ancienne pêcherie
INSERT INTO tj_ouvrageusage_ouu (ouu_ouv_id,ouu_us_code,ouu_us_code_desc,ouu_us_autre,ouu_us_autre_desc,ouu_datedebut,ouu_datefin)
	SELECT  id_barrage,
	CASE WHEN anc_pecherie_avalaison=1 THEN 27
	     WHEN anc_pecherie_avalaison=5 THEN 9999
	END,
	'',null,'','1900-01-01',null
	FROM buffer;

	--Création de t_denivele_den

CREATE TABLE t_denivele_den
(
  den_id serial NOT NULL,
  den_ouv_id character varying(7) NOT NULL,
  den_date date,
  den_denivele character varying (20),
  den_debit real,
  CONSTRAINT c_pk_den_id PRIMARY KEY (den_id),
  CONSTRAINT c_fk_den_ouv_id FOREIGN KEY (den_ouv_id)
      REFERENCES t_ouvrage_ouv (ouv_id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (OIDS=FALSE);
ALTER TABLE t_denivele_den OWNER TO postgres;
COMMENT ON TABLE t_denivele_den IS 'Mesure du denivele de l''ouvrage';
COMMENT ON COLUMN t_denivele_den.den_denivele IS 'chute mesurée à l''étiage';

--Insertion base Loire
INSERT INTO t_denivele_den (den_ouv_id, den_date, den_denivele, den_debit)
	SELECT id_barrage, null, chute_etiage, 0
	FROM buffer;

	--Création de tj_espececible_esp

CREATE TABLE tj_espececible_esp
(
  esp_tax_code character varying NOT NULL,
  esp_passe_code integer NOT NULL,
  CONSTRAINT c_pk_esp PRIMARY KEY (esp_tax_code,esp_passe_code),
  CONSTRAINT c_fk_esp_passe_code FOREIGN KEY (esp_passe_code)
    REFERENCES t_passe_passe (passe_code) MATCH FULL
    ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT c_fk_esp_tax_code FOREIGN KEY (esp_tax_code)
     REFERENCES tr_taxon_tax (tax_code) MATCH FULL
     ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (OIDS=FALSE);
ALTER TABLE tj_espececible_esp OWNER TO postgres;

--Pas de données sur les espèces cibles des passes en Loire-Bretagne

	--Création de t_franchisbar_fba

CREATE TABLE t_franchisbar_fba
(
fba_id SERIAL,
fba_ouv_id character varying (7) NOT NULL,
fba_tax_code character varying (6) not null,
fba_valeurnote character varying (40),
fba_tyn_typenote character varying (20),
fba_iconf_indiceconfiance real,
fba_observateur text,
fba_datedebut character varying (20) DEFAULT '1900-01-01',
fba_datefin date,
fba_commentaire text,
 CONSTRAINT c_pk_fba_id_pk PRIMARY KEY (fba_id),
 CONSTRAINT c_fk_fba_ouv_id FOREIGN KEY (fba_ouv_id)
      REFERENCES t_ouvrage_ouv (ouv_id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT c_fk_fba_tax_code FOREIGN KEY (fba_tax_code)
      REFERENCES tr_taxon_tax (tax_code) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT c_fk_fba_tyn_typenote FOREIGN KEY (fba_tyn_typenote)
      REFERENCES tr_typenote_tyn (tyn_typenote) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT c_uk_fba_ouv_pk1 UNIQUE (fba_ouv_id, fba_tax_code, fba_tyn_typenote)
 )
WITH (OIDS=FALSE);
ALTER TABLE t_franchisbar_fba OWNER TO postgres;
COMMENT ON TABLE t_franchisbar_fba IS 'Table d''expertise de franchissement.
Il ne peut y avoir qu''une seule expertise de franchissement pour une caractéristique d''ouvrage (sur une période) et une espèce .
';
COMMENT ON COLUMN t_franchisbar_fba.fba_tax_code IS 'code sandre du taxon hérité de la table taxon';
COMMENT ON COLUMN t_franchisbar_fba.fba_valeurnote IS 'Note moyenne de franchissement, ce champ pourra être calcule par la suite (ex note anguille)';
COMMENT ON COLUMN t_franchisbar_fba.fba_datedebut IS 'Date de la dernière expertise de franchissement, il ne peut y avoir qu''une expertise pour une caracteristique d''ouvrage donnee';

--Insertion base Loire
  --Note franchissabilité pour l'anguille
INSERT INTO  t_franchisbar_fba (fba_ouv_id, fba_tax_code, fba_valeurnote, fba_tyn_typenote , fba_iconf_indiceconfiance, fba_observateur, fba_datedebut, fba_datefin, fba_commentaire)
    SELECT B.id_barrage, '2038', B.ang,'EXPERTISE' , ind_confiance, observateur, 
    CASE WHEN dt_derniere_visite ~ '([0-9]{2})/([0-9]{2})/([0-9]{4})' --dans le cas où la date est mal formatée
	THEN regexp_replace(dt_derniere_visite, '([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1') --la remplacer par la forme de date standard
    WHEN (dt_derniere_visite <> '-98' AND dt_derniere_visite <> '' AND dt_derniere_visite <> '0') --ne pas afficher quand il n'y a pas de date rentré
	THEN dt_derniere_visite
    ELSE '1900-01-01'
    END,
    null, ''
	FROM buffer AS B
	WHERE B.ang IS NOT NULL AND ang >= 0;
  --Note franchissabilité pour l'alose
INSERT INTO  t_franchisbar_fba (fba_ouv_id, fba_tax_code, fba_valeurnote, fba_tyn_typenote , fba_iconf_indiceconfiance, fba_observateur, fba_datedebut, fba_datefin, fba_commentaire)
 SELECT B.id_barrage, '2055', B.ala, 'EXPERTISE', ind_confiance, observateur, 
    CASE WHEN dt_derniere_visite ~ '([0-9]{2})/([0-9]{2})/([0-9]{4})'
	THEN regexp_replace(dt_derniere_visite, '([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1')
    WHEN (dt_derniere_visite <> '-98' AND dt_derniere_visite <> '' AND dt_derniere_visite <> '0') 
	THEN dt_derniere_visite
    ELSE '1900-01-01'
    END,
    null, ''
    	FROM buffer AS B
	WHERE B.ala IS NOT NULL AND ala >= 0;
  --Note franchissabilité pour la lamproie
INSERT INTO  t_franchisbar_fba (fba_ouv_id, fba_tax_code, fba_valeurnote, fba_tyn_typenote , fba_iconf_indiceconfiance, fba_observateur, fba_datedebut, fba_datefin, fba_commentaire)
 SELECT B.id_barrage, '2014', B.lpm, 'EXPERTISE', ind_confiance, observateur, 
    CASE WHEN dt_derniere_visite ~ '([0-9]{2})/([0-9]{2})/([0-9]{4})'
	THEN regexp_replace(dt_derniere_visite, '([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1')
    WHEN (dt_derniere_visite <> '-98' AND dt_derniere_visite <> '' AND dt_derniere_visite <> '0') 
	THEN dt_derniere_visite
    ELSE '1900-01-01'
    END,
    null, ''
    	FROM buffer AS B
	WHERE B.lpm IS NOT NULL AND lpm >= 0;
  --Note franchissabilité pour le saumon
INSERT INTO  t_franchisbar_fba (fba_ouv_id, fba_tax_code, fba_valeurnote, fba_tyn_typenote , fba_iconf_indiceconfiance, fba_observateur, fba_datedebut, fba_datefin, fba_commentaire)
 SELECT B.id_barrage, '2219', B.sat, 'EXPERTISE', ind_confiance, observateur, 
    CASE WHEN dt_derniere_visite ~ '([0-9]{2})/([0-9]{2})/([0-9]{4})'
	THEN regexp_replace(dt_derniere_visite, '([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1')
    WHEN (dt_derniere_visite <> '-98' AND dt_derniere_visite <> '' AND dt_derniere_visite <> '0') 
	THEN dt_derniere_visite
    ELSE '1900-01-01'
    END,
    null, ''
    	FROM buffer AS B
	WHERE B.sat IS NOT NULL AND sat >= 0;
  --Note franchissabilité pour la truite de rivière
INSERT INTO  t_franchisbar_fba (fba_ouv_id, fba_tax_code, fba_valeurnote, fba_tyn_typenote , fba_iconf_indiceconfiance, fba_observateur, fba_datedebut, fba_datefin, fba_commentaire)
 SELECT B.id_barrage, '2221', B.trf, 'EXPERTISE', ind_confiance, observateur, 
    CASE WHEN dt_derniere_visite ~ '([0-9]{2})/([0-9]{2})/([0-9]{4})'
	THEN regexp_replace(dt_derniere_visite, '([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1')
    WHEN (dt_derniere_visite <> '-98' AND dt_derniere_visite <> '' AND dt_derniere_visite <> '0') 
	THEN dt_derniere_visite
    ELSE '1900-01-01'
    END,
    null, ''
    	FROM buffer AS B
	WHERE B.trf IS NOT NULL AND trf >= 0;
  
  --Pour ajouter les fba_valeurnote 'mortalité dévalaison' (je n'intègre pas les -98) 
  --Pour l'anguille
INSERT INTO  t_franchisbar_fba (fba_ouv_id, fba_tax_code, fba_valeurnote, fba_tyn_typenote , fba_iconf_indiceconfiance, fba_observateur, fba_datedebut, fba_datefin, fba_commentaire)
    SELECT B.id_barrage, '2038', mortalite_devalaison_ANG, 'MORTALITE DEVALAISON' , ind_confiance, observateur, 
    CASE WHEN dt_derniere_visite ~ '([0-9]{2})/([0-9]{2})/([0-9]{4})'
	THEN regexp_replace(dt_derniere_visite, '([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1')
    WHEN (dt_derniere_visite <> '-98' AND dt_derniere_visite <> '' AND dt_derniere_visite <> '0') 
	THEN dt_derniere_visite
    ELSE '1900-01-01'
    END,
    null, ''
	FROM buffer AS B
	WHERE B.mortalite_devalaison_ANG IS NOT NULL AND mortalite_devalaison_ANG <> '-98';
  --Pour le saumon
INSERT INTO  t_franchisbar_fba (fba_ouv_id, fba_tax_code, fba_valeurnote, fba_tyn_typenote , fba_iconf_indiceconfiance, fba_observateur, fba_datedebut, fba_datefin, fba_commentaire)
    SELECT B.id_barrage, '2219', mortalite_devalaison_SAT, 'MORTALITE DEVALAISON' , ind_confiance, observateur, 
    CASE WHEN dt_derniere_visite ~ '([0-9]{2})/([0-9]{2})/([0-9]{4})'
	THEN regexp_replace(dt_derniere_visite, '([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1')
    WHEN (dt_derniere_visite <> '-98' AND dt_derniere_visite <> '' AND dt_derniere_visite <> '0') 
	THEN dt_derniere_visite
    ELSE '1900-01-01'
    END,
    null, ''
	FROM buffer AS B
	WHERE B.mortalite_devalaison_SAT IS NOT NULL AND mortalite_devalaison_SAT <> '-98';

	
	--Création de t_devalaison_deval

CREATE TABLE t_devalaison_deval
(
  deval_code serial NOT NULL,
  deval_ouv_id character varying (7) NOT NULL,
  deval_existdeval boolean,
  deval_hauteur real,
  deval_grilles_espacement character varying (50),
  deval_ecartement integer,
  deval_vitesse integer,
  CONSTRAINT c_pk_deval_code PRIMARY KEY (deval_code),
  CONSTRAINT c_fk_deval_ouv_id FOREIGN KEY (deval_ouv_id)
      REFERENCES t_ouvrage_ouv (ouv_id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (OIDS=FALSE);
ALTER TABLE t_devalaison_deval OWNER TO postgres;
COMMENT ON COLUMN t_devalaison_deval.deval_hauteur IS 'chute exploitée';
--Insertion données Loire 
INSERT INTO t_devalaison_deval (deval_ouv_id,deval_hauteur,deval_grilles_espacement)
	SELECT id_barrage,chute_exploitee,
	CASE WHEN espacement_grille = '-98' THEN null
	     ELSE espacement_grille
	     END
	FROM buffer;

	--Création de t_turbine_turb
drop table if exists t_turbine_turb;
CREATE TABLE t_turbine_turb
(
  turb_code serial NOT NULL,
  turb_ouv_id character varying (7) NOT NULL,
  turb_typeturbine integer,
  turb_datecreation character varying (40),
  turb_echeance character varying (40),
  turb_datesuppression date,
  turb_principale boolean,
  turb_descr character varying(200),
  turb_enservice character varying (20), --A mettre en boolean quand règlera pb sur base Pierre
  turb_puissance character varying (30),
  turb_nb_turbines real,
  turb_diametre character varying (40),
  turb_debit real,
  turb_vitesse_rotation character varying (40),
  turb_nbpales character varying (40),
  turb_debitamenagement integer,
  CONSTRAINT c_pk_turb_code PRIMARY KEY (turb_code),
  CONSTRAINT c_fk_turb_ouv_id FOREIGN KEY (turb_ouv_id)
      REFERENCES t_ouvrage_ouv (ouv_id) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT c_fk_turb_typeturbine FOREIGN KEY (turb_typeturbine)
      REFERENCES tr_typeturbine_typt (typt_code) MATCH FULL
      ON UPDATE NO ACTION ON DELETE NO ACTION
  --CONSTRAINT c_ck_turb_datesupression CHECK (turb_datesuppression > turb_datecreation) pb datecreation pas en format date
)
WITH (OIDS=FALSE);
ALTER TABLE t_turbine_turb OWNER TO postgres;
COMMENT ON COLUMN t_turbine_turb.turb_diametre IS 'diamètre de la roue';
COMMENT ON COLUMN t_turbine_turb.turb_debit IS 'débit turbiné';

--Insertion données Loire 
INSERT INTO t_turbine_turb (turb_ouv_id, turb_typeturbine,turb_datecreation,turb_echeance,turb_principale,turb_descr,turb_enservice,turb_puissance,turb_nb_turbines,turb_diametre,turb_debit,turb_vitesse_rotation,turb_nbpales)
	SELECT id_barrage, 
	  CASE WHEN (type_turbine = '0' OR type_turbine = '99') THEN -99    -- On part du principe que si c'est '0', c'est qu'il n'y a pas de turbine. A CONFIRMER
               ELSE type_turbine
          END,
	  CASE WHEN date_arrete~ '([0-9]{2})/([0-9]{2})/([0-9]{4})'
	        THEN regexp_replace(dt_derniere_visite, '([0-9]{2})/([0-9]{2})/([0-9]{4})', E'\\3-\\2-\\1')
               WHEN (dt_derniere_visite <> '-98' AND dt_derniere_visite <> '' AND dt_derniere_visite <> '0') 
	        THEN dt_derniere_visite
               ELSE '1900-01-01'
          END,
          CASE WHEN date_echeance ~ '([0-9]{2})/([0-9]{2})/([0-9]{4})'
                THEN regexp_replace (date_echeance,'([0-9]{2})/([0-9]{2})/([0-9]{4})',E'\\3-\\2-\\1')
               WHEN (date_echeance <> '-98' AND date_echeance <> '' AND date_echeance <> '0')
		THEN date_echeance
	       ELSE '1900-01-01'
	  END,
	  CASE WHEN (type_turbine <> -99 AND type_turbine <> 99 AND type_turbine <> 0 AND type_turbine <> -98)
	        THEN TRUE	
	        ELSE FALSE
	  END,
	  intitule_carac_turbine,id_turbine_activite,puissance_equipement,nb_turbines,diametre_roue,q_equipement, vitesse_rotation,nb_pales
	FROM buffer;

-- Création de la fonction trigger permettant de détecter si une turbine n'existe pas déjà lors de l'ajout d'une ligne

CREATE OR REPLACE FUNCTION trig_turb_princ()RETURNS TRIGGER AS $trig_turb_princ$
DECLARE nb_turb_princ INTEGER;
BEGIN
 SELECT * FROM t_turbine_turb
  WHERE turb_ouv_id=new
  AND (turb_ouv_id AND turb_code)=new
  AND (turb_code AND turb_principale)=TRUE;
 SELECT COUNT (*) into nb_turb_princ FROM t_turbine_turb
  WHERE turb_ouv_id=new
  AND (turb_ouv_id AND turb_code)=new
  AND (turb_code AND turb_principale)=TRUE;
 IF (nb_turb_princ>1) THEN RAISE EXCEPTION 'il ne peut y avoir qu''une seule turbine principale';
 END IF;
 RETURN NEW;
 END;
$trig_turb_princ$
 LANGUAGE 'plpgsql' VOLATILE;
ALTER FUNCTION trig_turb_princ()OWNER TO POSTGRES;

--Etape 6 : Création des vues
	--Création v_ouv_den

CREATE OR REPLACE VIEW v_ouv_den AS 
 SELECT t_ouvrage_ouv.ouv_id, t_ouvrage_ouv.ouv_ouv_id, t_ouvrage_ouv.ouv_baraval, t_ouvrage_ouv.ouv_codegenerique, t_ouvrage_ouv.ouv_distancesource, t_ouvrage_ouv.ouv_distancemer, t_ouvrage_ouv.ouv_distancemareedyn, t_ouvrage_ouv.ouv_sbv, t_ouvrage_ouv.ouv_bassin, t_ouvrage_ouv.ouv_rinom, t_ouvrage_ouv.ouv_abscisse, t_ouvrage_ouv.ouv_ordonnee, t_ouvrage_ouv.ouv_libelle, t_ouvrage_ouv.ouv_commentaires, t_denivele_den.den_id, t_denivele_den.den_ouv_id, t_denivele_den.den_date, t_denivele_den.den_denivele, t_denivele_den.den_debit
   FROM t_ouvrage_ouv
   JOIN t_denivele_den ON t_ouvrage_ouv.ouv_id::text = t_denivele_den.den_ouv_id::text;

ALTER TABLE v_ouv_den OWNER TO postgres;

	--Création v_ouv_fba

CREATE OR REPLACE VIEW v_ouv_fba AS 
 SELECT t_ouvrage_ouv.ouv_id, t_ouvrage_ouv.ouv_ouv_id, t_ouvrage_ouv.ouv_baraval, t_ouvrage_ouv.ouv_codegenerique, t_ouvrage_ouv.ouv_distancesource, t_ouvrage_ouv.ouv_distancemer, t_ouvrage_ouv.ouv_distancemareedyn, t_ouvrage_ouv.ouv_sbv, t_ouvrage_ouv.ouv_bassin, t_ouvrage_ouv.ouv_rinom, t_ouvrage_ouv.ouv_abscisse, t_ouvrage_ouv.ouv_ordonnee, t_ouvrage_ouv.ouv_libelle, t_ouvrage_ouv.ouv_commentaires, t_franchisbar_fba.fba_id, t_franchisbar_fba.fba_ouv_id, t_franchisbar_fba.fba_tax_code, t_franchisbar_fba.fba_valeurnote, t_franchisbar_fba.fba_tyn_typenote, t_franchisbar_fba.fba_datedebut, t_franchisbar_fba.fba_datefin, t_franchisbar_fba.fba_commentaire
   FROM t_ouvrage_ouv
   JOIN t_franchisbar_fba ON t_ouvrage_ouv.ouv_id::text = t_franchisbar_fba.fba_ouv_id::text
  WHERE t_franchisbar_fba.fba_tax_code::text = '2038'::text;

ALTER TABLE v_ouv_fba OWNER TO postgres;

 	
	--Création v_ouv_nao 

CREATE OR REPLACE VIEW v_ouv_nao AS 
 SELECT t_ouvrage_ouv.ouv_id, t_ouvrage_ouv.ouv_ouv_id, t_ouvrage_ouv.ouv_baraval, t_ouvrage_ouv.ouv_codegenerique, t_ouvrage_ouv.ouv_distancesource, t_ouvrage_ouv.ouv_distancemer, t_ouvrage_ouv.ouv_distancemareedyn, t_ouvrage_ouv.ouv_sbv, t_ouvrage_ouv.ouv_bassin, t_ouvrage_ouv.ouv_rinom, t_ouvrage_ouv.ouv_abscisse, t_ouvrage_ouv.ouv_ordonnee, t_ouvrage_ouv.ouv_libelle, t_ouvrage_ouv.ouv_commentaires, tj_natureouvrage_nao.nao_id, tj_natureouvrage_nao.nao_nov_code, tj_natureouvrage_nao.nao_ouv_id, tj_natureouvrage_nao.nao_datedebut, tj_natureouvrage_nao.nao_datefin
   FROM t_ouvrage_ouv
   JOIN tj_natureouvrage_nao ON t_ouvrage_ouv.ouv_id::text = tj_natureouvrage_nao.nao_ouv_id::text;

ALTER TABLE v_ouv_nao OWNER TO postgres;

	--Création v_ouv_passe

CREATE OR REPLACE VIEW v_ouv_passe AS 
 SELECT temptable.ouv_abscisse, temptable.ouv_ordonnee, temptable.passe_code, temptable.passe_ouv_id, temptable.passe_typ_code, temptable.passe_datedebut, temptable.passe_datefin, temptable.passe_descr, temptable.typ_code, temptable.typ_libelle, temptable.fba_id, temptable.fba_ouv_id, temptable.fba_tax_code, temptable.fba_valeurnote AS integer, temptable.fba_tyn_typenote
   FROM ( SELECT ouv.ouv_abscisse, ouv.ouv_ordonnee, passe.passe_code, passe.passe_ouv_id, passe.passe_typ_code, passe.passe_datedebut, passe.passe_datefin, passe.passe_descr, typ.typ_code, typ.typ_libelle, t_franchisbar_fba.fba_id, t_franchisbar_fba.fba_ouv_id, t_franchisbar_fba.fba_tax_code, t_franchisbar_fba.fba_valeurnote, t_franchisbar_fba.fba_tyn_typenote
           FROM t_ouvrage_ouv ouv
      JOIN t_passe_passe passe ON ouv.ouv_id::text = passe.passe_ouv_id::text
   JOIN tr_typepasse_typ typ ON passe.passe_typ_code::text = typ.typ_code::text
   LEFT JOIN t_franchisbar_fba ON t_franchisbar_fba.fba_ouv_id::text = ouv.ouv_id::text
  WHERE t_franchisbar_fba.fba_tyn_typenote::text = 'EXPERTISE'::text) temptable;
  --WHERE CAST (temptable.fba_valeurnote AS integer) < 3::double precision;

ALTER TABLE v_ouv_passe OWNER TO postgres;

--Tout à la fin fermeture de la connexion 

select* from dblink_disconnect('base=Migang');
select* from dblink_disconnect('base=BASE Pierre');

-- vire les fonctions

--DROP FUNCTION dblink_connect (text, text);
--DROP FUNCTION dblink_connect (text);
--DROP FUNCTION dblink(text,text);
--DROP FUNCTION dblink_disconnect();
