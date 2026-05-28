# WC3 POTS Database - Quick Start Cheat Sheet

## 🚀 Getting Started (Existing Database)

### 1. Run the Setup Script

```powershell
cd h:\Pelit\PotS_JASS\WC3_Database
.\setup_existing_db.bat
```

This will:
- ✅ Check your database connection
- ✅ Optionally create backup
- ✅ Install stat system (39 stats + 16 abilities)
- ✅ Verify installation

### 2. Or Manual Installation

```powershell
# Set your password
$env:PGPASSWORD="your_password"

# Apply enhancements (safe - won't delete existing data)
psql -U postgres -d wc3_pots -f schema_stats_enhancement.sql

# Verify
psql -U postgres -d wc3_pots -c "SELECT COUNT(*) FROM stat_definitions;"
# Should return 39
```

---

## 📝 Common Operations

### View Your Items

```sql
-- Connect to database
psql -U postgres -d wc3_pots

-- List all items
SELECT item_code, item_name FROM items LIMIT 10;

-- See what stats items currently have (if migrated)
SELECT * FROM v_item_stats LIMIT 10;
```

### Add Stats to an Item

```sql
-- Add +50 Strength (StatID 1)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    1,   -- Strength
    50   -- +50
);

-- Add +25% Attack Speed (StatID 20, ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    20,    -- Attack Speed
    0.25,  -- 25% (stored as decimal)
    TRUE   -- Display as percentage
);

-- Add +2% HP regeneration per second (StatID 6, ability-based)
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I000'),
    6,     -- HP Pct Per Sec
    0.02,  -- 2%
    TRUE
);
```

### View Item Stats

```sql
-- All stats for a specific item
SELECT * FROM v_item_stats WHERE item_code = 'I000';

-- Items with ability-based stats
SELECT * FROM v_item_ability_stats WHERE item_code = 'I000';

-- Quick summary
SELECT 
    i.item_code,
    i.item_name,
    COUNT(isb.statid) as stat_count
FROM items i
LEFT JOIN item_stat_bonuses isb ON i.id = isb.item_id
GROUP BY i.id, i.item_code, i.item_name
ORDER BY stat_count DESC
LIMIT 10;
```

---

## 🎯 Most Common StatIDs

| ID | Name | Type | Example Use |
|----|------|------|-------------|
| 1 | STR | Flat | `INSERT INTO item_stat_bonuses VALUES (..., 1, 50, FALSE)` |
| 2 | AGI | Flat | `INSERT INTO item_stat_bonuses VALUES (..., 2, 30, FALSE)` |
| 3 | INT | Flat | `INSERT INTO item_stat_bonuses VALUES (..., 3, 40, FALSE)` |
| 4 | HP | Flat | `INSERT INTO item_stat_bonuses VALUES (..., 4, 500, FALSE)` |
| 6 | HP%/sec | % | `INSERT INTO item_stat_bonuses VALUES (..., 6, 0.02, TRUE)` |
| 12 | DMG | Flat | `INSERT INTO item_stat_bonuses VALUES (..., 12, 100, FALSE)` |
| 20 | IAS | % | `INSERT INTO item_stat_bonuses VALUES (..., 20, 0.25, TRUE)` |
| 22 | Lifesteal | % | `INSERT INTO item_stat_bonuses VALUES (..., 22, 0.20, TRUE)` |
| 25 | Armor | Flat | `INSERT INTO item_stat_bonuses VALUES (..., 25, 10, FALSE)` |
| 31 | MS | Flat | `INSERT INTO item_stat_bonuses VALUES (..., 31, 50, FALSE)` |

**See all 39 stats:** `SELECT * FROM stat_definitions ORDER BY statid;`

---

## 📤 Export to JASS

### Export All Items

```powershell
python wc3_exporter_enhanced.py --output exports\all_items.j --format deq_enhanced
```

### Export Specific Items

```powershell
python wc3_exporter_enhanced.py --output exports\legendary.j --format deq_enhanced --items I000 I001 I002
```

### Test Single Item

```powershell
python wc3_exporter_enhanced.py --output test.j --format deq_enhanced --items I000
notepad test.j
```

---

## 🔍 Useful Queries

### Find Items Without Stats

```sql
SELECT i.item_code, i.item_name
FROM items i
LEFT JOIN item_stat_bonuses isb ON i.id = isb.item_id
WHERE isb.id IS NULL;
```

### Find Items With Specific Stat

```sql
-- Items with Strength bonuses
SELECT i.item_code, i.item_name, isb.bonus_value
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
WHERE isb.statid = 1
ORDER BY isb.bonus_value DESC;

-- Items with Attack Speed bonuses
SELECT i.item_code, i.item_name, isb.bonus_value * 100 AS "IAS %"
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
WHERE isb.statid = 20
ORDER BY isb.bonus_value DESC;
```

### Find Items Using Abilities

```sql
-- Items that will add abilities to units
SELECT DISTINCT
    i.item_code,
    i.item_name,
    sd.ability_code,
    ac.ability_name
FROM items i
JOIN item_stat_bonuses isb ON i.id = isb.item_id
JOIN stat_definitions sd ON isb.statid = sd.statid
JOIN ability_codes ac ON sd.ability_code = ac.ability_code
WHERE sd.application_method = 'ABILITY'
ORDER BY i.item_code;
```

### Stat Usage Statistics

```sql
-- How many items use each stat
SELECT 
    sd.statid,
    sd.stat_display_name,
    sd.application_method,
    COUNT(isb.item_id) as item_count
FROM stat_definitions sd
LEFT JOIN item_stat_bonuses isb ON sd.statid = isb.statid
GROUP BY sd.statid, sd.stat_display_name, sd.application_method
HAVING COUNT(isb.item_id) > 0
ORDER BY item_count DESC;
```

---

## 🔄 Migrate Old Data

### From item_bonuses Table

```sql
-- If you have old item_bonuses with bonus_type column
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, notes)
SELECT 
    item_id,
    CASE bonus_type
        WHEN 'strength' THEN 1
        WHEN 'agility' THEN 2
        WHEN 'intelligence' THEN 3
        WHEN 'hp' THEN 4
        WHEN 'damage' THEN 12
        WHEN 'armor' THEN 25
    END AS statid,
    bonus_value,
    'Migrated from old system'
FROM item_bonuses
WHERE bonus_type IN ('strength', 'agility', 'intelligence', 'hp', 'damage', 'armor')
ON CONFLICT (item_id, statid) DO NOTHING;
```

### From Hardcoded Columns

```sql
-- If your items table has strength_bonus, agility_bonus columns
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value)
SELECT id, 1, strength_bonus FROM items WHERE strength_bonus > 0
UNION ALL
SELECT id, 2, agility_bonus FROM items WHERE agility_bonus > 0
UNION ALL
SELECT id, 3, intelligence_bonus FROM items WHERE intelligence_bonus > 0
ON CONFLICT (item_id, statid) DO NOTHING;
```

---

## 🛠️ Troubleshooting

### Connection Issues

```powershell
# Test connection
$env:PGPASSWORD="your_password"
psql -U postgres -h localhost -p 5432 -d wc3_pots -c "SELECT version();"
```

### Check Installation

```sql
-- Verify tables exist
\dt stat_definitions
\dt ability_codes
\dt item_stat_bonuses

-- Verify data loaded
SELECT COUNT(*) FROM stat_definitions;  -- Should be 39
SELECT COUNT(*) FROM ability_codes;      -- Should be 16
```

### Python Issues

```powershell
# Install requirements
pip install -r requirements.txt

# Test importer/exporter
python wc3_exporter_enhanced.py --help
```

### View Logs

```sql
-- Check export history (if export_history table exists)
SELECT * FROM export_history ORDER BY created_at DESC LIMIT 10;
```

---

## 📚 Documentation

- **Complete Guide:** [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Step-by-step migration
- **Stat Reference:** [STAT_SYSTEM_REFERENCE.md](STAT_SYSTEM_REFERENCE.md) - All 39 stats detailed
- **Summary:** [ENHANCEMENT_SUMMARY.md](ENHANCEMENT_SUMMARY.md) - What was changed
- **SQL Schema:** [schema_stats_enhancement.sql](schema_stats_enhancement.sql) - Database structure

---

## ⚡ Quick Example: Create a Legendary Sword

```sql
-- 1. Create the item (if not exists)
INSERT INTO items (item_code, item_name, item_level, rarity_id)
VALUES ('ILEG', 'Legendary Sword of Power', 50, 
    (SELECT id FROM item_rarities WHERE rarity_name = 'Legendary'));

-- 2. Add multiple stats
INSERT INTO item_stat_bonuses (item_id, statid, bonus_value, bonus_value_percent)
SELECT id, 1, 100, FALSE FROM items WHERE item_code = 'ILEG'   -- +100 STR
UNION SELECT id, 12, 200, FALSE FROM items WHERE item_code = 'ILEG'  -- +200 DMG
UNION SELECT id, 20, 0.35, TRUE FROM items WHERE item_code = 'ILEG'  -- +35% IAS
UNION SELECT id, 22, 0.25, TRUE FROM items WHERE item_code = 'ILEG'  -- +25% Lifesteal
UNION SELECT id, 10, 0.20, TRUE FROM items WHERE item_code = 'ILEG'; -- +20% Crit

-- 3. View the item
SELECT * FROM v_item_stats WHERE item_code = 'ILEG';

-- 4. Export
-- python wc3_exporter_enhanced.py --output legendary_sword.j --format deq_enhanced --items ILEG
```

---

## 💡 Tips

1. **Always use statids** instead of hardcoded column names for flexibility
2. **Store percentages as decimals** (e.g., 0.25 for 25%) with `bonus_value_percent=TRUE`
3. **Use views** (`v_item_stats`, `v_item_ability_stats`) for easy querying
4. **Export frequently** to test your changes in-game
5. **Check ability codes** - some stats require specific WC3 abilities in your map

---

**Need help?** Check [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for detailed instructions!
