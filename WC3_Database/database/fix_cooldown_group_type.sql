-- Fix cooldown_group data type: INTEGER -> VARCHAR
-- WC3's 'icid' field stores STRING values (ability codes), not integers

ALTER TABLE items ALTER COLUMN cooldown_group TYPE VARCHAR(50);

-- Update default
ALTER TABLE items ALTER COLUMN cooldown_group SET DEFAULT NULL;

COMMENT ON COLUMN items.cooldown_group IS 'WC3 cooldown group ID (string: ability code or custom ID)';
