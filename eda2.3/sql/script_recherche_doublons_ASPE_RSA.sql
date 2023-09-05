/* Un doublon = 
- opération de pêche : même date, même lieu, même quantité pêchée 
- poisson même date, même lieu, même poids, même taille*/

-- Etape 1 : Peut on trouver des stations communes entre RSA et ASPE ? (A faire sous R)
-- Faire une table qui fait le lien entre les stations de RSA et ASPE qui se trouvent à moins de 10km (distance à adapter selon les besoins)
-- on travaille sur dbeel_station_aspe et dbeel_station_rsa
-- structure req résutlat (liste des champs) :
-- source : ASPE
-- src_nom : nom de la station ASPE de la source
-- cible : RSA
-- cbl_nom : nom de la station RSA
-- cbl_geom : coordonnées en 3035 de la cible
-- distance entre la source et la cible

-- Etape 2 : Chercher l'ensemble des opérations de pêches réalisées 
-- conjointement sur des couples de stations de l'étape 1 à 2/3j 
-- d'intervalle (au cas où la date de l 'opération ne soit pas très précise)

-- Etape 3 : Comparer les quantités de poissons pêchées et les méthodes utilisées
-- Remonter la liste des couples d'opérations de pêches de l'étape 2
-- dont les quantités pêchées sont égales

-- Etape 4 : Chercher l'ensemble des poissons de même tailles et/ou poids
-- issus d'une pêche le même jour et dans un couple de station existant à l'étape 1
-- NB : beaucoup de poids sont NULL, à ignorer ?