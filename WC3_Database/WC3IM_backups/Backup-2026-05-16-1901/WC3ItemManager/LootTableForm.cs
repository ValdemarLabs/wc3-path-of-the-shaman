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
    /// <summary>
    /// Form for managing loot tables and their items
    /// </summary>
    public class LootTableForm : Form
    {
        private readonly string _connectionString;
        private readonly LootTableRepository _tableRepository;
        private readonly LootTableItemRepository _itemRepository;
        
        // Controls - Left panel (loot tables list)
        private DataGridView dgvTables;
        private TextBox txtSearch;
        private ComboBox cmbCategory;
        private CheckBox chkShowDisabled;
        private Button btnAddTable;
        private Button btnDeleteTable;
        private Button btnDuplicateTable;
        private Button btnRefresh;
        
        // Controls - Right panel (table details)
        private Panel pnlDetails;
        private TextBox txtTableName;
        private TextBox txtDescription;
        private ComboBox cmbTableCategory;
        private NumericUpDown numDropChance;
        private NumericUpDown numDropCountMin;
        private NumericUpDown numDropCountMax;
        private NumericUpDown numMinLevel;
        private NumericUpDown numMaxLevel;
        private CheckBox chkEnabled;
        private Button btnSaveTable;
        
        // Controls - Items in table
        private DataGridView dgvItems;
        private Button btnAddItem;
        private Button btnRemoveItem;
        private Button btnEditItem;
        private Button btnAutoFill;
        
        private Label lblStatus;
        
        private LootTable _currentTable;
        private bool _isNewTable;
        
        private readonly string[] Categories = {
            "Level Range", "Monster Type", "Container", "Boss", "Special"
        };

        public LootTableForm(string connectionString)
        {
            _connectionString = connectionString;
            _tableRepository = new LootTableRepository(connectionString);
            _itemRepository = new LootTableItemRepository(connectionString);
            
            InitializeComponent();
            LoadTables();
        }

        private void InitializeComponent()
        {
            this.Text = "Loot Table Management";
            this.Size = new Size(1200, 800);
            this.StartPosition = FormStartPosition.CenterParent;
            this.MinimumSize = new Size(1000, 700);

            // Main split container
            var splitContainer = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                SplitterDistance = 380
            };

            // Left panel - Table list
            var pnlList = new Panel { Dock = DockStyle.Fill };
            CreateTableListPanel(pnlList);

            // Right panel - Details and Items
            pnlDetails = new Panel { Dock = DockStyle.Fill, AutoScroll = true, Padding = new Padding(10) };
            CreateDetailsPanel();

            splitContainer.Panel1.Controls.Add(pnlList);
            splitContainer.Panel2.Controls.Add(pnlDetails);

            // Status bar
            lblStatus = new Label
            {
                Dock = DockStyle.Bottom,
                Height = 25,
                BackColor = Color.FromArgb(35, 35, 35),
                ForeColor = Color.LightGray,
                Padding = new Padding(5, 5, 0, 0)
            };

            this.Controls.Add(splitContainer);
            this.Controls.Add(lblStatus);

            // Dark theme
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;
            ApplyDarkTheme(this);
        }

        private void CreateTableListPanel(Panel parent)
        {
            var lblTitle = new Label
            {
                Text = "Loot Tables",
                Font = new Font("Segoe UI", 12, FontStyle.Bold),
                Dock = DockStyle.Top,
                Height = 30,
                Padding = new Padding(5)
            };

            // Filter panel
            var pnlFilter = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 35,
                FlowDirection = FlowDirection.LeftToRight,
                Padding = new Padding(5, 2, 5, 2)
            };

            txtSearch = new TextBox { Width = 120, PlaceholderText = "Search..." };
            txtSearch.TextChanged += (s, e) => LoadTables();

            cmbCategory = new ComboBox { Width = 100, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbCategory.Items.Add("All Categories");
            foreach (var cat in Categories)
                cmbCategory.Items.Add(cat);
            cmbCategory.SelectedIndex = 0;
            cmbCategory.SelectedIndexChanged += (s, e) => LoadTables();

            chkShowDisabled = new CheckBox { Text = "Show Disabled", AutoSize = true, Padding = new Padding(5, 3, 0, 0) };
            chkShowDisabled.CheckedChanged += (s, e) => LoadTables();

            pnlFilter.Controls.AddRange(new Control[] { txtSearch, cmbCategory, chkShowDisabled });

            // Grid
            dgvTables = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(30, 30, 30),
                GridColor = Color.FromArgb(60, 60, 60)
            };
            dgvTables.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgvTables.DefaultCellStyle.ForeColor = Color.White;
            dgvTables.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvTables.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvTables.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvTables.EnableHeadersVisualStyles = false;
            dgvTables.SelectionChanged += DgvTables_SelectionChanged;

            // Toolbar
            var pnlToolbar = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 40,
                FlowDirection = FlowDirection.LeftToRight,
                Padding = new Padding(5)
            };

            btnAddTable = new Button { Text = "Add New", Width = 75 };
            btnAddTable.Click += BtnAddTable_Click;

            btnDuplicateTable = new Button { Text = "Duplicate", Width = 75 };
            btnDuplicateTable.Click += BtnDuplicateTable_Click;

            btnDeleteTable = new Button { Text = "Delete", Width = 75 };
            btnDeleteTable.Click += BtnDeleteTable_Click;

            btnRefresh = new Button { Text = "Refresh", Width = 75 };
            btnRefresh.Click += (s, e) => LoadTables();

            pnlToolbar.Controls.AddRange(new Control[] { btnAddTable, btnDuplicateTable, btnDeleteTable, btnRefresh });

            parent.Controls.Add(dgvTables);
            parent.Controls.Add(pnlFilter);
            parent.Controls.Add(pnlToolbar);
            parent.Controls.Add(lblTitle);
        }

        private void CreateDetailsPanel()
        {
            int y = 10;
            int labelWidth = 120;
            int inputWidth = 250;

            // Title
            var lblDetailsTitle = new Label
            {
                Text = "Table Configuration",
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                Location = new Point(10, y),
                AutoSize = true
            };
            pnlDetails.Controls.Add(lblDetailsTitle);
            y += 35;

            // Table Name
            txtTableName = new TextBox { Width = inputWidth };
            AddLabelAndControl("Table Name:", ref y, labelWidth, txtTableName);

            // Category
            cmbTableCategory = new ComboBox { Width = inputWidth, DropDownStyle = ComboBoxStyle.DropDownList };
            foreach (var cat in Categories)
                cmbTableCategory.Items.Add(cat);
            cmbTableCategory.SelectedIndex = 0;
            AddLabelAndControl("Category:", ref y, labelWidth, cmbTableCategory);

            // Level Range
            var pnlLevelRange = new FlowLayoutPanel { FlowDirection = FlowDirection.LeftToRight, AutoSize = true };
            numMinLevel = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 100, Value = 1 };
            numMaxLevel = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 100, Value = 5 };
            pnlLevelRange.Controls.Add(numMinLevel);
            pnlLevelRange.Controls.Add(new Label { Text = " to ", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            pnlLevelRange.Controls.Add(numMaxLevel);
            AddLabelAndControl("Level Range:", ref y, labelWidth, pnlLevelRange);

            // Drop Chance
            numDropChance = new NumericUpDown { Width = 80, Minimum = 0, Maximum = 100, DecimalPlaces = 1, Value = 100 };
            AddLabelAndControl("Drop Chance %:", ref y, labelWidth, numDropChance);

            // Drop Count Range
            var pnlDropCount = new FlowLayoutPanel { FlowDirection = FlowDirection.LeftToRight, AutoSize = true };
            numDropCountMin = new NumericUpDown { Width = 60, Minimum = 0, Maximum = 10, Value = 1 };
            numDropCountMax = new NumericUpDown { Width = 60, Minimum = 0, Maximum = 10, Value = 1 };
            pnlDropCount.Controls.Add(numDropCountMin);
            pnlDropCount.Controls.Add(new Label { Text = " to ", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            pnlDropCount.Controls.Add(numDropCountMax);
            AddLabelAndControl("Drop Count:", ref y, labelWidth, pnlDropCount);

            // Description
            txtDescription = new TextBox { Width = inputWidth, Height = 50, Multiline = true };
            AddLabelAndControl("Description:", ref y, labelWidth, txtDescription);

            // Enabled
            chkEnabled = new CheckBox { Text = "Enabled", Checked = true };
            AddLabelAndControl("", ref y, labelWidth, chkEnabled);

            // Save button
            btnSaveTable = new Button
            {
                Text = "Save Table",
                Location = new Point(labelWidth + 15, y),
                Width = 100,
                Height = 28,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnSaveTable.FlatAppearance.BorderSize = 0;
            btnSaveTable.Click += BtnSaveTable_Click;
            pnlDetails.Controls.Add(btnSaveTable);
            y += 50;

            // Items section
            var lblItemsTitle = new Label
            {
                Text = "Items in Table",
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                Location = new Point(10, y),
                AutoSize = true
            };
            pnlDetails.Controls.Add(lblItemsTitle);
            y += 30;

            // Items grid
            dgvItems = new DataGridView
            {
                Location = new Point(10, y),
                Size = new Size(500, 200),
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(30, 30, 30),
                GridColor = Color.FromArgb(60, 60, 60)
            };
            dgvItems.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgvItems.DefaultCellStyle.ForeColor = Color.White;
            dgvItems.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvItems.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvItems.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvItems.EnableHeadersVisualStyles = false;
            pnlDetails.Controls.Add(dgvItems);
            y += 210;

            // Item buttons
            var pnlItemButtons = new FlowLayoutPanel
            {
                Location = new Point(10, y),
                Size = new Size(500, 35),
                FlowDirection = FlowDirection.LeftToRight
            };

            btnAddItem = new Button { Text = "Add Item", Width = 80 };
            btnAddItem.Click += BtnAddItem_Click;

            btnEditItem = new Button { Text = "Edit Item", Width = 80 };
            btnEditItem.Click += BtnEditItem_Click;

            btnRemoveItem = new Button { Text = "Remove", Width = 80 };
            btnRemoveItem.Click += BtnRemoveItem_Click;

            btnAutoFill = new Button { Text = "Auto Fill...", Width = 80, BackColor = Color.FromArgb(0, 100, 0), ForeColor = Color.White };
            btnAutoFill.Click += BtnAutoFill_Click;

            pnlItemButtons.Controls.AddRange(new Control[] { btnAddItem, btnEditItem, btnRemoveItem, btnAutoFill });
            pnlDetails.Controls.Add(pnlItemButtons);
        }

        private void AddLabelAndControl(string labelText, ref int y, int labelWidth, Control control)
        {
            if (!string.IsNullOrEmpty(labelText))
            {
                var label = new Label
                {
                    Text = labelText,
                    Location = new Point(10, y + 3),
                    Width = labelWidth,
                    AutoSize = false
                };
                pnlDetails.Controls.Add(label);
            }

            control.Location = new Point(labelWidth + 15, y);
            pnlDetails.Controls.Add(control);

            y += Math.Max(control.Height, 25) + 10;
        }

        private void LoadTables()
        {
            try
            {
                var tables = _tableRepository.GetAll();

                // Apply filters
                if (!chkShowDisabled.Checked)
                    tables = tables.Where(t => t.Enabled).ToList();

                if (cmbCategory.SelectedIndex > 0)
                {
                    var category = cmbCategory.SelectedItem.ToString();
                    tables = tables.Where(t => t.Category == category).ToList();
                }

                if (!string.IsNullOrWhiteSpace(txtSearch.Text))
                {
                    var search = txtSearch.Text.ToLower();
                    tables = tables.Where(t =>
                        t.Name.ToLower().Contains(search) ||
                        (t.Description?.ToLower().Contains(search) ?? false)).ToList();
                }

                dgvTables.DataSource = null;
                dgvTables.Columns.Clear();

                dgvTables.Columns.Add(new DataGridViewTextBoxColumn { Name = "Id", HeaderText = "ID", Width = 40 });
                dgvTables.Columns.Add(new DataGridViewTextBoxColumn { Name = "Name", HeaderText = "Name", Width = 120 });
                dgvTables.Columns.Add(new DataGridViewTextBoxColumn { Name = "Category", HeaderText = "Category", Width = 80 });
                dgvTables.Columns.Add(new DataGridViewTextBoxColumn { Name = "Levels", HeaderText = "Levels", Width = 60 });
                dgvTables.Columns.Add(new DataGridViewTextBoxColumn { Name = "Items", HeaderText = "Items", Width = 50 });
                dgvTables.Columns.Add(new DataGridViewCheckBoxColumn { Name = "Enabled", HeaderText = "On", Width = 30 });

                foreach (var table in tables)
                {
                    var itemCount = _itemRepository.GetByLootTableId(table.Id).Count;
                    var levelRange = table.MinLevel == table.MaxLevel
                        ? $"{table.MinLevel}"
                        : $"{table.MinLevel}-{table.MaxLevel}";

                    dgvTables.Rows.Add(
                        table.Id,
                        table.Name,
                        table.Category ?? "—",
                        levelRange,
                        itemCount,
                        table.Enabled
                    );
                    dgvTables.Rows[dgvTables.Rows.Count - 1].Tag = table;
                }

                lblStatus.Text = $"Loaded {tables.Count} loot tables";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading tables: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void LoadItems()
        {
            dgvItems.DataSource = null;
            dgvItems.Columns.Clear();

            if (_currentTable == null || _isNewTable)
            {
                dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "Info", HeaderText = "Info" });
                dgvItems.Rows.Add("Save the table first to add items");
                return;
            }

            try
            {
                var items = _itemRepository.GetByLootTableId(_currentTable.Id);

                dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "ItemCode", HeaderText = "Code", Width = 60 });
                dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "ItemName", HeaderText = "Item Name", Width = 150 });
                dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "DropChance", HeaderText = "Chance %", Width = 70 });
                dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "Weight", HeaderText = "Weight", Width = 60 });
                dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "Quantity", HeaderText = "Qty", Width = 50 });
                dgvItems.Columns.Add(new DataGridViewCheckBoxColumn { Name = "Guaranteed", HeaderText = "Guar.", Width = 50 });

                // Build a lookup dictionary for item names
                var itemNames = GetItemNamesDictionary(items.Select(i => i.ItemCode).ToList());

                foreach (var item in items)
                {
                    // Get item name from lookup
                    var itemName = itemNames.ContainsKey(item.ItemCode) ? itemNames[item.ItemCode] : item.ItemCode;

                    var qtyRange = item.QuantityMin == item.QuantityMax
                        ? $"{item.QuantityMin}"
                        : $"{item.QuantityMin}-{item.QuantityMax}";

                    dgvItems.Rows.Add(
                        item.ItemCode,
                        itemName,
                        $"{item.DropChance}%",
                        item.Weight,
                        qtyRange,
                        item.IsGuaranteed
                    );
                    dgvItems.Rows[dgvItems.Rows.Count - 1].Tag = item;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading items: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private Dictionary<string, string> GetItemNamesDictionary(List<string> itemCodes)
        {
            var result = new Dictionary<string, string>();
            if (itemCodes == null || itemCodes.Count == 0) return result;

            try
            {
                using (var conn = new NpgsqlConnection(_connectionString))
                {
                    conn.Open();
                    using (var cmd = new NpgsqlCommand(
                        "SELECT item_code, item_name FROM items WHERE item_code = ANY(@codes)", conn))
                    {
                        cmd.Parameters.AddWithValue("@codes", itemCodes.ToArray());
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var code = reader.GetString(0);
                                var name = reader.IsDBNull(1) ? code : reader.GetString(1);
                                // Strip WC3 color codes from item names
                                name = System.Text.RegularExpressions.Regex.Replace(name, @"\|c[0-9a-fA-F]{8}|\|r", "");
                                result[code] = name;
                            }
                        }
                    }
                }
            }
            catch { }

            return result;
        }

        private void DgvTables_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvTables.SelectedRows.Count > 0)
            {
                _currentTable = dgvTables.SelectedRows[0].Tag as LootTable;
                _isNewTable = false;
                DisplayTable(_currentTable);
                LoadItems();
            }
        }

        private void DisplayTable(LootTable table)
        {
            if (table == null)
            {
                txtTableName.Text = "";
                txtDescription.Text = "";
                numDropChance.Value = 100;
                numDropCountMin.Value = 1;
                numDropCountMax.Value = 1;
                numMinLevel.Value = 1;
                numMaxLevel.Value = 5;
                chkEnabled.Checked = true;
                cmbTableCategory.SelectedIndex = 0;
                return;
            }

            txtTableName.Text = table.Name;
            txtDescription.Text = table.Description ?? "";
            numDropChance.Value = table.DropChance / 100m;  // Convert from 0-10000 to percentage
            numDropCountMin.Value = table.DropCountMin;
            numDropCountMax.Value = table.DropCountMax;
            numMinLevel.Value = table.MinLevel;
            numMaxLevel.Value = table.MaxLevel;
            chkEnabled.Checked = table.Enabled;

            // Set category
            var catIndex = Categories.ToList().FindIndex(c => c == table.Category);
            cmbTableCategory.SelectedIndex = catIndex >= 0 ? catIndex : 0;
        }

        private void BtnAddTable_Click(object sender, EventArgs e)
        {
            _currentTable = new LootTable
            {
                Name = "New Loot Table",
                Category = "Level Range",
                MinLevel = 1,
                MaxLevel = 5,
                DropChance = 100,
                DropCountMin = 1,
                DropCountMax = 1,
                Enabled = true
            };
            _isNewTable = true;
            DisplayTable(_currentTable);
            LoadItems();
            txtTableName.Focus();
            txtTableName.SelectAll();
        }

        private void BtnDuplicateTable_Click(object sender, EventArgs e)
        {
            if (_currentTable == null || _isNewTable)
            {
                MessageBox.Show("Select a table to duplicate first.", "Info",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            try
            {
                var newId = _tableRepository.Duplicate(_currentTable.Id, $"{_currentTable.Name} (Copy)");
                LoadTables();

                // Select the new table
                foreach (DataGridViewRow row in dgvTables.Rows)
                {
                    if (row.Tag is LootTable t && t.Id == newId)
                    {
                        row.Selected = true;
                        break;
                    }
                }

                lblStatus.Text = $"Duplicated table as ID {newId}";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error duplicating table: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnDeleteTable_Click(object sender, EventArgs e)
        {
            if (_currentTable == null || _isNewTable)
            {
                MessageBox.Show("Select a table to delete first.", "Info",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var result = MessageBox.Show(
                $"Delete loot table '{_currentTable.Name}'?\n\nThis will also remove all items in this table.",
                "Confirm Delete",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);

            if (result == DialogResult.Yes)
            {
                try
                {
                    _tableRepository.Delete(_currentTable.Id);
                    LoadTables();
                    _currentTable = null;
                    DisplayTable(null);
                    LoadItems();
                    lblStatus.Text = "Table deleted";
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error deleting table: {ex.Message}", "Error",
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void BtnSaveTable_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrWhiteSpace(txtTableName.Text))
            {
                MessageBox.Show("Please enter a table name.", "Validation",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                var table = _currentTable ?? new LootTable();
                table.Name = txtTableName.Text.Trim();
                table.Description = string.IsNullOrWhiteSpace(txtDescription.Text) ? null : txtDescription.Text.Trim();
                table.Category = cmbTableCategory.SelectedItem?.ToString();
                table.DropChance = (int)(numDropChance.Value * 100);  // Convert percentage to 0-10000 range
                table.DropCountMin = (int)numDropCountMin.Value;
                table.DropCountMax = (int)numDropCountMax.Value;
                table.MinLevel = (int)numMinLevel.Value;
                table.MaxLevel = (int)numMaxLevel.Value;
                table.Enabled = chkEnabled.Checked;

                if (_isNewTable)
                {
                    var newId = _tableRepository.Insert(table);
                    table.Id = newId;
                    _currentTable = table;
                    _isNewTable = false;
                    lblStatus.Text = $"Created new table with ID {newId}";
                }
                else
                {
                    _tableRepository.Update(table);
                    lblStatus.Text = "Table saved";
                }

                LoadTables();
                LoadItems();

                // Re-select the saved table
                foreach (DataGridViewRow row in dgvTables.Rows)
                {
                    if (row.Tag is LootTable t && t.Id == table.Id)
                    {
                        row.Selected = true;
                        break;
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving table: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnAddItem_Click(object sender, EventArgs e)
        {
            if (_currentTable == null || _isNewTable)
            {
                MessageBox.Show("Please save the table first before adding items.", "Info",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            using (var dialog = new LootTableItemDialog(_connectionString, _currentTable.Id))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    LoadItems();
                    lblStatus.Text = "Item added to table";
                }
            }
        }

        private void BtnAutoFill_Click(object sender, EventArgs e)
        {
            if (_currentTable == null || _isNewTable)
            {
                MessageBox.Show("Please save the table first before using Auto Fill.", "Info",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            using (var dialog = new LootTableAutoFillDialog(_connectionString, _currentTable))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    LoadItems();
                    LoadTables(); // Update item count in list
                    lblStatus.Text = $"Added {dialog.ItemsAdded} items to table";
                }
            }
        }

        private void BtnEditItem_Click(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count == 0 || dgvItems.SelectedRows[0].Tag == null)
            {
                MessageBox.Show("Select an item to edit.", "Info",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var item = dgvItems.SelectedRows[0].Tag as LootTableItem;
            if (item == null) return;

            using (var dialog = new LootTableItemDialog(_connectionString, _currentTable.Id, item))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    LoadItems();
                    lblStatus.Text = "Item updated";
                }
            }
        }

        private void BtnRemoveItem_Click(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count == 0 || dgvItems.SelectedRows[0].Tag == null)
            {
                MessageBox.Show("Select an item to remove.", "Info",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var item = dgvItems.SelectedRows[0].Tag as LootTableItem;
            if (item == null) return;

            var result = MessageBox.Show(
                $"Remove item '{item.ItemCode}' from this table?",
                "Confirm Remove",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);

            if (result == DialogResult.Yes)
            {
                try
                {
                    _itemRepository.Delete(item.Id);
                    LoadItems();
                    lblStatus.Text = "Item removed from table";
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error removing item: {ex.Message}", "Error",
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void ApplyDarkTheme(Control parent)
        {
            foreach (Control control in parent.Controls)
            {
                if (control is TextBox txt)
                {
                    txt.BackColor = Color.FromArgb(60, 60, 60);
                    txt.ForeColor = Color.White;
                    txt.BorderStyle = BorderStyle.FixedSingle;
                }
                else if (control is NumericUpDown num)
                {
                    num.BackColor = Color.FromArgb(60, 60, 60);
                    num.ForeColor = Color.White;
                }
                else if (control is ComboBox cmb)
                {
                    cmb.BackColor = Color.FromArgb(60, 60, 60);
                    cmb.ForeColor = Color.White;
                    cmb.FlatStyle = FlatStyle.Flat;
                }
                else if (control is Button btn && btn.BackColor != Color.FromArgb(0, 122, 204))
                {
                    btn.BackColor = Color.FromArgb(60, 60, 60);
                    btn.ForeColor = Color.White;
                    btn.FlatStyle = FlatStyle.Flat;
                }
                else if (control is CheckBox chk)
                {
                    chk.ForeColor = Color.White;
                }
                else if (control is Panel || control is FlowLayoutPanel || control is SplitContainer)
                {
                    control.BackColor = Color.FromArgb(45, 45, 45);
                }

                if (control.HasChildren)
                    ApplyDarkTheme(control);
            }
        }
    }

    /// <summary>
    /// Dialog for adding/editing items in a loot table
    /// </summary>
    public class LootTableItemDialog : Form
    {
        private readonly string _connectionString;
        private readonly int _lootTableId;
        private readonly LootTableItemRepository _repository;
        private readonly LootTableItem _existingItem;

        private TextBox txtItemSearch;
        private ListBox lstItems;
        private List<ComboBoxItem> _allItems = new List<ComboBoxItem>();
        private NumericUpDown numDropChance;
        private NumericUpDown numWeight;
        private NumericUpDown numQuantityMin;
        private NumericUpDown numQuantityMax;
        private CheckBox chkGuaranteed;
        private Button btnSave;
        private Button btnCancel;

        // Property to get selected item code
        public string SelectedItemCode => (lstItems.SelectedItem as ComboBoxItem)?.Value;

        public LootTableItemDialog(string connectionString, int lootTableId, LootTableItem existingItem = null)
        {
            _connectionString = connectionString;
            _lootTableId = lootTableId;
            _repository = new LootTableItemRepository(connectionString);
            _existingItem = existingItem;

            InitializeComponent();
            LoadItems();

            if (_existingItem != null)
                LoadExistingItem();
        }

        private void InitializeComponent()
        {
            this.Text = _existingItem == null ? "Add Item to Table" : "Edit Table Item";
            this.Size = new Size(500, 500);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;

            int y = 20;
            int labelWidth = 100;
            int controlWidth = 340;

            // Item search
            var lblSearch = new Label { Text = "Search:", Location = new Point(20, y + 3), Width = labelWidth };
            txtItemSearch = new TextBox
            {
                Location = new Point(labelWidth + 25, y),
                Width = controlWidth,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            txtItemSearch.TextChanged += TxtItemSearch_TextChanged;
            this.Controls.AddRange(new Control[] { lblSearch, txtItemSearch });
            y += 30;

            // Item list
            var lblItem = new Label { Text = "Item:", Location = new Point(20, y + 3), Width = labelWidth };
            lstItems = new ListBox
            {
                Location = new Point(labelWidth + 25, y),
                Width = controlWidth,
                Height = 150,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle
            };
            this.Controls.AddRange(new Control[] { lblItem, lstItems });
            y += 160;

            // Drop Chance
            var lblChance = new Label { Text = "Drop Chance %:", Location = new Point(20, y + 3), Width = labelWidth };
            numDropChance = new NumericUpDown
            {
                Location = new Point(labelWidth + 25, y),
                Width = 80,
                Minimum = 0,
                Maximum = 100,
                DecimalPlaces = 1,
                Value = 100,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            this.Controls.AddRange(new Control[] { lblChance, numDropChance });
            y += 35;

            // Weight
            var lblWeight = new Label { Text = "Weight:", Location = new Point(20, y + 3), Width = labelWidth };
            numWeight = new NumericUpDown
            {
                Location = new Point(labelWidth + 25, y),
                Width = 80,
                Minimum = 0,
                Maximum = 1000,
                Value = 100,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            this.Controls.AddRange(new Control[] { lblWeight, numWeight });
            y += 35;

            // Quantity
            var lblQty = new Label { Text = "Quantity:", Location = new Point(20, y + 3), Width = labelWidth };
            var pnlQty = new FlowLayoutPanel
            {
                Location = new Point(labelWidth + 25, y),
                AutoSize = true,
                FlowDirection = FlowDirection.LeftToRight,
                BackColor = Color.Transparent
            };
            numQuantityMin = new NumericUpDown
            {
                Width = 60,
                Minimum = 1,
                Maximum = 100,
                Value = 1,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            numQuantityMax = new NumericUpDown
            {
                Width = 60,
                Minimum = 1,
                Maximum = 100,
                Value = 1,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            pnlQty.Controls.Add(numQuantityMin);
            pnlQty.Controls.Add(new Label { Text = " to ", AutoSize = true, ForeColor = Color.White, Padding = new Padding(0, 3, 0, 0) });
            pnlQty.Controls.Add(numQuantityMax);
            this.Controls.AddRange(new Control[] { lblQty, pnlQty });
            y += 40;

            // Guaranteed
            chkGuaranteed = new CheckBox
            {
                Text = "Guaranteed Drop",
                Location = new Point(labelWidth + 25, y),
                AutoSize = true,
                ForeColor = Color.White
            };
            this.Controls.Add(chkGuaranteed);
            y += 40;

            // Buttons
            btnSave = new Button
            {
                Text = "Save",
                Location = new Point(170, y),
                Width = 80,
                Height = 30,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                DialogResult = DialogResult.OK
            };
            btnSave.Click += BtnSave_Click;

            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(260, y),
                Width = 80,
                Height = 30,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                DialogResult = DialogResult.Cancel
            };

            this.Controls.AddRange(new Control[] { btnSave, btnCancel });
            this.AcceptButton = btnSave;
            this.CancelButton = btnCancel;
        }

        private void TxtItemSearch_TextChanged(object sender, EventArgs e)
        {
            FilterItems();
        }

        private void FilterItems()
        {
            string filter = txtItemSearch.Text.Trim().ToLower();
            lstItems.Items.Clear();

            var filtered = string.IsNullOrEmpty(filter)
                ? _allItems
                : _allItems.Where(i => i.Text.ToLower().Contains(filter)).ToList();

            foreach (var item in filtered)
            {
                lstItems.Items.Add(item);
            }

            if (lstItems.Items.Count > 0)
                lstItems.SelectedIndex = 0;
        }

        private void LoadItems()
        {
            try
            {
                _allItems.Clear();

                using (var conn = new NpgsqlConnection(_connectionString))
                {
                    conn.Open();
                    using (var cmd = new NpgsqlCommand(
                        "SELECT item_code, item_name FROM items ORDER BY item_name", conn))
                    {
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var code = reader.GetString(0);
                                var name = reader.IsDBNull(1) ? code : reader.GetString(1);
                                // Strip WC3 color codes
                                name = System.Text.RegularExpressions.Regex.Replace(name, @"\|c[0-9a-fA-F]{8}|\|r", "");
                                
                                _allItems.Add(new ComboBoxItem
                                {
                                    Text = $"[{code}] {name}",
                                    Value = code
                                });
                            }
                        }
                    }
                }

                FilterItems();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading items: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void LoadExistingItem()
        {
            // Find and select the item in list
            for (int i = 0; i < lstItems.Items.Count; i++)
            {
                if (lstItems.Items[i] is ComboBoxItem cbi && cbi.Value == _existingItem.ItemCode)
                {
                    lstItems.SelectedIndex = i;
                    break;
                }
            }

            numDropChance.Value = _existingItem.DropChance / 100m;  // Convert from 0-10000 to percentage
            numWeight.Value = _existingItem.Weight;
            numQuantityMin.Value = _existingItem.QuantityMin;
            numQuantityMax.Value = _existingItem.QuantityMax;
            chkGuaranteed.Checked = _existingItem.IsGuaranteed;

            // Disable item selection when editing
            lstItems.Enabled = false;
            txtItemSearch.Enabled = false;
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            if (lstItems.SelectedItem == null)
            {
                MessageBox.Show("Please select an item.", "Validation",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                this.DialogResult = DialogResult.None;
                return;
            }

            try
            {
                var selectedItem = (ComboBoxItem)lstItems.SelectedItem;

                if (_existingItem == null)
                {
                    // Check if item already exists in table
                    if (_repository.ItemExistsInTable(_lootTableId, selectedItem.Value))
                    {
                        MessageBox.Show("This item is already in the table.", "Validation",
                            MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        this.DialogResult = DialogResult.None;
                        return;
                    }

                    var newItem = new LootTableItem
                    {
                        LootTableId = _lootTableId,
                        ItemCode = selectedItem.Value,
                        DropChance = (int)(numDropChance.Value * 100),  // Convert percentage to 0-10000
                        Weight = (int)numWeight.Value,
                        QuantityMin = (int)numQuantityMin.Value,
                        QuantityMax = (int)numQuantityMax.Value,
                        IsGuaranteed = chkGuaranteed.Checked
                    };
                    _repository.Insert(newItem);
                }
                else
                {
                    _existingItem.DropChance = (int)(numDropChance.Value * 100);  // Convert percentage to 0-10000
                    _existingItem.Weight = (int)numWeight.Value;
                    _existingItem.QuantityMin = (int)numQuantityMin.Value;
                    _existingItem.QuantityMax = (int)numQuantityMax.Value;
                    _existingItem.IsGuaranteed = chkGuaranteed.Checked;
                    _repository.Update(_existingItem);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving item: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                this.DialogResult = DialogResult.None;
            }
        }

        private class ComboBoxItem
        {
            public string Text { get; set; }
            public string Value { get; set; }
            public override string ToString() => Text;
        }
    }
}
