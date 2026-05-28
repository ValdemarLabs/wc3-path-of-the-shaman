"""
Test the ability debug display feature by generating sample ability codes
and showing what the debug display would look like
"""
import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)
cur = conn.cursor()

print("\n=== Ability Debug Display Demo ===\n")

# Sample ability codes (as they would appear in item)
sample_abilities = ["A04K", "A01H", "A6D7", "A04L", "ZZZZ"]  # Last one is invalid

print("Sample ability codes from item:")
print(f"  {', '.join(sample_abilities)}\n")

print("Debug display would show:\n")
print("="*90)
print(f"📋 Debug: {len(sample_abilities)} abilities")
print("─"*90)

for code in sample_abilities:
    cur.execute("""
        SELECT ability_code, ability_name, editor_suffix 
        FROM wc3_abilities 
        WHERE ability_code = %s
    """, (code,))
    
    row = cur.fetchone()
    
    if row:
        ability_code, name, suffix = row
        status = "✓"
        color = "GREEN"
        display_name = name or "(No Name)"
        display_suffix = suffix or ""
        print(f"{status}  {ability_code:<6} → {display_name:<45} {display_suffix}")
    else:
        status = "❌"
        color = "RED"
        print(f"{status}  {code:<6} → ⚠ NOT FOUND IN DATABASE")

print("="*90)

# Show stats about abilities
print("\n\n=== Sample Auto-Generated Abilities ===\n")

# Show Hit abilities
print("Hit Abilities (20% example):")
cur.execute("""
    SELECT ability_code, ability_name, editor_suffix 
    FROM wc3_abilities 
    WHERE ability_name = 'Stats_Hit' AND editor_suffix = '(20 %)'
    LIMIT 5
""")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]} {row[2]}")

# Show Crit abilities
print("\nCrit Abilities (15% example):")
cur.execute("""
    SELECT ability_code, ability_name, editor_suffix 
    FROM wc3_abilities 
    WHERE ability_name = 'Stats_Crit' AND editor_suffix = '(15 %)'
    LIMIT 5
""")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]} {row[2]}")

# Show Strength abilities
print("\nStrength Abilities (+10 example):")
cur.execute("""
    SELECT ability_code, ability_name, editor_suffix 
    FROM wc3_abilities 
    WHERE editor_suffix LIKE '(+10 Strength%)'
    LIMIT 5
""")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1] or '(Base ability)'} {row[2]}")

conn.close()

print("\n\n=== Feature Summary ===")
print("""
In the Item Edit window:
1. Enter ability codes in 'Abilities' field: A04K, A01H, A6D7
2. Check '🔍 Show Ability Names (Debug)' checkbox
3. Debug panel appears showing:
   ✓  A04K   → Stats_Hit                                   (20 %)
   ✓  A01H   → Stats_Crit                                  (15 %)
   ✓  A6D7   → (No Name)                                   (+10 Strength)
4. If invalid code entered, shows:
   ❌ ZZZZ   → ⚠ NOT FOUND IN DATABASE

Benefits:
- Instantly verify auto-generated abilities are correct
- Debug typos in ability codes
- See ability values without switching windows
- Toggle on/off to keep UI clean
""")
