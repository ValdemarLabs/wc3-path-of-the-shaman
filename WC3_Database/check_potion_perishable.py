import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Check perishable status for potions
cur.execute("""
    SELECT item_code, item_name, base_id, is_perishable, max_charges, actively_used
    FROM items 
    WHERE (item_name ILIKE '%potion%' OR item_name ILIKE '%elixir%')
    AND (base_id IN ('phea', 'pghe', 'pman', 'pmna') OR item_code IN ('phea', 'pghe', 'pman', 'pmna'))
    ORDER BY item_name
""")

print("=== Potion Perishable Status ===\n")
print(f"{'Code':<8} | {'Name':<40} | {'Base':<6} | {'Perishable':<11} | {'MaxCharges':<11} | {'ActivelyUsed'}")
print("-" * 120)

issues = []
for row in cur.fetchall():
    code, name, base_id, is_perishable, max_charges, actively_used = row
    print(f"{code:<8} | {name:<40} | {base_id:<6} | {str(is_perishable):<11} | {str(max_charges):<11} | {actively_used}")
    
    # Check if perishable should be true but isn't
    if max_charges and max_charges > 0 and not is_perishable:
        issues.append(code)

if issues:
    print(f"\n[WARNING] Found {len(issues)} potions with charges but is_perishable=FALSE:")
    for code in issues:
        print(f"  - {code}")
    print("\nThese items should have is_perishable=TRUE so they disappear when charges are used up")
else:
    print("\n[OK] All charged potions have is_perishable=TRUE")

conn.close()
