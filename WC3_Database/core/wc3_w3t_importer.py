"""
WC3 .w3t Item Importer
======================
Imports items from Warcraft 3 .w3t binary files into PostgreSQL database.

Author: Generated for PotS Project
Date: 2026-03-10
Version: 1.0.0
"""

import os
import sys
import psycopg2
from psycopg2.extras import execute_values
from datetime import datetime
from typing import Dict, List, Optional
import configparser
from wc3_w3t_parser import WC3ObjectDataParser


class WC3W3TImporter:
    """Imports WC3 items from .w3t files into PostgreSQL database."""
    
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
            self.conn = psycopg2.connect(**self.db_config)
            self.cursor = self.conn.cursor()
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
        
    def import_from_w3t(self, file_path: str) -> Dict:
        """
        Import items from WC3 .w3t file.
        
        Args:
            file_path: Path to .w3t file
            
        Returns:
            Dictionary with import statistics
        """
        print(f"\n=== Importing from W3T: {os.path.basename(file_path)} ===\n")
        
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        # Parse the .w3t file
        parser = WC3ObjectDataParser(file_path)
        data = parser.parse()
        
        print(f"\nParsed {len(data['original_objects'])} modified objects and {len(data['custom_objects'])} custom objects")
        print(f"Converting to database format...\n")
        
        items = parser.to_items_dict()
        
        print(f"Processing {len(items)} items...")
        
        for i, item_data in enumerate(items, 1):
            try:
                self._insert_or_update_item(item_data)
                if i % 50 == 0:
                    print(f"  Processed {i}/{len(items)} items...")
            except Exception as e:
                self.stats['failed'] += 1
                item_code = item_data.get('item_code', 'UNKNOWN')
                error_msg = f"Failed to import {item_code}: {str(e)}"
                self.stats['errors'].append(error_msg)
                print(f"✗ {error_msg}")
                
        self.conn.commit()
        self._log_import_history(file_path, 'W3T')
        return self.stats
        
    def _insert_or_update_item(self, item_data: Dict):
        """Insert or update an item in the database."""
        item_code = item_data.get('item_code')
        item_name = item_data.get('item_name')
        original_item_code = item_data.get('original_item_code')
        
        if not item_code:
            raise ValueError("Item code is required")
        
        # Skip importing original items without names (modified Blizzard items with incomplete data)
        # These are partial modifications that should use WC3's default data
        is_original_item = (not original_item_code or original_item_code == item_code)
        if is_original_item and not item_name:
            print(f"  ⊘ Skipped original item without name: {item_code} (has only partial modifications)")
            self.stats['skipped'] = self.stats.get('skipped', 0) + 1
            return
        
        # Default name for custom items only
        if not item_name:
            item_name = f'Unknown Item ({item_code})'
            
        # Check if item exists
        self.cursor.execute("SELECT id FROM items WHERE item_code = %s", (item_code,))
        existing = self.cursor.fetchone()
        
        # Get or create item type/class
        item_class = self._map_item_class(item_data.get('item_class', ''))
        item_type_id = self._get_or_create_type('Miscellaneous')
        item_rarity_id = self._get_rarity_from_name(item_name)
        item_class_id = self._get_or_create_class(item_class) if item_class else None
        
        # Inherit model_path from base item if not specified
        # Custom items (those with original_item_code different from item_code) should inherit
        # model_path from their base item if they didn't explicitly override it
        original_item_code = item_data.get('original_item_code')
        if not item_data.get('model_path') and original_item_code and original_item_code != item_code:
            # This is a custom item without explicit model_path - inherit from base
            self.cursor.execute(
                "SELECT model_path FROM items WHERE item_code = %s AND model_path IS NOT NULL",
                (original_item_code,)
            )
            base_model = self.cursor.fetchone()
            if base_model and base_model[0]:
                item_data['model_path'] = base_model[0]
                
        # Prepare item fields
        gold_cost = item_data.get('gold_cost', 0)
        if isinstance(gold_cost, str):
            try:
                gold_cost = int(gold_cost)
            except:
                gold_cost = 0
                
        item_level = item_data.get('item_level', 1)
        if isinstance(item_level, str):
            try:
                item_level = int(item_level)
            except:
                item_level = 1
                
        # Build SQL for item
        if existing:
            # Update existing item
            sql = """
                UPDATE items SET
                    item_name = %s,
                    base_id = %s,
                    type_id = %s,
                    rarity_id = %s,
                    class_id = %s,
                    item_level = %s,
                    gold_cost = %s,
                    tooltip = %s,
                    description = %s,
                    icon_path = %s,
                    model_path = %s,
                    max_charges = %s,
                    is_droppable = %s,
                    is_sellable = %s,
                    is_pawnable = %s,
                    wc3_classification = %s,
                    wc3_abilities = %s,
                    cooldown_group = %s,
                    scale = %s,
                    tint_red = %s,
                    tint_green = %s,
                    tint_blue = %s,
                    updated_at = CURRENT_TIMESTAMP
                WHERE item_code = %s
                RETURNING id
            """
            # Set base_id for custom items (where original_item_code != item_code)
            base_id_value = original_item_code if (original_item_code and original_item_code != item_code) else None
            values = (
                item_name,
                base_id_value,
                item_type_id,
                item_rarity_id,
                item_class_id,
                item_level,
                gold_cost,
                item_data.get('tooltip', '')[:500],
                item_data.get('description', '')[:1000],
                item_data.get('icon_path', '')[:255],
                item_data.get('model_path', '')[:255],
                item_data.get('max_charges'),
                bool(item_data.get('is_droppable', True)),
                bool(item_data.get('is_sellable', True)),
                bool(item_data.get('is_pawnable', True)),
                item_data.get('wc3_classification'),
                item_data.get('wc3_abilities'),
                item_data.get('cooldown_group'),
                item_data.get('scale'),
                item_data.get('tint_red'),
                item_data.get('tint_green'),
                item_data.get('tint_blue'),
                item_code
            )
            self.cursor.execute(sql, values)
            self.stats['updated'] += 1
            print(f"  ↻ Updated: {item_code} - {item_name}")
        else:
            # Insert new item
            sql = """
                INSERT INTO items (
                    item_code, item_name, base_id, type_id, rarity_id, class_id, item_level, gold_cost,
                    tooltip, description, icon_path, model_path, max_charges,
                    is_droppable, is_sellable, is_pawnable,
                    wc3_classification, wc3_abilities, cooldown_group, scale, tint_red, tint_green, tint_blue
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                )
                RETURNING id
            """
            # Set base_id for custom items (where original_item_code != item_code)
            base_id_value = original_item_code if (original_item_code and original_item_code != item_code) else None
            values = (
                item_code,
                item_name,
                base_id_value,
                item_type_id,
                item_rarity_id,
                item_class_id,
                item_level,
                gold_cost,
                item_data.get('tooltip', '')[:500],
                item_data.get('description', '')[:1000],
                item_data.get('icon_path', '')[:255],
                item_data.get('model_path', '')[:255],
                item_data.get('max_charges'),
                bool(item_data.get('is_droppable', True)),
                bool(item_data.get('is_sellable', True)),
                bool(item_data.get('is_pawnable', True)),
                item_data.get('wc3_classification'),
                item_data.get('wc3_abilities'),
                item_data.get('cooldown_group'),
                item_data.get('scale'),
                item_data.get('tint_red'),
                item_data.get('tint_green'),
                item_data.get('tint_blue')
            )
            self.cursor.execute(sql, values)
            self.stats['imported'] += 1
            print(f"  + Added: {item_code} - {item_name}")
            
    def _map_item_class(self, wc3_class: str) -> str:
        """Map WC3 item class to database item class."""
        class_mapping = {
            'Permanent': 'MISC',
            'Charged': 'CONSUMABLE',
            'Powerup': 'CONSUMABLE',
            'Artifact': 'ARTIFACT',
            'Purchasable': 'MISC',
            'Campaign': 'QUEST',
            'Miscellaneous': 'MISC'
        }
        return class_mapping.get(wc3_class, 'MISC')
        
    def _get_rarity_from_name(self, name: str) -> int:
        """Determine rarity ID from item name color codes."""
        # WC3 color codes in item names indicate rarity
        if '|c00FFB400' in name or '|cFFFFB400' in name:  # Orange
            return self._get_or_create_rarity('Legendary')
        elif '|c00800080' in name or '|cFF800080' in name:  # Purple
            return self._get_or_create_rarity('Epic')
        elif '|c000080FF' in name or '|cFF0080FF' in name:  # Blue
            return self._get_or_create_rarity('Rare')
        elif '|c0090EE90' in name or '|cFF90EE90' in name:  # Green
            return self._get_or_create_rarity('Uncommon')
        else:
            return self._get_or_create_rarity('Common')
            
    def _get_or_create_type(self, type_name: str) -> int:
        """Get or create item type ID."""
        self.cursor.execute("SELECT id FROM item_types WHERE type_name = %s", (type_name,))
        result = self.cursor.fetchone()
        if result:
            return result[0]
        else:
            self.cursor.execute(
                "INSERT INTO item_types (type_name) VALUES (%s) RETURNING id",
                (type_name,)
            )
            return self.cursor.fetchone()[0]
            
    def _get_or_create_rarity(self, rarity_name: str) -> int:
        """Get or create item rarity ID."""
        self.cursor.execute("SELECT id FROM item_rarities WHERE rarity_name = %s", (rarity_name,))
        result = self.cursor.fetchone()
        if result:
            return result[0]
        else:
            self.cursor.execute(
                "INSERT INTO item_rarities (rarity_name, rarity_level) VALUES (%s, 0) RETURNING id",
                (rarity_name,)
            )
            return self.cursor.fetchone()[0]
            
    def _get_or_create_class(self, class_name: str) -> Optional[int]:
        """Get or create item class ID."""
        if not class_name:
            return None
        self.cursor.execute("SELECT id FROM item_classes WHERE class_name = %s", (class_name,))
        result = self.cursor.fetchone()
        if result:
            return result[0]
        else:
            self.cursor.execute(
                "INSERT INTO item_classes (class_name) VALUES (%s) RETURNING id",
                (class_name,)
            )
            return self.cursor.fetchone()[0]
            
    def _log_import_history(self, file_path: str, file_type: str):
        """Log the import to history table."""
        # Import history logging (skip if table doesn't exist)
        pass
            
    def print_summary(self):
        """Print import summary."""
        print(f"\n{'=' * 60}")
        print(f"IMPORT SUMMARY")
        print(f"{'=' * 60}")
        print(f"✓ Items imported: {self.stats['imported']}")
        print(f"↻ Items updated:  {self.stats['updated']}")
        print(f"○ Items skipped:  {self.stats['skipped']}")
        print(f"✗ Items failed:   {self.stats['failed']}")
        print(f"{'=' * 60}")
        
        if self.stats['errors']:
            print(f"\nERRORS ({len(self.stats['errors'])} total):")
            for error in self.stats['errors'][:10]:  # Show first 10 errors
                print(f"  • {error}")
            if len(self.stats['errors']) > 10:
                print(f"  ... and {len(self.stats['errors']) - 10} more")


def load_config(config_file: str = 'database.ini') -> Dict[str, str]:
    """Load database configuration from INI file."""
    config = configparser.ConfigParser()
    config.read(config_file)
    
    return {
        'host': config.get('postgresql', 'host'),
        'port': config.get('postgresql', 'port'),
        'database': config.get('postgresql', 'database'),
        'user': config.get('postgresql', 'user'),
        'password': config.get('postgresql', 'password')
    }


def main():
    """Main entry point for CLI usage."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Import WC3 items from .w3t file into PostgreSQL')
    parser.add_argument('file', help='Path to .w3t file to import')
    parser.add_argument('--config', default='database.ini',
                       help='Database configuration file (default: database.ini)')
    parser.add_argument('--host', help='Database host (overrides config)')
    parser.add_argument('--port', help='Database port (overrides config)')
    parser.add_argument('--database', help='Database name (overrides config)')
    parser.add_argument('--user', help='Database user (overrides config)')
    parser.add_argument('--password', help='Database password (overrides config)')
    
    args = parser.parse_args()
    
    # Load configuration
    db_config = load_config(args.config)
    
    # Override with command line arguments
    if args.host:
        db_config['host'] = args.host
    if args.port:
        db_config['port'] = args.port
    if args.database:
        db_config['database'] = args.database
    if args.user:
        db_config['user'] = args.user
    if args.password:
        db_config['password'] = args.password
        
    # Import data
    importer = WC3W3TImporter(db_config)
    
    try:
        importer.connect()
        importer.import_from_w3t(args.file)
        importer.print_summary()
        
    except Exception as e:
        print(f"\n✗ Import failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        importer.disconnect()


if __name__ == '__main__':
    main()
