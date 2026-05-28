using System;
using System.Drawing;
using System.Windows.Forms;

namespace WC3ItemManager
{
    public class HelpDialog : Form
    {
        private TabControl tabControl;
        private Button btnClose;
        
        public HelpDialog()
        {
            InitializeUI();
        }
        
        private void InitializeUI()
        {
            this.Text = "WC3 Item Manager - User Guide & FAQ";
            this.Size = new Size(900, 700);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            
            // Tab control
            tabControl = new TabControl
            {
                Dock = DockStyle.Fill,
                Padding = new Point(10, 5)
            };
            
            // Add tabs
            tabControl.TabPages.Add(CreateGettingStartedTab());
            tabControl.TabPages.Add(CreateFeaturesTab());
            tabControl.TabPages.Add(CreateDatabaseTab());
            tabControl.TabPages.Add(CreateIconsTab());
            tabControl.TabPages.Add(CreateFAQTab());
            
            // Close button
            Panel bottomPanel = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 50,
                Padding = new Padding(10)
            };
            
            btnClose = new Button
            {
                Text = "Close",
                Width = 100,
                Height = 30,
                Anchor = AnchorStyles.Bottom | AnchorStyles.Right,
                DialogResult = DialogResult.OK
            };
            btnClose.Location = new Point(bottomPanel.Width - btnClose.Width - 20, 10);
            
            bottomPanel.Controls.Add(btnClose);
            
            this.Controls.Add(tabControl);
            this.Controls.Add(bottomPanel);
        }
        
        private TabPage CreateGettingStartedTab()
        {
            var tab = new TabPage("Getting Started");
            var rtb = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.White,
                Font = new Font("Segoe UI", 10),
                BorderStyle = BorderStyle.None,
                Padding = new Padding(15)
            };
            
            rtb.Text = @"WELCOME TO WC3 ITEM MANAGER
================================================

This application helps you manage custom items for Warcraft 3 custom maps using a PostgreSQL database.

QUICK START:
1. Connect to Database
   - Default connection: localhost:5432, database 'wc3_pots', user 'postgres'
   - Use Tools → Configuration to change icon folder paths

2. Browse Items
   - View all items in the main grid
   - Use filters to search by code, name, rarity, level, or cost
   - Use Sort dropdown to order items by different columns

3. Create New Item
   - Click 'Add New Item' button
   - Fill in required fields (code, name, rarity)
   - Select icon, add tooltip text, configure stats
   - Click 'Save'

4. Edit Existing Item
   - Right-click an item → Edit
   - Or double-click an item row
   - Modify fields and click 'Save'

5. Import Items
   - File → Import from W3T...
   - Select a .w3t file from Warcraft 3 Object Editor
   - Items will be imported automatically

INTERFACE LAYOUT:
- Left Panel: DataGrid with all items
- Right Panel: Preview of selected item (tooltip + icon)
- Top: Search/filter controls and sort options
- Status Bar: Shows connection status and row count";
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateFeaturesTab()
        {
            var tab = new TabPage("Features");
            var rtb = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.White,
                Font = new Font("Segoe UI", 10),
                BorderStyle = BorderStyle.None,
                Padding = new Padding(15)
            };
            
            rtb.Text = @"FEATURES OVERVIEW
================================================

ITEM MANAGEMENT:
✓ Create, Edit, Delete items
✓ Duplicate existing items
✓ Batch delete multiple items
✓ Copy item codes to clipboard
✓ Validation highlighting (red rows for errors)

SEARCH & FILTERING:
✓ Search by item code (exact match)
✓ Search by item name (partial match)
✓ Filter by rarity (Common, Uncommon, Rare, etc.)
✓ Filter by class (Weapon, Armor, Consumable, etc.)
✓ Filter by level range (min/max)
✓ Filter by gold cost range (min/max)

SORTING:
✓ Sort by Code (A-Z or Z-A)
✓ Sort by Name (A-Z or Z-A)
✓ Sort by Recently Added
✓ Sort by Recently Modified
✓ Sort by Level (Low to High or High to Low)

PREVIEW SYSTEM:
✓ Real-time WC3-style tooltip preview
✓ Icon display with proper colors
✓ Shows stats, abilities, tooltip text
✓ Color-coded rarity borders

ICONS:
✓ Browse Blizzard + Custom icons
✓ 64x64 icon preview
✓ Pre-converted PNG support (faster loading)
✓ Folder tree navigation
✓ Async loading for large icon sets

CONFIGURATION:
✓ Column visibility management
✓ Icon folder path configuration
✓ Cache management (clear converted icons)
✓ Display settings

DATABASE FEATURES:
✓ PostgreSQL backend
✓ Full CRUD operations (Create, Read, Update, Delete)
✓ Stats system (item_stat_types, item_stat_values)
✓ Timestamp tracking (created_at, updated_at)
✓ Type safety with enums";
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateDatabaseTab()
        {
            var tab = new TabPage("Database");
            var rtb = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.White,
                Font = new Font("Segoe UI", 10),
                BorderStyle = BorderStyle.None,
                Padding = new Padding(15)
            };
            
            rtb.Text = @"DATABASE STRUCTURE
================================================

POSTGRESQL DATABASE: wc3_pots
Default connection:
  Host: 127.0.0.1 (localhost)
  Port: 5432
  User: postgres
  Password: postgres

MAIN TABLE: items
Contains all item data with these key columns:

PRIMARY FIELDS:
- item_id (SERIAL PRIMARY KEY) - Auto-generated ID
- item_code (VARCHAR(4) UNIQUE) - WC3 4-character code (e.g., 'I001')
- item_name (VARCHAR(255)) - Display name

CLASSIFICATION:
- rarity (rarity_enum) - Common, Uncommon, Rare, etc.
- class (class_enum) - Weapon, Armor, Consumable, etc.
- type (VARCHAR(100)) - Specific item type

DISPLAY:
- icon_path (TEXT) - Path to .blp icon file
- tooltip (TEXT) - Item description shown in-game
- tooltip_extended (TEXT) - Additional tooltip text (shift-click)

GAMEPLAY:
- item_level (INTEGER) - Item power level
- gold_cost (INTEGER) - Purchase price
- wc3_abilities (TEXT) - Comma-separated ability codes
- is_powerup (BOOLEAN) - Consumable/permanent flag

STATS:
Stats are stored in separate tables:
- item_stat_types: Defines stat types (Agility, Strength, etc.)
- item_stat_values: Links items to stats with values

TIMESTAMPS:
- created_at (TIMESTAMP) - When item was added
- updated_at (TIMESTAMP) - Last modification time

HOW IT WORKS:
1. Application queries 'items' table via SQL
2. JOINs with item_stat_values to get stats
3. Data is displayed in DataGrid
4. Changes are saved back to database via UPDATE/INSERT/DELETE
5. Preview loads icon from filesystem using icon_path

SQL EXAMPLE:
SELECT i.*, 
       COUNT(DISTINCT isv.stat_id) as stat_count
FROM items i
LEFT JOIN item_stat_values isv ON i.item_id = isv.item_id
WHERE i.rarity = 'Legendary'
GROUP BY i.item_id
ORDER BY i.item_level DESC;";
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateIconsTab()
        {
            var tab = new TabPage("Icons & BLP");
            var rtb = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.White,
                Font = new Font("Segoe UI", 10),
                BorderStyle = BorderStyle.None,
                Padding = new Padding(15)
            };
            
            rtb.Text = @"ICON SYSTEM
================================================

ICON FORMATS:
- .blp (Blizzard Picture Format) - Native WC3 format
- .png (Portable Network Graphics) - Pre-converted format
- .tga (Targa) - Not yet supported

ICON PATHS:
Icons are stored with relative paths from configured root folders:
  Example: ReplaceableTextures\CommandButtons\BTNSword.blp

Two icon folders:
  1. Blizzard Icons - Official WC3 icons
  2. Custom Icons - Community/custom icons

USING ICONS:
1. Click 'Browse Icons' in item editor
2. Navigate folder tree (left panel)
3. Select icon (right panel)
4. Path is saved as .blp extension in database
5. Preview shows icon immediately

BLP CONVERSION:
Why convert BLP to PNG?
- Some BLP files have encoding issues
- War3Net.Drawing.Blp library has compatibility problems
- PNG files load faster and more reliably

HOW TO CONVERT:
Option 1 - Pre-convert with external tool:
  1. Use BLPConverter or similar tool
  2. Convert entire folder: blp → png
  3. Keep folder structure identical
  4. Keep both .blp and .png files

Option 2 - Automatic conversion (built-in):
  1. Application tries to load .blp
  2. If file has issues, tries smaller mipmaps
  3. Converts to .png and caches in /cache folder
  4. Uses cached PNG next time

TROUBLESHOOTING ICONS:
Q: Icons appear black?
A: Convert BLP to PNG externally, or clear cache (Tools → Configuration → Display Settings → Clear Icon Cache)

Q: Icons show wrong colors?
A: Some BLP files use BGR instead of RGB. Application auto-detects and corrects this.

Q: Icon preview not showing?
A: Check icon folder path in Configuration. Ensure both .blp or .png file exists.

ICON PATH CONFIGURATION:
Tools → Configuration → Icon Paths tab
- Set 'Blizzard WC3 Icons' folder
- Set 'Custom Icons' folder
- Browse buttons help locate folders
- Paths are saved and persistent";
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateFAQTab()
        {
            var tab = new TabPage("FAQ");
            var rtb = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.White,
                Font = new Font("Segoe UI", 10),
                BorderStyle = BorderStyle.None,
                Padding = new Padding(15)
            };
            
            rtb.Text = @"FREQUENTLY ASKED QUESTIONS
================================================

Q: How do I connect to a different database?
A: Currently connection is hardcoded. Edit the code to change host/database/credentials. Future version will have connection dialog.

Q: Can I use this without PostgreSQL?
A: No, PostgreSQL is required. Install it from postgresql.org (version 12+).

Q: What is item_code and why 4 characters?
A: WC3 uses 4-character codes for objects (e.g., 'I001', 'aswd'). These must be unique. The editor validates this.

Q: How do I add custom stats to items?
A: In the item editor, go to the Stats tab. Select stat type and enter value. Stats are stored in item_stat_values table.

Q: Why do some items have red highlighting?
A: Red rows indicate validation errors:
  - Stats mentioned in tooltip but not defined
  - Missing or invalid icon path
  - Missing or very short item name

Q: Can I export items back to .w3t format?
A: Export feature is planned but not yet implemented. Currently import-only.

Q: What happens if I delete an item?
A: The item and its stats are permanently removed from database. Use caution. Consider duplicating items before major edits.

Q: How do I backup the database?
A: Use PostgreSQL tools:
  pg_dump -U postgres -d wc3_pots > backup.sql
  
  Restore with:
  psql -U postgres -d wc3_pots < backup.sql

Q: Can multiple people use this simultaneously?
A: Yes! PostgreSQL supports concurrent connections. Multiple editors can work at the same time. However, be careful of edit conflicts.

Q: Why is the icon selector slow to load?
A: Large icon folders (1000+ icons) take time to load. Icons load in batches (50 at a time) to prevent freezing. Consider organizing into subfolders.

Q: How do I update an item without changing updated_at?
A: The updated_at timestamp always updates on edit. This is intentional for tracking changes.

Q: What's the difference between tooltip and tooltip_extended?
A: 
  - tooltip: Main description (always visible)
  - tooltip_extended: Additional info (shown when holding Shift in WC3)

Q: Can I change column widths?
A: Yes, drag column borders. Widths are saved automatically and restored on next launch.

Q: How do I clear the icon cache?
A: Tools → Configuration → Display Settings → Clear Icon Cache button

Q: Where is data stored?
A: Items: PostgreSQL database (wc3_pots)
   Icons: Filesystem (configured paths)
   Cache: Application folder /cache/*.png
   Settings: MainFormSettings.ini

Q: What if Python script fails on import?
A: Ensure:
  - Python 3.x is installed
  - Python is in system PATH
  - psycopg2 module installed: pip install psycopg2
  - wc3_w3t_parser module present in core folder";
            
            tab.Controls.Add(rtb);
            return tab;
        }
    }
}
