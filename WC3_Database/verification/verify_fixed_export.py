"""
Verify Fixed Export - Check Field Count Reduction
"""

from wc3_w3t_parser import WC3ObjectDataParser
from collections import Counter

# Parse original and new export
original = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
original_data = original.parse()

new_export = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0115.w3t')
new_export_data = new_export.parse()

# Count modifications
def count_modifications(data):
    total = 0
    field_counts = Counter()
    for obj in data['original_objects'] + data['custom_objects']:
        total += len(obj['modifications'])
        for mod in obj['modifications']:
            field_counts[mod['id']] += 1
    return total, field_counts

orig_total, orig_fields = count_modifications(original_data)
new_total, new_fields = count_modifications(new_export_data)

print(f"\n{'='*60}")
print("FIXED EXPORT VERIFICATION")
print(f"{'='*60}")
print(f"\nTotal Modifications:")
print(f"  Original: {orig_total:,}")
print(f"  Old export: 13,717 (TOO MANY)")
print(f"  New export: {new_total:,}")
print(f"  Reduction: {13717 - new_total:,} fewer modifications")

print(f"\nAverage Modifications per Item:")
print(f"  Original: {orig_total / 608:.1f}")
print(f"  Old export: 22.6 (TOO HIGH)")
print(f"  New export: {new_total / 608:.1f}")

print(f"\nField Usage Comparison:")
print(f"{'Field':<6} {'Original':<10} {'New Export':<12} {'Difference':<10}")
print(f"{'-'*50}")

# Show most used fields
all_fields = set(orig_fields.keys()) | set(new_fields.keys())
top_fields = sorted(all_fields, key=lambda f: abs(orig_fields.get(f, 0) - new_fields.get(f, 0)), reverse=True)[:20]

for field in top_fields:
    orig_count = orig_fields.get(field, 0)
    new_count = new_fields.get(field, 0)
    diff = new_count - orig_count
    sign = '+' if diff > 0 else ''
    print(f"{field:<6} {orig_count:<10} {new_count:<12} {sign}{diff:<10}")

# Check critical fields
print(f"\n{'='*60}")
print("Critical Field Preservation:")
print(f"{'='*60}")
critical = ['iabi', 'unam', 'ides', 'igol', 'ilev', 'iico']
for field in critical:
    orig_count = orig_fields.get(field, 0)
    new_count = new_fields.get(field, 0)
    status = '✓' if new_count == orig_count else '✗'
    print(f"{status} {field}: {orig_count} → {new_count}")

print(f"\n{'='*60}")
print("RESULT:")
if new_total < 6000:  # Should be around 5,173 like original
    print("✓ Export looks good - field count similar to original")
    print("✓ Ready to test in World Editor")
else:
    print("⚠ Still exporting more fields than expected")
print(f"{'='*60}\n")
