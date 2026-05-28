import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Search for Minor Healing Potion
cur.execute("""
    SELECT id, item_code, item_name, base_id, class_id, cooldown_group, 
           wc3_abilities, is_droppable, is_pawnable, is_powerup, is_sellable, 
           actively_used, use_automatically
    FROM items 
    WHERE item_name ILIKE '%healing potion%' OR item_name ILIKE '%health potion%'
    ORDER BY item_name
""")

rows = cur.fetchall()

print("=== Healing Potion Items ===\n")
for row in rows:
    print(f"ID: {row[0]}")
    print(f"Code: {row[1]}")
    print(f"Name: {row[2]}")
    print(f"Base ID: {row[3]}")
    print(f"Class ID: {row[4]}")
    print(f"Cooldown Group: {row[5]}")
    print(f"Abilities: {row[6]}")
    print(f"Droppable: {row[7]}, Pawnable: {row[8]}, Powerup: {row[9]}")
    print(f"Sellable: {row[10]}, Actively Used: {row[11]}, Use Auto: {row[12]}")
    print()

conn.close()
