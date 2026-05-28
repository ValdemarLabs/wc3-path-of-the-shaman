# ItemLootSystem Requirements Document

**Version:** 1.1  
**Date:** 2026-04-11  
**Status:** Draft - Design Decisions Resolved  

---

## 1. Overview

This document outlines the requirements for implementing an ItemLootTables system that integrates:
- PostgreSQL database (wc3_pots)
- ItemManager C# application
- JASS libraries for Warcraft 3

The system enables defining item drop rates from units and generating JASS loot table code from the database.

---

## 2. Database Requirements

### 2.1 Unit Types Table (NEW)

Create table `unit_types` to store WC3 unit type data imported from map files.

> **Note:** This is a "unit types" table, not individual unit instances. Each row represents a unit type definition (e.g., "Kobold Worker" type, not a specific kobold in the map).

#### 2.1.1 WC3-Imported Columns (from .w3u files)
| Column | Type | WC3 Field | Description |
|--------|------|-----------|-------------|
| `unit_code` | VARCHAR(4) PK | - | 4-char unit type ID (e.g., 'hfoo', 'Hpal') |
| `base_id` | VARCHAR(4) | - | Base unit ID for custom units (NULL if original) |
| `unit_name` | VARCHAR(255) | `unam` | Unit type display name |
| `editor_suffix` | VARCHAR(100) | `unsf` | Editor suffix (e.g., "(Level 5)") |
| `icon_path` | VARCHAR(255) | `uico` | Art - Icon path |

#### 2.1.2 Internal/Application Columns
| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL | Internal auto-increment ID |
| `unit_level` | INTEGER | Unit level (for generic drop matching) |
| `is_boss` | BOOLEAN DEFAULT FALSE | Boss unit flag (uses specific loot) |
| `loot_mode` | VARCHAR(20) DEFAULT 'generic' | 'generic', 'specific', 'both', 'none' |
| `loot_tier_id` | INTEGER FK | Reference to loot_tiers table (for generic) |
| `drop_count_min` | INTEGER DEFAULT 1 | Minimum items dropped |
| `drop_count_max` | INTEGER DEFAULT 1 | Maximum items dropped |
| `notes` | TEXT | Internal notes |
| `created_at` | TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | Last update time |

#### 2.1.3 Loot Mode Explanation
| Mode | Description | Use Case |
|------|-------------|----------|
| `generic` | Uses level-based item pool only | Normal mobs (90% of units) |
| `specific` | Uses explicit unit-item mappings only | Unique bosses with custom drops |
| `both` | Generic pool + specific additions | Bosses with custom + level-appropriate drops |
| `none` | No item drops (gold only or nothing) | Critters, summons, etc. |

#### 2.1.4 Indexes
```sql
CREATE INDEX idx_unit_types_unit_code ON unit_types(unit_code);
CREATE INDEX idx_unit_types_is_boss ON unit_types(is_boss);
CREATE INDEX idx_unit_types_loot_mode ON unit_types(loot_mode);
CREATE INDEX idx_unit_types_unit_level ON unit_types(unit_level);
```

---

### 2.2 Item Rarities Table (EXISTING)

The `item_rarities` table already exists in the database with the following rarity levels:

| rarity_id | rarity_name | Description |
|-----------|-------------|-------------|
| 0 | Common | Basic items |
| 1 | Uncommon | Slightly better items |
| 2 | Rare | Valuable items |
| 3 | Epic | Powerful items |
| 4 | Legendary | Exceptional items |
| 5 | Artifact | Unique world items |

---

### 2.3 Items Table Updates (MODIFY EXISTING)

Add columns to existing `items` table:

| Column | Type | Description |
|--------|------|-------------|
| `is_unique` | BOOLEAN DEFAULT FALSE | Item can only drop once per game |
| `item_level_unclassified` | INTEGER | For non-equippable items (from WC3 `ilvo` field) |

> **Note:** `rarity_id` column already exists in items table. All items can drop by default - no `can_drop` flag needed.

**Important:** The existing `item_level` field serves multiple purposes:
- Loot tier classification (which units drop this)
- Rarity scaling (higher rarities = higher item levels)
- Stack limit for charged items

For non-equippable items where `item_level` is used for stacks, use `item_level_unclassified` for loot matching.

---

### 2.4 Loot Tiers Table (NEW - For Generic Drops)

Create table `loot_tiers` to define level-based drop pools with rarity breakdown.

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PK | Auto-increment ID |
| `tier_name` | VARCHAR(50) UNIQUE | Identifier (e.g., "TIER_1_5", "TIER_6_10") |
| `min_unit_level` | INTEGER | Minimum unit level for this tier |
| `max_unit_level` | INTEGER | Maximum unit level for this tier |
| `description` | TEXT | Human-readable description |
| `drop_chance_base` | DECIMAL(5,2) | Base drop chance % for this tier |
| `common_item_level` | INTEGER | Item level for Common drops |
| `uncommon_item_level` | INTEGER | Item level for Uncommon drops |
| `rare_item_level` | INTEGER | Item level for Rare drops |
| `epic_item_level` | INTEGER | Item level for Epic drops (NULL if unavailable) |
| `legendary_item_level` | INTEGER | Item level for Legendary drops (NULL if unavailable) |
| `common_weight` | INTEGER DEFAULT 60 | Rarity roll weight |
| `uncommon_weight` | INTEGER DEFAULT 25 | Rarity roll weight |
| `rare_weight` | INTEGER DEFAULT 12 | Rarity roll weight |
| `epic_weight` | INTEGER DEFAULT 3 | Rarity roll weight |
| `legendary_weight` | INTEGER DEFAULT 0 | Rarity roll weight (0 = unavailable) |
| `enabled` | BOOLEAN DEFAULT TRUE | Enable/disable tier |

#### 2.3.1 Example Tiers (with Rarity Item Levels)
| Tier | Unit Lvl | Common | Uncommon | Rare | Epic | Legendary |
|------|----------|--------|----------|------|------|-----------|
| TIER_1_5 | 1-5 | 5 | 10 | 15 | - | - |
| TIER_6_10 | 6-10 | 10 | 15 | 20 | 25 | - |
| TIER_11_15 | 11-15 | 15 | 20 | 25 | 30 | 35 |
| TIER_16_20 | 16-20 | 20 | 25 | 30 | 35 | 40 |
| TIER_21_25 | 21-25 | 25 | 30 | 35 | 40 | 45 |
| TIER_26_30 | 26-30 | 30 | 35 | 40 | 45 | 50 |
| TIER_31_PLUS | 31+ | 35 | 40 | 45 | 50 | 55 |

---

### 2.5 Loot Tier Items Table (NEW - Generic Pool Overrides)

Create table `loot_tier_items` to define which items can drop from each tier. Items are matched by their `item_level` from the `items` table.

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PK | Auto-increment ID |
| `loot_tier_id` | INTEGER FK | Reference to loot_tiers |
| `item_code` | VARCHAR(4) FK | Reference to items table (NULL if using item_level range) |
| `item_level_min` | INTEGER | Minimum item level to include (if item_code is NULL) |
| `item_level_max` | INTEGER | Maximum item level to include (if item_code is NULL) |
| `weight` | INTEGER DEFAULT 100 | Relative weight for weighted random |
| `drop_chance` | DECIMAL(5,2) | Individual drop chance modifier |
| `rarity_filter` | VARCHAR(20) | Filter by rarity: 'common', 'uncommon', 'rare', 'legendary', 'all' |
| `type_filter` | VARCHAR(50) | Filter by item type: 'weapon', 'armor', 'consumable', 'all' |
| `enabled` | BOOLEAN DEFAULT TRUE | Enable/disable entry |

#### 2.4.1 How Generic Drops Work
1. Unit dies with `loot_mode = 'generic'`
2. System looks up unit's tier (from `unit_level`)
3. **Roll rarity first:** Weighted random between available rarities for this tier
4. Get the `{rarity}_item_level` for this tier (e.g., tier 1-5 + Uncommon = iLvl 10)
5. Select random item where `item_level = {rolled_item_level}` AND `rarity_id = {rolled_rarity}`
6. For non-equippable items, also check `item_level_unclassified`

**Key Benefit:** Adding a new item with `item_level = 15` and `rarity = Rare` automatically makes it droppable by units level 1-5 (their Rare pool) - NO code regeneration needed!

**Stackable Items:** After drop, call `SetItemCharges(item, GetRandomInt(1, 3))` for 1-3 stacks.

**Unique Items:** Check `is_unique` flag - if true and already dropped this game, skip.

---

### 2.6 Specific Unit-Item Drops Table (For Specific/Boss Drops)

Create junction table `unit_specific_drops` for SPECIFIC drops only (bosses, unique units).

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL PK | Auto-increment ID |
| `unit_code` | VARCHAR(4) FK | Reference to unit_types table |
| `item_code` | VARCHAR(4) FK | Reference to items table |
| `drop_chance` | DECIMAL(5,2) | Drop chance percentage (0.00 - 100.00) |
| `min_quantity` | INTEGER DEFAULT 1 | Minimum quantity dropped |
| `max_quantity` | INTEGER DEFAULT 1 | Maximum quantity dropped |
| `is_guaranteed` | BOOLEAN DEFAULT FALSE | Always drops (ignores chance) |
| `weight` | INTEGER DEFAULT 100 | Relative weight for weighted random |
| `enabled` | BOOLEAN DEFAULT TRUE | Enable/disable this drop entry |
| `notes` | TEXT | Internal notes |

#### 2.4.1 Constraints
```sql
ALTER TABLE unit_specific_drops 
ADD CONSTRAINT fk_usd_unit FOREIGN KEY (unit_code) REFERENCES unit_types(unit_code);

ALTER TABLE unit_specific_drops 
ADD CONSTRAINT fk_usd_item FOREIGN KEY (item_code) REFERENCES items(item_code);

CREATE UNIQUE INDEX idx_unit_specific_unique ON unit_specific_drops(unit_code, item_code);
```

**Note:** This table is ONLY for units with `loot_mode = 'specific'` or `'both'`. Most units (90%+) will use generic tier-based drops and won't have entries here.

---

### 2.7 Code Size Analysis

#### Problem
- 1000 unit types × 20 items each = 20,000 registration calls
- WC3 JASS has practical limits on script size and init time
- Large generated files are hard to maintain

#### Solution: Tiered Architecture
| Sublibrary | Content | Est. Lines | Regeneration |
|------------|---------|------------|--------------|
| ItemLootDefinitionsGeneric | Tier definitions (7-10 tiers) | 50-100 | Rarely (tier structure changes) |
| ItemLootDefinitionsSpecific | Boss/unique drops only | 200-500 | When boss loot changes |

#### Why This Works
- **Generic drops:** Computed at runtime using `unit_level` → `loot_tier` → `item_level` matching
- **Items table already has `item_level`:** No extra data entry needed per item
- **Only specific/boss drops in code:** Maybe 50-100 bosses with 5-10 specific items each = 500-1000 lines max
- **New items auto-drop:** Add an item with `item_level = 15`, it automatically drops from level-appropriate units

---

## 3. ItemManager Application Requirements

### 3.1 Unit Type Import Feature

#### 3.1.1 Import Source
- Parse `.w3u` (unit object data) files from WC3 map for **custom units**
- Parse WC3 base unit data files for **standard/original units**
- Support importing all units (both original and custom)

**Reference Libraries:**
- [War3Net](https://github.com/Drake53/War3Net) - C# library for WC3 file formats
- [wc3data](https://github.com/d07RiV/wc3data) - JavaScript WC3 data parser

**Python Implementation:**
- Use existing `wc3_data_parser` as base
- May need separate parser script for unit object data format
- Consider porting relevant War3Net parsing logic if needed

**Fields to Extract:**
| WC3 Field | Column | Description |
|-----------|--------|-------------|
| `unam` | `unit_name` | Unit display name |
| `unsf` | `editor_suffix` | Editor suffix (e.g., "(Level 5)") |
| `uico` | `icon_path` | Art - Icon path |
| `ulev` | `unit_level` | Unit level (for tier matching) |

#### 3.1.2 Import Behavior
- **New unit types:** INSERT into database with `loot_mode = 'generic'` default
- **Existing unit types:** UPDATE name/suffix/icon/level (preserve loot settings)
- **Removed unit types:** Flag or soft-delete (preserve loot data)

#### 3.1.3 Import UI
- File browser to select `.w3u` file (and/or base unit data)
- Preview of units to import (with level column)
- Conflict resolution options
- Import progress indicator

---

### 3.2 Unit Type Management UI

#### 3.2.1 Unit Type List View
- Searchable/filterable list of all unit types
- Columns: Icon, Name, Suffix, Level, Loot Mode, Boss flag
- Quick filters: Boss only, By loot mode, By level range
- Color coding: Generic (gray), Specific (blue), Both (purple), None (red)

#### 3.2.2 Unit Type Edit Form
- **Basic info (read-only from WC3):** Name, Suffix, Icon
- **Loot Settings:**
  - Unit Level (integer input)
  - Is Boss (checkbox)
  - Loot Mode (dropdown: Generic, Specific, Both, None)
  - Drop Count Range (min/max inputs)
- **Specific Drops Panel** (only visible if mode = Specific or Both):
  - Grid showing specific item drops for this unit
  - Add/Remove item drops
  - Edit drop chance, quantity, weight
  - Note: "For most units, use Generic mode. Only define specific drops for bosses."

---

### 3.3 Loot Tier Management UI (NEW)

#### 3.3.1 Tier List View
- List of all loot tiers
- Columns: Tier Name, Unit Level Range, Base Drop Chance, Rarities Available
- Add/Edit/Delete tiers

#### 3.3.2 Tier Edit Form

**Basic Settings:**
- Tier Name (e.g., "TIER_1_5")
- Unit Level Range (min/max)
- Base Drop Chance (%)
- Description
- Enabled (checkbox)

**Per-Rarity Configuration (grid or grouped inputs):**

| Rarity | Item Level | Weight | Available |
|--------|------------|--------|-----------|
| Common | [input] | [input] | [checkbox] |
| Uncommon | [input] | [input] | [checkbox] |
| Rare | [input] | [input] | [checkbox] |
| Epic | [input] | [input] | [checkbox] |
| Legendary | [input] | [input] | [checkbox] |
| Artifact | [input] | [input] | [checkbox] |

- **Item Level:** Items with this level (and matching rarity) drop from this tier
- **Weight:** Relative probability of rolling this rarity (0 = disabled)
- **Available:** Quick toggle (sets weight to 0 if unchecked)

**Preview Panel:**
- Shows count of items that would match each rarity for this tier
- Example: "Common (iLvl 5): 42 items, Uncommon (iLvl 10): 28 items..."

---

### 3.4 Item Edit Integration

#### 3.4.1 Item Level Fields - Important Clarification

The Item Edit form should clearly explain the dual-purpose fields:

| Field | Usage | Items Affected |
|-------|-------|----------------|
| **Item Level** | Loot tier + Rarity classification, AND max stack for charged items | Equippable items |
| **Item Level (Unclassified)** | Loot tier classification only | Consumables, quest items, misc |
| **Is Unique** | Can only drop once per game | Legendary/special items |

**UI Guidance Text:**
> "For equippable items, Item Level determines both the loot tier and max charges for stackable variants.
> For consumables/misc items, use 'Item Level (Unclassified)' from WC3's ilvo field for loot classification."

#### 3.4.2 "Loot Info" Tab/Panel in Item Edit
- **Item Level** (already exists): Used for generic tier matching
- **Specific Drops From** section:
  - Grid showing which units have this as a SPECIFIC drop
  - Only shows units with `loot_mode = 'specific'` or `'both'`
  - Add button: Opens unit selector (filtered to boss/specific units)
  - Note: "Most items drop generically based on Item Level + Rarity. Only add specific drops for special loot."

#### 3.4.3 Generic Drop Preview
- Read-only info showing which tiers this item falls into based on its level and rarity
- Example: "Item Level 15, Rarity: Rare → Drops from: Tier 1 (units 1-5 Rare pool), Tier 2 (units 6-10 Rare pool)"

#### 3.4.4 Base Item Selection - WC3 Classification Inheritance

When selecting a Base Item, the WC3 Classification field should auto-populate based on the base item's classification.

**Behavior:**

| Scenario | Action |
|----------|--------|
| **New item / First base selection** | Auto-set WC3 Classification from base item (no prompt) |
| **Base item changed, WC3 Classification empty** | Auto-set WC3 Classification from new base item (no prompt) |
| **Base item changed, WC3 Classification already set** | Show confirmation dialog |

**Confirmation Dialog (when both fields already have values):**
```
Title: Update WC3 Classification?

The new base item has a different WC3 Classification.
Current: [Permanent]
New base item: [Charged]

Do you want to update the WC3 Classification to match the new base item?

[Yes]  [No]  [Cancel]
```

| Button | Result |
|--------|--------|
| **Yes** | Update WC3 Classification to match new base item, keep new base selection |
| **No** | Keep existing WC3 Classification, keep new base selection |
| **Cancel** | Revert base item selection to previous value |

---

### 3.5 JASS Export Feature

#### 3.5.1 Export Command
- CLI: `python export_loot_tables.py <output_path>`
- GUI: Export button in ItemManager

#### 3.5.2 Export Options
- Export all or selected units
- Include/exclude disabled entries
- Format options (comments, debug statements)

---

### 3.6 Logs Tab (NEW)

Simple lightweight logging for tracking application events and errors.

#### 3.6.1 UI
- **"Logs" tab** in main application window
- Read-only text area showing log entries
- Auto-scroll to latest entry
- Optional: Filter by log level (Info, Warning, Error)
- Optional: Clear/refresh button

#### 3.6.2 Log File Structure
- **Location:** `<AppFolder>/Logs/`
- **Filename:** `ItemManager_YYYY-MM-DD_HHmmss.log` (new file per session)
- **Format:** Plain text, human-readable
- **Line format:** `[YYYY-MM-DD HH:mm:ss] [LEVEL] Message`

#### 3.6.3 Log Levels
| Level | Use Case |
|-------|----------|
| INFO | Application start/stop, successful operations, exports |
| WARN | Non-critical issues, fallback behaviors |
| ERROR | Failed operations, database errors, exceptions |

#### 3.6.4 What to Log
- Application startup/shutdown
- Database connection success/failure
- Import operations (unit types, items)
- Export operations (JASS files)
- Save/update operations with counts
- Errors with stack traces (ERROR level)

#### 3.6.5 Implementation Notes
- Lightweight: Simple `StreamWriter` append, no heavy logging frameworks
- Files viewable with any text editor outside the application
- Consider log rotation: Delete logs older than 30 days on startup

---

### 3.7 TooltipGenerator Enhancement (UPDATE)

The current TooltipGenerator.cs has limited text variation. This enhancement adds rich, varied tooltip text based on item class, rarity, stats, and more.

#### 3.7.1 External Phrase Dictionary File

**Location:** `<AppFolder>/Data/TooltipPhrases.json`

**Structure:**
```json
{
  "version": "1.0",
  "flavorText": {
    "byRarity": {
      "Common": [
        "Every journey begins with a single step.",
        "Humble beginnings often lead to greatness.",
        "Simple, yet reliable in times of need.",
        "Found in many a traveler's pack.",
        "Basic equipment for the aspiring adventurer."
      ],
      "Uncommon": [
        "Not all treasures gleam with gold.",
        "A cut above the mundane.",
        "Sought after by knowledgeable adventurers.",
        "Quality that stands the test of time.",
        "Crafted with care and skill."
      ],
      "Rare": [
        "Few have seen such magnificence.",
        "A prize worth the seeking.",
        "Discovered in forgotten places.",
        "Whispered about in tavern tales.",
        "Touched by fortune's hand."
      ],
      "Epic": [
        "Legends speak of such artifacts.",
        "Power that shapes destinies.",
        "Forged in the fires of ancient conflict.",
        "Only the worthy may wield it.",
        "A relic from ages past."
      ],
      "Legendary": [
        "Heroes are forged by items such as these.",
        "Songs will be sung of this artifact.",
        "The stuff of myth made real.",
        "Rarest of the rare, most powerful of powers.",
        "The cosmos itself trembles at its presence."
      ]
    },
    "byClass": {
      "Weapon": [
        "Forged for battle.",
        "A deadly instrument of war.",
        "Eager to taste blood.",
        "The balance speaks of a master smith.",
        "This blade has seen many conflicts."
      ],
      "Armor": [
        "Protection against the darkness.",
        "Hardened in countless battles.",
        "A bulwark against harm.",
        "Shields the wearer from peril.",
        "Crafted for defense, built for survival."
      ],
      "Ring": [
        "A circle of power unbroken.",
        "Small, yet potent.",
        "Mysteries bound in precious metal.",
        "Whispers of enchantment linger.",
        "Power condensed into perfect form."
      ],
      "Amulet": [
        "A talisman of protection.",
        "Ancient magic pulses within.",
        "Close to the heart, close to power.",
        "A pendant of considerable might.",
        "Blessings etched in every facet."
      ],
      "Trinket": [
        "A curious artifact.",
        "More than meets the eye.",
        "Subtle power awaits activation.",
        "A pocket of potential.",
        "Unassuming, yet invaluable."
      ],
      "Consumable": [
        "Use wisely.",
        "A temporary boon.",
        "When the moment demands it.",
        "Single use, lasting impact.",
        "Keep it close for emergencies."
      ],
      "Material": [
        "Raw potential awaits.",
        "A component of greater things.",
        "Valued by craftsmen everywhere.",
        "The building blocks of power.",
        "Quality ingredients for quality results."
      ]
    },
    "byDominantStat": {
      "Strength": [
        "Imbued with raw physical might, this item channels the strength of ancient warriors.",
        "The bearer feels their muscles surge with newfound power.",
        "Forged in the heart of a mountain, it carries the weight of stone.",
        "Warriors of old sought such items to crush their foes."
      ],
      "Agility": [
        "Swift as the wind, this artifact enhances the bearer's grace.",
        "Movement becomes fluid, reactions quickened.",
        "Crafted for those who strike before being seen.",
        "The shadow's blessing rests upon it."
      ],
      "Intelligence": [
        "Crackling with arcane energy, this relic amplifies magical prowess.",
        "Knowledge flows through it like water through a river.",
        "Mages prize such artifacts above gold.",
        "The arcane whispers secrets to its bearer."
      ],
      "Vitality": [
        "Blessed with vitality, this item fortifies life force.",
        "The pulse of life beats strong within.",
        "Against death itself, this offers protection.",
        "Health flows abundant to the bearer."
      ],
      "Mana": [
        "Resonating with magical essence, reserves of power expand.",
        "The wellspring of magic deepens.",
        "Spells flow more freely in its presence.",
        "Arcane energy gathers around the bearer."
      ],
      "Damage": [
        "Forged in battle, this weapon thirsts for devastation.",
        "Destruction incarnate, ready to be unleashed.",
        "Enemies fall swiftly before such might.",
        "Pure offensive power, concentrated and deadly."
      ],
      "Armor": [
        "Hardened through countless conflicts, protection unyielding.",
        "Blows glance away harmlessly.",
        "A fortress in wearable form.",
        "Safety in the chaos of battle."
      ],
      "Critical": [
        "Sharp and deadly, enhancing lethal precision.",
        "Find the weakness, exploit it ruthlessly.",
        "Every strike carries the potential for devastation.",
        "Precision elevated to an art form."
      ]
    },
    "closingLines": {
      "Common": [
        "A reliable piece of equipment.",
        "Sturdy and practical.",
        "Simple, yet effective.",
        "Gets the job done."
      ],
      "Uncommon": [
        "Well-crafted and dependable.",
        "Finely made and useful.",
        "A notch above the ordinary.",
        "Worth keeping."
      ],
      "Rare": [
        "A treasure worth protecting.",
        "A find most fortunate.",
        "Rare and valuable indeed.",
        "Guard it well."
      ],
      "Epic": [
        "The stuff of legends.",
        "A relic of great power.",
        "Few items match its majesty.",
        "Destiny awaits its bearer."
      ],
      "Legendary": [
        "Few have wielded such power.",
        "A legend made manifest.",
        "The pinnacle of craftsmanship.",
        "History will remember its bearer."
      ]
    },
    "classSpecificClosing": {
      "Weapon": [
        "May it strike true.",
        "Victory awaits.",
        "Let none stand before you."
      ],
      "Armor": [
        "Stand firm against the darkness.",
        "Let no blow find you.",
        "Protection eternal."
      ],
      "Ring": [
        "Wear it with purpose.",
        "Its power is yours to command.",
        "A circle of fate."
      ],
      "Amulet": [
        "Keep it close to your heart.",
        "Its blessing upon you.",
        "Protected by ancient magic."
      ]
    }
  },
  "templates": {
    "standard": "{flavor}|n|n{statLore}|n|n{closing}",
    "minimal": "{flavor}|n|n{closing}",
    "detailed": "{classIntro}|n|n{flavor}|n|n{statLore}|n|n{closing} {classClosing}"
  }
}
```

#### 3.7.2 TooltipGenerator Changes

**New Methods:**
```csharp
// Load phrases from external JSON file
private TooltipPhrases LoadPhrases();

// Get random phrase from category
private string GetRandomPhrase(string[] options);

// Build tooltip using template
private string BuildFromTemplate(string template, Dictionary<string, string> values);

// Get phrase based on dominant stat
private string GetStatLore(string dominantStatCode);

// Get class-specific intro/closing
private string GetClassPhrase(string className, string category);
```

**Generation Flow:**
1. Load phrases from `TooltipPhrases.json` (cache on first load)
2. Determine dominant stat from item stats
3. Select template based on rarity or config
4. Fill template with randomly selected phrases:
   - `{flavor}` from `byRarity` + optionally `byClass`
   - `{statLore}` from `byDominantStat` (if stats exist)
   - `{closing}` from `closingLines`
   - `{classIntro}` / `{classClosing}` from class-specific sections
5. Return formatted tooltip

#### 3.7.3 Phrase Selection Rules

| Component | Selection Source | Fallback |
|-----------|------------------|----------|
| Flavor text | `byRarity[rarity]` → `byClass[class]` (50% chance to append) | Generic phrase |
| Stat lore | `byDominantStat[stat]` | Skip if no stats |
| Closing | `closingLines[rarity]` | Generic closing |
| Class closing | `classSpecificClosing[class]` (30% chance) | Skip |

#### 3.7.4 Stat Code Mapping

The JSON uses display names but code uses stat codes. Add mapping section to `TooltipPhrases.json`:

```json
{
  "statCodeMapping": {
    "str": "Strength",
    "agi": "Agility",
    "int": "Intelligence",
    "vit": "Vitality",
    "hp": "Vitality",
    "mp": "Mana",
    "mana": "Mana",
    "dmg": "Damage",
    "damage": "Damage",
    "armor": "Armor",
    "def": "Armor",
    "crit": "Critical",
    "critchance": "Critical",
    "lifesteal": "Damage",
    "spell_power": "Intelligence",
    "attack_speed": "Agility",
    "move_speed": "Agility",
    "dodge": "Agility",
    "block": "Armor"
  }
}
```

**Usage in TooltipGenerator:**
```csharp
private string GetStatDisplayName(string statCode)
{
    if (_phrases.StatCodeMapping.TryGetValue(statCode.ToLower(), out var displayName))
        return displayName;
    return "Power"; // Fallback for unknown stats
}

private string GetStatLore(string statCode)
{
    var displayName = GetStatDisplayName(statCode);
    if (_phrases.FlavorText.ByDominantStat.TryGetValue(displayName, out var phrases))
        return GetRandomPhrase(phrases);
    return null;
}
```

#### 3.7.5 Benefits

1. **External file:** Edit phrases without recompiling
2. **Easy expansion:** Add new rarities/classes by editing JSON
3. **Templates:** Different tooltip styles per rarity or setting
4. **Combination variety:** Random selection from multiple pools = thousands of combinations
5. **Translatable:** JSON file could be swapped for localization

---

## 4. JASS Library Architecture

### 4.1 Library Structure

```
ItemLootSystem.j                    (Main library - logic, events, API, generic drop computation)
    ├── ItemLootDefinitionsGeneric.j   (Generated - tier definitions, compact)
    └── ItemLootDefinitionsSpecific.j  (Generated - boss/unique drops only)
```

### 4.2 ItemLootSystem.j (Main Library)

#### 4.2.1 Dependencies
```jass
library ItemLootSystem initializer Init requires Table, optional TimerUtils
```

#### 4.2.2 Data Structures (using Table)

```jass
// === TIER SYSTEM (Generic Drops) ===
// Tier definitions (registered by ItemLootDefinitionsGeneric)
private Table tierMinLevel        // tier_id -> min_unit_level
private Table tierMaxLevel        // tier_id -> max_unit_level  
private Table tierDropChance      // tier_id -> base_drop_chance (0-10000)
private integer tierCount = 0

// Rarity item levels per tier: tierRarityItemLevel[tier_id * 10 + rarity_id] = item_level
private Table tierRarityItemLevel  // tier_rarity_key -> item_level for that rarity
private Table tierRarityWeight     // tier_rarity_key -> weight for rarity roll

// Item lookup by (item_level, rarity) -> item pool
private Table itemPoolTable        // (item_level * 100 + rarity_id) -> first_item_index
private Table itemPoolNext         // item_index -> next_item_index (linked list)
private Table itemPoolItemType     // item_index -> item_type_id
private Table itemPoolWeight       // item_index -> weight

// Unique item tracking (items that can only drop once per game)
private Table uniqueItemDropped    // item_type_id -> boolean (has dropped this game)
private Table itemIsUnique         // item_type_id -> boolean (from database)

// === SPECIFIC DROPS (Boss/Unique) ===
// Unit -> has specific drops flag
private Table unitHasSpecificDrops  // unit_type_id -> boolean
private Table unitSpecificTableId   // unit_type_id -> specific_table_id

// Specific drop entries (linked list per table)
private Table specificDropItem      // entry_id -> item_type_id
private Table specificDropChance    // entry_id -> drop_chance (0-10000)
private Table specificDropWeight    // entry_id -> weight
private Table specificDropMinQty    // entry_id -> min_quantity
private Table specificDropMaxQty    // entry_id -> max_quantity
private Table specificDropNext      // entry_id -> next_entry_id

// === UNIT OVERRIDES ===
private Table unitLootMode          // unit_type_id -> LOOT_MODE_* constant
private Table unitDropCountMin      // unit_type_id -> min_drop_count
private Table unitDropCountMax      // unit_type_id -> max_drop_count
```

#### 4.2.3 Constants
```jass
// Loot modes
globals
    constant integer LOOT_MODE_GENERIC  = 0  // Use tier-based drops
    constant integer LOOT_MODE_SPECIFIC = 1  // Use specific drops only
    constant integer LOOT_MODE_BOTH     = 2  // Generic + specific
    constant integer LOOT_MODE_NONE     = 3  // No drops
endglobals
```

#### 4.2.4 Public API - Registration (for generated libraries)
```jass
// === TIER REGISTRATION (ItemLootDefinitionsGeneric) ===
function RegisterLootTier takes integer tierId, integer minUnitLevel, integer maxUnitLevel, integer dropChance returns nothing
function RegisterTierRarity takes integer tierId, integer rarityId, integer itemLevel, integer weight returns nothing

// === ITEM POOL REGISTRATION (ItemLootDefinitionsGeneric) ===
// Registers item to the (itemLevel, rarity) pool for generic drops
function RegisterItemToPool takes integer itemTypeId, integer itemLevel, integer rarityId, integer weight, boolean isUnique returns nothing

// === SPECIFIC DROP REGISTRATION (ItemLootDefinitionsSpecific) ===
function RegisterUnitSpecificTable takes integer unitTypeId, integer tableId returns nothing
function RegisterSpecificDrop takes integer tableId, integer itemTypeId, integer dropChance, integer weight, integer minQty, integer maxQty returns nothing

// === UNIT OVERRIDE REGISTRATION ===
function RegisterUnitLootMode takes integer unitTypeId, integer lootMode returns nothing
function RegisterUnitDropCounts takes integer unitTypeId, integer minDrops, integer maxDrops returns nothing
```

#### 4.2.5 Public API - Runtime
```jass
// Main drop function (called on unit death)
function RollLootForUnit takes unit dyingUnit returns nothing

// Utility functions
function GetUnitLootMode takes integer unitTypeId returns integer
function GetTierForUnitLevel takes integer unitLevel returns integer
function IsUniqueItemDropped takes integer itemTypeId returns boolean

// Configuration
function SetLootDropRadius takes real radius returns nothing
function SetGenericDropsEnabled takes boolean enabled returns nothing

// Events (for custom handling)
function RegisterOnItemDropped takes code callback returns nothing
function RegisterOnLootRolled takes code callback returns nothing
```

#### 4.2.6 Core Logic - Generic Drop Computation
```jass
// Rarity constants (must match database item_rarities.rarity_id values)
globals
    constant integer RARITY_COMMON    = 0
    constant integer RARITY_UNCOMMON  = 1
    constant integer RARITY_RARE      = 2
    constant integer RARITY_EPIC      = 3
    constant integer RARITY_LEGENDARY = 4
    constant integer RARITY_ARTIFACT  = 5
endglobals

// Roll rarity based on tier weights
private function RollRarityForTier takes integer tierId returns integer
    local integer totalWeight = 0
    local integer roll
    local integer cumulative = 0
    local integer r = RARITY_COMMON
    
    // Sum weights for available rarities in this tier
    loop
        exitwhen r > RARITY_ARTIFACT
        set totalWeight = totalWeight + tierRarityWeight[tierId * 10 + r]
        set r = r + 1
    endloop
    
    if totalWeight == 0 then
        return -1 // No drops available
    endif
    
    set roll = GetRandomInt(1, totalWeight)
    set r = RARITY_COMMON
    loop
        exitwhen r > RARITY_ARTIFACT
        set cumulative = cumulative + tierRarityWeight[tierId * 10 + r]
        if roll <= cumulative then
            return r
        endif
        set r = r + 1
    endloop
    return RARITY_COMMON
endfunction

// Get items that can drop for a unit level (computed at runtime)
private function RollGenericDrop takes integer unitLevel, real x, real y returns nothing
    local integer tierId = GetTierForUnitLevel(unitLevel)
    local integer dropChance = tierDropChance[tierId]
    local integer rarity
    local integer itemLevel
    local integer itemTypeId
    local item droppedItem
    
    // Roll drop chance first
    if GetRandomInt(0, 10000) > dropChance then
        return
    endif
    
    // Step 1: Roll rarity
    set rarity = RollRarityForTier(tierId)
    if rarity < 0 then
        return // No rarities available for this tier
    endif
    
    // Step 2: Get item level for this tier+rarity combo
    set itemLevel = tierRarityItemLevel[tierId * 10 + rarity]
    if itemLevel == 0 then
        return
    endif
    
    // Step 3: Get random item from pool (item_level, rarity)
    set itemTypeId = GetRandomItemFromPool(itemLevel, rarity)
    if itemTypeId == 0 then
        return
    endif
    
    // Step 4: Check unique item restriction
    if itemIsUnique[itemTypeId] and uniqueItemDropped[itemTypeId] then
        return // Already dropped this game
    endif
    
    // Step 5: Create the item
    set droppedItem = CreateItem(itemTypeId, x, y)
    
    // Step 6: Handle stackable items (1-3 stacks)
    if GetItemCharges(droppedItem) > 0 then
        call SetItemCharges(droppedItem, GetRandomInt(1, 3))
    endif
    
    // Step 7: Mark unique items as dropped
    if itemIsUnique[itemTypeId] then
        set uniqueItemDropped[itemTypeId] = true
    endif
    
    set droppedItem = null
endfunction

// Get appropriate tier for unit level
private function GetTierForUnitLevel takes integer unitLevel returns integer
    local integer i = 1
    loop
        exitwhen i > tierCount
        if unitLevel >= tierMinLevel[i] and unitLevel <= tierMaxLevel[i] then
            return i
        endif
        set i = i + 1
    endloop
    return 0  // No matching tier
endfunction
```

#### 4.2.7 Core Logic - Death Event Handler
```jass
private function OnUnitDeath takes nothing returns boolean
    local unit dyingUnit = GetDyingUnit()
    local integer unitType = GetUnitTypeId(dyingUnit)
    local integer lootMode = GetUnitLootMode(unitType)
    local integer unitLevel = GetUnitLevel(dyingUnit)
    local real x = GetUnitX(dyingUnit)
    local real y = GetUnitY(dyingUnit)
    
    if lootMode == LOOT_MODE_NONE then
        set dyingUnit = null
        return false
    endif
    
    // Roll generic drops (if mode allows)
    if lootMode == LOOT_MODE_GENERIC or lootMode == LOOT_MODE_BOTH then
        call RollGenericDrop(unitLevel, x, y)
    endif
    
    // Roll specific drops (if mode allows)
    if lootMode == LOOT_MODE_SPECIFIC or lootMode == LOOT_MODE_BOTH then
        call RollSpecificDrops(unitType, x, y)
    endif
    
    // Note: Gold is handled by WC3's native bounty system, not here
    
    set dyingUnit = null
    return false
endfunction
```

#### 4.2.8 Initialization
```jass
private function Init takes nothing returns nothing
    // Initialize all Tables
    set tierMinLevel = Table.create()
    set tierMaxLevel = Table.create()
    // ... etc
    
    // Register death event
    local trigger t = CreateTrigger()
    call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddCondition(t, Condition(function OnUnitDeath))
endfunction
```

#### 4.2.9 Missing Functions (To Be Implemented)

**GetRandomItemFromPool - Weighted random selection from item pool:**
```jass
// Pool key format: itemLevel * 100 + rarityId
private function GetRandomItemFromPool takes integer itemLevel, integer rarity returns integer
    local integer poolKey = itemLevel * 100 + rarity
    local integer firstIndex = itemPoolTable[poolKey]
    local integer totalWeight = 0
    local integer currentIndex = firstIndex
    local integer roll
    local integer cumulative = 0
    
    // First pass: calculate total weight
    loop
        exitwhen currentIndex == 0
        set totalWeight = totalWeight + itemPoolWeight[currentIndex]
        set currentIndex = itemPoolNext[currentIndex]
    endloop
    
    if totalWeight == 0 then
        return 0 // No items in pool
    endif
    
    // Second pass: weighted random selection
    set roll = GetRandomInt(1, totalWeight)
    set currentIndex = firstIndex
    loop
        exitwhen currentIndex == 0
        set cumulative = cumulative + itemPoolWeight[currentIndex]
        if roll <= cumulative then
            return itemPoolItemType[currentIndex]
        endif
        set currentIndex = itemPoolNext[currentIndex]
    endloop
    
    return 0
endfunction
```

**RollSpecificDrops - Process specific drop table for unit:**
```jass
private function RollSpecificDrops takes integer unitType, real x, real y returns nothing
    local integer tableId = unitSpecificTableId[unitType]
    local integer entryId
    local integer itemTypeId
    local integer dropChance
    local integer quantity
    local item droppedItem
    local integer i
    
    if tableId == 0 then
        return // No specific drops for this unit
    endif
    
    // Get first entry in linked list
    set entryId = specificDropFirst[tableId]
    
    loop
        exitwhen entryId == 0
        
        set itemTypeId = specificDropItem[entryId]
        set dropChance = specificDropChance[entryId]
        
        // Roll for this drop
        if GetRandomInt(0, 10000) <= dropChance then
            // Check unique restriction
            if not (itemIsUnique[itemTypeId] and uniqueItemDropped[itemTypeId]) then
                // Roll quantity
                set quantity = GetRandomInt(specificDropMinQty[entryId], specificDropMaxQty[entryId])
                
                // Create items
                set i = 0
                loop
                    exitwhen i >= quantity
                    set droppedItem = CreateItem(itemTypeId, x + GetRandomReal(-50, 50), y + GetRandomReal(-50, 50))
                    
                    // Handle stackable
                    if GetItemCharges(droppedItem) > 0 then
                        call SetItemCharges(droppedItem, GetRandomInt(1, 3))
                    endif
                    
                    set i = i + 1
                endloop
                
                // Mark unique
                if itemIsUnique[itemTypeId] then
                    set uniqueItemDropped[itemTypeId] = true
                endif
            endif
        endif
        
        // Next entry
        set entryId = specificDropNext[entryId]
    endloop
    
    set droppedItem = null
endfunction
```

**BuildItemPools - Called during init to organize items by (level, rarity):**
```jass
// Global counter for pool entries
globals
    private integer itemPoolNextIndex = 1
endglobals

// Called by RegisterItemToPool from generated library
function RegisterItemToPool takes integer itemTypeId, integer itemLevel, integer rarityId, integer weight, boolean isUnique returns nothing
    local integer poolKey = itemLevel * 100 + rarityId
    local integer newIndex = itemPoolNextIndex
    
    // Store item data
    set itemPoolItemType[newIndex] = itemTypeId
    set itemPoolWeight[newIndex] = weight
    set itemIsUnique[itemTypeId] = isUnique
    
    // Insert at head of linked list
    set itemPoolNext[newIndex] = itemPoolTable[poolKey]
    set itemPoolTable[poolKey] = newIndex
    
    set itemPoolNextIndex = itemPoolNextIndex + 1
endfunction
```

**Additional Data Structure:**
```jass
// Add to data structures section:
private Table specificDropFirst  // tableId -> first_entry_id in linked list
```

---

### 4.3 ItemLootDefinitionsGeneric.j (Generated - Compact)

This library defines loot tiers and item levels. It's very compact since it only defines tier brackets, not per-unit drops.

#### 4.3.1 Structure
```jass
library ItemLootDefinitionsGeneric initializer Init requires ItemLootSystem

private trigger initTrigger = CreateTrigger()

private function DefineLootTiers takes nothing returns nothing
    // === LOOT TIERS ===
    // RegisterLootTier(tierId, minUnitLevel, maxUnitLevel, dropChance)
    // RegisterTierRarity(tierId, rarityId, itemLevel, weight)
    
    // Tier 1: Starting area (units level 1-5)
    call RegisterLootTier(1, 1, 5, 1500)  // 15% base drop chance
    call RegisterTierRarity(1, RARITY_COMMON, 5, 60)      // 60% Common, iLvl 5
    call RegisterTierRarity(1, RARITY_UNCOMMON, 10, 25)   // 25% Uncommon, iLvl 10
    call RegisterTierRarity(1, RARITY_RARE, 15, 15)       // 15% Rare, iLvl 15
    // No Epic/Legendary in tier 1
    
    // Tier 2: Early game (units level 6-10)
    call RegisterLootTier(2, 6, 10, 1200)  // 12% base drop chance
    call RegisterTierRarity(2, RARITY_COMMON, 10, 55)
    call RegisterTierRarity(2, RARITY_UNCOMMON, 15, 28)
    call RegisterTierRarity(2, RARITY_RARE, 20, 14)
    call RegisterTierRarity(2, RARITY_EPIC, 25, 3)
    
    // Tier 3: Mid-early (units level 11-15)
    call RegisterLootTier(3, 11, 15, 1000)  // 10% base drop chance
    call RegisterTierRarity(3, RARITY_COMMON, 15, 50)
    call RegisterTierRarity(3, RARITY_UNCOMMON, 20, 28)
    call RegisterTierRarity(3, RARITY_RARE, 25, 15)
    call RegisterTierRarity(3, RARITY_EPIC, 30, 5)
    call RegisterTierRarity(3, RARITY_LEGENDARY, 35, 2)
    
    // Tier 4: Mid game (units level 16-20)
    call RegisterLootTier(4, 16, 20, 800)  // 8% base drop chance
    call RegisterTierRarity(4, RARITY_COMMON, 20, 45)
    call RegisterTierRarity(4, RARITY_UNCOMMON, 25, 30)
    call RegisterTierRarity(4, RARITY_RARE, 30, 16)
    call RegisterTierRarity(4, RARITY_EPIC, 35, 6)
    call RegisterTierRarity(4, RARITY_LEGENDARY, 40, 3)
    call RegisterTierRarity(4, RARITY_ARTIFACT, 45, 0)  // 0% at this tier
    
    // Tier 5: Mid-late (units level 21-25)
    call RegisterLootTier(5, 21, 25, 600)  // 6% base drop chance
    call RegisterTierRarity(5, RARITY_COMMON, 25, 40)
    call RegisterTierRarity(5, RARITY_UNCOMMON, 30, 30)
    call RegisterTierRarity(5, RARITY_RARE, 35, 18)
    call RegisterTierRarity(5, RARITY_EPIC, 40, 8)
    call RegisterTierRarity(5, RARITY_LEGENDARY, 45, 3)
    call RegisterTierRarity(5, RARITY_ARTIFACT, 50, 1)
    
    // Tier 6: Late game (units level 26-30)
    call RegisterLootTier(6, 26, 30, 500)  // 5% base drop chance
    call RegisterTierRarity(6, RARITY_COMMON, 30, 35)
    call RegisterTierRarity(6, RARITY_UNCOMMON, 35, 30)
    call RegisterTierRarity(6, RARITY_RARE, 40, 20)
    call RegisterTierRarity(6, RARITY_EPIC, 45, 10)
    call RegisterTierRarity(6, RARITY_LEGENDARY, 50, 4)
    call RegisterTierRarity(6, RARITY_ARTIFACT, 55, 1)
    
    // Tier 7: End game (units level 31+)
    call RegisterLootTier(7, 31, 99, 400)  // 4% base drop chance
    call RegisterTierRarity(7, RARITY_COMMON, 35, 30)
    call RegisterTierRarity(7, RARITY_UNCOMMON, 40, 28)
    call RegisterTierRarity(7, RARITY_RARE, 45, 22)
    call RegisterTierRarity(7, RARITY_EPIC, 50, 12)
    call RegisterTierRarity(7, RARITY_LEGENDARY, 55, 6)
    call RegisterTierRarity(7, RARITY_ARTIFACT, 60, 2)
endfunction

private function RegisterItemLevels takes nothing returns nothing
    // === ITEM POOL REGISTRATION ===
    // Items are registered by (item_level, rarity) for pool lookup
    // RegisterItemToPool(itemTypeId, itemLevel, rarityId, weight, isUnique)
    
    // === COMMON ITEMS (rarity 0) ===
    // Level 5 Common
    call RegisterItemToPool('hpot', 5, RARITY_COMMON, 100, false)   // Minor Healing Potion
    call RegisterItemToPool('mpot', 5, RARITY_COMMON, 100, false)   // Minor Mana Potion
    
    // Level 10 Common
    call RegisterItemToPool('rde0', 10, RARITY_COMMON, 100, false)  // Ring of Protection +1
    
    // === UNCOMMON ITEMS (rarity 1) ===
    // Level 10 Uncommon
    call RegisterItemToPool('rlif', 10, RARITY_UNCOMMON, 80, false) // Ring of Regeneration
    
    // Level 15 Uncommon
    call RegisterItemToPool('gcel', 15, RARITY_UNCOMMON, 80, false) // Gloves of Haste
    
    // === RARE ITEMS (rarity 2) ===
    // Level 15 Rare
    call RegisterItemToPool('I6CF', 15, RARITY_RARE, 50, false)     // Rare Sigil
    
    // === LEGENDARY ITEMS (rarity 4, unique) ===
    // Level 35 Legendary - Unique (only drops once)
    call RegisterItemToPool('I999', 35, RARITY_LEGENDARY, 10, true) // Legendary Sword
    
    // ... etc (generated from database)
endfunction

private function Init takes nothing returns nothing
    call TriggerRegisterTimerEvent(initTrigger, 0.1, false)
    call TriggerAddAction(initTrigger, function DefineLootTiers)
    // Item levels registered with slightly longer delay
    call TriggerRegisterTimerEvent(CreateTrigger(), 0.15, false)
    call TriggerAddAction(CreateTrigger(), function RegisterItemLevels)
endfunction

endlibrary
```

#### 4.3.2 Code Size Estimate
- ~7 tier definitions with 5 rarities each = ~50 lines
- Item pool registrations = ~200-400 lines (one per droppable item type)
- **Total: ~250-500 lines** (vs 20,000+ for per-unit mapping)

---

### 4.4 ItemLootDefinitionsSpecific.j (Generated - Boss/Unique Only)

This library defines ONLY specific drops for bosses and unique units that need custom loot tables.

#### 4.4.1 Structure
```jass
library ItemLootDefinitionsSpecific initializer Init requires ItemLootSystem

private trigger initTrigger = CreateTrigger()

private function DefineSpecificDrops takes nothing returns nothing
    // === BOSS: Forest Troll Warlord ===
    // Unit: n001 (Forest Troll Warlord) - Level 10, BOSS
    call RegisterUnitLootMode('n001', LOOT_MODE_BOTH)  // Generic + specific
    call RegisterUnitSpecificTable('n001', 1)
    call RegisterUnitDropCounts('n001', 2, 3)         // Drops 2-3 items
    
    // Specific drops for this boss
    call RegisterSpecificDrop(1, 'I6CF', 500, 100, 1, 1)   // 5% Legendary Sigil
    call RegisterSpecificDrop(1, 'rlif', 2500, 75, 1, 1)   // 25% Ring of Regen
    call RegisterSpecificDrop(1, 'hpot', 10000, 50, 2, 4)  // 100% 2-4 Health Potions
    
    // === BOSS: Ancient Hydra ===
    // Unit: n005 (Ancient Hydra) - Level 25, BOSS
    call RegisterUnitLootMode('n005', LOOT_MODE_SPECIFIC)  // Specific only
    call RegisterUnitSpecificTable('n005', 2)
    call RegisterUnitDropCounts('n005', 3, 5)
    
    call RegisterSpecificDrop(2, 'I6CB', 1000, 100, 1, 1)  // 10% Blazing Sharpblade
    call RegisterSpecificDrop(2, 'afac', 5000, 80, 1, 1)   // 50% Rare artifact
    call RegisterSpecificDrop(2, 'pghe', 10000, 50, 3, 5)  // 100% 3-5 Greater Healing
    
    // === UNIQUE: Merchant Guard (no drops) ===
    call RegisterUnitLootMode('h001', LOOT_MODE_NONE)
    
    // ... more specific definitions (only for ~50-100 special units)
endfunction

private function Init takes nothing returns nothing
    call TriggerRegisterTimerEvent(initTrigger, 0.2, false)  // After generic init
    call TriggerAddAction(initTrigger, function DefineSpecificDrops)
endfunction

endlibrary
```

#### 4.4.2 Code Size Estimate
- ~100 bosses with 5 drops each = ~600 lines
- ~50 units with mode overrides = ~50 lines
- **Total: ~700 lines max**

#### 4.4.3 Generation Rules
1. Only export units with `loot_mode = 'specific'` or `'both'`
2. Only export units with entries in `unit_specific_drops`
3. Include unit mode, drop counts, gold range
4. Order entries by weight descending
5. Disabled entries excluded

---

## 5. Existing Code Integration

### 5.1 Review Existing Draft Libraries

The following files should be reviewed as baseline/reference:

| File | Purpose | Integration Notes |
|------|---------|-------------------|
| `ItemDropSystem.j` | Main drop system | May replace or merge |
| `ItemDropBoss.j` | Boss-specific drops | Incorporate boss logic |
| `ItemDropConfig.j` | Configuration | Merge config options |
| `ItemDropCore.j` | Core drop functions | Review algorithms |
| `ItemDropDestructible.j` | Destructible drops | Phase 2 feature |
| `ItemDropSpecific.j` | Specific drop rules | Review special cases |

### 5.2 Migration Strategy
1. Analyze existing code for reusable logic
2. Identify conflicts with new architecture
3. Create compatibility layer if needed
4. Deprecate old code after migration

---

## 6. Export Script Requirements

### 6.1 Generic Loot Export Script

**File:** `export_loot_generic_cli.py`

#### 6.1.1 CLI Interface
```bash
python export_loot_generic_cli.py <output_path> [options]

Options:
  --config PATH          Database config file
  --include-item-levels  Include item level registrations
```

#### 6.1.2 Database Queries
```sql
-- Get all loot tiers with rarity breakdown
SELECT id, tier_name, min_unit_level, max_unit_level, drop_chance_base,
       common_item_level, uncommon_item_level, rare_item_level,
       epic_item_level, legendary_item_level,
       common_weight, uncommon_weight, rare_weight, epic_weight, legendary_weight
FROM loot_tiers
WHERE enabled = true
ORDER BY min_unit_level;

-- Get all droppable items with rarity for pool registration
-- Uses item_level for equippables, item_level_unclassified for others
SELECT i.item_code, 
       COALESCE(i.item_level, i.item_level_unclassified) as effective_level,
       r.rarity_id, r.rarity_name,
       i.is_unique
FROM items i
JOIN item_rarities r ON r.id = i.rarity_id
WHERE COALESCE(i.item_level, i.item_level_unclassified) IS NOT NULL
  AND COALESCE(i.item_level, i.item_level_unclassified) > 0
ORDER BY effective_level, r.rarity_id, i.item_code;
```

---

### 6.2 Specific Loot Export Script

**File:** `export_loot_specific_cli.py`

#### 6.2.1 CLI Interface
```bash
python export_loot_specific_cli.py <output_path> [options]

Options:
  --units UNIT1,UNIT2    Export specific units only
  --include-disabled     Include disabled drop entries
  --config PATH          Database config file
```

#### 6.2.2 Database Queries
```sql
-- Get units with specific/both loot mode
SELECT u.unit_code, u.unit_name, u.editor_suffix, u.unit_level, u.is_boss,
       u.loot_mode, u.drop_count_min, u.drop_count_max
FROM unit_types u
WHERE u.loot_mode IN ('specific', 'both')
ORDER BY u.unit_code;

-- Get specific drops for unit
SELECT usd.item_code, usd.drop_chance, usd.weight, 
       usd.min_quantity, usd.max_quantity, usd.is_guaranteed, i.item_name
FROM unit_specific_drops usd
JOIN items i ON i.item_code = usd.item_code
WHERE usd.unit_code = %s AND usd.enabled = true
ORDER BY usd.weight DESC, usd.drop_chance DESC;

-- Get units with mode overrides (none mode)
SELECT unit_code FROM unit_types WHERE loot_mode = 'none';
```

---

## 7. Future Considerations (Phase 2+)

### 7.1 Destructible Loot Tables
- Create `destructible_types` table similar to `unit_types`
- Import from `.w3d` files
- Can use same tier system for generic drops
- Extend ItemLootSystem for destructible death events

### 7.2 Tier Item Overrides
- `loot_tier_items` table for explicit tier inclusions/exclusions
- Example: Force specific item into tier even if item_level doesn't match
- Example: Exclude certain items from generic pool (unique/quest items)

### 7.3 Conditional Drops
- Player level requirements
- Quest completion requirements  
- Time-based drops (day/night, events)
- First-kill bonuses

### 7.4 Loot Modifiers
- Luck stat influence on drop chance
- Difficulty modifiers
- Magic Find percentage

### 7.5 Item Type Filters
- Filter generic pool by item type (weapon, armor, consumable)
- Useful for themed areas or unit types

---

## 8. Implementation Order

### Phase 1: Database Foundation
1. Create `unit_types` table
2. Create `loot_tiers` table (with rarity columns)
3. Add `is_unique`, `item_level_unclassified` columns to `items` table
4. Create `loot_tier_items` table (optional, for tier overrides)
5. Create `unit_specific_drops` table
6. Create unit type import script (Python, from .w3u)
7. Run initial import from map

### Phase 2: Tier System Setup
8. Seed initial loot tiers (7 default tiers with rarity weights)
9. Ensure `items.item_level` and `rarity_id` are populated for all items
10. Populate `item_level_unclassified` for consumables/misc from WC3 ilvo
11. Create tier management UI in ItemManager

### Phase 3: ItemManager UI
12. Implement Logs tab and logging infrastructure (simple text file logging)
13. Create `TooltipPhrases.json` external phrase dictionary
14. Update TooltipGenerator.cs to load phrases from JSON and support templates
15. Unit type list view with loot mode column
16. Unit type edit form with loot settings
17. Specific drops panel (boss/unique only)
18. Item edit "Loot Info" tab with item level clarification and tier preview
19. Is Unique checkbox for items

### Phase 4: JASS Libraries
20. Create `ItemLootSystem.j` main library (rarity-first rolling, unique tracking)
21. Create `export_loot_generic_cli.py` export script
22. Generate `ItemLootDefinitionsGeneric.j`
23. Create `export_loot_specific_cli.py` export script
24. Generate `ItemLootDefinitionsSpecific.j`
25. Test in-game with various unit levels and rarities

### Phase 5: Refinement
26. Review existing draft code (ItemDropSystem.j etc.) for integration
27. Add advanced features (type filters)
28. Performance optimization
29. Documentation

---

## 8.1 SQL Migration Scripts

Migration files to be created in `WC3_Database/migrations/`:

### Migration 1: Create unit_types table
**File:** `migrations/2026-XX-XX_create_unit_types.sql`

```sql
-- Create unit_types table for WC3 unit type data
CREATE TABLE IF NOT EXISTS unit_types (
    id SERIAL,
    unit_code VARCHAR(4) PRIMARY KEY,
    base_id VARCHAR(4),
    unit_name VARCHAR(255),
    editor_suffix VARCHAR(100),
    icon_path VARCHAR(255),
    unit_level INTEGER DEFAULT 1,
    is_boss BOOLEAN DEFAULT FALSE,
    loot_mode VARCHAR(20) DEFAULT 'generic',
    loot_tier_id INTEGER,
    drop_count_min INTEGER DEFAULT 1,
    drop_count_max INTEGER DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_unit_types_unit_code ON unit_types(unit_code);
CREATE INDEX idx_unit_types_is_boss ON unit_types(is_boss);
CREATE INDEX idx_unit_types_loot_mode ON unit_types(loot_mode);
CREATE INDEX idx_unit_types_unit_level ON unit_types(unit_level);

-- Constraint for loot_mode values
ALTER TABLE unit_types ADD CONSTRAINT chk_loot_mode 
    CHECK (loot_mode IN ('generic', 'specific', 'both', 'none'));
```

### Migration 2: Create loot_tiers table
**File:** `migrations/2026-XX-XX_create_loot_tiers.sql`

```sql
-- Create loot_tiers table for level-based drop pools
CREATE TABLE IF NOT EXISTS loot_tiers (
    id SERIAL PRIMARY KEY,
    tier_name VARCHAR(50) UNIQUE NOT NULL,
    min_unit_level INTEGER NOT NULL,
    max_unit_level INTEGER NOT NULL,
    description TEXT,
    drop_chance_base DECIMAL(5,2) DEFAULT 10.00,
    -- Per-rarity item levels
    common_item_level INTEGER,
    uncommon_item_level INTEGER,
    rare_item_level INTEGER,
    epic_item_level INTEGER,
    legendary_item_level INTEGER,
    artifact_item_level INTEGER,
    -- Per-rarity weights
    common_weight INTEGER DEFAULT 60,
    uncommon_weight INTEGER DEFAULT 25,
    rare_weight INTEGER DEFAULT 12,
    epic_weight INTEGER DEFAULT 3,
    legendary_weight INTEGER DEFAULT 0,
    artifact_weight INTEGER DEFAULT 0,
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add FK constraint to unit_types
ALTER TABLE unit_types ADD CONSTRAINT fk_unit_loot_tier 
    FOREIGN KEY (loot_tier_id) REFERENCES loot_tiers(id);
```

### Migration 3: Add columns to items table
**File:** `migrations/2026-XX-XX_alter_items_loot_columns.sql`

```sql
-- Add loot-related columns to existing items table
ALTER TABLE items ADD COLUMN IF NOT EXISTS is_unique BOOLEAN DEFAULT FALSE;
ALTER TABLE items ADD COLUMN IF NOT EXISTS item_level_unclassified INTEGER;

-- Add comment for clarity
COMMENT ON COLUMN items.is_unique IS 'Item can only drop once per game';
COMMENT ON COLUMN items.item_level_unclassified IS 'For non-equippable items where item_level is used for stack size (from WC3 ilvo field)';
```

### Migration 4: Create unit_specific_drops table
**File:** `migrations/2026-XX-XX_create_unit_specific_drops.sql`

```sql
-- Create junction table for boss/specific unit drops
CREATE TABLE IF NOT EXISTS unit_specific_drops (
    id SERIAL PRIMARY KEY,
    unit_code VARCHAR(4) NOT NULL,
    item_code VARCHAR(4) NOT NULL,
    drop_chance DECIMAL(5,2) NOT NULL DEFAULT 10.00,
    min_quantity INTEGER DEFAULT 1,
    max_quantity INTEGER DEFAULT 1,
    is_guaranteed BOOLEAN DEFAULT FALSE,
    weight INTEGER DEFAULT 100,
    enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_usd_unit FOREIGN KEY (unit_code) REFERENCES unit_types(unit_code),
    CONSTRAINT fk_usd_item FOREIGN KEY (item_code) REFERENCES items(item_code)
);

-- Unique constraint (one entry per unit+item pair)
CREATE UNIQUE INDEX idx_unit_specific_unique ON unit_specific_drops(unit_code, item_code);

-- Index for lookups
CREATE INDEX idx_usd_unit_code ON unit_specific_drops(unit_code);
```

### Migration 5: Create loot_tier_items table (optional)
**File:** `migrations/2026-XX-XX_create_loot_tier_items.sql`

```sql
-- Optional: Explicit tier item overrides
CREATE TABLE IF NOT EXISTS loot_tier_items (
    id SERIAL PRIMARY KEY,
    loot_tier_id INTEGER NOT NULL REFERENCES loot_tiers(id),
    item_code VARCHAR(4) REFERENCES items(item_code),
    item_level_min INTEGER,
    item_level_max INTEGER,
    weight INTEGER DEFAULT 100,
    drop_chance DECIMAL(5,2),
    rarity_filter VARCHAR(20),
    type_filter VARCHAR(50),
    enabled BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT chk_item_or_range CHECK (
        item_code IS NOT NULL OR 
        (item_level_min IS NOT NULL AND item_level_max IS NOT NULL)
    )
);

CREATE INDEX idx_lti_tier ON loot_tier_items(loot_tier_id);
```

### Migration 6: Seed default loot tiers
**File:** `migrations/2026-XX-XX_seed_loot_tiers.sql`

```sql
-- Seed 7 default loot tiers
INSERT INTO loot_tiers (tier_name, min_unit_level, max_unit_level, description, drop_chance_base,
    common_item_level, uncommon_item_level, rare_item_level, epic_item_level, legendary_item_level, artifact_item_level,
    common_weight, uncommon_weight, rare_weight, epic_weight, legendary_weight, artifact_weight)
VALUES 
    ('TIER_1_5', 1, 5, 'Starting area mobs', 15.00, 5, 10, 15, NULL, NULL, NULL, 60, 25, 15, 0, 0, 0),
    ('TIER_6_10', 6, 10, 'Early game mobs', 12.00, 10, 15, 20, 25, NULL, NULL, 55, 28, 14, 3, 0, 0),
    ('TIER_11_15', 11, 15, 'Mid-early game', 10.00, 15, 20, 25, 30, 35, NULL, 50, 28, 15, 5, 2, 0),
    ('TIER_16_20', 16, 20, 'Mid game', 8.00, 20, 25, 30, 35, 40, 45, 45, 30, 16, 6, 3, 0),
    ('TIER_21_25', 21, 25, 'Mid-late game', 6.00, 25, 30, 35, 40, 45, 50, 40, 30, 18, 8, 3, 1),
    ('TIER_26_30', 26, 30, 'Late game', 5.00, 30, 35, 40, 45, 50, 55, 35, 30, 20, 10, 4, 1),
    ('TIER_31_PLUS', 31, 99, 'End game / elite', 4.00, 35, 40, 45, 50, 55, 60, 30, 28, 22, 12, 6, 2)
ON CONFLICT (tier_name) DO NOTHING;
```

---

## 9. Technical Notes

### 9.1 Gold Drops - Not In Scope
Gold drops are already handled by WC3's native unit gold bounty system. This ItemLootSystem only handles **item drops**. Do not include gold-related columns or logic.

### 9.2 Table (TableV6) Usage
- Use nested Tables for multi-dimensional data
- Tier+Rarity key format: `tierId * 10 + rarityId` (e.g., tier 3 + Rare = 32)
- Item pool key format: `itemLevel * 100 + rarityId` (e.g., level 15 + Uncommon = 1501)
- Entry keys: `tableId * 10000 + entryIndex` for linked lists
- Avoid string keys for performance

### 9.3 Generic Drop Performance
- **Pre-build item lists per tier during init:**
  - Iterate all registered items
  - Group by item_level into tier buckets
  - Store as arrays in Tables for O(1) access
- **At runtime:** Just roll random index into tier's item array
- Avoids expensive per-death queries

### 9.4 Item Level Registration Options
Option A: **Generated in ItemLootDefinitionsGeneric.j** (current recommendation)
- ~300-500 `RegisterItemLevel` calls
- Clear, explicit, easy to debug

Option B: **Read from item ability field at runtime**
- Use unused ability field to encode item level
- No code generation needed
- More complex, harder to debug

### 9.5 Performance Considerations
- Pre-build item pools per (item_level, rarity) during init:
  - Iterate all registered items
  - Group by (item_level, rarity_id) into pools
  - Store as linked lists in Tables for weighted random
- **At runtime:**
  1. Roll rarity (weighted random, ~5 comparisons max)
  2. Get item_level for tier+rarity (O(1) table lookup)
  3. Roll weighted random from pool (traverse list)
- Avoids expensive per-death queries

### 9.6 Stackable Item Handling
- After `CreateItem()`, check `GetItemCharges(item) > 0`
- If stackable, call `SetItemCharges(item, GetRandomInt(1, 3))`
- This gives 1-3 stacks per drop

### 9.7 Unique Item Tracking
- Track dropped unique items in `uniqueItemDropped` Table
- Check before dropping: if `itemIsUnique[id]` and `uniqueItemDropped[id]`, skip
- Mark after dropping: `uniqueItemDropped[id] = true`
- Persists for duration of game (not saved)

### 9.8 Debug Support
- Compile-time debug flag (`DEBUG_LOOT`)
- Runtime debug commands (`-lootdebug on`)
- Logging: Drop rolls, tier selection, item selection
- Test command: `-testloot <unit_code>` to simulate drops

---

## 10. Resolved Design Decisions

These questions have been resolved:

| Question | Decision | Notes |
|----------|----------|-------|
| **Gold Drops** | Handle separately | WC3 already defines gold drops per unit type - not part of this system |
| **Stack Items** | Drop 1-3 stacks | Use `SetItemCharges(item, count)` after item creation |
| **Unique Items** | Yes, track unique drops | Add `is_unique` flag to items - can only drop once per game |
| **Rarity Weighting** | Yes | Each rarity has different weight/chance within a tier |
| **Party Distribution** | N/A | Single-player only, not needed |
| **Item Level Assignment** | Manual, multi-purpose | See section 10.1 below |

### 10.1 Item Level Field - Multiple Purposes

The `item_level` field in the `items` table serves **multiple purposes**:

1. **Loot Tier Classification:** Determines which unit level tiers can drop this item
2. **Rarity Scaling:** Higher rarities have higher item levels within same unit tier
3. **Stack Limit (Charged Items):** For stackable items, also defines max charges

**For Equippable Items:**
- Item level is set based on unit tier + rarity using a defined scale
- Example: Units 1-5 drop Common iLvl 5, Uncommon iLvl 10, Rare iLvl 15

**For Other Items (Consumables, Quest, Misc):**
- Use WC3's `ilvo` field ("Stats - Level (Unclassified)") from item data
- This avoids conflict with item level being used for stack limits
- Import `ilvo` to a separate `item_level_unclassified` column

### 10.2 Rarity-Based Tier Drops

Each unit level tier has **separate pools per rarity** with different item level ranges:

| Unit Tier | Common iLvl | Uncommon iLvl | Rare iLvl | Epic iLvl | Legendary iLvl |
|-----------|-------------|---------------|-----------|-----------|----------------|
| 1-5       | 5           | 10            | 15        | -         | -              |
| 6-10      | 10          | 15            | 20        | 25        | -              |
| 11-15     | 15          | 20            | 25        | 30        | 35             |
| 16-20     | 20          | 25            | 30        | 35        | 40             |
| 21-25     | 25          | 30            | 35        | 40        | 45             |
| 26-30     | 30          | 35            | 40        | 45        | 50             |

**Drop Weight Example (Unit Tier 1-5):**
- Roll rarity first (e.g., Common 60%, Uncommon 25%, Rare 15%)
- Then select item from that rarity's pool for the tier
- Each item has individual weight within its rarity pool

---

## 11. Architecture Benefits Summary

### 11.1 Code Size Comparison

| Approach | Units | Items/Unit | Lines Generated |
|----------|-------|------------|-----------------|
| **Old (per-unit)** | 1000 | 20 | ~20,000+ |
| **New (rarity-tiered)** | 1000 | N/A | ~800-1200 |

### 11.2 Key Benefits

1. **Minimal Code Generation:**
   - Generic: ~250-500 lines (tiers × rarities + item pools)
   - Specific: ~500-700 lines (only bosses)
   - **Total: ~1000 lines vs 20,000+**

2. **Automatic New Item Integration:**
   - Add item with `item_level = 15`, `rarity = Rare` in ItemManager
   - Item automatically drops from Tier 1-5 Rare pool
   - **No code regeneration needed!**

3. **Rarity-First Rolling:**
   - Roll rarity first (Common 60%, Uncommon 25%, etc.)
   - Then select item from that rarity's pool
   - Easy to tune drop distribution per tier

4. **Stackable Item Support:**
   - After drop, `SetItemCharges(item, GetRandomInt(1, 3))` for 1-3 stacks
   - Simple, handled at runtime

5. **Unique Item Tracking:**
   - `is_unique` flag prevents item from dropping twice per game
   - Tracked in-memory via Table

6. **Gold Excluded:**
   - WC3 handles gold bounty natively
   - This system focuses only on item drops

7. **Clear Separation:**
   - Generic = 90% of units (rarity-tiered pools)
   - Specific = Bosses/unique only (hand-crafted loot)

---

*End of Requirements Document*
