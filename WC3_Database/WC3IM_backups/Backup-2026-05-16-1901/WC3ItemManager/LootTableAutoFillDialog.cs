using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using Npgsql;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;

namespace WC3ItemManager
{
    public class LootTableAutoFillDialog : Form
    {
        private readonly string _connectionString;
        private readonly LootTable _lootTable;
        private readonly LootTableItemRepository _lootTableItemRepository;

        // Level range
        private NumericUpDown numMinLevel;
        private NumericUpDown numMaxLevel;

        // Item filters
        private CheckedListBox clbRarities;
        private CheckedListBox clbClasses;
        private CheckedListBox clbTypes;
        private CheckedListBox clbWc3Classifications;

        // Amount configuration
        private RadioButton rbRandomAmount;
        private RadioButton rbSpecificAmount;
        private NumericUpDown numMinAmount;
        private NumericUpDown numMaxAmount;
        private CheckBox chkAllMatching;

        // Default drop settings
        private NumericUpDown numDropChance;
        private NumericUpDown numWeight;
        private CheckBox chkGuaranteed;
        private NumericUpDown numMinQuantity;
        private NumericUpDown numMaxQuantity;

        // Preview and status
        private Label lblPreviewCount;
        private Button btnPreview;
        private Button btnOK;
        private Button btnCancel;

        // Result tracking
        public int ItemsAdded { get; private set; }

        public LootTableAutoFillDialog(string connectionString, LootTable lootTable)
        {
            _connectionString = connectionString;
            _lootTable = lootTable;
            _lootTableItemRepository = new LootTableItemRepository(connectionString);

            InitializeComponent();
            LoadFilterOptions();
            SetDefaultValues();
        }

        private void InitializeComponent()
        {
            this.Text = $"Auto Fill Loot Table: {_lootTable.Name}";
            this.Size = new Size(700, 750);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.ForeColor = Color.White;

            var mainPanel = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(10),
                RowCount = 7,
                ColumnCount = 1
            };
            mainPanel.RowStyles.Add(new RowStyle(SizeType.Absolute, 60));  // Level range
            mainPanel.RowStyles.Add(new RowStyle(SizeType.Percent, 50));   // Filters (upper)
            mainPanel.RowStyles.Add(new RowStyle(SizeType.Absolute, 100)); // Amount config
            mainPanel.RowStyles.Add(new RowStyle(SizeType.Absolute, 120)); // Drop settings
            mainPanel.RowStyles.Add(new RowStyle(SizeType.Absolute, 40));  // Preview
            mainPanel.RowStyles.Add(new RowStyle(SizeType.Absolute, 50));  // Buttons

            // Level Range Panel
            var pnlLevel = CreateLevelRangePanel();
            mainPanel.Controls.Add(pnlLevel, 0, 0);

            // Filters Panel (contains 4 checked list boxes)
            var pnlFilters = CreateFiltersPanel();
            mainPanel.Controls.Add(pnlFilters, 0, 1);

            // Amount Configuration Panel
            var pnlAmount = CreateAmountPanel();
            mainPanel.Controls.Add(pnlAmount, 0, 2);

            // Drop Settings Panel
            var pnlDropSettings = CreateDropSettingsPanel();
            mainPanel.Controls.Add(pnlDropSettings, 0, 3);

            // Preview Panel
            var pnlPreview = CreatePreviewPanel();
            mainPanel.Controls.Add(pnlPreview, 0, 4);

            // Buttons Panel
            var pnlButtons = CreateButtonsPanel();
            mainPanel.Controls.Add(pnlButtons, 0, 5);

            this.Controls.Add(mainPanel);
        }

        private Panel CreateLevelRangePanel()
        {
            var panel = new Panel { Dock = DockStyle.Fill };

            var grpLevel = new GroupBox
            {
                Text = "Item Level Range",
                Dock = DockStyle.Fill,
                ForeColor = Color.White
            };

            var lblMin = new Label { Text = "Min Level:", Location = new Point(10, 22), AutoSize = true };
            numMinLevel = new NumericUpDown
            {
                Location = new Point(80, 20),
                Width = 80,
                Minimum = 0,
                Maximum = 100,
                Value = _lootTable.MinLevel
            };

            var lblMax = new Label { Text = "Max Level:", Location = new Point(180, 22), AutoSize = true };
            numMaxLevel = new NumericUpDown
            {
                Location = new Point(255, 20),
                Width = 80,
                Minimum = 0,
                Maximum = 100,
                Value = _lootTable.MaxLevel
            };

            var lblNote = new Label
            {
                Text = "(Defaults from loot table's level range, changes here do not affect the table)",
                Location = new Point(350, 22),
                AutoSize = true,
                ForeColor = Color.Gray
            };

            grpLevel.Controls.AddRange(new Control[] { lblMin, numMinLevel, lblMax, numMaxLevel, lblNote });
            panel.Controls.Add(grpLevel);
            return panel;
        }

        private Panel CreateFiltersPanel()
        {
            var panel = new Panel { Dock = DockStyle.Fill };

            var filterLayout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 4,
                RowCount = 1
            };
            filterLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));
            filterLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));
            filterLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));
            filterLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25));

            // Rarities
            var grpRarities = new GroupBox { Text = "Item Rarities", Dock = DockStyle.Fill, ForeColor = Color.White };
            clbRarities = new CheckedListBox
            {
                Dock = DockStyle.Fill,
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.White,
                CheckOnClick = true
            };
            grpRarities.Controls.Add(clbRarities);
            filterLayout.Controls.Add(grpRarities, 0, 0);

            // Classes
            var grpClasses = new GroupBox { Text = "Item Classes", Dock = DockStyle.Fill, ForeColor = Color.White };
            clbClasses = new CheckedListBox
            {
                Dock = DockStyle.Fill,
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.White,
                CheckOnClick = true
            };
            grpClasses.Controls.Add(clbClasses);
            filterLayout.Controls.Add(grpClasses, 1, 0);

            // Types
            var grpTypes = new GroupBox { Text = "Item Types", Dock = DockStyle.Fill, ForeColor = Color.White };
            clbTypes = new CheckedListBox
            {
                Dock = DockStyle.Fill,
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.White,
                CheckOnClick = true
            };
            grpTypes.Controls.Add(clbTypes);
            filterLayout.Controls.Add(grpTypes, 2, 0);

            // WC3 Classifications
            var grpWc3 = new GroupBox { Text = "WC3 Classifications", Dock = DockStyle.Fill, ForeColor = Color.White };
            clbWc3Classifications = new CheckedListBox
            {
                Dock = DockStyle.Fill,
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.White,
                CheckOnClick = true
            };
            grpWc3.Controls.Add(clbWc3Classifications);
            filterLayout.Controls.Add(grpWc3, 3, 0);

            panel.Controls.Add(filterLayout);
            return panel;
        }

        private Panel CreateAmountPanel()
        {
            var panel = new Panel { Dock = DockStyle.Fill };

            var grpAmount = new GroupBox
            {
                Text = "Amount of Items to Add",
                Dock = DockStyle.Fill,
                ForeColor = Color.White
            };

            chkAllMatching = new CheckBox
            {
                Text = "Add ALL matching items",
                Location = new Point(10, 25),
                AutoSize = true,
                Checked = false
            };
            chkAllMatching.CheckedChanged += (s, e) =>
            {
                rbRandomAmount.Enabled = !chkAllMatching.Checked;
                rbSpecificAmount.Enabled = !chkAllMatching.Checked;
                numMinAmount.Enabled = !chkAllMatching.Checked && rbSpecificAmount.Checked;
                numMaxAmount.Enabled = !chkAllMatching.Checked && rbSpecificAmount.Checked;
            };

            rbRandomAmount = new RadioButton
            {
                Text = "Random amount from range:",
                Location = new Point(10, 50),
                AutoSize = true,
                Checked = true
            };
            rbRandomAmount.CheckedChanged += (s, e) =>
            {
                numMinAmount.Enabled = rbSpecificAmount.Checked;
                numMaxAmount.Enabled = rbSpecificAmount.Checked;
            };

            rbSpecificAmount = new RadioButton
            {
                Text = "Specific range:",
                Location = new Point(200, 50),
                AutoSize = true
            };

            numMinAmount = new NumericUpDown
            {
                Location = new Point(310, 48),
                Width = 60,
                Minimum = 1,
                Maximum = 500,
                Value = 5,
                Enabled = false
            };

            var lblTo = new Label { Text = "to", Location = new Point(375, 50), AutoSize = true };

            numMaxAmount = new NumericUpDown
            {
                Location = new Point(395, 48),
                Width = 60,
                Minimum = 1,
                Maximum = 500,
                Value = 20,
                Enabled = false
            };

            var lblAmountNote = new Label
            {
                Text = "(Random will pick 1 to total matching items)",
                Location = new Point(10, 75),
                AutoSize = true,
                ForeColor = Color.Gray
            };

            grpAmount.Controls.AddRange(new Control[] {
                chkAllMatching, rbRandomAmount, rbSpecificAmount,
                numMinAmount, lblTo, numMaxAmount, lblAmountNote
            });
            panel.Controls.Add(grpAmount);
            return panel;
        }

        private Panel CreateDropSettingsPanel()
        {
            var panel = new Panel { Dock = DockStyle.Fill };

            var grpDropSettings = new GroupBox
            {
                Text = "Default Drop Settings for Added Items",
                Dock = DockStyle.Fill,
                ForeColor = Color.White
            };

            var lblDropChance = new Label { Text = "Drop Chance (%):", Location = new Point(10, 25), AutoSize = true };
            numDropChance = new NumericUpDown
            {
                Location = new Point(120, 23),
                Width = 70,
                Minimum = 0,
                Maximum = 100,
                DecimalPlaces = 2,
                Value = 100
            };

            var lblWeight = new Label { Text = "Weight:", Location = new Point(210, 25), AutoSize = true };
            numWeight = new NumericUpDown
            {
                Location = new Point(265, 23),
                Width = 70,
                Minimum = 1,
                Maximum = 10000,
                Value = 100
            };

            chkGuaranteed = new CheckBox
            {
                Text = "Guaranteed Drop",
                Location = new Point(360, 25),
                AutoSize = true
            };

            var lblQuantity = new Label { Text = "Quantity Range:", Location = new Point(10, 55), AutoSize = true };
            numMinQuantity = new NumericUpDown
            {
                Location = new Point(120, 53),
                Width = 60,
                Minimum = 1,
                Maximum = 999,
                Value = 1
            };

            var lblQtyTo = new Label { Text = "to", Location = new Point(185, 55), AutoSize = true };
            numMaxQuantity = new NumericUpDown
            {
                Location = new Point(205, 53),
                Width = 60,
                Minimum = 1,
                Maximum = 999,
                Value = 1
            };

            var lblSettingsNote = new Label
            {
                Text = "(These settings will be applied to all added items)",
                Location = new Point(10, 85),
                AutoSize = true,
                ForeColor = Color.Gray
            };

            grpDropSettings.Controls.AddRange(new Control[] {
                lblDropChance, numDropChance, lblWeight, numWeight, chkGuaranteed,
                lblQuantity, numMinQuantity, lblQtyTo, numMaxQuantity, lblSettingsNote
            });
            panel.Controls.Add(grpDropSettings);
            return panel;
        }

        private Panel CreatePreviewPanel()
        {
            var panel = new Panel { Dock = DockStyle.Fill };

            lblPreviewCount = new Label
            {
                Text = "Click 'Preview' to see how many items match your criteria",
                Location = new Point(10, 10),
                AutoSize = true
            };

            btnPreview = new Button
            {
                Text = "Preview",
                Location = new Point(500, 5),
                Size = new Size(100, 28),
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnPreview.Click += BtnPreview_Click;

            panel.Controls.AddRange(new Control[] { lblPreviewCount, btnPreview });
            return panel;
        }

        private Panel CreateButtonsPanel()
        {
            var panel = new Panel { Dock = DockStyle.Fill };

            btnOK = new Button
            {
                Text = "Add Items",
                DialogResult = DialogResult.OK,
                Size = new Size(120, 35),
                Location = new Point(440, 5),
                BackColor = Color.FromArgb(0, 100, 0),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOK.Click += BtnOK_Click;

            btnCancel = new Button
            {
                Text = "Cancel",
                DialogResult = DialogResult.Cancel,
                Size = new Size(100, 35),
                Location = new Point(570, 5),
                BackColor = Color.FromArgb(100, 100, 100),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };

            panel.Controls.AddRange(new Control[] { btnOK, btnCancel });

            this.AcceptButton = btnOK;
            this.CancelButton = btnCancel;

            return panel;
        }

        private void LoadFilterOptions()
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();

                // Load Rarities
                using (var cmd = new NpgsqlCommand("SELECT id, rarity_name FROM item_rarities ORDER BY id", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var item = new FilterItem(reader.GetInt32(0), reader.GetString(1));
                        clbRarities.Items.Add(item);
                    }
                }

                // Load Classes
                using (var cmd = new NpgsqlCommand("SELECT id, class_name FROM item_classes ORDER BY class_name", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var item = new FilterItem(reader.GetInt32(0), reader.GetString(1));
                        clbClasses.Items.Add(item);
                    }
                }

                // Load Types
                using (var cmd = new NpgsqlCommand("SELECT id, type_name FROM item_types ORDER BY type_name", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var item = new FilterItem(reader.GetInt32(0), reader.GetString(1));
                        clbTypes.Items.Add(item);
                    }
                }

                // Load WC3 Classifications (hardcoded as they're enum-like)
                var wc3Classifications = new[] { "Permanent", "Charged", "Powerup", "Artifact", "Campaign", "Miscellaneous" };
                foreach (var classification in wc3Classifications)
                {
                    clbWc3Classifications.Items.Add(classification);
                }
            }
        }

        private void SetDefaultValues()
        {
            // Select all rarities by default
            for (int i = 0; i < clbRarities.Items.Count; i++)
                clbRarities.SetItemChecked(i, true);

            // Select all classes by default
            for (int i = 0; i < clbClasses.Items.Count; i++)
                clbClasses.SetItemChecked(i, true);

            // Select all types by default
            for (int i = 0; i < clbTypes.Items.Count; i++)
                clbTypes.SetItemChecked(i, true);

            // Select all WC3 classifications by default
            for (int i = 0; i < clbWc3Classifications.Items.Count; i++)
                clbWc3Classifications.SetItemChecked(i, true);
        }

        private void BtnPreview_Click(object sender, EventArgs e)
        {
            try
            {
                var items = GetMatchingItems();
                int existingCount = CountExistingItems(items);
                int newCount = items.Count - existingCount;

                lblPreviewCount.Text = $"Found {items.Count} matching items. {existingCount} already in table. {newCount} new items can be added.";
                lblPreviewCount.ForeColor = items.Count > 0 ? Color.LightGreen : Color.Orange;
            }
            catch (Exception ex)
            {
                lblPreviewCount.Text = $"Error: {ex.Message}";
                lblPreviewCount.ForeColor = Color.Red;
            }
        }

        private List<ItemInfo> GetMatchingItems()
        {
            var items = new List<ItemInfo>();

            var selectedRarities = clbRarities.CheckedItems.Cast<FilterItem>().Select(f => f.Id).ToList();
            var selectedClasses = clbClasses.CheckedItems.Cast<FilterItem>().Select(f => f.Id).ToList();
            var selectedTypes = clbTypes.CheckedItems.Cast<FilterItem>().Select(f => f.Id).ToList();
            var selectedWc3 = clbWc3Classifications.CheckedItems.Cast<string>().ToList();

            if (selectedRarities.Count == 0 && selectedClasses.Count == 0 && 
                selectedTypes.Count == 0 && selectedWc3.Count == 0)
            {
                throw new Exception("Please select at least one filter option.");
            }

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();

                var sql = @"
                    SELECT i.item_code, i.item_name, i.item_level, i.rarity_id, i.class_id, i.type_id, i.wc3_classification
                    FROM items i
                    WHERE i.item_level >= @minLevel AND i.item_level <= @maxLevel";

                var conditions = new List<string>();

                if (selectedRarities.Count > 0 && selectedRarities.Count < clbRarities.Items.Count)
                    conditions.Add($"i.rarity_id = ANY(@rarities)");

                if (selectedClasses.Count > 0 && selectedClasses.Count < clbClasses.Items.Count)
                    conditions.Add($"i.class_id = ANY(@classes)");

                if (selectedTypes.Count > 0 && selectedTypes.Count < clbTypes.Items.Count)
                    conditions.Add($"i.type_id = ANY(@types)");

                if (selectedWc3.Count > 0 && selectedWc3.Count < clbWc3Classifications.Items.Count)
                    conditions.Add($"i.wc3_classification = ANY(@wc3)");

                if (conditions.Count > 0)
                    sql += " AND " + string.Join(" AND ", conditions);

                sql += " ORDER BY i.item_level, i.item_name";

                using (var cmd = new NpgsqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("minLevel", (int)numMinLevel.Value);
                    cmd.Parameters.AddWithValue("maxLevel", (int)numMaxLevel.Value);

                    if (selectedRarities.Count > 0 && selectedRarities.Count < clbRarities.Items.Count)
                        cmd.Parameters.AddWithValue("rarities", selectedRarities.ToArray());

                    if (selectedClasses.Count > 0 && selectedClasses.Count < clbClasses.Items.Count)
                        cmd.Parameters.AddWithValue("classes", selectedClasses.ToArray());

                    if (selectedTypes.Count > 0 && selectedTypes.Count < clbTypes.Items.Count)
                        cmd.Parameters.AddWithValue("types", selectedTypes.ToArray());

                    if (selectedWc3.Count > 0 && selectedWc3.Count < clbWc3Classifications.Items.Count)
                        cmd.Parameters.AddWithValue("wc3", selectedWc3.ToArray());

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            items.Add(new ItemInfo
                            {
                                ItemCode = reader.GetString(0),
                                ItemName = reader.IsDBNull(1) ? "" : reader.GetString(1),
                                ItemLevel = reader.IsDBNull(2) ? 0 : reader.GetInt32(2)
                            });
                        }
                    }
                }
            }

            return items;
        }

        private int CountExistingItems(List<ItemInfo> items)
        {
            int count = 0;
            foreach (var item in items)
            {
                if (_lootTableItemRepository.ItemExistsInTable(_lootTable.Id, item.ItemCode))
                    count++;
            }
            return count;
        }

        private void BtnOK_Click(object sender, EventArgs e)
        {
            try
            {
                var allItems = GetMatchingItems();
                
                // Filter out items already in the table
                var newItems = allItems.Where(item => 
                    !_lootTableItemRepository.ItemExistsInTable(_lootTable.Id, item.ItemCode)).ToList();

                if (newItems.Count == 0)
                {
                    MessageBox.Show("No new items to add. All matching items are already in the table.", 
                        "Info", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    this.DialogResult = DialogResult.None;
                    return;
                }

                // Determine how many items to add
                List<ItemInfo> itemsToAdd;
                if (chkAllMatching.Checked)
                {
                    itemsToAdd = newItems;
                }
                else if (rbRandomAmount.Checked)
                {
                    var random = new Random();
                    int count = random.Next(1, newItems.Count + 1);
                    itemsToAdd = newItems.OrderBy(x => random.Next()).Take(count).ToList();
                }
                else
                {
                    var random = new Random();
                    int minAmt = (int)numMinAmount.Value;
                    int maxAmt = (int)numMaxAmount.Value;
                    if (minAmt > maxAmt) minAmt = maxAmt;
                    int count = random.Next(minAmt, Math.Min(maxAmt, newItems.Count) + 1);
                    itemsToAdd = newItems.OrderBy(x => random.Next()).Take(count).ToList();
                }

                // Add items to the loot table
                // Convert drop chance from percentage (0-100) to internal format (0-10000)
                int addedCount = 0;
                foreach (var item in itemsToAdd)
                {
                    var lootTableItem = new LootTableItem
                    {
                        LootTableId = _lootTable.Id,
                        ItemCode = item.ItemCode,
                        DropChance = (int)(numDropChance.Value * 100),
                        Weight = (int)numWeight.Value,
                        QuantityMin = (int)numMinQuantity.Value,
                        QuantityMax = (int)numMaxQuantity.Value,
                        IsGuaranteed = chkGuaranteed.Checked
                    };

                    _lootTableItemRepository.Insert(lootTableItem);
                    addedCount++;
                }

                ItemsAdded = addedCount;
                MessageBox.Show($"Successfully added {addedCount} items to the loot table.", 
                    "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error adding items: {ex.Message}", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                this.DialogResult = DialogResult.None;
            }
        }

        // Helper class for filter items
        private class FilterItem
        {
            public int Id { get; }
            public string Name { get; }

            public FilterItem(int id, string name)
            {
                Id = id;
                Name = name;
            }

            public override string ToString() => Name;
        }

        // Helper class for item info during auto-fill
        private class ItemInfo
        {
            public string ItemCode { get; set; }
            public string ItemName { get; set; }
            public int ItemLevel { get; set; }
        }
    }
}
