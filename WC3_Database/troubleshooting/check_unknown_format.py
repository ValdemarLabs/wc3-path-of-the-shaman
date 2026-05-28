"""
Check if original w3t uses count+array format for unknown fields in v3
"""

import struct

def check_unknown_format(filepath):
    """Check the unknown field format."""
    with open(filepath, 'rb') as f:
        # Version
        version = struct.unpack('<I', f.read(4))[0]
        print(f"Version: {version}")
        
        # Original objects
        orig_count = struct.unpack('<I', f.read(4))[0]
        print(f"Original objects: {orig_count}")
        
        if orig_count > 0:
            print(f"\nFirst original object:")
            # Old ID
            old_id = f.read(4)
            print(f"  Old ID: {old_id.decode('ascii', errors='ignore')}")
            
            # New ID
            new_id = f.read(4)
            print(f"  New ID: {new_id.decode('ascii', errors='ignore')}")
            
            # Check if next is a count or direct unknown values
            pos_before = f.tell()
            value1 = struct.unpack('<I', f.read(4))[0]
            value2 = struct.unpack('<I', f.read(4))[0]
            value3 = struct.unpack('<I', f.read(4))[0]
            
            f.seek(pos_before)
            
            print(f"  Next 3 values: {value1:#010x}, {value2:#010x}, {value3:#010x}")
            
            # If value1 is small (0-10) and value2 matches pattern, it's likely count+array
            # If value1 is 0 or 1 and value3 is reasonable mod count, it's likely fixed unknowns
            
            if value1 <= 10 and value2 != 0:
                print(f"  → Likely FORMAT: unkCount={value1}, then array of {value1} values")
                print(f"  → Reading as count+array:")
                unk_count = struct.unpack('<I', f.read(4))[0]
                print(f"    unkCount: {unk_count}")
                for i in range(unk_count):
                    unk_val = struct.unpack('<I', f.read(4))[0]
                    print(f"    unk[{i}]: {unk_val:#010x}")
            else:
                print(f"  → Likely FORMAT: fixed unknown1, unknown2")
                print(f"  → Reading as fixed unknowns:")
                unknown1 = struct.unpack('<I', f.read(4))[0]
                unknown2 = struct.unpack('<I', f.read(4))[0]
                print(f"    unknown1: {unknown1:#010x}")
                print(f"    unknown2: {unknown2:#010x}")
            
            # Mod count
            mod_count = struct.unpack('<I', f.read(4))[0]
            print(f"  Modifications: {mod_count}")

print("="*70)
print("CHECKING UNKNOWN FIELD FORMAT")
print("="*70)

original_path = r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t'
check_unknown_format(original_path)

print("\n" + "="*70)
print("CHECKING OUR EXPORT")
print("="*70)
export_path = r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0159.w3t'
check_unknown_format(export_path)
