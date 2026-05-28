import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Get column names from items table
cursor.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'items'
    ORDER BY ordinal_position
""")

columns = cursor.fetchall()
print("Columns in 'items' table:")
print("=" * 60)
for col_name, data_type in columns:
    print(f"{col_name:<30} {data_type}")

cursor.close()
conn.close()
