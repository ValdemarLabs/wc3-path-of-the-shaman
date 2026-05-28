import psycopg2

conn = psycopg2.connect(
    host='127.0.0.1',
    port=5432,
    database='wc3_pots',
    user='postgres',
    password='009900'
)

cursor = conn.cursor()

# Get all herbs we just added
cursor.execute("""
    SELECT 
        i.item_code,
        i.item_name,
        i.gold_cost,
        r.rarity_name,
        i.model_path
    FROM items i
    LEFT JOIN item_rarities r ON i.rarity_id = r.id
    WHERE i.item_code >= 'i1c6' AND i.item_code <= 'i206'
    ORDER BY i.item_code
""")

herbs = cursor.fetchall()

print("=" * 120)
print("NEWLY ADDED HERBS - VERIFICATION")
print("=" * 120)
print(f"{'Code':<8} {'Name':<35} {'Gold':<8} {'Rarity':<12} {'Model Path'}")
print("=" * 120)

rarity_counts = {'Common': 0, 'Uncommon': 0, 'Rare': 0, 'Epic': 0}

for code, name, gold, rarity, model in herbs:
    model_short = (model[:60] + "...") if model and len(model) > 60 else (model if model else "(null)")
    print(f"{code:<8} {name:<35} {gold:<8} {rarity:<12} {model_short}")
    
    if rarity in rarity_counts:
        rarity_counts[rarity] += 1

print("\n" + "=" * 120)
print("SUMMARY")
print("=" * 120)
print(f"Total herbs added: {len(herbs)}")
print(f"\nBy rarity:")
for rarity, count in rarity_counts.items():
    print(f"  {rarity:<12} {count:>3} herbs")

cursor.close()
conn.close()
