-- Migration: 009_add_specific_drop_quest_gate
-- Description: Link unit-specific drops to optional Quest Designer state gates
-- Date: 2026-09-11

BEGIN;

ALTER TABLE unit_specific_drops
    ADD COLUMN IF NOT EXISTS required_quest_id INTEGER REFERENCES quests(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS required_quest_state VARCHAR(16) NOT NULL DEFAULT 'active';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'unit_specific_drops_required_quest_state_check'
    ) THEN
        ALTER TABLE unit_specific_drops
            ADD CONSTRAINT unit_specific_drops_required_quest_state_check
            CHECK (required_quest_state IN ('active', 'discovered'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_usd_required_quest_id
    ON unit_specific_drops(required_quest_id);

COMMENT ON COLUMN unit_specific_drops.required_quest_id IS
    'Optional Quest Designer quest that must satisfy required_quest_state before this drop can roll';
COMMENT ON COLUMN unit_specific_drops.required_quest_state IS
    'Required runtime quest state: active or discovered';

-- Gnoll Heads are quest loot, not part of the generic level-based item pool.
UPDATE items
SET specific_drop_only = TRUE
WHERE item_code = 'I69A';

-- WC3 base gnolls are not present in custom war3map.w3u imports, so register
-- their loot identities explicitly and keep their normal generic loot rolls.
INSERT INTO unit_types (unit_code, base_id, unit_name, unit_level, loot_mode, notes)
VALUES
    ('ngno', 'ngno', 'Gnoll', 1, 'both', 'Warcraft base unit used by Gnoll Headcount'),
    ('ngna', 'ngna', 'Gnoll Poacher', 1, 'both', 'Warcraft base unit used by Gnoll Headcount'),
    ('ngnb', 'ngnb', 'Gnoll Brute', 3, 'both', 'Warcraft base unit used by Gnoll Headcount'),
    ('ngnw', 'ngnw', 'Gnoll Warden', 3, 'both', 'Warcraft base unit used by Gnoll Headcount')
ON CONFLICT (unit_code) DO NOTHING;

WITH gnoll_headcount AS (
    SELECT MIN(id) AS quest_id
    FROM quests
    WHERE quest_name = 'Gnoll Headcount'
), base_gnolls(unit_code) AS (
    VALUES ('ngno'), ('ngnb'), ('ngna'), ('ngnw')
)
INSERT INTO unit_specific_drops (
    unit_code, item_code, drop_chance, min_quantity, max_quantity,
    is_guaranteed, weight, required_quest_id, required_quest_state, enabled, notes
)
SELECT
    bg.unit_code, 'I69A', 25.00, 1, 1,
    FALSE, 80, gh.quest_id, 'active', TRUE, 'Gnoll Headcount quest drop'
FROM base_gnolls bg
JOIN unit_types ut ON ut.unit_code = bg.unit_code
CROSS JOIN gnoll_headcount gh
WHERE gh.quest_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM items WHERE item_code = 'I69A')
ON CONFLICT (unit_code, item_code) DO UPDATE SET
    drop_chance = EXCLUDED.drop_chance,
    min_quantity = EXCLUDED.min_quantity,
    max_quantity = EXCLUDED.max_quantity,
    is_guaranteed = EXCLUDED.is_guaranteed,
    weight = EXCLUDED.weight,
    required_quest_id = EXCLUDED.required_quest_id,
    required_quest_state = EXCLUDED.required_quest_state,
    enabled = EXCLUDED.enabled,
    notes = EXCLUDED.notes;

UPDATE unit_specific_drops
SET required_quest_id = (
        SELECT MIN(id)
        FROM quests
        WHERE quest_name = 'Gnoll Headcount'
    ),
    required_quest_state = 'active'
WHERE item_code = 'I69A'
  AND EXISTS (SELECT 1 FROM quests WHERE quest_name = 'Gnoll Headcount');

COMMIT;
