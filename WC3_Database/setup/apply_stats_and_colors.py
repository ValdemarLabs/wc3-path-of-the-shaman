"""
Apply Stats and Color System Schema
"""

import psycopg2
import sys

def main():
    print("=== Applying Stats and Color System Schema ===\n")
    
    conn = psycopg2.connect(
        host='127.0.0.1',
        port='5432',
        database='wc3_pots',
        user='postgres',
        password='009900'
    )
    
    cur = conn.cursor()
    
    try:
        # Read and execute schema
        with open('database/schema_stats_and_colors.sql', 'r') as f:
            schema_sql = f.read()
            # Remove PRINT statements (PostgreSQL doesn't support them)
            schema_sql = schema_sql.replace("PRINT 'Stats and color system schema created successfully!';", "")
        
        print("Executing schema updates...")
        cur.execute(schema_sql)
        conn.commit()
        print("✓ Schema applied successfully\n")
        
        # Verify tables
        cur.execute("""
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema='public' 
            AND table_name IN ('item_stats', 'item_stat_values', 'ui_color_scheme', 'tooltip_templates')
            ORDER BY table_name
        """)
        
        tables = cur.fetchall()
        print(f"✓ Created {len(tables)} new tables:")
        for table in tables:
            print(f"  • {table[0]}")
        
        # Count stats
        cur.execute("SELECT COUNT(*) FROM item_stats")
        stat_count = cur.fetchone()[0]
        print(f"\n✓ Inserted {stat_count} default stats")
        
        # Count colors
        cur.execute("SELECT COUNT(*) FROM ui_color_scheme")
        color_count = cur.fetchone()[0]
        print(f"✓ Inserted {color_count} default color schemes")
        
        # Count templates
        cur.execute("SELECT COUNT(*) FROM tooltip_templates")
        template_count = cur.fetchone()[0]
        print(f"✓ Inserted {template_count} tooltip templates")
        
        print("\n✓ Stats and color system ready!")
        
    except Exception as e:
        print(f"✗ Error: {e}")
        conn.rollback()
        sys.exit(1)
    finally:
        conn.close()

if __name__ == '__main__':
    main()
