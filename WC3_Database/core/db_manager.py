"""
WC3 Database Management Utility
================================
Interactive command-line tool for managing the WC3 items database.

Features:
- Quick import/export operations
- Database statistics
- Item search
- Configuration management

Author: Generated for PotS Project
Date: 2026-03-10
Version: 1.0.0
"""

import os
import sys
from wc3_importer import WC3ItemImporter, load_config
from wc3_exporter import WC3ItemExporter


def print_banner():
    """Print application banner."""
    print("\n" + "="*70)
    print(" WC3 POTS DATABASE MANAGEMENT UTILITY".center(70))
    print("="*70 + "\n")


def print_menu():
    """Print main menu."""
    print("\nMAIN MENU")
    print("-" * 50)
    print("1. Import Items")
    print("2. Export Items")
    print("3. View Statistics")
    print("4. Search Items")
    print("5. Database Info")
    print("6. Test Connection")
    print("0. Exit")
    print("-" * 50)


def menu_import(db_config):
    """Handle import menu."""
    print("\n--- IMPORT ITEMS ---")
    print("1. Import from JSON")
    print("2. Import from CSV")
    print("3. Import from TXT (WC3)")
    print("0. Back")
    
    choice = input("\nChoose option: ").strip()
    
    if choice == '0':
        return
        
    file_path = input("Enter file path: ").strip().strip('"')
    
    if not os.path.exists(file_path):
        print(f"\n✗ Error: File not found: {file_path}")
        input("\nPress Enter to continue...")
        return
        
    format_map = {'1': 'json', '2': 'csv', '3': 'txt'}
    file_format = format_map.get(choice)
    
    if not file_format:
        print("\n✗ Invalid choice")
        input("\nPress Enter to continue...")
        return
        
    print(f"\nImporting from {file_format.upper()}...")
    
    importer = WC3ItemImporter(db_config)
    try:
        importer.connect()
        
        if file_format == 'json':
            importer.import_from_json(file_path)
        elif file_format == 'csv':
            importer.import_from_csv(file_path)
        elif file_format == 'txt':
            importer.import_from_txt(file_path)
            
        importer.print_summary()
        
    except Exception as e:
        print(f"\n✗ Import failed: {e}")
    finally:
        importer.disconnect()
        
    input("\nPress Enter to continue...")


def menu_export(db_config):
    """Handle export menu."""
    print("\n--- EXPORT ITEMS ---")
    print("1. Export to JASS")
    print("2. Export to DEquipment")
    print("3. Export to DInventory Rarity")
    print("4. Export to JSON")
    print("5. Export to CSV")
    print("0. Back")
    
    choice = input("\nChoose option: ").strip()
    
    if choice == '0':
        return
        
    output_file = input("Enter output file path: ").strip().strip('"')
    
    item_codes_str = input("Enter item codes (comma-separated, or leave empty for all): ").strip()
    item_codes = [code.strip() for code in item_codes_str.split(',')] if item_codes_str else None
    
    format_map = {
        '1': ('jass', '.j'),
        '2': ('deq', '.j'),
        '3': ('dinv', '.j'),
        '4': ('json', '.json'),
        '5': ('csv', '.csv')
    }
    
    if choice not in format_map:
        print("\n✗ Invalid choice")
        input("\nPress Enter to continue...")
        return
        
    file_format, default_ext = format_map[choice]
    
    # Add default extension if not present
    if not any(output_file.endswith(ext) for ext in ['.j', '.json', '.csv']):
        output_file += default_ext
        
    print(f"\nExporting to {file_format.upper()}...")
    
    exporter = WC3ItemExporter(db_config)
    try:
        exporter.connect()
        
        if file_format == 'jass':
            exporter.export_to_jass(output_file, item_codes)
        elif file_format == 'deq':
            exporter.export_to_deq_config(output_file, item_codes)
        elif file_format == 'dinv':
            exporter.export_to_dinv_rarity(output_file, item_codes)
        elif file_format == 'json':
            exporter.export_to_json(output_file, item_codes)
        elif file_format == 'csv':
            exporter.export_to_csv(output_file, item_codes)
            
        exporter.print_summary()
        
    except Exception as e:
        print(f"\n✗ Export failed: {e}")
    finally:
        exporter.disconnect()
        
    input("\nPress Enter to continue...")


def menu_statistics(db_config):
    """Show database statistics."""
    print("\n--- DATABASE STATISTICS ---\n")
    
    importer = WC3ItemImporter(db_config)
    try:
        importer.connect()
        
        # Total items
        importer.cursor.execute("SELECT COUNT(*) FROM items")
        total_items = importer.cursor.fetchone()[0]
        print(f"Total Items: {total_items}")
        
        # Items by rarity
        print("\nItems by Rarity:")
        importer.cursor.execute("""
            SELECT r.rarity_name, COUNT(*) as count
            FROM items i
            LEFT JOIN item_rarities r ON i.rarity_id = r.id
            GROUP BY r.rarity_name, r.rarity_level
            ORDER BY r.rarity_level
        """)
        for row in importer.cursor.fetchall():
            rarity, count = row
            print(f"  {rarity or 'Unknown'}: {count}")
            
        # Items by type
        print("\nItems by Type:")
        importer.cursor.execute("""
            SELECT t.type_name, COUNT(*) as count
            FROM items i
            LEFT JOIN item_types t ON i.type_id = t.id
            GROUP BY t.type_name
            ORDER BY count DESC
        """)
        for row in importer.cursor.fetchall():
            itype, count = row
            print(f"  {itype or 'Unknown'}: {count}")
            
        # DEquipment compatible
        importer.cursor.execute("SELECT COUNT(*) FROM items WHERE deq_compatible = TRUE")
        deq_count = importer.cursor.fetchone()[0]
        print(f"\nDEquipment Compatible: {deq_count}")
        
        # DInventory compatible
        importer.cursor.execute("SELECT COUNT(*) FROM items WHERE dinv_compatible = TRUE")
        dinv_count = importer.cursor.fetchone()[0]
        print(f"DInventory Compatible: {dinv_count}")
        
        # Latest import
        importer.cursor.execute("""
            SELECT import_date, source_file, items_imported
            FROM import_history
            ORDER BY import_date DESC
            LIMIT 1
        """)
        result = importer.cursor.fetchone()
        if result:
            import_date, source_file, items_imported = result
            print(f"\nLatest Import: {source_file}")
            print(f"  Date: {import_date}")
            print(f"  Items: {items_imported}")
            
    except Exception as e:
        print(f"\n✗ Error: {e}")
    finally:
        importer.disconnect()
        
    input("\nPress Enter to continue...")


def menu_search(db_config):
    """Search for items."""
    print("\n--- SEARCH ITEMS ---\n")
    
    search_term = input("Enter search term (name or description): ").strip()
    
    if not search_term:
        print("\n✗ Search term cannot be empty")
        input("\nPress Enter to continue...")
        return
        
    importer = WC3ItemImporter(db_config)
    try:
        importer.connect()
        
        importer.cursor.execute("""
            SELECT item_code, item_name, type_name, rarity_name, item_level, gold_cost
            FROM v_items_complete
            WHERE item_name ILIKE %s OR description ILIKE %s
            ORDER BY item_level DESC
            LIMIT 20
        """, (f'%{search_term}%', f'%{search_term}%'))
        
        results = importer.cursor.fetchall()
        
        if not results:
            print("\n✗ No items found")
        else:
            print(f"\nFound {len(results)} items:\n")
            print(f"{'Code':<6} {'Name':<30} {'Type':<12} {'Rarity':<12} {'Lvl':<5} {'Cost':<8}")
            print("-" * 85)
            for row in results:
                code, name, itype, rarity, level, cost = row
                name = (name[:27] + '...') if len(name) > 30 else name
                itype = itype or 'N/A'
                rarity = rarity or 'N/A'
                print(f"{code:<6} {name:<30} {itype:<12} {rarity:<12} {level:<5} {cost:<8}")
                
    except Exception as e:
        print(f"\n✗ Error: {e}")
    finally:
        importer.disconnect()
        
    input("\nPress Enter to continue...")


def menu_db_info(db_config):
    """Show database information."""
    print("\n--- DATABASE INFO ---\n")
    
    print(f"Host: {db_config['host']}")
    print(f"Port: {db_config['port']}")
    print(f"Database: {db_config['database']}")
    print(f"User: {db_config['user']}")
    
    input("\nPress Enter to continue...")


def test_connection(db_config):
    """Test database connection."""
    print("\n--- TEST CONNECTION ---\n")
    print("Testing connection to database...")
    
    importer = WC3ItemImporter(db_config)
    try:
        importer.connect()
        
        importer.cursor.execute("SELECT version()")
        version = importer.cursor.fetchone()[0]
        
        print(f"\n✓ Connection successful!")
        print(f"\nPostgreSQL Version:")
        print(f"  {version}")
        
        importer.disconnect()
        
    except Exception as e:
        print(f"\n✗ Connection failed: {e}")
        
    input("\nPress Enter to continue...")


def main():
    """Main application loop."""
    # Load configuration
    try:
        db_config = load_config()
    except Exception as e:
        print(f"\n✗ Error loading configuration: {e}")
        print("\nPlease ensure database.ini exists and is properly configured.")
        input("\nPress Enter to exit...")
        return
        
    while True:
        os.system('cls' if os.name == 'nt' else 'clear')
        print_banner()
        print_menu()
        
        choice = input("\nChoose option: ").strip()
        
        if choice == '0':
            print("\nGoodbye!")
            break
        elif choice == '1':
            menu_import(db_config)
        elif choice == '2':
            menu_export(db_config)
        elif choice == '3':
            menu_statistics(db_config)
        elif choice == '4':
            menu_search(db_config)
        elif choice == '5':
            menu_db_info(db_config)
        elif choice == '6':
            test_connection(db_config)
        else:
            print("\n✗ Invalid choice")
            input("\nPress Enter to continue...")


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        input("\nPress Enter to exit...")
