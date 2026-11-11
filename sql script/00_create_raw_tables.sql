-- 00 create the database and the raw tables
-- every column is text on purpose, because the raw data is messy
-- (dates like TBC, quantities like "3,402 units") and would be rejected by number or date columns
-- the types are changed later, inside each cleaning script

CREATE DATABASE plant_ops;
USE plant_ops;

CREATE TABLE machines (
  machine_id VARCHAR(50), machine_name VARCHAR(100), machine_type VARCHAR(100),
  production_line VARCHAR(50), manufacturer VARCHAR(100), install_date VARCHAR(50), status VARCHAR(50)
);

CREATE TABLE production_runs (
  run_id VARCHAR(50), product VARCHAR(100), line VARCHAR(50), shift VARCHAR(50),
  run_date VARCHAR(50), supervisor VARCHAR(100), planned_qty VARCHAR(50), actual_qty VARCHAR(50),
  rejected_qty VARCHAR(50), start_time VARCHAR(50), end_time VARCHAR(50),
  status VARCHAR(50), unit_cost_ngn VARCHAR(50)
);

CREATE TABLE downtime_log (
  downtime_id VARCHAR(50), machine_id VARCHAR(50), downtime_date VARCHAR(50), reason VARCHAR(100),
  duration VARCHAR(50), reported_by_role VARCHAR(100), action_taken VARCHAR(200), estimated_loss_ngn VARCHAR(50)
);

CREATE TABLE quality_checks (
  check_id VARCHAR(50), run_id VARCHAR(50), check_date VARCHAR(50), inspector VARCHAR(100),
  parameter VARCHAR(100), reading VARCHAR(50), result VARCHAR(50), remarks VARCHAR(200)
);

CREATE TABLE inventory_movements (
  movement_id VARCHAR(50), movement_date VARCHAR(50), material VARCHAR(100), category VARCHAR(50),
  quantity VARCHAR(50), unit VARCHAR(50), movement_type VARCHAR(50), supplier VARCHAR(100),
  unit_price_ngn VARCHAR(50), location VARCHAR(100)
);
