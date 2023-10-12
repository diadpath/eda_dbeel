DROP VIEW IF EXISTS dbeel.view_electrofishing_size_weight_new CASCADE;
CREATE OR REPLACE VIEW  dbeel.view_electrofishing_size_weight_new AS (
--505339 lignes au 16/10
--505288 lignes au 16/10 avec la filtre sur les bornes ]50,1400[
select 
dp.dp_name,
e.ob_id,
bc.bc_id,--attention ici c'est l'id de la mesure de longueur uniquement
bc.bc_ba_id,--ici c'ets l'id du poisson
null as fish_id,--pas de fish_id côté ASPE/RSA, le bc_ba_id doit pouvoir être suffisant
bc.bc_numvalue as length,
bc2.bc_numvalue as weight
from dbeel.observation_places op 
join dbeel.electrofishing e on e.ob_op_id = op.op_id 
join dbeel.batch b on b.ba_ob_id = e.ob_id and b.ba_batch_level = 2
join dbeel.data_provider dp on dp.dp_id = e.ob_dp_id 
--on ne remonte que les poissons avec au moins une mesure de longueur
--mais on accepte les poissons sans mesure de poids
join dbeel.biological_characteristic bc on bc.bc_ba_id = b.ba_id and bc.bc_no_characteristic_type = 39
left join dbeel.biological_characteristic bc2 on bc2.bc_ba_id = b.ba_id and bc2.bc_no_characteristic_type = 42
where op.op_gis_layername in ('ASPE','RSA')
--on filtre sur la taille des poissons 
--(à noter que dans la vue view_electrofishing_size_new, il n'y a pas de filtre sur des valeurs > 1400)
and bc.bc_numvalue>50 
AND bc.bc_numvalue<1400 
)
;

ALTER TABLE dbeel.view_electrofishing_size_weight_new OWNER TO postgres;
GRANT ALL ON TABLE dbeel.view_electrofishing_size_weight_new TO postgres;
GRANT SELECT ON TABLE dbeel.view_electrofishing_size_weight_new TO dbeel;    
