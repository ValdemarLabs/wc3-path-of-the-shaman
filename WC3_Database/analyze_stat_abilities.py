"""
Analyze stat-based abilities in the database to understand patterns
"""
import psycopg2
import re

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)
cur = conn.cursor()

print("\n=== Analyzing Stat-Based Abilities ===\n")

# Look for abilities with "Stats" or stat keywords in the name
stat_keywords = ['Stats_', 'stat_', 'Bonus', 'bonus', '%', 'Hit', 'Damage', 'Armor', 'Agility', 'Strength', 'Intelligence']

for keyword in stat_keywords:
    cur.execute("""
        SELECT ability_code, ability_name, editor_suffix 
        FROM wc3_abilities 
        WHERE ability_name ILIKE %s OR editor_suffix ILIKE %s
        ORDER BY ability_code
        LIMIT 20
    """, (f'%{keyword}%', f'%{keyword}%'))
    
    rows = cur.fetchall()
    if rows:
        print(f"\n--- Abilities matching '{keyword}' ({len(rows)} shown) ---")
        for r in rows:
            print(f"  {r[0]:<8} | {(r[1] or '')[:50]:<50} | {(r[2] or '')[:30]}")

# Look for abilities starting with A0
print(f"\n--- Abilities starting with 'A0' (likely custom stat abilities) ---")
cur.execute("""
    SELECT ability_code, ability_name, editor_suffix 
    FROM wc3_abilities 
    WHERE ability_code LIKE 'A0%'
    ORDER BY ability_code
    LIMIT 50
""")

rows = cur.fetchall()
for r in rows:
    print(f"  {r[0]:<8} | {(r[1] or '')[:50]:<50} | {(r[2] or '')[:30]}")

# Count abilities by prefix
print(f"\n--- Ability Code Prefixes (custom abilities) ---")
cur.execute("""
    SELECT SUBSTRING(ability_code, 1, 2) as prefix, COUNT(*) as count
    FROM wc3_abilities
    WHERE ability_code ~ '^[A-Z][0-9]'
    GROUP BY prefix
    ORDER BY prefix
""")

rows = cur.fetchall()
for r in rows:
    print(f"  {r[0]}: {r[1]} abilities")

conn.close()
