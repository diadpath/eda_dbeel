alter table rsa.station add column sta_last_update date;
update rsa.station set sta_last_update='15/01/2015';

CREATE OR REPLACE FUNCTION rsa.update_sta_last_update()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.sta_last_update = now()::date;
    RETURN NEW;	
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_sta_time ON rsa.station;
CREATE TRIGGER update_sta_time BEFORE INSERT OR UPDATE ON rsa.station FOR EACH ROW EXECUTE PROCEDURE  rsa.update_sta_last_update();
-------------------------------------------------------------------

alter table rsa.operation add column op_last_update date;
update rsa.operation set op_last_update='15/01/2015';

CREATE OR REPLACE FUNCTION rsa.update_op_last_update()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.op_last_update = now()::date;
    RETURN NEW;	
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_op_time ON rsa.operation;
CREATE TRIGGER update_op_time BEFORE INSERT OR UPDATE ON rsa.operation FOR EACH ROW EXECUTE PROCEDURE  rsa.update_op_last_update();
----------------------------------------------------------
-------------------------------------------------------------------

alter table rsa.op_epab add column epab_last_update date;
update rsa.op_epab set epab_last_update='15/01/2015';

CREATE OR REPLACE FUNCTION rsa.update_epab_last_update()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.epab_last_update = now()::date;
    RETURN NEW;	
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_epab_time ON rsa.op_epab;
CREATE TRIGGER  update_epab_time  BEFORE INSERT OR UPDATE ON rsa.op_epab FOR EACH ROW EXECUTE PROCEDURE  rsa.update_epab_last_update();
----------------------------------------------------------
alter table rsa.op_epap add column epap_last_update date;
update rsa.op_epap set epap_last_update='15/01/2015';

CREATE OR REPLACE FUNCTION rsa.update_epap_last_update()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.epap_last_update = now()::date;
    RETURN NEW;	
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_epap_time ON rsa.op_epap;
CREATE TRIGGER  update_epap_time  BEFORE INSERT OR UPDATE ON rsa.op_epap FOR EACH ROW EXECUTE PROCEDURE  rsa.update_epap_last_update();
----------------------------------------------------------
alter table rsa.op_inv add column inv_last_update date;
update rsa.op_inv set inv_last_update='15/01/2015';

CREATE OR REPLACE FUNCTION rsa.update_inv_last_update()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.inv_last_update = now()::date;
    RETURN NEW;	
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_inv_time ON rsa.op_inv;
CREATE TRIGGER  update_inv_time  BEFORE INSERT OR UPDATE ON rsa.op_inv FOR EACH ROW EXECUTE PROCEDURE  rsa.update_inv_last_update();
----------------------------------------------------------
alter table rsa.op_pcbgb add column pcbgb_last_update date;
update rsa.op_pcbgb set pcbgb_last_update='15/01/2015';

CREATE OR REPLACE FUNCTION rsa.update_pcbgb_last_update()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.pcbgb_last_update = now()::date;
    RETURN NEW;	
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_pcbgb_time ON rsa.op_pcbgb;
CREATE TRIGGER  update_pcbgb_time  BEFORE INSERT OR UPDATE ON rsa.op_pcbgb FOR EACH ROW EXECUTE PROCEDURE  rsa.update_pcbgb_last_update();
---------------------------
alter table rsa.op_pcbgp add column pcbgp_last_update date;
update rsa.op_pcbgp set pcbgp_last_update='15/01/2015';

CREATE OR REPLACE FUNCTION rsa.update_pcbgp_last_update()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.pcbgp_last_update = now()::date;
    RETURN NEW;	
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_pcbgp_time ON rsa.op_pcbgp;
CREATE TRIGGER  update_pcbgp_time  BEFORE INSERT OR UPDATE ON rsa.op_pcbgp FOR EACH ROW EXECUTE PROCEDURE  rsa.update_pcbgp_last_update();

---------------------------
alter table rsa.anguille_ang add column ang_last_update date;
update rsa.anguille_ang set ang_last_update='15/01/2015';

CREATE OR REPLACE FUNCTION rsa.update_ang_last_update()	
RETURNS TRIGGER AS $$
BEGIN
    NEW.ang_last_update = now()::date;
    RETURN NEW;	
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_ang_time ON rsa.op_pcbgp;
CREATE TRIGGER  update_ang_time  BEFORE INSERT OR UPDATE ON rsa.anguille_ang  FOR EACH ROW EXECUTE PROCEDURE  rsa.update_ang_last_update();	

