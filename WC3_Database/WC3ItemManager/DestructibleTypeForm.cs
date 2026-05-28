using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using Npgsql;
using WC3ItemManager.Models;
using WC3ItemManager.Parsers;
using WC3ItemManager.Repositories;

namespace WC3ItemManager
{
    /// <summary>
    /// Form for managing destructible types and their loot configuration
    /// </summary>
    public class DestructibleTypeForm : Form
    {
        private readonly string _connectionString;
        private readonly DestructibleTypeRepository _destRepo;
        private readonly LootTierRepository _tierRepo;
        private readonly LootTableRepository _tableRepo;
        private readonly DestructibleSpecificDropRepository _dropRepo;
        
        // Controls - List panel
        private DataGridView dgvDestructibles;
        private TextBox txtSearch;
        private ComboBox cmbLootModeFilter;
        private ComboBox cmbCategoryFilter;
        private CheckBox chkContainerOnly;
        private NumericUpDown numMinLevel;
        private NumericUpDown numMaxLevel;
        
        // Controls - Details panel
        private Panel pnlDetails;
        private Label lblDestructibleName;
        private Label lblDestructibleCode;
        private PictureBox picIcon;
        private NumericUpDown numDestructibleLevel;
        private CheckBox chkIsContainer;
        private ComboBox cmbLootMode;
        private ComboBox cmbLootTier;
        private ComboBox cmbLootTable;
        private ComboBox cmbCategory;
        private NumericUpDown numDropMin;
        private NumericUpDown numDropMax;
        private TextBox txtNotes;
        private DataGridView dgvSpecificDrops;
        
        // Buttons
        private Button btnAdd;
        private Button btnSave;
        private Button btnRefresh;
        private Button btnDelete;
        private Button btnAddDrop;
        private Button btnEditDrop;
        private Button btnRemoveDrop;
        private Button btnAdoptTierLevel;
        private Label lblStatus;
        
        private DestructibleType _currentDestructible;
        private List<DestructibleType> _selectedDestructibles = new List<DestructibleType>();
        private List<LootTier> _tiers;
        private List<LootTable> _tables;
        private List<string> _categories;
        private bool _isLoadingDestructible;
        private bool _isMultiSelect;
        
        // Track original values for multi-select (to detect changes)
        private int? _origLevel;
        private bool? _origIsContainer;
        private int? _origLootMode;
        private int? _origTierIndex;
        private int? _origTableIndex;
        private int? _origDropMin;
        private int? _origDropMax;
        private string _origCategory;
        
        // Fixed icon for all destructibles
        private const string DESTRUCTIBLE_ICON = @"ReplaceableTextures\WorldEditUI\Doodad-Destructible.blp";
        
        public DestructibleTypeForm(string connectionString)
        {
            _connectionString = connectionString;
            _destRepo = new DestructibleTypeRepository(connectionString);
            _tierRepo = new LootTierRepository(connectionString);
            _tableRepo = new LootTableRepository(connectionString);
            _dropRepo = new DestructibleSpecificDropRepository(connectionString);
            
            InitializeComponent();
            LoadTiers();
            LoadLootTables();
            LoadCategories();
            LoadDestructibles();
        }

        private void InitializeComponent()
        {
            this.Text = "Destructible Type Management";
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

            // Left panel - Destructible list
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
                Width = 140
            };
            txtSearch.TextChanged += (s, e) => FilterDestructibles();

            // Loot mode filter
            var lblMode = new Label { Text = "Mode:", Location = new Point(210, 10), AutoSize = true };
            cmbLootModeFilter = new ComboBox
            {
                Location = new Point(250, 7),
                Width = 90,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbLootModeFilter.Items.AddRange(new object[] { "All", "Generic", "Specific", "Both", "None" });
            cmbLootModeFilter.SelectedIndex = 0;
            cmbLootModeFilter.SelectedIndexChanged += (s, e) => FilterDestructibles();

            // Container only
            chkContainerOnly = new CheckBox
            {
                Text = "Container Only",
                Location = new Point(350, 8),
                AutoSize = true
            };
            chkContainerOnly.CheckedChanged += (s, e) => FilterDestructibles();

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
            var lblTo = new Label { Text = "to", Location = new Point(102, 45), AutoSize = true };
            numMaxLevel = new NumericUpDown
            {
                Location = new Point(120, 42),
                Width = 50,
                Minimum = 0,
                Maximum = 100,
                Value = 99
            };
            numMinLevel.ValueChanged += (s, e) => FilterDestructibles();
            numMaxLevel.ValueChanged += (s, e) => FilterDestructibles();

            // Category filter
            var lblCat = new Label { Text = "Category:", Location = new Point(180, 45), AutoSize = true };
            cmbCategoryFilter = new ComboBox
            {
                Location = new Point(240, 42),
                Width = 100,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbCategoryFilter.SelectedIndexChanged += (s, e) => FilterDestructibles();

            // Import button
            btnAdd = new Button
            {
                Text = "Import...",
                Location = new Point(350, 40),
                Width = 80,
                Height = 25,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnAdd.Click += BtnImport_Click;

            // Refresh button
            btnRefresh = new Button
            {
                Text = "Refresh",
                Location = new Point(436, 40),
                Width = 65,
                Height = 25
            };
            btnRefresh.Click += (s, e) => LoadDestructibles();

            pnlFilters.Controls.AddRange(new Control[] {
                lblSearch, txtSearch, lblMode, cmbLootModeFilter, chkContainerOnly,
                lblLevel, numMinLevel, lblTo, numMaxLevel, lblCat, cmbCategoryFilter,
                btnAdd, btnRefresh
            });

            // Destructible grid
            dgvDestructibles = new DataGridView
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
            dgvDestructibles.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgvDestructibles.DefaultCellStyle.ForeColor = Color.White;
            dgvDestructibles.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvDestructibles.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvDestructibles.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvDestructibles.EnableHeadersVisualStyles = false;
            dgvDestructibles.SelectionChanged += DgvDestructibles_SelectionChanged;

            parent.Controls.Add(dgvDestructibles);
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

            // Destructible header
            picIcon = new PictureBox
            {
                Location = new Point(10, y),
                Size = new Size(64, 64),
                SizeMode = PictureBoxSizeMode.Zoom,
                BackColor = Color.FromArgb(60, 60, 60)
            };
            pnlDetails.Controls.Add(picIcon);

            lblDestructibleName = new Label
            {
                Location = new Point(85, y),
                Size = new Size(300, 25),
                Font = new Font("Segoe UI", 12, FontStyle.Bold),
                Text = "Select a destructible"
            };
            pnlDetails.Controls.Add(lblDestructibleName);

            lblDestructibleCode = new Label
            {
                Location = new Point(85, y + 25),
                Size = new Size(100, 20),
                ForeColor = Color.Gray,
                Text = ""
            };
            pnlDetails.Controls.Add(lblDestructibleCode);

            y += 80;

            // Destructible Level
            AddLabelAndControl("Level (WE bret):", ref y, 100,
                numDestructibleLevel = new NumericUpDown { Width = 60, Minimum = 0, Maximum = 100, Value = 1 });

            // Is Container
            chkIsContainer = new CheckBox { Text = "Is Container (Chest/Crate)", AutoSize = true, ThreeState = true };
            chkIsContainer.CheckedChanged += ChkIsContainer_CheckedChanged;
            AddLabelAndControl("", ref y, 100, chkIsContainer);

            // Category
            cmbCategory = new ComboBox
            {
                Width = 150,
                DropDownStyle = ComboBoxStyle.DropDown
            };
            AddLabelAndControl("Category:", ref y, 100, cmbCategory);

            // Loot Mode
            cmbLootMode = new ComboBox
            {
                Width = 120,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbLootMode.Items.AddRange(new object[] { "Generic", "Specific", "Both", "None" });
            cmbLootMode.SelectedIndexChanged += CmbLootMode_SelectedIndexChanged;
            AddLabelAndControl("Loot Mode:", ref y, 100, cmbLootMode);

            // Loot Tier (only for Generic/Both) with Adopt Level button
            var pnlTier = new FlowLayoutPanel
            {
                FlowDirection = FlowDirection.LeftToRight,
                AutoSize = true
            };
            cmbLootTier = new ComboBox
            {
                Width = 150,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbLootTier.SelectedIndexChanged += (s, e) => 
            {
                btnAdoptTierLevel.Enabled = cmbLootTier.Enabled && cmbLootTier.SelectedIndex > 0;
            };
            btnAdoptTierLevel = new Button
            {
                Text = "Adopt Tier Level",
                Width = 110,
                Height = 23,
                Margin = new Padding(5, 0, 0, 0),
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnAdoptTierLevel.FlatAppearance.BorderSize = 1;
            btnAdoptTierLevel.Click += BtnAdoptTierLevel_Click;
            pnlTier.Controls.Add(cmbLootTier);
            pnlTier.Controls.Add(btnAdoptTierLevel);
            AddLabelAndControl("Loot Tier:", ref y, 100, pnlTier);

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

            // Save/Delete buttons
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

            btnDelete = new Button
            {
                Text = "Delete",
                Location = new Point(140, y),
                Width = 80,
                Height = 30,
                BackColor = Color.FromArgb(180, 50, 50),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnDelete.FlatAppearance.BorderSize = 0;
            btnDelete.Click += BtnDelete_Click;
            pnlDetails.Controls.Add(btnDelete);

            y += 50;

            // Specific Drops section
            var lblSpecificDrops = new Label
            {
                Text = "Specific Drops (Container Loot)",
                Location = new Point(10, y),
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                AutoSize = true
            };
            pnlDetails.Controls.Add(lblSpecificDrops);
            y += 25;

            // Specific drops grid
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

        private void LoadCategories()
        {
            try
            {
                _categories = _destRepo.GetCategories();
                cmbCategoryFilter.Items.Clear();
                cmbCategoryFilter.Items.Add("All");
                cmbCategory.Items.Clear();
                
                foreach (var cat in _categories)
                {
                    cmbCategoryFilter.Items.Add(cat);
                    cmbCategory.Items.Add(cat);
                }
                cmbCategoryFilter.SelectedIndex = 0;
                
                // Add common categories if not present
                var commonCategories = new[] { "Tree", "Rock", "Chest", "Crate", "Barrel", "Debris", "Other" };
                foreach (var cat in commonCategories)
                {
                    if (!cmbCategory.Items.Contains(cat))
                        cmbCategory.Items.Add(cat);
                }
            }
            catch (Exception ex)
            {
                Logger.Instance.Error("Failed to load categories", ex);
            }
        }

        private void LoadDestructibles()
        {
            FilterDestructibles();
        }

        private void FilterDestructibles()
        {
            try
            {
                LootMode? modeFilter = null;
                if (cmbLootModeFilter.SelectedIndex > 0)
                {
                    modeFilter = (LootMode)(cmbLootModeFilter.SelectedIndex - 1);
                }

                string categoryFilter = cmbCategoryFilter.SelectedIndex > 0 
                    ? cmbCategoryFilter.SelectedItem.ToString() 
                    : null;

                var destructibles = _destRepo.GetFiltered(
                    isContainer: chkContainerOnly.Checked ? true : null,
                    lootMode: modeFilter,
                    minLevel: (int)numMinLevel.Value > 0 ? (int?)numMinLevel.Value : null,
                    maxLevel: (int)numMaxLevel.Value < 99 ? (int?)numMaxLevel.Value : null,
                    searchText: string.IsNullOrWhiteSpace(txtSearch.Text) ? null : txtSearch.Text,
                    category: categoryFilter
                );

                dgvDestructibles.DataSource = null;
                dgvDestructibles.Columns.Clear();

                dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn { Name = "Code", HeaderText = "Code", Width = 55 });
                dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn { Name = "BaseId", HeaderText = "Base", Width = 55 });
                dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn { Name = "Name", HeaderText = "Name", Width = 140 });
                dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn { Name = "EditorSuffix", HeaderText = "Editor Suffix", Width = 100 });
                dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn { Name = "Type", HeaderText = "Type", Width = 60 });
                dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn { Name = "Level", HeaderText = "Lvl", Width = 35 });
                dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn { Name = "Mode", HeaderText = "Mode", Width = 60 });
                dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn { Name = "Category", HeaderText = "Category", Width = 65 });
                dgvDestructibles.Columns.Add(new DataGridViewCheckBoxColumn { Name = "Container", HeaderText = "Cont", Width = 40 });
                dgvDestructibles.RowTemplate.Height = 24;

                foreach (var dest in destructibles)
                {
                    bool isCustom = !string.IsNullOrEmpty(dest.BaseId) && dest.BaseId != dest.DestructibleCode;
                    int rowIdx = dgvDestructibles.Rows.Add(
                        dest.DestructibleCode,
                        dest.BaseId ?? dest.DestructibleCode,
                        dest.DisplayName,
                        dest.EditorSuffix ?? "",
                        isCustom ? "Custom" : "Original",
                        dest.DestructibleLevel,
                        dest.LootMode.ToString(),
                        dest.Category ?? "-",
                        dest.IsContainer
                    );
                    dgvDestructibles.Rows[rowIdx].Tag = dest;

                    // Color code by loot mode
                    var row = dgvDestructibles.Rows[rowIdx];
                    switch (dest.LootMode)
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
                    bool hasLoot = dest.LootMode != LootMode.None && 
                                   (dest.LootTierId.HasValue || dest.LootTableId.HasValue);
                    if (dest.LootMode == LootMode.None)
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
                    
                    // Color code Type column
                    row.Cells["Type"].Style.ForeColor = isCustom ? Color.Cyan : Color.Gray;
                    
                    // Highlight containers
                    if (dest.IsContainer)
                    {
                        row.Cells["Container"].Style.ForeColor = Color.Lime;
                    }
                }

                lblStatus.Text = $"Showing {destructibles.Count} destructibles";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading destructibles: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error("Failed to load destructibles", ex);
            }
        }

        private void DgvDestructibles_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvDestructibles.SelectedRows.Count == 0) return;

            // Gather selected destructibles
            _selectedDestructibles.Clear();
            foreach (DataGridViewRow row in dgvDestructibles.SelectedRows)
            {
                if (row.Tag is DestructibleType dest)
                    _selectedDestructibles.Add(dest);
            }

            if (_selectedDestructibles.Count == 1)
            {
                _isMultiSelect = false;
                LoadDestructibleDetails(_selectedDestructibles[0]);
            }
            else if (_selectedDestructibles.Count > 1)
            {
                _isMultiSelect = true;
                LoadMultiDestructibleDetails();
            }
        }

        private void LoadMultiDestructibleDetails()
        {
            _isLoadingDestructible = true;
            _currentDestructible = _selectedDestructibles[0]; // Keep reference to first for some operations

            lblDestructibleName.Text = $"Multiple Selected ({_selectedDestructibles.Count})";
            lblDestructibleCode.Text = "Multiple destructibles";
            
            // Load common icon
            LoadDestructibleIcon();

            // Check if values are the same across all selected
            bool sameLevel = _selectedDestructibles.All(d => d.DestructibleLevel == _selectedDestructibles[0].DestructibleLevel);
            bool sameContainer = _selectedDestructibles.All(d => d.IsContainer == _selectedDestructibles[0].IsContainer);
            bool sameMode = _selectedDestructibles.All(d => d.LootMode == _selectedDestructibles[0].LootMode);
            bool sameTier = _selectedDestructibles.All(d => d.LootTierId == _selectedDestructibles[0].LootTierId);
            bool sameDropMin = _selectedDestructibles.All(d => d.DropCountMin == _selectedDestructibles[0].DropCountMin);
            bool sameDropMax = _selectedDestructibles.All(d => d.DropCountMax == _selectedDestructibles[0].DropCountMax);
            bool sameCategory = _selectedDestructibles.All(d => d.Category == _selectedDestructibles[0].Category);

            // Store original values (null = mixed)
            _origLevel = sameLevel ? _selectedDestructibles[0].DestructibleLevel : (int?)null;
            _origIsContainer = sameContainer ? _selectedDestructibles[0].IsContainer : (bool?)null;
            _origLootMode = sameMode ? (int)_selectedDestructibles[0].LootMode : (int?)null;
            _origDropMin = sameDropMin ? _selectedDestructibles[0].DropCountMin : (int?)null;
            _origDropMax = sameDropMax ? _selectedDestructibles[0].DropCountMax : (int?)null;
            _origCategory = sameCategory ? _selectedDestructibles[0].Category : null;

            // Set tier index
            if (sameTier)
            {
                if (_selectedDestructibles[0].LootTierId.HasValue)
                {
                    int tierIndex = _tiers.FindIndex(t => t.Id == _selectedDestructibles[0].LootTierId.Value);
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
            numDestructibleLevel.Value = sameLevel ? _selectedDestructibles[0].DestructibleLevel : 1;
            chkIsContainer.CheckState = sameContainer 
                ? (_selectedDestructibles[0].IsContainer ? CheckState.Checked : CheckState.Unchecked)
                : CheckState.Indeterminate;
            cmbLootMode.SelectedIndex = sameMode ? (int)_selectedDestructibles[0].LootMode : -1;
            cmbLootTier.SelectedIndex = _origTierIndex ?? -1;
            numDropMin.Value = sameDropMin ? _selectedDestructibles[0].DropCountMin : 0;
            numDropMax.Value = sameDropMax ? _selectedDestructibles[0].DropCountMax : 1;
            
            // Category handling
            if (sameCategory && !string.IsNullOrEmpty(_selectedDestructibles[0].Category))
            {
                int catIdx = cmbCategory.Items.IndexOf(_selectedDestructibles[0].Category);
                if (catIdx >= 0)
                    cmbCategory.SelectedIndex = catIdx;
                else
                    cmbCategory.Text = _selectedDestructibles[0].Category;
            }
            else
            {
                cmbCategory.SelectedIndex = -1;
                cmbCategory.Text = sameCategory ? "" : "(mixed)";
            }
            
            txtNotes.Text = "";

            // Clear specific drops (doesn't make sense for multi-select)
            dgvSpecificDrops.Rows.Clear();

            UpdateUIState();
            _isLoadingDestructible = false;
        }

        private void LoadDestructibleDetails(DestructibleType dest)
        {
            _isLoadingDestructible = true;
            _currentDestructible = dest;

            lblDestructibleName.Text = dest.DisplayName;
            lblDestructibleCode.Text = $"Code: '{dest.DestructibleCode}'";
            numDestructibleLevel.Value = dest.DestructibleLevel;
            chkIsContainer.Checked = dest.IsContainer;

            // Load fixed destructible icon
            LoadDestructibleIcon();

            // Set category
            if (!string.IsNullOrEmpty(dest.Category))
            {
                int catIdx = cmbCategory.Items.IndexOf(dest.Category);
                if (catIdx >= 0)
                    cmbCategory.SelectedIndex = catIdx;
                else
                    cmbCategory.Text = dest.Category;
            }
            else
            {
                cmbCategory.SelectedIndex = -1;
                cmbCategory.Text = "";
            }

            cmbLootMode.SelectedIndex = (int)dest.LootMode;

            // Set tier dropdown
            if (dest.LootTierId.HasValue)
            {
                int tierIndex = _tiers.FindIndex(t => t.Id == dest.LootTierId.Value);
                cmbLootTier.SelectedIndex = tierIndex >= 0 ? tierIndex + 1 : 0;
            }
            else
            {
                cmbLootTier.SelectedIndex = 0;
            }

            // Set loot table dropdown
            if (dest.LootTableId.HasValue)
            {
                int tableIndex = _tables.FindIndex(t => t.Id == dest.LootTableId.Value);
                cmbLootTable.SelectedIndex = tableIndex >= 0 ? tableIndex + 1 : 0;
            }
            else
            {
                cmbLootTable.SelectedIndex = 0;
            }

            numDropMin.Value = dest.DropCountMin;
            numDropMax.Value = dest.DropCountMax;
            txtNotes.Text = dest.Notes ?? "";

            // Load specific drops
            LoadSpecificDrops(dest.DestructibleCode);

            UpdateUIState();
            _isLoadingDestructible = false;
        }

        private void LoadDestructibleIcon()
        {
            try
            {
                string iconPath = DESTRUCTIBLE_ICON;
                string fullPath = IconPathConfig.Instance.ResolveIconPath(iconPath);
                
                if (string.IsNullOrEmpty(fullPath))
                {
                    picIcon.Image = null;
                    return;
                }
                
                // Prefer PNG over BLP
                string actualPath = fullPath;
                if (System.IO.Path.GetExtension(fullPath).ToLower() == ".blp")
                {
                    string pngPath = System.IO.Path.ChangeExtension(fullPath, ".png");
                    if (System.IO.File.Exists(pngPath))
                    {
                        actualPath = pngPath;
                    }
                }
                
                if (!System.IO.File.Exists(actualPath))
                {
                    picIcon.Image = null;
                    return;
                }
                
                // Load and scale to fit PictureBox
                using (var originalImage = Image.FromFile(actualPath))
                {
                    var thumbnail = new Bitmap(picIcon.Width, picIcon.Height);
                    using (var graphics = Graphics.FromImage(thumbnail))
                    {
                        graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                        graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
                        graphics.Clear(Color.Black);
                        graphics.DrawImage(originalImage, 0, 0, picIcon.Width, picIcon.Height);
                    }
                    picIcon.Image?.Dispose();
                    picIcon.Image = thumbnail;
                }
            }
            catch
            {
                picIcon.Image = null;
            }
        }

        private void LoadSpecificDrops(string destructibleCode)
        {
            try
            {
                var drops = _dropRepo.GetByDestructibleCode(destructibleCode);

                dgvSpecificDrops.DataSource = null;
                dgvSpecificDrops.Columns.Clear();

                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Code", HeaderText = "Code", Width = 50 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Item", HeaderText = "Item Code", Width = 100 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Chance", HeaderText = "Chance", Width = 60 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Qty", HeaderText = "Qty", Width = 50 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Weight", HeaderText = "Weight", Width = 45 });
                dgvSpecificDrops.Columns.Add(new DataGridViewCheckBoxColumn { Name = "Guaranteed", HeaderText = "Guar", Width = 40 });
                dgvSpecificDrops.Columns.Add(new DataGridViewTextBoxColumn { Name = "Notes", HeaderText = "Notes", Width = 80 });

                foreach (var drop in drops)
                {
                    int rowIdx = dgvSpecificDrops.Rows.Add(
                        drop.ItemCode,
                        drop.ItemCode,
                        drop.DropChanceDisplay,
                        drop.QuantityDisplay,
                        drop.Weight,
                        drop.IsGuaranteed,
                        drop.Notes ?? ""
                    );
                    dgvSpecificDrops.Rows[rowIdx].Tag = drop;
                    
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

        private void UpdateUIState()
        {
            bool showSpecific = _currentDestructible != null &&
                (_currentDestructible.LootMode == LootMode.Specific || _currentDestructible.LootMode == LootMode.Both);

            dgvSpecificDrops.Enabled = showSpecific;
            btnAddDrop.Enabled = showSpecific;
            btnEditDrop.Enabled = showSpecific && dgvSpecificDrops.SelectedRows.Count > 0;
            btnRemoveDrop.Enabled = showSpecific && dgvSpecificDrops.SelectedRows.Count > 0;

            bool showGeneric = _currentDestructible != null &&
                (_currentDestructible.LootMode == LootMode.Generic || _currentDestructible.LootMode == LootMode.Both);
            cmbLootTier.Enabled = showGeneric;
            cmbLootTable.Enabled = showGeneric;
            btnAdoptTierLevel.Enabled = showGeneric && cmbLootTier.SelectedIndex > 0;
        }

        private void ChkIsContainer_CheckedChanged(object sender, EventArgs e)
        {
            // Skip suggestion when loading destructible details
            if (_isLoadingDestructible) return;
            
            // Suggest changing to Specific/Both mode when marking as container
            if (chkIsContainer.Checked && cmbLootMode.SelectedIndex == 0)
            {
                var result = MessageBox.Show(
                    "Container destructibles typically have specific drops. Change loot mode to 'Specific'?",
                    "Loot Mode",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question);

                if (result == DialogResult.Yes)
                {
                    cmbLootMode.SelectedIndex = 1; // Specific
                }
            }
        }

        private void CmbLootMode_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (_currentDestructible != null)
            {
                _currentDestructible.LootMode = (LootMode)cmbLootMode.SelectedIndex;
                UpdateUIState();
            }
        }

        private void BtnAdoptTierLevel_Click(object sender, EventArgs e)
        {
            // Check if a tier is selected (index 0 is "(Auto by Level)")
            if (cmbLootTier.SelectedIndex <= 0)
            {
                MessageBox.Show("Please select a Loot Tier first.", "No Tier Selected",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            // Get the selected tier
            var selectedTier = _tiers[cmbLootTier.SelectedIndex - 1];
            
            // Calculate middle of the tier's level range
            int midLevel = (selectedTier.MinUnitLevel + selectedTier.MaxUnitLevel) / 2;
            
            // Set the destructible level
            numDestructibleLevel.Value = midLevel;
            
            lblStatus.Text = $"Level set to {midLevel} (from tier {selectedTier.TierName}: {selectedTier.LevelRange})";
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            if (_isMultiSelect && _selectedDestructibles.Count > 1)
            {
                SaveMultipleDestructibles();
            }
            else if (_currentDestructible != null)
            {
                SaveSingleDestructible();
            }
        }

        private void SaveSingleDestructible()
        {
            try
            {
                _currentDestructible.DestructibleLevel = (int)numDestructibleLevel.Value;
                _currentDestructible.IsContainer = chkIsContainer.Checked;
                _currentDestructible.Category = string.IsNullOrWhiteSpace(cmbCategory.Text) ? null : cmbCategory.Text;
                _currentDestructible.LootMode = (LootMode)cmbLootMode.SelectedIndex;
                _currentDestructible.LootTierId = cmbLootTier.SelectedIndex > 0
                    ? _tiers[cmbLootTier.SelectedIndex - 1].Id
                    : (int?)null;
                _currentDestructible.LootTableId = cmbLootTable.SelectedIndex > 0
                    ? _tables[cmbLootTable.SelectedIndex - 1].Id
                    : (int?)null;
                _currentDestructible.DropCountMin = (int)numDropMin.Value;
                _currentDestructible.DropCountMax = (int)numDropMax.Value;
                _currentDestructible.Notes = txtNotes.Text;

                _destRepo.Update(_currentDestructible);
                Logger.Instance.Info($"Updated destructible: {_currentDestructible.DestructibleCode}");
                lblStatus.Text = $"Saved destructible: {_currentDestructible.DisplayName}";

                // Refresh categories if a new one was added
                if (!string.IsNullOrEmpty(_currentDestructible.Category) && 
                    !_categories.Contains(_currentDestructible.Category))
                {
                    LoadCategories();
                }

                FilterDestructibles();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving destructible: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error("Failed to save destructible", ex);
            }
        }

        private void SaveMultipleDestructibles()
        {
            try
            {
                int count = 0;
                
                // Check for LootTable same-ness for multi-select
                bool sameTable = _selectedDestructibles.All(d => d.LootTableId == _selectedDestructibles[0].LootTableId);
                int? origTableIndex = null;
                if (sameTable)
                {
                    if (_selectedDestructibles[0].LootTableId.HasValue)
                    {
                        int tableIdx = _tables.FindIndex(t => t.Id == _selectedDestructibles[0].LootTableId.Value);
                        origTableIndex = tableIdx >= 0 ? tableIdx + 1 : 0;
                    }
                    else
                    {
                        origTableIndex = 0;
                    }
                }
                
                // Determine which fields to update (only those that changed from original mixed state)
                bool updateLevel = _origLevel.HasValue ? (int)numDestructibleLevel.Value != _origLevel.Value : true;
                bool updateContainer = _origIsContainer.HasValue ? chkIsContainer.Checked != _origIsContainer.Value : chkIsContainer.CheckState != CheckState.Indeterminate;
                bool updateMode = _origLootMode.HasValue ? cmbLootMode.SelectedIndex != _origLootMode.Value : cmbLootMode.SelectedIndex >= 0;
                bool updateTier = _origTierIndex.HasValue ? cmbLootTier.SelectedIndex != _origTierIndex.Value : cmbLootTier.SelectedIndex >= 0;
                bool updateTable = origTableIndex.HasValue ? cmbLootTable.SelectedIndex != origTableIndex.Value : cmbLootTable.SelectedIndex >= 0;
                bool updateDropMin = _origDropMin.HasValue ? (int)numDropMin.Value != _origDropMin.Value : true;
                bool updateDropMax = _origDropMax.HasValue ? (int)numDropMax.Value != _origDropMax.Value : true;
                bool updateCategory = _origCategory != null 
                    ? cmbCategory.Text != _origCategory 
                    : !string.IsNullOrEmpty(cmbCategory.Text) && cmbCategory.Text != "(mixed)";

                foreach (var dest in _selectedDestructibles)
                {
                    if (updateLevel)
                        dest.DestructibleLevel = (int)numDestructibleLevel.Value;
                    if (updateContainer && chkIsContainer.CheckState != CheckState.Indeterminate)
                        dest.IsContainer = chkIsContainer.Checked;
                    if (updateMode && cmbLootMode.SelectedIndex >= 0)
                        dest.LootMode = (LootMode)cmbLootMode.SelectedIndex;
                    if (updateTier && cmbLootTier.SelectedIndex >= 0)
                        dest.LootTierId = cmbLootTier.SelectedIndex > 0
                            ? _tiers[cmbLootTier.SelectedIndex - 1].Id
                            : (int?)null;
                    if (updateTable && cmbLootTable.SelectedIndex >= 0)
                        dest.LootTableId = cmbLootTable.SelectedIndex > 0
                            ? _tables[cmbLootTable.SelectedIndex - 1].Id
                            : (int?)null;
                    if (updateDropMin)
                        dest.DropCountMin = (int)numDropMin.Value;
                    if (updateDropMax)
                        dest.DropCountMax = (int)numDropMax.Value;
                    if (updateCategory)
                        dest.Category = string.IsNullOrWhiteSpace(cmbCategory.Text) || cmbCategory.Text == "(mixed)" 
                            ? null : cmbCategory.Text;

                    _destRepo.Update(dest);
                    count++;
                }

                // Refresh categories if needed
                string newCategory = string.IsNullOrWhiteSpace(cmbCategory.Text) || cmbCategory.Text == "(mixed)" 
                    ? null : cmbCategory.Text;
                if (!string.IsNullOrEmpty(newCategory) && !_categories.Contains(newCategory))
                {
                    LoadCategories();
                }

                Logger.Instance.Info($"Updated {count} destructibles");
                lblStatus.Text = $"Saved {count} destructibles";
                FilterDestructibles();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving destructibles: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error("Failed to save multiple destructibles", ex);
            }
        }

        private void BtnImport_Click(object sender, EventArgs e)
        {
            using (var ofd = new OpenFileDialog())
            {
                ofd.Filter = "WC3 Destructible Data (*.w3b)|*.w3b|All Files (*.*)|*.*";
                ofd.Title = "Select Destructible Object Data File";

                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    ImportDestructiblesFromW3B(ofd.FileName);
                }
            }
        }

        private void ImportDestructiblesFromW3B(string filePath)
        {
            var parser = new W3BParser();
            
            if (!parser.TryParse(filePath, out var destructibles, out int expectedOriginal, out int expectedCustom, out string error))
            {
                MessageBox.Show(error, "Parse Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error($"Failed to parse .w3b file: {error}");
                return;
            }

            int expectedTotal = expectedOriginal + expectedCustom;
            string parseInfo = $"Expected: {expectedTotal} destructibles ({expectedOriginal} modified, {expectedCustom} custom)\n" +
                               $"Parsed: {destructibles.Count} destructibles\n\n" +
                               $"Note: .w3b files only contain modified fields. Destructibles with no changes from base are not included.";
            
            if (destructibles.Count != expectedTotal)
            {
                Logger.Instance.Warn($"W3B parse count mismatch: expected {expectedTotal}, got {destructibles.Count}");
            }

            if (destructibles.Count == 0)
            {
                MessageBox.Show("No destructibles found in the file.\n\n" + parseInfo, "Import", 
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            
            Logger.Instance.Info($"W3B Import: {parseInfo.Replace("\n", " | ")}");

            // Show import preview dialog
            using (var importDialog = new W3BImportDialog(destructibles, _destRepo, expectedOriginal, expectedCustom))
            {
                if (importDialog.ShowDialog(this) == DialogResult.OK)
                {
                    var selectedDestructibles = importDialog.SelectedDestructibles;
                    int imported = 0;
                    int updated = 0;
                    int skipped = 0;

                    foreach (var w3bDest in selectedDestructibles)
                    {
                        try
                        {
                            var existing = _destRepo.GetByCode(w3bDest.DestructibleCode);
                            
                            if (existing != null)
                            {
                                if (importDialog.UpdateExisting)
                                {
                                    // Update existing destructible
                                    existing.DestructibleName = w3bDest.Name ?? existing.DestructibleName;
                                    existing.EditorSuffix = w3bDest.EditorSuffix ?? existing.EditorSuffix;
                                    existing.BaseId = w3bDest.BaseId ?? existing.BaseId;
                                    if (w3bDest.LootLevelFromWE.HasValue)
                                    {
                                        existing.DestructibleLevel = w3bDest.LootLevelFromWE.Value;
                                    }
                                    
                                    _destRepo.Update(existing);
                                    updated++;
                                }
                                else
                                {
                                    skipped++;
                                }
                            }
                            else
                            {
                                // Create new destructible
                                var newDest = new DestructibleType
                                {
                                    DestructibleCode = w3bDest.DestructibleCode,
                                    BaseId = w3bDest.BaseId,
                                    DestructibleName = w3bDest.Name ?? w3bDest.DestructibleCode,
                                    EditorSuffix = w3bDest.EditorSuffix,
                                    ModelPath = DESTRUCTIBLE_ICON,
                                    DestructibleLevel = w3bDest.LootLevelFromWE ?? 1,
                                    LootMode = LootMode.Generic,
                                    DropCountMin = 1,
                                    DropCountMax = 1,
                                    Enabled = true
                                };
                                
                                _destRepo.Insert(newDest);
                                imported++;
                            }
                        }
                        catch (Exception ex)
                        {
                            Logger.Instance.Error($"Failed to import destructible {w3bDest.DestructibleCode}", ex);
                            skipped++;
                        }
                    }

                    string message = $"Import complete:\n" +
                        $"- New destructibles: {imported}\n" +
                        $"- Updated: {updated}\n" +
                        $"- Skipped: {skipped}";
                    
                    MessageBox.Show(message, "Import Results", 
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    
                    Logger.Instance.Info($"W3B Import: {imported} new, {updated} updated, {skipped} skipped from {Path.GetFileName(filePath)}");
                    
                    // Refresh the list
                    LoadDestructibles();
                }
            }
        }

        private void BtnDelete_Click(object sender, EventArgs e)
        {
            if (_currentDestructible == null) return;

            var result = MessageBox.Show(
                $"Delete destructible '{_currentDestructible.DisplayName}'?\n\nThis will also delete all specific drops for this destructible.",
                "Confirm Delete",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);

            if (result == DialogResult.Yes)
            {
                try
                {
                    // Delete specific drops first
                    _dropRepo.DeleteByDestructibleCode(_currentDestructible.DestructibleCode);
                    
                    // Delete the destructible
                    _destRepo.Delete(_currentDestructible.DestructibleCode);
                    
                    Logger.Instance.Info($"Deleted destructible: {_currentDestructible.DestructibleCode}");
                    lblStatus.Text = $"Deleted destructible: {_currentDestructible.DisplayName}";
                    
                    _currentDestructible = null;
                    LoadDestructibles();
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error deleting destructible: {ex.Message}", "Error",
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                    Logger.Instance.Error("Failed to delete destructible", ex);
                }
            }
        }

        private void BtnAddDrop_Click(object sender, EventArgs e)
        {
            if (_currentDestructible == null) return;

            using (var dialog = new DestructibleDropDialog(_connectionString, _currentDestructible.DestructibleCode))
            {
                if (dialog.ShowDialog(this) == DialogResult.OK && dialog.Result != null)
                {
                    try
                    {
                        int id = _dropRepo.Insert(dialog.Result);
                        Logger.Instance.Info($"Added drop: {dialog.Result.ItemCode} to {_currentDestructible.DestructibleCode}");
                        LoadSpecificDrops(_currentDestructible.DestructibleCode);
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
            if (_currentDestructible == null || dgvSpecificDrops.SelectedRows.Count == 0) return;

            var drop = dgvSpecificDrops.SelectedRows[0].Tag as DestructibleSpecificDrop;
            if (drop == null) return;

            var result = MessageBox.Show(
                $"Remove drop '{drop.ItemCode}' from {_currentDestructible.DisplayName}?",
                "Confirm Remove",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);

            if (result == DialogResult.Yes)
            {
                try
                {
                    _dropRepo.Delete(drop.Id);
                    Logger.Instance.Info($"Removed drop: {drop.ItemCode} from {_currentDestructible.DestructibleCode}");
                    LoadSpecificDrops(_currentDestructible.DestructibleCode);
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
            if (_currentDestructible == null || dgvSpecificDrops.SelectedRows.Count == 0) return;

            var drop = dgvSpecificDrops.SelectedRows[0].Tag as DestructibleSpecificDrop;
            if (drop == null) return;

            using (var dialog = new DestructibleDropDialog(_connectionString, drop))
            {
                if (dialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        _dropRepo.Update(dialog.Result);
                        Logger.Instance.Info($"Updated drop: {drop.ItemCode} for {_currentDestructible.DestructibleCode}");
                        LoadSpecificDrops(_currentDestructible.DestructibleCode);
                        lblStatus.Text = $"Drop updated: {drop.ItemCode}";
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
    
    /// <summary>
    /// Dialog for adding/editing destructible-specific drops with searchable item list
    /// </summary>
    public class DestructibleDropDialog : Form
    {
        private readonly string _connectionString;
        private TextBox txtItemSearch;
        private ListBox lstItems;
        private List<ItemListEntry> _allItems = new List<ItemListEntry>();
        private NumericUpDown numDropChance;
        private NumericUpDown numMinQty;
        private NumericUpDown numMaxQty;
        private NumericUpDown numWeight;
        private CheckBox chkGuaranteed;
        private TextBox txtNotes;
        private Button btnOk;
        private Button btnCancel;
        private Label lblSelectedItem;
        
        private string _destructibleCode;
        private DestructibleSpecificDrop _existingDrop;
        
        public DestructibleSpecificDrop Result { get; private set; }
        
        // Helper class for item list
        private class ItemListEntry
        {
            public string ItemCode { get; set; }
            public string ItemName { get; set; }
            public string DisplayText => $"[{ItemCode}] {ItemName}";
            public override string ToString() => DisplayText;
        }
        
        public DestructibleDropDialog(string connectionString, string destructibleCode)
        {
            _connectionString = connectionString;
            _destructibleCode = destructibleCode;
            InitUI();
            LoadItems();
        }
        
        public DestructibleDropDialog(string connectionString, DestructibleSpecificDrop existingDrop)
        {
            _connectionString = connectionString;
            _destructibleCode = existingDrop.DestructibleCode;
            _existingDrop = existingDrop;
            InitUI();
            LoadItems();
            LoadExistingDrop();
        }
        
        private void InitUI()
        {
            this.Text = _existingDrop == null ? "Add Specific Drop" : "Edit Specific Drop";
            this.Size = new Size(500, 520);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(45, 45, 45);
            this.ForeColor = Color.White;
            
            int y = 15;
            int labelWidth = 110;
            int controlWidth = 340;
            
            // Search
            var lblSearch = new Label { Text = "Search Item:", Location = new Point(15, y + 3), AutoSize = true };
            txtItemSearch = new TextBox
            {
                Location = new Point(labelWidth + 15, y),
                Width = controlWidth,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            txtItemSearch.TextChanged += TxtItemSearch_TextChanged;
            y += 30;
            
            // Item list
            var lblItem = new Label { Text = "Select Item:", Location = new Point(15, y + 3), AutoSize = true };
            lstItems = new ListBox
            {
                Location = new Point(labelWidth + 15, y),
                Width = controlWidth,
                Height = 150,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle
            };
            lstItems.SelectedIndexChanged += LstItems_SelectedIndexChanged;
            y += 160;
            
            // Selected item display
            lblSelectedItem = new Label
            {
                Text = "No item selected",
                Location = new Point(labelWidth + 15, y),
                Width = controlWidth,
                ForeColor = Color.FromArgb(0, 150, 255)
            };
            y += 25;
            
            // Drop Chance
            var lblChance = new Label { Text = "Drop Chance %:", Location = new Point(15, y + 3), AutoSize = true };
            numDropChance = new NumericUpDown
            {
                Location = new Point(labelWidth + 15, y),
                Width = 80,
                Minimum = 0.01m,
                Maximum = 100,
                DecimalPlaces = 2,
                Value = 100,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            y += 35;
            
            // Quantity
            var lblQty = new Label { Text = "Quantity:", Location = new Point(15, y + 3), AutoSize = true };
            numMinQty = new NumericUpDown
            {
                Location = new Point(labelWidth + 15, y),
                Width = 60,
                Minimum = 1,
                Maximum = 99,
                Value = 1,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            var lblTo = new Label { Text = "to", Location = new Point(labelWidth + 80, y + 3), AutoSize = true };
            numMaxQty = new NumericUpDown
            {
                Location = new Point(labelWidth + 100, y),
                Width = 60,
                Minimum = 1,
                Maximum = 99,
                Value = 1,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            y += 35;
            
            // Weight
            var lblWeight = new Label { Text = "Weight:", Location = new Point(15, y + 3), AutoSize = true };
            numWeight = new NumericUpDown
            {
                Location = new Point(labelWidth + 15, y),
                Width = 70,
                Minimum = 1,
                Maximum = 1000,
                Value = 100,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            var lblWeightHelp = new Label
            {
                Text = "(relative weight for selection)",
                Location = new Point(labelWidth + 95, y + 3),
                AutoSize = true,
                ForeColor = Color.Gray
            };
            y += 35;
            
            // Guaranteed
            chkGuaranteed = new CheckBox
            {
                Text = "Guaranteed Drop",
                Location = new Point(labelWidth + 15, y),
                AutoSize = true,
                ForeColor = Color.Lime
            };
            chkGuaranteed.CheckedChanged += (s, e) =>
            {
                numDropChance.Enabled = !chkGuaranteed.Checked;
                if (chkGuaranteed.Checked) numDropChance.Value = 100;
            };
            y += 30;
            
            // Notes
            var lblNotes = new Label { Text = "Notes:", Location = new Point(15, y + 3), AutoSize = true };
            txtNotes = new TextBox
            {
                Location = new Point(labelWidth + 15, y),
                Width = controlWidth,
                Height = 40,
                Multiline = true,
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            y += 55;
            
            // Buttons
            btnOk = new Button
            {
                Text = _existingDrop == null ? "Add" : "Save",
                Location = new Point(260, y),
                Width = 90,
                Height = 30,
                DialogResult = DialogResult.OK,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOk.Click += BtnOk_Click;
            
            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(360, y),
                Width = 90,
                Height = 30,
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(70, 70, 70),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            
            this.Controls.AddRange(new Control[] {
                lblSearch, txtItemSearch,
                lblItem, lstItems, lblSelectedItem,
                lblChance, numDropChance,
                lblQty, numMinQty, lblTo, numMaxQty,
                lblWeight, numWeight, lblWeightHelp,
                chkGuaranteed,
                lblNotes, txtNotes, btnOk, btnCancel
            });
            
            this.AcceptButton = btnOk;
            this.CancelButton = btnCancel;
        }
        
        private void TxtItemSearch_TextChanged(object sender, EventArgs e)
        {
            FilterItems();
        }
        
        private void LstItems_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (lstItems.SelectedItem is ItemListEntry entry)
            {
                lblSelectedItem.Text = $"Selected: {entry.DisplayText}";
            }
            else
            {
                lblSelectedItem.Text = "No item selected";
            }
        }
        
        private void FilterItems()
        {
            string filter = txtItemSearch.Text.Trim().ToLower();
            lstItems.Items.Clear();
            
            var filtered = string.IsNullOrEmpty(filter)
                ? _allItems
                : _allItems.Where(i => i.DisplayText.ToLower().Contains(filter)).ToList();
            
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
                                
                                _allItems.Add(new ItemListEntry
                                {
                                    ItemCode = code,
                                    ItemName = name
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
        
        private void LoadExistingDrop()
        {
            if (_existingDrop == null) return;
            
            // Find and select the item in list
            for (int i = 0; i < lstItems.Items.Count; i++)
            {
                if (lstItems.Items[i] is ItemListEntry entry && entry.ItemCode == _existingDrop.ItemCode)
                {
                    lstItems.SelectedIndex = i;
                    break;
                }
            }
            
            // Disable item selection when editing
            lstItems.Enabled = false;
            txtItemSearch.Enabled = false;
            
            numDropChance.Value = _existingDrop.DropChance;
            numMinQty.Value = _existingDrop.MinQuantity;
            numMaxQty.Value = _existingDrop.MaxQuantity;
            numWeight.Value = _existingDrop.Weight;
            chkGuaranteed.Checked = _existingDrop.IsGuaranteed;
            txtNotes.Text = _existingDrop.Notes ?? "";
        }
        
        private void BtnOk_Click(object sender, EventArgs e)
        {
            if (lstItems.SelectedItem == null)
            {
                MessageBox.Show("Please select an item.", "Validation",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                this.DialogResult = DialogResult.None;
                return;
            }
            
            var selectedItem = (ItemListEntry)lstItems.SelectedItem;
            
            Result = new DestructibleSpecificDrop
            {
                Id = _existingDrop?.Id ?? 0,
                DestructibleCode = _destructibleCode,
                ItemCode = selectedItem.ItemCode,
                DropChance = numDropChance.Value,
                MinQuantity = (int)numMinQty.Value,
                MaxQuantity = (int)numMaxQty.Value,
                Weight = (int)numWeight.Value,
                IsGuaranteed = chkGuaranteed.Checked,
                Notes = string.IsNullOrWhiteSpace(txtNotes.Text) ? null : txtNotes.Text.Trim(),
                Enabled = true
            };
        }
    }
}
