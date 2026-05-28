import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Get column names
cursor.execute("""
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'items' 
      AND column_name ILIKE '%model%'
    ORDER BY column_name
""")

model_columns = cursor.fetchall()
print("Model-related columns in items table:")
for col in model_columns:
    print(f"  - {col[0]}")

cursor.close()
conn.close()
