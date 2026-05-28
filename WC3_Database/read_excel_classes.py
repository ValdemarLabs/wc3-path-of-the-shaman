"""
Read item classes from POTS_ItemConcept.xlsx column A
"""
import openpyxl
import psycopg2

# Read Excel file
wb = openpyxl.load_workbook('H:/Pelit/PotS_JASS/WC3_ItemConcept/POTS_ItemConcept.xlsx', data_only=True)
ws = wb.active

print("Item Classes from Excel (Column A):")
print("=" * 60)

item_classes = []
for row_num, row in enumerate(ws.iter_rows(min_row=1, max_row=200, min_col=1, max_col=1), start=1):
    cell = row[0]
    if cell.value and isinstance(cell.value, str):
        value = cell.value.strip()
        if value and value not in ['Item Type', 'Type', '']:  # Skip headers
            item_classes.append((row_num, value))
            print(f"Row {row_num}: {value}")

print(f"\nTotal unique classes found: {len(set([c[1] for c in item_classes]))}")
print("\nUnique classes:")
unique = sorted(set([c[1] for c in item_classes]))
for cls in unique:
    print(f"  - {cls}")

# Connect to database and check existing classes
try:
    conn = psycopg2.connect(
        host="localhost",
        database="wc3_pots",
        user="postgres",
        password="009900"
    )
    
    cur = conn.cursor()
    cur.execute("SELECT id, class_name, slot_type FROM item_classes ORDER BY id")
    existing = cur.fetchall()
    
    print("\n" + "=" * 60)
    print("Current item_classes in database:")
    print("=" * 60)
    for id, name, slot in existing:
        print(f"ID {id:2d}: {name:30s} (slot: {slot})")
    
    # Find what's missing
    existing_names = [e[1] for e in existing]
    missing = [cls for cls in unique if cls not in existing_names]
    
    if missing:
        print("\n" + "=" * 60)
        print("Missing classes (need to be added):")
        print("=" * 60)
        for cls in missing:
            print(f"  - {cls}")
    else:
        print("\nAll Excel classes are already in database!")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\nDatabase error: {e}")

wb.close()
