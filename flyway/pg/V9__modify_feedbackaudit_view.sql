-- Add a comment to the view (demonstrates view modification)
COMMENT ON VIEW redgate.feedbackauditsummary IS 'Summary view of feedback audit data (modified)';

-- Recreate view to ensure it reflects any structural changes
CREATE OR REPLACE VIEW redgate.feedbackauditsummary AS
SELECT auditid, customerid, createdat, source
FROM redgate.feedbackaudit;
