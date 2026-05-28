"""Check for EQUIP_ abilities in database"""
import psycopg2
import configparser

config = configparser.ConfigParser()
config.read('config/database.ini')

conn = psycopg2.connect(**dict(config['postgresql']))
cur = conn.cursor()

# Check for abilities starting with EQUIP_ or containing Equip
cur.execute("""
    SELECT ability_code, ability_name, editor_suffix 
    FROM wc3_abilities 
    WHERE ability_code LIKE 'EQUIP%' OR ability_name ILIKE '%equip%'
    ORDER BY ability_name
""")

rows = cur.fetchall()
print(f"Found {len(rows)} EQUIP-related abilities:\n")

for r in rows[:30]:
    code = r[0]
    name = r[1] or '(No Name)'
    suffix = r[2] or '(No Suffix)'
    print(f"  {name} ({code}) - Editor: {suffix}")

conn.close()
