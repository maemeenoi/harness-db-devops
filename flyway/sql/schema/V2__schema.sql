-- Adds 'status' column to customer_feedback (safe re-run)

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE Name = N'status' AND Object_ID = Object_ID(N'sales.customer_feedback')
)
BEGIN
    ALTER TABLE sales.customer_feedback ADD status VARCHAR(20) NOT NULL DEFAULT 'active';
END