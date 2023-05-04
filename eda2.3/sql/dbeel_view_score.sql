DROP MATERIALIZED VIEW IF EXISTS montepomi.view_score CASCADE;
CREATE MATERIALIZED VIEW montepomi.view_score AS (
with
ordered as( dbeel_physical_osbtruction_score_species
SELECT * from dbeel_physical_osbtruction_score_species
order by ob_id, species, source_note desc -- we take ICE then bdoe
)
select distinct on (ob_id, species, source_note) * from ordered
);
