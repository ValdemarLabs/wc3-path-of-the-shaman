"""Detailed comparison of file structures"""
from wc3_w3t_parser import WC3ObjectDataParser

# Parse both files
parser1 = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
data1 = parser1.parse()

parser2 = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0310-2346.w3t')
data2 = parser2.parse()

print("FILE STRUCTURE COMPARISON")
print("="*60)
print(f"{'':20s} {'ORIGINAL':>15s} {'EXPORTED':>15s} {'DIFFERENCE':>15s}")
print("="*60)

# File sizes
import os
size1 = os.path.getsize(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
size2 = os.path.getsize(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0310-2346.w3t')
print(f"{'File Size (bytes)':20s} {size1:>15,} {size2:>15,} {size2-size1:>15,}")

print(f"{'Original Objects':20s} {len(data1['original_objects']):>15} {len(data2['original_objects']):>15} {len(data2['original_objects'])-len(data1['original_objects']):>15}")
print(f"{'Custom Objects':20s} {len(data1['custom_objects']):>15} {len(data2['custom_objects']):>15} {len(data2['custom_objects'])-len(data1['custom_objects']):>15}")
print(f"{'Total Objects':20s} {len(data1['original_objects'])+len(data1['custom_objects']):>15} {len(data2['original_objects'])+len(data2['custom_objects']):>15}")

# Modification counts
orig_mods1 = sum(len(obj['modifications']) for obj in data1['original_objects'] + data1['custom_objects'])
orig_mods2 = sum(len(obj['modifications']) for obj in data2['original_objects'] + data2['custom_objects'])
print(f"{'Total Modifications':20s} {orig_mods1:>15,} {orig_mods2:>15,} {orig_mods2-orig_mods1:>15,}")

avg1 = orig_mods1 / 608
avg2 = orig_mods2 / 608
print(f"{'Avg Mods/Item':20s} {avg1:>15.1f} {avg2:>15.1f} {avg2-avg1:>15.1f}")

print("\n" + "="*60)
print("MODIFICATION FIELD ANALYSIS")
print("="*60)

# Get all field IDs used
fields1 = {}
fields2 = {}

for obj in data1['original_objects'] + data1['custom_objects']:
    for mod in obj['modifications']:
        fields1[mod['id']] = fields1.get(mod['id'], 0) + 1

for obj in data2['original_objects'] + data2['custom_objects']:
    for mod in obj['modifications']:
        fields2[mod['id']] = fields2.get(mod['id'], 0) + 1

print(f"\nFields in ORIGINAL but NOT in EXPORTED:")
for field in sorted(fields1.keys()):
    if field not in fields2:
        print(f"  {field}: {fields1[field]} times")

print(f"\nFields in EXPORTED but NOT in ORIGINAL:")
for field in sorted(fields2.keys()):
    if field not in fields1:
        print(f"  {field}: {fields2[field]} times")

print(f"\nField usage comparison (top 20):")
all_fields = set(fields1.keys()) | set(fields2.keys())
field_diff = []
for field in all_fields:
    count1 = fields1.get(field, 0)
    count2 = fields2.get(field, 0)
    if count1 != count2:
        field_diff.append((field, count1, count2, count2 - count1))

field_diff.sort(key=lambda x: abs(x[3]), reverse=True)
for field, count1, count2, diff in field_diff[:20]:
    print(f"  {field:4s}: {count1:>4} -> {count2:>4} ({diff:>+5})")
