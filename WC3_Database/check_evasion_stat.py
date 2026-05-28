import psycopg2

DB_CONFIG = {
    'host': '127.0.0.1',
    'port': 5432,
    'database': 'wc3_pots',
    'user': 'postgres',
    'password': '009900'
}

conn = psycopg2.connect(**DB_CONFIG)
cursor = conn.cursor()

# Check for Evasion stat
cursor.execute("""
    SELECT id, stat_name, stat_code 
    FROM item_stats 
    WHERE stat_name ILIKE '%evasion%' OR stat_name ILIKE '%dodge%'
""")

print("Current Evasion/Dodge stats:")
print("=" * 80)
for row in cursor.fetchall():
    print(f"ID: {row[0]}, Name: '{row[1]}', Code: '{row[2]}'")

# Check how many items use this stat
cursor.execute("""
    SELECT COUNT(*) 
    FROM item_stat_values isv
    JOIN item_stats s ON isv.stat_id = s.id
    WHERE s.stat_name ILIKE '%evasion%'
""")
count = cursor.fetchone()[0]
print(f"\nItems using Evasion stat: {count}")

# Show some examples
cursor.execute("""
    SELECT i.item_code, i.item_name, isv.stat_value
    FROM item_stat_values isv
    JOIN item_stats s ON isv.stat_id = s.id
    JOIN items i ON isv.item_id = i.id
    WHERE s.stat_name ILIKE '%evasion%'
    LIMIT 5
""")
print("\nExample items with Evasion:")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]} → {row[2]}")

cursor.close()
conn.close()
