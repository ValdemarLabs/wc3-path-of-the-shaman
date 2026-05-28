using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace WC3ItemManager
{
    public class ConfigurationForm : Form
    {
        private TabControl tabControl;
        private Button btnSave;
        private Button btnCancel;
        
        // Column Visibility Tab
        private CheckedListBox lstColumns;
        private Dictionary<string, bool> columnVisibility;
        
        // Icon Paths Tab
        private TextBox txtBlizzardIconPath;
        private TextBox txtCustomIconPath;
        private Button btnBrowseBlizzard;
        private Button btnBrowseCustom;
        
        // Display Settings Tab
        private CheckBox chkShowTooltipPreview;
        private CheckBox chkColorCodeRows;
        private CheckBox chkValidateOnLoad;
        private NumericUpDown numRowHeight;
        
        // Database Tab
        private TextBox txtBackupFolder;
        private Button btnBrowseBackupFolder;
        
        public Dictionary<string, bool> ColumnVisibilitySettings => columnVisibility;
        public string BlizzardIconPath { get; private set; }
        public string CustomIconPath { get; private set; }
        public string BackupFolderPath { get; private set; }
        
        public ConfigurationForm(Dictionary<string, bool> currentVisibility, string blizzardPath, string customPath, string backupPath = null)
        {
            columnVisibility = new Dictionary<string, bool>(currentVisibility);
            BlizzardIconPath = blizzardPath ?? "";
            CustomIconPath = customPath ?? "";
            BackupFolderPath = backupPath ?? GetDefaultBackupPath();
            
            InitializeUI();
            LoadSettings();
        }
        
        private string GetDefaultBackupPath()
        {
            return System.IO.Path.Combine(
                System.IO.Directory.GetParent(AppDomain.CurrentDomain.BaseDirectory).Parent.Parent.Parent.FullName,
                "database_item_backups"
            );
        }
        
        private void InitializeUI()
        {
            this.Text = "⚙️ Configuration";
            this.Size = new Size(700, 600);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            
            tabControl = new TabControl
            {
                Dock = DockStyle.Fill,
                Font = new Font("Segoe UI", 10)
            };
            
            // Column Visibility Tab
            TabPage tabColumns = new TabPage("Column Visibility");
            SetupColumnVisibilityTab(tabColumns);
            tabControl.TabPages.Add(tabColumns);
            
            // Icon Paths Tab
            TabPage tabIconPaths = new TabPage("Icon Paths");
            SetupIconPathsTab(tabIconPaths);
            tabControl.TabPages.Add(tabIconPaths);
            
            // Display Settings Tab
            TabPage tabDisplay = new TabPage("Display Settings");
            SetupDisplaySettingsTab(tabDisplay);
            tabControl.TabPages.Add(tabDisplay);
            
            // Database Tab
            TabPage tabDatabase = new TabPage("Database");
            SetupDatabaseTab(tabDatabase);
            tabControl.TabPages.Add(tabDatabase);
            
            // Button Panel
            Panel buttonPanel = new Panel
            {
                Dock = DockStyle.Bottom,
                Height = 60,
                Padding = new Padding(10)
            };
            
            btnSave = new Button
            {
                Text = "💾 Save",
                Location = new Point(450, 15),
                Width = 100,
                Height = 35,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                BackColor = Color.FromArgb(76, 175, 80),
                ForeColor = Color.White,
                DialogResult = DialogResult.OK
            };
            btnSave.Click += BtnSave_Click;
            
            btnCancel = new Button
            {
                Text = "❌ Cancel",
                Location = new Point(560, 15),
                Width = 100,
                Height = 35,
                Font = new Font("Segoe UI", 10),
                DialogResult = DialogResult.Cancel
            };
            
            buttonPanel.Controls.AddRange(new Control[] { btnSave, btnCancel });
            
            this.Controls.Add(tabControl);
            this.Controls.Add(buttonPanel);
        }
        
        private void SetupColumnVisibilityTab(TabPage tab)
        {
            Label lblInstructions = new Label
            {
                Text = "Select which columns to display in the main item list:",
                Location = new Point(20, 20),
                Size = new Size(620, 30),
                Font = new Font("Segoe UI", 10)
            };
            
            lstColumns = new CheckedListBox
            {
                Location = new Point(20, 60),
                Size = new Size(620, 400),
                Font = new Font("Segoe UI", 10),
                CheckOnClick = true
            };
            
            Button btnSelectAll = new Button
            {
                Text = "Select All",
                Location = new Point(20, 470),
                Width = 120,
                Height = 30
            };
            btnSelectAll.Click += (s, e) =>
            {
                for (int i = 0; i < lstColumns.Items.Count; i++)
                    lstColumns.SetItemChecked(i, true);
            };
            
            Button btnSelectNone = new Button
            {
                Text = "Select None",
                Location = new Point(150, 470),
                Width = 120,
                Height = 30
            };
            btnSelectNone.Click += (s, e) =>
            {
                for (int i = 0; i < lstColumns.Items.Count; i++)
                    lstColumns.SetItemChecked(i, false);
            };
            
            Button btnReset = new Button
            {
                Text = "Reset to Default",
                Location = new Point(280, 470),
                Width = 120,
                Height = 30
            };
            btnReset.Click += BtnResetColumns_Click;
            
            tab.Controls.AddRange(new Control[] { lblInstructions, lstColumns, btnSelectAll, btnSelectNone, btnReset });
        }
        
        private void SetupIconPathsTab(TabPage tab)
        {
            int y = 30;
            
            Label lblBlizzard = new Label
            {
                Text = "Blizzard Icon Path:",
                Location = new Point(20, y),
                Size = new Size(150, 25),
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };
            
            txtBlizzardIconPath = new TextBox
            {
                Location = new Point(20, y + 30),
                Size = new Size(500, 25),
                Font = new Font("Segoe UI", 10),
                Text = BlizzardIconPath
            };
            
            btnBrowseBlizzard = new Button
            {
                Text = "📁 Browse",
                Location = new Point(530, y + 28),
                Width = 100,
                Height = 28
            };
            btnBrowseBlizzard.Click += (s, e) => BrowseFolder(txtBlizzardIconPath);
            
            Label lblBlizzardNote = new Label
            {
                Text = "Path to Warcraft 3 installation icons (e.g., C:\\Games\\Warcraft III\\_retail_\\war3.w3mod\\ui\\icons)",
                Location = new Point(20, y + 65),
                Size = new Size(620, 40),
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.Gray
            };
            
            y += 130;
            
            Label lblCustom = new Label
            {
                Text = "Custom Icon Path:",
                Location = new Point(20, y),
                Size = new Size(150, 25),
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };
            
            txtCustomIconPath = new TextBox
            {
                Location = new Point(20, y + 30),
                Size = new Size(500, 25),
                Font = new Font("Segoe UI", 10),
                Text = CustomIconPath
            };
            
            btnBrowseCustom = new Button
            {
                Text = "📁 Browse",
                Location = new Point(530, y + 28),
                Width = 100,
                Height = 28
            };
            btnBrowseCustom.Click += (s, e) => BrowseFolder(txtCustomIconPath);
            
            Label lblCustomNote = new Label
            {
                Text = "Path to custom/imported icons for your map (e.g., H:\\Maps\\MyMap\\Assets\\Icons)",
                Location = new Point(20, y + 65),
                Size = new Size(620, 40),
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.Gray
            };
            
            tab.Controls.AddRange(new Control[] { 
                lblBlizzard, txtBlizzardIconPath, btnBrowseBlizzard, lblBlizzardNote,
                lblCustom, txtCustomIconPath, btnBrowseCustom, lblCustomNote
            });
        }
        
        private void SetupDisplaySettingsTab(TabPage tab)
        {
            int y = 30;
            
            Label lblTitle = new Label
            {
                Text = "Display & UI Options:",
                Location = new Point(20, y),
                Size = new Size(200, 25),
                Font = new Font("Segoe UI", 11, FontStyle.Bold)
            };
            
            y += 40;
            
            chkShowTooltipPreview = new CheckBox
            {
                Text = "Show tooltip preview panel",
                Location = new Point(40, y),
                Size = new Size(300, 25),
                Font = new Font("Segoe UI", 10),
                Checked = true
            };
            
            y += 35;
            
            chkColorCodeRows = new CheckBox
            {
                Text = "Color-code rows by rarity",
                Location = new Point(40, y),
                Size = new Size(300, 25),
                Font = new Font("Segoe UI", 10),
                Checked = true
            };
            
            y += 35;
            
            chkValidateOnLoad = new CheckBox
            {
                Text = "Validate items on load (highlight errors in red)",
                Location = new Point(40, y),
                Size = new Size(400, 25),
                Font = new Font("Segoe UI", 10),
                Checked = true
            };
            
            y += 50;
            
            Label lblRowHeight = new Label
            {
                Text = "DataGrid Row Height:",
                Location = new Point(40, y),
                Size = new Size(200, 25),
                Font = new Font("Segoe UI", 10)
            };
            
            numRowHeight = new NumericUpDown
            {
                Location = new Point(250, y),
                Width = 80,
                Minimum = 18,
                Maximum = 100,
                Value = 22,
                Font = new Font("Segoe UI", 10)
            };
            
            y += 60;
            
            // Cache Management Section
            Label lblCacheTitle = new Label
            {
                Text = "Icon Cache Management:",
                Location = new Point(20, y),
                Size = new Size(300, 25),
                Font = new Font("Segoe UI", 11, FontStyle.Bold)
            };
            
            y += 35;
            
            Label lblCacheInfo = new Label
            {
                Text = "Clear the icon cache to force re-conversion of all BLP files.\nUseful after color correction algorithm improvements.",
                Location = new Point(40, y),
                Size = new Size(500, 35),
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.Gray
            };
            
            y += 45;
            
            Button btnClearCache = new Button
            {
                Text = "🗑️ Clear Icon Cache",
                Location = new Point(40, y),
                Width = 200,
                Height = 35,
                Font = new Font("Segoe UI", 10),
                BackColor = Color.FromArgb(244, 67, 54),
                ForeColor = Color.White
            };
            btnClearCache.Click += BtnClearCache_Click;
            
            Label lblCacheSize = new Label
            {
                Text = GetCacheSizeInfo(),
                Location = new Point(250, y + 8),
                AutoSize = true,
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.DarkGray
            };
            
            tab.Controls.AddRange(new Control[] { 
                lblTitle, chkShowTooltipPreview, chkColorCodeRows, chkValidateOnLoad, 
                lblRowHeight, numRowHeight,
                lblCacheTitle, lblCacheInfo, btnClearCache, lblCacheSize
            });
        }
        
        private void LoadSettings()
        {
            // Load column visibility settings
            foreach (var kvp in columnVisibility)
            {
                string displayName = GetColumnDisplayName(kvp.Key);
                int index = lstColumns.Items.Add(displayName);
                lstColumns.SetItemChecked(index, kvp.Value);
            }
            
            txtBlizzardIconPath.Text = BlizzardIconPath;
            txtCustomIconPath.Text = CustomIconPath;
        }
        
        private string GetColumnDisplayName(string columnName)
        {
            // Convert database column names to friendly display names
            var mapping = new Dictionary<string, string>
            {
                { "item_code", "Item Code" },
                { "item_name", "Item Name" },
                { "base_id", "Base ID" },
                { "icon_path", "Icon Path" },
                { "rarity", "Rarity" },
                { "class", "Class" },
                { "item_level", "Level" },
                { "gold_cost", "Gold Cost" },
                { "type", "Type" },
                { "created_at", "Created Date" },
                { "updated_at", "Modified Date" },
                { "tooltip", "Tooltip" },
                { "tooltip_extended", "Extended Tooltip" },
                { "hotkey", "Hotkey" },
                { "wc3_abilities", "WC3 Abilities" },
                { "wc3_classification", "WC3 Classification" }
            };
            
            return mapping.ContainsKey(columnName) ? mapping[columnName] : columnName;
        }
        
        private string GetColumnInternalName(string displayName)
        {
            // Reverse mapping
            var mapping = new Dictionary<string, string>
            {
                { "Item Code", "item_code" },
                { "Item Name", "item_name" },
                { "Base ID", "base_id" },
                { "Icon Path", "icon_path" },
                { "Rarity", "rarity" },
                { "Class", "class" },
                { "Level", "item_level" },
                { "Gold Cost", "gold_cost" },
                { "Type", "type" },
                { "Created Date", "created_at" },
                { "Modified Date", "updated_at" },
                { "Tooltip", "tooltip" },
                { "Extended Tooltip", "tooltip_extended" },
                { "Hotkey", "hotkey" },
                { "WC3 Abilities", "wc3_abilities" },
                { "WC3 Classification", "wc3_classification" }
            };
            
            return mapping.ContainsKey(displayName) ? mapping[displayName] : displayName;
        }
        
        private void BrowseFolder(TextBox textBox)
        {
            using (var folderDialog = new FolderBrowserDialog())
            {
                folderDialog.Description = "Select icon folder path";
                folderDialog.ShowNewFolderButton = true;
                
                if (!string.IsNullOrWhiteSpace(textBox.Text) && System.IO.Directory.Exists(textBox.Text))
                {
                    folderDialog.SelectedPath = textBox.Text;
                }
                
                if (folderDialog.ShowDialog() == DialogResult.OK)
                {
                    textBox.Text = folderDialog.SelectedPath;
                }
            }
        }
        
        private void BtnResetColumns_Click(object sender, EventArgs e)
        {
            var result = MessageBox.Show(
                "Reset column visibility to default settings?\n\nThis will show commonly used columns and hide technical fields.",
                "Reset to Default",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            
            if (result == DialogResult.Yes)
            {
                // Define default visibility
                var defaults = new HashSet<string> { 
                    "item_code", "item_name", "rarity", "class", "item_level", "gold_cost", "type" 
                };
                
                for (int i = 0; i < lstColumns.Items.Count; i++)
                {
                    string displayName = lstColumns.Items[i].ToString();
                    string internalName = GetColumnInternalName(displayName);
                    bool isVisible = defaults.Contains(internalName);
                    lstColumns.SetItemChecked(i, isVisible);
                }
            }
        }
        
        private void BtnSave_Click(object sender, EventArgs e)
        {
            // Save column visibility from CheckedListBox
            columnVisibility.Clear();
            for (int i = 0; i < lstColumns.Items.Count; i++)
            {
                string displayName = lstColumns.Items[i].ToString();
                string internalName = GetColumnInternalName(displayName);
                columnVisibility[internalName] = lstColumns.GetItemChecked(i);
            }
            
            // Save icon paths
            BlizzardIconPath = txtBlizzardIconPath.Text;
            CustomIconPath = txtCustomIconPath.Text;
            
            // Validate paths
            if (!string.IsNullOrWhiteSpace(BlizzardIconPath) && !System.IO.Directory.Exists(BlizzardIconPath))
            {
                var result = MessageBox.Show(
                    $"Blizzard icon path does not exist:\n{BlizzardIconPath}\n\nSave anyway?",
                    "Path Warning",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Warning);
                
                if (result == DialogResult.No)
                {
                    this.DialogResult = DialogResult.None;
                    return;
                }
            }
            
            if (!string.IsNullOrWhiteSpace(CustomIconPath) && !System.IO.Directory.Exists(CustomIconPath))
            {
                var result = MessageBox.Show(
                    $"Custom icon path does not exist:\n{CustomIconPath}\n\nSave anyway?",
                    "Path Warning",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Warning);
                
                if (result == DialogResult.No)
                {
                    this.DialogResult = DialogResult.None;
                    return;
                }
            }
        }
        
        private string GetCacheSizeInfo()
        {
            try
            {
                string cacheFolder = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cache");
                if (!System.IO.Directory.Exists(cacheFolder))
                    return "Cache: 0 files (0 MB)";
                
                var files = System.IO.Directory.GetFiles(cacheFolder, "*.png");
                long totalBytes = files.Sum(f => new System.IO.FileInfo(f).Length);
                double totalMB = totalBytes / (1024.0 * 1024.0);
                
                return $"Cache: {files.Length} files ({totalMB:F1} MB)";
            }
            catch
            {
                return "Cache: Unknown";
            }
        }
        
        private void BtnClearCache_Click(object sender, EventArgs e)
        {
            try
            {
                string cacheFolder = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "cache");
                if (!System.IO.Directory.Exists(cacheFolder))
                {
                    MessageBox.Show("Cache folder does not exist.", "Info", 
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
                
                var files = System.IO.Directory.GetFiles(cacheFolder, "*.png");
                
                if (files.Length == 0)
                {
                    MessageBox.Show("Cache is already empty.", "Info", 
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
                
                var result = MessageBox.Show(
                    $"This will delete {files.Length} cached icon files.\n\n" +
                    "Icons will be re-converted with improved color correction when you browse them again.\n\n" +
                    "Continue?",
                    "Clear Cache",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Question);
                
                if (result == DialogResult.Yes)
                {
                    int deletedCount = 0;
                    foreach (var file in files)
                    {
                        try
                        {
                            System.IO.File.Delete(file);
                            deletedCount++;
                        }
                        catch
                        {
                            // Skip files that can't be deleted
                        }
                    }
                    
                    MessageBox.Show(
                        $"Successfully deleted {deletedCount} cached files.\n\n" +
                        "Icons will be regenerated with improved color correction on next use.",
                        "Cache Cleared",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information);
                    
                    // Update the cache size label if it exists
                    foreach (Control ctrl in this.tabControl.TabPages[2].Controls)
                    {
                        if (ctrl is Label lbl && lbl.Text.StartsWith("Cache:"))
                        {
                            lbl.Text = GetCacheSizeInfo();
                            break;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error clearing cache: {ex.Message}", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        
        private void SetupDatabaseTab(TabPage tab)
        {
            int y = 20;
            
            // Title
            Label lblTitle = new Label
            {
                Text = "Database Backup & Management",
                Location = new Point(20, y),
                Size = new Size(500, 30),
                Font = new Font("Segoe UI", 14, FontStyle.Bold)
            };
            
            y += 45;
            
            // Backup Section
            Label lblBackupTitle = new Label
            {
                Text = "Database Backup:",
                Location = new Point(20, y),
                Size = new Size(300, 25),
                Font = new Font("Segoe UI", 11, FontStyle.Bold)
            };
            
            y += 35;
            
            Label lblBackupInfo = new Label
            {
                Text = "Create a backup of all item data, stats, and classifications.",
                Location = new Point(40, y),
                Size = new Size(500, 25),
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.Gray
            };
            
            y += 35;
            
            // Backup folder location
            Label lblBackupFolder = new Label
            {
                Text = "Backup Folder:",
                Location = new Point(40, y),
                Size = new Size(120, 25),
                Font = new Font("Segoe UI", 9)
            };
            
            txtBackupFolder = new TextBox
            {
                Location = new Point(160, y),
                Width = 350,
                Height = 25,
                Font = new Font("Segoe UI", 9),
                ReadOnly = true,
                Text = BackupFolderPath
            };
            
            btnBrowseBackupFolder = new Button
            {
                Text = "📁 Browse",
                Location = new Point(520, y - 2),
                Width = 100,
                Height = 28,
                Font = new Font("Segoe UI", 9)
            };
            btnBrowseBackupFolder.Click += BtnBrowseBackupFolder_Click;
            
            y += 40;
            
            Button btnBackup = new Button
            {
                Text = "💾 Create Backup Now",
                Location = new Point(40, y),
                Width = 200,
                Height = 40,
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                BackColor = Color.FromArgb(33, 150, 243),
                ForeColor = Color.White
            };
            btnBackup.Click += BtnBackup_Click;
            
            y += 55;
            
            Label lblBackupList = new Label
            {
                Text = "📁 View Backups Folder",
                Location = new Point(40, y),
                Size = new Size(200, 25),
                Font = new Font("Segoe UI", 9, FontStyle.Underline),
                ForeColor = Color.Blue,
                Cursor = Cursors.Hand
            };
            lblBackupList.Click += (s, e) =>
            {
                string backupFolder = txtBackupFolder.Text;
                if (!System.IO.Directory.Exists(backupFolder))
                {
                    System.IO.Directory.CreateDirectory(backupFolder);
                }
                System.Diagnostics.Process.Start("explorer.exe", backupFolder);
            };
            
            y += 50;
            
            // Database Info
            Label lblInfoTitle = new Label
            {
                Text = "Database Information:",
                Location = new Point(20, y),
                Size = new Size(300, 25),
                Font = new Font("Segoe UI", 11, FontStyle.Bold)
            };
            
            y += 35;
            
            Label lblDbInfo = new Label
            {
                Text = "Host: 127.0.0.1:5432\nDatabase: wc3_pots\nUser: postgres",
                Location = new Point(40, y),
                Size = new Size(400, 60),
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.Gray
            };
            
            y += 70;
            
            // Warning
            Label lblWarning = new Label
            {
                Text = "⚠️ Note: Backup requires pg_dump to be installed and in system PATH.\n" +
                       "Install PostgreSQL client tools if backups fail.",
                Location = new Point(40, y),
                Size = new Size(600, 40),
                Font = new Font("Segoe UI", 8),
                ForeColor = Color.FromArgb(255, 152, 0)
            };
            
            tab.Controls.AddRange(new Control[] {
                lblTitle, lblBackupTitle, lblBackupInfo, lblBackupFolder, txtBackupFolder, btnBrowseBackupFolder,
                btnBackup, lblBackupList, lblInfoTitle, lblDbInfo, lblWarning
            });
        }
        
        private void BtnBrowseBackupFolder_Click(object sender, EventArgs e)
        {
            using (var folderDialog = new FolderBrowserDialog())
            {
                folderDialog.Description = "Select folder for database backups";
                folderDialog.SelectedPath = txtBackupFolder.Text;
                
                if (folderDialog.ShowDialog() == DialogResult.OK)
                {
                    txtBackupFolder.Text = folderDialog.SelectedPath;
                    BackupFolderPath = folderDialog.SelectedPath;
                }
            }
        }
        
        private void BtnBackup_Click(object sender, EventArgs e)
        {
            try
            {
                string backupFolder = txtBackupFolder.Text;
                if (!System.IO.Directory.Exists(backupFolder))
                {
                    System.IO.Directory.CreateDirectory(backupFolder);
                }
                
                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                string backupFile = System.IO.Path.Combine(backupFolder, $"items_backup_{timestamp}.sql");
                
                // Find pg_dump executable
                string pgDumpPath = FindPgDump();
                if (string.IsNullOrEmpty(pgDumpPath))
                {
                    MessageBox.Show(
                        "pg_dump not found.\n\n" +
                        "Please add PostgreSQL bin directory to system PATH, or:\n\n" +
                        "1. Locate your PostgreSQL installation (e.g., C:\\Program Files\\PostgreSQL\\18\\bin)\n" +
                        "2. Add that bin folder to your system PATH environment variable\n" +
                        "3. Restart this application\n\n" +
                        "Install PostgreSQL client tools if not installed.",
                        "pg_dump Not Found",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Warning);
                    return;
                }
                
                // Use pg_dump to backup
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
                    {
                        var fileInfo = new System.IO.FileInfo(backupFile);
                        MessageBox.Show(
                            $"Backup created successfully!\n\n" +
                            $"File: {System.IO.Path.GetFileName(backupFile)}\n" +
                            $"Size: {fileInfo.Length / 1024} KB\n" +
                            $"Location: {backupFolder}",
                            "Backup Complete",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Information);
                    }
                    else
                    {
                        MessageBox.Show(
                            $"Backup failed:\n\n{error}\n\n" +
                            "Make sure pg_dump is installed and in system PATH.\n" +
                            "Install PostgreSQL client tools if needed.",
                            "Backup Error",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Error creating backup: {ex.Message}\n\n" +
                    "Ensure pg_dump is installed and in system PATH.\n\n" +
                    "You can install it with PostgreSQL client tools.",
                    "Backup Error",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
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
                if (System.IO.File.Exists(path))
                {
                    return path;
                }
            }
            
            return null;
        }
    }
}
