#!/usr/bin/env python3
"""
PNG to BLP Batch Converter for Warcraft 3

Converts all PNG files in a directory to BLP format using BLPConverter.

Requirements:
    - Download BLPConverter.exe from: https://www.hiveworkshop.com/threads/blp-converter.249621/
    - Or use Warcraft 3 Viewer's BLPLab

Usage:
    python convert_png_to_blp.py --input war3mapImported --blp-converter "path/to/BLPConverter.exe"
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path


def find_blp_converter():
    """Try to find BLPConverter.exe in common locations"""
    common_paths = [
        "BLPConverter.exe",
        "tools/BLPConverter.exe",
        "C:/Program Files/BLPConverter/BLPConverter.exe",
        "C:/Program Files (x86)/BLPConverter/BLPConverter.exe",
    ]
    
    for path in common_paths:
        if os.path.exists(path):
            return path
    
    return None


def convert_png_to_blp_imagemagick(png_path, blp_path):
    """Convert using ImageMagick (if installed with BLP support)"""
    try:
        subprocess.run(['magick', 'convert', png_path, blp_path], check=True, capture_output=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def convert_png_to_blp_blpconverter(png_path, blp_path, blp_converter_path):
    """Convert using BLPConverter.exe"""
    try:
        # BLPConverter.exe <input.png> <output.blp> [options]
        subprocess.run([blp_converter_path, png_path, blp_path, '/NOGUI'], 
                      check=True, capture_output=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"Error with BLPConverter: {e}")
        return False


def batch_convert(input_dir, blp_converter_path=None, delete_png=False):
    """Convert all PNG files in directory to BLP"""
    
    if not os.path.exists(input_dir):
        print(f"ERROR: Directory not found: {input_dir}")
        return
    
    # Find all PNG files
    png_files = list(Path(input_dir).glob("*.png"))
    
    if not png_files:
        print(f"No PNG files found in: {input_dir}")
        return
    
    print(f"Found {len(png_files)} PNG files to convert")
    
    # Determine conversion method
    use_blpconverter = False
    if blp_converter_path and os.path.exists(blp_converter_path):
        use_blpconverter = True
        print(f"Using BLPConverter: {blp_converter_path}")
    else:
        blp_converter_path = find_blp_converter()
        if blp_converter_path:
            use_blpconverter = True
            print(f"Found BLPConverter: {blp_converter_path}")
        else:
            print("BLPConverter not found, trying ImageMagick...")
    
    converted = 0
    failed = 0
    
    for i, png_path in enumerate(png_files, 1):
        blp_path = png_path.with_suffix('.blp')
        
        success = False
        if use_blpconverter:
            success = convert_png_to_blp_blpconverter(str(png_path), str(blp_path), blp_converter_path)
        else:
            success = convert_png_to_blp_imagemagick(str(png_path), str(blp_path))
        
        if success:
            converted += 1
            if delete_png:
                os.remove(png_path)
            print(f"Converted {i}/{len(png_files)}: {png_path.name}", end='\r')
        else:
            failed += 1
            print(f"FAILED {i}/{len(png_files)}: {png_path.name}")
    
    print(f"\n\nConversion complete!")
    print(f"  Converted: {converted}")
    print(f"  Failed: {failed}")
    
    if failed > 0:
        print(f"\nManual conversion needed:")
        print(f"1. Download BLPConverter from: https://www.hiveworkshop.com/threads/blp-converter.249621/")
        print(f"2. Use BLPLab in Warcraft 3 Viewer")
        print(f"3. Or re-run with: --blp-converter 'path/to/BLPConverter.exe'")


def main():
    parser = argparse.ArgumentParser(description='Batch convert PNG files to BLP for Warcraft 3')
    parser.add_argument('--input', default='war3mapImported', help='Input directory with PNG files')
    parser.add_argument('--blp-converter', help='Path to BLPConverter.exe')
    parser.add_argument('--delete-png', action='store_true', help='Delete PNG files after conversion')
    
    args = parser.parse_args()
    
    batch_convert(args.input, args.blp_converter, args.delete_png)


if __name__ == '__main__':
    main()
