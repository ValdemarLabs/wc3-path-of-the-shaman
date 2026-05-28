-- Add model attachment abilities field to items table
-- These are hidden from players (like stat abilities) but used for visual effects
-- Examples: particle effects, glows, auras, model attachments

ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_abilities_attachments TEXT;

COMMENT ON COLUMN items.wc3_abilities_attachments IS 'Model attachment abilities (comma-separated, hidden from players, summed to wc3_abilities)';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_items_wc3_abilities_attachments ON items(wc3_abilities_attachments);
