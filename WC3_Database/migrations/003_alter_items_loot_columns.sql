-- Migration: 003_alter_items_loot_columns
-- Description: Add loot-related columns to existing items table
-- Date: 2026-04-11

-- Add loot-related columns to items table
-- Note: rarity_id already exists in items table

-- is_unique: Item can only drop once per game (for legendary/special items)
ALTER TABLE items 
    ADD COLUMN IF NOT EXISTS is_unique BOOLEAN DEFAULT FALSE;

-- item_level_unclassified: For non-equippable items (consumables, misc)
-- where item_level is used for stacks, this field is for loot tier matching
ALTER TABLE items 
    ADD COLUMN IF NOT EXISTS item_level_unclassified INTEGER;

-- Index for loot queries
CREATE INDEX IF NOT EXISTS idx_items_is_unique ON items(is_unique);
CREATE INDEX IF NOT EXISTS idx_items_item_level_unclassified ON items(item_level_unclassified) 
    WHERE item_level_unclassified IS NOT NULL;

-- Composite index for loot pool lookups (item_level + rarity_id)
CREATE INDEX IF NOT EXISTS idx_items_loot_pool ON items(item_level, rarity_id) 
    WHERE item_level IS NOT NULL AND rarity_id IS NOT NULL;

COMMENT ON COLUMN items.is_unique IS 'If true, item can only drop once per game session';
COMMENT ON COLUMN items.item_level_unclassified IS 'For consumables: loot tier level (when item_level is used for stacks)';
