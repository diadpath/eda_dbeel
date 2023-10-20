-- dbeel.view_silvering source
--19/10/2023
CREATE OR REPLACE VIEW sudoang.view_silvering
AS SELECT op.op_id,
    --locationid, what is it ?
    --country, FR ?
    es.et_establishment_name,
    --,--x ?
    --,--y ?
    e.ob_id,
    e.ob_starting_date,
    vsb.ba_id,
    vsb.length,
    vsb.weight,
    vsb.sex,
    vsb.stage,
    vsb.eye_diam_vert,
    vsb.eye_diam_horiz,
    vsb.length_pect,
    vsb.presence_neuromast,
    vsb.contrast
   FROM dbeel.observation_places op 
     JOIN dbeel.electrofishing e ON op.op_id = e.ob_op_id
     JOIN dbeel.batch b ON e.ob_id = b.ba_ob_id
     JOIN dbeel.view_silvering_bc vsb ON vsb.ba_id = b.ba_id
     JOIN dbeel.data_provider dp ON dp.dp_id = e.ob_dp_id
     JOIN dbeel.establishment es ON es.et_id = dp.dp_et_id
	 where op.op_gis_layername in ('ASPE', 'RSA')

-- Permissions

ALTER TABLE dbeel.view_silvering OWNER TO postgres;
GRANT ALL ON TABLE dbeel.view_silvering TO postgres;
GRANT SELECT ON TABLE dbeel.view_silvering TO dbeel;