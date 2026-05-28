import psycopg2
import re

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# List of herb model paths from user
herb_models = [
    "world_skillactivated_tradeskillnodes_bush_ancientlichen",
    "world_skillactivated_tradeskillnodes_bush_arthastears",
    "world_skillactivated_tradeskillnodes_bush_azsharasveil",
    "world_skillactivated_tradeskillnodes_bush_blacklotus",
    "world_skillactivated_tradeskillnodes_bush_blindweed",
    "world_skillactivated_tradeskillnodes_bush_bloodthistle",
    "world_skillactivated_tradeskillnodes_bush_bruiseweed01",
    "world_skillactivated_tradeskillnodes_bush_chameleonlotus",
    "world_skillactivated_tradeskillnodes_bush_cinderbloom",
    "world_skillactivated_tradeskillnodes_bush_constrictorgrass",
    "world_skillactivated_tradeskillnodes_bush_crownroyal01",
    "world_skillactivated_tradeskillnodes_bush_dragonsteeth",
    "world_skillactivated_tradeskillnodes_bush_dreamfoil",
    "world_skillactivated_tradeskillnodes_bush_dreamingglory",
    "world_skillactivated_tradeskillnodes_bush_evergreenmoss",
    "world_skillactivated_tradeskillnodes_bush_fadeleaf01",
    "world_skillactivated_tradeskillnodes_bush_felweed",
    "world_skillactivated_tradeskillnodes_bush_firebloom",
    "world_skillactivated_tradeskillnodes_bush_fireweed",
    "world_skillactivated_tradeskillnodes_bush_flamecap",
    "world_skillactivated_tradeskillnodes_bush_foolscap",
    "world_skillactivated_tradeskillnodes_bush_frostlotus",
    "world_skillactivated_tradeskillnodes_bush_frostweed",
    "world_skillactivated_tradeskillnodes_bush_frozenherb",
    "world_skillactivated_tradeskillnodes_bush_goldclover",
    "world_skillactivated_tradeskillnodes_bush_goldenlotus",
    "world_skillactivated_tradeskillnodes_bush_gravemoss01",
    "world_skillactivated_tradeskillnodes_bush_gromsblood",
    "world_skillactivated_tradeskillnodes_bush_heartblossom",
    "world_skillactivated_tradeskillnodes_bush_icecap",
    "world_skillactivated_tradeskillnodes_bush_jadetealeaf",
    "world_skillactivated_tradeskillnodes_bush_khadgarswhisker01",
    "world_skillactivated_tradeskillnodes_bush_magebloom01",
    "world_skillactivated_tradeskillnodes_bush_manathistle",
    "world_skillactivated_tradeskillnodes_bush_mountainsilversage",
    "world_skillactivated_tradeskillnodes_bush_mushroom03",
    "world_skillactivated_tradeskillnodes_bush_mushroom02",
    "world_skillactivated_tradeskillnodes_bush_mushroom01",
    "world_skillactivated_tradeskillnodes_bush_netherbloom",
    "world_skillactivated_tradeskillnodes_bush_nightmarevine",
    "world_skillactivated_tradeskillnodes_bush_peacebloom01",
    "world_skillactivated_tradeskillnodes_bush_plaguebloom",
    "world_skillactivated_tradeskillnodes_bush_purplelotus",
    "world_skillactivated_tradeskillnodes_bush_ragveil",
    "world_skillactivated_tradeskillnodes_bush_rainpoppy",
    "world_skillactivated_tradeskillnodes_bush_sansam",
    "world_skillactivated_tradeskillnodes_bush_shaherb",
    "world_skillactivated_tradeskillnodes_bush_silkweed",
    "world_skillactivated_tradeskillnodes_bush_silverleaf01",
    "world_skillactivated_tradeskillnodes_bush_snowlily",
    "world_skillactivated_tradeskillnodes_bush_spineleaf",
    "world_skillactivated_tradeskillnodes_bush_stardust",
    "world_skillactivated_tradeskillnodes_bush_starflower",
    "world_skillactivated_tradeskillnodes_bush_steelbloom01",
    "world_skillactivated_tradeskillnodes_bush_stormvine",
    "world_skillactivated_tradeskillnodes_bush_stormvinebubbles",
    "world_skillactivated_tradeskillnodes_bush_stranglekelp01",
    "world_skillactivated_tradeskillnodes_bush_sungrass",
    "world_skillactivated_tradeskillnodes_bush_swiftthistle01",
    "world_skillactivated_tradeskillnodes_bush_taladororchid",
    "world_skillactivated_tradeskillnodes_bush_talandrasrose",
    "world_skillactivated_tradeskillnodes_bush_goldthorn01",
    "world_skillactivated_tradeskillnodes_bush_icethorn",
    "world_skillactivated_tradeskillnodes_bush_terrocone",
    "world_skillactivated_tradeskillnodes_bush_tigerlily",
    "world_skillactivated_tradeskillnodes_bush_twilightjasmine",
    "world_skillactivated_tradeskillnodes_bush_whiptail01",
    "world_skillactivated_tradeskillnodes_bush_whispervine",
    "world_skillactivated_tradeskillnodes_bush_wintersbite01",
    "world_skillactivated_tradeskillnodes_stranglekelp_01",
    "world_skillactivated_tradeskillnodes_bush_liferoot01",
    "world_skillactivated_tradeskillnodes_bush_snakeroot",
    "world_skillactivated_tradeskillnodes_bush_thornroot01"
]

def extract_herb_name(model_path):
    """Extract clean herb name from model path"""
    # Remove prefix and get the herb part
    herb_part = model_path.replace("world_skillactivated_tradeskillnodes_bush_", "")
    herb_part = herb_part.replace("world_skillactivated_tradeskillnodes_", "")
    
    # Remove trailing numbers
    herb_part = re.sub(r'\d+$', '', herb_part)
    herb_part = re.sub(r'_$', '', herb_part)  # Remove trailing underscore
    
    # Split by underscore and capitalize each word
    words = herb_part.split('_')
    words = [w.capitalize() for w in words if w]
    
    # Join words
    name = ' '.join(words)
    
    # Fix specific naming patterns for possessive names
    name = name.replace('Arthastears', "Arthas' Tears")
    name = name.replace('Azsharasveil', "Azshara's Veil")
    name = name.replace('Khadgarswhisker', "Khadgar's Whisker")
    name = name.replace('Talandrasrose', "Talandra's Rose")
    
    return name

# Check existing herbs in database
cursor.execute("""
    SELECT item_name, model_path
    FROM items
    WHERE model_path ILIKE '%herb%' 
       OR model_path ILIKE '%bush%'
       OR model_path ILIKE '%tradeskillnodes%'
""")

existing = {row[1]: row[0] for row in cursor.fetchall() if row[1]}

print("=" * 100)
print("HERB ANALYSIS")
print("=" * 100)
print(f"\nTotal herbs to add: {len(herb_models)}")
print(f"Existing herbs in database: {len(existing)}")

# Find which ones need to be added
new_herbs = []
already_exist = []

for model in herb_models:
    herb_name = extract_herb_name(model)
    
    # Check if already exists
    if any(model in existing_model for existing_model in existing.keys()):
        already_exist.append((herb_name, model))
    else:
        new_herbs.append((herb_name, model))

print(f"Herbs that need to be added: {len(new_herbs)}")
print(f"Herbs already in database: {len(already_exist)}")

if already_exist:
    print("\nAlready existing:")
    for name, model in already_exist[:10]:
        print(f"  ✓ {name:<30} ({model})")
    if len(already_exist) > 10:
        print(f"  ... and {len(already_exist) - 10} more")

print("\nNew herbs to add:")
for name, model in new_herbs[:20]:
    print(f"  + {name:<30} ({model})")
if len(new_herbs) > 20:
    print(f"  ... and {len(new_herbs) - 20} more")

cursor.close()
conn.close()
