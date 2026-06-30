-- Ensure all powerup items are exported/handled as auto-acquire items.
ALTER TABLE items
ADD COLUMN IF NOT EXISTS use_automatically BOOLEAN DEFAULT FALSE;

UPDATE items
SET is_powerup = TRUE,
    use_automatically = TRUE
WHERE COALESCE(is_powerup, FALSE) = TRUE
   OR LOWER(COALESCE(wc3_classification, '')) = 'powerup';
