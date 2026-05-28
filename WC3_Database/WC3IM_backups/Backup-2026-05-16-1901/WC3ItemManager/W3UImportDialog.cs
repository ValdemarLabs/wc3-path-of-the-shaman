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
    /// Dialog for previewing and selecting units to import from .w3u files
    /// </summary>
    public class W3UImportDialog : Form
    {
        private readonly List<W3UUnit> _units;
        private readonly UnitTypeRepository _unitRepo;
        private readonly int _expectedOriginal;
        private readonly int _expectedCustom;
        
        private DataGridView dgvUnits;
        private CheckBox chkSelectAll;
        private CheckBox chkUpdateExisting;
        private CheckBox chkCustomOnly;
        private Label lblSummary;
        private Label lblExpected;
        private Button btnImport;
        private Button btnCancel;
        
        public List<W3UUnit> SelectedUnits { get; private set; } = new List<W3UUnit>();
        public bool UpdateExisting => chkUpdateExisting.Checked;

        public W3UImportDialog(List<W3UUnit> units, UnitTypeRepository unitRepo, int expectedOriginal = 0, int expectedCustom = 0)
        {
            _units = units;
            _unitRepo = unitRepo;
            _expectedOriginal = expectedOriginal;
            _expectedCustom = expectedCustom;
            
            InitializeComponent();
            LoadUnits();
            ApplyDarkTheme();
        }

        private void InitializeComponent()
        {
            this.Text = "Import Units from .w3u";
            this.Size = new Size(900, 600);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.Sizable;
            this.MinimumSize = new Size(700, 400);

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
                Text = "Custom Units Only",
                Location = new Point(120, 10),
                AutoSize = true,
                Checked = false
            };
            chkCustomOnly.CheckedChanged += ChkCustomOnly_CheckedChanged;

            chkUpdateExisting = new CheckBox
            {
                Text = "Update existing units",
                Location = new Point(280, 10),
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

            // Grid for units
            dgvUnits = new DataGridView
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
            dgvUnits.Columns.Add(new DataGridViewCheckBoxColumn
            {
                Name = "Selected",
                HeaderText = "✓",
                Width = 30,
                ReadOnly = false
            });
            dgvUnits.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "UnitCode",
                HeaderText = "Code",
                Width = 60,
                ReadOnly = true
            });
            dgvUnits.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "BaseId",
                HeaderText = "Base",
                Width = 60,
                ReadOnly = true
            });
            dgvUnits.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Name",
                HeaderText = "Name",
                Width = 150,
                ReadOnly = true
            });
            dgvUnits.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "EditorSuffix",
                HeaderText = "Editor Suffix",
                Width = 100,
                ReadOnly = true
            });
            dgvUnits.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Level",
                HeaderText = "Level",
                Width = 50,
                ReadOnly = true
            });
            dgvUnits.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Type",
                HeaderText = "Type",
                Width = 80,
                ReadOnly = true
            });
            dgvUnits.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "Status",
                HeaderText = "Status",
                Width = 80,
                ReadOnly = true
            });
            dgvUnits.Columns.Add(new DataGridViewTextBoxColumn
            {
                Name = "IconPath",
                HeaderText = "Icon Path",
                Width = 150,
                ReadOnly = true
            });

            dgvUnits.CellClick += DgvUnits_CellClick;

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
                BackColor = Color.FromArgb(0, 122, 204),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnImport.Click += BtnImport_Click;

            // Use FlowLayoutPanel for right-aligned buttons
            var flowPanel = new FlowLayoutPanel
            {
                Dock = DockStyle.Right,
                FlowDirection = FlowDirection.RightToLeft,
                AutoSize = true,
                WrapContents = false,
                Padding = new Padding(5)
            };
            flowPanel.Controls.Add(btnCancel);
            flowPanel.Controls.Add(btnImport);
            
            pnlBottom.Controls.Add(flowPanel);

            this.Controls.Add(dgvUnits);
            this.Controls.Add(pnlTop);
            this.Controls.Add(pnlBottom);
        }

        private void LoadUnits()
        {
            dgvUnits.Rows.Clear();
            
            var displayUnits = chkCustomOnly.Checked 
                ? _units.Where(u => u.IsCustom).ToList() 
                : _units;

            int newCount = 0;
            int existingCount = 0;

            foreach (var unit in displayUnits)
            {
                bool exists = _unitRepo.GetByCode(unit.UnitCode) != null;
                if (exists) existingCount++;
                else newCount++;

                int rowIndex = dgvUnits.Rows.Add(
                    chkSelectAll.Checked,  // Selected
                    unit.UnitCode,
                    unit.BaseId ?? "-",
                    unit.Name ?? unit.UnitCode,
                    unit.EditorSuffix ?? "-",
                    unit.Level > 0 ? unit.Level.ToString() : "-",
                    unit.IsCustom ? "Custom" : "Modified",
                    exists ? "Exists" : "New",
                    unit.IconPath ?? "-"
                );

                dgvUnits.Rows[rowIndex].Tag = unit;

                // Color existing rows differently
                if (exists)
                {
                    dgvUnits.Rows[rowIndex].DefaultCellStyle.ForeColor = Color.Orange;
                }
            }

            // Update expected counts label
            int expectedTotal = _expectedOriginal + _expectedCustom;
            int actualModified = _units.Count(u => !u.IsCustom);
            int actualCustom = _units.Count(u => u.IsCustom);
            
            if (expectedTotal > 0)
            {
                string status = (expectedTotal == _units.Count) ? "✓" : "⚠";
                lblExpected.Text = $"File header: {expectedTotal} total ({_expectedOriginal} modified + {_expectedCustom} custom) | Parsed: {_units.Count} ({actualModified} modified + {actualCustom} custom) {status}";
            }
            else
            {
                lblExpected.Text = $"Parsed: {_units.Count} units ({actualModified} modified + {actualCustom} custom)";
            }
            
            lblSummary.Text = $"Showing {displayUnits.Count} units ({newCount} new to DB, {existingCount} already in DB)";
        }

        private void ChkSelectAll_CheckedChanged(object sender, EventArgs e)
        {
            foreach (DataGridViewRow row in dgvUnits.Rows)
            {
                row.Cells["Selected"].Value = chkSelectAll.Checked;
            }
        }

        private void ChkCustomOnly_CheckedChanged(object sender, EventArgs e)
        {
            LoadUnits();
        }

        private void DgvUnits_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0 && e.ColumnIndex == 0)
            {
                // Toggle checkbox
                var cell = dgvUnits.Rows[e.RowIndex].Cells["Selected"];
                cell.Value = !(bool)(cell.Value ?? false);
            }
        }

        private void BtnImport_Click(object sender, EventArgs e)
        {
            SelectedUnits.Clear();
            
            foreach (DataGridViewRow row in dgvUnits.Rows)
            {
                if ((bool)(row.Cells["Selected"].Value ?? false))
                {
                    if (row.Tag is W3UUnit unit)
                    {
                        SelectedUnits.Add(unit);
                    }
                }
            }

            if (SelectedUnits.Count == 0)
            {
                MessageBox.Show("Please select at least one unit to import.", "No Selection",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            this.DialogResult = DialogResult.OK;
        }

        private void ApplyDarkTheme()
        {
            this.BackColor = Color.FromArgb(45, 45, 48);
            this.ForeColor = Color.White;

            dgvUnits.BackgroundColor = Color.FromArgb(45, 45, 48);
            dgvUnits.DefaultCellStyle.BackColor = Color.FromArgb(60, 60, 60);
            dgvUnits.DefaultCellStyle.ForeColor = Color.White;
            dgvUnits.DefaultCellStyle.SelectionBackColor = Color.FromArgb(0, 122, 204);
            dgvUnits.AlternatingRowsDefaultCellStyle.BackColor = Color.FromArgb(50, 50, 50);
            dgvUnits.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(37, 37, 38);
            dgvUnits.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvUnits.EnableHeadersVisualStyles = false;
            dgvUnits.GridColor = Color.FromArgb(70, 70, 70);

            foreach (Control c in this.Controls)
            {
                ApplyDarkThemeToControl(c);
            }
        }

        private void ApplyDarkThemeToControl(Control c)
        {
            if (c is Panel panel)
            {
                panel.BackColor = Color.FromArgb(45, 45, 48);
            }
            else if (c is CheckBox chk)
            {
                chk.ForeColor = Color.White;
            }
            else if (c is Label lbl)
            {
                lbl.ForeColor = Color.White;
            }
            else if (c is Button btn && btn.BackColor == SystemColors.Control)
            {
                btn.BackColor = Color.FromArgb(60, 60, 60);
                btn.ForeColor = Color.White;
                btn.FlatStyle = FlatStyle.Flat;
                btn.FlatAppearance.BorderColor = Color.FromArgb(100, 100, 100);
            }

            foreach (Control child in c.Controls)
            {
                ApplyDarkThemeToControl(child);
            }
        }
    }
}
