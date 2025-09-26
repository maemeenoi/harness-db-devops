CREATE OR REPLACE FUNCTION redgate.count_recent_audits(days INTEGER)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    -- Modified to count only rows with a non-null source (demonstrates function change)
    SELECT COUNT(*)
    FROM redgate.feedbackaudit
    WHERE createdat > (CURRENT_TIMESTAMP - (days || ' days')::interval)
      AND (source IS NOT NULL);
$$;
