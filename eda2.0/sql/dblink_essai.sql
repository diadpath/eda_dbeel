CREATE OR REPLACE FUNCTION dblink_connect (text)
RETURNS text
AS '$libdir/dblink','dblink_connect'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION dblink_connect (text, text)
RETURNS text
AS '$libdir/dblink','dblink_connect'
LANGUAGE C STRICT;

SELECT * from dblink_connect('labelleconnexion','hostaddr=127.0.0.1 port=5432 dbname=BD_CONTMIG user=postgres password=postgres');

CREATE OR REPLACE FUNCTION dblink (text, text)
RETURNS setof record
AS '$libdir/dblink','dblink_record'
LANGUAGE C STRICT;

dblink_connect(connname="conn",'hostaddr=127.0.0.1 port=5432 dbname=BD_CONTMIG user=postgres password=postgres'); 


create or replace view myremote_pg_proc as
      select *
        from dblink(text 'dbname=BD_CONTMIG', text 'select lot_identifiant from t_lot_lot')
        as t1(lot_identifiant integer);

    select * from myremote_pg_proc where proname like 'bytea%';


 create view myremote_pg_proc as
      select *
        from dblink('dbname=postgres', 'select proname, prosrc from pg_proc')
        as t1(proname name, prosrc text);

    select * from myremote_pg_proc where proname like 'bytea%';


 
select dblink_connect('dbname=postgres password=postgres');

SELECT * from dblink_connect('labelleconnexion','hostaddr=127.0.0.1 port=5432 dbname=BD_CONTMIG user=postgres password=postgres');

  