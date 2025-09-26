CREATE OR REPLACE VIEW redgate.feedbackauditsummary AS
SELECT auditid, customerid, note, createdat
FROM redgate.feedbackaudit;
