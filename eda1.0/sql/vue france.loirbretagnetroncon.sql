DROP VIEW IF EXISTS france.loirebretagnetroncon;
CREATE OR REPLACE VIEW france.loirebretagnetroncon AS 

SELECT * FROM
france.v_loirebretagne_total vlt
JOIN france.troncon2 tron ON tron.id_bdcarthage = vlt."Id_BDCARTHAGE";

select * from france.loirebretagnetroncon limit 10