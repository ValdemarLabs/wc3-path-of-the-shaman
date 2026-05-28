#!/usr/bin/env python3
"""Backfill classification for items with NULL wc3_classification."""

import psycopg2

# Database configuration
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
    
    # Update NULL classifications to 'Permanent'
    cur.execute("""
        UPDATE items 
        SET wc3_classification = 'Permanent' 
        WHERE wc3_classification IS NULL OR wc3_classification = ''
    """)
    
    updated_count = cur.rowcount
    conn.commit()
    
    print(f"[OK] Updated {updated_count} items to have default classification 'Permanent'")
    
    # Report results
    cur.execute("""
        SELECT 
            COUNT(*) as total_items,
            COUNT(CASE WHEN wc3_classification = 'Permanent' THEN 1 END) as permanent_items,
            COUNT(CASE WHEN wc3_classification = 'Charged' THEN 1 END) as charged_items,
            COUNT(CASE WHEN wc3_classification IS NULL THEN 1 END) as null_items
        FROM items
    """)
    
    row = cur.fetchone()
    print(f"\nClassification Summary:")
    print(f"  Total items: {row[0]}")
    print(f"  Permanent: {row[1]}")
    print(f"  Charged: {row[2]}")
    print(f"  NULL: {row[3]}")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"[ERROR] {e}")
    import traceback
    traceback.print_exc()
