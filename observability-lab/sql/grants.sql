-- Run this once against the cluster (as master_username) after
-- `terraform apply` finishes. It creates the DB role that the IAM role
-- authenticates as, and grants it write access to specific tables only.
--
-- Usage:
--   psql "host=<cluster_endpoint> dbname=labdb user=labadmin sslmode=require" -f sql/grants.sql

-- 1. Sample tables, standing in for whatever warehouse IT ops actually needs.
CREATE TABLE IF NOT EXISTS printers (
    id SERIAL PRIMARY KEY,
    asset_tag TEXT NOT NULL,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS printer_assignments (
    id SERIAL PRIMARY KEY,
    printer_id INT REFERENCES printers(id),
    assigned_to TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. A role representing the group (this is the Postgres-side counterpart
--    to the AD GroupID / IAM role chain in iam.tf).
CREATE ROLE printer_admins NOLOGIN;

GRANT INSERT, UPDATE, DELETE, SELECT ON printers TO printer_admins;
GRANT INSERT, UPDATE, DELETE, SELECT ON printer_assignments TO printer_admins;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO printer_admins;

-- 3. The actual IAM-authenticating DB user. Its name must exactly match
--    the dbuser in the IAM policy Resource ARN in iam.tf.
--    rds_iam is a built-in Aurora role that enables IAM token auth
--    instead of a static password.
CREATE USER printer_admins_iam;
GRANT rds_iam TO printer_admins_iam;
GRANT printer_admins TO printer_admins_iam;

-- Sanity check
SELECT rolname FROM pg_roles WHERE rolname IN ('printer_admins', 'printer_admins_iam');
