import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

print("=" * 80)
print("FIXING BROKEN CONSUMABLES")
print("=" * 80)

# Fix consumables - those with Charged classification or CONSUMABLE class
# Set appropriate max_charges based on existing value or naming patterns
cursor.execute("""
    UPDATE items i
    SET 
        actively_used = true,
        is_perishable = true,
        max_charges = CASE
            -- Keep existing charges if already set and > 0
            WHEN i.max_charges IS NOT NULL AND i.max_charges > 0 THEN i.max_charges
            -- Water items typically have 5 charges
            WHEN i.item_name ILIKE '%water%' THEN 5
            -- Salves typically have 6 charges
            WHEN i.item_name ILIKE '%salve%' THEN 6
            -- Scrolls, potions, elixirs, tomes are single-use
            WHEN i.item_name ILIKE '%scroll%' THEN 1
            WHEN i.item_name ILIKE '%potion%' THEN 1
            WHEN i.item_name ILIKE '%elixir%' THEN 1
            WHEN i.item_name ILIKE '%tome%' THEN 1
            -- Default to 1 for everything else
            ELSE 1
        END
    WHERE i.base_id IS NOT NULL
      AND (
          i.wc3_classification = 'Charged' OR
          EXISTS (SELECT 1 FROM item_classes c WHERE c.id = i.class_id AND c.class_name = 'CONSUMABLE') OR
          i.item_name ILIKE '%water%' OR
          i.item_name ILIKE '%potion%' OR
          i.item_name ILIKE '%elixir%' OR
          i.item_name ILIKE '%scroll%' OR
          i.item_name ILIKE '%tome%'
      )
      AND NOT (i.actively_used = true AND i.is_perishable = true AND i.max_charges > 0)
""")

fixed_count = cursor.rowcount
conn.commit()

print(f"\n✓ Fixed {fixed_count} consumable items")
print("\nChanges applied:")
print("  - actively_used = true")
print("  - is_perishable = true")
print("  - max_charges = appropriate value (1, 5, or 6 depending on item type)")

# Verify the fix
cursor.execute("""
    SELECT 
        i.item_code, 
        i.item_name, 
        i.actively_used,
        i.is_perishable,
        i.max_charges
    FROM items i
    LEFT JOIN item_classes c ON i.class_id = c.id
    WHERE i.base_id IS NOT NULL
      AND (
          i.wc3_classification = 'Charged' OR
          c.class_name = 'CONSUMABLE' OR
          i.item_name ILIKE '%water%' OR
          i.item_name ILIKE '%potion%' OR
          i.item_name ILIKE '%elixir%' OR
          i.item_name ILIKE '%scroll%' OR
          i.item_name ILIKE '%tome%'
      )
      AND NOT (i.actively_used = true AND i.is_perishable = true AND i.max_charges > 0)
""")

still_broken = cursor.fetchall()

if still_broken:
    print(f"\n⚠ WARNING: {len(still_broken)} items still broken:")
    for code, name, active, perish, charges in still_broken[:10]:
        print(f"  {code}: {name} - active={active}, perish={perish}, charges={charges}")
else:
    print("\n✓ All consumables verified working!")

cursor.close()
conn.close()

print("\n" + "=" * 80)
print("CONSUMABLE FIX COMPLETE")
print("=" * 80)
