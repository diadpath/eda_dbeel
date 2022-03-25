

rht.upstream_segments(id_drain_ numeric)

CREATE TABLE rht.silver_production (LIKE rht.silver2017);
SELECT * FROM rht.silver_production;
SELECT AddGeometryColumn('rht','silver_production', 'geom',2154,'MULTILINESTRING',2);


DROP FUNCTION rht.upstream_silver(integer);
/*
Fonction de calcul du nombre d'anguilles argentées par classe de taille sur le bassin amont
*/
DROP FUNCTION  rht.upstream_silver(integer);
CREATE OR REPLACE FUNCTION rht.upstream_silver(_id_drain integer) RETURNS void AS 
$$
        BEGIN
	        INSERT INTO rht.silver_production("id_drain","300_450","450_600","600_750","750","total")
	              SELECT _id_drain,
	               round(sum("300_450")::numeric,2) AS "300_450",
	               round(sum("450_600")::numeric,2) AS "450_600",
	               round(sum("600_750")::numeric,2) AS "600_750",
	               round(sum("750")::numeric,2) AS "750",
	               round((sum("300_450")+sum("450_600")+sum("600_750")+sum("750"))::numeric,2) AS "Total"
	        FROM rht.silver2017 s WHERE s.id_drain in (select * from rht.upstream_segments(_id_drain));
	    RETURN;        
        END       
$$
LANGUAGE 'plpgsql' ;



SELECT rht.upstream_silver(200870);
SELECT rht.upstream_segments(200870);
select * from rht.silver_production;
DELETE FROM rht.silver_production;

/*
Fonction de calcul du nombre d'anguilles argentées boucle sur un id_drain de départ à un id_drain d'arrivée.
*/
DROP FUNCTION rht.upstream_silver_vector(integer, integer);
CREATE OR REPLACE FUNCTION rht.upstream_silver_vector(
    id_drain_init integer,
    id_drain_end integer)
  RETURNS text AS
$BODY$
	DECLARE
	current_id_drain int;
	exists_id_drain boolean;
	is_not_source boolean;	
	BEGIN	  	
		RAISE NOTICE 'calcul des bassin amont de % à %',id_drain_init,id_drain_end;
		current_id_drain=id_drain_init;
		while (current_id_drain<=id_drain_end) LOOP 
			select exists (SELECT 1 FROM rht.rhtvs2 WHERE id_drain = current_id_drain LIMIT 1) into exists_id_drain ;
			select NOT noeudsource from rht.rhtvs2 where id_drain=current_id_drain into is_not_source;
			RAISE NOTICE 'id_drain =%',current_id_drain;
			IF (exists_id_drain AND is_not_source) THEN
			RAISE NOTICE 'insert';	
			EXECUTE 'select rht.upstream_silver('||current_id_drain||')';			
			END IF;	
			current_id_drain=current_id_drain+1;						
		END LOOP;
	RETURN('transaction effectuée');
	END
$BODY$
LANGUAGE plpgsql VOLATILE
--------------------------------------------
--1 =>28000 
-- 100000 => 124000 
--200000=>240000 
--300000 325000 
--400000 407000 
-- 500000 508000
------------------------------------------------
begin;
SELECT rht.upstream_silver_vector(1,10000);
commit;

begin;
SELECT rht.upstream_silver_vector(10001,20000);
commit;

begin;
SELECT rht.upstream_silver_vector(20001,30000);
commit;
------------------------------------------------
begin;
SELECT rht.upstream_silver_vector(100001,120000);
commit;

begin;
SELECT rht.upstream_silver_vector(104142,120000);
commit;
begin;
SELECT rht.upstream_silver_vector(120001,130000); --123626
commit;
begin;
SELECT rht.upstream_silver_vector(130001,140000); 
commit;
---------------------------------------------
begin;
SELECT rht.upstream_silver_vector(200001,210000);
Commit;

begin;
SELECT rht.upstream_silver_vector(210001,220000);
Commit;

begin;
SELECT rht.upstream_silver_vector(220001,230000);
Commit;

begin;
SELECT rht.upstream_silver_vector(230001,240000);
Commit;
------------------------------------------------
begin;
SELECT rht.upstream_silver_vector(300000,310000);
commit;

begin;
SELECT rht.upstream_silver_vector(310001,325000);
commit;
-------------------------------------------------
begin;
SELECT rht.upstream_silver_vector(400000,410000);
commit;
----------------------------------------------------
begin;
SELECT rht.upstream_silver_vector(500000,506421);
commit;
-------------
-- MISE A JOUR DES GEOM DE LA TABLE
-------------        
UPDATE rht.silver_production SET geom=sub.geom FROM
(SELECT id_drain, st_transform(the_geom,2154) AS geom FROM rht.rhtvs2) sub 
WHERE sub.id_drain=silver_production.id_drain and silver_production.geom is null;


CREATE INDEX silver_production_gistindex
  ON rht.silver_production
  USING gist
  (geom);

  
/*
A ce stade sauvegarde du fichier de données
pg_dump -U postgres -f "rht.silver_production.sql" --table rht.silver_production  eda2.2
*/



/*--------------------
RAJOUT DE LA VALEUR DE L'ID_DRAIN EN COURS
ATTENTION AJOUTER LES ID_DRAINS AMONT VA ME GENERER UN AJOUT DE SEGMENTS QUI NE SONT PAS DANS MON JEU DE DONNEES
--------------------------------*/




select * from rht.silver_production where id_drain in (
select id_drain from rht.attributs_rht_fev_2011_vs2 where d_source::numeric=0);--0

select count(*) from rht.silver_production where id_drain in (
select id_drain from rht.attributs_rht_fev_2011_vs2 );--104996

insert into rht.silver_production(id_drain, geom) 
 select id_drain, st_transform(the_geom,2154) from
 rht.attributs_rht_fev_2011_vs2 
 where d_source::numeric=0 ; -- 5600
alter table rht.silver_production add column source boolean default FALSE;
-- j'ai un peu peur je rajoute les id_drain amont
update rht.silver_production set source = FALSE;
update rht.silver_production set source = TRUE where id_drain in
 (
select id_drain from rht.rhtvs2 where noeudsource);--55600 sur 57593

-------------------
-- travail temps id_drains manquants
-------------------
select * from rht.silver_production limit 10;

select * from rht.silver_production where source is false and "300_450" is null order by id_drain ;

select source, count(*) from rht.silver_production group by source;
select * from rht.silver_production where source;

select id_drain from rht.silver_production except select id_drain from rht.rhtvs2;
select count(*) from rht.silver_production; 110597

select * from rht.silver_production where id_drain>100000 and id_drain <115000 order by id_drain ;
delete from rht.silver_production where id_drain <104146 and id_drain>100000; --216


begin;
SELECT rht.upstream_silver_vector(100001,104143);
commit;

/*--------------------
GROS TRAVAIL BROUILLON DE SUPPRESSION DES DOUBLONS
--------------------------------*/

select count(*) from rht.silver2017; --114473 => 114472
select * from rht.silver2017 limit 10;
delete from rht.silver2017 where id_drain=0;
select count(*) from rht.silver_production; --110597

select  * from rht.silver_production limit 10;
alter table rht.silver_production add column id serial primary key;
DELETE FROM rht.silver_production
WHERE id IN (SELECT id
              FROM (SELECT id,
                             ROW_NUMBER() OVER (partition BY id_drain ORDER BY id) AS rnum
                     FROM rht.silver_production) t
              WHERE t.rnum > 1);
 DELETE FROM rht.silver_production where id_drain  in (             
SELECT id_drain from rht.silver_production
except select id_drain from rht.rhtvs2); --9

alter table rht.silver_production add constraint c_uk_id_drain unique (id_drain);

 DELETE FROM rht.silver_production where id_drain  in (             
SELECT id_drain from rht.silver_production
except select id_drain from rht.silver2017); --28


/*--------------------
AJOUT DE LA VALEUR DE L'ID_DRAIN en COURS A l'ID_DRAIN AMONT
--------------------------------*/

select id_drain,
	               "300_450",
	              "450_600",
	              "600_750",
	               "750",
	              "total"
	        FROM rht.silver_production
		where source
	        limit 10;
/*
Il est nécessaire d'ajouter la valeur de l'id_drain en cours à la somme de l'amont
*/	        
select count(*) from rht.silver_production ; --112401

update rht.silver_production sp set (
                       "300_450",
	               "450_600",
	               "600_750",
	               "750",
	              "total")
	              =
	             (
                       sub."300_450",
	               sub."450_600",
	               sub."600_750",
	               sub."750",
	              sub."total")
	           from (select 
	               s.id_drain,
	               s."300_450"+coalesce(sp."300_450",0) as "300_450",
	               s."450_600"+coalesce(sp."450_600",0) as "450_600",
	               s."600_750"+coalesce(sp."600_750",0) as "600_750",
	               s."750"+coalesce(sp."750",0) as "750",
	              s."total"+coalesce(sp."total",0) as "total"
	        FROM rht.silver2017 s
	        JOIN rht.silver_production sp
	        ON s.id_drain = sp.id_drain) as sub	        
	        where sub.id_drain=sp.id_drain; --112365


select * from rht.silver_production;

--212 manquant





insert into rht.silver_production(id_drain, geom) 
 select id_drain, st_transform(the_geom,2154) from
 rht.attributs_rht_fev_2011_vs2 where id_drain in (
	select id_drain from   rht.attributs_rht_fev_2011_vs2 
	 where d_source::numeric=0 except
	select id_drain from rht.silver_production);
select * from rht.silver_production where total is null; --259

select * from rht.silver_production where id_drain>=100001 and id_drain<=104141
select * from rht.silver2017 where id_drain=100169
select * from rht.silver_production  where id_drain=100169
-- manque le qualitficatif source sur les recalculés







select * from rht.silver2017 where id_drain=100398;
select * from rht.silver_production where id_drain=100398;

insert into rht.silver_production (
			id_drain,
                       "300_450",
	               "450_600",
	               "600_750",
	               "750",
	              "total",
		       source,
			geom)
	            select 
	               s.id_drain,
	               s."300_450" as "300_450",
	               s."450_600" as "450_600",
	               s."600_750" as "600_750",
	               s."750" as "750",
	              s."total" as "total",
			true,
                       st_transform(vs2.the_geom,2154)
	         FROM rht.silver2017 s
                join rht.rhtvs2 vs2
		ON s.id_drain = vs2.id_drain
                where s.id_drain in (
                select id_drain from rht.rhtvs2 vs2
	        where noeudsource is true
                and id_drain>=100001 and id_drain<=104141
		except
		select id_drain from rht.silver_production); --1893
                	        
	        


-- TODO rajouter geom



select * from rht.silver_production where total is null order by id_drain; --259



 where d_source::numeric=0 ;