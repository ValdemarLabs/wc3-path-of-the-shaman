"""Analyze original .w3t file to understand the format"""
from wc3_w3t_parser import WC3ObjectDataParser

# Parse original file
parser = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
data = parser.parse()

print(f"Version: {data['version']}")
print(f"Original objects: {len(data['original_objects'])}")
print(f"Custom objects: {len(data['custom_objects'])}")

if data['custom_objects']:
    obj = data['custom_objects'][0]
    print(f"\nFirst custom object: {obj['new_id']}")
    print(f"Modification count: {len(obj['modifications'])}")
    print("\nModifications:")
    for mod in obj['modifications'][:15]:
        print(f"  {mod['id']:4s}: type={mod['type']:2d}, value={repr(mod['value'])[:50]}")

# Check a few more items
print("\n\nSample of modification counts:")
for i in range(min(10, len(data['custom_objects']))):
    obj = data['custom_objects'][i]
    print(f"  {obj['new_id']}: {len(obj['modifications'])} modifications")
