"""
Binary Format Comparison - Deep dive into .w3t structure
Compare our export with the working original file at byte level
"""

import struct
from wc3_w3t_parser import WC3ObjectDataParser

def read_bytes_at(filepath, offset, count):
    """Read raw bytes at specific offset."""
    with open(filepath, 'rb') as f:
        f.seek(offset)
        return f.read(count)

def analyze_object_structure(filepath, max_objects=5):
    """Analyze the binary structure of objects in detail."""
    with open(filepath, 'rb') as f:
        # Version
        version = struct.unpack('<I', f.read(4))[0]
        print(f"Version: {version}")
        
        # Original objects table
        orig_count = struct.unpack('<I', f.read(4))[0]
        print(f"\nOriginal objects: {orig_count}")
        
        for i in range(min(orig_count, max_objects)):
            print(f"\n  Object {i+1}:")
            pos = f.tell()
            print(f"    Offset: {pos}")
            
            # Old ID
            old_id = f.read(4)
            print(f"    Old ID: {old_id} ({old_id.decode('ascii', errors='ignore')})")
            
            # New ID
            new_id = f.read(4)
            print(f"    New ID: {new_id} ({new_id.decode('ascii', errors='ignore')})")
            
            # Unknown fields (Reforged v3)
            if version >= 3:
                unknown1 = struct.unpack('<I', f.read(4))[0]
                unknown2 = struct.unpack('<I', f.read(4))[0]
                print(f"    Unknown1: {unknown1:#010x}")
                print(f"    Unknown2: {unknown2:#010x}")
            
            # Modification count
            mod_count = struct.unpack('<I', f.read(4))[0]
            print(f"    Modifications: {mod_count}")
            
            # Read modifications
            for j in range(min(mod_count, 3)):
                field_id = f.read(4)
                field_type = struct.unpack('<I', f.read(4))[0]
                
                if field_type == 0:  # INT
                    value = struct.unpack('<i', f.read(4))[0]
                    print(f"      Mod {j+1}: {field_id.decode('ascii', errors='ignore')} (int) = {value}")
                elif field_type == 1 or field_type == 2:  # FLOAT
                    value = struct.unpack('<f', f.read(4))[0]
                    print(f"      Mod {j+1}: {field_id.decode('ascii', errors='ignore')} (float) = {value:.4f}")
                elif field_type == 3:  # STRING
                    # Read until null terminator
                    chars = []
                    while True:
                        c = f.read(1)
                        if c == b'\x00' or not c:
                            break
                        chars.append(c)
                    value = b''.join(chars).decode('utf-8', errors='ignore')
                    print(f"      Mod {j+1}: {field_id.decode('ascii', errors='ignore')} (string) = '{value[:50]}'")
                
                # End token (v1+)
                if version > 0:
                    end_token = f.read(4)
                    print(f"        End token: {end_token.hex()}")
            
            # Skip remaining modifications
            if mod_count > 3:
                print(f"      ... ({mod_count - 3} more modifications)")
                for j in range(3, mod_count):
                    field_id = f.read(4)
                    field_type = struct.unpack('<I', f.read(4))[0]
                    
                    if field_type == 0:
                        f.read(4)
                    elif field_type == 1 or field_type == 2:
                        f.read(4)
                    elif field_type == 3:
                        while f.read(1) != b'\x00':
                            pass
                    
                    if version > 0:
                        f.read(4)

print("="*70)
print("ORIGINAL FILE (Working)")
print("="*70)
original_path = r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t'
analyze_object_structure(original_path)

print("\n" + "="*70)
print("OUR EXPORT (Fixed Format)")
print("="*70)
export_path = r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\POTS_ItemSettings_2026-0311-0159.w3t'
analyze_object_structure(export_path)
