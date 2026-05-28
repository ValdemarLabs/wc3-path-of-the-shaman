#!/usr/bin/env python3
"""Test export with updated logic that skips empty fields."""

import sys
import os
from datetime import datetime

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

# Path to original .w3t file (for abilities)
original_w3t = r'H:\Pelit\PotS_JASS\WC3_Export\fromWC3\POTS_ItemSettings_2026-0310-1826.w3t'

# Output file
timestamp = datetime.now().strftime('%Y-%m%d-%H%M')
output_filename = f'POTS_ItemSettings_{timestamp}_FIXED.w3t'
output_path = os.path.join(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3', output_filename)

print("="*80)
print("TESTING EXPORT WITH FIXED LOGIC")
print("="*80)
print("Changes:")
print("  - Skip NULL/empty fields instead of writing empty strings")
print("  - Allows WC3 to use defaults from base items")
print("  - icon_path removed from REQUIRED_FIELDS")
print("="*80)

try:
    exporter = WC3W3TExporter(db_config, original_w3t_path=original_w3t)
    exporter.connect()
    
    # Export a few test items first
    test_items = ['ankh', 'asbl', 'belv', 'bgst', 'ajen', 'i0d0', 'i0d1']
    print(f"\nExporting {len(test_items)} test items...")
    exporter.export_to_w3t(output_path, item_codes=test_items)
    
    exporter.disconnect()
    
    print(f"\n{'='*80}")
    print("SUCCESS!")
    print(f"{'='*80}")
    print(f"Test file created: {output_path}")
    print(f"\nNext steps:")
    print(f"1. Import this file into World Editor")
    print(f"2. Check if items show proper icons, models, and abilities")
    print(f"3. If successful, export ALL items")
    
except Exception as e:
    print(f"\n[ERROR] {e}")
    import traceback
    traceback.print_exc()
