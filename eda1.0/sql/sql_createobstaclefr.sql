DROP TABLE t_obstaclefr_ofr;

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

delete from t_obstaclefr_ofr  where (t_obstaclefr_ofr.bassin!= 'Loire-Bretagne' 
and bassin!='Adour-Garonne')





