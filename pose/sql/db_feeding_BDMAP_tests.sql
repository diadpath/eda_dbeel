-- pb dans lotpeche 'ANG' présente alors que pas dans optaxon
SELECT * FROM onema.lotpeche_onema WHERE fk_batch_id ISNULL ORDER BY op_id;
		
SELECT DISTINCT lo_cd_codeestimpoids, lo_cd_type, count(batch_id)   FROM onema.lotpeche_onema GROUP BY lo_cd_codeestimpoids, lo_cd_type   ORDER BY lo_cd_codeestimpoids 
--> 752

SELECT DISTINCT  lo_cd_type, cd_libl, count(batch_id)  FROM onema.lotpeche_onema, onema.codier_onema WHERE lo_cd_type=cd_id  GROUP BY lo_cd_type, cd_libl;
SELECT DISTINCT  lo_cd_codeestimpoids, cd_libl, count(batch_id)  FROM onema.lotpeche_onema, onema.codier_onema WHERE lo_cd_codeestimpoids=cd_id  GROUP BY lo_cd_codeestimpoids, cd_libl;

SELECT lo_taillemin, lo_taillemax FROM onema.lotpeche_onema WHERE lo_cd_type=1061 ORDER BY lo_taillemin;
SELECT * FROM onema.lotpeche_onema WHERE (lo_cd_type = 1059 OR lo_cd_type =1060 OR lo_cd_type=1061) ORDER BY lo_poids;

SELECT lotpeche_onema.fk_observation_id, lo_cd_type, * FROM  onema.lotpeche_onema, onema.mensurationindiv_onema WHERE  (lo_cd_type = 1061 OR  lo_cd_type = 1063) AND lotpeche_onema.fk_observation_id='01189a0c-2619-4ffe-9583-cb5bcce42e96'  AND mensurationindiv_onema.fk_batch_id = lotpeche_onema.batch_id ORDER BY lotpeche_onema.fk_observation_id;

SELECT lotpeche_onema.fk_observation_id, lo_cd_type, * FROM  onema.lotpeche_onema WHERE  (lo_cd_type = 1061 OR  lo_cd_type = 1063) AND lotpeche_onema.fk_observation_id='01189a0c-2619-4ffe-9583-cb5bcce42e96'  ORDER BY lotpeche_onema.fk_observation_id;


SELECT (lot_l.quantity - lot_s.quantity) AS delta, *
FROM
	(SELECT * FROM  onema.lotpeche_onema WHERE  (lo_cd_type = 1061)) AS lot_l
	FULL OUTER JOIN
	(SELECT* FROM  onema.lotpeche_onema WHERE  (lo_cd_type = 1063)) AS lot_s
	USING (fk_observation_id, lo_code) ORDER BY lot_l.fk_observation_id

(SELECT lotpeche_onema.fk_observation_id, lo_cd_type, * FROM  onema.lotpeche_onema WHERE  (lo_cd_type = 1063)) AS lot_s
 AND mensurationindiv_onema.fk_batch_id = lotpeche_onema.batch_id
 lo_cd_type = 1062 AND 
lo_cd_type nb	lot

	1059	9465		G
	1060	2022		I
	1061	127		L
	1062	161433	N
	1063	128		S
