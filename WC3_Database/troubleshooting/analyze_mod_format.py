#!/usr/bin/env python3
"""Analyze raw hex of first modification to understand string format."""

def analyze_hex():
    """Show hex bytes of first object."""
    filepath = r"H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t"
    
    with open(filepath, 'rb') as f:
        # Skip to object 1 mods (after header + object ID + padding + mod count)
        f.seek(0x1C)  # Start of first modification
        
        # Read 60 bytes and display
        data = f.read(60)
        
        print("HEX DUMP FROM 0x001C (First Modification):")
        print("=" * 80)
        for i in range(0, len(data), 16):
            hex_str = ' '.join(f'{b:02X}' for b in data[i:i+16])
            ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in data[i:i+16])
            print(f"0x{0x1C + i:04X}: {hex_str:<48} {ascii_str}")
        
        print("\n" + "=" * 80)
        print("INTERPRETATION:")
        print("=" * 80)
        
        # Parse first modification
        f.seek(0x1C)
        mod_id = f.read(4)
        print(f"\nMod ID (0x1C-0x1F): {mod_id.hex()} = '{mod_id.decode('ascii')}'")
        
        type_bytes = f.read(4)
        type_val = int.from_bytes(type_bytes, 'little')
        print(f"Type (0x20-0x23): {type_bytes.hex()} = {type_val} (3=string)")
        
        # Next 4 bytes
        next4 = f.read(4)
        next4_int = int.from_bytes(next4, 'little')
        next4_ascii = next4.decode('ascii', errors='replace')
        print(f"Next 4 bytes (0x24-0x27): {next4.hex()} = {next4_int} = '{next4_ascii}'")
        
        # Check if it's a string length or string content
        print(f"\nIs 0x24-0x27 a string length? {next4_int} bytes seems {'reasonable' if next4_int < 1000 else 'TOO LARGE'}")
        print(f"Is 0x24-0x27 string content? '{next4_ascii}' {'looks like text' if next4_ascii.isalpha() else 'does NOT look like text'}")
        
        # Look for null terminator
        f.seek(0x24)
        search_bytes = f.read(20)
        null_pos = search_bytes.find(b'\x00')
        if null_pos >= 0:
            string_content = search_bytes[:null_pos].decode('ascii', errors='replace')
            print(f"\nFound null terminator at offset +{null_pos}")
            print(f"String content: '{string_content}'")
            print(f"Total bytes for this mod: 4 (ID) + 4 (type) + {null_pos + 1} (string with null) = {8 + null_pos + 1}")
        
        # Second mod
        print(f"\n{'=' * 80}")
        print("SECOND MODIFICATION:")
        print("=" * 80)
        
        # Assume first mod is: mod_id(4) + type(4) + string with null
        # From the dump, let's try to find where second mod starts
        f.seek(0x1C)
        all_bytes = f.read(40)
        
        # Look for next 4-char ID that could be a valid WC3 field
        print("\nSearching for next modification ID...")
        for offset in range(8, 30):
            potential_id = all_bytes[offset:offset+4]
            try:
                id_str = potential_id.decode('ascii')
                if id_str.isalpha() or id_str.isalnum():
                    print(f"  Offset {offset:2d} (0x{0x1C + offset:04X}): '{id_str}' {potential_id.hex()}")
            except:
                pass

if __name__ == '__main__':
    analyze_hex()
