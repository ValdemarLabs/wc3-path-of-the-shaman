"""
Migrate item_classes to sync with POTS_ItemConcept.xlsx
Preserves existing IDs for DEquipment compatibility
"""
import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        database="wc3_pots",
        user="postgres",
        password="009900"
    )
    
    # Read migration SQL
    with open('H:/Pelit/PotS_JASS/WC3_Database/database/migrate_item_classes.sql', 'r', encoding='utf-8') as f:
        sql = f.read()
    
    cur = conn.cursor()
    
    # Execute migration
    print("Executing migration...")
    print("=" * 60)
    
    # Split by statements and execute
    statements = [s.strip() for s in sql.split(';') if s.strip() and not s.strip().startswith('--')]
    
    for stmt in statements:
        if stmt.upper().startswith('SELECT'):
            cur.execute(stmt)
            results = cur.fetchall()
            if results:
                for row in results:
                    print(row)
        elif stmt.upper() in ['BEGIN', 'COMMIT']:
            # Skip transaction control in Python, we'll handle it ourselves
            pass
        else:
            cur.execute(stmt)
    
    conn.commit()
    
    print("\n" + "=" * 60)
    print("FINAL RESULT:")
    print("=" * 60)
    
    # Show final state
    cur.execute("SELECT id, class_name, slot_type FROM item_classes ORDER BY id")
    results = cur.fetchall()
    
    for id, name, slot in results:
        slot_str = slot if slot else "None"
        print(f"ID {id:2d}: {name:30s} (slot: {slot_str})")
    
    print(f"\nTotal classes: {len(results)}")
    print("\n✓ Migration completed successfully!")
    print("✓ Existing IDs preserved for DEquipment compatibility")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"Error: {e}")
    if 'conn' in locals():
        conn.rollback()
