# restore geobs script
# 28/09/2022
#----------------------------
SET PGPASSWORD=xxxxx  # no space
d:
cd d:/eda/base/eda2.3/
pg_dump -U postgres -f "old_geobs.backup" --schema geobs eda2.3
pg_dump -U postgres -f "old_ice.backup" --schema ice eda2.3
pg_dump -U postgres -f "old_bdoe.backup" --schema bdoe eda2.3
pg_dump -U postgres -f "old_roe.backup" --schema roe eda2.3

# sauvegarde de la base
pg_dump -U postgres -Fc -f "eda2.3.backup" eda2.3  #28/09/2022


cd D:/eda/data/eda2.3/gt2/geobs2022
psql -U postgres -c "drop schema geobs  CASCADE" eda2.3
psql -U postgres -c "drop schema ice  CASCADE" eda2.3
psql -U postgres -c "drop schema bdoe  CASCADE" eda2.3
psql -U postgres -c "drop schema roe  CASCADE" eda2.3

psql -U postgres -c "drop schema geobs  CASCADE; drop schema ice  CASCADE;drop schema bdoe  CASCADE; drop schema roe  CASCADE" eda2.3

psql -U postgres -c "drop database geobs"
createdb -U postgres geobs
psql -U postgres -c "CREATE EXTENSION postgis" geobs
psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS tablefunc;" geobs


psql -U postgres -f "d:/eda/base/eda2.3/old_roe.backup" geobs
# The schema postgis is not in a standared location (public)... changed here
psql -U postgres -d geobs -c "CREATE SCHEMA IF NOT EXISTS postgis;UPDATE pg_extension SET extrelocatable = TRUE WHERE extname = 'postgis';ALTER EXTENSION postgis SET SCHEMA postgis;"  

# -c clean -j jobs -1 (begin commit single transaction) -e exit on error ATTENTION j incompatible avec -e
pg_restore -U postgres -c -d  geobs geobs_export_20220704.backup 1> "restorelog.log" 2>&1
# 731 errors of foreign keys and postgis

pg_dump  -U postgres --schema roe --schema ice --schema bdoe --schema geobs geobs > "D:/eda/base/eda2.3/sauv_geobs_to_eda_2022.sql"
# OPEN FILE IN notepad ++ replace all postgis. by public.
psql -U postgres -c "drop schema roe cascade; drop schema ice cascade; drop schema bdoe cascade; drop schema geobs cascade;" eda2.3
psql -U postgres  -f "D:/eda/base/eda2.3/sauv_geobs_to_eda_2022.sql"  eda2.3