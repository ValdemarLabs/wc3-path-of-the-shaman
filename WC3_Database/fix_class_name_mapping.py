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
    print("FIXING ITEM CLASS NAME MAPPING")
    print("=" * 100)
    
    # Mapping from Excel names to Database names
    mappings = {
        'Helm': 'Head Armor',
        'Chest': 'Chest Armor',
        'Legpiece': 'Leg Armor',
        'Boots': 'Foot Armor',
        'Gloves': 'Hand Armor',
        'Rings': 'Ring',
        '2h': 'Two-Hand Weapon',
    }
    
    print("\nUpdating item_level_ranges with correct class names:")
    print("-" * 100)
    
    for excel_name, db_name in mappings.items():
        cursor.execute("""
            UPDATE item_level_ranges
            SET item_class_name = %s
            WHERE item_class_name = %s
        """, (db_name, excel_name))
        
        count = cursor.rowcount
        print(f"  {excel_name:20s} -> {db_name:30s} ({count} rows updated)")
    
    conn.commit()
    
    # Verify the changes
    print("\n\nVerifying updated mappings:")
    print("-" * 100)
    
    cursor.execute("""
        SELECT DISTINCT ilr.item_class_name, ic.id
        FROM item_level_ranges ilr
        LEFT JOIN item_classes ic ON ilr.item_class_name = ic.class_name
        ORDER BY ic.id NULLS LAST, ilr.item_class_name
    """)
    
    for class_name, class_id in cursor.fetchall():
        if class_id:
            print(f"  {class_name:30s} -> Class ID {class_id} ✓")
        else:
            print(f"  {class_name:30s} -> NOT MAPPED ✗")
    
    # Check for any unmapped ranges
    cursor.execute("""
        SELECT DISTINCT ilr.item_class_name
        FROM item_level_ranges ilr
        LEFT JOIN item_classes ic ON ilr.item_class_name = ic.class_name
        WHERE ic.id IS NULL
    """)
    
    unmapped = cursor.fetchall()
    if unmapped:
        print("\n\nWARNING: Unmapped classes in item_level_ranges:")
        for (class_name,) in unmapped:
            print(f"  - {class_name}")
    else:
        print("\n\n✓ All item level ranges are now mapped to database classes!")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 100)
    print("✓ MAPPING UPDATE COMPLETE")
    print("=" * 100)
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
