"""Check what abilities are in the original .w3t file"""
from wc3_w3t_parser import WC3ObjectDataParser

parser = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
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

print(f"Items with abilities: {len(items_with_abilities)}")
print("\nSample items with abilities:")
for item in items_with_abilities[:10]:
    print(f"  {item['item_code']}: {item['abilities']}")
