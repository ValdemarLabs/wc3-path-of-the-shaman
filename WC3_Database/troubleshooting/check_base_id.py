"""
Check database for base_id field to determine original vs custom
"""

import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port='5432',
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Check if base_id column exists
cur.execute("""
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name='items' 
    AND column_name IN ('base_id', 'base_item_code', 'is_custom', 'is_original')
""")
print("Relevant columns:", [row[0] for row in cur.fetchall()])

# Check base_id values
cur.execute("SELECT item_code, base_id FROM items WHERE base_id IS NOT NULL ORDER BY item_code LIMIT 10")
print("\nItems with base_id (first 10):")
for row in cur.fetchall():
    print(f"  {row[0]}: base_id={row[1]}")

# Check items that should be in original table (like shea, phea)
cur.execute("SELECT item_code, base_id FROM items WHERE item_code IN ('shea', 'phea', 'pman', 'olig', 'oli2')")
print("\nOriginal table items from original file:")
for row in cur.fetchall():
    print(f"  {row[0]}: base_id={row[1]}")

# Check what we're exporting as original
cur.execute("""
    SELECT item_code, base_id 
    FROM items 
    WHERE base_id = item_code OR base_id IS NULL
    ORDER BY item_code 
    LIMIT 10
""")
print("\nWhat we classify as original (first 10):")
for row in cur.fetchall():
    print(f"  {row[0]}: base_id={row[1]}")

conn.close()
