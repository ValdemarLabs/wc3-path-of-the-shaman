#!/usr/bin/env python3
"""Check what data exists in w3t file for specific items."""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'parsers'))
sys.path.insert(0, os.path.dirname(__file__))

from parsers.wc3_w3t_parser import WC3ObjectDataParser

# Analyze the NEW fixed export with name skip
w3t_path = r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0317-0912_FIXED.w3t'

if not os.path.exists(w3t_path):
    print(f"[ERROR] File not found: {w3t_path}")
    sys.exit(1)

print(f"Analyzing: {w3t_path}")
print("="*80)

parser = WC3ObjectDataParser(w3t_path)
data = parser.parse()

print(f"\nOriginal objects: {len(data['original_objects'])}")
print(f"Custom objects: {len(data['custom_objects'])}")

# Convert to items dict and check field coverage
items = parser.to_items_dict()

print(f"\n{'='*80}")
print(f"FIELD COVERAGE IN W3T FILE:")
print(f"{'='*80}")

field_counts = {
    'item_name': 0,
    'icon_path': 0,
    'model_path': 0,
    'scale': 0,
    'cooldown_group': 0,
    'wc3_abilities': 0,
    'tint_red': 0,
    'tooltip_extended': 0,
}

for item in items:
    for field in field_counts.keys():
        if field in item and item[field]:
            field_counts[field] += 1

total = len(items)
print(f"Total items in w3t: {total}\n")
print(f"Items with fields:")
print(f"  item_name (unam):      {field_counts['item_name']:4d} ({field_counts['item_name']/total*100:5.1f}%)")
print(f"  icon_path (iico):      {field_counts['icon_path']:4d} ({field_counts['icon_path']/total*100:5.1f}%)")
print(f"  model_path (ifil):     {field_counts['model_path']:4d} ({field_counts['model_path']/total*100:5.1f}%)")
print(f"  scale (isca):          {field_counts['scale']:4d} ({field_counts['scale']/total*100:5.1f}%)")
print(f"  cooldown_group (icid): {field_counts['cooldown_group']:4d} ({field_counts['cooldown_group']/total*100:5.1f}%)")
print(f"  wc3_abilities (iabi):  {field_counts['wc3_abilities']:4d} ({field_counts['wc3_abilities']/total*100:5.1f}%)")
print(f"  tint_red (iclr):       {field_counts['tint_red']:4d} ({field_counts['tint_red']/total*100:5.1f}%)")
print(f"  tooltip_extended:      {field_counts['tooltip_extended']:4d} ({field_counts['tooltip_extended']/total*100:5.1f}%)")

# Check specific problem items
print(f"\n{'='*80}")
print(f"CHECKING SPECIFIC ITEMS:")
print(f"{'='*80}")

problem_items = ['ankh', 'asbl', 'belv', 'ajen', 'bgst']

for item in items:
    if item['item_code'] in problem_items:
        print(f"\n[{item['item_code']}]")
        print(f"  Name: {item.get('item_name', '(missing)')}")
        print(f"  Icon: {item.get('icon_path', '(missing)')}")
        print(f"  Model: {item.get('model_path', '(missing)')}")
        print(f"  Scale: {item.get('scale', '(missing)')}")
        print(f"  Cooldown: {item.get('cooldown_group', '(missing)')}")
        print(f"  Abilities: {item.get('wc3_abilities', '(missing)')}")
        print(f"  Tint Red: {item.get('tint_red', '(missing)')}")
        
        # Check raw modifications
        if 'modifications' in item:
            print(f"  Raw modifications: {len(item['modifications'])} fields")
            if 'iico' in item['modifications']:
                print(f"    → iico exists: {item['modifications']['iico']['value']}")
            if 'ifil' in item['modifications']:
                print(f"    → ifil exists: {item['modifications']['ifil']['value']}")
            if 'iabi' in item['modifications']:
                print(f"    → iabi exists: {item['modifications']['iabi']['value']}")
        
        print("-"*80)

print(f"\n{'='*80}")
print(f"CONCLUSION:")
print(f"{'='*80}")
print(f"\nIf w3t file has low field coverage, the data was never exported properly.")
print(f"If w3t file has high coverage but DB is low, importer is failing to save data.")
