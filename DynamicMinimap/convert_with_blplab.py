#!/usr/bin/env python3
"""
Batch convert PNG to BLP using BLPLab
"""

import os
import subprocess
from pathlib import Path

BLPLAB_PATH = r"H:\Pelit\WC3_Tools\BLP Laboratory\blplab.exe"
INPUT_DIR = "war3mapImported"

def convert_with_blplab(png_path, blp_path):
    """Convert PNG to BLP using BLPLab command line"""
    try:
        # BLPLab command: blplab.exe -i input.png -o output.blp
        result = subprocess.run(
            [BLPLAB_PATH, '-i', str(png_path), '-o', str(blp_path)],
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.returncode == 0
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    if not os.path.exists(INPUT_DIR):
        print(f"ERROR: Directory not found: {INPUT_DIR}")
        return
    
    png_files = list(Path(INPUT_DIR).glob("minimap_*.png"))
    
    if not png_files:
        print(f"No minimap PNG files found in: {INPUT_DIR}")
        return
    
    print(f"Found {len(png_files)} PNG files to convert")
    print(f"Using BLPLab: {BLPLAB_PATH}\n")
    
    converted = 0
    failed = 0
    
    for i, png_path in enumerate(png_files, 1):
        blp_path = png_path.with_suffix('.blp')
        
        if convert_with_blplab(png_path, blp_path):
            converted += 1
            print(f"[{i}/{len(png_files)}] ✓ {png_path.name}", end='\r')
        else:
            failed += 1
            print(f"[{i}/{len(png_files)}] ✗ {png_path.name}")
    
    print(f"\n\nConversion complete!")
    print(f"  ✓ Converted: {converted}")
    print(f"  ✗ Failed: {failed}")
    print(f"\nBLP files saved in: {INPUT_DIR}")

if __name__ == '__main__':
    main()
