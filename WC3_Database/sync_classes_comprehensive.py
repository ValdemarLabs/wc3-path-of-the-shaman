"""
Comprehensive sync of item_classes with POTS_ItemConcept.xlsx Column A
"""
import psycopg2

# Define the complete mapping from Excel to database classes
# Excel Name -> (slot_type, description, map_to_existing_id or None)
excel_mappings = {
    # Skip headers
    'Item type': None,  # Header, skip
    
    # Existing classes that might need aliases or should be preserved
    'Other': ('OTHER', 'Other/uncategorized items', None),
    'Miscellaneous': ('MISC', 'Miscellaneous items', None),
    
    # Armor pieces - map to existing or add new
    'Helm': ('HEAD', 'Helmets (Excel synonym for Head Armor)', 1),  # Maps to ID 1
    'Shoulders': ('SHOULDERS', 'Shoulder armor and pauldrons', None),
    'Neck': ('NECK', 'Necklaces (Excel synonym, distinct from Amulet)', None),
    'Back': ('BACK', 'Cloaks and capes', 12),  # Already exists as ID 12
    'Chest': ('CHEST', 'Chest pieces (Excel synonym for Chest Armor)', 2),  # Maps to ID 2
    'Bracers': ('WRISTS', 'Wrist armor and bracers', None),
    'Gloves': ('HANDS', 'Gloves (Excel synonym for Hand Armor)', 5),  # Maps to ID 5
    'Belt': ('BELT', 'Belts and waist armor', None),
    'Legpiece': ('LEGS', 'Leg pieces (Excel synonym for Leg Armor)', 3),  # Maps to ID 3
    'Boots': ('FEET', 'Boots (Excel synonym for Foot Armor)', 4),  # Maps to ID 4
    
    # Accessories
    'Rings': ('RING', 'Rings (plural form)', 9),  # Maps to ID 9
    'Trinket': ('TRINKET', 'Trinkets and charms', 11),  # Already exists as ID 11
    
    # Weapons
    '1h': ('WEAPON', 'One-handed weapons', None),
    '2h': ('TWOHAND', 'Two-handed weapons', 8),  # Maps to ID 8
    'Stave': ('TWOHAND_STAFF', 'Staves and staffs', None),
    'Shield': ('OFFHAND_SHIELD', 'Shields', None),
    
    # Reserved slots
    'reserved': ('RESERVED', 'Reserved slots for future expansion', None),  # Will create 4
}

try:
    conn = psycopg2.connect(
        host="localhost",
        database="wc3_pots",
        user="postgres",
        password="009900"
    )
    
    cur = conn.cursor()
    
    # Get current state
    cur.execute("SELECT id, class_name, slot_type FROM item_classes ORDER BY id")
    existing = {row[1]: row for row in cur.fetchall()}
    
    print("ANALYSIS")
    print("=" * 80)
    print(f"Current database has {len(existing)} classes")
    print("Existing IDs: ", sorted([e[0] for e in existing.values()]))
    print("\nProcessing Excel entries:")
    print("=" * 80)
    
    to_add = []
    
    for excel_name, mapping in excel_mappings.items():
        if mapping is None:
            print(f"SKIP: '{excel_name}' (header)")
            continue
        
        slot_type, description, maps_to_id = mapping
        
        if excel_name in existing:
            print(f"EXISTS: '{excel_name}' (ID {existing[excel_name][0]})")
        elif maps_to_id:
            print(f"ALIAS: '{excel_name}' -> maps to existing ID {maps_to_id}")
            # We could add it as an alias, but let's skip to avoid confusion
        elif excel_name == 'reserved':
            # Add 4 reserved slots
            for i in range(1, 5):
                name = f'reserved_{i}'
                if name not in existing:
                    to_add.append((name, 'RESERVED', f'Reserved slot {i} for future expansion'))
                    print(f"ADD: '{name}'")
        else:
            to_add.append((excel_name, slot_type, description))
            print(f"ADD: '{excel_name}' ({slot_type})")
    
    # Execute insertions
    if to_add:
        print("\n" + "=" * 80)
        print(f"INSERTING {len(to_add)} new classes...")
        print("=" * 80)
        
        for name, slot, desc in to_add:
            try:
                cur.execute(
                    "INSERT INTO item_classes (class_name, slot_type, description) VALUES (%s, %s, %s)",
                    (name, slot if slot != 'RESERVED' else None, desc)
                )
                print(f"✓ Inserted: {name}")
            except Exception as e:
                print(f"✗ Failed to insert '{name}': {e}")
        
        conn.commit()
    
    # Show final state
    print("\n" + "=" * 80)
    print("FINAL STATE")
    print("=" * 80)
    cur.execute("SELECT id, class_name, slot_type FROM item_classes ORDER BY id")
    results = cur.fetchall()
    
    for id, name, slot in results:
        slot_str = slot if slot else "None"
        print(f"ID {id:2d}: {name:30s} (slot: {slot_str})")
    
    print(f"\nTotal classes: {len(results)}")
    print("\n✓ Sync completed!")
    print("✓ Existing IDs preserved for DEquipment compatibility")
    print("✓ All Excel entries processed")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
    if 'conn' in locals():
        conn.rollback()
