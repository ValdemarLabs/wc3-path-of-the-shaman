-- ====================================================================================================
-- ITEM CLASSES MIGRATION - SYNC WITH POTS_ItemConcept.xlsx
-- ====================================================================================================
-- This migration preserves existing IDs (for DEquipment compatibility)
-- and adds missing classes from the Excel spreadsheet
--
-- IMPORTANT: Existing IDs 1-12, 13, 16-18 are preserved
-- New entries use IDs starting from 19+
-- ====================================================================================================

BEGIN;

-- First, let's see what we have
SELECT 'BEFORE MIGRATION:' as status;
SELECT id, class_name, slot_type FROM item_classes ORDER BY id;

-- Add missing classes from Excel (Column A of POTS_ItemConcept.xlsx)
-- Using INSERT ... ON CONFLICT to safely add only new entries

-- Helm (maps to existing Head Armor - add as alias or separate?)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Helm', 'HEAD', 'Helmets and head armor (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Neck (maps to existing Amulet - add as separate type)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Neck', 'NECK', 'Necklaces and neck items (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Shoulders
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Shoulders', 'SHOULDERS', 'Shoulder armor and pauldrons (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Chest (already exists as "Chest Armor", add as alias)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Chest', 'CHEST', 'Chest pieces and torso armor (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Bracers (wrist armor)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Bracers', 'WRISTS', 'Wrist armor and bracers (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Gloves (already exists as "Hand Armor", add as alias)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Gloves', 'HANDS', 'Gloves and hand armor (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Belt
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Belt', 'BELT', 'Belts and waist armor (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Legpiece (already exists as "Leg Armor", add as alias)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Legpiece', 'LEGS', 'Leg armor and leg pieces (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Boots (already exists as "Foot Armor", add as alias)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Boots', 'FEET', 'Boots and foot armor (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Rings (already exists as "Ring", add as alias with plural)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Rings', 'RING', 'Rings (plural form from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- 1h (One-handed weapon)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('1h', 'WEAPON', 'One-handed weapons (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- 2h (Two-handed weapon - already exists as "Two-Hand Weapon", add as alias)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('2h', 'TWOHAND', 'Two-handed weapons (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Stave (Staff)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Stave', 'TWOHAND', 'Staves and staffs (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Shield (Off-hand defensive)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Shield', 'OFFHAND', 'Shields and off-hand defensive items (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Miscellaneous
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Miscellaneous', NULL, 'Miscellaneous items (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Other
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('Other', NULL, 'Other/uncategorized items (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Reserved slots (4 slots for future use)
INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('reserved_1', NULL, 'Reserved slot 1 for future expansion (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('reserved_2', NULL, 'Reserved slot 2 for future expansion (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('reserved_3', NULL, 'Reserved slot 3 for future expansion (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

INSERT INTO item_classes (class_name, slot_type, description) 
VALUES ('reserved_4', NULL, 'Reserved slot 4 for future expansion (from Excel)')
ON CONFLICT (class_name) DO NOTHING;

-- Show results
SELECT 'AFTER MIGRATION:' as status;
SELECT id, class_name, slot_type, description FROM item_classes ORDER BY id;

SELECT 'SUMMARY:' as status;
SELECT COUNT(*) as total_classes FROM item_classes;

COMMIT;

-- Report: IDs preserved for DEquipment compatibility:
-- ID 1-12: Original armor/weapon slots
-- ID 13: MISC
-- ID 16-18: CONSUMABLE, ARTIFACT, QUEST
-- ID 19+: New entries from Excel
