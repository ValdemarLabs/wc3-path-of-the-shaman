import psycopg2

try:
    conn = psycopg2.connect(
        host="localhost",
        database="wc3_pots",
        user="postgres",
        password="009900"
    )
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM unit_level_mappings")
    total = cursor.fetchone()[0]
    print(f"Total mappings: {total}")
    
    cursor.close()
    conn.close()
except Exception as e:
    print(f"ERROR: {e}")
