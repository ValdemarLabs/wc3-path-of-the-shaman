#!/usr/bin/env python3
"""Diagnose what data exists for original items in w3t file."""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'parsers'))
sys.path.insert(0, os.path.dirname(__file__))

from parsers.wc3_w3t_parser import WC3ObjectDataParser
import glob

# Find most recent w3t file
w3t_files = glob.glob(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\*.w3t')
if not w3t_files:
    print("[ERROR] No .w3t files found in H:\\Pelit\\PotS_JASS\\WC3_Export\\toWC3\\")
    sys.exit(1)

# Use most recent (by filename which has timestamp)
w3t_path = sorted(w3t_files)[-1]

print(f"Analyzing: {w3t_path}")
print("="*80)

parser = WC3ObjectDataParser(w3t_path)
data = parser.parse()

print(f"\nOriginal objects (modified Blizzard items): {len(data['original_objects'])}")
print(f"Custom objects (new items): {len(data['custom_objects'])}")

# Check a few problem items
problem_items = ['ankh', 'asbl', 'belv', 'clfm', 'clsd']

print("\n" + "="*80)
print("CHECKING PROBLEM ITEMS:")
print("="*80)

for obj in data['original_objects']:
    item_code = obj['new_id']
    if item_code in problem_items:
        print(f"\n[{item_code}] Original Item")
        print(f"  Original ID: {obj['original_id']}")
        print(f"  Modifications: {len(obj['modifications'])} fields")
        
        # Check what fields are present
        has_name = False
        has_abilities = False
        has_cooldown = False
        
        for mod in obj['modifications']:
            field_id = mod['id']
            value = mod['value']
            
            if field_id == 'unam':
                has_name = True
                print(f"    unam (Name): {value}")
            elif field_id == 'iabi':
                has_abilities = True
                print(f"    iabi (Abilities): {value}")
            elif field_id == 'icid':
                has_cooldown = True
                print(f"    icid (Cooldown Group): {value}")
            elif field_id == 'utub':
                print(f"    utub (Extended Tooltip): {value[:60]}...")
            elif field_id == 'ides':
                print(f"    ides (Description): {value[:60]}...")
            elif field_id == 'iico':
                print(f"    iico (Icon): {value}")
            elif field_id == 'ifil':
                print(f"    ifil (Model): {value}")
        
        print(f"\n  Has Name: {'✓' if has_name else '✗'}")
        print(f"  Has Abilities: {'✓' if has_abilities else '✗'}")
        print(f"  Has Cooldown: {'✓' if has_cooldown else '✗'}")
        
        if not has_name:
            print(f"\n  ⚠️ This item will be SKIPPED (no name in modifications)")
        
        print("-"*80)

# Summary
print("\n" + "="*80)
print("SUMMARY:")
print("="*80)

items_without_names = 0
items_without_abilities = 0

for obj in data['original_objects']:
    has_name = any(mod['id'] == 'unam' for mod in obj['modifications'])
    has_abilities = any(mod['id'] == 'iabi' for mod in obj['modifications'])
    
    if not has_name:
        items_without_names += 1
    if not has_abilities:
        items_without_abilities += 1

print(f"Original items without 'unam' (name) field: {items_without_names}")
print(f"Original items without 'iabi' (abilities) field: {items_without_abilities}")
print(f"\nWith the new importer fix:")
print(f"  - {items_without_names} items will be SKIPPED (no name)")
print(f"  - These are partial modifications that need WC3's default data")
print(f"  - Custom items and fully specified original items will import correctly")
