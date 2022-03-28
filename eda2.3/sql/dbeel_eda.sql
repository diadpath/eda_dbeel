-----------------------------
-- LOOKING DATA WITH LAURENT 
-------------------------------
-- Schema base_mai (eda2.2 database)
SET search_path TO base_mai;
select min(date_operation) from base_mai.operation;

-- Schema dbeel (dbeel database)
SET search_path TO dbeel;
SELECT count(*) FROM dbeel.batch WHERE ba_ba_id IS NULL; --33141 (everything is null)