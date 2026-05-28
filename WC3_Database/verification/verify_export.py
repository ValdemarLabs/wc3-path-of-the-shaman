"""Verify exported .w3t file can be parsed"""
from wc3_w3t_parser import WC3ObjectDataParser

# Parse our exported file
parser = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0310-2334.w3t')
data = parser.parse()

print(f"✓ Successfully parsed exported file!")
print(f"  Version: {data['version']}")
print(f"  Original objects: {len(data['original_objects'])}")
print(f"  Custom objects: {len(data['custom_objects'])}")

if data['custom_objects']:
    obj = data['custom_objects'][0]
    print(f"\n  First item: {obj['new_id']}")
    print(f"  Modifications: {len(obj['modifications'])}")
    for mod in obj['modifications'][:8]:
        print(f"    {mod['id']:4s}: {repr(mod['value'])[:40]}")
