using System;
using System.Data;
using System.Drawing;
using System.Drawing.Imaging;
using System.Windows.Forms;
using Npgsql;
using System.Linq;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using War3Net.Drawing.Blp;

namespace WC3ItemManager
{
    public partial class MainForm : Form
    {
        private string connectionString = "Host=127.0.0.1;Port=5432;Database=wc3_pots;Username=postgres;Password=009900";
        private DataGridView dgvItems;
        private TextBox txtSearch;
        private ComboBox cmbRarity;
        private ComboBox cmbClass;
        private Button btnAdd;
        private Button btnEdit;
        private Button btnDelete;
        private Button btnRefresh;
        private Button btnExport;
        private Button btnImport;
        private Button btnConnect;
        private Button btnClearFilters;
        private Button btnToggleAdvanced;
        private Button btnExportDEquipment;
        private Button btnConfiguration;
        private Label lblStatus;
        private Label lblCount;
        private Label lblConnectionStatus;
        private Panel pnlConnectionIndicator;
        private CheckBox chkCustomOnly;
        private CheckBox chkHasAbilities;
        private CheckBox chkHasStats;
        private NumericUpDown numMinLevel;
        private NumericUpDown numMaxLevel;
        private NumericUpDown numMinCost;
        private NumericUpDown numMaxCost;
        private Panel pnlAdvancedFilters;
        private Panel pnlPreview;
        private RichTextBox rtbTooltipPreview;
        private PictureBox picIconPreview;
        private Label lblPreviewTitle;
        private ContextMenuStrip dgvContextMenu;
        private MenuStrip menuStrip;
        private ComboBox cmbZoom; // Zoom scale control
        private Label lblZoom;
        private float currentZoomFactor = 1.0f; // Current zoom level
        private ComboBox cmbSort; // Sort order control
        private Label lblSort;
        private bool isConnected = false;
        private bool advancedFiltersVisible = false;
        private Dictionary<string, int> columnWidths = new Dictionary<string, int>();
        private Dictionary<string, bool> columnVisibilitySettings = new Dictionary<string, bool>();
        private string settingsFile = "MainFormSettings.ini";
        private static string cacheFolder = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cache");
        private static string backupFolder = "";

        public MainForm()
        {
            try
            {
                // Ensure cache folder exists
                if (!Directory.Exists(cacheFolder))
                {
                    Directory.CreateDirectory(cacheFolder);
                }
                
                InitializeComponent();
                LoadSettings();
                SetupUI();
                SetupContextMenu();
                
                // Apply saved zoom level after UI is setup
                if (currentZoomFactor != 1.0f && cmbZoom != null)
                {
                    ApplyZoom(currentZoomFactor);
                }
                
                TestConnection();
                if (isConnected)
                    LoadData();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error initializing form: {ex.Message}\n\nStack: {ex.StackTrace}",
                    "Startup Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                throw;
            }
        }
        
        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            SaveSettings();
            base.OnFormClosing(e);
        }

        private void LoadSettings()
        {
            try
            {
                if (File.Exists(settingsFile))
                {
                    foreach (var line in File.ReadAllLines(settingsFile))
                    {
                        var parts = line.Split('=');
                        if (parts.Length == 2)
                        {
                            if (parts[0] == "ZoomLevel" && float.TryParse(parts[1], out float zoom))
                            {
                                currentZoomFactor = zoom;
                            }
                            else if (parts[0] == "BackupFolder")
                            {
                                backupFolder = parts[1];
                            }
                            else if (parts[0].StartsWith("Visible_"))
                            {
                                string colName = parts[0].Substring(8);
                                if (bool.TryParse(parts[1], out bool visible))
                                {
                                    columnVisibilitySettings[colName] = visible;
                                }
                            }
                            else if (int.TryParse(parts[1], out int width))
                            {
                                columnWidths[parts[0]] = width;
                            }
                        }
                    }
                }
                
                // Set default backup folder if not loaded or empty
                if (string.IsNullOrEmpty(backupFolder))
                {
                    backupFolder = Path.Combine(
                        Directory.GetParent(AppDomain.CurrentDomain.BaseDirectory).Parent.Parent.Parent.FullName,
                        "database_item_backups"
                    );
                }
            }
            catch { /* Ignore settings load errors */ }
        }

        private void SaveSettings()
        {
            try
            {
                var lines = new List<string>();
                lines.Add($"ZoomLevel={currentZoomFactor}"); // Save zoom level
                lines.Add($"BackupFolder={backupFolder}"); // Save backup folder path
                
                if (dgvItems != null && dgvItems.Columns != null)
                {
                    foreach (DataGridViewColumn col in dgvItems.Columns)
                    {
                        lines.Add($"{col.Name}={col.Width}");
                        lines.Add($"Visible_{col.Name}={col.Visible}");
                    }
                }
                File.WriteAllLines(settingsFile, lines);
            }
            catch { /* Ignore settings save errors */ }
        }

        private void SetupUI()
        {
            this.Text = "WC3 Item Manager - PotS Database";
            this.Size = new Size(1900, 900);
            this.StartPosition = FormStartPosition.CenterScreen;

            // Main container - split between datagrid and preview
            SplitContainer mainSplitter = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                FixedPanel = FixedPanel.None, // Allow both panels to resize
                BorderStyle = BorderStyle.FixedSingle
                // Panel2MinSize and SplitterDistance set AFTER adding to form
            };

            // === LEFT SIDE: DataGrid and controls ===

            // Top Panel - Search and Basic Filters
            Panel topPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 90,
                Padding = new Padding(10)
            };

            Label lblSearchTitle = new Label
            {
                Text = "Search & Filters:",
                Location = new Point(10, 10),
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                AutoSize = true
            };

            Label lblSearch = new Label
            {
                Text = "Search:",
                Location = new Point(10, 40),
                AutoSize = true
            };

            txtSearch = new TextBox
            {
                Location = new Point(70, 38),
                Width = 350,
                Font = new Font("Segoe UI", 9)
            };
            txtSearch.TextChanged += (s, e) => ApplyFilters();
            txtSearch.Enter += (s, e) => lblStatus.Text = "Search in: Name, Code, Description, Abilities";

            Label lblRarity = new Label
            {
                Text = "Rarity:",
                Location = new Point(440, 40),
                AutoSize = true
            };

            cmbRarity = new ComboBox
            {
                Location = new Point(500, 38),
                Width = 120,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbRarity.Items.AddRange(new object[] { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary" });
            cmbRarity.SelectedIndex = 0;
            cmbRarity.SelectedIndexChanged += (s, e) => ApplyFilters();

            Label lblClass = new Label
            {
                Text = "Class:",
                Location = new Point(630, 40),
                AutoSize = true
            };

            cmbClass = new ComboBox
            {
                Location = new Point(680, 38),
                Width = 120,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cmbClass.Items.AddRange(new object[] { "All", "MISC", "CONSUMABLE", "ARTIFACT", "QUEST" });
            cmbClass.SelectedIndex = 0;
            cmbClass.SelectedIndexChanged += (s, e) => ApplyFilters();

            chkCustomOnly = new CheckBox
            {
                Text = "Custom Only",
                Location = new Point(810, 40),
                AutoSize = true
            };
            chkCustomOnly.CheckedChanged += (s, e) => ApplyFilters();

            btnToggleAdvanced = new Button
            {
                Text = "▼ Advanced",
                Location = new Point(920, 36),
                Width = 110,
                Height = 28
            };
            btnToggleAdvanced.Click += BtnToggleAdvanced_Click;

            btnClearFilters = new Button
            {
                Text = "✖ Clear All",
                Location = new Point(1040, 36),
                Width = 100,
                Height = 28,
                ForeColor = Color.DarkRed
            };
            btnClearFilters.Click += BtnClearFilters_Click;

            topPanel.Controls.AddRange(new Control[] {
                lblSearchTitle, lblSearch, txtSearch, lblRarity, cmbRarity,
                lblClass, cmbClass, chkCustomOnly, btnToggleAdvanced, btnClearFilters
            });

            // Advanced Filters Panel (initially hidden)
            pnlAdvancedFilters = new Panel
            {
                Dock = DockStyle.Top,
                Height = 130,
                Padding = new Padding(10),
                BackColor = Color.FromArgb(245, 245, 245),
                Visible = false
            };

            Label lblAdvTitle = new Label
            {
                Text = "Advanced Filters:",
                Location = new Point(10, 5),
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                AutoSize = true
            };

            // Level filters
            Label lblLevel = new Label
            {
                Text = "Level:",
                Location = new Point(10, 30),
                AutoSize = true
            };

            numMinLevel = new NumericUpDown
            {
                Location = new Point(60, 28),
                Width = 70,
                Minimum = 0,
                Maximum = 999,
                Value = 0
            };
            numMinLevel.ValueChanged += (s, e) => ApplyFilters();

            Label lblTo1 = new Label
            {
                Text = "to",
                Location = new Point(135, 30),
                AutoSize = true
            };

            numMaxLevel = new NumericUpDown
            {
                Location = new Point(160, 28),
                Width = 70,
                Minimum = 0,
                Maximum = 999,
                Value = 999
            };
            numMaxLevel.ValueChanged += (s, e) => ApplyFilters();

            // Level range quick filters
            Label lblLevelRanges = new Label
            {
                Text = "Quick Filters:",
                Location = new Point(10, 60),
                AutoSize = true,
                Font = new Font("Segoe UI", 8, FontStyle.Regular)
            };

            FlowLayoutPanel pnlLevelRanges = new FlowLayoutPanel
            {
                Location = new Point(90, 58),
                Width = 640,
                Height = 30,
                AutoSize = false,
                WrapContents = false
            };

            // Create level range buttons
            var levelRanges = new[] 
            {
                ("All", 0, 999),
                ("1-5", 1, 5),
                ("6-10", 6, 10),
                ("11-15", 11, 15),
                ("16-20", 16, 20),
                ("21-25", 21, 25),
                ("26+", 26, 999)
            };

            foreach (var (text, min, max) in levelRanges)
            {
                Button btnRange = new Button
                {
                    Text = text,
                    Width = 60,
                    Height = 26,
                    Font = new Font("Segoe UI", 8, FontStyle.Regular),
                    BackColor = Color.FromArgb(240, 240, 240),
                    FlatStyle = FlatStyle.Flat,
                    Margin = new Padding(0, 0, 5, 0),
                    Tag = new Tuple<int, int>(min, max)
                };
                btnRange.FlatAppearance.BorderColor = Color.FromArgb(200, 200, 200);
                btnRange.Click += (s, e) =>
                {
                    var btn = (Button)s;
                    var range = (Tuple<int, int>)btn.Tag;
                    numMinLevel.Value = range.Item1;
                    numMaxLevel.Value = range.Item2;
                    // Highlight the active button
                    foreach (Control ctrl in pnlLevelRanges.Controls)
                    {
                        if (ctrl is Button b)
                        {
                            b.BackColor = Color.FromArgb(240, 240, 240);
                            b.Font = new Font("Segoe UI", 8, FontStyle.Regular);
                        }
                    }
                    btn.BackColor = Color.FromArgb(100, 149, 237); // Cornflower blue
                    btn.Font = new Font("Segoe UI", 8, FontStyle.Bold);
                };
                pnlLevelRanges.Controls.Add(btnRange);
            }

            // Cost filters
            Label lblCost = new Label
            {
                Text = "Gold Cost:",
                Location = new Point(10, 95),
                AutoSize = true
            };

            numMinCost = new NumericUpDown
            {
                Location = new Point(80, 93),
                Width = 90,
                Minimum = 0,
                Maximum = 999999,
                Value = 0
            };
            numMinCost.ValueChanged += (s, e) => ApplyFilters();

            Label lblTo2 = new Label
            {
                Text = "to",
                Location = new Point(175, 95),
                AutoSize = true
            };

            numMaxCost = new NumericUpDown
            {
                Location = new Point(200, 93),
                Width = 90,
                Minimum = 0,
                Maximum = 999999,
                Value = 999999
            };
            numMaxCost.ValueChanged += (s, e) => ApplyFilters();

            // Has abilities/stats checkboxes
            chkHasAbilities = new CheckBox
            {
                Text = "Has Abilities",
                Location = new Point(320, 95),
                AutoSize = true
            };
            chkHasAbilities.CheckedChanged += (s, e) => ApplyFilters();

            chkHasStats = new CheckBox
            {
                Text = "Has Stats",
                Location = new Point(440, 95),
                AutoSize = true
            };
            chkHasStats.CheckedChanged += (s, e) => ApplyFilters();

            pnlAdvancedFilters.Controls.AddRange(new Control[] {
                lblAdvTitle, lblLevel, numMinLevel, lblTo1, numMaxLevel,
                lblLevelRanges, pnlLevelRanges,
                lblCost, numMinCost, lblTo2, numMaxCost, chkHasAbilities, chkHasStats
            });

            // Button Panel
            Panel buttonPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 50,
                Padding = new Padding(10, 5, 10, 5)
            };

            btnAdd = new Button
            {
                Text = "➕ Add New",
                Location = new Point(10, 10),
                Width = 100,
                Height = 35,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                BackColor = Color.FromArgb(76, 175, 80),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnAdd.FlatAppearance.BorderSize = 0;
            btnAdd.Click += BtnAdd_Click;

            btnEdit = new Button
            {
                Text = "✏️ Edit",
                Location = new Point(120, 10),
                Width = 120,
                Height = 35,
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(33, 150, 243),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnEdit.FlatAppearance.BorderSize = 0;
            btnEdit.Click += BtnEdit_Click;

            btnDelete = new Button
            {
                Text = "🗑️ Delete",
                Location = new Point(250, 10),
                Width = 100,
                Height = 35,
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(244, 67, 54),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnDelete.FlatAppearance.BorderSize = 0;
            btnDelete.Click += BtnDelete_Click;

            btnRefresh = new Button
            {
                Text = "🔄 Refresh",
                Location = new Point(360, 10),
                Width = 100,
                Height = 35,
                Font = new Font("Segoe UI", 9)
            };
            btnRefresh.Click += (s, e) => LoadData();

            btnExport = new Button
            {
                Text = "💾 Export to W3T",
                Location = new Point(470, 10),
                Width = 140,
                Height = 35,
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(156, 39, 176),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnExport.FlatAppearance.BorderSize = 0;
            btnExport.Click += BtnExport_Click;

            // Import Button
            btnImport = new Button
            {
                Text = "📥 Import from W3T",
                Location = new Point(620, 10),
                Width = 150,
                Height = 35,
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(0, 150, 136),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnImport.FlatAppearance.BorderSize = 0;
            btnImport.Click += (s, e) => Menu_ImportW3T(s, e);

            // DEquipment Export Button
            btnExportDEquipment = new Button
            {
                Text = "📜 DEquipment",
                Location = new Point(780, 10),
                Width = 130,
                Height = 35,
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(255, 140, 0), // Dark orange
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Visible = false // Hide by default, show when connected
            };
            btnExportDEquipment.FlatAppearance.BorderSize = 0;
            btnExportDEquipment.Click += BtnExportDEquipment_Click;

            btnConnect = new Button
            {
                Text = "🔌 Connect",
                Location = new Point(920, 10),
                Width = 110,
                Height = 35,
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(96, 125, 139),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnConnect.FlatAppearance.BorderSize = 0;
            btnConnect.Click += BtnConnect_Click;
            
            btnConfiguration = new Button
            {
                Text = "⚙️ Config",
                Location = new Point(1040, 10),
                Width = 100,
                Height = 35,
                Font = new Font("Segoe UI", 9),
                BackColor = Color.FromArgb(96, 125, 139),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnConfiguration.FlatAppearance.BorderSize = 0;
            btnConfiguration.Click += BtnConfiguration_Click;

            // Connection status indicator
            pnlConnectionIndicator = new Panel
            {
                Location = new Point(1150, 18),
                Size = new Size(16, 16),
                BackColor = Color.Red
            };

            lblConnectionStatus = new Label
            {
                Text = "Disconnected",
                Location = new Point(1172, 15),
                AutoSize = true,
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.Red
            };

            lblCount = new Label
            {
                Text = "Items: 0",
                Location = new Point(1280, 15),
                AutoSize = true,
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };
            
            // Zoom control
            lblZoom = new Label
            {
                Text = "Zoom:",
                Location = new Point(1390, 18),
                AutoSize = true,
                Font = new Font("Segoe UI", 9)
            };
            
            cmbZoom = new ComboBox
            {
                Location = new Point(1435, 15),
                Width = 80,
                DropDownStyle = ComboBoxStyle.DropDownList,
                Font = new Font("Segoe UI", 9)
            };
            cmbZoom.Items.AddRange(new string[] { "50%", "75%", "100%", "125%", "150%", "175%", "200%" });
            int savedZoomIndex = Array.IndexOf(new float[] { 0.5f, 0.75f, 1.0f, 1.25f, 1.5f, 1.75f, 2.0f }, currentZoomFactor);
            cmbZoom.SelectedIndex = savedZoomIndex >= 0 ? savedZoomIndex : 2; // Default 100%
            cmbZoom.SelectedIndexChanged += CmbZoom_SelectedIndexChanged;
            
            // Sort control
            lblSort = new Label
            {
                Text = "Sort By:",
                Location = new Point(1525, 18),
                AutoSize = true,
                Font = new Font("Segoe UI", 9)
            };
            
            cmbSort = new ComboBox
            {
                Location = new Point(1580, 15),
                Width = 150,
                DropDownStyle = ComboBoxStyle.DropDownList,
                Font = new Font("Segoe UI", 9)
            };
            cmbSort.Items.AddRange(new string[] {
                "Code (A-Z)",
                "Code (Z-A)",
                "Name (A-Z)",
                "Name (Z-A)",
                "Recently Added",
                "Recently Modified",
                "Level (Low-High)",
                "Level (High-Low)"
            });
            cmbSort.SelectedIndex = 0; // Default to Code (A-Z)
            cmbSort.SelectedIndexChanged += CmbSort_SelectedIndexChanged;

            buttonPanel.Controls.AddRange(new Control[] {
                btnAdd, btnEdit, btnDelete, btnRefresh, btnExport, btnImport, btnConnect, btnConfiguration,
                btnExportDEquipment,
                pnlConnectionIndicator, lblConnectionStatus, lblCount, lblZoom, cmbZoom, lblSort, cmbSort
            });

            // DataGridView
            dgvItems = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                MultiSelect = true, // ENABLE MULTI-SELECT
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.None,
                AllowUserToResizeColumns = true,
                AllowUserToOrderColumns = true,
                BackgroundColor = Color.White,
                BorderStyle = BorderStyle.None,
                Font = new Font("Segoe UI", 9),
                RowHeadersVisible = false,
                EnableHeadersVisualStyles = false,
                RowTemplate = { Height = 40 } // Taller rows to accommodate icons
            };
            dgvItems.CellDoubleClick += (s, e) => { if (e.RowIndex >= 0) BtnEdit_Click(s, e); };
            dgvItems.SelectionChanged += DgvItems_SelectionChanged;
            dgvItems.ColumnWidthChanged += (s, e) => SaveSettings();
            dgvItems.CellFormatting += DgvItems_CellFormatting; // Row coloring based on rarity

            // Enable column sorting
            dgvItems.ColumnHeaderMouseClick += DgvItems_ColumnHeaderMouseClick;

            // Style headers
            dgvItems.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(70, 130, 180);
            dgvItems.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgvItems.ColumnHeadersDefaultCellStyle.Font = new Font("Segoe UI", 9, FontStyle.Bold);
            dgvItems.ColumnHeadersHeight = 32;

            // Default row colors (overridden by rarity coloring)
            dgvItems.RowsDefaultCellStyle.BackColor = Color.White;
            dgvItems.RowsDefaultCellStyle.SelectionBackColor = Color.FromArgb(51, 153, 255);

            // Add to left panel
            Panel leftPanel = new Panel { Dock = DockStyle.Fill };
            leftPanel.Controls.Add(dgvItems);
            leftPanel.Controls.Add(buttonPanel);
            leftPanel.Controls.Add(pnlAdvancedFilters);
            leftPanel.Controls.Add(topPanel);

            mainSplitter.Panel1.Controls.Add(leftPanel);

            // === RIGHT SIDE: Preview Panel ===
            pnlPreview = new Panel
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(10),
                BackColor = Color.FromArgb(250, 250, 250)
            };

            lblPreviewTitle = new Label
            {
                Text = "Item Preview",
                Dock = DockStyle.Top,
                Height = 30,
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                TextAlign = ContentAlignment.MiddleLeft
            };

            picIconPreview = new PictureBox
            {
                Dock = DockStyle.Top,
                Height = 80,
                SizeMode = PictureBoxSizeMode.CenterImage,
                BackColor = Color.FromArgb(230, 230, 230),
                BorderStyle = BorderStyle.FixedSingle
            };

            rtbTooltipPreview = new RichTextBox
            {
                Dock = DockStyle.Fill,
                ReadOnly = true,
                BackColor = Color.FromArgb(15, 15, 25),
                ForeColor = Color.White,
                Font = new Font("Consolas", 9),
                BorderStyle = BorderStyle.None,
                Padding = new Padding(10)
            };

            pnlPreview.Controls.Add(rtbTooltipPreview);
            pnlPreview.Controls.Add(picIconPreview);
            pnlPreview.Controls.Add(lblPreviewTitle);

            mainSplitter.Panel2.Controls.Add(pnlPreview);

            // Status Bar
            Panel statusPanel = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 30,
                BackColor = Color.FromArgb(240, 240, 240),
                Padding = new Padding(10, 5, 10, 5)
            };

            lblStatus = new Label
            {
                Text = "Ready",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleLeft,
                Font = new Font("Segoe UI", 9)
            };
            statusPanel.Controls.Add(lblStatus);

            // Create menu bar
            CreateMenuBar();
            
            // Add to Form
            this.Controls.Add(mainSplitter);
            this.Controls.Add(statusPanel);
            this.Controls.Add(menuStrip);
            this.MainMenuStrip = menuStrip;
            
            // Set splitter properties AFTER adding to form (when it has actual width)
            // Use a safe calculation with fallback
            int formWidth = this.ClientSize.Width > 0 ? this.ClientSize.Width : 1900;
            mainSplitter.Panel2MinSize = 300; // Set min size first
            mainSplitter.SplitterDistance = Math.Max(800, formWidth - 450); // Leave 450px for preview
        }

        private void TestConnection()
        {
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    isConnected = true;
                    UpdateConnectionStatus(true, "Connected");
                }
            }
            catch (Exception ex)
            {
                isConnected = false;
                UpdateConnectionStatus(false, $"Connection failed: {ex.Message}");
            }
        }

        private void UpdateConnectionStatus(bool connected, string message)
        {
            isConnected = connected;
            pnlConnectionIndicator.BackColor = connected ? Color.LimeGreen : Color.Red;
            lblConnectionStatus.Text = connected ? "Connected" : "Disconnected";
            lblConnectionStatus.ForeColor = connected ? Color.Green : Color.Red;
            lblStatus.Text = message;
            
            // Enable/disable buttons based on connection
            btnAdd.Enabled = connected;
            btnEdit.Enabled = connected;
            btnDelete.Enabled = connected;
            btnRefresh.Enabled = connected;
            btnExport.Enabled = connected;
            btnImport.Enabled = connected;
            btnExportDEquipment.Visible = connected; // Show DEquipment export when connected
            btnConnect.Text = connected ? "🔌 Reconnect" : "🔌 Connect";
        }

        private void BtnConnect_Click(object sender, EventArgs e)
        {
            lblStatus.Text = "Connecting to database...";
            TestConnection();
            if (isConnected)
                LoadData();
        }
        
        private void BtnConfiguration_Click(object sender, EventArgs e)
        {
            try
            {
                // Get current column visibility
                var columnVisibility = new Dictionary<string, bool>();
                if (dgvItems != null && dgvItems.Columns.Count > 0)
                {
                    foreach (DataGridViewColumn col in dgvItems.Columns)
                    {
                        columnVisibility[col.Name] = col.Visible;
                    }
                }
                
                // Get current icon paths from settings
                string blizzardPath = IconPathConfig.GetBlizzardIconPath();
                string customPath = IconPathConfig.GetCustomIconPath();
                
                // Open configuration dialog
                using (var configForm = new ConfigurationForm(columnVisibility, blizzardPath, customPath, backupFolder))
                {
                    if (configForm.ShowDialog() == DialogResult.OK)
                    {
                        // Apply and save column visibility settings
                        foreach (var kvp in configForm.ColumnVisibilitySettings)
                        {
                            if (dgvItems.Columns.Contains(kvp.Key))
                            {
                                dgvItems.Columns[kvp.Key].Visible = kvp.Value;
                                columnVisibilitySettings[kvp.Key] = kvp.Value; // Save to persistent settings
                            }
                        }
                        
                        // Update backup folder from configuration
                        backupFolder = configForm.BackupFolderPath;
                        
                        // Save settings to file
                        SaveSettings();
                        
                        // Save icon path settings
                        IconPathConfig.SaveIconPaths(configForm.BlizzardIconPath, configForm.CustomIconPath);
                        
                        // Refresh display
                        dgvItems.Refresh();
                        lblStatus.Text = "Configuration saved successfully";
                        lblStatus.ForeColor = Color.Green;
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error opening configuration: {ex.Message}", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void LoadData(string whereClause = "", string orderByClause = "ORDER BY i.item_code ASC")
        {
            if (!isConnected || dgvItems == null)
            {
                return;
            }

            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    string query = @"
                        SELECT 
                            i.id,
                            i.item_code,
                            i.item_name,
                            i.base_id,
                            i.icon_path,
                            COALESCE(r.rarity_name, 'Unknown') as rarity,
                            COALESCE(c.class_name, 'MISC') as class,
                            i.item_level,
                            i.gold_cost,
                            i.tooltip,
                            i.tooltip_extended,
                            i.hotkey,
                            i.wc3_abilities,
                            i.wc3_classification,
                            CASE WHEN i.base_id IS NOT NULL THEN 'Custom' ELSE 'Original' END as type,
                            i.created_at,
                            i.updated_at
                        FROM items i
                        LEFT JOIN item_rarities r ON i.rarity_id = r.id
                        LEFT JOIN item_classes c ON i.class_id = c.id
                        " + whereClause + @" 
                        " + orderByClause;

                    using (var adapter = new NpgsqlDataAdapter(query, conn))
                    {
                        DataTable dt = new DataTable();
                        adapter.Fill(dt);
                        
                        // Add icon image column
                        if (!dt.Columns.Contains("icon_image"))
                        {
                            dt.Columns.Add("icon_image", typeof(Image));
                        }
                        
                        // Strip WC3 color codes from item names for clean display
                        // and load icon images
                        if (dt.Columns.Contains("item_name"))
                        {
                            foreach (DataRow row in dt.Rows)
                            {
                                if (row["item_name"] != DBNull.Value)
                                {
                                    string rawName = row["item_name"].ToString();
                                    row["item_name"] = ParseWC3ColorCodes(rawName);
                                }
                                
                                // Load icon image
                                if (row["icon_path"] != DBNull.Value)
                                {
                                    string iconPath = row["icon_path"].ToString();
                                    Image iconImage = LoadIconThumbnail(iconPath, 32, 32);
                                    row["icon_image"] = iconImage ?? CreatePlaceholderIcon(32, 32);
                                }
                                else
                                {
                                    row["icon_image"] = CreatePlaceholderIcon(32, 32);
                                }
                            }
                        }
                        
                        dgvItems.DataSource = dt;

                        // Format columns
                        if (dgvItems.Columns.Count > 0)
                        {
                            // Configure icon column
                            if (dgvItems.Columns.Contains("icon_image"))
                            {
                                dgvItems.Columns["icon_image"].HeaderText = "";
                                dgvItems.Columns["icon_image"].Width = 40;
                                dgvItems.Columns["icon_image"].DisplayIndex = 0;
                                dgvItems.Columns["icon_image"].SortMode = DataGridViewColumnSortMode.NotSortable;
                                dgvItems.Columns["icon_image"].DefaultCellStyle.Padding = new Padding(4);
                                dgvItems.Columns["icon_image"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
                            }
                            
                            dgvItems.Columns["id"].Visible = false;
                            dgvItems.Columns["item_code"].HeaderText = "Code";
                            dgvItems.Columns["item_name"].HeaderText = "Name";
                            dgvItems.Columns["base_id"].HeaderText = "Base";
                            dgvItems.Columns["icon_path"].Visible = false;
                            dgvItems.Columns["rarity"].HeaderText = "Rarity";
                            dgvItems.Columns["class"].HeaderText = "Class";
                            dgvItems.Columns["item_level"].HeaderText = "Level";
                            dgvItems.Columns["gold_cost"].HeaderText = "Gold";
                            dgvItems.Columns["type"].HeaderText = "Type";
                            dgvItems.Columns["tooltip"].Visible = false;
                            dgvItems.Columns["tooltip_extended"].Visible = false;
                            dgvItems.Columns["created_at"].HeaderText = "Created";
                            dgvItems.Columns["created_at"].Width = 150;
                            dgvItems.Columns["created_at"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm";
                            dgvItems.Columns["updated_at"].HeaderText = "Modified";
                            dgvItems.Columns["updated_at"].Width = 150;
                            dgvItems.Columns["updated_at"].DefaultCellStyle.Format = "yyyy-MM-dd HH:mm";
                            dgvItems.Columns["hotkey"].Visible = false;
                            dgvItems.Columns["wc3_abilities"].Visible = false;
                            dgvItems.Columns["wc3_classification"].Visible = false;

                            // Apply saved column widths or defaults
                            ApplyColumnWidth("item_code", 80);
                            ApplyColumnWidth("item_name", 250);
                            ApplyColumnWidth("base_id", 80);
                            ApplyColumnWidth("rarity", 100);
                            ApplyColumnWidth("class", 100);
                            ApplyColumnWidth("item_level", 60);
                            ApplyColumnWidth("gold_cost", 80);
                            ApplyColumnWidth("type", 80);
                            
                            // Apply saved column visibility settings
                            ApplyColumnVisibilitySettings();
                            
                            // Enable sorting for all visible columns
                            foreach (DataGridViewColumn col in dgvItems.Columns)
                            {
                                if (col.Visible)
                                    col.SortMode = DataGridViewColumnSortMode.Programmatic;
                            }
                        }

                        lblCount.Text = $"Items: {dt.Rows.Count}";
                        lblStatus.Text = $"Loaded {dt.Rows.Count} items";
                    }
                }
            }
            catch (Exception ex)
            {
                string errorDetails = $"Error loading data: {ex.Message}";
                if (ex.InnerException != null)
                {
                    errorDetails += $"\n\nInner Exception: {ex.InnerException.Message}";
                }
                errorDetails += $"\n\nStack Trace:\n{ex.StackTrace}";
                MessageBox.Show(errorDetails, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                lblStatus.Text = "Error loading data";
            }
        }

        /// <summary>
        /// Loads an icon from the icon path and resizes it to thumbnail size.
        /// </summary>
        private Image LoadIconThumbnail(string iconPath, int width, int height)
        {
            try
            {
                string fullPath = IconPathConfig.Instance.ResolveIconPath(iconPath);
                
                if (string.IsNullOrEmpty(fullPath))
                    return null;
                
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
                    return null;
                
                // Load and resize image
                using (var originalImage = Image.FromFile(actualPath))
                {
                    var thumbnail = new Bitmap(width, height);
                    using (var graphics = Graphics.FromImage(thumbnail))
                    {
                        graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                        graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
                        graphics.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                        graphics.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
                        
                        // Calculate scaling to fit within bounds while maintaining aspect ratio
                        float scale = Math.Min((float)width / originalImage.Width, (float)height / originalImage.Height);
                        int scaledWidth = (int)(originalImage.Width * scale);
                        int scaledHeight = (int)(originalImage.Height * scale);
                        int x = (width - scaledWidth) / 2;
                        int y = (height - scaledHeight) / 2;
                        
                        graphics.Clear(Color.Black);
                        graphics.DrawImage(originalImage, x, y, scaledWidth, scaledHeight);
                    }
                    return thumbnail;
                }
            }
            catch
            {
                return null;
            }
        }
        
        /// <summary>
        /// Creates a placeholder icon for items without icons.
        /// </summary>
        private Image CreatePlaceholderIcon(int width, int height)
        {
            var placeholder = new Bitmap(width, height);
            using (var graphics = Graphics.FromImage(placeholder))
            {
                graphics.Clear(Color.FromArgb(50, 50, 50));
                using (var pen = new Pen(Color.Gray, 2))
                {
                    graphics.DrawRectangle(pen, 2, 2, width - 4, height - 4);
                }
                // Draw a small "?" in the center
                using (var font = new Font("Arial", 12, FontStyle.Bold))
                using (var brush = new SolidBrush(Color.Gray))
                {
                    var format = new StringFormat
                    {
                        Alignment = StringAlignment.Center,
                        LineAlignment = StringAlignment.Center
                    };
                    graphics.DrawString("?", font, brush, new RectangleF(0, 0, width, height), format);
                }
            }
            return placeholder;
        }

        private void ApplyFilters()
        {
            List<string> conditions = new List<string>();

            // Search filter - multiple fields
            if (!string.IsNullOrWhiteSpace(txtSearch.Text))
            {
                string search = txtSearch.Text.Replace("'", "''");
                conditions.Add($"(i.item_name ILIKE '%{search}%' OR i.item_code ILIKE '%{search}%' OR i.tooltip ILIKE '%{search}%' OR i.tooltip_extended ILIKE '%{search}%' OR i.wc3_abilities ILIKE '%{search}%')");
            }

            // Rarity filter
            if (cmbRarity.SelectedIndex > 0)
            {
                conditions.Add($"r.rarity_name = '{cmbRarity.SelectedItem}'");
            }

            // Class filter
            if (cmbClass.SelectedIndex > 0)
            {
                conditions.Add($"c.class_name = '{cmbClass.SelectedItem}'");
            }

            // Custom items only
            if (chkCustomOnly.Checked)
            {
                conditions.Add("i.base_id IS NOT NULL");
            }

            // Level filter
            if (numMinLevel.Value > 0 || numMaxLevel.Value < 999)
            {
                conditions.Add($"i.item_level BETWEEN {numMinLevel.Value} AND {numMaxLevel.Value}");
            }

            // Cost filter (advanced)
            if (numMinCost.Value > 0 || numMaxCost.Value < 999999)
            {
                conditions.Add($"i.gold_cost BETWEEN {numMinCost.Value} AND {numMaxCost.Value}");
            }

            // Has abilities filter (advanced)
            if (chkHasAbilities.Checked)
            {
                conditions.Add("(i.wc3_abilities IS NOT NULL AND i.wc3_abilities != '')");
            }

            // Has stats filter (advanced)
            if (chkHasStats.Checked)
            {
                conditions.Add("EXISTS (SELECT 1 FROM item_stat_values isv WHERE isv.item_id = i.id)");
            }

            string whereClause = conditions.Count > 0 ? "WHERE " + string.Join(" AND ", conditions) : "";
            
            // Get current sort order
            string orderByClause = GetOrderByClause();
            
            LoadData(whereClause, orderByClause);
        }

        private void BtnAdd_Click(object sender, EventArgs e)
        {
            using (var form = new ItemEditForm(null, connectionString))
            {
                if (form.ShowDialog() == DialogResult.OK)
                {
                    LoadData();
                }
            }
        }

        private void BtnEdit_Click(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count == 0)
            {
                MessageBox.Show("Please select an item to edit.", "No Selection", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            int itemId = Convert.ToInt32(dgvItems.SelectedRows[0].Cells["id"].Value);
            using (var form = new ItemEditForm(itemId, connectionString))
            {
                if (form.ShowDialog() == DialogResult.OK)
                {
                    LoadData();
                }
            }
        }

        private void BtnDelete_Click(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count == 0)
            {
                MessageBox.Show("Please select an item to delete.", "No Selection", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            string itemName = dgvItems.SelectedRows[0].Cells["item_name"].Value?.ToString() ?? "Unknown";
            string itemCode = dgvItems.SelectedRows[0].Cells["item_code"].Value?.ToString() ?? "Unknown";
            var result = MessageBox.Show($"Are you sure you want to delete '{itemName}'?", "Confirm Delete",
                MessageBoxButtons.YesNo, MessageBoxIcon.Warning);

            if (result == DialogResult.Yes)
            {
                try
                {
                    int itemId = Convert.ToInt32(dgvItems.SelectedRows[0].Cells["id"].Value);
                    using (var conn = new NpgsqlConnection(connectionString))
                    {
                        conn.Open();
                        using (var cmd = new NpgsqlCommand("DELETE FROM items WHERE id = @id", conn))
                        {
                            cmd.Parameters.AddWithValue("id", itemId);
                            cmd.ExecuteNonQuery();
                        }
                    }
                    Logger.Instance.Info($"Deleted item: {itemCode} - {itemName}");
                    MessageBox.Show("Item deleted successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    LoadData();
                }
                catch (Exception ex)
                {
                    Logger.Instance.Error($"Error deleting item {itemCode}: {ex.Message}");
                    MessageBox.Show($"Error deleting item: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void SetupContextMenu()
        {
            dgvContextMenu = new ContextMenuStrip();
            
            var menuEdit = new ToolStripMenuItem("✏️ Edit", null, ContextMenu_Edit);
            var menuDuplicate = new ToolStripMenuItem("📋 Duplicate", null, ContextMenu_Duplicate);
            var menuDelete = new ToolStripMenuItem("🗑️ Delete", null, ContextMenu_Delete);
            var menuSeparator = new ToolStripSeparator();
            var menuCopy = new ToolStripMenuItem("📄 Copy Item Code", null, ContextMenu_CopyCode);
            var menuSeparator2 = new ToolStripSeparator();
            var menuBatchResave = new ToolStripMenuItem("💾 Batch Re-save Selected", null, ContextMenu_BatchResave);
            var menuBatchDelete = new ToolStripMenuItem("🗑️ Batch Delete Selected", null, ContextMenu_BatchDelete);
            
            dgvContextMenu.Items.AddRange(new ToolStripItem[] {
                menuEdit, menuDuplicate, menuSeparator, menuCopy, menuSeparator2, menuBatchResave, menuBatchDelete, menuDelete
            });
            
            dgvItems.ContextMenuStrip = dgvContextMenu;
            
            // Enable/disable menu items based on selection
            dgvContextMenu.Opening += (s, e) =>
            {
                bool hasSingle = dgvItems.SelectedRows.Count == 1;
                bool hasMultiple = dgvItems.SelectedRows.Count > 1;
                
                menuEdit.Enabled = hasSingle;
                menuDuplicate.Enabled = hasSingle;
                menuDelete.Enabled = hasSingle;
                menuCopy.Enabled = hasSingle;
                menuBatchResave.Enabled = hasMultiple;
                menuBatchResave.Text = hasMultiple ? $"💾 Batch Re-save ({dgvItems.SelectedRows.Count} items)" : "💾 Batch Re-save Selected";
                menuBatchDelete.Enabled = hasMultiple;
                menuBatchDelete.Text = $"🗑️ Batch Delete ({dgvItems.SelectedRows.Count} items)";
            };
        }
        
        private void CreateMenuBar()
        {
            menuStrip = new MenuStrip();
            
            // File Menu
            var fileMenu = new ToolStripMenuItem("&File");
            fileMenu.DropDownItems.Add(new ToolStripMenuItem("Import Items from W3T...", null, Menu_ImportW3T));
            fileMenu.DropDownItems.Add(new ToolStripMenuItem("Import Abilities from W3A...", null, Menu_ImportW3A));
            fileMenu.DropDownItems.Add(new ToolStripSeparator());
            fileMenu.DropDownItems.Add(new ToolStripMenuItem("Exit", null, (s, e) => this.Close()));
            
            // Loot System Menu
            var lootMenu = new ToolStripMenuItem("&Loot System");
            lootMenu.DropDownItems.Add(new ToolStripMenuItem("📦 Manage Loot Tiers...", null, Menu_ManageLootTiers));
            lootMenu.DropDownItems.Add(new ToolStripMenuItem("📋 Manage Loot Tables...", null, Menu_ManageLootTables));
            lootMenu.DropDownItems.Add(new ToolStripMenuItem("🎯 Manage Unit Types...", null, Menu_ManageUnitTypes));
            lootMenu.DropDownItems.Add(new ToolStripMenuItem("🏺 Manage Destructible Types...", null, Menu_ManageDestructibleTypes));
            lootMenu.DropDownItems.Add(new ToolStripSeparator());
            lootMenu.DropDownItems.Add(new ToolStripMenuItem("📤 Export Loot System JASS...", null, Menu_ExportLootSystem));
            
            // Gathering Menu
            var gatheringMenu = new ToolStripMenuItem("&Gathering");
            gatheringMenu.DropDownItems.Add(new ToolStripMenuItem("🌿 Manage Gather Nodes...", null, Menu_ManageGatherNodes));
            gatheringMenu.DropDownItems.Add(new ToolStripSeparator());
            gatheringMenu.DropDownItems.Add(new ToolStripMenuItem("📤 Export Gather Nodes JASS...", null, Menu_ExportGatherNodes));
            
            // Tools Menu
            var toolsMenu = new ToolStripMenuItem("&Tools");
            toolsMenu.DropDownItems.Add(new ToolStripMenuItem("⚙️ Configuration", null, BtnConfiguration_Click));
            
            // Logs Menu
            var logsMenu = new ToolStripMenuItem("&Logs");
            logsMenu.DropDownItems.Add(new ToolStripMenuItem("📋 View Logs...", null, Menu_ViewLogs));
            logsMenu.DropDownItems.Add(new ToolStripMenuItem("📁 Open Logs Folder", null, Menu_OpenLogsFolder));
            
            // Help Menu
            var helpMenu = new ToolStripMenuItem("&Help");
            helpMenu.DropDownItems.Add(new ToolStripMenuItem("📖 User Guide & FAQ", null, Menu_ShowHelp));
            helpMenu.DropDownItems.Add(new ToolStripSeparator());
            helpMenu.DropDownItems.Add(new ToolStripMenuItem("About", null, Menu_ShowAbout));
            
            menuStrip.Items.AddRange(new ToolStripItem[] { fileMenu, lootMenu, gatheringMenu, toolsMenu, logsMenu, helpMenu });
        }
        
        private void Menu_ImportW3T(object sender, EventArgs e)
        {
            using (OpenFileDialog dlg = new OpenFileDialog())
            {
                dlg.Filter = "Warcraft 3 Item Files (*.w3t)|*.w3t|All Files (*.*)|*.*";
                dlg.Title = "Select W3T file to import";
                
                if (dlg.ShowDialog() == DialogResult.OK)
                {
                    ImportW3TFile(dlg.FileName);
                }
            }
        }
        
        private void ImportW3TFile(string w3tPath)
        {
            // Ask user how to handle existing items
            var modeDialog = new Form
            {
                Text = "Import Options",
                Width = 500,
                Height = 280,
                FormBorderStyle = FormBorderStyle.FixedDialog,
                StartPosition = FormStartPosition.CenterParent,
                MaximizeBox = false,
                MinimizeBox = false
            };
            
            var lblHeader = new Label
            {
                Text = "How should existing items be handled?",
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                AutoSize = false,
                Width = 460,
                Height = 30,
                Left = 20,
                Top = 20
            };
            
            var rbMerge = new RadioButton
            {
                Text = "Merge - Update only non-empty fields (RECOMMENDED)",
                Left = 30,
                Top = 60,
                Width = 440,
                Checked = true
            };
            
            var lblMerge = new Label
            {
                Text = "   Keeps existing data, only updates fields from W3T that have values.\\n   Safe option that won't overwrite your data with blanks.",
                ForeColor = Color.Gray,
                Left = 30,
                Top = 85,
                Width = 440,
                Height = 35,
                Font = new Font("Segoe UI", 8)
            };
            
            var rbReplace = new RadioButton
            {
                Text = "Replace - Overwrite all fields",
                Left = 30,
                Top = 125,
                Width = 440
            };
            
            var lblReplace = new Label
            {
                Text = "   Replaces ALL data with W3T contents (may overwrite with blanks).\\n   Use only if W3T has complete data.",
                ForeColor = Color.Gray,
                Left = 30,
                Top = 150,
                Width = 440,
                Height = 35,
                Font = new Font("Segoe UI", 8)
            };
            
            var rbSkip = new RadioButton
            {
                Text = "Skip - Keep existing items unchanged",
                Left = 30,
                Top = 190,
                Width = 440
            };
            
            var btnContinue = new Button
            {
                Text = "Continue",
                Width = 100,
                Height = 30,
                Left = 280,
                Top = 210,
                DialogResult = DialogResult.OK
            };
            
            var btnCancel = new Button
            {
                Text = "Cancel",
                Width = 100,
                Height = 30,
                Left = 390,
                Top = 210,
                DialogResult = DialogResult.Cancel
            };
            
            modeDialog.Controls.AddRange(new Control[] { lblHeader, rbMerge, lblMerge, rbReplace, lblReplace, rbSkip, btnContinue, btnCancel });
            modeDialog.AcceptButton = btnContinue;
            modeDialog.CancelButton = btnCancel;
            
            if (modeDialog.ShowDialog() != DialogResult.OK)
            {
                return;
            }
            
            string updateMode = rbMerge.Checked ? "merge" : (rbReplace.Checked ? "replace" : "skip");
            
            // Show warning dialog
            var warning = MessageBox.Show(
                "⚠️ WARNING: Importing from W3T will REPLACE all current items in the database!\n\n" +
                "This action cannot be undone through the application.\n\n" +
                "Do you want to create a backup before importing?\n\n" +
                "Click YES to backup and continue\n" +
                "Click NO to import without backup\n" +
                "Click CANCEL to abort import",
                "Import Warning",
                MessageBoxButtons.YesNoCancel,
                MessageBoxIcon.Warning);
            
            if (warning == DialogResult.Cancel)
            {
                return;
            }
            
            string backupFile = null;
            if (warning == DialogResult.Yes)
            {
                backupFile = BackupDatabase();
                if (backupFile == null)
                {
                    var continueAnyway = MessageBox.Show(
                        "Backup failed. Do you want to continue with import anyway?\\n\\n" +
                        "This is NOT recommended!",
                        "Backup Failed",
                        MessageBoxButtons.YesNo,
                        MessageBoxIcon.Error);
                    
                    if (continueAnyway != DialogResult.Yes)
                    {
                        return;
                    }
                }
                else
                {
                    MessageBox.Show($"Backup created successfully:\\n{backupFile}\\n\\nProceeding with import...",
                                  "Backup Complete", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            
            // Final confirmation
            var finalConfirm = MessageBox.Show(
                "⚠️ FINAL CONFIRMATION ⚠️\n\n" +
                "Are you ABSOLUTELY SURE you want to replace all items?\n\n" +
                $"W3T File: {Path.GetFileName(w3tPath)}\n" +
                $"Backup: {(backupFile != null ? "Created" : "None")}\n\n" +
                "This will DELETE all existing items and import new ones from the W3T file.",
                "Final Confirmation",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning,
                MessageBoxDefaultButton.Button2);
            
            if (finalConfirm != DialogResult.Yes)
            {
                return;
            }
            
            try
            {
                // Find Python script (use v2 importer)
                string projectRoot = Path.GetFullPath(Path.Combine(Application.StartupPath, "..", "..", "..", "..", ".."));
                string scriptPath = Path.Combine(projectRoot, "WC3_Database", "importers", "wc3_w3t_importer_v2.py");
                
                if (!File.Exists(scriptPath))
                {
                    MessageBox.Show($"Import script not found:\n\n{scriptPath}\n\nPlease ensure wc3_w3t_importer_v2.py exists.",
                                  "Import Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                
                // Build command (use correct password and update mode)
                string args = $"\"{scriptPath}\" \"{w3tPath}\" --host 127.0.0.1 --port 5432 --database wc3_pots --user postgres --password 009900 --update-mode {updateMode}";
                
                System.Diagnostics.ProcessStartInfo psi = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "python",
                    Arguments = args,
                    WorkingDirectory = Path.Combine(projectRoot, "WC3_Database"),
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    RedirectStandardInput = true,
                    StandardOutputEncoding = System.Text.Encoding.UTF8,
                    StandardErrorEncoding = System.Text.Encoding.UTF8,
                    CreateNoWindow = true
                };
                
                // Show progress form
                var progressForm = new Form
                {
                    Text = "Importing from W3T",
                    Width = 600,
                    Height = 400,
                    FormBorderStyle = FormBorderStyle.FixedDialog,
                    StartPosition = FormStartPosition.CenterParent,
                    MaximizeBox = false,
                    MinimizeBox = false
                };
                
                var txtOutput = new TextBox
                {
                    Multiline = true,
                    ReadOnly = true,
                    ScrollBars = ScrollBars.Vertical,
                    Dock = DockStyle.Fill,
                    Font = new Font("Consolas", 9),
                    BackColor = Color.Black,
                    ForeColor = Color.LightGreen
                };
                progressForm.Controls.Add(txtOutput);
                
                var btnClose = new Button
                {
                    Text = "Close",
                    Width = 100,
                    Height = 30,
                    Dock = DockStyle.Bottom,
                    Enabled = false
                };
                btnClose.Click += (s, ev) => progressForm.Close();
                progressForm.Controls.Add(btnClose);
                
                progressForm.Show();
                Application.DoEvents();
                
                txtOutput.AppendText($"Starting import from: {Path.GetFileName(w3tPath)}\r\n");
                txtOutput.AppendText($"Command: python {args}\r\n");
                txtOutput.AppendText(new string('=', 60) + "\r\n\r\n");
                
                // Run import in background thread to avoid blocking UI
                System.Threading.Tasks.Task.Run(() =>
                {
                    try
                    {
                        using (var process = System.Diagnostics.Process.Start(psi))
                        {
                            if (process == null)
                            {
                                txtOutput.Invoke((MethodInvoker)(() =>
                                {
                                    txtOutput.AppendText("[ERROR] Failed to start Python process\r\n");
                                    btnClose.Enabled = true;
                                }));
                                return;
                            }
                            
                            // Close stdin immediately so Python doesn't wait for input
                            process.StandardInput.Close();
                            
                            // Read output synchronously in background thread
                            var outputTask = System.Threading.Tasks.Task.Run(() =>
                            {
                                while (!process.StandardOutput.EndOfStream)
                                {
                                    string line = process.StandardOutput.ReadLine();
                                    if (line != null)
                                    {
                                        try
                                        {
                                            txtOutput.Invoke((MethodInvoker)(() =>
                                            {
                                                txtOutput.AppendText(line + "\r\n");
                                                txtOutput.SelectionStart = txtOutput.Text.Length;
                                                txtOutput.ScrollToCaret();
                                            }));
                                        }
                                        catch { /* Form might be closed */ }
                                    }
                                }
                            });
                            
                            var errorTask = System.Threading.Tasks.Task.Run(() =>
                            {
                                while (!process.StandardError.EndOfStream)
                                {
                                    string line = process.StandardError.ReadLine();
                                    if (line != null)
                                    {
                                        try
                                        {
                                            txtOutput.Invoke((MethodInvoker)(() =>
                                            {
                                                txtOutput.AppendText("ERROR: " + line + "\r\n");
                                                txtOutput.SelectionStart = txtOutput.Text.Length;
                                                txtOutput.ScrollToCaret();
                                            }));
                                        }
                                        catch { /* Form might be closed */ }
                                    }
                                }
                            });
                            
                            // Wait for process and both output tasks
                            process.WaitForExit();
                            System.Threading.Tasks.Task.WaitAll(outputTask, errorTask);
                            
                            txtOutput.Invoke((MethodInvoker)(() =>
                            {
                                txtOutput.AppendText("\r\n" + new string('=', 60) + "\r\n");
                                if (process.ExitCode == 0)
                                {
                                    Logger.Instance.Info($"W3T import completed: {Path.GetFileName(w3tPath)} (mode: {updateMode})");
                                    txtOutput.AppendText("[OK] Import completed successfully!\r\n");
                                    MessageBox.Show("Import completed successfully! Reloading data...",
                                                  "Import Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                                    LoadData(); // Reload data
                                }
                                else
                                {
                                    Logger.Instance.Error($"W3T import failed (exit code {process.ExitCode}): {Path.GetFileName(w3tPath)}");
                                    txtOutput.AppendText($"[ERROR] Import failed with exit code {process.ExitCode}\r\n");
                                }
                                btnClose.Enabled = true;
                            }));
                        }
                    }
                    catch (Exception ex)
                    {
                        txtOutput.Invoke((MethodInvoker)(() =>
                        {
                            txtOutput.AppendText($"\r\n[ERROR] Exception: {ex.Message}\r\n");
                            btnClose.Enabled = true;
                        }));
                    }
                });
            }
            catch (Exception ex)
            {
                Logger.Instance.Error($"W3T import error: {ex.Message}");
                MessageBox.Show($"Error running import: {ex.Message}\n\nEnsure Python is installed and in PATH.",
                              "Import Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        
        private void Menu_ImportW3A(object sender, EventArgs e)
        {
            using (OpenFileDialog dlg = new OpenFileDialog())
            {
                dlg.Filter = "Warcraft 3 Ability Files (*.w3a)|*.w3a|All Files (*.*)|*.*";
                dlg.Title = "Select W3A file to import";
                
                if (dlg.ShowDialog() == DialogResult.OK)
                {
                    ImportW3AFile(dlg.FileName);
                }
            }
        }
        
        private void ImportW3AFile(string w3aPath)
        {
            // Show information dialog
            var infoDialog = MessageBox.Show(
                "📚 Ability Import Information\n\n" +
                "This will import ALL abilities from the .w3a file into the database.\n\n" +
                "⚠️ WARNING: This will REPLACE all existing abilities!\n\n" +
                "Do you want to continue with the import?",
                "Import Abilities",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            
            if (infoDialog != DialogResult.Yes)
            {
                return;
            }
            
            try
            {
                // Find Python script
                string projectRoot = Path.GetFullPath(Path.Combine(Application.StartupPath, "..", "..", "..", "..", ".."));
                string scriptPath = Path.Combine(projectRoot, "WC3_Database", "importers", "wc3_w3a_importer.py");
                
                if (!File.Exists(scriptPath))
                {
                    MessageBox.Show($"Ability import script not found:\n\n{scriptPath}\n\nPlease ensure wc3_w3a_importer.py exists.",
                                  "Import Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                
                // Build command
                string arguments = $"\"{scriptPath}\" \"{w3aPath}\" --host 127.0.0.1 --port 5432 --database wc3_pots --user postgres --password 009900";
                
                // Create progress dialog
                var progressForm = new Form
                {
                    Text = "Importing Abilities...",
                    Width = 800,
                    Height = 600,
                    FormBorderStyle = FormBorderStyle.Sizable,
                    StartPosition = FormStartPosition.CenterParent,
                    MinimizeBox = false
                };
                
                var txtOutput = new TextBox
                {
                    Multiline = true,
                    ScrollBars = ScrollBars.Vertical,
                    ReadOnly = true,
                    Dock = DockStyle.Fill,
                    Font = new Font("Consolas", 9)
                };
                
                var btnClose = new Button
                {
                    Text = "Close",
                    Dock = DockStyle.Bottom,
                    Height = 40,
                    Enabled = false
                };
                btnClose.Click += (s, ev) => progressForm.Close();
                
                progressForm.Controls.Add(txtOutput);
                progressForm.Controls.Add(btnClose);
                
                txtOutput.AppendText($"Starting ability import from {Path.GetFileName(w3aPath)}...\r\n");
                txtOutput.AppendText($"Command: python {arguments}\r\n\r\n");
                
                progressForm.Show();
                Application.DoEvents();
                
                // Run import in background thread
                Task.Run(() =>
                {
                    try
                    {
                        var processInfo = new ProcessStartInfo
                        {
                            FileName = "python",
                            Arguments = arguments,
                            UseShellExecute = false,
                            RedirectStandardOutput = true,
                            RedirectStandardError = true,
                            RedirectStandardInput = true,
                            CreateNoWindow = true,
                            StandardOutputEncoding = System.Text.Encoding.UTF8,
                            StandardErrorEncoding = System.Text.Encoding.UTF8
                        };
                        
                        using (var process = new Process { StartInfo = processInfo })
                        {
                            process.Start();
                            
                            // Close stdin immediately
                            process.StandardInput.Close();
                            
                            // Read output and error streams synchronously in separate tasks
                            var outputTask = Task.Run(() =>
                            {
                                string line;
                                while ((line = process.StandardOutput.ReadLine()) != null)
                                {
                                    txtOutput.Invoke((MethodInvoker)(() =>
                                    {
                                        txtOutput.AppendText(line + "\r\n");
                                        txtOutput.SelectionStart = txtOutput.Text.Length;
                                        txtOutput.ScrollToCaret();
                                    }));
                                }
                            });
                            
                            var errorTask = Task.Run(() =>
                            {
                                string line;
                                while ((line = process.StandardError.ReadLine()) != null)
                                {
                                    txtOutput.Invoke((MethodInvoker)(() =>
                                    {
                                        txtOutput.AppendText($"[ERROR] {line}\r\n");
                                        txtOutput.SelectionStart = txtOutput.Text.Length;
                                        txtOutput.ScrollToCaret();
                                    }));
                                }
                            });
                            
                            // Wait for process to exit
                            process.WaitForExit();
                            
                            // Wait for output tasks to complete
                            Task.WaitAll(outputTask, errorTask);
                            
                            // Update UI on completion
                            txtOutput.Invoke((MethodInvoker)(() =>
                            {
                                if (process.ExitCode == 0)
                                {
                                    Logger.Instance.Info($"W3A ability import completed: {Path.GetFileName(w3aPath)}");
                                    txtOutput.AppendText("\r\n[OK] Abilities imported successfully!\r\n");
                                    MessageBox.Show("Abilities imported successfully!",
                                                  "Import Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                                }
                                else
                                {
                                    Logger.Instance.Error($"W3A ability import failed (exit code {process.ExitCode}): {Path.GetFileName(w3aPath)}");
                                    txtOutput.AppendText($"\r\n[ERROR] Import failed with exit code {process.ExitCode}\r\n");
                                    MessageBox.Show($"Ability import failed with exit code {process.ExitCode}. Check output for details.",
                                                  "Import Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                                }
                                btnClose.Enabled = true;
                            }));
                        }
                    }
                    catch (Exception ex)
                    {
                        txtOutput.Invoke((MethodInvoker)(() =>
                        {
                            txtOutput.AppendText($"\r\n[ERROR] Exception: {ex.Message}\r\n");
                            btnClose.Enabled = true;
                        }));
                    }
                });
            }
            catch (Exception ex)
            {
                Logger.Instance.Error($"W3A ability import error: {ex.Message}");
                MessageBox.Show($"Error running ability import: {ex.Message}\n\nEnsure Python is installed and in PATH.",
                              "Import Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        
        private void Menu_ViewLogs(object sender, EventArgs e)
        {
            using (var form = new LogsViewerForm())
            {
                form.ShowDialog(this);
            }
        }
        
        private void Menu_OpenLogsFolder(object sender, EventArgs e)
        {
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            string logsLower = Path.Combine(baseDir, "logs");
            string logsUpper = Path.Combine(baseDir, "Logs");
            string logFolder = System.IO.Directory.Exists(logsLower) ? logsLower : logsUpper;
            
            if (System.IO.Directory.Exists(logFolder))
            {
                System.Diagnostics.Process.Start("explorer.exe", logFolder);
            }
            else
            {
                MessageBox.Show("Logs folder not found.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }
        
        private void Menu_ShowHelp(object sender, EventArgs e)
        {
            var helpForm = new HelpDialog();
            helpForm.ShowDialog();
        }
        
        private void Menu_ShowAbout(object sender, EventArgs e)
        {
            MessageBox.Show($"WC3 Item Manager\\n\\nVersion: 1.0.0\\nAuthor: PotS Project\\nDate: {DateTime.Now.Year}\\n\\nA database management tool for Warcraft 3 custom items.",
                          "About", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void Menu_ManageLootTiers(object sender, EventArgs e)
        {
            if (!isConnected)
            {
                MessageBox.Show("Please connect to the database first.", "Not Connected",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var form = new LootTierForm(connectionString))
            {
                form.ShowDialog(this);
            }
        }

        private void Menu_ManageLootTables(object sender, EventArgs e)
        {
            if (!isConnected)
            {
                MessageBox.Show("Please connect to the database first.", "Not Connected",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var form = new LootTableForm(connectionString))
            {
                form.ShowDialog(this);
            }
        }

        private void Menu_ManageUnitTypes(object sender, EventArgs e)
        {
            if (!isConnected)
            {
                MessageBox.Show("Please connect to the database first.", "Not Connected",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var form = new UnitTypeForm(connectionString))
            {
                form.ShowDialog(this);
            }
        }

        private void Menu_ManageDestructibleTypes(object sender, EventArgs e)
        {
            if (!isConnected)
            {
                MessageBox.Show("Please connect to the database first.", "Not Connected",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var form = new DestructibleTypeForm(connectionString))
            {
                form.ShowDialog(this);
            }
        }

        private void Menu_ExportLootSystem(object sender, EventArgs e)
        {
            if (!isConnected)
            {
                MessageBox.Show("Please connect to the database first.", "Not Connected",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var fbd = new FolderBrowserDialog())
            {
                fbd.Description = "Select output folder for JASS loot system files";
                fbd.ShowNewFolderButton = true;

                if (fbd.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        var exporter = new Exporters.LootSystemExporter(connectionString);
                        var result = exporter.ExportAll(fbd.SelectedPath);

                        if (result.Success)
                        {
                            var sb = new System.Text.StringBuilder();
                            sb.AppendLine("Export complete!");
                            sb.AppendLine($"Tiers: {result.TiersExported}, Unit drops: {result.SpecificDropsExported}, Destructible drops: {result.DestructibleDropsExported}");
                            sb.AppendLine();
                            sb.AppendLine("Files:");
                            foreach (var file in result.FilesExported)
                            {
                                sb.AppendLine($"• {Path.GetFileName(file)}");
                            }
                            
                            Logger.Instance.Info($"Exported loot system to {fbd.SelectedPath}");
                            MessageBox.Show(sb.ToString(), "Export Success",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                        else
                        {
                            MessageBox.Show($"Export failed: {result.ErrorMessage}", "Export Error",
                                MessageBoxButtons.OK, MessageBoxIcon.Error);
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.Instance.Error("Failed to export loot system", ex);
                        MessageBox.Show($"Export failed: {ex.Message}", "Export Error",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void Menu_ManageGatherNodes(object sender, EventArgs e)
        {
            if (!isConnected)
            {
                MessageBox.Show("Please connect to the database first.", "Not Connected",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var form = new GatherNodeForm(connectionString))
            {
                form.ShowDialog(this);
            }
        }

        private void Menu_ExportGatherNodes(object sender, EventArgs e)
        {
            if (!isConnected)
            {
                MessageBox.Show("Please connect to the database first.", "Not Connected",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            using (var fbd = new FolderBrowserDialog())
            {
                fbd.Description = "Select output folder for JASS gather node files";
                fbd.ShowNewFolderButton = true;

                if (fbd.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        var exporter = new Exporters.GatherNodeExporter(connectionString);
                        var result = exporter.ExportAll(fbd.SelectedPath);

                        if (result.Success)
                        {
                            var sb = new System.Text.StringBuilder();
                            sb.AppendLine("Export complete!");
                            sb.AppendLine($"Item nodes: {result.ItemNodesExported}, Unit nodes: {result.UnitNodesExported}");
                            sb.AppendLine($"Zone assignments: {result.ZoneAssignmentsExported}, Spawn points: {result.SpawnPointsExported}");
                            sb.AppendLine();
                            sb.AppendLine("Files:");
                            foreach (var file in result.FilesExported)
                            {
                                sb.AppendLine($"• {Path.GetFileName(file)}");
                            }
                            
                            Logger.Instance.Info($"Exported gather nodes to {fbd.SelectedPath}");
                            MessageBox.Show(sb.ToString(), "Export Success",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                        else
                        {
                            MessageBox.Show($"Export failed: {result.ErrorMessage}", "Export Error",
                                MessageBoxButtons.OK, MessageBoxIcon.Error);
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.Instance.Error("Failed to export gather nodes", ex);
                        MessageBox.Show($"Export failed: {ex.Message}", "Export Error",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void ContextMenu_Edit(object sender, EventArgs e)
        {
            BtnEdit_Click(sender, e);
        }

        private void ContextMenu_Duplicate(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count == 0) return;

            int sourceItemId = Convert.ToInt32(dgvItems.SelectedRows[0].Cells["id"].Value);
            string sourceName = dgvItems.SelectedRows[0].Cells["item_name"].Value?.ToString() ?? "Unknown";
            
            // Open ItemEditForm in duplicate mode (passing negative ID signals duplicate)
            using (var form = new ItemEditForm(sourceItemId, connectionString, isDuplicateMode: true))
            {
                if (form.ShowDialog() == DialogResult.OK)
                {
                    LoadData();
                    lblStatus.Text = $"Duplicated item '{sourceName}'";
                }
            }
        }

        private void ContextMenu_Delete(object sender, EventArgs e)
        {
            BtnDelete_Click(sender, e);
        }

        private void ContextMenu_CopyCode(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count == 0) return;
            
            string code = dgvItems.SelectedRows[0].Cells["item_code"].Value?.ToString() ?? "";
            if (!string.IsNullOrEmpty(code))
            {
                Clipboard.SetText(code);
                lblStatus.Text = $"Copied item code: {code}";
            }
        }

        private void ContextMenu_BatchResave(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count <= 1) return;

            int count = dgvItems.SelectedRows.Count;
            var result = MessageBox.Show(
                $"Re-save {count} selected items to regenerate complete WC3 tooltips?\n\n" +
                $"This will update the Description (ides) and Extended Tooltip (utub) fields with:\n" +
                $"• [Class, Rarity] header\n" +
                $"• Description text\n" +
                $"• Formatted stats\n" +
                $"• Ability descriptions\n\n" +
                $"Recommended after updating tooltip format.",
                "Confirm Batch Re-save",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);

            if (result == DialogResult.Yes)
            {
                try
                {
                    var itemIds = new List<int>();
                    foreach (DataGridViewRow row in dgvItems.SelectedRows)
                    {
                        itemIds.Add(Convert.ToInt32(row.Cells["id"].Value));
                    }

                    // Show progress form
                    var progressForm = new Form
                    {
                        Text = "Batch Re-saving Items",
                        Width = 500,
                        Height = 150,
                        FormBorderStyle = FormBorderStyle.FixedDialog,
                        StartPosition = FormStartPosition.CenterParent,
                        MaximizeBox = false,
                        MinimizeBox = false,
                        ControlBox = false
                    };
                    
                    var lblProgress = new Label
                    {
                        Text = $"Re-saving item 0 of {count}...",
                        AutoSize = false,
                        Width = 460,
                        Height = 60,
                        Left = 20,
                        Top = 30,
                        TextAlign = ContentAlignment.MiddleCenter
                    };
                    progressForm.Controls.Add(lblProgress);

                    int processed = 0;
                    int succeeded = 0;
                    int failed = 0;

                    var bgWorker = new System.ComponentModel.BackgroundWorker();
                    bgWorker.DoWork += (s, args) =>
                    {
                        foreach (int itemId in itemIds)
                        {
                            try
                            {
                                RegenerateItemTooltip(itemId);
                                succeeded++;
                            }
                            catch (Exception ex)
                            {
                                failed++;
                                System.Diagnostics.Debug.WriteLine($"Failed to re-save item {itemId}: {ex.Message}");
                            }
                            
                            processed++;
                            progressForm.BeginInvoke(new Action(() =>
                            {
                                lblProgress.Text = $"Re-saving item {processed} of {count}...\n{succeeded} succeeded, {failed} failed";
                            }));
                        }
                    };
                    
                    bgWorker.RunWorkerCompleted += (s, args) =>
                    {
                        progressForm.Close();
                        
                        Logger.Instance.Info($"Batch re-save completed: {succeeded} succeeded, {failed} failed out of {count} items");
                        
                        string message = $"Batch re-save completed:\n\n" +
                                       $"✓ Succeeded: {succeeded}\n" +
                                       $"✗ Failed: {failed}\n\n" +
                                       $"Items have been updated with complete WC3 tooltips.";
                        
                        MessageBox.Show(message, "Batch Re-save Complete", 
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                        LoadData();
                    };

                    bgWorker.RunWorkerAsync();
                    progressForm.ShowDialog();
                }
                catch (Exception ex)
                {
                    Logger.Instance.Error($"Batch re-save error: {ex.Message}");
                    MessageBox.Show($"Error during batch re-save: {ex.Message}", "Error", 
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void ContextMenu_BatchDelete(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count <= 1) return;

            int count = dgvItems.SelectedRows.Count;
            var result = MessageBox.Show(
                $"Are you sure you want to delete {count} selected items?\n\nThis action cannot be undone.",
                "Confirm Batch Delete",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);

            if (result == DialogResult.Yes)
            {
                try
                {
                    var itemIds = new List<int>();
                    var itemCodes = new List<string>();
                    foreach (DataGridViewRow row in dgvItems.SelectedRows)
                    {
                        itemIds.Add(Convert.ToInt32(row.Cells["id"].Value));
                        itemCodes.Add(row.Cells["item_code"].Value?.ToString() ?? "?");
                    }

                    using (var conn = new NpgsqlConnection(connectionString))
                    {
                        conn.Open();
                        using (var cmd = new NpgsqlCommand($"DELETE FROM items WHERE id = ANY(@ids)", conn))
                        {
                            cmd.Parameters.AddWithValue("ids", itemIds.ToArray());
                            cmd.ExecuteNonQuery();
                        }
                    }
                    
                    Logger.Instance.Info($"Batch deleted {count} items: {string.Join(", ", itemCodes)}");
                    MessageBox.Show($"Successfully deleted {count} items!", "Batch Delete Complete", 
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    LoadData();
                }
                catch (Exception ex)
                {
                    Logger.Instance.Error($"Error during batch delete: {ex.Message}");
                    MessageBox.Show($"Error during batch delete: {ex.Message}", "Error", 
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private void BtnToggleAdvanced_Click(object sender, EventArgs e)
        {
            advancedFiltersVisible = !advancedFiltersVisible;
            pnlAdvancedFilters.Visible = advancedFiltersVisible;
            btnToggleAdvanced.Text = advancedFiltersVisible ? "▲ Advanced" : "▼ Advanced";
        }

        private void BtnClearFilters_Click(object sender, EventArgs e)
        {
            txtSearch.Clear();
            cmbRarity.SelectedIndex = 0;
            cmbClass.SelectedIndex = 0;
            chkCustomOnly.Checked = false;
            numMinLevel.Value = 0;
            numMaxLevel.Value = 999;
            numMinCost.Value = 0;
            numMaxCost.Value = 999999;
            chkHasAbilities.Checked = false;
            chkHasStats.Checked = false;
            lblStatus.Text = "Filters cleared";
            ApplyFilters();
        }

        /// <summary>
        /// Regenerates the complete WC3 tooltip for a single item and saves it to the database.
        /// This creates the [Class, Rarity] + Description + Stats + Abilities format.
        /// </summary>
        private void RegenerateItemTooltip(int itemId)
        {
            using (var conn = new NpgsqlConnection(connectionString))
            {
                conn.Open();

                // Load item data
                string query = @"
                    SELECT i.*, 
                           r.rarity_name, 
                           c.class_name, 
                           t.type_name,
                           i.item_name,
                           i.tooltip_extended
                    FROM items i
                    LEFT JOIN item_rarities r ON i.rarity_id = r.id
                    LEFT JOIN item_classes c ON i.class_id = c.id
                    LEFT JOIN item_types t ON i.type_id = t.id
                    WHERE i.id = @id";

                using (var cmd = new NpgsqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("id", itemId);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            string className = reader["class_name"]?.ToString() ?? "";
                            string rarityName = reader["rarity_name"]?.ToString() ?? "";
                            string itemName = reader["item_name"]?.ToString() ?? "";
                            string existingTooltip = reader["tooltip_extended"]?.ToString() ?? "";
                            
                            reader.Close();

                            // Generate complete tooltip
                            string completeTooltip = GenerateCompleteTooltipForItem(
                                conn, itemId, className, rarityName, existingTooltip);

                            // Ensure tooltip is never empty
                            if (string.IsNullOrWhiteSpace(completeTooltip))
                            {
                                completeTooltip = StripWC3ColorCodes(itemName);
                            }

                            // Update both tooltip_extended and description
                            string updateQuery = @"
                                UPDATE items 
                                SET tooltip_extended = @tooltip,
                                    description = @tooltip,
                                    updated_at = CURRENT_TIMESTAMP
                                WHERE id = @id";

                            using (var updateCmd = new NpgsqlCommand(updateQuery, conn))
                            {
                                updateCmd.Parameters.AddWithValue("tooltip", completeTooltip);
                                updateCmd.Parameters.AddWithValue("id", itemId);
                                updateCmd.ExecuteNonQuery();
                            }
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Generates the complete WC3 tooltip for a specific item from database data.
        /// Format: [Class, Rarity] + Description + Stats + Abilities
        /// </summary>
        private string GenerateCompleteTooltipForItem(NpgsqlConnection conn, int itemId, 
            string className, string rarityName, string existingTooltip)
        {
            var tooltipParts = new List<string>();

            // Part 0: [Class, Rarity] header
            if (!string.IsNullOrEmpty(className) || !string.IsNullOrEmpty(rarityName))
            {
                // Get colors (use defaults if ColorManager not available)
                string classColor = GetWC3ColorForClass(className);
                string rarityColor = GetWC3ColorForRarity(rarityName);
                
                tooltipParts.Add($"[{classColor}{className}|r, {rarityColor}{rarityName}|r]");
            }

            // Part 1: Description text (cleaned)
            string descriptionText = CleanTooltipText(existingTooltip);
            if (!string.IsNullOrWhiteSpace(descriptionText))
            {
                tooltipParts.Add("|n" + descriptionText);
            }

            // Part 2: Stats
            var statLines = LoadAndFormatItemStats(conn, itemId);
            if (statLines.Count > 0)
            {
                tooltipParts.Add("|n" + string.Join("|n", statLines));
            }

            // Part 3: Abilities
            var abilityLines = LoadAndFormatItemAbilities(conn, itemId);
            if (abilityLines.Count > 0)
            {
                tooltipParts.Add("|n|n|cff00ff00Abilities:|r|n" + string.Join("|n", abilityLines));
            }

            return string.Join("", tooltipParts);
        }

        /// <summary>
        /// Loads and formats item stats in WC3 color-coded format.
        /// Returns list of formatted stat lines like: |cffRRGGBB+10 Strength|r
        /// </summary>
        private List<string> LoadAndFormatItemStats(NpgsqlConnection conn, int itemId)
        {
            var statLines = new List<string>();

            string query = @"
                SELECT isv.stat_value, s.stat_name, s.color_hex, s.display_format, s.display_order
                FROM item_stat_values isv
                JOIN item_stats s ON isv.stat_id = s.id
                WHERE isv.item_id = @item_id
                ORDER BY s.display_order";

            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("item_id", itemId);
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        decimal statValue = reader.GetDecimal(0);
                        string statName = reader.GetString(1);
                        string colorHex = reader["color_hex"]?.ToString() ?? "#FFFFFF";
                        string displayFormat = reader["display_format"]?.ToString() ?? "+#";

                        // Convert hex color to WC3 format
                        colorHex = colorHex.Replace("#", "");
                        if (colorHex.Length == 6)
                        {
                            colorHex = "ff" + colorHex; // Add alpha channel
                        }

                        // Format the stat value
                        string formattedValue = FormatStatValue(statValue, displayFormat);

                        // Create colored stat line
                        string statLine = $"|c{colorHex}{formattedValue} {statName}|r";
                        statLines.Add(statLine);
                    }
                }
            }

            return statLines;
        }

        /// <summary>
        /// Loads and formats manual ability descriptions.
        /// Returns list of formatted ability lines like: |cffffcc00Passive:|r Bash - stun
        /// </summary>
        private List<string> LoadAndFormatItemAbilities(NpgsqlConnection conn, int itemId)
        {
            var abilityLines = new List<string>();

            string query = "SELECT manual_abilities_data FROM items WHERE id = @item_id";

            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("item_id", itemId);
                var result = cmd.ExecuteScalar();

                if (result != null && result != DBNull.Value)
                {
                    string jsonData = result.ToString();
                    if (!string.IsNullOrWhiteSpace(jsonData))
                    {
                        try
                        {
                            var abilities = System.Text.Json.JsonSerializer.Deserialize<List<ManualAbilityData>>(jsonData);
                            if (abilities != null)
                            {
                                foreach (var ability in abilities)
                                {
                                    if (!string.IsNullOrWhiteSpace(ability.Type) && 
                                        !string.IsNullOrWhiteSpace(ability.Description))
                                    {
                                        string formatted = $"|cffffcc00{ability.Type}:|r {ability.Description}";
                                        abilityLines.Add(formatted);
                                    }
                                }
                            }
                        }
                        catch
                        {
                            // Ignore JSON parse errors
                        }
                    }
                }
            }

            return abilityLines;
        }

        /// <summary>
        /// Formats a stat value according to its display format.
        /// </summary>
        private string FormatStatValue(decimal value, string displayFormat)
        {
            if (displayFormat.Contains("%"))
            {
                // Percentage format
                if (value >= 0)
                    return $"+{value:0.##}%";
                else
                    return $"{value:0.##}%";
            }
            else
            {
                // Integer format
                if (value >= 0)
                    return $"+{value:0.##}";
                else
                    return $"{value:0.##}";
            }
        }

        /// <summary>
        /// Cleans tooltip text by removing stats, headers, and abilities, leaving only description.
        /// </summary>
        private string CleanTooltipText(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return "";

            // Remove [Class, Rarity] headers
            text = RemoveClassRarityHeaders(text);

            // Remove stat lines (lines with |cffXXXXXX+N Name|r pattern)
            text = RemoveStatLines(text);

            // Remove ability section
            text = RemoveAbilitySection(text);

            // Clean up excessive line breaks
            while (text.Contains("|n|n|n"))
                text = text.Replace("|n|n|n", "|n|n");

            return text.Trim();
        }

        /// <summary>
        /// Removes [Class, Rarity] style headers from text.
        /// </summary>
        private string RemoveClassRarityHeaders(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return text;

            var lines = text.Split(new[] { "|n", "\n" }, StringSplitOptions.None);
            var filteredLines = new List<string>();

            foreach (var line in lines)
            {
                string trimmedLine = line.Trim();
                bool isHeader = trimmedLine.StartsWith("[") && 
                               trimmedLine.EndsWith("]") &&
                               trimmedLine.Contains(",");

                if (!isHeader)
                {
                    filteredLines.Add(line);
                }
            }

            return string.Join("|n", filteredLines).Trim();
        }

        /// <summary>
        /// Removes WC3-formatted stat lines from text.
        /// </summary>
        private string RemoveStatLines(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return text;

            var lines = text.Split(new[] { "|n", "\n" }, StringSplitOptions.None);
            var filteredLines = new List<string>();

            foreach (var line in lines)
            {
                string trimmedLine = line.Trim();
                
                // Check if line looks like a stat: |cffXXXXXX+N Name|r
                bool isStatLine = trimmedLine.Contains("|c") && 
                                 trimmedLine.Contains("|r") &&
                                 (trimmedLine.Contains("+") || trimmedLine.Contains("-")) &&
                                 System.Text.RegularExpressions.Regex.IsMatch(trimmedLine, @"\|c[a-fA-F0-9]{8}[+\-]");

                if (!isStatLine)
                {
                    filteredLines.Add(line);
                }
            }

            return string.Join("|n", filteredLines).Trim();
        }

        /// <summary>
        /// Removes the abilities section from text.
        /// </summary>
        private string RemoveAbilitySection(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return text;

            var lines = text.Split(new[] { "|n", "\n" }, StringSplitOptions.None);
            var filteredLines = new List<string>();

            bool inAbilitySection = false;
            foreach (var line in lines)
            {
                string trimmedLine = line.Trim();

                if (trimmedLine.Contains("Abilities:") || trimmedLine.Contains("|cff00ff00Abilities:|r"))
                {
                    inAbilitySection = true;
                    continue;
                }

                if (!inAbilitySection)
                {
                    filteredLines.Add(line);
                }
            }

            return string.Join("|n", filteredLines).Trim();
        }

        /// <summary>
        /// Gets WC3 color code for a class name.
        /// </summary>
        private string GetWC3ColorForClass(string className)
        {
            // Use default brown color for classes
            return "|cffA52A2A";
        }

        /// <summary>
        /// Gets WC3 color code for a rarity name.
        /// </summary>
        private string GetWC3ColorForRarity(string rarityName)
        {
            // Simple rarity color mapping
            switch (rarityName?.ToLower())
            {
                case "legendary":
                    return "|cffFF8000"; // Orange
                case "epic":
                    return "|cffA335EE"; // Purple
                case "rare":
                    return "|cff0070DD"; // Blue
                case "uncommon":
                    return "|cff1EFF00"; // Green
                case "common":
                default:
                    return "|cff9D9D9D"; // Gray
            }
        }

        /// <summary>
        /// Strips WC3 color codes from text.
        /// </summary>
        private string StripWC3ColorCodes(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return text;

            // Remove |cffXXXXXX and |r tags
            text = System.Text.RegularExpressions.Regex.Replace(text, @"\|c[a-fA-F0-9]{8}", "");
            text = text.Replace("|r", "");

            return text.Trim();
        }

        private void DgvItems_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvItems.SelectedRows.Count == 1)
            {
                var row = dgvItems.SelectedRows[0];
                UpdatePreviewPanel(row);
                btnEdit.Enabled = true;
                btnDelete.Enabled = true;
            }
            else if (dgvItems.SelectedRows.Count > 1)
            {
                lblPreviewTitle.Text = $"Item Preview ({dgvItems.SelectedRows.Count} items selected)";
                rtbTooltipPreview.Text = $"{dgvItems.SelectedRows.Count} items selected.\n\nRight-click for batch operations.";
                rtbTooltipPreview.ForeColor = Color.LightGray;
                
                // Clear icon properly
                if (picIconPreview.Image != null)
                {
                    var oldImage = picIconPreview.Image;
                    picIconPreview.Image = null;
                    oldImage.Dispose();
                }
                picIconPreview.BackColor = Color.FromArgb(40, 40, 50);
                
                btnEdit.Enabled = false;
                btnDelete.Enabled = false;
            }
            else
            {
                lblPreviewTitle.Text = "Item Preview";
                rtbTooltipPreview.Text = "Select an item to see preview";
                rtbTooltipPreview.ForeColor = Color.LightGray;
                
                // Clear icon properly
                if (picIconPreview.Image != null)
                {
                    var oldImage = picIconPreview.Image;
                    picIconPreview.Image = null;
                    oldImage.Dispose();
                }
                picIconPreview.BackColor = Color.FromArgb(40, 40, 50);
                
                btnEdit.Enabled = false;
                btnDelete.Enabled = false;
            }
        }

        private void UpdatePreviewPanel(DataGridViewRow row)
        {
            try
            {
                string name = row.Cells["item_name"].Value?.ToString() ?? "Unknown";
                string rarity = row.Cells["rarity"].Value?.ToString() ?? "Common";
                string itemClass = row.Cells["class"].Value?.ToString() ?? "";
                string itemType = row.Cells["type"].Value?.ToString() ?? "";
                string iconPath = row.Cells["icon_path"].Value?.ToString() ?? "";
                string tooltipExt = row.Cells["tooltip_extended"].Value?.ToString() ?? "";
                int level = Convert.ToInt32(row.Cells["item_level"].Value ?? 0);
                int cost = Convert.ToInt32(row.Cells["gold_cost"].Value ?? 0);
                int itemId = Convert.ToInt32(row.Cells["id"].Value ?? 0);

                lblPreviewTitle.Text = $"Preview: {name}";

                // Load stats for this item
                List<ItemStatValue> stats = LoadItemStats(itemId);

                // Use shared preview generator for consistency
                ItemPreviewGenerator.RenderPreviewFromRow(
                    rtbTooltipPreview,
                    picIconPreview,
                    name,
                    rarity,
                    itemClass,
                    itemType,
                    iconPath,
                    tooltipExt,
                    level,
                    cost,
                    stats,
                    null // Could load rarity colors from database if needed
                );
            }
            catch (Exception ex)
            {
                rtbTooltipPreview.Text = $"Error loading preview: {ex.Message}";
                rtbTooltipPreview.ForeColor = Color.Red;
            }
        }
        
        /// <summary>
        /// Load item stats from database for preview display
        /// </summary>
        private List<ItemStatValue> LoadItemStats(int itemId)
        {
            var stats = new List<ItemStatValue>();
            
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    
                    string query = @"
                        SELECT isv.stat_value, isv.sort_order,
                               s.id, s.stat_code, s.stat_name, s.display_format, s.color_hex, s.display_order
                        FROM item_stat_values isv
                        JOIN item_stats s ON isv.stat_id = s.id
                        WHERE isv.item_id = @itemId
                        ORDER BY isv.sort_order, s.display_order";
                    
                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("itemId", itemId);
                        
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var stat = new ItemStat
                                {
                                    Id = Convert.ToInt32(reader["id"]),
                                    Code = reader["stat_code"]?.ToString() ?? "",
                                    Name = reader["stat_name"]?.ToString() ?? "",
                                    DisplayFormat = reader["display_format"]?.ToString() ?? "{value}",
                                    ColorHex = reader["color_hex"]?.ToString() ?? "",
                                    DisplayOrder = Convert.ToInt32(reader["display_order"] ?? 0)
                                };
                                
                                var statValue = new ItemStatValue
                                {
                                    ItemId = itemId,
                                    StatId = stat.Id,
                                    Value = Convert.ToDecimal(reader["stat_value"]),
                                    Stat = stat
                                };
                                
                                stats.Add(statValue);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading item stats: {ex.Message}");
            }
            
            return stats;
        }
        
        /// <summary>
        /// Helper method to parse WC3 color codes from text
        /// </summary>
        private string ParseWC3ColorCodes(string text)
        {
            return ItemPreviewGenerator.RemoveWC3ColorCodes(text);
        }
        
        private void DgvItems_CellFormatting(object sender, DataGridViewCellFormattingEventArgs e)
        {
            if (e.RowIndex >= 0 && e.RowIndex < dgvItems.Rows.Count)
            {
                try
                {
                    var row = dgvItems.Rows[e.RowIndex];
                    
                    // Check for validation errors first
                    var errors = ValidateItemRow(row);
                    if (errors.Count > 0)
                    {
                        // Highlight row with error color (light red)
                        e.CellStyle.BackColor = Color.FromArgb(255, 220, 220);
                        e.CellStyle.SelectionBackColor = Color.FromArgb(220, 100, 100);
                        e.CellStyle.ForeColor = Color.DarkRed;
                        
                        // Add tooltip with error details
                        row.Cells[e.ColumnIndex].ToolTipText = "⚠️ Validation Errors:\\n" + string.Join("\\n", errors);
                        return; // Skip rarity formatting if there are errors
                    }
                    
                    // Only format if rarity column exists and has a value
                    if (row.Cells["rarity"]?.Value != null)
                    {
                        string rarity = row.Cells["rarity"].Value.ToString();
                        
                        if (!string.IsNullOrEmpty(rarity))
                        {
                            // Get color from rarity name
                            Color rarityColor = GetRarityDisplayColor(rarity);
                            
                            // Apply light tint to entire row
                            Color lightTint = Color.FromArgb(
                                Math.Min(255, rarityColor.R + 200),
                                Math.Min(255, rarityColor.G + 200),
                                Math.Min(255, rarityColor.B + 200)
                            );
                            
                            e.CellStyle.BackColor = lightTint;
                            e.CellStyle.SelectionBackColor = rarityColor;
                            
                            // Make rarity column itself use full color
                            if (dgvItems.Columns[e.ColumnIndex].Name == "rarity")
                            {
                                e.CellStyle.BackColor = rarityColor;
                                e.CellStyle.ForeColor = Color.White;
                                e.CellStyle.Font = new Font(dgvItems.Font, FontStyle.Bold);
                            }
                        }
                    }
                }
                catch { /* Ignore formatting errors */ }
            }
        }
        
        private List<string> ValidateItemRow(DataGridViewRow row)
        {
            var errors = new List<string>();
            
            try
            {
                // Get cell values safely
                string tooltip = row.Cells["tooltip"]?.Value?.ToString() ?? "";
                string tooltipExt = row.Cells["tooltip_extended"]?.Value?.ToString() ?? "";
                string iconPath = row.Cells["icon_path"]?.Value?.ToString() ?? "";
                int itemId = row.Cells["id"]?.Value != null ? Convert.ToInt32(row.Cells["id"].Value) : 0;
                
                // Check 1: Stats mentioned in tooltip but not in database
                if (HasStatKeywords(tooltip) || HasStatKeywords(tooltipExt))
                {
                    // Check if item actually has stats in database
                    if (itemId > 0 && !ItemHasStatsInDatabase(itemId))
                    {
                        errors.Add("Stats mentioned in tooltip but not defined in database");
                    }
                }
                
                // Check 2: Missing or invalid icon path
                if (string.IsNullOrWhiteSpace(iconPath))
                {
                    errors.Add("Missing icon path");
                }
                else if (!iconPath.EndsWith(".blp", StringComparison.OrdinalIgnoreCase) && 
                         !iconPath.EndsWith(".tga", StringComparison.OrdinalIgnoreCase))
                {
                    errors.Add("Invalid icon file extension (should be .blp or .tga)");
                }
                
                // Check 3: Missing item name
                string itemName = row.Cells["item_name"]?.Value?.ToString() ?? "";
                if (string.IsNullOrWhiteSpace(itemName) || itemName.Length < 2)
                {
                    errors.Add("Missing or too short item name");
                }
            }
            catch
            {
                // Ignore validation errors
            }
            
            return errors;
        }
        
        private bool HasStatKeywords(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return false;
            
            string lowerText = text.ToLower();
            string[] statKeywords = { 
                "agility", "strength", "intelligence", "armor", "health", "mana",
                "damage", "attack", "defense", "resistance", "regeneration",
                "+", "resist", "regen", "hp", "mp", "str", "agi", "int"
            };
            
            return statKeywords.Any(keyword => lowerText.Contains(keyword));
        }
        
        private bool ItemHasStatsInDatabase(int itemId)
        {
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    string query = "SELECT COUNT(*) FROM item_stat_values WHERE item_id = @itemId";
                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("itemId", itemId);
                        int count = Convert.ToInt32(cmd.ExecuteScalar());
                        return count > 0;
                    }
                }
            }
            catch
            {
                return true; // Assume it's fine if we can't check
            }
        }
        
        private Color GetRarityDisplayColor(string rarity)
        {
            // Map rarity names to colors (matching WC3 color codes)
            switch (rarity?.ToLower())
            {
                case "common":
                    return Color.FromArgb(128, 128, 128); // Gray
                case "uncommon":
                    return Color.FromArgb(30, 255, 0); // Green
                case "rare":
                    return Color.FromArgb(0, 112, 221); // Blue
                case "epic":
                    return Color.FromArgb(163, 53, 238); // Purple
                case "legendary":
                    return Color.FromArgb(255, 128, 0); // Orange
                default:
                    return Color.White;
            }
        }

        private void LoadItemIcon(string iconPath, string rarity)
        {
            try
            {
                // Clear previous image
                if (picIconPreview.Image != null)
                {
                    var oldImage = picIconPreview.Image;
                    picIconPreview.Image = null;
                    oldImage.Dispose();
                }
                
                if (string.IsNullOrEmpty(iconPath))
                {
                    picIconPreview.Image = CreateErrorIconImage("Error: No icon");
                    picIconPreview.BackColor = Color.FromArgb(60, 60, 70);
                    return;
                }
                
                // Resolve icon path using configuration
                string fullPath = IconPathConfig.Instance.ResolveIconPath(iconPath);
                
                if (string.IsNullOrEmpty(fullPath))
                {
                    picIconPreview.Image = CreateErrorIconImage("Error: Path not found");
                    picIconPreview.BackColor = Color.FromArgb(60, 60, 70);
                    return;
                }
                
                // ALWAYS prefer PNG over BLP if path ends with .blp
                string actualPath = fullPath;
                if (Path.GetExtension(fullPath).ToLower() == ".blp")
                {
                    string pngPath = Path.ChangeExtension(fullPath, ".png");
                    if (File.Exists(pngPath))
                    {
                        // Use PNG version directly (faster and more reliable)
                        actualPath = pngPath;
                    }
                    else if (!File.Exists(fullPath))
                    {
                        // Neither BLP nor PNG exists
                        picIconPreview.Image = CreateErrorIconImage("Error: File not found");
                        picIconPreview.BackColor = Color.FromArgb(60, 60, 70);
                        return;
                    }
                }
                
                if (!File.Exists(actualPath))
                {
                    picIconPreview.Image = CreateErrorIconImage("Error: File not found");
                    picIconPreview.BackColor = Color.FromArgb(60, 60, 70);
                    return;
                }
                
                string ext = Path.GetExtension(actualPath).ToLower();
                
                if (ext == ".png" || ext == ".jpg" || ext == ".jpeg")
                {
                    // Load PNG/JPG directly
                    picIconPreview.Image = Image.FromFile(actualPath);
                    picIconPreview.BackColor = Color.Black;
                }
                else if (ext == ".blp")
                {
                    // BLP file - use cache system
                    string cacheFileName = GetCacheFileName(actualPath);
                    string cachedPath = Path.Combine(cacheFolder, cacheFileName);
                    
                    if (File.Exists(cachedPath))
                    {
                        // Load from disk cache
                        picIconPreview.Image = Image.FromFile(cachedPath);
                        picIconPreview.BackColor = Color.Black;
                    }
                    else
                    {
                        // Convert BLP using improved multi-mipmap method
                        var convertedBitmap = ConvertBlpToCache(actualPath, cachedPath);
                        if (convertedBitmap != null)
                        {
                            picIconPreview.Image = convertedBitmap;
                            picIconPreview.BackColor = Color.Black;
                        }
                        else
                        {
                            // Conversion failed - show error
                            picIconPreview.Image = CreateErrorIconImage("Error: BLP conversion failed");
                            picIconPreview.BackColor = Color.FromArgb(60, 60, 70);
                        }
                    }
                }
                else
                {
                    // TGA or other format not supported - show placeholder
                    picIconPreview.Image = CreateErrorIconImage($"Error: {ext} not supported");
                    picIconPreview.BackColor = Color.FromArgb(60, 60, 70);
                }
            }
            catch (Exception ex)
            {
                // Error loading icon
                picIconPreview.Image = CreateErrorIconImage("Error: Load failed");
                picIconPreview.BackColor = Color.FromArgb(60, 60, 70);
                Console.WriteLine($"Error loading icon: {ex.Message}");
            }
        }

        /// <summary>
        /// Creates an error icon image with text message for the preview pane.
        /// </summary>
        private Image CreateErrorIconImage(string message)
        {
            // Get dimensions from the PictureBox (or use defaults)
            int width = picIconPreview?.Width ?? 64;
            int height = picIconPreview?.Height ?? 64;
            
            var errorImage = new Bitmap(width, height);
            using (var graphics = Graphics.FromImage(errorImage))
            {
                graphics.Clear(Color.FromArgb(45, 45, 55));
                
                // Draw border
                using (var pen = new Pen(Color.FromArgb(100, 100, 110), 2))
                {
                    graphics.DrawRectangle(pen, 2, 2, width - 4, height - 4);
                }
                
                // Draw error icon (X symbol)
                using (var pen = new Pen(Color.FromArgb(180, 80, 80), 3))
                {
                    int margin = width / 4;
                    graphics.DrawLine(pen, margin, margin, width - margin, height - margin);
                    graphics.DrawLine(pen, width - margin, margin, margin, height - margin);
                }
                
                // Draw text message
                using (var font = new Font("Segoe UI", height > 80 ? 9f : 7f, FontStyle.Regular))
                using (var brush = new SolidBrush(Color.FromArgb(180, 180, 190)))
                {
                    var format = new StringFormat
                    {
                        Alignment = StringAlignment.Center,
                        LineAlignment = StringAlignment.Far
                    };
                    
                    var textRect = new RectangleF(0, 0, width, height - 5);
                    graphics.DrawString(message, font, brush, textRect, format);
                }
            }
            return errorImage;
        }

        private Color GetRarityColor(string rarity)
        {
            return rarity switch
            {
                "Common" => Color.LightGray,
                "Uncommon" => Color.FromArgb(30, 255, 0),
                "Rare" => Color.FromArgb(0, 112, 221),
                "Epic" => Color.FromArgb(163, 53, 238),
                "Legendary" => Color.FromArgb(255, 128, 0),
                _ => Color.Gray
            };
        }

        private void DgvItems_ColumnHeaderMouseClick(object sender, DataGridViewCellMouseEventArgs e)
        {
            if (e.ColumnIndex < 0) return;

            DataGridViewColumn column = dgvItems.Columns[e.ColumnIndex];
            
            // Toggle sort order
            if (dgvItems.SortedColumn == column)
            {
                // Toggle between ascending and descending
                var newDirection = (dgvItems.SortOrder == SortOrder.Ascending)
                    ? System.ComponentModel.ListSortDirection.Descending
                    : System.ComponentModel.ListSortDirection.Ascending;
                dgvItems.Sort(column, newDirection);
            }
            else
            {
                // First click - sort ascending
                dgvItems.Sort(column, System.ComponentModel.ListSortDirection.Ascending);
            }
        }

        private void ApplyColumnWidth(string columnName, int defaultWidth)
        {
            if (dgvItems.Columns[columnName] != null)
            {
                dgvItems.Columns[columnName].Width = columnWidths.ContainsKey(columnName)
                    ? columnWidths[columnName]
                    : defaultWidth;
            }
        }
        
        private void ApplyColumnVisibilitySettings()
        {
            // Apply saved column visibility settings from configuration
            if (columnVisibilitySettings != null && columnVisibilitySettings.Count > 0)
            {
                foreach (var kvp in columnVisibilitySettings)
                {
                    if (dgvItems.Columns.Contains(kvp.Key))
                    {
                        dgvItems.Columns[kvp.Key].Visible = kvp.Value;
                    }
                }
            }
        }
        
        private string BackupDatabase()
        {
            try
            {
                // Ensure backup folder exists
                if (!Directory.Exists(backupFolder))
                {
                    Directory.CreateDirectory(backupFolder);
                }
                
                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                string backupFile = Path.Combine(backupFolder, $"items_backup_{timestamp}.sql");
                
                // Find pg_dump executable
                string pgDumpPath = FindPgDump();
                if (string.IsNullOrEmpty(pgDumpPath))
                {
                    throw new Exception("pg_dump not found. Please add PostgreSQL bin directory to PATH or install PostgreSQL client tools.");
                }
                
                // Use pg_dump to backup items table
                var psi = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = pgDumpPath,
                    Arguments = $"-h 127.0.0.1 -p 5432 -U postgres -d wc3_pots -t items -t item_stat_values -t item_rarities -t item_classes -t item_stat_types -f \"{backupFile}\"",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    Environment = { ["PGPASSWORD"] = "009900" }
                };
                
                using (var process = System.Diagnostics.Process.Start(psi))
                {
                    string error = process.StandardError.ReadToEnd();
                    process.WaitForExit();
                    
                    if (process.ExitCode == 0)
                    {                        return backupFile;
                    }
                    else
                    {
                        throw new Exception($"pg_dump failed: {error}");
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Database backup failed: {ex.Message}\n\nNote: pg_dump must be installed and in PATH.",
                              "Backup Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return null;
            }
        }
        
        private string FindPgDump()
        {
            // Check if pg_dump is in PATH
            try
            {
                var psi = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = "pg_dump",
                    Arguments = "--version",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };
                
                using (var process = System.Diagnostics.Process.Start(psi))
                {
                    process.WaitForExit();
                    if (process.ExitCode == 0)
                    {
                        return "pg_dump";
                    }
                }
            }
            catch { }
            
            // Search common PostgreSQL installation directories
            var commonPaths = new List<string>
            {
                @"C:\Program Files\PostgreSQL\18\bin\pg_dump.exe",
                @"C:\Program Files\PostgreSQL\17\bin\pg_dump.exe",
                @"C:\Program Files\PostgreSQL\16\bin\pg_dump.exe",
                @"C:\Program Files\PostgreSQL\15\bin\pg_dump.exe",
                @"C:\Program Files\PostgreSQL\14\bin\pg_dump.exe",
                @"C:\Program Files (x86)\PostgreSQL\18\bin\pg_dump.exe",
                @"C:\Program Files (x86)\PostgreSQL\17\bin\pg_dump.exe",
                @"C:\Program Files (x86)\PostgreSQL\16\bin\pg_dump.exe",
                @"C:\Program Files (x86)\PostgreSQL\15\bin\pg_dump.exe",
                @"C:\Program Files (x86)\PostgreSQL\14\bin\pg_dump.exe"
            };
            
            foreach (var path in commonPaths)
            {
                if (File.Exists(path))
                {
                    return path;
                }
            }
            
            return null;
        }

        private void BtnExport_Click(object sender, EventArgs e)
        {
            // Create export dialog
            using (var exportDialog = new Form())
            {
                exportDialog.Text = "Export to W3T";
                exportDialog.Size = new Size(500, 200);
                exportDialog.StartPosition = FormStartPosition.CenterParent;
                exportDialog.FormBorderStyle = FormBorderStyle.FixedDialog;
                exportDialog.MaximizeBox = false;
                exportDialog.MinimizeBox = false;

                int y = 20;
                int labelX = 20;
                int controlX = 150;

                // Export folder
                Label lblFolder = new Label { Text = "Export Folder:", Location = new Point(labelX, y), AutoSize = true };
                TextBox txtFolder = new TextBox { Location = new Point(controlX, y), Width = 250, Text = @"H:\Pelit\PotS_JASS\WC3_Database\exports" };
                Button btnBrowse = new Button { Text = "Browse...", Location = new Point(controlX + 260, y - 2), Width = 80 };
                exportDialog.Controls.AddRange(new Control[] { lblFolder, txtFolder, btnBrowse });
                y += 35;

                // Base filename
                Label lblBaseName = new Label { Text = "Base Filename:", Location = new Point(labelX, y), AutoSize = true };
                TextBox txtBaseName = new TextBox { Location = new Point(controlX, y), Width = 250, Text = "ItemData" };
                exportDialog.Controls.AddRange(new Control[] { lblBaseName, txtBaseName });
                y += 35;

                // Info label
                Label lblInfo = new Label 
                { 
                    Text = "Export file will be named: [BaseName]_YYYYMMDD_HHMMSS.w3t", 
                    Location = new Point(labelX, y), 
                    AutoSize = true,
                    ForeColor = Color.Gray
                };
                exportDialog.Controls.Add(lblInfo);
                y += 35;

                // Buttons
                Button btnOk = new Button { Text = "Export", Location = new Point(250, y), Width = 90, DialogResult = DialogResult.OK };
                Button btnCancel = new Button { Text = "Cancel", Location = new Point(350, y), Width = 90, DialogResult = DialogResult.Cancel };
                exportDialog.Controls.AddRange(new Control[] { btnOk, btnCancel });
                exportDialog.AcceptButton = btnOk;
                exportDialog.CancelButton = btnCancel;

                // Browse button handler
                btnBrowse.Click += (s, ev) =>
                {
                    using (var folderDialog = new FolderBrowserDialog())
                    {
                        folderDialog.SelectedPath = txtFolder.Text;
                        folderDialog.Description = "Select export folder";
                        if (folderDialog.ShowDialog() == DialogResult.OK)
                        {
                            txtFolder.Text = folderDialog.SelectedPath;
                        }
                    }
                };

                if (exportDialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        string folder = txtFolder.Text;
                        string baseName = txtBaseName.Text;
                        string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                        string filename = $"{baseName}_{timestamp}.w3t";
                        string fullPath = System.IO.Path.Combine(folder, filename);

                        // Create folder if it doesn't exist
                        if (!System.IO.Directory.Exists(folder))
                        {
                            System.IO.Directory.CreateDirectory(folder);
                        }

                        // Execute Python exporter
                        string projectRoot = System.IO.Path.GetFullPath(
                            System.IO.Path.Combine(Application.StartupPath, "..", "..", "..", "..", ".."));
                        string exportScript = System.IO.Path.Combine(projectRoot, "WC3_Database", "export_w3t_cli.py");
                        
                        if (!System.IO.File.Exists(exportScript))
                        {
                            MessageBox.Show($"Export script not found:\n\n{exportScript}\n\nPlease ensure export_w3t_cli.py exists.",
                                "Export Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                            return;
                        }

                        // Create process to run Python script
                        var processInfo = new ProcessStartInfo
                        {
                            FileName = "python",
                            Arguments = $"\"{exportScript}\" \"{fullPath}\"",
                            WorkingDirectory = System.IO.Path.Combine(projectRoot, "WC3_Database"),
                            UseShellExecute = false,
                            RedirectStandardOutput = true,
                            RedirectStandardError = true,
                            CreateNoWindow = true
                        };

                        // Show progress dialog
                        var progressForm = new Form
                        {
                            Text = "Exporting to W3T",
                            Width = 500,
                            Height = 150,
                            FormBorderStyle = FormBorderStyle.FixedDialog,
                            StartPosition = FormStartPosition.CenterParent,
                            MaximizeBox = false,
                            MinimizeBox = false,
                            ControlBox = false
                        };
                        
                        var lblProgress = new Label
                        {
                            Text = "Exporting items to .w3t file...\nThis may take a moment.",
                            AutoSize = false,
                            Width = 460,
                            Height = 60,
                            Left = 20,
                            Top = 30,
                            TextAlign = ContentAlignment.MiddleCenter
                        };
                        progressForm.Controls.Add(lblProgress);

                        // Run export in background
                        string output = "";
                        string error = "";
                        int exitCode = -1;

                        var bgWorker = new System.ComponentModel.BackgroundWorker();
                        bgWorker.DoWork += (s, args) =>
                        {
                            using (var process = Process.Start(processInfo))
                            {
                                output = process.StandardOutput.ReadToEnd();
                                error = process.StandardError.ReadToEnd();
                                process.WaitForExit();
                                exitCode = process.ExitCode;
                            }
                        };
                        
                        bgWorker.RunWorkerCompleted += (s, args) =>
                        {
                            progressForm.Close();
                            
                            if (exitCode == 0)
                            {
                                Logger.Instance.Info($"Exported W3T file: {fullPath}");
                                MessageBox.Show(
                                    $"✓ Export completed successfully!\n\n" +
                                    $"Output file:\n{fullPath}\n\n" +
                                    $"To import into World Editor:\n" +
                                    $"1. Open World Editor\n" +
                                    $"2. Object Editor → Items\n" +
                                    $"3. File → Import Object Data\n" +
                                    $"4. Select the exported file",
                                    "Export Successful",
                                    MessageBoxButtons.OK,
                                    MessageBoxIcon.Information);
                            }
                            else
                            {
                                Logger.Instance.Error($"W3T export failed (exit code {exitCode}): {error}");
                                MessageBox.Show(
                                    $"Export failed with exit code: {exitCode}\n\n" +
                                    $"Error:\n{error}\n\n" +
                                    $"Output:\n{output}",
                                    "Export Failed",
                                    MessageBoxButtons.OK,
                                    MessageBoxIcon.Error);
                            }
                        };
                        
                        bgWorker.RunWorkerAsync();
                        progressForm.ShowDialog(this);
                    }
                    catch (Exception ex)
                    {
                        Logger.Instance.Error($"W3T export error: {ex.Message}");
                        MessageBox.Show($"Error during export: {ex.Message}\n\n{ex.StackTrace}", "Export Error", 
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void BtnExportDEquipment_Click(object sender, EventArgs e)
        {
            // Create export dialog similar to W3T export
            using (var exportDialog = new Form())
            {
                exportDialog.Text = "Export DEquipment Item Definitions";
                exportDialog.Size = new Size(600, 250);
                exportDialog.StartPosition = FormStartPosition.CenterParent;
                exportDialog.FormBorderStyle = FormBorderStyle.FixedDialog;
                exportDialog.MaximizeBox = false;
                exportDialog.MinimizeBox = false;

                int y = 20;
                int labelX = 20;
                int controlX = 170;

                // Export folder
                Label lblFolder = new Label { Text = "Export Folder:", Location = new Point(labelX, y), AutoSize = true };
                TextBox txtFolder = new TextBox { Location = new Point(controlX, y), Width = 300, 
                    Text = @"H:\Pelit\PotS_JASS\WC3_Export\DEquipmentItemDefinitions" };
                Button btnBrowse = new Button { Text = "Browse...", Location = new Point(controlX + 310, y - 2), Width = 80 };
                exportDialog.Controls.AddRange(new Control[] { lblFolder, txtFolder, btnBrowse });
                y += 35;

                // Base filename
                Label lblBaseName = new Label { Text = "Base Filename:", Location = new Point(labelX, y), AutoSize = true };
                TextBox txtBaseName = new TextBox { Location = new Point(controlX, y), Width = 300, 
                    Text = "DEquipmentItemDefinitions" };
                exportDialog.Controls.AddRange(new Control[] { lblBaseName, txtBaseName });
                y += 35;

                // Library name
                Label lblLibraryName = new Label { Text = "Library Name:", Location = new Point(labelX, y), AutoSize = true };
                TextBox txtLibraryName = new TextBox { Location = new Point(controlX, y), Width = 300, 
                    Text = "DEquipmentItemDefinitions" };
                exportDialog.Controls.AddRange(new Control[] { lblLibraryName, txtLibraryName });
                y += 35;

                // Info label
                Label lblInfo = new Label 
                { 
                    Text = "Export file will be named: [BaseName]_YYYYMMDD_HHMM.j", 
                    Location = new Point(labelX, y), 
                    AutoSize = true,
                    ForeColor = Color.Gray
                };
                exportDialog.Controls.Add(lblInfo);
                y += 35;

                // Buttons
                Button btnOk = new Button { Text = "Export", Location = new Point(350, y), Width = 90, DialogResult = DialogResult.OK };
                Button btnCancel = new Button { Text = "Cancel", Location = new Point(450, y), Width = 90, DialogResult = DialogResult.Cancel };
                exportDialog.Controls.AddRange(new Control[] { btnOk, btnCancel });
                exportDialog.AcceptButton = btnOk;
                exportDialog.CancelButton = btnCancel;

                // Browse button handler
                btnBrowse.Click += (s, ev) =>
                {
                    using (var folderDialog = new FolderBrowserDialog())
                    {
                        folderDialog.SelectedPath = txtFolder.Text;
                        folderDialog.Description = "Select export folder";
                        if (folderDialog.ShowDialog() == DialogResult.OK)
                        {
                            txtFolder.Text = folderDialog.SelectedPath;
                        }
                    }
                };

                if (exportDialog.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        string folder = txtFolder.Text;
                        string baseName = txtBaseName.Text;
                        string libraryName = txtLibraryName.Text;
                        string timestamp = DateTime.Now.ToString("yyyyMMdd-HHmm");
                        string filename = $"{baseName}_{timestamp}.j";
                        string fullPath = System.IO.Path.Combine(folder, filename);

                        // Create folder if it doesn't exist
                        if (!System.IO.Directory.Exists(folder))
                        {
                            System.IO.Directory.CreateDirectory(folder);
                        }

                        // Execute Python exporter
                        string projectRoot = System.IO.Path.GetFullPath(
                            System.IO.Path.Combine(Application.StartupPath, "..", "..", "..", "..", ".."));
                        string exportScript = System.IO.Path.Combine(projectRoot, "WC3_Database", "export_dequipment_cli.py");
                        
                        if (!System.IO.File.Exists(exportScript))
                        {
                            MessageBox.Show($"Export script not found:\n\n{exportScript}\n\nCreating script...",
                                "Script Missing", MessageBoxButtons.OK, MessageBoxIcon.Information);
                            
                            // Script doesn't exist yet - will need to create it
                            MessageBox.Show(
                                "DEquipment Python exporter needs to be created.\n\n" +
                                "The script should be at:\n" + exportScript,
                                "Not Implemented",
                                MessageBoxButtons.OK,
                                MessageBoxIcon.Warning);
                            return;
                        }

                        // Create process to run Python script
                        var processInfo = new ProcessStartInfo
                        {
                            FileName = "python",
                            Arguments = $"\"{exportScript}\" \"{fullPath}\" \"{libraryName}\"",
                            WorkingDirectory = System.IO.Path.Combine(projectRoot, "WC3_Database"),
                            UseShellExecute = false,
                            RedirectStandardOutput = true,
                            RedirectStandardError = true,
                            CreateNoWindow = true
                        };

                        // Show progress dialog
                        var progressForm = new Form
                        {
                            Text = "Exporting DEquipment Definitions",
                            Width = 500,
                            Height = 150,
                            FormBorderStyle = FormBorderStyle.FixedDialog,
                            StartPosition = FormStartPosition.CenterParent,
                            MaximizeBox = false,
                            MinimizeBox = false,
                            ControlBox = false
                        };
                        
                        var lblProgress = new Label
                        {
                            Text = "Exporting items to JASS library...\nThis may take a moment.",
                            AutoSize = false,
                            Width = 460,
                            Height = 60,
                            Left = 20,
                            Top = 30,
                            TextAlign = ContentAlignment.MiddleCenter
                        };
                        progressForm.Controls.Add(lblProgress);

                        // Run export in background
                        string output = "";
                        string error = "";
                        int exitCode = -1;

                        var bgWorker = new System.ComponentModel.BackgroundWorker();
                        bgWorker.DoWork += (s, args) =>
                        {
                            using (var process = Process.Start(processInfo))
                            {
                                output = process.StandardOutput.ReadToEnd();
                                error = process.StandardError.ReadToEnd();
                                process.WaitForExit();
                                exitCode = process.ExitCode;
                            }
                        };
                        
                        bgWorker.RunWorkerCompleted += (s, args) =>
                        {
                            progressForm.Close();
                            
                            if (exitCode == 0)
                            {
                                Logger.Instance.Info($"Exported DEquipment JASS file: {fullPath}");
                                MessageBox.Show(
                                    $"✓ DEquipment export completed successfully!\n\n" +
                                    $"Output file:\n{fullPath}\n\n" +
                                    $"To use in your map:\n" +
                                    $"1. Open Trigger Editor\n" +
                                    $"2. Import → Custom Script\n" +
                                    $"3. Select the exported .j file\n" +
                                    $"4. Ensure DEquipment library is loaded first",
                                    "Export Successful",
                                    MessageBoxButtons.OK,
                                    MessageBoxIcon.Information);
                            }
                            else
                            {
                                Logger.Instance.Error($"DEquipment export failed (exit code {exitCode}): {error}");
                                MessageBox.Show(
                                    $"Export failed with exit code: {exitCode}\n\n" +
                                    $"Error:\n{error}\n\n" +
                                    $"Output:\n{output}",
                                    "Export Failed",
                                    MessageBoxButtons.OK,
                                    MessageBoxIcon.Error);
                            }
                        };
                        
                        bgWorker.RunWorkerAsync();
                        progressForm.ShowDialog(this);
                    }
                    catch (Exception ex)
                    {
                        Logger.Instance.Error($"DEquipment export error: {ex.Message}");
                        MessageBox.Show($"Error during export: {ex.Message}\n\n{ex.StackTrace}", "Export Error", 
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }
        
        // Zoom functionality
        private void CmbZoom_SelectedIndexChanged(object sender, EventArgs e)
        {
            // Map zoom selection to scale factor
            float[] zoomLevels = new float[] { 0.5f, 0.75f, 1.0f, 1.25f, 1.5f, 1.75f, 2.0f };
            int selectedIndex = cmbZoom.SelectedIndex;
            
            if (selectedIndex >= 0 && selectedIndex < zoomLevels.Length)
            {
                currentZoomFactor = zoomLevels[selectedIndex];
                ApplyZoom(currentZoomFactor);
                SaveSettings(); // Save zoom preference
            }
        }
        
        private void CmbSort_SelectedIndexChanged(object sender, EventArgs e)
        {
            // Re-apply filters with new sort order
            ApplyFilters();
        }
        
        private string GetOrderByClause()
        {
            if (cmbSort == null || cmbSort.SelectedIndex < 0)
                return "ORDER BY i.item_code ASC";
            
            switch (cmbSort.SelectedIndex)
            {
                case 0: return "ORDER BY i.item_code ASC";       // Code (A-Z)
                case 1: return "ORDER BY i.item_code DESC";      // Code (Z-A)
                case 2: return "ORDER BY i.item_name ASC";       // Name (A-Z)
                case 3: return "ORDER BY i.item_name DESC";      // Name (Z-A)
                case 4: return "ORDER BY i.created_at DESC";     // Recently Added
                case 5: return "ORDER BY i.updated_at DESC";     // Recently Modified
                case 6: return "ORDER BY i.item_level ASC";      // Level (Low-High)
                case 7: return "ORDER BY i.item_level DESC";     // Level (High-Low)
                default: return "ORDER BY i.item_code ASC";
            }
        }
        
        private void ApplyZoom(float scaleFactor)
        {
            try
            {
                // Suspend layout during zoom changes
                this.SuspendLayout();
                
                // Scale font for DataGridView
                float baseFontSize = 9f;
                float newFontSize = baseFontSize * scaleFactor;
                dgvItems.Font = new Font("Segoe UI", newFontSize);
                dgvItems.ColumnHeadersDefaultCellStyle.Font = new Font("Segoe UI", newFontSize, FontStyle.Bold);
                dgvItems.RowTemplate.Height = (int)(22 * scaleFactor);
                dgvItems.ColumnHeadersHeight = (int)(32 * scaleFactor);
                
                // Scale preview panel fonts
                rtbTooltipPreview.Font = new Font("Consolas", 9 * scaleFactor);
                lblPreviewTitle.Font = new Font("Segoe UI", 11 * scaleFactor, FontStyle.Bold);
                
                // Scale button and control fonts in top panel
                foreach (Control ctrl in this.Controls)
                {
                    if (ctrl is Panel panel)
                    {
                        ScaleControlFonts(panel, scaleFactor);
                    }
                }
                
                this.ResumeLayout();
                this.PerformLayout();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error applying zoom: {ex.Message}", "Zoom Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }
        
        private void ScaleControlFonts(Control parent, float scaleFactor)
        {
            foreach (Control ctrl in parent.Controls)
            {
                if (ctrl is Button || ctrl is Label || ctrl is TextBox || ctrl is ComboBox || ctrl is CheckBox)
                {
                    if (ctrl != cmbZoom && ctrl != lblZoom) // Don't scale zoom control itself
                    {
                        float baseFontSize = 9f;
                        if (ctrl is Label lbl && lbl.Font.Bold)
                            baseFontSize = 10f;
                        
                        ctrl.Font = new Font(ctrl.Font.FontFamily, baseFontSize * scaleFactor, ctrl.Font.Style);
                    }
                }
                
                // Recursively scale child controls
                if (ctrl.Controls.Count > 0)
                {
                    ScaleControlFonts(ctrl, scaleFactor);
                }
            }
        }
        
        // Helper methods for BLP caching
        private string GetCacheFileName(string fullPath)
        {
            // Create unique cache filename based on full path hash
            string hash = Convert.ToBase64String(
                System.Security.Cryptography.MD5.Create()
                .ComputeHash(System.Text.Encoding.UTF8.GetBytes(fullPath)))
                .Replace("/", "_").Replace("+", "-").Replace("=", "");
            return hash + ".png";
        }
        
        private Bitmap ConvertBlpToCache(string blpPath, string cachePath)
        {
            try
            {
                using (var fileStream = File.OpenRead(blpPath))
                {
                    var blpFile = new BlpFile(fileStream);
                    
                    // Try different mipmap levels (0 = full size, 1 = half, 2 = quarter, etc.)
                    // Some BLP files have corrupt mipmap 0 but valid smaller mipmaps
                    Bitmap bitmap = null;
                    Bitmap fallbackBitmap = null; // Keep last decoded bitmap as fallback
                    
                    for (int mipmapLevel = 0; mipmapLevel < Math.Min(blpFile.MipMapCount, 4); mipmapLevel++)
                    {
                        try
                        {
                            var bitmapSource = blpFile.GetBitmapSource(mipmapLevel);
                            
                            // Convert to Bitmap
                            using (var ms = new MemoryStream())
                            {
                                var encoder = new System.Windows.Media.Imaging.PngBitmapEncoder();
                                encoder.Frames.Add(System.Windows.Media.Imaging.BitmapFrame.Create(bitmapSource));
                                encoder.Save(ms);
                                ms.Seek(0, SeekOrigin.Begin);
                                bitmap = new Bitmap(ms);
                            }
                            
                            // Validate bitmap isn't completely black/empty
                            if (IsValidBitmap(bitmap))
                            {
                                // Found a good mipmap level
                                fallbackBitmap?.Dispose();
                                break;
                            }
                            else
                            {
                                // Keep as fallback but try next mipmap level
                                fallbackBitmap?.Dispose();
                                fallbackBitmap = bitmap;
                                bitmap = null;
                            }
                        }
                        catch
                        {
                            // This mipmap level failed, try next one
                            bitmap?.Dispose();
                            bitmap = null;
                            continue;
                        }
                    }
                    
                    // Use fallback if no valid bitmap found but we have something
                    if (bitmap == null && fallbackBitmap != null)
                    {
                        bitmap = fallbackBitmap;
                        fallbackBitmap = null;
                    }
                    
                    if (bitmap == null)
                    {
                        // All mipmap levels failed completely
                        fallbackBitmap?.Dispose();
                        return null;
                    }
                    
                    // Fix color channels (swap B and R if needed)
                    bitmap = FixBlpColors(bitmap);
                    
                    // Save to disk cache
                    bitmap.Save(cachePath, ImageFormat.Png);
                    
                    return bitmap;
                }
            }
            catch
            {
                return null;
            }
        }
        
        private bool IsValidBitmap(Bitmap bitmap)
        {
            if (bitmap == null || bitmap.Width < 4 || bitmap.Height < 4)
                return false;
            
            try
            {
                // Sample several points to see if image has any visible content
                int nonBlackPixels = 0;
                int sampledPixels = 0;
                
                // Sample 16 points in a 4x4 grid
                for (int y = 0; y < 4; y++)
                {
                    for (int x = 0; x < 4; x++)
                    {
                        int px = (bitmap.Width * x) / 4 + bitmap.Width / 8;
                        int py = (bitmap.Height * y) / 4 + bitmap.Height / 8;
                        
                        if (px >= bitmap.Width) px = bitmap.Width - 1;
                        if (py >= bitmap.Height) py = bitmap.Height - 1;
                        
                        Color pixel = bitmap.GetPixel(px, py);
                        sampledPixels++;
                        
                        // Check if pixel has any color content (ignore alpha for transparency)
                        // Very lenient - just check if there's ANY color at all
                        if (pixel.R > 5 || pixel.G > 5 || pixel.B > 5)
                        {
                            nonBlackPixels++;
                        }
                    }
                }
                
                // Consider valid if at least 10% of sampled pixels have any content
                // Very lenient to accept even mostly-dark images
                return nonBlackPixels >= sampledPixels * 0.1;
            }
            catch
            {
                return false;
            }
        }
        
        private Bitmap FixBlpColors(Bitmap original)
        {
            try
            {
                // Sample multiple points to detect if B/R channels are swapped
                int sampleCount = 0;
                long totalR = 0, totalG = 0, totalB = 0;
                int blueHighCount = 0; // Count pixels where blue > red significantly
                int nonZeroPixels = 0; // Count non-black pixels
                
                // Sample 25 points in a 5x5 grid
                for (int sy = 0; sy < 5; sy++)
                {
                    for (int sx = 0; sx < 5; sx++)
                    {
                        int x = (original.Width * sx) / 5 + original.Width / 10;
                        int y = (original.Height * sy) / 5 + original.Height / 10;
                        
                        if (x >= original.Width) x = original.Width - 1;
                        if (y >= original.Height) y = original.Height - 1;
                        
                        Color pixel = original.GetPixel(x, y);
                        
                        // Skip fully transparent pixels
                        if (pixel.A < 10)
                            continue;
                        
                        totalR += pixel.R;
                        totalG += pixel.G;
                        totalB += pixel.B;
                        sampleCount++;
                        
                        // Count non-black pixels
                        if (pixel.R > 5 || pixel.G > 5 || pixel.B > 5)
                        {
                            nonZeroPixels++;
                        }
                        
                        // Check if blue channel is suspiciously higher than red
                        if (pixel.B > pixel.R + 20 && pixel.B > 30)
                        {
                            blueHighCount++;
                        }
                    }
                }
                
                if (sampleCount == 0)
                    return original; // All transparent
                
                // Calculate averages
                double avgR = (double)totalR / sampleCount;
                double avgG = (double)totalG / sampleCount;
                double avgB = (double)totalB / sampleCount;
                
                // Determine if swap is needed
                bool needsSwap = false;
                
                // For very dark images (avg brightness < 5%), be more aggressive
                // If there's ANY blue presence at all, try swapping
                if (avgB > 5 && avgR < 5 && nonZeroPixels > 0)
                {
                    needsSwap = true; // Very dark with any blue = likely BGR
                }
                // For normal brightness images, use statistical analysis
                else if (avgB > avgR * 1.2 && avgB > 20)
                {
                    needsSwap = true; // Blue significantly higher than red
                }
                // If many pixels show blue dominance
                else if (blueHighCount > sampleCount * 0.25)
                {
                    needsSwap = true; // 25% threshold for blue-dominant pixels
                }
                // For images with moderate blue but very low red
                else if (avgB > 15 && avgR < avgB * 0.5)
                {
                    needsSwap = true;
                }
                
                if (!needsSwap)
                {
                    return original;
                }
                
                // Create new bitmap with swapped R and B channels
                Bitmap fixedBitmap = new Bitmap(original.Width, original.Height);
                
                for (int y = 0; y < original.Height; y++)
                {
                    for (int x = 0; x < original.Width; x++)
                    {
                        Color pixel = original.GetPixel(x, y);
                        // Swap R and B channels
                        Color swapped = Color.FromArgb(pixel.A, pixel.B, pixel.G, pixel.R);
                        fixedBitmap.SetPixel(x, y, swapped);
                    }
                }
                
                original.Dispose();
                return fixedBitmap;
            }
            catch
            {
                return original;
            }
        }
    }
}
