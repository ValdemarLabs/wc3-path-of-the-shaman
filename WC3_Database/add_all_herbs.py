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

print("=" * 100)
print("ADDING HERBS TO DATABASE")
print("=" * 100)

# Step 1: Create/Get Material class
cursor.execute("""
    SELECT id FROM item_classes WHERE class_name = 'Miscellaneous'
""")
result = cursor.fetchone()
material_class_id = result[0] if result else None

if not material_class_id:
    print("\n⚠ Miscellaneous class not found, using MISC")
    cursor.execute("SELECT id FROM item_classes WHERE class_name = 'MISC'")
    result = cursor.fetchone()
    material_class_id = result[0] if result else 13  # Default MISC ID

print(f"✓ Using class ID: {material_class_id} for herbs")

# Step 2: Get rarity IDs
cursor.execute("SELECT id, rarity_name FROM item_rarities WHERE rarity_name IN('Common', 'Uncommon', 'Rare', 'Epic')")
rarities = {row[1]: row[0] for row in cursor.fetchall()}
print(f"✓ Found rarities: {list(rarities.keys())}")

# Step 3: Define herbs with WoW-based rarity and pricing
# Pricing based on WoW herb values and rarity
herbs_data = [
    ("ancientlichen", "Ancient Lichen", "Uncommon", 150),
    ("arthastears", "Arthas' Tears", "Rare", 250),
    ("azsharasveil", "Azshara's Veil", "Rare", 300),
    ("blacklotus", "Black Lotus", "Epic", 1000),
    ("blindweed", "Blindweed", "Common", 100),
    ("bloodthistle", "Bloodthistle", "Common", 75),
    ("bruiseweed01", "Bruiseweed", "Common", 80),
    ("chameleonlotus", "Chameleon Lotus", "Rare", 400),
    ("cinderbloom", "Cinderbloom", "Common", 120),
    ("constrictorgrass", "Constrictor Grass", "Uncommon", 180),
    ("crownroyal01", "Crown Royal", "Rare", 350),
    ("dragonsteeth", "Dragon's Teeth", "Rare", 450),
    ("dreamfoil", "Dreamfoil", "Uncommon", 200),
    ("dreamingglory", "Dreaming Glory", "Uncommon", 175),
    ("evergreenmoss", "Evergreen Moss", "Common", 90),
    ("fadeleaf01", "Fadeleaf", "Common", 110),
    ("felweed", "Felweed", "Common", 95),
    ("firebloom", "Firebloom", "Uncommon", 160),
    ("fireweed", "Fireweed", "Common", 105),
    ("flamecap", "Flame Cap", "Rare", 280),
    ("foolscap", "Fool's Cap", "Uncommon", 220),
    ("frostlotus", "Frost Lotus", "Epic", 800),
    ("frostweed", "Frostweed", "Common", 130),
    ("frozenherb", "Frozen Herb", "Uncommon", 190),
    ("goldclover", "Goldclover", "Common", 85),
    ("goldenlotus", "Golden Lotus", "Rare", 500),
    ("gravemoss01", "Grave Moss", "Common", 95),
    ("gromsblood", "Gromsblood", "Uncommon", 210),
    ("heartblossom", "Heartblossom", "Uncommon", 185),
    ("icecap", "Icecap", "Uncommon", 170),
    ("jadetealeaf", "Jade Tea Leaf", "Common", 125),
    ("khadgarswhisker01", "Khadgar's Whisker", "Uncommon", 195),
    ("magebloom01","Magebloom", "Rare", 320),
    ("manathistle", "Mana Thistle", "Rare", 380),
    ("mountainsilversage", "Mountain Silversage", "Uncommon", 205),
    ("mushroom03", "Gloom Cap", "Common", 70),
    ("mushroom02", "Fel Cap", "Common", 75),
    ("mushroom01", "Spawn Cap", "Common", 65),
    ("netherbloom", "Netherbloom", "Rare", 340),
    ("nightmarevine", "Nightmare Vine", "Uncommon", 215),
    ("peacebloom01", "Peacebloom", "Common", 50),
    ("plaguebloom", "Plaguebloom", "Uncommon", 175),
    ("purplelotus", "Purple Lotus", "Uncommon", 230),
    ("ragveil", "Ragveil", "Uncommon", 165),
    ("rainpoppy", "Rain Poppy", "Common", 80),
    ("sansam", "Mountain Sansam", "Uncommon", 195),
    ("shaherb", "Sha-Touched Herb", "Rare", 420),
    ("silkweed", "Silkweed", "Common", 115),
    ("silverleaf01", "Silverleaf", "Common", 45),
    ("snowlily", "Snow Lily", "Common", 135),
    ("spineleaf", "Spineleaf", "Uncommon", 180),
    ("stardust", "Stardust", "Rare", 460),
    ("starflower", "Starflower", "Uncommon", 200),
    ("steelbloom01", "Steelbloom", "Common", 105),
    ("stormvine", "Stormvine", "Uncommon", 190),
    ("stormvinebubbles", "Stormvine Bubbles", "Rare", 310),
    ("stranglekelp01", "Stranglekelp", "Common", 90),
    ("sungrass", "Sungrass", "Uncommon", 155),
    ("swiftthistle01", "Swiftthistle", "Common", 100),
    ("taladororchid", "Talador Orchid", "Uncommon", 175),
    ("talandrasrose", "Talandra's Rose", "Uncommon", 185),
    ("goldthorn01", "Goldthorn", "Common", 120),
    ("icethorn", "Icethorn", "Uncommon", 180),
    ("terrocone", "Terocone", "Uncommon", 170),
    ("tigerlily", "Tiger Lily", "Common", 125),
    ("twilightjasmine", "Twilight Jasmine", "Uncommon", 190),
    ("whiptail01", "Whiptail", "Uncommon", 165),
    ("whispervine", "Whispervine", "Rare", 290),
    ("wintersbite01", "Winter's Bite", "Common", 110),
    ("stranglekelp_01", "Stranglekelp", "Common", 90),
    ("liferoot01", "Liferoot", "Common", 105),
    ("snakeroot", "Snakeroot", "Uncommon", 155),
    ("thornroot01", "Thornroot", "Uncommon", 145)
]

# Get next available item code
cursor.execute("SELECT item_code FROM items WHERE item_code LIKE 'I6%' ORDER BY item_code DESC LIMIT 1")
result = cursor.fetchone()
if result:
    last_code = result[0]
    # Extract number part
    num_part = int(last_code[2:], 36)  # Base 36 conversion
    next_num = num_part + 1
else:
    next_num = 0x6D0  # Start from I6D0

print(f"\n✓ Starting from item code: I{next_num:03X}")

# Step 4: Insert herbs
inserted_count = 0
skipped_count = 0

for herb_key, herb_name, rarity, gold_cost in herbs_data:
    # Generate model path
    if herb_key == "stranglekelp_01":
        model_path = "world_skillactivated_tradeskillnodes_stranglekelp_01"
    elif herb_key.startswith("mushroom"):
        model_path = f"world_skillactivated_tradeskillnodes_bush_{herb_key}"
    else:
        model_path = f"world_skillactivated_tradeskillnodes_bush_{herb_key}"
    
    # Check if already exists
    cursor.execute("SELECT id FROM items WHERE item_name = %s OR model_path = %s", (herb_name, model_path))
    if cursor.fetchone():
        print(f"⊘ Skipped: {herb_name} (already exists)")
        skipped_count += 1
        continue
    
    # Generate item code
    item_code = f"I{next_num:03X}".lower()
    next_num += 1
    
    # Get rarity ID
    rarity_id = rarities.get(rarity, rarities.get('Common', 1))
    
    # Insert herb
    cursor.execute("""
        INSERT INTO items (
            item_code, item_name, base_id, gold_cost, rarity_id, class_id,
            model_path, wc3_classification, actively_used, is_perishable,
            max_charges
        ) VALUES (
            %s, %s, 'bspd', %s, %s, %s,
            %s, 'Permanent', false, false, 0
        )
    """, (item_code, herb_name, gold_cost, rarity_id, material_class_id, model_path))
    
    print(f"+ Added: {item_code} - {herb_name:<30} ({rarity}, {gold_cost}g)")
    inserted_count += 1

conn.commit()

print("\n" + "=" * 100)
print(f"✓ COMPLETE: Added {inserted_count} herbs, skipped {skipped_count} existing")
print("=" * 100)

cursor.close()
conn.close()
