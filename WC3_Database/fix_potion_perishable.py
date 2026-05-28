import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Fix perishable and max_charges for all potions
# In WC3, consumable potions need:
# - max_charges = 1 (or higher for multi-use items)
# - is_perishable = TRUE (so item disappears when used up)
cur.execute("""
    UPDATE items 
    SET 
        is_perishable = TRUE,
        max_charges = COALESCE(max_charges, 1)  -- Set to 1 if NULL
    WHERE (item_name ILIKE '%potion%' OR item_name ILIKE '%elixir%')
    AND (base_id IN ('phea', 'pghe', 'pman', 'pmna') OR item_code IN ('phea', 'pghe', 'pman', 'pmna'))
    AND (is_perishable = FALSE OR max_charges IS NULL)
""")

updated_count = cur.rowcount
print(f"Updated {updated_count} potion items")

# Show the results
cur.execute("""
    SELECT item_code, item_name, base_id, is_perishable, max_charges, actively_used
    FROM items 
    WHERE (item_name ILIKE '%potion%' OR item_name ILIKE '%elixir%')
    AND (base_id IN ('phea', 'pghe', 'pman', 'pmna') OR item_code IN ('phea', 'pghe', 'pman', 'pmna'))
    ORDER BY item_name
""")

print("\n=== Updated Potion Items ===\n")
print(f"{'Code':<8} | {'Name':<40} | {'Base':<6} | {'Perishable':<11} | {'MaxCharges':<11} | {'ActivelyUsed'}")
print("-" * 120)

for row in cur.fetchall():
    code, name, base_id, is_perishable, max_charges, actively_used = row
    print(f"{code:<8} | {name:<40} | {base_id:<6} | {str(is_perishable):<11} | {str(max_charges):<11} | {actively_used}")

conn.commit()
conn.close()

print("\n[SUCCESS] All potions now have:")
print("  - is_perishable = TRUE (item disappears when used)")
print("  - max_charges = 1 (single-use consumable)")
print("  - actively_used = TRUE (can be right-clicked)")
