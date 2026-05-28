import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check if items have equipment_slot or deq_compatible hints
cursor.execute("""
    SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN equipment_slot IS NOT NULL AND equipment_slot != '' THEN 1 END) as with_slot,
        COUNT(CASE WHEN deq_compatible = true THEN 1 END) as deq_items,
        COUNT(CASE WHEN c.class_name = 'MISC' THEN 1 END) as misc_class
    FROM items i
    LEFT JOIN item_classes c ON i.class_id = c.id
    WHERE i.base_id IS NOT NULL
""")

total, with_slot, deq_items, misc_class = cursor.fetchone()
print("Item Classification Status:")
print("=" * 60)
print(f"Total items with base_id:     {total}")
print(f"Items with equipment_slot:    {with_slot}")
print(f"Items marked deq_compatible:  {deq_items}")
print(f"Items classified as MISC:     {misc_class}")
print()

# Check sample items that are deq_compatible but classified as MISC
cursor.execute("""
    SELECT i.item_code, i.item_name, c.class_name, i.equipment_slot, i.deq_compatible
    FROM items i
    LEFT JOIN item_classes c ON i.class_id = c.id
    WHERE i.base_id IS NOT NULL 
      AND i.deq_compatible = true
      AND c.class_name = 'MISC'
    LIMIT 20
""")

print("Sample DEquipment items wrongly classified as MISC:")
print("=" * 100)
for code, name, cls, slot, deq in cursor.fetchall():
    slot_str = slot if slot else "(none)"
    print(f"{code}: {name:<45} class={cls}, slot={slot_str}")

print()

# Check if item names contain slot hints
cursor.execute("""
    SELECT i.item_code, i.item_name, c.class_name  
    FROM items i
    LEFT JOIN item_classes c ON i.class_id = c.id
    WHERE i.base_id IS NOT NULL
      AND c.class_name = 'MISC'
      AND (
          i.item_name ILIKE '%ring%' OR
          i.item_name ILIKE '%belt%' OR  
          i.item_name ILIKE '%glove%' OR
          i.item_name ILIKE '%boot%' OR
          i.item_name ILIKE '%chest%' OR
          i.item_name ILIKE '%helm%' OR
          i.item_name ILIKE '%armor%' OR
          i.item_name ILIKE '%shield%' OR
          i.item_name ILIKE '%neck%' OR
          i.item_name ILIKE '%amulet%'
      )
    LIMIT 20
""")

results = cursor.fetchall()
if results:
    print("\nMISC items with equipment hints in name:")
    print("=" * 100)
    for code, name, cls in results:
        print(f"{code}: {name:<50} (currently: {cls})")

cursor.close()
conn.close()
