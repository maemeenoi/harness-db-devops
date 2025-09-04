# Evidence Check: Liquibase SQL Server Migration

## Data Seed Evidence

```sql
-- ==========================================
-- Evidence: SQL Server (data-seed)
-- Changelog: liquibase/sql/data-seed/changelog.xml
-- Purpose: Verify inserted seed rows
-- ==========================================

-- 0) Context
SELECT
  DB_NAME()     AS CurrentDB,
  SUSER_SNAME() AS ExecutingLogin;

-- 1) Table exists
SELECT s.name AS schema_name, t.name AS table_name, t.create_date, t.modify_date
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'RedGate' AND t.name = 'FeedbackAudit';

-- 2) Column inventory
SELECT
  c.column_id,
  c.name                AS column_name,
  TYPE_NAME(c.user_type_id) AS data_type,
  c.max_length,
  c.is_nullable,
  dc.definition         AS default_definition
FROM sys.columns c
LEFT JOIN sys.default_constraints dc
  ON dc.parent_object_id = c.object_id
 AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAudit')
ORDER BY c.column_id;

-- 3) Seed row count (overall)
SELECT COUNT(*) AS total_rows
FROM RedGate.FeedbackAudit;

-- 4) Seed sample rows (most recent first)
SELECT TOP (10) *
FROM RedGate.FeedbackAudit
ORDER BY AuditID DESC;

-- 5) Check for specific seeded values from changelog
--    Looking for CustomerID 30001, 30002 and Notes 'seed row one', 'seed row two'
SELECT COUNT(*) AS rows_for_30001_30002
FROM RedGate.FeedbackAudit
WHERE CustomerID IN (30001, 30002);

SELECT COUNT(*) AS rows_with_seed_notes
FROM RedGate.FeedbackAudit
WHERE Note IN ('seed row one', 'seed row two');

-- 6) Verify exact seed data matches
SELECT
  CustomerID,
  Note,
  CreatedAt,
  CASE
    WHEN CustomerID = 30001 AND Note = 'seed row one' THEN 'MATCH_ROW_1'
    WHEN CustomerID = 30002 AND Note = 'seed row two' THEN 'MATCH_ROW_2'
    ELSE 'OTHER_ROW'
  END AS seed_match_status
FROM RedGate.FeedbackAudit
WHERE CustomerID IN (30001, 30002)
ORDER BY AuditID;

-- 7) CreatedAt default applied? (should never be NULL)
SELECT
  SUM(CASE WHEN CreatedAt IS NULL THEN 1 ELSE 0 END) AS null_created_at,
  MIN(CreatedAt) AS oldest_created_at,
  MAX(CreatedAt) AS newest_created_at
FROM RedGate.FeedbackAudit;

-- 8) Liquibase history for this folder
SELECT
  ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE
FROM dbo.DATABASECHANGELOG
WHERE FILENAME LIKE '%/liquibase/sql/data-seed/%'
ORDER BY DATEEXECUTED DESC;

-- 9) Liquibase lock state (should be unlocked)
SELECT * FROM dbo.DATABASECHANGELOGLOCK;
```

## Expected Results

### Successful Migration Should Show:

1. **Schema and Table**: RedGate.FeedbackAudit exists
2. **Columns**: AuditID (BIGINT IDENTITY), CustomerID (INT), Note (VARCHAR), CreatedAt (DATETIMEOFFSET)
3. **Seed Data**:
   - At least 2 rows total
   - CustomerID 30001 with Note 'seed row one'
   - CustomerID 30002 with Note 'seed row two'
4. **Timestamps**: All CreatedAt values populated (no NULLs)
5. **Liquibase**: Changeset VSQL3-seed-feedback_audit executed successfully

### Key Verification Points:

- `rows_for_30001_30002` should return 2
- `rows_with_seed_notes` should return 2
- `seed_match_status` should show MATCH_ROW_1 and MATCH_ROW_2
- `null_created_at` should be 0

## View Evidence

```sql
-- ==========================================
-- Evidence: SQL Server (view)
-- Changelog: liquibase/sql/view/changelog.xml
-- Purpose: Verify view creation - FeedbackAuditSummary
-- ==========================================

-- 0) Context
SELECT
  DB_NAME()     AS CurrentDB,
  SUSER_SNAME() AS ExecutingLogin;

-- 1) View exists
SELECT
  s.name AS schema_name,
  v.name AS view_name,
  v.create_date,
  v.modify_date
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
WHERE s.name = 'RedGate' AND v.name = 'FeedbackAuditSummary';

-- 2) View definition
SELECT
  OBJECT_NAME(object_id) AS view_name,
  definition
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('RedGate.FeedbackAuditSummary');

-- 3) View columns
SELECT
  c.column_id,
  c.name AS column_name,
  TYPE_NAME(c.user_type_id) AS data_type,
  c.max_length,
  c.is_nullable
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAuditSummary')
ORDER BY c.column_id;

-- 4) Test view query (should return data if base table has data)
SELECT COUNT(*) AS view_row_count
FROM RedGate.FeedbackAuditSummary;

-- 5) Sample data from view
SELECT TOP (5) *
FROM RedGate.FeedbackAuditSummary
ORDER BY AuditID DESC;

-- 6) Verify view selects correct columns (AuditID, CustomerID, CreatedAt)
SELECT
  COLUMN_NAME,
  ORDINAL_POSITION
FROM INFORMATION_SCHEMA.VIEW_COLUMN_USAGE vcu
JOIN INFORMATION_SCHEMA.COLUMNS c ON c.TABLE_NAME = vcu.VIEW_NAME
  AND c.TABLE_SCHEMA = vcu.VIEW_SCHEMA
WHERE vcu.VIEW_SCHEMA = 'RedGate'
  AND vcu.VIEW_NAME = 'FeedbackAuditSummary'
ORDER BY c.ORDINAL_POSITION;

-- 7) Verify view data matches base table data
SELECT
  'Base Table' AS source,
  COUNT(*) AS row_count,
  MIN(AuditID) AS min_audit_id,
  MAX(AuditID) AS max_audit_id
FROM RedGate.FeedbackAudit
UNION ALL
SELECT
  'View' AS source,
  COUNT(*) AS row_count,
  MIN(AuditID) AS min_audit_id,
  MAX(AuditID) AS max_audit_id
FROM RedGate.FeedbackAuditSummary;

-- 8) Liquibase history for view folder
SELECT
  ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE
FROM dbo.DATABASECHANGELOG
WHERE FILENAME LIKE '%/liquibase/sql/view/%'
ORDER BY DATEEXECUTED DESC;

-- 9) Liquibase lock state (should be unlocked)
SELECT * FROM dbo.DATABASECHANGELOGLOCK;
```

### View Expected Results:

1. **View Exists**: RedGate.FeedbackAuditSummary should be present
2. **View Columns**: Should have exactly 3 columns - AuditID, CustomerID, CreatedAt
3. **View Data**: Row count should match base table RedGate.FeedbackAudit
4. **View Definition**: Should reference RedGate.FeedbackAudit table
5. **Liquibase**: Both changesets executed successfully:
   - `VSQL4-create-view-FeedbackAuditSummary` (drop if exists)
   - `VSQL4-create-view-FeedbackAuditSummary-create` (create view)

### Key View Verification Points:

- View exists in RedGate schema
- View has 3 columns: AuditID, CustomerID, CreatedAt (Note column is excluded)
- View row count matches base table row count
- View data consistency with base table

## Function Evidence

```sql
-- ==========================================
-- Evidence: SQL Server (function)
-- Changelog: liquibase/sql/function/changelog.xml
-- Purpose: Verify function creation - count_recent_audits
-- ==========================================

-- 0) Context
SELECT
  DB_NAME()     AS CurrentDB,
  SUSER_SNAME() AS ExecutingLogin;

-- 1) Function exists
SELECT
  s.name AS schema_name,
  o.name AS function_name,
  o.type_desc,
  o.create_date,
  o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = 'RedGate'
  AND o.name = 'count_recent_audits'
  AND o.type IN ('FN', 'IF', 'TF');

-- 2) Function definition
SELECT
  OBJECT_NAME(object_id) AS function_name,
  definition
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('RedGate.count_recent_audits');

-- 3) Function parameters
SELECT
  p.parameter_id,
  p.name AS parameter_name,
  TYPE_NAME(p.user_type_id) AS parameter_type,
  p.max_length,
  p.is_output
FROM sys.parameters p
WHERE p.object_id = OBJECT_ID('RedGate.count_recent_audits')
ORDER BY p.parameter_id;

-- 4) Test function with different day ranges
-- Test 1: Recent 7 days
SELECT
  'Last 7 days' AS test_period,
  RedGate.count_recent_audits(7) AS function_result,
  (SELECT COUNT(*)
   FROM RedGate.FeedbackAudit
   WHERE CreatedAt > DATEADD(DAY, -7, SYSDATETIMEOFFSET())) AS direct_count;

-- Test 2: Recent 30 days
SELECT
  'Last 30 days' AS test_period,
  RedGate.count_recent_audits(30) AS function_result,
  (SELECT COUNT(*)
   FROM RedGate.FeedbackAudit
   WHERE CreatedAt > DATEADD(DAY, -30, SYSDATETIMEOFFSET())) AS direct_count;

-- Test 3: Recent 1 day
SELECT
  'Last 1 day' AS test_period,
  RedGate.count_recent_audits(1) AS function_result,
  (SELECT COUNT(*)
   FROM RedGate.FeedbackAudit
   WHERE CreatedAt > DATEADD(DAY, -1, SYSDATETIMEOFFSET())) AS direct_count;

-- Test 4: Recent 365 days (should include all data)
SELECT
  'Last 365 days' AS test_period,
  RedGate.count_recent_audits(365) AS function_result,
  (SELECT COUNT(*) FROM RedGate.FeedbackAudit) AS total_rows;

-- 5) Verify function handles edge cases
-- Test with 0 days (should return 0 or very recent records)
SELECT
  'Today only (0 days)' AS test_period,
  RedGate.count_recent_audits(0) AS function_result;

-- 6) Sample data showing CreatedAt distribution
SELECT
  CAST(CreatedAt AS DATE) AS audit_date,
  COUNT(*) AS records_per_day
FROM RedGate.FeedbackAudit
GROUP BY CAST(CreatedAt AS DATE)
ORDER BY audit_date DESC;

-- 7) Liquibase history for function folder
SELECT
  ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE
FROM dbo.DATABASECHANGELOG
WHERE FILENAME LIKE '%/liquibase/sql/function/%'
ORDER BY DATEEXECUTED DESC;

-- 8) Liquibase lock state (should be unlocked)
SELECT * FROM dbo.DATABASECHANGELOGLOCK;
```

### Function Expected Results:

1. **Function Exists**: RedGate.count_recent_audits should be present
2. **Function Type**: Should be a scalar function (type 'FN')
3. **Parameters**: Should have one parameter @p_days of type INT
4. **Function Logic**: Function result should match direct count queries
5. **Return Type**: Should return INT values
6. **Liquibase**: Both changesets executed successfully:
   - `VSQL5-drop-func-count_recent_audits` (drop if exists)
   - `VSQL5-create-func-count_recent_audits` (create function)

### Key Function Verification Points:

- Function exists in RedGate schema
- Function accepts @p_days INT parameter
- Function returns correct count for different day ranges
- Function result matches direct SQL query results
- Function handles edge cases (0 days, large day ranges)
- Function uses correct date arithmetic with DATEADD and SYSDATETIMEOFFSET
