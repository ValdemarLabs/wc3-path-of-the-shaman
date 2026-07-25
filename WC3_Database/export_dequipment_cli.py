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


def normalize_slot_value(slot_value):
    """Map database slot/class labels to DEquipment slot names or IDs."""
    if not slot_value:
        return None

    slot_text = str(slot_value).strip().upper().replace('_', ' ').replace('-', ' ')
    slot_text = ' '.join(slot_text.split())
    compact_slot = slot_text.replace(' ', '')

    # Check weapon hand labels before hand armor. "Main Hand Weapon" contains HAND.
    if compact_slot in ('2H', '2HWEAPON', 'TWOHAND', 'TWOHANDED', 'TWOHANDWEAPON', 'TWOHANDEDWEAPON') or 'TWO HAND' in slot_text:
        return 19  # 2-handed weapon slot ID
    if compact_slot in ('OFFHAND', 'OFFHANDWEAPON') or 'OFF HAND' in slot_text or 'SHIELD' in slot_text:
        return 'OffHand'
    if compact_slot in ('MAINHAND', 'MAINHANDWEAPON', '1H', '1HWEAPON', 'ONEHAND', 'ONEHANDED', 'ONEHANDWEAPON', 'WEAPON') or 'MAIN HAND' in slot_text:
        return 'MainHand'

    # Check specific armor types before generic "ARMOR" pattern.
    if compact_slot in ('HEAD', 'HEADARMOR') or 'HELMET' in slot_text or 'HELM' in slot_text:
        return 'Head'
    elif compact_slot in ('NECK', 'AMULET') or 'PENDANT' in slot_text or 'NECKLACE' in slot_text:
        return 'Neck'
    elif compact_slot in ('SHOULDER', 'SHOULDERS', 'SHOULDERARMOR') or 'PAULDRON' in slot_text:
        return 'Shoulder'
    elif compact_slot in ('HAND', 'HANDS', 'HANDARMOR', 'GLOVE', 'GLOVES', 'GAUNTLET', 'GAUNTLETS') or 'HAND ARMOR' in slot_text or 'GAUNTLET' in slot_text or 'GLOVE' in slot_text:
        return 'Gloves'
    elif compact_slot in ('LEG', 'LEGS', 'LEGARMOR') or 'PANT' in slot_text or 'GREAVES' in slot_text:
        return 'Legs'
    elif compact_slot in ('FEET', 'FOOT', 'FOOTARMOR') or 'BOOT' in slot_text or 'SHOE' in slot_text:
        return 'Boots'
    elif compact_slot in ('CHEST', 'CHESTARMOR') or 'BREASTPLATE' in slot_text or 'ARMOR' in slot_text:
        return 'Chest'
    elif compact_slot == 'BACK' or 'CLOAK' in slot_text or 'CAPE' in slot_text:
        return 'Back'
    elif compact_slot in ('BRACER', 'BRACERS') or 'WRIST' in slot_text:
        return 'Bracers'
    elif compact_slot == 'RING' or 'RING' in slot_text:
        return 'Ring'
    elif compact_slot == 'BELT' or 'WAIST' in slot_text or 'GIRDLE' in slot_text:
        return 'Belt'

    if 'WEAPON' in slot_text or 'SWORD' in slot_text or 'AXE' in slot_text or 'MACE' in slot_text or 'DAGGER' in slot_text:
        return 'MainHand'

    return None


def get_item_slot(class_name, slot_type=None, equipment_slot=None):
    """Determine equipment slot from explicit slot data, then class metadata."""
    slot = normalize_slot_value(equipment_slot)
    if slot:
        return slot

    slot = normalize_slot_value(class_name)
    if slot:
        return slot

    return normalize_slot_value(slot_type)


def is_two_handed_weapon(class_name, slot_type=None, equipment_slot=None):
    """Check if item is a two-handed weapon"""
    for slot_value in (equipment_slot, class_name, slot_type):
        if normalize_slot_value(slot_value) == 19:
            return True

    return False


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
                i.equipment_slot,
                c.slot_type,
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
            item_id, code, name, base_id, gold_cost, abilities, equipment_slot, slot_type, class_name, rarity = item
            
            # Skip items without proper code
            if not code or len(code) != 4:
                print(f"  Skipping item {name} - invalid code: {code}")
                continue
            
            code_str = convert_item_code(code)
            
            lines.append(f"    // {name} ({rarity})")
            lines.append(f"    // Base: {base_id}, Class: {class_name}")
            
            # Define equipment slot
            slot = get_item_slot(class_name, slot_type, equipment_slot)
            if slot:
                if isinstance(slot, int):
                    lines.append(f"    call DEqItemTypeDefineAllowedSlotId({code_str}, {slot})")
                else:
                    lines.append(f"    call DEqItemTypeDefineAllowedSlotByName({code_str}, \"{slot}\")")
            
            # Check if two-handed
            if is_two_handed_weapon(class_name, slot_type, equipment_slot):
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
