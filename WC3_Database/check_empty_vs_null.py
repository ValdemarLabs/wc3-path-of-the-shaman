#!/usr/bin/env python3
"""Check if database items have EMPTY strings or NULL values."""

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
    
    # Check specific items to see if they have empty strings or NULL
    test_items = ['ajen', 'ankh', 'asbl', 'belv', 'bgst']
    
    print("="*80)
    print("CHECKING DATABASE VALUES FOR PROBLEM ITEMS:")
    print("="*80)
    
    for item_code in test_items:
        cur.execute("""
            SELECT item_code, item_name,
                   icon_path, model_path, scale, cooldown_group, wc3_abilities,
                   tint_red, tint_green, tint_blue
            FROM items
            WHERE item_code = %s
        """, (item_code,))
        
        row = cur.fetchone()
        if row:
            code, name, icon, model, scale, cooldown, abilities, tr, tg, tb = row
            print(f"\n[{code}] {name[:40]}")
            print(f"  icon_path:      {repr(icon)}")
            print(f"  model_path:     {repr(model)}")
            print(f"  scale:          {repr(scale)}")
            print(f"  cooldown_group: {repr(cooldown)}")
            print(f"  wc3_abilities:  {repr(abilities)}")
            print(f"  tints (R,G,B):  {repr(tr)}, {repr(tg)}, {repr(tb)}")
        else:
            print(f"\n[{item_code}] NOT FOUND in database")
        print("-"*80)
    
    # Summary: Check if empty strings vs NULL
    cur.execute("""
        SELECT 
            COUNT(CASE WHEN icon_path IS NULL THEN 1 END) as icon_null,
            COUNT(CASE WHEN icon_path = '' THEN 1 END) as icon_empty,
            COUNT(CASE WHEN model_path IS NULL THEN 1 END) as model_null,
            COUNT(CASE WHEN model_path = '' THEN 1 END) as model_empty,
            COUNT(CASE WHEN cooldown_group IS NULL THEN 1 END) as cooldown_null,
            COUNT(CASE WHEN cooldown_group = '' THEN 1 END) as cooldown_empty,
            COUNT(CASE WHEN wc3_abilities IS NULL THEN 1 END) as abilities_null,
            COUNT(CASE WHEN wc3_abilities = '' THEN 1 END) as abilities_empty
        FROM items
    """)
    
    row = cur.fetchone()
    icon_null, icon_empty, model_null, model_empty, cooldown_null, cooldown_empty, abilities_null, abilities_empty = row
    
    print("\n" + "="*80)
    print("NULL vs EMPTY STRING COUNTS:")
    print("="*80)
    print(f"icon_path:      {icon_null:4d} NULL, {icon_empty:4d} empty strings")
    print(f"model_path:     {model_null:4d} NULL, {model_empty:4d} empty strings")
    print(f"cooldown_group: {cooldown_null:4d} NULL, {cooldown_empty:4d} empty strings")
    print(f"wc3_abilities:  {abilities_null:4d} NULL, {abilities_empty:4d} empty strings")
    
    print("\n" + "="*80)
    print("DIAGNOSIS:")
    print("="*80)
    if icon_empty > 0 or model_empty > 0 or cooldown_empty > 0 or abilities_empty > 0:
        print("⚠️  Database has EMPTY STRINGS (not NULL)")
        print("   This happens when exporter writes \"\" for NULL, then import saves it.")
        print("   The export→import cycle is poisoning the data with empty strings!")
        print("\n   SOLUTION:")
        print("   1. Restore from backup BEFORE any export→import cycles")
        print("   2. OR: Update empty strings to NULL, then re-export")
    else:
        print("✓ Database has proper NULL values (not empty strings)")
        print("  The data was never there - need to get it from original WC3 data")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"[ERROR] {e}")
    import traceback
    traceback.print_exc()
