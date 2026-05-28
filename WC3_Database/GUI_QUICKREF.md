# WC3 Item Manager - Quick Reference Guide
**GUI Enhancements - March 2026**

## 🎯 Quick Actions

### DataGrid Operations
| Action | Method |
|--------|--------|
| Sort column | Click column header |
| Resize column | Drag column edge (auto-saves) |
| Edit item | Double-click row OR right-click → Edit |
| Duplicate item | Right-click → Duplicate |
| Delete item | Right-click → Delete |
| Delete multiple | Select with Ctrl+Click → Right-click → Batch Delete |
| Copy item code | Right-click → Copy Item Code |

### Multi-Select
- **Select multiple:** Ctrl+Click individual rows
- **Select range:** Click first, then Shift+Click last
- **Selected shown in preview:** "5 items selected. Right-click for batch operations."

### Search & Filters
| Feature | Location | Searches |
|---------|----------|-----------|
| Main search box | Top panel | Name, Code, Tooltip, Description, Abilities |
| Rarity filter | Top panel | Dropdown: All, Common, Uncommon, Rare, Epic, Legendary |
| Class filter | Top panel | Dropdown: All, MISC, CONSUMABLE, ARTIFACT, QUEST |
| Custom Only | Top panel | Checkbox: Shows only custom items (has base_id) |
| Advanced filters | Click "▼ Advanced" | Level range, Cost range, Has Abilities, Has Stats |
| Clear all | Top panel | "✖ Clear All" button - resets everything |

### Preview Panel
- **Location:** Right side of window (resizable splitter)
- **Shows:** Item tooltip with WC3-style colors, rarity border, icon placeholder
- **Updates:** Automatically when you select an item
- **Multi-select:** Shows count instead of preview

## 🎨 Visual Cues

### Rarity Colors
- **Common:** Light Gray
- **Uncommon:** Green
- **Rare:** Blue
- **Epic:** Purple
- **Legendary:** Orange
*(Applied to name in preview + icon border)*

### Button Colors
- **Green:** Add New
- **Blue:** Edit
- **Red:** Delete
- **Purple:** Export to W3T
- **Gray:** Connect/Reconnect

### Connection Status
- **Green dot:** Connected to PostgreSQL
- **Red dot:** Disconnected

## 🧠 Smart Assistance

When saving an item, the system checks for:

### ⚠️ Warnings (you can save anyway)
- **Similar name exists** - another item has matching name
- **Missing icon/model paths** - item will use defaults
- **Missing tooltip** - consider auto-generating
- **Invalid code format** - should be letter-digit-letter-digit (e.g., i0a5)
- **Duplicate code** - code already exists in database
- **High-level item with no stats** - level > 5 but no stats assigned

### 💰 Balance Suggestions
- **Underpriced:** Cost < Level × 50
- **Overpriced:** Cost > Level × 1000
- **Expected range:** Level × 50 to Level × 500

### 📝 Text Quality
- Multiple spaces detected
- Leading/trailing spaces
- All CAPS warning
- Common typos (teh → the, sowrd → sword, etc.)

## 🔄 Duplicate Item Feature

**How to duplicate:**
1. Right-click item
2. Select "📋 Duplicate"
3. Edit form opens with:
   - All fields copied
   - New code auto-generated (e.g., i0a5 → i0a6)
   - Title: "Duplicate Item (Save with New Code)"
4. Modify as needed
5. Save as NEW item

**Code generation logic:**
- Increments trailing number: `i0a5` → `i0a6`
- Wraps at 9: `i0a9` → `i0b0`
- Increments letters: `i0z9` → `i1a0`
- Fallback: appends "2" or "_copy"

## ⚙️ Settings Persistence

**Auto-saved:**
- Column widths
- Window size (not yet implemented)
- Filter states (not yet implemented)

**Location:** `MainFormSettings.ini` in app directory

**Format:**
```ini
item_code=80
item_name=250
rarity=100
```

**Reset:** Delete `MainFormSettings.ini` to restore defaults

## 🐛 Troubleshooting

### "Not connected to database" error
1. Check PostgreSQL is running
2. Verify database `wc3_pots` exists
3. Click "🔌 Connect" button
4. Check connection string in code if still failing

### Preview panel is empty
- Make sure an item is selected (single selection only)
- Multi-select shows count instead of preview

### Context menu not appearing
- Right-click on a data row (not header)
- If no rows, add some items first

### Filters not working
- Check database has data matching filter
- Try "✖ Clear All" to reset
- Advanced filters hidden? Click "▼ Advanced"

### Smart assistance warnings won't go away
- Click "Yes" to save anyway (warnings are non-blocking)
- Or fix the issues mentioned and save again

## 💡 Pro Tips

1. **Quick search:** Just start typing in search box (no need to click)
2. **Multi-sort:** Can't sort by multiple columns yet - use SQL filters instead
3. **Batch editing:** Create a template item, duplicate it multiple times, then edit
4. **Balance checking:** Keep cost around Level × 100-200 for balanced items
5. **Code patterns:** Stick to `[a-z][0-9][a-z][0-9]` format for WC3 compatibility
6. **Preview speed:** Preview updates instantly - no delay
7. **Filter combos:** Combine search + rarity + class for precise results
8. **Custom items:** Use "Custom Only" filter when working on your content

## 📋 Common Workflows

### Adding a New Item
1. Click "➕ Add New"
2. Fill in required fields (Code, Name)
3. Select Rarity, Class, Type
4. Click "Auto-Generate Tooltip" if needed
5. Add stats in Stats tab
6. Save (warnings will appear if needed)

### Duplicating an Item Series
1. Create "template" item (e.g., "Basic Sword")
2. Right-click → Duplicate
3. Rename to "Enhanced Sword", increase stats/level/cost
4. Repeat for "Legendary Sword", etc.
5. Use consistent code increments (i0a1, i0a2, i0a3...)

### Finding Items to Edit
1. Use Search box: type keyword (e.g., "fire")
2. Filter by Rarity: Legendary
3. Filter by Class: Weapon
4. Result: All legendary fire weapons
5. Double-click to edit

### Batch Deleting Test Items
1. Search: "test"
2. Ctrl+Click all test items
3. Right-click → "Batch Delete (X items)"
4. Confirm deletion
5. Done in one operation!

### Checking Item Balance
1. Create/edit item
2. Set level and cost
3. Try to save
4. Smart assistance will warn if:
   - Cost too low: "May be underpriced"
   - Cost too high: "May be overpriced"
5. Adjust and save

## 🚀 Advanced Features

### Filter Presets (Not Yet Implemented)
*Planned feature to save filter combinations like:*
- "My Legendaries" (Rarity=Legendary, Has Stats=true)
- "Low Level Items" (Level 1-10)
- "High Value" (Cost > 10000)

### Item Templates (Not Yet Implemented)
*Planned feature to save item configurations for reuse*

### Icon Loading (Not Yet Implemented)
*Preview panel has placeholder but doesn't load images yet*

---

## 🆘 Need Help?

**Documentation:**
- Full details: `GUI_IMPROVEMENTS_SUMMARY.md`
- Code comments in MainForm.cs and ItemEditForm.cs

**Common Issues:**
- Check PostgreSQL service is running
- Verify database connection string
- Delete `MainFormSettings.ini` if corrupted
- Rebuild project if errors after update

---

**Version:** 1.0  
**Last Updated:** March 12, 2026  
**Project:** WC3 PotS - Item Database Manager
