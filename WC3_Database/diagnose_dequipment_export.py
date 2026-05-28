import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check how many items have MISC class vs proper classes
cursor.execute("""
    SELECT ic.class_name, COUNT(*) as count
    FROM items i
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    WHERE i.deq_compatible = true
    GROUP BY ic.class_name
    ORDER BY count DESC
""")

print("DEquipment-compatible items by class:")
print("="*60)
for class_name, count in cursor.fetchall():
    print(f"  {class_name:30} {count:5} items")

print()
print("="*60)

# Check some example MISC items
cursor.execute("""
    SELECT i.item_code, i.item_name, i.equipment_slot
    FROM items i
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    WHERE i.deq_compatible = true 
    AND ic.class_name = 'MISC'
    LIMIT 10
""")

print("\nExample MISC items (these WON'T work in DEquipment export):")
print("="*60)
for code, name, eq_slot in cursor.fetchall():
    print(f"  {code}: {name:40} slot={eq_slot}")

print()

# Check items with proper classes
cursor.execute("""
    SELECT i.item_code, i.item_name, ic.class_name
    FROM items i
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    WHERE i.deq_compatible = true 
    AND ic.class_name != 'MISC'
    AND ic.class_name IS NOT NULL
    LIMIT 10
""")

print("\nExample items with proper classes (these WILL work):")
print("="*60)
for code, name, class_name in cursor.fetchall():
    print(f"  {code}: {name:40} class={class_name}")

cursor.close()
conn.close()

print()
print("="*60)
print("PROBLEM: Export script needs proper class names (not MISC)")
print("         to generate DEqItemTypeDefineAllowedSlotByName calls")
print("="*60)
