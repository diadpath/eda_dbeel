-- data come from different tables
/*
-- raw data 
france.station_fdloire
 rsa.station
france.station_aspe
*/

--processed data

SELECT * FROM france.dbeel_station_aspe
SELECT * FROM france.dbeel_station_fdloire
SELECT * FROM france.dbeel_station_rsa

SELECT max(op_date) FROM rsa.operation WHERE op_zone  = 'lcvlogrami' ; --2013
SELECT count(*) FROM rsa_loire.station; --349
SELECT count(*) FROM rsa_loire.operation; --1001
SELECT count(*) FROM rsa_loire.op_iaa; --864

SELECT count(*) FROM rsa.operation WHERE op_zone  = 'lcvlogrami' ; --2013

SELECT DISTINCT sta_zone FROM rsa.station;
SELECT count(*), sta_zone FROM rsa_loire.station GROUP by sta_zone;
SELECT count(*), sta_zone FROM rsa.station GROUP by sta_zone;




-- bassin de la Loire seaidsegment = 'FR214925'


SELECT * FROM france.rn_rna WHERE emu='FR_Loir' 


DROP TABLE IF EXISTS france.dbeel_station_fdloire_duplicates_rsa;  
CREATE TABLE france.dbeel_station_fdloire_duplicates_rsa AS( 
WITH 
       projection_fdloire as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r       
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_fdloire s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_fdloire2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_fdloire
       WHERE emu='FR_Loir' ),

       projection_rsa as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_rsa s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_rsa2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_rsa
       WHERE emu='FR_Loir' 
       ),
       
       duplicates_fdloire_rsa AS (       
       SELECT f.op_id AS dfloire_op_id, r.op_id AS rsa_ope_id, r.the_geom FROM projection_rsa2 r
       JOIN   projection_fdloire2 f ON st_dwithin(r.the_geom, f.the_geom, 50))
      
       SELECT * FROM  duplicates_fdloire_rsa       
       ) --50
       
CREATE TABLE france.dbeel_station_aspe_duplicates_rsa AS( 
WITH projection_aspe as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_aspe s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_aspe2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_aspe
       WHERE emu='FR_Loir' ),
       
       projection_rsa as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_rsa s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_rsa2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_rsa
       WHERE emu='FR_Loir' 
       ),
       
       duplicates_aspe_rsa AS (       
       SELECT f.op_id AS aspe_op_id, r.op_id AS rsa_ope_id, r.the_geom 
       FROM projection_rsa2 r
       JOIN   projection_aspe2 f ON st_dwithin(r.the_geom, f.the_geom, 50))
      
       SELECT * FROM  duplicates_aspe_rsa       
       ) --19  
       
       
CREATE TABLE france.dbeel_station_aspe_duplicates_fdloire AS( 
WITH projection_aspe as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_aspe s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_aspe2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_aspe
       WHERE emu='FR_Loir' ),
       
       projection_fdloire as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r       
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_fdloire s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_fdloire2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_fdloire
       WHERE emu='FR_Loir' ),
       
       duplicates_aspe_fdloire AS (       
       SELECT f.op_id AS aspe_op_id, r.op_id AS fdloire_ope_id, r.the_geom 
       FROM projection_fdloire2 r
       JOIN   projection_aspe2 f ON st_dwithin(r.the_geom, f.the_geom, 50))
      
       SELECT * FROM  duplicates_aspe_fdloire       
       ) --568 
       
-------------------------------------------------------------
 -- On part de RSA, on ajoute ensuite les données ASPE
 -- il y 19 duplicats mais il y a peu de chances que ce soit les
 -- mêmes tant pis on garde
 -- par contre on dégage de fd_loire toutes les données dupliquées,
 -- à la fois avec ASPE et avec RSA      
-------------------------------------------------------------       
       
 CREATE TABLE france.join_loire_rn AS (     
       WITH projection_aspe as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_aspe s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_aspe2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_aspe
       WHERE emu='FR_Loir' ),
       
              projection_rsa as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_rsa s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_rsa2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_rsa
       WHERE emu='FR_Loir' 
       ),
       
       projection_fdloire as (  
       SELECT r.idsegment, 
       op_id,                          
       the_geom,
       emu,
       st_distance(r.geom,s.the_geom) as distance 
       FROM france.rn r       
       JOIN france.rna ON r.idsegment = rna.idsegment
       JOIN  france.dbeel_station_fdloire s
       ON st_dwithin(r.geom, s.the_geom, 500)
       order by idsegment, distance desc),
       
       projection_fdloire2 AS(
       SELECT distinct on (op_id) op_id, idsegment, the_geom from projection_fdloire
       WHERE emu='FR_Loir' ),
       
       duplicates_aspe_fdloire AS (       
       SELECT f.op_id AS aspe_op_id, r.op_id AS fdloire_ope_id, r.the_geom 
       FROM projection_fdloire2 r
       JOIN   projection_aspe2 f ON st_dwithin(r.the_geom, f.the_geom, 50)),
       
       the_big_union AS (
       SELECT * FROM projection_rsa2 UNION
       SELECT * FROM projection_aspe2 UNION 
       SELECT * FROM projection_fdloire2 WHERE op_id NOT IN (
       SELECT fdloire_ope_id FROM france.dbeel_station_aspe_duplicates_fdloire) AND
       op_id NOT IN (SELECT dfloire_op_id FROM france.dbeel_station_fdloire_duplicates_rsa)
      )
       
       SELECT the_big_union.* FROM the_big_union 
        )  ;  --7191

