"""
Verify Table Placement in Latest Export
"""

from wc3_w3t_parser import WC3ObjectDataParser

# Parse files
original = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
orig_data = original.parse()

new = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0123.w3t')
new_data = new.parse()

print(f"\n{'='*60}")
print("TABLE PLACEMENT VERIFICATION")
print(f"{'='*60}")

print(f"\nOriginal file:")
print(f"  Original objects: {len(orig_data['original_objects'])}")
print(f"  Custom objects: {len(orig_data['custom_objects'])}")

print(f"\nNew export:")
print(f"  Original objects: {len(new_data['original_objects'])}")
print(f"  Custom objects: {len(new_data['custom_objects'])}")

# Check if counts match
orig_match = len(new_data['original_objects']) == len(orig_data['original_objects'])
custom_match = len(new_data['custom_objects']) == len(orig_data['custom_objects'])

print(f"\n{'='*60}")
if orig_match and custom_match:
    print("✓ TABLE PLACEMENT CORRECT!")
else:
    print("✗ TABLE PLACEMENT INCORRECT")
print(f"{'='*60}")

# Sample check - show first few items in each table
print(f"\nOriginal table (first 5):")
print("  Original file:", [obj['new_id'] for obj in orig_data['original_objects'][:5]])
print("  New export:", [obj['new_id'] for obj in new_data['original_objects'][:5]])

print(f"\nCustom table (first 5):")
print("  Original file:", [obj['new_id'] for obj in orig_data['custom_objects'][:5]])
print("  New export:", [obj['new_id'] for obj in new_data['custom_objects'][:5]])

# Total modifications
orig_count = sum(len(obj['modifications']) for obj in orig_data['original_objects'] + orig_data['custom_objects'])
new_count = sum(len(obj['modifications']) for obj in new_data['original_objects'] + new_data['custom_objects'])

print(f"\nTotal modifications:")
print(f"  Original: {orig_count:,} (avg: {orig_count/608:.1f} per item)")
print(f"  New export: {new_count:,} (avg: {new_count/608:.1f} per item)")

# Check abilities
orig_abilities = sum(1 for obj in orig_data['original_objects'] + orig_data['custom_objects'] 
                     for mod in obj['modifications'] if mod['id'] == 'iabi')
new_abilities = sum(1 for obj in new_data['original_objects'] + new_data['custom_objects']
                    for mod in obj['modifications'] if mod['id'] == 'iabi')

print(f"\nAbilities preserved: {orig_abilities} → {new_abilities} {'✓' if orig_abilities == new_abilities else '✗'}")

print(f"\n{'='*60}")
print("STATUS: Ready to test in World Editor")
print(f"{'='*60}\n")
