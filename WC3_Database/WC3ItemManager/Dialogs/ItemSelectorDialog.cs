using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Dialogs
{
    /// <summary>
    /// Dialog for selecting an item and configuring drop properties
    /// </summary>
    public class ItemSelectorDialog : Form
    {
        private readonly string _connectionString;
        private readonly string _unitCode;
        
        private TextBox txtSearch;
        private DataGridView dgvItems;
        private NumericUpDown nudDropChance;
        private NumericUpDown nudMinQty;
        private NumericUpDown nudMaxQty;
        private CheckBox chkGuaranteed;
        private NumericUpDown nudWeight;
        private TextBox txtNotes;
        private Button btnOK;
        private Button btnCancel;
        private Label lblSelected;
        
        private List<ItemInfo> _allItems;
        private ItemInfo _selectedItem;
        
        public UnitSpecificDrop Result { get; private set; }

        public ItemSelectorDialog(string connectionString, string unitCode)
        {
            _connectionString = connectionString;
            _unitCode = unitCode;
            
            InitializeComponent();
            LoadItems();
            ApplyDarkTheme();
        }

        private void InitializeComponent()
        {
            this.Text = "Add Item Drop";
            this.Size = new Size(800, 650);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.Sizable;
            this.MinimumSize = new Size(600, 500);

            // Search panel
            var pnlSearch = new Panel
            {
                Dock = DockStyle.Top,
                Height = 40,
                Padding = new Padding(10, 5, 10, 5)
            };

            var lblSearch = new Label
            {
                Text = "Search:",
                Location = new Point(10, 12),
                AutoSize = true
            };

            txtSearch = new TextBox
            {
                Location = new Point(70, 8),
                Width = 300
            };
            txtSearch.TextChanged += TxtSearch_TextChanged;

            lblSelected = new Label
            {
                Location = new Point(400, 12),
                AutoSize = true,
                Text = "No item selected"
            };

            pnlSearch.Controls.AddRange(new Control[] { lblSearch, txtSearch, lblSelected });

            // Items grid
            dgvItems = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(45, 45, 48),
                BorderStyle = BorderStyle.None
            };

            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "ItemCode", HeaderText = "Code", Width = 60 });
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "ItemName", HeaderText = "Name", Width = 200 });
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "ItemType", HeaderText = "Type", Width = 100 });
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "Rarity", HeaderText = "Rarity", Width = 80 });
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "Level", HeaderText = "Level", Width = 50 });
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { Name = "IconPath", HeaderText = "Icon", Width = 150 });

            dgvItems.SelectionChanged += DgvItems_SelectionChanged;
            dgvItems.CellDoubleClick += DgvItems_CellDoubleClick;

            // Properties panel
            var pnlProperties = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 180,
                Padding = new Padding(10)
            };

            var grpProperties = new GroupBox
            {
                Text = "Drop Properties",
                Dock = DockStyle.Fill,
                Padding = new Padding(10)
            };

            // Drop Chance
            var lblDropChance = new Label { Text = "Drop Chance (%):", Location = new Point(15, 25), AutoSize = true };
            nudDropChance = new NumericUpDown
            {
                Location = new Point(130, 23),
                Size = new Size(80, 23),
                Minimum = 0,
                Maximum = 100,
                DecimalPlaces = 1,
                Value = 100
            };

            // Guaranteed checkbox
            chkGuaranteed = new CheckBox
            {
                Text = "Guaranteed Drop",
                Location = new Point(230, 25),
                AutoSize = true
            };
            chkGuaranteed.CheckedChanged += ChkGuaranteed_CheckedChanged;

            // Quantity
            var lblMinQty = new Label { Text = "Min Qty:", Location = new Point(15, 55), AutoSize = true };
            nudMinQty = new NumericUpDown
            {
                Location = new Point(80, 53),
                Size = new Size(60, 23),
                Minimum = 1,
                Maximum = 99,
                Value = 1
            };

            var lblMaxQty = new Label { Text = "Max Qty:", Location = new Point(160, 55), AutoSize = true };
            nudMaxQty = new NumericUpDown
            {
                Location = new Point(230, 53),
                Size = new Size(60, 23),
                Minimum = 1,
                Maximum = 99,
                Value = 1
            };

            // Weight
            var lblWeight = new Label { Text = "Weight:", Location = new Point(310, 55), AutoSize = true };
            nudWeight = new NumericUpDown
            {
                Location = new Point(370, 53),
                Size = new Size(70, 23),
                Minimum = 1,
                Maximum = 10000,
                Value = 100
            };

            // Notes
            var lblNotes = new Label { Text = "Notes:", Location = new Point(15, 85), AutoSize = true };
            txtNotes = new TextBox
            {
                Location = new Point(80, 83),
                Size = new Size(400, 23)
            };

            grpProperties.Controls.AddRange(new Control[] {
                lblDropChance, nudDropChance, chkGuaranteed,
                lblMinQty, nudMinQty, lblMaxQty, nudMaxQty,
                lblWeight, nudWeight,
                lblNotes, txtNotes
            });

            pnlProperties.Controls.Add(grpProperties);

            // Buttons panel
            var pnlButtons = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 50,
                Padding = new Padding(10)
            };

            btnCancel = new Button
            {
                Text = "Cancel",
                Size = new Size(100, 30),
                FlatStyle = FlatStyle.Flat
            };
            btnCancel.Click += (s, e) => { DialogResult = DialogResult.Cancel; };

            btnOK = new Button
            {
                Text = "Add Drop",
                Size = new Size(100, 30),
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Enabled = false
            };
            btnOK.Click += BtnOK_Click;

            var flowButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Right,
                FlowDirection = FlowDirection.RightToLeft,
                AutoSize = true,
                WrapContents = false,
                Padding = new Padding(5)
            };
            flowButtons.Controls.Add(btnCancel);
            flowButtons.Controls.Add(btnOK);

            pnlButtons.Controls.Add(flowButtons);

            // Add controls to form (order matters for docking)
            this.Controls.Add(dgvItems);
            this.Controls.Add(pnlSearch);
            this.Controls.Add(pnlProperties);
            this.Controls.Add(pnlButtons);
        }

        private void LoadItems()
        {
            _allItems = new List<ItemInfo>();

            try
            {
                using (var conn = new NpgsqlConnection(_connectionString))
                {
                    conn.Open();
                    using (var cmd = new NpgsqlCommand(@"
                        SELECT i.item_code, i.item_name, i.item_level,
                               t.type_name, r.rarity_name, i.icon_path
                        FROM items i
                        LEFT JOIN item_types t ON i.type_id = t.id
                        LEFT JOIN item_rarities r ON i.rarity_id = r.id
                        ORDER BY i.item_name", conn))
                    {
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                _allItems.Add(new ItemInfo
                                {
                                    ItemCode = reader.GetString(0).Trim(),
                                    ItemName = reader.GetString(1),
                                    Level = reader.IsDBNull(2) ? 0 : reader.GetInt32(2),
                                    TypeName = reader.IsDBNull(3) ? "-" : reader.GetString(3),
                                    RarityName = reader.IsDBNull(4) ? "-" : reader.GetString(4),
                                    IconPath = reader.IsDBNull(5) ? "-" : reader.GetString(5)
                                });
                            }
                        }
                    }
                }

                FilterItems(string.Empty);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading items: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void FilterItems(string filter)
        {
            dgvItems.Rows.Clear();

            var filtered = string.IsNullOrWhiteSpace(filter)
                ? _allItems
                : _allItems.Where(i =>
                    i.ItemCode.Contains(filter, StringComparison.OrdinalIgnoreCase) ||
                    i.ItemName.Contains(filter, StringComparison.OrdinalIgnoreCase) ||
                    i.TypeName.Contains(filter, StringComparison.OrdinalIgnoreCase) ||
                    i.RarityName.Contains(filter, StringComparison.OrdinalIgnoreCase))
                .ToList();

            foreach (var item in filtered)
            {
                int rowIndex = dgvItems.Rows.Add(
                    item.ItemCode,
                    item.ItemName,
                    item.TypeName,
                    item.RarityName,
                    item.Level > 0 ? item.Level.ToString() : "-",
                    item.IconPath
                );
                dgvItems.Rows[rowIndex].Tag = item;

                // Color by rarity
                var color = GetRarityColor(item.RarityName);
                if (color != Color.Empty)
                {
                    dgvItems.Rows[rowIndex].DefaultCellStyle.ForeColor = color;
                }
            }
        }

        private Color GetRarityColor(string rarity)
        {
            return rarity?.ToLower() switch
            {
                "common" => Color.White,
                "uncommon" => Color.FromArgb(30, 255, 0),      // Green
                "rare" => Color.FromArgb(0, 112, 221),         // Blue
                "epic" => Color.FromArgb(163, 53, 238),        // Purple
                "legendary" => Color.FromArgb(255, 128, 0),    // Orange
                "unique" => Color.FromArgb(255, 215, 0),       // Gold
                "set" => Color.FromArgb(0, 255, 0),            // Bright green
                _ => Color.Empty
            };
        }

        private void TxtSearch_TextChanged(object sender, EventArgs e)
        {
            FilterItems(txtSearch.Text);
        }

        private void DgvItems_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count > 0)
            {
                _selectedItem = dgvItems.SelectedRows[0].Tag as ItemInfo;
                lblSelected.Text = _selectedItem != null
                    ? $"Selected: {_selectedItem.ItemName} ({_selectedItem.ItemCode})"
                    : "No item selected";
                btnOK.Enabled = _selectedItem != null;
            }
            else
            {
                _selectedItem = null;
                lblSelected.Text = "No item selected";
                btnOK.Enabled = false;
            }
        }

        private void DgvItems_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0 && _selectedItem != null)
            {
                BtnOK_Click(sender, e);
            }
        }

        private void ChkGuaranteed_CheckedChanged(object sender, EventArgs e)
        {
            nudDropChance.Enabled = !chkGuaranteed.Checked;
            if (chkGuaranteed.Checked)
            {
                nudDropChance.Value = 100;
            }
        }

        private void BtnOK_Click(object sender, EventArgs e)
        {
            if (_selectedItem == null)
            {
                MessageBox.Show("Please select an item.", "Validation",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (nudMinQty.Value > nudMaxQty.Value)
            {
                MessageBox.Show("Min quantity cannot be greater than max quantity.", "Validation",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            Result = new UnitSpecificDrop
            {
                UnitCode = _unitCode,
                ItemCode = _selectedItem.ItemCode,
                ItemName = _selectedItem.ItemName,
                DropChance = nudDropChance.Value,
                MinQuantity = (int)nudMinQty.Value,
                MaxQuantity = (int)nudMaxQty.Value,
                IsGuaranteed = chkGuaranteed.Checked,
                Weight = (int)nudWeight.Value,
                Notes = txtNotes.Text,
                Enabled = true
            };

            DialogResult = DialogResult.OK;
        }

        private void ApplyDarkTheme()
        {
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.ForeColor = Color.White;

            ApplyDarkThemeRecursive(this);
        }

        private void ApplyDarkThemeRecursive(Control parent)
        {
            foreach (Control c in parent.Controls)
            {
                if (c is TextBox || c is NumericUpDown)
                {
                    c.BackColor = Color.FromArgb(30, 30, 30);
                    c.ForeColor = Color.White;
                }
                else if (c is DataGridView dgv)
                {
                    dgv.BackgroundColor = Color.FromArgb(45, 45, 48);
                    dgv.GridColor = Color.FromArgb(60, 60, 60);
                    dgv.DefaultCellStyle.BackColor = Color.FromArgb(30, 30, 30);
                    dgv.DefaultCellStyle.ForeColor = Color.White;
                    dgv.DefaultCellStyle.SelectionBackColor = Color.FromArgb(0, 122, 204);
                    dgv.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(45, 45, 48);
                    dgv.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
                    dgv.EnableHeadersVisualStyles = false;
                }
                else if (c is GroupBox grp)
                {
                    grp.ForeColor = Color.White;
                }
                else if (c is Button btn)
                {
                    if (btn.BackColor == Color.FromArgb(0, 122, 204))
                    {
                        // Keep accent buttons
                    }
                    else
                    {
                        btn.BackColor = Color.FromArgb(60, 60, 60);
                        btn.ForeColor = Color.White;
                    }
                    btn.FlatAppearance.BorderColor = Color.FromArgb(100, 100, 100);
                }
                else if (c is Panel || c is FlowLayoutPanel)
                {
                    c.BackColor = Color.FromArgb(45, 45, 48);
                }

                if (c.HasChildren)
                {
                    ApplyDarkThemeRecursive(c);
                }
            }
        }

        /// <summary>
        /// Simple item info class for display
        /// </summary>
        private class ItemInfo
        {
            public string ItemCode { get; set; }
            public string ItemName { get; set; }
            public int Level { get; set; }
            public string TypeName { get; set; }
            public string RarityName { get; set; }
            public string IconPath { get; set; }
        }
    }
}
