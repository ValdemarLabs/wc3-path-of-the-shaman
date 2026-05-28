import psycopg2

# Database connection
conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)
cursor = conn.cursor()

# Check items without model_path
cursor.execute("""
    SELECT item_code, item_name, model_path
    FROM items
    WHERE model_path IS NULL OR model_path = ''
    ORDER BY item_code
    LIMIT 50
""")

results = cursor.fetchall()
print(f"Items without model_path: {len(results)}")
print("\nFirst 50 items:")
for item_code, item_name, model_path in results:
    print(f"  {item_code}: {item_name} - model_path: {model_path}")

# Get total count
cursor.execute("""
    SELECT COUNT(*)
    FROM items
    WHERE model_path IS NULL OR model_path = ''
""")
total = cursor.fetchone()[0]
print(f"\nTotal items without model_path: {total}")

cursor.close()
conn.close()
