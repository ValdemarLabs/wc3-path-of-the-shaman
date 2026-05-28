"""
Apply WC3 Full Field Support Schema Updates
============================================
Adds missing WC3-specific columns to the items table
"""

import psycopg2
import configparser
import sys

def load_config(config_path='config/database.ini'):
    """Load database configuration."""
    config = configparser.ConfigParser()
    config.read(config_path)
    return {
        'host': config.get('postgresql', 'host'),
        'port': config.get('postgresql', 'port'),
        'database': config.get('postgresql', 'database'),
        'user': config.get('postgresql', 'user'),
        'password': config.get('postgresql', 'password')
    }

def main():
    print("=== Applying WC3 Full Field Support Schema Updates ===\n")
    
    # Load config
    db_config = load_config()
    
    print(f"Connecting to database: {db_config['database']}...")
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    print("✓ Connected\n")
    
    # Read and execute schema updates
    print("Reading schema updates from database/schema_wc3_full_support.sql...")
    with open('database/schema_wc3_full_support.sql', 'r') as f:
        schema_sql = f.read()
    
    print("Executing schema updates...")
    try:
        cursor.execute(schema_sql)
        conn.commit()
        print("✓ Schema updates applied successfully\n")
    except Exception as e:
        print(f"✗ Error applying schema: {e}")
        conn.rollback()
        sys.exit(1)
    
    # Verify new columns
    print("Verifying new columns were created...")
    cursor.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name='items' 
        AND column_name IN (
            'base_id', 'tooltip_extended', 'hotkey', 'wc3_classification',
            'old_level', 'hit_points', 'actively_used', 'dropped_on_death',
            'morph_target', 'ignore_cooldown', 'pick_random', 'armor_type',
            'wc3_abilities', 'scale', 'selection_size', 'button_pos_x', 'button_pos_y',
            'stock_initial', 'stock_max', 'stock_replenish', 'stock_start_delay',
            'wc3_requirements', 'wc3_requirements_amount', 'original_modifications'
        )
        ORDER BY column_name
    """)
    
    columns = cursor.fetchall()
    print(f"✓ Found {len(columns)} new WC3 columns:")
    for col_name, col_type in columns:
        print(f"  • {col_name} ({col_type})")
    
    # Count existing items
    cursor.execute("SELECT COUNT(*) FROM items")
    item_count = cursor.fetchone()[0]
    print(f"\n✓ Ready to import! Database has {item_count} existing items.")
    print(f"  (Re-import with wc3_w3t_importer_v2.py to populate new fields)\n")
    
    conn.close()
    print("✓ Schema upgrade complete!")

if __name__ == '__main__':
    main()
