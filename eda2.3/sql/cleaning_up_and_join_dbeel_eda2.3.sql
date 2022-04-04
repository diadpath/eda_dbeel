alter table dbeel.rn set schema dbeel_rivers;
alter table dbeel.rna set schema dbeel_rivers;

/*
-- supprimer le schema dbeel dans eda2.3
-- supprimer le schema dbeel_nomenclature dans eda2.3
pg_dump -U postgres -f "dbeel.sql" --schema dbeel_nomenclature --schema dbeel dbeel
psql -U postgres -f "dbeel.sql" eda2.3
pg_dump -U postgres -f "sudoang.sql" --schema sudoang dbeel
create extension dblink;
psql -U postgres -f "sudoang.sql" eda2.3


/* seulement pour cedric */

/*
pg_dump -U postgres -f "dbeel.sql" dbeel

creer base dbeel sur le serveur
CREATE EXTENSION dblink;
CREATE EXTENSION ltree;
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology; 
CREATE EXTENSION "uuid-ossp"
psql -U postgres -p 5434 -h w3.eptb-vilaine.fr -f "dbeel.sql" dbeel
une fois terminé supprimer la base dbeel en local

pg_dump -U postgres -f "dbeel_rivers.sql" --schema dbeel_rivers eda2.3
psql -U postgres -f "dbeel_rivers.sql" eda2.3

pg_dump -U postgres -f "france.sql" --schema france eda2.3
psql -U postgres -f "france.sql" eda2.3
pg_dump -U postgres -f "spain_rn.sql" --table spain.rn --table spain.rna eda2.3
psql -U postgres -f "spain.sql" eda2.3
pg_dump -U postgres -f "portugal_rn.sql" --table portugal.rn --verbose eda2.3
psql -U postgres -f "portugal.sql" eda2.3

alter table spain.wise_rbd_f1v3 add column gid serial primary key;

