import psycopg2
import json

print("=" * 100)
print("FIXING MAX_STACK CONSTRAINT AND CREATING ITEM LEVEL RANGES TABLE")
print("=" * 100)

try:
    conn = psycopg2.connect(
        host="localhost",
        database="wc3_pots",
        user="postgres",
        password="009900"
    )
    cursor = conn.cursor()
    
    # 1. Fix max_stack constraint
    print("\n1. Fixing max_stack constraint...")
    cursor.execute("ALTER TABLE items DROP CONSTRAINT IF EXISTS check_max_stack")
    cursor.execute("ALTER TABLE items ADD CONSTRAINT check_max_stack CHECK (max_stack >= 0)")
    print("   ✓ max_stack constraint updated to allow 0")
    
    # 2. Create item_level_ranges table
    print("\n2. Creating item_level_ranges table...")
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS item_level_ranges (
            id SERIAL PRIMARY KEY,
            item_class_name VARCHAR(50) NOT NULL,
            rarity_name VARCHAR(50) NOT NULL,
            min_level INTEGER NOT NULL,
            max_level INTEGER NOT NULL,
            UNIQUE(item_class_name, rarity_name)
        )
    """)
    print("   ✓ Table created")
    
    # 3. Load JSON data
    print("\n3. Loading item level ranges from JSON...")
    with open(r'H:\Pelit\PotS_JASS\WC3_Database\itemlevel_ranges_correct.json', 'r') as f:
        ranges_data = json.load(f)
    
    # 4. Insert data
    print("\n4. Inserting data...")
    insert_count = 0
    for item_data in ranges_data:
        item_type = item_data['item_type']
        ranges = item_data.get('ranges', {})
        
        if not ranges:
            continue
        
        for rarity, range_info in ranges.items():
            min_level = range_info['min']
            max_level = range_info['max']
            
            cursor.execute("""
                INSERT INTO item_level_ranges (item_class_name, rarity_name, min_level, max_level)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (item_class_name, rarity_name) 
                DO UPDATE SET min_level = EXCLUDED.min_level, max_level = EXCLUDED.max_level
            """, (item_type, rarity, min_level, max_level))
            insert_count += 1
            print(f"   {item_type:15s} {rarity:10s}: {min_level:3d}-{max_level:3d}")
    
    conn.commit()
    
    print(f"\n✓ Inserted/updated {insert_count} range definitions")
    
    # 5. Verify
    print("\n5. Verifying data...")
    cursor.execute("SELECT COUNT(*) FROM item_level_ranges")
    total = cursor.fetchone()[0]
    print(f"   Total ranges in database: {total}")
    
    # Show summary by item class
    print("\n6. Summary by item class:")
    cursor.execute("""
        SELECT item_class_name, COUNT(*) as rarity_count
        FROM item_level_ranges
        GROUP BY item_class_name
        ORDER BY item_class_name
    """)
    for row in cursor.fetchall():
        print(f"   {row[0]:15s}: {row[1]} rarities")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 100)
    print("✓ DATABASE SETUP COMPLETE")
    print("=" * 100)
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
