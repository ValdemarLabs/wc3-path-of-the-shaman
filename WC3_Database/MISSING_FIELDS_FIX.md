# Missing Visual Fields Issue - Root Cause & Fix

## Problem Summary
After importing .w3t files and exporting again, many items were missing:
- icon_path (iico) - 49.5% missing
- model_path (ifil) - 32.6% missing  
- cooldown_group (icid) - 92.2% missing
- scale (isca) - 92.5% missing
- wc3_abilities (iabi) - 68.3% missing
- tint colors (iclr/iclg/iclb) - 93.9% missing

## Root Cause Analysis

### Investigation Process
1. Checked database field coverage → Found high % of NULL/empty values
2. Checked current exported .w3t file → Found low field coverage
3. **Checked ORIGINAL .w3t from World Editor** → Found SAME low coverage!

### Key Finding
The **ORIGINAL** w3t file from World Editor (`fromWC3\POTS_ItemSettings_2026-0310-1826.w3t`) has:
- 50.8% have icon_path
- 48.8% have model_path
- **Only 5.8% have cooldown_group** (35 out of 608 items)
- Only 2.0% have scale
- Only 31.6% have abilities

**Why?** Many items are "original objects" (modified Blizzard items) that only specify PARTIAL modifications. World Editor fills in the rest from its built-in default item data.

### The Data Poisoning Cycle
1. **Original WC3 Export**: Item has only `ifil` field modified, relies on WC3 defaults for icon/abilities
2. **Import to Database**: Saves `ifil`, other fields are NULL
3. **Export from Database**: OLD exporter wrote **empty strings** ("") for NULL fields
4. **Import back to WC3**: Empty strings **overwrite** WC3's ability to use defaults
5. **Result**: Item loses its icon, abilities, and other properties that WC3 would have provided

## The Fix

### Changes to wc3_w3t_exporter.py

**1. Skip Empty Fields for Custom Items** (Lines 303-319):
```python
# OLD CODE: Wrote empty strings for NULL
if value is None:
    if field_type == self.TYPE_STRING:
        value = ""  # ❌ This overwrites WC3 defaults!

# NEW CODE: Skip empty fields entirely
if value is None or value == '' or value == 0:
    if field_type == self.TYPE_STRING and (value is None or value == ''):
        continue  # ✓ Skip - let WC3 use defaults
```

**2. Remove icon_path from REQUIRED_FIELDS** (Line 108):
```python
# OLD: Forced export of empty icon_path
REQUIRED_FIELDS = ['item_name', 'icon_path', 'tooltip_extended', 'description']

# NEW: Only require text fields that we actually populate
REQUIRED_FIELDS = ['item_name', 'tooltip_extended', 'description']
```

**3. Skip Empty Values for Original Items** (Line 321):
```python
# OLD: Could export empty required fields
if value is not None:

# NEW: Skip empty/zero values
if value is not None and value != '' and value != 0:
```

### What This Achieves
- **Empty/NULL fields are NOT written** to .w3t file
- **WC3 can use default data** from base items (bzbe, bspd, etc.)
- **Non-empty database values ARE exported** (tooltips, names, custom values)
- **Prevents data loss** in export→import cycles

## Testing

### Test Script
Run: `python test_fixed_export.py`

This exports test items: ankh, asbl, belv, bgst, ajen

### Expected Results
After importing the test .w3t into World Editor:
- ✓ Items should show correct icons (from WC3 defaults)
- ✓ Items should show correct models (from WC3 defaults)
- ✓ Items should have abilities (if base item has them)
- ✓ Custom fields (names, tooltips) should be preserved

### Before/After Comparison

**Before Fix** (exported w3t):
- ankh: icon="" (empty string written) → WC3 shows no icon ❌
- belv: model="" (empty string written) → WC3 shows no model ❌

**After Fix** (exported w3t):
- ankh: icon field NOT PRESENT → WC3 uses default from base item ✓
- belv: model="ITEMBootsOfSpeed.mdl" → Custom model preserved ✓

## Migration Path

### For Current Database
**Option 1: Re-import Original File**
```bash
cd "h:\Pelit\PotS_JASS\WC3_Database"
python core\wc3_w3t_importer.py
# Select: H:\Pelit\PotS_JASS\WC3_Export\fromWC3\POTS_ItemSettings_2026-0310-1826.w3t
```
This will restore the original field coverage (still low, but correct).

**Option 2: Keep Current Database**
- Current NULL/empty values are correct - they mean "use WC3 default"
- Just use the new exporter - it will skip those fields
- WC3 will fill in from defaults

### For New Exports
Simply export with the new exporter:
```bash
python core/wc3_w3t_exporter.py
```

The exported .w3t will no longer poison the data with empty strings.

## Files Modified
1. `core/wc3_w3t_exporter.py`:
   - Line 108: Removed icon_path from REQUIRED_FIELDS
   - Lines 303-319: Skip NULL/empty fields for custom items
   - Line 321: Skip empty values for original items

## New Diagnostic Tools
1. `analyze_w3t_coverage.py` - Check field coverage in .w3t files
2. `check_missing_fields.py` - Check database field coverage
3. `check_empty_vs_null.py` - Detect data poisoning (empty strings vs NULL)
4. `test_fixed_export.py` - Test export with new logic

## Summary
The issue wasn't missing data - it was the exporter **overwriting** WC3's ability to use default data by writing empty strings. The fix allows WC3 to do what it's designed to do: inherit properties from base items when not explicitly overridden.
