"""Quick script to check imported abilities"""
import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)
cur = conn.cursor()

# Get total count
cur.execute('SELECT COUNT(*) FROM wc3_abilities')
count = cur.fetchone()[0]
print(f"\nTotal abilities in database: {count}\n")

# Get sample with names
cur.execute("SELECT ability_code, ability_name, editor_suffix FROM wc3_abilities WHERE ability_name IS NOT NULL AND ability_name != '' LIMIT 20")
rows = cur.fetchall()

print(f"Abilities with custom names ({len(rows)} shown):")
print(f"{'Code':<8} | {'Name':<45} | {'Editor Suffix':<20}")
print("-" * 80)
for r in rows:
    name = (r[1] or '')[:45]
    suffix = (r[2] or '')[:20]
    print(f"{r[0]:<8} | {name:<45} | {suffix:<20}")

conn.close()
