import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check what classes exist
cursor.execute("""
    SELECT id, class_name, description
    FROM item_classes
    ORDER BY class_name
""")

classes = cursor.fetchall()
print("Item classes in database:")
print("=" * 70)
for class_id, class_name, desc in classes:
    desc_str = f" - {desc}" if desc else ""
    print(f"{class_id:>2}. {class_name:<30}{desc_str}")

print("\n")

# Check how many items are assigned to each class
cursor.execute("""
    SELECT c.class_name, COUNT(i.id) as item_count
    FROM item_classes c
    LEFT JOIN items i ON c.id = i.class_id
    GROUP BY c.id, c.class_name
    ORDER BY item_count DESC, c.class_name
""")

class_counts = cursor.fetchall()
print("Items per class:")
print("=" * 50)
for class_name, count in class_counts:
    print(f"{class_name:<30} {count:>4} items")

print("\n")

# Show sample items from equipment classes
cursor.execute("""
    SELECT i.item_code, i.item_name, c.class_name
    FROM items i
    JOIN item_classes c ON i.class_id = c.id
    WHERE c.class_name LIKE '%ARMOR%' 
       OR c.class_name LIKE '%RING%'
       OR c.class_name LIKE '%GLOVE%'
       OR c.class_name LIKE '%BOOT%'
       OR c.class_name LIKE '%BELT%'
    LIMIT 15
""")

sample_items = cursor.fetchall()
print("Sample equipment items:")
print("=" * 80)
for code, name, class_name in sample_items:
    print(f"{code}: {name:<45} (class={class_name})")

cursor.close()
conn.close()
