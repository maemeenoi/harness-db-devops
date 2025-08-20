-- Creates sales.customer_feedback + summary view

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'sales') EXEC('CREATE SCHEMA sales');

IF NOT EXISTS (
    SELECT * FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'customer_feedback' AND s.name = 'sales'
)
BEGIN
    CREATE TABLE sales.customer_feedback (
        feedback_id     INT IDENTITY(1,1) PRIMARY KEY,
        customer_id     INT NOT NULL,
        rating          INT CHECK (rating BETWEEN 1 AND 5),
        feedback_text   NVARCHAR(MAX),
        submitted_at    DATETIME2 DEFAULT SYSUTCDATETIME(),
        CONSTRAINT fk_customer_feedback_customer FOREIGN KEY (customer_id)
            REFERENCES sales.Customer(CustomerID) ON DELETE CASCADE
    );
END

IF OBJECT_ID('sales.customer_feedback_summary', 'V') IS NOT NULL
    DROP VIEW sales.customer_feedback_summary;

EXEC('CREATE VIEW sales.customer_feedback_summary AS
SELECT
    c.CustomerID,
    c.AccountNumber,
    f.feedback_id,
    f.rating,
    f.feedback_text,
    f.submitted_at
FROM sales.Customer c
LEFT JOIN sales.customer_feedback f ON c.CustomerID = f.customer_id;');