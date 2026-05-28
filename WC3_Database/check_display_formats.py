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
    print("CHECKING DISPLAY FORMATS IN DATABASE")
    print("=" * 80)
    
    cursor.execute("""
        SELECT *
        FROM item_stats
        ORDER BY display_order
        LIMIT 5
    """)
    
    # Get column names
    colnames = [desc[0] for desc in cursor.description]
    print(f"Columns: {colnames}\n")
    
    rows = cursor.fetchall()
    for row in rows:
        print(row)
    
    # Now get all rows with specific columns
    cursor.execute("""
        SELECT stat_code, stat_name, display_format
        FROM item_stats
        ORDER BY display_order
    """)
    
    rows = cursor.fetchall()
    print(f"\nFound {len(rows)} stats:\n")
    
    for code, name, display_format in rows:
        print(f"{code:15s} {name:25s} Format: '{display_format}'")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"ERROR: {e}")
