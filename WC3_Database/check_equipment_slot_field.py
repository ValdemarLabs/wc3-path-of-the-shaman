import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check how many items have equipment_slot populated
cursor.execute("""
    SELECT 
        CASE 
            WHEN equipment_slot IS NULL OR equipment_slot = '' THEN 'NO SLOT'
            ELSE 'HAS SLOT'
        END as has_slot,
        COUNT(*) as count
    FROM items
    WHERE deq_compatible = true
    GROUP BY has_slot
""")

print("Equipment slot population:")
print("="*60)
for has_slot, count in cursor.fetchall():
    print(f"  {has_slot:15} {count:5} items")

# Show items that HAVE equipment_slot defined
cursor.execute("""
    SELECT i.item_code, i.item_name, i.equipment_slot, ic.class_name
    FROM items i
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    WHERE i.deq_compatible = true
    AND i.equipment_slot IS NOT NULL
    AND i.equipment_slot != ''
    LIMIT 15
""")

print("\nExample items WITH equipment_slot defined:")
print("="*80)
for code, name, eq_slot, class_name in cursor.fetchall():
    print(f"  {code}: {eq_slot:12} {class_name:20} {name[:40]}")

cursor.close()
conn.close()

print()
print("="*80)
print("SOLUTION: Modify export script to use 'equipment_slot' field from database")
print("          instead of deriving it from 'class_name'")
print("="*80)
