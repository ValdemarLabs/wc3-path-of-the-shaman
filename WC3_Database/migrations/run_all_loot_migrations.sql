-- Master Migration: run_all_loot_migrations.sql
-- Description: Run all ItemLootSystem migrations in order
-- Date: 2026-04-11
-- Usage: psql -U postgres -d wc3_pots -f run_all_loot_migrations.sql

-- Enable transaction rollback on error
\set ON_ERROR_STOP on

BEGIN;

\echo '=========================================='
\echo 'ItemLootSystem Database Migrations'
\echo '=========================================='

\echo ''
\echo '[1/6] Creating unit_types table...'
\i 001_create_unit_types.sql

\echo ''
\echo '[2/6] Creating loot_tiers table...'
\i 002_create_loot_tiers.sql

\echo ''
\echo '[3/6] Adding loot columns to items table...'
\i 003_alter_items_loot_columns.sql

\echo ''
\echo '[4/6] Creating unit_specific_drops table...'
\i 004_create_unit_specific_drops.sql

\echo ''
\echo '[5/6] Creating loot_tier_items table...'
\i 005_create_loot_tier_items.sql

\echo ''
\echo '[6/6] Seeding default loot tiers...'
\i 006_seed_loot_tiers.sql

\echo ''
\echo '=========================================='
\echo 'All migrations completed successfully!'
\echo '=========================================='

-- Verify tables created
\echo ''
\echo 'Verifying tables:'
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('unit_types', 'loot_tiers', 'unit_specific_drops', 'loot_tier_items')
ORDER BY table_name;

\echo ''
\echo 'Loot tiers seeded:'
SELECT tier_name, min_unit_level, max_unit_level, drop_chance_base 
FROM loot_tiers ORDER BY min_unit_level;

COMMIT;
