import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check current level and class for herbs we added
cursor.execute("""
    SELECT i.item_code, i.item_name, i.item_level, ic.class_name, i.class_id, it.type_name, i.type_id
    FROM items i
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    LEFT JOIN item_types it ON i.type_id = it.id
    WHERE i.item_code >= 'i1c6' AND i.item_code <= 'i206'
    ORDER BY i.item_code
    LIMIT 10
""")

print("Sample herbs (first 10):")
for code, name, level, class_name, class_id, type_name, type_id in cursor.fetchall():
    print(f"  {code}: {name} - level={level}, class={class_name} (id={class_id}), type={type_name} (id={type_id})")

# Check if Material class exists
cursor.execute("""
    SELECT id, class_name
    FROM item_classes
    WHERE class_name ILIKE '%material%'
""")

material_classes = cursor.fetchall()
print(f"\nMaterial-related classes:")
if material_classes:
    for class_id, class_name in material_classes:
        print(f"  {class_id}: {class_name}")
else:
    print("  No Material class found")

# Show all item classes
cursor.execute("""
    SELECT id, class_name
    FROM item_classes
    ORDER BY id
""")

print(f"\nAll item classes:")
for class_id, class_name in cursor.fetchall():
    print(f"  {class_id}: {class_name}")

# Check item_types table
cursor.execute("""
    SELECT id, type_name
    FROM item_types
    ORDER BY id
""")

print(f"\nAll item types:")
for type_id, type_name in cursor.fetchall():
    print(f"  {type_id}: {type_name}")

cursor.close()
conn.close()
