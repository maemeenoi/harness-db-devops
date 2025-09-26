-- PostgreSQL supports CREATE PROCEDURE (no result), but commonly a set-returning function is used.
-- We'll create a function returning the 10 most recent audits to mirror the SQL Server proc.
CREATE OR REPLACE FUNCTION redgate.get_recent_audits()
RETURNS TABLE (auditid INT, customerid INT, createdat TIMESTAMP, source VARCHAR(50))
LANGUAGE sql
STABLE
AS $$
    SELECT auditid, customerid, createdat, source
    FROM redgate.feedbackaudit
    ORDER BY createdat DESC
    LIMIT 10;
$$;
