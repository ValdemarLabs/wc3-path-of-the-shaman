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
import sys
import re
import psycopg2
from datetime import datetime
from typing import Dict, List, Optional, Any
from wc3_w3t_parser import WC3ObjectDataParser

# Force UTF-8 encoding for stdout/stderr to support Unicode characters
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8')


class WC3W3TExporter:
    """Exports items from database to .w3t binary format."""

    LEGACY_COLOR_CODE_RE = re.compile(r'\|c00([0-9A-Fa-f]{6})')
    
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
        'description': ('ides', TYPE_STRING),
        'hotkey': ('uhot', TYPE_STRING),
        
        # Costs & level
        'gold_cost': ('igol', TYPE_INT),
        'lumber_cost': ('ilum', TYPE_INT),
        'item_level': ('ilev', TYPE_INT),
        'old_level': ('ilvo', TYPE_INT),  # Old level field
        
        # Charges & Stacks
        'max_charges': ('iuse', TYPE_INT),
        'max_stack': ('ista', TYPE_INT),
        
        # Combat & Classification
        'armor_type': ('iamn', TYPE_STRING),
        'wc3_classification': ('icla', TYPE_STRING),
        'wc3_abilities': ('iabi', TYPE_STRING),  # Comma-separated ability codes
        'hit_points': ('ihtp', TYPE_INT),
        
        # Boolean flags
        'is_droppable': ('idro', TYPE_INT),
        'is_sellable': ('isel', TYPE_INT),
        'is_pawnable': ('ipaw', TYPE_INT),
        'is_powerup': ('ipow', TYPE_INT),
        'is_perishable': ('iper', TYPE_INT),
        'actively_used': ('iusa', TYPE_INT),
        'ignore_cooldown': ('iicd', TYPE_INT),
        'pick_random': ('iprn', TYPE_INT),
        'dropped_on_death': ('idrp', TYPE_INT),
        
        # Visual/Art
        'icon_path': ('iico', TYPE_STRING),
        'model_path': ('ifil', TYPE_STRING),
        'scale': ('isca', TYPE_REAL),
        'selection_size': ('issc', TYPE_REAL),
        'tint_red': ('iclr', TYPE_INT),
        'tint_green': ('iclg', TYPE_INT),
        'tint_blue': ('iclb', TYPE_INT),
        
        # Stock & Priority
        'priority': ('ipri', TYPE_INT),
        'stock_initial': ('isit', TYPE_INT),  # Stock initial
        'stock_start_delay': ('isst', TYPE_INT),  # Stock start delay  
        'stock_max': ('isto', TYPE_INT),
        'stock_replenish': ('istr', TYPE_INT),  # Stock replenish interval
        
        # Cooldown & Morph
        'cooldown_group': ('icid', TYPE_STRING),
        'morph_target': ('imor', TYPE_STRING),
        
        # Requirements
        'wc3_requirements': ('ureq', TYPE_STRING),
        'wc3_requirements_amount': ('urqa', TYPE_STRING),
        
        # Button Position
        'button_pos_x': ('ubpx', TYPE_INT),
        'button_pos_y': ('ubpy', TYPE_INT),
    }
    
    # Fields that MUST be exported for items that lack other modifications
    # tooltip_extended and description are critical for item tooltips
    # Only export these if they have actual non-empty values
    # Note: item_name is NOT required - we skip "Unknown Item" names to let WC3 use defaults
    REQUIRED_FIELDS = ['tooltip_extended', 'description']
    
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
                
        print(f"  [OK] Loaded modifications for {len(self.original_modifications)} items")
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
            print(f"[OK] Connected to database: {self.db_config['database']}")
        except Exception as e:
            print(f"[ERROR] Database connection failed: {e}")
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
        print(f"[OK] Fetched {len(items)} items from database")
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

    def _normalize_wc3_string(self, value: Any) -> Any:
        """Normalize legacy WC3 color codes before writing object strings."""
        if not isinstance(value, str) or '|c00' not in value:
            return value

        return self.LEGACY_COLOR_CODE_RE.sub(r'|cFF\1', value)
        
    def _write_object(self, f, item: Dict, is_custom: bool):
        """Write a single object."""
        item_code = item['item_code']
        
        # Original ID (base item) and New ID have different meanings:
        # - Original table: Modifying existing Blizzard items (old_id=item_code, new_id=NULL)
        # - Custom table: Creating new items based on original (old_id=base, new_id=item_code)
        
        if is_custom:
            # Custom objects: old_id is base item, new_id is new item code
            # Get base_id from database column (preferred) or fallback to lookup
            base_item = item.get('base_id') or self.item_base_ids.get(item_code, '\x00\x00\x00\x00')
            if not base_item or base_item == '\x00\x00\x00\x00':
                # Fallback: use a generic consumable item as base
                base_item = 'bzbe'  # Cheese (commonly used base item)
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
        
        # Only export fields that were in the original .w3t to avoid over-export
        # This prevents exporting thousands of default values that WC3 doesn't expect
        fields_in_original = set()
        if item_code in self.original_modifications:
            fields_in_original = set(self.original_modifications[item_code].keys())
        
        for db_field, (wc3_field, field_type) in self.FIELD_MAP.items():
            # Get value from database or use default for NULL
            value = item.get(db_field)

            if db_field == 'is_powerup':
                classification = str(item.get('wc3_classification') or '')
                value = bool(value) or bool(item.get('use_automatically')) or classification.lower() == 'powerup'
            
            # Skip "Unknown Item" names - let WC3 use default name
            if db_field == 'item_name' and value and value.startswith('Unknown Item'):
                continue
            
            # For CUSTOM items, export ALL fields (even if NULL, use defaults)
            # WC3 requires explicit values for all properties of custom items
            # This makes World Editor show all ~40+ fields in Object Editor
            if is_custom:
                # SKIP empty/null fields instead of writing empty strings
                # This allows WC3 to use default values from base item
                if value is None or value == '' or value == 0:
                    # Only skip if it's truly empty - keep explicit zeros for some fields
                    if field_type == self.TYPE_STRING and (value is None or value == ''):
                        continue  # Skip empty strings
                    elif (field_type == self.TYPE_INT or field_type == self.TYPE_REAL or field_type == self.TYPE_UNREAL):
                        # For numbers, only skip if NULL (not if explicitly 0)
                        if value is None:
                            continue
                
                # Export field
                modifications.append((wc3_field, field_type, value if value is not None else 0))
            else:
                # For ORIGINAL items (modifying Blizzard items), only export non-NULL non-default values
                if value is not None and value != '' and value != 0:
                    # Always include required fields (but only if non-empty)
                    is_required = db_field in self.REQUIRED_FIELDS
                    
                    # Check if value is non-default
                    is_non_default = False
                    if field_type == self.TYPE_STRING and value:
                        is_non_default = True
                    elif field_type == self.TYPE_INT and value != 0:
                        is_non_default = True
                    elif field_type == self.TYPE_REAL and value != 0.0:
                        is_non_default = True
                    elif field_type == self.TYPE_UNREAL and value != 0.0:
                        is_non_default = True
                    
                    if is_required or wc3_field in fields_in_original or is_non_default:
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
        
        # --- BEGIN CUSTOM LOGIC FOR copy_base_abilities & cooldown_group ---
        # If copy_base_abilities is True, always copy iabi from base item (original Blizzard item)
        copy_base_abilities = item.get('copy_base_abilities', False)
        base_item_code = item.get('base_id')
        base_mods = None
        if base_item_code and base_item_code in self.original_modifications:
            base_mods = self.original_modifications[base_item_code]

        # Remove any iabi from modifications if we will override it
        if copy_base_abilities and base_mods and 'iabi' in base_mods:
            modifications = [m for m in modifications if m[0] != 'iabi']
            modifications.append(('iabi', base_mods['iabi']['type'], base_mods['iabi']['value']))

        # If cooldown_group (icid) is not set, copy from base item if available
        has_cooldown = any(m[0] == 'icid' for m in modifications)
        if not has_cooldown and base_mods and 'icid' in base_mods:
            modifications.append(('icid', base_mods['icid']['type'], base_mods['icid']['value']))
        # --- END CUSTOM LOGIC ---
        
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

            if field_type == self.TYPE_STRING and value:
                value = self._normalize_wc3_string(value)
            
            # Debug: Log critical field writes
            if field_code == 'utub' and value:
                value_preview = value[:80] if len(value) > 80 else value
                print(f"    [DEBUG] Writing utub for {item_code}: {len(value)} chars - {value_preview}...")
            elif field_code == 'ifil' and value:
                print(f"    [DEBUG] Writing model_path (ifil) for {item_code}: {value}")
                
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
            print("[ERROR] No items to export")
            return
            
        # Determine which are custom vs original based on base_id column
        # Custom items have a base_id (the Blizzard item they're based on)
        # Original items have NULL base_id (they ARE the Blizzard item being modified)
        custom_items = []
        original_items = []
        
        for item in items:
            # Check base_id column to determine if custom
            if item.get('base_id') is not None and item.get('base_id'):
                custom_items.append(item)
            else:
                original_items.append(item)
        
        print(f"  Original items (modified defaults): {len(original_items)}")
        print(f"  Custom items (new objects): {len(custom_items)}")
        
        # Create output directory if needed
        output_dir = os.path.dirname(output_path)
        if output_dir:  # Only create if dirname is not empty
            os.makedirs(output_dir, exist_ok=True)
        
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
        print(f"[OK] Exported {len(items)} items to {output_path}")
        print(f"[OK] File size: {file_size:,} bytes")
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
        
        print("[OK] Export completed successfully!")
        print(f"\nTo use this file:")
        print(f"1. Open World Editor")
        print(f"2. Go to Object Editor -> Items")
        print(f"3. File -> Import Object Data")
        print(f"4. Select: {output_path}")
        
    except Exception as e:
        print(f"\n[ERROR] Export failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()
