-- Source provenance for importing existing qXXX quest libraries into WC3 Manager.
-- Safe to run repeatedly after 007_create_quest_designer.sql.

BEGIN;

ALTER TABLE quest_givers
    ADD COLUMN IF NOT EXISTS source_kind VARCHAR(32) NOT NULL DEFAULT '';
ALTER TABLE quest_givers
    ADD COLUMN IF NOT EXISTS source_import_fingerprint VARCHAR(64) NOT NULL DEFAULT '';
ALTER TABLE quest_givers
    ADD COLUMN IF NOT EXISTS source_imported_at TIMESTAMPTZ;

ALTER TABLE quests
    ADD COLUMN IF NOT EXISTS source_file VARCHAR(512) NOT NULL DEFAULT '';
ALTER TABLE quests
    ADD COLUMN IF NOT EXISTS source_symbol VARCHAR(128) NOT NULL DEFAULT '';
ALTER TABLE quests
    ADD COLUMN IF NOT EXISTS source_import_fingerprint VARCHAR(64) NOT NULL DEFAULT '';
ALTER TABLE quests
    ADD COLUMN IF NOT EXISTS source_imported_at TIMESTAMPTZ;

ALTER TABLE quest_givers DROP CONSTRAINT IF EXISTS quest_givers_binding_check;
ALTER TABLE quest_givers ADD CONSTRAINT quest_givers_binding_check CHECK (
    ownership_mode = 'external'
    OR unit_code IS NOT NULL
    OR placed_unit_variable IS NOT NULL
);

ALTER TABLE quest_givers DROP CONSTRAINT IF EXISTS quest_givers_source_kind_check;
ALTER TABLE quest_givers ADD CONSTRAINT quest_givers_source_kind_check CHECK (
    source_kind IN ('', 'quest_giver', 'vendor_quest_giver', 'generic_quest')
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_quests_source_symbol
    ON quests(quest_giver_id, source_symbol)
    WHERE source_symbol <> '';
CREATE INDEX IF NOT EXISTS idx_quest_givers_source_file ON quest_givers(source_file);
CREATE INDEX IF NOT EXISTS idx_quests_source_file ON quests(source_file);

COMMIT;
