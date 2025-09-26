# Evidence Check: Flyway PostgreSQL Migration

## Migration Evidence Scripts

```sql
-- ==========================================
-- Evidence: PostgreSQL (Flyway)
-- Purpose: Comprehensive validation of all Flyway migrations
-- ==========================================

-- 0) Context
SELECT
  current_database() AS current_db,
  current_user AS executing_user,
  NOW() AS evidence_run_time;

-- ==========================================
-- V1: Schema Creation Evidence
-- ==========================================

-- 1) Schema exists
SELECT
  schema_name,
  schema_owner
FROM information_schema.schemata
WHERE schema_name = 'redgate';

-- ==========================================
-- V2: Table Creation Evidence
-- ==========================================

-- 2) Table exists with correct structure
SELECT
  table_schema,
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'redgate' AND table_name = 'feedbackaudit';

-- 3) Table columns
SELECT
  ordinal_position,
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'redgate' AND table_name = 'feedbackaudit'
ORDER BY ordinal_position;

-- 4) Primary key constraint
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  tc.constraint_type
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'redgate'
  AND tc.table_name = 'feedbackaudit'
  AND tc.constraint_type = 'PRIMARY KEY';

-- 5) Check sequence for identity column
SELECT
  sequence_name,
  data_type,
  start_value,
  minimum_value,
  maximum_value,
  increment
FROM information_schema.sequences
WHERE sequence_schema = 'redgate'
  AND sequence_name LIKE '%feedbackaudit%';

-- ==========================================
-- V3: Data Seeding Evidence
-- ==========================================

-- 6) Seeded data exists
SELECT
  COUNT(*) AS total_rows,
  MIN(auditid) AS min_audit_id,
  MAX(auditid) AS max_audit_id,
  MIN(createdat) AS earliest_created,
  MAX(createdat) AS latest_created
FROM redgate.feedbackaudit;

-- 7) Sample seeded data
SELECT *
FROM redgate.feedbackaudit
ORDER BY auditid
LIMIT 5;

-- 8) Check for specific seed data
SELECT COUNT(*) AS seed_data_count
FROM redgate.feedbackaudit
WHERE customerid IN (1001, 1002)
  AND note IN ('Seed row 1', 'Seed row 2');

-- ==========================================
-- V4: View Creation Evidence
-- ==========================================

-- 9) View exists
SELECT
  table_schema,
  table_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'redgate' AND table_name = 'feedbackauditsummary';

-- 10) View columns
SELECT
  ordinal_position,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'redgate' AND table_name = 'feedbackauditsummary'
ORDER BY ordinal_position;

-- 11) Test view query
SELECT COUNT(*) AS view_row_count
FROM redgate.feedbackauditsummary;

-- 12) Sample data from view
SELECT *
FROM redgate.feedbackauditsummary
ORDER BY auditid DESC
LIMIT 3;

-- ==========================================
-- V5: Function Creation Evidence
-- ==========================================

-- 13) Function exists
SELECT
  routine_schema,
  routine_name,
  routine_type,
  data_type AS return_type,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'redgate'
  AND routine_name = 'count_recent_audits';

-- 14) Function parameters
SELECT
  parameter_name,
  data_type,
  parameter_mode
FROM information_schema.parameters
WHERE specific_schema = 'redgate'
  AND specific_name = 'count_recent_audits'
ORDER BY ordinal_position;

-- 15) Test function
SELECT
  'Function Test - 30 days' AS test_description,
  redgate.count_recent_audits(30) AS function_result,
  (SELECT COUNT(*) FROM redgate.feedbackaudit
   WHERE createdat > (CURRENT_TIMESTAMP - '30 days'::interval)) AS direct_count;

-- ==========================================
-- V11: Function (PostgreSQL equivalent of procedure)
-- ==========================================

-- 16) get_recent_audits function exists
SELECT
  routine_schema,
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'redgate'
  AND routine_name = 'get_recent_audits';

-- 17) Test function execution
SELECT * FROM redgate.get_recent_audits();

-- ==========================================
-- Column Modifications Evidence (V6, V7)
-- ==========================================

-- 18) Check current column structure after modifications
SELECT
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  CASE
    WHEN column_name = 'source' THEN 'V6 - Added'
    WHEN column_name = 'note' THEN 'Should be dropped in V7'
    ELSE 'Original'
  END AS column_status
FROM information_schema.columns
WHERE table_schema = 'redgate' AND table_name = 'feedbackaudit'
ORDER BY ordinal_position;

-- 19) Verify source column exists (V6)
SELECT
  CASE
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'redgate'
        AND table_name = 'feedbackaudit'
        AND column_name = 'source'
    ) THEN 'Source column EXISTS (V6 success)'
    ELSE 'Source column MISSING (V6 failed)'
  END AS source_column_status;

-- 20) Verify note column dropped (V7)
SELECT
  CASE
    WHEN NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'redgate'
        AND table_name = 'feedbackaudit'
        AND column_name = 'note'
    ) THEN 'Note column DROPPED (V7 success)'
    ELSE 'Note column EXISTS (V7 failed)'
  END AS note_column_status;

-- ==========================================
-- Schema Modifications Evidence (V8, V9)
-- ==========================================

-- 21) Schema comment (V8)
SELECT
  schema_name,
  obj_description(oid, 'pg_namespace') AS schema_comment
FROM pg_namespace
WHERE nspname = 'redgate';

-- 22) View modifications (V9) - check current definition and comment
SELECT
  table_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'redgate' AND table_name = 'feedbackauditsummary';

-- 22b) View comment (V9)
SELECT
  schemaname,
  viewname,
  obj_description(c.oid, 'pg_class') AS view_comment
FROM pg_views v
JOIN pg_class c ON c.relname = v.viewname
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE v.schemaname = 'redgate' AND v.viewname = 'feedbackauditsummary';

-- ==========================================
-- Function Modifications Evidence (V10)
-- ==========================================

-- 23) Modified function definition
SELECT
  routine_name,
  routine_definition
FROM information_schema.routines
WHERE routine_schema = 'redgate'
  AND routine_name = 'count_recent_audits';

-- 24) Test modified function with different parameters
SELECT
  'Modified Function Test - 7 days' AS test_description,
  redgate.count_recent_audits(7) AS function_result,
  (SELECT COUNT(*) FROM redgate.feedbackaudit
   WHERE createdat > (CURRENT_TIMESTAMP - '7 days'::interval)) AS direct_count;

-- ==========================================
-- Failure Test Evidence (V12)
-- ==========================================

-- 25) Check if failure migration was handled properly
-- This should either show as failed or marked as executed depending on error handling

-- ==========================================
-- Flyway Schema History
-- ==========================================

-- 26) Flyway migration history
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

-- 27) Migration success summary
SELECT
  COUNT(*) AS total_migrations,
  COUNT(CASE WHEN success = true THEN 1 END) AS successful_migrations,
  COUNT(CASE WHEN success = false THEN 1 END) AS failed_migrations
FROM flyway_schema_history;

-- 28) Most recent migrations
SELECT
  version,
  description,
  installed_on,
  execution_time,
  CASE WHEN success = true THEN 'SUCCESS' ELSE 'FAILED' END AS status
FROM flyway_schema_history
ORDER BY installed_on DESC
LIMIT 5;

-- ==========================================
-- Additional PostgreSQL-specific checks
-- ==========================================

-- 29) Database objects summary
SELECT
  schemaname,
  COUNT(CASE WHEN type = 'table' THEN 1 END) AS tables,
  COUNT(CASE WHEN type = 'view' THEN 1 END) AS views,
  COUNT(CASE WHEN type = 'function' THEN 1 END) AS functions
FROM (
  SELECT schemaname, 'table' AS type FROM pg_tables WHERE schemaname = 'redgate'
  UNION ALL
  SELECT schemaname, 'view' AS type FROM pg_views WHERE schemaname = 'redgate'
  UNION ALL
  SELECT n.nspname AS schemaname, 'function' AS type
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'redgate'
) AS objects
GROUP BY schemaname;

-- 30) Sequence current values (for identity columns)
SELECT
  sequence_schema,
  sequence_name,
  last_value
FROM information_schema.sequences s
JOIN pg_sequences ps ON s.sequence_name = ps.sequencename
WHERE sequence_schema = 'redgate';
```

## Expected Results Summary

### Migration V1-V2 (Schema & Table):

- `redgate` schema should exist (created with IF NOT EXISTS for safety)
- `feedbackaudit` table with 4 columns initially: auditid (GENERATED BY DEFAULT AS IDENTITY), customerid, note, createdat

### Migration V3 (Data Seeding):

- At least 2 rows with CustomerID=1001,1002 and Notes='Seed row 1','Seed row 2'

### Migration V4 (View):

- `feedbackauditsummary` view exists and returns data from base table

### Migration V5 (Function):

- `count_recent_audits` function exists and returns correct counts for date ranges

### Migration V6 (Add Column):

- `source` column should be present in feedbackaudit table

### Migration V7 (Drop Column):

- View updated to remove `note` column reference first (to handle dependencies)
- `note` column should be removed from feedbackaudit table

### Migration V8 (Schema Comment):

- Schema should have comment/description attached

### Migration V9 (View Modification):

- View comment should be added/updated
- View definition should be consistent and reflect final structure

### Migration V10 (Function Modification):

- Function should have updated logic while maintaining same interface

### Migration V11 (Function as Procedure):

- `get_recent_audits` function exists and returns recent audit records

### Migration V12 (Failure Test):

- Should demonstrate error handling without breaking the migration chain

### Key Validation Points:

- All migrations show as successful in flyway_schema_history
- Database objects exist and function correctly
- Data integrity maintained throughout all changes
- PostgreSQL-specific features (sequences, functions) work properly
- Error handling works appropriately for failure scenarios

### PostgreSQL-Specific Features Validated:

- `CREATE SCHEMA IF NOT EXISTS` syntax
- `GENERATED BY DEFAULT AS IDENTITY` for auto-increment
- PostgreSQL function syntax with `LANGUAGE sql`
- `CURRENT_TIMESTAMP` and interval arithmetic
- Schema comments using `obj_description`
- Set-returning functions for procedure-like behavior
