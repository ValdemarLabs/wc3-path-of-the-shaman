using System;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;

namespace WC3ItemManager.Dialogs
{
    public class GatherUnitNodeDropDialog : Form
    {
        private readonly GatherNodeRepository _repository;
        private readonly GatherUnitNodeDrop _originalDrop;

        private TextBox txtSearch;
        private DataGridView dgvItems;
        private Label lblSelected;
        private ComboBox cmbGroupName;
        private NumericUpDown numChance;
        private NumericUpDown numWeight;
        private NumericUpDown numMinQty;
        private NumericUpDown numMaxQty;
        private CheckBox chkEnabled;
        private TextBox txtNotes;

        private DatabaseItemInfo _selectedItem;

        public GatherUnitNodeDrop Result { get; private set; }

        public GatherUnitNodeDropDialog(string connectionString, GatherUnitNodeDrop drop = null)
        {
            _repository = new GatherNodeRepository(connectionString);
            _originalDrop = drop;

            InitializeComponent();
            LoadItems();
            if (_originalDrop != null)
            {
                LoadDrop();
            }
            ApplyDarkTheme(this);
        }

        private void InitializeComponent()
        {
            Text = _originalDrop == null ? "Add Harvest Reward" : "Edit Harvest Reward";
            Size = new Size(760, 620);
            StartPosition = FormStartPosition.CenterParent;
            MinimumSize = new Size(640, 520);

            var pnlTop = new Panel
            {
                Dock = DockStyle.Top,
                Height = 44,
                Padding = new Padding(10, 8, 10, 8)
            };
            pnlTop.Controls.Add(new Label { Text = "Search:", Location = new Point(8, 11), AutoSize = true });
            txtSearch = new TextBox { Location = new Point(62, 8), Width = 250 };
            txtSearch.TextChanged += (s, e) => LoadItems(txtSearch.Text);
            lblSelected = new Label { Location = new Point(330, 11), AutoSize = true, Text = "No item selected" };
            pnlTop.Controls.Add(txtSearch);
            pnlTop.Controls.Add(lblSelected);

            dgvItems = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = false,
                RowHeadersVisible = false,
                AutoGenerateColumns = false
            };
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { DataPropertyName = nameof(DatabaseItemInfo.ItemCode), HeaderText = "Code", Width = 70 });
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { DataPropertyName = nameof(DatabaseItemInfo.ItemName), HeaderText = "Name", Width = 220 });
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { DataPropertyName = nameof(DatabaseItemInfo.TypeName), HeaderText = "Type", Width = 120 });
            dgvItems.Columns.Add(new DataGridViewTextBoxColumn { DataPropertyName = nameof(DatabaseItemInfo.ItemLevel), HeaderText = "Lvl", Width = 50 });
            dgvItems.SelectionChanged += DgvItems_SelectionChanged;
            dgvItems.CellDoubleClick += (s, e) => SaveAndClose();

            var pnlBottom = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 170,
                Padding = new Padding(10)
            };

            pnlBottom.Controls.Add(new Label { Text = "Group:", Location = new Point(10, 14), AutoSize = true });
            cmbGroupName = new ComboBox
            {
                Location = new Point(55, 11),
                Width = 110,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbGroupName.Items.AddRange(new object[] { GatherUnitNodeDrop.MainGroup, GatherUnitNodeDrop.SecondaryGroup });
            cmbGroupName.SelectedIndex = 0;
            pnlBottom.Controls.Add(cmbGroupName);

            pnlBottom.Controls.Add(new Label { Text = "Reward %:", Location = new Point(180, 14), AutoSize = true });
            numChance = new NumericUpDown
            {
                Location = new Point(275, 11),
                Width = 60,
                Minimum = 0,
                Maximum = 100,
                DecimalPlaces = 0,
                Value = 100
            };
            pnlBottom.Controls.Add(numChance);

            pnlBottom.Controls.Add(new Label { Text = "Pick Weight:", Location = new Point(350, 14), AutoSize = true });
            numWeight = new NumericUpDown
            {
                Location = new Point(430, 11),
                Width = 60,
                Minimum = 1,
                Maximum = 10000,
                Value = 100
            };
            pnlBottom.Controls.Add(numWeight);

            pnlBottom.Controls.Add(new Label { Text = "Per-Hit Min:", Location = new Point(10, 50), AutoSize = true });
            numMinQty = new NumericUpDown
            {
                Location = new Point(85, 47),
                Width = 60,
                Minimum = 1,
                Maximum = 99,
                Value = 1
            };
            pnlBottom.Controls.Add(numMinQty);

            pnlBottom.Controls.Add(new Label { Text = "Per-Hit Max:", Location = new Point(165, 50), AutoSize = true });
            numMaxQty = new NumericUpDown
            {
                Location = new Point(245, 47),
                Width = 60,
                Minimum = 1,
                Maximum = 99,
                Value = 1
            };
            pnlBottom.Controls.Add(numMaxQty);

            chkEnabled = new CheckBox
            {
                Text = "Enabled",
                Location = new Point(290, 49),
                AutoSize = true,
                Checked = true
            };
            pnlBottom.Controls.Add(chkEnabled);

            pnlBottom.Controls.Add(new Label
            {
                Text = "Per-Hit Qty is granted on one successful harvest. Main Reward Pool is set on the unit node.",
                Location = new Point(10, 80),
                Size = new Size(575, 18)
            });

            pnlBottom.Controls.Add(new Label { Text = "Notes:", Location = new Point(10, 108), AutoSize = true });
            txtNotes = new TextBox
            {
                Location = new Point(65, 105),
                Width = 520,
                Height = 33,
                Multiline = true
            };
            pnlBottom.Controls.Add(txtNotes);

            var btnSave = new Button
            {
                Text = "Save",
                Width = 90,
                Height = 30,
                Location = new Point(495, 142),
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnSave.Click += (s, e) => SaveAndClose();
            pnlBottom.Controls.Add(btnSave);

            var btnCancel = new Button
            {
                Text = "Cancel",
                Width = 90,
                Height = 30,
                Location = new Point(595, 142)
            };
            btnCancel.Click += (s, e) => DialogResult = DialogResult.Cancel;
            pnlBottom.Controls.Add(btnCancel);

            Controls.Add(dgvItems);
            Controls.Add(pnlTop);
            Controls.Add(pnlBottom);
        }

        private void LoadItems(string filter = null)
        {
            var items = _repository.GetDatabaseItems(filter);
            dgvItems.DataSource = items;

            if (_originalDrop != null && !string.IsNullOrWhiteSpace(_originalDrop.ItemCode))
            {
                foreach (DataGridViewRow row in dgvItems.Rows)
                {
                    if (row.DataBoundItem is DatabaseItemInfo item && string.Equals(item.ItemCode, _originalDrop.ItemCode, StringComparison.OrdinalIgnoreCase))
                    {
                        row.Selected = true;
                        dgvItems.CurrentCell = row.Cells[0];
                        _selectedItem = item;
                        lblSelected.Text = $"Selected: {item.ItemName} ({item.ItemCode})";
                        break;
                    }
                }
            }
        }

        private void LoadDrop()
        {
            cmbGroupName.SelectedItem = string.Equals(_originalDrop.GroupName, GatherUnitNodeDrop.SecondaryGroup, StringComparison.OrdinalIgnoreCase)
                ? GatherUnitNodeDrop.SecondaryGroup
                : GatherUnitNodeDrop.MainGroup;
            numChance.Value = Math.Max(numChance.Minimum, Math.Min(numChance.Maximum, _originalDrop.DropChancePercent));
            numWeight.Value = Math.Max(numWeight.Minimum, Math.Min(numWeight.Maximum, _originalDrop.Weight));
            numMinQty.Value = Math.Max(numMinQty.Minimum, Math.Min(numMinQty.Maximum, _originalDrop.MinQuantity));
            numMaxQty.Value = Math.Max(numMaxQty.Minimum, Math.Min(numMaxQty.Maximum, _originalDrop.MaxQuantity));
            chkEnabled.Checked = _originalDrop.Enabled;
            txtNotes.Text = _originalDrop.Notes ?? string.Empty;
        }

        private void DgvItems_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count == 0)
            {
                _selectedItem = null;
                lblSelected.Text = "No item selected";
                return;
            }

            _selectedItem = dgvItems.SelectedRows[0].DataBoundItem as DatabaseItemInfo;
            if (_selectedItem != null)
            {
                lblSelected.Text = $"Selected: {_selectedItem.ItemName} ({_selectedItem.ItemCode})";
            }
        }

        private void SaveAndClose()
        {
            if (_selectedItem == null)
            {
                MessageBox.Show("Select an item reward first.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (numMinQty.Value > numMaxQty.Value)
            {
                MessageBox.Show("Min quantity cannot be greater than max quantity.", "Validation", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            Result = new GatherUnitNodeDrop
            {
                Id = _originalDrop?.Id ?? 0,
                NodeId = _originalDrop?.NodeId ?? 0,
                GroupName = cmbGroupName.SelectedItem?.ToString() == GatherUnitNodeDrop.SecondaryGroup
                    ? GatherUnitNodeDrop.SecondaryGroup
                    : GatherUnitNodeDrop.MainGroup,
                ItemCode = _selectedItem.ItemCode,
                ItemName = _selectedItem.ItemName,
                DropChancePercent = (int)numChance.Value,
                Weight = (int)numWeight.Value,
                MinQuantity = (int)numMinQty.Value,
                MaxQuantity = (int)numMaxQty.Value,
                Enabled = chkEnabled.Checked,
                DisplayOrder = _originalDrop?.DisplayOrder ?? 0,
                Notes = string.IsNullOrWhiteSpace(txtNotes.Text) ? null : txtNotes.Text
            };

            DialogResult = DialogResult.OK;
        }

        private void ApplyDarkTheme(Control parent)
        {
            foreach (Control control in parent.Controls)
            {
                if (control is TextBox || control is NumericUpDown)
                {
                    control.BackColor = Color.FromArgb(60, 60, 60);
                    control.ForeColor = Color.White;
                }
                else if (control is DataGridView dgv)
                {
                    dgv.BackgroundColor = Color.FromArgb(30, 30, 30);
                    dgv.GridColor = Color.FromArgb(60, 60, 60);
                    dgv.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 45);
                    dgv.DefaultCellStyle.ForeColor = Color.White;
                    dgv.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
                    dgv.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
                    dgv.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
                    dgv.EnableHeadersVisualStyles = false;
                }
                else if (control is Button btn && btn.BackColor != Color.FromArgb(0, 122, 204))
                {
                    btn.BackColor = Color.FromArgb(70, 70, 70);
                    btn.ForeColor = Color.White;
                    btn.FlatStyle = FlatStyle.Flat;
                    btn.FlatAppearance.BorderColor = Color.FromArgb(100, 100, 100);
                }
                else if (control is Panel)
                {
                    control.BackColor = Color.FromArgb(45, 45, 45);
                }

                if (control.HasChildren)
                {
                    ApplyDarkTheme(control);
                }
            }

            BackColor = Color.FromArgb(45, 45, 45);
            ForeColor = Color.White;
        }
    }
}
