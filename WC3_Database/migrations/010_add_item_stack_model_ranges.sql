BEGIN;

ALTER TABLE items
ADD COLUMN IF NOT EXISTS stack_model_ranges JSONB;

COMMENT ON COLUMN items.stack_model_ranges IS
'Optional ordered JSON array of {min, max, model_path} ground-model overrides selected by item charges.';

UPDATE items
SET stack_model_ranges = CASE
    WHEN item_name IN ('Copper Bar', 'Tin Bar', 'Bronze Bar', 'Gold Bar') THEN
        '[{"min":1,"max":5,"model_path":"war3campImported\\GoldIngotRotating.mdx"},{"min":6,"max":10,"model_path":"war3campImported\\GoldIngotPyramid3Rotating.mdx"},{"min":11,"max":20,"model_path":"war3campImported\\GoldIngotPyramid6Rotating.mdx"}]'::jsonb
    WHEN item_name IN ('Silver Bar', 'Iron Bar') THEN
        '[{"min":1,"max":5,"model_path":"war3campImported\\IronIngotRotating.mdx"},{"min":6,"max":10,"model_path":"war3campImported\\IronIngotPyramid3Rotating.mdx"},{"min":11,"max":20,"model_path":"war3campImported\\IronIngotPyramid6Rotating.mdx"}]'::jsonb
    WHEN item_name = 'Mithril Bar' THEN
        '[{"min":1,"max":5,"model_path":"war3campImported\\MithrilIngotRotating.mdx"},{"min":6,"max":10,"model_path":"war3campImported\\MithrilIngotPyramid3Rotating.mdx"},{"min":11,"max":20,"model_path":"war3campImported\\MithrilIngotPyramid6Rotating.mdx"}]'::jsonb
    WHEN item_name IN ('Steel Bar', 'Arcanite Bar', 'Thorium Bar') THEN
        '[{"min":1,"max":5,"model_path":"war3campImported\\SteelIngotRotating.mdx"},{"min":6,"max":10,"model_path":"war3campImported\\SteelIngotPyramid3Rotating.mdx"},{"min":11,"max":20,"model_path":"war3campImported\\SteelIngotPyramid6Rotating.mdx"}]'::jsonb
    ELSE stack_model_ranges
END
WHERE stack_model_ranges IS NULL
AND item_name IN (
    'Copper Bar',
    'Tin Bar',
    'Silver Bar',
    'Bronze Bar',
    'Iron Bar',
    'Steel Bar',
    'Gold Bar',
    'Mithril Bar',
    'Arcanite Bar',
    'Thorium Bar'
);

COMMIT;
