import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Check all potion items
cur.execute("""
    SELECT item_code, item_name, base_id, cooldown_group, actively_used
    FROM items 
    WHERE item_name ILIKE '%potion%' OR base_id IN ('phea', 'pghe', 'pman', 'pmna')
    ORDER BY item_name
    LIMIT 30
""")

print("=== Potion Items ===\n")
for row in cur.fetchall():
    print(f"Code: {row[0]:<6} | Name: {row[1]:<40} | Base: {row[2]:<6} | CooldownGroup: {row[3]} | ActivelyUsed: {row[4]}")

# Check if there are any items with cooldown_group set
print("\n=== Items with Cooldown Group Set ===\n")
cur.execute("""
    SELECT item_code, item_name, cooldown_group
    FROM items 
    WHERE cooldown_group IS NOT NULL
    LIMIT 20
""")

for row in cur.fetchall():
    print(f"Code: {row[0]:<6} | Name: {row[1]:<40} | CooldownGroup: {row[2]}")

conn.close()
