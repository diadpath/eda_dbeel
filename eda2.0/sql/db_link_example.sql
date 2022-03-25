
/* Connection à une base distante

 http://www.postgresql.org/docs/current/static/dblink.html
 A lancer depuis 'BASE Pierre'
*/

-- création des fonctions db_lik permettant un lien vers d'autres bases
CREATE OR REPLACE FUNCTION dblink_connect (text)
RETURNS text
AS '$libdir/dblink','dblink_connect'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION dblink_connect (text, text)
RETURNS text
AS '$libdir/dblink','dblink_connect'
LANGUAGE C STRICT;

--dblink_connect -- opens a persistent connection to a remote database

CREATE OR REPLACE FUNCTION dblink_disconnect (text)
RETURNS text
AS '$libdir/dblink','dblink_disconnect'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION dblink (text, text)
RETURNS setof record
AS '$libdir/dblink','dblink_record'
LANGUAGE C STRICT;

/*
dblink executes a query (usually a SELECT, but it can be any SQL statement that returns rows) in a remote database.
When two text arguments are given, the first one is first looked up as a persistent connection's name;
 if found, the command is executed on that connection. If not found, the first argument is treated as a connection info string 
as for dblink_connect, and the indicated connection is made just for the duration of this command. 
*/

-- essai de connexion => je crois qu'il faut le nom de la connexion
SELECT * from dblink_connect('base=Migang','hostaddr=127.0.0.1 port=5432 dbname=Migang user=postgres password=postgres');


--drop view Migang_t_ouvrage_view
-- cette requete ne renvoit qu'une colonne dans la vue

create or replace view Migang_t_ouvrage_view as

      select *
        from dblink('base=Migang', 'select ouv_id from t_ouvrage_ouv')
        as t1(ouv_id character(7)); -- la fonction doit retourner le nom et le type du champ

-- pour voir
    select * from Migang_t_ouvrage_view ;

-- fermeture de la connexion 

select * from dblink_disconnect('base=Migang');


-- vire les fonctions
DROP FUNCTION dblink_connect (text, text);

DROP FUNCTION dblink_connect (text);

DROP FUNCTION dblink(text,text);

DROP FUNCTION dblink_disconnect();

