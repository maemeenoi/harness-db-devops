-- First, update the view to remove the note column reference
CREATE OR REPLACE VIEW redgate.feedbackauditsummary AS
SELECT auditid, customerid, createdat, source
FROM redgate.feedbackaudit;

-- Now drop the note column from the table
ALTER TABLE redgate.feedbackaudit
DROP COLUMN IF EXISTS note;
