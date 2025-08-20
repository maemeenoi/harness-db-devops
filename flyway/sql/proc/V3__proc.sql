-- Create a stored procedure that joins customer_feedback with core AW tables

IF OBJECT_ID('sales.GetRecentFeedbackByRegion', 'P') IS NOT NULL
    DROP PROCEDURE sales.GetRecentFeedbackByRegion;
GO

CREATE PROCEDURE sales.GetRecentFeedbackByRegion
AS
BEGIN
    SELECT TOP 10
        c.CustomerID,
        c.TerritoryID,
        f.rating,
        f.feedback_text,
        f.submitted_at
    FROM sales.Customer c
    JOIN sales.customer_feedback f ON c.CustomerID = f.customer_id
    WHERE f.submitted_at > DATEADD(day, -30, GETUTCDATE())
    ORDER BY f.submitted_at DESC;
END;
GO