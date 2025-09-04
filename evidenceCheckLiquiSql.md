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

## Stored Procedure Evidence

```sql
-- ==========================================
-- Evidence: SQL Server (stored procedure)
-- Changelog: liquibase/sql/proc/changelog.xml
-- Purpose: Verify stored procedure creation - get_recent_audits
-- ==========================================

-- 0) Context
SELECT
  DB_NAME()     AS CurrentDB,
  SUSER_SNAME() AS ExecutingLogin;

-- 1) Procedure exists
SELECT
  s.name AS schema_name,
  o.name AS procedure_name,
  o.type_desc,
  o.create_date,
  o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = 'RedGate'
  AND o.name = 'get_recent_audits'
  AND o.type IN ('P', 'PC');

-- 2) Procedure definition
SELECT
  OBJECT_NAME(object_id) AS procedure_name,
  definition
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('RedGate.get_recent_audits');

-- 3) Procedure parameters
SELECT
  p.parameter_id,
  p.name AS parameter_name,
  TYPE_NAME(p.user_type_id) AS parameter_type,
  p.max_length,
  p.has_default_value,
  p.default_value
FROM sys.parameters p
WHERE p.object_id = OBJECT_ID('RedGate.get_recent_audits')
ORDER BY p.parameter_id;

-- 4) Test procedure execution with different parameters
-- Test 1: Recent 7 days (no customer filter)
EXEC RedGate.get_recent_audits @p_days = 7;

-- Test 2: Recent 30 days (no customer filter)
EXEC RedGate.get_recent_audits @p_days = 30;

-- Test 3: Recent 7 days with customer filter
EXEC RedGate.get_recent_audits @p_days = 7, @p_min_customer_id = 30000;

-- Test 4: Recent 1 day with customer filter
EXEC RedGate.get_recent_audits @p_days = 1, @p_min_customer_id = 30001;

-- Test 5: Large day range (should return all data)
EXEC RedGate.get_recent_audits @p_days = 365;

-- 5) Verify procedure results match expected direct queries
-- Compare procedure results with direct SQL for 7 days
SELECT 'Direct Query - 7 days' AS source, COUNT(*) AS row_count
FROM RedGate.FeedbackAudit
WHERE CreatedAt > DATEADD(DAY, -7, SYSDATETIMEOFFSET());

-- Compare procedure results with direct SQL for 7 days + customer filter
SELECT 'Direct Query - 7 days + customer >= 30000' AS source, COUNT(*) AS row_count
FROM RedGate.FeedbackAudit
WHERE CreatedAt > DATEADD(DAY, -7, SYSDATETIMEOFFSET())
  AND CustomerID >= 30000;

-- 6) Test procedure parameter validation
-- Test with NULL customer filter (should work)
EXEC RedGate.get_recent_audits @p_days = 7, @p_min_customer_id = NULL;

-- Test with 0 days
EXEC RedGate.get_recent_audits @p_days = 0;

-- 7) Sample data showing what procedure should return
SELECT
  AuditID,
  CustomerID,
  Note,
  CreatedAt,
  DATEDIFF(DAY, CreatedAt, SYSDATETIMEOFFSET()) AS days_old
FROM RedGate.FeedbackAudit
ORDER BY CreatedAt DESC, AuditID DESC;

-- 8) Liquibase history for procedure folder
SELECT
  ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE
FROM dbo.DATABASECHANGELOG
WHERE FILENAME LIKE '%/liquibase/sql/proc/%'
ORDER BY DATEEXECUTED DESC;

-- 9) Liquibase lock state (should be unlocked)
SELECT * FROM dbo.DATABASECHANGELOGLOCK;
```

### Stored Procedure Expected Results:

1. **Procedure Exists**: RedGate.get_recent_audits should be present
2. **Procedure Type**: Should be a stored procedure (type 'P')
3. **Parameters**: Should have two parameters:
   - @p_days INT (required)
   - @p_min_customer_id INT (optional, default NULL)
4. **Procedure Logic**: Should return filtered audit records based on:
   - CreatedAt within specified days
   - Optional CustomerID filtering
5. **Result Set**: Should return AuditID, CustomerID, Note, CreatedAt columns
6. **Liquibase**: Both changesets executed successfully:
   - `VSQL6-drop-proc-get_recent_audits` (drop if exists)
   - `VSQL6-create-proc-get_recent_audits` (create procedure)

### Key Procedure Verification Points:

- Procedure exists in RedGate schema
- Procedure accepts correct parameters (@p_days INT, @p_min_customer_id INT = NULL)
- Procedure returns correct columns and data types
- Procedure filters by date range correctly using DATEADD
- Procedure handles optional customer filtering (NULL vs specific values)
- Procedure results ordered by CreatedAt DESC, AuditID DESC
- Procedure handles edge cases (0 days, NULL customer filter)

## Drop Column Evidence

```sql
-- ==========================================
-- Evidence: SQL Server (drop-column)
-- Changelog: liquibase/sql/drop-column/changelog.xml
-- Purpose: Verify column drop and view updates
-- ==========================================

-- 0) Context
SELECT
  DB_NAME()     AS CurrentDB,
  SUSER_SNAME() AS ExecutingLogin;

-- 1) Table structure BEFORE and AFTER column drop
-- Check current table columns
SELECT
  c.column_id,
  c.name AS column_name,
  TYPE_NAME(c.user_type_id) AS data_type,
  c.max_length,
  c.is_nullable,
  dc.definition AS default_definition
FROM sys.columns c
LEFT JOIN sys.default_constraints dc
  ON dc.parent_object_id = c.object_id
 AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAudit')
ORDER BY c.column_id;

-- 2) Verify Note column is gone
SELECT
  CASE WHEN COL_LENGTH('RedGate.FeedbackAudit','Note') IS NULL
       THEN 'COLUMN DROPPED (SUCCESS)'
       ELSE 'COLUMN STILL EXISTS (FAILED)'
  END AS note_column_status;

-- 3) Expected columns after drop (should be 3 columns only)
SELECT COUNT(*) AS total_columns_remaining
FROM sys.columns
WHERE object_id = OBJECT_ID('RedGate.FeedbackAudit');

-- 4) Verify view exists and works correctly
SELECT
  s.name AS schema_name,
  v.name AS view_name,
  v.create_date,
  v.modify_date
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
WHERE s.name = 'RedGate' AND v.name = 'FeedbackAuditSummary';

-- 5) View columns (should NOT include Note column)
SELECT
  c.column_id,
  c.name AS column_name,
  TYPE_NAME(c.user_type_id) AS data_type,
  c.max_length,
  c.is_nullable
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAuditSummary')
ORDER BY c.column_id;

-- 6) Test view query (should work without Note column)
SELECT COUNT(*) AS view_row_count
FROM RedGate.FeedbackAuditSummary;

-- 7) Sample data from view (should show only AuditID, CustomerID, CreatedAt)
SELECT TOP (5) *
FROM RedGate.FeedbackAuditSummary
ORDER BY AuditID DESC;

-- 8) Test that procedures still work after column drop
-- This procedure should now exclude Note column from results
EXEC RedGate.get_recent_audits @p_days = 7;

-- 9) Verify data integrity - existing data should still be accessible
SELECT
  COUNT(*) AS total_rows,
  COUNT(AuditID) AS non_null_audit_ids,
  COUNT(CustomerID) AS non_null_customer_ids,
  COUNT(CreatedAt) AS non_null_created_ats
FROM RedGate.FeedbackAudit;

-- 10) Sample table data (should show remaining columns only)
SELECT TOP (5) *
FROM RedGate.FeedbackAudit
ORDER BY AuditID DESC;

-- 11) Liquibase history for drop-column folder
SELECT
  ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE
FROM dbo.DATABASECHANGELOG
WHERE FILENAME LIKE '%/liquibase/sql/drop-column/%'
ORDER BY DATEEXECUTED DESC;

-- 12) Liquibase lock state (should be unlocked)
SELECT * FROM dbo.DATABASECHANGELOGLOCK;
```

### Drop Column Expected Results:

1. **Column Dropped**: Note column should no longer exist in RedGate.FeedbackAudit
2. **Table Structure**: Should have exactly 3 columns remaining:
   - AuditID (BIGINT IDENTITY)
   - CustomerID (INT)
   - CreatedAt (DATETIMEOFFSET)
3. **View Updated**: RedGate.FeedbackAuditSummary should work correctly without Note column
4. **Data Integrity**: Existing data in remaining columns should be preserved
5. **Dependent Objects**: Stored procedures should be updated to work without Note column
6. **Liquibase**: All changesets executed successfully:
   - `VSQL7-drop-view-before-update` (drop view before column changes)
   - `VSQL7-update-view-no-note` (recreate view without Note)
   - `VSQL8-drop-column-note` (drop column and recreate view)

### Key Drop Column Verification Points:

- Note column completely removed from table
- Table has exactly 3 columns remaining
- View recreated successfully without Note column
- View returns correct data with remaining columns
- Stored procedures work correctly after column drop
- No data loss in remaining columns
- All dependent objects (views, procedures) updated correctly

## Modify Objects Evidence

```sql
-- ==========================================
-- Evidence: SQL Server (modify-objects)
-- Changelog: liquibase/sql/modify-objects/changelog.xml
-- Purpose: Verify schema comment, view modification, and function update
-- ==========================================

-- 0) Context
SELECT
  DB_NAME()     AS CurrentDB,
  SUSER_SNAME() AS ExecutingLogin;

-- 1) Schema extended property (SQL Server equivalent of schema comment)
SELECT
  s.name AS schema_name,
  ep.value AS schema_description
FROM sys.schemas s
LEFT JOIN sys.extended_properties ep ON ep.major_id = s.schema_id
  AND ep.name = 'MS_Description'
  AND ep.class = 3 -- Schema level
WHERE s.name = 'RedGate';

-- 2) View exists and has been modified
SELECT
  s.name AS schema_name,
  v.name AS view_name,
  v.create_date,
  v.modify_date
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
WHERE s.name = 'RedGate' AND v.name = 'FeedbackAuditSummary';

-- 3) View columns after modification (should show CustID instead of CustomerID)
SELECT
  c.column_id,
  c.name AS column_name,
  TYPE_NAME(c.user_type_id) AS data_type,
  c.max_length,
  c.is_nullable
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAuditSummary')
ORDER BY c.column_id;

-- 4) Verify view column rename (should have CustID, not CustomerID)
SELECT
  CASE WHEN EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('RedGate.FeedbackAuditSummary')
    AND name = 'CustID'
  ) THEN 'CustID FOUND (SUCCESS)'
  ELSE 'CustID NOT FOUND (FAILED)' END AS custid_column_status,

  CASE WHEN EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('RedGate.FeedbackAuditSummary')
    AND name = 'CustomerID'
  ) THEN 'CustomerID STILL EXISTS (FAILED)'
  ELSE 'CustomerID RENAMED (SUCCESS)' END AS customerid_column_status;

-- 5) Test modified view query
SELECT COUNT(*) AS view_row_count
FROM RedGate.FeedbackAuditSummary;

-- 6) Sample data from modified view (should show AuditID, CustID, CreatedAt)
SELECT TOP (5) *
FROM RedGate.FeedbackAuditSummary
ORDER BY AuditID DESC;

-- 7) Modified function exists
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

-- 8) Function definition (should show updated SQL Server syntax)
SELECT
  OBJECT_NAME(object_id) AS function_name,
  definition
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('RedGate.count_recent_audits');

-- 9) Test modified function
SELECT
  'Modified Function Test - 7 days' AS test_description,
  RedGate.count_recent_audits(7) AS function_result,
  (SELECT COUNT(*)
   FROM RedGate.FeedbackAudit
   WHERE CreatedAt > DATEADD(DAY, -7, SYSDATETIMEOFFSET())) AS direct_count;

-- 10) Verify function still works correctly with different parameters
SELECT
  'Modified Function Test - 30 days' AS test_description,
  RedGate.count_recent_audits(30) AS function_result,
  (SELECT COUNT(*)
   FROM RedGate.FeedbackAudit
   WHERE CreatedAt > DATEADD(DAY, -30, SYSDATETIMEOFFSET())) AS direct_count;

-- 11) View definition showing the column alias
SELECT
  OBJECT_NAME(object_id) AS view_name,
  definition
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('RedGate.FeedbackAuditSummary');

-- 12) Compare base table vs modified view columns
SELECT 'Base Table Columns' AS source, c.name AS column_name
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAudit')
UNION ALL
SELECT 'Modified View Columns' AS source, c.name AS column_name
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('RedGate.FeedbackAuditSummary')
ORDER BY source, column_name;

-- 13) Liquibase history for modify-objects folder
SELECT
  ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE
FROM dbo.DATABASECHANGELOG
WHERE FILENAME LIKE '%/liquibase/sql/modify-objects/%'
ORDER BY DATEEXECUTED DESC;

-- 14) Liquibase lock state (should be unlocked)
SELECT * FROM dbo.DATABASECHANGELOGLOCK;
```

### Modify Objects Expected Results:

1. **Schema Metadata**: RedGate schema should have extended property 'Liquibase SQL Server test schema (updated)'
2. **View Modification**: RedGate.FeedbackAuditSummary should show:
   - AuditID column (unchanged)
   - CustID column (renamed from CustomerID)
   - CreatedAt column (unchanged)
3. **Function Update**: RedGate.count_recent_audits should:
   - Use updated SQL Server syntax
   - Return same results as before modification
   - Have updated modify_date
4. **Data Consistency**: All data should remain accessible through modified objects
5. **Liquibase**: All changesets executed successfully:
   - `VSQL9-modify-schema-comment` (schema extended property)
   - `VSQL10-modify-view-drop` (drop view)
   - `VSQL10-modify-view-create` (recreate view with column alias)
   - `VSQL11-modify-func-drop` (drop function)
   - `VSQL11-modify-func-count_recent_audits` (recreate function)

### Key Modify Objects Verification Points:

- Schema has proper extended property (SQL Server comment equivalent)
- View column renamed: CustomerID → CustID via alias
- View returns correct data with new column name
- Function recreated with updated SQL Server syntax
- Function results match previous version
- All objects have updated modify_date timestamps
- No data loss or corruption in any objects
