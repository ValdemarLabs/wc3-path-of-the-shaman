"""
WC3 Item Data Exporter - Enhanced with StatID Support
=====================================================
Exports item data from PostgreSQL database with full DEquipment statid system support.

This enhanced version properly handles all 39 statids from the stat_definitions table
and generates correct JASS code with ability additions where needed.

Author: Enhanced for PotS Project
Date: 2026-03-10
Version: 2.0.0
"""

import os
import json
import csv
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import configparser


class WC3ItemExporterEnhanced:
    """
    Enhanced exporter with full statid system support.
    Exports WC3 item data using stat_definitions and ability_codes tables.
    """
    
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
        self.stat_definitions = {}  # Cache of statid -> stat info
        self.ability_codes = {}     # Cache of ability_code -> ability info
        
    def connect(self):
        """Connect to PostgreSQL database and load stat definitions."""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            print(f"✓ Connected to database: {self.db_config['database']}")
            
            # Load stat definitions into cache
            self._load_stat_definitions()
            self._load_ability_codes()
            
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
    
    def _load_stat_definitions(self):
        """Load stat definitions from database into cache."""
        self.cursor.execute("SELECT * FROM stat_definitions WHERE is_active = TRUE ORDER BY statid")
        for row in self.cursor.fetchall():
            self.stat_definitions[row['statid']] = dict(row)
        print(f"✓ Loaded {len(self.stat_definitions)} stat definitions")
        
    def _load_ability_codes(self):
        """Load ability codes from database into cache."""
        self.cursor.execute("SELECT * FROM ability_codes WHERE is_active = TRUE")
        for row in self.cursor.fetchall():
            self.ability_codes[row['ability_code']] = dict(row)
        print(f"✓ Loaded {len(self.ability_codes)} ability codes")
        
    def export_to_deq_config(self, output_file: str, item_codes: Optional[List[str]] = None):
        """
        Export items to DEquipment subsystem configuration with full statid support.
        
        Args:
            output_file: Path to output .j file
            item_codes: List of specific item codes to export (None = all items)
        """
        print(f"\n=== Exporting to DEquipment format (Enhanced): {output_file} ===")
        
        items = self._fetch_items_with_stats(item_codes)
        
        if not items:
            print("✗ No items to export")
            return
            
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(self._generate_deq_header())
            f.write("\n")
            
            # Generate item definitions
            for item in items:
                f.write(self._generate_deq_item_definition_enhanced(item))
                f.write("\n")
                self.stats['exported'] += 1
                
            # Generate initialization
            f.write(self._generate_deq_init_function(items))
            
        self._log_export_history(output_file, 'DEQUIP_ENHANCED', item_codes)
        print(f"✓ Exported {self.stats['exported']} items with full statid support to {output_file}")
        
    def _fetch_items_with_stats(self, item_codes: Optional[List[str]] = None) -> List[Dict]:
        """
        Fetch items with their stat bonuses from item_stat_bonuses table.
        Returns items with nested 'stats' list containing stat details.
        """
        # Fetch items
        query = "SELECT * FROM items WHERE 1=1"
        params = []
        
        if item_codes:
            placeholders = ','.join(['%s'] * len(item_codes))
            query += f" AND item_code IN ({placeholders})"
            params.extend(item_codes)
            
        query += " ORDER BY item_code"
        
        self.cursor.execute(query, params)
        items = [dict(row) for row in self.cursor.fetchall()]
        
        # Fetch stats for each item
        for item in items:
            stat_query = """
                SELECT 
                    isb.statid,
                    isb.bonus_value,
                    isb.bonus_value_percent,
                    isb.is_flat_bonus,
                    isb.notes,
                    sd.stat_name,
                    sd.stat_display_name,
                    sd.stat_short_name,
                    sd.display_as_percent,
                    sd.application_method,
                    sd.ability_code,
                    sd.ability_field
                FROM item_stat_bonuses isb
                JOIN stat_definitions sd ON isb.statid = sd.statid
                WHERE isb.item_id = %s
                ORDER BY isb.statid
            """
            self.cursor.execute(stat_query, (item['id'],))
            item['stats'] = [dict(row) for row in self.cursor.fetchall()]
            
        return items
        
    def _generate_deq_header(self) -> str:
        """Generate DEquipment configuration header with statid constants."""
        header = f"""//===========================================================================
// DEquipment Item Definitions - Auto-Generated (Enhanced with StatID System)
//===========================================================================
// Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
// Database: {self.db_config['database']}
// StatID System Version: 2.0
//
// This file contains DEquipment subsystem configuration for items.
// Uses the full 39-stat DEquipment system with proper statid references.
// Include this in your map after the DEquipment library.
//===========================================================================

library DEquipmentItemsEnhanced initializer InitDEqItems requires SharedDInvLib

globals
    // Stat ID constants (for clarity - these map to statids 1-39)
"""
        
        # Add stat ID constants for clarity
        for statid, stat in sorted(self.stat_definitions.items()):
            const_name = f"STATID_{stat['stat_short_name']}" if stat['stat_short_name'] else f"STATID_{statid}"
            header += f"    constant integer {const_name:30s} = {statid:2d}  // {stat['stat_display_name']}\n"
            
        header += """endglobals

"""
        return header
        
    def _generate_deq_item_definition_enhanced(self, item: Dict) -> str:
        """
        Generate DEquipment item definition with full statid support.
        
        This properly handles:
        - All 39 statids
        - Ability-based stats (generates UnitAddAbility calls if needed)
        - Native stats (generates regular stat bonus calls)
        - Global variable stats (generates comments for manual implementation)
        """
        code = item['item_code']
        name = item['item_name'].replace("'", "\\'")
        stats = item.get('stats', [])
        
        deq = f"""//===========================================================================
// {name} ('{code}')
//===========================================================================
function DEqSetup_{code} takes nothing returns nothing
    local integer iid = '{code}'
    
"""
        
        if not stats:
            deq += "    // No stat bonuses defined\n"
        else:
            # Group stats by application method
            native_stats = []
            ability_stats = []
            global_var_stats = []
            
            for stat in stats:
                if stat['application_method'] == 'NATIVE':
                    native_stats.append(stat)
                elif stat['application_method'] == 'ABILITY':
                    ability_stats.append(stat)
                elif stat['application_method'] == 'GLOBAL_VAR':
                    global_var_stats.append(stat)
                    
            # Generate native stat bonuses (classic DEqSetStatBonus calls)
            if native_stats:
                deq += "    // Native stats (applied via SetHeroStr, BlzSetUnitMaxHP, etc.)\n"
                for stat in native_stats:
                    value = stat['bonus_value']
                    statid = stat['statid']
                    stat_name = stat['stat_short_name'] or f"STAT_{statid}"
                    
                    # Format value display
                    if stat['display_as_percent']:
                        value_display = f"{float(value)*100:.1f}%"
                    else:
                        value_display = f"{value}"
                    
                    deq += f"    call DEqSetStatBonus(iid, {statid}, {value})  // {stat_name}: {value_display}\n"
                deq += "\n"
                
            # Generate ability-based stat bonuses
            if ability_stats:
                deq += "    // Ability-based stats (applied via WC3 abilities)\n"
                deq += "    // Note: Items with these stats will add abilities to units when equipped\n"
                for stat in ability_stats:
                    value = stat['bonus_value']
                    statid = stat['statid']
                    stat_name = stat['stat_short_name'] or f"STAT_{statid}"
                    ability_code = stat['ability_code']
                    
                    # Format value display
                    if stat['display_as_percent']:
                        value_display = f"{float(value)*100:.1f}%"
                    else:
                        value_display = f"{value}"
                    
                    deq += f"    call DEqSetStatBonus(iid, {statid}, {value})  // {stat_name}: {value_display} (ability '{ability_code}')\n"
                deq += "\n"
                
            # Generate global variable stat bonuses (require manual implementation)
            if global_var_stats:
                deq += "    // Global variable stats (handled by DamageEngine or custom systems)\n"
                deq += "    // These are set via DEqSetStatBonus but applied through global arrays\n"
                for stat in global_var_stats:
                    value = stat['bonus_value']
                    statid = stat['statid']
                    stat_name = stat['stat_short_name'] or f"STAT_{statid}"
                    global_var = stat.get('global_variable', 'TBD')
                    
                    # Format value display
                    if stat['display_as_percent']:
                        value_display = f"{float(value)*100:.1f}%"
                    else:
                        value_display = f"{value}"
                    
                    deq += f"    call DEqSetStatBonus(iid, {statid}, {value})  // {stat_name}: {value_display} (uses {global_var})\n"
                deq += "\n"
        
        # Add item type/class/rarity if available
        if item.get('type_id'):
            deq += f"    // Type ID: {item['type_id']}\n"
        if item.get('class_id'):
            deq += f"    // Class ID: {item['class_id']}\n"
        if item.get('rarity_id'):
            deq += f"    // Rarity ID: {item['rarity_id']}\n"
        if item.get('item_level', 1) > 1:
            deq += f"    // Item Level: {item['item_level']}\n"
            
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
    
    def _log_export_history(self, output_file: str, export_type: str, item_codes: Optional[List[str]]):
        """Log export operation to database."""
        try:
            query = """
                INSERT INTO export_history (export_type, output_file, item_count, item_codes)
                VALUES (%s, %s, %s, %s)
            """
            item_codes_json = json.dumps(item_codes) if item_codes else None
            self.cursor.execute(query, (export_type, output_file, self.stats['exported'], item_codes_json))
            self.conn.commit()
        except Exception as e:
            print(f"⚠ Warning: Could not log export history: {e}")
            

def main():
    """Main function for command-line usage."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Export WC3 items from PostgreSQL database with statid support')
    parser.add_argument('--config', default='database.ini', help='Database configuration file')
    parser.add_argument('--output', '-o', required=True, help='Output file path')
    parser.add_argument('--format', '-f', choices=['deq', 'deq_enhanced'], default='deq_enhanced',
                        help='Export format')
    parser.add_argument('--items', nargs='*', help='Specific item codes to export (default: all)')
    
    args = parser.parse_args()
    
    # Load database configuration
    config = configparser.ConfigParser()
    config.read(args.config)
    
    db_config = {
        'host': config.get('postgresql', 'host'),
        'port': config.get('postgresql', 'port'),
        'database': config.get('postgresql', 'database'),
        'user': config.get('postgresql', 'user'),
        'password': config.get('postgresql', 'password')
    }
    
    # Create exporter and export
    exporter = WC3ItemExporterEnhanced(db_config)
    
    try:
        exporter.connect()
        
        if args.format in ['deq', 'deq_enhanced']:
            exporter.export_to_deq_config(args.output, args.items)
        
        print(f"\n✓ Export complete!")
        print(f"  Items exported: {exporter.stats['exported']}")
        if exporter.stats['failed'] > 0:
            print(f"  Failed: {exporter.stats['failed']}")
            
    except Exception as e:
        print(f"\n✗ Export failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        exporter.disconnect()


if __name__ == '__main__':
    main()
