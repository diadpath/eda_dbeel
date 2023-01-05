DELETE FROM rsa.op_epab WHERE epab_zone  = 'lcvlogrami' ;
DELETE FROM rsa.op_epap WHERE epap_zone  = 'lcvlogrami' ;
DELETE FROM rsa.op_iaa WHERE iaa_zone  = 'lcvlogrami' ;
DELETE FROM rsa.op_inv WHERE inv_zone  = 'lcvlogrami' ;
DELETE FROM rsa.op_pcbgb WHERE pcbgb_zone  = 'lcvlogrami' ;
DELETE FROM rsa.op_pcbgp WHERE pcbgp_zone  = 'lcvlogrami' ;
DELETE FROM rsa.anguille_ang WHERE ang_zone  = 'lcvlogrami' ;
DELETE FROM rsa.operation  WHERE op_zone  = 'lcvlogrami' ;
DELETE FROM rsa.station WHERE sta_zone  = 'lcvlogrami' ;


INSERT INTO rsa.station
(sta_id, sta_cod, sta_lib, sta_x93, sta_y93, sta_zone, geom, sta_code,
sta_last_update)
SELECT 
sta_id, 
sta_cod, 
sta_lib,
sta_x93, 
sta_y93, 
'lcvlogrami' AS sta_zone, 
geom, 
sta_code,
CURRENT_DATE AS sta_last_update
FROM rsa_loire.station WHERE 
sta_zone='lcv'; --317

UPDATE rsa.station SET sta_prod_id=11 WHERE sta_zone='lcvlogrami' AND sta_prod_id IS NULL;--317

INSERT INTO rsa.operation
( op_id, op_cod, op_sta_id, op_date, op_typ, op_zone, 
op_last_update)
SELECT 
op_id, op_cod, op_sta_id, op_date, op_typ,
'lcvlogrami' AS op_zone, 
CURRENT_DATE AS op_last_update
FROM rsa_loire.operation WHERE 
op_zone='lcv'; --891

UPDATE rsa.operation SET op_prod_id=11 WHERE op_zone='lcvlogrami' AND op_prod_id IS NULL;--891



INSERT INTO rsa.anguille_ang
(ang_id, ang_op_id, ang_pas, ang_taille, ang_poids, ang_lot,
ang_eff, ang_nlot, ang_zone, ang_last_update)
SELECT
ang_id, ang_op_id, ang_pas, ang_taille, ang_poids, ang_lot, 
ang_eff, ang_nlot, 
'lcvlogrami' AS ang_zone, 
CURRENT_DATE AS ang_last_update
FROM rsa_loire.anguille_ang
WHERE ang_zone='lcv'; --9512


INSERT INTO rsa.op_epab
(epab_id, epab_op_id, epab_npnt, epab_ang, epab_vue, 
epab_zone, 
epab_last_update)
SELECT epab_id, epab_op_id, epab_npnt, epab_ang, epab_vue, 
'lcvlogrami' AS epab_zone,
CURRENT_DATE AS epab_last_update
FROM rsa_loire.op_epab
WHERE epab_zone='lcv'; --0


INSERT INTO rsa.op_iaa
(iaa_id, iaa_op_id, iaa_npnt, iaa_ang, iaa_vue, iaa_zone)
SELECT iaa_id, iaa_op_id, iaa_npnt, iaa_ang, iaa_vue,
'lcvlogrami' AS iaa_zone
FROM rsa_loire.op_iaa
WHERE iaa_zone='lcv'; --864


INSERT INTO rsa.op_inv
(inv_id, inv_op_id, inv_long, inv_larg, inv_npas, inv_p1, inv_p2, inv_p3, 
inv_zone, 
inv_last_update)
SELECT inv_id, inv_op_id, inv_long, inv_larg, inv_npas, inv_p1, inv_p2, inv_p3,
'lcvlogrami' AS inv_zone,
CURRENT_DATE AS inv_last_update
FROM rsa_loire.op_inv
WHERE inv_zone='lcv'
; --0


/*
INSERT INTO rsa.op_pcbgb
(pcbgb_id, pcbgb_op_id, pcbgb_long, pcbgb_larg, pcbgb_npas, pcbgb_p1, pcbgb_p2, pcbgb_p3, pcbgb_zone, pcbgb_last_update)
SELECT 
pcbgb_id, pcbgb_op_id, pcbgb_long, pcbgb_larg, pcbgb_npas, pcbgb_p1,
pcbgb_p2, pcbgb_p3,
pcbgb_zone
FROM rsa_loire.op_pcbgb
WHERE pcbgb_zone='lcv'
;*/ --Marais Poitevin







SELECT * FROM rsa_loire.station 
  WHERE sta_zone  = 'lcvlogrami';




