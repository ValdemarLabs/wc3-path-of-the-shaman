#!/usr/bin/env python3
"""Check which items are missing visual fields in database."""

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
    
    # Check items missing various fields
    cur.execute("""
        SELECT 
            COUNT(*) as total_items,
            COUNT(CASE WHEN icon_path IS NULL OR icon_path = '' THEN 1 END) as missing_icon,
            COUNT(CASE WHEN model_path IS NULL OR model_path = '' THEN 1 END) as missing_model,
            COUNT(CASE WHEN scale IS NULL OR scale = 0 THEN 1 END) as missing_scale,
            COUNT(CASE WHEN cooldown_group IS NULL OR cooldown_group = '' THEN 1 END) as missing_cooldown,
            COUNT(CASE WHEN tint_red IS NULL OR tint_red = 0 THEN 1 END) as default_tint_red,
            COUNT(CASE WHEN wc3_abilities IS NULL OR wc3_abilities = '' THEN 1 END) as missing_abilities
        FROM items
    """)
    
    row = cur.fetchone()
    total, no_icon, no_model, no_scale, no_cooldown, default_tint, no_abilities = row
    
    print("="*80)
    print("DATABASE FIELD COVERAGE:")
    print("="*80)
    print(f"Total items: {total}")
    print(f"\nMissing/Empty Fields:")
    print(f"  icon_path (iico):      {no_icon:4d} ({no_icon/total*100:5.1f}%)")
    print(f"  model_path (ifil):     {no_model:4d} ({no_model/total*100:5.1f}%)")
    print(f"  scale (isca):          {no_scale:4d} ({no_scale/total*100:5.1f}%)")
    print(f"  cooldown_group (icid): {no_cooldown:4d} ({no_cooldown/total*100:5.1f}%)")
    print(f"  tint_red (iclr):       {default_tint:4d} ({default_tint/total*100:5.1f}%)")
    print(f"  wc3_abilities (iabi):  {no_abilities:4d} ({no_abilities/total*100:5.1f}%)")
    
    # Show sample items with missing data
    print("\n" + "="*80)
    print("SAMPLE ITEMS WITH MISSING FIELDS:")
    print("="*80)
    
    cur.execute("""
        SELECT item_code, item_name,
               CASE WHEN icon_path IS NULL OR icon_path = '' THEN '✗' ELSE '✓' END as has_icon,
               CASE WHEN model_path IS NULL OR model_path = '' THEN '✗' ELSE '✓' END as has_model,
               CASE WHEN scale IS NULL OR scale = 0 THEN '✗' ELSE '✓' END as has_scale,
               CASE WHEN cooldown_group IS NULL OR cooldown_group = '' THEN '✗' ELSE '✓' END as has_cooldown,
               CASE WHEN wc3_abilities IS NULL OR wc3_abilities = '' THEN '✗' ELSE '✓' END as has_abilities
        FROM items
        WHERE (icon_path IS NULL OR icon_path = '')
           OR (model_path IS NULL OR model_path = '')
           OR (cooldown_group IS NULL OR cooldown_group = '')
           OR (wc3_abilities IS NULL OR wc3_abilities = '')
        ORDER BY item_code
        LIMIT 10
    """)
    
    rows = cur.fetchall()
    
    if rows:
        print("\nFirst 10 items with missing fields:")
        print("-"*80)
        print(f"{'Code':<8} {'Name':<30} {'Icon':<5} {'Model':<6} {'Scale':<6} {'Cool':<5} {'Abil':<5}")
        print("-"*80)
        for row in rows:
            code, name, icon, model, scale, cooldown, abilities = row
            name_short = name[:28] + '..' if len(name) > 30 else name
            print(f"{code:<8} {name_short:<30} {icon:<5} {model:<6} {scale:<6} {cooldown:<5} {abilities:<5}")
    else:
        print("\n✓ All items have complete field data!")
    
    # Check if any items have ALL fields populated
    cur.execute("""
        SELECT COUNT(*) as complete_items
        FROM items
        WHERE icon_path IS NOT NULL AND icon_path != ''
          AND model_path IS NOT NULL AND model_path != ''
          AND scale IS NOT NULL AND scale != 0
          AND (wc3_abilities IS NOT NULL OR cooldown_group IS NULL)
    """)
    
    complete = cur.fetchone()[0]
    print(f"\n✓ Items with complete visual data: {complete} ({complete/total*100:.1f}%)")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"[ERROR] {e}")
    import traceback
    traceback.print_exc()
