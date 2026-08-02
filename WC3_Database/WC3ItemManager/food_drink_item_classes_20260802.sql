-- Add Food and Drink as searchable consumable classes and classify the 55
-- Cooking outputs whose existing descriptions explicitly identify their kind.
INSERT INTO item_classes (class_name, slot_type, description)
VALUES
    ('Food', 'FOOD', 'Edible consumable items'),
    ('Drink', 'DRINK', 'Drinkable consumable items')
ON CONFLICT (class_name) DO UPDATE SET
    slot_type = EXCLUDED.slot_type,
    description = EXCLUDED.description;

INSERT INTO ui_color_scheme (element_type, element_name, color_hex, description)
VALUES
    ('class', 'Food', '#D2B48C', 'Food consumables'),
    ('class', 'Drink', '#87CEEB', 'Drink consumables')
ON CONFLICT (element_type, element_name) DO NOTHING;

DO $$
DECLARE
    food_count INTEGER;
    drink_count INTEGER;
BEGIN
    UPDATE items
    SET class_id = (SELECT id FROM item_classes WHERE class_name = 'Food'),
        updated_at = CURRENT_TIMESTAMP
    WHERE item_code IN (
        'j0c6', 'j0c7', 'j0c8', 'j0c9', 'j0d0', 'j0d1',
        'j2a0', 'j2a1', 'j2a2', 'j2a3', 'j2a4', 'j2a5', 'j2a6', 'j2a7', 'j2a8', 'j2a9',
        'j2b0', 'j2b1', 'j2b2', 'j2b3', 'j2b4', 'j2b5', 'j2b6', 'j2b7', 'j2b9',
        'j2c0', 'j2c1', 'j2c2', 'j2c3', 'j2c4', 'j2c5', 'j2c6', 'j2c7', 'j2c8', 'j2c9',
        'j2d0', 'j2d1', 'j2d2', 'j2d3', 'j2d4'
    );
    GET DIAGNOSTICS food_count = ROW_COUNT;

    UPDATE items
    SET class_id = (SELECT id FROM item_classes WHERE class_name = 'Drink'),
        updated_at = CURRENT_TIMESTAMP
    WHERE item_code IN (
        'j3a0', 'j3a1', 'j3a2', 'j3a3', 'j3a4', 'j3a5', 'j3a6', 'j3a7', 'j3a8', 'j3a9',
        'j3b0', 'j3b1', 'j3b2', 'j3b3', 'j3b4'
    );
    GET DIAGNOSTICS drink_count = ROW_COUNT;

    IF food_count <> 40 OR drink_count <> 15 THEN
        RAISE EXCEPTION 'Expected 40 Food and 15 Drink items, updated % and %', food_count, drink_count;
    END IF;
END $$;

SELECT c.class_name, COUNT(*) AS item_count
FROM items i
JOIN item_classes c ON c.id = i.class_id
WHERE c.class_name IN ('Food', 'Drink')
GROUP BY c.class_name
ORDER BY c.class_name;
