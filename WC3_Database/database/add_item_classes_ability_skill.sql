BEGIN;

INSERT INTO item_classes (class_name, slot_type, description)
VALUES
    ('Ability', 'ABILITY', 'Ability-granting item slot/class'),
    ('Skill', 'SKILL', 'Skill-granting item slot/class')
ON CONFLICT (class_name) DO NOTHING;

COMMIT;
