# WC3 Database - Quick Start Guide

## 🚀 Fastest Setup (5 minutes)

### Windows Quick Setup

1. **Install PostgreSQL** (if not already installed)
   - Download from: https://www.postgresql.org/download/windows/
   - Remember your password for the `postgres` user

2. **Run the setup script**
   ```cmd
   cd h:\Pelit\PotS_JASS\WC3_Database
   setup.bat
   ```

3. **Import example data**
   ```cmd
   import_examples.bat
   ```

4. **Done!** You now have 10 example items in the database.

### Manual Setup

```cmd
# 1. Create database
psql -U postgres -c "CREATE DATABASE wc3_pots;"

# 2. Initialize schema
psql -U postgres -d wc3_pots -f schema.sql

# 3. Install Python dependencies
pip install -r requirements.txt

# 4. Configure database connection
copy database.ini.example database.ini
notepad database.ini
# (Edit with your password)

# 5. Import example data
python wc3_importer.py example_items.json
```

## 📖 Common Operations

### Import Items

```bash
# From JSON
python wc3_importer.py items.json

# From CSV
python wc3_importer.py items.csv

# From WC3 .txt format
python wc3_importer.py UnitItemFunc.txt --format txt
```

### Export Items

```bash
# To JASS (all items)
python wc3_exporter.py --output ItemsDatabase.j --format jass

# To JASS (specific items)
python wc3_exporter.py --output BossLoot.j --format jass --items I001 I002 I003

# To DEquipment format
python wc3_exporter.py --output DEquipItems.j --format deq

# To DInventory format
python wc3_exporter.py --output DInvRarities.j --format dinv

# To JSON
python wc3_exporter.py --output items.json --format json

# To CSV
python wc3_exporter.py --output items.csv --format csv
```

### Interactive Database Manager

```bash
python db_manager.py
```

Features:
- Import/Export with menu
- View statistics
- Search items
- Test connection

### SQL Queries

```sql
-- Connect to database
psql -U postgres -d wc3_pots

-- View all items
SELECT * FROM v_items_complete;

-- Search by name
SELECT * FROM v_items_complete WHERE item_name ILIKE '%sword%';

-- Get legendary items
SELECT * FROM v_items_complete WHERE rarity_name = 'Legendary';

-- Items by level
SELECT * FROM v_items_complete WHERE item_level BETWEEN 10 AND 20;
```

See `example_queries.sql` for 100+ example queries!

## 🔧 Troubleshooting

### "psql: command not found"
Add PostgreSQL to PATH:
- Windows: `C:\Program Files\PostgreSQL\15\bin`

### "could not connect to server"
1. Check PostgreSQL is running (Services → postgresql)
2. Verify password in `database.ini`
3. Check port 5432 is not blocked

### "Failed to import"
1. Run `python wc3_importer.py example_items.json` first
2. Check file format matches extension
3. Verify JSON/CSV structure

## 📁 Files Overview

### Core Files
- `schema.sql` - Database schema with all tables
- `wc3_importer.py` - Import script (TXT/CSV/JSON → PostgreSQL)
- `wc3_exporter.py` - Export script (PostgreSQL → JASS/DEquip/CSV/JSON)
- `db_manager.py` - Interactive management tool

### Configuration
- `database.ini` - Database connection settings (create from .example)
- `database.ini.example` - Template configuration

### Examples & Documentation
- `README.md` - Complete documentation
- `example_items.json` - 10 example items
- `example_queries.sql` - 100+ SQL query examples
- `QUICKSTART.md` - This file

### Utilities
- `setup.bat` - Windows setup script
- `import_examples.bat` - Import example data (Windows)
- `import_examples.sh` - Import example data (Linux/Mac)
- `requirements.txt` - Python dependencies

## 💡 Next Steps

1. **Add your items**
   - Edit `example_items.json` or create new JSON/CSV
   - Import with `python wc3_importer.py your_items.json`

2. **Export to your map**
   - `python wc3_exporter.py --output YourMap_Items.j --format jass`
   - Copy the .j file to your map

3. **Integrate with DEquip/DInv**
   - `python wc3_exporter.py --output DEquipItems.j --format deq`
   - `python wc3_exporter.py --output DInvRarities.j --format dinv`
   - Import libraries into World Editor

4. **Query and manage**
   - Use `python db_manager.py` for interactive management
   - Use `psql` or pgAdmin for direct SQL access
   - See `example_queries.sql` for query ideas

## 📞 Need Help?

- Check `README.md` for detailed documentation
- Review `example_queries.sql` for SQL examples
- Test with `example_items.json` first
- Use `db_manager.py` for interactive help

---

**Quick Reference Card**

```
IMPORT:  python wc3_importer.py <file>
EXPORT:  python wc3_exporter.py --output <file> --format <jass|deq|dinv|csv|json>
MANAGE:  python db_manager.py
QUERY:   psql -U postgres -d wc3_pots
```
