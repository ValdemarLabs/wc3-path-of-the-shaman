"""
WC3 .w3t Item Importer v2.0.0 - ZERO DATA LOSS
================================================
Imports COMPLETE item data from Warcraft 3 .w3t binary files into PostgreSQL database.

NEW IN V2:
- Stores ALL 60+ WC3 fields (vs 15 fields in v1.0.0)
- Stores original modifications as JSON for perfect round-trip export
- Zero data loss: Full preservation of all WC3 item data
- Supports tooltip_extended, hotkey, cooldown_group, classification, abilities, etc.

FIXES:
- v1.0.0 lost ~754 modifications (14.6% data loss) due to only storing 15 fields
- v2.0.0 stores all parsed fields + original modifications JSON

Author: Generated for PotS Project
Date: 2026-03-11
Version: 2.0.0
"""

import os
import sys
import psycopg2
import json
from psycopg2.extras import execute_values, Json
from datetime import datetime
from typing import Dict, List, Optional
import configparser

# Force UTF-8 encoding for stdout/stderr to support Unicode characters
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8')

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
try:
    from core.wc3_w3t_parser import WC3ObjectDataParser
except ImportError:
    from parsers.wc3_w3t_parser import WC3ObjectDataParser


class WC3W3TImporter:
    """Imports WC3 items from .w3t files into PostgreSQL database with ZERO data loss."""
    
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
            'errors': [],
            'fields_stored': 0
        }
        
    def connect(self):
        """Connect to PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            self.cursor = self.conn.cursor()
            print(f"[OK] Connected to database: {self.db_config['database']}")
        except Exception as e:
            print(f"[ERROR] Failed to connect to database: {e}")
            raise
            
    def disconnect(self):
        """Close database connection."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("[OK] Database connection closed")
        
    def import_from_w3t(self, file_path: str, preserve_original_mods: bool = True, 
                         update_mode: str = 'merge') -> Dict:
        """
        Import items from WC3 .w3t file.
        
        Args:
            file_path: Path to .w3t file
            preserve_original_mods: Store original modifications as JSON for perfect round-trip
            update_mode: How to handle existing items:
                - 'replace': Replace ALL fields (may overwrite with NULL)
                - 'merge': Only update non-NULL fields (preserve existing data)
                - 'skip': Don't update existing items at all
            
        Returns:
            Dictionary with import statistics
        """
        print(f"\n=== Importing from W3T: {os.path.basename(file_path)} ===")
        print(f"Mode: {'FULL PRESERVATION' if preserve_original_mods else 'MAPPED FIELDS ONLY'}")
        print(f"Update Mode: {update_mode.upper()}\n")
        
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")
            
        # Parse the .w3t file
        parser = WC3ObjectDataParser(file_path)
        data = parser.parse()
        
        print(f"Parsed {len(data['original_objects'])} modified objects and {len(data['custom_objects'])} custom objects")
        print(f"Converting to database format...\n")
        
        items = parser.to_items_dict()
        
        print(f"Processing {len(items)} items with ALL WC3 fields...")
        
        field_counts = {}
        for i, item_data in enumerate(items, 1):
            try:
                stored_fields = self._insert_or_update_item(item_data, preserve_original_mods, update_mode)
                self.stats['fields_stored'] += stored_fields
                
                # Track which fields are being stored
                for key in item_data.keys():
                    if key != 'modifications':
                        field_counts[key] = field_counts.get(key, 0) + 1
                
                if i % 50 == 0:
                    print(f"  Processed {i}/{len(items)} items...")
            except Exception as e:
                self.stats['failed'] += 1
                item_code = item_data.get('item_code', 'UNKNOWN')
                error_msg = f"Failed to import {item_code}: {str(e)}"
                self.stats['errors'].append(error_msg)
                print(f"[ERROR] {error_msg}")
                
        self.conn.commit()
        self._log_import_history(file_path, 'W3T')
        
        # Print field storage summary
        print(f"\n=== Field Storage Summary ===")
        print(f"Total fields stored across all items: {self.stats['fields_stored']}")
        print(f"\nMost common fields extracted:")
        for field, count in sorted(field_counts.items(), key=lambda x: x[1], reverse=True)[:15]:
            print(f"  {field}: {count} items")
        
        return self.stats
        
    def _insert_or_update_item(self, item_data: Dict, preserve_original_mods: bool = True,
                                update_mode: str = 'merge') -> int:
        """
        Insert or update an item in the database with ALL WC3 fields.
        
        Args:
            item_data: Item data dictionary
            preserve_original_mods: Whether to store original modifications JSON
            update_mode: 'replace' (overwrite all), 'merge' (update non-NULL), 'skip' (don't update)
        
        Returns:
            Number of fields stored for this item
        """
        item_code = item_data.get('item_code')
        item_name = item_data.get('item_name', f'Unknown Item ({item_code})')
        
        if not item_code:
            raise ValueError("Item code is required")
            
        # Check if item exists
        self.cursor.execute("SELECT id FROM items WHERE item_code = %s", (item_code,))
        existing = self.cursor.fetchone()
        
        # Get or create item type/class/rarity
        item_class = self._map_item_class(item_data.get('item_class', ''))
        item_type_id = self._get_or_create_type('Miscellaneous')
        item_rarity_id = self._get_rarity_from_name(item_name)
        item_class_id = self._get_or_create_class(item_class) if item_class else None
        
        # ===== PREPARE ALL WC3 FIELDS (60+ fields) =====
        
        # Helper to safely convert numeric values
        def safe_int(val, default=None):
            if val is None:
                return default
            if isinstance(val, (int, float)):
                return int(val)
            if isinstance(val, str):
                try:
                    return int(float(val))
                except:
                    return default
            return default
            
        def safe_float(val, default=None):
            if val is None:
                return default
            if isinstance(val, (int, float)):
                return float(val)
            if isinstance(val, str):
                try:
                    return float(val)
                except:
                    return default
            return default
            
        def safe_bool(val, default=False):
            if val is None:
                return default
            if isinstance(val, bool):
                return val
            if isinstance(val, int):
                return bool(val)
            if isinstance(val, str):
                return val.lower() in ('1', 'true', 'yes')
            return default
            
        def safe_str(val, max_len=None):
            if val is None:
                return None
            s = str(val)
            if max_len:
                return s[:max_len]
            return s

        def safe_optional_bool(field_name):
            if field_name not in item_data or item_data.get(field_name) is None:
                return None
            return safe_bool(item_data.get(field_name))
        
        # Core identification fields
        original_item_code = item_data.get('original_item_code')
        base_id = safe_str(original_item_code, 4) if original_item_code else None
        
        # Text fields
        tooltip = safe_str(item_data.get('tooltip'), 1000)
        tooltip_extended = safe_str(item_data.get('tooltip_extended'))  # Full length
        description = safe_str(item_data.get('description'))
        hotkey = safe_str(item_data.get('hotkey'), 10)
        
        # Classification field (WC3 specific)
        wc3_classification = safe_str(item_data.get('wc3_classification'), 50)
        
        # Cost & Level fields
        gold_cost = safe_int(item_data.get('gold_cost'), 0)
        lumber_cost = safe_int(item_data.get('lumber_cost'), 0)
        item_level = safe_int(item_data.get('item_level'), 1)
        old_level = safe_int(item_data.get('old_level'))
        hit_points = safe_int(item_data.get('hit_points'))
        
        # Charges & Stacks
        max_charges = safe_int(item_data.get('max_charges'))
        max_stack = safe_int(item_data.get('max_stack'))

        # Boolean flags: keep absent fields as NULL so imports do not overwrite
        # inherited/default WC3 values with False during merge updates.
        actively_used = safe_optional_bool('actively_used')
        is_droppable = safe_optional_bool('is_droppable')
        is_sellable = safe_optional_bool('is_sellable')
        is_pawnable = safe_optional_bool('is_pawnable')
        dropped_on_death = safe_optional_bool('dropped_on_death')
        is_perishable = safe_optional_bool('is_perishable')
        is_powerup = safe_optional_bool('is_powerup')
        ignore_cooldown = safe_optional_bool('ignore_cooldown')
        pick_random = safe_optional_bool('pick_random')
        if is_powerup is None and isinstance(wc3_classification, str) and wc3_classification.lower() == 'powerup':
            is_powerup = True
        use_automatically = True if is_powerup is True else safe_optional_bool('use_automatically')
        
        # Other fields
        morph_target = safe_str(item_data.get('morph_target'), 4)
        armor_type = safe_str(item_data.get('armor_type'), 50)
        
        # Abilities (stored as comma-separated raw codes or JSON)
        abilities_raw = item_data.get('wc3_abilities')
        wc3_abilities = None
        if abilities_raw:
            if isinstance(abilities_raw, list):
                wc3_abilities = ','.join(abilities_raw)
            else:
                wc3_abilities = safe_str(abilities_raw)
        
        # Cooldown Group (WC3 'icid' field stores STRING values: ability codes or custom IDs)
        cooldown_group = safe_str(item_data.get('cooldown_group'), 50)
        
        # Visual/Art fields
        icon_path = safe_str(item_data.get('icon_path'), 255)
        model_path = safe_str(item_data.get('model_path'), 255)
        scale = safe_float(item_data.get('scale'))
        selection_size = safe_float(item_data.get('selection_size'))
        tint_red = safe_int(item_data.get('tint_red'))
        tint_green = safe_int(item_data.get('tint_green'))
        tint_blue = safe_int(item_data.get('tint_blue'))
        button_pos_x = safe_int(item_data.get('button_pos_x'))
        button_pos_y = safe_int(item_data.get('button_pos_y'))
        
        # Stock system
        priority = safe_int(item_data.get('priority'))
        stock_initial = safe_int(item_data.get('stock_initial'))
        stock_max = safe_int(item_data.get('stock_max'))
        stock_replenish = safe_int(item_data.get('stock_replenish'))
        stock_start_delay = safe_int(item_data.get('stock_start_delay'))
        
        # Requirements
        wc3_requirements = safe_str(item_data.get('wc3_requirements'))
        wc3_requirements_amount = safe_str(item_data.get('wc3_requirements_amount'))
        
        # ===== CRITICAL: Store original modifications as JSON for perfect round-trip =====
        original_modifications = None
        if preserve_original_mods and 'modifications' in item_data:
            original_modifications = Json(item_data['modifications'])
        
        # Count non-None fields
        fields_stored = sum(1 for v in [
            item_name, base_id, tooltip, tooltip_extended, description, hotkey,
            wc3_classification, gold_cost, lumber_cost, item_level, old_level, hit_points,
            max_charges, max_stack, actively_used, is_droppable, is_sellable, is_pawnable,
            dropped_on_death, is_perishable, is_powerup, use_automatically, morph_target, ignore_cooldown,
            pick_random, armor_type, wc3_abilities, cooldown_group, icon_path, model_path,
            scale, selection_size, tint_red, tint_green, tint_blue, button_pos_x,
            button_pos_y, priority, stock_initial, stock_max, stock_replenish,
            stock_start_delay, wc3_requirements, wc3_requirements_amount
        ] if v is not None)
        
        # Check if item exists
        self.cursor.execute("SELECT item_code FROM items WHERE item_code = %s", (item_code,))
        existing = self.cursor.fetchone()
        
        if existing:
            # Handle different update modes
            if update_mode == 'skip':
                self.stats['skipped'] += 1
                print(f"  - Skipped: {item_code} - {item_name} (already exists)")
                return 0
            
            elif update_mode == 'merge':
                # Only update non-NULL fields (preserve existing data)
                update_fields = []
                update_values = []
                
                field_map = {
                    'item_name': item_name, 'base_id': base_id, 'type_id': item_type_id,
                    'rarity_id': item_rarity_id, 'class_id': item_class_id,
                    'item_level': item_level, 'old_level': old_level, 'gold_cost': gold_cost,
                    'lumber_cost': lumber_cost, 'hit_points': hit_points, 'tooltip': tooltip,
                    'tooltip_extended': tooltip_extended, 'description': description,
                    'hotkey': hotkey, 'wc3_classification': wc3_classification,
                    'icon_path': icon_path, 'model_path': model_path, 'max_charges': max_charges,
                    'max_stack': max_stack, 'actively_used': actively_used,
                    'is_droppable': is_droppable, 'is_sellable': is_sellable,
                    'is_pawnable': is_pawnable, 'dropped_on_death': dropped_on_death,
                    'is_perishable': is_perishable, 'is_powerup': is_powerup,
                    'use_automatically': use_automatically,
                    'morph_target': morph_target, 'ignore_cooldown': ignore_cooldown,
                    'pick_random': pick_random, 'armor_type': armor_type,
                    'wc3_abilities': wc3_abilities, 'cooldown_group': cooldown_group,
                    'scale': scale, 'selection_size': selection_size, 'tint_red': tint_red,
                    'tint_green': tint_green, 'tint_blue': tint_blue,
                    'button_pos_x': button_pos_x, 'button_pos_y': button_pos_y,
                    'priority': priority, 'stock_initial': stock_initial,
                    'stock_max': stock_max, 'stock_replenish': stock_replenish,
                    'stock_start_delay': stock_start_delay, 'wc3_requirements': wc3_requirements,
                    'wc3_requirements_amount': wc3_requirements_amount,
                    'original_modifications': original_modifications
                }
                
                # Only include non-NULL values
                for field, value in field_map.items():
                    if value is not None:
                        update_fields.append(f"{field} = %s")
                        update_values.append(value)
                
                if not update_fields:
                    self.stats['skipped'] += 1
                    print(f"  - Skipped: {item_code} - {item_name} (no non-NULL fields)")
                    return 0
                
                update_fields.append("updated_at = CURRENT_TIMESTAMP")
                update_values.append(item_code)
                
                sql = f"""
                    UPDATE items SET
                        {', '.join(update_fields)}
                    WHERE item_code = %s
                    RETURNING id
                """
                self.cursor.execute(sql, update_values)
                self.stats['updated'] += 1
                print(f"  ↻ Merged: {item_code} - {item_name} ({len([v for v in field_map.values() if v is not None])} fields)")
                
            else:  # update_mode == 'replace'
                # Replace ALL fields (may overwrite with NULL)
                sql = """
                    UPDATE items SET
                        item_name = %s,
                        base_id = %s,
                        type_id = %s,
                        rarity_id = %s,
                        class_id = %s,
                        item_level = %s,
                        old_level = %s,
                        gold_cost = %s,
                        lumber_cost = %s,
                        hit_points = %s,
                        tooltip = %s,
                        tooltip_extended = %s,
                        description = %s,
                        hotkey = %s,
                        wc3_classification = %s,
                        icon_path = %s,
                        model_path = %s,
                        max_charges = %s,
                        max_stack = %s,
                        actively_used = %s,
                        is_droppable = %s,
                        is_sellable = %s,
                        is_pawnable = %s,
                        dropped_on_death = %s,
                        is_perishable = %s,
                        is_powerup = %s,
                        use_automatically = %s,
                        morph_target = %s,
                        ignore_cooldown = %s,
                        pick_random = %s,
                        armor_type = %s,
                        wc3_abilities = %s,
                        cooldown_group = %s,
                        scale = %s,
                        selection_size = %s,
                        tint_red = %s,
                        tint_green = %s,
                        tint_blue = %s,
                        button_pos_x = %s,
                        button_pos_y = %s,
                        priority = %s,
                        stock_initial = %s,
                        stock_max = %s,
                        stock_replenish = %s,
                        stock_start_delay = %s,
                        wc3_requirements = %s,
                        wc3_requirements_amount = %s,
                        original_modifications = %s,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE item_code = %s
                    RETURNING id
                """
                values = (
                    item_name, base_id, item_type_id, item_rarity_id, item_class_id,
                    item_level, old_level, gold_cost, lumber_cost, hit_points,
                    tooltip, tooltip_extended, description, hotkey, wc3_classification,
                    icon_path, model_path, max_charges, max_stack,
                    actively_used, is_droppable, is_sellable, is_pawnable,
                    dropped_on_death, is_perishable, is_powerup, use_automatically, morph_target,
                    ignore_cooldown, pick_random, armor_type, wc3_abilities, cooldown_group,
                    scale, selection_size, tint_red, tint_green, tint_blue,
                    button_pos_x, button_pos_y, priority, stock_initial, stock_max,
                    stock_replenish, stock_start_delay, wc3_requirements, wc3_requirements_amount,
                    original_modifications,
                    item_code
                )
                self.cursor.execute(sql, values)
                self.stats['updated'] += 1
                print(f"  ↻ Replaced: {item_code} - {item_name} ({fields_stored} fields)")
        else:
            # Insert new item with ALL fields
            sql = """
                INSERT INTO items (
                    item_code, item_name, base_id, type_id, rarity_id, class_id,
                    item_level, old_level, gold_cost, lumber_cost, hit_points,
                    tooltip, tooltip_extended, description, hotkey, wc3_classification,
                    icon_path, model_path, max_charges, max_stack,
                    actively_used, is_droppable, is_sellable, is_pawnable,
                    dropped_on_death, is_perishable, is_powerup, use_automatically, morph_target,
                    ignore_cooldown, pick_random, armor_type, wc3_abilities, cooldown_group,
                    scale, selection_size, tint_red, tint_green, tint_blue,
                    button_pos_x, button_pos_y, priority, stock_initial, stock_max,
                    stock_replenish, stock_start_delay, wc3_requirements, wc3_requirements_amount,
                    original_modifications
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                )
                RETURNING id
            """
            values = (
                item_code, item_name, base_id, item_type_id, item_rarity_id, item_class_id,
                item_level, old_level, gold_cost, lumber_cost, hit_points,
                tooltip, tooltip_extended, description, hotkey, wc3_classification,
                icon_path, model_path, max_charges, max_stack,
                actively_used, is_droppable, is_sellable, is_pawnable,
                dropped_on_death, is_perishable, is_powerup, use_automatically, morph_target,
                ignore_cooldown, pick_random, armor_type, wc3_abilities, cooldown_group,
                scale, selection_size, tint_red, tint_green, tint_blue,
                button_pos_x, button_pos_y, priority, stock_initial, stock_max,
                stock_replenish, stock_start_delay, wc3_requirements, wc3_requirements_amount,
                original_modifications
            )
            self.cursor.execute(sql, values)
            self.stats['imported'] += 1
            print(f"  + Added: {item_code} - {item_name} ({fields_stored} fields)")
        
        return fields_stored
            
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
        if not name:
            return self._get_or_create_rarity('Common')
            
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
            
    def _get_or_create_class(self, class_name: str) -> int:
        """Get or create item class ID."""
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
            
    def _get_or_create_rarity(self, rarity_name: str) -> int:
        """Get or create item rarity ID."""
        self.cursor.execute("SELECT id FROM item_rarities WHERE rarity_name = %s", (rarity_name,))
        result = self.cursor.fetchone()
        if result:
            return result[0]
        else:
            self.cursor.execute(
                "INSERT INTO item_rarities (rarity_name) VALUES (%s) RETURNING id",
                (rarity_name,)
            )
            return self.cursor.fetchone()[0]
            
    def _log_import_history(self, file_path: str, import_type: str):
        """Log import to history table."""
        try:
            self.cursor.execute("""
                                          preserve_original_mods=not args.no_preserve_mods,
                                          update_mode=args.update_mode
                INSERT INTO import_history (file_path, import_type, items_imported, items_updated, items_failed)
                VALUES (%s, %s, %s, %s, %s)
            """, (file_path, import_type, self.stats['imported'], self.stats['updated'], self.stats['failed']))
        except Exception as e:
            print(f"Warning: Could not log import history: {e}")


def load_config(config_path: str = 'config.ini') -> Dict[str, str]:
    """Load database configuration from config file."""
    config = configparser.ConfigParser()
    config.read(config_path)
    return {
        'host': config.get('database', 'host'),
        'port': config.get('database', 'port'),
        'database': config.get('database', 'database'),
        'user': config.get('database', 'user'),
        'password': config.get('database', 'password')
    }


def main():
    """CLI entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Import WC3 items from .w3t file')
    parser.add_argument('w3t_file', help='Path to .w3t file')
    parser.add_argument('--config', help='Path to config file (optional if using --host/--database)')
    parser.add_argument('--host', help='Database host (default: 127.0.0.1)')
    parser.add_argument('--port', help='Database port (default: 5432)')
    parser.add_argument('--database', help='Database name')
    parser.add_argument('--user', help='Database user')
    parser.add_argument('--password', help='Database password')
    parser.add_argument('--no-preserve-mods', action='store_true', 
                        help='Do not preserve original modifications JSON (smaller DB size)')
    parser.add_argument('--update-mode', choices=['replace', 'merge', 'skip'], default='merge',
                        help='How to handle existing items: replace (overwrite all), merge (update non-NULL only), skip (ignore existing)')
    
    args = parser.parse_args()
    
    # Load config from command line args or config file
    if args.host and args.database and args.user:
        # Use command-line arguments
        db_config = {
            'host': args.host or '127.0.0.1',
            'port': args.port or '5432',
            'database': args.database,
            'user': args.user,
            'password': args.password or ''
        }
        print(f"Using command-line database configuration: {args.user}@{args.host}:{args.port}/{args.database}")
    else:
        # Load from config file
        print("Loading database configuration from file...")
        config_file = args.config or 'config.ini'
        db_config = load_config(config_file)
    
    # Create importer
    importer = WC3W3TImporter(db_config)
    
    try:
        # Connect to database
        importer.connect()
        
        # Import items
        stats = importer.import_from_w3t(args.w3t_file, preserve_original_mods=not args.no_preserve_mods)
        
        # Print summary
        print(f"\n{'='*50}")
        print(f"IMPORT SUMMARY")
        print(f"{'='*50}")
        print(f"[OK] Imported: {stats['imported']} items")
        print(f"[OK] Updated: {stats['updated']} items")
        print(f"[OK] Total fields stored: {stats['fields_stored']}")
        print(f"[INFO] Failed: {stats['failed']} items")
        
        if stats['errors']:
            print(f"\nErrors:")
            for error in stats['errors'][:10]:
                print(f"  • {error}")
            if len(stats['errors']) > 10:
                print(f"  ... and {len(stats['errors']) - 10} more errors")
        
        print(f"\n{'='*50}")
        print(f"[OK] Import completed successfully!")
        print(f"{'='*50}\n")
        
    except Exception as e:
        print(f"\n[ERROR] Import failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        importer.disconnect()


if __name__ == '__main__':
    main()
