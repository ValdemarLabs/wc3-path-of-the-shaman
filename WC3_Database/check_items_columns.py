import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check what columns exist in items table
cursor.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'items'
    ORDER BY ordinal_position
""")

print("Items table columns:")
for col_name, data_type in cursor.fetchall():
    print(f"  {col_name}: {data_type}")

cursor.close()
conn.close()
