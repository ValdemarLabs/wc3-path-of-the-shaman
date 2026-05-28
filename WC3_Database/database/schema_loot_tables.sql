-- ============================================================================
-- Loot Tables Schema
-- Pre-defined named loot tables that can be assigned to units/destructibles
-- Replaces the tier-based system with more flexible named collections
-- ============================================================================

-- Drop existing tables if migrating
-- DROP TABLE IF EXISTS loot_table_items CASCADE;
-- DROP TABLE IF EXISTS loot_tables CASCADE;

-- ============================================================================
-- LOOT TABLES
-- Named collections of items (e.g., "Forest Trolls", "Human Guards", "Crates Level 1-5")
-- ============================================================================
CREATE TABLE IF NOT EXISTS loot_tables (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    
    -- Drop configuration
    drop_chance INTEGER DEFAULT 5000,       -- Base drop chance (0-10000 = 0-100.00%)
    drop_count_min INTEGER DEFAULT 0,       -- Minimum items to drop (0 = possible no drop)
    drop_count_max INTEGER DEFAULT 1,       -- Maximum items to drop
    
    -- Level range (for filtering/categorization)
    min_level INTEGER DEFAULT 1,            -- Suggested minimum level for this table
    max_level INTEGER DEFAULT 99,           -- Suggested maximum level for this table
    
    -- Categorization
    category VARCHAR(50),                   -- 'units', 'destructibles', 'both', 'boss', etc.
    
    -- State
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- LOOT TABLE ITEMS
-- Items within each loot table with their drop configuration
-- ============================================================================
CREATE TABLE IF NOT EXISTS loot_table_items (
    id SERIAL PRIMARY KEY,
    loot_table_id INTEGER NOT NULL REFERENCES loot_tables(id) ON DELETE CASCADE,
    item_code VARCHAR(10) NOT NULL,
    
    -- Drop configuration
    drop_chance INTEGER DEFAULT 10000,      -- Individual item drop chance (0-10000 = 0-100.00%)
    weight INTEGER DEFAULT 100,             -- Weight for weighted random selection
    is_guaranteed BOOLEAN DEFAULT FALSE,    -- If true, always drops when table is rolled
    
    -- Quantity
    quantity_min INTEGER DEFAULT 1,
    quantity_max INTEGER DEFAULT 1,
    
    -- Metadata
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent duplicate items in same table
    UNIQUE(loot_table_id, item_code)
);

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_loot_tables_name ON loot_tables(name);
CREATE INDEX IF NOT EXISTS idx_loot_tables_category ON loot_tables(category);
CREATE INDEX IF NOT EXISTS idx_loot_tables_enabled ON loot_tables(enabled);
CREATE INDEX IF NOT EXISTS idx_loot_table_items_table_id ON loot_table_items(loot_table_id);
CREATE INDEX IF NOT EXISTS idx_loot_table_items_item_code ON loot_table_items(item_code);

-- ============================================================================
-- UPDATE UNIT_TYPES TABLE
-- Add loot_table_id column (nullable, as alternative to existing tier system)
-- ============================================================================
ALTER TABLE unit_types ADD COLUMN IF NOT EXISTS loot_table_id INTEGER REFERENCES loot_tables(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_unit_types_loot_table ON unit_types(loot_table_id);

-- ============================================================================
-- UPDATE DESTRUCTIBLE_TYPES TABLE  
-- Add loot_table_id column (nullable, as alternative to existing tier system)
-- ============================================================================
ALTER TABLE destructible_types ADD COLUMN IF NOT EXISTS loot_table_id INTEGER REFERENCES loot_tables(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_destructible_types_loot_table ON destructible_types(loot_table_id);

-- ============================================================================
-- UPDATE TIMESTAMPS TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION update_loot_tables_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_loot_tables_timestamp ON loot_tables;
CREATE TRIGGER trigger_loot_tables_timestamp
    BEFORE UPDATE ON loot_tables
    FOR EACH ROW
    EXECUTE FUNCTION update_loot_tables_timestamp();

-- ============================================================================
-- PRE-DEFINED LOOT TABLES
-- Create default loot tables for various level ranges
-- ============================================================================

-- Level 1-5 (Early Game / Starter)
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Generic Level 1-5', 'Basic drops for early game enemies', 3000, 0, 1, 1, 5, 'units'),
    ('Destructible Level 1-5', 'Basic drops from crates/barrels in starter areas', 4000, 0, 1, 1, 5, 'destructibles')
ON CONFLICT (name) DO NOTHING;

-- Level 6-10 (Early-Mid Game)
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Generic Level 6-10', 'Drops for low-mid level enemies', 3500, 0, 1, 6, 10, 'units'),
    ('Destructible Level 6-10', 'Drops from crates/barrels in low-mid areas', 4500, 0, 1, 6, 10, 'destructibles')
ON CONFLICT (name) DO NOTHING;

-- Level 11-15 (Mid Game)
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Generic Level 11-15', 'Mid-game enemy drops', 4000, 0, 1, 11, 15, 'units'),
    ('Destructible Level 11-15', 'Mid-game container drops', 5000, 0, 1, 11, 15, 'destructibles')
ON CONFLICT (name) DO NOTHING;

-- Level 16-20 (Mid-High Game)
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Generic Level 16-20', 'Mid-high level enemy drops', 4500, 0, 1, 16, 20, 'units'),
    ('Destructible Level 16-20', 'Mid-high level container drops', 5500, 0, 1, 16, 20, 'destructibles')
ON CONFLICT (name) DO NOTHING;

-- Level 21-25 (High Game)
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Generic Level 21-25', 'High level enemy drops', 5000, 0, 1, 21, 25, 'units'),
    ('Destructible Level 21-25', 'High level container drops', 6000, 0, 1, 21, 25, 'destructibles')
ON CONFLICT (name) DO NOTHING;

-- Level 26-30 (Very High)
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Generic Level 26-30', 'Very high level enemy drops', 5500, 0, 2, 26, 30, 'units'),
    ('Destructible Level 26-30', 'Very high level container drops', 6500, 0, 2, 26, 30, 'destructibles')
ON CONFLICT (name) DO NOTHING;

-- Level 31+ (End Game)
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Generic Level 31+', 'End-game enemy drops', 6000, 0, 2, 31, 99, 'units'),
    ('Destructible Level 31+', 'End-game container drops', 7000, 0, 2, 31, 99, 'destructibles')
ON CONFLICT (name) DO NOTHING;

-- Unit Type Specific Tables
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Human Guards', 'Standard drops from human soldiers', 4000, 0, 1, 1, 99, 'units'),
    ('Forest Trolls', 'Drops from forest troll enemies', 4500, 0, 1, 1, 99, 'units'),
    ('Undead Minions', 'Drops from undead creatures', 3500, 0, 1, 1, 99, 'units'),
    ('Demons', 'Drops from demon units', 5000, 0, 2, 1, 99, 'units'),
    ('Dragons', 'Drops from dragon-type enemies', 6000, 1, 2, 1, 99, 'units'),
    ('Boss Generic', 'Standard boss drops (in addition to specific)', 7000, 1, 3, 1, 99, 'boss')
ON CONFLICT (name) DO NOTHING;

-- Container Specific Tables  
INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max, min_level, max_level, category)
VALUES 
    ('Wooden Crates', 'Basic wooden storage crates', 5000, 0, 1, 1, 99, 'destructibles'),
    ('Metal Chests', 'Metal reinforced chests with better loot', 7000, 1, 2, 1, 99, 'destructibles'),
    ('Barrels', 'Storage barrels with consumables', 4000, 0, 1, 1, 99, 'destructibles'),
    ('Treasure Chests', 'Rare treasure chests with valuable items', 8000, 1, 3, 1, 99, 'destructibles')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE 'Loot tables schema created successfully';
    RAISE NOTICE 'Created % pre-defined loot tables', (SELECT COUNT(*) FROM loot_tables);
END $$;
