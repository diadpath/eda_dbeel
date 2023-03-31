# sauvegarde de la base de données roe, bdoe, ice, geobs locale pour remplacement sur le serveur

pg_dump -U postgres -h localhost -Fc -f "dam_databases.backup" --schema bdoe --schema roe --schema ice --schema geobs eda2.3

psql -U postgres -h HOST -c "DROP SCHEMA roe CASCADE; DROP SCHEMA ice cascade; DROP SCHEMA bdoe CASCADE; DROP SCHEMA geobs cascade;" eda2.3

pg_restore -U postgres -h HOST -d eda2.3 dam_databases.backup



# restauration du schema france en localhost

psql -U postgres -c "DROP SCHEMA france CASCADE" eda2.3
psql -U postgres -c "DROP SCHEMA dbeel_rivers CASCADE" eda2.3
pg_dump -U postgres --schema dbeel_rivers --schema france --dbname=postgresql://USER:PASSWORD@HOST:5432/eda2.3 | psql -U postgres --dbname=postgresql://USER:PASSWORD@127.0.0.1:5432/eda2.3 



# restauration de montepomi en localhost
# remplacer HOST USER PASSWORD pour les machines distantes et localhost

psql -U postgres -c "DROP SCHEMA montepomi CASCADE" eda2.3
pg_dump -U postgres --schema montepomi --dbname=postgresql://USER:PASSWORD@HOST:5432/eda2.3 | psql -U postgres --dbname=postgresql://USER:PASSWORD@127.0.0.1:5432/eda2.3 


# récupération du référentiel du SANDRE roe (en localhost)
# https://services.sandre.eaufrance.fr/geo/obs?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&typename=ObstEcoul_FXX&SRSNAME=EPSG:2154&OUTPUTFORMAT=SHAPEZIP
shp2pgsql -s 2154 ObstEcoul_FXX temp.roe > "obstecoul.sql"
psql - U postgres -f obstecoul.sql geola

# récupération du référentiel du SANDRE roe (sur le serveur) (HOST est l'adresse IP du serveur)

psql - U postgres -h HOST -f obstecoul.sql geola