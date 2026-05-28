import psycopg2
import configparser

config = configparser.ConfigParser()
config.read('config/database.ini')

conn = psycopg2.connect(
    host=config['postgresql']['host'],
    port=config['postgresql']['port'],
    database=config['postgresql']['database'],
    user=config['postgresql']['user'],
    password=config['postgresql'].get('password', '')
)

cur = conn.cursor()

# Get test items
cur.execute("""
    SELECT item_code, item_name, base_id, gold_cost, lumber_cost, item_level, 
           max_charges, max_stack, is_droppable, is_sellable, is_pawnable, 
           armor_type, wc3_classification, actively_used, is_powerup, is_perishable,
           ignore_cooldown, pick_random, priority, stock_initial, stock_max
    FROM items 
    WHERE item_name LIKE '%Ragnaros%' OR item_name LIKE '%Test Hammer%'
    LIMIT 3
""")

rows = cur.fetchall()
print("TEST ITEMS IN DATABASE:")
print("=" * 80)
for r in rows:
    print(f"\nItem Code: {r[0]}")
    print(f"  Name: {r[1]}")
    print(f"  Base ID: {r[2]}")
    print(f"  Gold Cost: {r[3]}, Lumber: {r[4]}, Level: {r[5]}")
    print(f"  Charges: {r[6]}, Stack: {r[7]}")
    print(f"  Droppable: {r[8]}, Sellable: {r[9]}, Pawnable: {r[10]}")
    print(f"  Armor Type: {r[11]}, Classification: {r[12]}")
    print(f"  Actively Used: {r[13]}, Powerup: {r[14]}, Perishable: {r[15]}")
    print(f"  Ignore Cooldown: {r[16]}, Pick Random: {r[17]}")
    print(f"  Priority: {r[18]}, Stock Initial: {r[19]}, Stock Max: {r[20]}")

# Check how many fields are NULL for this item
if rows:
    item_code = rows[0][0]
    cur.execute(f"""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'items' 
        ORDER BY ordinal_position
    """)
    
    all_columns = [c[0] for c in cur.fetchall()]
    
    cur.execute(f"SELECT * FROM items WHERE item_code = %s", (item_code,))
    item_data = cur.fetchone()
    
    null_count = sum(1 for v in item_data if v is None)
    non_null_count = len(item_data) - null_count
    
    print(f"\n{'=' * 80}")
    print(f"FIELD STATISTICS for {item_code}:")
    print(f"  Total columns in items table: {len(all_columns)}")
    print(f"  Non-NULL fields: {non_null_count}")
    print(f"  NULL fields: {null_count}")

conn.close()
