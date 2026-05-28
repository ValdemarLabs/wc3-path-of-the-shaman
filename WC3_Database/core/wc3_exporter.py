"""
WC3 Item Data Exporter
======================
Exports item data from PostgreSQL database to various formats including JASS code.

Supported export formats:
- JASS code for WC3 maps
- DEquipment/DInventory subsystem format
- CSV for spreadsheets
- JSON for web/API use
- WC3 .txt object data format

Author: Generated for PotS Project
Date: 2026-03-10
Version: 1.0.0
"""

import os
import json
import csv
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import configparser


class WC3ItemExporter:
    """Exports WC3 item data from PostgreSQL database."""
    
    def __init__(self, db_config: Dict[str, str]):
        """
        Initialize exporter with database configuration.
        
        Args:
            db_config: Dictionary with keys: host, port, database, user, password
        """
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.stats = {
            'exported': 0,
            'failed': 0,
            'errors': []
        }
        
    def connect(self):
        """Connect to PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
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
        
    def export_to_jass(self, output_file: str, item_codes: Optional[List[str]] = None):
        """
        Export items to JASS code format for WC3 maps.
        
        Args:
            output_file: Path to output .j file
            item_codes: List of specific item codes to export (None = all items)
        """
        print(f"\n=== Exporting to JASS: {output_file} ===")
        
        items = self._fetch_items(item_codes)
        
        if not items:
            print("✗ No items to export")
            return
            
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(self._generate_jass_header())
            f.write("\n")
            
            # Generate CreateItem functions
            for item in items:
                f.write(self._generate_jass_item_function(item))
                f.write("\n")
                self.stats['exported'] += 1
                
            # Generate initialization function
            f.write(self._generate_jass_init_function(items))
            
        self._log_export_history(output_file, 'JASS', item_codes)
        print(f"✓ Exported {self.stats['exported']} items to {output_file}")
        
    def export_to_deq_config(self, output_file: str, item_codes: Optional[List[str]] = None):
        """
        Export items to DEquipment subsystem configuration format.
        
        Args:
            output_file: Path to output .j file
            item_codes: List of specific item codes to export (None = all items)
        """
        print(f"\n=== Exporting to DEquipment format: {output_file} ===")
        
        items = self._fetch_items(item_codes, deq_only=True)
        
        if not items:
            print("✗ No DEquipment-compatible items to export")
            return
            
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(self._generate_deq_header())
            f.write("\n")
            
            # Generate item definitions
            for item in items:
                f.write(self._generate_deq_item_definition(item))
                f.write("\n")
                self.stats['exported'] += 1
                
            # Generate initialization
            f.write(self._generate_deq_init_function(items))
            
        self._log_export_history(output_file, 'DEQUIP', item_codes)
        print(f"✓ Exported {self.stats['exported']} items to {output_file}")
        
    def export_to_dinv_rarity(self, output_file: str, item_codes: Optional[List[str]] = None):
        """
        Export items to DInventory rarity configuration format.
        
        Args:
            output_file: Path to output .j file
            item_codes: List of specific item codes to export (None = all items)
        """
        print(f"\n=== Exporting to DInventory Rarity format: {output_file} ===")
        
        items = self._fetch_items(item_codes, dinv_only=True)
        
        if not items:
            print("✗ No DInventory-compatible items to export")
            return
            
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(self._generate_dinv_rarity_header())
            f.write("\n")
            
            # Generate rarity definitions
            f.write(self._generate_dinv_rarity_definitions(items))
            
        self._log_export_history(output_file, 'DINV_RARITY', item_codes)
        print(f"✓ Exported {len(items)} item rarities to {output_file}")
        
    def export_to_csv(self, output_file: str, item_codes: Optional[List[str]] = None):
        """
        Export items to CSV format.
        
        Args:
            output_file: Path to output .csv file
            item_codes: List of specific item codes to export (None = all items)
        """
        print(f"\n=== Exporting to CSV: {output_file} ===")
        
        items = self._fetch_items(item_codes)
        
        if not items:
            print("✗ No items to export")
            return
            
        with open(output_file, 'w', encoding='utf-8', newline='') as f:
            if items:
                # Get all unique keys from all items
                all_keys = set()
                for item in items:
                    all_keys.update(item.keys())
                all_keys = sorted(all_keys)
                
                writer = csv.DictWriter(f, fieldnames=all_keys)
                writer.writeheader()
                
                for item in items:
                    # Clean item data for CSV
                    cleaned_item = {}
                    for key, value in item.items():
                        if isinstance(value, (dict, list)):
                            cleaned_item[key] = json.dumps(value)
                        else:
                            cleaned_item[key] = value
                    writer.writerow(cleaned_item)
                    self.stats['exported'] += 1
                    
        self._log_export_history(output_file, 'CSV', item_codes)
        print(f"✓ Exported {self.stats['exported']} items to {output_file}")
        
    def export_to_json(self, output_file: str, item_codes: Optional[List[str]] = None, pretty: bool = True):
        """
        Export items to JSON format.
        
        Args:
            output_file: Path to output .json file
            item_codes: List of specific item codes to export (None = all items)
            pretty: Whether to use pretty printing (default: True)
        """
        print(f"\n=== Exporting to JSON: {output_file} ===")
        
        items = self._fetch_items(item_codes)
        
        if not items:
            print("✗ No items to export")
            return
            
        # Convert datetime objects to strings
        json_items = []
        for item in items:
            json_item = {}
            for key, value in item.items():
                if isinstance(value, datetime):
                    json_item[key] = value.isoformat()
                else:
                    json_item[key] = value
            json_items.append(json_item)
            self.stats['exported'] += 1
            
        with open(output_file, 'w', encoding='utf-8') as f:
            if pretty:
                json.dump(json_items, f, indent=2, ensure_ascii=False)
            else:
                json.dump(json_items, f, ensure_ascii=False)
                
        self._log_export_history(output_file, 'JSON', item_codes)
        print(f"✓ Exported {self.stats['exported']} items to {output_file}")
        
    def _fetch_items(self, item_codes: Optional[List[str]] = None, 
                     deq_only: bool = False, dinv_only: bool = False) -> List[Dict]:
        """Fetch items from database."""
        query = "SELECT * FROM v_items_complete WHERE 1=1"
        params = []
        
        if deq_only:
            query += " AND deq_compatible = TRUE"
        if dinv_only:
            query += " AND dinv_compatible = TRUE"
            
        if item_codes:
            placeholders = ','.join(['%s'] * len(item_codes))
            query += f" AND item_code IN ({placeholders})"
            params.extend(item_codes)
            
        query += " ORDER BY item_code"
        
        self.cursor.execute(query, params)
        return self.cursor.fetchall()
        
    def _generate_jass_header(self) -> str:
        """Generate JASS file header."""
        return f"""//===========================================================================
// WC3 Items - Auto-Generated from PostgreSQL Database
//===========================================================================
// Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
// Database: {self.db_config['database']}
// 
// This file contains item creation functions for Warcraft 3 maps.
// Use these functions to create items with all their properties set.
//===========================================================================

library ItemsDatabase initializer Init

globals
    // Item handle storage (optional - for quick access)
    hashtable ItemDB_Hash = InitHashtable()
endglobals
"""
        
    def _generate_jass_item_function(self, item: Dict) -> str:
        """Generate JASS function for a single item."""
        code = item['item_code']
        name = item['item_name'].replace("'", "\\'")
        
        jass = f"""//===========================================================================
// {name} ('{code}')
//===========================================================================
function CreateItem_{code} takes real x, real y returns item
    local item it = CreateItem('{code}', x, y)
    
    // Basic properties
    call BlzSetItemName(it, "{name}")
"""
        
        # Add tooltip if exists
        if item.get('tooltip'):
            tooltip = item['tooltip'].replace('"', '\\"').replace('\n', '|n')
            jass += f'    call BlzSetItemTooltip(it, "{tooltip}")\n'
            
        # Add extended tooltip if exists
        if item.get('extended_tooltip'):
            ext_tooltip = item['extended_tooltip'].replace('"', '\\"').replace('\n', '|n')
            jass += f'    call BlzSetItemExtendedTooltip(it, "{ext_tooltip}")\n'
            
        # Add icon if exists
        if item.get('icon_path'):
            jass += f'    call BlzSetItemIconPath(it, "{item["icon_path"]}")\n'
            
        # Set item properties
        if item.get('max_charges', 0) > 0:
            jass += f"    call SetItemCharges(it, {item['max_charges']})\n"
            
        # Set item flags
        if not item.get('is_droppable', True):
            jass += "    call SetItemDroppable(it, false)\n"
        if not item.get('is_sellable', True):
            jass += "    call SetItemPawnable(it, false)\n"
        if item.get('is_invulnerable', False):
            jass += "    call SetItemInvulnerable(it, true)\n"
            
        jass += "    return it\nendfunction\n"
        return jass
        
    def _generate_jass_init_function(self, items: List[Dict]) -> str:
        """Generate JASS initialization function."""
        jass = """//===========================================================================
// Initialization
//===========================================================================
function Init takes nothing returns nothing
    // Items initialized
    // You can preload or cache items here if needed
endfunction

endlibrary
"""
        return jass
        
    def _generate_deq_header(self) -> str:
        """Generate DEquipment configuration header."""
        return f"""//===========================================================================
// DEquipment Item Definitions - Auto-Generated
//===========================================================================
// Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
// Database: {self.db_config['database']}
//
// This file contains DEquipment subsystem configuration for items.
// Include this in your map after the DEquipment library.
//===========================================================================

library DEquipmentItems initializer InitDEqItems requires DConfigurationArea

globals
endglobals
"""
        
    def _generate_deq_item_definition(self, item: Dict) -> str:
        """Generate DEquipment item definition."""
        code = item['item_code']
        name = item['item_name'].replace("'", "\\'")
        
        deq = f"""//===========================================================================
// {name} ('{code}')
//===========================================================================
function DEqSetup_{code} takes nothing returns nothing
    local integer iid = '{code}'
    
"""
        
        # Add equipment slot
        if item.get('equipment_slot'):
            slot = item['equipment_slot']
            deq += f"    // Equipment Slot: {slot}\n"
            
        # Add stats
        if item.get('strength_bonus', 0) != 0:
            deq += f"    call DEqSetStatBonus(iid, STAT_STR, {item['strength_bonus']})\n"
        if item.get('agility_bonus', 0) != 0:
            deq += f"    call DEqSetStatBonus(iid, STAT_AGI, {item['agility_bonus']})\n"
        if item.get('intelligence_bonus', 0) != 0:
            deq += f"    call DEqSetStatBonus(iid, STAT_INT, {item['intelligence_bonus']})\n"
            
        # Add armor
        if item.get('armor', 0) != 0:
            deq += f"    call DEqSetStatBonus(iid, STAT_ARMOR, {item['armor']})\n"
            
        # Add damage
        if item.get('damage_min', 0) != 0 or item.get('damage_max', 0) != 0:
            dmg_min = item.get('damage_min', 0)
            dmg_max = item.get('damage_max', 0)
            deq += f"    call DEqSetDamageBonus(iid, {dmg_min}, {dmg_max})\n"
            
        # Add rarity
        if item.get('rarity_level') is not None:
            deq += f"    call DEqSetRarity(iid, {item['rarity_level']})\n"
            
        # Add item level
        if item.get('item_level', 1) > 1:
            deq += f"    call DEqSetItemLevel(iid, {item['item_level']})\n"
            
        deq += "endfunction\n"
        return deq
        
    def _generate_deq_init_function(self, items: List[Dict]) -> str:
        """Generate DEquipment initialization function."""
        jass = """//===========================================================================
// Initialize all DEquipment items
//===========================================================================
function InitDEqItems takes nothing returns nothing
"""
        
        for item in items:
            code = item['item_code']
            jass += f"    call DEqSetup_{code}()\n"
            
        jass += """endfunction

endlibrary
"""
        return jass
        
    def _generate_dinv_rarity_header(self) -> str:
        """Generate DInventory rarity configuration header."""
        return f"""//===========================================================================
// DInventory Item Rarity Definitions - Auto-Generated
//===========================================================================
// Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
// Database: {self.db_config['database']}
//
// This file contains DInventory rarity configuration for items.
//===========================================================================

library DInventoryItemRarities initializer InitDInvRarities requires DItemRarity

globals
endglobals
"""
        
    def _generate_dinv_rarity_definitions(self, items: List[Dict]) -> str:
        """Generate DInventory rarity definitions."""
        jass = """//===========================================================================
// Set item rarities
//===========================================================================
function InitDInvRarities takes nothing returns nothing
    local integer rarity
    
"""
        
        for item in items:
            code = item['item_code']
            name = item['item_name'].replace("'", "\\'")
            rarity_level = item.get('rarity_level', 0)
            
            jass += f"    // {name}\n"
            jass += f"    call DInvSetRarity('{code}', {rarity_level})\n\n"
            
        jass += """endfunction

endlibrary
"""
        return jass
        
    def _log_export_history(self, destination_file: str, format_type: str, item_codes: Optional[List[str]]):
        """Log export operation to history table."""
        query = """
            INSERT INTO export_history 
            (destination_file, items_exported, export_format, export_type, item_codes, notes)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        
        export_type = 'SELECTION' if item_codes else 'ALL'
        notes = "\n".join(self.stats['errors']) if self.stats['errors'] else None
        
        self.cursor.execute(query, (
            destination_file,
            self.stats['exported'],
            format_type,
            export_type,
            item_codes,
            notes
        ))
        self.conn.commit()
        
    def print_summary(self):
        """Print export summary."""
        print("\n" + "="*60)
        print("EXPORT SUMMARY")
        print("="*60)
        print(f"✓ Items Exported: {self.stats['exported']}")
        print(f"✗ Items Failed:   {self.stats['failed']}")
        
        if self.stats['errors']:
            print("\nErrors:")
            for error in self.stats['errors']:
                print(f"  - {error}")
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
    
    parser = argparse.ArgumentParser(description='Export WC3 item data from PostgreSQL')
    parser.add_argument('--output', '-o', required=True, help='Output file path')
    parser.add_argument('--format', '-f', choices=['jass', 'deq', 'dinv', 'csv', 'json'], 
                       default='jass', help='Export format (default: jass)')
    parser.add_argument('--items', '-i', nargs='+', help='Specific item codes to export')
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
        
    # Export data
    exporter = WC3ItemExporter(db_config)
    
    try:
        exporter.connect()
        
        if args.format == 'jass':
            exporter.export_to_jass(args.output, args.items)
        elif args.format == 'deq':
            exporter.export_to_deq_config(args.output, args.items)
        elif args.format == 'dinv':
            exporter.export_to_dinv_rarity(args.output, args.items)
        elif args.format == 'csv':
            exporter.export_to_csv(args.output, args.items)
        elif args.format == 'json':
            exporter.export_to_json(args.output, args.items)
            
        exporter.print_summary()
        
    except Exception as e:
        print(f"\n✗ Export failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        exporter.disconnect()


if __name__ == '__main__':
    main()
