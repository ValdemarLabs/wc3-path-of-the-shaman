-- Backfill missing model_path values for custom items
-- Custom items should inherit model_path from their base item if not explicitly set

-- Update custom items that are missing model_path
-- by copying from their base_id item
UPDATE items AS custom
SET model_path = base_item.model_path
FROM items AS base_item
WHERE custom.base_id IS NOT NULL
  AND custom.base_id = base_item.item_code
  AND base_item.model_path IS NOT NULL
  AND base_item.model_path != ''
  AND (custom.model_path IS NULL OR custom.model_path = '');

-- Report results
SELECT 
    'Backfilled model_path for ' || COUNT(*) || ' custom items' AS result
FROM items AS custom
JOIN items AS base_item ON custom.base_id = base_item.item_code
WHERE custom.base_id IS NOT NULL
  AND base_item.model_path IS NOT NULL
  AND base_item.model_path != ''
  AND custom.model_path = base_item.model_path;
