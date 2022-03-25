SELECT t_ouvrage_ouv.ouv_id,exp.fba_valeurnote,t_denivele_den.den_denivele
FROM public.t_ouvrage_ouv
LEFT JOIN  (
SELECT * FROM public.t_franchisbar_fba
		WHERE t_franchisbar_fba.fba_tyn_typenote = 'EXPERTISE'
		AND fba_tax_code='2038')as exp
 ON   t_ouvrage_ouv.ouv_id = exp.fba_ouv_id
LEFT JOIN  public.t_denivele_den   ON t_denivele_den.den_ouv_id=t_ouvrage_ouv.ouv_id



