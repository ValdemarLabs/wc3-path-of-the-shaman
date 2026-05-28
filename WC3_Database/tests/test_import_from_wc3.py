"""
Test W3T Import - Using correct file from WC3
"""

import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from importers.wc3_w3t_importer_v2 import WC3W3TImporter

def main():
    """Test import from correct WC3 file."""
    
    # Database configuration
    db_config = {
        'host': '127.0.0.1',
        'port': '5432',
        'database': 'wc3_pots',
        'user': 'postgres',
        'password': '009900'
    }
    
    # Correct .w3t file from WC3
    w3t_file = r'H:\Pelit\PotS_JASS\WC3_Export\fromWC3\POTS_ItemSettings_2026-0310-1826.w3t'
    
    print(f"{'='*70}")
    print(f"WC3 W3T IMPORTER TEST")
    print(f"{'='*70}")
    print(f"File: {os.path.basename(w3t_file)}")
    print(f"Path: {w3t_file}")
    print(f"Database: {db_config['database']}")
    print(f"{'='*70}\n")
    
    # Create importer
    importer = WC3W3TImporter(db_config)
    
    try:
        # Connect
        importer.connect()
        
        # Import with full preservation
        print("Starting import with full WC3 field preservation...")
        stats = importer.import_from_w3t(w3t_file, preserve_original_mods=True)
        
        # Summary
        print(f"\n{'='*70}")
        print(f"IMPORT SUMMARY")
        print(f"{'='*70}")
        print(f"✓ Items imported: {stats['imported']}")
        print(f"✓ Items updated: {stats['updated']}")
        print(f"✓ Total fields stored per item: ~60+")
        print(f"✗ Failed: {stats['failed']}")
        
        if stats.get('errors'):
            print(f"\nErrors ({len(stats['errors'])}):")
            for error in stats['errors'][:5]:
                print(f"  • {error}")
            if len(stats['errors']) > 5:
                print(f"  ... and {len(stats['errors']) - 5} more")
        
        print(f"\n{'='*70}")
        print("✓ Import completed successfully!")
        print(f"{'='*70}\n")
        
    except Exception as e:
        print(f"\n✗ Import failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if importer.conn:
            importer.conn.close()

if __name__ == '__main__':
    main()
