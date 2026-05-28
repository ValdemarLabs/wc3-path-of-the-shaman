# WC3 Item Manager - User Guide & FAQ

**Version:** 1.0  
**Last Updated:** April 2026

A comprehensive guide to using the WC3 Item Manager application for managing Warcraft 3 item databases, loot systems, and JASS code generation.

---

## 📑 Table of Contents

- [1. Getting Started](#1-getting-started)
  - [1.1 What is WC3 Item Manager?](#11-what-is-wc3-item-manager)
  - [1.2 System Requirements](#12-system-requirements)
  - [1.3 First Launch](#13-first-launch)
  - [1.4 Database Connection](#14-database-connection)
- [2. Item Management](#2-item-management)
  - [2.1 Viewing Items](#21-viewing-items)
  - [2.2 Searching & Filtering](#22-searching--filtering)
  - [2.3 Creating Items](#23-creating-items)
  - [2.4 Editing Items](#24-editing-items)
  - [2.5 Duplicating Items](#25-duplicating-items)
  - [2.6 Deleting Items](#26-deleting-items)
  - [2.7 Stats & Bonuses](#27-stats--bonuses)
  - [2.8 Auto-Generated Tooltips](#28-auto-generated-tooltips)
- [3. Loot Systems](#3-loot-systems)
  - [3.1 Overview: Tiers vs Tables](#31-overview-tiers-vs-tables)
  - [3.2 Loot Tiers (Level-Based)](#32-loot-tiers-level-based)
  - [3.3 Loot Tables (Named Collections)](#33-loot-tables-named-collections)
  - [3.4 When to Use Which?](#34-when-to-use-which)
- [4. Unit & Destructible Types](#4-unit--destructible-types)
  - [4.1 Managing Unit Types](#41-managing-unit-types)
  - [4.2 Managing Destructible Types](#42-managing-destructible-types)
  - [4.3 Importing from W3U/W3B Files](#43-importing-from-w3uw3b-files)
  - [4.4 Assigning Loot](#44-assigning-loot)
- [5. Exporting](#5-exporting)
  - [5.1 Export to W3T (World Editor)](#51-export-to-w3t-world-editor)
  - [5.2 Export Loot System JASS](#52-export-loot-system-jass)
  - [5.3 Export DEquipment Library](#53-export-dequipment-library)
- [6. Troubleshooting](#6-troubleshooting)
- [7. FAQ](#7-faq)

---

## 1. Getting Started

### 1.1 What is WC3 Item Manager?

WC3 Item Manager is a Windows desktop application for managing Warcraft 3 (WC3) item data in a PostgreSQL database. It provides:

- **Visual item editing** with preview panels
- **Database-driven** item storage with full WC3 property support
- **Loot system management** for units and destructibles
- **JASS code generation** for in-game use
- **Import/Export** between WC3 formats and the database

### 1.2 System Requirements

| Component | Requirement |
|-----------|-------------|
| OS | Windows 10/11 |
| Runtime | .NET 5.0 or later |
| Database | PostgreSQL 12+ running locally or remotely |
| Database | `wc3_pots` database with schema installed |

### 1.3 First Launch

1. **Run** `WC3ItemManager.exe` or launch via `run.bat`
2. The application will attempt to connect to the database automatically
3. If connection fails, you'll see a red status indicator - see [Database Connection](#14-database-connection)

### 1.4 Database Connection

**Connection Status Indicators:**
- 🟢 **Green dot** = Connected successfully
- 🔴 **Red dot** = Disconnected

**To reconnect:**
1. Click the **🔌 Connect** button in the toolbar
2. If it fails, verify:
   - PostgreSQL service is running
   - Database `wc3_pots` exists
   - Connection string is correct (check `database.ini`)

**Default connection settings:**
```
Host: localhost
Port: 5432
Database: wc3_pots
Username: postgres
```

---

## 2. Item Management

### 2.1 Viewing Items

The main window displays all items in a sortable data grid:

| Column | Description |
|--------|-------------|
| Code | 4-character WC3 item ID (e.g., `i0a5`) |
| Name | Display name |
| Rarity | Common → Legendary color-coded |
| Class | MISC, CONSUMABLE, ARTIFACT, QUEST |
| Level | Item level (affects drops & requirements) |
| Cost | Gold value |

**Preview Panel:** Select an item to see a WC3-style tooltip preview on the right side with:
- Colored item name (by rarity)
- Stats and bonuses
- Description text
- Rarity-colored border

### 2.2 Searching & Filtering

#### Quick Search
- Type in the **search box** at the top
- Searches: Name, Code, Tooltip, Description, Abilities

#### Filter Dropdowns
| Filter | Options |
|--------|---------|
| Rarity | All, Common, Uncommon, Rare, Epic, Legendary |
| Class | All, MISC, CONSUMABLE, ARTIFACT, QUEST |
| Custom Only | Checkbox - shows only custom items (has `base_id`) |

#### Advanced Filters
Click **▼ Advanced** to reveal:
- Level range (min/max)
- Cost range (min/max)
- Has Abilities (checkbox)
- Has Stats (checkbox)

#### Clear Filters
Click **✖ Clear All** to reset all filters and search.

### 2.3 Creating Items

1. Click **➕ Add New** button (green)
2. Fill in the **Item Edit Form**:
   - **Basic Info tab:** Code, Name, Class, Level, Cost
   - **Appearance tab:** Icon path, Model path
   - **Extended Info tab:** Tooltip, Description
   - **Stats & Bonuses tab:** Add item stats
3. Click **💾 Save**

**Item Code Rules:**
- Must be 4 characters
- Format: letter-digit-letter-digit (e.g., `i0a5`)
- Must be unique

### 2.4 Editing Items

**Method 1:** Double-click an item row  
**Method 2:** Right-click → **✏️ Edit**

The Edit Form opens with all current data pre-filled. Make changes and click **💾 Save**.

### 2.5 Duplicating Items

Perfect for creating item variants:

1. Right-click an item
2. Select **📋 Duplicate**
3. The Edit Form opens with:
   - All fields copied
   - New code auto-generated (e.g., `i0a5` → `i0a6`)
4. Modify as needed
5. Click **💾 Save** (creates NEW item)

**Code Generation:**
- Increments trailing digit: `i0a5` → `i0a6`
- Wraps at 9: `i0a9` → `i0b0`
- Increments letter: `i0z9` → `i1a0`

### 2.6 Deleting Items

**Single item:** Right-click → **🗑️ Delete**

**Multiple items:**
1. Ctrl+Click to select multiple rows
2. Right-click → **🗑️ Batch Delete**
3. Confirm the deletion

⚠️ **Warning:** Deletions cannot be undone!

### 2.7 Stats & Bonuses

Items can have multiple stats attached via the **Stats & Bonuses** tab in the Edit Form.

**Available Stats (21 total):**
| Category | Stats |
|----------|-------|
| Primary | STR, AGI, INT |
| Resources | HP, MP, HP Regen, MP Regen |
| Combat | Damage, Armor, Attack Speed, Move Speed |
| Critical | Crit Chance, Crit Damage |
| Defense | Dodge, Block |
| Special | Lifesteal, Spell Power |
| Resistances | Fire, Cold, Lightning, Poison |

**To add stats:**
1. Open the **Stats & Bonuses** tab
2. Select a stat from the dropdown
3. Enter a value
4. Click **Add**
5. Repeat for additional stats

Stats are color-coded (positive = green, negative = red) and preserved when saving.

### 2.8 Auto-Generated Tooltips

The system can automatically generate tooltips and descriptions based on item properties.

**In the Extended Info tab:**

1. **🔄 Auto-Generate Tooltip** - Creates formatted tooltip with:
   - Colored item name (by rarity)
   - Level and class
   - All stats with colors
   - Abilities list
   - Requirements

2. **🔄 Auto-Generate Description** - Creates lore text based on:
   - Item rarity
   - Dominant stats
   - Item level
   - Class type

---

## 3. Loot Systems

### 3.1 Overview: Tiers vs Tables

The system supports **two complementary loot systems**:

| Feature | Loot Tiers | Loot Tables |
|---------|------------|-------------|
| Assignment | Automatic by unit level | Manual per unit/destructible |
| Item Selection | By item_level + rarity | Explicit item list |
| Use Case | Generic enemy drops | Themed/boss drops |
| Flexibility | Level-range based | Fully customizable |

**They work together:** Use tiers for most enemies, tables for special cases.

### 3.2 Loot Tiers (Level-Based)

Loot Tiers define **level-based drop pools** with rarity breakdowns.

**Access:** Menu → **Loot** → **Manage Loot Tiers**

#### How Tiers Work

1. Each tier covers a **unit level range** (e.g., 1-5, 6-10, 11-15)
2. When a unit in that range dies, the tier determines:
   - Base drop chance (e.g., 15%)
   - Which item_level to use per rarity
   - Rarity weights (60% common, 25% uncommon, etc.)

#### Example Tier Configuration

| Tier | Unit Levels | Drop Chance | Common Level | Uncommon Level | Rare Level |
|------|-------------|-------------|--------------|----------------|------------|
| 1 | 1-5 | 15% | 1 | 1 | - |
| 2 | 6-10 | 12% | 2 | 1 | 1 |
| 3 | 11-15 | 10% | 3 | 2 | 1 |

#### Rarity Weights

Each tier defines probability weights:
- **Common:** 60 (most likely)
- **Uncommon:** 25
- **Rare:** 12
- **Epic:** 3
- **Legendary:** 0 (disabled for low tiers)

### 3.3 Loot Tables (Named Collections)

Loot Tables are **named, curated item lists** assigned to specific units or destructibles.

**Access:** Menu → **Loot** → **Manage Loot Tables**

#### Creating a Loot Table

1. Click **➕ Add New Table**
2. Fill in:
   - **Name:** e.g., "Forest Trolls", "Undead Crypt", "Crates Level 1-5"
   - **Description:** What this table is for
   - **Category:** units, destructibles, both, boss
   - **Drop Settings:** Base chance, min/max items
3. **Add Items** to the table:
   - Search and select items
   - Set per-item drop chance
   - Set weight (for weighted selection)
   - Mark as guaranteed (always drops)
   - Set quantity range

#### Table Item Settings

| Setting | Description |
|---------|-------------|
| Drop Chance | Individual item % (0-100) |
| Weight | Priority in weighted random (higher = more likely) |
| Is Guaranteed | Always drops when table is rolled |
| Quantity Min/Max | How many of this item can drop |

### 3.4 When to Use Which?

| Scenario | Use |
|----------|-----|
| Generic forest creatures | **Loot Tier** (auto by level) |
| Named boss with unique drops | **Loot Table** (specific items) |
| Dungeon with themed loot | **Loot Table** ("Undead Crypt" table) |
| Random chest/crate | **Loot Table** per chest type |
| Scaling difficulty zones | **Loot Tier** (levels match zones) |
| Boss with level-appropriate + special | **Both** (loot_mode = 'both') |

---

## 4. Unit & Destructible Types

### 4.1 Managing Unit Types

**Access:** Menu → **Units** → **Manage Unit Types**

Unit Types represent WC3 unit type definitions (e.g., "Kobold Worker" as a type, not individual units).

**Key Fields:**
| Field | Description |
|-------|-------------|
| Unit Code | 4-char WC3 ID (e.g., 'hfoo') |
| Unit Name | Display name |
| Unit Level | For tier-based drops |
| Is Boss | Flag for special loot treatment |
| Loot Mode | generic, specific, both, none |
| Loot Tier | Assigned tier (for generic mode) |
| Loot Table | Assigned table (for specific mode) |

#### Loot Modes Explained

| Mode | Behavior |
|------|----------|
| `generic` | Uses level-based tier pool only |
| `specific` | Uses assigned loot table only |
| `both` | Rolls both tier AND table |
| `none` | No item drops |

### 4.2 Managing Destructible Types

**Access:** Menu → **Destructibles** → **Manage Destructible Types**

Similar to Unit Types but for breakable objects (crates, barrels, etc.).

**Key Fields:**
| Field | Description |
|-------|-------------|
| Destructible Code | 4-char WC3 ID |
| Destructible Name | Display name |
| Category | crate, barrel, rock, tree, etc. |
| Loot Table | Assigned loot table |
| Drop Chance Override | Custom drop % |

### 4.3 Importing from W3U/W3B Files

**For Units:**
1. Menu → **Import** → **Import W3U (Units)**
2. Select your `.w3u` file from your map
3. Review import preview
4. Click **Import**

**For Destructibles:**
1. Menu → **Import** → **Import W3B (Destructibles)**
2. Select your `.w3b` file
3. Review and import

This populates unit/destructible types with WC3 data (names, icons, editor suffixes).

### 4.4 Assigning Loot

**From the Unit/Destructible Type Form:**

1. Open a unit/destructible type for editing
2. Set **Loot Mode** (generic, specific, both, none)
3. If generic: Assign a **Loot Tier** from dropdown
4. If specific: Assign a **Loot Table** from dropdown
5. Optionally set **Drop Count** (min/max items)
6. Save

---

## 5. Exporting

### 5.1 Export to W3T (World Editor)

Exports items to a `.w3t` file for use in WC3 World Editor.

1. Select items to export (or export all)
2. Click **📤 Export to W3T** (purple button)
3. Choose save location
4. Import the `.w3t` in World Editor

### 5.2 Export Loot System JASS

Generates JASS code for the ItemLootSystem.

**Access:** Menu → **Export** → **Export Loot System**

This creates:
- `ItemLootDefinitionsGeneric.j` - Tier definitions
- `ItemLootDefinitionsSpecific.j` - Unit-specific drops
- Registration calls for all configured loot

### 5.3 Export DEquipment Library

Generates JASS code for DEquipment integration.

**Access:** Menu → **Export** → **Export DEquipment**

Creates item registration code compatible with DInventory/DEquipment systems.

---

## 6. Troubleshooting

### Database Connection Issues

**"Not connected to database" error:**
1. Verify PostgreSQL is running (check Windows Services)
2. Ensure `wc3_pots` database exists
3. Check `database.ini` has correct credentials
4. Try the **🔌 Connect** button

**Connection timeout:**
- PostgreSQL may be starting up - wait and retry
- Check firewall isn't blocking port 5432

### UI Issues

**Preview panel is empty:**
- Select a single item (multi-select shows count instead)

**Context menu not appearing:**
- Right-click on a data row, not the header
- Ensure items exist in the database

**Filters not working:**
- Click **✖ Clear All** to reset
- Check if data matches filter criteria

### Save Warnings

The system shows warnings when saving items:

| Warning | Meaning | Action |
|---------|---------|--------|
| Similar name exists | Another item has matching name | Verify it's intentional |
| Missing icon path | Item will use default icon | Add icon path or ignore |
| Invalid code format | Should be letter-digit-letter-digit | Fix the code |
| Duplicate code | Code already exists | Use a different code |
| Underpriced/Overpriced | Cost outside expected range | Adjust cost or ignore |

Click **Yes** to save anyway (warnings are non-blocking).

---

## 7. FAQ

### General

**Q: Where is my data stored?**  
A: All data is stored in the PostgreSQL database `wc3_pots`. The application is just a viewer/editor.

**Q: Can I backup my data?**  
A: Yes! Use `pg_dump wc3_pots > backup.sql` or pgAdmin's backup feature.

**Q: Can multiple people use this simultaneously?**  
A: Yes, if they connect to the same PostgreSQL server. However, there's no real-time sync - refresh to see others' changes.

---

### Items

**Q: What's the difference between `item_level` and `item_level_unclassified`?**  
A: `item_level` is used for equippable items and determines which tier drops them. `item_level_unclassified` is for consumables/misc items where level means something else (like stack size).

**Q: Can I import items from my existing WC3 map?**  
A: Yes, export items as `.w3t` from World Editor, then use Python scripts in `/core/` to import to database.

**Q: How do rarity colors work?**  
A: Colors are stored in the `ui_color_scheme` database table and applied automatically. Default colors:
- Common: Gray
- Uncommon: Green
- Rare: Blue
- Epic: Purple
- Legendary: Orange

---

### Loot System

**Q: Can a unit use both tiers AND tables?**  
A: Yes! Set `loot_mode` to `both`. The unit will roll its tier pool AND its assigned table.

**Q: How do I make certain items always drop?**  
A: In a Loot Table, mark individual items as **Is Guaranteed**. Guaranteed items always drop when the table is rolled.

**Q: What's the difference between drop_chance and weight?**  
A: 
- **Drop Chance:** Whether this specific item drops at all (0-100%)
- **Weight:** When multiple items could drop, higher weight = more likely to be chosen

**Q: Why isn't my unit dropping items?**  
A: Check:
1. Unit has a Loot Mode other than 'none'
2. If generic: Loot Tier is assigned
3. If specific: Loot Table is assigned
4. Loot Table has items with drop_chance > 0
5. JASS code is exported and included in map

---

### Exporting

**Q: After exporting, my items don't appear in WC3?**  
A: Ensure you:
1. Imported the `.w3t` file in World Editor
2. Saved the map
3. The item codes don't conflict with existing items

**Q: My loot system isn't working in-game?**  
A: Verify:
1. Exported JASS files are included in map
2. `ItemLootSystem.j` library is present
3. Unit types are registered in JASS
4. Triggers are calling the loot functions on unit death

---

### Performance

**Q: The item list is slow with many items?**  
A: Use filters to narrow results. The database can handle thousands of items efficiently.

**Q: Export is taking a long time?**  
A: Large exports (thousands of items) take time. Progress is shown in the status bar.

---

## 📞 Need More Help?

- Check `/docs/` folder for detailed technical documentation
- Review `GUI_QUICKREF.md` for quick keyboard shortcuts
- See `ItemLootSystem_Requirements.md` for system architecture

---

*Last updated: April 2026*
