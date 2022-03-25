
set search_path to rsa,public;


select * from station;
select distinct sta_zone from station;
-- En fait il s’agit des dernières stations du 56 intégrées dans la base en 2015 : n° 427 à 460
select * from station where sta_zone ='bzh' 
	and sta_id >= 427
	and sta_id <= 460;

select op_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh'; --34


select * from op_iaa where iaa_op_id in (
select op_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh');--34

select * from rsa.anguille_ang where ang_op_id in (
select op_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh');--1780

create table rsa.temp_anguille_ang_bre  (like rsa.anguille_ang);
insert into rsa.temp_anguille_ang_bre 
select * from rsa.anguille_ang where ang_op_id in (
select op_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh');--1780
comment on table rsa.temp_anguille_ang_bre is 'sauvegarde temporaire des opérations qui doivent être corrigées en Bretagne';

create table rsa.temp_op_iaa  (like rsa.op_iaa);
insert into rsa.temp_op_iaa
select * from op_iaa where iaa_op_id in (
select op_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh');--34
comment on table rsa.temp_op_iaa is 'sauvegarde temporaire des opérations qui doivent être corrigées en Bretagne';

create table rsa.temp_operation  (like rsa.operation);
insert into rsa.temp_operation
select * from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh';--34
comment on table rsa.temp_operation is 'sauvegarde temporaire des opérations qui doivent être corrigées en Bretagne';

create table rsa.temp_station  (like rsa.station);
insert into rsa.temp_station
select * from station where sta_id >=427 and sta_id <= 460 and sta_zone='bzh';--34
comment on table rsa.temp_station is 'sauvegarde temporaire des stations qui doivent être corrigées en Bretagne';


----------------
--suppression des données
-----------------
delete from rsa.anguille_ang where ang_op_id in (
select op_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh');--1780

delete from op_iaa where iaa_op_id in (
select op_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh');--34

delete from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh'; --34

delete from station where sta_zone ='bzh' 
	and sta_id >= 427
	and sta_id <= 460;




select * from rsa.anguille_ang where ang_op_id=473 and ang_zone='bzh';
select min(ang_id),max(ang_id) from rsa.anguille_ang where ang_op_id=474 and ang_zone='bzh';--10823-10942
select count (*) from rsa.anguille_ang where ang_op_id=474 and ang_zone='bzh';--120
select min(ang_id),max(ang_id) from rsa.anguille_ang where ang_op_id=473 and ang_zone='bzh';--10943 10953
update rsa.anguille_ang set ang_op_id=474  where 
				ang_op_id=473 
				and ang_zone='bzh';
update rsa.anguille_ang set ang_op_id=473  where 
				ang_op_id=474 
				and ang_zone='bzh'
				and ang_id<10943;

-- ce dessous après j'ai du le remplacer de nouveau, je ne le lance pas
select min(ang_id) from rsa.anguille_ang where ang_op_id=438;
update rsa.anguille_ang set ang_op_id=438  where 
				ang_op_id=437 
				and ang_zone='bzh';
update rsa.anguille_ang set ang_op_id=437  where 
				ang_op_id=438 
				and ang_id>=10298;

update rsa.anguille_ang set ang_op_id=4  where 
				ang_op_id=5 
				and ang_zone='bzh';--117
update rsa.anguille_ang set ang_op_id=5  where 
				ang_op_id=6 
				and ang_zone='bzh'; --12

--le 4 n'existe pas dans ang, il n'a pas besoin de devenir 6 qui est vide
--------------------------
-- la suppression qui a foutu la zone (il manquait la clause where
----------------------------
   ----------------
    --suppression des données bzh
    -----------------
    delete from rsa.anguille_ang where ang_op_id in (
    select ang_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh')--1780
    and ang_zone='bzh';

    delete from op_iaa where iaa_op_id in (
    select op_id from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh');--34
    and ang_zone='bzh';

    delete from operation where op_sta_id >=427 and op_sta_id <= 460 and op_zone='bzh'; --34
    
    delete from station where sta_zone ='bzh' and sta_id >= 427 and sta_id <= 460;
    
    ----------------
    --suppression des données ap
    -----------------
    
    delete from rsa.anguille_ang where ang_op_id in (
    select op_id from rsa.operation where op_zone='ap')
    and ang_zone='ap';-- 37517
    
    delete from rsa.op_iaa where iaa_op_id in (
    select op_id from rsa.operation where   op_zone='ap')
     and ang_zone='ap'; -- 469
    
    delete from rsa.op_epab where epab_op_id in (
    select op_id from rsa.operation where   op_zone='ap')
    and ang_zone='ap'; -- 71
    
    delete from rsa.op_inv where inv_op_id in (
    select op_id from rsa.operation where   op_zone='ap')
    and ang_zone='ap'; -- 442
    
    
    delete from rsa.operation where op_zone='ap' ; -- 186
    
    delete from rsa.station where sta_zone ='ap' ; -- 163

   ----------------
    --TRIGGER DE DATE POUR MODIF
    -----------------

        alter table rsa.station add column sta_last_update date;
        update rsa.station set sta_last_update='15/01/2015';
        
        CREATE OR REPLACE FUNCTION rsa.update_sta_last_update()	
        RETURNS TRIGGER AS $$
        BEGIN
        NEW.sta_last_update = now()::date;
        RETURN NEW;	
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_sta_time ON rsa.station;
        CREATE TRIGGER update_sta_time BEFORE INSERT OR UPDATE ON rsa.station FOR EACH ROW EXECUTE PROCEDURE  rsa.update_sta_last_update();
        -------------------------------------------------------------------
        
        alter table rsa.operation add column op_last_update date;
        update rsa.operation set op_last_update='15/01/2015';
        
        CREATE OR REPLACE FUNCTION rsa.update_op_last_update()	
        RETURNS TRIGGER AS $$
        BEGIN
        NEW.op_last_update = now()::date;
        RETURN NEW;	
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_op_time ON rsa.operation;
        CREATE TRIGGER update_op_time BEFORE INSERT OR UPDATE ON rsa.operation FOR EACH ROW EXECUTE PROCEDURE  rsa.update_op_last_update();
        ----------------------------------------------------------
        -------------------------------------------------------------------
        
        alter table rsa.op_epab add column epab_last_update date;
        update rsa.op_epab set epab_last_update='15/01/2015';
        
        CREATE OR REPLACE FUNCTION rsa.update_epab_last_update()	
        RETURNS TRIGGER AS $$
        BEGIN
        NEW.epab_last_update = now()::date;
        RETURN NEW;	
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_epab_time ON rsa.op_epab;
        CREATE TRIGGER  update_epab_time  BEFORE INSERT OR UPDATE ON rsa.op_epab FOR EACH ROW EXECUTE PROCEDURE  rsa.update_epab_last_update();
        ----------------------------------------------------------
        alter table rsa.op_epap add column epap_last_update date;
        update rsa.op_epap set epap_last_update='15/01/2015';
        
        CREATE OR REPLACE FUNCTION rsa.update_epap_last_update()	
        RETURNS TRIGGER AS $$
        BEGIN
        NEW.epap_last_update = now()::date;
        RETURN NEW;	
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_epap_time ON rsa.op_epap;
        CREATE TRIGGER  update_epap_time  BEFORE INSERT OR UPDATE ON rsa.op_epap FOR EACH ROW EXECUTE PROCEDURE  rsa.update_epap_last_update();
        ----------------------------------------------------------
        alter table rsa.op_inv add column inv_last_update date;
        update rsa.op_inv set inv_last_update='15/01/2015';
        
        CREATE OR REPLACE FUNCTION rsa.update_inv_last_update()	
        RETURNS TRIGGER AS $$
        BEGIN
        NEW.inv_last_update = now()::date;
        RETURN NEW;	
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_inv_time ON rsa.op_inv;
        CREATE TRIGGER  update_inv_time  BEFORE INSERT OR UPDATE ON rsa.op_inv FOR EACH ROW EXECUTE PROCEDURE  rsa.update_inv_last_update();
        ----------------------------------------------------------
        alter table rsa.op_pcbgb add column pcbgb_last_update date;
        update rsa.op_pcbgb set pcbgb_last_update='15/01/2015';
        
        CREATE OR REPLACE FUNCTION rsa.update_pcbgb_last_update()	
        RETURNS TRIGGER AS $$
        BEGIN
        NEW.pcbgb_last_update = now()::date;
        RETURN NEW;	
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_pcbgb_time ON rsa.op_pcbgb;
        CREATE TRIGGER  update_pcbgb_time  BEFORE INSERT OR UPDATE ON rsa.op_pcbgb FOR EACH ROW EXECUTE PROCEDURE  rsa.update_pcbgb_last_update();
        ---------------------------
        alter table rsa.op_pcbgp add column pcbgp_last_update date;
        update rsa.op_pcbgp set pcbgp_last_update='15/01/2015';
        
        CREATE OR REPLACE FUNCTION rsa.update_pcbgp_last_update()	
        RETURNS TRIGGER AS $$
        BEGIN
        NEW.pcbgp_last_update = now()::date;
        RETURN NEW;	
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_pcbgp_time ON rsa.op_pcbgp;
        CREATE TRIGGER  update_pcbgp_time  BEFORE INSERT OR UPDATE ON rsa.op_pcbgp FOR EACH ROW EXECUTE PROCEDURE  rsa.update_pcbgp_last_update();
        
        ---------------------------
        alter table rsa.anguille_ang add column ang_last_update date;
        update rsa.anguille_ang set ang_last_update='15/01/2015';
        
        CREATE OR REPLACE FUNCTION rsa.update_ang_last_update()	
        RETURNS TRIGGER AS $$
        BEGIN
        NEW.ang_last_update = now()::date;
        RETURN NEW;	
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_ang_time ON rsa.op_pcbgp;
        CREATE TRIGGER  update_ang_time  BEFORE INSERT OR UPDATE ON rsa.anguille_ang  FOR EACH ROW EXECUTE PROCEDURE  rsa.update_ang_last_update();	    
  



----------------------
-- correction des erreurs de correspondance entre anguilles et total 
-- 30/11/2017
------------------------





select * from rsa.op_epab where epab_op_id=267 and epab_zone='ap';
begin;
update rsa.op_epab set epab_ang=97 where epab_op_id=267 and epab_zone='ap';
commit;


select * from rsa.operation where op_id=274;
select * from rsa.op_inv where inv_op_id=274 and inv_zone='ap';
begin;
update rsa.op_inv set inv_p1=13 where inv_op_id=274 and inv_zone='ap';
commit;

select * from rsa.operation where op_id=275;
select * from rsa.op_iaa where iaa_op_id=275 and iaa_zone='ap';

begin;
update rsa.op_iaa set iaa_ang=14 where iaa_op_id=275 and iaa_zone='ap';
commit;

ALTER TABLE rsa.op_pcbgp DROP CONSTRAINT c_fk_pcbgp_op_id_pcbgp_zone;
ALTER TABLE rsa.op_pcbgb DROP CONSTRAINT c_fk_pcbgb_op_id_pcbgb_zone;
ALTER TABLE rsa.op_inv DROP CONSTRAINT c_fk_inv_op_id_inv_zone;
ALTER TABLE rsa.op_iaa DROP CONSTRAINT c_fk_iaa_op_id_iaa_zone;
ALTER TABLE rsa.op_epap DROP CONSTRAINT c_fk_epap_op_id_epap_zone;
ALTER TABLE rsa.op_epab DROP CONSTRAINT c_fk_epab_op_id_epab_zone;
ALTER TABLE rsa.anguille_ang DROP  CONSTRAINT c_fk_ang_op_id_ang_zone;
BEGIN;
UPDATE rsa.operation set op_id=238000 where op_id=238 and op_zone='ap';
UPDATE rsa.operation set op_id=238 where op_id=242 and op_zone='ap';
UPDATE rsa.operation set op_id=242 where op_id=238000 and op_zone='ap';
COMMIT;
BEGIN;
UPDATE rsa.operation set op_id=245000 where op_id=245 and op_zone='ap';
UPDATE rsa.operation set op_id=245 where op_id=246 and op_zone='ap';
UPDATE rsa.operation set op_id=246 where op_id=245000 and op_zone='ap';
COMMIT;



ALTER TABLE rsa.op_pcbgp ADD CONSTRAINT c_fk_pcbgp_op_id_pcbgp_zone FOREIGN KEY (pcbgp_op_id, pcbgp_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE rsa.op_pcbgb ADD CONSTRAINT c_fk_pcbgb_op_id_pcbgb_zone FOREIGN KEY (pcbgb_op_id, pcbgb_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE rsa.op_inv ADD CONSTRAINT c_fk_inv_op_id_inv_zone FOREIGN KEY (inv_op_id, inv_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE rsa.op_iaa  ADD CONSTRAINT c_fk_iaa_op_id_iaa_zone FOREIGN KEY (iaa_op_id, iaa_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH FULL
            ON UPDATE CASCADE ON DELETE CASCADE;    

ALTER TABLE rsa.op_epab  ADD CONSTRAINT c_fk_epap_op_id_epab_zone FOREIGN KEY (epab_op_id, epab_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;
             

ALTER TABLE rsa.op_epap ADD CONSTRAINT c_fk_epap_op_id_epab_zone FOREIGN KEY (epap_op_id, epap_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH FULL
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE rsa.anguille_ang ADD CONSTRAINT c_fk_ang_op_id_ang_zone FOREIGN KEY (ang_op_id, ang_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH FULL
       ON UPDATE CASCADE ON DELETE CASCADE;




select * from rsa.operation where op_id=135 and op_zone='ap';
select * from rsa.op_iaa where iaa_op_id=135 and iaa_zone='ap';
begin;
update rsa.op_iaa set iaa_ang=27 where iaa_op_id=135 and iaa_zone='ap';
commit;

select * from rsa.operation where op_id=218 and op_zone='ap';
select * from rsa.op_inv where inv_op_id=218 and inv_zone='ap';
begin;
update rsa.op_inv set inv_p1=19 where inv_op_id=218 and inv_zone='ap';
commit;
begin;
update rsa.op_inv set inv_p1=8 where inv_op_id=219 and inv_zone='ap';
commit;

select * from rsa.operation where op_id=221 and op_zone='ap';
select * from rsa.op_inv where inv_op_id=221 and inv_zone='ap';
begin;
update rsa.op_inv set inv_p1=87 where inv_op_id=221 and inv_zone='ap';
commit;



select * from rsa.operation where op_id=213 and op_zone='ap';
select * from rsa.op_inv where inv_op_id=213 and inv_zone='ap';
begin;
update rsa.op_inv set inv_p1=54 where inv_op_id=213 and inv_zone='ap';
commit;

select * from rsa.operation where op_id=213 and op_zone='ap';
select * from rsa.op_inv where inv_op_id=213 and inv_zone='ap';
begin;
update rsa.op_inv set inv_p1=54 where inv_op_id=213 and inv_zone='ap';
commit;

-----------------
select * from rsa.operation where op_id=223 and op_zone='ap';
select * from rsa.op_epab where epab_op_id=223 and epab_zone='ap';
begin;
update rsa.op_epab set epab_ang=6 where epab_op_id=223 and epab_zone='ap';
commit;
-----------------


select * from rsa.operation where op_id=225 and op_zone='ap';
select * from rsa.op_inv where inv_op_id=225 and inv_zone='ap';
begin;
update rsa.op_inv set (inv_p1,inv_p2)=(2,1) where inv_op_id=225 and inv_zone='ap';
commit;

select * from rsa.operation where op_id=235 and op_zone='ap';
select * from rsa.op_epab where epab_op_id=235 and epab_zone='ap';
begin;
update rsa.op_epab set (epab_ang)=(17) where epab_op_id=235 and epab_zone='ap';
commit;

select * from rsa.operation where op_id=229 and op_zone='bn';
select * from rsa.op_iaa where iaa_op_id=229 and iaa_zone='bn';
begin;
update rsa.op_iaa set (iaa_ang)=(22) where iaa_op_id=229 and iaa_zone='bn';
commit;

select * from rsa.operation where op_id=288 and op_zone='bn';
select * from rsa.op_iaa where iaa_op_id=288 and iaa_zone='bn';
begin;
update rsa.op_iaa set (iaa_npnt,iaa_ang,iaa_vue)=(30,18,2) where iaa_op_id=288 and iaa_zone='bn';
commit;

-- Lots S voir code R



select * from rsa.operation where op_id=240 and op_zone='bzh';
select * from rsa.op_iaa where iaa_op_id=240 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(74) where iaa_op_id=240 and iaa_zone='bzh'; -- remplace 75
commit;

select * from rsa.op_iaa where iaa_op_id=242 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(43) where iaa_op_id=242 and iaa_zone='bzh'; -- remplace 42
commit;

select * from rsa.op_iaa where iaa_op_id=243 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(107) where iaa_op_id=243 and iaa_zone='bzh'; -- remplace 108
commit;

select * from rsa.op_iaa where iaa_op_id=244 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(35) where iaa_op_id=244 and iaa_zone='bzh'; -- remplace 36
commit;

select * from rsa.op_iaa where iaa_op_id=244 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(37) where iaa_op_id=244 and iaa_zone='bzh'; -- remplace 36
commit;

select * from rsa.op_iaa where iaa_op_id=245 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(55) where iaa_op_id=245 and iaa_zone='bzh'; -- remplace 54
commit;

select * from rsa.op_iaa where iaa_op_id=246 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(19) where iaa_op_id=246 and iaa_zone='bzh'; -- remplace 18
commit;

select * from rsa.op_iaa where iaa_op_id=246 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(19) where iaa_op_id=246 and iaa_zone='bzh'; -- remplace 18
commit;

select * from rsa.op_iaa where iaa_op_id=247 and iaa_zone='bzh';
begin;
update rsa.op_iaa set (iaa_ang)=(41) where iaa_op_id=247 and iaa_zone='bzh'; -- remplace 42
commit;



select * from rsa.op_iaa where iaa_op_id=344 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=44 where iaa_op_id=344 and iaa_zone='bzh'; -- remplace 43
commit;

select * from rsa.op_iaa where iaa_op_id=248 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=19 where iaa_op_id=248 and iaa_zone='bzh'; -- remplace 18
commit;

select * from rsa.op_iaa where iaa_op_id=254 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=20 where iaa_op_id=254 and iaa_zone='bzh'; -- remplace 21
commit;

select * from rsa.op_iaa where iaa_op_id=256 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=13 where iaa_op_id=256 and iaa_zone='bzh'; -- remplace 12
commit;

select * from rsa.op_iaa where iaa_op_id=257 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=10 where iaa_op_id=257 and iaa_zone='bzh'; -- remplace 9
commit;

select * from rsa.op_iaa where iaa_op_id=258 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=5 where iaa_op_id=258 and iaa_zone='bzh'; -- remplace 6
commit;

select * from rsa.op_iaa where iaa_op_id=259 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=10 where iaa_op_id=259 and iaa_zone='bzh'; -- remplace 9
commit;

select * from rsa.op_iaa where iaa_op_id=261 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=7 where iaa_op_id=261 and iaa_zone='bzh'; -- remplace 6
commit;

select * from rsa.op_iaa where iaa_op_id=262 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=2 where iaa_op_id=262 and iaa_zone='bzh'; -- remplace 3
commit;

select * from rsa.op_iaa where iaa_op_id=263 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=8 where iaa_op_id=263 and iaa_zone='bzh'; -- remplace 9
commit;

select * from rsa.op_iaa where iaa_op_id=381 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=2 where iaa_op_id=381 and iaa_zone='bzh'; -- remplace 0
commit;

select * from rsa.op_iaa where iaa_op_id=386 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=5 where iaa_op_id=386 and iaa_zone='bzh'; -- remplace 3
commit;

select * from rsa.op_iaa where iaa_op_id=387 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=3 where iaa_op_id=387 and iaa_zone='bzh'; -- remplace 5
commit;

select * from rsa.op_iaa where iaa_op_id=387 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=3 where iaa_op_id=387 and iaa_zone='bzh'; -- remplace 5
commit;

select * from rsa.op_iaa where iaa_op_id=437 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=12 where iaa_op_id=437 and iaa_zone='bzh'; -- remplace 4
commit;

select * from rsa.op_iaa where iaa_op_id=438 and iaa_zone='bzh';
begin;
update rsa.op_iaa set iaa_ang=4 where iaa_op_id=438 and iaa_zone='bzh'; -- remplace 12 erreur mis 438
commit;

begin;
update rsa.op_iaa set iaa_ang=2 where iaa_op_id=478 and iaa_zone='bzh'; -- erreur
commit;

select * from rsa.op_iaa where iaa_op_id=456 and iaa_zone='bzh';
update rsa.op_iaa set iaa_ang=2 where iaa_op_id=456 and iaa_zone='bzh'; -- remplace 1

select * from rsa.op_iaa where iaa_op_id=815 and iaa_zone='bzh';
update rsa.op_iaa set iaa_ang=424 where iaa_op_id=815 and iaa_zone='bzh'; -- remplace 461

select * from rsa.op_iaa where iaa_op_id=244 and iaa_zone='bzh';
update rsa.op_iaa set iaa_ang=35 where iaa_op_id=244 and iaa_zone='bzh'; -- remplace 461

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------

select * from rsa.op_inv where inv_op_id=206 and inv_zone='vil';
update rsa.op_inv set inv_p1=22 where inv_op_id=206 and inv_zone='vil'; -- remplace 21

select * from rsa.op_inv where inv_op_id=207 and inv_zone='vil';
update rsa.op_inv set inv_p1=21 where inv_op_id=207 and inv_zone='vil'; -- remplace 13

select * from rsa.op_inv where inv_op_id=207 and inv_zone='vil';
update rsa.op_inv set inv_p1=21 where inv_op_id=207 and inv_zone='vil'; -- remplace 13

select * from rsa.op_inv where inv_op_id=208 and inv_zone='vil';
update rsa.op_inv set inv_p1=65 where inv_op_id=208 and inv_zone='vil'; -- remplace 30
update rsa.op_inv set inv_p2=17 where inv_op_id=208 and inv_zone='vil'; -- vérifié avec le numéro d'op ds mes propres donnees
/*
script pour vérifier les données Vilaine
CY<-2017
datawd<-"C:/workspace/pdata/pechelec/data/"
datawdy=str_c(datawd,CY,"/")
 load(file=str_c(datawdy,"pec.Rdata")) # pec
setDT(pec)
setkey(pec,Op_code)
pec["20020000210"]
*/
select * from rsa.op_inv where inv_op_id=200 and inv_zone='vil';
update rsa.op_inv set inv_p2=3 where inv_op_id=200 and inv_zone='vil'; -- remplace 1

select * from rsa.op_inv where inv_op_id=214 and inv_zone='vil';
update rsa.op_inv set inv_p1=14 where inv_op_id=214 and inv_zone='vil'; -- remplace 15
select * from rsa.anguille_ang where ang_op_id=214 and ang_zone='vil';
delete from rsa.anguille_ang where ang_id=9383 and ang_op_id=214 and ang_zone='vil'; --vire anguille de taille 240




-- note pour Pierre Marie j'ai bien 30 anguilles et pas 29 dans ce fichier
select * from rsa.op_inv where inv_op_id=235 and inv_zone='vil'; -- 21 8 0
update rsa.op_inv set inv_p1=22 where inv_op_id=235; -- remplace 21
select * from rsa.anguille_ang where ang_op_id=235 and ang_zone='vil';
select count(*) from rsa.anguille_ang where ang_op_id=235 and ang_zone='vil' group by ang_pas; --22 8 0



--changement des tables poissons (j''avais changé les operations)
ALTER TABLE rsa.anguille_ang DROP  CONSTRAINT c_fk_ang_op_id_ang_zone;
BEGIN;
UPDATE rsa.anguille_ang set ang_op_id=238000 where ang_op_id=238 and ang_zone='ap';
UPDATE rsa.anguille_ang set ang_op_id=238 where ang_op_id=242 and ang_zone='ap';
UPDATE rsa.anguille_ang set ang_op_id=242 where ang_op_id=238000 and ang_zone='ap';
COMMIT;
BEGIN;
UPDATE rsa.anguille_ang set ang_op_id=245000 where ang_op_id=245 and ang_zone='ap';
UPDATE rsa.anguille_ang set ang_op_id=245 where ang_op_id=246 and ang_zone='ap';
UPDATE rsa.anguille_ang set ang_op_id=246 where ang_op_id=245000 and ang_zone='ap';
COMMIT;

ALTER TABLE rsa.anguille_ang ADD CONSTRAINT c_fk_ang_op_id_ang_zone FOREIGN KEY (ang_op_id, ang_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH FULL
       ON UPDATE CASCADE ON DELETE CASCADE;

       
-- oublié de virer les lots L
select * from rsa.anguille_ang where ang_op_id in (529,545,546,586,587,589,590,599,605,
615,649,845,848,850,851,853,855,856,857,868,869,870) and ang_lot='L';

begin;
delete from rsa.anguille_ang where ang_op_id in (529,545,546,586,587,589,590,599,605,
615,649,845,848,850,851,853,855,856,857,868,869,870) and ang_lot='L'; --22
commit;

-- recherche des anguilles manquantes

select * from rsa.anguille_ang where ang_zone='gdl'
select distinct on (ang_zone) ang_zone from rsa.anguille_ang

delete from rsa.anguille_ang where ang_zone='bzh'  

select * from rsa.op_inv where inv_zone='rmc';
delete from rsa.op_inv where inv_zone='rmc';

select * from rsa.op_inv where inv_zone='rmc';
delete from rsa.op_inv where inv_zone='rmc';--11


select * from rsa.op_iaa where iaa_zone='bn'; --op_id de 187 à 596
delete from rsa.op_iaa where iaa_zone='bn'; --410




select * from rsa.anguille_ang where ang_lot='I';


--- sauvegarde des poids des lots I
-- après discussion avec PM on a écidé que commela moité des lots N n'avaient pas de poids, et que les poids des lot I avaient été virés
-- on ne garderait pas ces poids. Si on veut calculer les biomasses on pourra utiliser des poids observés (indiv) et les poids moyens issus d'une courbe taille poids.
Insert into rsa.temp_anguille_lotL select * from rsa.anguille_ang where ang_lot='I' and ang_eff>0;--206


select * from rsa.anguille_ang where ang_lot='I' and ang_poids>0;
select * from rsa.anguille_ang where ang_lot='I' and ang_poids=0;
update rsa.anguille_ang set (ang_eff,ang_poids)=(1,NULL )where ang_lot='I'; --2619

select * from rsa.operation where op_zone='gdl';
update rsa.operation set op_typ='epap' where op_typ='epab' and op_zone='gdl';--4

delete from  rsa.op_epap where epap_zone='gdl' and epap_last_update='2017-12-08';--9



update rsa.anguille_ang set ang_op_id=100  where 
				ang_op_id=99 
				and ang_zone='adr';
update rsa.anguille_ang set ang_op_id=99  where 
				ang_op_id=98 
				and ang_zone='adr';
				 
update rsa.anguille_ang set ang_op_id=98  where 
				ang_op_id=100 
				and ang_zone='adr'
				and ang_id>6972;
				


select * from rsa.operation where op_id=99 and op_zone='adr'
update rsa.operation set op_typ='epab' where (op_id,op_zone) in 
(select epab_op_id,epab_zone from rsa.op_epab); --97


ALTER TABLE rsa.anguille_ang DROP  CONSTRAINT c_fk_ang_op_id_ang_zone;
BEGIN;
UPDATE rsa.anguille_ang set ang_op_id=90000 where ang_op_id=9 and ang_zone='rmc';
UPDATE rsa.anguille_ang set ang_op_id=9 where ang_op_id=8 and ang_zone='rmc';
UPDATE rsa.anguille_ang set ang_op_id=8 where ang_op_id=90000 and ang_zone='rmc';
COMMIT;
ALTER TABLE rsa.anguille_ang ADD CONSTRAINT c_fk_ang_op_id_ang_zone FOREIGN KEY (ang_op_id, ang_zone)
      REFERENCES rsa.operation (op_id, op_zone) MATCH FULL
       ON UPDATE CASCADE ON DELETE CASCADE;

select * from rsa.op_iaa where iaa_op_id=11 and iaa_zone='bzh';
update rsa.op_iaa set iaa_ang=32 where iaa_op_id=11 and iaa_zone='bzh'; -- remplace 31

select * from rsa.op_iaa where iaa_op_id=12 and iaa_zone='bzh';
update rsa.op_iaa set iaa_ang=24 where iaa_op_id=12 and iaa_zone='bzh'; -- remplace 23


select * from rsa.op_iaa where iaa_op_id=81 and iaa_zone='bn';
update rsa.op_iaa set iaa_ang=26 where iaa_op_id=81 and iaa_zone='bn'; -- remplace 23

select * from rsa.op_iaa where iaa_op_id=81 and iaa_zone='bn';
update rsa.op_iaa set iaa_ang=26 where iaa_op_id=81 and iaa_zone='bn'; -- remplace 23

select * from rsa.op_iaa where iaa_op_id=437 and iaa_zone='bn';
update rsa.op_iaa set iaa_ang=141 where iaa_op_id=437 and iaa_zone='bn'; -- remplace 23


select * from rsa.anguille_ang where ang_op_id=437 and ang_zone='bn';
update rsa.anguille_ang set ang_op_id=438 where ang_op_id=437 and ang_zone='bn' and ang_id>=12717 ; --31 retour à op 438

update rsa.op_iaa set iaa_ang=10 where iaa_op_id=514 and iaa_zone='bn'; 
update rsa.op_iaa set iaa_ang=5 where iaa_op_id=515 and iaa_zone='bn';
update rsa.op_iaa set iaa_ang=2 where iaa_op_id=542 and iaa_zone='bn';  
update rsa.op_iaa set iaa_ang=2 where iaa_op_id=543 and iaa_zone='bn';  

select * from rsa.op_iaa where iaa_op_id=605 and iaa_zone='bzh';
update rsa.op_iaa set iaa_ang=78 where iaa_op_id=605 and iaa_zone='bzh'; --remplace 79
update rsa.op_iaa set iaa_ang=820 where iaa_op_id=649 and iaa_zone='bzh'; --remplace 819

select * from rsa.anguille_ang where ang_op_id=10 and ang_zone='gdl';

select ang_op_id  from rsa.anguille_ang where ang_lot='L' group by ang_op_id order by ang_op_id


select * from rsa.anguille_ang  where ang_op_id=46 and ang_zone='gdl';
select * from rsa.temp_anguille_lotL where ang_op_id in (46,53,66,245); -- le lot n'a pas été intégré ?
insert into rsa.anguille_ang select distinct on (ang_op_id) *  from rsa.temp_anguille_lotL where ang_op_id= 46;
delete from rsa.anguille_ang  where ang_op_id= 46 and ang_zone='gdl' and ang_lot='R';

delete from rsa.temp_anguille_lotL where ang_op_id in (46) and ang_zone='gdl'
update rsa.op_iaa set iaa_ang=141 where iaa_op_id=437 and iaa_zone='bn'; 


select * from rsa.operation where op_id=53 and op_zone='gdl';
select * from rsa.op_pcbgp  where pcbgp_op_id=53 and pcbgp_zone='gdl';
update rsa.op_pcbgp set pcbgp_p2=94  where pcbgp_op_id=53 and pcbgp_zone='gdl'; --remplace 76
--Pour la 53 dans les lots j’ai un dernier lotS  (numéro 5) sans lot L attaché, du coup comme j’ai remis un effectif de 1 à toutes les anguilles l’effectif final est supérieur (230 au lieu de 212),
-- Les anguilles sont à ajouter au deuxième passage.


select * from rsa.op_inv  where inv_op_id=66 and inv_zone='gdl';
update rsa.op_inv set inv_p1=140  where inv_op_id=66 and inv_zone='gdl'; -- remplace 141

select * from rsa.op_inv  where inv_op_id=245 and inv_zone='gdl';
update rsa.op_inv set inv_p1=91  where inv_op_id=245 and inv_zone='gdl'; -- remplace 74


