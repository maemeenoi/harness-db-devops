-- Schema present
SELECT name FROM sys.schemas WHERE name='RedGateSchema2';

-- Table & data
SELECT TOP 5 \* FROM RedGateSchema2.FeedbackAudit ORDER BY AuditID DESC;

-- View
SELECT OBJECT_ID(N'RedGateSchema2.FeedbackAuditSummary','V') AS ViewId;

-- Proc & function
SELECT OBJECT_ID(N'RedGateSchema2.GetRecentAudits','P') AS ProcId;
SELECT OBJECT_ID(N'RedGateSchema2.CountRecentAudits','FN') AS FuncId;

-- History
SELECT \* FROM flyway_schema_history_rg2 ORDER BY installed_on DESC;
