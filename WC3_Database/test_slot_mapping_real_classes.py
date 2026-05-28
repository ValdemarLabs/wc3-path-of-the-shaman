import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Test the get_item_slot function logic
test_classes = [
    'Shoulders',
    'Two-Hand Weapon', 
    'Shield',
    'Hand Armor',
    'Belt',
    'Chest Armor',
    'Foot Armor',
    'Ring',
    'Neck',
    'Bracers'
]

def get_item_slot(class_name):
    """Determine equipment slot from item class"""
    if not class_name:
        return None
    
    class_name = class_name.upper()
    
    # Check specific armor types FIRST before generic "ARMOR" pattern
    if 'HEAD' in class_name or 'HELMET' in class_name or 'HELM' in class_name:
        return 'Head'
    elif 'NECK' in class_name or 'AMULET' in class_name or 'PENDANT' in class_name or 'NECKLACE' in class_name:
        return 'Neck'
    elif 'SHOULDER' in class_name or 'PAULDRON' in class_name:
        return 'Shoulder'
    elif 'HAND' in class_name or 'GAUNTLET' in class_name or 'GLOVE' in class_name:
        return 'Gloves'
    elif 'LEG' in class_name or 'PANT' in class_name or 'GREAVES' in class_name:
        return 'Legs'
    elif 'FEET' in class_name or 'FOOT' in class_name or 'BOOT' in class_name or 'SHOE' in class_name:
        return 'Boots'
    elif 'CHEST' in class_name or 'ARMOR' in class_name or 'BREASTPLATE' in class_name:
        return 'Chest'
    elif 'BACK' in class_name or 'CLOAK' in class_name or 'CAPE' in class_name:
        return 'Back'
    elif 'BRACER' in class_name or 'WRIST' in class_name:
        return 'Bracers'
    elif 'RING' in class_name:
        return 'Ring'
    elif 'BELT' in class_name or 'WAIST' in class_name or 'GIRDLE' in class_name:
        return 'Belt'
    elif '2H' in class_name or 'TWO-HANDED' in class_name or 'TWO HANDED' in class_name:
        return 19  # 2-handed weapon slot ID
    elif 'WEAPON' in class_name or 'SWORD' in class_name or 'AXE' in class_name or 'MACE' in class_name or 'DAGGER' in class_name:
        return 'MainHand'
    elif 'SHIELD' in class_name or 'OFF-HAND' in class_name or 'OFFHAND' in class_name:
        return 'OffHand'
    
    return None

print("Testing slot mapping for database class names:")
print("="*70)
for class_name in test_classes:
    slot = get_item_slot(class_name)
    status = "✓ OK" if slot else "✗ FAIL"
    print(f"  {status} | {class_name:20} → {slot}")

print()
print("="*70)
print("Checking actual items from database:")
print("="*70)

# Get items with these classes
cursor.execute("""
    SELECT i.item_code, i.item_name, ic.class_name
    FROM items i
    INNER JOIN item_classes ic ON i.class_id = ic.id
    WHERE i.deq_compatible = true
    AND ic.class_name IN ('Shoulders', 'Two-Hand Weapon', 'Shield', 'Hand Armor', 'Belt', 
                          'Chest Armor', 'Foot Armor', 'Ring', 'Neck', 'Bracers')
    ORDER BY ic.class_name, i.item_code
""")

items = cursor.fetchall()
print(f"\nFound {len(items)} items with proper classes")

for code, name, class_name in items[:20]:
    slot = get_item_slot(class_name)
    status = "✓" if slot else "✗"
    print(f"  {status} {code}: {class_name:20} → {str(slot):15} | {name[:35]}")

cursor.close()
conn.close()

print()
print("="*70)
print("RESULT: If slots are mapped correctly, the problem is elsewhere")
print("        (e.g., items not exported, or DEquipment slot names wrong)")
print("="*70)
