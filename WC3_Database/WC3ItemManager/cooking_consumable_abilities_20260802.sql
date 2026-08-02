-- Cooking applies food/drink stats and status auras from JASS on item use.
-- Cooked outputs need only the neutral Eat/Drink ability to consume one charge.
INSERT INTO wc3_abilities (ability_code, ability_name, tooltip_normal, tooltip_extended)
VALUES ('A0F5', 'Eat/Drink', 'Eat/Drink', 'Consumes one food or beverage charge. Cooking applies the configured timed effect.')
ON CONFLICT (ability_code) DO UPDATE SET
    ability_name = EXCLUDED.ability_name,
    tooltip_normal = EXCLUDED.tooltip_normal,
    tooltip_extended = EXCLUDED.tooltip_extended,
    updated_at = CURRENT_TIMESTAMP;

DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE items
    SET wc3_abilities = 'A0F5',
        manual_abilities_data = '[{"Code":"A0F5","Type":"Use","Description":"Consumes one food or beverage charge.","TooltipNormal":"Eat/Drink","TooltipSource":"Custom","TooltipExtended":"Cooking applies the configured timed effect."}]'::jsonb,
        copy_base_abilities = FALSE,
        actively_used = TRUE,
        max_charges = GREATEST(COALESCE(max_charges, 1), 1),
        updated_at = CURRENT_TIMESTAMP
    WHERE item_code IN (
        'j0c6', 'j0c7', 'j0c8', 'j0c9', 'j0d0', 'j0d1',
        'j2a0', 'j2a1', 'j2a2', 'j2a3', 'j2a4', 'j2a5', 'j2a6', 'j2a7', 'j2a8', 'j2a9',
        'j2b0', 'j2b1', 'j2b2', 'j2b3', 'j2b4', 'j2b5', 'j2b6', 'j2b7', 'j2b9',
        'j2c0', 'j2c1', 'j2c2', 'j2c3', 'j2c4', 'j2c5', 'j2c6', 'j2c7', 'j2c8', 'j2c9',
        'j2d0', 'j2d1', 'j2d2', 'j2d3', 'j2d4',
        'j3a0', 'j3a1', 'j3a2', 'j3a3', 'j3a4', 'j3a5', 'j3a6', 'j3a7', 'j3a8', 'j3a9',
        'j3b0', 'j3b1', 'j3b2', 'j3b3', 'j3b4'
    );

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    IF updated_count <> 55 THEN
        RAISE EXCEPTION 'Expected to update 55 Cooking consumables, updated %', updated_count;
    END IF;
END $$;

SELECT COUNT(*) FILTER (
           WHERE wc3_abilities = 'A0F5'
             AND copy_base_abilities = FALSE
             AND actively_used = TRUE
       ) AS configured_cooking_consumables,
       COUNT(*) FILTER (
           WHERE COALESCE(wc3_abilities, '') ~ 'A60V|A61F'
              OR COALESCE(manual_abilities_data::text, '') ~ 'A60V|A61F'
       ) AS stale_buff_ability_references
FROM items
WHERE item_code IN (
      'j0c6', 'j0c7', 'j0c8', 'j0c9', 'j0d0', 'j0d1',
      'j2a0', 'j2a1', 'j2a2', 'j2a3', 'j2a4', 'j2a5', 'j2a6', 'j2a7', 'j2a8', 'j2a9',
      'j2b0', 'j2b1', 'j2b2', 'j2b3', 'j2b4', 'j2b5', 'j2b6', 'j2b7', 'j2b9',
      'j2c0', 'j2c1', 'j2c2', 'j2c3', 'j2c4', 'j2c5', 'j2c6', 'j2c7', 'j2c8', 'j2c9',
      'j2d0', 'j2d1', 'j2d2', 'j2d3', 'j2d4',
      'j3a0', 'j3a1', 'j3a2', 'j3a3', 'j3a4', 'j3a5', 'j3a6', 'j3a7', 'j3a8', 'j3a9',
      'j3b0', 'j3b1', 'j3b2', 'j3b3', 'j3b4'
  );
