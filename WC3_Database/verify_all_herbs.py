import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Get all herbs with their updated values
cursor.execute("""
    SELECT i.item_code, i.item_name, i.item_level, it.type_name, ic.class_name, ir.rarity_name, i.gold_cost
    FROM items i
    LEFT JOIN item_types it ON i.type_id = it.id
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    LEFT JOIN item_rarities ir ON i.rarity_id = ir.id
    WHERE i.item_code >= 'i1c6' AND i.item_code <= 'i206'
    ORDER BY i.item_code
""")

results = cursor.fetchall()

print(f"All {len(results)} herbs updated:")
print()

for code, name, level, type_name, class_name, rarity, cost in results:
    print(f"{code}: {name:25} | Level={level:2} | Type={type_name:10} | Rarity={rarity:10} | Cost={cost:4}g")

cursor.close()
conn.close()
