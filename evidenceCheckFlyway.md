# Evidence Check: Flyway SQL Server Migration

## Migration Evidence Scripts

```sql
-- ==========================================
-- Evidence: SQL Server (Flyway)
-- Purpose: Comprehensive validation of all Flyway migrations
-- ==========================================

-- 0) Context
SELECT
  DB_NAME()     AS CurrentDB,
  SUSER_SNAME() AS ExecutingLogin,
  GETDATE()     AS EvidenceRunTime;

-- ==========================================
-- V1: Schema Creation Evidence
-- ==========================================

-- 1) Schema exists
SELECT
  s.name AS schema_name,
  s.schema_id,
  p.name AS principal_name
FROM sys.schemas s
LEFT JOIN sys.database_principals p ON s.principal_id = p.principal_id
WHERE s.name = 'RedGate';

-- ==========================================
-- V2: Table Creation Evidence
-- ==========================================

-- 2) Table exists with correct structure
SELECT
  s.name AS schema_name,
  t.name AS table_name,
  t.create_date,
  t.modify_date
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'RedGate' AND t.name = 'FeedbackAudit';

-- 3) Table columns
SELECT
  c.column_id,
  c.name AS column_name,
  TYPE_NAME(c.user_type_id) AS data_type,
  c.max_length,
  c.is_nullable,
  c.is_identity,
  dc.definition AS default_definition
FROM sys.columns c
LEFT JOIN sys.default_constraints dc
  ON dc.parent_object_id = c.object_id
 AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAudit')
ORDER BY c.column_id;

-- 4) Primary key constraint
SELECT
  kc.name AS constraint_name,
  c.name AS column_name
FROM sys.key_constraints kc
JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id
  AND kc.unique_index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id
  AND ic.column_id = c.column_id
WHERE kc.parent_object_id = OBJECT_ID('RedGate.FeedbackAudit')
  AND kc.type = 'PK';

-- ==========================================
-- V3: Data Seeding Evidence
-- ==========================================

-- 5) Seeded data exists
SELECT
  COUNT(*) AS total_rows,
  MIN(AuditID) AS min_audit_id,
  MAX(AuditID) AS max_audit_id,
  MIN(CreatedAt) AS earliest_created,
  MAX(CreatedAt) AS latest_created
FROM RedGate.FeedbackAudit;

-- 6) Sample seeded data
SELECT TOP (5) *
FROM RedGate.FeedbackAudit
ORDER BY AuditID;

-- 7) Check for specific seed data (CustomerID 1001)
SELECT COUNT(*) AS seed_data_count
FROM RedGate.FeedbackAudit
WHERE CustomerID = 1001 AND Note = 'Seed row 1';

-- ==========================================
-- V4: View Creation Evidence
-- ==========================================

-- 8) View exists
SELECT
  s.name AS schema_name,
  v.name AS view_name,
  v.create_date,
  v.modify_date
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
WHERE s.name = 'RedGate' AND v.name = 'FeedbackAuditSummary';

-- 9) View columns
SELECT
  c.column_id,
  c.name AS column_name,
  TYPE_NAME(c.user_type_id) AS data_type
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAuditSummary')
ORDER BY c.column_id;

-- 10) Test view query
SELECT COUNT(*) AS view_row_count
FROM RedGate.FeedbackAuditSummary;

-- 11) Sample data from view
SELECT TOP (3) *
FROM RedGate.FeedbackAuditSummary
ORDER BY AuditID DESC;

-- ==========================================
-- V5: Function Creation Evidence
-- ==========================================

-- 12) Function exists
SELECT
  s.name AS schema_name,
  o.name AS function_name,
  o.type_desc,
  o.create_date,
  o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = 'RedGate'
  AND o.name = 'CountRecentAudits'
  AND o.type IN ('FN', 'IF', 'TF');

-- 13) Function parameters
SELECT
  p.parameter_id,
  p.name AS parameter_name,
  TYPE_NAME(p.user_type_id) AS parameter_type
FROM sys.parameters p
WHERE p.object_id = OBJECT_ID('RedGate.CountRecentAudits')
ORDER BY p.parameter_id;

-- 14) Test function
SELECT
  'Function Test - 30 days' AS test_description,
  RedGate.CountRecentAudits(30) AS function_result,
  (SELECT COUNT(*) FROM RedGate.FeedbackAudit
   WHERE CreatedAt > DATEADD(DAY, -30, SYSUTCDATETIME())) AS direct_count;

-- ==========================================
-- V11: Stored Procedure Evidence
-- ==========================================

-- 15) Procedure exists
SELECT
  s.name AS schema_name,
  o.name AS procedure_name,
  o.type_desc,
  o.create_date,
  o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = 'RedGate'
  AND o.name = 'GetRecentAudits'
  AND o.type IN ('P', 'PC');

-- 16) Test procedure execution
EXEC RedGate.GetRecentAudits;

-- ==========================================
-- Column Modifications Evidence (V6, V7)
-- ==========================================

-- 17) Check current column structure after modifications
SELECT
  c.name AS column_name,
  TYPE_NAME(c.user_type_id) AS data_type,
  c.max_length,
  c.is_nullable,
  CASE WHEN c.name = 'Source' THEN 'V6 - Added'
       WHEN c.name = 'Note' THEN 'Should be dropped in V7'
       ELSE 'Original' END AS column_status
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAudit')
ORDER BY c.column_id;

-- 18) Verify Source column exists (V6)
SELECT
  CASE WHEN COL_LENGTH('RedGate.FeedbackAudit','Source') IS NOT NULL
       THEN 'Source column EXISTS (V6 success)'
       ELSE 'Source column MISSING (V6 failed)'
  END AS source_column_status;

-- 19) Verify Note column dropped (V7)
SELECT
  CASE WHEN COL_LENGTH('RedGate.FeedbackAudit','Note') IS NULL
       THEN 'Note column DROPPED (V7 success)'
       ELSE 'Note column EXISTS (V7 failed)'
  END AS note_column_status;

-- ==========================================
-- Schema Modifications Evidence (V8, V9)
-- ==========================================

-- 20) Schema extended properties (V8)
SELECT
  s.name AS schema_name,
  ep.name AS property_name,
  ep.value AS property_value
FROM sys.schemas s
LEFT JOIN sys.extended_properties ep ON ep.major_id = s.schema_id
  AND ep.class = 3 -- Schema level
WHERE s.name = 'RedGate';

-- 21) View modifications (V9)
SELECT
  OBJECT_NAME(object_id) AS view_name,
  definition
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('RedGate.FeedbackAuditSummary');

-- ==========================================
-- Function Modifications Evidence (V10)
-- ==========================================

-- 22) Modified function definition
SELECT
  OBJECT_NAME(object_id) AS function_name,
  definition
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('RedGate.CountRecentAudits');

-- ==========================================
-- Failure Test Evidence (V12)
-- ==========================================

-- 23) Check if failure migration was handled properly
-- This should either show as failed or marked as executed depending on error handling

-- ==========================================
-- Flyway Schema History
-- ==========================================

-- 24) Flyway migration history
SELECT
  installed_rank,
  version,
  description,
  type,
  script,
  checksum,
  installed_by,
  installed_on,
  execution_time,
  success
FROM flyway_schema_history
ORDER BY installed_rank DESC;

-- 25) Migration success summary
SELECT
  COUNT(*) AS total_migrations,
  COUNT(CASE WHEN success = 1 THEN 1 END) AS successful_migrations,
  COUNT(CASE WHEN success = 0 THEN 1 END) AS failed_migrations
FROM flyway_schema_history;

-- 26) Most recent migrations
SELECT TOP (5)
  version,
  description,
  installed_on,
  execution_time,
  CASE WHEN success = 1 THEN 'SUCCESS' ELSE 'FAILED' END AS status
FROM flyway_schema_history
ORDER BY installed_on DESC;
```

## Expected Results Summary

### Migration V1-V2 (Schema & Table):

- RedGate schema should exist
- FeedbackAudit table with 4 columns initially: AuditID (IDENTITY), CustomerID, Note, CreatedAt

### Migration V3 (Data Seeding):

- At least 1 row with CustomerID=1001, Note='Seed row 1'

### Migration V4 (View):

- FeedbackAuditSummary view exists and returns data

### Migration V5 (Function):

- CountRecentAudits function exists and returns correct counts

### Migration V6 (Add Column):

- Source column should be present in FeedbackAudit table

### Migration V7 (Drop Column):

- Note column should be removed from FeedbackAudit table

### Migration V8 (Schema Comment):

- Schema should have extended property for description

### Migration V9 (View Modification):

- View definition should reflect any structural changes

### Migration V10 (Function Modification):

- Function should have updated logic/parameters

### Migration V11 (Procedure):

- GetRecentAudits procedure exists and executes successfully

### Migration V12 (Failure Test):

- Should demonstrate error handling without breaking the migration chain

### Key Validation Points:

- All migrations show as successful in flyway_schema_history
- Database objects exist and function correctly
- Data integrity maintained throughout all changes
- Error handling works appropriately for failure scenarios
