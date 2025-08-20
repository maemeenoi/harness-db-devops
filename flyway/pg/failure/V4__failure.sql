-- V4__failure.sql (PostgreSQL)
-- Intentionally fails by re-adding existing column 'status'

ALTER TABLE sales.customer_feedback 
ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';  -- Will fail if already exists
