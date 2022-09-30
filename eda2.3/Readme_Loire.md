# La base de données dbeel

Les données de pêche électriques utilisées par EDA sont stockées dans la
base de données dbeel. La base a été créée dans le cadre du projet POSE.


La base de données est organisée sous forme de schémas. De nombreux
schémas [héritent](https://docs.postgresql.fr/9.6/ddl-inherit.html)
d'un schéma père. Ainsi, tous les schémas "géographiques" (e.g.
france) héritent du schéma dbeel. Donc toutes les données saisies dans
un schéma fils seront rapatriées dans le schéma père lors des requêtes
sur ce dernier. Cela permet de conserver des champs supplémentaires dans
les schémas fils qui ne seront pas présents dans le schéma père.

Les évolutions dans sudoang du schema dbeel sont dans le [script](https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/sql/update_schema_dbeel.sql)


# Mise à jour des données

Les données de pêche électriques sont stockées dans la base de données
sql dbeel développée par l'OFB. Cette base doit être installée sur un
serveur en local.

Afin d'être en mesure de réaliser annuellement les mises à jour des
scripts dédiés ont été développés par C. Briand, D. Lafage et C.
Boulenger sur le gitlab de l'OFB. Les données à importer sont principalement
copiées dans le dossier local EDA_data ou dans le dossier d'import d'EDA.

# Principe d'import

L'import de données se fait en 3 grandes phases:

 - Préparation de 3 jeux distincts (généralement sous R):
   - une table "stations": description des lieux de pêche)
   - une table "opérations" : une pêche électrique 1 jour à une station (la table comprend notamment le nombre d'anguilles total et par passage)
   - une table de données biométrique
 - Écriture des données dans la base (sous R grâce à {DBI} dans le schéma France (qui hérite du schéma dbeel)
 - Création et import des tables correspondantes en SQL (elles auront toutes le préfix "dbeel_"), elles héritent de la table de base crée dans la dbeel.



 - Les données de nombre d'anguilles total et par passage sont stockées en format long : une colonne (`ba_no_biological_characteristic_type`) indique de quelle variable on parle (Number, Number p1...) et une colonne (ba_quantity) indique la valeur associée. Ces données dans leur ensemble constituent un "batch" de niveau 1.
 -  Les données de biométrie sont, elles aussi, stockées en format long : une colonne (`bc_no_characteristic_type`) indique de quelle variable on parle (longueur, poids...) et une colonne (bc_numvalue) indique la valeur associée. Ces données dans leur ensemble constituent un "batch" de niveau 2.


   - la table station est importée dans `france.dbeel_station_source` (remplacer source par ASPE ou autre)
   - la table opération est importée
     - dans `france.dbeel_electrofishing_source` pour ce qui concerne la description de l'opération en elle-même
     - dans `france.dbeel_batch_ope_source` pour le nombre total et le nombre par passage.
   - la table de biométrie nécessite plusieurs étapes :
     - on référence chaque poisson (1 import par passage) dans `france.batch_fish_source`
     - on importe les données biométriques correspondantes dans `france.dbeel_mensurationindiv_biol_charac_source` (1 import par type (longueur, poids...) et par passage)

# Détail de l'import par source 

## ASPE

L'intégralité de la base de données ASPE nous a été transmise par l'OFB [Pascal Irz](pascal.irz@ofb.gouv.fr). On pourra se reporter au [github](https://github.com/PascalIrz/aspe) de Pascal Irz pour disposer de tutoriels permettant de mieux comprendre la structure de la base et d'utiliser le package R dédié.

Les deux fichiers Rdata sont stockés dans EDA_data/Loire


L'import se déroule en deux phases:

  - tout d'abord un [script R](https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/R/aspe_import.R) permet de préparer les données et de les copier dans la base dbeel
  - dans un second temps, un [script SQL](https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/sql/import_aspe_dbeel.sql) permet d'intégrer les données dans les différentes tables de la base.

## Données FD

Un appel à données a été réalisé auprès des fédérations de pêches du
bassin de la Loire. Des données ont été transmises par les FD 36, 37,
43, 44, 45, 49, 72, 86 ainsi que l'EP Loire. L'extrême hétérogénéité
des informations et formats de données disponibles nous a amené à
centraliser les données dans un template minimal. Les données transmises
sont centralisées dans EDA_data/Loire.

## FD37

Les données fournies par la FD37 constituent un cas particulier puisque
c'est l'ensemble de la base de données WAMA qui nous a été transmis
(sans les noms d'utilisateurs et mot de passe !!). Un [script
spécifique](https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/R/Import_donnees_WAMA.R)
a été développé pour permettre l'intégration de ces données.

# Import

L'import se déroule en deux phases:

  - Après avoir préparé les données de la FD37 grâce au [script dédié](https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/R/Import_donnees_WAMA.R), un [ second script R](https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/R/FDLoire_import.R) permet de préparer les données et de les copier dans la base dbeel
  - dans un second temps, un [script SQL](https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/sql/import_FDLoire_dbeel.sql) permet d'intégrer les données dans les différentes tables de la base.

# Données RSA
L'OFB maintient une base de donnée avec les suivis anguilles sur les rivières index et les réseaux externes (dont celui de LOGRAMI). Un
export a été transmis par C. Boulenger et est stocké dans "D:\eda\data\eda2.3\RSA" (chez Cédric).

Après avoir restauré le schéma de cette base sur le serveur local (dans la dbeel), un [script SQL](https://forgemia.inra.fr/pole-migrateurs/eda/dbeel/-/blob/develop/eda2.3/sql/import_rsa_dbeel.sql) permet l'import des données.

## A faire

* [ ] refaire tourner  ASPE #8
* [ ] dédoublonner les données ASPE et logrami #4
* [ ] dans ASPE ré-échantillonner #5 
* [ ] integrer les paramètres d'argenture historique en faisant un lien et renvoyer table au niveau national #6
* [ ] Importer les données RSA logrami #9
_ note : les nombres totaux d'anguille correspondent aux anguilles vues et capturées._
* [ ] Refaire tourner les scripts ouvrages pour import dbeel et génération des Rdata #12
* [ ] Refaire tourner EDA2.3 avec les nouvelles données eda_model#12
* [ ] Refaire tourner le modèle seulement sur la Loire eda_model#13
