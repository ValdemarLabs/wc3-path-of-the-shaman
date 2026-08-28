-- Quest Designer schema for WC3 Manager
-- Date: 2026-08-28
-- Safe to run repeatedly against the wc3_pots PostgreSQL database.

BEGIN;

CREATE TABLE IF NOT EXISTS quest_givers (
    id SERIAL PRIMARY KEY,
    giver_key VARCHAR(64) NOT NULL UNIQUE,
    display_name VARCHAR(128) NOT NULL,
    library_name VARCHAR(64) NOT NULL UNIQUE,
    ownership_mode VARCHAR(16) NOT NULL DEFAULT 'managed',
    source_file VARCHAR(512) NOT NULL DEFAULT '',
    unit_code VARCHAR(4),
    placed_unit_variable VARCHAR(128),
    zone_id INTEGER,
    faction VARCHAR(128) NOT NULL DEFAULT '',
    allow_nazgrek BOOLEAN NOT NULL DEFAULT TRUE,
    allow_zulkis BOOLEAN NOT NULL DEFAULT FALSE,
    dialog_range NUMERIC(8,2) NOT NULL DEFAULT 500.00,
    dialog_cooldown NUMERIC(8,2) NOT NULL DEFAULT 6.00,
    use_dialog_camera BOOLEAN NOT NULL DEFAULT TRUE,
    use_cinematic_mode BOOLEAN NOT NULL DEFAULT TRUE,
    camera_distance NUMERIC(8,2) NOT NULL DEFAULT 850.00,
    camera_z_offset NUMERIC(8,2) NOT NULL DEFAULT 20.00,
    camera_angle NUMERIC(8,2) NOT NULL DEFAULT 350.00,
    camera_rotation_offset NUMERIC(8,2) NOT NULL DEFAULT 180.00,
    camera_far_z NUMERIC(10,2) NOT NULL DEFAULT 10000.00,
    camera_fov NUMERIC(8,2) NOT NULL DEFAULT 60.00,
    camera_block_radius NUMERIC(8,2) NOT NULL DEFAULT 0.00,
    camera_block_check BOOLEAN NOT NULL DEFAULT TRUE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT NOT NULL DEFAULT '',
    last_export_fingerprint VARCHAR(64) NOT NULL DEFAULT '',
    last_exported_at TIMESTAMPTZ,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT quest_givers_key_check CHECK (giver_key ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_givers_library_check CHECK (library_name ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_givers_ownership_check CHECK (ownership_mode IN ('managed', 'hybrid', 'external')),
    CONSTRAINT quest_givers_unit_code_check CHECK (unit_code IS NULL OR char_length(unit_code) = 4),
    CONSTRAINT quest_givers_variable_check CHECK (placed_unit_variable IS NULL OR placed_unit_variable ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_givers_binding_check CHECK (unit_code IS NOT NULL OR placed_unit_variable IS NOT NULL),
    CONSTRAINT quest_givers_dialog_range_check CHECK (dialog_range > 0),
    CONSTRAINT quest_givers_dialog_cooldown_check CHECK (dialog_cooldown >= 0)
);

CREATE TABLE IF NOT EXISTS quests (
    id SERIAL PRIMARY KEY,
    quest_giver_id INTEGER NOT NULL REFERENCES quest_givers(id) ON DELETE CASCADE,
    quest_key VARCHAR(64) NOT NULL,
    quest_name VARCHAR(160) NOT NULL,
    title VARCHAR(160) NOT NULL,
    quest_type VARCHAR(16) NOT NULL DEFAULT 'normal',
    category VARCHAR(16) NOT NULL DEFAULT 'general',
    quest_level INTEGER NOT NULL DEFAULT 1,
    required_level INTEGER NOT NULL DEFAULT 1,
    required_reputation INTEGER NOT NULL DEFAULT 0,
    icon_path VARCHAR(512) NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    info_text TEXT NOT NULL DEFAULT '',
    info2_text TEXT NOT NULL DEFAULT '',
    receiver_giver_id INTEGER REFERENCES quest_givers(id) ON DELETE SET NULL,
    receiver_display_name VARCHAR(128) NOT NULL DEFAULT '',
    zone_id INTEGER,
    faction VARCHAR(128) NOT NULL DEFAULT '',
    allow_nazgrek BOOLEAN NOT NULL DEFAULT TRUE,
    allow_zulkis BOOLEAN NOT NULL DEFAULT FALSE,
    requires_turn_in BOOLEAN NOT NULL DEFAULT TRUE,
    auto_complete BOOLEAN NOT NULL DEFAULT FALSE,
    fail_reason TEXT NOT NULL DEFAULT '',
    draft BOOLEAN NOT NULL DEFAULT TRUE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT quests_key_check CHECK (quest_key ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quests_type_check CHECK (quest_type IN ('normal', 'daily', 'repeatable')),
    CONSTRAINT quests_category_check CHECK (category IN ('general', 'story', 'dungeon', 'class', 'profession')),
    CONSTRAINT quests_level_check CHECK (quest_level >= 0 AND required_level >= 0),
    CONSTRAINT quests_reputation_check CHECK (required_reputation BETWEEN -20000 AND 20000),
    CONSTRAINT quests_unique_name_per_giver UNIQUE (quest_giver_id, quest_name),
    CONSTRAINT quests_unique_order_per_giver UNIQUE (quest_giver_id, sort_order)
);

CREATE TABLE IF NOT EXISTS quest_objectives (
    id SERIAL PRIMARY KEY,
    quest_id INTEGER NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    objective_key VARCHAR(64) NOT NULL,
    display_order INTEGER NOT NULL,
    objective_type VARCHAR(24) NOT NULL DEFAULT 'manual',
    text TEXT NOT NULL,
    amount INTEGER NOT NULL DEFAULT 1,
    item_code VARCHAR(4),
    unit_code VARCHAR(4),
    target_variable VARCHAR(128),
    target_name VARCHAR(160) NOT NULL DEFAULT '',
    region_variable VARCHAR(128),
    zone_id INTEGER,
    faction VARCHAR(128) NOT NULL DEFAULT '',
    required_reputation INTEGER NOT NULL DEFAULT 0,
    completion_mode VARCHAR(16) NOT NULL DEFAULT 'automatic',
    external_hook VARCHAR(128),
    notes TEXT NOT NULL DEFAULT '',
    CONSTRAINT quest_objectives_order_check CHECK (display_order BETWEEN 1 AND 8),
    CONSTRAINT quest_objectives_type_check CHECK (objective_type IN ('item', 'kill', 'escort', 'talk', 'find', 'goto', 'reputation', 'investigate', 'manual')),
    CONSTRAINT quest_objectives_amount_check CHECK (amount > 0),
    CONSTRAINT quest_objectives_item_code_check CHECK (item_code IS NULL OR char_length(item_code) = 4),
    CONSTRAINT quest_objectives_unit_code_check CHECK (unit_code IS NULL OR char_length(unit_code) = 4),
    CONSTRAINT quest_objectives_target_variable_check CHECK (target_variable IS NULL OR target_variable ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_objectives_region_variable_check CHECK (region_variable IS NULL OR region_variable ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_objectives_hook_check CHECK (external_hook IS NULL OR external_hook ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_objectives_completion_check CHECK (completion_mode IN ('automatic', 'manual', 'external')),
    CONSTRAINT quest_objectives_unique_key UNIQUE (quest_id, objective_key),
    CONSTRAINT quest_objectives_unique_order UNIQUE (quest_id, display_order)
);

CREATE TABLE IF NOT EXISTS quest_rewards (
    quest_id INTEGER PRIMARY KEY REFERENCES quests(id) ON DELETE CASCADE,
    xp_active BOOLEAN NOT NULL DEFAULT TRUE,
    xp_adjust INTEGER NOT NULL DEFAULT 0,
    gold_active BOOLEAN NOT NULL DEFAULT TRUE,
    gold_adjust INTEGER NOT NULL DEFAULT 0,
    arena_active BOOLEAN NOT NULL DEFAULT FALSE,
    arena_adjust INTEGER NOT NULL DEFAULT 0,
    reputation_active BOOLEAN NOT NULL DEFAULT FALSE,
    reputation_adjust INTEGER NOT NULL DEFAULT 0,
    reputation_linked BOOLEAN NOT NULL DEFAULT FALSE,
    item_code VARCHAR(4),
    custom_text TEXT NOT NULL DEFAULT '',
    CONSTRAINT quest_rewards_item_code_check CHECK (item_code IS NULL OR char_length(item_code) = 4)
);

CREATE TABLE IF NOT EXISTS quest_prerequisites (
    quest_id INTEGER NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    prerequisite_quest_id INTEGER NOT NULL REFERENCES quests(id) ON DELETE RESTRICT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (quest_id, prerequisite_quest_id),
    CONSTRAINT quest_prerequisites_not_self CHECK (quest_id <> prerequisite_quest_id)
);

CREATE TABLE IF NOT EXISTS quest_voicelines (
    id SERIAL PRIMARY KEY,
    speaker_key VARCHAR(64) NOT NULL,
    speaker_name VARCHAR(128) NOT NULL,
    line_key VARCHAR(160) NOT NULL,
    text TEXT NOT NULL DEFAULT '',
    constant_name VARCHAR(128),
    source_library VARCHAR(128),
    source_file VARCHAR(512),
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT quest_voicelines_speaker_check CHECK (speaker_key ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_voicelines_constant_check CHECK (constant_name IS NULL OR constant_name ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_voicelines_library_check CHECK (source_library IS NULL OR source_library ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_voicelines_unique_key UNIQUE (speaker_key, line_key)
);

CREATE TABLE IF NOT EXISTS quest_sequences (
    id SERIAL PRIMARY KEY,
    quest_giver_id INTEGER NOT NULL REFERENCES quest_givers(id) ON DELETE CASCADE,
    quest_id INTEGER REFERENCES quests(id) ON DELETE CASCADE,
    sequence_key VARCHAR(64) NOT NULL,
    display_name VARCHAR(160) NOT NULL,
    purpose VARCHAR(16) NOT NULL DEFAULT 'custom',
    show_as_dialog_option BOOLEAN NOT NULL DEFAULT FALSE,
    button_label VARCHAR(160) NOT NULL DEFAULT '',
    button_order INTEGER NOT NULL DEFAULT 0,
    on_start_hook VARCHAR(128),
    on_finish_hook VARCHAR(128),
    skippable BOOLEAN NOT NULL DEFAULT TRUE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT quest_sequences_key_check CHECK (sequence_key ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_sequences_purpose_check CHECK (purpose IN ('greet', 'info', 'farewell', 'accept', 'complete', 'fail', 'custom')),
    CONSTRAINT quest_sequences_start_hook_check CHECK (on_start_hook IS NULL OR on_start_hook ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_sequences_finish_hook_check CHECK (on_finish_hook IS NULL OR on_finish_hook ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_sequences_unique_key UNIQUE (quest_giver_id, sequence_key)
);

CREATE TABLE IF NOT EXISTS quest_sequence_steps (
    id SERIAL PRIMARY KEY,
    sequence_id INTEGER NOT NULL REFERENCES quest_sequences(id) ON DELETE CASCADE,
    display_order INTEGER NOT NULL,
    step_type VARCHAR(24) NOT NULL DEFAULT 'line',
    speaker_binding VARCHAR(128),
    speaker_name VARCHAR(128) NOT NULL DEFAULT '',
    text TEXT NOT NULL DEFAULT '',
    sound_key VARCHAR(160) NOT NULL DEFAULT '',
    voiceline_id INTEGER REFERENCES quest_voicelines(id) ON DELETE SET NULL,
    duration NUMERIC(8,2) NOT NULL DEFAULT 0.00,
    target_binding VARCHAR(128),
    point_x NUMERIC(12,2),
    point_y NUMERIC(12,2),
    action_hook VARCHAR(128),
    sound_at_unit BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT NOT NULL DEFAULT '',
    CONSTRAINT quest_sequence_steps_order_check CHECK (display_order BETWEEN 1 AND 100),
    CONSTRAINT quest_sequence_steps_type_check CHECK (step_type IN ('line', 'delay', 'face_unit', 'face_point', 'look_unit', 'look_point', 'reset_look', 'fade_out', 'fade_in', 'action')),
    CONSTRAINT quest_sequence_steps_speaker_check CHECK (speaker_binding IS NULL OR speaker_binding ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_sequence_steps_target_check CHECK (target_binding IS NULL OR target_binding ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_sequence_steps_action_check CHECK (action_hook IS NULL OR action_hook ~ '^[A-Za-z][A-Za-z0-9_]*$'),
    CONSTRAINT quest_sequence_steps_duration_check CHECK (duration >= 0),
    CONSTRAINT quest_sequence_steps_unique_order UNIQUE (sequence_id, display_order)
);

CREATE TABLE IF NOT EXISTS quest_we_dependencies (
    id SERIAL PRIMARY KEY,
    quest_giver_id INTEGER NOT NULL REFERENCES quest_givers(id) ON DELETE CASCADE,
    quest_id INTEGER REFERENCES quests(id) ON DELETE CASCADE,
    dependency_kind VARCHAR(32) NOT NULL,
    symbol VARCHAR(160) NOT NULL,
    expected_value TEXT NOT NULL DEFAULT '',
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    manual_follow_up TEXT NOT NULL DEFAULT '',
    source_evidence TEXT NOT NULL DEFAULT '',
    CONSTRAINT quest_we_dependencies_kind_check CHECK (dependency_kind IN ('unit_global', 'rect', 'camera', 'unit_rawcode', 'item_rawcode', 'gui_trigger', 'object_editor', 'placed_unit', 'audio_asset', 'other')),
    CONSTRAINT quest_we_dependencies_unique UNIQUE (quest_giver_id, dependency_kind, symbol)
);

ALTER TABLE quest_givers ADD COLUMN IF NOT EXISTS ownership_mode VARCHAR(16) NOT NULL DEFAULT 'managed';
ALTER TABLE quest_givers ADD COLUMN IF NOT EXISTS source_file VARCHAR(512) NOT NULL DEFAULT '';
ALTER TABLE quest_givers ADD COLUMN IF NOT EXISTS last_export_fingerprint VARCHAR(64) NOT NULL DEFAULT '';
ALTER TABLE quest_givers ADD COLUMN IF NOT EXISTS last_exported_at TIMESTAMPTZ;
ALTER TABLE quests ADD COLUMN IF NOT EXISTS required_reputation INTEGER NOT NULL DEFAULT 0;
ALTER TABLE quests DROP CONSTRAINT IF EXISTS quests_quest_key_key;
CREATE UNIQUE INDEX IF NOT EXISTS uq_quests_key_per_giver ON quests(quest_giver_id, quest_key);

CREATE INDEX IF NOT EXISTS idx_quests_giver ON quests(quest_giver_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_quests_receiver ON quests(receiver_giver_id);
CREATE INDEX IF NOT EXISTS idx_quest_objectives_quest ON quest_objectives(quest_id, display_order);
CREATE INDEX IF NOT EXISTS idx_quest_prerequisites_prerequisite ON quest_prerequisites(prerequisite_quest_id);
CREATE INDEX IF NOT EXISTS idx_quest_sequences_giver ON quest_sequences(quest_giver_id);
CREATE INDEX IF NOT EXISTS idx_quest_sequences_quest ON quest_sequences(quest_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_quest_sequences_single_giver_purpose
    ON quest_sequences(quest_giver_id, purpose)
    WHERE purpose IN ('greet', 'farewell');
CREATE UNIQUE INDEX IF NOT EXISTS uq_quest_sequences_single_quest_purpose
    ON quest_sequences(quest_giver_id, quest_id, purpose)
    WHERE quest_id IS NOT NULL AND purpose IN ('accept', 'complete', 'fail');
CREATE INDEX IF NOT EXISTS idx_quest_sequence_steps_sequence ON quest_sequence_steps(sequence_id, display_order);
CREATE INDEX IF NOT EXISTS idx_quest_we_dependencies_giver ON quest_we_dependencies(quest_giver_id);
CREATE INDEX IF NOT EXISTS idx_quest_we_dependencies_quest ON quest_we_dependencies(quest_id);

CREATE OR REPLACE FUNCTION quest_designer_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_quest_givers_updated_at ON quest_givers;
CREATE TRIGGER trg_quest_givers_updated_at
    BEFORE UPDATE ON quest_givers
    FOR EACH ROW EXECUTE FUNCTION quest_designer_touch_updated_at();

DROP TRIGGER IF EXISTS trg_quests_updated_at ON quests;
CREATE TRIGGER trg_quests_updated_at
    BEFORE UPDATE ON quests
    FOR EACH ROW EXECUTE FUNCTION quest_designer_touch_updated_at();

DROP TRIGGER IF EXISTS trg_quest_voicelines_updated_at ON quest_voicelines;
CREATE TRIGGER trg_quest_voicelines_updated_at
    BEFORE UPDATE ON quest_voicelines
    FOR EACH ROW EXECUTE FUNCTION quest_designer_touch_updated_at();

DROP TRIGGER IF EXISTS trg_quest_sequences_updated_at ON quest_sequences;
CREATE TRIGGER trg_quest_sequences_updated_at
    BEFORE UPDATE ON quest_sequences
    FOR EACH ROW EXECUTE FUNCTION quest_designer_touch_updated_at();

CREATE OR REPLACE VIEW v_quest_giver_overview AS
SELECT
    g.id,
    g.giver_key,
    g.display_name,
    g.library_name,
    g.unit_code,
    g.placed_unit_variable,
    g.zone_id,
    COUNT(q.id) AS quest_count,
    COUNT(q.id) FILTER (WHERE q.enabled AND NOT q.draft) AS exportable_quest_count,
    COUNT(q.id) FILTER (WHERE q.draft) AS draft_quest_count
FROM quest_givers g
LEFT JOIN quests q ON q.quest_giver_id = g.id
GROUP BY g.id;

CREATE OR REPLACE VIEW v_quest_relationships AS
SELECT
    q.id AS quest_id,
    q.quest_key,
    q.title,
    giver.giver_key,
    giver.display_name AS giver_name,
    receiver.giver_key AS receiver_key,
    receiver.display_name AS receiver_name,
    prerequisite.id AS prerequisite_id,
    prerequisite.quest_key AS prerequisite_key,
    prerequisite.title AS prerequisite_title,
    prerequisite_giver.giver_key AS prerequisite_giver_key,
    prerequisite_giver.display_name AS prerequisite_giver_name
FROM quests q
JOIN quest_givers giver ON giver.id = q.quest_giver_id
LEFT JOIN quest_givers receiver ON receiver.id = q.receiver_giver_id
LEFT JOIN quest_prerequisites edge ON edge.quest_id = q.id
LEFT JOIN quests prerequisite ON prerequisite.id = edge.prerequisite_quest_id
LEFT JOIN quest_givers prerequisite_giver ON prerequisite_giver.id = prerequisite.quest_giver_id;

COMMIT;
