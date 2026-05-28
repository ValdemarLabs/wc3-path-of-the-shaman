import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        database="wc3_pots",
        user="postgres",
        password="009900"
    )
    cursor = conn.cursor()
    
    print("=" * 80)
    print("ADDING SORT_ORDER TO ITEM_STAT_VALUES")
    print("=" * 80)
    
    # Read SQL file
    with open(r'H:\Pelit\PotS_JASS\WC3_Database\add_sort_order_to_stats.sql', 'r') as f:
        sql = f.read()
    
    cursor.execute(sql)
    conn.commit()
    
    print("\n✓ Successfully added sort_order column")
    
    # Verify
    cursor.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'item_stat_values'
        ORDER BY ordinal_position
    """)
    
    print("\nColumns in item_stat_values:")
    for col_name, data_type in cursor.fetchall():
        print(f"  {col_name:20s} {data_type}")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 80)
    print("✓ MIGRATION COMPLETE")
    print("=" * 80)
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
