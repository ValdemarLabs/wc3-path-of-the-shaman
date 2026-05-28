using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Parsers;
using WC3ItemManager.Repositories;

namespace WC3ItemManager
{
    /// <summary>
    /// Dialog for previewing and selecting destructibles to import from .w3b files
    /// </summary>
    public class W3BImportDialog : Form
    {
        private readonly List<W3BDestructible> _destructibles;
        private readonly DestructibleTypeRepository _destRepo;
        private readonly int _expectedOriginal;
        private readonly int _expectedCustom;
        
        private DataGridView dgvDestructibles;
        private CheckBox chkSelectAll;
        private CheckBox chkUpdateExisting;
        private CheckBox chkCustomOnly;
        private Label lblSummary;
        private Label lblExpected;
        private Button btnImport;
        private Button btnCancel;
        
        public List<W3BDestructible> SelectedDestructibles { get; private set; } = new List<W3BDestructible>();
        public bool UpdateExisting => chkUpdateExisting.Checked;

        public W3BImportDialog(List<W3BDestructible> destructibles, DestructibleTypeRepository destRepo, int expectedOriginal = 0, int expectedCustom = 0)
        {
            _destructibles = destructibles;
            _destRepo = destRepo;
            _expectedOriginal = expectedOriginal;
            _expectedCustom = expectedCustom;
            
            InitializeComponent();
            LoadDestructibles();
            ApplyDarkTheme();
        }

        private void InitializeComponent()
        {
            this.Text = "Import Destructibles from .w3b";
            this.Size = new Size(800, 600);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.Sizable;
            this.MinimumSize = new Size(600, 400);

            // Top panel with options
            var pnlTop = new Panel
            {
                Dock = DockStyle.Top,
                Height = 80,
                Padding = new Padding(10)
            };

            chkSelectAll = new CheckBox
            {
                Text = "Select All",
                Location = new Point(10, 10),
                AutoSize = true,
                Checked = true
            };
            chkSelectAll.CheckedChanged += ChkSelectAll_CheckedChanged;

            chkCustomOnly = new CheckBox
            {
                Text = "Custom Destructibles Only",
                Location = new Point(120, 10),
                AutoSize = true,
                Checked = false
            };
            chkCustomOnly.CheckedChanged += ChkCustomOnly_CheckedChanged;

            chkUpdateExisting = new CheckBox
            {
                Text = "Update existing destructibles",
                Location = new Point(310, 10),
                AutoSize = true,
                Checked = false
            };

            lblExpected = new Label
            {
                Location = new Point(10, 35),
                AutoSize = true,
                Text = "Expected: ..."
            };
            
            lblSummary = new Label
            {
                Location = new Point(10, 55),
                AutoSize = true,
                Text = "Loading..."
            };

            pnlTop.Controls.AddRange(new Control[] { chkSelectAll, chkCustomOnly, chkUpdateExisting, lblExpected, lblSummary });

            // Grid for destructibles
            dgvDestructibles = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = false,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = true,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                RowHeadersVisible = false,
                BackgroundColor = Color.FromArgb(45, 45, 48),
                BorderStyle = BorderStyle.None
            };

            // Add columns
            dgvDestructibles.Columns.Add(new DataGridViewCheckBoxColumn
            {
                Name = "Selected",
                HeaderText = "✓",
                Width = 30,
                ReadOnly = false
            });
            dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Code",
                HeaderText = "Code",
                Width = 60,
                ReadOnly = true
            });
            dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "BaseId",
                HeaderText = "Base",
                Width = 60,
                ReadOnly = true
            });
            dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Name",
                HeaderText = "Name",
                Width = 180,
                ReadOnly = true
            });
            dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "EditorSuffix",
                HeaderText = "Editor Suffix",
                Width = 120,
                ReadOnly = true
            });
            dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "LootLevel",
                HeaderText = "Level (WE bret)",
                Width = 85,
                ReadOnly = true
            });
            dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Type",
                HeaderText = "Type",
                Width = 80,
                ReadOnly = true
            });
            dgvDestructibles.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Status",
                HeaderText = "Status",
                Width = 80,
                ReadOnly = true
            });

            dgvDestructibles.CellClick += DgvDestructibles_CellClick;

            // Bottom panel with buttons
            var pnlBottom = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 50,
                Padding = new Padding(10)
            };

            btnCancel = new Button
            {
                Text = "Cancel",
                Size = new Size(100, 30),
                Anchor = AnchorStyles.Right | AnchorStyles.Top,
                FlatStyle = FlatStyle.Flat
            };
            btnCancel.Click += (s, e) => this.DialogResult = DialogResult.Cancel;

            btnImport = new Button
            {
                Text = "Import Selected",
                Size = new Size(120, 30),
                Anchor = AnchorStyles.Right | AnchorStyles.Top,
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White
            };
            btnImport.Click += BtnImport_Click;

            // Position buttons
            btnCancel.Location = new Point(pnlBottom.Width - btnCancel.Width - 20, 10);
            btnImport.Location = new Point(btnCancel.Left - btnImport.Width - 10, 10);

            pnlBottom.Controls.AddRange(new Control[] { btnCancel, btnImport });

            // Add controls
            this.Controls.Add(dgvDestructibles);
            this.Controls.Add(pnlTop);
            this.Controls.Add(pnlBottom);

            // Handle resize
            this.Resize += (s, e) =>
            {
                btnCancel.Location = new Point(pnlBottom.Width - btnCancel.Width - 20, 10);
                btnImport.Location = new Point(btnCancel.Left - btnImport.Width - 10, 10);
            };
        }

        private void LoadDestructibles()
        {
            dgvDestructibles.Rows.Clear();

            int expectedTotal = _expectedOriginal + _expectedCustom;
            lblExpected.Text = $"Expected: {expectedTotal} destructibles ({_expectedOriginal} modified, {_expectedCustom} custom) | Parsed: {_destructibles.Count}";

            var displayList = chkCustomOnly.Checked 
                ? _destructibles.Where(d => d.IsCustom).ToList() 
                : _destructibles;

            int newCount = 0;
            int existingCount = 0;

            foreach (var dest in displayList)
            {
                bool exists = _destRepo.Exists(dest.DestructibleCode);
                if (exists) existingCount++;
                else newCount++;

                int rowIdx = dgvDestructibles.Rows.Add(
                    true,
                    dest.DestructibleCode ?? "",
                    dest.BaseId ?? "",
                    dest.Name ?? "",
                    dest.EditorSuffix ?? "",
                    dest.LootLevelFromWE?.ToString() ?? "",
                    dest.IsCustom ? "Custom" : "Modified",
                    exists ? "Exists" : "New"
                );

                dgvDestructibles.Rows[rowIdx].Tag = dest;

                // Color coding
                var row = dgvDestructibles.Rows[rowIdx];
                if (exists)
                {
                    row.DefaultCellStyle.ForeColor = Color.FromArgb(255, 180, 100);
                }
                else
                {
                    row.DefaultCellStyle.ForeColor = Color.FromArgb(100, 200, 100);
                }
            }

            lblSummary.Text = $"Showing {displayList.Count()} destructibles ({newCount} new, {existingCount} existing)";
        }

        private void ChkSelectAll_CheckedChanged(object sender, EventArgs e)
        {
            foreach (DataGridViewRow row in dgvDestructibles.Rows)
            {
                row.Cells["Selected"].Value = chkSelectAll.Checked;
            }
        }

        private void ChkCustomOnly_CheckedChanged(object sender, EventArgs e)
        {
            LoadDestructibles();
        }

        private void DgvDestructibles_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0 && e.ColumnIndex == 0)
            {
                var cell = dgvDestructibles.Rows[e.RowIndex].Cells["Selected"];
                cell.Value = !(bool)(cell.Value ?? false);
            }
        }

        private void BtnImport_Click(object sender, EventArgs e)
        {
            SelectedDestructibles.Clear();

            foreach (DataGridViewRow row in dgvDestructibles.Rows)
            {
                if ((bool)(row.Cells["Selected"].Value ?? false))
                {
                    var dest = row.Tag as W3BDestructible;
                    if (dest != null)
                    {
                        SelectedDestructibles.Add(dest);
                    }
                }
            }

            if (SelectedDestructibles.Count == 0)
            {
                MessageBox.Show("Please select at least one destructible to import.",
                    "No Selection", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            this.DialogResult = DialogResult.OK;
        }

        private void ApplyDarkTheme()
        {
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.ForeColor = Color.White;

            dgvDestructibles.BackgroundColor = Color.FromArgb(30, 30, 30);
            dgvDestructibles.GridColor = Color.FromArgb(60, 60, 60);
            dgvDestructibles.DefaultCellStyle.BackColor = Color.FromArgb(45, 45, 48);
            dgvDestructibles.DefaultCellStyle.ForeColor = Color.White;
            dgvDestructibles.DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 70, 70);
            dgvDestructibles.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(35, 35, 35);
            dgvDestructibles.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvDestructibles.EnableHeadersVisualStyles = false;

            foreach (Control c in this.Controls)
            {
                ApplyThemeToControl(c);
            }
        }

        private void ApplyThemeToControl(Control parent)
        {
            foreach (Control c in parent.Controls)
            {
                if (c is CheckBox || c is Label)
                {
                    c.ForeColor = Color.White;
                }
                else if (c is Button btn && btn.BackColor == SystemColors.Control)
                {
                    btn.BackColor = Color.FromArgb(70, 70, 70);
                    btn.ForeColor = Color.White;
                    btn.FlatAppearance.BorderColor = Color.FromArgb(100, 100, 100);
                }
                else if (c is Panel pnl)
                {
                    pnl.BackColor = Color.FromArgb(45, 45, 48);
                }

                if (c.HasChildren)
                {
                    ApplyThemeToControl(c);
                }
            }
        }
    }
}
