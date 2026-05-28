#!/usr/bin/env python3
"""Detailed hex analysis of first two objects to understand complete structure."""

import struct

def read_string(f):
    """Read null-terminated string."""
    chars = []
    while True:
        c = f.read(1)
        if not c or c == b'\x00':
            break
        chars.append(c)
    return b''.join(chars).decode('ascii', errors='replace')

def analyze_file(filepath):
    """Analyze the .w3t file structure."""
    with open(filepath, 'rb') as f:
        # Read header
        version = struct.unpack('<I', f.read(4))[0]
        obj_count = struct.unpack('<I', f.read(4))[0]
        print(f"Version: {version}, Object Count: {obj_count}")
        print(f"\nFILE POSITION: 0x{f.tell():08X}\n")
        
        # Object 1
        print("=" * 80)
        print("OBJECT 1")
        print("=" * 80)
        
        obj_id = f.read(4).decode('ascii', errors='replace')
        print(f"Object ID: '{obj_id}' at 0x{f.tell()-4:08X}")
        
        # Read padding
        pad1 = struct.unpack('<I', f.read(4))[0]
        pad2 = struct.unpack('<I', f.read(4))[0]
        pad3 = struct.unpack('<I', f.read(4))[0]
        print(f"Padding 1: 0x{pad1:08X} ({pad1})")
        print(f"Padding 2: 0x{pad2:08X} ({pad2})")
        print(f"Padding 3: 0x{pad3:08X} ({pad3})")
        
        mod_count = struct.unpack('<I', f.read(4))[0]
        print(f"Modification Count: {mod_count}")
        print(f"File position after mod_count: 0x{f.tell():08X}\n")
        
        # Read modifications
        for i in range(mod_count):
            print(f"\n--- Modification {i+1}/{mod_count} ---")
            pos = f.tell()
            
            mod_id = f.read(4).decode('ascii', errors='replace')
            print(f"  Mod ID: '{mod_id}' at 0x{pos:08X}")
            
            mod_type = struct.unpack('<I', f.read(4))[0]
            print(f"  Type: {mod_type} (0=int, 1=real, 2=unreal, 3=string)")
            
            # Read more fields to understand structure
            level_var = struct.unpack('<I', f.read(4))[0]
            data_pointer = struct.unpack('<I', f.read(4))[0]
            print(f"  Level/Var: {level_var}")
            print(f"  Data Pointer: {data_pointer}")
            
            # Read value based on type
            if mod_type == 0:  # INT
                value = struct.unpack('<i', f.read(4))[0]
                print(f"  Value (int): {value}")
            elif mod_type == 1 or mod_type == 2:  # REAL/UNREAL
                value = struct.unpack('<f', f.read(4))[0]
                print(f"  Value (float): {value}")
            elif mod_type == 3:  # STRING
                value = read_string(f)
                print(f"  Value (string): '{value}'")
            
            # Check for end marker
            end_marker = f.read(4)
            print(f"  End marker: {end_marker.hex()}")
            
            print(f"  Position after mod: 0x{f.tell():08X}")
        
        print(f"\n{'=' * 80}")
        print(f"POSITION AFTER OBJECT 1: 0x{f.tell():08X}")
        print(f"{'=' * 80}\n")
        
        # Object 2
        print("OBJECT 2")
        print("=" * 80)
        
        obj_id2 = f.read(4)
        print(f"Object ID bytes: {obj_id2.hex()} = '{obj_id2.decode('ascii', errors='replace')}' at 0x{f.tell()-4:08X}")
        
        # Read next 32 bytes to see pattern
        print("\nNext 32 bytes:")
        next_bytes = f.read(32)
        for j in range(0, 32, 4):
            val = struct.unpack('<I', next_bytes[j:j+4])[0]
            ascii_rep = next_bytes[j:j+4].decode('ascii', errors='replace')
            print(f"  Bytes {j:2d}-{j+3:2d}: {next_bytes[j:j+4].hex()} = {val:10d} (0x{val:08X}) '{ascii_rep}'")

if __name__ == '__main__':
    filepath = r"H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t"
    analyze_file(filepath)
