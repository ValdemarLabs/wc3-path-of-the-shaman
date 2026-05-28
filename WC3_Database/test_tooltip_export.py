#!/usr/bin/env python3
"""Test export of a single item with tooltip_extended to see debug output."""

import sys
import os

# Add paths for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'parsers'))
sys.path.insert(0, os.path.dirname(__file__))

from core.wc3_w3t_exporter import WC3W3TExporter

# Database configuration
db_config = {
    'host': '127.0.0.1',
    'port': '5432',
    'database': 'wc3_pots',
    'user': 'postgres',
    'password': '009900'
}

# Path to original .w3t file
original_w3t = r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t'

# Output path for test
output_path = r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\TEST_tooltip_export.w3t'

print("Testing tooltip_extended export...")
print("="*60)

try:
    exporter = WC3W3TExporter(db_config, original_w3t_path=original_w3t)
    exporter.connect()
    
    # First, check which items have tooltip_extended
    cursor = exporter.conn.cursor()
    cursor.execute("""
        SELECT item_code, item_name, base_id, 
               length(tooltip_extended) as tooltip_len,
               substring(tooltip_extended from 1 for 60) as preview
        FROM items 
        WHERE tooltip_extended IS NOT NULL 
          AND tooltip_extended != ''
        ORDER BY updated_at DESC
        LIMIT 5
    """)
    
    print("\nItems with tooltip_extended data:")
    print("-" * 60)
    test_items = []
    for row in cursor.fetchall():
        item_code, name, base_id, length, preview = row
        is_custom = "CUSTOM" if base_id else "ORIGINAL"
        print(f"{item_code} ({is_custom}): {name[:30]} - {length} chars")
        print(f"  Preview: {preview}...")
        test_items.append(item_code)
    
    cursor.close()
    
    if not test_items:
        print("\n[ERROR] No items with tooltip_extended found!")
        sys.exit(1)
    
    # Export first 3 items
    test_codes = test_items[:3]
    print(f"\n\nExporting {len(test_codes)} test items: {test_codes}")
    print("="*60)
    print("Watch for [DEBUG] lines showing utub writes...")
    print("="*60)
    
    exporter.export_to_w3t(output_path, item_codes=test_codes)
    
    exporter.disconnect()
    
    print("\n[OK] Test export completed!")
    print(f"Check output above for '[DEBUG] Writing utub for...' messages")
    
except Exception as e:
    print(f"\n[ERROR] Test export failed: {e}")
    import traceback
    traceback.print_exc()
