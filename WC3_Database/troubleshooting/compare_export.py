"""Compare specific item between original and exported files"""
from wc3_w3t_parser import WC3ObjectDataParser

# Parse original
print("Original file:")
parser1 = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
data1 = parser1.parse()

# Parse exported
print("\nExported file:")
parser2 = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0310-2346.w3t')
data2 = parser2.parse()

# Compare I603
test_item = 'I603'
print(f"\n{'='*60}")
print(f"Comparing item: {test_item}")
print(f"{'='*60}")

for label, data in [("ORIGINAL", data1), ("EXPORTED", data2)]:
    print(f"\n{label}:")
    for obj in data['custom_objects']:
        if obj['new_id'] == test_item:
            print(f"  Item: {obj['new_id']}")
            print(f"  Modifications: {len(obj['modifications'])}")
            
            # Show key fields
            for mod in obj['modifications']:
                if mod['id'] in ['iabi', 'unam', 'igol', 'ilev']:
                    print(f"    {mod['id']:4s}: {mod['value']}")
            break
