"""
Fix item_stats table IDs to match JASS code
=============================================
Updates the item_stats table to have the correct stat IDs 
matching the SharedDInvLib.j stat ID mappings.

Author: Generated for PotS Project
Date: 2026-03-12
"""

import sys
import os
import psycopg2
import configparser

def load_database_config(config_path='config/database.ini'):
    """Load database configuration from INI file."""
    config_file = os.path.join(os.path.dirname(__file__), config_path)
    
    if not os.path.exists(config_file):
        raise FileNotFoundError(f"Database config not found: {config_file}")
    
    config = configparser.ConfigParser()
    config.read(config_file)
    
    if 'postgresql' not in config:
        raise ValueError("Database config missing [postgresql] section")
    
    return {
        'host': config['postgresql']['host'],
        'port': config['postgresql']['port'],
        'database': config['postgresql']['database'],
        'user': config['postgresql']['user'],
        'password': config['postgresql'].get('password', '')
    }

def main():
    """Main migration function."""
    try:
        # Load database configuration
        print("Loading database configuration...")
        db_config = load_database_config()
        
        # Connect to database
        print(f"Connecting to database: {db_config['database']}...")
        conn = psycopg2.connect(**db_config)
        conn.autocommit = False  # Use transaction
        cursor = conn.cursor()
        
        print("Starting migration...")
        
        # Clear existing data
        print("Clearing existing item_stat_values...")
        cursor.execute("TRUNCATE TABLE item_stat_values CASCADE;")
        
        print("Clearing existing item_stats...")
        cursor.execute("DELETE FROM item_stats;")
        
        print("Resetting sequence...")
        cursor.execute("ALTER SEQUENCE item_stats_id_seq RESTART WITH 1;")
        
        # Define stats with correct IDs
        stats = [
            (1, 'str', 'Strength', 'Increases damage and HP', '+{value}', '#FF0000', 1),
            (2, 'agi', 'Agility', 'Increases attack speed and armor', '+{value}', '#00FF00', 2),
            (3, 'int', 'Intelligence', 'Increases mana and spell damage', '+{value}', '#0080FF', 3),
            (4, 'hp', 'Health', 'Maximum health points', '+{value}', '#C41E3A', 4),
            (5, 'hp_regen', 'HP Regen', 'Health regeneration per second', '+{value}', '#FF69B4', 5),
            (6, 'hp_regen_pct', 'HP Regen %', 'Health regeneration percent per second', '+{value}%', '#FF99CC', 6),
            (7, 'mp', 'Mana', 'Maximum mana points', '+{value}', '#0070DD', 7),
            (8, 'mp_regen', 'Mana Regen', 'Mana regeneration per second', '+{value}', '#9482C9', 8),
            (9, 'mp_regen_pct', 'Mana Regen %', 'Mana regeneration percent per second', '+{value}%', '#B099DD', 9),
            (10, 'crit', 'Critical Chance', 'Chance to deal critical damage', '+{value}%', '#FF8C00', 10),
            (11, 'crit_dmg', 'Critical Damage', 'Critical hit damage multiplier', '+{value}%', '#FF4500', 11),
            (12, 'dmg', 'Damage', 'Attack damage bonus', '+{value}', '#FFD700', 12),
            (13, 'dmg_pct', 'Damage %', 'General damage percent bonus', '+{value}%', '#FFDD00', 13),
            (14, 'melee_dmg', 'Melee Damage', 'Melee damage flat bonus', '+{value}', '#CC0000', 14),
            (15, 'melee_dmg_pct', 'Melee Damage %', 'Melee damage percent bonus', '+{value}%', '#DD0000', 15),
            (16, 'ranged_dmg', 'Ranged Damage', 'Ranged damage flat bonus', '+{value}', '#00CC00', 16),
            (17, 'ranged_dmg_pct', 'Ranged Damage %', 'Ranged damage percent bonus', '+{value}%', '#00DD00', 17),
            (18, 'cleave_pct', 'Cleave %', 'Cleave damage percent', '+{value}%', '#FFA500', 18),
            (19, 'cleave_area', 'Cleave Area', 'Cleave area of effect', '+{value}', '#FFB700', 19),
            (20, 'aspd', 'Attack Speed', 'Attack speed bonus', '+{value}%', '#FFFF00', 20),
            (21, 'attack_range', 'Attack Range', 'Attack range bonus', '+{value}', '#FFEE00', 21),
            (22, 'lifesteal', 'Lifesteal', 'Heal from damage dealt', '+{value}%', '#8B0000', 22),
            (23, 'thorns_flat', 'Thorns', 'Reflects flat damage when hit', '+{value}', '#CD853F', 23),
            (24, 'thorns_pct', 'Thorns %', 'Reflects damage percent when hit', '+{value}%', '#D2691E', 24),
            (25, 'armor', 'Armor', 'Physical damage reduction', '+{value}', '#C0C0C0', 25),
            (26, 'armor_pct', 'Armor %', 'Armor percent bonus', '+{value}%', '#D0D0D0', 26),
            (27, 'evasion', 'Evasion', 'Chance to evade attacks', '+{value}%', '#32CD32', 27),
            (28, 'magic_dmg_taken', 'Magic Damage Taken', 'Magic damage taken modifier', '{value}%', '#9370DB', 28),
            (29, 'melee_dmg_taken', 'Melee Damage Taken', 'Melee damage taken modifier', '{value}%', '#DC143C', 29),
            (30, 'pierce_dmg_taken', 'Pierce Damage Taken', 'Pierce damage taken modifier', '{value}%', '#228B22', 30),
            (31, 'ms', 'Movement Speed', 'Movement speed bonus', '+{value}', '#00FFFF', 31),
            (32, 'ms_pct', 'Movement Speed %', 'Movement speed percent bonus', '+{value}%', '#00EEEE', 32),
            (33, 'sight_range', 'Sight Range', 'Vision range bonus', '+{value}', '#87CEEB', 33),
            (34, 'inv_space', 'Inventory Space', 'Additional inventory slots', '+{value}', '#DAA520', 34),
        ]
        
        # Insert stats with explicit IDs
        print("Inserting 34 stats with correct IDs...")
        for stat in stats:
            cursor.execute("""
                INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order) 
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, stat)
        
        # Update sequence to continue from 35
        print("Updating sequence to start from 35...")
        cursor.execute("SELECT setval('item_stats_id_seq', 34, true);")
        
        # Verify the results
        print("\nVerifying inserted stats:")
        cursor.execute("SELECT id, stat_code, stat_name FROM item_stats ORDER BY id;")
        rows = cursor.fetchall()
        
        for row in rows:
            print(f"  ID {row[0]:2d}: {row[1]:20s} - {row[2]}")
        
        # Commit the transaction
        conn.commit()
        print("\n[OK] Migration completed successfully!")
        print(f"[OK] Total stats inserted: {len(rows)}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"[ERROR] Migration failed: {str(e)}")
        if 'conn' in locals():
            conn.rollback()
            conn.close()
        sys.exit(1)

if __name__ == '__main__':
    main()
