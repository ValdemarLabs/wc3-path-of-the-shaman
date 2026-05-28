-- Migration: 005_create_loot_tier_items
-- Description: Create optional tier-specific item overrides table
-- Date: 2026-04-11

-- Loot Tier Items - optional overrides for generic tier pools
-- Most items auto-match via item_level + rarity_id, this allows exceptions
CREATE TABLE IF NOT EXISTS loot_tier_items (
    id SERIAL PRIMARY KEY,
    loot_tier_id INTEGER NOT NULL,
    
    -- Either specify exact item OR level range
    item_code VARCHAR(4),                         -- Specific item (NULL if using range)
    item_level_min INTEGER,                       -- Min item level (if item_code is NULL)
    item_level_max INTEGER,                       -- Max item level (if item_code is NULL)
    
    -- Drop modifiers
    weight INTEGER DEFAULT 100,                   -- Relative weight
    drop_chance_modifier DECIMAL(5,2) DEFAULT 0,  -- Additive modifier to base chance
    
    -- Filters
    rarity_filter VARCHAR(20) DEFAULT 'all',      -- common, uncommon, rare, epic, legendary, artifact, all
    type_filter VARCHAR(50) DEFAULT 'all',        -- weapon, armor, consumable, etc., all
    
    enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign keys
    CONSTRAINT fk_lti_tier FOREIGN KEY (loot_tier_id) REFERENCES loot_tiers(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_lti_item FOREIGN KEY (item_code) REFERENCES items(item_code)
        ON DELETE CASCADE,
    
    -- Constraints
    CONSTRAINT chk_item_or_range CHECK (
        (item_code IS NOT NULL AND item_level_min IS NULL AND item_level_max IS NULL)
        OR (item_code IS NULL AND item_level_min IS NOT NULL AND item_level_max IS NOT NULL)
    ),
    CONSTRAINT chk_level_range CHECK (
        item_level_min IS NULL OR item_level_min <= item_level_max
    )
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_lti_tier ON loot_tier_items(loot_tier_id);
CREATE INDEX IF NOT EXISTS idx_lti_item ON loot_tier_items(item_code) WHERE item_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lti_enabled ON loot_tier_items(enabled);

COMMENT ON TABLE loot_tier_items IS 'Optional overrides for tier-specific item pools (most items auto-match via item_level)';
COMMENT ON COLUMN loot_tier_items.rarity_filter IS 'Filter by rarity name or "all"';
