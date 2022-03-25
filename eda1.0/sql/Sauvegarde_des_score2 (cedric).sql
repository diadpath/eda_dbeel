-- depuis R sauvegarde de la table t_franchisbar_pierremarie dans public le schéma par défaut

ALTER TABLE franchisbar_pierremarie SET SCHEMA travail
SELECT * from public.t_franchisbar_fba where fba_tyn_typenote='SCORE2' 
			and fba_id  <11473


--UPDATE public.t_franchisbar_fba SET fba_valeurnote=CAST(CAST(fba_valeurnote AS REAL)-3.5 AS CHARACTER VARYING) where t_franchisbar_fba.fba_tyn_typenote='SCORE2' 
--			and fba_id  <11473



DELETE FROM public.t_franchisbar_fba WHERE fba_tyn_typenote = 'SCORE2'

INSERT INTO public.t_franchisbar_fba (fba_id,fba_ouv_id,fba_tax_code,fba_valeurnote,fba_tyn_typenote,fba_iconf_indiceconfiance,fba_observateur,fba_commentaire) 
SELECT 
CAST(fba_id AS REAL),fba_ouv_id,
CAST(fba_tax_code AS CHARACTER VARYING),
CAST(fba_valeurnote AS CHARACTER VARYING),
fba_tyn_typenote,null,null,CAST(fba_commentaire AS TEXT)
FROM travail.t_franchisbar_pierre


INSERT INTO public.t_franchisbar_fba (fba_id,fba_ouv_id,fba_tax_code,fba_valeurnote,fba_tyn_typenote,fba_iconf_indiceconfiance,fba_observateur,fba_commentaire) 
SELECT 
CAST(fba_id AS REAL),
fba_ouv_id,
CAST(fba_tax_code AS CHARACTER VARYING),
CAST(fba_valeur AS CHARACTER VARYING),
fba_typenote,
null,
null,
null
FROM travail.franchisbar_pierremarie


