# sauvegarde de la base de données roe, bdoe, ice, geobs locale pour remplacement sur le serveur

pg_dump -U postgres -h localhost -Fc -f "dam_databases.backup" --schema bdoe --schema roe --schema ice --schema geobs eda2.3

psql -U postgres -h 185.135.126.250 -c "DROP SCHEMA roe CASCADE; DROP SCHEMA ice cascade; DROP SCHEMA bdoe CASCADE; DROP SCHEMA geobs cascade;" eda2.3

pg_restore -U postgres -h 185.135.126.250 -d eda2.3 dam_databases.backup