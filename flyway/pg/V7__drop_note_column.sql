-- First, drop the view completely to remove dependency on note column
DROP VIEW IF EXISTS redgate.feedbackauditsummary;

-- Now drop the note column from the table
ALTER TABLE redgate.feedbackaudit
DROP COLUMN IF EXISTS note;

-- Recreate the view without the note column
CREATE VIEW redgate.feedbackauditsummary AS
SELECT auditid, customerid, createdat, source
FROM redgate.feedbackaudit;

