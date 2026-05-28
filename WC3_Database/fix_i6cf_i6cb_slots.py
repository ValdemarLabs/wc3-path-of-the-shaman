import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

print("Fixing I6CF and I6CB equipment definitions...")
print("="*80)

# I6CF - Infernal Sigil of Colossus - Neck slot (Amulet)
# Slot "Neck" should use class Amulet (id=10) or Neck (id=25)
print("\nFixing I6CF (Infernal Sigil of Colossus)...")
cursor.execute("""
    UPDATE items
    SET 
        class_id = 10,  -- Amulet class
        equipment_slot = 'Neck'
    WHERE UPPER(item_code) = 'I6CF'
""")
print(f"  ✓ Set class=Amulet, equipment_slot=Neck ({cursor.rowcount} row)")

# I6CB - Blazing Obsidian Sharpblade - 2-handed weapon (slot 19)
# Should use Two-Hand Weapon class (id=8)
print("\nFixing I6CB (Blazing Obsidian Sharpblade)...")
cursor.execute("""
    UPDATE items
    SET 
        class_id = 8,  -- Two-Hand Weapon class
        equipment_slot = 'Two-Hand'
    WHERE UPPER(item_code) = 'I6CB'
""")
print(f"  ✓ Set class=Two-Hand Weapon, equipment_slot=Two-Hand ({cursor.rowcount} row)")

conn.commit()

# Verify
cursor.execute("""
    SELECT i.item_code, i.item_name, ic.class_name, i.equipment_slot
    FROM items i
    LEFT JOIN item_classes ic ON i.class_id = ic.id
    WHERE UPPER(i.item_code) IN ('I6CF', 'I6CB')
    ORDER BY i.item_code
""")

print("\n" + "="*80)
print("Verification - Updated items:")
print("="*80)
for code, name, class_name, eq_slot in cursor.fetchall():
    print(f"{code}: {name}")
    print(f"  Class: {class_name}")
    print(f"  Equipment Slot: {eq_slot}")
    print()

cursor.close()
conn.close()

print("✓ ITEMS UPDATED! Now re-export DEquipment definitions.")
print("\nTo export:")
print("  cd WC3_Export")
print("  python export_dequipment_cli.py")
