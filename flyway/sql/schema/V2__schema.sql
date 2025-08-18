IF COL_LENGTH('shop.customers', 'status') IS NULL
  ALTER TABLE shop.customers ADD status NVARCHAR(20) NOT NULL DEFAULT 'active';