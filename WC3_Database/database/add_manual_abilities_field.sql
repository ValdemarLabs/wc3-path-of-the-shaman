-- Add field to store manual ability details (Code, Type, Description)
-- This preserves user-entered Type and Description fields that are not part of WC3 export

ALTER TABLE items ADD COLUMN IF NOT EXISTS manual_abilities_data JSONB;

COMMENT ON COLUMN items.manual_abilities_data IS 'JSON array storing manual ability details: [{code: "A001", type: "Passive", description: "Bash - random stun"}]';
