INSERT INTO t_denivele_den (den_ouv_id, den_date, den_denivele, den_debit)
	SELECT den_ouv_id, den_date, den_denivele, den_debit
	FROM t_denivele_den1;