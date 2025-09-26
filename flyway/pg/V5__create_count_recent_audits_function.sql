CREATE OR REPLACE FUNCTION redgate.count_recent_audits(days INTEGER)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)
    FROM redgate.feedbackaudit
    WHERE createdat > (CURRENT_TIMESTAMP - (days || ' days')::interval);
$$;
