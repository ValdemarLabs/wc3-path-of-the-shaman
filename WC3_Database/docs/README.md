# WC3 PotS PostgreSQL Item Database

A comprehensive PostgreSQL database system for managing Warcraft 3 items with seamless import/export capabilities for World Editor and DInventory/DEquipment subsystems.

## 📋 Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Database Schema](#database-schema)
- [Usage](#usage)
  - [Importing Data](#importing-data)
  - [Exporting Data](#exporting-data)
  - [SQL Queries](#sql-queries)
- [Integration](#integration)
  - [DInventory Integration](#dinventory-integration)
  - [DEquipment Integration](#dequipment-integration)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## ✨ Features

### Core Features
- **Complete PostgreSQL schema** for WC3 item management
- **Multi-format import** support (WC3 .txt, CSV, JSON)
- **Multi-format export** support (JASS, DEquip, DInventory, CSV, JSON)
- **Single item, selection, or bulk** operations
- **Full WC3 item property** support (stats, bonuses, requirements, abilities)
- **Item sets and set bonuses** management
- **Rarity system** with customizable levels and colors
- **Import/Export history** tracking

### Advanced Features
- Item bonuses and effects system
- Item requirements (level, class, quest, etc.)
- Item abilities tracking
- Growth item support (for DEqGrowthItem module)
- Named item support (for DEqNamedItem module)
- Custom data storage (JSONB field)
- Automatic sell value calculation
- Comprehensive indexing for performance

### Integration
- **DInventory subsystem** ready
- **DEquipment subsystem** ready
- **Item rarity module** support
- WC3 World Editor compatible
- Easy migration from existing JASS code

## 📦 Requirements

### Software Requirements
- PostgreSQL 12 or higher
- Python 3.7 or higher
- pip (Python package manager)

### Python Packages
```bash
pip install psycopg2-binary
```

### Optional
- pgAdmin 4 (for GUI database management)
- DBeaver (alternative database GUI)

## 🚀 Installation

### 1. Install PostgreSQL

**Windows:**
Download and install from [PostgreSQL Official Site](https://www.postgresql.org/download/windows/)

During installation:
- Set a password for the `postgres` user
- Default port: 5432
- Check "pgAdmin 4" for GUI management

### 2. Create Database

Open pgAdmin or use command line:

```sql
CREATE DATABASE wc3_pots;
```

### 3. Initialize Database Schema

Navigate to the database directory and run:

```bash
cd h:\Pelit\PotS_JASS\WC3_Database
psql -U postgres -d wc3_pots -f schema.sql
```

Or using pgAdmin:
1. Connect to `wc3_pots` database
2. Open Query Tool
3. Load `schema.sql`
4. Execute (F5)

### 4. Configure Database Connection

Copy the example configuration:

```bash
copy database.ini.example database.ini
```

Edit `database.ini` with your settings:

```ini
[postgresql]
host = localhost
port = 5432
database = wc3_pots
user = postgres
password = your_password_here
```

### 5. Install Python Dependencies

```bash
pip install psycopg2-binary
```

## 🎯 Quick Start

### Import Sample Data

```bash
# Import from JSON
python wc3_importer.py example_items.json --format json

# Import from CSV
python wc3_importer.py your_items.csv --format csv
```

### Export to JASS

```bash
# Export all items
python wc3_exporter.py --output ItemsDatabase.j --format jass

# Export specific items
python wc3_exporter.py --output SelectedItems.j --format jass --items I001 I002 I003

# Export to DEquipment format
python wc3_exporter.py --output DEquipmentItems.j --format deq

# Export to DInventory rarity format
python wc3_exporter.py --output DInventoryRarities.j --format dinv
```

### Query Database

```bash
# Using psql
psql -U postgres -d wc3_pots

# Then run queries
SELECT * FROM v_items_complete WHERE rarity_name = 'Legendary';
```

## 🗄️ Database Schema

### Main Tables

#### `items`
Core item data table with all WC3 properties.

**Key Fields:**
- `item_code` - WC3 4-character ID (e.g., 'I000')
- `item_name` - Display name
- `type_id` - Foreign key to item_types
- `rarity_id` - Foreign key to item_rarities
- `class_id` - Foreign key to item_classes (equipment slot)
- `set_id` - Foreign key to item_sets

**Stats Fields:**
- Combat: `damage_min`, `damage_max`, `armor`, `attack_speed`
- Attributes: `strength_bonus`, `agility_bonus`, `intelligence_bonus`
- Derived: `health_bonus`, `mana_bonus`, `health_regen`, `mana_regen`
- Resistances: `fire_resistance`, `cold_resistance`, `lightning_resistance`, `poison_resistance`

**Flags:**
- `is_droppable`, `is_sellable`, `is_soulbound`, `is_unique`
- `dinv_compatible`, `deq_compatible`
- `is_growth_item`, `is_named_item`

#### `item_bonuses`
Additional bonuses and effects for items.

```sql
INSERT INTO item_bonuses (item_id, bonus_type, bonus_name, bonus_value, description)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I001'),
    'EFFECT',
    'Fire Damage',
    25,
    '+25 Fire Damage on hit'
);
```

#### `item_requirements`
Requirements for equipping or using items.

```sql
INSERT INTO item_requirements (item_id, requirement_type, requirement_value, description)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I001'),
    'LEVEL',
    '20',
    'Requires level 20'
);
```

#### `item_abilities`
WC3 abilities granted by items.

```sql
INSERT INTO item_abilities (item_id, ability_code, ability_name, ability_description)
VALUES (
    (SELECT id FROM items WHERE item_code = 'I001'),
    'A001',
    'Cleave',
    'Deals splash damage to nearby enemies'
);
```

#### `item_sets`
Item set definitions with set bonuses.

```sql
INSERT INTO item_sets (set_name, description, set_bonus_2pc, set_bonus_3pc)
VALUES (
    'Dragon Slayer Set',
    'Armor forged to slay dragons',
    '+50 Fire Resistance',
    '+100 Fire Resistance, +10% Dragon Damage'
);
```

### Lookup Tables

- **`item_types`** - Weapon, Armor, Consumable, Quest, Material, etc.
- **`item_rarities`** - Common, Uncommon, Rare, Epic, Legendary, Artifact
- **`item_classes`** - Equipment slots (HEAD, CHEST, WEAPON, etc.)

### Views

- **`v_items_complete`** - Join all tables for complete item data
- **`v_deq_items`** - DEquipment compatible items only
- **`v_dinv_items`** - DInventory compatible items only
- **`v_items_by_rarity`** - Statistics grouped by rarity

## 📚 Usage

### Importing Data

#### From WC3 .txt Format

```bash
python wc3_importer.py UnitItemFunc.txt --format txt
```

WC3 .txt format example:
```
[I000]
Name=Health Potion
Ubertip=Restores 150 health
goldcost=50
level=1
uses=1
```

#### From CSV

```bash
python wc3_importer.py items.csv --format csv
```

CSV format (headers required):
```csv
item_code,item_name,type_name,rarity_name,item_level,gold_cost,damage_min,damage_max
I001,Rusty Sword,Weapon,Common,1,100,2,5
I002,Steel Sword,Weapon,Uncommon,5,500,8,15
```

#### From JSON

```bash
python wc3_importer.py items.json --format json
```

JSON format:
```json
[
  {
    "item_code": "I001",
    "item_name": "Health Potion",
    "type_name": "Consumable",
    "rarity_name": "Common",
    "item_level": 1,
    "gold_cost": 50
  }
]
```

#### Auto-detect Format

```bash
python wc3_importer.py items.json
# Format auto-detected from .json extension
```

#### Override Database Config

```bash
python wc3_importer.py items.json --host localhost --database wc3_test --user myuser --password mypass
```

### Exporting Data

#### Export to JASS

```bash
# Export all items
python wc3_exporter.py --output ItemsDatabase.j --format jass

# Export specific items
python wc3_exporter.py --output BossLoot.j --format jass --items I100 I101 I102
```

Generated JASS output:
```jass
library ItemsDatabase initializer Init

function CreateItem_I001 takes real x, real y returns item
    local item it = CreateItem('I001', x, y)
    call BlzSetItemName(it, "Health Potion")
    call BlzSetItemTooltip(it, "Restores 150 health")
    call SetItemCharges(it, 1)
    return it
endfunction

endlibrary
```

#### Export to DEquipment Format

```bash
python wc3_exporter.py --output DEquipmentItems.j --format deq
```

Generated output:
```jass
library DEquipmentItems initializer InitDEqItems requires DConfigurationArea

function DEqSetup_I002 takes nothing returns nothing
    local integer iid = 'I002'
    call DEqSetStatBonus(iid, STAT_STR, 10)
    call DEqSetStatBonus(iid, STAT_ARMOR, 5)
    call DEqSetDamageBonus(iid, 10, 20)
    call DEqSetRarity(iid, 2)
    call DEqSetItemLevel(iid, 10)
endfunction

function InitDEqItems takes nothing returns nothing
    call DEqSetup_I002()
endfunction

endlibrary
```

#### Export to DInventory Rarity Format

```bash
python wc3_exporter.py --output DInventoryRarities.j --format dinv
```

Generated output:
```jass
library DInventoryItemRarities initializer InitDInvRarities requires DItemRarity

function InitDInvRarities takes nothing returns nothing
    // Health Potion
    call DInvSetRarity('I001', 0)
    
    // Steel Sword
    call DInvSetRarity('I002', 1)
    
    // Flaming Blade
    call DInvSetRarity('I003', 2)
endfunction

endlibrary
```

#### Export to CSV

```bash
python wc3_exporter.py --output items_export.csv --format csv
```

#### Export to JSON

```bash
python wc3_exporter.py --output items_export.json --format json
```

### SQL Queries

See `example_queries.sql` for comprehensive examples.

#### Basic Queries

```sql
-- Get all legendary items
SELECT item_code, item_name, item_level, gold_cost
FROM v_items_complete
WHERE rarity_name = 'Legendary'
ORDER BY item_level DESC;

-- Search by name
SELECT * FROM v_items_complete
WHERE item_name ILIKE '%sword%';

-- Get items by level range
SELECT * FROM v_items_complete
WHERE item_level BETWEEN 10 AND 20;
```

#### Statistics

```sql
-- Items by rarity
SELECT rarity_name, COUNT(*) as count, AVG(gold_cost)::INTEGER as avg_cost
FROM v_items_complete
GROUP BY rarity_name, rarity_level
ORDER BY rarity_level;

-- Most powerful weapons
SELECT item_code, item_name, (damage_min + damage_max) / 2 as avg_damage
FROM v_items_complete
WHERE damage_max > 0
ORDER BY avg_damage DESC
LIMIT 10;
```

#### Insert New Item

```sql
INSERT INTO items (
    item_code, item_name, type_id, rarity_id,
    item_level, gold_cost, damage_min, damage_max,
    strength_bonus, description
) VALUES (
    'I999',
    'Awesome Sword',
    (SELECT id FROM item_types WHERE type_name = 'Weapon'),
    (SELECT id FROM item_rarities WHERE rarity_name = 'Epic'),
    15, 5000, 20, 40, 10,
    'A really awesome sword'
);
```

#### Update Item

```sql
UPDATE items
SET gold_cost = 1000, damage_max = 50
WHERE item_code = 'I001';
```

## 🔗 Integration

### DInventory Integration

The database fully supports the DInventory subsystem from the DestroyerInventoryAndEquipmentSystem.

#### Export for DInventory

```bash
# Export rarity configurations
python wc3_exporter.py --output DInvRarities.j --format dinv

# Export all DInventory compatible items
python wc3_exporter.py --output DInvItems.j --format jass
```

#### Mark Items as DInventory Compatible

```sql
UPDATE items
SET dinv_compatible = TRUE
WHERE item_code IN ('I001', 'I002', 'I003');

-- Or mark all non-quest items
UPDATE items
SET dinv_compatible = TRUE
WHERE type_id != (SELECT id FROM item_types WHERE type_name = 'Quest');
```

#### Integration Steps

1. Export rarities: `python wc3_exporter.py --output DInvRarities.j --format dinv`
2. Copy `DInvRarities.j` to your map's script folder
3. In World Editor, import the library
4. Items will automatically use database-defined rarities

### DEquipment Integration

Full support for the DEquipment subsystem.

#### Export for DEquipment

```bash
# Export equipment configurations
python wc3_exporter.py --output DEquipmentItems.j --format deq

# Export only equipment items
python wc3_exporter.py --output Weapons.j --format deq --items I002 I003 I004
```

#### Define Equipment Slots

```sql
UPDATE items
SET 
    deq_compatible = TRUE,
    equipment_slot = 'WEAPON',
    class_id = (SELECT id FROM item_classes WHERE class_name = 'Main Hand Weapon')
WHERE item_code = 'I002';
```

#### Integration Steps

1. Export equipment: `python wc3_exporter.py --output DEquipmentItems.j --format deq`
2. Copy `DEquipmentItems.j` to your map
3. The file includes all DEq configuration calls
4. Items automatically integrate with the equipment system

## 📖 Examples

### Example 1: Import Items from CSV

**items.csv:**
```csv
item_code,item_name,type_name,rarity_name,item_level,gold_cost,description
I001,Health Potion,Consumable,Common,1,50,Restores health
I002,Mana Potion,Consumable,Common,1,50,Restores mana
I003,Rusty Sword,Weapon,Common,1,100,A basic sword
```

**Import:**
```bash
python wc3_importer.py items.csv
```

**Verify:**
```sql
SELECT * FROM v_items_complete WHERE item_code IN ('I001', 'I002', 'I003');
```

### Example 2: Create Epic Item with Bonuses

```sql
-- Insert the item
INSERT INTO items (
    item_code, item_name, type_id, rarity_id, class_id,
    item_level, required_level, gold_cost,
    damage_min, damage_max, strength_bonus,
    deq_compatible, equipment_slot,
    tooltip, description
) VALUES (
    'I050',
    'Blade of the Phoenix',
    (SELECT id FROM item_types WHERE type_name = 'Weapon'),
    (SELECT id FROM item_rarities WHERE rarity_name = 'Epic'),
    (SELECT id FROM item_classes WHERE class_name = 'Main Hand Weapon'),
    15, 15, 8000,
    25, 50, 12,
    TRUE, 'WEAPON',
    'Epic Sword with Fire Damage',
    'Forged in phoenix flames'
);

-- Add fire damage bonus
INSERT INTO item_bonuses (
    item_id, bonus_type, bonus_name, bonus_value, description
) VALUES (
    (SELECT id FROM items WHERE item_code = 'I050'),
    'EFFECT',
    'Fire Damage',
    50,
    'Deals 50 bonus fire damage'
);

-- Add fire resistance
INSERT INTO item_bonuses (
    item_id, bonus_type, bonus_name, bonus_value
) VALUES (
    (SELECT id FROM items WHERE item_code = 'I050'),
    'RESISTANCE',
    'Fire Resistance',
    25
);
```

### Example 3: Export Boss Loot Table

```sql
-- Tag boss loot items
UPDATE items
SET custom_data = custom_data || '{"boss_loot": true, "boss": "Dragon King"}'::jsonb
WHERE item_code IN ('I100', 'I101', 'I102');
```

```bash
# Export boss loot
python wc3_exporter.py --output DragonKingLoot.j --format jass --items I100 I101 I102
```

### Example 4: Item Set Creation

```sql
-- Create the set
INSERT INTO item_sets (set_name, description, set_bonus_2pc, set_bonus_3pc, set_bonus_4pc)
VALUES (
    'Dragon Slayer Armor',
    'Legendary armor set for dragon hunting',
    '+50 Fire Resistance',
    '+100 Fire Resistance, +5% Movement Speed',
    '+150 Fire Resistance, +10% Movement Speed, +20% Dragon Damage'
);

-- Assign items to set
UPDATE items
SET set_id = (SELECT id FROM item_sets WHERE set_name = 'Dragon Slayer Armor')
WHERE item_code IN ('I201', 'I202', 'I203', 'I204');

-- Add detailed set bonuses
INSERT INTO item_set_bonuses (set_id, pieces_required, bonus_type, bonus_value, bonus_description)
VALUES
    ((SELECT id FROM item_sets WHERE set_name = 'Dragon Slayer Armor'), 2, 'RESISTANCE', 50, '+50 Fire Resistance'),
    ((SELECT id FROM item_sets WHERE set_name = 'Dragon Slayer Armor'), 3, 'RESISTANCE', 100, '+100 Fire Resistance'),
    ((SELECT id FROM item_sets WHERE set_name = 'Dragon Slayer Armor'), 4, 'EFFECT', 20, '+20% Damage vs Dragons');
```

## 🔧 Troubleshooting

### Connection Issues

**Problem:** `psycopg2.OperationalError: could not connect to server`

**Solution:**
1. Verify PostgreSQL is running: `pg_ctl status`
2. Check `database.ini` settings
3. Verify PostgreSQL service: Services → postgresql-x64-XX
4. Check firewall settings for port 5432

### Import Errors

**Problem:** `Failed to import item: foreign key violation`

**Solution:**
1. Verify reference data exists:
```sql
SELECT * FROM item_types;
SELECT * FROM item_rarities;
SELECT * FROM item_classes;
```
2. Use exact names from lookup tables
3. Check case sensitivity

### Export Empty Results

**Problem:** `No items to export`

**Solution:**
1. Verify items exist:
```sql
SELECT COUNT(*) FROM items;
```
2. Check compatibility flags if using `--format deq` or `dinv`
3. Verify item codes if using `--items` parameter

### Character Encoding Issues

**Problem:** Special characters display incorrectly

**Solution:**
1. Save files as UTF-8
2. Use `encoding='utf-8'` in Python scripts
3. Set PostgreSQL client encoding: `SET CLIENT_ENCODING TO 'UTF8';`

### Performance Issues

**Problem:** Slow queries

**Solution:**
```sql
-- Reindex tables
REINDEX TABLE items;

-- Update statistics
VACUUM ANALYZE items;

-- Check query plan
EXPLAIN ANALYZE SELECT * FROM v_items_complete WHERE item_level > 10;
```

## 🤝 Contributing

Feel free to extend the database schema or add new export formats!

### Adding New Export Format

1. Add method to `WC3ItemExporter` class in `wc3_exporter.py`
2. Update CLI argument parser
3. Add example to README

### Adding New Item Properties

1. Add column to `items` table in `schema.sql`
2. Update import/export scripts
3. Test with example data

## 📄 License

This database system is part of the WC3 PotS project.

---

## 📞 Support

For issues or questions:
- Check `example_queries.sql` for SQL examples
- Review `example_items.json` for data format
- Check PostgreSQL logs for errors

---

**Generated for PotS Project - 2026-03-10**
