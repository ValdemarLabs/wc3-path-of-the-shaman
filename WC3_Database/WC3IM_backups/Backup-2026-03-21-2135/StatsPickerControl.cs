using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace WC3ItemManager
{
    /// <summary>
    /// Control for selecting item stats and their values
    /// </summary>
    public class StatsPickerControl : UserControl
    {
        private DataGridView dgvStats;
        private Button btnAdd;
        private Button btnRemove;
        private Button btnMoveUp;
        private Button btnMoveDown;
        private ComboBox cboAvailableStats;
        private Label lblInfo;
        
        private List<ItemStat> availableStats;
        private List<ItemStatValue> currentStats;
        private ColorManager colorManager;
        
        // Event fired when stats are added, removed, reordered, or values changed
        public event EventHandler StatsChanged;

        public StatsPickerControl()
        {
            availableStats = new List<ItemStat>();
            currentStats = new List<ItemStatValue>();
            InitializeComponent();
        }

        public void Initialize(ColorManager colorManager, List<ItemStat> stats)
        {
            this.colorManager = colorManager;
            this.availableStats = stats;
            PopulateAvailableStats();
        }

        private void InitializeComponent()
        {
            this.Size = new Size(500, 400);
            
            // Label
            lblInfo = new Label
            {
                Text = "Item Stats & Bonuses:",
                Location = new Point(10, 10),
                Size = new Size(480, 20),
                Font = new Font(FontFamily.GenericSansSerif, 10, FontStyle.Bold)
            };
            
            // ComboBox for available stats
            cboAvailableStats = new ComboBox
            {
                Location = new Point(10, 35),
                Size = new Size(250, 25),
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            
            // Add button
            btnAdd = new Button
            {
                Text = "Add Stat",
                Location = new Point(270, 35),
                Size = new Size(80, 25)
            };
            btnAdd.Click += BtnAdd_Click;
            
            // Remove button
            btnRemove = new Button
            {
                Text = "Remove",
                Location = new Point(360, 35),
                Size = new Size(80, 25)
            };
            btnRemove.Click += BtnRemove_Click;
            
            // Move Up button
            btnMoveUp = new Button
            {
                Text = "↑ Up",
                Location = new Point(450, 35),
                Size = new Size(50, 25)
            };
            btnMoveUp.Click += BtnMoveUp_Click;
            
            // Move Down button
            btnMoveDown = new Button
            {
                Text = "↓ Down",
                Location = new Point(450, 65),
                Size = new Size(50, 25)
            };
            btnMoveDown.Click += BtnMoveDown_Click;
            
            // DataGridView for selected stats
            dgvStats = new DataGridView
            {
                Location = new Point(10, 70),
                Size = new Size(480, 320),
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                BackgroundColor = Color.White,
                BorderStyle = BorderStyle.Fixed3D
            };
            
            // Setup columns
            dgvStats.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "StatName",
                HeaderText = "Stat",
                ReadOnly = true,
                Width = 150
            });
            
            dgvStats.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "StatValue",
                HeaderText = "Value",
                ReadOnly = false,
                Width = 100
            });
            
            dgvStats.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Preview",
                HeaderText = "Preview",
                ReadOnly = true,
                Width = 200
            });
            
            dgvStats.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "StatId",
                HeaderText = "StatId",
                Visible = false
            });
            
            dgvStats.CellEndEdit += DgvStats_CellEndEdit;
            
            // Add controls
            this.Controls.Add(lblInfo);
            this.Controls.Add(cboAvailableStats);
            this.Controls.Add(btnAdd);
            this.Controls.Add(btnRemove);
            this.Controls.Add(btnMoveUp);
            this.Controls.Add(btnMoveDown);
            this.Controls.Add(dgvStats);
        }

        private void PopulateAvailableStats()
        {
            cboAvailableStats.Items.Clear();
            foreach (var stat in availableStats.OrderBy(s => s.DisplayOrder))
            {
                cboAvailableStats.Items.Add($"{stat.Name} - {stat.Description}");
            }
            
            if (cboAvailableStats.Items.Count > 0)
                cboAvailableStats.SelectedIndex = 0;
        }

        private void BtnAdd_Click(object sender, EventArgs e)
        {
            if (cboAvailableStats.SelectedIndex < 0) return;
            
            var selectedStat = availableStats[cboAvailableStats.SelectedIndex];
            
            // Check if already added
            if (currentStats.Any(s => s.StatId == selectedStat.Id))
            {
                MessageBox.Show("This stat has already been added.", "Duplicate Stat", 
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            
            // Add stat with default value of 1
            var statValue = new ItemStatValue
            {
                StatId = selectedStat.Id,
                Value = 1,
                Stat = selectedStat
            };
            
            currentStats.Add(statValue);
            
            // Add to grid
            int rowIndex = dgvStats.Rows.Add();
            UpdateGridRow(rowIndex, statValue);
            
            // Notify stats changed
            StatsChanged?.Invoke(this, EventArgs.Empty);
        }

        private void BtnRemove_Click(object sender, EventArgs e)
        {
            if (dgvStats.SelectedRows.Count == 0) return;
            
            int rowIndex = dgvStats.SelectedRows[0].Index;
            int statId = Convert.ToInt32(dgvStats.Rows[rowIndex].Cells["StatId"].Value);
            
            currentStats.RemoveAll(s => s.StatId == statId);
            dgvStats.Rows.RemoveAt(rowIndex);
            
            // Notify stats changed
            StatsChanged?.Invoke(this, EventArgs.Empty);
        }

        private void BtnMoveUp_Click(object sender, EventArgs e)
        {
            if (dgvStats.SelectedRows.Count == 0) return;
            
            int rowIndex = dgvStats.SelectedRows[0].Index;
            if (rowIndex == 0) return; // Already at top
            
            // Swap in currentStats list
            var temp = currentStats[rowIndex];
            currentStats[rowIndex] = currentStats[rowIndex - 1];
            currentStats[rowIndex - 1] = temp;
            
            // Refresh grid
            RefreshGrid();
            
            // Keep selection on the moved row
            dgvStats.Rows[rowIndex - 1].Selected = true;
            
            // Notify stats changed
            StatsChanged?.Invoke(this, EventArgs.Empty);
        }

        private void BtnMoveDown_Click(object sender, EventArgs e)
        {
            if (dgvStats.SelectedRows.Count == 0) return;
            
            int rowIndex = dgvStats.SelectedRows[0].Index;
            if (rowIndex >= currentStats.Count - 1) return; // Already at bottom
            
            // Swap in currentStats list
            var temp = currentStats[rowIndex];
            currentStats[rowIndex] = currentStats[rowIndex + 1];
            currentStats[rowIndex + 1] = temp;
            
            // Refresh grid
            RefreshGrid();
            
            // Keep selection on the moved row
            dgvStats.Rows[rowIndex + 1].Selected = true;
            
            // Notify stats changed
            StatsChanged?.Invoke(this, EventArgs.Empty);
        }

        private void DgvStats_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            if (e.ColumnIndex != 1) return; // Only handle Value column
            
            try
            {
                int statId = Convert.ToInt32(dgvStats.Rows[e.RowIndex].Cells["StatId"].Value);
                string valueStr = dgvStats.Rows[e.RowIndex].Cells["StatValue"].Value?.ToString();
                
                if (decimal.TryParse(valueStr, out decimal value))
                {
                    var stat = currentStats.FirstOrDefault(s => s.StatId == statId);
                    if (stat != null)
                    {
                        stat.Value = value;
                        UpdateGridRow(e.RowIndex, stat);
                        
                        // Notify stats changed
                        StatsChanged?.Invoke(this, EventArgs.Empty);
                    }
                }
                else
                {
                    MessageBox.Show("Please enter a valid number.", "Invalid Value", 
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    // Reset to previous value
                    var stat = currentStats.FirstOrDefault(s => s.StatId == statId);
                    if (stat != null)
                    {
                        dgvStats.Rows[e.RowIndex].Cells["StatValue"].Value = stat.Value;
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error updating stat value: {ex.Message}", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void UpdateGridRow(int rowIndex, ItemStatValue statValue)
        {
            dgvStats.Rows[rowIndex].Cells["StatName"].Value = statValue.Stat.Name;
            dgvStats.Rows[rowIndex].Cells["StatValue"].Value = statValue.Value;
            dgvStats.Rows[rowIndex].Cells["Preview"].Value = statValue.GetFormattedText();
            dgvStats.Rows[rowIndex].Cells["StatId"].Value = statValue.StatId;
            
            // Apply color if available
            if (colorManager != null && !string.IsNullOrEmpty(statValue.Stat.ColorHex))
            {
                try
                {
                    Color color = ColorManager.ColorFromHex(statValue.Stat.ColorHex, Color.Black);
                    dgvStats.Rows[rowIndex].DefaultCellStyle.ForeColor = color;
                }
                catch { }
            }
        }

        private void RefreshGrid()
        {
            dgvStats.Rows.Clear();
            foreach (var stat in currentStats)
            {
                int rowIndex = dgvStats.Rows.Add();
                UpdateGridRow(rowIndex, stat);
            }
        }

        public List<ItemStatValue> GetStatValues()
        {
            return new List<ItemStatValue>(currentStats);
        }

        public void SetStatValues(List<ItemStatValue> stats)
        {
            currentStats.Clear();
            dgvStats.Rows.Clear();
            
            if (stats != null)
            {
                // Don't sort - preserve order from database (sort_order)
                foreach (var stat in stats)
                {
                    currentStats.Add(stat);
                    int rowIndex = dgvStats.Rows.Add();
                    UpdateGridRow(rowIndex, stat);
                }
            }
            
            // Fire StatsChanged event so auto-generation happens after loading item
            StatsChanged?.Invoke(this, EventArgs.Empty);
        }

        public void Clear()
        {
            currentStats.Clear();
            dgvStats.Rows.Clear();
        }

        public int StatCount => currentStats.Count;

        public decimal GetTotalStatValue(string statCode)
        {
            return currentStats
                .Where(s => s.Stat.Code == statCode)
                .Sum(s => s.Value);
        }
    }
}
