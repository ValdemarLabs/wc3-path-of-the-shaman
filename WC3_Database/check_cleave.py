import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()
cur.execute("SELECT stat_name, display_format, stat_code FROM item_stats WHERE stat_name ILIKE '%cleave%'")
rows = cur.fetchall()

for row in rows:
    print(f"stat_name: {row[0]}")
    print(f"display_format: {row[1]}")
    print(f"stat_code: {row[2]}")
    print()

conn.close()
