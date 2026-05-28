"""
WC3 Item Data Importer
======================
Imports item data from Warcraft 3 World Editor formats into PostgreSQL database.

Supported formats:
- WC3 .txt object data files
- WC3 .slk files
- CSV exports
- JSON files

Author: Generated for PotS Project
Date: 2026-03-10
Version: 1.0.0
"""

import os
import re
import csv
import json
import psycopg2
from psycopg2.extras import execute_values, Json
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import configparser


class WC3ItemImporter:
    """Imports WC3 item data into PostgreSQL database."""
    
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
        
    def import_from_txt(self, file_path: str) -> Dict:
        """
        Import items from WC3 .txt object data file.
        
        Args:
            file_path: Path to WC3 .txt file
            
        Returns:
            Dictionary with import statistics
        """
        print(f"\n=== Importing from TXT: {file_path} ===")
        
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        items = self._parse_wc3_txt(file_path)
        
        for item_data in items:
            try:
                self._insert_or_update_item(item_data)
                self.stats['imported'] += 1
            except Exception as e:
                self.stats['failed'] += 1
                self.stats['errors'].append(f"Failed to import {item_data.get('item_code', 'UNKNOWN')}: {str(e)}")
                print(f"✗ Error importing item: {e}")
                
        self.conn.commit()
        self._log_import_history(file_path, 'WC3_TXT')
        return self.stats
        
    def import_from_csv(self, file_path: str) -> Dict:
        """
        Import items from CSV file.
        
        CSV Format expected:
        item_code, item_name, type, rarity, item_level, gold_cost, ...
        
        Args:
            file_path: Path to CSV file
            
        Returns:
            Dictionary with import statistics
        """
        print(f"\n=== Importing from CSV: {file_path} ===")
        
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                try:
                    item_data = self._normalize_csv_row(row)
                    self._insert_or_update_item(item_data)
                    self.stats['imported'] += 1
                except Exception as e:
                    self.stats['failed'] += 1
                    self.stats['errors'].append(f"Failed to import {row.get('item_code', 'UNKNOWN')}: {str(e)}")
                    print(f"✗ Error importing item: {e}")
                    
        self.conn.commit()
        self._log_import_history(file_path, 'CSV')
        return self.stats
        
    def import_from_json(self, file_path: str) -> Dict:
        """
        Import items from JSON file.
        
        Args:
            file_path: Path to JSON file
            
        Returns:
            Dictionary with import statistics
        """
        print(f"\n=== Importing from JSON: {file_path} ===")
        
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        items = data if isinstance(data, list) else [data]
        
        for item_data in items:
            try:
                self._insert_or_update_item(item_data)
                self.stats['imported'] += 1
            except Exception as e:
                self.stats['failed'] += 1
                self.stats['errors'].append(f"Failed to import {item_data.get('item_code', 'UNKNOWN')}: {str(e)}")
                print(f"✗ Error importing item: {e}")
                
        self.conn.commit()
        self._log_import_history(file_path, 'JSON')
        return self.stats
        
    def _parse_wc3_txt(self, file_path: str) -> List[Dict]:
        """
        Parse WC3 .txt object data file format.
        
        Format example:
        [I000]
        Name=Health Potion
        file=Abilities\\Spells\\Items\\AIhe\\AIheTarget.mdl
        ...
        """
        items = []
        current_item = None
        
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                
                # New item section
                if line.startswith('[') and line.endswith(']'):
                    if current_item:
                        items.append(current_item)
                    item_code = line[1:-1]
                    current_item = {'item_code': item_code}
                    
                # Property line
                elif '=' in line and current_item is not None:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    
                    # Map WC3 fields to database fields
                    field_mapping = {
                        'Name': 'item_name',
                        'Ubertip': 'tooltip',
                        'Description': 'description',
                        'file': 'model_path',
                        'Art': 'icon_path',
                        'goldcost': 'gold_cost',
                        'lumbercost': 'lumber_cost',
                        'level': 'item_level',
                        'uses': 'max_charges',
                        'stock': 'max_stack',
                        'prio': 'priority',
                        'drop': 'is_droppable',
                        'sellable': 'is_sellable',
                        'pawnable': 'is_pawnable',
                        'powerup': 'is_powerup',
                        'droppable': 'can_be_dropped_by_carrier',
                        'perishable': 'is_perishable',
                        'usable': 'use_automatically',
                        'morph': 'is_powerup',
                    }
                    
                    if key in field_mapping:
                        db_field = field_mapping[key]
                        
                        # Convert boolean values
                        if value in ('1', 'true', 'True', 'TRUE'):
                            value = True
                        elif value in ('0', 'false', 'False', 'FALSE'):
                            value = False
                        elif value.isdigit():
                            value = int(value)
                        elif self._is_float(value):
                            value = float(value)
                            
                        current_item[db_field] = value
                        
        if current_item:
            items.append(current_item)
            
        return items
        
    def _normalize_csv_row(self, row: Dict) -> Dict:
        """Normalize CSV row to database format."""
        normalized = {}
        
        for key, value in row.items():
            # Clean key
            key = key.strip().lower().replace(' ', '_')
            
            # Clean value
            if isinstance(value, str):
                value = value.strip()
                
                # Convert boolean strings
                if value.lower() in ('true', '1', 'yes'):
                    value = True
                elif value.lower() in ('false', '0', 'no', ''):
                    value = False
                # Convert numeric strings
                elif value.isdigit():
                    value = int(value)
                elif self._is_float(value):
                    value = float(value)
                    
            normalized[key] = value
            
        return normalized
        
    def _is_float(self, value: str) -> bool:
        """Check if string can be converted to float."""
        try:
            float(value)
            return True
        except (ValueError, TypeError):
            return False
            
    def _resolve_foreign_keys(self, item_data: Dict) -> Dict:
        """Resolve foreign key IDs from names."""
        resolved = item_data.copy()
        
        # Resolve type_id
        if 'type_name' in item_data:
            type_name = item_data['type_name']
            self.cursor.execute("SELECT id FROM item_types WHERE type_name = %s", (type_name,))
            result = self.cursor.fetchone()
            if result:
                resolved['type_id'] = result[0]
            del resolved['type_name']
            
        # Resolve rarity_id
        if 'rarity_name' in item_data:
            rarity_name = item_data['rarity_name']
            self.cursor.execute("SELECT id FROM item_rarities WHERE rarity_name = %s", (rarity_name,))
            result = self.cursor.fetchone()
            if result:
                resolved['rarity_id'] = result[0]
            del resolved['rarity_name']
            
        # Resolve class_id
        if 'class_name' in item_data:
            class_name = item_data['class_name']
            self.cursor.execute("SELECT id FROM item_classes WHERE class_name = %s", (class_name,))
            result = self.cursor.fetchone()
            if result:
                resolved['class_id'] = result[0]
            del resolved['class_name']
            
        # Resolve set_id
        if 'set_name' in item_data:
            set_name = item_data['set_name']
            self.cursor.execute("SELECT id FROM item_sets WHERE set_name = %s", (set_name,))
            result = self.cursor.fetchone()
            if result:
                resolved['set_id'] = result[0]
            del resolved['set_name']
            
        return resolved
        
    def _insert_or_update_item(self, item_data: Dict):
        """Insert new item or update existing item."""
        # Resolve foreign keys
        item_data = self._resolve_foreign_keys(item_data)
        
        item_code = item_data['item_code']
        
        # Check if item exists
        self.cursor.execute("SELECT id FROM items WHERE item_code = %s", (item_code,))
        existing = self.cursor.fetchone()
        
        if existing:
            # Update existing item
            item_id = existing[0]
            
            # Build UPDATE query dynamically
            set_clauses = []
            values = []
            for key, value in item_data.items():
                if key != 'item_code':  # Don't update the primary lookup key
                    set_clauses.append(f"{key} = %s")
                    values.append(value)
            values.append(item_code)
            
            if set_clauses:
                query = f"UPDATE items SET {', '.join(set_clauses)} WHERE item_code = %s"
                self.cursor.execute(query, values)
                self.stats['updated'] += 1
                print(f"  ↻ Updated: {item_code}")
        else:
            # Insert new item
            columns = list(item_data.keys())
            placeholders = [f'%s' for _ in columns]
            values = [item_data[col] for col in columns]
            
            query = f"INSERT INTO items ({', '.join(columns)}) VALUES ({', '.join(placeholders)})"
            self.cursor.execute(query, values)
            print(f"  + Added: {item_code}")
            
    def _log_import_history(self, source_file: str, format_type: str):
        """Log import operation to history table."""
        query = """
            INSERT INTO import_history 
            (source_file, items_imported, items_updated, items_failed, import_format, notes)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        notes = "\n".join(self.stats['errors']) if self.stats['errors'] else None
        self.cursor.execute(query, (
            source_file,
            self.stats['imported'],
            self.stats['updated'],
            self.stats['failed'],
            format_type,
            notes
        ))
        self.conn.commit()
        
    def print_summary(self):
        """Print import summary."""
        print("\n" + "="*60)
        print("IMPORT SUMMARY")
        print("="*60)
        print(f"✓ Items Imported: {self.stats['imported']}")
        print(f"↻ Items Updated:  {self.stats['updated']}")
        print(f"✗ Items Failed:   {self.stats['failed']}")
        
        if self.stats['errors']:
            print("\nErrors:")
            for error in self.stats['errors'][:10]:  # Show first 10 errors
                print(f"  - {error}")
            if len(self.stats['errors']) > 10:
                print(f"  ... and {len(self.stats['errors']) - 10} more errors")
        print("="*60)


def load_config(config_file: str = 'database.ini') -> Dict[str, str]:
    """Load database configuration from INI file."""
    config = configparser.ConfigParser()
    config.read(config_file)
    
    if 'postgresql' in config:
        return {
            'host': config['postgresql'].get('host', 'localhost'),
            'port': config['postgresql'].get('port', '5432'),
            'database': config['postgresql'].get('database', 'wc3_pots'),
            'user': config['postgresql'].get('user', 'postgres'),
            'password': config['postgresql'].get('password', '')
        }
    else:
        # Default configuration
        return {
            'host': 'localhost',
            'port': '5432',
            'database': 'wc3_pots',
            'user': 'postgres',
            'password': ''
        }


def main():
    """Main entry point for CLI usage."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Import WC3 item data into PostgreSQL')
    parser.add_argument('file', help='Path to file to import')
    parser.add_argument('--format', choices=['txt', 'csv', 'json', 'auto'], default='auto',
                       help='File format (default: auto-detect from extension)')
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
        
    # Auto-detect format
    file_format = args.format
    if file_format == 'auto':
        ext = os.path.splitext(args.file)[1].lower()
        format_map = {'.txt': 'txt', '.csv': 'csv', '.json': 'json'}
        file_format = format_map.get(ext, 'txt')
        
    # Import data
    importer = WC3ItemImporter(db_config)
    
    try:
        importer.connect()
        
        if file_format == 'txt':
            importer.import_from_txt(args.file)
        elif file_format == 'csv':
            importer.import_from_csv(args.file)
        elif file_format == 'json':
            importer.import_from_json(args.file)
            
        importer.print_summary()
        
    except Exception as e:
        print(f"\n✗ Import failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        importer.disconnect()


if __name__ == '__main__':
    main()
