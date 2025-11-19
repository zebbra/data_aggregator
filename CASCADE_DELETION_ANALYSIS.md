# Cascade Deletion Problem Analysis

## Problem Summary

When deleting a collection, orphaned records remain in `validation_request_records_versions` table, even though there are foreign key constraints with `ON DELETE CASCADE` that should prevent this.

## Root Cause

The `drop_partitions_for_collection()` trigger function removes foreign key constraints that it shouldn't touch, and fails to recreate all of them.

### What Happens

1. **Before deletion:** All constraints exist
   - `validation_request_records.validation_request_records_record_id_fkey` → `records`
   - `validation_request_records_versions.validation_request_records_versions_version_source_id_fkey` → `validation_request_records`

2. **During deletion trigger:**
   - The trigger drops **ALL** constraints matching `%_record_id_fkey` or `%_version_source_id_fkey`
   - This includes constraints from **non-partitioned** tables like `validation_request_records`
   - Then it drops the partitions
   - Then it tries to recreate constraints **only for specific hardcoded tables**
   - **`validation_request_records` is NOT in that list**, so its constraint is never recreated

3. **After deletion:**
   - `validation_request_records.validation_request_records_record_id_fkey` is **GONE**
   - `validation_request_records_versions.validation_request_records_versions_version_source_id_fkey` still exists
   - But it references `validation_request_records`, which now has orphaned data
   - The orphaned data in `validation_request_records_versions` cannot be cascade-deleted

## Test Results

Run `mix run test_cascade_deletion.exs` to reproduce:

```
=== BEFORE deletion ===
✓ records: 1 rows
✓ validation_request_records: 1 rows
✓ validation_request_records_versions: 1 rows

=== AFTER deletion ===
✓ records: 0 rows
✓ validation_request_records: 0 rows
❌ validation_request_records_versions: 1 rows  ← ORPHANED DATA!

🚨 PROBLEM: validation_request_records_versions rows still exist
   These reference a deleted collection
```

### Constraint Status

**Before:**
- ✓ `validation_request_records_record_id_fkey` exists
- ✓ `validation_request_records_versions_version_source_id_fkey` exists

**After:**
- ❌ `validation_request_records_record_id_fkey` **REMOVED**
- ✓ `validation_request_records_versions_version_source_id_fkey` still exists

## Solutions

### Option 1: Don't Drop Constraints for Non-Partitioned Tables (Recommended)

Only drop constraints from **partitioned tables** (relkind = 'p'):

```sql
FOR constraint_info IN
  SELECT ...
  FROM information_schema.table_constraints tc
  JOIN pg_class c ON c.relname = tc.table_name 
  WHERE tc.constraint_type = 'FOREIGN KEY'
  AND c.relkind = 'p'  -- Only partitioned tables
  AND (tc.constraint_name LIKE '%_record_id_fkey' ...)
```

This way:
- Partitioned tables (that need special handling) get their constraints temporarily removed
- Non-partitioned tables keep their constraints
- CASCADE works naturally through the constraints

### Option 2: Use CASCADE on Partition Drops (Simplest)

Instead of dropping constraints, just use CASCADE:

```sql
DROP TABLE records_partition_xyz CASCADE;
```

This automatically handles all dependencies without touching constraints.

### Option 3: Add Missing Tables to Recreation List

Add `validation_request_records` to the hardcoded list of tables whose constraints get recreated. But this is fragile and doesn't scale.

## Recommended Fix

Implement **Option 1** because:
- It's precise - only affects tables that actually need it
- It's safe - preserves CASCADE behavior for regular tables
- It's maintainable - no hardcoded table lists needed
