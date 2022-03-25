-- D'abord un essai qui marche
select cast(unnest(vecteurchemin) as integer) as id_drain 
        from (SELECT regexp_split_to_array(ltree2text(chemin),E'\\.+') as vecteurchemin from rht.rhtvs2 where chemin ~ '*.20211.*') as sub 
EXCEPT  select cast(unnest(vecteurchemin) as integer) as id_drain 
        from ( select regexp_split_to_array(ltree2text(chemin),E'\\.+') as vecteurchemin from rht.rhtvs2 where id_drain=20211) as sub
EXCEPT select 20211;

-- Ensuite la fonction qui ne marchait pas le E'\\.+' devient un E''\\\\.+''
DROP TYPE IF EXISTS id_drain;
CREATE TYPE id_drain as (id_drain int);
-- je sors le create table de la fonction pour gagner du temps... Attention à bien le lancer sinon ça plantera
DROP TABLE IF EXISTS rht.upstream_riversegments;
CREATE TABLE rht.upstream_riversegments(id_drain integer);
DROP  FUNCTION IF EXISTS rht.upstream_segments(id_ numeric);
CREATE OR REPLACE FUNCTION rht.upstream_segments(id_ numeric) RETURNS setof int AS $$
        DECLARE
        id_drain id_drain%ROWTYPE;
        BEGIN
        -- filling a new table with the results from a catchment
        delete from rht.upstream_riversegments;
        EXECUTE 'insert into rht.upstream_riversegments (select cast(unnest(vecteurchemin) as integer) as id_drain 
        from (SELECT regexp_split_to_array(ltree2text(chemin),E''\\.+'') as vecteurchemin from rht.rhtvs2 where chemin ~ ''*.'||id_||'.*'') as sub 
        EXCEPT  select cast(unnest(vecteurchemin) as integer) as id_drain 
        from ( select regexp_split_to_array(ltree2text(chemin),E''\\.+'') as vecteurchemin from rht.rhtvs2 where id_drain='||id_||') as sub
        EXCEPT select '||id_||' order by id_drain)';
        
        for id_drain in select * from rht.upstream_riversegments loop
                id_drain.id_drain=CAST(id_drain.id_drain AS int8);
                return next id_drain.id_drain;
                end loop;
                return; 
        END;
$$
LANGUAGE 'plpgsql' ;
COMMENT ON FUNCTION rht.upstream_segments(id_drain_ numeric) IS 'function using btree to calculate upstream riversegments';
-- pour lancer la fonction
select  rht.upstream_segments(20211); --734ms


DROP  FUNCTION IF EXISTS rht.sea_riversegment(id_ numeric);
CREATE OR REPLACE FUNCTION rht.sea_riversegment(id_ numeric) RETURNS int AS $$
        DECLARE id_drain int;
        BEGIN
        execute 'select vecteurchemin[1] from (
        select regexp_split_to_array(ltree2text(chemin),E''\\.+'') vecteurchemin from rht.rhtvs2 where id_drain='||id_||') sub' into id_drain;
        RETURN id_drain;
        END;
$$
LANGUAGE 'plpgsql' ;
COMMENT ON FUNCTION rht.sea_riversegment(id_drain_ numeric) IS 'function using btree to calculate sea riversegments';
select rht.sea_riversegment(20211); 
