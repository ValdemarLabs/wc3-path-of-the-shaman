"""
Check item database schema to understand how stats are stored
"""
import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)
cur = conn.cursor()

# Get table structure
print("=== Items Table Structure ===\n")
cur.execute("""
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_name = 'items'
    ORDER BY ordinal_position
""")

for row in cur.fetchall():
    print(f"{row[0]:<30} | {row[1]:<20} | Nullable: {row[2]:<3} | Default: {row[3] or 'None'}")

# Check if there's a separate stats table
print("\n\n=== Checking for item_stats table ===\n")
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_name LIKE '%stat%'
""")

rows = cur.fetchall()
if rows:
    for row in rows:
        print(f"  Found: {row[0]}")
else:
    print("  No separate stats table found")

# Sample items with stats
print("\n\n=== Sample Items (first 5) ===\n")
cur.execute("""
    SELECT item_code, name, abilities
    FROM items
    LIMIT 5
""")

for row in cur.fetchall():
    print(f"Code: {row[0]:<6} | Name: {row[1]:<40} | Abilities: {row[2] or 'None'}")

conn.close()
