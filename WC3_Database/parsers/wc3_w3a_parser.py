"""
WC3 .w3a Ability Data Parser
=============================
Parses Warcraft 3 binary ability data files (.w3a).

Format specification based on WC3 modding documentation.
Supports both Classic and Reforged formats (versions 1-3).

Author: Generated for PotS Project
Date: 2026-03-11
Version: 1.0.0
"""

import struct
import os
from typing import Dict, List, Tuple, Any, Optional


class WC3AbilityDataParser:
    """Parser for WC3 .w3a ability binary files."""
    
    # Field type codes
    TYPE_INT = 0
    TYPE_REAL = 1
    TYPE_UNREAL = 2
    TYPE_STRING = 3
    
    def __init__(self, file_path: str):
        """
        Initialize parser with file path.
        
        Args:
            file_path: Path to .w3a file
        """
        self.file_path = file_path
        self.version = None
        self.original_objects = []  # Modified base abilities
        self.custom_objects = []    # New custom abilities
        
    def parse(self) -> Dict[str, Any]:
        """
        Parse the .w3a ability file.
        
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
            print(f"Parsing .w3a version {self.version} format")
            
            # Check if this is Reforged format (version 3+)
            self.is_reforged = self.version >= 3
            
            # Read original abilities (modified game defaults)
            original_table_count = struct.unpack('<I', f.read(4))[0]
            print(f"Reading {original_table_count} modified base abilities...")
            for i in range(original_table_count):
                try:
                    obj = self._read_object(f, is_custom=False)
                    if obj['modifications']:  # Only add if it has modifications
                        self.original_objects.append(obj)
                except EOFError:
                    print(f"Reached end of file at ability {i+1}/{original_table_count}")
                    break
                    
            # Read custom abilities (new abilities)
            try:
                custom_table_count = struct.unpack('<I', f.read(4))[0]
                print(f"Reading {custom_table_count} custom abilities...")
                for i in range(custom_table_count):
                    try:
                        obj = self._read_object(f, is_custom=True)
                        self.custom_objects.append(obj)
                    except EOFError:
                        print(f"Reached end of file at custom ability {i+1}/{custom_table_count}")
                        break
            except struct.error:
                print("No custom abilities section found (reached end of file)")
                
        return {
            'version': self.version,
            'original_objects': self.original_objects,
            'custom_objects': self.custom_objects
        }
        
    def _read_object(self, f, is_custom: bool) -> Dict[str, Any]:
        """
        Read a single ability object from file.
        
        Classic .w3a: oldId(4) + newId(4) + modCount(4) + mods[]
        Reforged v3: oldId(4) + newId(4) + unknown1(4) + unknown2(4) + modCount(4) + mods[]
        """
        obj = {}
        obj['modifications'] = []
        
        # Read old ID (4 bytes) - base ability being modified
        obj['original_id'] = f.read(4).decode('ascii', errors='ignore').rstrip('\x00')
        
        # Read new ID (4 bytes) - this ability's ID  
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
            raise EOFError(f"Parser out of sync - mod_count too high")
        
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
        
        .w3a abilities use level-based modifications (War3Net confirmed format):
        Format: id(4) + type(4) + level(4) + pointer(4) + value(varies) + sanityCheck(4)
        
        - id: Modification ID as 4-char ASCII string (e.g., 'anam', 'ansf')
        - type: Value type (INT/REAL/UNREAL/STRING)
        - level: Level this modification applies to (0 = base, 1-5 = levels)
        - pointer: Data pointer/column (usually 0, sometimes 1 or 2)
        - value: The actual value (varies by type)
        - sanityCheck: Always present (4 bytes) - often contains base ability ID
        """
        mod = {}
        
        # Read modification ID as 4-byte ASCII string (e.g., 'anam', 'ansf')
        mod['id'] = f.read(4).decode('ascii', errors='ignore').rstrip('\x00')
        
        # Read variable type (4 bytes)
        var_type = struct.unpack('<I', f.read(4))[0]
        mod['type'] = var_type
        
        # Read level (4 bytes) - abilities have level-based data
        mod['level'] = struct.unpack('<I', f.read(4))[0]
        
        # Read data pointer/column (4 bytes) - usually 0, sometimes 1 or 2
        mod['data_pointer'] = struct.unpack('<I', f.read(4))[0]
        
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
            # Unknown type - try to read as int
            mod['value'] = struct.unpack('<I', f.read(4))[0]
            
        # Read sanity check (4 bytes) - ALWAYS PRESENT in all versions
        sanity_bytes = f.read(4)
        mod['sanity_check'] = struct.unpack('<I', sanity_bytes)[0]
        
        # DEBUG output for first few modifications
        if f.tell() < 200:
            print(f"DEBUG: id={mod['id']}, type={mod['type']}, level={mod['level']}, ptr={mod['data_pointer']}, value={mod['value']}, sanity={mod['sanity_check']}, pos_after={f.tell()}")
        
        return mod
        
    def to_abilities_dict(self) -> List[Dict[str, Any]]:
        """
        Convert parsed data to ability dictionary format for database import.
        
        Returns:
            List of ability dictionaries with standardized field names
        """
        abilities = []
        
        # Process all abilities (both original and custom)
        all_objects = self.original_objects + self.custom_objects
        
        for obj in all_objects:
            ability = {
                'ability_code': obj['new_id'],
                'base_id': obj['original_id'],
                'modifications': {},
                'data_fields': {}  # Level-dependent fields
            }
            
            # Map WC3 ability field IDs to database fields
            for mod in obj['modifications']:
                field_id = mod['id']
                value = mod['value']
                level = mod.get('level', 0)
                data_ptr = mod.get('data_pointer', 0)
                
                # Create a key for level-dependent fields
                level_key = f"{field_id}_L{level}" if level > 0 else field_id
                
                # Map common WC3 ability fields (based on Object Editor field IDs)
                field_map = {
                    # Core text fields
                    'anam': 'ability_name',           # Name
                    'atp1': 'tooltip',                # Tooltip - Normal (level 1)
                    'aub1': 'tooltip_extended',       # Tooltip - Extended (level 1)
                    'aret': 'research_tooltip',       # Research Tooltip
                    'arut': 'research_tooltip_extended', # Research Ubertip
                    'ahky': 'hotkey',                 # Hotkey
                    'auho': 'unhotkey',               # Un-hotkey
                    'arhk': 'research_hotkey',        # Research Hotkey
                    
                    # Levels & Requirements
                    'alev': 'levels',                 # Levels
                    'arlv': 'required_level',         # Required Hero Level
                    'alsk': 'level_skip',             # Level Skip Requirement
                    
                    # Costs
                    'amcs': 'mana_cost',              # Mana Cost (level 1)
                    'agar': 'gold_cost',              # Gold Cost
                    'alar': 'lumber_cost',            # Lumber Cost
                    
                    # Cooldown & Timers
                    'acdn': 'cooldown',               # Cooldown (level 1)
                    'acas': 'cast_time',              # Cast Time (level 1)
                    'adur': 'duration',               # Duration - Normal (level 1)
                    'ahdu': 'hero_duration',          # Duration - Hero (level 1)
                    
                    # Ranges & Areas
                    'aran': 'cast_range',             # Cast Range (level 1)
                    'aare': 'area_of_effect',         # Area of Effect (level 1)
                    
                    # Effects (level 1 defaults)
                    'adps': 'damage_per_second',      # DPS
                    
                    # Flags
                    'aher': 'is_hero_ability',        # Hero Ability
                    'aite': 'is_item_ability',        # Item Ability
                    'achd': 'checkdep',               # Check Dependencies
                    'avis': 'visible',                # Visible
                    
                    # Targeting
                    'atar': 'targets_allowed',        # Targets Allowed
                    
                    # Visual/Art
                    'aart': 'icon_path',              # Icon - Normal
                    'arar': 'icon_research',          # Icon - Research
                    'abpx': 'button_pos_x',           # Button Position (X)
                    'abpy': 'button_pos_y',           # Button Position (Y)
                    'arbx': 'button_pos_research_x',  # Research Button X
                    'arby': 'button_pos_research_y',  # Research Button Y
                    
                    'aeat': 'effect_art',             # Art - Effect
                    'atat': 'effect_target',          # Art - Target
                    'acat': 'effect_caster',          # Art - Caster
                    'asat': 'effect_special',         # Art - Special
                    'amat': 'missile_art',            # Art - Missile
                    'amsp': 'missile_speed',          # Missile Speed
                    'amar': 'missile_arc',            # Missile Arc
                    'amho': 'missile_homing',         # Missile Homing
                    
                    # Sound
                    'aefs': 'effect_sound',           # Sound - Effect
                    
                    # Requirements
                    'areq': 'requirements',           # Requirements
                    'arqa': 'requirements_levels',    # Requirements - Levels
                }
                
                # Store base-level fields in main ability dict
                if level == 0 and field_id in field_map:
                    ability[field_map[field_id]] = value
                elif level == 1 and field_id in field_map and field_map[field_id] not in ability:
                    # Store level 1 as default if no base level exists
                    ability[field_map[field_id]] = value
                
                # Store ALL level-dependent data in data_fields
                if level > 0:
                    if field_id not in ability['data_fields']:
                        ability['data_fields'][field_id] = {}
                    ability['data_fields'][field_id][f'level_{level}'] = value
                    
                # Store raw modification for reference
                ability['modifications'][level_key] = {
                    'value': value,
                    'type': mod['type'],
                    'level': level,
                    'data_pointer': data_ptr
                }
                
            abilities.append(ability)
            
        return abilities
        
    def print_summary(self):
        """Print summary of parsed data."""
        print(f"\n=== W3A Parse Summary ===")
        print(f"File: {os.path.basename(self.file_path)}")
        print(f"Version: {self.version}")
        print(f"Modified base abilities: {len(self.original_objects)}")
        print(f"Custom abilities: {len(self.custom_objects)}")
        print(f"Total abilities: {len(self.original_objects) + len(self.custom_objects)}")
        
        # Show sample of custom abilities
        if self.custom_objects:
            print(f"\nSample custom abilities:")
            for obj in self.custom_objects[:5]:
                name = next((m['value'] for m in obj['modifications'] if m['id'] == 'anam'), obj['new_id'])
                print(f"  {obj['new_id']}: {name}")
                
        if len(self.custom_objects) > 5:
            print(f"  ... and {len(self.custom_objects) - 5} more")


def main():
    """Test parser with a .w3a file."""
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python wc3_w3a_parser.py <path_to_w3a_file>")
        sys.exit(1)
        
    file_path = sys.argv[1]
    
    try:
        parser = WC3AbilityDataParser(file_path)
        data = parser.parse()
        parser.print_summary()
        
        # Convert to abilities dict
        abilities = parser.to_abilities_dict()
        print(f"\n[OK] Converted to {len(abilities)} ability dictionaries")
        
        # Show a sample ability with full details
        if abilities:
            print(f"\n=== Sample Ability (Full Details) ===")
            sample = abilities[0]
            print(f"Code: {sample['ability_code']}")
            print(f"Name: {sample.get('ability_name', 'N/A')}")
            print(f"Base: {sample.get('base_id', 'N/A')}")
            print(f"Tooltip: {sample.get('tooltip', 'N/A')[:100]}...")
            print(f"Hero Ability: {sample.get('is_hero_ability', False)}")
            print(f"Item Ability: {sample.get('is_item_ability', False)}")
            print(f"Data Fields (by level): {len(sample.get('data_fields', {}))}")
            
    except Exception as e:
        print(f"\n[ERROR] Error parsing file: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
