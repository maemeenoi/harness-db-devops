-- V2__schema.sql (PostgreSQL)
-- Adds 'status' column to sales.customer_feedback if not exists

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'sales' AND table_name = 'customer_feedback' AND column_name = 'status'
  ) THEN
    ALTER TABLE sales.customer_feedback 
    ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';
  END IF;
END$$;