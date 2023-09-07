/* Un doublon = 
- opération de pêche : même date, même lieu, même quantité pêchée 
- poisson même date, même lieu, même poids, même taille*/
/* Attention : il peut y avoir parfois des opérations de pêches qui ont donné lieu a 1 saisie dans RSA puis dans ASPE mais sur des données différentes
Théoriquement dans ASPE, il n'y a que de l'OFB et dans RSA ce sont d'autres partenaires
*/

-- Etape 1 : Peut on trouver des stations communes entre RSA et ASPE ? (A faire sous R)
-- Faire une table qui fait le lien entre les stations de RSA et ASPE qui se trouvent à moins de 200m (distance à adapter selon les besoins)---
-- cf fichier check_dup_stations_ASPE_RSA.R
-- résultats dans france.stations_dup_aspe_rsa

-- Etape 2 : Chercher l'ensemble des opérations de pêches réalisées 
-- conjointement sur des couples de stations de l'étape 1 à 2/3j 
-- d'intervalle (au cas où la date de l 'opération ne soit pas très précise)

-- opérations de pêches réalisées sur ces stations ASPE
select dea.ob_starting_date, dea.ope_id ,dboa.ba_quantity  from dbeel_electrofishing_aspe dea 
join stations_dup_aspe_rsa sdar on sdar.aspe_sta_id = dea.sta_id 
join dbeel_batch_ope_aspe dboa on dboa.ope_id = dea.ope_id
order by dea.ob_starting_date, dea.ope_id 

-- Etape 3 : Comparer les quantités de poissons pêchées et les méthodes utilisées
-- Remonter la liste des couples d'opérations de pêches de l'étape 2
-- dont les quantités pêchées sont égales

-- Etape 4 : Chercher l'ensemble des poissons de même tailles et/ou poids
-- issus d'une pêche le même jour et dans un couple de station existant à l'étape 1
-- NB : beaucoup de poids sont NULL, à ignorer ?