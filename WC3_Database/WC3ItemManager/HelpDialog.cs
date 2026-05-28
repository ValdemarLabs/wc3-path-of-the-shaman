using System;
using System.Drawing;
using System.Windows.Forms;

namespace WC3ItemManager
{
    public class HelpDialog : Form
    {
        private TabControl tabControl;
        private Button btnClose;
        
        // Colors for styled text
        private readonly Color HeaderColor = Color.FromArgb(51, 122, 183);      // Blue
        private readonly Color SubHeaderColor = Color.FromArgb(92, 184, 92);    // Green
        private readonly Color WarningColor = Color.FromArgb(240, 173, 78);     // Orange
        private readonly Color TipColor = Color.FromArgb(91, 192, 222);         // Cyan
        private readonly Color CodeColor = Color.FromArgb(119, 119, 119);       // Gray
        
        public HelpDialog()
        {
            InitializeUI();
        }
        
        private void InitializeUI()
        {
            this.Text = "📖 WC3 Item Manager - User Guide & FAQ";
            this.Size = new Size(1000, 750);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.Sizable;
            this.MaximizeBox = true;
            this.MinimizeBox = false;
            this.Icon = SystemIcons.Information;
            
            // Tab control with larger tabs
            tabControl = new TabControl
            {
                Dock = DockStyle.Fill,
                Padding = new Point(12, 6),
                Font = new Font("Segoe UI", 9.5f)
            };
            
            // Add tabs
            tabControl.TabPages.Add(CreateGettingStartedTab());
            tabControl.TabPages.Add(CreateItemManagementTab());
            tabControl.TabPages.Add(CreateLootSystemTab());
            tabControl.TabPages.Add(CreateUnitsDestructiblesTab());
            tabControl.TabPages.Add(CreateExportingTab());
            tabControl.TabPages.Add(CreateIconsTab());
            tabControl.TabPages.Add(CreateFAQTab());
            
            // Bottom panel with close button
            Panel bottomPanel = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 55,
                BackColor = Color.FromArgb(248, 249, 250)
            };
            
            btnClose = new Button
            {
                Text = "✓ Close",
                Width = 120,
                Height = 35,
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(51, 122, 183),
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                Cursor = Cursors.Hand,
                DialogResult = DialogResult.OK
            };
            btnClose.FlatAppearance.BorderSize = 0;
            btnClose.Location = new Point(bottomPanel.Width - btnClose.Width - 20, 10);
            btnClose.Anchor = AnchorStyles.Bottom | AnchorStyles.Right;
            
            bottomPanel.Controls.Add(btnClose);
            
            this.Controls.Add(tabControl);
            this.Controls.Add(bottomPanel);
        }
        
        private RichTextBox CreateStyledRichTextBox()
        {
            return new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.White,
                Font = new Font("Segoe UI", 10),
                BorderStyle = BorderStyle.None,
                Padding = new Padding(20)
            };
        }
        
        private void AppendHeader(RichTextBox rtb, string text)
        {
            int start = rtb.TextLength;
            rtb.AppendText(text + "\n");
            rtb.Select(start, text.Length);
            rtb.SelectionFont = new Font("Segoe UI", 14, FontStyle.Bold);
            rtb.SelectionColor = HeaderColor;
            rtb.AppendText("\n");
        }
        
        private void AppendSubHeader(RichTextBox rtb, string text)
        {
            int start = rtb.TextLength;
            rtb.AppendText(text + "\n");
            rtb.Select(start, text.Length);
            rtb.SelectionFont = new Font("Segoe UI", 11, FontStyle.Bold);
            rtb.SelectionColor = SubHeaderColor;
        }
        
        private void AppendBullet(RichTextBox rtb, string text)
        {
            rtb.AppendText("  • " + text + "\n");
        }
        
        private void AppendNumbered(RichTextBox rtb, int num, string text)
        {
            int start = rtb.TextLength;
            rtb.AppendText($"  {num}. ");
            rtb.Select(start, $"  {num}. ".Length);
            rtb.SelectionFont = new Font("Segoe UI", 10, FontStyle.Bold);
            rtb.SelectionColor = HeaderColor;
            rtb.AppendText(text + "\n");
        }
        
        private void AppendTip(RichTextBox rtb, string text)
        {
            int start = rtb.TextLength;
            rtb.AppendText("💡 TIP: ");
            rtb.Select(start, 8);
            rtb.SelectionFont = new Font("Segoe UI", 10, FontStyle.Bold);
            rtb.SelectionColor = TipColor;
            rtb.AppendText(text + "\n\n");
        }
        
        private void AppendWarning(RichTextBox rtb, string text)
        {
            int start = rtb.TextLength;
            rtb.AppendText("⚠️ WARNING: ");
            rtb.Select(start, 11);
            rtb.SelectionFont = new Font("Segoe UI", 10, FontStyle.Bold);
            rtb.SelectionColor = WarningColor;
            rtb.AppendText(text + "\n\n");
        }
        
        private void AppendText(RichTextBox rtb, string text)
        {
            rtb.AppendText(text + "\n");
        }
        
        private void AppendSpacer(RichTextBox rtb)
        {
            rtb.AppendText("\n");
        }
        
        private TabPage CreateGettingStartedTab()
        {
            var tab = new TabPage("🚀 Getting Started");
            var rtb = CreateStyledRichTextBox();
            
            AppendHeader(rtb, "Welcome to WC3 Item Manager");
            AppendText(rtb, "A powerful desktop application for managing Warcraft 3 custom items, loot systems, and JASS code generation using a PostgreSQL database backend.");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🔌 Database Connection");
            AppendText(rtb, "The application connects to PostgreSQL on startup:");
            AppendBullet(rtb, "Default: localhost:5432, database 'wc3_pots'");
            AppendBullet(rtb, "Green dot in status bar = Connected");
            AppendBullet(rtb, "Red dot = Disconnected (click Connect button)");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "📋 Quick Start Guide");
            AppendNumbered(rtb, 1, "Browse Items - View all items in the main grid with filtering");
            AppendNumbered(rtb, 2, "Search & Filter - Use the search box or filter dropdowns");
            AppendNumbered(rtb, 3, "Create Item - Click 'Add New Item' and fill in the form");
            AppendNumbered(rtb, 4, "Edit Item - Double-click a row or right-click → Edit");
            AppendNumbered(rtb, 5, "Preview - Select an item to see WC3-style tooltip on the right");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🖱️ Mouse & Keyboard Shortcuts");
            AppendBullet(rtb, "Double-click row: Edit item");
            AppendBullet(rtb, "Right-click: Context menu (Edit, Duplicate, Delete, Copy Code)");
            AppendBullet(rtb, "Ctrl+Click: Multi-select items");
            AppendBullet(rtb, "Shift+Click: Select range");
            AppendBullet(rtb, "Click column header: Sort by that column");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🎨 Visual Indicators");
            AppendBullet(rtb, "Rarity colors: Gray=Common, Green=Uncommon, Blue=Rare, Purple=Epic, Orange=Legendary");
            AppendBullet(rtb, "Red row highlight: Validation warning (hover for details)");
            AppendBullet(rtb, "Preview panel: Shows selected item with WC3-style tooltip");
            AppendSpacer(rtb);
            
            AppendTip(rtb, "Use Tools → Configuration to set icon folder paths for proper icon display.");
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateItemManagementTab()
        {
            var tab = new TabPage("📦 Item Management");
            var rtb = CreateStyledRichTextBox();
            
            AppendHeader(rtb, "Managing Items");
            
            AppendSubHeader(rtb, "🔍 Searching & Filtering");
            AppendText(rtb, "Multiple ways to find items:");
            AppendBullet(rtb, "Search box: Searches name, code, tooltip, description, abilities");
            AppendBullet(rtb, "Rarity filter: All, Common, Uncommon, Rare, Epic, Legendary");
            AppendBullet(rtb, "Class filter: All, MISC, CONSUMABLE, ARTIFACT, QUEST");
            AppendBullet(rtb, "Custom Only checkbox: Shows only items with base_id (custom items)");
            AppendBullet(rtb, "Advanced Filters: Level range, cost range, has abilities, has stats");
            AppendBullet(rtb, "Clear All button: Resets all filters");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "➕ Creating Items");
            AppendNumbered(rtb, 1, "Click 'Add New Item' button (green)");
            AppendNumbered(rtb, 2, "Fill in Basic Info: Code (4 chars), Name, Class, Level, Cost");
            AppendNumbered(rtb, 3, "Set Appearance: Icon path, Model path");
            AppendNumbered(rtb, 4, "Add Extended Info: Tooltip, Description");
            AppendNumbered(rtb, 5, "Configure Stats: Use the Stats & Bonuses tab");
            AppendNumbered(rtb, 6, "Click Save");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "📋 Duplicating Items");
            AppendText(rtb, "Perfect for creating item variants:");
            AppendBullet(rtb, "Right-click item → Duplicate");
            AppendBullet(rtb, "All fields are copied with auto-generated new code");
            AppendBullet(rtb, "Code increment: i0a5 → i0a6 → i0a7... → i0b0");
            AppendBullet(rtb, "Modify as needed and save as new item");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "📊 Stats & Bonuses");
            AppendText(rtb, "Items can have multiple stats from 21 available types:");
            AppendBullet(rtb, "Primary: STR, AGI, INT");
            AppendBullet(rtb, "Resources: HP, MP, HP Regen, MP Regen");
            AppendBullet(rtb, "Combat: Damage, Armor, Attack Speed, Move Speed");
            AppendBullet(rtb, "Critical: Crit Chance, Crit Damage");
            AppendBullet(rtb, "Defense: Dodge, Block, Lifesteal");
            AppendBullet(rtb, "Magic: Spell Power, Fire/Cold/Lightning/Poison Resistance");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🔄 Auto-Generated Tooltips");
            AppendText(rtb, "In the Extended Info tab:");
            AppendBullet(rtb, "Auto-Generate Tooltip: Creates formatted tooltip with colored name, stats, abilities");
            AppendBullet(rtb, "Auto-Generate Description: Creates lore text based on item properties");
            AppendSpacer(rtb);
            
            AppendWarning(rtb, "Deletions are permanent! Consider duplicating items before major changes.");
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateLootSystemTab()
        {
            var tab = new TabPage("💎 Loot System");
            var rtb = CreateStyledRichTextBox();
            
            AppendHeader(rtb, "Loot System Overview");
            AppendText(rtb, "The system supports TWO complementary loot mechanisms that work together:");
            AppendSpacer(rtb);
            
            // Comparison table as formatted text
            AppendSubHeader(rtb, "⚖️ Loot Tiers vs Loot Tables");
            AppendSpacer(rtb);
            
            int start = rtb.TextLength;
            rtb.AppendText("┌─────────────────┬─────────────────────────┬─────────────────────────┐\n");
            rtb.AppendText("│     ASPECT      │      LOOT TIERS         │      LOOT TABLES        │\n");
            rtb.AppendText("├─────────────────┼─────────────────────────┼─────────────────────────┤\n");
            rtb.AppendText("│ Assignment      │ Automatic by unit level │ Manual per unit         │\n");
            rtb.AppendText("│ Item Selection  │ By item_level + rarity  │ Explicit item list      │\n");
            rtb.AppendText("│ Use Case        │ Generic enemy drops     │ Themed/boss drops       │\n");
            rtb.AppendText("│ Flexibility     │ Level-range based       │ Fully customizable      │\n");
            rtb.AppendText("└─────────────────┴─────────────────────────┴─────────────────────────┘\n");
            rtb.Select(start, rtb.TextLength - start);
            rtb.SelectionFont = new Font("Consolas", 9);
            rtb.SelectionColor = CodeColor;
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "📊 Loot Tiers (Level-Based Automatic Drops)");
            AppendText(rtb, "Access: Menu → Loot → Manage Loot Tiers");
            AppendSpacer(rtb);
            AppendText(rtb, "How it works:");
            AppendBullet(rtb, "Each tier covers a unit level range (e.g., 1-5, 6-10, 11-15)");
            AppendBullet(rtb, "When a unit dies, the tier determines base drop chance");
            AppendBullet(rtb, "Tier defines which item_level to use per rarity");
            AppendBullet(rtb, "Rarity weights control drop distribution (60% common, 25% uncommon, etc.)");
            AppendSpacer(rtb);
            AppendText(rtb, "Example: A level 7 Gnoll automatically uses Tier 2, which might drop:");
            AppendBullet(rtb, "Common items with item_level 2");
            AppendBullet(rtb, "Uncommon items with item_level 1");
            AppendBullet(rtb, "Rare items with item_level 1 (lower chance)");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "📋 Loot Tables (Named Item Collections)");
            AppendText(rtb, "Access: Menu → Loot → Manage Loot Tables");
            AppendSpacer(rtb);
            AppendText(rtb, "What they are:");
            AppendBullet(rtb, "Named, curated lists of items (e.g., 'Forest Trolls', 'Undead Crypt')");
            AppendBullet(rtb, "Manually assigned to specific units or destructibles");
            AppendBullet(rtb, "Each item has its own drop chance, weight, and quantity settings");
            AppendBullet(rtb, "Reusable - multiple units can share the same table");
            AppendSpacer(rtb);
            AppendText(rtb, "Table item settings:");
            AppendBullet(rtb, "Drop Chance: Individual item % (0-100)");
            AppendBullet(rtb, "Weight: Priority in weighted selection (higher = more likely)");
            AppendBullet(rtb, "Is Guaranteed: Always drops when table is rolled");
            AppendBullet(rtb, "Quantity Min/Max: How many of this item can drop");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🎯 When to Use Which?");
            AppendBullet(rtb, "Generic forest creatures → Loot Tier (auto by level)");
            AppendBullet(rtb, "Named boss with unique drops → Loot Table");
            AppendBullet(rtb, "Dungeon with themed loot → Loot Table ('Undead Crypt')");
            AppendBullet(rtb, "Random chests/crates → Loot Table per type");
            AppendBullet(rtb, "Boss with level-appropriate + special items → BOTH (loot_mode='both')");
            AppendSpacer(rtb);
            
            AppendTip(rtb, "Units can use both systems! Set loot_mode to 'both' for generic + specific drops.");
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateUnitsDestructiblesTab()
        {
            var tab = new TabPage("🛡️ Units & Destructibles");
            var rtb = CreateStyledRichTextBox();
            
            AppendHeader(rtb, "Managing Units & Destructibles");
            
            AppendSubHeader(rtb, "👹 Unit Types");
            AppendText(rtb, "Access: Menu → Units → Manage Unit Types");
            AppendSpacer(rtb);
            AppendText(rtb, "Unit Types represent WC3 unit definitions (e.g., 'Kobold Worker'), not individual units.");
            AppendSpacer(rtb);
            AppendText(rtb, "Key fields:");
            AppendBullet(rtb, "Unit Code: 4-char WC3 ID (e.g., 'hfoo', 'nkob')");
            AppendBullet(rtb, "Unit Name: Display name");
            AppendBullet(rtb, "Unit Level: For tier-based drop calculation");
            AppendBullet(rtb, "Is Boss: Flag for special loot treatment");
            AppendBullet(rtb, "Loot Mode: generic, specific, both, or none");
            AppendBullet(rtb, "Loot Tier: Assigned tier (for generic mode)");
            AppendBullet(rtb, "Loot Table: Assigned table (for specific mode)");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "📦 Loot Modes Explained");
            AppendBullet(rtb, "generic: Uses level-based tier pool only (90% of units)");
            AppendBullet(rtb, "specific: Uses assigned loot table only (unique bosses)");
            AppendBullet(rtb, "both: Rolls BOTH tier AND table (bosses with custom + generic)");
            AppendBullet(rtb, "none: No item drops (critters, summons)");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🏺 Destructible Types");
            AppendText(rtb, "Access: Menu → Destructibles → Manage Destructible Types");
            AppendSpacer(rtb);
            AppendText(rtb, "For breakable objects like crates, barrels, rocks, etc.");
            AppendBullet(rtb, "Destructible Code: 4-char WC3 ID");
            AppendBullet(rtb, "Category: crate, barrel, rock, tree, etc.");
            AppendBullet(rtb, "Level: Uses WE field 'bret' (Stats - Repair Time) as loot level for generic drops");
            AppendBullet(rtb, "Loot Table: Assigned loot table");
            AppendBullet(rtb, "Drop Chance Override: Custom drop %");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "📥 Importing from WC3 Files");
            AppendText(rtb, "Import unit/destructible definitions from your map:");
            AppendBullet(rtb, "Menu → Import → Import W3U (Units)");
            AppendBullet(rtb, "Menu → Import → Import W3B (Destructibles)");
            AppendText(rtb, "This populates types with WC3 data (names, icons, editor suffixes). For destructibles, WE field 'bret' / Stats - Repair Time is imported as the loot Level.");
            AppendSpacer(rtb);
            
            AppendTip(rtb, "Import your W3U file first, then assign loot tiers/tables to each unit type.");
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateExportingTab()
        {
            var tab = new TabPage("📤 Exporting");
            var rtb = CreateStyledRichTextBox();
            
            AppendHeader(rtb, "Export Options");
            
            AppendSubHeader(rtb, "🗂️ Export to W3T (World Editor)");
            AppendText(rtb, "Creates a .w3t file for import into WC3 World Editor:");
            AppendNumbered(rtb, 1, "Select items to export (or export all)");
            AppendNumbered(rtb, 2, "Click 'Export to W3T' button (purple)");
            AppendNumbered(rtb, 3, "Choose save location");
            AppendNumbered(rtb, 4, "Import the .w3t in World Editor's Object Editor");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "⚔️ Export Loot System JASS");
            AppendText(rtb, "Generates JASS code for the ItemLootSystem:");
            AppendText(rtb, "Menu → Export → Export Loot System");
            AppendSpacer(rtb);
            AppendText(rtb, "Creates these files:");
            AppendBullet(rtb, "ItemLootDefinitionsGeneric.j - Tier definitions and rarity weights");
            AppendBullet(rtb, "ItemLootDefinitionsSpecific.j - Unit-specific drop tables");
            AppendBullet(rtb, "Registration calls for all configured loot");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🎒 Export DEquipment Library");
            AppendText(rtb, "Generates JASS for DInventory/DEquipment integration:");
            AppendText(rtb, "Menu → Export → Export DEquipment");
            AppendSpacer(rtb);
            AppendText(rtb, "Creates item registration code compatible with the DEquipment system.");
            AppendSpacer(rtb);
            
            AppendWarning(rtb, "After exporting JASS files, remember to include them in your map's trigger scripts!");
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateIconsTab()
        {
            var tab = new TabPage("🖼️ Icons & BLP");
            var rtb = CreateStyledRichTextBox();
            
            AppendHeader(rtb, "Icon System");
            
            AppendSubHeader(rtb, "📁 Supported Formats");
            AppendBullet(rtb, ".blp (Blizzard Picture Format) - Native WC3 format");
            AppendBullet(rtb, ".png (Portable Network Graphics) - Pre-converted format (faster)");
            AppendBullet(rtb, ".tga (Targa) - Limited support");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "📂 Icon Path Configuration");
            AppendText(rtb, "Access: Tools → Configuration → Icon Paths tab");
            AppendSpacer(rtb);
            AppendText(rtb, "Two icon folders can be configured:");
            AppendBullet(rtb, "Blizzard WC3 Icons - Official WC3 icons");
            AppendBullet(rtb, "Custom Icons - Community/custom icons");
            AppendSpacer(rtb);
            AppendText(rtb, "Icons are stored with relative paths:");
            AppendText(rtb, "Example: ReplaceableTextures\\CommandButtons\\BTNSword.blp");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🎨 Using the Icon Selector");
            AppendNumbered(rtb, 1, "Click 'Browse Icons' in item editor");
            AppendNumbered(rtb, 2, "Navigate folder tree (left panel)");
            AppendNumbered(rtb, 3, "Select an icon (right panel)");
            AppendNumbered(rtb, 4, "Path is saved as .blp extension in database");
            AppendNumbered(rtb, 5, "Preview shows icon immediately");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "⚡ BLP to PNG Conversion");
            AppendText(rtb, "Why convert?");
            AppendBullet(rtb, "Some BLP files have encoding issues");
            AppendBullet(rtb, "PNG files load faster and more reliably");
            AppendSpacer(rtb);
            AppendText(rtb, "Option 1 - Pre-convert externally:");
            AppendBullet(rtb, "Use BLPConverter or similar tool");
            AppendBullet(rtb, "Keep both .blp and .png files in same folder");
            AppendSpacer(rtb);
            AppendText(rtb, "Option 2 - Automatic (built-in):");
            AppendBullet(rtb, "App tries to load .blp, falls back to .png");
            AppendBullet(rtb, "Converted files cached in /cache folder");
            AppendSpacer(rtb);
            
            AppendSubHeader(rtb, "🔧 Troubleshooting Icons");
            AppendBullet(rtb, "Icons appear black? Convert BLP to PNG externally");
            AppendBullet(rtb, "Wrong colors? Some BLPs use BGR - app auto-corrects");
            AppendBullet(rtb, "Not showing? Check icon folder path in Configuration");
            AppendBullet(rtb, "Clear cache: Tools → Configuration → Clear Icon Cache");
            AppendSpacer(rtb);
            
            AppendTip(rtb, "Pre-converted PNG icons load much faster than BLP files!");
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private TabPage CreateFAQTab()
        {
            var tab = new TabPage("❓ FAQ");
            var rtb = CreateStyledRichTextBox();
            
            AppendHeader(rtb, "Frequently Asked Questions");
            
            // General
            AppendSubHeader(rtb, "🌐 General");
            AppendSpacer(rtb);
            
            AppendFAQ(rtb, "Where is my data stored?",
                "All data is stored in the PostgreSQL database 'wc3_pots'. The application is just a viewer/editor. Backup with: pg_dump -U postgres -d wc3_pots > backup.sql");
            
            AppendFAQ(rtb, "Can I use this without PostgreSQL?",
                "No, PostgreSQL 12+ is required. Install it from postgresql.org.");
            
            AppendFAQ(rtb, "Can multiple people use this simultaneously?",
                "Yes! PostgreSQL supports concurrent connections. Refresh to see others' changes.");
            
            // Items
            AppendSubHeader(rtb, "📦 Items");
            AppendSpacer(rtb);
            
            AppendFAQ(rtb, "What's the difference between item_level and item_level_unclassified?",
                "item_level is for equippable items and determines loot tier drops. item_level_unclassified is for consumables where level means something else (like stack size).");
            
            AppendFAQ(rtb, "What is item_code and why 4 characters?",
                "WC3 uses 4-character codes for all objects (e.g., 'I001'). They must be unique. The format is typically letter-digit-letter-digit.");
            
            AppendFAQ(rtb, "Why do some items have red highlighting?",
                "Red rows indicate validation warnings: missing stats mentioned in tooltip, invalid icon path, or missing/short item name.");
            
            AppendFAQ(rtb, "What's the difference between tooltip and tooltip_extended?",
                "tooltip is the main description (always visible). tooltip_extended shows when holding Shift in WC3.");
            
            // Loot System
            AppendSubHeader(rtb, "💎 Loot System");
            AppendSpacer(rtb);
            
            AppendFAQ(rtb, "Can a unit use both tiers AND tables?",
                "Yes! Set loot_mode to 'both'. The unit will roll its tier pool AND its assigned table.");
            
            AppendFAQ(rtb, "How do I make certain items always drop?",
                "In a Loot Table, mark individual items as 'Is Guaranteed'. They always drop when the table is rolled.");
            
            AppendFAQ(rtb, "What's the difference between drop_chance and weight?",
                "drop_chance is whether this item drops at all (0-100%). weight determines selection priority when multiple items could drop (higher = more likely).");
            
            AppendFAQ(rtb, "Why isn't my unit dropping items?",
                "Check: 1) Loot Mode is not 'none', 2) Loot Tier assigned (generic mode), 3) Loot Table assigned with items (specific mode), 4) JASS code exported and included in map.");
            
            // Exporting
            AppendSubHeader(rtb, "📤 Exporting");
            AppendSpacer(rtb);
            
            AppendFAQ(rtb, "After exporting, items don't appear in WC3?",
                "Ensure you: 1) Imported .w3t in World Editor, 2) Saved the map, 3) Item codes don't conflict with existing items.");
            
            AppendFAQ(rtb, "My loot system isn't working in-game?",
                "Verify: 1) Exported JASS files included in map, 2) ItemLootSystem.j library present, 3) Triggers calling loot functions on unit death.");
            
            // Performance
            AppendSubHeader(rtb, "⚡ Performance");
            AppendSpacer(rtb);
            
            AppendFAQ(rtb, "The item list is slow with many items?",
                "Use filters to narrow results. The database handles thousands of items efficiently.");
            
            AppendFAQ(rtb, "Why is the icon selector slow?",
                "Large icon folders (1000+) take time. Icons load in batches. Consider organizing into subfolders or pre-converting to PNG.");
            
            tab.Controls.Add(rtb);
            return tab;
        }
        
        private void AppendFAQ(RichTextBox rtb, string question, string answer)
        {
            int start = rtb.TextLength;
            rtb.AppendText("Q: " + question + "\n");
            rtb.Select(start, question.Length + 3);
            rtb.SelectionFont = new Font("Segoe UI", 10, FontStyle.Bold);
            rtb.SelectionColor = HeaderColor;
            
            rtb.AppendText("A: " + answer + "\n\n");
        }
    }
}
