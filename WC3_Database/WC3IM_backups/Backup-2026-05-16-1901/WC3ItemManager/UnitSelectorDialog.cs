using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Models;

namespace WC3ItemManager
{
    /// <summary>
    /// Dialog for selecting a unit from available units
    /// </summary>
    public class UnitSelectorDialog : Form
    {
        private TextBox txtSearch;
        private ListBox lstUnits;
        private Button btnOK;
        private Button btnCancel;
        private Label lblInfo;
        
        private List<UnitType> _allUnits;
        private List<UnitType> _filteredUnits;
        
        public UnitType SelectedUnit { get; private set; }
        
        public UnitSelectorDialog(List<UnitType> availableUnits)
        {
            _allUnits = availableUnits;
            _filteredUnits = availableUnits;
            InitializeComponent();
            PopulateList();
        }
        
        private void InitializeComponent()
        {
            this.Text = "Select Unit";
            this.Size = new Size(450, 500);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.ForeColor = Color.White;
            
            int y = 15;
            
            var lblTitle = new Label
            {
                Text = "Select a unit to add as drop source:",
                Location = new Point(15, y),
                AutoSize = true,
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };
            this.Controls.Add(lblTitle);
            y += 30;
            
            var lblSearch = new Label
            {
                Text = "Search:",
                Location = new Point(15, y + 2),
                AutoSize = true
            };
            this.Controls.Add(lblSearch);
            
            txtSearch = new TextBox
            {
                Location = new Point(70, y),
                Size = new Size(345, 23),
                BackColor = Color.FromArgb(60, 60, 60),
                ForeColor = Color.White
            };
            txtSearch.TextChanged += TxtSearch_TextChanged;
            this.Controls.Add(txtSearch);
            y += 35;
            
            lblInfo = new Label
            {
                Text = $"{_allUnits.Count} units available",
                Location = new Point(15, y),
                AutoSize = true,
                ForeColor = Color.LightGray
            };
            this.Controls.Add(lblInfo);
            y += 25;
            
            lstUnits = new ListBox
            {
                Location = new Point(15, y),
                Size = new Size(400, 320),
                BackColor = Color.FromArgb(30, 30, 30),
                ForeColor = Color.White,
                Font = new Font("Consolas", 9),
                DrawMode = DrawMode.OwnerDrawFixed,
                ItemHeight = 22
            };
            lstUnits.DrawItem += LstUnits_DrawItem;
            lstUnits.DoubleClick += (s, e) => SelectAndClose();
            this.Controls.Add(lstUnits);
            y += 330;
            
            btnOK = new Button
            {
                Text = "Select",
                Location = new Point(230, y),
                Size = new Size(90, 30),
                DialogResult = DialogResult.OK,
                BackColor = Color.FromArgb(50, 120, 50),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnOK.Click += (s, e) => SelectAndClose();
            this.Controls.Add(btnOK);
            
            btnCancel = new Button
            {
                Text = "Cancel",
                Location = new Point(325, y),
                Size = new Size(90, 30),
                DialogResult = DialogResult.Cancel,
                BackColor = Color.FromArgb(70, 70, 70),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            this.Controls.Add(btnCancel);
            
            this.AcceptButton = btnOK;
            this.CancelButton = btnCancel;
        }
        
        private void PopulateList()
        {
            lstUnits.Items.Clear();
            foreach (var unit in _filteredUnits)
            {
                lstUnits.Items.Add(unit);
            }
            
            lblInfo.Text = $"{_filteredUnits.Count} of {_allUnits.Count} units";
            
            if (lstUnits.Items.Count > 0)
                lstUnits.SelectedIndex = 0;
        }
        
        private void TxtSearch_TextChanged(object sender, EventArgs e)
        {
            string search = txtSearch.Text.Trim().ToLower();
            
            if (string.IsNullOrEmpty(search))
            {
                _filteredUnits = _allUnits;
            }
            else
            {
                _filteredUnits = _allUnits
                    .Where(u => u.DisplayName.ToLower().Contains(search) || 
                                u.UnitCode.ToLower().Contains(search))
                    .ToList();
            }
            
            PopulateList();
        }
        
        private void LstUnits_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index < 0) return;
            
            e.DrawBackground();
            
            var unit = lstUnits.Items[e.Index] as UnitType;
            if (unit == null) return;
            
            // Determine colors
            Color textColor = e.ForeColor;
            Color codeColor = Color.FromArgb(150, 150, 150);
            Color bossColor = Color.FromArgb(255, 180, 100);
            
            if ((e.State & DrawItemState.Selected) == DrawItemState.Selected)
            {
                textColor = Color.White;
                codeColor = Color.White;
                bossColor = Color.Yellow;
            }
            
            using (var brush = new SolidBrush(textColor))
            using (var codeBrush = new SolidBrush(codeColor))
            using (var bossBrush = new SolidBrush(bossColor))
            {
                string displayText = unit.DisplayName;
                string codeText = $"[{unit.UnitCode}]";
                string levelText = $"Lv{unit.UnitLevel}";
                
                // Draw unit name
                e.Graphics.DrawString(displayText, e.Font, brush, e.Bounds.X + 5, e.Bounds.Y + 2);
                
                // Draw level
                var nameSize = e.Graphics.MeasureString(displayText, e.Font);
                e.Graphics.DrawString(levelText, e.Font, codeBrush, e.Bounds.X + nameSize.Width + 10, e.Bounds.Y + 2);
                
                // Draw boss indicator
                if (unit.IsBoss)
                {
                    var levelSize = e.Graphics.MeasureString(levelText, e.Font);
                    e.Graphics.DrawString("⭐BOSS", e.Font, bossBrush, 
                        e.Bounds.X + nameSize.Width + levelSize.Width + 20, e.Bounds.Y + 2);
                }
                
                // Draw code on the right
                var codeSize = e.Graphics.MeasureString(codeText, e.Font);
                e.Graphics.DrawString(codeText, e.Font, codeBrush, 
                    e.Bounds.Right - codeSize.Width - 5, e.Bounds.Y + 2);
            }
            
            e.DrawFocusRectangle();
        }
        
        private void SelectAndClose()
        {
            if (lstUnits.SelectedItem is UnitType unit)
            {
                SelectedUnit = unit;
                this.DialogResult = DialogResult.OK;
                this.Close();
            }
        }
    }
}
