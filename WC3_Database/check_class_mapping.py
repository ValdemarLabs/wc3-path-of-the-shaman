import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        database="wc3_pots",
        user="postgres",
        password="009900"
    )
    cursor = conn.cursor()
    
    print("=" * 100)
    print("ITEM CLASSES vs ITEM LEVEL RANGES MAPPING")
    print("=" * 100)
    
    # Get all item classes
    cursor.execute("""
        SELECT id, class_name, slot_type
        FROM item_classes
        ORDER BY id
    """)
    
    item_classes = cursor.fetchall()
    print(f"\nItem Classes ({len(item_classes)}):")
    print("-" * 100)
    for id, class_name, slot_type in item_classes:
        print(f"ID {id:2d}: {class_name:30s} (slot: {slot_type})")
    
    # Get all item level ranges
    cursor.execute("""
        SELECT DISTINCT item_class_name
        FROM item_level_ranges
        ORDER BY item_class_name
    """)
    
    range_classes = [row[0] for row in cursor.fetchall()]
    print(f"\n\nItem Level Range Classes ({len(range_classes)}):")
    print("-" * 100)
    for class_name in range_classes:
        cursor.execute("""
            SELECT rarity_name, min_level, max_level
            FROM item_level_ranges
            WHERE item_class_name = %s
            ORDER BY min_level
        """, (class_name,))
        ranges = cursor.fetchall()
        range_summary = f"{ranges[0][1]}-{ranges[-1][2]}" if ranges else "N/A"
        print(f"{class_name:20s} -> {range_summary}")
    
    # Find mismatches
    print(f"\n\nMAPPING ANALYSIS:")
    print("-" * 100)
    
    class_names = {c[1] for c in item_classes}
    
    print("\nClasses in item_level_ranges but NOT in item_classes:")
    for range_class in range_classes:
        if range_class not in class_names:
            print(f"  - {range_class}")
    
    print("\nSuggested mappings (Excel name -> Database name):")
    mappings = {
        'Helm': 'Head Armor',
        'Chest': 'Chest Armor',
        'Legpiece': 'Leg Armor',
        'Boots': 'Foot Armor',
        'Gloves': 'Hand Armor',
        'Rings': 'Ring',
        '2h': 'Two-Hand Weapon',
        # These are already correct or new
        'Back': 'Back',
        'Trinket': 'Trinket',
        'Shoulders': 'Shoulders',
        'Neck': 'Neck',
        'Bracers': 'Bracers',
        'Belt': 'Belt',
        '1h': '1h',
        'Stave': 'Stave',
        'Shield': 'Shield',
        'Miscellaneous': 'Miscellaneous',
    }
    
    for excel_name, db_name in mappings.items():
        # Check if excel name exists in ranges
        if excel_name in range_classes:
            # Check if db name exists in classes
            db_id = next((id for id, name, _ in item_classes if name == db_name), None)
            if db_id:
                print(f"  {excel_name:20s} -> {db_name:30s} (ID {db_id})")
            else:
                print(f"  {excel_name:20s} -> {db_name:30s} (NOT FOUND IN DB)")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
