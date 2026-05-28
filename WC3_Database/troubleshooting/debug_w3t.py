"""
Debug script to analyze .w3t file structure
"""
import struct

file_path = r"H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t"

with open(file_path, 'rb') as f:
    # Read first 200 bytes to see structure
    data = f.read(300)
    
    print("First 300 bytes (hex):")
    for i in range(0, len(data), 16):
        hex_str = " ".join(f"{b:02x}" for b in data[i:i+16])
        ascii_str = "".join(chr(b) if 32 <= b < 127 else '.' for b in data[i:i+16])
        print(f"{i:04x}: {hex_str:48s} {ascii_str}")
    print()
    
    # Try to read as version + counts
    f.seek(0)
    try:
        version = struct.unpack('<I', f.read(4))[0]
        print(f"\nVersion: {version} (0x{version:08x})")
        
        original_count = struct.unpack('<I', f.read(4))[0]
        print(f"Original objects count: {original_count}")
        
        # Try to read first few objects
        for obj_num in range(min(5, original_count)):
            print(f"\n--- Object {obj_num + 1} ---")
            orig_id = f.read(4)
            print(f"  Original ID: {orig_id.hex()} ({orig_id.decode('ascii', errors='ignore').rstrip(chr(0))})")
            
            mod_count = struct.unpack('<I', f.read(4))[0]
            print(f"  Modification count: {mod_count}")
            print(f"  File position after mod_count: 0x{f.tell():04x}")
            
            if mod_count ==  0:
                print(f"  -> No modifications, should skip to next object")
                # Show next 32 bytes
                pos = f.tell()
                next_data = f.read(32)
                f.seek(pos)
                print(f"  Next 32 bytes: {next_data.hex()}")
                print(f"  Next 32 bytes (chars): {next_data.decode('ascii', errors='replace')}")
                break  # Stop after first object for analysis
                
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
        
    print(f"\n\nFile size: {f.seek(0, 2)} bytes")
