"""Test the get_item_slot() function logic"""

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
    
    return None

# Test with actual class names from database
test_classes = [
    'Chest Armor',
    'Ring',
    'Belt',
    'Hand Armor',
    'Foot Armor',
    'Head Armor',
    'Leg Armor',
]

print("Testing get_item_slot() with database class names:")
print("=" * 60)
for cls in test_classes:
    result = get_item_slot(cls)
    print(f"{cls:<20} -> {result}")
