"""
Script to create wc3_base_items table
"""
import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        database="wc3_pots",
        user="postgres",
        password="009900"
    )
    
    with open('H:/Pelit/PotS_JASS/WC3_Database/database/base_items.sql', 'r', encoding='utf-8') as f:
        sql = f.read()
    
    cur = conn.cursor()
    cur.execute(sql)
    conn.commit()
    
    # Verify
    cur.execute("SELECT COUNT(*) FROM wc3_base_items")
    count = cur.fetchone()[0]
    print(f"✓ Table created successfully! Inserted {count} base items.")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"Error: {e}")
