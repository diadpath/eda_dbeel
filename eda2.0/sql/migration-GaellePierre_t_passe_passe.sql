INSERT INTO t_passe_passe (passe_ouv_id,passe_typ_code,passe_datedebut,passe_type_compl1_code,passe_datedebut_compl1,passe_type_compl2_code,passe_datedebut_compl2,passe_datefin,passe_descr)
	SELECT passe_ouv_id,passe_typ_code,passe_datedebut,'','1900-01-01','','1900-01-01',passe_datefin,passe_descr
	FROM t_passe_passe1;