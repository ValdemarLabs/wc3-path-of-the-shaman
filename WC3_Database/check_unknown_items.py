#!/usr/bin/env python3
"""Check current database for 'Unknown Item' entries and their data."""

import psycopg2

db_config = {
    'host': '127.0.0.1',
    'port': '5432',
    'database': 'wc3_pots',
    'user': 'postgres',
    'password': '009900'
}

try:
    conn = psycopg2.connect(**db_config)
    cur = conn.cursor()
    
    # Find all "Unknown Item" entries
    cur.execute("""
        SELECT item_code, item_name, base_id, wc3_abilities, cooldown_group,
               length(tooltip_extended) as tooltip_len,
               length(description) as desc_len
        FROM items 
        WHERE item_name LIKE 'Unknown Item%'
        ORDER BY item_code
        LIMIT 20
    """)
    
    rows = cur.fetchall()
    
    print("="*80)
    print(f"ITEMS WITH 'Unknown Item' NAMES: {len(rows)}")
    print("="*80)
    
    if not rows:
        print("\n✓ No 'Unknown Item' entries found!")
        print("  All items have proper names.")
    else:
        print("\nThese items have generic names and may be missing data:")
        print("-"*80)
        
        for row in rows:
            item_code, name, base_id, abilities, cooldown, tooltip_len, desc_len = row
            is_custom = "CUSTOM" if base_id else "ORIGINAL"
            
            print(f"\n{item_code} - {name}")
            print(f"  Type: {is_custom}")
            print(f"  Abilities: {abilities if abilities else '(empty)'}")
            print(f"  Cooldown Group: {cooldown if cooldown else '(empty)'}")
            print(f"  Tooltip: {tooltip_len or 0} chars")
            print(f"  Description: {desc_len or 0} chars")
    
    # Check how many items have abilities
    cur.execute("""
        SELECT 
            COUNT(*) as total,
            COUNT(wc3_abilities) as with_abilities,
            COUNT(CASE WHEN base_id IS NULL THEN 1 END) as original_items,
            COUNT(CASE WHEN base_id IS NULL AND wc3_abilities IS NOT NULL THEN 1 END) as original_with_abilities
        FROM items
    """)
    
    stats = cur.fetchone()
    total, with_abilities, original_items, original_with_abilities = stats
    
    print("\n" + "="*80)
    print("DATABASE STATISTICS:")
    print("="*80)
    print(f"Total items: {total}")
    print(f"Items with abilities: {with_abilities} ({with_abilities/total*100:.1f}%)")
    print(f"Original items (modified Blizzard): {original_items}")
    print(f"Original items with abilities: {original_with_abilities}")
    
    if with_abilities == 0:
        print("\n⚠️  WARNING: NO items have abilities!")
        print("   The importer was not saving wc3_abilities field.")
        print("   This has now been fixed - re-import your .w3t file.")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"[ERROR] {e}")
    import traceback
    traceback.print_exc()
