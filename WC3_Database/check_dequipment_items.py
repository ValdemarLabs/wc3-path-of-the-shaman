import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check the two items mentioned
cursor.execute("""
    SELECT i.item_code, i.item_name, ic.class_name, i.equipment_slot, i.deq_compatible
    FROM items i
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    WHERE UPPER(i.item_code) IN ('I6CF', 'I6CB')
    ORDER BY i.item_code
""")

print("Items I6CF and I6CB in database:")
print("="*80)
for code, name, class_name, eq_slot, deq_compat in cursor.fetchall():
    print(f"Code: {code}")
    print(f"Name: {name}")
    print(f"Class: {class_name}")
    print(f"Equipment Slot: {eq_slot}")
    print(f"DEq Compatible: {deq_compat}")
    print("-"*80)

# Check what items have proper equipment slots defined
cursor.execute("""
    SELECT i.item_code, i.item_name, ic.class_name, i.equipment_slot, i.deq_compatible
    FROM items i
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    WHERE i.equipment_slot IS NOT NULL 
    AND i.deq_compatible = true
    ORDER BY i.item_code
    LIMIT 10
""")

print("\nExample items with equipment_slot defined:")
print("="*80)
for code, name, class_name, eq_slot, deq_compat in cursor.fetchall():
    print(f"{code}: {name:30} | Class: {class_name:15} | Slot: {eq_slot:10} | DEq: {deq_compat}")

cursor.close()
conn.close()
