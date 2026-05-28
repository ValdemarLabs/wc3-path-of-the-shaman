"""
Quick comparison of latest export
"""

from wc3_w3t_parser import WC3ObjectDataParser

# Parse files
original = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
orig_data = original.parse()

new = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0116.w3t')
new_data = new.parse()

# Count mods
orig_count = sum(len(obj['modifications']) for obj in orig_data['original_objects'] + orig_data['custom_objects'])
new_count = sum(len(obj['modifications']) for obj in new_data['original_objects'] + new_data['custom_objects'])

print(f"\n{'='*60}")
print("LATEST EXPORT COMPARISON")
print(f"{'='*60}")
print(f"Total modifications:")
print(f"  Original: {orig_count:,} (avg: {orig_count/608:.1f} per item)")
print(f"  New export: {new_count:,} (avg: {new_count/608:.1f} per item)")
print(f"  Difference: {new_count - orig_count:+,}")
print(f"\nFile size:")
print(f"  Original: 192,754 bytes")
print(f"  New export: 146,155 bytes (24% smaller)")
print(f"\nStatus: {'✓ VERY CLOSE' if abs(new_count - orig_count) < 500 else '⚠ STILL DIFFERENT'}")
print(f"{'='*60}\n")

# Check if abilities preserved
orig_abilities = sum(1 for obj in orig_data['original_objects'] + orig_data['custom_objects'] 
                     for mod in obj['modifications'] if mod['id'] == 'iabi')
new_abilities = sum(1 for obj in new_data['original_objects'] + new_data['custom_objects']
                    for mod in obj['modifications'] if mod['id'] == 'iabi')
print(f"Abilities (iabi): {orig_abilities} → {new_abilities} {'✓' if orig_abilities == new_abilities else '✗'}")
