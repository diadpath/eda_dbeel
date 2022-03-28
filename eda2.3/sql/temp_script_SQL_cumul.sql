WITH d
-- les données barrage = table des hauteurs de chute en entrée
 AS (
SELECT
	cdobstecou AS op_id,
	hauteur,
	--hauteurbrute,
	CASE WHEN equipement = 'equipement' THEN TRUE
		ELSE FALSE
	END AS equipement
FROM
	hauteur.haut_fr_4326),
r
-- données réseau
 AS (
SELECT
	rn.idsegment,
	rn.country,
	rna.basin,
	rna.emu,
	geom
FROM
	"france".rn
JOIN "france".rna ON
	rn.idsegment = rna.idsegment),
dr
-- données de projection entre le réseau et les barrages (jointure = snapping)
 AS (
SELECT
	*
FROM
	"france"."join_geobs_rn"),
-- table de jointure entre les codes ROE et les idsegments          
 /*
            joined dams
            */
jd
 AS (
SELECT
	d.op_id ,
	r.idsegment,
	hauteur as heightp,
	--d.hauteurbrute,
	CASE WHEN equipement = TRUE THEN 0
	ELSE d.hauteur END AS heightc, -- hauteur corrigée
	d.equipement,
	r.country,
	r.basin,
	r.emu
FROM
	d
JOIN dr ON
	d.op_id = dr.op_id
JOIN r ON
	r.idsegment = dr.idsegment ),
jds AS(	
SELECT
	idsegment,
	country,
	basin,
	emu,
	1 AS nbdams,
	heightp,
	heightc,
	-- TODO hauteurs brutes coalesce(hauteurbrute,0) as heightb -- hauteur brutes
      case when heightp>1 then heightp else power( heightp,0.8) end as heightp08,
      case when  heightp<1 then  heightp else power( heightp,1.2) end as heightp12,
      case when  heightp<1 then  heightp else power( heightp,1.5) end as heightp15,
      case when  heightp<1 then  heightp else power( heightp,2) end as heightp2,
      case when heightc>1 then heightc else power( heightc,0.8) end as heightc08,
      case when  heightc<1 then  heightc else power( heightc,1.2) end as heightc12,
      case when  heightc<1 then  heightc else power( heightc,1.5) end as heightc15,
      case when  heightc<1 then  heightc else power( heightc,2) end as heightc2
      FROM jd),
final as (
SELECT
	DISTINCT ON (idsegment) 
	idsegment,
	sum(nbdams) AS nbdams,
	--sum(heightb) AS c_heightb,  -- hauteurs brutes non corrigées
	sum(heightp) as c_heightp,  -- hateurs corrigées
	sum(heightp08) as c_heightp08,
	sum(heightp12) as c_heightp12,
	sum(heightp15) as c_heightp15,
	sum(heightp2) as c_heightp2,
        sum(heightc) as c_heightc, -- hauteurs corrigées réduites à zero si passe
	sum(heightc08) as c_heightc08,
	sum(heightc12) as c_heightc12,
	sum(heightc15) as c_heightc15,
	sum(heightc2) as c_heightc2,
      	basin,
	emu FROM
	jds
GROUP BY
	idsegment,
	emu,
	basin)
SELECT * FROM final
