-- Add tooltip lookup columns used by ItemManager manual ability search.
ALTER TABLE wc3_abilities
ADD COLUMN IF NOT EXISTS tooltip_normal TEXT,
ADD COLUMN IF NOT EXISTS tooltip_extended TEXT;

COMMENT ON COLUMN wc3_abilities.tooltip_normal IS 'Ability normal tooltip (atp1 field)';
COMMENT ON COLUMN wc3_abilities.tooltip_extended IS 'Ability extended tooltip (aub1 field)';
