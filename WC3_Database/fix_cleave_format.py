import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Fix Cleave % display format - remove the % since stat_name already has it
cur.execute("""
    UPDATE item_stats 
    SET display_format = '+{value}' 
    WHERE stat_code = 'cleave_pct'
""")

print(f"Updated {cur.rowcount} row(s) for Cleave %")
print("Changed display_format from '+{value}%' to '+{value}'")

conn.commit()
conn.close()

print("\nFixed: Cleave % will now display as '+25 Cleave %' instead of '+25% Cleave %'")
