--Cette vue a pour objectif de remonter le décompte du nombre d'anguilles "mesurées" par catégories de taille
--et ce pour chaque opération de pêche électriques connues dans ASPE ou RSA
--Elle est utilisée par le modèle EDA
--Elle présente le détail des résultats, pour chaque classe de taille, par opérations de pêches
--durée sur postgres_local : environ 20s (avec 200 lignes remontées)

CREATE OR REPLACE VIEW dbeel.view_electrofishing_size_new
AS
--first we create the list of size categories
with cate_list as (
 SELECT * FROM (VALUES (0, '0 - error'), (1, '1 - <150'), (2, '2 - [150-300['),
						(3, '3 - [300-450['), (4, '4 - [450-600['), (5, '5 - [600-750['),
					(6,'6 - >=750')) AS t (cat_id,cat_label)
 ),
--the we count the number of eels in each category for each fishing operations
--in this query, when a size category is not met, it isn't retrieve in the 'select'
--this is why we need the cate_list above  
cate_query as(
SELECT 
el.ob_id,
CASE
	WHEN bc.bc_numvalue < 50::double precision THEN '0 - error'::text
	WHEN bc.bc_numvalue >= 50::double precision AND bc.bc_numvalue < 150::double precision THEN '1 - <150'::text
	WHEN bc.bc_numvalue >= 150::double precision AND bc.bc_numvalue < 300::double precision THEN '2 - [150-300['::text
	WHEN bc.bc_numvalue >= 300::double precision AND bc.bc_numvalue < 450::double precision THEN '3 - [300-450['::text
	WHEN bc.bc_numvalue >= 450::double precision AND bc.bc_numvalue < 600::double precision THEN '4 - [450-600['::text
	WHEN bc.bc_numvalue >= 600::double precision AND bc.bc_numvalue < 750::double precision THEN '5 - [600-750['::text
	WHEN bc.bc_numvalue >= 750::double precision THEN '6 - >=750'::text
	ELSE NULL::text
END AS length_class,
count(*) AS nb_meas
FROM dbeel.electrofishing el
--joined with station tables to limit the records only in ASPE and RSA.
--this join statement could be omited when the futur dbeel_france schema would be online
JOIN dbeel.observation_places opl on opl.op_id = el.ob_op_id  and opl.op_gis_layername in ('ASPE','RSA')
--to get list of fishes, working only with batch_level = 2
JOIN dbeel.batch ba ON el.ob_id = ba.ba_ob_id and ba.ba_batch_level=2
--to get size measurement
JOIN dbeel.biological_characteristic bc ON bc.bc_ba_id = ba.ba_id and bc.bc_no_characteristic_type = 39 
GROUP BY (el.ob_id,length_class))
--
--main select
--
SELECT 
e.ob_id, 									--operation id
dp.dp_name,									--provider name
cl.cat_label as length_class,				--label of length_class
coalesce (cq.nb_meas,0) as number			--count in each class
--to work only with ASPE ou RSA stations
from dbeel.observation_places op 
-- getting operations results	
join dbeel.electrofishing e on e.ob_op_id = op.op_id and op.op_gis_layername in ('ASPE','RSA')
-- to get provider name
join dbeel.data_provider dp on dp.dp_id = e.ob_dp_id 
-- to get the full list of size category for each operation
cross join cate_list cl
-- to get the count of eels in each size category, previously calculated
left join cate_query cq on cq.ob_id = e.ob_id and cq.length_class = cl.cat_label

 -- Permissions

ALTER TABLE dbeel.view_electrofishing_size_new OWNER TO postgres;
GRANT ALL ON TABLE dbeel.view_electrofishing_size_new TO postgres;
GRANT SELECT ON TABLE dbeel.view_electrofishing_size_new TO dbeel;         