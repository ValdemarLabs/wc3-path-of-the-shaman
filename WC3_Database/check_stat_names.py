#!/usr/bin/env python3
"""
Check stat names in database
"""

import psycopg2

# Database connection
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="wc3_pots",
    user="postgres",
    password="009900"
)

cursor = conn.cursor()

# Query all stats
cursor.execute("SELECT id, stat_code, stat_name FROM item_stats ORDER BY id;")
stats = cursor.fetchall()

print(f"Total stats in database: {len(stats)}\n")
print("ID | Stat Code | Stat Name")
print("-" * 80)
for stat_id, stat_code, stat_name in stats:
    print(f"{stat_id:2d} | {stat_code:30s} | {stat_name}")

cursor.close()
conn.close()
