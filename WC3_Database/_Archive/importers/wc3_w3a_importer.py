"""
WC3 .w3a Ability Importer v2.0.0 - SIMPLIFIED
==============================================
Imports essential ability data from Warcraft 3 .w3a files into PostgreSQL database.

SIMPLIFIED VERSION:
- Stores essential lookup fields: ability_code, ability_name (anam), editor_suffix (ansf),
  tooltip_normal (atp1), tooltip_extended (aub1)
- For item reference purposes only

Author: Generated for PotS Project
Date: 2026-03-15
Version: 2.1.0 - Simplified for item reference with tooltip lookup
"""

import os
import sys
import psycopg2
from datetime import datetime
from typing import Dict, List
import argparse

# Force UTF-8 encoding for stdout/stderr to support Unicode characters
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8')

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
try:
    from parsers.wc3_w3a_parser import WC3AbilityDataParser
except ImportError:
    print("Error: Could not import WC3AbilityDataParser")
    sys.exit(1)


class WC3AbilityImporter:
    """Imports WC3 abilities from .w3a files into PostgreSQL database (simplified version)."""
    
    def __init__(self, db_config: Dict[str, str]):
        """
        Initialize importer with database configuration.
        
        Args:
            db_config: Dictionary with keys: host, port, database, user, password
        """
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.stats = {
            'imported': 0,
            'updated': 0,
            'skipped': 0,
            'failed': 0,
            'errors': []
        }
        
    def connect(self):
        """Connect to PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(
                host=self.db_config['host'],
                port=self.db_config['port'],
                database=self.db_config['database'],
                user=self.db_config['user'],
                password=self.db_config['password']
            )
            self.cursor = self.conn.cursor()
            self._ensure_lookup_schema()
            print(f"✓ Connected to database: {self.db_config['database']}")
        except Exception as e:
            print(f"✗ Failed to connect to database: {e}")
            raise
            
    def disconnect(self):
        """Close database connection."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("✓ Database connection closed")
        
    def import_from_w3a(self, file_path: str) -> Dict:
        """
        Import abilities from WC3 .w3a file (only essential lookup fields).
        
        Args:
            file_path: Path to .w3a file
            
        Returns:
            Dictionary with import statistics
        """
        print(f"\n=== Importing Abilities from W3A: {os.path.basename(file_path)} ===")
        print("Mode: SIMPLIFIED (ability_code, name, editor_suffix, tooltip_normal, tooltip_extended)\n")
        
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        # Parse the .w3a file
        parser = WC3AbilityDataParser(file_path)
        data = parser.parse()
        
        print(f"Parsed {len(data['original_objects'])} modified base abilities and {len(data['custom_objects'])} custom abilities")
        
        # Combine all abilities
        all_abilities = data['original_objects'] + data['custom_objects']
        
        print(f"Processing {len(all_abilities)} abilities...\n")
        
        for i, ability in enumerate(all_abilities, 1):
            try:
                self._insert_or_update_ability(ability)
                
                if i % 100 == 0:
                    print(f"  Processed {i}/{len(all_abilities)} abilities...")
                    
            except Exception as e:
                self.stats['failed'] += 1
                ability_code = ability.get('new_id', 'UNKNOWN')
                error_msg = f"Failed to import {ability_code}: {str(e)}"
                self.stats['errors'].append(error_msg)
                print(f"✗ {error_msg}")
                
        self.conn.commit()
        
        # Print summary
        print(f"\n=== Import Summary ===")
        print(f"✓ Imported: {self.stats['imported']}")
        print(f"↻ Updated: {self.stats['updated']}")
        print(f"⊘ Skipped: {self.stats['skipped']}")
        print(f"✗ Failed: {self.stats['failed']}")
        
        if self.stats['errors']:
            print(f"\nErrors:")
            for error in self.stats['errors'][:10]:
                print(f"  {error}")
            if len(self.stats['errors']) > 10:
                print(f"  ... and {len(self.stats['errors']) - 10} more errors")
        
        return self.stats

    def _ensure_lookup_schema(self) -> None:
        """Make sure simplified tooltip lookup columns exist before import."""
        self.cursor.execute("""
            ALTER TABLE wc3_abilities
            ADD COLUMN IF NOT EXISTS tooltip_normal TEXT,
            ADD COLUMN IF NOT EXISTS tooltip_extended TEXT
        """)
        self.conn.commit()
        
    def _insert_or_update_ability(self, ability: Dict) -> None:
        """
        Insert or update an ability in the database (essential lookup fields only).
        
        Args:
            ability: Ability dictionary from parser
        """
        ability_code = ability.get('new_id')
        
        if not ability_code:
            raise ValueError("Ability code (new_id) is required")
            
        # Extract only the fields we need
        ability_name = None
        editor_suffix = None
        tooltip_normal = None
        tooltip_extended = None
        
        # Look through modifications for the essential tooltip/name fields.
        for mod in ability.get('modifications', []):
            field_id = mod.get('id')
            value = mod.get('value')
            
            if field_id == 'anam':  # Ability name
                ability_name = str(value) if value else None
            elif field_id == 'ansf':  # Editor suffix
                editor_suffix = str(value) if value else None
            elif field_id == 'atp1':  # Normal tooltip (level 1)
                tooltip_normal = str(value) if value else None
            elif field_id == 'aub1':  # Extended tooltip (level 1)
                tooltip_extended = str(value) if value else None
                
        # Check if ability exists
        self.cursor.execute("SELECT id FROM wc3_abilities WHERE ability_code = %s", (ability_code,))
        existing = self.cursor.fetchone()
        
        if existing:
            # Update existing
            self.cursor.execute("""
                UPDATE wc3_abilities 
                SET ability_name = %s,
                    editor_suffix = %s,
                    tooltip_normal = %s,
                    tooltip_extended = %s,
                    updated_at = CURRENT_TIMESTAMP
                WHERE ability_code = %s
            """, (ability_name, editor_suffix, tooltip_normal, tooltip_extended, ability_code))
            self.stats['updated'] += 1
        else:
            # Insert new
            self.cursor.execute("""
                INSERT INTO wc3_abilities (
                    ability_code, ability_name, editor_suffix, tooltip_normal, tooltip_extended
                )
                VALUES (%s, %s, %s, %s, %s)
            """, (ability_code, ability_name, editor_suffix, tooltip_normal, tooltip_extended))
            self.stats['imported'] += 1


def main():
    """Main entry point for ability importer."""
    parser = argparse.ArgumentParser(description='Import WC3 abilities from .w3a file')
    parser.add_argument('w3a_file', help='Path to .w3a file')
    parser.add_argument('--host', default='127.0.0.1', help='Database host')
    parser.add_argument('--port', default='5432', help='Database port')
    parser.add_argument('--database', default='wc3_pots', help='Database name')
    parser.add_argument('--user', default='postgres', help='Database user')
    parser.add_argument('--password', default='password', help='Database password')
    
    args = parser.parse_args()
    
    try:
        # Database configuration
        db_config = {
            'host': args.host,
            'port': args.port,
            'database': args.database,
            'user': args.user,
            'password': args.password
        }
        
        # Create importer
        importer =WC3AbilityImporter(db_config)
        importer.connect()
        
        # Import abilities
        stats = importer.import_from_w3a(args.w3a_file)
        
        # Print results
        print(f"\n{'='*60}")
        print(f"IMPORT COMPLETE")
        print(f"{'='*60}")
        print(f"✓ Imported: {stats['imported']} new abilities")
        print(f"↻ Updated: {stats['updated']} existing abilities")
        print(f"✗ Failed: {stats['failed']} abilities")
        
        if stats['errors']:
            print(f"\n⚠ Errors encountered:")
            for error in stats['errors'][:10]:
                print(f"  - {error}")
            if len(stats['errors']) > 10:
                print(f"  ... and {len(stats['errors']) - 10} more")
        
        importer.disconnect()
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
