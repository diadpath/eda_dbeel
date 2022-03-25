select distinct on (op_cd_objectifpeche) op_cd_objectifpeche, cd_libl from operation
inner join codier on cd_id=op_cd_objectifpeche;
