using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Dialogs;
using WC3ItemManager.Models;
using WC3ItemManager.Parsers;
using WC3ItemManager.Repositories;

namespace WC3ItemManager
{
    /// <summary>
    /// Form for managing unit types and their loot configuration
    /// </summary>
    public class UnitTypeForm : Form
    {
        private readonly string _connectionString;
        private readonly UnitTypeRepository _unitRepo;
        private readonly LootTierRepository _tierRepo;
        private readonly LootTableRepository _tableRepo;
        private readonly UnitSpecificDropRepository _dropRepo;
        
        // Controls - List panel
        private DataGridView dgvUnits;
        private TextBox txtSearch;
        private ComboBox cmbLootModeFilter;
        private CheckBox chkBossOnly;
        private NumericUpDown numMinLevel;
        private NumericUpDown numMaxLevel;
        
        // Controls - Details panel
        private Panel pnlDetails;
        private Label lblUnitName;
        private Label lblUnitCode;
        private PictureBox picIcon;
        private NumericUpDown numUnitLevel;
        private CheckBox chkIsBoss;
        private ComboBox cmbLootMode;
        private ComboBox cmbLootTier;
        private ComboBox cmbLootTable;
        private NumericUpDown numDropMin;
        private NumericUpDown numDropMax;
        private TextBox txtNotes;
        private DataGridView dgvSpecificDrops;
        
        // Buttons
        private Button btnImport;
        private Button btnSave;
        private Button btnRefresh;
        private Button btnAddDrop;
        private Button btnEditDrop;
        private Button btnRemoveDrop;
        private Label lblStatus;
        
        private UnitType _currentUnit;
        private List<UnitType> _selectedUnits = new List<UnitType>();
        private List<LootTier> _tiers;
        private List<LootTable> _tables;
        private bool _isLoadingUnit;
        private bool _isMultiSelect;
        
        // Track original values for multi-select (to detect changes)
        private int? _origLevel;
        private bool? _origIsBoss;
        private int? _origLootMode;
        private int? _origTierIndex;
        private int? _origTableIndex;
        private int? _origDropMin;
        private int? _origDropMax;
        
        public UnitTypeForm(string connectionString)
        {
            _connectionString = connectionString;
            _unitRepo = new UnitTypeRepository(connectionString);
            _tierRepo = new LootTierRepository(connectionString);
            _tableRepo = new LootTableRepository(connectionString);
            _dropRepo = new UnitSpecificDropRepository(connectionString);
            
            InitializeComponent();
            LoadTiers();
            LoadLootTables();
            LoadUnits();
        }

        private void InitializeComponent()
        {
            this.Text = "Unit Type Management";
            this.Size = new Size(1200, 800);
            this.StartPosition = FormStartPosition.CenterParent;
            this.MinimumSize = new Size(1000, 600);

            // Main split container
            var splitMain = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                SplitterDistance = 450
            };

            // Left panel - Unit list
            CreateListPanel(splitMain.Panel1);

            // Right panel - Details
            CreateDetailsPanel(splitMain.Panel2);

            // Status bar
            lblStatus = new Label
            {
                Dock = DockStyle.Bottom,
                Height = 25,
                BackColor = Color.FromArgb(35, 35, 35),
                ForeColor = Color.LightGray,
                Padding = new Padding(5, 5, 0, 0)
            };

            this.Controls.Add(splitMain);
            this.Controls.Add(lblStatus);

            // Dark theme
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;
            ApplyDarkTheme(this);
        }

        private void CreateListPanel(Panel parent)
        {
            var pnlFilters = new Panel
            {
                Dock = DockStyle.Top,
                Height = 80,
                Padding = new Padding(5)
            };

            // Search
            var lblSearch = new Label { Text = "Search:", Location = new Point(5, 10), AutoSize = true };
            txtSearch = new TextBox
            {
                Location = new Point(60, 7),
                Width = 150
            };
            txtSearch.TextChanged += (s, e) => FilterUnits();

            // Loot mode filter
            var lblMode = new Label { Text = "Mode:", Location = new Point(220, 10), AutoSize = true };
            cmbLootModeFilter = new ComboBox
            {
                Location = new Point(260, 7),
                Width = 100,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbLootModeFilter.Items.AddRange(new object[] { "All", "Generic", "Specific", "Both", "None" });
            cmbLootModeFilter.SelectedIndex = 0;
            cmbLootModeFilter.SelectedIndexChanged += (s, e) => FilterUnits();

            // Boss only
            chkBossOnly = new CheckBox
            {
                Text = "Boss Only",
                Location = new Point(370, 8),
                AutoSize = true
            };
            chkBossOnly.CheckedChanged += (s, e) => FilterUnits();

            // Level range
            var lblLevel = new Label { Text = "Level:", Location = new Point(5, 45), AutoSize = true };
            numMinLevel = new NumericUpDown
            {
                Location = new Point(50, 42),
                Width = 50,
                Minimum = 0,
                Maximum = 100,
                Value = 0
            };
            var lblTo = new Label { Text = "to", Location = new Point(105, 45), AutoSize = true };
            numMaxLevel = new NumericUpDown
            {
                Location = new Point(125, 42),
                Width = 50,
                Minimum = 0,
                Maximum = 100,
                Value = 99
            };
            numMinLevel.ValueChanged += (s, e) => FilterUnits();
            numMaxLevel.ValueChanged += (s, e) => FilterUnits();

            // Import button
            btnImport = new Button
            {
                Text = "Import Units...",
                Location = new Point(200, 40),
                Width = 100,
                Height = 25,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnImport.Click += BtnImport_Click;

            // Refresh button
            btnRefresh = new Button
            {
                Text = "Refresh",
                Location = new Point(310, 40),
                Width = 70,
                Height = 25
            };
            btnRefresh.Click += (s, e) => LoadUnits();

            pnlFilters.Controls.AddRange(new Control[] {
                lblSearch, txtSearch, lblMode, cmbLootModeFilter, chkBossOnly,
                lblLevel, numMinLevel, lblTo, numMaxLevel, btnImport, btnRefresh
            });

            // Unit grid
            dgvUnits = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = true,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(30, 30, 30),
                GridColor = Color.FromArgb(60, 60, 60)
            };
            dgvUnits.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgvUnits.DefaultCellStyle.ForeColor = Color.White;
            dgvUnits.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvUnits.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvUnits.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvUnits.EnableHeadersVisualStyles = false;
            dgvUnits.SelectionChanged += DgvUnits_SelectionChanged;

            parent.Controls.Add(dgvUnits);
            parent.Controls.Add(pnlFilters);
        }

        private void CreateDetailsPanel(Panel parent)
        {
            pnlDetails = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(10)
            };

            int y = 10;

            // Unit header
            picIcon = new PictureBox
            {
                Location = new Point(10, y),
                Size = new Size(64, 64),
                SizeMode = PictureBoxSizeMode.Zoom,
                BackColor = Color.FromArgb(60, 60, 60)
            };
            pnlDetails.Controls.Add(picIcon);

            lblUnitName = new Label
            {
                Location = new Point(85, y),
                Size = new Size(300, 25),
                Font = new Font("Segoe UI", 12, FontStyle.Bold),
                Text = "Select a unit"
            };
            pnlDetails.Controls.Add(lblUnitName);

            lblUnitCode = new Label
            {
                Location = new Point(85, y + 25),
                Size = new Size(100, 20),
                ForeColor = Color.Gray,
                Text = ""
            };
            pnlDetails.Controls.Add(lblUnitCode);

            y += 80;

            // Unit Level
            AddLabelAndControl("Unit Level:", ref y, 100,
                numUnitLevel = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 100 });

            // Is Boss
            chkIsBoss = new CheckBox { Text = "Is Boss", AutoSize = true, ThreeState = true };
            chkIsBoss.CheckedChanged += ChkIsBoss_CheckedChanged;
            AddLabelAndControl("", ref y, 100, chkIsBoss);

            // Loot Mode
            cmbLootMode = new ComboBox
            {
                Width = 120,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbLootMode.Items.AddRange(new object[] { "Generic", "Specific", "Both", "None" });
            cmbLootMode.SelectedIndexChanged += CmbLootMode_SelectedIndexChanged;
            AddLabelAndControl("Loot Mode:", ref y, 100, cmbLootMode);

            // Loot Tier (only for Generic/Both)
            cmbLootTier = new ComboBox
            {
                Width = 150,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            AddLabelAndControl("Loot Tier:", ref y, 100, cmbLootTier);

            // Loot Table (alternative to tier - specific named tables)
            cmbLootTable = new ComboBox
            {
                Width = 200,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            AddLabelAndControl("Loot Table:", ref y, 100, cmbLootTable);

            // Drop Count Range
            var pnlDropCount = new FlowLayoutPanel
            {
                FlowDirection = FlowDirection.LeftToRight,
                AutoSize = true
            };
            numDropMin = new NumericUpDown { Width = 50, Minimum = 0, Maximum = 10, Value = 1 };
            numDropMax = new NumericUpDown { Width = 50, Minimum = 0, Maximum = 10, Value = 1 };
            pnlDropCount.Controls.Add(numDropMin);
            pnlDropCount.Controls.Add(new Label { Text = " to ", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            pnlDropCount.Controls.Add(numDropMax);
            AddLabelAndControl("Drop Count:", ref y, 100, pnlDropCount);

            // Notes
            txtNotes = new TextBox { Width = 250, Height = 50, Multiline = true };
            AddLabelAndControl("Notes:", ref y, 100, txtNotes);

            y += 10;

            // Save button
            btnSave = new Button
            {
                Text = "Save Changes",
                Location = new Point(10, y),
                Width = 120,
                Height = 30,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnSave.FlatAppearance.BorderSize = 0;
            btnSave.Click += BtnSave_Click;
            pnlDetails.Controls.Add(btnSave);

            y += 50;

            // Specific Drops section
            var lblSpecificDrops = new Label
            {
                Text = "Specific Drops (Boss Loot)",
                Location = new Point(10, y),
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                AutoSize = true
            };
            pnlDetails.Controls.Add(lblSpecificDrops);
            y += 25;

            // Specific drops grid (wider to show Weight/Guaranteed/Notes)
            dgvSpecificDrops = new DataGridView
            {
                Location = new Point(10, y),
                Size = new Size(500, 180),
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(30, 30, 30),
                GridColor = Color.FromArgb(60, 60, 60)
            };
            dgvSpecificDrops.CellDoubleClick += DgvSpecificDrops_CellDoubleClick;
            dgvSpecificDrops.SelectionChanged += DgvSpecificDrops_SelectionChanged;
            dgvSpecificDrops.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgvSpecificDrops.DefaultCellStyle.ForeColor = Color.White;
            dgvSpecificDrops.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvSpecificDrops.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvSpecificDrops.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvSpecificDrops.EnableHeadersVisualStyles = false;
            pnlDetails.Controls.Add(dgvSpecificDrops);

            y += 190;

            // Add/Edit/Remove drop buttons
            btnAddDrop = new Button
            {
                Text = "Add Drop",
                Location = new Point(10, y),
                Width = 80,
                Height = 25
            };
            btnAddDrop.Click += BtnAddDrop_Click;
            pnlDetails.Controls.Add(btnAddDrop);

            btnEditDrop = new Button
            {
                Text = "Edit",
                Location = new Point(100, y),
                Width = 60,
                Height = 25
            };
            btnEditDrop.Click += BtnEditDrop_Click;
            pnlDetails.Controls.Add(btnEditDrop);

            btnRemoveDrop = new Button
            {
                Text = "Remove",
                Location = new Point(170, y),
                Width = 80,
                Height = 25
            };
            btnRemoveDrop.Click += BtnRemoveDrop_Click;
            pnlDetails.Controls.Add(btnRemoveDrop);

            parent.Controls.Add(pnlDetails);
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

            y += Math.Max(control.Height, 25) + 8;
        }

        private void LoadTiers()
        {
            try
            {
                _tiers = _tierRepo.GetAll();
                cmbLootTier.Items.Clear();
                cmbLootTier.Items.Add("(Auto by Level)");
                foreach (var tier in _tiers)
                {
                    cmbLootTier.Items.Add($"{tier.TierName} (Lvl {tier.LevelRange})");
                }
                cmbLootTier.SelectedIndex = 0;
            }
            catch (Exception ex)
            {
                Logger.Instance.Error("Failed to load tiers", ex);
            }
        }

        private void LoadLootTables()
        {
            try
            {
                _tables = _tableRepo.GetEnabled();
                cmbLootTable.Items.Clear();
                cmbLootTable.Items.Add("(None - Use Tier)");
                foreach (var table in _tables)
                {
                    cmbLootTable.Items.Add($"{table.Name} (Lvl {table.LevelRangeDisplay})");
                }
                cmbLootTable.SelectedIndex = 0;
            }
            catch (Exception ex)
            {
                Logger.Instance.Error("Failed to load loot tables", ex);
            }
        }

        private void LoadUnits()
        {
            FilterUnits();
        }

        private void FilterUnits()
        {
            try
            {
                LootMode? modeFilter = null;
                if (cmbLootModeFilter.SelectedIndex > 0)
                {
                    modeFilter = (LootMode)(cmbLootModeFilter.SelectedIndex - 1);
                }

                var units = _unitRepo.GetFiltered(
                    isBoss: chkBossOnly.Checked ? true : null,
                    lootMode: modeFilter,
                    minLevel: (int)numMinLevel.Value > 0 ? (int?)numMinLevel.Value : null,
                    maxLevel: (int)numMaxLevel.Value < 99 ? (int?)numMaxLevel.Value : null,
                    searchText: string.IsNullOrWhiteSpace(txtSearch.Text) ? null : txtSearch.Text
                );

                dgvUnits.DataSource = null;
                dgvUnits.Columns.Clear();

                // Icon column
                var iconColumn = new DataGridViewImageColumn
                {
                    Name = "Icon",
                    HeaderText = "",
                    Width = 32,
                    ImageLayout = DataGridViewImageCellLayout.Zoom
                };
                dgvUnits.Columns.Add(iconColumn);
                dgvUnits.Columns.Add(new DataGridViewTextBoxColumn { Name = "Code", HeaderText = "Code", Width = 50 });
                dgvUnits.Columns.Add(new DataGridViewTextBoxColumn { Name = "Name", HeaderText = "Name", Width = 150 });
                dgvUnits.Columns.Add(new DataGridViewTextBoxColumn { Name = "Level", HeaderText = "Lvl", Width = 40 });
                dgvUnits.Columns.Add(new DataGridViewTextBoxColumn { Name = "Mode", HeaderText = "Mode", Width = 70 });
                dgvUnits.Columns.Add(new DataGridViewCheckBoxColumn { Name = "Boss", HeaderText = "Boss", Width = 40 });
                dgvUnits.RowTemplate.Height = 32; // Accommodate icon size

                foreach (var unit in units)
                {
                    // Load icon for unit
                    Image unitIcon = LoadUnitIconThumbnail(unit.IconPath);
                    
                    int rowIdx = dgvUnits.Rows.Add(
                        unitIcon ?? new Bitmap(1, 1),
                        unit.UnitCode,
                        unit.DisplayName,
                        unit.UnitLevel,
                        unit.LootMode.ToString(),
                        unit.IsBoss
                    );
                    dgvUnits.Rows[rowIdx].Tag = unit;

                    // Color code by loot mode
                    var row = dgvUnits.Rows[rowIdx];
                    switch (unit.LootMode)
                    {
                        case LootMode.Generic:
                            row.DefaultCellStyle.ForeColor = Color.LightGray;
                            break;
                        case LootMode.Specific:
                            row.DefaultCellStyle.ForeColor = Color.FromArgb(0, 150, 255);
                            break;
                        case LootMode.Both:
                            row.DefaultCellStyle.ForeColor = Color.FromArgb(180, 100, 255);
                            break;
                        case LootMode.None:
                            row.DefaultCellStyle.ForeColor = Color.FromArgb(150, 50, 50);
                            break;
                    }
                    
                    // Background highlight based on loot status
                    bool hasLoot = unit.LootMode != LootMode.None && 
                                   (unit.LootTierId.HasValue || unit.LootTableId.HasValue);
                    if (unit.LootMode == LootMode.None)
                    {
                        // Red background for no loot
                        row.DefaultCellStyle.BackColor = Color.FromArgb(60, 30, 30);
                    }
                    else if (hasLoot)
                    {
                        // Green background for loot configured
                        row.DefaultCellStyle.BackColor = Color.FromArgb(30, 60, 30);
                    }
                    else
                    {
                        // Yellow/orange background for mode set but no tier/table
                        row.DefaultCellStyle.BackColor = Color.FromArgb(60, 50, 20);
                    }
                }

                lblStatus.Text = $"Showing {units.Count} units";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading units: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error("Failed to load units", ex);
            }
        }

        private void DgvUnits_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvUnits.SelectedRows.Count == 0) return;

            // Gather selected units
            _selectedUnits.Clear();
            foreach (DataGridViewRow row in dgvUnits.SelectedRows)
            {
                if (row.Tag is UnitType unit)
                    _selectedUnits.Add(unit);
            }

            if (_selectedUnits.Count == 1)
            {
                _isMultiSelect = false;
                LoadUnitDetails(_selectedUnits[0]);
            }
            else if (_selectedUnits.Count > 1)
            {
                _isMultiSelect = true;
                LoadMultiUnitDetails();
            }
        }

        private void LoadMultiUnitDetails()
        {
            _isLoadingUnit = true;
            _currentUnit = _selectedUnits[0]; // Keep reference to first for some operations

            lblUnitName.Text = $"Multiple Selected ({_selectedUnits.Count})";
            lblUnitCode.Text = "Multiple units";
            picIcon.Image = null;

            // Check if values are the same across all selected
            bool sameLevel = _selectedUnits.All(u => u.UnitLevel == _selectedUnits[0].UnitLevel);
            bool sameBoss = _selectedUnits.All(u => u.IsBoss == _selectedUnits[0].IsBoss);
            bool sameMode = _selectedUnits.All(u => u.LootMode == _selectedUnits[0].LootMode);
            bool sameTier = _selectedUnits.All(u => u.LootTierId == _selectedUnits[0].LootTierId);
            bool sameDropMin = _selectedUnits.All(u => u.DropCountMin == _selectedUnits[0].DropCountMin);
            bool sameDropMax = _selectedUnits.All(u => u.DropCountMax == _selectedUnits[0].DropCountMax);

            // Store original values (null = mixed)
            _origLevel = sameLevel ? _selectedUnits[0].UnitLevel : (int?)null;
            _origIsBoss = sameBoss ? _selectedUnits[0].IsBoss : (bool?)null;
            _origLootMode = sameMode ? (int)_selectedUnits[0].LootMode : (int?)null;
            _origDropMin = sameDropMin ? _selectedUnits[0].DropCountMin : (int?)null;
            _origDropMax = sameDropMax ? _selectedUnits[0].DropCountMax : (int?)null;

            // Set tier index
            if (sameTier)
            {
                if (_selectedUnits[0].LootTierId.HasValue)
                {
                    int tierIndex = _tiers.FindIndex(t => t.Id == _selectedUnits[0].LootTierId.Value);
                    _origTierIndex = tierIndex >= 0 ? tierIndex + 1 : 0;
                }
                else
                {
                    _origTierIndex = 0;
                }
            }
            else
            {
                _origTierIndex = null;
            }

            // Set controls - show values if same, otherwise show indicator
            numUnitLevel.Value = sameLevel ? _selectedUnits[0].UnitLevel : 1;
            chkIsBoss.CheckState = sameBoss 
                ? (_selectedUnits[0].IsBoss ? CheckState.Checked : CheckState.Unchecked)
                : CheckState.Indeterminate;
            cmbLootMode.SelectedIndex = sameMode ? (int)_selectedUnits[0].LootMode : -1;
            cmbLootTier.SelectedIndex = _origTierIndex ?? -1;
            numDropMin.Value = sameDropMin ? _selectedUnits[0].DropCountMin : 0;
            numDropMax.Value = sameDropMax ? _selectedUnits[0].DropCountMax : 1;
            txtNotes.Text = "";

            // Clear specific drops (doesn't make sense for multi-select)
            dgvSpecificDrops.Rows.Clear();

            UpdateUIState();
            _isLoadingUnit = false;
        }

        private void LoadUnitDetails(UnitType unit)
        {
            _isLoadingUnit = true;
            _currentUnit = unit;

            lblUnitName.Text = unit.DisplayName;
            lblUnitCode.Text = $"Code: '{unit.UnitCode}'";
            numUnitLevel.Value = unit.UnitLevel;
            chkIsBoss.Checked = unit.IsBoss;
            
            // Load unit icon
            LoadUnitIcon(unit.IconPath);

            cmbLootMode.SelectedIndex = (int)unit.LootMode;

            // Set tier dropdown
            if (unit.LootTierId.HasValue)
            {
                int tierIndex = _tiers.FindIndex(t => t.Id == unit.LootTierId.Value);
                cmbLootTier.SelectedIndex = tierIndex >= 0 ? tierIndex + 1 : 0;
            }
            else
            {
                cmbLootTier.SelectedIndex = 0;
            }

            // Set loot table dropdown
            if (unit.LootTableId.HasValue)
            {
                int tableIndex = _tables.FindIndex(t => t.Id == unit.LootTableId.Value);
                cmbLootTable.SelectedIndex = tableIndex >= 0 ? tableIndex + 1 : 0;
            }
            else
            {
                cmbLootTable.SelectedIndex = 0;
            }

            numDropMin.Value = unit.DropCountMin;
            numDropMax.Value = unit.DropCountMax;
            txtNotes.Text = unit.Notes ?? "";

            // Load specific drops
            LoadSpecificDrops(unit.UnitCode);

            UpdateUIState();
            _isLoadingUnit = false;
        }

        private void LoadSpecificDrops(string unitCode)
        {
            try
            {
                var drops = _dropRepo.GetByUnitCode(unitCode);

                dgvSpecificDrops.DataSource = null;
                dgvSpecificDrops.Columns.Clear();

                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Code", HeaderText = "Code", Width = 50 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Item", HeaderText = "Item Name", Width = 140 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Rarity", HeaderText = "Rarity", Width = 55 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Chance", HeaderText = "Chance", Width = 60 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Qty", HeaderText = "Qty", Width = 35 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Weight", HeaderText = "Weight", Width = 45 });
                dgvSpecificDrops.Columns.Add(new DataGridViewCheckBoxColumn { Name = "Guaranteed", HeaderText = "Guar", Width = 40 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Notes", HeaderText = "Notes", Width = 80 });

                foreach (var drop in drops)
                {
                    int rowIdx = dgvSpecificDrops.Rows.Add(
                        drop.ItemCode,
                        drop.ItemName,
                        drop.ItemRarity ?? "-",
                        drop.DropChanceDisplay,
                        drop.QuantityDisplay,
                        drop.Weight,
                        drop.IsGuaranteed,
                        drop.Notes ?? ""
                    );
                    dgvSpecificDrops.Rows[rowIdx].Tag = drop;
                    
                    // Color by rarity
                    var color = GetRarityColor(drop.ItemRarity);
                    if (color != Color.Empty)
                    {
                        dgvSpecificDrops.Rows[rowIdx].Cells["Item"].Style.ForeColor = color;
                        dgvSpecificDrops.Rows[rowIdx].Cells["Rarity"].Style.ForeColor = color;
                    }
                    
                    // Highlight guaranteed drops
                    if (drop.IsGuaranteed)
                    {
                        dgvSpecificDrops.Rows[rowIdx].Cells["Chance"].Style.ForeColor = Color.Lime;
                    }
                }
            }
            catch (Exception ex)
            {
                Logger.Instance.Error("Failed to load specific drops", ex);
            }
        }
        
        /// <summary>
        /// Load a small thumbnail icon for the unit grid
        /// </summary>
        private Image LoadUnitIconThumbnail(string iconPath)
        {
            if (string.IsNullOrEmpty(iconPath)) return null;
            
            try
            {
                string fullPath = IconPathConfig.Instance.ResolveIconPath(iconPath);
                if (string.IsNullOrEmpty(fullPath)) return null;
                
                // Prefer PNG over BLP
                string actualPath = fullPath;
                if (Path.GetExtension(fullPath).ToLower() == ".blp")
                {
                    string pngPath = Path.ChangeExtension(fullPath, ".png");
                    if (File.Exists(pngPath))
                        actualPath = pngPath;
                    else if (!File.Exists(fullPath))
                        return null;
                }
                
                if (!File.Exists(actualPath)) return null;
                
                string ext = Path.GetExtension(actualPath).ToLower();
                if (ext == ".png" || ext == ".jpg" || ext == ".jpeg")
                {
                    using (var img = Image.FromFile(actualPath))
                    {
                        // Create 28x28 thumbnail
                        return new Bitmap(img, new Size(28, 28));
                    }
                }
            }
            catch
            {
                // Silently fail for thumbnails
            }
            return null;
        }
        
        /// <summary>
        /// Load the icon for the currently selected unit (larger preview)
        /// </summary>
        private void LoadUnitIcon(string iconPath)
        {
            try
            {
                // Clear previous image
                if (picIcon.Image != null)
                {
                    var oldImage = picIcon.Image;
                    picIcon.Image = null;
                    oldImage.Dispose();
                }
                
                if (string.IsNullOrEmpty(iconPath))
                {
                    picIcon.Image = null;
                    picIcon.BackColor = Color.FromArgb(60, 60, 60);
                    return;
                }
                
                // Resolve icon path using configuration
                string fullPath = IconPathConfig.Instance.ResolveIconPath(iconPath);
                
                if (string.IsNullOrEmpty(fullPath))
                {
                    picIcon.Image = null;
                    picIcon.BackColor = Color.FromArgb(60, 60, 60);
                    return;
                }
                
                // Prefer PNG over BLP
                string actualPath = fullPath;
                if (Path.GetExtension(fullPath).ToLower() == ".blp")
                {
                    string pngPath = Path.ChangeExtension(fullPath, ".png");
                    if (File.Exists(pngPath))
                    {
                        actualPath = pngPath;
                    }
                    else if (!File.Exists(fullPath))
                    {
                        picIcon.Image = null;
                        picIcon.BackColor = Color.FromArgb(80, 60, 60);
                        return;
                    }
                }
                
                if (!File.Exists(actualPath))
                {
                    picIcon.Image = null;
                    picIcon.BackColor = Color.FromArgb(80, 60, 60);
                    return;
                }
                
                string ext = Path.GetExtension(actualPath).ToLower();
                
                if (ext == ".png" || ext == ".jpg" || ext == ".jpeg")
                {
                    picIcon.Image = Image.FromFile(actualPath);
                    picIcon.BackColor = Color.Black;
                }
                else if (ext == ".blp")
                {
                    // BLP without PNG conversion
                    picIcon.Image = null;
                    picIcon.BackColor = Color.FromArgb(60, 60, 90);
                }
                else
                {
                    picIcon.Image = null;
                    picIcon.BackColor = Color.FromArgb(60, 60, 60);
                }
            }
            catch (Exception ex)
            {
                picIcon.Image = null;
                picIcon.BackColor = Color.FromArgb(120, 40, 40);
                Logger.Instance.Error($"Error loading unit icon: {ex.Message}", ex);
            }
        }
        
        private Color GetRarityColor(string rarity)
        {
            return rarity?.ToLower() switch
            {
                "common" => Color.White,
                "uncommon" => Color.FromArgb(30, 255, 0),      // Green
                "rare" => Color.FromArgb(0, 170, 255),         // Blue
                "epic" => Color.FromArgb(163, 53, 238),        // Purple
                "legendary" => Color.FromArgb(255, 128, 0),    // Orange
                "unique" => Color.FromArgb(255, 215, 0),       // Gold
                "set" => Color.FromArgb(0, 255, 0),            // Bright green
                _ => Color.Empty
            };
        }

        private void UpdateUIState()
        {
            bool showSpecific = _currentUnit != null &&
                (_currentUnit.LootMode == LootMode.Specific || _currentUnit.LootMode == LootMode.Both);

            dgvSpecificDrops.Enabled = showSpecific;
            btnAddDrop.Enabled = showSpecific;
            btnEditDrop.Enabled = showSpecific && dgvSpecificDrops.SelectedRows.Count > 0;
            btnRemoveDrop.Enabled = showSpecific && dgvSpecificDrops.SelectedRows.Count > 0;

            bool showGeneric = _currentUnit != null &&
                (_currentUnit.LootMode == LootMode.Generic || _currentUnit.LootMode == LootMode.Both);
            cmbLootTier.Enabled = showGeneric;
            cmbLootTable.Enabled = showGeneric;
        }

        private void ChkIsBoss_CheckedChanged(object sender, EventArgs e)
        {
            // Skip suggestion when loading unit details
            if (_isLoadingUnit) return;
            
            // Suggest changing to Specific/Both mode when marking as boss
            if (chkIsBoss.Checked && cmbLootMode.SelectedIndex == 0)
            {
                var result = MessageBox.Show(
                    "Boss units typically have specific drops. Change loot mode to 'Both'?",
                    "Loot Mode",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question);

                if (result == DialogResult.Yes)
                {
                    cmbLootMode.SelectedIndex = 2; // Both
                }
            }
        }

        private void CmbLootMode_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (_currentUnit != null)
            {
                _currentUnit.LootMode = (LootMode)cmbLootMode.SelectedIndex;
                UpdateUIState();
            }
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            if (_isMultiSelect && _selectedUnits.Count > 1)
            {
                SaveMultipleUnits();
            }
            else if (_currentUnit != null)
            {
                SaveSingleUnit();
            }
        }

        private void SaveSingleUnit()
        {
            try
            {
                _currentUnit.UnitLevel = (int)numUnitLevel.Value;
                _currentUnit.IsBoss = chkIsBoss.Checked;
                _currentUnit.LootMode = (LootMode)cmbLootMode.SelectedIndex;
                _currentUnit.LootTierId = cmbLootTier.SelectedIndex > 0
                    ? _tiers[cmbLootTier.SelectedIndex - 1].Id
                    : (int?)null;
                _currentUnit.LootTableId = cmbLootTable.SelectedIndex > 0
                    ? _tables[cmbLootTable.SelectedIndex - 1].Id
                    : (int?)null;
                _currentUnit.DropCountMin = (int)numDropMin.Value;
                _currentUnit.DropCountMax = (int)numDropMax.Value;
                _currentUnit.Notes = txtNotes.Text;

                _unitRepo.Update(_currentUnit);
                Logger.Instance.Info($"Updated unit: {_currentUnit.UnitCode}");
                lblStatus.Text = $"Saved unit: {_currentUnit.DisplayName}";

                FilterUnits();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving unit: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error("Failed to save unit", ex);
            }
        }

        private void SaveMultipleUnits()
        {
            try
            {
                int count = 0;
                
                // Check for LootTable same-ness for multi-select
                bool sameTable = _selectedUnits.All(u => u.LootTableId == _selectedUnits[0].LootTableId);
                int? origTableIndex = null;
                if (sameTable)
                {
                    if (_selectedUnits[0].LootTableId.HasValue)
                    {
                        int tableIdx = _tables.FindIndex(t => t.Id == _selectedUnits[0].LootTableId.Value);
                        origTableIndex = tableIdx >= 0 ? tableIdx + 1 : 0;
                    }
                    else
                    {
                        origTableIndex = 0;
                    }
                }
                
                // Determine which fields to update (only those that changed from original mixed state)
                bool updateLevel = _origLevel.HasValue ? (int)numUnitLevel.Value != _origLevel.Value : true;
                bool updateBoss = _origIsBoss.HasValue ? chkIsBoss.Checked != _origIsBoss.Value : chkIsBoss.CheckState != CheckState.Indeterminate;
                bool updateMode = _origLootMode.HasValue ? cmbLootMode.SelectedIndex != _origLootMode.Value : cmbLootMode.SelectedIndex >= 0;
                bool updateTier = _origTierIndex.HasValue ? cmbLootTier.SelectedIndex != _origTierIndex.Value : cmbLootTier.SelectedIndex >= 0;
                bool updateTable = origTableIndex.HasValue ? cmbLootTable.SelectedIndex != origTableIndex.Value : cmbLootTable.SelectedIndex >= 0;
                bool updateDropMin = _origDropMin.HasValue ? (int)numDropMin.Value != _origDropMin.Value : true;
                bool updateDropMax = _origDropMax.HasValue ? (int)numDropMax.Value != _origDropMax.Value : true;

                foreach (var unit in _selectedUnits)
                {
                    if (updateLevel)
                        unit.UnitLevel = (int)numUnitLevel.Value;
                    if (updateBoss && chkIsBoss.CheckState != CheckState.Indeterminate)
                        unit.IsBoss = chkIsBoss.Checked;
                    if (updateMode && cmbLootMode.SelectedIndex >= 0)
                        unit.LootMode = (LootMode)cmbLootMode.SelectedIndex;
                    if (updateTier && cmbLootTier.SelectedIndex >= 0)
                        unit.LootTierId = cmbLootTier.SelectedIndex > 0
                            ? _tiers[cmbLootTier.SelectedIndex - 1].Id
                            : (int?)null;
                    if (updateTable && cmbLootTable.SelectedIndex >= 0)
                        unit.LootTableId = cmbLootTable.SelectedIndex > 0
                            ? _tables[cmbLootTable.SelectedIndex - 1].Id
                            : (int?)null;
                    if (updateDropMin)
                        unit.DropCountMin = (int)numDropMin.Value;
                    if (updateDropMax)
                        unit.DropCountMax = (int)numDropMax.Value;

                    _unitRepo.Update(unit);
                    count++;
                }

                Logger.Instance.Info($"Updated {count} units");
                lblStatus.Text = $"Saved {count} units";
                FilterUnits();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving units: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error("Failed to save multiple units", ex);
            }
        }

        private void BtnImport_Click(object sender, EventArgs e)
        {
            using (var ofd = new OpenFileDialog())
            {
                ofd.Filter = "WC3 Unit Data (*.w3u)|*.w3u|All Files (*.*)|*.*";
                ofd.Title = "Select Unit Object Data File";

                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    ImportUnitsFromW3U(ofd.FileName);
                }
            }
        }

        private void ImportUnitsFromW3U(string filePath)
        {
            var parser = new W3UParser();
            
            if (!parser.TryParse(filePath, out var units, out int expectedOriginal, out int expectedCustom, out string error))
            {
                MessageBox.Show(error, "Parse Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error($"Failed to parse .w3u file: {error}");
                return;
            }

            int expectedTotal = expectedOriginal + expectedCustom;
            string parseInfo = $"Expected: {expectedTotal} units ({expectedOriginal} modified, {expectedCustom} custom)\n" +
                               $"Parsed: {units.Count} units\n\n" +
                               $"Note: .w3u files only contain modified fields. Units with no changes from base are not included.";
            
            if (units.Count != expectedTotal)
            {
                Logger.Instance.Warn($"W3U parse count mismatch: expected {expectedTotal}, got {units.Count}");
            }

            if (units.Count == 0)
            {
                MessageBox.Show("No units found in the file.\n\n" + parseInfo, "Import", 
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            
            // Log parse info
            Logger.Instance.Info($"W3U Import: {parseInfo.Replace("\n", " | ")}");

            // Show import preview dialog
            using (var importDialog = new W3UImportDialog(units, _unitRepo, expectedOriginal, expectedCustom))
            {
                if (importDialog.ShowDialog(this) == DialogResult.OK)
                {
                    var selectedUnits = importDialog.SelectedUnits;
                    int imported = 0;
                    int updated = 0;
                    int skipped = 0;

                    foreach (var w3uUnit in selectedUnits)
                    {
                        try
                        {
                            // Check if unit already exists
                            var existing = _unitRepo.GetByCode(w3uUnit.UnitCode);
                            
                            if (existing != null)
                            {
                                if (importDialog.UpdateExisting)
                                {
                                    // Update existing unit
                                    existing.UnitName = w3uUnit.Name ?? existing.UnitName;
                                    existing.EditorSuffix = w3uUnit.EditorSuffix ?? existing.EditorSuffix;
                                    existing.IconPath = w3uUnit.IconPath ?? existing.IconPath;
                                    existing.UnitLevel = w3uUnit.Level > 0 ? w3uUnit.Level : existing.UnitLevel;
                                    existing.BaseId = w3uUnit.BaseId ?? existing.BaseId;
                                    
                                    _unitRepo.Update(existing);
                                    updated++;
                                }
                                else
                                {
                                    skipped++;
                                }
                            }
                            else
                            {
                                // Create new unit
                                var newUnit = new UnitType
                                {
                                    UnitCode = w3uUnit.UnitCode,
                                    BaseId = w3uUnit.BaseId,
                                    UnitName = w3uUnit.Name ?? w3uUnit.UnitCode,
                                    EditorSuffix = w3uUnit.EditorSuffix,
                                    IconPath = w3uUnit.IconPath,
                                    UnitLevel = w3uUnit.Level > 0 ? w3uUnit.Level : 1,
                                    LootMode = LootMode.Generic,
                                    DropCountMin = 1,
                                    DropCountMax = 1
                                };
                                
                                _unitRepo.Insert(newUnit);
                                imported++;
                            }
                        }
                        catch (Exception ex)
                        {
                            Logger.Instance.Error($"Failed to import unit {w3uUnit.UnitCode}", ex);
                            skipped++;
                        }
                    }

                    string message = $"Import complete:\n" +
                        $"- New units: {imported}\n" +
                        $"- Updated: {updated}\n" +
                        $"- Skipped: {skipped}";
                    
                    MessageBox.Show(message, "Import Results", 
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    
                    Logger.Instance.Info($"W3U Import: {imported} new, {updated} updated, {skipped} skipped from {Path.GetFileName(filePath)}");
                    
                    // Refresh the unit list
                    LoadUnits();
                }
            }
        }

        private void BtnAddDrop_Click(object sender, EventArgs e)
        {
            if (_currentUnit == null) return;

            using (var dialog = new ItemSelectorDialog(_connectionString, _currentUnit.UnitCode))
            {
                if (dialog.ShowDialog(this) == DialogResult.OK && dialog.Result != null)
                {
                    try
                    {
                        int id = _dropRepo.Insert(dialog.Result);
                        Logger.Instance.Info($"Added drop: {dialog.Result.ItemCode} to {_currentUnit.UnitCode}");
                        LoadSpecificDrops(_currentUnit.UnitCode);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error adding drop: {ex.Message}", "Error",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                        Logger.Instance.Error($"Failed to add drop: {ex.Message}", ex);
                    }
                }
            }
        }

        private void BtnRemoveDrop_Click(object sender, EventArgs e)
        {
            if (_currentUnit == null || dgvSpecificDrops.SelectedRows.Count == 0) return;

            var drop = dgvSpecificDrops.SelectedRows[0].Tag as UnitSpecificDrop;
            if (drop == null) return;

            var result = MessageBox.Show(
                $"Remove drop '{drop.ItemName}' from {_currentUnit.DisplayName}?",
                "Confirm Remove",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);

            if (result == DialogResult.Yes)
            {
                try
                {
                    _dropRepo.Delete(drop.Id);
                    Logger.Instance.Info($"Removed drop: {drop.ItemCode} from {_currentUnit.UnitCode}");
                    LoadSpecificDrops(_currentUnit.UnitCode);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error removing drop: {ex.Message}", "Error",
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void BtnEditDrop_Click(object sender, EventArgs e)
        {
            EditSelectedDrop();
        }

        private void DgvSpecificDrops_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0)
            {
                EditSelectedDrop();
            }
        }

        private void EditSelectedDrop()
        {
            if (_currentUnit == null || dgvSpecificDrops.SelectedRows.Count == 0) return;

            var drop = dgvSpecificDrops.SelectedRows[0].Tag as UnitSpecificDrop;
            if (drop == null) return;

            using (var dialog = new DropEditDialog(_connectionString, drop))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        _dropRepo.Update(dialog.Result);
                        Logger.Instance.Info($"Updated drop: {drop.ItemCode} for {_currentUnit.UnitCode}");
                        LoadSpecificDrops(_currentUnit.UnitCode);
                        lblStatus.Text = $"Drop updated: {drop.ItemName}";
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error updating drop: {ex.Message}", "Error",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void DgvSpecificDrops_SelectionChanged(object sender, EventArgs e)
        {
            UpdateUIState();
        }

        private void ApplyDarkTheme(Control parent)
        {
            foreach (Control c in parent.Controls)
            {
                if (c is TextBox || c is NumericUpDown || c is ComboBox)
                {
                    c.BackColor = Color.FromArgb(60, 60, 60);
                    c.ForeColor = Color.White;
                }
                else if (c is Button btn && btn.BackColor == SystemColors.Control)
                {
                    btn.BackColor = Color.FromArgb(70, 70, 70);
                    btn.ForeColor = Color.White;
                    btn.FlatStyle = FlatStyle.Flat;
                    btn.FlatAppearance.BorderColor = Color.FromArgb(100, 100, 100);
                }
                else if (c is Panel || c is FlowLayoutPanel)
                {
                    c.BackColor = Color.FromArgb(45, 45, 45);
                }

                if (c.HasChildren)
                {
                    ApplyDarkTheme(c);
                }
            }
        }
    }
}
