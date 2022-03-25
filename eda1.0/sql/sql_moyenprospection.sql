select distinct on (cd_libl) cd_libl, op_cd_moyenprospection from operation
inner join codier on cd_id=op_cd_moyenprospection;
