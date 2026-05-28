#!/usr/bin/env python3
"""
DEquipment Item Definitions Exporter
Exports items from PostgreSQL database to JASS library format for DEquipment system
"""

import sys
import psycopg2
from datetime import datetime

# Database connection settings
DB_CONFIG = {
    'host': '127.0.0.1',
    'port': 5432,
    'database': 'wc3_pots',
    'user': 'postgres',
    'password': '009900'
}

# Stat name mappings from database to DEquipment
STAT_MAPPINGS = {
    'Strength': 'Strength',
    'Agility': 'Agility',
    'Intelligence': 'Intelligence',
    'Hit Points': 'Hitpoints',
    'HP Regen': 'HPS',
    'Mana': 'Mana',
    'Mana Regen': 'Mana Regen Per Sec',
    'Melee Attack Damage': 'Melee Damage',
    'Ranged Attack Damage': 'Ranged Damage',
    'Spell Power': 'Spell Power',
    'Attack Speed': 'Attack Speed',
    'Critical Strike Chance': 'Critical Chance',
    'Critical Strike Damage': 'Critical Damage',
    'Lifesteal %': 'Lifesteal Pct',
    'Spell Vamp %': 'Spell Vamp Pct',
    'Cleave %': 'Cleave Pct',
    'Armor': 'Armor',
    'Armor %': 'Armor Pct',
    'Dodge': 'Dodge',
    'Evasion': 'Dodge',  # legacy mapping for old data
    'Block Chance': 'Block Chance',
    'Magic Resistance %': 'Magic Resist Pct',
    'Move Speed': 'Movement Speed',
    'Move Speed %': 'MoveSPD Pct',
    'Sight Range': 'Sight Range',
    'Attack Range': 'Attack Range'
}

# Slot name mappings
SLOT_MAPPINGS = {
    'Head': 'Head',
    'Neck': 'Neck',
    'Shoulder': 'Shoulder',
    'Chest': 'Chest',
    'Back': 'Back',
    'Bracers': 'Bracers',
    'Gloves': 'Gloves',
    'Ring': 'Ring',
    'Belt': 'Belt',
    'Legs': 'Legs',
    'Boots': 'Boots',
    'MainHand': 'MainHand',
    'OffHand': 'OffHand',
    'Two-Handed': 19  # Special slot ID for 2handed weapons
}


def convert_item_code(code):
    """Convert 4-char item code to JASS format 'I###' or use as-is"""
    if code and len(code) == 4:
        # WC3 format: 4 characters (e.g., 'i0a5', 'hcun', 'I6CF')
        # DEquipment uses both raw codes and 'XXXX' format
        return f"'{code.lower()}'"  # Use lowercase for consistency
    return f"'{code}'"


def get_item_slot(class_name):
    """Determine equipment slot from item class"""
    if not class_name:
        return None
    
    class_name = class_name.upper()
    
    # Check TWO-HAND weapons FIRST before checking HAND
    if '2H' in class_name or 'TWO-HAND' in class_name or 'TWO HAND' in class_name or 'TWOHANDED' in class_name:
        return 19  # 2-handed weapon slot ID
    
    # Check shields and off-hands before other weapons
    if 'SHIELD' in class_name or 'OFF-HAND' in class_name or 'OFFHAND' in class_name:
        return 'OffHand'
    
    # Check specific armor types FIRST before generic "ARMOR" pattern
    if 'HEAD' in class_name or 'HELMET' in class_name or 'HELM' in class_name:
        return 'Head'
    elif 'NECK' in class_name or 'AMULET' in class_name or 'PENDANT' in class_name or 'NECKLACE' in class_name:
        return 'Neck'
    elif 'SHOULDER' in class_name or 'PAULDRON' in class_name:
        return 'Shoulder'
    elif 'HAND' in class_name or 'GAUNTLET' in class_name or 'GLOVE' in class_name:
        return 'Gloves'
    elif 'LEG' in class_name or 'PANT' in class_name or 'GREAVES' in class_name:
        return 'Legs'
    elif 'FEET' in class_name or 'FOOT' in class_name or 'BOOT' in class_name or 'SHOE' in class_name:
        return 'Boots'
    elif 'CHEST' in class_name or 'ARMOR' in class_name or 'BREASTPLATE' in class_name:
        return 'Chest'
    elif 'BACK' in class_name or 'CLOAK' in class_name or 'CAPE' in class_name:
        return 'Back'
    elif 'BRACER' in class_name or 'WRIST' in class_name:
        return 'Bracers'
    elif 'RING' in class_name:
        return 'Ring'
    elif 'BELT' in class_name or 'WAIST' in class_name or 'GIRDLE' in class_name:
        return 'Belt'
    elif 'WEAPON' in class_name or 'SWORD' in class_name or 'AXE' in class_name or 'MACE' in class_name or 'DAGGER' in class_name or '1H' in class_name:
        return 'MainHand'
    
    return None


def is_two_handed_weapon(class_name):
    """Check if item is a two-handed weapon"""
    if not class_name:
        return False
    
    class_name = class_name.upper()
    return '2H' in class_name or 'TWO-HANDED' in class_name or 'TWO HANDED' in class_name


def export_dequipment_definitions(output_path, library_name='DEquipmentItemDefinitions'):
    """Export items to DEquipment JASS format"""
    
    print(f"Connecting to database {DB_CONFIG['database']}...")
    
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Get all custom items (those with stats/equipment potential)
        query = """
            SELECT 
                i.id,
                i.item_code,
                i.item_name,
                i.base_id,
                i.gold_cost,
                i.wc3_abilities,
                COALESCE(c.class_name, 'MISC') as class_name,
                COALESCE(r.rarity_name, 'Common') as rarity
            FROM items i
            LEFT JOIN item_classes c ON i.class_id = c.id
            LEFT JOIN item_rarities r ON i.rarity_id = r.id
            WHERE i.base_id IS NOT NULL  -- Only custom items
            ORDER BY i.item_code
        """
        
        cursor.execute(query)
        items = cursor.fetchall()
        
        print(f"Found {len(items)} custom items to export...")
        
        # Get stats for each item
        stats_query = """
            SELECT s.stat_name, isv.stat_value
            FROM item_stat_values isv
            JOIN item_stats s ON isv.stat_id = s.id
            WHERE isv.item_id = %s
            ORDER BY s.stat_name
        """
        
        # Start building JASS output
        lines = []
        lines.append(f"library {library_name} initializer Init requires DEquipment")
        lines.append("")
        lines.append("function DEqPreDefineItemsHere takes nothing returns nothing")
        lines.append("    // Auto-generated from WC3 Item Database")
        lines.append(f"    // Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append(f"    // Total items: {len(items)}")
        lines.append("")
        
        exported_count = 0
        
        for item in items:
            item_id, code, name, base_id, gold_cost, abilities, class_name, rarity = item
            
            # Skip items without proper code
            if not code or len(code) != 4:
                print(f"  Skipping item {name} - invalid code: {code}")
                continue
            
            code_str = convert_item_code(code)
            
            lines.append(f"    // {name} ({rarity})")
            lines.append(f"    // Base: {base_id}, Class: {class_name}")
            
            # Define equipment slot
            slot = get_item_slot(class_name)
            if slot:
                if isinstance(slot, int):
                    lines.append(f"    call DEqItemTypeDefineAllowedSlotId({code_str}, {slot})")
                else:
                    lines.append(f"    call DEqItemTypeDefineAllowedSlotByName({code_str}, \"{slot}\")")
            
            # Check if two-handed
            if is_two_handed_weapon(class_name):
                lines.append(f"    call DEqItemTypeDefineAs2Handed({code_str})")
            
            # Get item stats from database
            cursor.execute(stats_query, (item_id,))
            item_stats = cursor.fetchall()
            
            for stat_name, stat_value in item_stats:
                # Map database stat name to DEquipment stat name
                deq_stat_name = STAT_MAPPINGS.get(stat_name, stat_name)
                
                if stat_value and stat_value != 0:
                    # Format value appropriately
                    if isinstance(stat_value, float):
                        value_str = f"{stat_value:.3f}".rstrip('0').rstrip('.')
                    else:
                        value_str = str(stat_value)
                    
                    lines.append(f"    call DEqItemTypeDefineStatGrantedByName({code_str}, \"{deq_stat_name}\", {value_str})")
            
            # Define gold value if set
            if gold_cost and gold_cost > 0:
                lines.append(f"    call DEqItemTypeDefineGoldValue({code_str}, {gold_cost})")
            
            # Parse abilities if present
            if abilities:
                # abilities format: "Abcd,Axyz" or "Abcd" 
                ability_codes = [a.strip() for a in abilities.split(',') if a.strip()]
                for ability_code in ability_codes:
                    if len(ability_code) == 4:
                        lines.append(f"    call DEqItemTypeDefineAbilityGranted({code_str}, '{ability_code}', 1)")
            
            lines.append("")
            exported_count += 1
        
        lines.append("endfunction")
        lines.append("")
        lines.append("private function Init takes nothing returns nothing")
        lines.append("    call TriggerRegisterTimerEvent(trg_DEqPreDefinedItems, 0.1, false)")
        lines.append("    call TriggerAddAction(trg_DEqPreDefinedItems, function DEqPreDefineItemsHere)")
        lines.append("endfunction")
        lines.append("")
        lines.append("endlibrary")
        
        # Write to file
        print(f"Writing to {output_path}...")
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        
        print(f"Successfully exported {exported_count} items!")
        print(f"Output file: {output_path}")
        
        cursor.close()
        conn.close()
        
        return 0
        
    except Exception as e:
        print(f"Error during export: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python export_dequipment_cli.py <output_path> [library_name]")
        print("Example: python export_dequipment_cli.py output.j DEquipmentItemDefinitions")
        sys.exit(1)
    
    output_path = sys.argv[1]
    library_name = sys.argv[2] if len(sys.argv) > 2 else 'DEquipmentItemDefinitions'
    
    exit_code = export_dequipment_definitions(output_path, library_name)
    sys.exit(exit_code)
