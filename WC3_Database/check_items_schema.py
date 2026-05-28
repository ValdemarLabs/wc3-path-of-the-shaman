import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Get column names from items table
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'items'
    ORDER BY ordinal_position
""")

print("=== Items Table Columns ===\n")
for row in cur.fetchall():
    print(f"{row[0]}: {row[1]}")

conn.close()
