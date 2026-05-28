import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check properly classified items (not MISC)
cursor.execute("""
    SELECT i.item_code, i.item_name, c.class_name, i.equipment_slot, i.deq_compatible, i.base_id
    FROM items i
    JOIN item_classes c ON i.class_id = c.id
    WHERE c.class_name IN ('Chest Armor', 'Ring', 'Belt', 'Hand Armor', 'Foot Armor', 'Head Armor')
      AND i.base_id IS NOT NULL
    ORDER BY c.class_name, i.item_name
""")

classified_items = cursor.fetchall()

print("Properly Classified Equipment Items:")
print("=" * 120)
print(f"{'Code':<8} {'Name':<45} {'Class':<20} {'Slot':<15} {'DEQ?':<6} {'Base'}")
print("=" * 120)

for code, name, cls, slot, deq, base in classified_items:
    slot_str = slot if slot else "(none)"
    deq_str = "YES" if deq else "NO"
    print(f"{code:<8} {name:<45} {cls:<20} {slot_str:<15} {deq_str:<6} {base}")

print(f"\nTotal: {len(classified_items)} items")
print()

# Check if export script would include them
cursor.execute("""
    SELECT COUNT(*) 
    FROM items i
    JOIN item_classes c ON i.class_id = c.id
    WHERE c.class_name IN ('Chest Armor', 'Ring', 'Belt', 'Hand Armor', 'Foot Armor', 'Head Armor')
      AND i.base_id IS NOT NULL
      AND (i.deq_compatible = true OR i.deq_compatible IS NULL)
""")

exportable = cursor.fetchone()[0]
print(f"Items that would be included in export (has base_id): {exportable}")

# Show what get_item_slot() function would return for these class names
print("\nget_item_slot() mapping test:")
print("=" * 60)

class_mappings = {
    'Chest Armor': 'Should match "CHEST" or "ARMOR" pattern',
    'Ring': 'Should match "RING" pattern',
    'Belt': 'Should match "BELT" pattern', 
    'Hand Armor': 'Should match "HAND" or "GLOVE" pattern',
    'Foot Armor': 'Should match "BOOT" or "FOOT" pattern',
    'Head Armor': 'Should match "HEAD" or "HELM" pattern'
}

for cls, expected in class_mappings.items():
    print(f"{cls:<30} -> {expected}")

cursor.close()
conn.close()
