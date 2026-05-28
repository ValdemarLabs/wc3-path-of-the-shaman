import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check Spring Water and similar consumables specifically
cursor.execute("""
    SELECT 
        i.item_code, 
        i.item_name, 
        i.actively_used,
        i.is_perishable,
        i.max_charges,
        i.wc3_classification
    FROM items i
    WHERE i.item_code IN ('I60Z', 'I61J', 'I6BA', 'I6BB', 'I6BC', 'pghe', 'phea', 'I6BE')
       OR i.item_name ILIKE '%spring water%'
       OR i.item_name ILIKE '%crystal water%'
       OR i.item_name ILIKE '%purified water%'
    ORDER BY i.item_name
""")

items = cursor.fetchall()

print("\nVerification - Water & Key Consumables:")
print("=" * 100)
print(f"{'Code':<8} {'Name':<45} {'Active':<8} {'Perish':<8} {'Charges':<9} {'WC3Class'}")
print("=" * 100)

for code, name, active, perish, charges, wc3class in items:
    active_str = "✓ YES" if active else "✗ NO"
    perish_str = "✓ YES" if perish else "✗ NO"
    charges_str = str(charges) if charges else "null"
    wc3class_str = wc3class if wc3class else "(null)"
    print(f"{code:<8} {name:<45} {active_str:<8} {perish_str:<8} {charges_str:<9} {wc3class_str}")

cursor.close()
conn.close()
