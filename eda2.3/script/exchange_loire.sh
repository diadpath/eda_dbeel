cd "D:\eda\base\eda2.3"
pg_dump -U postgres -Fc eda2.3
pg_dump -U postgres -Fc --table france.batch_aspe --table france.batch_fish_aspe --table france.batch_fish_fdloire --table france.operation_aspe --table france.operation_fdloire --table france.station_aspe --table france.station_fdloire -f "edafishloire.backup" eda2.3


-- Marion
CREATE TABLESPACE big_data LOCATION 'D:\postgresql\data';
createdb -U postgres --tablespace big_data eda2.3
psql -U postgres -c "create extension postgis" eda2.3
psql -U postgres -c "create extension 'uuid-ossp'" eda2.3
psql -U postgres -c "create extension pgrouting" eda2.3
psql -U postgres -c "create extension ltree" eda2.3
psql -U postgres -c "create extension tablefunc" eda2.3