CREATE OR REPLACE VIEW redgate.feedbackauditsummary AS
SELECT auditid, customerid, createdat, source
FROM redgate.feedbackaudit;
