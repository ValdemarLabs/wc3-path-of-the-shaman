"""
Verify Latest Export - Check Table Structure
"""

from wc3_w3t_parser import WC3ObjectDataParser

# Parse both files
original = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
orig_data = original.parse()

new_export = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0123.w3t')
new_data = new_export.parse()

print(f"\n{'='*60}")
print("TABLE STRUCTURE VERIFICATION")
print(f"{'='*60}")
print(f"\n{'File':<25} {'Original':<12} {'Custom':<12} {'Total':<10}")
print(f"{'-'*60}")
print(f"{'Original .w3t':<25} {len(orig_data['original_objects']):<12} {len(orig_data['custom_objects']):<12} {len(orig_data['original_objects']) + len(orig_data['custom_objects']):<10}")
print(f"{'New Export':<25} {len(new_data['original_objects']):<12} {len(new_data['custom_objects']):<12} {len(new_data['original_objects']) + len(new_data['custom_objects']):<10}")

# Verify same items in each table
orig_original_ids = set(obj['new_id'] for obj in orig_data['original_objects'])
new_original_ids = set(obj['new_id'] for obj in new_data['original_objects'])
orig_custom_ids = set(obj['new_id'] for obj in orig_data['custom_objects'])
new_custom_ids = set(obj['new_id'] for obj in new_data['custom_objects'])

table_match = (orig_original_ids == new_original_ids) and (orig_custom_ids == new_custom_ids)

print(f"\n{'='*60}")
print("TABLE PLACEMENT:")
print(f"{'='*60}")
print(f"Original table items match: {'✓ YES' if orig_original_ids == new_original_ids else '✗ NO'}")
print(f"Custom table items match: {'✓ YES' if orig_custom_ids == new_custom_ids else '✗ NO'}")

# Check sample base IDs
print(f"\n{'='*60}")
print("BASE ID VERIFICATION (Sample Custom Objects):")
print(f"{'='*60}")
print(f"{'Item':<8} {'Original Base':<15} {'Export Base':<15} {'Match':<8}")
print(f"{'-'*60}")

orig_custom_map = {obj['new_id']: obj['original_id'] for obj in orig_data['custom_objects']}
new_custom_map = {obj['new_id']: obj['original_id'] for obj in new_data['custom_objects']}

for item_id in list(orig_custom_ids)[:10]:
    if item_id in new_custom_map:
        orig_base = orig_custom_map[item_id]
        new_base = new_custom_map[item_id]
        match = '✓' if orig_base == new_base else '✗'
        print(f"{item_id:<8} {orig_base:<15} {new_base:<15} {match:<8}")

# Count mods
orig_mods = sum(len(obj['modifications']) for obj in orig_data['original_objects'] + orig_data['custom_objects'])
new_mods = sum(len(obj['modifications']) for obj in new_data['original_objects'] + new_data['custom_objects'])

print(f"\n{'='*60}")
print("MODIFICATION COUNT:")
print(f"{'='*60}")
print(f"Original: {orig_mods:,} mods (avg {orig_mods/608:.1f} per item)")
print(f"Export:   {new_mods:,} mods (avg {new_mods/608:.1f} per item)")
print(f"Difference: {new_mods - orig_mods:+,}")

print(f"\n{'='*60}")
print("FINAL STATUS:")
print(f"{'='*60}")
if table_match:
    print("✓ Table structure MATCHES original perfectly")
    print("✓ This export should work in World Editor")
else:
    print("✗ Table structure does NOT match - WE may crash")
print(f"{'='*60}\n")
