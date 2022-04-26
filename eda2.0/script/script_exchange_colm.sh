
# exchange Colm

pg_dump -U postgres -f "dbeel.backup" -Fc -h 185.135.126.250 --schema dbeel_nomenclature --schema dbeel eda2.0
pg_restore -U postgres -d eda2.0 dbeel.backup

pg_dump -U postgres -Fc  -h 185.135.126.250 -p 5432 --schema ccm21 -f "ccm.backup" eda2.0 
pg_restore -U postgres -d eda2.0 ccm.backup

pg_dump -U postgres -Fc  -h 185.135.126.250 -p 5432 --schema europe -f "europe.backup" eda2.0 
pg_restore -U postgres -d eda2.0 europe.backup


pg_dump -U postgres -Fc  -h 185.135.126.250 -p 5432 --schema wrbd --schema ireland -f "ireland.backup" eda2.0 
pg_restore -U postgres -d eda2.0 ireland.backup

pg_dump -U postgres -Fc  -h 185.135.126.250 -p 5432 --schema dmeer2003 --schema europe --schema ecoregion2003 --schema european_wise2008   eda2.0


F:\eda\base\eda2.3>pg_dump -U postgres -f "portugalrne.backup" --table portugal.rne --verbose -Fc eda2.3
pg_restore -U postgres -d eda2.3 portugalrne.backup


# exchange 26/04
# restoration from Colm data to preserve UUIDs

cd eda/base/eda2.0
# first of all save the database
pg_dump -U postgres -FC -h 185.135.126.250 -p 5432 --schema ireland -f ireland_26_04.sql --verbose eda2.3
psql -U postgres -h 185.135.126.250 -p 5432 eda2.0

drop table ireland.electrofishing CASCADE;
drop table ireland.batch_ope CASCADE;
drop table ireland.eel_ifi_length;
drop table ireland.eel_ifi_survey;
drop table ireland.eel_mi_length;
drop table ireland.eel_mi_survey;
drop table ireland.eel_wfd_length;
drop table ireland.eel_wfd_survey;

pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_stationdbeel_colm.backup
pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_batchope_colm.backup
pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_eelifilength_colm.backup
pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_eelifisurvey_colm.backup
pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_eelmilength_colm.backup
pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_eelmisurvey_colm.backup
pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_eelwfdlength_colm.backup
pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_eelwfdsurvey_colm.backup
pg_restore -U postgres -d eda2.0 -h 185.135.12.250 ireland_electrofishing_colm.backup


