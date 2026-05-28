"""
Check unknown format for custom objects in v3
"""

import struct

def check_custom_object_format(filepath):
    """Check the unknown field format for custom objects."""
    with open(filepath, 'rb') as f:
        # Version
        version =struct.unpack('<I', f.read(4))[0]
        
        # Skip original objects table
        orig_count = struct.unpack('<I', f.read(4))[0]
        for _ in range(orig_count):
            # Old ID, New ID
            f.read(8)
            
            # Read what we think is unknown1
            unknown_or_count = struct.unpack('<I', f.read(4))[0]
            
            # If this is a count, read that many unknowns
            for _ in range(unknown_or_count if unknown_or_count <= 10 else 0):
                f.read(4)
            
            # If we didn't read as count, still need to read unknown2
            if unknown_or_count > 10:
                f.read(4)
            
            # Modifications
            mod_count = struct.unpack('<I', f.read(4))[0]
            for _ in range(mod_count):
                field_id = f.read(4)
                field_type = struct.unpack('<I', f.read(4))[0]
                
                if field_type == 0:
                    f.read(4)
                elif field_type == 1 or field_type == 2:
                    f.read(4)
                elif field_type == 3:
                    while f.read(1) != b'\x00':
                        pass
                
                # End token
                f.read(4)
        
        # Custom objects
        custom_count = struct.unpack('<I', f.read(4))[0]
        print(f"Custom objects: {custom_count}")
        
        if custom_count > 0:
            print(f"\nFirst custom object:")
            # Old ID
            old_id = f.read(4)
            print(f"  Old ID (base): {old_id.decode('ascii', errors='ignore')}")
            
            # New ID
            new_id = f.read(4)
            print(f"  New ID: {new_id.decode('ascii', errors='ignore')}")
            
            # Check unknown values
            pos_before = f.tell()
            value1 = struct.unpack('<I', f.read(4))[0]
            value2 = struct.unpack('<I', f.read(4))[0]
            value3 = struct.unpack('<I', f.read(4))[0]
            
            f.seek(pos_before)
            
            print(f"  Next 3 values: {value1:#010x}, {value2:#010x}, {value3:#010x}")
            
            # Try both interpretations
            print(f"\n  INTERPRETATION 1 (Fixed unknowns):")
            print(f"    unknown1: {value1:#010x}")
            print(f"    unknown2: {value2:#010x}")
            print(f"    modCount: {value3}")
            
            print(f"\n  INTERPRETATION 2 (Count+Array):")
            if value1 <= 10:
                print(f"    unkCount: {value1}")
                if value1 == 0:
                    print(f"    unk array: []")
                    print(f"    modCount: {value2}")
                elif value1 == 1:
                    print(f"    unk[0]: {value2:#010x}")
                    print(f"    modCount: {value3}")
                elif value1 == 2:
                    print(f"    unk[0]: {value2:#010x}")
                    print(f"    unk[1]: {value3:#010x}")
                    value4 = struct.unpack('<I', f.read(4))[0]
                    print(f"    modCount: {value4}")
            else:
                print(f"    unkCount too large ({value1}), likely wrong interpretation")

print("="*70)
print("CHECKING CUSTOM OBJECTS FORMAT - ORIGINAL")
print("="*70)
original_path = r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t'
check_custom_object_format(original_path)

print("\n" + "="*70)
print("CHECKING CUSTOM OBJECTS FORMAT - OUR EXPORT")
print("="*70)
export_path = r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0159.w3t'
check_custom_object_format(export_path)
