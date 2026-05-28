"""
Build comprehensive stat ability mapping for item stat system
"""
import psycopg2
import re
from collections import defaultdict

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)
cur = conn.cursor()

print("\n=== Building Stat Ability Mapping ===\n")

# Get all abilities with stat patterns
cur.execute("""
    SELECT ability_code, ability_name, editor_suffix 
    FROM wc3_abilities 
    WHERE ability_name LIKE 'Stats_%' 
       OR editor_suffix ~ '\\([0-9]+ ?%\\)'
       OR editor_suffix ~ '\\(\\+[0-9]+ (Strength|Agility|Intelligence|Armor|Damage)\\)'
       OR ability_name LIKE 'Item % Bonus%'
       OR ability_name LIKE 'Item Hit Rating%'
    ORDER BY ability_name, ability_code
""")

rows = cur.fetchall()

# Group by stat type
stat_map = defaultdict(list)

for code, name, suffix in rows:
    # Extract stat type and value
    stat_type = None
    value = None
    
    if name and 'Stats_' in name:
        # Extract stat type from name
        stat_type = name.replace('Stats_', '').strip()
        
    # Parse editor_suffix for value
    if suffix:
        # Match patterns like (5 %), (20%), (+8 Strength), etc.
        percent_match = re.search(r'\(([0-9]+)\s*%\)', suffix)
        attr_match = re.search(r'\(\+([0-9]+)\s+(Strength|Agility|Intelligence|Armor|Damage)\)', suffix)
        
        if percent_match:
            value = int(percent_match.group(1))
        elif attr_match:
            value = int(attr_match.group(1))
            if not stat_type:
                stat_type = attr_match.group(2)
    
    # Also check name for clues
    if not stat_type and name:
        if 'Hit Rating' in name or 'Hit Chance' in name:
            stat_type = 'Hit'
            # Try to extract percent from suffix
            hit_match = re.search(r'([0-9]+)%', suffix) if suffix else None
            if hit_match:
                value = int(hit_match.group(1))
        elif 'Mana Bonus' in name:
            stat_type = 'Mana'
            mana_match = re.search(r'\(([0-9]+)\)', suffix or name)
            if mana_match:
                value = int(mana_match.group(1))
    
    if stat_type and value is not None:
        stat_map[stat_type].append({
            'code': code,
            'name': name,
            'suffix': suffix,
            'value': value
        })

# Print organized mapping
print("="*80)
for stat_type in sorted(stat_map.keys()):
    abilities = sorted(stat_map[stat_type], key=lambda x: x['value'])
    print(f"\n{stat_type} ({len(abilities)} abilities):")
    print("-" * 80)
    for ability in abilities:
        suffix_str = (ability['suffix'] or '')[:30]
        name_str = (ability['name'] or '')[:40]
        print(f"  {ability['code']:<8} = {ability['value']:>4} | {name_str:<40} | {suffix_str}")

# Generate JSON-like structure for easy use
print("\n\n=== Ability Selection Algorithm Output ===\n")
print("Stat mapping structure for code generation:")
print("```")
for stat_type in sorted(stat_map.keys()):
    abilities = sorted(stat_map[stat_type], key=lambda x: x['value'])
    print(f"\n  '{stat_type}': [")
    for ability in abilities:
        print(f"    {{ 'code': '{ability['code']}', 'value': {ability['value']} }},")
    print("  ],")
print("```")

# Test: Find combination for Hit 25%
print("\n\n=== Example: Finding abilities for Hit 25% ===")

def find_ability_combination(stat_type, target_value, available_abilities):
    """
    Find the best combination of abilities to reach target value.
    Uses greedy algorithm: pick largest values first to minimize ability count.
    """
    abilities = sorted(available_abilities, key=lambda x: x['value'], reverse=True)
    selected = []
    remaining = target_value
    
    for ability in abilities:
        while remaining >= ability['value']:
            selected.append(ability['code'])
            remaining -= ability['value']
            if remaining == 0:
                break
    
    return selected, remaining

if 'Hit' in stat_map:
    combination, remaining = find_ability_combination('Hit', 25, stat_map['Hit'])
    print(f"Target: Hit 25%")
    print(f"Selected abilities: {', '.join(combination)}")
    print(f"Remaining value: {remaining}")
    
    # Show what each ability contributes
    print("\nBreakdown:")
    for code in combination:
        ability = next(a for a in stat_map['Hit'] if a['code'] == code)
        print(f"  {code}: +{ability['value']}%")

conn.close()
