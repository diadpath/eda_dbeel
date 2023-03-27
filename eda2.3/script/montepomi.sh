# sauvegarde de la base de données roe, bdoe, ice, geobs locale pour remplacement sur le serveur

pg_dump -U postgres -h localhost -Fc -f "dam_databases.backup" --schema bdoe --schema roe --schema ice --schema geobs eda2.3