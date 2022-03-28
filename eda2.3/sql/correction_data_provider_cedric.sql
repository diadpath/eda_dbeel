/*
Dropping dependent constrainst
*/
begin;
alter table  dbeel.gear_fishing drop constraint fk_dp;
alter table  dbeel.migration_monitoring drop constraint fk_dp;
alter table  dbeel.ecological_status drop constraint fk_dp;
alter table  dbeel.habitat_loss drop constraint fk_dp;
alter table  dbeel.stocking drop constraint fk_dp;
alter table  dbeel.predation drop constraint fk_dp;
alter table  dbeel.fishery drop constraint fk_dp;
alter table  dbeel.wildlife drop constraint fk_dp;
alter table  dbeel.obstruction drop constraint fk_dp;
alter table  dbeel.physical_obstruction drop constraint fk_dp;
alter table  dbeel.chemical_obstruction drop constraint fk_dp;
alter table  dbeel.migration drop constraint fk_dp;
alter table  dbeel.maturation drop constraint fk_dp;
alter table  dbeel.growth  drop constraint fk_dp;
alter table  dbeel.mortality drop constraint fk_dp;
alter table  dbeel.differentiation drop constraint fk_dp;
alter table  dbeel.electrofishing drop constraint fk_dp;
alter table  dbeel.observations drop constraint fk_dp;
ALTER TABLE sudoang.dbeel_physical_obstruction drop constraint fk_dp;

-- drop primary key
alter table dbeel.data_provider drop constraint data_provider_pkey;
update sudoang.dbeel_physical_obstruction set ob_dp_id = 22 where ob_dp_id=23; --80324
--Manual edition of the table


-- correct number for Pierre
update dbeel.data_provider set dp_id = 22 where dp_id = 23;
update dbeel.data_provider set dp_id = 23 where dp_id = 24;
update dbeel.data_provider set dp_id = 24 where dp_id = 25;
update dbeel.data_provider set dp_id = 25 where dp_id = 26;


alter table dbeel.data_provider ADD constraint data_provider_pkey primary key(dp_id);
ALTER TABLE  dbeel.gear_fishing   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.migration_monitoring   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.ecological_status   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.habitat_loss   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.stocking   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.predation   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.fishery   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.wildlife   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.obstruction   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.physical_obstruction   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.chemical_obstruction   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.migration   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.maturation   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.growth   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.mortality   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.differentiation   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE  dbeel.electrofishing   ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
alter table  dbeel.observations  ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE sudoang.dbeel_physical_obstruction  ADD CONSTRAINT fk_dp FOREIGN KEY (ob_dp_id) REFERENCES dbeel.data_provider (dp_id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE RESTRICT;

COMMIT;


      