#!/usr/bin/env python3
"""
DEquipment Item Definitions Exporter
Exports items from PostgreSQL database to JASS library format for DEquipment system
"""

import json
import os
import sys
import psycopg2
from decimal import Decimal
from datetime import datetime

# Database connection settings
DB_CONFIG = {
    'host': '127.0.0.1',
    'port': 5432,
    'database': 'wc3_pots',
    'user': 'postgres',
    'password': '009900'
}

# Stat name mappings from database to DEquipment. Keys are normalized by
# normalize_text so exporter output is not sensitive to punctuation/case.
STAT_MAPPINGS = {
    'Strength': 'Strength',
    'STR': 'Strength',
    'Agility': 'Agility',
    'AGI': 'Agility',
    'Intelligence': 'Intelligence',
    'INT': 'Intelligence',
    'Health': 'Hitpoints',
    'HP': 'Hitpoints',
    'Hit Points': 'Hitpoints',
    'Hitpoints': 'Hitpoints',
    'Health Bonus': 'Hitpoints',
    'HP Regen': 'Hitpoint regeneration',
    'Health Regen': 'Hitpoint regeneration',
    'HPS': 'Hitpoint regeneration',
    'HP Regen %': 'HP Pct Per Sec',
    'Health Regen %': 'HP Pct Per Sec',
    'Mana': 'Mana',
    'MP': 'Mana',
    'Mana Regen': 'Mana regeneration',
    'Mana Regen Per Sec': 'Mana regeneration',
    'MPS': 'Mana regeneration',
    'Mana Regen %': 'Mana Pct Per Sec',
    'Damage': 'Damage',
    'Damage %': 'Damage Pct',
    'Damage Pct': 'Damage Pct',
    'Melee Attack Damage': 'Melee Damage',
    'Melee Damage': 'Melee Damage',
    'Melee Damage %': 'Melee DMG Pct',
    'Melee DMG Pct': 'Melee DMG Pct',
    'Ranged Attack Damage': 'Ranged Damage',
    'Ranged Damage': 'Ranged Damage',
    'Ranged Damage %': 'Ranged DMG Pct',
    'Ranged DMG Pct': 'Ranged DMG Pct',
    'Spell Power': 'Spell Power',
    'Spell Power %': 'Spell Power Pct',
    'Spell Power Pct': 'Spell Power Pct',
    'Attack Speed': 'Attack Speed',
    'Critical Strike Chance': 'Critical Chance',
    'Critical Chance': 'Critical Chance',
    'Crit Chance': 'Critical Chance',
    'Critical Strike Damage': 'Critical Damage',
    'Critical Damage': 'Critical Damage',
    'Crit Damage': 'Critical Damage',
    'Lifesteal': 'Lifesteal Pct',
    'Lifesteal %': 'Lifesteal Pct',
    'Lifesteal Pct': 'Lifesteal Pct',
    'Spell Vamp %': 'Spell Vamp Pct',
    'Cleave %': 'Cleave Pct',
    'Cleave Pct': 'Cleave Pct',
    'Cleave Area': 'Cleave Area',
    'Armor': 'Armor',
    'Armor %': 'Armor Pct',
    'Armor Pct': 'Armor Pct',
    'Dodge': 'Dodge',
    'Evasion': 'Dodge',  # legacy mapping for old data
    'Block Chance': 'Block Chance',
    'Hit Chance': 'Hit Chance',
    'Magic Damage Taken': 'Spell Damage Taken Pct',
    'Magic Damage Taken %': 'Spell Damage Taken Pct',
    'Magic Resistance %': 'Spell Damage Taken Pct',
    'Spell Damage Taken Pct': 'Spell Damage Taken Pct',
    'Melee Damage Taken': 'Melee Damage Taken Pct',
    'Melee Damage Taken %': 'Melee Damage Taken Pct',
    'Melee Damage Taken Pct': 'Melee Damage Taken Pct',
    'Pierce Damage Taken': 'Pierce Damage Taken Pct',
    'Pierce Damage Taken %': 'Pierce Damage Taken Pct',
    'Pierce Damage Taken Pct': 'Pierce Damage Taken Pct',
    'Movement Speed': 'Movement Speed',
    'Move Speed': 'Movement Speed',
    'MS': 'Movement Speed',
    'Movement Speed %': 'MoveSPD Pct',
    'Move Speed %': 'MoveSPD Pct',
    'MoveSPD Pct': 'MoveSPD Pct',
    'Sight Range': 'Sight Range',
    'Attack Range': 'Attack Range',
    'Inventory Space': 'Inventory Space',
    'Healing Power': 'Healing Power',
    'Mining': 'Mining',
    'Herbalism': 'Herbalism',
    'Skinning': 'Skinning',
    'Fishing': 'Fishing',
    'Alchemy': 'Alchemy',
    'Blacksmithing': 'Blacksmithing',
    'Leatherworking': 'Leatherworking',
    'Enchanting': 'Enchanting',
    'Cooking': 'Cooking'
}

DEQ_STAT_NAMES = {
    'Strength',
    'Agility',
    'Intelligence',
    'Hitpoints',
    'Hitpoint regeneration',
    'HP Pct Per Sec',
    'Mana',
    'Mana regeneration',
    'Mana Pct Per Sec',
    'Critical Chance',
    'Critical Damage',
    'Damage',
    'Damage Pct',
    'Melee Damage',
    'Melee DMG Pct',
    'Ranged Damage',
    'Ranged DMG Pct',
    'Cleave Pct',
    'Cleave Area',
    'Attack Speed',
    'Attack Range',
    'Lifesteal Pct',
    'Thorns',
    'Thorns Pct',
    'Armor',
    'Armor Pct',
    'Dodge',
    'Spell Damage Taken Pct',
    'Melee Damage Taken Pct',
    'Pierce Damage Taken Pct',
    'Movement Speed',
    'MoveSPD Pct',
    'Sight Range',
    'Inventory Space',
    'Block Chance',
    'Hit Chance',
    'Spell Power Pct',
    'Spell Power',
    'Healing Power',
    'Mining',
    'Herbalism',
    'Skinning',
    'Fishing',
    'Alchemy',
    'Blacksmithing',
    'Leatherworking',
    'Enchanting',
    'Cooking',
}

FRACTION_PERCENT_STATS = {
    'HP Pct Per Sec',
    'Mana Pct Per Sec',
    'Critical Damage',
    'Damage Pct',
    'Melee DMG Pct',
    'Ranged DMG Pct',
    'Cleave Pct',
    'Attack Speed',
    'Lifesteal Pct',
    'Thorns Pct',
    'Armor Pct',
    'Spell Damage Taken Pct',
    'Melee Damage Taken Pct',
    'Pierce Damage Taken Pct',
    'MoveSPD Pct',
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


def normalize_text(value):
    """Normalize a user/database label while preserving the original value elsewhere."""
    return ' '.join(str(value).strip().replace('_', ' ').replace('-', ' ').split()).upper()


STAT_MAPPINGS = {normalize_text(key): value for key, value in STAT_MAPPINGS.items()}


def load_item_code_aliases():
    """Load imported object codes so lowercase DB rows can still define uppercase map rawcodes."""
    aliases_by_lower = {}
    mapping_path = os.path.join(os.path.dirname(__file__), 'config', 'item_table_mapping.json')

    try:
        with open(mapping_path, 'r', encoding='utf-8') as f:
            mapping_data = json.load(f)
    except Exception as e:
        print(f"Warning: could not load item rawcode mapping aliases: {e}")
        return aliases_by_lower

    def collect_codes(value):
        if isinstance(value, str):
            if len(value) == 4:
                aliases_by_lower.setdefault(value.lower(), set()).add(value)
        elif isinstance(value, list):
            for child in value:
                collect_codes(child)
        elif isinstance(value, dict):
            for child in value.values():
                collect_codes(child)

    collect_codes(mapping_data)
    return aliases_by_lower


ITEM_CODE_ALIASES = load_item_code_aliases()


def convert_item_code(code):
    """Convert 4-char item code to JASS format 'I###' or use as-is"""
    if code and len(code) == 4:
        # WC3 format: 4 characters (e.g., 'i0a5', 'hcun', 'I6CF')
        # Rawcode case is significant in JASS; keep the database/mapping case.
        return f"'{code}'"
    return f"'{code}'"


def get_item_code_aliases(code):
    """Return the DB rawcode plus imported-object aliases with the same case-insensitive code."""
    codes = []
    seen = set()

    for rawcode in [code] + sorted(ITEM_CODE_ALIASES.get(code.lower(), set())):
        if rawcode and rawcode not in seen:
            codes.append(rawcode)
            seen.add(rawcode)

    return codes


def normalize_slot_value(slot_value):
    """Map database slot/class labels to DEquipment slot names or IDs."""
    if not slot_value:
        return None

    slot_text = normalize_text(slot_value)
    compact_slot = slot_text.replace(' ', '')

    # Check weapon hand labels before hand armor. "Main Hand Weapon" contains HAND.
    if compact_slot in ('2H', '2HWEAPON', 'TWOHAND', 'TWOHANDED', 'TWOHANDWEAPON', 'TWOHANDEDWEAPON', 'TWOHANDSTAFF', 'TWOHANDEDSTAFF', 'STAVE', 'STAFF') or 'TWO HAND' in slot_text or 'STAVE' in slot_text or 'STAFF' in slot_text:
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
        return [8, 9]
    elif compact_slot == 'TRINKET' or 'TRINKET' in slot_text:
        return [17, 18]
    elif compact_slot == 'BELT' or 'WAIST' in slot_text or 'GIRDLE' in slot_text:
        return 'Belt'

    if 'WEAPON' in slot_text or 'SWORD' in slot_text or 'AXE' in slot_text or 'MACE' in slot_text or 'DAGGER' in slot_text:
        return 'MainHand'

    return None


def slot_values(slot):
    """Normalize a slot return value to a list."""
    if slot is None:
        return []
    if isinstance(slot, list):
        return slot
    return [slot]


def get_item_slots(class_name, slot_type=None, equipment_slot=None):
    """Determine equipment slots from explicit slot data, then class metadata."""
    slot = normalize_slot_value(equipment_slot)
    if slot:
        return slot_values(slot)

    slot = normalize_slot_value(class_name)
    if slot:
        return slot_values(slot)

    return slot_values(normalize_slot_value(slot_type))


def is_two_handed_weapon(class_name, slot_type=None, equipment_slot=None):
    """Check if item is a two-handed weapon"""
    for slot_value in (equipment_slot, class_name, slot_type):
        if 19 in slot_values(normalize_slot_value(slot_value)):
            return True

    return False


def map_stat_name(stat_name):
    """Return a DEquipment stat name, or None when no registered stat exists."""
    deq_stat_name = STAT_MAPPINGS.get(normalize_text(stat_name))
    if deq_stat_name:
        if deq_stat_name in DEQ_STAT_NAMES:
            return deq_stat_name
        return None

    if stat_name in DEQ_STAT_NAMES:
        return stat_name

    return None


def normalize_stat_value(deq_stat_name, stat_value):
    """Convert whole-percent ItemManager values to DEquipment fractional fields where needed."""
    if deq_stat_name not in FRACTION_PERCENT_STATS:
        return stat_value

    try:
        amount = stat_value if isinstance(stat_value, Decimal) else Decimal(str(stat_value))
    except Exception:
        return stat_value

    if abs(amount) > Decimal('1'):
        return amount / Decimal('100')
    return amount


def format_jass_number(value):
    """Format numeric values without unnecessary trailing zeros."""
    if isinstance(value, Decimal):
        return format(value.normalize(), 'f')
    if isinstance(value, float):
        return f"{value:.3f}".rstrip('0').rstrip('.')
    return str(value)


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
        alias_count = 0
        unsupported_stats = set()
        
        for item in items:
            item_id, code, name, base_id, gold_cost, abilities, equipment_slot, slot_type, class_name, rarity = item
            
            # Skip items without proper code
            if not code or len(code) != 4:
                print(f"  Skipping item {name} - invalid code: {code}")
                continue
            
            item_code_aliases = get_item_code_aliases(code)
            code_strings = [convert_item_code(rawcode) for rawcode in item_code_aliases]
            if len(code_strings) > 1:
                alias_count += 1
            
            lines.append(f"    // {name} ({rarity})")
            lines.append(f"    // Base: {base_id}, Class: {class_name}")
            if len(code_strings) > 1:
                lines.append(f"    // Rawcode aliases: {', '.join(code_strings)}")
            
            # Define equipment slot
            slots = get_item_slots(class_name, slot_type, equipment_slot)
            for code_str in code_strings:
                for slot in slots:
                    if isinstance(slot, int):
                        lines.append(f"    call DEqItemTypeDefineAllowedSlotId({code_str}, {slot})")
                    else:
                        lines.append(f"    call DEqItemTypeDefineAllowedSlotByName({code_str}, \"{slot}\")")
            
            # Check if two-handed
            if is_two_handed_weapon(class_name, slot_type, equipment_slot):
                for code_str in code_strings:
                    lines.append(f"    call DEqItemTypeDefineAs2Handed({code_str})")
            
            # Get item stats from database
            cursor.execute(stats_query, (item_id,))
            item_stats = cursor.fetchall()
            
            for stat_name, stat_value in item_stats:
                # Map database stat name to DEquipment stat name
                deq_stat_name = map_stat_name(stat_name)
                
                if stat_value and stat_value != 0:
                    if not deq_stat_name:
                        unsupported_stats.add(stat_name)
                        lines.append(f"    // Unsupported DEquipment stat skipped: {stat_name} = {format_jass_number(stat_value)}")
                        continue

                    stat_value = normalize_stat_value(deq_stat_name, stat_value)

                    # Format value appropriately
                    value_str = format_jass_number(stat_value)
                    
                    for code_str in code_strings:
                        lines.append(f"    call DEqItemTypeDefineStatGrantedByName({code_str}, \"{deq_stat_name}\", {value_str})")
            
            # Define gold value if set
            if gold_cost and gold_cost > 0:
                for code_str in code_strings:
                    lines.append(f"    call DEqItemTypeDefineGoldValue({code_str}, {gold_cost})")
            
            # Parse abilities if present
            if abilities:
                # abilities format: "Abcd,Axyz" or "Abcd" 
                ability_codes = [a.strip() for a in abilities.split(',') if a.strip()]
                for ability_code in ability_codes:
                    if len(ability_code) == 4:
                        for code_str in code_strings:
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
        
        if alias_count:
            print(f"Emitted rawcode aliases for {alias_count} items.")
        if unsupported_stats:
            print("Skipped unsupported DEquipment stats: " + ", ".join(sorted(unsupported_stats)))
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
