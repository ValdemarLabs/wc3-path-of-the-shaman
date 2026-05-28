import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Check what herb-related items already exist
cursor.execute("""
    SELECT 
        i.item_code,
        i.item_name,
        i.gold_cost,
        r.rarity_name,
        c.class_name,
        i.model_path
    FROM items i
    LEFT JOIN item_rarities r ON i.rarity_id = r.id
    LEFT JOIN item_classes c ON i.class_id = c.id
    WHERE 
        i.item_name ILIKE '%bloom%' OR
        i.item_name ILIKE '%root%' OR
        i.item_name ILIKE '%weed%' OR
        i.item_name ILIKE '%lotus%' OR
        i.item_name ILIKE '%leaf%' OR
        i.item_name ILIKE '%flower%' OR
        i.item_name ILIKE '%herb%' OR
        i.item_name ILIKE '%moss%' OR
        i.item_name ILIKE '%cap%' OR
        i.item_name ILIKE '%thistle%' OR
        i.item_name ILIKE '%vine%' OR
        i.item_name ILIKE '%kelp%' OR
        i.item_name ILIKE '%grass%' OR
        i.item_name ILIKE '%clover%' OR
        i.item_name ILIKE '%fadeleaf%' OR
        i.item_name ILIKE '%bloodthistle%' OR
        i.item_name ILIKE '%gromsblood%' OR
        i.item_name ILIKE '%silversage%' OR
        i.item_name ILIKE '%peacebloom%' OR
        i.item_name ILIKE '%silverleaf%' OR
        i.item_name ILIKE '%stranglekelp%' OR
        i.item_name ILIKE '%dreamfoil%' OR
        i.item_name ILIKE '%arthas%' OR
        i.item_name ILIKE '%khadgar%'
    ORDER BY i.item_name
""")

herbs = cursor.fetchall()

print("=" * 120)
print("EXISTING HERB-RELATED ITEMS IN DATABASE")
print("=" * 120)
print(f"{'Code':<8} {'Name':<40} {'Gold Cost':<12} {'Rarity':<15} {'Class':<15} {'Model'}")
print("=" * 120)

for code, name, gold, rarity, cls, model in herbs:
    gold_str = str(gold) if gold else "(null)"
    rarity_str = rarity if rarity else "(null)"
    cls_str = cls if cls else "(null)"
    model_str = (model[:50] + "...") if model and len(model) > 50 else (model if model else "(null)")
    print(f"{code:<8} {name:<40} {gold_str:<12} {rarity_str:<15} {cls_str:<15} {model_str}")

print(f"\nTotal existing herb-related items: {len(herbs)}")

# Check for Material class
cursor.execute("""
    SELECT id, class_name 
    FROM item_classes 
    WHERE class_name ILIKE '%material%'
""")

material_class = cursor.fetchone()
if material_class:
    print(f"\n✓ Found Material class: ID={material_class[0]}, Name='{material_class[1]}'")
else:
    print("\n⚠ No 'Material' class found in item_classes")

cursor.close()
conn.close()
