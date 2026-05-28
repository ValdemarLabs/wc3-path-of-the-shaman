import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cur = conn.cursor()

# Fix actively_used for all healing potions
# In WC3, consumable potions must have actively_used = TRUE to be usable
cur.execute("""
    UPDATE items 
    SET actively_used = TRUE
    WHERE (item_name ILIKE '%potion%' OR item_name ILIKE '%elixir%')
    AND (base_id IN ('phea', 'pghe', 'pman', 'pmna') OR item_code IN ('phea', 'pghe', 'pman', 'pmna'))
    AND actively_used = FALSE
""")

print(f"Updated {cur.rowcount} potion items to actively_used = TRUE")

# List the updated items
cur.execute("""
    SELECT item_code, item_name, base_id, actively_used
    FROM items 
    WHERE (item_name ILIKE '%potion%' OR item_name ILIKE '%elixir%')
    AND (base_id IN ('phea', 'pghe', 'pman', 'pmna') OR item_code IN ('phea', 'pghe', 'pman', 'pmna'))
    ORDER BY item_name
""")

print("\n=== Updated Potion Items ===\n")
for row in cur.fetchall():
    print(f"Code: {row[0]:<6} | Name: {row[1]:<40} | Base: {row[2]:<6} | ActivelyUsed: {row[3]}")

conn.commit()
conn.close()

print("\n[SUCCESS] All healing/mana potions now have actively_used = TRUE")
print("This allows them to be right-clicked/used by players in WC3")
