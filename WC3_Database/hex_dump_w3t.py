#!/usr/bin/env python3
"""Hex dump .w3t file to inspect binary content."""

import sys
import os

w3t_path = r'H:\Pelit\PotS_JASS\WC3_Export\toWC3\TEST_tooltip_export.w3t'

if not os.path.exists(w3t_path):
    print(f"[ERROR] File not found: {w3t_path}")
    sys.exit(1)

print(f"Hex dump of: {w3t_path}")
print(f"File size: {os.path.getsize(w3t_path)} bytes")
print("="*80)

with open(w3t_path, 'rb') as f:
    data = f.read()

# Search for 'utub' field code
utub_positions = []
for i in range(len(data) - 3):
    if data[i:i+4] == b'utub':
        utub_positions.append(i)

print(f"\nFound {len(utub_positions)} occurrences of 'utub' field code")
print()

for pos in utub_positions:
    print(f"'utub' at offset {pos} (0x{pos:04X})")
    
    # Show context: 20 bytes before and 200 bytes after
    start = max(0, pos - 20)
    end = min(len(data), pos + 200)
    
    print(f"Context (offset {start} to {end}):")
    
    # Hex dump
    for i in range(start, end, 16):
        hex_str = ' '.join(f'{b:02x}' for b in data[i:min(i+16, end)])
        ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in data[i:min(i+16, end)])
        print(f"  {i:04X}: {hex_str:<48} | {ascii_str}")
    
    # Try to parse the string value after utub + type (8 bytes after 'utub')
    string_start = pos + 8  # 4 bytes for 'utub', 4 bytes for type
    if string_start < len(data):
        # Find null terminator
        string_end = data.find(b'\x00', string_start)
        if string_end != -1:
            string_value = data[string_start:string_end]
            try:
                decoded = string_value.decode('utf-8', errors='ignore')
                print(f"\n  String value ({len(string_value)} bytes): {decoded[:100]}")
                if len(decoded) > 100:
                    print(f"  ... (truncated, total {len(decoded)} chars)")
            except:
                print(f"\n  String value (binary, {len(string_value)} bytes)")
    
    print()
    print("-"*80)
    print()
