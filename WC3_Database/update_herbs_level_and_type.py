import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

print("Updating all herbs (i1c6 - i206) to have:")
print("  - item_level = 20")
print("  - type_id = 6 (Material)")
print()

# Update all herbs
cursor.execute("""
    UPDATE items
    SET 
        item_level = 20,
        type_id = 6
    WHERE item_code >= 'i1c6' AND item_code <= 'i206'
""")

rows_updated = cursor.rowcount
conn.commit()

print(f"✓ Updated {rows_updated} herbs")
print()

# Verify updates
cursor.execute("""
    SELECT i.item_code, i.item_name, i.item_level, it.type_name, ic.class_name
    FROM items i
    LEFT JOIN item_types it ON i.type_id = it.id
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    WHERE i.item_code >= 'i1c6' AND i.item_code <= 'i206'
    ORDER BY i.item_code
    LIMIT 10
""")

print("Verification - Sample herbs (first 10):")
for code, name, level, type_name, class_name in cursor.fetchall():
    print(f"  {code}: {name} - Level={level}, Type={type_name}, Class={class_name}")

# Get summary
cursor.execute("""
    SELECT COUNT(*), i.item_level, it.type_name
    FROM items i
    LEFT JOIN item_types it ON i.type_id = it.id
    WHERE i.item_code >= 'i1c6' AND i.item_code <= 'i206'
    GROUP BY i.item_level, it.type_name
""")

print()
print("Summary:")
for count, level, type_name in cursor.fetchall():
    print(f"  {count} herbs with Level={level}, Type={type_name}")

cursor.close()
conn.close()

print()
print("✓ ALL HERBS UPDATED SUCCESSFULLY!")
