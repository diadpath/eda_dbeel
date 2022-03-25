CREATE OR REPLACE VIEW france.v_loirebretagne_total_troncon AS 
 SELECT v.ouv_id, v.den_denivele, v."Id_BDCARTHAGE", v."ID_final", v."Id_trhyd", v.score2,v.score,v.expertise, tron.id_bdcarthage, 
 tron.nouveau_sens, tron.nouveau_noeud_amont, tron.dmer_amont, tron.nouveau_noeud_aval, tron.dmer_aval, tron.longueur, tron.bassin, 
 tron.noeud_mer, tron.dist_source_max_amont, tron.dist_source_cum_amont, tron.noeud_source_amont, tron.dist_source_max_aval, 
 tron.dist_source_cum_aval, tron.noeud_source_aval
   FROM france.v_loirebretagne_total v
   LEFT JOIN france.troncon2 tron ON tron.id_bdcarthage = v."Id_BDCARTHAGE";

ALTER TABLE france.jointure OWNER TO postgres;

Select * from france.v_loirebretagne_total_troncon  limit 10