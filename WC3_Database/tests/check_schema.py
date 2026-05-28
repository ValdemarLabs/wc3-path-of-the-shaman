"""
Check database schema fields
"""

import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port='5432',
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()
cur.execute("""
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name='items' 
    ORDER BY ordinal_position
""")

print("All fields in items table:")
for i, row in enumerate(cur.fetchall(), 1):
    print(f"  {i}. {row[0]}")

# Count fields
cur.execute("SELECT COUNT(*) FROM information_schema.columns WHERE table_name='items'")
count = cur.fetchone()[0]
print(f"\nTotal: {count} fields")

conn.close()
