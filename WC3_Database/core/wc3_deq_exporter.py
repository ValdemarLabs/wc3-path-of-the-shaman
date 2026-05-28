"""
WC3 DEquipment Subsystem Exporter
Exports items from PostgreSQL database as DEquipment item definitions
"""

import psycopg2
from datetime import datetime
from typing import Dict, List, Optional
import os


# Slot ID mapping based on item_level ranges from POTS_ItemConcept.xlsx
SLOT_MAPPING = {
    # Level Range: (Slot ID, Slot Name)
    (50, 99): (None, 'Miscellaneous'),     # Charged items, no equipment slot
    (100, 149): (1, 'Head'),               # Helm
    (150, 199): (2, 'Neck'),               # Neck
    (200, 249): (3, 'Shoulders'),          # Shoulders
    (250, 299): (4, 'Back'),               # Back/Cloak
    (300, 349): (5, 'Chest'),              # Chest
    (350, 399): (6, 'Bracers'),            # Bracers/Wrist
    (400, 449): (7, 'Gloves'),             # Gloves/Hands
    (450, 499): (10, 'Belt'),              # Belt/Waist
    (500, 549): (11, 'Legpiece'),          # Legs
    (550, 599): (12, 'Boots'),             # Boots/Feet
    (600, 649): (8, 'Ring'),               # Ring (single slot in PoTs version)
    (650, 699): (None, 'Trinket'),         # Trinket (not enabled in current system)
    (700, 749): (19, '1h'),                # 1h Weapon (Main Hand)
    (750, 799): (19, '2h'),                # 2h Weapon (Main Hand + uses slot 20)
    (800, 849): (19, 'Stave'),             # Stave (Main Hand + uses slot 20)
    (850, 899): (20, 'Shield'),            # Shield (Off Hand)
}


def get_slot_info(item_level: int) -> tuple:
    """Get slot ID and name based on item level."""
    for (min_level, max_level), (slot_id, slot_name) in SLOT_MAPPING.items():
        if min_level <= item_level <= max_level:
            return slot_id, slot_name
    return None, 'Other'


def is_2handed(item_level: int) -> bool:
    """Check if item is 2-handed based on level range."""
    return 750 <= item_level <= 849  # 2h weapons and staves


class DEquipmentExporter:
    """Exports DEquipment item definitions from database."""
    
    def __init__(self, db_config: Dict[str, str]):
        self.db_config = db_config
        self.conn = None
        
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
            
    def fetch_equipment_items(self) -> List[Dict]:
        """Fetch all equipment items (level >= 50) from database."""
        query = """
        SELECT 
            i.item_code,
            i.item_name,
            i.item_level,
            i.gold_cost,
            i.rarity_id,
            r.rarity_name,
            i.is_droppable,
            i.is_sellable,
            i.is_pawnable
        FROM items i
        LEFT JOIN item_rarities r ON r.id = i.rarity_id
        WHERE i.item_level >= 50
        ORDER BY i.item_level, i.item_name;
        """
        
        cursor = self.conn.cursor()
        cursor.execute(query)
        
        columns = [desc[0] for desc in cursor.description]
        items = []
        for row in cursor.fetchall():
            items.append(dict(zip(columns, row)))
            
        cursor.close()
        print(f"✓ Fetched {len(items)} equipment items")
        return items
        
    def fetch_item_stats(self, item_code: str) -> List[Dict]:
        """Fetch stats granted by an item."""
        query = """
        SELECT 
            stat_name,
            bonus_value
        FROM v_item_stats
        WHERE item_code = %s
        ORDER BY stat_name;
        """
        
        cursor = self.conn.cursor()
        cursor.execute(query, (item_code,))
        
        columns = [desc[0] for desc in cursor.description]
        stats = []
        for row in cursor.fetchall():
            stats.append(dict(zip(columns, row)))
            
        cursor.close()
        return stats
        
    def fetch_item_abilities(self, item_code: str) -> List[Dict]:
        """Fetch abilities granted by an item."""
        query = """
        SELECT 
            ia.ability_code,
            ia.ability_name,
            1 as ability_level
        FROM item_abilities ia
        JOIN items i ON i.id = ia.item_id
        WHERE i.item_code = %s
        ORDER BY ia.ability_name;
        """
        
        cursor = self.conn.cursor()
        cursor.execute(query, (item_code,))
        
        columns = [desc[0] for desc in cursor.description]
        abilities = []
        for row in cursor.fetchall():
            abilities.append(dict(zip(columns, row)))
            
        cursor.close()
        return abilities
        
    def generate_jass_header(self) -> str:
        """Generate JASS file header."""
        return f"""//===========================================================================
// DEquipment Item Definitions - Auto-Generated from Database
//===========================================================================
// Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
// Database: {self.db_config['database']}
// Source: PostgreSQL wc3_pots database
//
// This file contains DEquipment subsystem configuration for all equipment items.
// Equipment items are those with item_level >= 50.
//
// Usage: Include this library in your map after the DEquipment library
//===========================================================================

library DEquipmentItemDefinitions initializer Init requires DEquipment

function DEqPreDefineItemsHere takes nothing returns nothing
//local integer goldCost = 0

// =======================================================================
// ====== Auto-Generated Item Definitions ({datetime.now().strftime('%Y-%m-%d')})
// =======================================================================

"""

    def generate_item_definition(self, item: Dict, stats: List[Dict], abilities: List[Dict]) -> str:
        """Generate JASS code for a single item definition."""
        item_code = item['item_code']
        item_name = item['item_name']
        item_level = item['item_level']
        gold_cost = item['gold_cost'] or 0
        
        # Get slot information
        slot_id, slot_name = get_slot_info(item_level)
        is_2h = is_2handed(item_level)
        
        lines = []
        lines.append(f"// {item_name} (Level {item_level})")
        
        # Define allowed slot
        if slot_id is not None:
            lines.append(f"call DEqItemTypeDefineAllowedSlotId('{item_code}', {slot_id})")
            
        # Mark as 2-handed if applicable
        if is_2h:
            lines.append(f"call DEqItemTypeDefineAs2Handed('{item_code}')")
            
        # Add stats
        for stat in stats:
            stat_name = stat['stat_name']
            value = stat['bonus_value'] or 0
            if value != 0:
                lines.append(f"call DEqItemTypeDefineStatGrantedByName('{item_code}', \"{stat_name}\", {value})")
                
        # Add abilities
        for ability in abilities:
            ability_code = ability['ability_code']
            ability_level = ability['ability_level'] or 1
            lines.append(f"call DEqItemTypeDefineAbilityGranted('{item_code}', '{ability_code}', {ability_level})")
            
        # Set gold value
        if gold_cost > 0:
            lines.append(f"call DEqItemTypeDefineGoldValue('{item_code}', {gold_cost})")
            
        lines.append("")  # Empty line between items
        return "\n".join(lines)
        
    def generate_jass_footer(self) -> str:
        """Generate JASS file footer."""
        return """
endfunction


private function Init takes nothing returns nothing
call TriggerRegisterTimerEvent( trg_DEqPreDefinedItems, 0.1, false )
call TriggerAddAction(trg_DEqPreDefinedItems, function DEqPreDefineItemsHere)
endfunction

endlibrary
"""
        
    def export_to_file(self, output_path: str):
        """Export all equipment items to JASS file."""
        print(f"\nExporting to: {output_path}")
        
        # Fetch data
        items = self.fetch_equipment_items()
        
        # Generate JASS code
        jass_code = self.generate_jass_header()
        
        item_count = 0
        for item in items:
            item_code = item['item_code']
            stats = self.fetch_item_stats(item_code)
            abilities = self.fetch_item_abilities(item_code)
            
            # Only export if item has slot, stats, or abilities
            slot_id, _ = get_slot_info(item['item_level'])
            if slot_id is not None or stats or abilities or item['gold_cost']:
                jass_code += self.generate_item_definition(item, stats, abilities)
                item_count += 1
                
        jass_code += self.generate_jass_footer()
        
        # Write to file
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(jass_code)
            
        print(f"✓ Exported {item_count} items to {output_path}")
        print(f"✓ File size: {os.path.getsize(output_path)} bytes")
        
        # Generate summary
        self._print_export_summary(items)
        
    def _print_export_summary(self, items: List[Dict]):
        """Print summary of exported items by slot."""
        print("\n" + "="*60)
        print("EXPORT SUMMARY")
        print("="*60)
        
        slot_counts = {}
        for item in items:
            _, slot_name = get_slot_info(item['item_level'])
            slot_counts[slot_name] = slot_counts.get(slot_name, 0) + 1
            
        for slot_name in sorted(slot_counts.keys()):
            count = slot_counts[slot_name]
            print(f"{slot_name:20s}: {count:3d} items")
            
        print("="*60)
        print(f"{'TOTAL':20s}: {len(items):3d} items")
        print("="*60)


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
    
    # Output file path with timestamp
    timestamp = datetime.now().strftime('%Y-%m%d-%H%M')
    output_filename = f'DEquipmentItemDefinitions_{timestamp}.j'
    output_dir = r'H:\Pelit\PotS_JASS\WC3_Export\DEquipmentItemDefinitions'
    
    # Create directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    output_path = os.path.join(output_dir, output_filename)
    
    print("="*60)
    print("WC3 DEQUIPMENT SUBSYSTEM EXPORTER")
    print("="*60)
    
    try:
        exporter = DEquipmentExporter(db_config)
        exporter.connect()
        exporter.export_to_file(output_path)
        exporter.disconnect()
        
        print("\n✓ Export completed successfully!")
        
    except Exception as e:
        print(f"\n✗ Export failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()
