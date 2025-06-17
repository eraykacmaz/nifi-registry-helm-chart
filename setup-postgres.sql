-- PostgreSQL setup for NiFi Registry
-- Run this script as postgres superuser

-- Create database
CREATE DATABASE nifi_registry;

-- Create user
CREATE USER nifi_user WITH PASSWORD 'nifi_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE nifi_registry TO nifi_user;

-- Connect to the nifi_registry database and grant schema privileges
\c nifi_registry;
GRANT ALL ON SCHEMA public TO nifi_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nifi_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nifi_user;

-- Verify setup
\l nifi_registry
\du nifi_user 