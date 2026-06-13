"""
WC3 .w3t Object Data Exporter
==============================
Exports items from PostgreSQL database to Warcraft 3 Reforged .w3t binary format.

This is the reverse of wc3_w3t_parser.py - writes database items back to .w3t files
that can be imported into World Editor.

Author: Generated for PotS Project
Date: 2026-03-11
Version: 1.4.0 - CRITICAL FIX: Use count+array format for unknown fields (War3Net compatible)
                 - Format v3 uses: unkCount + unk[] array, not fixed unknowns
                 - Both original & custom objects use: unkCount=1, unk=[0]
"""

import struct
import os
import psycopg2
from datetime import datetime
from typing import Dict, List, Optional, Any
from wc3_w3t_parser import WC3ObjectDataParser


class WC3W3TExporter:
    """Exports items from database to .w3t binary format."""
    
    # Field type codes
    TYPE_INT = 0
    TYPE_REAL = 1
    TYPE_UNREAL = 2
    TYPE_STRING = 3
    
    # Map database columns to WC3 field codes
    # Based on successful import mapping from wc3_w3t_parser.py matching items table schema
    FIELD_MAP = {
        # Core identification & text
        'item_name': ('unam', TYPE_STRING),
        'tooltip': ('utip', TYPE_STRING),
        'tooltip_extended': ('utub', TYPE_STRING),
        'extended_tooltip': ('utub', TYPE_STRING),  # Alternative column name
        'description': ('ides', TYPE_STRING),
        'hotkey': ('uhot', TYPE_STRING),
        
        # Costs & level
        'gold_cost': ('igol', TYPE_INT),
        'lumber_cost': ('ilum', TYPE_INT),
        'item_level': ('ilev', TYPE_INT),
        'old_level': ('ilvo', TYPE_INT),
        'required_level': ('ilvo', TYPE_INT),  # Alternative mapping
        
        # Charges & Stacks
        'max_charges': ('iuse', TYPE_INT),
        'max_stack': ('ista', TYPE_INT),
        
        # Hit points
        'hit_points': ('ihtp', TYPE_INT),
        
        # Combat stats (not directly exported - stored in item_stat_bonuses)
        # 'damage_min', 'damage_max', 'attack_speed', etc. - handled separately
        
        # Boolean flags
        'is_droppable': ('idro', TYPE_INT),
        'is_sellable': ('isel', TYPE_INT),
        'is_pawnable': ('ipaw', TYPE_INT),
        'is_powerup': ('ipow', TYPE_INT),
        'dropped_on_death': ('idrp', TYPE_INT),
        'drops_on_death': ('idrp', TYPE_INT),  # Alternative column name
        'is_perishable': ('iper', TYPE_INT),
        'actively_used': ('iusa', TYPE_INT),
        'use_automatically': ('iusa', TYPE_INT),  # Alternative column name
        'pick_random': ('iprn', TYPE_INT),
        'ignore_cooldown': ('iicd', TYPE_INT),
        
        # WC3 Classification & Morph
        'wc3_classification': ('icla', TYPE_STRING),
        'morph_target': ('imor', TYPE_STRING),
        'armor_type': ('iamn', TYPE_STRING),
        
        # Abilities (CRITICAL - this was missing!)
        'wc3_abilities': ('iabi', TYPE_STRING),
        
        # Visual/Art
        'icon_path': ('iico', TYPE_STRING),
        'model_path': ('ifil', TYPE_STRING),
        'scale': ('isca', TYPE_REAL),
        'selection_size': ('issc', TYPE_REAL),
        'tint_red': ('iclr', TYPE_INT),
        'tint_green': ('iclg', TYPE_INT),
        'tint_blue': ('iclb', TYPE_INT),
        # tint_alpha - no direct WC3 field
        
        # Button position
        'button_pos_x': ('ubpx', TYPE_INT),
        'button_pos_y': ('ubpy', TYPE_INT),
        
        # Stock settings
        'stock_initial': ('isit', TYPE_INT),  # Stock initial
        'stock_start_delay': ('isst', TYPE_INT),  # Stock start delay
        'stock_replenish': ('istr', TYPE_INT),  # Stock replenish interval
        'stock_max': ('isto', TYPE_INT),
        
        # Priority
        'priority': ('ipri', TYPE_INT),
        
        # Cooldown
        'cooldown_group': ('icid', TYPE_STRING),
        # cooldown_duration - not a direct WC3 field, handled by cooldown_group
        
        # Requirements (if available)
        'wc3_requirements': ('ureq', TYPE_STRING),
        'wc3_requirements_amount': ('urqa', TYPE_STRING),
    }
    
    # Fields that MUST be exported for items that lack other modifications
    # Only export these if the item has very few other fields
    REQUIRED_FIELDS = ['item_name', 'icon_path']
    
    def __init__(self, db_config: Dict[str, str], original_w3t_path: Optional[str] = None):
        self.db_config = db_config
        self.conn = None
        self.original_w3t_path = original_w3t_path
        self.original_modifications = {}  # Cache of original item modifications
        self.original_table_items = set()  # Items that go in original objects table
        self.item_base_ids = {}  # Base item IDs for custom objects
        
    def load_original_modifications(self):
        """Load modifications from original .w3t file (for abilities and other data not in DB)."""
        if not self.original_w3t_path or not os.path.exists(self.original_w3t_path):
            print("  No original .w3t file provided - abilities will not be exported")
            return
            
        print(f"  Loading original modifications from: {os.path.basename(self.original_w3t_path)}")
        parser = WC3ObjectDataParser(self.original_w3t_path)
        data = parser.parse()
        
        # Index modifications by item code and track table placement
        for obj in data['original_objects']:
            item_code = obj['new_id']
            self.original_table_items.add(item_code)
            self.original_modifications[item_code] = {}
            
            for mod in obj['modifications']:
                self.original_modifications[item_code][mod['id']] = {
                    'type': mod['type'],
                    'value': mod['value']
                }
        
        for obj in data['custom_objects']:
            item_code = obj['new_id']
            # Store base item ID for custom objects
            self.item_base_ids[item_code] = obj['original_id']
            self.original_modifications[item_code] = {}
            
            for mod in obj['modifications']:
                self.original_modifications[item_code][mod['id']] = {
                    'type': mod['type'],
                    'value': mod['value']
                }
                
        print(f"  ✓ Loaded modifications for {len(self.original_modifications)} items")
        print(f"    - {len(self.original_table_items)} in original table")
        print(f"    - {len(self.item_base_ids)} in custom table")
        
    def connect(self):
        """Connect to PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(
                host=self.db_config['host'],
                port=self.db_config['port'],
                database=self.db_config['database'],
                user=self.db_config['user'],
                password=self.db_config.get('password', '')
            )
            print(f"✓ Connected to database: {self.db_config['database']}")
        except Exception as e:
            print(f"✗ Database connection failed: {e}")
            raise
            
    def disconnect(self):
        """Disconnect from database."""
        if self.conn:
            self.conn.close()
            
    def fetch_items(self, item_codes: Optional[List[str]] = None) -> List[Dict]:
        """Fetch items from database."""
        cursor = self.conn.cursor()
        
        if item_codes:
            placeholders = ','.join(['%s'] * len(item_codes))
            query = f"""
                SELECT *
                FROM items
                WHERE item_code IN ({placeholders})
                ORDER BY item_code
            """
            cursor.execute(query, item_codes)
        else:
            query = "SELECT * FROM items ORDER BY item_code"
            cursor.execute(query)
            
        columns = [desc[0] for desc in cursor.description]
        items = []
        for row in cursor.fetchall():
            items.append(dict(zip(columns, row)))
            
        cursor.close()
        print(f"✓ Fetched {len(items)} items from database")
        return items
        
    def _write_string(self, f, value: str):
        """Write null-terminated string."""
        if value is not None and value:
            # Handle string values that might be bytes or strings
            if isinstance(value, str):
                f.write(value.encode('utf-8', errors='ignore'))
            else:
                f.write(value)
        f.write(b'\x00')
        
    def _write_int(self, f, value: int):
        """Write 4-byte integer."""
        f.write(struct.pack('<i', value))
        
    def _write_uint(self, f, value: int):
        """Write 4-byte unsigned integer."""
        f.write(struct.pack('<I', value))
        
    def _write_real(self, f, value: float):
        """Write 4-byte float."""
        f.write(struct.pack('<f', value))
        
    def _write_field_id(self, f, field_code: str):
        """Write 4-character field ID."""
        if len(field_code) != 4:
            raise ValueError(f"Field code must be 4 characters: {field_code}")
        f.write(field_code.encode('ascii'))
        
    def _write_modification(self, f, field_code: str, field_type: int, value: Any, end_token: bytes):
        """Write a single modification."""
        # Field ID (4 bytes)
        self._write_field_id(f, field_code)
        
        # Type (4 bytes)
        self._write_int(f, field_type)
        
        # Value (type-dependent)
        if field_type == self.TYPE_INT:
            # Boolean values in database should be converted to int
            if isinstance(value, bool):
                self._write_int(f, 1 if value else 0)
            else:
                self._write_int(f, int(value) if value is not None else 0)
                
        elif field_type == self.TYPE_REAL or field_type == self.TYPE_UNREAL:
            self._write_real(f, float(value) if value is not None else 0.0)
            
        elif field_type == self.TYPE_STRING:
            self._write_string(f, str(value) if value else '')
            
        # End marker (4 bytes) - should be old_id for original objects, 0 for custom
        f.write(end_token)
        
    def _write_object(self, f, item: Dict, is_custom: bool):
        """Write a single object."""
        item_code = item['item_code']
        
        # Original ID (base item) and New ID have different meanings:
        # - Original table: Modifying existing Blizzard items (old_id=item_code, new_id=NULL)
        # - Custom table: Creating new items based on original (old_id=base, new_id=item_code)
        
        if is_custom:
            # Custom objects: old_id is base item, new_id is new item code
            base_item = self.item_base_ids.get(item_code, '\x00\x00\x00\x00')
            old_id = base_item.ljust(4, '\x00').encode('ascii')[:4]
            new_id = item_code.ljust(4, '\x00').encode('ascii')[:4]
        else:
            # Original table: old_id is the item being modified, new_id is NULL
            old_id = item_code.ljust(4, '\x00').encode('ascii')[:4]
            new_id = b'\x00\x00\x00\x00'  # NULL for original objects!
        
        f.write(old_id)
        f.write(new_id)
        
        # Reforged v3: Unknown array (count + values)
        # Format is: unkCount (4 bytes), then unkCount * 4 bytes of values
        # Based on War3Net and original file analysis:
        # - Original & Custom objects both use: unkCount=1, unk=[0]
        unk_count = 1
        unk_values = [0]
        self._write_int(f, unk_count)
        for unk_val in unk_values:
            self._write_int(f, unk_val)
        
        # Collect modifications
        modifications = []
        
        # Different logic for custom vs original items
        # Custom items need ALL fields defined so WC3 sees them as complete objects
        # Original items only need changed fields to override Blizzard defaults
        fields_in_original = set()
        if item_code in self.original_modifications:
            fields_in_original = set(self.original_modifications[item_code].keys())
        
        for db_field, (wc3_field, field_type) in self.FIELD_MAP.items():
            value = item.get(db_field)

            if db_field == 'is_powerup':
                classification = str(item.get('wc3_classification') or '')
                value = bool(value) or bool(item.get('use_automatically')) or classification.lower() == 'powerup'

            if db_field == 'use_automatically':
                classification = str(item.get('wc3_classification') or '')
                if bool(item.get('actively_used')) or bool(item.get('is_powerup')) or classification.lower() == 'powerup':
                    continue
            
            # Always include required fields
            is_required = db_field in self.REQUIRED_FIELDS
            
            if is_custom:
                # CUSTOM ITEMS: Export ALL fields with explicit defaults (even NULL from DB)  
                # This makes WC3 World Editor show all ~40+ fields in Object Editor
                # Use default values when database has NULL
                if field_type == self.TYPE_STRING:
                    # Export ALL strings for custom items (empty string for NULL)
                    if value is None or value == '':
                        value = ''
                    # ALWAYS export for custom items, even empty strings
                    modifications.append((wc3_field, field_type, value))
                elif field_type == self.TYPE_INT:
                    # Export 0 for NULL numeric values
                    if value is None:
                        value = 0
                    modifications.append((wc3_field, field_type, value))
                elif field_type == self.TYPE_REAL or field_type == self.TYPE_UNREAL:
                    # Export 0.0 for NULL real values
                    if value is None:
                        value = 0.0
                    modifications.append((wc3_field, field_type, value))
            else:
                # ORIGINAL ITEMS: Only export changed/required fields
                # Don't override Blizzard defaults unnecessarily
                if value is not None:
                    if is_required:
                        modifications.append((wc3_field, field_type, value))
                    elif wc3_field in fields_in_original:
                        modifications.append((wc3_field, field_type, value))
                    elif value != 0 and value != '' and value != False:
                        # Export non-default values
                        modifications.append((wc3_field, field_type, value))
        
        # Add fields from original .w3t file that aren't in database
        if item_code in self.original_modifications:
            orig_mods = self.original_modifications[item_code]
            
            # Fields to copy from original (abilities, etc.)
            fields_to_copy = [
                'iabi',  # Abilities
                'ubpx',  # Button Position X
                'ubpy',  # Button Position Y
                'iicd',  # Ignore Cooldown
                'iprn',  # Pick Random
                'imor',  # Morph
                'ureq',  # Requirements
                'urqa',  # Requirements Amount
                'isit',  # Stock Initial
                'isto',  # Stock Max (might be in DB too)
                'istr',  # Stock Regen
                'isst',  # Stock Start
            ]
            
            for field_id in fields_to_copy:
                if field_id in orig_mods:
                    # Check if we already have this field from database
                    if not any(wc3_field == field_id for wc3_field, _, _ in modifications):
                        modifications.append((
                            field_id,
                            orig_mods[field_id]['type'],
                            orig_mods[field_id]['value']
                        ))
        
        # Write modification count
        self._write_int(f, len(modifications))
        
        # Prepare end token for modifications
        # Original objects: end_token = old_id (item_code)
        # Custom objects: end_token = 0x00000000
        if is_custom:
            end_token = b'\x00\x00\x00\x00'
        else:
            # End token is the old_id (item_code) as 4-byte value
            end_token = item_code.ljust(4, '\x00').encode('ascii')[:4]
        
        # Write modifications
        for field_code, field_type, value in modifications:
            # Set defaults for tooltip fields if empty
            if field_code == 'utip' and not value:
                value = ''  # Empty tooltip - basic
            elif field_code == 'utub' and not value:
                value = ''  # Empty ubertip - extended
                
            self._write_modification(f, field_code, field_type, value, end_token)
            
    def export_to_w3t(self, output_path: str, item_codes: Optional[List[str]] = None):
        """
        Export items to .w3t file.
        
        Args:
            output_path: Path to output .w3t file
            item_codes: Optional list of item codes to export (exports all if None)
        """
        print(f"\n{'='*60}")
        print("WC3 .W3T EXPORTER")
        print(f"{'='*60}")
        print(f"Output: {output_path}")
        
        # Load original modifications if available
        self.load_original_modifications()
        
        # Fetch items
        items = self.fetch_items(item_codes)
        
        if not items:
            print("✗ No items to export")
            return
            
        # Determine which are custom vs original based on what was in original .w3t
        custom_items = []
        original_items = []
        
        for item in items:
            code = item['item_code'].strip()
            # Use table placement from original .w3t file
            if code in self.original_table_items:
                original_items.append(item)
            else:
                custom_items.append(item)
        
        print(f"  Original items (modified defaults): {len(original_items)}")
        print(f"  Custom items (new objects): {len(custom_items)}")
        
        # Create output directory
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Write .w3t file
        with open(output_path, 'wb') as f:
            # Version (4 bytes) - Reforged v3
            self._write_int(f, 3)
            
            # Original objects count
            self._write_int(f, len(original_items))
            
            # Write original objects
            for item in original_items:
                self._write_object(f, item, is_custom=False)
                
            # Custom objects count
            self._write_int(f, len(custom_items))
            
            # Write custom objects
            for item in custom_items:
                self._write_object(f, item, is_custom=True)
                
        file_size = os.path.getsize(output_path)
        print(f"✓ Exported {len(items)} items to {output_path}")
        print(f"✓ File size: {file_size:,} bytes")
        print(f"{'='*60}\n")


def main():
    """Main export function."""
    
    # Database configuration
    db_config = {
        'host': '127.0.0.1',
        'port': '5432',
        'database': 'wc3_pots',
        'user': 'postgres',
        'password': '009900'
    }
    
    # Path to original .w3t file (for abilities and other unmapped fields)
    original_w3t = r'H:\Pelit\PotS_JASS\WC3_Export\ItemSettings-2026-03-10-1826\POTS_ItemSettings_2026-0310-1826.w3t'
    
    # Output file path with timestamp
    timestamp = datetime.now().strftime('%Y-%m%d-%H%M')
    output_filename = f'POTS_ItemSettings_{timestamp}.w3t'
    output_dir = r'H:\Pelit\PotS_JASS\WC3_Export\toWC3'
    
    # Create directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    output_path = os.path.join(output_dir, output_filename)
    
    try:
        exporter = WC3W3TExporter(db_config, original_w3t_path=original_w3t)
        exporter.connect()
        
        # Export all items (or specify item_codes=['I6CF', 'hval', ...] for specific items)
        exporter.export_to_w3t(output_path)
        
        exporter.disconnect()
        
        print("✓ Export completed successfully!")
        print(f"\nTo use this file:")
        print(f"1. Open World Editor")
        print(f"2. Go to Object Editor → Items")
        print(f"3. File → Import Object Data")
        print(f"4. Select: {output_path}")
        
    except Exception as e:
        print(f"\n✗ Export failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()
