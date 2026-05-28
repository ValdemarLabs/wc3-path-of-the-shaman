#!/usr/bin/env python3
"""Check which boolean field columns exist in database."""

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
    
    # Get column names from items table
    cur.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'items' 
          AND column_name IN (
              'actively_used', 'use_automatically',
              'dropped_on_death', 'drops_on_death'
          )
        ORDER BY column_name
    """)
    
    columns = [row[0] for row in cur.fetchall()]
    
    print("Boolean field columns in items table:")
    for col in columns:
        print(f"  - {col}")
    
    if not columns:
        print("  (None of these columns exist)")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"[ERROR] {e}")
    import traceback
    traceback.print_exc()
