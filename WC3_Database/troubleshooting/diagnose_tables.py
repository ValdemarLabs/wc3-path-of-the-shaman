"""
Diagnose Original vs Custom Object Tables
"""

from wc3_w3t_parser import WC3ObjectDataParser

# Parse original file
print("Analyzing original .w3t structure...\n")
original = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
orig_data = original.parse()

print(f"{'='*60}")
print("ORIGINAL FILE STRUCTURE")
print(f"{'='*60}")
print(f"\nOriginal Objects (Blizzard items modified): {len(orig_data['original_objects'])}")
print(f"Custom Objects (new items): {len(orig_data['custom_objects'])}")

# Show sample original objects
print(f"\n{'='*60}")
print("SAMPLE ORIGINAL OBJECTS (Modified Blizzard Items):")
print(f"{'='*60}")
print(f"{'Item Code':<12} {'Base ID':<8} {'Mods':<6}")
print(f"{'-'*40}")
for obj in orig_data['original_objects'][:20]:
    print(f"{obj['new_id']:<12} {obj['original_id']:<8} {len(obj['modifications']):<6}")

# Show sample custom objects  
print(f"\n{'='*60}")
print("SAMPLE CUSTOM OBJECTS (New Items):")
print(f"{'='*60}")
print(f"{'Item Code':<12} {'Base ID':<8} {'Mods':<6}")
print(f"{'-'*40}")
for obj in orig_data['custom_objects'][:20]:
    base = obj['original_id'] if obj['original_id'] != '\x00\x00\x00\x00' else 'NULL'
    print(f"{obj['new_id']:<12} {base:<8} {len(obj['modifications']):<6}")

# Create mapping
original_ids = set(obj['new_id'] for obj in orig_data['original_objects'])
custom_ids = set(obj['new_id'] for obj in orig_data['custom_objects'])

print(f"\n{'='*60}")
print("KEY INSIGHT:")
print(f"{'='*60}")
print(f"Items in ORIGINAL table: {len(original_ids)}")
print(f"Items in CUSTOM table: {len(custom_ids)}")
print(f"\nWE MUST export items to the SAME tables they came from!")
print(f"Otherwise World Editor will crash/reject the file.")

# Save mapping to file for exporter
import json
mapping = {
    'original_objects': sorted(list(original_ids)),
    'custom_objects': sorted(list(custom_ids))
}

with open('item_table_mapping.json', 'w') as f:
    json.dump(mapping, f, indent=2)
    
print(f"\n✓ Saved table mapping to: item_table_mapping.json")
print(f"  - {len(original_ids)} items for 'original' table")
print(f"  - {len(custom_ids)} items for 'custom' table")
print(f"{'='*60}\n")
