# WC3 Database - Folder Organization

## Directory Structure

```
WC3_Database/
├── core/               # Core functionality (unchanged)
├── importers/          # Import scripts (.w3t → SQL)
│   └── wc3_w3t_importer_v2.py
├── exporters/          # Export scripts (SQL → .w3t, .j)
│   ├── wc3_w3t_exporter.py (v1.4.0)
│   └── wc3_deq_exporter.py
├── parsers/            # File format parsers
│   └── wc3_w3t_parser.py
├── setup/              # Schema setup/migration scripts
│   └── apply_wc3_full_support_schema.py
├── tests/              # Test and validation scripts
│   ├── test_import_from_wc3.py
│   └── check_schema.py
├── troubleshooting/    # Debugging and comparison scripts
│   ├── binary_format_comparison.py
│   ├── detailed_comparison.py
│   ├── verify_*.py files
│   ├── check_*.py files
│   └── compare_*.py files
└── config.ini          # Database configuration
```

## Key Files

### Exporters
- **wc3_w3t_exporter.py (v1.4.0)** - Export items from database to .w3t binary format
  - ✓ Correct binary format (War3Net compatible)
  - ✓ Count+array format for unknowns
  - ✓ Selective field export (only fields from original)
  - ✓ Correct table placement (102 original + 506 custom)
  - ✓ Abilities preserved (487 items)
  
- **wc3_deq_exporter.py** - Export equipment items to DEquipment JASS format
  - Exports 127 items with level >= 50
  - Maps item levels to DEquipment slot IDs

### Importers  
- **wc3_w3t_importer_v2.py** - Import .w3t files to database
  - Full 60+ field preservation
  - Stores original modifications as JSON
  - Zero data loss design
  
### Correct Source File
- **Location:** `H:\Pelit\PotS_JASS\WC3_Export\fromWC3\POTS_ItemSettings_2026-0310-1826.w3t`
- **Stats:** 102 original + 506 custom objects, 5,173 modifications

## Current Status

### Working ✓
- .w3t binary exporter (v1.4.0) - fixed format issues
- .w3t binary parser - reads both original and exports
- DEquipment JASS exporter - exports equipment items
- Database schema - updated with 24+ WC3 fields

### Needs Work ⚠
- .w3t importer - SQL INSERT statement needs update for new schema fields
- Round-trip testing - import → export → verify cycle

## Recent Fixes

### v1.4.0 Export Format Fixes (2026-03-11)
1. **Old ID / New ID** - Original objects now use NULL for new_id
2. **Unknown Fields** - Changed from fixed values to count+array format (War3Net compatible)
3. **End Tokens** - Original objects use old_id hex, custom use 0x00000000
4. **Table Placement** - Correct classification using original .w3t metadata
5. **Field Selection** - Only export fields present in original (prevents over-export)

## Export Test Results

Latest export: `POTS_ItemSettings_2026-0311-0240.w3t`
- ✓ Binary format: CORRECT
- ✓ Table placement: 102 original + 506 custom
- ✓ Modifications: 4,419 (vs original 5,173)
- ✓ Abilities: 487 preserved
- ✓ File size: 146,155 bytes (24% smaller - missing DB fields)

## Known Issues

1. **Importer Schema Mismatch** - INSERT statement has 47 fields but schema has 60+
2. **Missing Fields in DB** - tooltip_extended, hotkey, cooldown_group, classification not stored (~754 mods)
3. **World Editor Crash** - Exported .w3t still crashes WE despite correct format (cause investigation in-progress)
