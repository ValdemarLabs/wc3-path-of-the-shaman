"""Verify the exported file has abilities"""
from wc3_w3t_parser import WC3ObjectDataParser

parser = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0310-2346.w3t')
data = parser.parse()

# Find items with abilities
items_with_abilities = []
for obj in data['custom_objects'] + data['original_objects']:
    abilities = [m for m in obj['modifications'] if m['id'] == 'iabi']
    if abilities:
        items_with_abilities.append({
            'item_code': obj['new_id'],
            'abilities': abilities[0]['value']
        })

print(f"✓ Exported file has {len(items_with_abilities)} items with abilities")
print("\nSample items with abilities:")
for item in items_with_abilities[:10]:
    print(f"  {item['item_code']}: {item['abilities']}")

# Verify specific item from screenshot
print("\n✓ Checking item 'ajen' (Alleria's Flute)...")
for obj in data['custom_objects']:
    if obj['new_id'] == 'Alar' or 'flute' in obj['new_id'].lower():
        print(f"  Found: {obj['new_id']}")
        for mod in obj['modifications']:
            if mod['id'] in ['iabi', 'unam']:
                print(f"    {mod['id']}: {mod['value']}")
