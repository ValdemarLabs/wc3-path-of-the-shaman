import psycopg2

conn = psycopg2.connect(
    dbname='wc3_pots',
    user='postgres',
    password='009900',
    host='127.0.0.1',
    port=5432
)

cursor = conn.cursor()

# Check items with equipment classes
cursor.execute("""
    SELECT item_code, item_name, class 
    FROM items 
    WHERE class IN ('CHEST_ARMOR', 'RING', 'BELT', 'GLOVES', 'BOOTS', 'HELMET')
    LIMIT 15
""")

rows = cursor.fetchall()
print("Sample items with equipment classes:")
print("=" * 70)
for item_code, item_name, item_class in rows:
    print(f"{item_code}: {item_name:<40} (class={item_class})")

print("\n")

# Check if ANY items have slot field populated
cursor.execute("""
    SELECT COUNT(*) 
    FROM items 
    WHERE slot IS NOT NULL AND slot != ''
""")
slot_count = cursor.fetchone()[0]
print(f"Items with 'slot' field populated: {slot_count}")

# Show some items with slot field
if slot_count > 0:
    cursor.execute("""
        SELECT item_code, item_name, slot, class 
        FROM items 
        WHERE slot IS NOT NULL AND slot != ''
        LIMIT 10
    """)
    rows = cursor.fetchall()
    print("\nItems with slot field:")
    print("=" * 70)
    for item_code, item_name, slot, item_class in rows:
        print(f"{item_code}: {item_name:<30} slot={slot:<15} class={item_class}")

cursor.close()
conn.close()
