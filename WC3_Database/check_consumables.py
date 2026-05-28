import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Find Spring Water and similar consumables
cursor.execute("""
    SELECT 
        i.item_code, 
        i.item_name, 
        i.actively_used,
        i.is_perishable,
        i.max_charges,
        i.wc3_classification,
        c.class_name,
        i.cooldown_group
    FROM items i
    LEFT JOIN item_classes c ON i.class_id = c.id
    WHERE i.base_id IS NOT NULL
      AND (
          i.item_name ILIKE '%water%' OR
          i.item_name ILIKE '%potion%' OR
          i.item_name ILIKE '%elixir%' OR
          i.item_name ILIKE '%scroll%' OR
          i.item_name ILIKE '%tome%' OR
          i.wc3_classification = 'Charged' OR
          c.class_name = 'CONSUMABLE'
      )
    ORDER BY i.item_name
""")

consumables = cursor.fetchall()

print("Consumable Items Status:")
print("=" * 130)
print(f"{'Code':<8} {'Name':<45} {'Active':<8} {'Perish':<8} {'Charges':<9} {'WC3Class':<12} {'ItemClass':<15} {'CD Group'}")
print("=" * 130)

broken_items = []
for code, name, active, perish, charges, wc3class, iclass, cdgroup in consumables:
    active_str = "YES" if active else "NO"
    perish_str = "YES" if perish else "NO"
    charges_str = str(charges) if charges else "(null)"
    wc3class_str = wc3class if wc3class else "(null)"
    iclass_str = iclass if iclass else "(null)"
    cdgroup_str = cdgroup if cdgroup else "(null)"
    
    # Check if broken (same logic as healing potions)
    is_broken = (not active) or (not perish) or (charges is None or charges == 0)
    
    marker = "❌" if is_broken else "✓"
    
    print(f"{marker} {code:<6} {name:<45} {active_str:<8} {perish_str:<8} {charges_str:<9} {wc3class_str:<12} {iclass_str:<15} {cdgroup_str}")
    
    if is_broken:
        broken_items.append((code, name, active, perish, charges))

print(f"\nTotal consumables found: {len(consumables)}")
print(f"Broken consumables: {len(broken_items)}")

if broken_items:
    print("\nBroken items need fixes:")
    print("  - actively_used = true")
    print("  - is_perishable = true")
    print("  - max_charges = 1 (or appropriate value)")

cursor.close()
conn.close()
