# WC3 Database Tools - Organized Structure

This folder contains tools for importing/exporting Warcraft 3 item data between .w3t files and PostgreSQL database.

## 📁 Folder Structure

### `/core/` - Main Production Scripts
Core functionality for parsing, importing, and exporting WC3 data.

- **wc3_w3t_parser.py** - Parses .w3t binary files into Python objects
- **wc3_w3t_importer.py** - Imports items from .w3t files to PostgreSQL ⚠️ NEEDS REVIEW
- **wc3_w3t_exporter.py** - Exports items from PostgreSQL to .w3t files (v1.4.0 - War3Net compatible)
- **wc3_deq_exporter.py** - Exports DEquipment JASS library definitions
- **wc3_exporter.py** - General item exporter
- **wc3_exporter_enhanced.py** - Enhanced exporter with stats
- **wc3_importer.py** - General item importer
- **db_manager.py** - Database connection manager

### `/verification/` - Verification Scripts
Scripts for verifying export correctness and data integrity.

- verify_abilities_export.py
- verify_export.py
- verify_fixed_export.py
- verify_new_export.py
- verify_table_placement.py
- verify_table_structure.py

### `/troubleshooting/` - Debugging & Analysis
Scripts for troubleshooting format issues, comparing files, and analyzing data.

**Binary Analysis:**
- binary_format_comparison.py - Compare binary structure of .w3t files
- hex_analyze_first_two_objects.py - Low-level hex analysis
- final_verification.py - Comprehensive format verification

**Data Analysis:**
- analyze_itemlevels.py - Level system analysis
- analyze_mod_format.py - Modification format analysis
- analyze_original_w3t.py - Original file statistics
- analyze_sheet_structure.py - Spreadsheet structure
- analyze_w3t_structure.py - .w3t file structure

**Comparison Tools:**
- compare_export.py - Compare exported vs original
- compare_item_placement.py - Verify table placement
- detailed_comparison.py - Detailed field-by-field comparison
- quick_comparison.py - Quick stats comparison

**Format Checking:**
- check_abilities.py - Verify ability preservation
- check_base_id.py - Check base_id field
- check_custom_format.py - Custom objects format
- check_unknown_format.py - Unknown field format (v3)

**Other:**
- debug_w3t.py - General .w3t debugging
- diagnose_tables.py - Database table diagnostics  
- extract_level_system.py - Extract level system data

### `/docs/` - Documentation
Comprehensive guides and documentation.

- **README.md** - This file
- **QUICKSTART.md** - Quick start guide
- **QUICKSTART_EXISTING_DB.md** - Guide for existing database
- **MIGRATION_GUIDE.md** - Migration instructions
- **CONNECTION_TROUBLESHOOTING.md** - Database connection help
- **ENHANCEMENT_SUMMARY.md** - Enhancement history
- **ITEM_LEVEL_SYSTEM_ANALYSIS.md** - Level system documentation
- **STAT_SYSTEM_REFERENCE.md** - Item stat system reference

### `/database/` - SQL Schema & Queries
Database schema definitions and example queries.

- **schema.sql** - Complete database schema
- **schema_stats_enhancement.sql** - Stats system enhancement
- **check_existing_schema.sql** - Schema verification queries
- **example_queries.sql** - Example SQL queries

### `/setup/` - Setup & Installation Scripts
Scripts for setting up the database and environment.

- setup.bat, setup_fresh_db.bat, setup_existing_db.bat - Windows setup
- setup_fresh_db.ps1 - PowerShell setup script
- import_examples.bat, import_examples.sh - Import examples
- test_connection.bat - Test database connection

### `/config/` - Configuration Files
Configuration files and data mappings.

- **database.ini** - Database connection config (user-specific)
- **database.ini.example** - Example configuration
- **requirements.txt** - Python dependencies
- **item_table_mapping.json** - Item field mappings
- **example_items.json** - Example item data

## 🚨 Known Issues

### Importer Data Loss Issue
**Status:** ⚠️ CRITICAL - Needs Review

The current `wc3_w3t_importer.py` only imports ~15 fields out of 60+ fields that the parser extracts. This causes data loss for:

- `tooltip_extended` (utub) - 516 items in original
- `hotkey` (uhot) - 393 items
- `cooldown_group` (icid) - 357 items
- `classification` (icla) - 175 items
- `hit_points` (ihtp) - 38 items
- And many more...

**Impact:** After import → export cycle, the resulting .w3t file is missing ~754 modifications (14.6% data loss).

**Solution Required:**
1. Update database schema to include all WC3 fields
2. Update importer to store ALL fields from parser
3. Store original modifications in `custom_data` JSON field for perfect round-trip

## 🔄 Current Workflow

### Import .w3t → Database:
```bash
cd core
python wc3_w3t_importer.py path/to/file.w3t
```

### Export Database → .w3t:
```bash
cd core
python wc3_w3t_exporter.py
```

### Verify Export:
```bash
cd verification  
python verify_new_export.py
```

### Export DEquipment JASS:
```bash
cd core
python wc3_deq_exporter.py
```

## 📊 Export Statistics (v1.4.0)

**Latest Working Export:**
- File: POTS_ItemSettings_2026-0311-0240.w3t
- Format: Reforged v3 (War3Net compatible)
- Objects: 102 original + 506 custom
- Modifications: 4,419 total
- Abilities preserved: 487 ✓
- Binary format: CORRECT ✓

**Known Limitations:**
- Missing ~754 modifications (not stored in database)
- Can't preserve tooltip_extended, hotkey, cooldown_group, classification fields

## 🔧 Quick Commands

```bash
# Test database connection
cd setup
./test_connection.bat

# Fresh database setup
cd setup  
./setup_fresh_db.bat

# Import .w3t file
cd core
python wc3_w3t_importer.py "../path/to/file.w3t"

# Export to .w3t
cd core
python wc3_w3t_exporter.py

# Verify export
cd verification
python verify_new_export.py
```

## 📝 Notes

- All core scripts use relative imports - run from their folder or adjust imports
- Parser is production-ready and tested ✓
- Exporter v1.4.0 is War3Net-compatible and produces valid .w3t files ✓
- **Importer needs fixing to prevent data loss** ⚠️

## Version History

- **2026-03-11 v1.4.0** - Fixed exporter to use War3Net count+array format for unknown fields
- **2026-03-11 v1.3.0** - Fixed old_id/new_id for original objects, correct end tokens
- **2026-03-11 v1.2.0** - Fixed over-export issue (only export fields from original)
- **2026-03-10 v1.1.0** - Added ability preservation from original .w3t
- **2026-03-10 v1.0.0** - Initial importer/exporter/parser
