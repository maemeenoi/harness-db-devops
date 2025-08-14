DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema='shop' AND table_name='customers' AND column_name='status') THEN
    ALTER TABLE shop.customers ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active';
  END IF;
END$$;