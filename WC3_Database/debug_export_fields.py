"""Debug script to see what fields are exported for a specific item"""
import psycopg2
import configparser

# Load database config
config = configparser.ConfigParser()
config.read('config/database.ini')
conn = psycopg2.connect(
    host=config['postgresql']['host'],
    port=config['postgresql']['port'],
    database=config['postgresql']['database'],
    user=config['postgresql']['user'],
    password=config['postgresql'].get('password', '')
)

# Get test item
cur = conn.cursor()
cur.execute("""
    SELECT * FROM items 
    WHERE item_name LIKE '%Ragnaros%'
    LIMIT 1
""")

columns = [desc[0] for desc in cur.description]
row = cur.fetchone()
test_item = dict(zip(columns, row))

print(f"Found item: {test_item['item_code']} - {test_item['item_name']}")
print(f"Base ID: {test_item.get('base_id')}")

# Hard-code FIELD_MAP from exporter
FIELD_MAP = {
    'item_name': ('unam', 'string'),
    'tooltip': ('utip', 'string'),
    'tooltip_extended': ('utub', 'string'),
    'description': ('ides', 'string'),
    'hotkey': ('uhot', 'string'),
    'gold_cost': ('igol', 'int'),
    'lumber_cost': ('ilum', 'int'),
    'item_level': ('ilev', 'int'),
    'old_level': ('ilvo', 'int'),
    'max_charges': ('iuse', 'int'),
    'max_stack': ('isto', 'int'),
    'armor_type': ('iarm', 'string'),
    'wc3_classification': ('icla', 'string'),
    'wc3_abilities': ('iabi', 'string'),
    'hit_points': ('ihtp', 'int'),
    'is_droppable': ('idrp', 'int'),
    'is_sellable': ('isel', 'int'),
    'is_pawnable': ('ipaw', 'int'),
    'is_powerup': ('ipow', 'int'),
    'is_perishable': ('iper', 'int'),
    'actively_used': ('iusa', 'int'),
    'ignore_cooldown': ('iicd', 'int'),
    'pick_random': ('iprn', 'int'),
    'icon_path': ('iico', 'string'),
    'model_path': ('ifil', 'string'),
    'scale': ('isca', 'real'),
    'selection_size': ('issc', 'real'),
    'tint_red': ('iclr', 'int'),
    'tint_green': ('iclg', 'int'),
    'tint_blue': ('iclb', 'int'),
    'priority': ('ipri', 'int'),
    'stock_initial': ('isit', 'int'),
    'stock_max': ('isto', 'int'),
    'stock_replenish': ('isrr', 'int'),
    'stock_start_delay': ('isst', 'int'),
    'cooldown_group': ('icid', 'string'),
    'morph_target': ('imor', 'string'),
    'wc3_requirements': ('ureq', 'string'),
    'wc3_requirements_amount': ('urqa', 'string'),
    'button_pos_x': ('ubpx', 'int'),
    'button_pos_y': ('ubpy', 'int'),
}

REQUIRED_FIELDS = ['item_name', 'tooltip', 'tooltip_extended', 'description']

print(f"\nFIELDS IN DATABASE:")
print("=" * 100)

# Check which fields would be exported
fields_to_export = []
is_custom = test_item.get('base_id') is not None and test_item.get('base_id') != ''

for db_field, (wc3_field, field_type) in FIELD_MAP.items():
    value = test_item.get(db_field)
    db_value_str = f"{value}" if value is not None else "NULL"
    
    # Simulate the NEW export logic
    will_export = False
    export_value = value
    
    if is_custom:
        if field_type == 'string':
            if value is None or value == '':
                export_value = ''
            # ALWAYS export for custom items
            will_export = True
        elif field_type in ['int', 'real']:
            if value is None:
                export_value = 0 if field_type == 'int' else 0.0
            will_export = True
    
    status = "[EXPORT]" if will_export else "[SKIP]"
    export_str = f"-> {export_value}" if will_export else ""
    print(f"{status:10s} {db_field:30s} ({wc3_field:6s}) = {db_value_str:20s} {export_str}")
    
    if will_export:
        fields_to_export.append((db_field, wc3_field, export_value))

print(f"\n{'=' * 100}")
print(f"IS CUSTOM ITEM: {is_custom}")
print(f"TOTAL FIELDS TO EXPORT: {len(fields_to_export)} out of {len(FIELD_MAP)}")  
print(f"\nExpected in World Editor: ~{len(fields_to_export)} visible fields")

conn.close()
