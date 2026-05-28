"""
Detailed .w3t hex analyzer to determine Reforged format structure
"""
import struct

file_path = r"H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t"

with open(file_path, 'rb') as f:
    # Read version & count
    version = struct.unpack('<I', f.read(4))[0]
    obj_count = struct.unpack('<I', f.read(4))[0]
    
    print(f"Version: {version}")
    print(f"Object count: {obj_count}")
    print(f"\nPosition: 0x{f.tell():04x}")
    
    # Try to parse first few objects manually
    for obj_num in range(min(3, obj_count)):
        start_pos = f.tell()
        print(f"\n{'='*60}")
        print(f"OBJECT #{obj_num + 1} starting at position 0x{start_pos:04x}")
        print(f"{'='*60}")
        
        # Show next 64 bytes in hex
        pos = f.tell()
        next_bytes = f.read(64)
        f.seek(pos)
        
        print("\nNext 64 bytes hex:")
        for i in range(0, len(next_bytes), 16):
            hex_str = " ".join(f"{b:02x}" for b in next_bytes[i:i+16])
            ascii_str = "".join(chr(b) if 32 <= b < 127 else '.' for b in next_bytes[i:i+16])
            print(f"  {i:04x}: {hex_str:48s} {ascii_str}")
        
        # Try to identify the pattern
        # Assumption 1: First 4 bytes after count is object ID
        test_id = f.read(4)
        print(f"\nBytes 0-3: {test_id.hex()} = '{test_id.decode('ascii', errors='replace').rstrip(chr(0))}'")
        
        # Try different parsing strategies
        print("\nTrying different parsing strategies:")
        
        # Strategy A: Next 4 bytes is mod count directly
        test_val_a = struct.unpack('<I', f.read(4))[0]
        print(f"  A) Bytes 4-7 as mod_count: {test_val_a}")
        
        # Strategy B: Skip 4 bytes, then read mod count
        f.seek(start_pos + 4)
        f.read(4)  # skip
        test_val_b = struct.unpack('<I', f.read(4))[0]
        print(f"  B) Bytes 8-11 as mod_count (skip 4-7): {test_val_b}")
        
        # Strategy C: Skip 8 bytes, then read mod count
        f.seek(start_pos + 4)
        f.read(8)  # skip
        test_val_c = struct.unpack('<I', f.read(4))[0]
        print(f"  C) Bytes 12-15 as mod_count (skip 4-11): {test_val_c}")
        
        # Strategy D: Skip 12 bytes, then read mod count
        f.seek(start_pos + 4)
        f.read(12)  # skip
        test_val_d = struct.unpack('<I', f.read(4))[0]
        print(f"  D) Bytes 16-19 as mod_count (skip 4-15): {test_val_d}")
        
        # Look for likely modification count (should be small, like 1-50)
        likely_strategies = []
        if 0 <= test_val_a < 100:
            likely_strategies.append(('A', test_val_a, start_pos + 8))
        if 0 <= test_val_b < 100:
            likely_strategies.append(('B', test_val_b, start_pos + 12))
        if 0 <= test_val_c < 100:
            likely_strategies.append(('C', test_val_c, start_pos + 16))
        if 0 <= test_val_d < 100:
            likely_strategies.append(('D', test_val_d, start_pos + 20))
        
        print(f"\nLikely strategies (mod_count < 100): {likely_strategies}")
        
        if likely_strategies:
            # Use first likely strategy
            strategy, mod_count, next_pos = likely_strategies[0]
            print(f"\nUsing strategy {strategy}: mod_count = {mod_count}")
            print(f"Modifications should start at position 0x{next_pos:04x}")
            
            # Skip to end of this object (estimate)
            # Each modification is roughly: 4 (id) + 4 (type) + 4 (level) + 4 (data_ptr) + value + 4 (end) = ~24+ bytes
            f.seek(next_pos)
            if mod_count > 0:
                print(f"\nFirst modification:")
                mod_id = f.read(4)
                print(f"  ID: {mod_id.hex()} = '{mod_id.decode('ascii', errors='replace').rstrip(chr(0))}'")
        
        # For now, skip ahead arbitrarily to avoid getting stuck
        f.seek(start_pos + 200)  # Just skip ahead
        if f.tell() >= len(next_bytes) + start_pos:
            break

    print(f"\n\nEnd of analysis")
