DROP VIEW IF EXISTS montepomi.dbeel_view_score CASCADE;
CREATE VIEW montepomi.dbeel_view_score AS (
with
ordered as( 
SELECT * FROM montepomi.dbeel_physical_obstruction_score_species
order by ob_id, species, source_note desc -- we take ICE then bdoe
)
select distinct on (ob_id, species, source_note) * from ordered
); --11341
