-- A la même période il peut y avoir plusieurs passes, 
-- si une passe est franchissable et l'autre non, on choisi la franchissable

DROP VIEW IF EXISTS  montepomi.dbeel_view_pass CASCADE;
CREATE VIEW montepomi.dbeel_view_pass AS (

WITH 

ordered AS (SELECT dbeel_physical_obstruction_pass_species.*
FROM montepomi.dbeel_physical_obstruction_pass_species
ORDER BY ob_id, species, po_presence_pass DESC) --15 019

SELECT DISTINCT ON (ob_id, species, po_presence_pass) * FROM ordered --14 350
);


-- SELECT * FROM montepomi.dbeel_view_pass 