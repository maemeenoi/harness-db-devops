IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'shop') EXEC('CREATE SCHEMA shop');
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id=s.schema_id WHERE t.name='customers' AND s.name='shop')
BEGIN
  CREATE TABLE shop.customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name   NVARCHAR(120) NOT NULL,
    email       NVARCHAR(255) UNIQUE,
    created_at  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END