"""
Analyze stat coverage between database and StatAbilityMapper
"""
import psycopg2
import configparser

config = configparser.ConfigParser()
config.read('config/database.ini')

conn = psycopg2.connect(**dict(config['postgresql']))
cur = conn.cursor()

# Get all stats from database
cur.execute("""
    SELECT id, stat_code, stat_name 
    FROM item_stats 
    ORDER BY id
""")
db_stats = cur.fetchall()

# Stats that have abilities mapped in StatAbilityMapper (from the C# code)
mapped_stats = {
    "Hit": "hit",
    "Crit": "crit",
    "Block": "block", 
    "Dodge": "evasion",
    "Spell": "spell_power",  # or spell_power_pct
    "Strength": "str",
    "Agility": "agi",
    "Intelligence": "int",
    "Mana": "mp",
    "Health": "hp",
    "HP": "hp",
    "Damage": "dmg",
    "Armor": "armor",
    "Attack Speed": "aspd",
    "Movement Speed": "ms"
}

print("=" * 80)
print("STAT COVERAGE ANALYSIS")
print("=" * 80)
print()
print(f"Total stats in database: {len(db_stats)}")
print(f"Stats with abilities in StatAbilityMapper: {len(set(mapped_stats.values()))}")
print()

# Find unmapped stats
mapped_codes = set(mapped_stats.values())
unmapped = []

print("STATS WITH ABILITIES MAPPED:")
print("-" * 80)
for display_name, stat_code in mapped_stats.items():
    matching = [s for s in db_stats if s[1] == stat_code]
    if matching:
        print(f"  ✓ {stat_code:20s} ({matching[0][2]:25s}) -> {display_name}")
    else:
        print(f"  ? {stat_code:20s} (NOT IN DB) -> {display_name}")
print()

print("STATS WITHOUT ABILITIES (NEED TO BE CREATED IN WE):")
print("-" * 80)
for id, stat_code, stat_name in db_stats:
    if stat_code not in mapped_codes:
        unmapped.append((id, stat_code, stat_name))
        print(f"  ✗ {id:2d}. {stat_code:20s} ({stat_name})")

print()
print("=" * 80)
print(f"SUMMARY: {len(unmapped)} stats need abilities created")
print("=" * 80)

conn.close()
