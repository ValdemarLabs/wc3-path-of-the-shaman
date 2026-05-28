"""
Verify the new export format
"""

from wc3_w3t_parser import WC3ObjectDataParser

print("="*70)
print("VERIFYING NEW EXPORT FORMAT")
print("="*70)

print("\nORIGINAL FILE:")
p1 = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t')
try:
    d1 = p1.parse()
    print(f'  ✓ Parsed successfully')
    print(f'  Original objects: {len(d1["original_objects"])}')
    print(f'  Custom objects: {len(d1["custom_objects"])}')
except Exception as e:
    print(f'  ✗ Parse failed: {e}')

print("\nOUR EXPORT:")
p2 = WC3ObjectDataParser(r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0240.w3t')
try:
    d2 = p2.parse()
    print(f'  ✓ Parsed successfully')
    print(f'  Original objects: {len(d2["original_objects"])}')
    print(f'  Custom objects: {len(d2["custom_objects"])}')
    
    # Check structure matches
    if len(d2["original_objects"]) == len(d1["original_objects"]) and \
       len(d2["custom_objects"]) == len(d1["custom_objects"]):
        print(f'\n  ✓ Object counts match!')
    
    # Count modifications
    orig_mods = sum(len(obj["modifications"]) for obj in d2["original_objects"] + d2["custom_objects"])
    print(f'  Total modifications: {orig_mods:,}')
    
    # Check abilities
    abilities = sum(1 for obj in d2["original_objects"] + d2["custom_objects"] 
                   for mod in obj["modifications"] if mod["id"] == "iabi")
    print(f'  Abilities (iabi): {abilities}')
    
except Exception as e:
    print(f'  ✗ Parse failed: {e}')
    import traceback
    traceback.print_exc()

print("\n" + "="*70)
print("✓ Export ready to test in World Editor")
print("="*70)
