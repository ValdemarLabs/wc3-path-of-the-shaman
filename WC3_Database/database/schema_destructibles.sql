-- ============================================================================
-- schema_destructibles.sql
-- Database tables for destructible type loot configuration
-- Created: 2026-04-14
-- ============================================================================

-- Destructible types table (analogous to unit_types)
CREATE TABLE IF NOT EXISTS destructible_types (
    id SERIAL PRIMARY KEY,
    destructible_code CHAR(4) UNIQUE NOT NULL,    -- 4-char WC3 rawcode (e.g., 'LTcr')
    base_id VARCHAR(50),                          -- Base destructible ID (for custom)
    destructible_name VARCHAR(255) NOT NULL,      -- Display name
    editor_suffix VARCHAR(100),                   -- Editor suffix (for variants)
    model_path VARCHAR(500),                      -- Art model path
    
    -- Loot configuration
    destructible_level INTEGER DEFAULT 1,         -- Equivalent level for loot tier matching
    loot_mode VARCHAR(20) DEFAULT 'generic',      -- 'generic', 'specific', 'both', 'none'
    loot_tier_id INTEGER REFERENCES loot_tiers(id),
    drop_count_min INTEGER DEFAULT 0,             -- Minimum drops (0 = possible no drop)
    drop_count_max INTEGER DEFAULT 1,             -- Maximum drops
    drop_chance_override DECIMAL(5,2),            -- Override tier drop chance (null = use tier)
    
    -- Category/classification
    category VARCHAR(50),                         -- 'crate', 'barrel', 'chest', 'rock', etc.
    is_container BOOLEAN DEFAULT false,           -- True for crates/chests/barrels
    
    -- Metadata
    notes TEXT,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Destructible-specific drops table (for unique containers with specific loot)
CREATE TABLE IF NOT EXISTS destructible_specific_drops (
    id SERIAL PRIMARY KEY,
    destructible_code CHAR(4) NOT NULL REFERENCES destructible_types(destructible_code),
    item_code CHAR(4) NOT NULL,                   -- FK to items (enforced at application level)
    
    -- Drop configuration
    drop_chance DECIMAL(5,2) DEFAULT 100.00,      -- 0-100%
    min_quantity INTEGER DEFAULT 1,
    max_quantity INTEGER DEFAULT 1,
    is_guaranteed BOOLEAN DEFAULT false,          -- Always drops from this destructible
    weight INTEGER DEFAULT 100,                   -- For weighted random selection
    
    -- Metadata
    enabled BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_destructible_types_level ON destructible_types(destructible_level);
CREATE INDEX IF NOT EXISTS idx_destructible_types_category ON destructible_types(category);
CREATE INDEX IF NOT EXISTS idx_destructible_types_loot_mode ON destructible_types(loot_mode);
CREATE INDEX IF NOT EXISTS idx_destructible_specific_drops_code ON destructible_specific_drops(destructible_code);
CREATE INDEX IF NOT EXISTS idx_destructible_specific_drops_item ON destructible_specific_drops(item_code);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_destructible_types_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_destructible_types_updated ON destructible_types;
CREATE TRIGGER trigger_destructible_types_updated
    BEFORE UPDATE ON destructible_types
    FOR EACH ROW
    EXECUTE FUNCTION update_destructible_types_timestamp();

-- ============================================================================
-- Sample data: Common WC3 destructibles
-- ============================================================================

-- Uncomment and modify as needed for your map
/*
INSERT INTO destructible_types (destructible_code, destructible_name, category, is_container, destructible_level) VALUES
('LTcr', 'Crate', 'crate', true, 1),
('LTbr', 'Barrel', 'barrel', true, 1),
('DTc2', 'Crate (Large)', 'crate', true, 5),
('DTc3', 'Crate (Lordaeron)', 'crate', true, 10),
('DTc4', 'Barrel (Lordaeron)', 'barrel', true, 10),
('ITcr', 'Ice Crate', 'crate', true, 15),
('YTct', 'Chest (Cityscape)', 'chest', true, 20),
('YTbr', 'Barrel (Cityscape)', 'barrel', true, 20)
ON CONFLICT (destructible_code) DO NOTHING;
*/
