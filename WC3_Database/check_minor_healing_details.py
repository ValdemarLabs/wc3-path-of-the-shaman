import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Get Minor Healing Potion details
cur.execute("""
    SELECT item_code, item_name, base_id, cooldown_group, wc3_abilities, 
           actively_used, use_automatically, is_powerup, 
           cooldown_duration, max_charges
    FROM items 
    WHERE item_code = 'I6BD'
""")

row = cur.fetchone()
if row:
    print("=== Minor Healing Potion (I6BD) ===\n")
    print(f"Code: {row[0]}")
    print(f"Name: {row[1]}")
    print(f"Base ID: {row[2]}")
    print(f"Cooldown Group: '{row[3]}' (type: {type(row[3])})")
    print(f"WC3 Abilities: {row[4]}")
    print(f"Actively Used: {row[5]}")
    print(f"Use Automatically: {row[6]}")
    print(f"Is Powerup: {row[7]}")
    print(f"Cooldown Duration: {row[8]}")
    print(f"Max Charges: {row[9]}")
    
    # Check if cooldown_group is empty string or None
    if row[3] is None:
        print("\n[INFO] Cooldown group is NULL (None)")
    elif row[3] == '':
        print("\n[ISSUE] Cooldown group is EMPTY STRING - this may override base item!")
    else:
        print(f"\n[INFO] Cooldown group is set to: '{row[3]}'")

# Compare with regular Healing Potion
print("\n" + "="*60 + "\n")
cur.execute("""
    SELECT item_code, item_name, base_id, cooldown_group, wc3_abilities
    FROM items 
    WHERE item_code = 'phea'
""")

row = cur.fetchone()
if row:
    print("=== Base Healing Potion (phea) ===\n")
    print(f"Code: {row[0]}")
    print(f"Name: {row[1]}")
    print(f"Base ID: {row[2]}")
    print(f"Cooldown Group: '{row[3]}' (type: {type(row[3])})")
    print(f"WC3 Abilities: {row[4]}")
else:
    print("Base item 'phea' not found in database")

conn.close()
