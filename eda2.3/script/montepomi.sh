# sauvegarde de la base de données roe, bdoe, ice, geobs locale pour remplacement sur le serveur

pg_dump -U postgres -h localhost -Fc -f "dam_databases.backup" --schema bdoe --schema roe --schema ice --schema geobs eda2.3

psql -U postgres -h 185.135.126.250 -c "DROP SCHEMA roe CASCADE; DROP SCHEMA ice cascade; DROP SCHEMA bdoe CASCADE; DROP SCHEMA geobs cascade;" eda2.3

pg_restore -U postgres -h 185.135.126.250 -d eda2.3 dam_databases.backup



-- restauration du schema france en localhost

psql -U postgres -c "DROP SCHEMA france CASCADE" eda2.3
psql -U postgres -c "DROP SCHEMA dbeel_rivers CASCADE" eda2.3
pg_dump -U postgres -h 185.135.126.250 --schema dbeel_rivers eda2.3 | psql -U postgres -h localhost eda2.3 