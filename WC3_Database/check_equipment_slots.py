import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
   user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check items with equipment_slot populated
cursor.execute("""
    SELECT item_code, item_name, equipment_slot, deq_compatible 
    FROM items 
    WHERE equipment_slot IS NOT NULL AND equipment_slot != ''
    ORDER BY equipment_slot
    LIMIT 20
""")

rows = cursor.fetchall()
print(f"Items with equipment_slot populated: {len(rows)}")
print("=" * 90)
for item_code, item_name, equipment_slot, deq_compat in rows:
    compat_str = "DEQ:YES" if deq_compat else "DEQ:NO"
    print(f"{item_code}: {item_name:<45} slot={equipment_slot:<15} {compat_str}")

print("\n")

# Check total count
cursor.execute("""
    SELECT COUNT(*) 
    FROM items 
    WHERE equipment_slot IS NOT NULL AND equipment_slot != ''
""")
total = cursor.fetchone()[0]
print(f"Total items with equipment_slot: {total}")

print("\n")

# Check what unique equipment_slot values exist
cursor.execute("""
    SELECT equipment_slot, COUNT(*) as count
    FROM items 
    WHERE equipment_slot IS NOT NULL AND equipment_slot != ''
    GROUP BY equipment_slot
    ORDER BY count DESC
""")
slots = cursor.fetchall()
print("Equipment slot values in database:")
print("=" * 50)
for slot, count in slots:
    print(f"{slot:<20} {count:>3} items")

cursor.close()
conn.close()
