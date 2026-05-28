"""
WC3 .w3t Exporter CLI Tool
==========================
Command-line interface for exporting items from database to .w3t file.
Called from C# GUI or can be used standalone.

Usage:
    python export_w3t_cli.py <output_path> [--items I6CF,hval,...]
    
Examples:
    python export_w3t_cli.py exports/items.w3t
    python export_w3t_cli.py exports/items.w3t --items I6CF,hval,I001

Author: Generated for PotS Project
Date: 2026-03-12
"""

import sys
import os
import argparse
import configparser
from datetime import datetime

# Add core and parsers directories to path
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(script_dir, 'core'))
sys.path.insert(0, os.path.join(script_dir, 'parsers'))

from wc3_w3t_exporter import WC3W3TExporter


def load_database_config(config_path='config/database.ini'):
    """Load database configuration from INI file."""
    config_file = os.path.join(os.path.dirname(__file__), config_path)
    
    if not os.path.exists(config_file):
        raise FileNotFoundError(f"Database config not found: {config_file}")
    
    config = configparser.ConfigParser()
    config.read(config_file)
    
    if 'postgresql' not in config:
        raise ValueError("Database config missing [postgresql] section")
    
    return {
        'host': config['postgresql']['host'],
        'port': config['postgresql']['port'],
        'database': config['postgresql']['database'],
        'user': config['postgresql']['user'],
        'password': config['postgresql'].get('password', '')
    }


def find_original_w3t():
    """
    Find the most recent original .w3t file for preserving abilities.
    Looks in WC3_Export directory for reference files.
    """
    export_dir = os.path.join(os.path.dirname(__file__), '..', 'WC3_Export')
    
    if not os.path.exists(export_dir):
        return None
    
    # Look for .w3t files in subdirectories
    w3t_files = []
    for root, dirs, files in os.walk(export_dir):
        for file in files:
            if file.endswith('.w3t'):
                full_path = os.path.join(root, file)
                w3t_files.append((os.path.getmtime(full_path), full_path))
    
    if not w3t_files:
        return None
    
    # Return most recent file
    w3t_files.sort(reverse=True)
    return w3t_files[0][1]


def main():
    parser = argparse.ArgumentParser(
        description='Export items from database to WC3 .w3t file',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('output', 
                        help='Output .w3t file path')
    
    parser.add_argument('--items', 
                        help='Comma-separated item codes to export (exports all if omitted)',
                        default=None)
    
    parser.add_argument('--original-w3t',
                        help='Path to original .w3t file for preserving abilities',
                        default=None)
    
    parser.add_argument('--config',
                        help='Path to database config file',
                        default='config/database.ini')
    
    args = parser.parse_args()
    
    try:
        print("=" * 70)
        print("WC3 .W3T DATABASE EXPORTER")
        print("=" * 70)
        print()
        
        # Load database config
        print(f"Loading database config from: {args.config}")
        db_config = load_database_config(args.config)
        print(f"  Database: {db_config['database']}")
        print(f"  Host: {db_config['host']}:{db_config['port']}")
        print()
        
        # Find original .w3t if not specified
        original_w3t = args.original_w3t
        if not original_w3t:
            print("Searching for original .w3t file...")
            original_w3t = find_original_w3t()
            if original_w3t:
                print(f"  Found: {os.path.basename(original_w3t)}")
            else:
                print("  No original .w3t found - abilities will not be exported")
        print()
        
        # Parse item codes if provided
        item_codes = None
        if args.items:
            item_codes = [code.strip() for code in args.items.split(',')]
            print(f"Exporting {len(item_codes)} specific items: {', '.join(item_codes)}")
        else:
            print("Exporting all items from database")
        print()
        
        # Create exporter and export
        exporter = WC3W3TExporter(db_config, original_w3t_path=original_w3t)
        exporter.connect()
        
        exporter.export_to_w3t(args.output, item_codes=item_codes)
        
        exporter.disconnect()
        
        print()
        print("=" * 70)
        print("[OK] EXPORT COMPLETED SUCCESSFULLY!")
        print("=" * 70)
        print()
        print("To import into World Editor:")
        print("  1. Open World Editor")
        print("  2. Object Editor -> Items")
        print("  3. File -> Import Object Data")
        print(f"  4. Select: {os.path.abspath(args.output)}")
        print()
        
        return 0
        
    except Exception as e:
        print()
        print("=" * 70)
        print("[ERROR] EXPORT FAILED!")
        print("=" * 70)
        print(f"Error: {e}")
        print()
        
        import traceback
        traceback.print_exc()
        
        return 1


if __name__ == '__main__':
    sys.exit(main())
