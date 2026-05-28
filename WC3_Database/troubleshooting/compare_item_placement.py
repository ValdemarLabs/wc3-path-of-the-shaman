"""
Compare which items are in original vs custom tables
"""

from wc3_w3t_parser import WC3ObjectDataParser

# Parse files
original = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
orig_data = original.parse()

new = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0123.w3t')
new_data = new.parse()

# Get sets of item codes in each table
orig_original_set = set(obj['new_id'] for obj in orig_data['original_objects'])
orig_custom_set = set(obj['new_id'] for obj in orig_data['custom_objects'])

new_original_set = set(obj['new_id'] for obj in new_data['original_objects'])
new_custom_set = set(obj['new_id'] for obj in new_data['custom_objects'])

print(f"\n{'='*60}")
print("ITEM PLACEMENT COMPARISON")
print(f"{'='*60}")

# Check if sets match
orig_match = orig_original_set == new_original_set
custom_match = orig_custom_set == new_custom_set

print(f"\nOriginal table items match: {orig_match}")
print(f"Custom table items match: {custom_match}")

if not orig_match:
    print(f"\nItems in original table but not in new export:")
    missing = orig_original_set - new_original_set
    print(f"  Count: {len(missing)}")
    if len(missing) <= 10:
        print(f"  Items: {sorted(missing)}")
    
    print(f"\nItems in new export but not in original table:")
    extra = new_original_set - orig_original_set
    print(f"  Count: {len(extra)}")
    if len(extra) <= 10:
        print(f"  Items: {sorted(extra)}")

if not custom_match:
    print(f"\nItems in custom table but not in new export:")
    missing = orig_custom_set - new_custom_set
    print(f"  Count: {len(missing)}")
    if len(missing) <= 10:
        print(f"  Items: {sorted(missing)}")
    
    print(f"\nItems in new export but not in custom table:")
    extra = new_custom_set - orig_custom_set
    print(f"  Count: {len(extra)}")
    if len(extra) <= 10:
        print(f"  Items: {sorted(extra)}")

print(f"\n{'='*60}")
if orig_match and custom_match:
    print("✓ ALL ITEMS IN CORRECT TABLES")
else:
    print("✗ ITEM PLACEMENT MISMATCH")
print(f"{'='*60}\n")
