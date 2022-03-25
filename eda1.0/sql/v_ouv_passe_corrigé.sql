--DROP VIEW v_ouv_passe
CREATE OR REPLACE VIEW v_ouv_passe AS 
 SELECT temptable.ouv_abscisse, temptable.ouv_ordonnee, temptable.passe_code, temptable.passe_ouv_id, temptable.passe_typ_code, temptable.passe_datedebut, temptable.passe_datefin, temptable.passe_descr, temptable.typ_code, temptable.typ_libelle, temptable.fba_id, temptable.fba_ouv_id, temptable.fba_tax_code, temptable.fba_valeurnote, temptable.fba_tyn_typenote
   FROM ( SELECT ouv.ouv_abscisse, ouv.ouv_ordonnee, passe.passe_code, passe.passe_ouv_id, passe.passe_typ_code, passe.passe_datedebut, passe.passe_datefin, passe.passe_descr, typ.typ_code, typ.typ_libelle, t_franchisbar_fba.fba_id, t_franchisbar_fba.fba_ouv_id, t_franchisbar_fba.fba_tax_code, t_franchisbar_fba.fba_valeurnote, t_franchisbar_fba.fba_tyn_typenote
           FROM t_ouvrage_ouv ouv
      JOIN t_passe_passe passe ON ouv.ouv_id::text = passe.passe_ouv_id::text
   JOIN tr_typepasse_typ typ ON passe.passe_typ_code::text = typ.typ_code::text
   LEFT JOIN t_franchisbar_fba ON t_franchisbar_fba.fba_ouv_id::text = ouv.ouv_id::text
  WHERE t_franchisbar_fba.fba_tyn_typenote::text = 'EXPERTISE'::text) temptable;

ALTER TABLE v_ouv_passe OWNER TO postgres;
