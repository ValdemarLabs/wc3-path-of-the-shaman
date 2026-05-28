using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;

namespace WC3ItemManager
{
    /// <summary>
    /// Form for managing loot tiers
    /// </summary>
    public class LootTierForm : Form
    {
        private readonly string _connectionString;
        private readonly LootTierRepository _repository;
        
        // Controls
        private DataGridView dgvTiers;
        private Panel pnlDetails;
        private TextBox txtTierName;
        private NumericUpDown numMinLevel;
        private NumericUpDown numMaxLevel;
        private NumericUpDown numDropChance;
        private TextBox txtDescription;
        private CheckBox chkEnabled;
        
        // Per-rarity controls
        private NumericUpDown[] numItemLevels = new NumericUpDown[6];
        private NumericUpDown[] numWeights = new NumericUpDown[6];
        private CheckBox[] chkAvailable = new CheckBox[6];
        private Label[] lblItemCounts = new Label[6];
        
        private Button btnAdd;
        private Button btnSave;
        private Button btnDelete;
        private Button btnRefresh;
        private Label lblStatus;
        
        private LootTier _currentTier;
        private bool _isNewTier;
        
        private readonly string[] RarityNames = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact" };
        private readonly Color[] RarityColors = {
            Color.Gray,           // Common
            Color.FromArgb(30, 255, 0),    // Uncommon (green)
            Color.FromArgb(0, 112, 221),   // Rare (blue)
            Color.FromArgb(163, 53, 238),  // Epic (purple)
            Color.FromArgb(255, 128, 0),   // Legendary (orange)
            Color.FromArgb(230, 204, 128)  // Artifact (gold)
        };

        public LootTierForm(string connectionString)
        {
            _connectionString = connectionString;
            _repository = new LootTierRepository(connectionString);
            
            InitializeComponent();
            LoadTiers();
        }

        private void InitializeComponent()
        {
            this.Text = "Loot Tier Management";
            this.Size = new Size(1200, 800);
            this.StartPosition = FormStartPosition.CenterParent;
            this.MinimumSize = new Size(1000, 700);

            // Main split container
            var splitContainer = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                SplitterDistance = 350
            };

            // Left panel - Tier list
            var pnlList = new Panel { Dock = DockStyle.Fill };
            
            var lblTitle = new Label
            {
                Text = "Loot Tiers",
                Font = new Font("Segoe UI", 12, FontStyle.Bold),
                Dock = DockStyle.Top,
                Height = 30,
                Padding = new Padding(5)
            };

            dgvTiers = new DataGridView
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
            dgvTiers.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
            dgvTiers.DefaultCellStyle.ForeColor = Color.White;
            dgvTiers.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvTiers.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvTiers.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvTiers.EnableHeadersVisualStyles = false;
            dgvTiers.SelectionChanged += DgvTiers_SelectionChanged;

            // Toolbar
            var pnlToolbar = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 40,
                FlowDirection = FlowDirection.LeftToRight,
                Padding = new Padding(5)
            };

            btnAdd = new Button { Text = "Add New", Width = 80 };
            btnAdd.Click += BtnAdd_Click;
            
            btnDelete = new Button { Text = "Delete", Width = 80 };
            btnDelete.Click += BtnDelete_Click;
            
            btnRefresh = new Button { Text = "Refresh", Width = 80 };
            btnRefresh.Click += (s, e) => LoadTiers();

            pnlToolbar.Controls.AddRange(new Control[] { btnAdd, btnDelete, btnRefresh });

            pnlList.Controls.Add(dgvTiers);
            pnlList.Controls.Add(pnlToolbar);
            pnlList.Controls.Add(lblTitle);

            // Right panel - Details
            pnlDetails = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(10)
            };
            
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

        private void CreateDetailsPanel()
        {
            int y = 10;
            int labelWidth = 120;
            int inputWidth = 200;

            // Title
            var lblDetailsTitle = new Label
            {
                Text = "Tier Configuration",
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                Location = new Point(10, y),
                AutoSize = true
            };
            pnlDetails.Controls.Add(lblDetailsTitle);
            y += 35;

            // Tier Name
            AddLabelAndControl("Tier Name:", ref y, labelWidth, 
                txtTierName = new TextBox { Width = inputWidth });

            // Level Range
            var pnlLevelRange = new FlowLayoutPanel
            {
                FlowDirection = FlowDirection.LeftToRight,
                AutoSize = true
            };
            numMinLevel = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 100 };
            numMaxLevel = new NumericUpDown { Width = 60, Minimum = 1, Maximum = 100 };
            pnlLevelRange.Controls.Add(numMinLevel);
            pnlLevelRange.Controls.Add(new Label { Text = " to ", AutoSize = true, Padding = new Padding(0, 3, 0, 0) });
            pnlLevelRange.Controls.Add(numMaxLevel);
            AddLabelAndControl("Unit Level Range:", ref y, labelWidth, pnlLevelRange);

            // Drop Chance
            numDropChance = new NumericUpDown
            {
                Width = 80,
                Minimum = 0,
                Maximum = 100,
                DecimalPlaces = 2,
                Increment = 0.5m
            };
            AddLabelAndControl("Base Drop Chance %:", ref y, labelWidth, numDropChance);

            // Description
            txtDescription = new TextBox { Width = inputWidth, Height = 50, Multiline = true };
            AddLabelAndControl("Description:", ref y, labelWidth, txtDescription);

            // Enabled
            chkEnabled = new CheckBox { Text = "Enabled", Checked = true };
            AddLabelAndControl("", ref y, labelWidth, chkEnabled);

            y += 20;

            // Rarity Configuration Header
            var lblRarityHeader = new Label
            {
                Text = "Per-Rarity Configuration",
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                Location = new Point(10, y),
                AutoSize = true
            };
            pnlDetails.Controls.Add(lblRarityHeader);
            y += 30;

            // Column headers
            var headerPanel = new Panel
            {
                Location = new Point(10, y),
                Size = new Size(550, 25)
            };
            headerPanel.Controls.Add(new Label { Text = "Rarity", Location = new Point(0, 0), Width = 90 });
            headerPanel.Controls.Add(new Label { Text = "Item Level", Location = new Point(100, 0), Width = 70 });
            headerPanel.Controls.Add(new Label { Text = "Weight", Location = new Point(180, 0), Width = 60 });
            headerPanel.Controls.Add(new Label { Text = "Available", Location = new Point(260, 0), Width = 70 });
            headerPanel.Controls.Add(new Label { Text = "Items in Pool", Location = new Point(340, 0), Width = 100 });
            pnlDetails.Controls.Add(headerPanel);
            y += 30;

            // Rarity rows
            for (int i = 0; i < 6; i++)
            {
                CreateRarityRow(i, ref y);
            }

            y += 20;

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
        }

        private void CreateRarityRow(int index, ref int y)
        {
            var panel = new Panel
            {
                Location = new Point(10, y),
                Size = new Size(550, 30)
            };

            // Rarity label
            var lblRarity = new Label
            {
                Text = RarityNames[index],
                ForeColor = RarityColors[index],
                Location = new Point(0, 5),
                Width = 90,
                Font = new Font("Segoe UI", 9, FontStyle.Bold)
            };
            panel.Controls.Add(lblRarity);

            // Item Level
            numItemLevels[index] = new NumericUpDown
            {
                Location = new Point(100, 2),
                Width = 60,
                Minimum = 0,
                Maximum = 100
            };
            panel.Controls.Add(numItemLevels[index]);

            // Weight
            numWeights[index] = new NumericUpDown
            {
                Location = new Point(180, 2),
                Width = 60,
                Minimum = 0,
                Maximum = 1000
            };
            panel.Controls.Add(numWeights[index]);

            // Available checkbox
            chkAvailable[index] = new CheckBox
            {
                Location = new Point(270, 5),
                AutoSize = true
            };
            chkAvailable[index].CheckedChanged += (s, e) =>
            {
                if (!chkAvailable[index].Checked)
                    numWeights[index].Value = 0;
                else if (numWeights[index].Value == 0)
                    numWeights[index].Value = GetDefaultWeight(index);
            };
            panel.Controls.Add(chkAvailable[index]);

            // Item count label
            lblItemCounts[index] = new Label
            {
                Location = new Point(340, 5),
                Width = 100,
                ForeColor = Color.LightGray,
                Text = "0 items"
            };
            panel.Controls.Add(lblItemCounts[index]);

            pnlDetails.Controls.Add(panel);
            y += 35;
        }

        private int GetDefaultWeight(int rarityIndex)
        {
            return rarityIndex switch
            {
                0 => 60,  // Common
                1 => 25,  // Uncommon
                2 => 12,  // Rare
                3 => 3,   // Epic
                4 => 1,   // Legendary
                5 => 0,   // Artifact
                _ => 10
            };
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

        private void LoadTiers()
        {
            try
            {
                var tiers = _repository.GetAll();
                
                dgvTiers.DataSource = null;
                dgvTiers.Columns.Clear();
                
                dgvTiers.Columns.Add(new DataGridViewTextBoxColumn { Name = "Id", HeaderText = "ID", Width = 40 });
                dgvTiers.Columns.Add(new DataGridViewTextBoxColumn { Name = "TierName", HeaderText = "Name", Width = 100 });
                dgvTiers.Columns.Add(new DataGridViewTextBoxColumn { Name = "LevelRange", HeaderText = "Levels", Width = 60 });
                dgvTiers.Columns.Add(new DataGridViewTextBoxColumn { Name = "DropChance", HeaderText = "Drop %", Width = 60 });
                dgvTiers.Columns.Add(new DataGridViewTextBoxColumn { Name = "Rarities", HeaderText = "Rarities", Width = 80 });
                dgvTiers.Columns.Add(new DataGridViewCheckBoxColumn { Name = "Enabled", HeaderText = "On", Width = 30 });

                foreach (var tier in tiers)
                {
                    dgvTiers.Rows.Add(
                        tier.Id,
                        tier.TierName,
                        tier.LevelRange,
                        $"{tier.DropChanceBase}%",
                        tier.AvailableRarities,
                        tier.Enabled
                    );
                    dgvTiers.Rows[dgvTiers.Rows.Count - 1].Tag = tier;
                }

                lblStatus.Text = $"Loaded {tiers.Count} tiers";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading tiers: {ex.Message}", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error("Failed to load loot tiers", ex);
            }
        }

        private void DgvTiers_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvTiers.SelectedRows.Count == 0) return;
            
            var tier = dgvTiers.SelectedRows[0].Tag as LootTier;
            if (tier != null)
            {
                LoadTierDetails(tier);
            }
        }

        private void LoadTierDetails(LootTier tier)
        {
            _currentTier = tier;
            _isNewTier = false;

            txtTierName.Text = tier.TierName;
            numMinLevel.Value = tier.MinUnitLevel;
            numMaxLevel.Value = tier.MaxUnitLevel;
            numDropChance.Value = tier.DropChanceBase;
            txtDescription.Text = tier.Description ?? "";
            chkEnabled.Checked = tier.Enabled;

            // Load per-rarity config
            LoadRarityValue(0, tier.CommonItemLevel, tier.CommonWeight);
            LoadRarityValue(1, tier.UncommonItemLevel, tier.UncommonWeight);
            LoadRarityValue(2, tier.RareItemLevel, tier.RareWeight);
            LoadRarityValue(3, tier.EpicItemLevel, tier.EpicWeight);
            LoadRarityValue(4, tier.LegendaryItemLevel, tier.LegendaryWeight);
            LoadRarityValue(5, tier.ArtifactItemLevel, tier.ArtifactWeight);

            // Update item counts
            UpdateItemCounts(tier);

            btnSave.Text = "Save Changes";
        }

        private void LoadRarityValue(int index, int? itemLevel, int weight)
        {
            numItemLevels[index].Value = itemLevel ?? 0;
            numWeights[index].Value = weight;
            chkAvailable[index].Checked = weight > 0;
        }

        private void UpdateItemCounts(LootTier tier)
        {
            try
            {
                var counts = _repository.GetItemCountsForTier(tier);
                for (int i = 0; i < 6; i++)
                {
                    string rarityName = RarityNames[i];
                    int count = counts.ContainsKey(rarityName) ? counts[rarityName] : 0;
                    lblItemCounts[i].Text = $"{count} items";
                    lblItemCounts[i].ForeColor = count > 0 ? Color.LightGreen : Color.Gray;
                }
            }
            catch
            {
                for (int i = 0; i < 6; i++)
                {
                    lblItemCounts[i].Text = "?";
                }
            }
        }

        private void BtnAdd_Click(object sender, EventArgs e)
        {
            _currentTier = new LootTier
            {
                TierName = "NEW_TIER",
                MinUnitLevel = 1,
                MaxUnitLevel = 5,
                DropChanceBase = 10.00m,
                Enabled = true,
                CommonWeight = 60,
                UncommonWeight = 25,
                RareWeight = 12,
                EpicWeight = 3
            };
            _isNewTier = true;

            txtTierName.Text = _currentTier.TierName;
            numMinLevel.Value = _currentTier.MinUnitLevel;
            numMaxLevel.Value = _currentTier.MaxUnitLevel;
            numDropChance.Value = _currentTier.DropChanceBase;
            txtDescription.Text = "";
            chkEnabled.Checked = true;

            // Reset rarity values
            for (int i = 0; i < 6; i++)
            {
                numItemLevels[i].Value = 0;
                numWeights[i].Value = GetDefaultWeight(i);
                chkAvailable[i].Checked = i < 4; // Common through Epic enabled by default
                lblItemCounts[i].Text = "0 items";
            }

            btnSave.Text = "Create Tier";
            dgvTiers.ClearSelection();
            lblStatus.Text = "Creating new tier...";
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            if (_currentTier == null) return;

            try
            {
                // Validate
                if (string.IsNullOrWhiteSpace(txtTierName.Text))
                {
                    MessageBox.Show("Tier name is required.", "Validation Error",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                if (numMinLevel.Value > numMaxLevel.Value)
                {
                    MessageBox.Show("Min level cannot be greater than max level.", "Validation Error",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                // Update tier object
                _currentTier.TierName = txtTierName.Text.Trim().ToUpper().Replace(" ", "_");
                _currentTier.MinUnitLevel = (int)numMinLevel.Value;
                _currentTier.MaxUnitLevel = (int)numMaxLevel.Value;
                _currentTier.DropChanceBase = numDropChance.Value;
                _currentTier.Description = txtDescription.Text;
                _currentTier.Enabled = chkEnabled.Checked;

                // Per-rarity values
                _currentTier.CommonItemLevel = numWeights[0].Value > 0 ? (int?)numItemLevels[0].Value : null;
                _currentTier.UncommonItemLevel = numWeights[1].Value > 0 ? (int?)numItemLevels[1].Value : null;
                _currentTier.RareItemLevel = numWeights[2].Value > 0 ? (int?)numItemLevels[2].Value : null;
                _currentTier.EpicItemLevel = numWeights[3].Value > 0 ? (int?)numItemLevels[3].Value : null;
                _currentTier.LegendaryItemLevel = numWeights[4].Value > 0 ? (int?)numItemLevels[4].Value : null;
                _currentTier.ArtifactItemLevel = numWeights[5].Value > 0 ? (int?)numItemLevels[5].Value : null;

                _currentTier.CommonWeight = (int)numWeights[0].Value;
                _currentTier.UncommonWeight = (int)numWeights[1].Value;
                _currentTier.RareWeight = (int)numWeights[2].Value;
                _currentTier.EpicWeight = (int)numWeights[3].Value;
                _currentTier.LegendaryWeight = (int)numWeights[4].Value;
                _currentTier.ArtifactWeight = (int)numWeights[5].Value;

                if (_isNewTier)
                {
                    _currentTier.Id = _repository.Insert(_currentTier);
                    Logger.Instance.Info($"Created loot tier: {_currentTier.TierName}");
                }
                else
                {
                    _repository.Update(_currentTier);
                    Logger.Instance.Info($"Updated loot tier: {_currentTier.TierName}");
                }

                LoadTiers();
                lblStatus.Text = $"Saved tier: {_currentTier.TierName}";
                
                // Select the saved tier
                foreach (DataGridViewRow row in dgvTiers.Rows)
                {
                    if ((row.Tag as LootTier)?.Id == _currentTier.Id)
                    {
                        row.Selected = true;
                        break;
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving tier: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                Logger.Instance.Error("Failed to save loot tier", ex);
            }
        }

        private void BtnDelete_Click(object sender, EventArgs e)
        {
            if (_currentTier == null || _isNewTier) return;

            var result = MessageBox.Show(
                $"Delete tier '{_currentTier.TierName}'?\n\nThis cannot be undone.",
                "Confirm Delete",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);

            if (result == DialogResult.Yes)
            {
                try
                {
                    _repository.Delete(_currentTier.Id);
                    Logger.Instance.Info($"Deleted loot tier: {_currentTier.TierName}");
                    _currentTier = null;
                    LoadTiers();
                    lblStatus.Text = "Tier deleted";
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error deleting tier: {ex.Message}", "Error",
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                    Logger.Instance.Error("Failed to delete loot tier", ex);
                }
            }
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
