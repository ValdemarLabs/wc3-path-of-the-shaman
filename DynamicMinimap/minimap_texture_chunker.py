#!/usr/bin/env python3
"""
Warcraft 3 Minimap Texture Chunker

Splits a full minimap texture (war3mapMap.blp) into smaller chunks for
dynamic minimap texture swapping in RPG maps.

Requirements:
    pip install Pillow
    
Optional (for direct BLP support):
    pip install blp-converter

Usage:
    python minimap_texture_chunker.py war3mapMap.blp --map-size 256 --chunk-size 32 --output-dir war3mapImported
"""

import os
import sys
from pathlib import Path
from PIL import Image
import argparse


def convert_blp_to_png(blp_path):
    """
    Convert BLP to PNG using external tool or library.
    If blp-converter is installed, use it. Otherwise, ask user to convert manually.
    """
    png_path = blp_path.replace('.blp', '.png')
    
    # Try using blp-converter library
    try:
        from blp_converter import blp_to_png
        blp_to_png(blp_path, png_path)
        print(f"Converted {blp_path} to {png_path}")
        return png_path
    except ImportError:
        pass
    
    # Check if PNG already exists
    if os.path.exists(png_path):
        print(f"Using existing PNG: {png_path}")
        return png_path
    
    print(f"\nERROR: Could not convert BLP to PNG automatically.")
    print(f"Please convert {blp_path} to {png_path} manually using:")
    print(f"  - Warcraft 3 Image Extractor II")
    print(f"  - BLPLab")
    print(f"  - Or install: pip install blp-converter")
    sys.exit(1)


def chunk_minimap(input_path, map_size_tiles, chunk_size_tiles, output_dir, grid_step=8):
    """
    Split full minimap into chunks.
    
    Args:
        input_path: Path to minimap image (PNG or BLP)
        map_size_tiles: Total map size in tiles (e.g., 256 for 256x256 tile map)
        chunk_size_tiles: Size of each chunk in tiles (e.g., 32 for 32x32 visible area)
        output_dir: Directory to save chunked images
        grid_step: How many tiles between each chunk position (for optimization)
    """
    # Convert BLP to PNG if needed
    if input_path.lower().endswith('.blp'):
        input_path = convert_blp_to_png(input_path)
    
    # Load the full minimap
    print(f"Loading minimap from: {input_path}")
    minimap = Image.open(input_path)
    width, height = minimap.size
    print(f"Minimap size: {width}x{height} pixels")
    
    # Calculate pixels per tile
    pixels_per_tile_x = width / map_size_tiles
    pixels_per_tile_y = height / map_size_tiles
    
    # Calculate chunk size in pixels
    chunk_width_px = int(chunk_size_tiles * pixels_per_tile_x)
    chunk_height_px = int(chunk_size_tiles * pixels_per_tile_y)
    
    print(f"\nChunk configuration:")
    print(f"  Map size: {map_size_tiles}x{map_size_tiles} tiles")
    print(f"  Chunk size: {chunk_size_tiles}x{chunk_size_tiles} tiles")
    print(f"  Chunk pixels (original): {chunk_width_px}x{chunk_height_px}")
    print(f"  Output resolution: 256x256 (WC3 minimap requirement)")
    print(f"  Grid step: every {grid_step} tiles")
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    chunk_count = 0
    
    # Generate chunks on a grid
    print(f"\nGenerating chunks...")
    for tile_x in range(0, map_size_tiles - chunk_size_tiles + 1, grid_step):
        for tile_y in range(0, map_size_tiles - chunk_size_tiles + 1, grid_step):
            # Calculate pixel coordinates for this chunk
            # Note: WC3 uses Y=0 at bottom, but images use Y=0 at top
            # So we need to flip the Y coordinate
            px_x = int(tile_x * pixels_per_tile_x)
            px_y_flipped = int((map_size_tiles - tile_y - chunk_size_tiles) * pixels_per_tile_y)
            
            # Ensure we don't go out of bounds
            if px_x + chunk_width_px > width:
                px_x = width - chunk_width_px
            if px_y_flipped < 0:
                px_y_flipped = 0
            if px_y_flipped + chunk_height_px > height:
                px_y_flipped = height - chunk_height_px
            
            # Crop the chunk
            chunk = minimap.crop((px_x, px_y_flipped, px_x + chunk_width_px, px_y_flipped + chunk_height_px))
            
            # Resize to 256x256 (required by WC3 minimap system)
            chunk = chunk.resize((256, 256), Image.LANCZOS)
            
            # Save as PNG (you'll need to convert to BLP later)
            output_filename = f"minimap_{tile_x}_{tile_y}_{chunk_size_tiles}.png"
            output_path = os.path.join(output_dir, output_filename)
            chunk.save(output_path)
            
            chunk_count += 1
            if chunk_count % 10 == 0:
                print(f"  Generated {chunk_count} chunks...", end='\r')
    
    print(f"\n\nGenerated {chunk_count} chunks in: {output_dir}")
    print(f"Each chunk is 256x256 pixels (WC3 minimap requirement)")
    print(f"\nNext steps:")
    print(f"1. Convert PNG files to BLP using BLPLab or Warcraft 3 Image Extractor")
    print(f"2. Import BLP files into your map in war3mapImported folder")
    print(f"3. Use the naming convention: minimap_X_Y_32.blp")


def main():
    parser = argparse.ArgumentParser(description='Chunk Warcraft 3 minimap texture for RPG scrolling')
    parser.add_argument('input', help='Input minimap file (war3mapMap.blp or .png)')
    parser.add_argument('--map-size', type=int, default=256, help='Map size in tiles (default: 256)')
    parser.add_argument('--chunk-size', type=int, default=32, help='Chunk size in tiles (default: 32)')
    parser.add_argument('--output-dir', default='war3mapImported', help='Output directory (default: war3mapImported)')
    parser.add_argument('--grid-step', type=int, default=8, help='Tiles between chunks (default: 8)')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"ERROR: Input file not found: {args.input}")
        sys.exit(1)
    
    chunk_minimap(
        args.input,
        args.map_size,
        args.chunk_size,
        args.output_dir,
        args.grid_step
    )


if __name__ == '__main__':
    main()
