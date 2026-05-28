"""
WC3 .w3t/.w3a/.w3o Object Data Parser
=====================================
Parses Warcraft 3 binary object data files (.w3t for items, .w3a for abilities, .w3o for units).

Format specification based on WC3 modding documentation.

Author: Generated for PotS Project
Date: 2026-03-10
Version: 1.0.0
"""

import struct
import os
from typing import Dict, List, Tuple, Any, Optional


class WC3ObjectDataParser:
    """Parser for WC3 binary object data files."""
    
    # Field type codes
    TYPE_INT = 0
    TYPE_REAL = 1
    TYPE_UNREAL = 2
    TYPE_STRING = 3
    
    def __init__(self, file_path: str):
        """
        Initialize parser with file path.
        
        Args:
            file_path: Path to .w3t/.w3a/.w3o file
        """
        self.file_path = file_path
        self.version = None
        self.original_objects = []
        self.custom_objects = []
        
    def parse(self) -> Dict[str, Any]:
        """
        Parse the object data file.
        
        Returns:
            Dictionary with parsed data: {
                'version': int,
                'original_objects': List[Dict],
                'custom_objects': List[Dict]
            }
        """
        if not os.path.exists(self.file_path):
            raise FileNotFoundError(f"File not found: {self.file_path}")
            
        with open(self.file_path, 'rb') as f:
            # Read version (4 bytes, little-endian int)
            self.version = struct.unpack('<I', f.read(4))[0]
            print(f"Parsing version {self.version} format")
            
            # Check if this is Reforged format (version 3+)
            self.is_reforged = self.version >= 3
            
            # Read original objects (modified game defaults)
            original_table_count = struct.unpack('<I', f.read(4))[0]
            print(f"Reading {original_table_count} original objects...")
            for i in range(original_table_count):
                try:
                    obj = self._read_object(f, is_custom=False)
                    if obj['modifications']:  # Only add if it has modifications
                        self.original_objects.append(obj)
                except EOFError:
                    print(f"Reached end of file at object {i+1}/{original_table_count}")
                    break
                    
            # Read custom objects (new objects)
            try:
                custom_table_count = struct.unpack('<I', f.read(4))[0]
                print(f"Reading {custom_table_count} custom objects...")
                for i in range(custom_table_count):
                    try:
                        obj = self._read_object(f, is_custom=True)
                        self.custom_objects.append(obj)
                    except EOFError:
                        print(f"Reached end of file at custom object {i+1}/{custom_table_count}")
                        break
            except struct.error:
                print("No custom objects section found (reached end of file)")
                
        return {
            'version': self.version,
            'original_objects': self.original_objects,
            'custom_objects': self.custom_objects
        }
        
    def _read_object(self, f, is_custom: bool) -> Dict[str, Any]:
        """
        Read a single object from file.
        Classic W3T: oldId(4) + newId(4) + modCount(4) + mods[]
        Reforged v3: oldId(4) + newId(4) + unknown1(4) + unknown2(4) + modCount(4) + mods[]
        """
        obj = {}
        obj['modifications'] = []
        
        # Read old ID (4 bytes) - base object being modified
        obj['original_id'] = f.read(4).decode('ascii', errors='ignore').rstrip('\x00')
        
        # Read new ID (4 bytes) - this object's ID
        obj['new_id'] = f.read(4).decode('ascii', errors='ignore').rstrip('\x00')
        
        # If new_id is null, use original_id
        if not obj['new_id'] or obj['new_id'] == '\x00\x00\x00\x00':
            obj['new_id'] = obj['original_id']
        
        # Reforged v3+ has TWO extra 4-byte fields before modification count
        if self.version >= 3:
            f.read(4)  # Unknown field 1
            f.read(4)  # Unknown field 2
            
        # Read modification count (4 bytes)
        mod_count_bytes = f.read(4)
        if len(mod_count_bytes) < 4:
            raise EOFError(f"Unexpected end of file while reading modification count")
        mod_count = struct.unpack('<I', mod_count_bytes)[0]
        
        # Sanity check
        if mod_count > 1000:
            print(f"Warning: Unreasonable modification count {mod_count} for {obj['new_id']}")
            raise EOFError(f"Parser out of sync")
        
        # Read modifications
        for i in range(mod_count):
            try:
                mod = self._read_modification(f)
                obj['modifications'].append(mod)
            except Exception as e:
                print(f"Warning: Error reading modification {i+1}/{mod_count} for {obj['new_id']}: {e}")
                raise
            
        return obj
        
    def _read_modification(self, f) -> Dict[str, Any]:
        """
        Read a single modification entry.
        Format: id(4) + type(4) + value(varies) + end_marker(4)  
        Note: .w3t uses useOptionalInts=false, no level/dataPointer
        """
        mod = {}
        
        # Read modification ID (4 bytes)
        mod['id'] = f.read(4).decode('ascii', errors='ignore')
        
        # Read variable type (4 bytes)
        var_type = struct.unpack('<I', f.read(4))[0]
        mod['type'] = var_type
        
        # Read value based on type
        if var_type == self.TYPE_INT:
            mod['value'] = struct.unpack('<i', f.read(4))[0]
        elif var_type == self.TYPE_REAL or var_type == self.TYPE_UNREAL:
            mod['value'] = struct.unpack('<f', f.read(4))[0]
        elif var_type == self.TYPE_STRING:
            # Read null-terminated string
            chars = []
            while True:
                c = f.read(1)
                if not c or c == b'\x00':
                    break
                chars.append(c)
            mod['value'] = b''.join(chars).decode('utf-8', errors='ignore')
        else:
            # Unknown type
            mod['value'] = struct.unpack('<I', f.read(4))[0]
            
        # Read end marker (4 bytes)
        f.read(4)
        
        return mod
        
    def to_items_dict(self) -> List[Dict[str, Any]]:
        """
        Convert parsed data to item dictionary format for database import.
        
        Returns:
            List of item dictionaries with standardized field names
        """
        items = []
        
        # Process all objects (both original and custom)
        all_objects = self.original_objects + self.custom_objects
        
        for obj in all_objects:
            item = {
                'item_code': obj['new_id'],
                'original_item_code': obj['original_id'],
                'modifications': {}
            }
            
            # Map WC3 field IDs to database fields
            for mod in obj['modifications']:
                field_id = mod['id']
                value = mod['value']
                
                # Map common WC3 item fields (based on Object Editor field IDs)
                field_map = {
                    # Text fields
                    'unam': 'item_name',           # Name
                    'utip': 'tooltip',             # Tooltip - Basic
                    'utub': 'tooltip_extended',    # Tooltip - Extended (Ubertip)
                    'ides': 'description',         # Description
                    'uhot': 'hotkey',              # Hotkey
                    
                    # Stats - Cost & Level
                    'igol': 'gold_cost',           # Gold Cost
                    'ilum': 'lumber_cost',         # Lumber Cost
                    'ilev': 'item_level',          # Level
                    'ilvo': 'old_level',           # Level (Unclassified/oldLevel)
                    'ihtp': 'hit_points',          # Hit Points
                    
                    # Stats - Charges & Stacks
                    'iuse': 'max_charges',         # Number of Charges (uses)
                    'ista': 'max_stack',           # Max Stacks (stackMax)
                    
                    # Stats - Boolean flags
                    'iusa': 'actively_used',       # Actively Used (usable)
                    'idro': 'is_droppable',        # Can Be Dropped (droppable)
                    'isel': 'is_sellable',         # Can Be Sold By Merchants (sellable)
                    'ipaw': 'is_pawnable',         # Can Be Sold To Merchants (pawnable)
                    'idrp': 'dropped_on_death',    # Dropped When Carrier Dies (drop) - FIXED from idnp
                    'iper': 'is_perishable',       # Perishable
                    'ipow': 'is_powerup',          # Use Automatically When Acquired (powerup)
                    'imor': 'morph_target',        # Valid Target For Transformation (morph)
                    'iicd': 'ignore_cooldown',     # Ignore Cooldown (ignoreCD)
                    'iprn': 'pick_random',         # Include As Random Choice (pickRandom)
                    
                    # Classification
                    'icla': 'wc3_classification',  # Classification (class) - Permanent/Charged/etc - FIXED
                    'iamn': 'armor_type',          # Armor Type - FIXED from iarm (4 chars!)
                    
                    # Abilities & Cooldown
                    'iabi': 'wc3_abilities',       # Abilities (abiList) - FIXED to use wc3_abilities column
                    'icid': 'cooldown_group',      # Cooldown Group (cooldownID)
                    
                    # Visual/Art fields
                    'iico': 'icon_path',           # Interface Icon (Art)
                    'ifil': 'model_path',          # Model Used (file)
                    'isca': 'scale',               # Scaling Value (scale)
                    'issc': 'selection_size',      # Selection Size - Editor (selSize)
                    'iclr': 'tint_red',            # Tinting Color 1 (Red) (colorR)
                    'iclg': 'tint_green',          # Tinting Color 2 (Green) (colorG)
                    'iclb': 'tint_blue',           # Tinting Color 3 (Blue) (colorB)
                    'ubpx': 'button_pos_x',        # Button Position (X) (Buttonpos)
                    'ubpy': 'button_pos_y',        # Button Position (Y) (Buttonpos)
                    
                    # Stock system
                    'ipri': 'priority',            # Priority (prio)
                    'isit': 'stock_initial',       # Stock Initial After Start Delay (stockInitial)
                    'isto': 'stock_max',           # Stock Maximum (stockMax)
                    'istr': 'stock_replenish',     # Stock Replenish Interval (stockRegen) - FIXED from isrr
                    'isst': 'stock_start_delay',   # Stock Start Delay (stockStart)
                    
                    # Requirements
                    'ureq': 'wc3_requirements',    # Requirements (Requires) - FIXED to use wc3_requirements
                    'urqa': 'wc3_requirements_amount', # Requirements - Levels (Requiresamount) - FIXED
                }
                
                if field_id in field_map:
                    item[field_map[field_id]] = value
                    
                # Store raw modification for reference
                item['modifications'][field_id] = {
                    'value': value,
                    'type': mod['type']
                }
                
            items.append(item)
            
        return items
        
    def print_summary(self):
        """Print summary of parsed data."""
        print(f"\n=== W3T Parse Summary ===")
        print(f"File: {os.path.basename(self.file_path)}")
        print(f"Version: {self.version}")
        print(f"Original objects modified: {len(self.original_objects)}")
        print(f"Custom objects: {len(self.custom_objects)}")
        print(f"Total objects: {len(self.original_objects) + len(self.custom_objects)}")
        
        # Show sample of custom objects
        if self.custom_objects:
            print(f"\nSample custom items:")
            for obj in self.custom_objects[:5]:
                name = next((m['value'] for m in obj['modifications'] if m['id'] == 'unam'), obj['new_id'])
                print(f"  {obj['new_id']}: {name}")
                
        if len(self.custom_objects) > 5:
            print(f"  ... and {len(self.custom_objects) - 5} more")


def main():
    """Test parser with a .w3t file."""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python wc3_w3t_parser.py <file.w3t>")
        sys.exit(1)
        
    file_path = sys.argv[1]
    
    parser = WC3ObjectDataParser(file_path)
    
    try:
        data = parser.parse()
        parser.print_summary()
        
        print("\n=== Converting to item format ===")
        items = parser.to_items_dict()
        
        print(f"\nConverted {len(items)} items")
        
        # Show details of first item
        if items:
            print(f"\nFirst item details:")
            item = items[0]
            print(f"  Code: {item['item_code']}")
            for key, value in item.items():
                if key not in ['modifications', 'item_code']:
                    print(f"  {key}: {value}")
                    
    except Exception as e:
        print(f"Error parsing file: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
